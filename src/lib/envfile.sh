# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# envfile.sh - The .env file of the new project: the one place a credential is written.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: env_file_keys, env_file_key_list, exclude_env_file, write_env_file, create_env_file

# env_file_keys: the credentials the new project needs, one per line: the
# Gitea token, and the GitHub token and account name when GitHub was chosen.
env_file_keys() {
  printf '%s\n' GITEA_TOKEN
  if ((PROJECT[has_github])); then
    printf '%s\n' GITHUB_PAT GITHUB_USER
  fi
}

# env_file_key_list: the same keys on one line, for messages.
env_file_key_list() {
  local keys
  keys="$(env_file_keys | tr '\n' ' ')"
  printf '%s' "${keys% }"
}

# exclude_env_file DIR: make git ignore .env in DIR without touching a tracked
# file: the entry goes into .git/info/exclude, which is never committed. It
# does nothing when .env is already ignored.
exclude_env_file() {
  local dir="$1" gitdir exclude
  if git_project "$dir" check-ignore -q -- "$ENV_FILE_NAME"; then
    return 0
  fi
  gitdir="$(git_project "$dir" rev-parse --absolute-git-dir)"
  exclude="$gitdir/info/exclude"
  mkdir -p -- "$gitdir/info"
  # Start on a fresh line when the file does not end with one.
  if [[ -s $exclude && -n "$(tail -c 1 -- "$exclude")" ]]; then
    printf '\n' >>"$exclude"
  fi
  printf '%s\n' "# RepoFoundry: the credentials file of this project" "$ENV_FILE_NAME" >>"$exclude"
  git_project "$dir" check-ignore -q -- "$ENV_FILE_NAME" ||
    die "could not make git ignore $ENV_FILE_NAME in $dir; nothing was written to it"
}

# write_env_file DIR IS_REPLACE: write the credentials to DIR/.env. The file is
# created private (mode 600) from the start, never readable by others, even
# for a moment: it is written under umask 077 as a temporary file next to the
# target and moved into place. An existing file is only replaced when
# IS_REPLACE is 1, and a file that appears in the meantime is never replaced.
write_env_file() {
  local dir="$1" is_replace="$2" target tmp key
  target="$dir/$ENV_FILE_NAME"
  tmp="$(umask 077 && mktemp "$dir/$ENV_FILE_NAME.XXXXXX")"
  TEMP_FILES+=("$tmp")
  {
    while IFS= read -r key; do
      printf '%s=%s\n' "$key" "${CREDENTIALS[$key]}"
    done < <(env_file_keys)
  } >"$tmp"
  if ((is_replace)); then
    mv -f -- "$tmp" "$target"
  else
    mv -n -- "$tmp" "$target"
    if [[ -e $tmp ]]; then
      die "$target appeared while it was being written; it was not replaced"
    fi
  fi
}

# create_env_file: the last step. Only after a yes (default no) is the .env
# written, and an existing one is only replaced after another yes. Nothing
# printed names a value, only the keys.
create_env_file() {
  local label="Project .env" dir="${PROJECT[directory]}" keys is_replace=0
  keys="$(env_file_key_list)"
  begin_step "$label"
  prompt_yes_no "Create a $ENV_FILE_NAME file in the project with the credentials it needs ($keys); only you can read it and git ignores it" n
  if ! ((REPLY)); then
    finish_step "$label" "skipped" "(you declined)"
    return 0
  fi
  if git_project "$dir" ls-files --error-unmatch -- "$ENV_FILE_NAME" >/dev/null 2>&1; then
    finish_step "$label" "skipped" "($ENV_FILE_NAME is tracked by git; it was not written)"
    return 0
  fi
  if [[ -e $dir/$ENV_FILE_NAME || -L $dir/$ENV_FILE_NAME ]]; then
    prompt_yes_no "$ENV_FILE_NAME already exists in the project. Replace it" n
    if ! ((REPLY)); then
      finish_step "$label" "kept" "(the existing $ENV_FILE_NAME was left as it was)"
      return 0
    fi
    is_replace=1
  fi
  exclude_env_file "$dir"
  write_env_file "$dir" "$is_replace"
  finish_step "$label" "created" "($keys; only you can read it, git ignores it)"
}
