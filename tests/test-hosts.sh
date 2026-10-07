#!/usr/bin/env bash
# test-hosts.sh - tests for the GitHub and Gitea steps (MIL-002): preflight
# checks, the dry run, creating the repositories and the push mirror, reusing
# existing repositories and reporting a partial failure. A stub curl answers
# from a routes file and records every call; no real host is contacted.
# Sourced by run-tests.sh.

# shellcheck disable=SC2016  # snippet and fixture text is literal on purpose

run_dry() {
  run_cli "$1" --config "$WORK/config.env" --env "$WORK/.env"
}

run_apply() {
  run_cli "$1" --apply --config "$WORK/config.env" --env "$WORK/.env"
}

# position LINE: the number of the first recorded call equal to LINE.
position() {
  calls | grep -n -x -F "$1" | head -n 1 | cut -d: -f1
}

readonly GITHUB_REPO_CALL="POST https://api.github.com/orgs/acme-org/repos"
readonly GITEA_REPO_CALL="POST https://git.example.test/api/v1/orgs/TirSystem/repos"
readonly MIRROR_CALL="POST https://git.example.test/api/v1/repos/TirSystem/my-app/push_mirrors"
readonly SYNC_CALL="POST https://git.example.test/api/v1/repos/TirSystem/my-app/push_mirrors-sync"

# ------------------------------------------------------------------ dry run

test_dry_run_prints_the_plan_and_only_reads() {
  setup_hosts
  run_dry "$ANSWERS_GITHUB"
  assert_status "dry run" 0 "$STATUS"
  assert_contains "Gitea plan" "$OUT" "Gitea repository  : create (private), empty https://git.example.test/TirSystem/my-app"
  assert_contains "GitHub plan" "$OUT" "GitHub repository : create (private), empty https://github.com/acme-org/my-app"
  assert_contains "mirror plan" "$OUT" "Push mirror       : Gitea -> GitHub every 10m0s"
  assert_contains "origin plan" "$OUT" "Local origin      : will use SSH (the SSH test passed)"
  assert_contains "says it is a dry run" "$OUT" "Dry run: nothing was created. Run again with --apply"
  assert_not_contains "no creation report" "$OUT" "This is what exists now"
  assert_not_contains "only reads" "$(calls)" "POST"
  assert_not_contains "never deletes" "$(calls)" "DELETE"
  assert_not_contains "no PUT or PATCH" "$(calls)" "PATCH"
}

test_dry_run_does_not_ask_to_confirm() {
  setup_hosts
  run_dry "$ANSWERS_GITHUB"
  assert_not_contains "no final question" "$ERR" "Create these now"
}

test_ssh_failure_means_https() {
  setup_hosts
  write_ssh_stub 255
  run_dry "$ANSWERS_GITHUB"
  assert_status "ssh failure is not fatal" 0 "$STATUS"
  assert_contains "origin falls back to HTTPS" "$OUT" "will use HTTPS (SSH test: failed"
}

test_ssh_without_the_ssh_tool_is_not_fatal() {
  setup_hosts
  # A PATH that has the stubs and the basic tools but no ssh.
  rm -f "$WORK/bin/ssh"
  run_lib "" 'command() { if [[ $1 == -v && $2 == ssh ]]; then return 1; fi; builtin command "$@"; }
CONFIG[GITEA_URL]=https://git.example.test CONFIG[GITEA_SSH_PORT]=10022
test_gitea_ssh
echo "${STATE[is_ssh_ok]}|${STATE[ssh_note]}"'
  assert_eq "no ssh installed" "0|not tested (ssh is not installed)" "$OUT"
}

