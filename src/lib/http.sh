# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# http.sh - The one safe place that runs curl: tokens stay off the command line.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: describe_http_status, describe_curl_error, http_request

describe_http_status() {
  case "$1" in
    401) printf 'authentication failed: the token is missing, expired or invalid' ;;
    403) printf 'the token is valid but not allowed to do this (check its scopes)' ;;
    404) printf 'not found (check the name, the owner and the token access)' ;;
    409 | 422) printf 'rejected (the name may already exist or be invalid)' ;;
    429) printf 'rate limited; wait and try again' ;;
    5??) printf 'the server reported an error; try again later' ;;
    *) printf 'unexpected HTTP status %s' "$1" ;;
  esac
}

describe_curl_error() {
  case "$1" in
    6) printf 'could not resolve the host name' ;;
    7) printf 'could not connect' ;;
    28) printf 'the request timed out' ;;
    35 | 51 | 58 | 60) printf 'the TLS connection failed' ;;
    *) printf 'curl failed with exit code %s' "$1" ;;
  esac
}

# http_request METHOD URL SCHEME TOKEN [BODY]
# SCHEME is "token" (Gitea) or "bearer" (GitHub). The token goes into a
# private curl config file, never onto the command line where other users
# could see it. Redirects are not followed, so the token is only ever sent
# to the host named in URL. On success HTTP_STATUS and HTTP_BODY_FILE are
# set; on a network failure the function returns 1 with HTTP_ERROR set.
# shellcheck disable=SC2034  # HTTP_* are results read by the callers
http_request() {
  local method="$1" url="$2" scheme="$3" token="$4" body="${5:-}"
  local header config_file body_file out_file host curl_status=0
  local data_args=()
  [[ $method =~ ^(GET|POST|PUT|PATCH|DELETE)$ ]] ||
    die "internal error: unsupported HTTP method"
  is_valid_request_url "$url" ||
    die "refusing to call an invalid or non-https URL"
  is_valid_token "$token" || die "refusing to send a malformed token"
  case "$scheme" in
    token) header="Authorization: token $token" ;;
    bearer) header="Authorization: Bearer $token" ;;
    *) die "internal error: unknown authentication scheme" ;;
  esac
  make_temp_file
  config_file="$REPLY"
  make_temp_file
  out_file="$REPLY"
  {
    printf 'url = "%s"\n' "$url"
    printf 'request = "%s"\n' "$method"
    printf 'header = "%s"\n' "$header"
    printf 'header = "Accept: application/json"\n'
    printf 'header = "User-Agent: %s/%s"\n' "$PROJECT_NAME" "$VERSION"
  } >"$config_file"
  if [[ -n $body ]]; then
    make_temp_file
    body_file="$REPLY"
    printf '%s' "$body" >"$body_file"
    printf 'header = "Content-Type: application/json"\n' >>"$config_file"
    data_args=(--data-binary "@$body_file")
  fi
  # curl's own error text is dropped: the exit code is mapped to a message
  # that never contains the request.
  HTTP_STATUS="$(curl --silent --max-time "$HTTP_TIMEOUT_SECONDS" \
    --connect-timeout 10 --output "$out_file" --write-out '%{http_code}' \
    --config "$config_file" "${data_args[@]}" </dev/null 2>/dev/null)" || curl_status=$?
  # The configuration file holds the token and the body may hold another one
  # (the mirror password): remove both now instead of at exit.
  rm -f -- "$config_file" ${body_file:+"$body_file"}
  if ((curl_status != 0)); then
    host="${url#https://}"
    host="${host%%/*}"
    HTTP_STATUS=0
    HTTP_ERROR="could not reach $host: $(describe_curl_error "$curl_status")"
    return 1
  fi
  HTTP_BODY_FILE="$out_file"
  HTTP_ERROR=""
}
