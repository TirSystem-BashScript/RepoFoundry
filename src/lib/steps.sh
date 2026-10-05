# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# steps.sh - The outcome of each step and the final report of a run.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: init_steps, begin_step, finish_step, report_outcome

init_steps() {
  local label
  for label in "${PLAN_STEPS[@]}"; do
    STEP_STATUS[$label]="not attempted"
    STEP_DETAIL[$label]=""
  done
  if ! ((PROJECT[has_github])); then
    STEP_STATUS["GitHub repository"]="not used"
    STEP_STATUS["Push mirror"]="not used"
  fi
}

# begin_step LABEL marks the step failed until finish_step says otherwise, so
# any stop in the middle of a step is reported as a failure of that step.
begin_step() {
  STEP_STATUS[$1]="FAILED"
  STEP_DETAIL[$1]=""
}

finish_step() {
  STEP_STATUS[$1]="$2"
  STEP_DETAIL[$1]="${3:-}"
}

report_outcome() {
  local code="$1" label
  say ""
  if ((code == 0)); then
    say "Done. This is what exists now:"
  else
    say "The run stopped before it finished. This is what exists now:"
  fi
  for label in "${PLAN_STEPS[@]}"; do
    say "$(printf '  %-18s: %s' "$label" "${STEP_STATUS[$label]}${STEP_DETAIL[$label]:+ ${STEP_DETAIL[$label]}}")"
  done
  if ((code == 0)); then
    say "The local project with the framework is created by a later phase."
  else
    say "To continue: fix the problem named above and run the same command again with --apply."
    say "A repository this run created is still empty (or holds only the license), so the next run offers to reuse it."
    say "Nothing is deleted automatically. To start over, delete the repositories above in the web interface."
  fi
}