test_ssh_uses_the_configured_port() {
  setup_hosts
  printf 'GITEA_SSH_PORT=2222\n' >>"$WORK/config.env"
  run_dry "$ANSWERS_GITHUB"
  assert_status "custom port" 0 "$STATUS"
  assert_contains "port passed to ssh" "$(cat "$WORK/ssh.args")" "2222"
  assert_contains "Gitea host" "$(cat "$WORK/ssh.args")" "git@git.example.test"
  assert_contains "batch mode, no prompts" "$(cat "$WORK/ssh.args")" "BatchMode=yes"
  assert_contains "unknown host keys are refused" "$(cat "$WORK/ssh.args")" "StrictHostKeyChecking=yes"
}

test_config_validates_ssh_port_and_interval() {
  local key value expected
  while IFS='|' read -r key value expected; do
    printf 'GITEA_URL=https://git.example.test\n%s=%s\n' "$key" "$value" >"$WORK/c.env"
    run_lib "" "parse_env_file \"$WORK/c.env\" CONFIG_KEYS CONFIG
validate_config"
    assert_status "$key=$value" 1 "$STATUS"
    assert_contains "$key=$value message" "$ERR" "$expected"
  done <<'EOF'
GITEA_SSH_PORT|abc|port number
GITEA_SSH_PORT|0|port number
GITEA_SSH_PORT|70000|port number
MIRROR_INTERVAL|soon|10m0s or 8h0m0s
MIRROR_INTERVAL|10|10m0s or 8h0m0s
MIRROR_INTERVAL|10 m|10m0s or 8h0m0s
EOF
}

# -------------------------------------------------------------- preflight

test_gitea_token_rejected() {
  setup_hosts
  prepend_route 'GET|/api/v1/user|401|{"message":"token is required"}'
  run_apply "$ANSWERS_GITHUB"
  assert_status "bad Gitea token" 1 "$STATUS"
  assert_contains "says what failed" "$ERR" "Gitea rejected the token: authentication failed"
  assert_contains "shows the server's words" "$ERR" "token is required"
  assert_not_contains "nothing created" "$(calls)" "POST"
  assert_not_contains "no creation report before anything was created" "$OUT" "This is what exists now"
  assert_not_contains "GitHub not contacted first" "$(calls)" "api.github.com"
}

test_github_token_rejected() {
  setup_hosts
  prepend_route 'GET|api.github.com/user|401|{"message":"Bad credentials"}'
  run_apply "$ANSWERS_GITHUB"
  assert_status "bad GitHub token" 1 "$STATUS"
  assert_contains "says what failed" "$ERR" "GitHub rejected the token: authentication failed"
  assert_not_contains "nothing created" "$(calls)" "POST"
}

test_gitea_owner_must_exist() {
  setup_hosts
  prepend_route 'GET|/api/v1/orgs/TirSystem|404|{"message":"not found"}'
  run_apply "$ANSWERS_GITHUB"
  assert_status "unknown Gitea owner" 1 "$STATUS"
  assert_contains "message" "$ERR" "neither your account (gitea-user) nor an organization"
  assert_not_contains "nothing created" "$(calls)" "POST"
}

test_gitea_organization_needs_create_permission() {
  setup_hosts
  prepend_route 'GET|/api/v1/users/gitea-user/orgs/TirSystem/permissions|200|{"can_create_repository":false}'
  run_apply "$ANSWERS_GITHUB"
  assert_status "no permission" 1 "$STATUS"
  assert_contains "message" "$ERR" "you may not create repositories in the Gitea organization 'TirSystem'"
}

test_github_owner_must_be_a_member() {
  setup_hosts
  prepend_route 'GET|api.github.com/user/memberships/orgs/acme-org|404|{"message":"Not Found"}'
  run_apply "$ANSWERS_GITHUB"
  assert_status "not a member" 1 "$STATUS"
  assert_contains "message" "$ERR" "neither your account (octo-user) nor an organization you belong to"
  prepend_route 'GET|api.github.com/user/memberships/orgs/acme-org|200|{"state":"pending"}'
  run_apply "$ANSWERS_GITHUB"
  assert_status "pending membership" 1 "$STATUS"
  assert_contains "pending message" "$ERR" "membership of the GitHub organization 'acme-org' is not active"
}

