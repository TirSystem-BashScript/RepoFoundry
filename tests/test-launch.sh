#!/usr/bin/env bash
# test-launch.sh - tests for MIL-007: the framework's own submodules (qc) are
# fetched, the script starts through a link, and the configuration files are
# --config and --env, else ./config.env and ./.env, else the checkout's.
# Sourced by run-tests.sh.

# shellcheck disable=SC2016  # snippet and fixture text is literal on purpose

# make_checkout: a copy of the script's own files with config.env and .env
# beside them, standing in for the checkout; the path is in CHECKOUT.
make_checkout() {
  CHECKOUT="$(cd "$WORK" && pwd -P)/checkout"
  mkdir -p "$CHECKOUT"
  cp -R "$SRC_DIR" "$CHECKOUT/src"
  cp "$WORK/config.env" "$CHECKOUT/config.env"
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$CHECKOUT/.env"
}

# make_folder: an empty working folder; the path is in FOLDER.
make_folder() {
  FOLDER="$(cd "$WORK" && pwd -P)/folder"
  mkdir -p "$FOLDER"
}

# run_from SCRIPT_PATH DIR INPUT ARGS...: run the script with DIR as the
# current folder.
run_from() {
  local script="$1" dir="$2" input="$3"
  shift 3
  STATUS=0
  (cd "$dir" && PATH="$WORK/bin:$PATH" STUB_DIR="$WORK" TMPDIR="$WORK/tmp" \
    REPOFOUNDRY_SYNC_WAIT=0 GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_CONFIG_NOSYSTEM=1 \
    "$BASH" "$script" "$@" <<<"$input" >"$WORK/out.txt" 2>"$WORK/err.txt") ||
    STATUS=$?
  OUT="$(cat "$WORK/out.txt")"
  ERR="$(cat "$WORK/err.txt")"
}

# --------------------------------------------------- the framework's qc

test_the_framework_checklists_are_fetched() {
  setup_hosts
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$WORK/.env"
  local dir="$WORK/project" answers
  printf -v answers 'my-app\n\n\nTirSystem\nn\n%s\nn\n' "$dir"
  run_apply "$answers"$'y\n'
  assert_status "apply" 0 "$STATUS"
  assert_file_exists "the framework" "$dir/framework/README.md"
  assert_file_exists "qc is filled" "$dir/framework/qc/qc-business-case.md"
  assert_eq "no submodule is left uninitialised" "" "$(GIT_CONFIG_GLOBAL="$WORK/gitconfig" git -C "$dir" submodule status --recursive | grep '^-' || true)"
}

test_an_empty_qc_is_filled_by_a_second_run_and_a_complete_one_is_not_changed() {
  setup_hosts
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$WORK/.env"
  local dir="$WORK/project" answers git_in
  printf -v answers 'my-app\n\n\nTirSystem\nn\n%s\nn\n' "$dir"
  run_apply "$answers"$'y\n'
  assert_status "first run" 0 "$STATUS"
  git_in() { GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_CONFIG_NOSYSTEM=1 git -C "$dir/framework" "$@"; }
  git_in submodule deinit -f qc >/dev/null 2>&1
  assert_file_missing "qc emptied" "$dir/framework/qc/qc-business-case.md"
  run_lib "" "init_framework_submodules '$dir'"
  assert_status "repair" 0 "$STATUS"
  assert_file_exists "qc filled again" "$dir/framework/qc/qc-business-case.md"
  local before after
  before="$(git_in status --porcelain)"
  run_lib "" "init_framework_submodules '$dir'"
  after="$(git_in status --porcelain)"
  assert_status "second call" 0 "$STATUS"
  assert_eq "nothing else changed" "$before" "$after"
}

test_a_failed_qc_fetch_names_the_command_to_run_by_hand() {
  setup_hosts
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$WORK/.env"
  local dir="$WORK/project" answers
  printf -v answers 'my-app\n\n\nTirSystem\nn\n%s\nn\n' "$dir"
  run_apply "$answers"$'y\n'
  GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_CONFIG_NOSYSTEM=1 git -C "$dir/framework" submodule deinit -f qc >/dev/null 2>&1
  printf '[url "file://%s/nowhere/"]\n\tinsteadOf = ssh://git@git.tirsystem.com:10022/\n' "$WORK" >>"$WORK/gitconfig"
  GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_CONFIG_NOSYSTEM=1 git -C "$dir/framework" config --unset-all submodule.qc.url >/dev/null 2>&1 || true
  run_lib "" "init_framework_submodules '$dir'"
  if ((STATUS == 0)); then
    # The earlier alias still wins in this git; remove the working alias instead.
    sed -i '/remote\/"\]/,+1d' "$WORK/gitconfig"
    run_lib "" "init_framework_submodules '$dir'"
  fi
  assert_status "fetch fails" 1 "$STATUS"
  assert_contains "the command" "$ERR" "git submodule update --init --recursive"
  assert_not_contains "no token" "$ERR" "$FAKE_GITEA_TOKEN"
}

test_a_framework_without_a_submodule_of_its_own_is_not_a_failure() {
  setup_hosts
  local dir="$WORK/plain"
  mkdir -p "$dir"
  git init -q "$dir"
  run_lib "" "init_framework_submodules '$dir'"
  assert_status "nothing to fetch" 0 "$STATUS"
}

# ------------------------------------------------ the configuration files

