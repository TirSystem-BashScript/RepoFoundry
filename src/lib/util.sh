# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# util.sh - Small string and list helpers with no knowledge of the project.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: trim, in_list, has_control_character, is_same_name

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

is_same_name() {
  [[ ${1,,} == "${2,,}" ]]
}
