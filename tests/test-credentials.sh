#!/usr/bin/env bash
# test-credentials.sh - tests for the credentials that .env does not provide
# and for the .env file of the new project (MIL-005): they are asked without
# echo, the project .env is only written after a yes, owner-only and ignored
# by git, and no token appears anywhere else. Sourced by run-tests.sh.

# shellcheck disable=SC2016  # snippet and fixture text is literal on purpose

readonly NL=$'\n'

# credentials_input: the answers of a run with no .env at all and GitHub
# chosen: the Gitea token, the details, then the GitHub token and account.
credentials_input() {
  printf '%s' "$FAKE_GITEA_TOKEN$NL$ANSWERS_GITHUB$FAKE_GITHUB_PAT${NL}octo-user$NL"
}

run_dry_cred() {
  run_cli "$1" --config "$WORK/config.env" --env "$WORK/.env"
}

run_apply_cred() {
  run_cli "$1" --apply --config "$WORK/config.env" --env "$WORK/.env"
}

# without_env: remove the .env of the fixtures.
without_env() {
  rm -f -- "$WORK/.env"
}

# env_mode FILE: the permission bits, empty where the platform has none.
env_mode() {
  case "$(uname -s 2>/dev/null || true)" in
    MINGW* | MSYS* | CYGWIN*) ;;
    *) stat -c '%a' -- "$1" 2>/dev/null || stat -f '%Lp' -- "$1" 2>/dev/null || true ;;
  esac
}

# ------------------------------------------------------------ prompt_secret

test_prompt_secret_asks_again_and_never_repeats_the_answer() {
  run_lib $'short\n\nlongenoughtoken1\n' \
    'prompt_secret "Gitea access token" is_valid_token "needs 8 characters"; echo "[$REPLY]"'
  assert_status "valid answer found" 0 "$STATUS"
  assert_eq "valid answer returned" "[longenoughtoken1]" "$OUT"
  assert_contains "told why" "$ERR" "invalid Gitea access token: needs 8 characters"
  assert_not_contains "refused answer not repeated" "$ERR" "short"
  assert_contains "says the input is hidden" "$ERR" "(input is hidden)"
}

test_prompt_secret_stops_when_input_ends() {
  run_lib "" 'prompt_secret "Gitea access token" is_valid_token "x" </dev/null'
  assert_status "end of input" 1 "$STATUS"
  assert_contains "message names the credential" "$ERR" "no input available for 'Gitea access token'"
}

# ------------------------------------------------------ collect_credentials

test_collect_credentials_asks_only_what_is_missing() {
  run_lib "$FAKE_GITHUB_PAT${NL}octo-user$NL" \
    'CREDENTIALS[GITEA_TOKEN]=giteaFAKEtoken1234567890
collect_credentials GITEA_TOKEN GITHUB_PAT GITHUB_USER
printf "%s|%s\n" "${CREDENTIALS[GITHUB_USER]}" "${#SECRET_VALUES[@]}"'
  assert_status "asked" 0 "$STATUS"
  assert_eq "account name kept, one secret registered" "octo-user|1" "$OUT"
  assert_contains "GitHub token asked" "$ERR" "GitHub personal access token"
  assert_contains "account asked" "$ERR" "GitHub account name"
  assert_not_contains "Gitea token not asked" "$ERR" "Gitea access token"
  assert_not_contains "no token shown" "$ERR$OUT" "$FAKE_GITHUB_PAT"
}

test_a_token_that_is_asked_is_registered_as_a_secret() {
  run_lib "$FAKE_GITEA_TOKEN$NL" \
    'collect_credentials GITEA_TOKEN
warn "the token is giteaFAKEtoken1234567890 here"'
  assert_status "asked" 0 "$STATUS"
  assert_not_contains "redacted in later messages" "$ERR" "$FAKE_GITEA_TOKEN"
}

test_an_empty_value_in_env_counts_as_not_provided() {
  printf 'GITEA_TOKEN=\nGITHUB_USER=\n' >"$WORK/e.env"
  run_lib "$FAKE_GITEA_TOKEN$NL" \
    'parse_env_file "'"$WORK"'/e.env" CREDENTIAL_KEYS CREDENTIALS
validate_credentials
collect_credentials GITEA_TOKEN
echo asked-ok'
  assert_status "empty value tolerated" 0 "$STATUS"
  assert_contains "asked instead" "$ERR" "Gitea access token"
}