test_license_must_be_offered_when_a_public_project_has_github() {
  setup_hosts
  prepend_route 'GET|/api/v1/licenses|200|[{"key":"MIT","name":"MIT"}]'
  run_apply "$ANSWERS_GITHUB_PUBLIC"
  assert_status "no AGPL" 1 "$STATUS"
  assert_contains "message" "$ERR" "does not offer the AGPL-3.0 license"
  assert_not_contains "nothing created" "$(calls)" "POST"
  # Without GitHub, or for a private project, no license is needed, so the same server is fine.
  setup_hosts
  prepend_route 'GET|/api/v1/licenses|200|[{"key":"MIT","name":"MIT"}]'
  run_dry "$ANSWERS_GITHUB"
  assert_status "private with GitHub" 0 "$STATUS"
  setup_hosts
  prepend_route 'GET|/api/v1/licenses|200|[{"key":"MIT","name":"MIT"}]'
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$WORK/.env"
  run_dry "$ANSWERS_GITEA_ONLY"
  assert_status "Gitea only" 0 "$STATUS"
}

test_existing_repository_with_content_stops_the_run() {
  setup_hosts
  prepend_route 'GET|/api/v1/repos/TirSystem/my-app|200|{"empty":false}'
  prepend_route 'GET|/api/v1/repos/TirSystem/my-app/contents|200|[{"name":"README.md","type":"file"}]'
  run_apply "$ANSWERS_GITHUB"
  assert_status "repository with content" 1 "$STATUS"
  assert_contains "message" "$ERR" "the Gitea repository TirSystem/my-app already exists and has content"
  assert_not_contains "nothing created" "$(calls)" "POST"
}

test_network_failure_stops_before_creating() {
  setup_hosts
  prepend_route 'GET|/api/v1/user|exit7|'
  run_apply "$ANSWERS_GITHUB"
  assert_status "no connection" 1 "$STATUS"
  assert_contains "message" "$ERR" "could not reach git.example.test: could not connect"
  assert_not_contains "nothing created" "$(calls)" "POST"
}

test_token_for_another_github_account_is_reported() {
  setup_hosts
  prepend_route 'GET|api.github.com/user|200|{"login":"someone-else"}'
  run_apply "$ANSWERS_GITHUB"$'y\n'
  assert_status "run continues" 0 "$STATUS"
  assert_contains "warns" "$ERR" "GITHUB_USER is 'octo-user' but the token belongs to 'someone-else'"
  assert_contains "mirror uses the account the token belongs to" "$(cat "$WORK/curl.bodies")" '"remote_username":"someone-else"'
}

# ------------------------------------------------------------ apply: success

test_apply_creates_repositories_and_mirror_in_order() {
  setup_hosts
  run_apply "$ANSWERS_GITHUB"$'y\n'
  assert_status "apply" 0 "$STATUS"
  assert_before "GitHub before Gitea" "$(position "$GITHUB_REPO_CALL")" "$(position "$GITEA_REPO_CALL")"
  assert_before "Gitea before the mirror" "$(position "$GITEA_REPO_CALL")" "$(position "$MIRROR_CALL")"
  assert_before "mirror before the sync" "$(position "$MIRROR_CALL")" "$(position "$SYNC_CALL")"
  assert_contains "final report" "$OUT" "Done. This is what exists now:"
  assert_contains "GitHub created" "$OUT" "GitHub repository : created https://github.com/acme-org/my-app"
  assert_contains "Gitea created" "$OUT" "Gitea repository  : created https://git.example.test/TirSystem/my-app"
  assert_contains "mirror created" "$OUT" "Push mirror       : created Gitea -> https://github.com/acme-org/my-app.git"
  assert_not_contains "never deletes" "$(calls)" "DELETE"
  assert_eq "temporary files removed" "" "$(find "$WORK/tmp" -mindepth 1)"
}

