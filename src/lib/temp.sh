# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# temp.sh - Private temporary files and their cleanup (never a recursive delete).
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: cleanup, setup_temp_dir, make_temp_file

# Files are removed one by one and the directory with rmdir: a recursive
# delete is never needed and never used.
cleanup() {
  local file
  for file in "${TEMP_FILES[@]}"; do
    rm -f -- "$file"
  done
  if [[ -n $TMP_DIR && -d $TMP_DIR ]]; then
    # rmdir fails only if something unexpected is left inside; leave it
    # rather than delete files this script did not create.
    rmdir -- "$TMP_DIR" 2>/dev/null || true
  fi
}

setup_temp_dir() {
  TMP_DIR="$(umask 077 && mktemp -d "${TMPDIR:-/tmp}/repofoundry.XXXXXX")"
}

# make_temp_file: create a private file in TMP_DIR and return it in REPLY.
make_temp_file() {
  REPLY="$(umask 077 && mktemp "$TMP_DIR/file.XXXXXX")"
  TEMP_FILES+=("$REPLY")
}
