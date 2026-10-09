#!/usr/bin/env bash
# test-security.sh - end-to-end tests: no token in any output, no network
# call, no change on disk, clean temporary files, safe failure paths
# (MIL-001 Go/No-Go criteria 2 to 4). Sourced by run-tests.sh.

# shellcheck disable=SC2016  # snippet and fixture text is literal on purpose

# listing: all files under the work directory except the test's own captures.
listing() {
  find "$WORK" -type f ! -name out.txt ! -name err.txt ! -name snippet.sh \
    ! -name 'curl.*' ! -name 'routes*' ! -name 'ssh.args' | sort
}

test_full_run_with_github() {
  setup_hosts
  local before after
  before="$(listing)"
  run_cli "$ANSWERS_GITHUB" --config "$WORK/config.env" --env "$WORK/.env"
  after="$(listing)"
  assert_status "full run" 0 "$STATUS"
  assert_contains "dry run" "$OUT" "Dry run: nothing was created"
  assert_contains "plan" "$OUT" "create (private), empty"
  assert_contains "Gitea link derived from config" "$OUT" "https://git.example.test/TirSystem/my-app"
  assert_contains "GitHub link uses the chosen organization" "$OUT" "https://github.com/acme-org/my-app"
  assert_contains "no default license for a private project" "$OUT" "License      : none (no default for a private project)"
  assert_contains "credential state" "$OUT" "GITEA_TOKEN set, GITHUB_PAT set"
  assert_not_contains "no Gitea token in output" "$OUT$ERR" "$FAKE_GITEA_TOKEN"
  assert_not_contains "no GitHub token in output" "$OUT$ERR" "$FAKE_GITHUB_PAT"
  assert_contains "reads from Gitea" "$(calls)" "GET https://git.example.test/api/v1/user"
  assert_contains "reads from GitHub" "$(calls)" "GET https://api.github.com/user"
  assert_not_contains "a dry run only reads" "$(calls)" "POST"
  assert_not_contains "a dry run never deletes" "$(calls)" "DELETE"
  assert_eq "no file created or changed" "$before" "$after"
  assert_eq "temporary files removed" "" "$(find "$WORK/tmp" -mindepth 1)"
}

test_full_run_without_github() {
  setup_hosts
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$WORK/.env"
  run_cli "$ANSWERS_GITEA_ONLY" --config "$WORK/config.env" --env "$WORK/.env"
  assert_status "Gitea-only run needs no GitHub credentials" 0 "$STATUS"
  assert_contains "GitHub not used" "$OUT" "GitHub       : not used"
  assert_not_contains "no AGPL line" "$OUT" "AGPL"
  assert_contains "GITHUB_PAT not set" "$OUT" "GITHUB_PAT not set"
  assert_not_contains "no call to GitHub" "$(calls)" "api.github.com"
  assert_not_contains "no license lookup without GitHub" "$(calls)" "/licenses"
  assert_contains "plan says GitHub is not used" "$OUT" "GitHub repository : not used"
}

test_github_chosen_without_credentials_stops_when_input_ends() {
  write_fixtures
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$WORK/.env"
  run_cli "$ANSWERS_GITHUB" --config "$WORK/config.env" --env "$WORK/.env"
  assert_status "missing GitHub credentials, no answer" 1 "$STATUS"
  assert_contains "names the credential" "$ERR" "no input available for 'GitHub personal access token'"
  assert_not_contains "no token in the error" "$OUT$ERR" "$FAKE_GITEA_TOKEN"
  assert_eq "temporary files removed" "" "$(find "$WORK/tmp" -mindepth 1)"
}

test_error_messages_never_contain_the_value() {
  write_fixtures
  printf 'GITEA_TOKEN=S3CR3T\nGITHUB_PAT=%s\n' "$FAKE_GITHUB_PAT" >"$WORK/.env"
  run_cli "" --config "$WORK/config.env" --env "$WORK/.env"
  assert_status "invalid token" 1 "$STATUS"
  assert_contains "says what is wrong" "$ERR" "GITEA_TOKEN"
  assert_not_contains "invalid value not echoed" "$OUT$ERR" "S3CR3T"
  assert_not_contains "valid PAT not echoed" "$OUT$ERR" "$FAKE_GITHUB_PAT"
  printf 'this line holds %s as text\n' "$FAKE_GITEA_TOKEN" >"$WORK/.env"
  run_cli "" --config "$WORK/config.env" --env "$WORK/.env"
  assert_status "malformed line" 1 "$STATUS"
  assert_not_contains "malformed line not echoed" "$OUT$ERR" "$FAKE_GITEA_TOKEN"
}

