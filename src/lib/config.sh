# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# config.sh - Reading and checking config.env and .env (parsed, never sourced).
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: unquote_value, parse_env_file, parse_env_entry, validate_config, check_preset, check_preset_choice, validate_project_presets, validate_credentials, require_github_credentials, warn_if_env_unsafe, load_configuration

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
  CONFIG[GITEA_SSH_PORT]="${CONFIG[GITEA_SSH_PORT]:-$DEFAULT_SSH_PORT}"
  is_valid_port "${CONFIG[GITEA_SSH_PORT]}" ||
    die "GITEA_SSH_PORT in $CONFIG_FILE must be a port number from 1 to 65535"
  CONFIG[MIRROR_INTERVAL]="${CONFIG[MIRROR_INTERVAL]:-$DEFAULT_MIRROR_INTERVAL}"
  is_valid_interval "${CONFIG[MIRROR_INTERVAL]}" ||
    die "MIRROR_INTERVAL in $CONFIG_FILE must look like 10m0s or 8h0m0s"
  CONFIG[FRAMEWORK_REPO]="${CONFIG[FRAMEWORK_REPO]:-$DEFAULT_FRAMEWORK_REPO}"
  is_valid_framework_repo "${CONFIG[FRAMEWORK_REPO]}" ||
    die "FRAMEWORK_REPO in $CONFIG_FILE must look like OWNER/NAME"
  validate_project_presets
}

# check_preset KEY VALIDATOR HINT: when KEY is set in config.env its value must
# pass VALIDATOR. A key that is present counts as set; only the description
# may be empty. The message names the key, never the value.
check_preset() {
  local key="$1" validator="$2" hint="$3"
  [[ -n ${CONFIG[$key]+set} ]] || return 0
  if [[ -z ${CONFIG[$key]} && $key != PROJECT_DESCRIPTION ]]; then
    die "$key in $CONFIG_FILE is empty; remove the line to be asked, or give a value ($hint)"
  fi
  "$validator" "${CONFIG[$key]}" ||
    die "$key in $CONFIG_FILE is not valid: $hint"
}

# check_preset_choice KEY CHOICE...: like check_preset for a fixed list of
# words; the value is stored in lower case.
check_preset_choice() {
  local key="$1"
  shift
  [[ -n ${CONFIG[$key]+set} ]] || return 0
  [[ -n ${CONFIG[$key]} ]] ||
    die "$key in $CONFIG_FILE is empty; remove the line to be asked, or give one of: $*"
  CONFIG[$key]="${CONFIG[$key],,}"
  in_list "${CONFIG[$key]}" "$@" ||
    die "$key in $CONFIG_FILE must be one of: $*"
}

# The optional project details that may be preset in config.env.
validate_project_presets() {
  check_preset PROJECT_NAME is_valid_repo_name "$HINT_REPO_NAME"
  check_preset PROJECT_DESCRIPTION is_valid_description "$HINT_DESCRIPTION"
  check_preset_choice PROJECT_VISIBILITY private public
  check_preset GITEA_OWNER is_valid_gitea_owner "$HINT_GITEA_OWNER"
  check_preset_choice USE_GITHUB yes no
  check_preset GITHUB_OWNER is_valid_github_owner "$HINT_GITHUB_OWNER"
  check_preset PROJECT_DIRECTORY is_valid_directory "$HINT_DIRECTORY"
  check_preset_choice ENABLE_PLAN_GATE yes no
  check_preset PROJECT_LICENSE is_valid_license "$HINT_LICENSE"
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
