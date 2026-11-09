#!/usr/bin/env bash
# itch-zip.sh — zips a web game's folder build (dist/) for itch.io: the folder's
# contents with index.html at the top of the zip, then the file count and sizes
# against itch.io's limits for an HTML game.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# Each limit row says within or over; whether to ship is the person's call.
#
# Usage: bash .claude/scripts/itch-zip.sh [--root DIR] [--dist DIR] [--out FILE]
#          [--tool auto|zip|python]
#   --root DIR    the project; defaults to the repo this script is in
#   --dist DIR    the build folder, relative to the project; default dist
#                 (npm run build makes it)
#   --out FILE    the zip, relative to the project or absolute; default
#                 <project folder name>-web.zip in the project
#   --tool T      auto (default): zip, else Python's zipfile (python, python3, py)
#   -h, --help    this text
#
# itch.io's limits for an HTML game (https://itch.io/docs/creators/html5): at most
# 1,000 files, 500 MB unpacked, 200 MB for one file. Sizes are compared in
# millions of bytes, the smaller reading of "MB", so "within" holds either way.
# To share the zip, on a hidden itch.io page or a web link: .claude/docs/share-link.md.
#
# Output: TSV.
#   dist      <folder>  <present|absent>
#   top       index.html  <present|absent>         index.html directly in the folder
#   files     <n>  1000  <within|over>
#   unpacked  <bytes>  500000000  <within|over>
#   largest   <bytes>  200000000  <within|over>  <path>
#   tool      <zip|python>  <the command>
#   zip       <path>  <bytes>
#   entries   <n>  <index.html at the top: yes|no>   read back from the zip
#   not_assessed  <why>                            no build, no index.html, or no tool
#
# Exit codes: 0 the zip was made and read back; 1 the root cannot be read; 2 usage
# error; 3 not assessed (no build folder, no index.html at its top, or no zip
# tool); 4 the zip tool failed or the zip did not read back. An old zip at the
# path is replaced. Never prompts.
#
# bash 3.2 and BWK awk safe; Python only as the zip tool.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
usage() { echo "itch-zip: $1 (try --help)" >&2; exit 2; }
ROOT_ARG=""; DIST=dist; OUT=""; TOOL=auto
while [ $# -gt 0 ]; do
  case "$1" in
    --root|--dist|--out|--tool)
      [ $# -ge 2 ] || usage "$1 needs a value"
      case "$1" in --root) ROOT_ARG="$2" ;; --dist) DIST="$2" ;; --out) OUT="$2" ;; --tool) TOOL="$2" ;; esac
      shift 2 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) usage "unknown argument: $1" ;;
  esac
