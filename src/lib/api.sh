# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# api.sh - Calls to the GitHub and Gitea APIs and the reporting of a refused call.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: host_label, api_call, server_message, fail_request, expect_status

host_label() {
  case "$1" in
    gitea) printf 'Gitea' ;;
    github) printf 'GitHub' ;;
    *) die "internal error: unknown host" ;;
  esac
}

# api_call HOST METHOD PATH [BODY]: HOST is gitea or github. A network
# failure ends the run; the HTTP status is left in HTTP_STATUS.
api_call() {
  local host="$1" method="$2" path="$3" body="${4:-}"
  case "$host" in
    gitea)
      http_request "$method" "${CONFIG[GITEA_API_URL]}$path" token \
        "${CREDENTIALS[GITEA_TOKEN]}" "$body" || die "$HTTP_ERROR"
      ;;
    github)
      http_request "$method" "${CONFIG[GITHUB_API_URL]}$path" bearer \
        "${CREDENTIALS[GITHUB_PAT]}" "$body" || die "$HTTP_ERROR"
      ;;
    *) die "internal error: unknown host" ;;
  esac
}

# server_message: the "message" of the last response, cleaned and shortened.
server_message() {
  local message
  # A response that is not JSON must not stop the error report.
  message="$(json_get "$HTTP_BODY_FILE" message 2>/dev/null || true)"
  message="${message//[[:cntrl:]]/ }"
  printf '%s' "${message:0:160}"
}

fail_request() {
  local detail message
  detail="$(describe_http_status "$HTTP_STATUS")"
  message="$(server_message)"
  die "$1: $detail${message:+ (the server says: $message)}"
}

# expect_status CONTEXT CODE...: go on if the last status is one of CODE,
# otherwise stop with CONTEXT and the server's own words.
expect_status() {
  local context="$1" code
  shift
  for code in "$@"; do
    if [[ $HTTP_STATUS == "$code" ]]; then
      return 0
    fi
  done
  fail_request "$context"
}
