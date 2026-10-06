# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# prompts.sh - Interactive questions with validation of every answer.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: prompt_value, prompt_secret, prompt_choice, prompt_yes_no

# prompt_value LABEL DEFAULT VALIDATOR HINT: ask until VALIDATOR accepts the
# answer; the accepted answer is returned in REPLY.
prompt_value() {
  local label="$1" default="$2" validator="$3" hint="$4" answer
  while true; do
    if [[ -n $default ]]; then
      printf '%s [%s]: ' "$label" "$default" >&2
    else
      printf '%s: ' "$label" >&2
    fi
    IFS= read -r answer || die "no input available for '$label'"
    answer="$(trim "$answer")"
    answer="${answer:-$default}"
    if "$validator" "$answer"; then
      REPLY="$answer"
      return 0
    fi
    warn "invalid $label: $hint"
  done
}

# prompt_secret LABEL VALIDATOR HINT: like prompt_value for a secret. What is
# typed is not shown (read -s) and a refused answer is never repeated in the
# message. An empty answer is refused; there is no default.
prompt_secret() {
  local label="$1" validator="$2" hint="$3" answer
  while true; do
    printf '%s (input is hidden): ' "$label" >&2
    IFS= read -rs answer || {
      printf '\n' >&2
      die "no input available for '$label'"
    }
    printf '\n' >&2 # the newline that hidden input did not echo
    answer="$(trim "$answer")"
    if [[ -n $answer ]] && "$validator" "$answer"; then
      REPLY="$answer"
      return 0
    fi
    warn "invalid $label: $hint"
  done
}

# prompt_choice LABEL DEFAULT CHOICE...: the answer is returned in REPLY.
prompt_choice() {
  local label="$1" default="$2" answer
  shift 2
  while true; do
    printf '%s (%s) [%s]: ' "$label" "$(IFS=/ && echo "$*")" "$default" >&2
    IFS= read -r answer || die "no input available for '$label'"
    answer="$(trim "$answer")"
    answer="${answer:-$default}"
    answer="${answer,,}"
    if in_list "$answer" "$@"; then
      REPLY="$answer"
      return 0
    fi
    warn "invalid $label: choose one of $*"
  done
}

# prompt_yes_no LABEL DEFAULT: DEFAULT is y or n; REPLY is 1 (yes) or 0 (no).
prompt_yes_no() {
  local label="$1" default="$2" answer
  while true; do
    printf '%s (y/n) [%s]: ' "$label" "$default" >&2
    IFS= read -r answer || die "no input available for '$label'"
    answer="$(trim "$answer")"
    answer="${answer:-$default}"
    case "${answer,,}" in
      y | yes)
        REPLY=1
        return 0
        ;;
      n | no)
        REPLY=0
        return 0
        ;;
    esac
    warn "invalid $label: answer y or n"
  done
}
