#!/usr/bin/env bash
# test-presets.sh - tests for the project details preset in config.env
# (MIL-004): a detail that is set there is not asked, an invalid one stops
# the run, and the confirmations stay interactive. Sourced by run-tests.sh.

# shellcheck disable=SC2016  # snippet and fixture text is literal on purpose

# The eight keys with a value that differs from the answer given when asked.
readonly PRESET_ALL='PROJECT_NAME=preset-app
PROJECT_DESCRIPTION=From the config
PROJECT_VISIBILITY=public
GITEA_OWNER=PresetOrg
USE_GITHUB=yes
GITHUB_OWNER=preset-gh
PROJECT_DIRECTORY=./preset-dir
ENABLE_PLAN_GATE=yes'

# The same details as ANSWERS_GITHUB, so a run with all of them preset is the
# same run with no answers.
readonly PRESET_LIKE_ANSWERS='PROJECT_NAME=my-app
PROJECT_DESCRIPTION=A test app
PROJECT_VISIBILITY=private
GITEA_OWNER=TirSystem
USE_GITHUB=yes
GITHUB_OWNER=acme-org
PROJECT_DIRECTORY=./my-app
ENABLE_PLAN_GATE=no'

# collect_with PRESET_LINES INPUT: parse a config holding the preset lines,
# collect the details and print them one per line.
collect_with() {
  printf '%s\n' "$1" >"$WORK/preset.env"
  run_lib "$2" 'parse_env_file "'"$WORK"'/preset.env" CONFIG_KEYS CONFIG
validate_project_presets
collect_project_details
for k in name description visibility gitea_owner has_github github_owner directory is_plan_gate_enabled; do
  printf "%s=%s\n" "$k" "${PROJECT[$k]}"
done'
}

# Each key, the answers a run gives for the other seven details, and the
# prompt that must not be shown for the key.
test_each_key_is_used_and_not_asked() {
  local key value field label line input
  local -A answer=([PROJECT_NAME]=asked-app [PROJECT_DESCRIPTION]="Asked description"
    [PROJECT_VISIBILITY]=private [GITEA_OWNER]=AskedOrg [USE_GITHUB]=y
    [GITHUB_OWNER]=asked-gh [PROJECT_DIRECTORY]=./asked-dir [ENABLE_PLAN_GATE]=n)
  local order=(PROJECT_NAME PROJECT_DESCRIPTION PROJECT_VISIBILITY GITEA_OWNER
    USE_GITHUB GITHUB_OWNER PROJECT_DIRECTORY ENABLE_PLAN_GATE)
  while IFS='|' read -r key value field label; do
    input=""
    for line in "${order[@]}"; do
      if [[ $line != "$key" ]]; then
        input+="${answer[$line]}"$'\n'
      fi
    done
    collect_with "$key=$value" "$input"
    assert_status "$key preset" 0 "$STATUS"
    assert_contains "$key value used" "$OUT" "$field"
    assert_not_contains "$key not asked" "$ERR" "$label"
    assert_contains "other details still asked" "$OUT" "asked"
  done <<'EOF'
PROJECT_NAME|preset-app|name=preset-app|Repository name
PROJECT_DESCRIPTION|From the config|description=From the config|Description
PROJECT_VISIBILITY|public|visibility=public|Visibility
GITEA_OWNER|PresetOrg|gitea_owner=PresetOrg|Gitea owner
USE_GITHUB|yes|has_github=1|Also create a GitHub
GITHUB_OWNER|preset-gh|github_owner=preset-gh|GitHub owner
PROJECT_DIRECTORY|./preset-dir|directory=./preset-dir|Local directory
ENABLE_PLAN_GATE|yes|is_plan_gate_enabled=1|Enable the plan gate
EOF
}

test_all_keys_set_asks_nothing() {
  collect_with "$PRESET_ALL" ""
  assert_status "no input needed" 0 "$STATUS"
  assert_eq "every value from the config" $'name=preset-app\ndescription=From the config\nvisibility=public\ngitea_owner=PresetOrg\nhas_github=1\ngithub_owner=preset-gh\ndirectory=./preset-dir\nis_plan_gate_enabled=1' "$OUT"
  assert_eq "no prompt text at all" "" "$ERR"
}

test_absent_keys_are_asked_as_before() {
  collect_with "PROJECT_NAME=preset-app" $'\n\nTirSystem\nn\n\nn\n'
  assert_status "mixed" 0 "$STATUS"
  assert_contains "preset name" "$OUT" "name=preset-app"
  assert_contains "default directory from the preset name" "$OUT" "directory=./preset-app"
  assert_contains "other details asked" "$ERR" "Gitea owner"
}

