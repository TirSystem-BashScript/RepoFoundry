#!/usr/bin/env bash
# test-local.sh - tests for the local project (MIL-003): the directory, the
# git repository and its remotes, the framework submodule, skills, hooks and
# plan gate, and the templates. Real git runs here, against local bare
# repositories that stand in for Gitea and the framework (git rewrites the
# remote addresses, see write_gitconfig); only the two hosts' APIs are stubs.
# Sourced by run-tests.sh.

# shellcheck disable=SC2016  # snippet and fixture text is literal on purpose

# local_answers DIR GITHUB GATE: the prompt answers; the result is in
# LOCAL_ANSWERS (kept in a variable because $(...) would drop the last newline).
local_answers() {
  if [[ $2 == y ]]; then
    printf -v LOCAL_ANSWERS 'my-app\nA test app\n\nTirSystem\ny\nacme-org\n%s\n%s\n' "$1" "$3"
  else
    printf -v LOCAL_ANSWERS 'my-app\n\n\nTirSystem\nn\n%s\n%s\n' "$1" "$3"
  fi
}

# project_git DIR ARGS...: git in the project with the tests' own config.
project_git() {
  local dir="$1"
  shift
  GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_CONFIG_NOSYSTEM=1 git -C "$dir" "$@"
}

# files_with_secret DIR: any file below DIR (the .git folder included) that
# holds one of the fake tokens.
files_with_secret() {
  grep -rlF -e "$FAKE_GITEA_TOKEN" -e "$FAKE_GITHUB_PAT" "$1" 2>/dev/null || true
}

readonly SSH_FRAMEWORK_URL="ssh://git@git.example.test:10022/TirSystem/SQA-QC-Framework.git"

# ----------------------------------------------------- directory and remotes

test_local_project_gets_credential_free_remotes_and_the_license_history() {
  setup_hosts
  local dir="$WORK/project"
  local_answers "$dir" y n
  run_apply "$LOCAL_ANSWERS"$'y\n'
  assert_status "apply" 0 "$STATUS"
  assert_file_exists "directory created" "$dir/.git"
  assert_eq "branch is main" "main" "$(project_git "$dir" symbolic-ref --short HEAD)"
  assert_eq "origin over SSH, no credential" "ssh://git@git.example.test:10022/TirSystem/my-app.git" "$(project_git "$dir" config --get remote.origin.url)"
  assert_eq "github remote over HTTPS, no credential" "https://github.com/acme-org/my-app.git" "$(project_git "$dir" config --get remote.github.url)"
  assert_eq "the license commit is the whole history" "1" "$(project_git "$dir" rev-list --count HEAD)"
  assert_eq "it is the Gitea commit" "Initial commit" "$(project_git "$dir" log -1 --format=%s)"
  assert_file_exists "LICENSE from Gitea" "$dir/LICENSE"
  assert_eq "branch follows origin" "origin" "$(project_git "$dir" config --get branch.main.remote)"
  assert_eq "no token in any file of the project" "" "$(files_with_secret "$dir")"
  assert_contains "reported" "$OUT" "Local project     : created $dir (origin over SSH)"
}

test_gitea_only_project_has_no_github_remote_and_no_commit() {
  setup_hosts
  printf 'GITEA_TOKEN=%s\n' "$FAKE_GITEA_TOKEN" >"$WORK/.env"
  local dir="$WORK/project"
  local_answers "$dir" n n
  run_apply "$LOCAL_ANSWERS"$'y\n'
  assert_status "apply" 0 "$STATUS"
  assert_eq "origin" "ssh://git@git.example.test:10022/TirSystem/my-app.git" "$(project_git "$dir" config --get remote.origin.url)"
  assert_eq "no github remote" "" "$(project_git "$dir" config --get remote.github.url || true)"
  assert_file_missing "no license file" "$dir/LICENSE"
  assert_eq "no commit was made" "0" "$(project_git "$dir" rev-list --all --count)"
  assert_eq "no token in any file" "" "$(files_with_secret "$dir")"
}

