#!/usr/bin/env bash
# test-structure.sh - guards for the split of create-project.sh into files
# with one responsibility each. Sourced by run-tests.sh.

# shellcheck disable=SC2016  # snippet and pattern text is literal on purpose

# lib_names: the names of the files in src/lib, one per line.
lib_names() {
  local file
  for file in "$SRC_DIR"/lib/*.sh; do
    file="${file##*/}"
    printf '%s\n' "${file%.sh}"
  done
}

test_every_library_file_is_loaded_and_nothing_else() {
  local loaded on_disk
  loaded="$(grep -E '^source "\$SCRIPT_DIR/lib/' "$SCRIPT" | sed -e 's|.*/lib/||' -e 's|\.sh"$||' | sort)"
  on_disk="$(lib_names | sort)"
  assert_eq "the files that are loaded are the files in src/lib" "$on_disk" "$loaded"
}

test_every_library_file_states_one_responsibility() {
  local name line
  for name in $(lib_names); do
    line="$(head -n 4 "$SRC_DIR/lib/$name.sh" | grep -m 1 "^# $name.sh - " || true)"
    check
    if [[ -z $line ]]; then
      fail "src/lib/$name.sh must name its responsibility in its first lines ('# $name.sh - ...')"
    fi
    check
    if ! grep -q '^# Provides: ' "$SRC_DIR/lib/$name.sh" && [[ $name != constants ]]; then
      fail "src/lib/$name.sh does not list what it provides"
    fi
  done
}

test_no_function_is_defined_twice() {
  local duplicates
  duplicates="$(cat "$SCRIPT" "$SRC_DIR"/lib/*.sh | grep -oE '^[a-z_]+\(\) \{' | sort | uniq -d)"
  assert_eq "each function is defined in exactly one file" "" "$duplicates"
}

test_the_listed_functions_exist_in_their_file() {
  local name list fn
  for name in $(lib_names); do
    list="$(sed -n 's/^# Provides: //p' "$SRC_DIR/lib/$name.sh" | tr -d ',')"
    for fn in $list; do
      check
      if ! grep -q "^$fn() {" "$SRC_DIR/lib/$name.sh"; then
        fail "src/lib/$name.sh says it provides $fn but does not define it"
      fi
    done
  done
}

test_library_files_have_no_side_effects_when_sourced_alone() {
  # A library file only defines functions and constants: running it by itself
  # (after the constants) prints nothing and makes no request.
  local name
  write_curl_stub
  for name in $(lib_names); do
    if [[ $name == constants ]]; then
      continue
    fi
    STATUS=0
    PATH="$WORK/bin:$PATH" STUB_DIR="$WORK" "$BASH" -c \
      'SCRIPT_DIR="$1"; PROJECT_ROOT="$2"; source "$1/lib/constants.sh"; source "$1/lib/$3.sh"' \
      _ "$SRC_DIR" "$REPO_ROOT" "$name" >"$WORK/out.txt" 2>"$WORK/err.txt" || STATUS=$?
    assert_status "sourcing lib/$name.sh" 0 "$STATUS"
    assert_eq "lib/$name.sh prints nothing" "" "$(cat "$WORK/out.txt" "$WORK/err.txt")"
  done
  assert_eq "no request made by sourcing" "" "$(calls)"
}

test_the_entry_point_is_small_and_holds_no_helpers() {
  local helpers
  helpers="$(grep -oE '^[a-z_]+\(\) \{' "$SCRIPT" | tr -d '(){ ' | sort | tr '\n' ' ')"
  assert_eq "only finish and main live in the entry point" "finish main " "$helpers"
}

test_no_library_file_is_ignored_by_git() {
  # The Python template in .gitignore ignores any folder named lib/; a file
  # that git ignores would silently be left out of every commit.
  local name
  for name in $(lib_names); do
    check
    if git -C "$REPO_ROOT" check-ignore -q --no-index "src/lib/$name.sh"; then
      fail "src/lib/$name.sh is ignored by git; check .gitignore (!src/lib)"
    fi
  done
}
