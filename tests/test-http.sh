#!/usr/bin/env bash
# test-http.sh - tests for the HTTP helper, the tool check and the JSON
# helpers (MIL-001 task: tool check and HTTP helper). A stub curl stands in
# for the network. Sourced by run-tests.sh.

# shellcheck disable=SC2016  # snippet and fixture text is literal on purpose
test_http_request_keeps_token_off_the_command_line() {
  write_curl_stub
  run_lib "" "setup_temp_dir
http_request GET https://git.example.test/api/v1/user token '$FAKE_GITEA_TOKEN'
echo \"status=\$HTTP_STATUS\"
cleanup"
  assert_status "request succeeds" 0 "$STATUS"
  assert_contains "status captured" "$OUT" "status=200"
  assert_file_exists "stub saw the call" "$WORK/curl.args"
  assert_not_contains "token not in arguments" "$(cat "$WORK/curl.args")" "$FAKE_GITEA_TOKEN"
  assert_contains "token in private config" "$(cat "$WORK/curl.config")" "Authorization: token $FAKE_GITEA_TOKEN"
  assert_contains "redirects are not followed" "$(cat "$WORK/curl.args")" "--silent"
  assert_not_contains "no redirect flag" "$(cat "$WORK/curl.args")" "--location"
  assert_not_contains "no -L flag" "$(cat "$WORK/curl.args")" $'\n-L\n'
  assert_not_contains "token not printed" "$OUT$ERR" "$FAKE_GITEA_TOKEN"
}

test_http_request_cleans_up_its_files() {
  write_curl_stub
  run_lib "" "setup_temp_dir
http_request GET https://git.example.test/api/v1/user token '$FAKE_GITEA_TOKEN'
cleanup"
  assert_eq "no temp files left" "" "$(find "$WORK/tmp" -mindepth 1 2>/dev/null)"
}

test_http_request_bearer_scheme_and_body() {
  write_curl_stub
  run_lib "" "setup_temp_dir
http_request POST https://api.github.com/user/repos bearer '$FAKE_GITHUB_PAT' '{\"name\":\"x\"}'
cleanup"
  assert_status "POST succeeds" 0 "$STATUS"
  assert_contains "bearer header" "$(cat "$WORK/curl.config")" "Authorization: Bearer $FAKE_GITHUB_PAT"
  assert_contains "content type" "$(cat "$WORK/curl.config")" "Content-Type: application/json"
  assert_contains "body sent from a file" "$(cat "$WORK/curl.args")" "--data-binary"
  assert_not_contains "token not in arguments" "$(cat "$WORK/curl.args")" "$FAKE_GITHUB_PAT"
}

test_http_status_messages() {
  local code expected
  while IFS='|' read -r code expected; do
    run_lib "" "describe_http_status $code"
    assert_contains "HTTP $code" "$OUT" "$expected"
  done <<'EOF'
401|authentication failed
403|scopes
404|not found
422|already exist
429|rate limited
503|server reported an error
418|unexpected HTTP status 418
EOF
}

test_http_network_failure() {
  write_curl_stub
  run_lib "" "setup_temp_dir
STUB_CURL_EXIT=7 http_request GET https://git.example.test/api/v1/user token '$FAKE_GITEA_TOKEN' || echo \"failed: \$HTTP_ERROR\"
cleanup"
  assert_contains "network error reported" "$OUT" "failed: could not reach git.example.test: could not connect"
  assert_not_contains "token not in the error" "$OUT$ERR" "$FAKE_GITEA_TOKEN"
}

test_http_request_refuses_unsafe_input() {
  local case_name args expected
  write_curl_stub
  while IFS='|' read -r case_name args expected; do
    run_lib "" "setup_temp_dir
http_request $args
cleanup"
    assert_status "$case_name" 1 "$STATUS"
    assert_contains "$case_name message" "$ERR" "$expected"
  done <<'EOF'
http URL|GET http://git.example.test/x token abcdefgh12345|invalid or non-https URL
user info URL|GET https://u:p@git.example.test/x token abcdefgh12345|invalid or non-https URL
bad method|TRACE https://git.example.test/x token abcdefgh12345|unsupported HTTP method
bad token|GET https://git.example.test/x token 'bad token'|malformed token
bad scheme|GET https://git.example.test/x basic abcdefgh12345|unknown authentication scheme
EOF
  assert_file_missing "curl never called" "$WORK/curl.args"
}

test_check_tools_stops_before_any_change() {
  # An empty PATH: no git, curl or mktemp, so the check must fail first and
  # the script must not create anything, not even a temporary directory.
  write_fixtures
  mkdir -p "$WORK/emptybin"
  STATUS=0
  PATH="$WORK/emptybin" TMPDIR="$WORK/tmp" "$BASH" "$SCRIPT" \
    --config "$WORK/config.env" --env "$WORK/.env" </dev/null \
    >"$WORK/out.txt" 2>"$WORK/err.txt" || STATUS=$?
  assert_status "missing tools" 1 "$STATUS"
  assert_contains "names the tools" "$(cat "$WORK/err.txt")" "required tool(s) not found: git curl mktemp"
  assert_eq "nothing created" "" "$(find "$WORK/tmp" -mindepth 1 2>/dev/null)"
}

test_missing_jq_is_only_a_warning() {
  run_lib "" "command() { if [[ \$1 == -v && \$2 == jq ]]; then return 1; fi; builtin command \"\$@\"; }
check_tools
echo \"HAS_JQ=\$HAS_JQ\""
  assert_status "jq optional" 0 "$STATUS"
  assert_contains "jq flag cleared" "$OUT" "HAS_JQ=0"
  assert_contains "warning shown" "$ERR" "jq not found"
}

test_json_escape() {
  run_lib "" 'json_escape "say \"hi\" \\ back"; echo; json_escape $'"'"'a\nb\tc'"'"'; echo'
  assert_eq "escaped" $'say \\"hi\\" \\\\ back\na\\nb\\tc' "$OUT"
}

test_json_get_with_and_without_jq() {
  local mode
  printf '{"id": 42, "name": "RepoFoundry", "private": false, "other": {"name": "x"}}\n' >"$WORK/r.json"
  for mode in 0 1; do
    if ((mode)) && ! command -v jq >/dev/null 2>&1; then
      continue
    fi
    run_lib "" "HAS_JQ=$mode
json_get '$WORK/r.json' id
json_get '$WORK/r.json' name
json_get '$WORK/r.json' private
json_get '$WORK/r.json' missing"
    assert_eq "json_get with HAS_JQ=$mode" $'42\nRepoFoundry\nfalse' "$OUT"
  done
}
