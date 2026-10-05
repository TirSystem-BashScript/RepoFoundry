# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# plan.sh - Printing what the script is about to do.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: print_plan

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
  say "$(printf '  %-18s: %s' "Local origin" "will use $origin_note, in a later phase")"
}