test_unknown_credential_key_in_config_is_rejected() {
  write_fixtures
  printf 'GITEA_URL=https://git.example.test\nGITHUB_PAT=%s\n' "$FAKE_GITHUB_PAT" >"$WORK/config.env"
  run_cli "" --config "$WORK/config.env" --env "$WORK/.env"
  assert_status "credential in config.env" 1 "$STATUS"
  assert_contains "explains" "$ERR" "keep it in the .env file only"
  assert_not_contains "token not echoed" "$OUT$ERR" "$FAKE_GITHUB_PAT"
}

test_redaction() {
  run_lib "" "SECRET_VALUES=('$FAKE_GITEA_TOKEN')
say 'token is $FAKE_GITEA_TOKEN here'
warn 'also $FAKE_GITEA_TOKEN'
die 'and $FAKE_GITEA_TOKEN'"
  assert_status "die exits 1" 1 "$STATUS"
  assert_eq "say redacts" "token is [redacted] here" "$OUT"
  assert_not_contains "stderr redacted" "$ERR" "$FAKE_GITEA_TOKEN"
  assert_contains "die message" "$ERR" "error: and [redacted]"
}

test_usage_errors() {
  run_cli "" --bogus
  assert_status "unknown option" 2 "$STATUS"
  assert_contains "says so" "$ERR" "unknown option: --bogus"
  run_cli "" --config
  assert_status "option without value" 2 "$STATUS"
  run_cli "" --help
  assert_status "help" 0 "$STATUS"
  assert_contains "help shows usage" "$OUT" "Usage"
  assert_contains "help shows exit codes" "$OUT" "Exit codes"
  run_cli "" --version
  assert_status "version" 0 "$STATUS"
  assert_contains "version output" "$OUT" "RepoFoundry 0.3.3"
}

test_warns_when_env_is_not_ignored_by_git() {
  setup_hosts
  git init -q "$WORK/repo"
  cp "$WORK/.env" "$WORK/repo/.env"
  cp "$WORK/config.env" "$WORK/repo/config.env"
  run_cli "$ANSWERS_GITEA_ONLY" --config "$WORK/repo/config.env" --env "$WORK/repo/.env"
  assert_status "still runs" 0 "$STATUS"
  assert_contains "warns" "$ERR" "is not ignored by git"
  assert_not_contains "no token in the warning" "$ERR" "$FAKE_GITEA_TOKEN"
  find "$WORK/repo" -type f -delete
  find "$WORK/repo" -depth -type d -exec rmdir {} +
}

test_script_uses_no_unsafe_constructs() {
  local code
  code="$(cat "$SCRIPT" "$SRC_DIR"/lib/*.sh | grep -vE '^[[:space:]]*#')"
  assert_not_contains "no rm -rf" "$code" "rm -rf"
  assert_not_contains "no rm -r" "$code" "rm -r "
  assert_not_contains "no eval" "$code" "eval "
  assert_not_contains "no dot-source" "$code" $'\n. '
  # Only the script's own library files are sourced, by a fixed path; a
  # configuration file never is.
  local line
  while IFS= read -r line; do
    check
    if [[ $line != 'source "$SCRIPT_DIR/lib/'*'.sh"' ]]; then
      fail "unexpected source line: $line"
    fi
  done < <(grep -hE '(^|[[:space:];])source ' <<<"$code")
  check
  if grep -Eq '^[[:space:]]*set -[A-Za-z]*x' <<<"$code"; then
    fail "the script turns tracing on"
  fi
  assert_not_contains "no fixed /tmp file" "$code" "/tmp/file"
}

