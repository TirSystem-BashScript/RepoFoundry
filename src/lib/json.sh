# shellcheck shell=bash
# shellcheck disable=SC2004,SC2034,SC2154  # shared state and arrays are declared in constants.sh
# json.sh - Reading and writing the small amount of JSON the script needs.
#
# Part of create-project.sh: sourced by it, never run on its own.
#
# Provides: json_escape, json_get, json_has_value, json_values

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

# json_has_value FILE KEY VALUE: succeed if the file holds "KEY": "VALUE",
# written with or without a space after the colon.
json_has_value() {
  local file="$1" key="$2" value="$3"
  grep -Fq "\"$key\":\"$value\"" "$file" ||
    grep -Fq "\"$key\": \"$value\"" "$file"
}

# json_values FILE KEY: print every string value of KEY, one per line.
json_values() {
  local file="$1" key="$2"
  [[ $key =~ ^[A-Za-z0-9_]+$ ]] || die "internal error: invalid JSON key"
  # grep exits 1 when the key is absent; that is not an error here.
  { grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" || true; } |
    sed -e 's/^[^:]*:[[:space:]]*//' -e 's/^"\(.*\)"$/\1/'
}