test_apply_sends_the_right_request_bodies() {
  setup_hosts
  run_apply "$ANSWERS_GITHUB"$'y\n'
  local bodies
  bodies="$(cat "$WORK/curl.bodies")"
  assert_contains "GitHub name" "$bodies" '"name":"my-app"'
  assert_contains "GitHub is created empty" "$bodies" '"private":true,"auto_init":false}'
  assert_not_contains "a private project gets no license" "$bodies" '"license"'
  assert_contains "default branch" "$bodies" '"default_branch":"main"'
  assert_contains "description" "$bodies" '"description":"A test app"'
  assert_contains "mirror target without credentials" "$bodies" '"remote_address":"https://github.com/acme-org/my-app.git"'
  assert_not_contains "no credentials in the address" "$bodies" 'https://octo-user:'
  assert_not_contains "no credentials in the address (at sign)" "$bodies" '@github.com'
  assert_contains "mirror account" "$bodies" '"remote_username":"octo-user"'
  assert_contains "the token is the mirror password" "$bodies" "\"remote_password\":\"$FAKE_GITHUB_PAT\""
  assert_contains "mirror interval" "$bodies" '"interval":"10m0s"'
  assert_contains "push on commit asked for" "$bodies" '"sync_on_commit":true'
}

test_apply_never_prints_or_passes_a_token() {
  setup_hosts
  run_apply "$ANSWERS_GITHUB"$'y\n'
  assert_not_contains "no Gitea token in output" "$OUT$ERR" "$FAKE_GITEA_TOKEN"
  assert_not_contains "no GitHub token in output" "$OUT$ERR" "$FAKE_GITHUB_PAT"
  assert_not_contains "no token on a command line" "$(cat "$WORK/curl.args")" "$FAKE_GITEA_TOKEN"
  assert_not_contains "no GitHub token on a command line" "$(cat "$WORK/curl.args")" "$FAKE_GITHUB_PAT"
  assert_contains "Gitea token in the private config" "$(cat "$WORK/curl.config")" "Authorization: token $FAKE_GITEA_TOKEN"
  assert_contains "GitHub token in the private config" "$(cat "$WORK/curl.config")" "Authorization: Bearer $FAKE_GITHUB_PAT"
}

test_apply_sends_the_license_for_a_public_project_with_github() {
  setup_hosts
  run_apply "$ANSWERS_GITHUB_PUBLIC"$'y\n'
  local bodies
  bodies="$(cat "$WORK/curl.bodies")"
  assert_contains "Gitea gets the license" "$bodies" '"license":"AGPL-3.0"'
  assert_contains "Gitea is initialised with it" "$bodies" '"auto_init":true'
  assert_contains "public" "$bodies" '"private":false'
  assert_contains "plan names the rule" "$OUT" "with the AGPL-3.0 license (default: GitHub and a public project)"
}

test_apply_with_gitea_only() {
  setup_hosts
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$WORK/.env"
  run_apply "$ANSWERS_GITEA_ONLY"$'y\n'
  assert_status "Gitea only" 0 "$STATUS"
  assert_contains "Gitea repository created" "$(calls)" "$GITEA_REPO_CALL"
  assert_contains "created empty" "$(cat "$WORK/curl.bodies")" '"auto_init":false'
  assert_not_contains "no license" "$(cat "$WORK/curl.bodies")" "license"
  assert_not_contains "no GitHub call" "$(calls)" "api.github.com"
  assert_not_contains "no mirror call" "$(calls)" "push_mirrors"
  assert_contains "GitHub not used" "$OUT" "GitHub repository : not used"
  assert_contains "mirror not used" "$OUT" "Push mirror       : not used"
}

test_apply_declined_creates_nothing() {
  setup_hosts
  run_apply "$ANSWERS_GITHUB"$'n\n'
  assert_status "answered no" 0 "$STATUS"
  assert_contains "says so" "$OUT" "Nothing was created."
  assert_not_contains "no POST" "$(calls)" "POST"
  assert_not_contains "no report" "$OUT" "This is what exists now"
}

