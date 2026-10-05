#!/usr/bin/env bash
# create-project.sh - set up a new project on Gitea (and optionally GitHub).
#
# Purpose
#   RepoFoundry creates a Gitea repository, optionally an empty GitHub
#   repository with a Gitea -> GitHub push mirror, and a local project with
#   the SQA-QC-Framework. This version (MIL-001) validates the configuration
#   and credentials, checks the required tools and asks for the project
#   details. It does NOT contact GitHub or Gitea and changes nothing on disk;
#   it only prints a summary of what it collected.
#
# Usage
#   create-project.sh [--config FILE] [--env FILE]
#   create-project.sh --help | --version
#
# Options
#   --config FILE   service addresses (default: config.env next to the script)
#   --env FILE      credentials (default: .env next to the script)
#   -h, --help      show this help
#   --version       show the version
#
# Files (parsed, never sourced)
#   config.env  GITHUB_API_URL, GITHUB_WEB_URL, GITEA_URL, GITEA_API_URL
#   .env        GITHUB_PAT, GITHUB_USER, GITEA_TOKEN
#
# Environment
#   REPOFOUNDRY_NAME  project name used in messages (default: RepoFoundry)
#   TMPDIR            where the private temporary directory is created
#
# Requires
#   bash 4.4 or later, git, curl, mktemp; jq is optional (used when present).
#   Also the base tools sed, grep, head, tr, rm, rmdir and uname, and stat
#   (GNU "stat -c" or BSD "stat -f"; only used outside Windows).
#
# Implements
#   MIL-001 tasks 1 to 6 (issues #3 to #8), user story US-001.01 and UC-001
#   steps 1 to 3; see docs/. Deviation from the request: its second
#   GITEA_URL key is named GITEA_API_URL.
#
# Tracing
#   set -x is switched off while the script runs, because a trace would print
#   every secret the script handles.
#
# Exit codes
#   0 success, 1 a failed check or bad input, 2 a usage error.
set -Eeuo pipefail

if [[ $- == *x* ]]; then
  set +x
  printf 'warning: tracing (set -x) is disabled because it would print secrets\n' >&2
fi

if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4))); then
  printf 'error: bash 4.4 or later is required (found %s)\n' "$BASH_VERSION" >&2
  exit 1
fi

readonly PROJECT_NAME="${REPOFOUNDRY_NAME:-RepoFoundry}"
readonly VERSION="0.1.0"
readonly EXIT_FAILURE=1
readonly EXIT_USAGE=2
readonly MAX_VALUE_LENGTH=2048
readonly MAX_DESCRIPTION_LENGTH=350
readonly HTTP_TIMEOUT_SECONDS=30
# shellcheck disable=SC2034  # read through namerefs (parse_env_file)
readonly CONFIG_KEYS=(GITHUB_API_URL GITHUB_WEB_URL GITEA_URL GITEA_API_URL)
readonly CREDENTIAL_KEYS=(GITHUB_PAT GITHUB_USER GITEA_TOKEN)

case "${BASH_SOURCE[0]}" in
  */*) script_path_dir="${BASH_SOURCE[0]%/*}" ;;
  *) script_path_dir="." ;;
esac
SCRIPT_DIR="$(cd "$script_path_dir" && pwd)"
readonly SCRIPT_DIR
unset script_path_dir

CONFIG_FILE="$SCRIPT_DIR/config.env"
ENV_FILE="$SCRIPT_DIR/.env"
TMP_DIR=""
HAS_JQ=0
HTTP_STATUS=0
HTTP_BODY_FILE=""
HTTP_ERROR=""
REPLY=""
SECRET_VALUES=()
TEMP_FILES=()
declare -A CONFIG=()
declare -A CREDENTIALS=()
declare -A PROJECT=()

# ---------------------------------------------------------------- output

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

usage() {
  cat <<EOF
Usage: ${0##*/} [--config FILE] [--env FILE]
       ${0##*/} --help | --version
EOF
}

usage_error() {
  printf 'error: %s\n' "$1" >&2
  usage >&2
  exit "$EXIT_USAGE"
}

