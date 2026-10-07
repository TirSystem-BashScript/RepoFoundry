# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# framework.sh - The SQA-QC-Framework in the new project: submodule, skills, hooks and templates.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: is_framework_skipped, init_framework_submodules, add_framework, run_framework_script, install_skills, install_hooks, install_framework, copy_template, copy_templates

# is_framework_skipped: succeed when the framework steps are left out because
# SSH to Gitea is not available (the Maintainer agreed to that).
is_framework_skipped() {
  [[ ${STATE[skip_framework]:-0} == 1 ]]
}

# init_framework_submodules DIR: fetch the submodules the framework holds
# itself (the qc checklists). Without a submodule of its own this changes
# nothing. A failure names the command to run by hand.
init_framework_submodules() {
  local dir="$1" err
  make_temp_file
  err="$REPLY"
  if ! git_project "$dir" submodule update -q --init --recursive 2>"$err"; then
    die "the framework was added but git could not fetch its own submodules (the qc checklists). Run in $dir: git submodule update --init --recursive. Git said: $(head -n 2 "$err" | tr '\n' ' ')"
  fi
}

# add_framework: git submodule add of the framework as "framework". SSH is
# needed for it; a failure says how to test the access.
add_framework() {
  local label="Framework" dir="${PROJECT[directory]}" url err existing
  url="$(framework_url)"
  if is_framework_skipped; then
    finish_step "$label" "skipped" "(no SSH access to Gitea)"
    return 0
  fi
  begin_step "$label"
  if [[ -e $dir/framework ]]; then
    existing="$(git_project "$dir" config -f .gitmodules --get submodule.framework.url || true)"
    if [[ $existing != "$url" ]]; then
      die "'framework' already exists in $dir and is not the framework submodule ($url)"
    fi
    init_framework_submodules "$dir"
    finish_step "$label" "reused" "$url (already a submodule)"
    return 0
  fi
  make_temp_file
  err="$REPLY"
  if ! git_project "$dir" submodule add -q "$url" framework 2>"$err"; then
    die "git could not add the framework from $url. Check the SSH access first: ssh -p ${CONFIG[GITEA_SSH_PORT]} -T git@$(gitea_host). Git said: $(head -n 2 "$err" | tr '\n' ' ')"
  fi
  init_framework_submodules "$dir"
  finish_step "$label" "created" "$url"
}

# run_framework_script DIR SCRIPT [ARG...]: run one of the framework's own
# scripts inside the project. PROJECT_ROOT is set explicitly so that a
# PROJECT_ROOT in the caller's environment cannot point it elsewhere.
run_framework_script() {
  local dir="$1" script="$2" out abs
  shift 2
  abs="$(cd "$dir" && pwd)"
  make_temp_file
  out="$REPLY"
  if ! (cd "$abs" && env PROJECT_ROOT="$abs" bash "framework/scripts/$script" "$@" </dev/null) >"$out" 2>&1; then
    die "the framework script $script failed: $(tail -n 3 "$out" | tr '\n' ' ')"
  fi
}

# install_skills DIR: install the framework's skills once. The installer is
# safe to repeat but copies everything again, so a project that already has
# them is left alone.
install_skills() {
  local dir="$1"
  if [[ -f $dir/.agents/skills/.framework-skills && -f $dir/.claude/skills/.framework-skills ]]; then
    STATE[skills_note]="skills already installed"
    return 0
  fi
  run_framework_script "$dir" install-skills.sh
  STATE[skills_note]="skills installed"
}

# install_hooks DIR: point core.hooksPath at the framework's hooks, and turn
# on the plan gate if chosen. A different hooks path that is already set is
# only replaced after a yes.
install_hooks() {
  local dir="$1" current global gate=() gate_enabled
  if ((PROJECT[is_plan_gate_enabled])); then
    gate=(--enable-plan-gate)
  fi
  # Both settings are normally unset; git config exits 1 then.
  current="$(git_project "$dir" config --local --get core.hooksPath || true)"
  global="$(git_project "$dir" config --global --get core.hooksPath || true)"
  gate_enabled="$(git_project "$dir" config --local --get planGate.enabled || true)"
  if [[ -z $current && -n $global ]]; then
    warn "your global core.hooksPath is '$global'; this project sets its own, which takes precedence here"
  fi
  if [[ -z $current ]]; then
    run_framework_script "$dir" install-git-hooks.sh "${gate[@]}"
    STATE[hooks_note]="hooks installed"
  elif [[ $current == framework/githooks ]]; then
    STATE[hooks_note]="hooks already installed"
    if ((PROJECT[is_plan_gate_enabled])) && [[ $gate_enabled != true ]]; then
      run_framework_script "$dir" install-git-hooks.sh "${gate[@]}"
    fi
  else
    prompt_yes_no "core.hooksPath is already '$current'. Replace it with framework/githooks" n
    if ((REPLY)); then
      run_framework_script "$dir" install-git-hooks.sh "${gate[@]}"
      STATE[hooks_note]="hooks installed (replaced '$current')"
    else
      STATE[hooks_note]="kept the existing hooks path '$current'"
      if ((PROJECT[is_plan_gate_enabled])); then
        warn "the plan gate is not enabled because the framework hooks were not installed"
      fi
    fi
  fi
}

# install_framework: skills, then hooks (and the plan gate). Each is done once.
install_framework() {
  local label="Skills and hooks" dir="${PROJECT[directory]}" gate_state="plan gate off"
  if is_framework_skipped; then
    finish_step "$label" "skipped" "(no SSH access to Gitea)"
    return 0
  fi
  begin_step "$label"
  install_skills "$dir"
  install_hooks "$dir"
  if [[ $(git_project "$dir" config --local --get planGate.enabled || true) == true ]]; then
    gate_state="plan gate on"
  fi
  finish_step "$label" "created" "(${STATE[skills_note]}; ${STATE[hooks_note]}; $gate_state)"
}

# copy_template DIR SOURCE TARGET: copy a framework template. An existing
# target is only replaced after a yes. The result goes to STATE[template_note].
copy_template() {
  local dir="$1" source="$2" target="$3"
  if [[ ! -f $dir/$source ]]; then
    die "the framework has no $source; is the submodule complete?"
  fi
  if [[ -e $dir/$target ]]; then
    prompt_yes_no "$target already exists. Replace it with the framework template" n
    if ! ((REPLY)); then
      STATE[template_note]="kept existing $target"
      return 0
    fi
  fi
  cp -- "$dir/$source" "$dir/$target"
  STATE[template_note]="copied $target"
}

# copy_templates: AGENTS.md and docs/artifact-registry.md from the framework.
copy_templates() {
  local label="Templates" dir="${PROJECT[directory]}" notes=""
  if is_framework_skipped; then
    finish_step "$label" "skipped" "(no SSH access to Gitea)"
    return 0
  fi
  begin_step "$label"
  mkdir -p -- "$dir/docs"
  copy_template "$dir" framework/templates/AGENTS-template.md AGENTS.md
  notes="${STATE[template_note]}"
  copy_template "$dir" framework/templates/artifact-registry-template.md docs/artifact-registry.md
  notes="$notes; ${STATE[template_note]}"
  finish_step "$label" "created" "($notes)"
}
