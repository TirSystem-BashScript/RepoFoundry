# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# preflight.sh - Read-only checks of both hosts before anything is created.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: check_gitea_organization, check_gitea_license, inspect_repository, preflight_gitea, check_github_organization, preflight_github, test_gitea_ssh, decide_existing_repositories, run_preflight

check_gitea_organization() {
  local org="$1" login="$2"
  api_call gitea GET "/orgs/$org"
  if [[ $HTTP_STATUS == 404 ]]; then
    die "Gitea owner '$org' is neither your account ($login) nor an organization the token can see"
  fi
  expect_status "cannot look up the Gitea organization '$org'" 200
  api_call gitea GET "/users/$login/orgs/$org/permissions"
  expect_status "cannot read your permissions in the Gitea organization '$org'" 200
  if [[ $(json_get "$HTTP_BODY_FILE" can_create_repository) != true ]]; then
    die "you may not create repositories in the Gitea organization '$org'"
  fi
}

check_gitea_license() {
  api_call gitea GET /licenses
  expect_status "cannot list the licenses of the Gitea server" 200
  json_has_value "$HTTP_BODY_FILE" key "$AGPL_LICENSE_KEY" ||
    die "the Gitea server does not offer the $AGPL_LICENSE_KEY license"
}

# inspect_repository HOST: record in STATE[HOST_repo] whether the repository
# is free (does not exist), empty, initial_only (just the LICENSE and the
# README.md Gitea adds) or not_empty.
inspect_repository() {
  local host="$1" owner name names
  owner="$(repo_owner "$host")"
  name="${PROJECT[name]}"
  api_call "$host" GET "/repos/$owner/$name"
  if [[ $HTTP_STATUS == 404 ]]; then
    STATE[${host}_repo]="free"
    return 0
  fi
  expect_status "cannot look up the $(host_label "$host") repository $owner/$name" 200
  api_call "$host" GET "/repos/$owner/$name/contents"
  if [[ $HTTP_STATUS == 404 ]]; then
    STATE[${host}_repo]="empty"
    return 0
  fi
  expect_status "cannot read the contents of the $(host_label "$host") repository $owner/$name" 200
  # Gitea adds a README.md of its own next to the LICENSE when it creates a
  # repository with a license (seen on a real server), so both count as the
  # content this script creates.
  names="$(json_values "$HTTP_BODY_FILE" name | sort | tr '\n' ' ')"
  case "${names% }" in
    "") STATE[${host}_repo]="empty" ;;
    "LICENSE" | "LICENSE README.md") STATE[${host}_repo]="initial_only" ;;
    *) STATE[${host}_repo]="not_empty" ;;
  esac
}

preflight_gitea() {
  local owner="${PROJECT[gitea_owner]}" login
  api_call gitea GET /user
  expect_status "Gitea rejected the token" 200
  login="$(json_get "$HTTP_BODY_FILE" login)"
  [[ -n $login ]] || die "Gitea did not say which account the token belongs to"
  STATE[gitea_login]="$login"
  if is_same_name "$owner" "$login"; then
    STATE[gitea_owner_kind]="user"
  else
    check_gitea_organization "$owner" "$login"
    STATE[gitea_owner_kind]="organization"
  fi
  if ((PROJECT[has_github])); then
    check_gitea_license
  fi
  inspect_repository gitea
}

check_github_organization() {
  local org="$1" login="$2"
  api_call github GET "/user/memberships/orgs/$org"
  if [[ $HTTP_STATUS == 404 ]]; then
    die "GitHub owner '$org' is neither your account ($login) nor an organization you belong to (or the token lacks the read:org scope)"
  fi
  expect_status "cannot read your membership of the GitHub organization '$org'" 200
  if [[ $(json_get "$HTTP_BODY_FILE" state) != active ]]; then
    die "your membership of the GitHub organization '$org' is not active"
  fi
}

preflight_github() {
  local owner="${PROJECT[github_owner]}" configured login
  configured="${CREDENTIALS[GITHUB_USER]:-}"
  api_call github GET /user
  expect_status "GitHub rejected the token" 200
  login="$(json_get "$HTTP_BODY_FILE" login)"
  [[ -n $login ]] || die "GitHub did not say which account the token belongs to"
  STATE[github_login]="$login"
  if [[ -n $configured ]] && ! is_same_name "$configured" "$login"; then
    warn "GITHUB_USER is '$configured' but the token belongs to '$login'; the mirror will use '$login'"
  fi
  if is_same_name "$owner" "$login"; then
    STATE[github_owner_kind]="user"
  else
    check_github_organization "$owner" "$login"
    STATE[github_owner_kind]="organization"
  fi
  inspect_repository github
}

# The SSH result decides later whether origin uses SSH or HTTPS. Without ssh
# or without access it is simply "not passed"; it never stops the run.
test_gitea_ssh() {
  local host port output status=0
  host="$(gitea_host)"
  port="${CONFIG[GITEA_SSH_PORT]}"
  STATE[is_ssh_ok]=0
  STATE[ssh_note]="failed (check your SSH key and that $host:$port is reachable)"
  if ! command -v ssh >/dev/null 2>&1; then
    STATE[ssh_note]="not tested (ssh is not installed)"
    return 0
  fi
  output="$(ssh -p "$port" -o BatchMode=yes -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=yes -T "git@$host" </dev/null 2>&1)" || status=$?
  if ((status == 0)) || [[ $output == *"successfully authenticated"* ]]; then
    STATE[is_ssh_ok]=1
    STATE[ssh_note]="passed"
  fi
}

# decide_existing_repositories: a repository that already exists may only be
# reused when it is empty (Gitea: or holds just the license this script adds).
decide_existing_repositories() {
  local host owner state
  for host in gitea github; do
    STATE[reuse_$host]=0
    if [[ $host == github ]] && ! ((PROJECT[has_github])); then
      continue
    fi
    owner="$(repo_owner "$host")"
    state="${STATE[${host}_repo]}"
    case "$state" in
      free) ;;
      empty) STATE[reuse_$host]=1 ;;
      initial_only)
        if [[ $host == gitea ]] && ((PROJECT[has_github])); then
          STATE[reuse_$host]=1
        else
          die "the $(host_label "$host") repository $owner/${PROJECT[name]} already exists and has content; choose another name or remove it first"
        fi
        ;;
      *)
        die "the $(host_label "$host") repository $owner/${PROJECT[name]} already exists and has content; choose another name or remove it first"
        ;;
    esac
  done
}

run_preflight() {
  say ""
  say "Checking the hosts (read-only requests)..."
  preflight_gitea
  if ((PROJECT[has_github])); then
    preflight_github
  fi
  test_gitea_ssh
  decide_existing_repositories
  inspect_local_directory
  say "All checks passed."
}