test_values_are_taken_in_any_case() {
  collect_with $'PROJECT_VISIBILITY=PUBLIC\nUSE_GITHUB=No\nENABLE_PLAN_GATE=YES' $'x-app\n\nTirSystem\n\n'
  assert_status "case ignored" 0 "$STATUS"
  assert_contains "visibility" "$OUT" "visibility=public"
  assert_contains "no GitHub" "$OUT" "has_github=0"
  assert_contains "plan gate" "$OUT" "is_plan_gate_enabled=1"
}

# ------------------------------------------------------- empty and invalid

test_empty_value_counts_as_set_only_for_the_description() {
  collect_with "PROJECT_DESCRIPTION=" $'my-app\npublic\nTirSystem\nn\n\nn\n'
  assert_status "empty description accepted" 0 "$STATUS"
  assert_contains "description empty" "$OUT" "description="
  assert_not_contains "description not asked" "$ERR" "Description"
  local key
  for key in PROJECT_NAME PROJECT_VISIBILITY GITEA_OWNER USE_GITHUB GITHUB_OWNER \
    PROJECT_DIRECTORY ENABLE_PLAN_GATE; do
    printf '%s=\n' "$key" >"$WORK/preset.env"
    run_lib "" 'parse_env_file "'"$WORK"'/preset.env" CONFIG_KEYS CONFIG
validate_project_presets'
    assert_status "$key empty" 1 "$STATUS"
    assert_contains "$key named" "$ERR" "$key in"
    assert_contains "$key says empty" "$ERR" "is empty"
  done
}

test_invalid_values_are_refused_naming_the_key() {
  local key value
  while IFS='|' read -r key value; do
    printf '%s=%s\n' "$key" "$value" >"$WORK/preset.env"
    run_lib "" 'parse_env_file "'"$WORK"'/preset.env" CONFIG_KEYS CONFIG
validate_project_presets'
    assert_status "$key=$value" 1 "$STATUS"
    assert_contains "$key=$value named" "$ERR" "$key in"
  done <<'EOF'
PROJECT_NAME|bad name
PROJECT_NAME|x.git
PROJECT_VISIBILITY|internal
GITEA_OWNER|-lead
USE_GITHUB|maybe
USE_GITHUB|1
GITHUB_OWNER|octo_user
PROJECT_DIRECTORY|-rf
ENABLE_PLAN_GATE|true
EOF
  # A description over the limit (350 characters) is refused too.
  printf 'PROJECT_DESCRIPTION=%s\n' "$(printf 'a%.0s' $(seq 1 351))" >"$WORK/preset.env"
  run_lib "" 'parse_env_file "'"$WORK"'/preset.env" CONFIG_KEYS CONFIG
validate_project_presets'
  assert_status "long description" 1 "$STATUS"
  assert_contains "named" "$ERR" "PROJECT_DESCRIPTION in"
}

test_invalid_value_stops_before_any_request_and_never_asks() {
  setup_hosts
  printf 'PROJECT_NAME=bad name\n' >>"$WORK/config.env"
  run_apply ""
  assert_status "stopped" 1 "$STATUS"
  assert_contains "key named" "$ERR" "PROJECT_NAME in"
  assert_not_contains "no value asked instead" "$ERR" "Repository name:"
  assert_eq "no request made" "" "$(calls)"
}

test_new_keys_are_rejected_in_env_and_credentials_in_config() {
  setup_hosts
  printf 'PROJECT_NAME=my-app\n' >>"$WORK/.env"
  run_dry ""
  assert_status ".env with a project key" 1 "$STATUS"
  assert_contains "unknown in .env" "$ERR" "unknown key 'PROJECT_NAME'"
  setup_hosts
  printf 'GITEA_TOKEN=abcdefgh12345\n' >>"$WORK/config.env"
  run_dry ""
  assert_status "config.env with a credential" 1 "$STATUS"
  assert_contains "credential refused" "$ERR" "is a credential"
}

# ------------------------------------------------------------- GitHub

test_use_github_no_skips_the_owner_and_warns_about_a_stray_one() {
  collect_with $'USE_GITHUB=no\nGITHUB_OWNER=acme-org' $'my-app\n\n\nTirSystem\n\nn\n'
  assert_status "GitHub off" 0 "$STATUS"
  assert_contains "no GitHub" "$OUT" "has_github=0"
  assert_contains "no owner" "$OUT" "github_owner="
  assert_not_contains "owner not asked" "$ERR" "GitHub owner ("
  assert_contains "ignored with a warning" "$ERR" "GITHUB_OWNER in"
  assert_contains "says why" "$ERR" "ignored because GitHub is not used"
  collect_with "USE_GITHUB=no" $'my-app\n\n\nTirSystem\n\nn\n'
  assert_not_contains "no warning without the key" "$ERR" "ignored"
}

