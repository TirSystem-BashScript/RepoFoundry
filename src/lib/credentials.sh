# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# credentials.sh - Asking for a credential that .env does not provide.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: credential_label, collect_credentials

# credential_label KEY: the name of a credential as the Maintainer sees it.
credential_label() {
  case "$1" in
    GITEA_TOKEN) printf 'Gitea access token' ;;
    GITHUB_PAT) printf 'GitHub personal access token' ;;
    GITHUB_USER) printf 'GitHub account name (the account the token belongs to)' ;;
    *) printf '%s' "$1" ;;
  esac
}

# collect_credentials KEY...: ask for each credential that is not already
# provided. A token is read without echo and registered as a secret at once,
# so no later message can show it; the GitHub account name is not secret and
# is read like any other answer. An empty value in .env counts as not provided.
collect_credentials() {
  local key
  for key in "$@"; do
    if [[ -n ${CREDENTIALS[$key]:-} ]]; then
      continue
    fi
    case "$key" in
      GITHUB_USER)
        prompt_value "$(credential_label "$key")" "" is_valid_github_owner \
          "use letters, digits or '-' (at most 39)"
        ;;
      *)
        prompt_secret "$(credential_label "$key")" is_valid_token "$HINT_TOKEN"
        SECRET_VALUES+=("$REPLY")
        ;;
    esac
    CREDENTIALS[$key]="$REPLY"
    REPLY=""
  done
}
