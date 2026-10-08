# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# git.sh - Running git for the new project: no prompts, no token on a command line.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: git_project, exclude_from_git, fetch_origin

# git_project DIR ARGS...: run git in DIR. Prompts are switched off and stdin
# is closed (git must not eat the answers meant for later prompts), so a
# missing credential or SSH key fails at once instead of waiting for input.
git_project() {
  local dir="$1"
  shift
  GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -o BatchMode=yes" \
    git -C "$dir" "$@" </dev/null
}

# exclude_from_git DIR COMMENT ENTRY...: make git ignore each ENTRY in DIR
# without touching a tracked file: the entries go into .git/info/exclude,
# which is never committed. An entry that already takes effect (checked by its
# pattern, so a tracked path counts) is left out, and with none left nothing
# is written. The comment line goes above the entries that are written. The
# number of entries written is left in REPLY; the return status is 1 when an
# entry still does not take effect afterwards.
exclude_from_git() {
  local dir="$1" comment="$2" gitdir exclude entry path missing=()
  shift 2
  for entry in "$@"; do
    path="${entry#/}"
    if ! git_project "$dir" check-ignore --no-index -q -- "${path%/}"; then
      missing+=("$entry")
    fi
  done
  REPLY="${#missing[@]}"
  if ((REPLY == 0)); then
    return 0
  fi
  gitdir="$(git_project "$dir" rev-parse --absolute-git-dir)"
  exclude="$gitdir/info/exclude"
  mkdir -p -- "$gitdir/info"
  # Start on a fresh line when the file does not end with one.
  if [[ -s $exclude && -n "$(tail -c 1 -- "$exclude")" ]]; then
    printf '\n' >>"$exclude"
  fi
  printf '%s\n' "# $comment" "${missing[@]}" >>"$exclude"
  for entry in "${missing[@]}"; do
    path="${entry#/}"
    git_project "$dir" check-ignore --no-index -q -- "${path%/}" || return 1
  done
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
