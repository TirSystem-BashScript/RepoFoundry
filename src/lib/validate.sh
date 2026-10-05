# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# validate.sh - Validators for names, URLs, tokens, ports and intervals.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: is_valid_framework_repo, is_valid_repo_name, is_valid_gitea_owner, is_valid_github_owner, is_valid_description, is_valid_directory, is_valid_base_url, is_valid_request_url, is_valid_token, is_valid_port, is_valid_interval, normalize_url

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

# OWNER/NAME of the framework repository on Gitea.
is_valid_framework_repo() {
  [[ $1 =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ && $1 != */.. && $1 != ../* && $1 != ./* && $1 != */. ]]
}

is_valid_port() {
  [[ $1 =~ ^[0-9]{1,5}$ ]] && ((10#$1 >= 1 && 10#$1 <= 65535))
}

# A Go duration such as 10m0s or 8h0m0s, the form Gitea expects.
is_valid_interval() {
  [[ -n $1 && $1 =~ ^([0-9]+h)?([0-9]+m)?([0-9]+s)?$ ]]
}

normalize_url() {
  local url="$1"
  while [[ $url == */ ]]; do
    url="${url%/}"
  done
  printf '%s' "$url"
}
