# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# output.sh - Messages for the user: output, warnings, errors, and redaction of secrets.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: redact, say, warn, die, on_error

# redact TEXT: print TEXT with every known secret value replaced.
redact() {
  local text="$1" secret
  for secret in "${SECRET_VALUES[@]}"; do
    if [[ -n $secret ]]; then
      text="${text//"$secret"/[redacted]}"
    fi
  done
  printf '%s' "$text"
}

say() {
  printf '%s\n' "$(redact "$*")"
}

warn() {
  printf 'warning: %s\n' "$(redact "$*")" >&2
}

# die [--code N] MESSAGE: print "error: MESSAGE" and exit (default code 1).
die() {
  local code=$EXIT_FAILURE
  if [[ ${1:-} == --code ]]; then
    code="$2"
    shift 2
  fi
  printf 'error: %s\n' "$(redact "$*")" >&2
  exit "$code"
}

# on_error LINE: report an unexpected failure without echoing the command,
# because a command line could contain a value that must stay private.
on_error() {
  printf 'error: unexpected failure near line %s of %s\n' "$1" "${0##*/}" >&2
}
