#!/usr/bin/env bash
# test-config.sh - tests for the config.env and .env parsing and validation
# (MIL-001 task: safe parser). Sourced by run-tests.sh.

# parse_ok FILE-CONTENT: parse a config file and print the CONFIG entries.
# shellcheck disable=SC2016  # snippet and fixture text is literal on purpose
parse_snippet() {
  printf 'parse_env_file "%s" CONFIG_KEYS CONFIG\nfor k in "${!CONFIG[@]}"; do printf "%%s=%%s\\n" "$k" "${CONFIG[$k]}"; done | sort\n' "$WORK/c.env"
}

test_parser_accepts_valid_file() {
  printf '# comment\n\nGITEA_URL="https://a.test/"\r\nGITHUB_WEB_URL='"'"'https://b.test'"'"'\nGITEA_API_URL=https://a.test/api/v1 # inline\n' >"$WORK/c.env"
  run_lib "" "$(parse_snippet)"
  assert_status "valid file" 0 "$STATUS"
  assert_contains "quotes stripped" "$OUT" "GITEA_URL=https://a.test/"
  assert_contains "single quotes" "$OUT" "GITHUB_WEB_URL=https://b.test"
  assert_contains "inline comment dropped" "$OUT" "GITEA_API_URL=https://a.test/api/v1"
}

test_parser_rejects_bad_input() {
  local case_name content expected
  while IFS='|' read -r case_name content expected; do
    printf '%b' "$content" >"$WORK/c.env"
    run_lib "" "$(parse_snippet)"
    assert_status "$case_name" 1 "$STATUS"
    assert_contains "$case_name message" "$ERR" "$expected"
  done <<'EOF'
unknown key|OTHER=1\n|unknown key 'OTHER'
credential in config|GITEA_TOKEN=abcdefgh12345\n|is a credential
not KEY=VALUE|just some text\n|line 1: expected KEY=VALUE
lowercase key|gitea_url=https://a.test\n|unknown key 'gitea_url'
duplicate key|GITEA_URL=https://a.test\nGITEA_URL=https://b.test\n|set twice
unbalanced quote|GITEA_URL="https://a.test\n|unbalanced
quote inside|GITEA_URL="https://a"b.test"\n|unbalanced
control character|GITEA_URL=https://a\x01b.test\n|control character
EOF
}

test_parser_missing_file() {
  run_lib "" "parse_env_file \"$WORK/none.env\" CONFIG_KEYS CONFIG"
  assert_status "missing file" 1 "$STATUS"
  assert_contains "missing file message" "$ERR" "cannot read"
}

test_parser_never_executes_values() {
  local marker="$WORK/pwned"
  printf 'GITEA_URL=$(touch %s)\nGITHUB_WEB_URL=`touch %s`\n' "$marker" "$marker" >"$WORK/c.env"
  run_lib "" "parse_env_file \"$WORK/c.env\" CONFIG_KEYS CONFIG
validate_config"
  assert_file_missing "command substitution not run" "$marker"
  assert_status "bad value rejected" 1 "$STATUS"
  printf 'GITEA_TOKEN=$(touch %s)\n' "$marker" >"$WORK/e.env"
  run_lib "" "parse_env_file \"$WORK/e.env\" CREDENTIAL_KEYS CREDENTIALS
validate_credentials"
  assert_file_missing "token value not run" "$marker"
  assert_status "bad token rejected" 1 "$STATUS"
}

test_config_validation() {
  local case_name url expected
  while IFS='|' read -r case_name url expected; do
    printf 'GITEA_URL=%s\n' "$url" >"$WORK/c.env"
    run_lib "" "parse_env_file \"$WORK/c.env\" CONFIG_KEYS CONFIG
validate_config"
    assert_status "$case_name" 1 "$STATUS"
    assert_contains "$case_name message" "$ERR" "$expected"
  done <<'EOF'
plain http|http://git.example.test|https URL
user info|https://user:pw@git.example.test|https URL
query string|https://git.example.test/?token=abc|https URL
fragment|https://git.example.test/#x|https URL
spaces|https://git.example.test/a b|https URL
EOF
  printf '# nothing\n' >"$WORK/c.env"
  run_lib "" "parse_env_file \"$WORK/c.env\" CONFIG_KEYS CONFIG
validate_config"
  assert_status "GITEA_URL missing" 1 "$STATUS"
  assert_contains "GITEA_URL missing message" "$ERR" "GITEA_URL is missing"
}

test_config_defaults_and_normalizing() {
  printf 'GITEA_URL=https://git.example.test///\n' >"$WORK/c.env"
  run_lib "" "parse_env_file \"$WORK/c.env\" CONFIG_KEYS CONFIG
validate_config
printf '%s\n' \"\${CONFIG[GITEA_URL]}\" \"\${CONFIG[GITEA_API_URL]}\" \"\${CONFIG[GITHUB_API_URL]}\" \"\${CONFIG[GITHUB_WEB_URL]}\""
  assert_status "defaults" 0 "$STATUS"
  assert_eq "trailing slashes removed" $'https://git.example.test\nhttps://git.example.test/api/v1\nhttps://api.github.com\nhttps://github.com' "$OUT"
}

