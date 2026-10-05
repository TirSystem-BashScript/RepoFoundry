# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# git.sh - Running git for the new project: no prompts, no token on a command line.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: git_project, fetch_origin

# git_project DIR ARGS...: run git in DIR. Prompts are switched off and stdin
# is closed (git must not eat the answers meant for later prompts), so a
# missing credential or SSH key fails at once instead of waiting for input.
git_project() {
  local dir="$1"
  shift
  GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -o BatchMode=yes" \
    git -C "$dir" "$@" </dev/null
}

# fetch_origin DIR: fetch the Gitea repository into the project. Over SSH the
# user's key is used. Over HTTPS the token reaches git through a private
# GIT_ASKPASS helper and the environment of this one command: it is never part
# of a URL, of the remote configuration or of a command line.
fetch_origin() {
  local dir="$1" url askpass
  url="$(git_project "$dir" config --get remote.origin.url)"
  if [[ $url != https://* ]]; then
    git_project "$dir" fetch -q origin
    return
  fi
  make_temp_file
  askpass="$REPLY"
  # shellcheck disable=SC2016  # the helper is written out literally: it expands $1 and its environment itself
  {
    printf '%s\n' '#!/usr/bin/env bash'
    printf '%s\n' 'case "$1" in'
    printf '%s\n' '  *sername*) printf "%s\n" "$REPOFOUNDRY_ASKPASS_USER" ;;'
    printf '%s\n' '  *) printf "%s\n" "$REPOFOUNDRY_ASKPASS_TOKEN" ;;'
    printf '%s\n' 'esac'
  } >"$askpass"
  chmod 700 "$askpass"
  # Not "cmd; rm": a failed fetch must still be reported to the caller.
  if ! GIT_ASKPASS="$askpass" REPOFOUNDRY_ASKPASS_USER="${STATE[gitea_login]}" \
    REPOFOUNDRY_ASKPASS_TOKEN="${CREDENTIALS[GITEA_TOKEN]}" \
    git_project "$dir" fetch -q origin; then
    rm -f -- "$askpass"
    return 1
  fi
  rm -f -- "$askpass"
}