# on_error LINE: report an unexpected failure without echoing the command,
# because a command line could contain a value that must stay private.
on_error() {
  printf 'error: unexpected failure near line %s of %s\n' "$1" "${0##*/}" >&2
}

# ------------------------------------------------------- temporary files

# Files are removed one by one and the directory with rmdir: a recursive
# delete is never needed and never used.
cleanup() {
  local file
  for file in "${TEMP_FILES[@]}"; do
    rm -f -- "$file"
  done
  if [[ -n $TMP_DIR && -d $TMP_DIR ]]; then
    # rmdir fails only if something unexpected is left inside; leave it
    # rather than delete files this script did not create.
    rmdir -- "$TMP_DIR" 2>/dev/null || true
  fi
}

setup_temp_dir() {
  TMP_DIR="$(umask 077 && mktemp -d "${TMPDIR:-/tmp}/repofoundry.XXXXXX")"
}

# make_temp_file: create a private file in TMP_DIR and return it in REPLY.
make_temp_file() {
  REPLY="$(umask 077 && mktemp "$TMP_DIR/file.XXXXXX")"
  TEMP_FILES+=("$REPLY")
}

# ------------------------------------------------------------ small helpers

trim() {
  local text="$1"
  text="${text#"${text%%[![:space:]]*}"}"
  text="${text%"${text##*[![:space:]]}"}"
  printf '%s' "$text"
}

# in_list NEEDLE ITEM...: succeed if NEEDLE equals one of the items.
in_list() {
  local needle="$1" item
  shift
  for item in "$@"; do
    if [[ $item == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

has_control_character() {
  [[ $1 == *[[:cntrl:]]* ]]
}

# ------------------------------------------------------------- validators

is_valid_repo_name() {
  local name="$1"
  [[ $name =~ ^[A-Za-z0-9._-]{1,100}$ ]] || return 1
  [[ $name != . && $name != .. && $name != *.git ]]
}

is_valid_gitea_owner() {
  [[ $1 =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,38}$ ]]
}

is_valid_github_owner() {
  [[ $1 =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,37}[A-Za-z0-9])?$ ]]
}

is_valid_description() {
  ((${#1} <= MAX_DESCRIPTION_LENGTH)) && ! has_control_character "$1"
}

is_valid_directory() {
  local path="$1"
  [[ -n $path && ${#path} -le 4096 && $path != -* ]] &&
    ! has_control_character "$path"
}

# https URL without user info, query or fragment, so it can never carry a
# credential.
is_valid_base_url() {
  local pattern='^https://[A-Za-z0-9.-]+(:[0-9]{1,5})?(/[A-Za-z0-9._~%+/-]*)?$'
  [[ $1 =~ $pattern ]]
}

# Like is_valid_base_url but a query string is allowed (for API requests).
is_valid_request_url() {
  local pattern='^https://[A-Za-z0-9.-]+(:[0-9]{1,5})?(/[A-Za-z0-9._~%+/-]*)?(\?[A-Za-z0-9._~%+=&,-]*)?$'
  [[ $1 =~ $pattern ]]
}

# Access tokens: no quotes, backslashes or whitespace, so a token cannot
# break out of the curl configuration it is written to.
is_valid_token() {
  [[ $1 =~ ^[A-Za-z0-9_.~+/=-]{8,255}$ ]]
}

normalize_url() {
  local url="$1"
  while [[ $url == */ ]]; do
    url="${url%/}"
  done
  printf '%s' "$url"
}

# --------------------------------------------------- config file parsing

# unquote_value RAW: strip matching quotes (or a trailing " # comment" on an
# unquoted value) and return the value in REPLY. Fails on unbalanced quotes.
unquote_value() {
  local raw quote
  raw="$(trim "$1")"
  quote="${raw:0:1}"
  if [[ $quote == '"' || $quote == "'" ]]; then
    [[ ${#raw} -ge 2 && ${raw: -1} == "$quote" ]] || return 1
    raw="${raw:1:${#raw}-2}"
    [[ $raw != *"$quote"* ]] || return 1
  else
    raw="${raw%%[[:space:]]#*}"
    raw="$(trim "$raw")"
    [[ $raw != *'"'* && $raw != *"'"* ]] || return 1
  fi
  REPLY="$raw"
}

# parse_env_file FILE ALLOWED_ARRAY TARGET_ARRAY
# Read KEY=VALUE lines without source or eval. Only keys named in
# ALLOWED_ARRAY are accepted; they are stored in the associative array
# TARGET_ARRAY. Messages name the key and the line, never the value.
parse_env_file() {
  local file="$1" line key line_number=0
  local pattern='^([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=(.*)$'
  [[ -f $file && -r $file ]] || die "cannot read '$file'"
  # shellcheck disable=SC2094  # the loop body only uses $file in messages
  while IFS= read -r line || [[ -n $line ]]; do
    line_number=$((line_number + 1))
    if ((line_number == 1)); then
      line="${line#$'\xEF\xBB\xBF'}" # byte order mark from some Windows editors
    fi
    line="$(trim "${line%$'\r'}")"
    if [[ -z $line || $line == \#* ]]; then
      continue
    fi
    [[ $line =~ $pattern ]] ||
      die "$file line $line_number: expected KEY=VALUE"
    key="${BASH_REMATCH[1]}"
    parse_env_entry "$file" "$line_number" "$key" "${BASH_REMATCH[2]}" \
      "$2" "$3"
  done <"$file"
}

# parse_env_entry FILE LINE KEY RAW_VALUE ALLOWED_ARRAY TARGET_ARRAY
parse_env_entry() {
  local file="$1" line_number="$2" key="$3" raw="$4"
  local -n allowed_keys="$5"
  local -n target_map="$6"
  local value
  if ! in_list "$key" "${allowed_keys[@]}"; then
    if in_list "$key" "${CREDENTIAL_KEYS[@]}"; then
      die "$file line $line_number: '$key' is a credential; keep it in the .env file only"
    fi
    die "$file line $line_number: unknown key '$key'"
  fi
  if [[ -n ${target_map[$key]+set} ]]; then
    die "$file line $line_number: '$key' is set twice"
  fi
  unquote_value "$raw" ||
    die "$file line $line_number: unbalanced or misplaced quotes"
  value="$REPLY"
  if has_control_character "$value"; then
    die "$file line $line_number: '$key' contains a control character"
  fi
  if ((${#value} > MAX_VALUE_LENGTH)); then
    die "$file line $line_number: '$key' is too long"
  fi
  # shellcheck disable=SC2004  # target_map is an associative array: $key is a string
  target_map[$key]="$value"
}

# ------------------------------------------------- configuration checks

validate_config() {
  local key url
  if [[ -z ${CONFIG[GITEA_URL]:-} ]]; then
    die "GITEA_URL is missing in $CONFIG_FILE (see config.env.example)"
  fi
  CONFIG[GITHUB_API_URL]="${CONFIG[GITHUB_API_URL]:-https://api.github.com}"
  CONFIG[GITHUB_WEB_URL]="${CONFIG[GITHUB_WEB_URL]:-https://github.com}"
  for key in GITHUB_API_URL GITHUB_WEB_URL GITEA_URL; do
    url="$(normalize_url "${CONFIG[$key]}")"
    is_valid_base_url "$url" ||
      die "$key in $CONFIG_FILE must be an https URL without credentials, query or fragment"
    CONFIG[$key]="$url"
  done
  CONFIG[GITEA_API_URL]="$(normalize_url "${CONFIG[GITEA_API_URL]:-${CONFIG[GITEA_URL]}/api/v1}")"
  is_valid_base_url "${CONFIG[GITEA_API_URL]}" ||
    die "GITEA_API_URL in $CONFIG_FILE must be an https URL without credentials, query or fragment"
}

validate_credentials() {
  if [[ -z ${CREDENTIALS[GITEA_TOKEN]:-} ]]; then
    die "GITEA_TOKEN is missing in $ENV_FILE (see .env.example)"
  fi
  # Register secrets first so that no later message can show them.
  SECRET_VALUES+=("${CREDENTIALS[GITEA_TOKEN]}")
  if [[ -n ${CREDENTIALS[GITHUB_PAT]:-} ]]; then
    SECRET_VALUES+=("${CREDENTIALS[GITHUB_PAT]}")
  fi
  is_valid_token "${CREDENTIALS[GITEA_TOKEN]}" ||
    die "GITEA_TOKEN in $ENV_FILE is not a valid token (8 to 255 letters, digits or _ . ~ + / = -)"
  if [[ -n ${CREDENTIALS[GITHUB_PAT]:-} ]] &&
    ! is_valid_token "${CREDENTIALS[GITHUB_PAT]}"; then
    die "GITHUB_PAT in $ENV_FILE is not a valid token (8 to 255 letters, digits or _ . ~ + / = -)"
  fi
  if [[ -n ${CREDENTIALS[GITHUB_USER]:-} ]] &&
    ! is_valid_github_owner "${CREDENTIALS[GITHUB_USER]}"; then
    die "GITHUB_USER in $ENV_FILE is not a valid GitHub account name"
  fi
}

# GitHub credentials are only needed when the Maintainer chose GitHub.
require_github_credentials() {
  local key
  for key in GITHUB_PAT GITHUB_USER; do
    if [[ -z ${CREDENTIALS[$key]:-} ]]; then
      die "GitHub was chosen but $key is missing in $ENV_FILE (see .env.example)"
    fi
  done
}

warn_if_env_unsafe() {
  local file="$1" dir mode
  case "$(uname -s 2>/dev/null || true)" in
    MINGW* | MSYS* | CYGWIN*) ;;
    *)
      mode="$(stat -c '%a' -- "$file" 2>/dev/null ||
        stat -f '%Lp' -- "$file" 2>/dev/null || true)"
      if [[ -n $mode ]] && (((8#$mode & 8#077) != 0)); then
        warn "$file is readable by other users (mode $mode); run: chmod 600 $file"
      fi
      ;;
  esac
  dir="."
  if [[ $file == */* ]]; then
    dir="${file%/*}"
  fi
  if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 &&
    ! git -C "$dir" check-ignore -q -- "$file"; then
    warn "$file is not ignored by git; add it to .gitignore before committing"
  fi
}

load_configuration() {
  parse_env_file "$CONFIG_FILE" CONFIG_KEYS CONFIG
  validate_config
  parse_env_file "$ENV_FILE" CREDENTIAL_KEYS CREDENTIALS
  validate_credentials
  warn_if_env_unsafe "$ENV_FILE"
}

# -------------------------------------------------------------- tool check

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

# --------------------------------------------------------------- JSON

# json_escape TEXT: escape TEXT for use inside a JSON string.
json_escape() {
  local text="$1"
  text="${text//\\/\\\\}"
  text="${text//\"/\\\"}"
  text="${text//$'\n'/\\n}"
  text="${text//$'\r'/\\r}"
  text="${text//$'\t'/\\t}"
  printf '%s' "$text"
}

# json_get FILE KEY: print the string, number or boolean value of KEY.
# With jq only the top-level key is read. Without jq the first occurrence of
# the key anywhere in the file is used, which is enough for the flat fields
# the GitHub and Gitea APIs return (name, id, html_url, ...).
json_get() {
  local file="$1" key="$2"
  [[ $key =~ ^[A-Za-z0-9_]+$ ]] || die "internal error: invalid JSON key"
  if ((HAS_JQ)); then
    # jq on Windows ends lines with CRLF; strip the CR so values stay clean.
    jq -r --arg key "$key" \
      'if has($key) and .[$key] != null then .[$key] | tostring else empty end' \
      "$file" | tr -d '\r'
  else
    # grep exits 1 when the key is absent; that is not an error here.
    { grep -o "\"$key\"[[:space:]]*:[[:space:]]*\(\"[^\"]*\"\|[0-9][0-9]*\|true\|false\)" "$file" || true; } |
      head -n 1 |
      sed -e 's/^[^:]*:[[:space:]]*//' -e 's/^"\(.*\)"$/\1/'
  fi
}

# --------------------------------------------------------------- HTTP

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
    --config "$config_file" "${data_args[@]}" 2>/dev/null)" || curl_status=$?
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

# ------------------------------------------------------------- prompts

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

collect_project_details() {
  prompt_value "Repository name" "" is_valid_repo_name \
    "use letters, digits, '.', '_' or '-' (at most 100), not ending in .git"
  PROJECT[name]="$REPLY"
  prompt_value "Description (optional)" "" is_valid_description \
    "at most $MAX_DESCRIPTION_LENGTH characters and no control characters"
  PROJECT[description]="$REPLY"
  prompt_choice "Visibility" private private public
  PROJECT[visibility]="$REPLY"
  prompt_value "Gitea owner (user or organization)" "" is_valid_gitea_owner \
    "use letters, digits, '.', '_' or '-' (at most 39)"
  PROJECT[gitea_owner]="$REPLY"
  prompt_yes_no "Also create a GitHub repository (applies the AGPL license)" y
  PROJECT[has_github]="$REPLY"
  PROJECT[github_owner]=""
  if ((PROJECT[has_github])); then
    prompt_value "GitHub owner (user or organization)" \
      "${CREDENTIALS[GITHUB_USER]:-}" is_valid_github_owner \
      "use letters, digits or '-' (at most 39)"
    PROJECT[github_owner]="$REPLY"
  fi
  prompt_value "Local directory" "./${PROJECT[name]}" is_valid_directory \
    "must not be empty, start with '-' or contain control characters"
  PROJECT[directory]="$REPLY"
  prompt_yes_no "Enable the plan gate" n
  PROJECT[is_plan_gate_enabled]="$REPLY"
}

# ------------------------------------------------------------- summary

yes_no() {
  if (($1)); then
    printf 'yes'
  else
    printf 'no'
  fi
}

credential_state() {
  if [[ -n ${CREDENTIALS[$1]:-} ]]; then
    printf 'set'
  else
    printf 'not set'
  fi
}

print_summary() {
  say ""
  say "$PROJECT_NAME $VERSION: nothing has been created yet."
  say "Collected details:"
  say "  Repository   : ${PROJECT[name]} (${PROJECT[visibility]})"
  say "  Description  : ${PROJECT[description]:-(none)}"
  say "  Gitea        : ${CONFIG[GITEA_URL]}/${PROJECT[gitea_owner]}/${PROJECT[name]}"
  if ((PROJECT[has_github])); then
    say "  GitHub       : ${CONFIG[GITHUB_WEB_URL]}/${PROJECT[github_owner]}/${PROJECT[name]} (AGPL license applied)"
  else
    say "  GitHub       : not used"
  fi
  say "  Directory    : ${PROJECT[directory]}"
  say "  Plan gate    : $(yes_no "${PROJECT[is_plan_gate_enabled]}")"
  say "Credentials    : GITEA_TOKEN $(credential_state GITEA_TOKEN)," \
    "GITHUB_PAT $(credential_state GITHUB_PAT)"
  say "Creating the repositories and the project comes in later phases."
}

# ---------------------------------------------------------------- main

parse_args() {
  while (($# > 0)); do
    case "$1" in
      --config)
        (($# >= 2)) || usage_error "--config needs a file"
        CONFIG_FILE="$2"
        shift 2
        ;;
      --env)
        (($# >= 2)) || usage_error "--env needs a file"
        ENV_FILE="$2"
        shift 2
        ;;
      -h | --help)
        sed -n '2,/^set -Eeuo/p' "${BASH_SOURCE[0]}" | sed -e '$d' -e 's/^# \{0,1\}//'
        exit 0
        ;;
      --version)
        say "$PROJECT_NAME $VERSION"
        exit 0
        ;;
      *) usage_error "unknown option: $1" ;;
    esac
  done
}

main() {
  trap 'on_error "$LINENO"' ERR
  trap cleanup EXIT
  is_valid_repo_name "$PROJECT_NAME" ||
    die "REPOFOUNDRY_NAME is not a valid project name"
  parse_args "$@"
  check_tools
  setup_temp_dir
  load_configuration
  collect_project_details
  if ((PROJECT[has_github])); then
    require_github_credentials
  fi
  print_summary
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
