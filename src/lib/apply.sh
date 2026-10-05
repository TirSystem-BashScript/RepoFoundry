# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# apply.sh - The only code that changes anything: confirmations and the apply flow.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: create_all, confirm_reuse, apply_plan

create_all() {
  IS_CREATION_STARTED=1
  if ((PROJECT[has_github])); then
    create_repository github
  fi
  create_repository gitea
  if ((PROJECT[has_github])); then
    configure_mirror
  fi
}

confirm_reuse() {
  local host
  for host in github gitea; do
    if ! is_reused "$host"; then
      continue
    fi
    prompt_yes_no "The $(host_label "$host") repository $(repo_url "$host") already exists and has no real content. Reuse it" n
    if ! ((REPLY)); then
      die "stopped: choose another name or remove the existing repository"
    fi
  done
  if ((${STATE[reuse_gitea]:-0})) && ((PROJECT[has_github])) &&
    [[ ${STATE[gitea_repo]} == empty ]]; then
    warn "the empty Gitea repository is reused as it is: the $AGPL_LICENSE_KEY license is not added to it"
  fi
}

# apply_plan: the only place that changes anything on GitHub or Gitea.
apply_plan() {
  prompt_yes_no "Create these now" n
  if ! ((REPLY)); then
    say "Nothing was created."
    return 0
  fi
  confirm_reuse
  create_all
}
