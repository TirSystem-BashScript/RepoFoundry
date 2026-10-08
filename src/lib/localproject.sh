# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# localproject.sh - The local project: its directory, its git repository and its remotes.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: inspect_local_directory, confirm_local_directory, ensure_remote, checkout_gitea_history, create_local_project

# inspect_local_directory: record in STATE[local_dir] whether the project
# directory is missing, empty or not_empty. It creates nothing.
inspect_local_directory() {
  local dir="${PROJECT[directory]}"
  if [[ ! -e $dir ]]; then
    STATE[local_dir]="missing"
  elif [[ ! -d $dir ]]; then
    die "$dir already exists and is not a directory"
  elif [[ -z "$(find "$dir" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    STATE[local_dir]="empty"
  else
    STATE[local_dir]="not_empty"
  fi
}

# confirm_local_directory: an existing directory is only used after a yes.
confirm_local_directory() {
  local dir="${PROJECT[directory]}" what="is empty"
  if [[ ${STATE[local_dir]} == missing ]]; then
    return 0
  fi
  if [[ ${STATE[local_dir]} == not_empty ]]; then
    what="already has files"
  fi
  prompt_yes_no "The directory $dir already exists and $what. Use it" n
  if ! ((REPLY)); then
    die "stopped: choose another directory or remove this one"
  fi
}

# ensure_remote DIR NAME URL: add the remote, or accept one that already has
# exactly this address. A different address is never overwritten.
ensure_remote() {
  local dir="$1" name="$2" url="$3" existing
  # git config exits 1 when the remote is not set; that is the normal case.
  existing="$(git_project "$dir" config --get "remote.$name.url" || true)"
  if [[ -z $existing ]]; then
    git_project "$dir" remote add "$name" "$url"
  elif [[ $existing != "$url" ]]; then
    die "the remote '$name' in $dir already points to $existing; remove it or choose another directory"
  fi
}

# checkout_gitea_history DIR: when the Gitea repository holds the license
# commit, fetch it and start the local branch from it, so the local history
# begins with that commit. Existing files are never overwritten: git refuses.
checkout_gitea_history() {
  local dir="$1" err
  if ! fetch_origin "$dir" 2>/dev/null; then
    die "could not fetch the Gitea repository from $(origin_url); check your SSH key (or, over HTTPS, the token) and run the same command again"
  fi
  if ! git_project "$dir" rev-parse --verify -q refs/remotes/origin/main >/dev/null; then
    return 0
  fi
  if git_project "$dir" rev-parse --verify -q HEAD >/dev/null 2>&1; then
    warn "$dir already has history: the Gitea content was fetched but not checked out"
    return 0
  fi
  make_temp_file
  err="$REPLY"
  if ! git_project "$dir" checkout -q -b main --track origin/main 2>"$err"; then
    die "git would overwrite files in $dir with the Gitea content; move them away and run again. Git said: $(head -n 2 "$err" | tr '\n' ' ')"
  fi
}

# create_local_project: the directory, the git repository on main, the origin
# remote and, when a license applies, the license history. No commit is made.
# Gitea is the only remote: a push to it reaches GitHub through the push
# mirror, so no github remote is added (and none that exists is removed).
create_local_project() {
  local label="Local project" dir="${PROJECT[directory]}"
  begin_step "$label"
  mkdir -p -- "$dir"
  if [[ ! -e $dir/.git ]]; then
    git_project "$dir" init -q
    git_project "$dir" symbolic-ref HEAD "refs/heads/$DEFAULT_BRANCH"
  fi
  ensure_remote "$dir" origin "$(origin_url)"
  if [[ -n ${PROJECT[license]} ]]; then
    checkout_gitea_history "$dir"
  fi
  finish_step "$label" "created" "$dir (origin over $(origin_protocol))"
}
