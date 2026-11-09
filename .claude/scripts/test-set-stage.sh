#!/usr/bin/env bash
# Regression tests for set-stage.sh's paired project.yaml/stage.txt write.
#
# Usage: bash .claude/scripts/test-set-stage.sh

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/set-stage.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/ccgs-set-stage.XXXXXX") || exit 1
TESTS=0
FAILURES=0

cleanup() {
  chmod -R u+w "$TMP_ROOT" 2>/dev/null || true
  rm -rf "$TMP_ROOT"
}
trap cleanup 0

OLD_PROJECT='project:
  stage: Concept'
NEW_PROJECT='project:
  stage: Production'

make_fixture() {
  local root="$1"
  mkdir -p "$root/production"
  printf '%s' "$OLD_PROJECT" > "$root/project.yaml"
  printf '%s' 'Concept' > "$root/production/stage.txt"
}

assert_status() {
  local expected="$1" actual="$2"
  if [ "$actual" != "$expected" ]; then
    echo "  expected exit $expected, got $actual"
    return 1
  fi
}

assert_file() {
  local path="$1" expected="$2" actual
  actual=$(cat "$path" 2>/dev/null) || {
    echo "  could not read $path"
    return 1
  }
  if [ "$actual" != "$expected" ]; then
    echo "  unexpected contents in $path"
    return 1
  fi
}

assert_paired() {
  local root="$1" project="$2" stage="$3"
  assert_file "$root/project.yaml" "$project" || return 1
  assert_file "$root/production/stage.txt" "$stage" || return 1
}

assert_no_temps() {
  local root="$1" found
  found=$(find "$root" -name '.ccgs-stage-*' -print 2>/dev/null)
  if [ -n "$found" ]; then
    echo "  temporary files remain:"
    printf '%s\n' "$found" | sed 's/^/    /'
    return 1
  fi
}

test_writable_success() {
  local root="$TMP_ROOT/success" output stderr_file code
  make_fixture "$root"
  stderr_file="$root/stderr"
  output=$(bash "$SCRIPT" Production --root "$root" 2>"$stderr_file")
  code=$?
  assert_status 0 "$code" || return 1
  assert_paired "$root" "$NEW_PROJECT" "Production" || return 1
  assert_no_temps "$root" || return 1
  if [ -s "$stderr_file" ]; then
    echo "  successful write emitted stderr:"
    sed 's/^/    /' "$stderr_file"
    return 1
  fi
  if [ "$output" != "$(printf 'project.yaml\treplaced\t2\nstage.txt\twritten\t-\nstage_yaml\tProduction\tproject.yaml\nstage_txt\tProduction\tproduction/stage.txt')" ]; then
    echo "  success output changed:"
    printf '%s\n' "$output" | sed 's/^/    /'
    return 1
  fi
}

test_readonly_stage_txt_leaves_both_old() {
  local root="$TMP_ROOT/readonly-stage" stderr_file stdout_file code
  make_fixture "$root"
  stderr_file="$root/stderr"
  stdout_file="$root/stdout"
  chmod 0444 "$root/production/stage.txt"
  bash "$SCRIPT" Production --root "$root" >"$stdout_file" 2>"$stderr_file"
  code=$?
  assert_status 1 "$code" || return 1
  assert_paired "$root" "$OLD_PROJECT" "Concept" || return 1
  assert_no_temps "$root" || return 1
  if [ -s "$stdout_file" ]; then
    echo "  failed write emitted stdout:"
    sed 's/^/    /' "$stdout_file"
    return 1
  fi
}

test_readonly_project_yaml_rolls_stage_back() {
  local root="$TMP_ROOT/readonly-yaml" stderr_file stdout_file code
  make_fixture "$root"
  stderr_file="$root/stderr"
  stdout_file="$root/stdout"
  chmod 0444 "$root/project.yaml"
  bash "$SCRIPT" Production --root "$root" >"$stdout_file" 2>"$stderr_file"
  code=$?
  assert_status 1 "$code" || return 1
  assert_paired "$root" "$OLD_PROJECT" "Concept" || return 1
  assert_no_temps "$root" || return 1
  if [ -s "$stdout_file" ]; then
    echo "  failed write emitted stdout:"
    sed 's/^/    /' "$stdout_file"
    return 1
  fi
}

test_missing_stage_txt_is_created() {
  local root="$TMP_ROOT/missing-stage"
  make_fixture "$root"
  rm "$root/production/stage.txt"
  bash "$SCRIPT" Production --root "$root" >/dev/null 2>&1
  assert_status 0 "$?" || return 1
  assert_paired "$root" "$NEW_PROJECT" "Production" || return 1
  assert_no_temps "$root" || return 1
}

run_test() {
  local name="$1"
  shift
  TESTS=$((TESTS + 1))
  if ( "$@" ); then
    echo "PASS $name"
  else
    echo "FAIL $name"
    FAILURES=$((FAILURES + 1))
  fi
}

run_test "writable success keeps output and paired state" test_writable_success
run_test "read-only stage.txt leaves both files old and removes temps" test_readonly_stage_txt_leaves_both_old
run_test "read-only project.yaml rolls stage.txt back" test_readonly_project_yaml_rolls_stage_back
run_test "missing stage.txt is still created" test_missing_stage_txt_is_created

if [ "$FAILURES" != 0 ]; then
  echo "$FAILURES of $TESTS tests failed"
  exit 1
fi
echo "$TESTS tests passed"
exit 0