test_existing_directory_is_used_only_after_a_yes() {
  setup_hosts
  local dir="$WORK/project"
  mkdir -p "$dir"
  printf 'mine\n' >"$dir/keep.txt"
  local_answers "$dir" y n
  run_apply "$LOCAL_ANSWERS"$'y\nn\n'
  assert_status "answered no" 1 "$STATUS"
  assert_contains "asked" "$ERR" "The directory $dir already exists and already has files. Use it"
  assert_contains "stopped" "$ERR" "stopped: choose another directory or remove this one"
  assert_file_missing "nothing added to the directory" "$dir/.git"
  assert_not_contains "no repository created before the answer" "$(calls)" "POST"
  run_apply "$LOCAL_ANSWERS"$'y\ny\n'
  assert_status "answered yes" 0 "$STATUS"
  assert_eq "the existing file is untouched" "mine" "$(cat "$dir/keep.txt")"
  assert_file_exists "project created beside it" "$dir/.git"
}

test_an_empty_existing_directory_is_also_confirmed() {
  setup_hosts
  local dir="$WORK/project"
  mkdir -p "$dir"
  local_answers "$dir" y n
  run_apply "$LOCAL_ANSWERS"$'y\ny\n'
  assert_status "empty directory, yes" 0 "$STATUS"
  assert_contains "asked" "$ERR" "already exists and is empty. Use it"
}

test_a_file_that_would_be_overwritten_by_the_license_history_is_kept() {
  setup_hosts
  local dir="$WORK/project"
  mkdir -p "$dir"
  printf 'my own license\n' >"$dir/LICENSE"
  local_answers "$dir" y n
  run_apply "$LOCAL_ANSWERS"$'y\ny\n'
  assert_status "git refuses to overwrite" 1 "$STATUS"
  assert_contains "says why" "$ERR" "git would overwrite files in $dir"
  assert_eq "the file is intact" "my own license" "$(cat "$dir/LICENSE")"
  assert_contains "step failed" "$OUT" "Local project     : FAILED"
  assert_contains "later steps not attempted" "$OUT" "Framework         : not attempted"
}

test_a_remote_with_another_address_is_never_replaced() {
  setup_hosts
  local dir="$WORK/project"
  mkdir -p "$dir"
  project_git "$dir" init -q
  project_git "$dir" remote add origin https://elsewhere.example.test/x/y.git
  local_answers "$dir" y n
  run_apply "$LOCAL_ANSWERS"$'y\ny\n'
  assert_status "different origin" 1 "$STATUS"
  assert_contains "says so" "$ERR" "the remote 'origin' in $dir already points to https://elsewhere.example.test/x/y.git"
  assert_eq "origin unchanged" "https://elsewhere.example.test/x/y.git" "$(project_git "$dir" config --get remote.origin.url)"
}

# ---------------------------------------------------------------- framework

test_framework_is_a_submodule_and_installed_in_order() {
  setup_hosts
  local dir="$WORK/project"
  local_answers "$dir" y n
  run_apply "$LOCAL_ANSWERS"$'y\n'
  assert_status "apply" 0 "$STATUS"
  assert_eq "submodule address" "$SSH_FRAMEWORK_URL" "$(project_git "$dir" config -f .gitmodules --get submodule.framework.url)"
  assert_file_exists "submodule content" "$dir/framework/scripts/install-skills.sh"
  assert_file_exists "skills installed" "$dir/.claude/skills/coding-conventions/SKILL.md"
  assert_file_exists "skills for the other harness" "$dir/.agents/skills/.framework-skills"
  assert_eq "hooks path" "framework/githooks" "$(project_git "$dir" config --local --get core.hooksPath)"
  assert_eq "plan gate off" "" "$(project_git "$dir" config --local --get planGate.enabled || true)"
  assert_contains "reported" "$OUT" "Framework         : created $SSH_FRAMEWORK_URL"
  assert_contains "reported once" "$OUT" "Skills and hooks  : created (skills installed; hooks installed; plan gate off)"
}

