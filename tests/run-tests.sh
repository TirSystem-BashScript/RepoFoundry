#!/usr/bin/env bash
# run-tests.sh - run the RepoFoundry checks: bash -n, shellcheck, shfmt (when
# installed) and every test_* function in tests/test-*.sh.
#
# Usage
#   tests/run-tests.sh [NAME-PATTERN]   run only tests whose name matches
#
# Everything runs in private work directories with stub tools: no network,
# no real .env and no change to the repository.
#
# Requires: bash 4.4 or later, git; shellcheck and shfmt are used if present.
#
# Exit codes: 0 all checks passed, 1 a check failed.
set -Eeuo pipefail

TEST_DIR="$(cd "${BASH_SOURCE[0]%/*}" && pwd)"
readonly TEST_DIR
# shellcheck source=tests/lib.sh
source "$TEST_DIR/lib.sh"

pattern="${1:-}"
failed_checks=0

run_static_checks() {
  printf '== static checks\n'
  bash -n "$SCRIPT" || failed_checks=$((failed_checks + 1))
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "$SCRIPT" "$TEST_DIR"/*.sh ||
      failed_checks=$((failed_checks + 1))
  else
    printf 'skipped: shellcheck is not installed\n'
  fi
  if command -v shfmt >/dev/null 2>&1; then
    shfmt -i 2 -ci -d "$SCRIPT" "$TEST_DIR"/*.sh ||
      failed_checks=$((failed_checks + 1))
  else
    printf 'skipped: shfmt is not installed\n'
  fi
}

run_test_file() {
  local file="$1" name
  # shellcheck source=/dev/null
  source "$file"
  while read -r name; do
    if [[ -n $pattern && $name != *"$pattern"* ]]; then
      continue
    fi
    CURRENT_TEST="$name"
    new_workdir
    "$name" || fail "the test stopped with an error"
    remove_workdir
  done < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
}

run_static_checks
for test_file in "$TEST_DIR"/test-*.sh; do
  printf '== %s\n' "${test_file##*/}"
  run_test_file "$test_file"
  # Forget this file's tests so the next file starts clean.
  while read -r name; do
    unset -f "$name"
  done < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
done

printf '\n%d checks, %d failed, %d static check(s) failed\n' \
  "$TESTS_RUN" "$TESTS_FAILED" "$failed_checks"
if ((TESTS_FAILED > 0 || failed_checks > 0)); then
  exit 1
fi
