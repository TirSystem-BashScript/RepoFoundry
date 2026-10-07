# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# cli.sh - The command line: usage text and option parsing.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: usage, usage_error, parse_args

usage() {
  cat <<EOF
Usage: ${0##*/} [--apply] [--config FILE] [--env FILE]
       Without --config and --env, ./config.env and ./.env in the current folder
       are read, then the ones in the checkout.
       ${0##*/} --help | --version
EOF
}

usage_error() {
  printf 'error: %s\n' "$1" >&2
  usage >&2
  exit "$EXIT_USAGE"
}

parse_args() {
  while (($# > 0)); do
    case "$1" in
      --apply)
        IS_APPLY=1
        shift
        ;;
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
        sed -n '2,/^set -Eeuo/p' "$SCRIPT_FILE" | sed -e '$d' -e 's/^# \{0,1\}//'
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