test_skills_and_hooks_are_installed_once() {
  setup_hosts
  local dir="$WORK/project"
  local_answers "$dir" y n
  run_apply "$LOCAL_ANSWERS"$'y\n'
  assert_status "first run" 0 "$STATUS"
  run_lib "" "PROJECT[directory]='$dir'
PROJECT[is_plan_gate_enabled]=0
install_framework
echo \"\${STATE[skills_note]}|\${STATE[hooks_note]}\""
  assert_status "second pass" 0 "$STATUS"
  assert_eq "nothing installed twice" "skills already installed|hooks already installed" "$OUT"
}

test_the_plan_gate_is_optional_and_refuses_unplanned_commits() {
  setup_hosts
  local dir="$WORK/project" out
  local_answers "$dir" y y
  run_apply "$LOCAL_ANSWERS"$'y\n'
  assert_status "apply with the plan gate" 0 "$STATUS"
  assert_eq "plan gate on" "true" "$(project_git "$dir" config --local --get planGate.enabled)"
  assert_contains "reported" "$OUT" "plan gate on)"
  # The hooks refuse a commit on main, so work on a branch.
  project_git "$dir" checkout -q -b work
  mkdir -p "$dir/src"
  printf 'x\n' >"$dir/src/x.txt"
  project_git "$dir" add src/x.txt
  out="$(project_git "$dir" commit -q -m "unplanned change" 2>&1 || true)"
  assert_contains "refused without a task trailer" "$out" "plan-first gate: no 'Task: MIL-NNN#N' trailer"
  assert_eq "no commit was made" "1" "$(project_git "$dir" rev-list --count HEAD)"
}

test_without_the_plan_gate_the_same_commit_is_allowed() {
  setup_hosts
  local dir="$WORK/project"
  local_answers "$dir" y n
  run_apply "$LOCAL_ANSWERS"$'y\n'
  project_git "$dir" checkout -q -b work
  mkdir -p "$dir/src"
  printf 'x\n' >"$dir/src/x.txt"
  project_git "$dir" add src/x.txt
  project_git "$dir" commit -q -m "change"
  assert_eq "commit made" "2" "$(project_git "$dir" rev-list --count HEAD)"
}

test_the_hooks_refuse_a_commit_on_main() {
  setup_hosts
  local dir="$WORK/project" out
  local_answers "$dir" y n
  run_apply "$LOCAL_ANSWERS"$'y\n'
  printf 'x\n' >"$dir/x.txt"
  project_git "$dir" add x.txt
  out="$(project_git "$dir" commit -q -m "on main" 2>&1 || true)"
  assert_contains "refused on main" "$out" "refusing to commit directly on 'main'"
}

test_an_existing_hooks_path_is_not_replaced_without_a_yes() {
  setup_hosts
  local dir="$WORK/project"
  mkdir -p "$dir"
  project_git "$dir" init -q
  project_git "$dir" config core.hooksPath .githooks
  local_answers "$dir" y y
  # create now, use the directory, keep the hooks path
  run_apply "$LOCAL_ANSWERS"$'y\ny\nn\n'
  assert_status "run continues" 0 "$STATUS"
  assert_contains "asked" "$ERR" "core.hooksPath is already '.githooks'. Replace it with framework/githooks"
  assert_eq "hooks path kept" ".githooks" "$(project_git "$dir" config --local --get core.hooksPath)"
  assert_contains "reported" "$OUT" "kept the existing hooks path '.githooks'"
  assert_contains "the plan gate is not on without the hooks" "$ERR" "the plan gate is not enabled because the framework hooks were not installed"
  # Answering yes replaces it.
  run_apply "$LOCAL_ANSWERS"$'y\ny\ny\n'
  assert_eq "hooks path replaced after a yes" "framework/githooks" "$(project_git "$dir" config --local --get core.hooksPath)"
}

