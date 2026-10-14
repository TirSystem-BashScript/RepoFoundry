# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# repositories.sh - Creating the GitHub and Gitea repositories.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: repo_body, settle_timed_out_create, create_repository

# repo_body HOST: the JSON body that creates the repository on HOST.
repo_body() {
  local host="$1" description private=true extra=""
  description="$(json_escape "${PROJECT[description]}")"
  if [[ ${PROJECT[visibility]} != private ]]; then
    private=false
  fi
  if [[ $host == github ]]; then
    printf '{"name":"%s","description":"%s","private":%s,"auto_init":false}' \
      "${PROJECT[name]}" "$description" "$private"
    return 0
  fi
  if [[ -n ${PROJECT[license]} ]]; then
    extra=',"auto_init":true,"license":"'"${PROJECT[license]}"'"'
  else
    extra=',"auto_init":false'
  fi
  printf '{"name":"%s","description":"%s","private":%s,"default_branch":"%s"%s}' \
    "${PROJECT[name]}" "$description" "$private" "$DEFAULT_BRANCH" "$extra"
}

# settle_timed_out_create HOST LABEL: the create request got no answer, so the
# host may have made the repository anyway. Ask the host and go on only when
# the repository exists and holds nothing but what this script adds; the
# repository was free before the request, so it is the one this run made.
settle_timed_out_create() {
  local host="$1" label="$2" owner
  owner="$(repo_owner "$host")"
  warn "the request to create the $label timed out; asking $(host_label "$host") whether it exists"
  inspect_repository "$host"
  case "${STATE[${host}_repo]}" in
    free)
      die "the request to create the $label timed out and the repository $owner/${PROJECT[name]} does not exist: nothing was created on $(host_label "$host"); run the same command again"
      ;;
    empty) return 0 ;;
    initial_only)
      if [[ $host == gitea && -n ${PROJECT[license]} ]]; then
        return 0
      fi
      ;;
  esac
  die "the request to create the $label timed out and the repository $owner/${PROJECT[name]} exists with content that this run did not add; it was not touched"
}

# create_repository HOST: create the repository, or reuse the existing one.
create_repository() {
  local host="$1" label owner path
  label="$(host_label "$host") repository"
  owner="$(repo_owner "$host")"
  if is_reused "$host"; then
    finish_step "$label" "reused" "$(repo_url "$host")"
    return 0
  fi
  begin_step "$label"
  path="/user/repos"
  if [[ ${STATE[${host}_owner_kind]} == organization ]]; then
    path="/orgs/$owner/repos"
  fi
  if ! try_api_call "$host" POST "$path" "$(repo_body "$host")"; then
    # Only a timeout leaves the outcome open; any other failure ends the run.
    ((HTTP_CURL_STATUS == 28)) || die "$HTTP_ERROR"
    settle_timed_out_create "$host" "$label"
    finish_step "$label" "reused" "$(repo_url "$host")"
    return 0
  fi
  expect_status "cannot create the $label" 201
  finish_step "$label" "created" "$(repo_url "$host")"
}
