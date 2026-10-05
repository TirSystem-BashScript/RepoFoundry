#!/usr/bin/env bash
# lib.sh - tiny test helpers for the RepoFoundry tests (sourced, not run).
#
# Each test file defines functions named test_*; run-tests.sh calls them.
# The helpers run create-project.sh in separate bash processes with a private
# work directory and stub tools on PATH, so a test never touches the network,
# the real .env or the repository.
#
# Requires: bash 4.4 or later.

# shellcheck disable=SC2016,SC2034  # stub and snippet text is literal on purpose; OUT, ERR and STATUS are read by the test files
REPO_ROOT="$(cd "${BASH_SOURCE[0]%/*}/.." && pwd)"
readonly REPO_ROOT
readonly SCRIPT="$REPO_ROOT/create-project.sh"

# Distinctive fake credentials; the tests search all output for them.
readonly FAKE_GITEA_TOKEN="giteaFAKEtoken1234567890"
readonly FAKE_GITHUB_PAT="ghpFAKEtoken1234567890"

TESTS_RUN=0
TESTS_FAILED=0
CURRENT_TEST=""
WORK=""
OUT=""
ERR=""
STATUS=0

fail() {
  TESTS_FAILED=$((TESTS_FAILED + 1))
  printf 'FAIL %s: %s\n' "$CURRENT_TEST" "$1"
}

check() {
  TESTS_RUN=$((TESTS_RUN + 1))
}

assert_eq() {
  check
  if [[ $2 != "$3" ]]; then
    fail "$1: expected '$2', got '$3'"
  fi
}

assert_status() {
  assert_eq "$1 (exit status)" "$2" "$3"
}

assert_contains() {
  check
  if [[ $2 != *"$3"* ]]; then
    fail "$1: output does not contain '$3'"
  fi
}

assert_not_contains() {
  check
  if [[ $2 == *"$3"* ]]; then
    fail "$1: output contains '$3' but must not"
  fi
}

assert_file_exists() {
  check
  if [[ ! -e $2 ]]; then
    fail "$1: '$2' does not exist"
  fi
}

assert_file_missing() {
  check
  if [[ -e $2 ]]; then
    fail "$1: '$2' exists but must not"
  fi
}

# new_workdir: create a private work directory with a stub bin directory.
new_workdir() {
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/repofoundry-test.XXXXXX")"
  mkdir -p "$WORK/bin" "$WORK/tmp"
}

# remove_workdir: delete the work directory without a recursive rm: files
# first, then the now empty directories from the bottom up.
remove_workdir() {
  if [[ -n $WORK && -d $WORK ]]; then
    find "$WORK" -type f -delete
    find "$WORK" -depth -type d -exec rmdir {} +
  fi
  WORK=""
}

# write_fixtures: valid config.env and .env in the work directory.
write_fixtures() {
  cat >"$WORK/config.env" <<EOF
# test configuration
GITHUB_API_URL=https://api.github.com
GITHUB_WEB_URL=https://github.com
GITEA_URL=https://git.example.test/
GITEA_API_URL=https://git.example.test/api/v1
EOF
  cat >"$WORK/.env" <<EOF
GITHUB_PAT=$FAKE_GITHUB_PAT
GITHUB_USER=octo-user
GITEA_TOKEN=$FAKE_GITEA_TOKEN
EOF
}

# write_stub NAME BODY: install an executable stub tool in the work bin.
write_stub() {
  printf '#!/usr/bin/env bash\n%s\n' "$2" >"$WORK/bin/$1"
  chmod +x "$WORK/bin/$1"
}

# write_curl_stub: a curl that records its arguments and configuration and
# answers with STUB_CURL_STATUS (default 200) and body STUB_CURL_BODY.
write_curl_stub() {
  write_stub curl '
printf "%s\n" "$@" >>"$STUB_DIR/curl.args"
out="" cfg=""
while (($# > 0)); do
  case "$1" in
    --output) out="$2"; shift 2 ;;
    --config) cfg="$2"; shift 2 ;;
    *) shift ;;
  esac
done
if [[ -n $cfg ]]; then cat "$cfg" >>"$STUB_DIR/curl.config"; fi
body="${STUB_CURL_BODY:-}"
if [[ -z $body ]]; then body="{\"ok\":true}"; fi
if [[ -n $out ]]; then printf "%s" "$body" >"$out"; fi
printf "%s" "${STUB_CURL_STATUS:-200}"
exit "${STUB_CURL_EXIT:-0}"'
}

# run_cli STDIN ARGS...: run create-project.sh with answers from STDIN (a
# string). Sets OUT, ERR and STATUS.
run_cli() {
  local input="$1"
  shift
  STATUS=0
  PATH="$WORK/bin:$PATH" STUB_DIR="$WORK" TMPDIR="$WORK/tmp" \
    "$BASH" "$SCRIPT" "$@" <<<"$input" >"$WORK/out.txt" 2>"$WORK/err.txt" ||
    STATUS=$?
  OUT="$(cat "$WORK/out.txt")"
  ERR="$(cat "$WORK/err.txt")"
}

# run_lib INPUT CODE: source create-project.sh and run CODE in a fresh bash,
# so that single functions can be tested. Sets OUT, ERR and STATUS.
run_lib() {
  local input="$1"
  STATUS=0
  {
    printf '#!/usr/bin/env bash\nsource "%s"\n' "$SCRIPT"
    printf '%s\n' "$2"
  } >"$WORK/snippet.sh"
  PATH="$WORK/bin:$PATH" STUB_DIR="$WORK" TMPDIR="$WORK/tmp" \
    "$BASH" "$WORK/snippet.sh" <<<"$input" >"$WORK/out.txt" 2>"$WORK/err.txt" ||
    STATUS=$?
  OUT="$(cat "$WORK/out.txt")"
  ERR="$(cat "$WORK/err.txt")"
}