test_files_in_the_working_folder_are_used_after_a_yes() {
  setup_hosts
  make_checkout
  make_folder
  cp "$WORK/config.env" "$FOLDER/config.env"
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$FOLDER/.env"
  run_from "$SCRIPT" "$FOLDER" $'y\n'"$ANSWERS_GITEA_ONLY"
  assert_status "folder files" 0 "$STATUS"
  assert_contains "config named" "$OUT" "Config file     : $FOLDER/config.env (from the working folder)"
  assert_contains "credentials named" "$OUT" "Credentials file: $FOLDER/.env (from the working folder)"
  assert_contains "the address is named" "$OUT" "Gitea would be https://git.example.test"
  assert_contains "asked" "$ERR" "Use $FOLDER/config.env $FOLDER/.env (y/n) [n]"
}

test_files_in_the_working_folder_are_not_used_without_a_yes() {
  setup_hosts
  make_checkout
  make_folder
  cp "$WORK/config.env" "$FOLDER/config.env"
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$FOLDER/.env"
  rm -f "$WORK/curl.calls"
  run_from "$SCRIPT" "$FOLDER" $'\n'"$ANSWERS_GITEA_ONLY"
  assert_status "default no" 1 "$STATUS"
  assert_contains "stopped" "$ERR" "stopped before any request"
  assert_eq "no request to any host" "" "$(calls)"
}

test_named_files_win_and_are_not_confirmed() {
  setup_hosts
  make_checkout
  make_folder
  cp "$WORK/config.env" "$FOLDER/config.env"
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$FOLDER/.env"
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$WORK/.env"
  run_from "$SCRIPT" "$FOLDER" "$ANSWERS_GITEA_ONLY" --config "$WORK/config.env" --env "$WORK/.env"
  assert_status "named files" 0 "$STATUS"
  assert_contains "named" "$OUT" "Config file     : $WORK/config.env (named on the command line)"
  assert_not_contains "no confirmation" "$OUT" "The working folder supplies"
}

test_the_checkouts_files_are_used_when_the_folder_has_none() {
  setup_hosts
  make_checkout
  make_folder
  run_from "$CHECKOUT/src/create-project.sh" "$FOLDER" "$ANSWERS_GITEA_ONLY"
  assert_status "checkout files" 0 "$STATUS"
  assert_contains "config named" "$OUT" "Config file     : $CHECKOUT/config.env (from the checkout)"
  assert_contains "credentials named" "$OUT" "Credentials file: $CHECKOUT/.env (from the checkout)"
  assert_not_contains "no confirmation" "$OUT" "The working folder supplies"
}

test_each_file_is_chosen_on_its_own() {
  setup_hosts
  make_checkout
  make_folder
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$FOLDER/.env"
  run_from "$CHECKOUT/src/create-project.sh" "$FOLDER" $'y\n'"$ANSWERS_GITEA_ONLY"
  assert_status "mixed" 0 "$STATUS"
  assert_contains "config from the checkout" "$OUT" "Config file     : $CHECKOUT/config.env (from the checkout)"
  assert_contains "credentials from the folder" "$OUT" "Credentials file: $FOLDER/.env (from the working folder)"
  assert_contains "asked about the folder file only" "$ERR" "Use $FOLDER/.env (y/n) [n]"
}

test_files_found_nowhere_stop_before_any_request_and_name_both_places() {
  setup_hosts
  make_checkout
  make_folder
  rm -f "$CHECKOUT/.env" "$WORK/curl.calls"
  run_from "$CHECKOUT/src/create-project.sh" "$FOLDER" "$ANSWERS_GITEA_ONLY"
  assert_status "no .env anywhere" 1 "$STATUS"
  assert_contains "working folder named" "$ERR" "working folder ($FOLDER)"
  assert_contains "checkout named" "$ERR" "checkout ($CHECKOUT)"
  assert_contains "the option" "$ERR" "--env FILE"
  assert_eq "no request to any host" "" "$(calls)"
}

# ----------------------------------------------------------- a link to it

test_the_script_runs_through_a_link_and_creates_the_project_in_the_current_folder() {
  setup_hosts
  make_checkout
  make_folder
  local bin="$WORK/linkbin"
  mkdir -p "$bin"
  ln -s "$CHECKOUT/src/create-project.sh" "$bin/repo-foundry" 2>/dev/null || true
  if [[ ! -L $bin/repo-foundry ]]; then
    printf 'skipped: this shell cannot make symbolic links\n'
    return 0
  fi
  run_from "$bin/repo-foundry" "$FOLDER" "" --version
  assert_status "version through the link" 0 "$STATUS"
  assert_contains "found its files" "$OUT" "RepoFoundry"
  run_from "$bin/repo-foundry" "$FOLDER" "$ANSWERS_GITEA_ONLY"$'y\n' --apply
  assert_status "apply through the link" 0 "$STATUS"
  assert_contains "the checkout's files" "$OUT" "Config file     : $CHECKOUT/config.env (from the checkout)"
  assert_file_exists "the project is in the current folder" "$FOLDER/my-app/.git"
  assert_file_missing "not in the checkout" "$CHECKOUT/my-app"
}

test_a_link_to_a_link_is_followed() {
  setup_hosts
  make_checkout
  make_folder
  local bin="$WORK/linkbin"
  mkdir -p "$bin"
  ln -s "$CHECKOUT/src/create-project.sh" "$bin/first" 2>/dev/null || true
  [[ -L $bin/first ]] || {
    printf 'skipped: this shell cannot make symbolic links\n'
    return 0
  }
  (cd "$bin" && ln -s first second)
  run_from "$bin/second" "$FOLDER" "" --version
  assert_status "second link" 0 "$STATUS"
}