test_a_global_hooks_path_is_reported_not_changed() {
  setup_hosts
  git config --file "$WORK/gitconfig" core.hooksPath /somewhere/global-hooks
  local dir="$WORK/project"
  local_answers "$dir" y n
  run_apply "$LOCAL_ANSWERS"$'y\n'
  assert_status "apply" 0 "$STATUS"
  assert_contains "warns" "$ERR" "your global core.hooksPath is '/somewhere/global-hooks'"
  assert_eq "the global setting is untouched" "/somewhere/global-hooks" "$(git config --file "$WORK/gitconfig" --get core.hooksPath)"
  assert_eq "the project has its own" "framework/githooks" "$(project_git "$dir" config --local --get core.hooksPath)"
}

test_a_project_root_in_the_environment_cannot_redirect_the_framework_scripts() {
  setup_hosts
  local dir="$WORK/project"
  local_answers "$dir" y n
  PROJECT_ROOT="$WORK/elsewhere" run_apply "$LOCAL_ANSWERS"$'y\n'
  assert_status "apply" 0 "$STATUS"
  assert_file_missing "nothing installed where the environment pointed" "$WORK/elsewhere"
  assert_file_exists "installed in the project" "$dir/.claude/skills/.framework-skills"
}

# ---------------------------------------------------------------- templates

test_templates_are_copied() {
  setup_hosts
  local dir="$WORK/project"
  local_answers "$dir" y n
  run_apply "$LOCAL_ANSWERS"$'y\n'
  assert_status "apply" 0 "$STATUS"
  assert_eq "AGENTS.md is the template" "$(cat "$dir/framework/templates/AGENTS-template.md")" "$(cat "$dir/AGENTS.md")"
  assert_eq "registry is the template" "$(cat "$dir/framework/templates/artifact-registry-template.md")" "$(cat "$dir/docs/artifact-registry.md")"
  assert_contains "reported" "$OUT" "Templates         : created (copied AGENTS.md; copied docs/artifact-registry.md)"
}

test_existing_template_targets_are_replaced_only_after_a_yes() {
  setup_hosts
  local dir="$WORK/project"
  mkdir -p "$dir/docs"
  printf 'my agents file\n' >"$dir/AGENTS.md"
  printf 'my registry\n' >"$dir/docs/artifact-registry.md"
  local_answers "$dir" y n
  # create now, use the directory, keep AGENTS.md, replace the registry
  run_apply "$LOCAL_ANSWERS"$'y\ny\nn\ny\n'
  assert_status "apply" 0 "$STATUS"
  assert_contains "asked about AGENTS.md" "$ERR" "AGENTS.md already exists. Replace it with the framework template"
  assert_eq "AGENTS.md kept" "my agents file" "$(cat "$dir/AGENTS.md")"
  assert_eq "registry replaced after a yes" "$(cat "$dir/framework/templates/artifact-registry-template.md")" "$(cat "$dir/docs/artifact-registry.md")"
  assert_contains "reported" "$OUT" "kept existing AGENTS.md; copied docs/artifact-registry.md"
}

# ----------------------------------------------------------- SSH and errors

test_without_ssh_the_run_stops_unless_the_framework_is_skipped() {
  setup_hosts
  write_ssh_stub 255
  local dir="$WORK/project"
  local_answers "$dir" y n
  run_apply "$LOCAL_ANSWERS"$'y\nn\n'
  assert_status "answered no" 1 "$STATUS"
  assert_contains "explains" "$ERR" "SSH to Gitea (git.example.test port 10022) did not work, so the framework cannot be added"
  assert_contains "says what to do" "$ERR" "stopped: set up SSH access to Gitea (see the README) and run again"
  assert_not_contains "nothing created" "$(calls)" "POST"
  assert_file_missing "no directory" "$dir"
}

