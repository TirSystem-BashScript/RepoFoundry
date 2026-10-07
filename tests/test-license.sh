#!/usr/bin/env bash
# test-license.sh - tests for the project license (MIL-006): PROJECT_LICENSE
# in config.env, the default (AGPL-3.0 only for a public project with GitHub),
# "none", invalid values and a license the server does not offer. Sourced by
# run-tests.sh.

# shellcheck disable=SC2016  # snippet and fixture text is literal on purpose

readonly ANSWERS_GITEA_ONLY_PUBLIC=$'my-app\n\npublic\nTirSystem\nn\n\nn\n'
readonly MIT_ROUTE='GET|/api/v1/licenses|200|[{"key":"MIT","name":"MIT"},{"key":"AGPL-3.0","name":"AGPL-3.0"}]'

# use_license LINE: add a line to config.env and make the server offer MIT.
use_license() {
  printf '%s\n' "$1" >>"$WORK/config.env"
  prepend_route "$MIT_ROUTE"
}

# gitea_only_env: a Gitea-only run needs no GitHub credentials.
gitea_only_env() {
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$WORK/.env"
}

# ------------------------------------------------------------- key is set

test_a_license_in_config_is_used_with_github_for_a_private_project() {
  setup_hosts
  use_license "PROJECT_LICENSE=MIT"
  run_apply "$ANSWERS_GITHUB"$'y\n'
  assert_status "apply" 0 "$STATUS"
  assert_contains "Gitea gets MIT" "$(cat "$WORK/curl.bodies")" '"license":"MIT"'
  assert_not_contains "no AGPL" "$(cat "$WORK/curl.bodies")" "AGPL"
  assert_contains "plan" "$OUT" "create (private) with the MIT license (from config.env)"
  assert_contains "summary" "$OUT" "License      : MIT (from config.env)"
}

test_a_license_in_config_is_used_without_github() {
  setup_hosts
  gitea_only_env
  use_license "PROJECT_LICENSE=MIT"
  run_apply "$ANSWERS_GITEA_ONLY"$'y\n'
  assert_status "apply" 0 "$STATUS"
  assert_contains "Gitea gets MIT" "$(cat "$WORK/curl.bodies")" '"license":"MIT"'
  assert_contains "initialised with it" "$(cat "$WORK/curl.bodies")" '"auto_init":true'
  assert_not_contains "no GitHub call" "$(calls)" "api.github.com"
  assert_contains "the server is asked" "$(calls)" "/licenses"
}

test_the_license_key_is_taken_in_any_case_for_none() {
  setup_hosts
  use_license "PROJECT_LICENSE=NONE"
  run_apply "$ANSWERS_GITHUB_PUBLIC"$'y\n'
  assert_status "apply" 0 "$STATUS"
  assert_not_contains "no license" "$(cat "$WORK/curl.bodies")" '"license"'
}

# ------------------------------------------------------------------- none

test_none_gives_no_license_even_for_a_public_project_with_github() {
  setup_hosts
  use_license "PROJECT_LICENSE=none"
  run_apply "$ANSWERS_GITHUB_PUBLIC"$'y\n'
  assert_status "apply" 0 "$STATUS"
  assert_not_contains "no license" "$(cat "$WORK/curl.bodies")" '"license"'
  assert_not_contains "no license lookup" "$(calls)" "/licenses"
  assert_contains "plan" "$OUT" "create (public), empty"
  assert_contains "summary" "$OUT" "License      : none (from config.env)"
}

# ----------------------------------------------------------------- absent

test_without_the_key_a_public_project_with_github_gets_agpl() {
  setup_hosts
  run_dry "$ANSWERS_GITHUB_PUBLIC"
  assert_status "dry run" 0 "$STATUS"
  assert_contains "plan" "$OUT" "with the AGPL-3.0 license (default: GitHub and a public project)"
  assert_contains "summary" "$OUT" "License      : AGPL-3.0 (default: GitHub and a public project)"
}

test_without_the_key_a_private_project_with_github_gets_no_license() {
  setup_hosts
  run_dry "$ANSWERS_GITHUB"
  assert_status "dry run" 0 "$STATUS"
  assert_contains "summary" "$OUT" "License      : none (no default for a private project)"
  assert_not_contains "no license lookup" "$(calls)" "/licenses"
}

test_without_the_key_a_project_without_github_gets_no_license() {
  setup_hosts
  gitea_only_env
  run_dry "$ANSWERS_GITEA_ONLY_PUBLIC"
  assert_status "dry run" 0 "$STATUS"
  assert_contains "summary" "$OUT" "License      : none"
  assert_not_contains "no marker" "$OUT" "License      : none ("
  assert_not_contains "no license lookup" "$(calls)" "/licenses"
}

# ---------------------------------------------------- empty and invalid

test_an_empty_license_stops_before_any_request() {
  setup_hosts
  printf 'PROJECT_LICENSE=\n' >>"$WORK/config.env"
  run_dry "$ANSWERS_GITHUB"
  assert_status "empty" 1 "$STATUS"
  assert_contains "key named" "$ERR" "PROJECT_LICENSE in"
  assert_contains "says empty" "$ERR" "is empty"
  assert_eq "no request to any host" "" "$(calls)"
}

test_an_invalid_license_stops_before_any_request_and_is_never_asked() {
  local value
  for value in 'bad license' 'MIT/2' 'MIT;rm' "$(printf 'a%.0s' {1..65})"; do
    remove_workdir
    new_workdir
    setup_hosts
    printf 'PROJECT_LICENSE=%s\n' "$value" >>"$WORK/config.env"
    run_dry "$ANSWERS_GITHUB"
    assert_status "invalid '$value'" 1 "$STATUS"
    assert_contains "key named" "$ERR" "PROJECT_LICENSE in"
    assert_eq "no request to any host" "" "$(calls)"
    assert_not_contains "never asked" "$ERR" "License ("
  done
}

# ------------------------------------------------------ not offered

test_a_license_the_server_does_not_offer_stops_before_anything_is_created() {
  setup_hosts
  use_license "PROJECT_LICENSE=Zlib"
  run_apply "$ANSWERS_GITHUB"$'y\n'
  assert_status "not offered" 1 "$STATUS"
  assert_contains "license named" "$ERR" "does not offer the Zlib license"
  assert_not_contains "nothing created" "$(calls)" "POST"
}

# ------------------------------------------------------- never asked

test_the_license_is_never_asked() {
  setup_hosts
  run_dry "$ANSWERS_GITHUB_PUBLIC"
  assert_not_contains "no license prompt" "$ERR" "icense ("
  assert_not_contains "no license prompt, any case" "$ERR" "License:"
  remove_workdir
  new_workdir
  setup_hosts
  use_license "PROJECT_LICENSE=MIT"
  run_dry "$ANSWERS_GITHUB"
  assert_not_contains "no license prompt with the key" "$ERR" "icense ("
}

# ------------------------------------------- mirror and local history

test_the_license_file_reaches_the_local_project_without_github() {
  setup_hosts
  gitea_only_env
  use_license "PROJECT_LICENSE=MIT"
  local dir="$WORK/project" answers
  printf -v answers 'my-app\n\n\nTirSystem\nn\n%s\nn\n' "$dir"
  run_apply "$answers"$'y\n'
  assert_status "apply" 0 "$STATUS"
  assert_eq "the Gitea license commit is the whole history" "1" "$(GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_CONFIG_NOSYSTEM=1 git -C "$dir" rev-list --count HEAD)"
  assert_file_exists "LICENSE from Gitea" "$dir/LICENSE"
}
