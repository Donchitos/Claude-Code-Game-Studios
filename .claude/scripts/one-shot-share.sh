#!/usr/bin/env bash
# one-shot-share.sh — make a one-shot's shared build: prototypes/<name>/dist/, the game as a
# player gets it. The tweak panel (tune.js, when the game has one) and the working files (bot.js,
# brief.md, feel-log.md, REPORT.md, evidence/, dotfiles) are left out, and index.html's tune.js
# tag is taken out.
#
# /prototype runs it when the person asks to share or export a game. Everything else in the
# folder is copied as it is. An old dist/ is replaced. The game's own folder is never changed.
# Afterwards the copied pages, scripts, styles and data are searched for "tune.js": a reference
# the script could not take out is a found row. To put dist/ online, on a hidden itch.io page or
# a web link: .claude/docs/share-link.md.
#
# Usage: bash .claude/scripts/one-shot-share.sh <folder> [--root DIR]
#   <folder>     the game's folder, prototypes/<name>
#   --root DIR   the project; defaults to the repo this script is in
#   -h, --help   this text
#
# Output: TSV.
#   dist      <folder>/dist                the shared build
#   left_out  <name>                       a file or folder not copied, one row each
#   stripped  index.html <tag>             a tune.js script tag taken out of the page
#   found     <file> <line>                a tune.js reference left in the shared build (exit 5)
#   files     <count>                      the files in the shared build
#
# Exit codes: 0 made; 1 the folder has no index.html, or a copy failed; 2 usage error; 5 made,
# but a tune.js reference is left in it (the found rows).
#
# bash 3.2 and BWK awk safe, no Python.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
DIR=""; ROOT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "one-shot-share: --root needs a value" >&2; exit 2; }; ROOT_ARG="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) echo "one-shot-share: unknown argument: $1 (try --help)" >&2; exit 2 ;;
    *) [ -z "$DIR" ] || { echo "one-shot-share: one folder only" >&2; exit 2; }; DIR="$1"; shift ;;
  esac
done
[ -n "$DIR" ] || { echo "one-shot-share: a folder is needed (try --help)" >&2; exit 2; }

ROOT="$(cd "${ROOT_ARG:-$HERE/../..}" 2>/dev/null && pwd)" || { echo "one-shot-share: no such folder: $ROOT_ARG" >&2; exit 1; }
SHOW="${DIR%/}"
case "$DIR" in /*|[A-Za-z]:*) ;; *) DIR="$ROOT/$DIR" ;; esac
DIR="${DIR%/}"
[ -f "$DIR/index.html" ] || { echo "one-shot-share: no index.html in $DIR" >&2; exit 1; }
OUT="$DIR/dist"

rm -rf "$OUT" && mkdir -p "$OUT" || { echo "one-shot-share: cannot make $SHOW/dist" >&2; exit 1; }
printf 'dist\t%s\n' "$SHOW/dist"

while IFS= read -r n; do
  case "$n" in
    ""|dist) ;;
    tune.js|bot.js|brief.md|feel-log.md|REPORT.md|evidence|.*) printf 'left_out\t%s\n' "$n" ;;
    *) cp -R "$DIR/$n" "$OUT/" || { echo "one-shot-share: cannot copy $n" >&2; exit 1; } ;;
  esac
done <<EOF
$(ls -A "$DIR" | sort)
EOF

# The tag in any quoting, with ./ or other attributes; a line left blank goes with it.
NAMES="tune"
awk -v rows="$OUT/.stripped" -v names="$NAMES" '
  BEGIN { BINMODE = 3; re = "<script[^>]*src=[\"\047](\\./)?(" names ")\\.js[\"\047][^>]*>[ \t]*</script>" }
  {
    l = $0; cr = sub(/\r$/, "", l)
    while (match(l, re)) {
      printf "stripped\tindex.html\t%s\n", substr(l, RSTART, RLENGTH) > rows
      l = substr(l, 1, RSTART - 1) substr(l, RSTART + RLENGTH); hit = 1
    }
    if (hit && l ~ /^[ \t]*$/) { hit = 0; next }
    hit = 0
    print l (cr ? "\r" : "")
  }' "$DIR/index.html" > "$OUT/index.html" || { echo "one-shot-share: cannot write $SHOW/dist/index.html" >&2; exit 1; }
[ -f "$OUT/.stripped" ] && { cat "$OUT/.stripped"; rm -f "$OUT/.stripped"; }

FOUND=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  for ln in $(grep -nE "($NAMES)\\.js" "$OUT/$f" | cut -d: -f1); do
    printf 'found\t%s\t%s\n' "$f" "$ln"; FOUND=1
  done
done <<EOF
$(cd "$OUT" && find . -type f \( -name '*.html' -o -name '*.htm' -o -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.json' \) | sed 's|^\./||' | sort)
EOF
printf 'files\t%s\n' "$(find "$OUT" -type f | wc -l | tr -d ' ')"
[ "$FOUND" = 0 ] || exit 5
exit 0
