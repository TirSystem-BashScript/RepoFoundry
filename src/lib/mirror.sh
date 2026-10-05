# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# mirror.sh - The Gitea to GitHub push mirror: create, verify, first sync.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: mirror_field, mirror_path, mirror_address, mirror_exists, create_mirror, verify_mirror, request_first_sync, configure_mirror

# mirror_field FILE ADDRESS FIELD: print FIELD of the push mirror whose
# remote_address is ADDRESS. Without jq the first mirror in the list is used,
# which is the only one on a repository this script has just created.
mirror_field() {
  local file="$1" address="$2" field="$3"
  if ((HAS_JQ)); then
    jq -r --arg address "$address" --arg field "$field" \
      '[.[] | select(.remote_address == $address)][0]
       | if . == null or .[$field] == null then empty else .[$field] | tostring end' \
      "$file" | tr -d '\r'
  else
    json_get "$file" "$field"
  fi
}

mirror_path() {
  printf '/repos/%s/%s/push_mirrors' "${PROJECT[gitea_owner]}" "${PROJECT[name]}"
}

mirror_address() {
  printf '%s/%s/%s.git' "${CONFIG[GITHUB_WEB_URL]}" "${PROJECT[github_owner]}" "${PROJECT[name]}"
}

# mirror_exists ADDRESS: succeed if Gitea already pushes to ADDRESS.
mirror_exists() {
  api_call gitea GET "$(mirror_path)"
  expect_status "cannot list the push mirrors of the Gitea repository" 200
  json_has_value "$HTTP_BODY_FILE" remote_address "$1"
}

create_mirror() {
  local address="$1" body
  # The GitHub token is the password of the mirror; the body file that holds
  # it is removed as soon as the request has been sent.
  body="$(printf '{"remote_address":"%s","remote_username":"%s","remote_password":"%s","interval":"%s","sync_on_commit":true}' \
    "$address" "${STATE[github_login]}" "${CREDENTIALS[GITHUB_PAT]}" \
    "${CONFIG[MIRROR_INTERVAL]}")"
  api_call gitea POST "$(mirror_path)" "$body"
  expect_status "cannot create the push mirror (push mirrors may be switched off on the Gitea server, the interval may be shorter than the server allows, or the GitHub token may not push to the new repository)" 200 201
}

# verify_mirror ADDRESS: read the mirror back and report what Gitea applied.
verify_mirror() {
  local address="$1" on_commit
  api_call gitea GET "$(mirror_path)"
  expect_status "cannot read the push mirror back from Gitea" 200
  json_has_value "$HTTP_BODY_FILE" remote_address "$address" ||
    die "Gitea did not list the push mirror after creating it"
  on_commit="$(mirror_field "$HTTP_BODY_FILE" "$address" sync_on_commit)"
  if [[ $on_commit != true ]]; then
    warn "Gitea did not apply sync_on_commit (a known server issue): the mirror syncs every ${CONFIG[MIRROR_INTERVAL]}, not on every commit. Switch it on in the repository settings if you need it."
    STEP_DETAIL["Push mirror"]="(syncs every ${CONFIG[MIRROR_INTERVAL]}, not on every commit)"
  fi
}

# request_first_sync ADDRESS: ask Gitea for a first push and report an error
# it records. A failure here is a warning: the mirror retries by itself.
request_first_sync() {
  local address="$1" last_error
  api_call gitea POST "$(mirror_path)-sync"
  if [[ $HTTP_STATUS != 200 && $HTTP_STATUS != 204 ]]; then
    warn "could not ask Gitea for the first sync (HTTP $HTTP_STATUS); it runs at the next interval"
    return 0
  fi
  sleep "${REPOFOUNDRY_SYNC_WAIT:-3}"
  api_call gitea GET "$(mirror_path)"
  if [[ $HTTP_STATUS == 200 ]]; then
    last_error="$(mirror_field "$HTTP_BODY_FILE" "$address" last_error)"
    if [[ -n $last_error ]]; then
      warn "the first mirror sync reported: ${last_error:0:200}"
    fi
  fi
}

configure_mirror() {
  local label="Push mirror" address
  address="$(mirror_address)"
  begin_step "$label"
  if mirror_exists "$address"; then
    finish_step "$label" "reused" "Gitea -> $address"
  else
    create_mirror "$address"
    finish_step "$label" "created" "Gitea -> $address"
    verify_mirror "$address"
  fi
  request_first_sync "$address"
}
