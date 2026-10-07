# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# apply.sh - The only code that changes anything: confirmations and the apply flow.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: create_all, confirm_reuse, confirm_framework_access, apply_plan

create_all() {
  IS_CREATION_STARTED=1
  if ((PROJECT[has_github])); then
    create_repository github
  fi
  create_repository gitea
  if ((PROJECT[has_github])); then
    configure_mirror
  fi
  create_local_project
  add_framework
  install_framework
  copy_templates
  create_env_file
}

# confirm_framework_access: the framework comes over SSH. Without SSH the
# Maintainer can still go on, without the framework steps, after a yes.
confirm_framework_access() {
  if ((${STATE[is_ssh_ok]:-0})); then
    STATE[skip_framework]=0
    return 0
  fi
  warn "SSH to Gitea ($(gitea_host) port ${CONFIG[GITEA_SSH_PORT]}) did not work, so the framework cannot be added: ${STATE[ssh_note]}"
  prompt_yes_no "Create the repositories and the local project without the framework" n
  if ! ((REPLY)); then
    die "stopped: set up SSH access to Gitea (see the README) and run again"
  fi
  STATE[skip_framework]=1
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
  if ((${STATE[reuse_gitea]:-0})) && [[ -n ${PROJECT[license]} ]] &&
    [[ ${STATE[gitea_repo]} == empty ]]; then
    warn "the empty Gitea repository is reused as it is: the ${PROJECT[license]} license is not added to it"
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
  confirm_local_directory
  confirm_framework_access
  create_all
}
