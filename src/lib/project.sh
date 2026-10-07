# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# project.sh - The details of the project being created: asking for them and showing them.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: preset_detail, resolve_license, license_note, collect_project_details, collect_github_details, source_note, yes_no, credential_state, print_summary

# preset_detail KEY NAME: a detail set in config.env is used and not asked;
# the value is returned in REPLY and marked in PRESET[NAME].
preset_detail() {
  [[ -n ${CONFIG[$1]+set} ]] || return 1
  REPLY="${CONFIG[$1]}"
  PRESET[$2]=1
}

# resolve_license: the license that applies, in PROJECT[license] (empty means
# none). PROJECT_LICENSE in config.env decides, and "none" means no license;
# without it AGPL-3.0 applies only when GitHub is chosen and the project is
# public. The license is never asked.
resolve_license() {
  PROJECT[license]=""
  if [[ -n ${CONFIG[PROJECT_LICENSE]+set} ]]; then
    PRESET[license]=1
    if [[ ${CONFIG[PROJECT_LICENSE],,} != "$NO_LICENSE_WORD" ]]; then
      PROJECT[license]="${CONFIG[PROJECT_LICENSE]}"
    fi
  elif ((PROJECT[has_github])) && [[ ${PROJECT[visibility]} == public ]]; then
    PROJECT[license]="$AGPL_LICENSE_KEY"
  fi
}

# license_note: where the license on the Gitea repository comes from.
license_note() {
  if [[ -n ${PRESET[license]:-} ]]; then
    source_note license
  elif [[ -n ${PROJECT[license]} ]]; then
    printf ' (default: GitHub and a public project)'
  elif ((PROJECT[has_github])); then
    printf ' (no default for a private project)'
  fi
}

# Ask for each project detail, except those set in config.env.
collect_project_details() {
  preset_detail PROJECT_NAME name ||
    prompt_value "Repository name" "" is_valid_repo_name "$HINT_REPO_NAME"
  PROJECT[name]="$REPLY"
  preset_detail PROJECT_DESCRIPTION description ||
    prompt_value "Description (optional)" "" is_valid_description "$HINT_DESCRIPTION"
  PROJECT[description]="$REPLY"
  preset_detail PROJECT_VISIBILITY visibility ||
    prompt_choice "Visibility" private private public
  PROJECT[visibility]="$REPLY"
  preset_detail GITEA_OWNER gitea_owner ||
    prompt_value "Gitea owner (user or organization)" "" is_valid_gitea_owner "$HINT_GITEA_OWNER"
  PROJECT[gitea_owner]="$REPLY"
  collect_github_details
  resolve_license
  preset_detail PROJECT_DIRECTORY directory ||
    prompt_value "Local directory" "./${PROJECT[name]}" is_valid_directory "$HINT_DIRECTORY"
  PROJECT[directory]="$REPLY"
  if preset_detail ENABLE_PLAN_GATE is_plan_gate_enabled; then
    [[ $REPLY == yes ]] && REPLY=1 || REPLY=0
  else
    prompt_yes_no "Enable the plan gate" n
  fi
  PROJECT[is_plan_gate_enabled]="$REPLY"
}

# Whether GitHub is used, and its owner. A GITHUB_OWNER set while GitHub is
# not used is ignored, with a warning.
collect_github_details() {
  if preset_detail USE_GITHUB has_github; then
    [[ $REPLY == yes ]] && REPLY=1 || REPLY=0
  else
    prompt_yes_no "Also create a GitHub repository" y
  fi
  PROJECT[has_github]="$REPLY"
  PROJECT[github_owner]=""
  if ((PROJECT[has_github])); then
    preset_detail GITHUB_OWNER github_owner ||
      prompt_value "GitHub owner (user or organization)" "${CREDENTIALS[GITHUB_USER]:-}" is_valid_github_owner "$HINT_GITHUB_OWNER"
    PROJECT[github_owner]="$REPLY"
  elif [[ -n ${CONFIG[GITHUB_OWNER]+set} ]]; then
    warn "GITHUB_OWNER in $CONFIG_FILE is ignored because GitHub is not used"
  fi
}

yes_no() {
  if (($1)); then
    printf 'yes'
  else
    printf 'no'
  fi
}

credential_state() {
  if [[ -n ${CREDENTIALS[$1]:-} ]]; then
    printf 'set'
  else
    printf 'not set'
  fi
}

# source_note NAME: the marker shown after a value that came from config.env.
source_note() {
  if [[ -n ${PRESET[$1]:-} ]]; then
    printf ' (from config.env)'
  fi
}

print_summary() {
  say ""
  say "$PROJECT_NAME $VERSION"
  say "Collected details:"
  say "  Repository   : ${PROJECT[name]}$(source_note name) (${PROJECT[visibility]}$(source_note visibility))"
  say "  Description  : ${PROJECT[description]:-(none)}$(source_note description)"
  say "  Gitea        : ${CONFIG[GITEA_URL]}/${PROJECT[gitea_owner]}/${PROJECT[name]}$(source_note gitea_owner)"
  if ((PROJECT[has_github])); then
    say "  GitHub       : ${CONFIG[GITHUB_WEB_URL]}/${PROJECT[github_owner]}/${PROJECT[name]}$(source_note github_owner)"
  else
    say "  GitHub       : not used$(source_note has_github)"
  fi
  say "  License      : ${PROJECT[license]:-none}$(license_note)"
  say "  Directory    : ${PROJECT[directory]}$(source_note directory)"
  say "  Plan gate    : $(yes_no "${PROJECT[is_plan_gate_enabled]}")$(source_note is_plan_gate_enabled)"
  say "Credentials    : GITEA_TOKEN $(credential_state GITEA_TOKEN)," \
    "GITHUB_PAT $(credential_state GITHUB_PAT)"
}
