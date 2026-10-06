# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# plan.sh - Printing what the script is about to do.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: local_plan_note, print_plan

# local_plan_note: what will happen to the project directory.
local_plan_note() {
  local dir="${PROJECT[directory]}"
  case "${STATE[local_dir]}" in
    missing) printf 'create %s (new directory), git on %s, no commit' "$dir" "$DEFAULT_BRANCH" ;;
    empty) printf 'use the existing empty directory %s (you will be asked)' "$dir" ;;
    *) printf 'use the existing directory %s, which has files (you will be asked)' "$dir" ;;
  esac
}

print_plan() {
  local gitea_action github_action origin_note
  say ""
  say "Plan:"
  if ((STATE[reuse_gitea])); then
    gitea_action="reuse the existing repository (you will be asked to confirm)"
  elif ((PROJECT[has_github])); then
    gitea_action="create (${PROJECT[visibility]}) with the $AGPL_LICENSE_KEY license"
  else
    gitea_action="create (${PROJECT[visibility]}), empty"
  fi
  say "$(printf '  %-18s: %s %s' "Gitea repository" "$gitea_action" "$(repo_url gitea)")"
  if ((PROJECT[has_github])); then
    if ((STATE[reuse_github])); then
      github_action="reuse the existing empty repository (you will be asked to confirm)"
    else
      github_action="create (${PROJECT[visibility]}), empty"
    fi
    say "$(printf '  %-18s: %s %s' "GitHub repository" "$github_action" "$(repo_url github)")"
    say "$(printf '  %-18s: %s' "Push mirror" "Gitea -> GitHub every ${CONFIG[MIRROR_INTERVAL]}")"
  else
    say "$(printf '  %-18s: %s' "GitHub repository" "not used")"
    say "$(printf '  %-18s: %s' "Push mirror" "not used")"
  fi
  if ((STATE[is_ssh_ok])); then
    origin_note="SSH (the SSH test passed)"
  else
    origin_note="HTTPS (SSH test: ${STATE[ssh_note]})"
  fi
  say "$(printf '  %-18s: %s' "Local project" "$(local_plan_note)")"
  say "$(printf '  %-18s: %s' "Local origin" "will use $origin_note")"
  if ((STATE[is_ssh_ok])); then
    say "$(printf '  %-18s: %s' "Framework" "add $(framework_url) as a submodule")"
    say "$(printf '  %-18s: %s' "Skills and hooks" "install once; plan gate $(yes_no "${PROJECT[is_plan_gate_enabled]}")")"
    say "$(printf '  %-18s: %s' "Templates" "AGENTS.md and docs/artifact-registry.md (you are asked before a file is replaced)")"
  else
    say "$(printf '  %-18s: %s' "Framework" "NOT possible without SSH to Gitea; you will be asked whether to go on without it")"
  fi
  say "$(printf '  %-18s: %s' "Project .env" "you are asked whether to create it ($(env_file_key_list))")"
}