test_apply_for_user_owners_uses_the_user_endpoints() {
  setup_hosts
  # The Gitea account's own repository (with the license commit) is a copy.
  mkdir -p "$WORK/remote/gitea-user"
  cp -R "$WORK/remote/TirSystem/my-app.git" "$WORK/remote/gitea-user/my-app.git"
  write_routes <<'ROUTES'
GET|/api/v1/user|200|{"login":"gitea-user"}
GET|/api/v1/licenses|200|[{"key":"AGPL-3.0"}]
GET|/api/v1/repos/gitea-user/my-app|404|{"message":"not found"}
GET|api.github.com/user|200|{"login":"octo-user"}
GET|api.github.com/repos/octo-user/my-app|404|{"message":"Not Found"}
GET|/api/v1/repos/gitea-user/my-app/push_mirrors|200|[]
GET|/api/v1/repos/gitea-user/my-app/push_mirrors|200|[{"remote_address":"https://github.com/octo-user/my-app.git","sync_on_commit":true}]
POST|api.github.com/user/repos|201|{}
POST|/api/v1/user/repos|201|{}
POST|/api/v1/repos/gitea-user/my-app/push_mirrors|200|{}
POST|/api/v1/repos/gitea-user/my-app/push_mirrors-sync|200|{}
ROUTES
  run_apply $'my-app\n\n\ngitea-user\ny\n\n\n\ny\n'
  assert_status "user owners" 0 "$STATUS"
  assert_contains "GitHub user endpoint" "$(calls)" "POST https://api.github.com/user/repos"
  assert_contains "Gitea user endpoint" "$(calls)" "POST https://git.example.test/api/v1/user/repos"
  assert_contains "mirror target of the GitHub account" "$(cat "$WORK/curl.bodies")" '"remote_address":"https://github.com/octo-user/my-app.git"'
  assert_not_contains "no organization endpoint" "$(calls)" "/orgs/"
}

test_public_visibility_and_special_characters_in_the_description() {
  setup_hosts
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$WORK/.env"
  run_apply $'my-app\nSay "hi" \\ there\npublic\nTirSystem\nn\n\nn\ny\n'
  assert_status "apply" 0 "$STATUS"
  assert_contains "public" "$(cat "$WORK/curl.bodies")" '"private":false'
  assert_contains "description escaped" "$(cat "$WORK/curl.bodies")" '"description":"Say \"hi\" \\ there"'
}

test_mirror_interval_comes_from_the_configuration() {
  setup_hosts
  printf 'MIRROR_INTERVAL=1h0m0s\n' >>"$WORK/config.env"
  run_apply "$ANSWERS_GITHUB"$'y\n'
  assert_status "apply" 0 "$STATUS"
  assert_contains "interval sent" "$(cat "$WORK/curl.bodies")" '"interval":"1h0m0s"'
  assert_contains "interval planned" "$OUT" "every 1h0m0s"
}

# ------------------------------------------------------------------- reuse

test_empty_github_repository_can_be_reused() {
  setup_hosts
  prepend_route 'GET|api.github.com/repos/acme-org/my-app|200|{"name":"my-app"}'
  run_dry "$ANSWERS_GITHUB"
  assert_contains "plan offers reuse" "$OUT" "reuse the existing empty repository (you will be asked to confirm)"
  assert_not_contains "dry run does not ask" "$ERR" "Reuse it"
  setup_hosts
  prepend_route 'GET|api.github.com/repos/acme-org/my-app|200|{"name":"my-app"}'
  run_apply "$ANSWERS_GITHUB"$'y\ny\n'
  assert_status "reuse" 0 "$STATUS"
  assert_contains "asked" "$ERR" "GitHub repository https://github.com/acme-org/my-app already exists"
  assert_not_contains "GitHub repository not created again" "$(calls)" "$GITHUB_REPO_CALL"
  assert_contains "reported as reused" "$OUT" "GitHub repository : reused https://github.com/acme-org/my-app"
  assert_contains "the rest is created" "$(calls)" "$GITEA_REPO_CALL"
}

