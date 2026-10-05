# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# tools.sh - Checking that the required tools are installed.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: check_tools

check_tools() {
  local tool
  local missing=()
  for tool in git curl mktemp; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing+=("$tool")
    fi
  done
  if ((${#missing[@]} > 0)); then
    die "required tool(s) not found: ${missing[*]}. Install them and try again."
  fi
  if command -v jq >/dev/null 2>&1; then
    HAS_JQ=1
  else
    HAS_JQ=0
    warn "jq not found; using the built-in JSON reader (install jq for stricter parsing)"
  fi
}
