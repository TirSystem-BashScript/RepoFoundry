# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# project.sh - The details of the project being created: asking for them and showing them.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: collect_project_details, yes_no, credential_state, print_summary

collect_project_details() {
  prompt_value "Repository name" "" is_valid_repo_name \
    "use letters, digits, '.', '_' or '-' (at most 100), not ending in .git"
  PROJECT[name]="$REPLY"
  prompt_value "Description (optional)" "" is_valid_description \
    "at most $MAX_DESCRIPTION_LENGTH characters and no control characters"
  PROJECT[description]="$REPLY"
  prompt_choice "Visibility" private private public
  PROJECT[visibility]="$REPLY"
  prompt_value "Gitea owner (user or organization)" "" is_valid_gitea_owner \
    "use letters, digits, '.', '_' or '-' (at most 39)"
  PROJECT[gitea_owner]="$REPLY"
  prompt_yes_no "Also create a GitHub repository (applies the AGPL license)" y
  PROJECT[has_github]="$REPLY"
  PROJECT[github_owner]=""
  if ((PROJECT[has_github])); then
    prompt_value "GitHub owner (user or organization)" \
      "${CREDENTIALS[GITHUB_USER]:-}" is_valid_github_owner \
      "use letters, digits or '-' (at most 39)"
    PROJECT[github_owner]="$REPLY"
  fi
  prompt_value "Local directory" "./${PROJECT[name]}" is_valid_directory \
    "must not be empty, start with '-' or contain control characters"
  PROJECT[directory]="$REPLY"
  prompt_yes_no "Enable the plan gate" n
  PROJECT[is_plan_gate_enabled]="$REPLY"
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

print_summary() {
  say ""
  say "$PROJECT_NAME $VERSION"
  say "Collected details:"
  say "  Repository   : ${PROJECT[name]} (${PROJECT[visibility]})"
  say "  Description  : ${PROJECT[description]:-(none)}"
  say "  Gitea        : ${CONFIG[GITEA_URL]}/${PROJECT[gitea_owner]}/${PROJECT[name]}"
  if ((PROJECT[has_github])); then
    say "  GitHub       : ${CONFIG[GITHUB_WEB_URL]}/${PROJECT[github_owner]}/${PROJECT[name]} (AGPL license applied)"
  else
    say "  GitHub       : not used"
  fi
  say "  Directory    : ${PROJECT[directory]}"
  say "  Plan gate    : $(yes_no "${PROJECT[is_plan_gate_enabled]}")"
  say "Credentials    : GITEA_TOKEN $(credential_state GITEA_TOKEN)," \
    "GITHUB_PAT $(credential_state GITHUB_PAT)"
}