test_declining_the_reuse_stops_the_run() {
  setup_hosts
  prepend_route 'GET|api.github.com/repos/acme-org/my-app|200|{"name":"my-app"}'
  run_apply "$ANSWERS_GITHUB"$'y\nn\n'
  assert_status "reuse declined" 1 "$STATUS"
  assert_contains "message" "$ERR" "stopped: choose another name or remove the existing repository"
  assert_not_contains "nothing created" "$(calls)" "POST"
}

test_gitea_repository_with_only_the_license_can_be_reused() {
  setup_hosts
  prepend_route 'GET|/api/v1/repos/TirSystem/my-app|200|{"empty":false}'
  prepend_route 'GET|/api/v1/repos/TirSystem/my-app/contents|200|[{"name":"LICENSE","type":"file","path":"LICENSE"}]'
  run_apply "$ANSWERS_GITHUB_PUBLIC"$'y\ny\n'
  assert_status "license only" 0 "$STATUS"
  assert_not_contains "Gitea repository not created again" "$(calls)" "$GITEA_REPO_CALL"
  assert_eq "mirror created once" "1" "$(calls | grep -c -x -F "$MIRROR_CALL")"
  assert_contains "reported" "$OUT" "Gitea repository  : reused https://git.example.test/TirSystem/my-app"
  # Without GitHub the license is not expected, so the repository has content.
  setup_hosts
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$WORK/.env"
  prepend_route 'GET|/api/v1/repos/TirSystem/my-app|200|{"empty":false}'
  prepend_route 'GET|/api/v1/repos/TirSystem/my-app/contents|200|[{"name":"LICENSE","type":"file"}]'
  run_dry "$ANSWERS_GITEA_ONLY"
  assert_status "license without GitHub" 1 "$STATUS"
  assert_contains "has content" "$ERR" "already exists and has content"
}

test_reusing_an_empty_gitea_repository_warns_about_the_license() {
  setup_hosts
  prepend_route 'GET|/api/v1/repos/TirSystem/my-app|200|{"empty":true}'
  run_apply "$ANSWERS_GITHUB_PUBLIC"$'y\ny\n'
  assert_status "reuse empty Gitea repository" 0 "$STATUS"
  assert_contains "warning" "$ERR" "the AGPL-3.0 license is not added to it"
}

test_an_existing_mirror_is_reused() {
  setup_hosts
  prepend_route 'GET|/api/v1/repos/TirSystem/my-app/push_mirrors|200|[{"remote_address":"https://github.com/acme-org/my-app.git","sync_on_commit":true,"last_error":""}]'
  run_apply "$ANSWERS_GITHUB"$'y\n'
  assert_status "mirror exists" 0 "$STATUS"
  assert_eq "mirror not created twice" "" "$(position "$MIRROR_CALL")"
  assert_contains "first sync still requested" "$(calls)" "$SYNC_CALL"
  assert_contains "reported" "$OUT" "Push mirror       : reused Gitea -> https://github.com/acme-org/my-app.git"
}

# ----------------------------------------------------------------- failures

test_partial_failure_reports_what_exists() {
  setup_hosts
  prepend_route 'POST|/api/v1/orgs/TirSystem/repos|422|{"message":"repository already exists"}'
  run_apply "$ANSWERS_GITHUB"$'y\n'
  assert_status "Gitea creation fails" 1 "$STATUS"
  assert_contains "reason" "$ERR" "cannot create the Gitea repository: rejected"
  assert_contains "server's words" "$ERR" "repository already exists"
  assert_contains "report header" "$OUT" "The run stopped before it finished. This is what exists now:"
  assert_contains "GitHub was created" "$OUT" "GitHub repository : created https://github.com/acme-org/my-app"
  assert_contains "Gitea failed" "$OUT" "Gitea repository  : FAILED"
  assert_contains "mirror not attempted" "$OUT" "Push mirror       : not attempted"
  assert_contains "how to continue" "$OUT" "To continue: fix the problem named above and run the same command again with --apply."
  assert_contains "nothing deleted" "$OUT" "Nothing is deleted automatically."
  assert_not_contains "never deletes" "$(calls)" "DELETE"
  assert_not_contains "no mirror call" "$(calls)" "push_mirrors"
  assert_eq "temporary files removed" "" "$(find "$WORK/tmp" -mindepth 1)"
}