test_github_owner_preset_is_used_when_github_is_asked_for() {
  collect_with "GITHUB_OWNER=preset-gh" $'my-app\n\n\nTirSystem\ny\n\nn\n'
  assert_contains "owner from the config" "$OUT" "github_owner=preset-gh"
  assert_not_contains "owner not asked" "$ERR" "GitHub owner ("
  collect_with "GITHUB_OWNER=preset-gh" $'my-app\n\n\nTirSystem\nn\n\nn\n'
  assert_contains "ignored when answered no" "$ERR" "ignored because GitHub is not used"
}

test_use_github_no_makes_no_github_call() {
  setup_hosts
  printf '%s\n' "$PRESET_LIKE_ANSWERS" | sed 's/^USE_GITHUB=.*/USE_GITHUB=no/' >>"$WORK/config.env"
  run_dry ""
  assert_status "dry run" 0 "$STATUS"
  assert_contains "GitHub not used" "$OUT" "GitHub repository : not used"
  assert_not_contains "no GitHub call" "$(calls)" "api.github.com"
  assert_not_contains "no GitHub owner asked" "$ERR" "GitHub owner ("
}

# ------------------------------------------------------------ the summary

test_summary_marks_the_values_from_config_env() {
  setup_hosts
  printf '%s\n' "$PRESET_LIKE_ANSWERS" >>"$WORK/config.env"
  run_dry ""
  assert_status "all preset" 0 "$STATUS"
  assert_contains "name" "$OUT" "Repository   : my-app (from config.env) (private (from config.env))"
  assert_contains "description" "$OUT" "Description  : A test app (from config.env)"
  assert_contains "Gitea" "$OUT" "/TirSystem/my-app (from config.env)"
  assert_contains "GitHub" "$OUT" "/acme-org/my-app (from config.env)"
  assert_contains "directory" "$OUT" "Directory    : ./my-app (from config.env)"
  assert_contains "plan gate" "$OUT" "Plan gate    : no (from config.env)"
}

test_summary_marks_nothing_when_everything_is_asked() {
  setup_hosts
  run_dry "$ANSWERS_GITHUB"
  assert_status "all asked" 0 "$STATUS"
  assert_not_contains "no marker" "$OUT" "(from config.env)"
}

# ----------------------------------------------------- the confirmations

test_with_every_detail_set_only_the_confirmations_are_asked() {
  setup_hosts
  run_apply "$ANSWERS_GITHUB"y$'\n'
  local asked_calls
  asked_calls="$(calls)"
  remove_workdir
  new_workdir
  setup_hosts
  printf '%s\n' "$PRESET_LIKE_ANSWERS" >>"$WORK/config.env"
  run_apply $'y\n'
  assert_status "run with presets" 0 "$STATUS"
  assert_eq "same requests as the run that was asked" "$asked_calls" "$(calls)"
  assert_contains "created" "$OUT" "This is what exists now"
}

test_with_every_detail_set_create_now_is_still_asked_and_defaults_to_no() {
  setup_hosts
  printf '%s\n' "$PRESET_LIKE_ANSWERS" >>"$WORK/config.env"
  run_apply $'n\n'
  assert_status "declined" 0 "$STATUS"
  assert_contains "says so" "$OUT" "Nothing was created."
  assert_not_contains "nothing created" "$(calls)" "POST"
  setup_hosts
  printf '%s\n' "$PRESET_LIKE_ANSWERS" >>"$WORK/config.env"
  run_apply $'\n'
  assert_contains "empty answer means no" "$OUT" "Nothing was created."
  assert_not_contains "no POST on the default" "$(calls)" "POST"
  setup_hosts
  printf '%s\n' "$PRESET_LIKE_ANSWERS" >>"$WORK/config.env"
  run_apply ""
  assert_contains "no answer means no" "$OUT" "Nothing was created."
  assert_not_contains "nothing created without an answer" "$(calls)" "POST"
}

test_with_every_detail_set_an_existing_directory_is_not_replaced() {
  setup_hosts
  printf '%s\n' "$PRESET_LIKE_ANSWERS" >>"$WORK/config.env"
  mkdir -p "$WORK/my-app"
  printf 'keep\n' >"$WORK/my-app/mine.txt"
  run_apply $'y\n\n'
  assert_file_exists "existing file kept" "$WORK/my-app/mine.txt"
  assert_eq "content kept" "keep" "$(cat "$WORK/my-app/mine.txt")"
}

test_a_quoted_description_may_contain_a_hash() {
  local answers=$'my-app\npublic\nTirSystem\nn\n\nn\n'
  collect_with 'PROJECT_DESCRIPTION="Tool for #mirrors"' "$answers"
  assert_status "quoted" 0 "$STATUS"
  assert_contains "whole value kept" "$OUT" "description=Tool for #mirrors"
  # Unquoted, the same text is cut at the comment mark, as documented.
  collect_with 'PROJECT_DESCRIPTION=Tool for #mirrors' "$answers"
  assert_contains "cut at the comment" "$OUT" "description=Tool for"
  assert_not_contains "comment dropped" "$OUT" "mirrors"
}
