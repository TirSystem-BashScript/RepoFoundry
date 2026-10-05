#!/usr/bin/env bash
# test-prompts.sh - tests for the interactive prompts and their validation
# (MIL-001 task: prompts). Answers are piped to stdin. Sourced by
# run-tests.sh.

# shellcheck disable=SC2016  # snippet and fixture text is literal on purpose
test_prompt_value_asks_again_until_valid() {
  run_lib $'bad name\n..\nok-name\n' \
    'prompt_value "Repository name" "" is_valid_repo_name "use letters"; echo "[$REPLY]"'
  assert_status "retries" 0 "$STATUS"
  assert_eq "valid answer returned" "[ok-name]" "$OUT"
  assert_contains "told why" "$ERR" "invalid Repository name: use letters"
}

test_prompt_value_uses_the_default() {
  run_lib $'\n' \
    'prompt_value "Local directory" "./proj" is_valid_directory "x"; echo "[$REPLY]"'
  assert_eq "default taken" "[./proj]" "$OUT"
}

test_prompt_stops_when_input_ends() {
  run_lib "" 'prompt_value "Repository name" "" is_valid_repo_name "x" </dev/null'
  assert_status "end of input" 1 "$STATUS"
  assert_contains "message" "$ERR" "no input available for 'Repository name'"
}

test_prompt_choice() {
  run_lib $'PUBLIC\n' 'prompt_choice "Visibility" private private public; echo "[$REPLY]"'
  assert_eq "case-insensitive choice" "[public]" "$OUT"
  run_lib $'\n' 'prompt_choice "Visibility" private private public; echo "[$REPLY]"'
  assert_eq "default choice" "[private]" "$OUT"
  run_lib $'secret\nprivate\n' 'prompt_choice "Visibility" private private public; echo "[$REPLY]"'
  assert_eq "invalid then valid" "[private]" "$OUT"
  assert_contains "told the options" "$ERR" "choose one of private public"
}

test_prompt_yes_no() {
  local answer expected
  while IFS='|' read -r answer expected; do
    run_lib "$answer"$'\n' 'prompt_yes_no "Use GitHub" y; echo "[$REPLY]"'
    assert_eq "answer '$answer'" "[$expected]" "$OUT"
  done <<'EOF'
|1
y|1
YES|1
n|0
No|0
EOF
  run_lib $'maybe\nn\n' 'prompt_yes_no "Use GitHub" y; echo "[$REPLY]"'
  assert_eq "invalid then valid" "[0]" "$OUT"
  assert_contains "told what to answer" "$ERR" "answer y or n"
}

test_collect_details_with_github() {
  run_lib $'my-app\nA test app\npublic\nTirSystem\ny\nmy-org\n\ny\n' \
    'collect_project_details
for k in name description visibility gitea_owner has_github github_owner directory is_plan_gate_enabled; do
  printf "%s=%s\n" "$k" "${PROJECT[$k]}"
done'
  assert_status "details collected" 0 "$STATUS"
  assert_eq "details" $'name=my-app\ndescription=A test app\nvisibility=public\ngitea_owner=TirSystem\nhas_github=1\ngithub_owner=my-org\ndirectory=./my-app\nis_plan_gate_enabled=1' "$OUT"
}

test_collect_details_without_github() {
  run_lib $'my-app\n\n\nTirSystem\nn\n\nn\n' \
    'collect_project_details
printf "%s|%s|%s|%s\n" "${PROJECT[visibility]}" "${PROJECT[has_github]}" "[${PROJECT[github_owner]}]" "${PROJECT[is_plan_gate_enabled]}"'
  assert_status "GitHub skipped" 0 "$STATUS"
  assert_eq "defaults and no GitHub owner" "private|0|[]|0" "$OUT"
  assert_not_contains "no GitHub owner prompt" "$ERR" "GitHub owner"
}

test_github_user_is_a_default_not_the_owner() {
  # GITHUB_USER only pre-fills the prompt; the Maintainer can pick an
  # organization instead.
  run_lib $'my-app\n\n\nTirSystem\ny\n\n\nn\n' \
    'CREDENTIALS[GITHUB_USER]=octo-user
collect_project_details
echo "${PROJECT[github_owner]}"'
  assert_eq "default is the account" "octo-user" "$OUT"
  run_lib $'my-app\n\n\nTirSystem\ny\nacme-org\n\nn\n' \
    'CREDENTIALS[GITHUB_USER]=octo-user
collect_project_details
echo "${PROJECT[github_owner]}"'
  assert_eq "organization chosen" "acme-org" "$OUT"
}
