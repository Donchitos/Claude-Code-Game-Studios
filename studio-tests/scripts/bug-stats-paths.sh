#!/usr/bin/env bash
# Run with bash studio-tests/scripts/bug-stats-paths.sh [path/to/bug-stats.sh].
# Uses fixtures only; no engine, Python or jq is needed.
set -eu

HERE=$(cd "$(dirname "$0")" && pwd -P)
SCRIPT=${1:-"$HERE/../../.claude/scripts/bug-stats.sh"}
BASE=$(cd "${TMPDIR:-/tmp}" && pwd -P)
FIXTURE=$(mktemp -d "$BASE/ccgs-bug-stats-XXXXXX")
cleanup() {
  case "$FIXTURE" in "$BASE"/ccgs-bug-stats-*) rm -rf -- "$FIXTURE" ;; esac
}
trap cleanup EXIT
ROOT="$FIXTURE/project with spaces"
mkdir -p "$ROOT/production/qa/bugs" "$ROOT/archived bugs" "$ROOT/empty" "$ROOT/-bugs" "$FIXTURE/external"
cat > "$ROOT/production/qa/bugs/BUG-0001.md" <<'EOF'
**ID**: BUG-0001
**Title**: Save file is not restored
**Severity**: S2-High
**Status**: Open
**Reported**: 2026-11-01
- **System**: Save/Load
EOF
cat > "$ROOT/archived bugs/BUG-0002.md" <<'EOF'
**ID**: BUG-0002
**Severity**: S3-Medium
**Status**: Closed
EOF
# The same ID in a different file must still be counted: de-duplicate paths,
# not bug IDs or file contents.
cp "$ROOT/production/qa/bugs/BUG-0001.md" "$FIXTURE/external/BUG-0001.md"
: > "$ROOT/empty/BUG-0003.md"
: > "$ROOT/-bugs/BUG-0004.md"

check() {
  label=$1; expected=$2; expected_open=$3; expected_s2=$4; shift 4
  output=$(bash "$SCRIPT" --root "$ROOT" --today 2026-11-03 "$@")
  bugs=$(printf '%s\n' "$output" | awk -F '\t' '$1 == "bugs" { print $2 }')
  open=$(printf '%s\n' "$output" | awk -F '\t' '$1 == "open" { print $2 }')
  s2=$(printf '%s\n' "$output" | awk -F '\t' '$1 == "open_s2" { print $2 }')
  rows=$(printf '%s\n' "$output" | awk -F '\t' '$1 == "BUG" { n++ } END { print n+0 }')
  if [ "$bugs/$open/$s2/$rows" != "$expected/$expected_open/$expected_s2/$expected" ]; then
    printf 'FAIL %s: bugs/open/S2/rows=%s/%s/%s/%s\n%s\n' "$label" "$bugs" "$open" "$s2" "$rows" "$output" >&2
    exit 1
  fi
  printf 'PASS %s\n' "$label"
}

check default 1 1 1
check relative-overlap 1 1 1 production production/qa/bugs
check absolute-overlap 1 1 1 production "$ROOT/production/qa/bugs"
check dot-components 1 1 1 production production/qa/../qa/bugs ./production/qa/bugs/
check project-root-alias 4 3 1 . "$ROOT" production
check spaces 2 1 1 production 'archived bugs' "$ROOT/archived bugs"
check external-distinct-file 2 2 2 production "$FIXTURE/external" "$FIXTURE/external/."
check missing 0 0 0 missing "$ROOT/does-not-exist"
check empty-bug 1 1 0 empty "$ROOT/empty"
check leading-dash-directory 1 1 0 "$ROOT/-bugs"
if command -v cygpath >/dev/null 2>&1; then
  check windows-drive-path 1 1 1 production "$(cygpath -m "$ROOT/production/qa/bugs")"
  check windows-backslashes 1 1 1 production "$(cygpath -w "$ROOT/production/qa/bugs")"
fi