test_validate_credentials_no_longer_requires_any() {
  printf '# nothing\n' >"$WORK/e.env"
  run_lib "" 'parse_env_file "'"$WORK"'/e.env" CREDENTIAL_KEYS CREDENTIALS
validate_credentials
echo fine'
  assert_status "no credential required" 0 "$STATUS"
  assert_eq "no error" "fine" "$OUT"
  printf 'GITEA_TOKEN=short\n' >"$WORK/e.env"
  run_lib "" 'parse_env_file "'"$WORK"'/e.env" CREDENTIAL_KEYS CREDENTIALS
validate_credentials'
  assert_status "a provided bad token is still refused" 1 "$STATUS"
  assert_contains "named" "$ERR" "GITEA_TOKEN"
}

# --------------------------------------------------------------- the run

test_env_is_optional_and_the_token_is_asked_without_echo() {
  setup_hosts
  without_env
  run_dry_cred "$FAKE_GITEA_TOKEN$NL$ANSWERS_GITEA_ONLY"
  assert_status "dry run without .env" 0 "$STATUS"
  assert_contains "token asked" "$ERR" "Gitea access token (input is hidden)"
  assert_contains "plan printed" "$OUT" "Plan:"
  assert_not_contains "token not shown" "$OUT$ERR" "$FAKE_GITEA_TOKEN"
  assert_not_contains "only reads" "$(calls)" "POST"
}

test_a_provided_credential_is_not_asked() {
  setup_hosts
  run_dry_cred "$ANSWERS_GITHUB"
  assert_status "all provided" 0 "$STATUS"
  assert_not_contains "no token prompt" "$ERR" "(input is hidden)"
  assert_not_contains "no account prompt" "$ERR" "GitHub account name"
}

test_github_credentials_are_asked_only_when_github_is_chosen() {
  setup_hosts
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$WORK/.env"
  run_dry_cred "$ANSWERS_GITEA_ONLY"
  assert_status "Gitea only" 0 "$STATUS"
  assert_not_contains "no GitHub token asked" "$ERR" "GitHub personal access token"
  assert_not_contains "no GitHub account asked" "$ERR" "GitHub account name"
  run_dry_cred "$ANSWERS_GITHUB$FAKE_GITHUB_PAT${NL}octo-user$NL"
  assert_status "GitHub chosen" 0 "$STATUS"
  assert_contains "GitHub token asked" "$ERR" "GitHub personal access token (input is hidden)"
  assert_contains "GitHub account asked" "$ERR" "GitHub account name"
  assert_not_contains "token not shown" "$OUT$ERR" "$FAKE_GITHUB_PAT"
}

test_an_invalid_asked_value_is_asked_again_and_never_shown() {
  setup_hosts
  without_env
  run_dry_cred "bad token${NL}$FAKE_GITEA_TOKEN$NL$ANSWERS_GITEA_ONLY"
  assert_status "second answer accepted" 0 "$STATUS"
  assert_contains "told it is invalid" "$ERR" "invalid Gitea access token"
  assert_not_contains "refused value not shown" "$ERR$OUT" "bad token"
}

test_input_that_ends_stops_before_any_request() {
  setup_hosts
  without_env
  run_dry_cred ""
  assert_status "stopped" 1 "$STATUS"
  assert_contains "key named" "$ERR" "no input available for 'Gitea access token'"
  assert_eq "no request made" "" "$(calls)"
  assert_not_contains "no creation report" "$OUT" "This is what exists now"
}

test_asked_tokens_do_not_leak_under_bash_x() {
  setup_hosts
  without_env
  STATUS=0
  PATH="$WORK/bin:$PATH" STUB_DIR="$WORK" TMPDIR="$WORK/tmp" "$BASH" -x "$SCRIPT" \
    --config "$WORK/config.env" --env "$WORK/.env" <<<"$(credentials_input)" \
    >"$WORK/out.txt" 2>"$WORK/err.txt" || STATUS=$?
  assert_status "run under bash -x" 0 "$STATUS"
  assert_not_contains "no Gitea token in the trace" "$(cat "$WORK/err.txt" "$WORK/out.txt")" "$FAKE_GITEA_TOKEN"
  assert_not_contains "no GitHub token in the trace" "$(cat "$WORK/err.txt" "$WORK/out.txt")" "$FAKE_GITHUB_PAT"
}