test_tracing_does_not_leak_secrets() {
  # bash -x would print every assignment and command, secrets included, so
  # the script switches tracing off and says so.
  setup_hosts
  STATUS=0
  PATH="$WORK/bin:$PATH" STUB_DIR="$WORK" TMPDIR="$WORK/tmp" "$BASH" -x "$SCRIPT" \
    --config "$WORK/config.env" --env "$WORK/.env" <<<"$ANSWERS_GITHUB" \
    >"$WORK/out.txt" 2>"$WORK/err.txt" || STATUS=$?
  assert_status "run under bash -x" 0 "$STATUS"
  assert_contains "tracing disabled" "$(cat "$WORK/err.txt")" "tracing (set -x) is disabled"
  assert_not_contains "no Gitea token in the trace" "$(cat "$WORK/err.txt" "$WORK/out.txt")" "$FAKE_GITEA_TOKEN"
  assert_not_contains "no GitHub token in the trace" "$(cat "$WORK/err.txt" "$WORK/out.txt")" "$FAKE_GITHUB_PAT"
}

test_byte_order_mark_is_accepted() {
  printf '\xef\xbb\xbfGITEA_URL=https://a.test\nGITHUB_WEB_URL=https://b.test\n' >"$WORK/c.env"
  run_lib "" "parse_env_file \"$WORK/c.env\" CONFIG_KEYS CONFIG
echo \"\${CONFIG[GITEA_URL]}\""
  assert_status "BOM on the first line" 0 "$STATUS"
  assert_eq "first key read" "https://a.test" "$OUT"
}

test_termination_removes_temp_files() {
  write_fixtures
  if ! mkfifo "$WORK/in" 2>/dev/null; then
    return 0
  fi
  PATH="$WORK/bin:$PATH" STUB_DIR="$WORK" TMPDIR="$WORK/tmp" "$BASH" "$SCRIPT" \
    --config "$WORK/config.env" --env "$WORK/.env" <"$WORK/in" \
    >/dev/null 2>&1 &
  local pid=$! tries=0
  # Keep the pipe open so the script waits at its first prompt.
  exec 7>"$WORK/in"
  while [[ -z "$(find "$WORK/tmp" -mindepth 1)" ]] && ((tries < 50)); do
    sleep 0.1
    tries=$((tries + 1))
  done
  assert_eq "temp directory exists while running" 1 "$(find "$WORK/tmp" -mindepth 1 | wc -l | tr -d ' ')"
  kill -TERM "$pid"
  # wait returns the signal status (143); only the cleanup matters here.
  wait "$pid" 2>/dev/null || true
  exec 7>&-
  assert_eq "temp directory removed after SIGTERM" "" "$(find "$WORK/tmp" -mindepth 1)"
}

test_script_lives_in_src() {
  assert_file_exists "script in src/" "$REPO_ROOT/src/create-project.sh"
  assert_file_missing "no copy in the project root" "$REPO_ROOT/create-project.sh"
}

test_default_files_are_in_the_project_root() {
  # A project copy: script in src/, config.env and .env one level up.
  setup_hosts
  mkdir -p "$WORK/project/src"
  cp "$SCRIPT" "$WORK/project/src/create-project.sh"
  cp -R "$SRC_DIR/lib" "$WORK/project/src/lib"
  cp "$WORK/config.env" "$WORK/project/config.env"
  cp "$WORK/.env" "$WORK/project/.env"
  STATUS=0
  (cd "$WORK/project" && PATH="$WORK/bin:$PATH" STUB_DIR="$WORK" TMPDIR="$WORK/tmp" "$BASH" "$WORK/project/src/create-project.sh" \
    <<<"$ANSWERS_GITHUB" >"$WORK/out.txt" 2>"$WORK/err.txt") || STATUS=$?
  assert_status "run with the default files" 0 "$STATUS"
  assert_contains "found config.env in the project root" "$(cat "$WORK/out.txt")" "https://git.example.test/TirSystem/my-app"
  # Run from another folder that holds no files of its own: the checkout's
  # files are used; the defaults follow the script, not the current folder.
  mkdir -p "$WORK/elsewhere"
  STATUS=0
  (cd "$WORK/elsewhere" && PATH="$WORK/bin:$PATH" STUB_DIR="$WORK" TMPDIR="$WORK/tmp" "$BASH" "$WORK/project/src/create-project.sh" \
    <<<"$ANSWERS_GITEA_ONLY" >"$WORK/out.txt" 2>"$WORK/err.txt") || STATUS=$?
  assert_status "run from another directory" 0 "$STATUS"
}