done
case "$TOOL" in auto|zip|python) ;; *) usage "--tool is auto, zip or python" ;; esac
case "$DIST" in ''|/*|[A-Za-z]:*|*..*) usage "--dist is a folder inside the project, got $DIST" ;; esac

if [ -n "$ROOT_ARG" ]; then cd "$ROOT_ARG" 2>/dev/null || { echo "itch-zip: cannot read root $ROOT_ARG" >&2; exit 1; }
else cd "$HERE/../.." 2>/dev/null || { echo "itch-zip: cannot reach the repo root" >&2; exit 1; }; fi
ROOT=$(pwd)
[ -n "$OUT" ] || OUT="$(basename "$ROOT")-web.zip"
case "$OUT" in /*|[A-Za-z]:*) ;; *) OUT="$ROOT/$OUT" ;; esac
not_assessed() { printf 'not_assessed\t%s\n' "$1"; exit 3; }

DIST=${DIST%/}
if [ -d "$DIST" ]; then printf 'dist\t%s\tpresent\n' "$DIST"
else printf 'dist\t%s\tabsent\n' "$DIST"; not_assessed "no build folder $DIST: npm run build makes it"; fi
if [ -f "$DIST/index.html" ]; then printf 'top\tindex.html\tpresent\n'
else printf 'top\tindex.html\tabsent\n'; not_assessed "no index.html directly in $DIST: itch.io opens the index.html at the top of the zip"; fi

# Sizes, in one wc over every file: "<bytes> <path>" lines, then a total line.
cd "$DIST" || exit 1
LIST=$(find . -type f | sed 's|^\./||' | sort)
N=$(printf '%s\n' "$LIST" | grep -c .)
SIZES=$(printf '%s\n' "$LIST" | awk 'NF' | while IFS= read -r f; do printf '%s\t%s\n' "$(wc -c < "$f" | tr -d ' ')" "$f"; done)
TOTAL=$(printf '%s\n' "$SIZES" | awk -F'\t' '{ s += $1 } END { printf "%.0f", s }')
BIG=$(printf '%s\n' "$SIZES" | awk -F'\t' '$1 + 0 > m { m = $1 + 0; p = $2 } END { printf "%.0f\t%s", m, p }')
lim() { if [ "$1" -le "$2" ]; then echo within; else echo over; fi; }
printf 'files\t%s\t1000\t%s\n' "$N" "$(lim "$N" 1000)"
printf 'unpacked\t%s\t500000000\t%s\n' "$TOTAL" "$(lim "$TOTAL" 500000000)"
printf 'largest\t%s\t200000000\t%s\t%s\n' "${BIG%%	*}" "$(lim "${BIG%%	*}" 200000000)" "${BIG#*	}"

# The zip tool: zip, else Python's zipfile.
PY=""
for _p in python python3 py; do
  if command -v "$_p" >/dev/null 2>&1 && "$_p" -c 'import zipfile' >/dev/null 2>&1; then PY=$_p; break; fi
done
USE=""
case "$TOOL" in
  zip) command -v zip >/dev/null 2>&1 && USE=zip ;;
  python) [ -n "$PY" ] && USE=python ;;
  auto) if command -v zip >/dev/null 2>&1; then USE=zip; elif [ -n "$PY" ]; then USE=python; fi ;;
esac
[ -n "$USE" ] || not_assessed "no zip tool: zip, or Python with zipfile (python, python3, py)"
mkdir -p "$(dirname "$OUT")" 2>/dev/null || { printf 'not_assessed\tcannot make the folder for %s\n' "$OUT"; exit 4; }
NATIVE_OUT=$OUT; command -v cygpath >/dev/null 2>&1 && NATIVE_OUT=$(cygpath -w "$OUT")
rm -f "$OUT"
# The zip is written from inside the build folder, so its paths start there.
PY_WRITE='import os, sys, zipfile
with zipfile.ZipFile(sys.argv[1], "w", zipfile.ZIP_DEFLATED) as z:
    for p in sys.stdin.read().splitlines():
        if p:
            z.write(p, p)'
PY_READ='import sys, zipfile
names = zipfile.ZipFile(sys.argv[1]).namelist()
print(len(names), "yes" if "index.html" in names else "no")'
if [ "$USE" = zip ]; then
  printf 'tool\tzip\tzip -X -q <zip> <each file>\n'
  printf '%s\n' "$LIST" | awk 'NF' | zip -X -q "$OUT" -@ >/dev/null 2>&1; RC=$?
else
  printf 'tool\tpython\t%s -c <zipfile write> <zip>\n' "$PY"
  printf '%s\n' "$LIST" | awk 'NF' | "$PY" -c "$PY_WRITE" "$NATIVE_OUT" 2>/dev/null; RC=$?
fi
cd "$ROOT" || exit 1
[ "$RC" = 0 ] && [ -s "$OUT" ] || { printf 'not_assessed\tthe %s tool failed (exit %s)\n' "$USE" "$RC"; exit 4; }
printf 'zip\t%s\t%s\n' "$OUT" "$(wc -c < "$OUT" | tr -d ' ')"

# Read the zip back: its entry count, and index.html at its top.
BACK=""
if [ -n "$PY" ]; then BACK=$("$PY" -c "$PY_READ" "$NATIVE_OUT" 2>/dev/null | tr -d '\r')
elif command -v unzip >/dev/null 2>&1; then
  BACK=$(unzip -Z1 "$OUT" 2>/dev/null | awk '{ n++ } $0 == "index.html" { t = 1 } END { print n + 0, (t ? "yes" : "no") }')
fi
[ -n "$BACK" ] || { printf 'not_assessed\tthe zip was made but not read back: no Python or unzip\n'; exit 4; }
printf 'entries\t%s\t%s\n' "${BACK% *}" "${BACK#* }"
[ "${BACK% *}" = "$N" ] && [ "${BACK#* }" = yes ] || exit 4
exit 0