test_without_ssh_the_framework_steps_are_skipped_after_a_yes() {
  setup_hosts
  write_ssh_stub 255
  local dir="$WORK/project"
  local_answers "$dir" y n
  run_apply "$LOCAL_ANSWERS"$'y\ny\n'
  assert_status "continue without the framework" 0 "$STATUS"
  assert_eq "origin over HTTPS, no credential" "https://git.example.test/TirSystem/my-app.git" "$(project_git "$dir" config --get remote.origin.url)"
  assert_eq "the license history arrived over HTTPS" "1" "$(project_git "$dir" rev-list --count HEAD)"
  assert_eq "no token in any file" "" "$(files_with_secret "$dir")"
  assert_eq "no temporary files left" "" "$(find "$WORK/tmp" -mindepth 1)"
  assert_contains "framework skipped" "$OUT" "Framework         : skipped (no SSH access to Gitea)"
  assert_contains "skills and hooks skipped" "$OUT" "Skills and hooks  : skipped (no SSH access to Gitea)"
  assert_contains "templates skipped" "$OUT" "Templates         : skipped (no SSH access to Gitea)"
  assert_file_missing "no submodule" "$dir/.gitmodules"
  assert_file_missing "no AGENTS.md" "$dir/AGENTS.md"
}

test_a_failed_submodule_gives_an_actionable_message() {
  setup_hosts
  find "$WORK/remote/TirSystem/SQA-QC-Framework.git" \( -type f -o -type l \) -delete
  find "$WORK/remote/TirSystem/SQA-QC-Framework.git" -depth -type d -exec rmdir {} +
  local dir="$WORK/project"
  local_answers "$dir" y n
  run_apply "$LOCAL_ANSWERS"$'y\n'
  assert_status "no framework repository" 1 "$STATUS"
  assert_contains "names the address" "$ERR" "git could not add the framework from $SSH_FRAMEWORK_URL"
  assert_contains "says how to test the access" "$ERR" "ssh -p 10022 -T git@git.example.test"
  assert_contains "step failed" "$OUT" "Framework         : FAILED"
  assert_contains "the rest not attempted" "$OUT" "Skills and hooks  : not attempted"
  assert_contains "the project itself exists" "$OUT" "Local project     : created"
}

test_the_framework_repository_is_configurable() {
  setup_hosts
  mkdir -p "$WORK/remote/Other"
  cp -R "$WORK/remote/TirSystem/SQA-QC-Framework.git" "$WORK/remote/Other/Framework.git"
  printf 'FRAMEWORK_REPO=Other/Framework\n' >>"$WORK/config.env"
  local dir="$WORK/project"
  local_answers "$dir" y n
  run_apply "$LOCAL_ANSWERS"$'y\n'
  assert_status "apply" 0 "$STATUS"
  assert_eq "submodule address" "ssh://git@git.example.test:10022/Other/Framework.git" "$(project_git "$dir" config -f .gitmodules --get submodule.framework.url)"
}

test_framework_repo_must_look_like_owner_and_name() {
  local value
  for value in "nope" "a/b/c" "../x" "a/.." "a b/c" "/x"; do
    printf 'GITEA_URL=https://git.example.test\nFRAMEWORK_REPO=%s\n' "$value" >"$WORK/c.env"
    run_lib "" "parse_env_file \"$WORK/c.env\" CONFIG_KEYS CONFIG
validate_config"
    assert_status "FRAMEWORK_REPO=$value" 1 "$STATUS"
    assert_contains "message" "$ERR" "FRAMEWORK_REPO"
  done
}

# --------------------------------------------------------------- the plan

test_the_dry_run_plan_describes_the_local_steps_and_creates_nothing() {
  setup_hosts
  local dir="$WORK/project"
  local_answers "$dir" y y
  run_dry "$LOCAL_ANSWERS"
  assert_status "dry run" 0 "$STATUS"
  assert_contains "project" "$OUT" "Local project     : create $dir (new directory), git on main, no commit"
  assert_contains "framework" "$OUT" "Framework         : add $SSH_FRAMEWORK_URL as a submodule"
  assert_contains "skills and hooks" "$OUT" "Skills and hooks  : install once; plan gate yes"
  assert_contains "templates" "$OUT" "Templates         : AGENTS.md and docs/artifact-registry.md (you are asked before a file is replaced)"
  assert_file_missing "nothing created" "$dir"
}