# ---------------------------------------------------------- the project .env

test_the_dry_run_names_the_env_step_and_writes_nothing() {
  setup_hosts
  run_dry_cred "$ANSWERS_GITHUB"
  assert_contains "plan line" "$OUT" "Project .env      : you are asked whether to create it (GITEA_TOKEN GITHUB_PAT GITHUB_USER)"
  assert_file_missing "no .env" "$WORK/my-app/.env"
}

test_the_project_env_is_not_created_without_a_yes() {
  setup_hosts
  run_apply_cred "${ANSWERS_GITHUB}y$NL$NL"
  assert_status "run" 0 "$STATUS"
  assert_file_missing "default is no" "$WORK/my-app/.env"
  assert_contains "reported" "$OUT" "Project .env      : skipped (you declined)"
  setup_hosts
  run_apply_cred "${ANSWERS_GITHUB}y${NL}n$NL"
  assert_file_missing "explicit no" "$WORK/my-app/.env"
}

test_the_project_env_holds_only_the_needed_keys_and_is_private() {
  setup_hosts
  run_apply_cred "${ANSWERS_GITHUB}y${NL}y$NL"
  assert_status "run" 0 "$STATUS"
  assert_file_exists ".env created" "$WORK/my-app/.env"
  assert_eq "exactly the needed keys" "GITEA_TOKEN=$FAKE_GITEA_TOKEN${NL}GITHUB_PAT=$FAKE_GITHUB_PAT${NL}GITHUB_USER=octo-user" "$(cat "$WORK/my-app/.env")"
  assert_eq "owner-only" "$(env_mode "$WORK/my-app/.env")" "$([[ -z "$(env_mode "$WORK/my-app/.env")" ]] || echo 600)"
  assert_contains "reported with the keys, not the values" "$OUT" "Project .env      : created (GITEA_TOKEN GITHUB_PAT GITHUB_USER;"
  assert_not_contains "no token in the output" "$OUT$ERR" "$FAKE_GITEA_TOKEN"
  assert_not_contains "no GitHub token in the output" "$OUT$ERR" "$FAKE_GITHUB_PAT"
  # Git ignores it without any tracked file changing.
  check
  if ! git -C "$WORK/my-app" check-ignore -q -- .env; then
    fail ".env is not ignored by git"
  fi
  assert_not_contains "not listed by git status" "$(git -C "$WORK/my-app" status --porcelain)" ".env"
  assert_contains "excluded locally" "$(cat "$WORK/my-app/.git/info/exclude")" ".env"
  check
  if [[ -e $WORK/my-app/.gitignore ]]; then
    fail "a .gitignore was written; only .git/info/exclude may change"
  fi
  # No temporary file is left behind.
  assert_eq "no leftover file" "" "$(find "$WORK/my-app" -maxdepth 1 -name '.env.*' -print)"
}

test_the_project_env_without_github_holds_only_the_gitea_token() {
  setup_hosts
  run_apply_cred "${ANSWERS_GITEA_ONLY}y${NL}y$NL"
  assert_status "run" 0 "$STATUS"
  assert_eq "one key" "GITEA_TOKEN=$FAKE_GITEA_TOKEN" "$(cat "$WORK/my-app/.env")"
  assert_contains "reported" "$OUT" "Project .env      : created (GITEA_TOKEN;"
}

test_asked_credentials_are_what_the_project_env_holds() {
  setup_hosts
  without_env
  run_apply_cred "$(credentials_input)${NL}y${NL}y$NL"
  assert_status "run" 0 "$STATUS"
  assert_eq "the asked values" "GITEA_TOKEN=$FAKE_GITEA_TOKEN${NL}GITHUB_PAT=$FAKE_GITHUB_PAT${NL}GITHUB_USER=octo-user" "$(cat "$WORK/my-app/.env")"
  assert_not_contains "no token in the output" "$OUT$ERR" "$FAKE_GITEA_TOKEN"
}