test_failure_of_the_first_step_leaves_the_rest_not_attempted() {
  setup_hosts
  prepend_route 'POST|api.github.com/orgs/acme-org/repos|403|{"message":"Resource not accessible by personal access token"}'
  run_apply "$ANSWERS_GITHUB"$'y\n'
  assert_status "GitHub creation fails" 1 "$STATUS"
  assert_contains "reason" "$ERR" "cannot create the GitHub repository: the token is valid but not allowed to do this"
  assert_contains "GitHub failed" "$OUT" "GitHub repository : FAILED"
  assert_contains "Gitea not attempted" "$OUT" "Gitea repository  : not attempted"
  assert_not_contains "no Gitea call" "$(calls)" "$GITEA_REPO_CALL"
}

test_mirror_failure_keeps_the_repositories_and_says_so() {
  setup_hosts
  prepend_route 'POST|/api/v1/repos/TirSystem/my-app/push_mirrors|403|{"message":"push mirrors are disabled"}'
  run_apply "$ANSWERS_GITHUB"$'y\n'
  assert_status "mirror fails" 1 "$STATUS"
  assert_contains "reason" "$ERR" "cannot create the push mirror"
  assert_contains "server's words" "$ERR" "push mirrors are disabled"
  assert_contains "GitHub kept" "$OUT" "GitHub repository : created"
  assert_contains "Gitea kept" "$OUT" "Gitea repository  : created"
  assert_contains "mirror failed" "$OUT" "Push mirror       : FAILED"
}

test_sync_on_commit_not_applied_is_reported() {
  setup_hosts
  sed -i 's/"sync_on_commit":true,"interval"/"sync_on_commit":false,"interval"/' "$WORK/routes"
  run_apply "$ANSWERS_GITHUB"$'y\n'
  assert_status "still succeeds" 0 "$STATUS"
  assert_contains "warning" "$ERR" "Gitea did not apply sync_on_commit (a known server issue)"
  assert_contains "report mentions the interval" "$OUT" "(syncs every 10m0s, not on every commit)"
}

test_first_sync_error_is_reported() {
  setup_hosts
  sed -i 's/"last_error":""/"last_error":"push failed: authentication required"/' "$WORK/routes"
  run_apply "$ANSWERS_GITHUB"$'y\n'
  assert_status "still succeeds" 0 "$STATUS"
  assert_contains "warning" "$ERR" "the first mirror sync reported: push failed: authentication required"
}

test_first_sync_request_failure_is_only_a_warning() {
  setup_hosts
  prepend_route 'POST|/api/v1/repos/TirSystem/my-app/push_mirrors-sync|500|{"message":"boom"}'
  run_apply "$ANSWERS_GITHUB"$'y\n'
  assert_status "still succeeds" 0 "$STATUS"
  assert_contains "warning" "$ERR" "could not ask Gitea for the first sync (HTTP 500)"
}

test_a_token_in_a_server_message_is_redacted() {
  setup_hosts
  prepend_route "POST|/api/v1/orgs/TirSystem/repos|422|{\"message\":\"bad credentials $FAKE_GITHUB_PAT given\"}"
  run_apply "$ANSWERS_GITHUB"$'y\n'
  assert_status "Gitea creation fails" 1 "$STATUS"
  assert_not_contains "token redacted" "$OUT$ERR" "$FAKE_GITHUB_PAT"
  assert_contains "redaction visible" "$ERR" "[redacted]"
}

