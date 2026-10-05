# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# repositories.sh - Creating the GitHub and Gitea repositories.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: repo_body, create_repository

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
  if ((PROJECT[has_github])); then
    extra=',"auto_init":true,"license":"'"$AGPL_LICENSE_KEY"'"'
  else
    extra=',"auto_init":false'
  fi
  printf '{"name":"%s","description":"%s","private":%s,"default_branch":"%s"%s}' \
    "${PROJECT[name]}" "$description" "$private" "$DEFAULT_BRANCH" "$extra"
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
  api_call "$host" POST "$path" "$(repo_body "$host")"
  expect_status "cannot create the $label" 201
  finish_step "$label" "created" "$(repo_url "$host")"
}