test_no_token_is_in_any_file_but_the_project_env() {
  setup_hosts
  without_env
  run_apply_cred "$(credentials_input)${NL}y${NL}y$NL"
  assert_status "run" 0 "$STATUS"
  local hits
  # The new project (with its .git folder), the script's temporary directory
  # and its output; the stub curl's own request log is not part of the product.
  hits="$(grep -rIl -F -e "$FAKE_GITEA_TOKEN" -e "$FAKE_GITHUB_PAT" "$WORK/my-app" "$WORK/tmp" "$WORK/out.txt" "$WORK/err.txt" 2>/dev/null |
    grep -v -e '/my-app/\.env$' || true)"
  assert_eq "only the project .env holds a token" "" "$hits"
}

test_an_existing_env_is_kept_unless_the_maintainer_says_replace() {
  setup_hosts
  mkdir -p "$WORK/my-app"
  printf 'keep\n' >"$WORK/my-app/.env"
  run_apply_cred "${ANSWERS_GITHUB}y${NL}y${NL}y${NL}n$NL"
  assert_status "declined replacing" 0 "$STATUS"
  assert_eq "unchanged" "keep" "$(cat "$WORK/my-app/.env")"
  assert_contains "reported" "$OUT" "Project .env      : kept (the existing .env was left as it was)"
  remove_workdir
  new_workdir
  setup_hosts
  mkdir -p "$WORK/my-app"
  printf 'keep\n' >"$WORK/my-app/.env"
  run_apply_cred "${ANSWERS_GITHUB}y${NL}y${NL}y${NL}y$NL"
  assert_status "agreed to replace" 0 "$STATUS"
  assert_contains "replaced" "$(cat "$WORK/my-app/.env")" "GITEA_TOKEN=$FAKE_GITEA_TOKEN"
  assert_eq "private after replacing" "$(env_mode "$WORK/my-app/.env")" "$([[ -z "$(env_mode "$WORK/my-app/.env")" ]] || echo 600)"
}

test_a_tracked_env_is_never_written() {
  mkdir -p "$WORK/p"
  git -C "$WORK/p" init -q
  printf 'tracked\n' >"$WORK/p/.env"
  git -C "$WORK/p" add .env
  git -C "$WORK/p" -c user.name=t -c user.email=t@example.test commit -q -m init
  run_lib "y$NL" \
    'PROJECT[directory]="'"$WORK"'/p"; PROJECT[has_github]=0
CREDENTIALS[GITEA_TOKEN]=giteaFAKEtoken1234567890
init_steps
create_env_file
echo "${STEP_STATUS["Project .env"]}"'
  assert_status "run" 0 "$STATUS"
  assert_eq "skipped" "skipped" "$OUT"
  assert_eq "unchanged" "tracked" "$(cat "$WORK/p/.env")"
  assert_contains "says why" "$(cat "$WORK/err.txt" "$WORK/out.txt")" "skipped"
}

test_exclude_is_added_once_and_keeps_the_existing_entries() {
  mkdir -p "$WORK/p"
  git -C "$WORK/p" init -q
  printf 'build/' >"$WORK/p/.git/info/exclude" # no trailing newline
  run_lib "" \
    'exclude_env_file "'"$WORK"'/p"
exclude_env_file "'"$WORK"'/p"
echo done'
  assert_status "run" 0 "$STATUS"
  local exclude
  exclude="$(cat "$WORK/p/.git/info/exclude")"
  assert_contains "old entry kept" "$exclude" "build/"
  assert_contains "comment line" "$exclude" "# RepoFoundry: the credentials file of this project"
  assert_eq "entry added once" "1" "$(grep -c '^\.env$' "$WORK/p/.git/info/exclude")"
  assert_eq "old entry still on its own line" "1" "$(grep -c '^build/$' "$WORK/p/.git/info/exclude")"
}

test_exclude_does_nothing_when_env_is_already_ignored() {
  mkdir -p "$WORK/p"
  git -C "$WORK/p" init -q
  printf '.env\n' >"$WORK/p/.gitignore"
  run_lib "" 'exclude_env_file "'"$WORK"'/p"; echo done'
  assert_status "run" 0 "$STATUS"
  assert_eq "exclude file untouched" "0" "$(grep -c '^\.env$' "$WORK/p/.git/info/exclude" || true)"
}