test_credentials_validation() {
  local case_name content expected
  while IFS='|' read -r case_name content expected; do
    printf '%b' "$content" >"$WORK/e.env"
    run_lib "" "parse_env_file \"$WORK/e.env\" CREDENTIAL_KEYS CREDENTIALS
validate_credentials"
    assert_status "$case_name" 1 "$STATUS"
    assert_contains "$case_name message" "$ERR" "$expected"
  done <<'EOF'
no Gitea token|GITHUB_USER=octo\n|GITEA_TOKEN is missing
token too short|GITEA_TOKEN=short\n|not a valid token
token with a backslash|GITEA_TOKEN=abc\\defgh12345\n|not a valid token
bad GitHub token|GITEA_TOKEN=abcdefgh12345\nGITHUB_PAT=bad token\n|GITHUB_PAT
bad GitHub user|GITEA_TOKEN=abcdefgh12345\nGITHUB_USER=-bad-\n|GITHUB_USER
EOF
}

test_github_credentials_required_only_when_chosen() {
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$WORK/e.env"
  run_lib "" "parse_env_file \"$WORK/e.env\" CREDENTIAL_KEYS CREDENTIALS
validate_credentials
echo no-github-ok
ENV_FILE=\"$WORK/e.env\"
require_github_credentials"
  assert_contains "Gitea-only .env is valid" "$OUT" "no-github-ok"
  assert_status "GitHub credentials missing" 1 "$STATUS"
  assert_contains "names the missing key" "$ERR" "GITHUB_PAT is missing"
}

test_validators() {
  local fn value expected
  while IFS='|' read -r fn value expected; do
    run_lib "" "if $fn '$value'; then echo yes; else echo no; fi"
    assert_eq "$fn '$value'" "$expected" "$OUT"
  done <<'EOF'
is_valid_repo_name|RepoFoundry|yes
is_valid_repo_name|my.repo_1-x|yes
is_valid_repo_name|bad name|no
is_valid_repo_name|..|no
is_valid_repo_name|x.git|no
is_valid_repo_name||no
is_valid_gitea_owner|Tirsvad|yes
is_valid_gitea_owner|-lead|no
is_valid_github_owner|octo-user|yes
is_valid_github_owner|octo_user|no
is_valid_github_owner|-octo|no
is_valid_github_owner|octo-|no
is_valid_directory|./my-project|yes
is_valid_directory|-rf|no
is_valid_directory||no
is_valid_token|abcdefgh12345|yes
is_valid_token|abc|no
is_valid_base_url|https://git.example.test/api/v1|yes
is_valid_base_url|http://git.example.test|no
is_valid_request_url|https://api.github.com/user?per_page=5|yes
is_valid_request_url|https://u:p@api.github.com/user|no
EOF
}

test_example_files_hold_placeholders_only() {
  local file line value
  for file in "$REPO_ROOT/.env.example" "$REPO_ROOT/config.env.example"; do
    assert_file_exists "example file" "$file"
  done
  while IFS= read -r line; do
    value="${line#*=}"
    check
    if [[ -n $value ]]; then
      fail ".env.example has a value for ${line%%=*}; it must be empty"
    fi
  done < <(grep -E '^[A-Z_]+=' "$REPO_ROOT/.env.example")
  # The example holds a placeholder for the Gitea address, so it must be
  # edited before use: as it is, it is refused with a clear message...
  run_lib "" "parse_env_file \"$REPO_ROOT/config.env.example\" CONFIG_KEYS CONFIG
validate_config
echo parsed"
  assert_status "placeholder address is refused" 1 "$STATUS"
  assert_contains "names the key" "$ERR" "GITEA_URL"
  # ...and with a real address in its place the rest of the file is valid.
  sed -e 's|^GITEA_URL=.*|GITEA_URL=https://git.example.test/|' \
    -e 's|^GITEA_API_URL=.*|GITEA_API_URL=https://git.example.test/api/v1|' \
    "$REPO_ROOT/config.env.example" >"$WORK/example.env"
  run_lib "" "parse_env_file \"$WORK/example.env\" CONFIG_KEYS CONFIG
validate_config
echo parsed"
  assert_contains "config.env.example is valid once the address is set" "$OUT" "parsed"
  run_lib "" "parse_env_file \"$REPO_ROOT/.env.example\" CREDENTIAL_KEYS CREDENTIALS
echo parsed"
  assert_contains ".env.example parses" "$OUT" "parsed"
}

test_env_is_ignored_by_git() {
  check
  if ! git -C "$REPO_ROOT" check-ignore -q .env; then
    fail ".env is not ignored by git"
  fi
  check
  if git -C "$REPO_ROOT" check-ignore -q .env.example; then
    fail ".env.example must not be ignored"
  fi
}