# ------------------------------------------------------------ JSON helpers

test_json_has_value_and_values() {
  printf '[{"key": "AGPL-3.0","name":"a"},{"key":"MIT","name":"b"}]\n' >"$WORK/l.json"
  run_lib "" "json_has_value '$WORK/l.json' key AGPL-3.0 && echo yes1
json_has_value '$WORK/l.json' key MIT && echo yes2
json_has_value '$WORK/l.json' key GPL-3.0 || echo no3
json_values '$WORK/l.json' name"
  assert_eq "pairs and values" $'yes1\nyes2\nno3\na\nb' "$OUT"
}

test_mirror_field_with_and_without_jq() {
  local mode
  printf '[{"remote_address":"https://github.com/o/a.git","sync_on_commit":false,"last_error":"x"},{"remote_address":"https://github.com/o/b.git","sync_on_commit":true,"last_error":""}]\n' >"$WORK/m.json"
  for mode in 0 1; do
    if ((mode)) && ! command -v jq >/dev/null 2>&1; then
      continue
    fi
    run_lib "" "HAS_JQ=$mode
mirror_field '$WORK/m.json' https://github.com/o/a.git sync_on_commit
mirror_field '$WORK/m.json' https://github.com/o/a.git last_error"
    assert_eq "first mirror (HAS_JQ=$mode)" $'false\nx' "$OUT"
  done
  if command -v jq >/dev/null 2>&1; then
    run_lib "" "HAS_JQ=1
mirror_field '$WORK/m.json' https://github.com/o/b.git sync_on_commit"
    assert_eq "the right mirror is chosen with jq" "true" "$OUT"
  fi
}

# ------------------------------------------------- found by the live e2e run

test_a_repository_this_script_created_earlier_can_be_reused() {
  # Seen on a real Gitea: creating a repository with a license also adds a
  # README.md. After a failed mirror step the next run must still reuse it.
  setup_hosts
  prepend_route 'GET|/api/v1/repos/TirSystem/my-app|200|{"empty":false}'
  prepend_route 'GET|/api/v1/repos/TirSystem/my-app/contents|200|[{"name":"README.md","type":"file"},{"name":"LICENSE","type":"file"}]'
  run_apply "$ANSWERS_GITHUB_PUBLIC"$'y\ny\n'
  assert_status "LICENSE and README.md" 0 "$STATUS"
  assert_not_contains "not created again" "$(calls)" "$GITEA_REPO_CALL"
  assert_contains "reported" "$OUT" "Gitea repository  : reused"
}

test_other_files_still_count_as_content() {
  local listing
  for listing in '[{"name":"README.md","type":"file"}]' \
    '[{"name":"LICENSE","type":"file"},{"name":"README.md","type":"file"},{"name":"main.c","type":"file"}]' \
    '[{"name":"LICENSE","type":"file"},{"name":"src","type":"dir"}]'; do
    setup_hosts
    prepend_route 'GET|/api/v1/repos/TirSystem/my-app|200|{"empty":false}'
    prepend_route "GET|/api/v1/repos/TirSystem/my-app/contents|200|$listing"
    run_dry "$ANSWERS_GITHUB"
    assert_status "content: $listing" 1 "$STATUS"
    assert_contains "refused" "$ERR" "already exists and has content"
  done
}

test_children_never_eat_the_answers_meant_for_later_prompts() {
  # The real ssh reads standard input until it ends; the stub does too. The
  # script closes stdin for ssh, git, curl and the framework scripts, so the
  # answers that follow the SSH test still reach the later prompts.
  setup_hosts
  run_apply "$ANSWERS_GITHUB"$'y\n'
  assert_status "the final question is still answered" 0 "$STATUS"
  assert_contains "created" "$OUT" "Done. This is what exists now:"
  assert_not_contains "no lost input" "$ERR" "no input available"
}