test_the_plan_marks_an_existing_directory_and_missing_ssh() {
  setup_hosts
  local dir="$WORK/project"
  mkdir -p "$dir"
  printf 'x\n' >"$dir/a.txt"
  write_ssh_stub 255
  local_answers "$dir" y n
  run_dry "$LOCAL_ANSWERS"
  assert_contains "existing directory" "$OUT" "use the existing directory $dir, which has files (you will be asked)"
  assert_contains "no SSH" "$OUT" "NOT possible without SSH to Gitea; you will be asked whether to go on without it"
  assert_contains "HTTPS origin" "$OUT" "will use HTTPS (SSH test: failed"
}

test_a_project_path_that_is_a_file_is_refused_in_the_preflight() {
  setup_hosts
  local dir="$WORK/project"
  printf 'x\n' >"$dir"
  local_answers "$dir" y n
  run_dry "$LOCAL_ANSWERS"
  assert_status "path is a file" 1 "$STATUS"
  assert_contains "message" "$ERR" "already exists and is not a directory"
}

# ------------------------------------------------------------------ helpers

test_remote_addresses_are_built_from_the_configuration() {
  run_lib "" 'CONFIG[GITEA_URL]=https://git.example.test/sub
CONFIG[GITEA_SSH_PORT]=2222 CONFIG[FRAMEWORK_REPO]=Org/Fw CONFIG[GITHUB_WEB_URL]=https://github.com
PROJECT[gitea_owner]=TirSystem PROJECT[github_owner]=acme PROJECT[name]=my-app
STATE[is_ssh_ok]=1
origin_url; echo
STATE[is_ssh_ok]=0
origin_url; echo
github_remote_url; echo
framework_url; echo
gitea_host; echo'
  assert_eq "addresses" $'ssh://git@git.example.test:2222/TirSystem/my-app.git\nhttps://git.example.test/sub/TirSystem/my-app.git\nhttps://github.com/acme/my-app.git\nssh://git@git.example.test:2222/Org/Fw.git\ngit.example.test' "$OUT"
}

test_the_https_fetch_hands_the_token_over_through_the_environment_only() {
  # A stub git plays the part of the server asking for credentials: it runs
  # the GIT_ASKPASS helper the way git does and records the answers.
  local real_git
  real_git="$(command -v git)"
  write_stub git "
if [[ \$* == *'config --get remote.origin.url'* ]]; then echo https://git.example.test/TirSystem/my-app.git; exit 0; fi
if [[ \$* == *fetch* ]]; then
  printf '%s\n' \"\$@\" >>\"\$STUB_DIR/git.args\"
  \"\$GIT_ASKPASS\" 'Username for https://git.example.test: ' >>\"\$STUB_DIR/askpass.out\"
  \"\$GIT_ASKPASS\" 'Password for https://git.example.test: ' >>\"\$STUB_DIR/askpass.out\"
  exit 0
fi
exec '$real_git' \"\$@\""
  run_lib "" "setup_temp_dir
STATE[gitea_login]=gitea-user
CREDENTIALS[GITEA_TOKEN]='$FAKE_GITEA_TOKEN'
fetch_origin '$WORK'
cleanup"
  assert_status "fetch" 0 "$STATUS"
  assert_eq "user name and token reach git" $'gitea-user\n'"$FAKE_GITEA_TOKEN" "$(cat "$WORK/askpass.out")"
  assert_not_contains "token not on the git command line" "$(cat "$WORK/git.args")" "$FAKE_GITEA_TOKEN"
  assert_eq "the helper is removed" "" "$(find "$WORK/tmp" -mindepth 1)"
}

test_a_failed_https_fetch_is_reported_to_the_caller() {
  write_stub git "
if [[ \$* == *'config --get remote.origin.url'* ]]; then echo https://git.example.test/TirSystem/my-app.git; exit 0; fi
if [[ \$* == *fetch* ]]; then exit 128; fi
exit 0"
  run_lib "" "setup_temp_dir
STATE[gitea_login]=gitea-user
CREDENTIALS[GITEA_TOKEN]='$FAKE_GITEA_TOKEN'
if fetch_origin '$WORK'; then echo ok; else echo failed; fi
cleanup"
  assert_eq "failure passed on" "failed" "$OUT"
  assert_eq "the helper is removed" "" "$(find "$WORK/tmp" -mindepth 1)"
}
