#!/usr/bin/env bash
# one-shot-new.sh — make a one-shot's folder from the starter: prototypes/<name>/ with
# index.html, config.js, assets/provenance.yaml, vendor/ and evidence/, and a copy of
# design/game-brief.md when there is one. The starter is lean (templates/one-shot-lean/): only
# what the checks read. The tweak panel (tune.js) is its one add-on, never in the first build:
# --add tune.js copies it into a game that exists, and its opening comment says how to wire it.
#
# /prototype's one-shot runs it once, before the build, and then edits the files it made. It
# never overwrites: a folder that already exists is reported and left alone, so a second game
# or a resumed build is the skill's question, not this script's.
#
# Usage: bash .claude/scripts/one-shot-new.sh <name> [--question TEXT] [--title TEXT] [--root DIR]
#        bash .claude/scripts/one-shot-new.sh <name> --add tune.js [--root DIR]
#   <name>           the folder name: lower-case letters, digits and hyphens, at most 40
#   --question TEXT  the prototype's question, written into each file's header
#   --title TEXT     the game's title; defaults to the name with spaces for hyphens
#   --add tune.js    into prototypes/<name>/, which must exist: copy the tweak panel, never over
#                    one already there; its opening comment says how to wire it, and its
#                    header takes the question from the game's config.js
#   --root DIR       the project; defaults to the repo this script is in
#   -h, --help       this text
#
# Output: TSV, one row per thing made.
#   created  prototypes/<name>
#   time     <YYYY-MM-DD HH:MM:SS>  the clock when the folder was made
#   file     <path>            index.html, config.js, assets/provenance.yaml, brief.md
#   added    <path>            --add: tune.js copied in
#   kept     <path>            --add: already there, left as it is
#   dir      <path>            vendor, evidence
#   exists   prototypes/<name> (exit 4; nothing written)
#
# Exit codes: 0 made; 1 the starter is missing or a write failed, or --add found no folder;
# 2 usage error; 3 the name is not a folder name this accepts; 4 the folder already exists.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
NAME=""; QUESTION=""; TITLE=""; ROOT_ARG=""; ADD=""
while [ $# -gt 0 ]; do
  case "$1" in
    --question) [ $# -ge 2 ] || { echo "one-shot-new: --question needs a value" >&2; exit 2; }; QUESTION="$2"; shift 2 ;;
    --title) [ $# -ge 2 ] || { echo "one-shot-new: --title needs a value" >&2; exit 2; }; TITLE="$2"; shift 2 ;;
    --add) [ $# -ge 2 ] || { echo "one-shot-new: --add needs a file: tune.js" >&2; exit 2; }; ADD="$ADD $2"; shift 2 ;;
    --root) [ $# -ge 2 ] || { echo "one-shot-new: --root needs a value" >&2; exit 2; }; ROOT_ARG="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) echo "one-shot-new: unknown argument: $1 (try --help)" >&2; exit 2 ;;
    *) [ -z "$NAME" ] || { echo "one-shot-new: one name only" >&2; exit 2; }; NAME="$1"; shift ;;
  esac
done
[ -n "$NAME" ] || { echo "one-shot-new: a name is needed (try --help)" >&2; exit 2; }
case "$NAME" in
  *[!a-z0-9-]*|-*|"") echo "one-shot-new: '$NAME' is not a folder name: use lower-case letters, digits and hyphens, starting with a letter or digit" >&2; exit 3 ;;
esac
[ "${#NAME}" -le 40 ] || { echo "one-shot-new: '$NAME' is longer than 40 characters" >&2; exit 3; }

ROOT="${ROOT_ARG:-$HERE/../..}"
[ -d "$ROOT" ] || { echo "one-shot-new: no such folder: $ROOT" >&2; exit 1; }
ROOT="$(cd "$ROOT" && pwd)"
LEAN="$HERE/../docs/templates/one-shot-lean"
REL="prototypes/$NAME"
DEST="$ROOT/$REL"
if [ -n "$ADD" ]; then # the tweak panel, into a game that exists
  [ -d "$DEST" ] || { echo "one-shot-new: --add: no such game: $REL" >&2; exit 1; }
  for m in $ADD; do
    case "$m" in tune.js) ;;
      *) echo "one-shot-new: --add: not an add-on: $m (tune.js is the one add-on)" >&2; exit 2 ;; esac
    [ -f "$LEAN/$m" ] || { echo "one-shot-new: the starter is missing: $LEAN/$m" >&2; exit 1; }
  done
  ADDING=1
else
  ADDING=0
  FILES="index.html config.js"
  for f in $FILES; do
    [ -f "$LEAN/$f" ] || { echo "one-shot-new: the starter is missing: $LEAN/$f" >&2; exit 1; }
  done
  if [ -e "$DEST" ]; then printf 'exists\t%s\n' "$REL"; exit 4; fi
fi
# An add-on with no --question takes the game's own, from its config.js header.
if [ "$ADDING" = 1 ] && [ -z "$QUESTION" ] && [ -f "$DEST/config.js" ]; then
  QUESTION=$(sed -n 's|^// Question: ||p' "$DEST/config.js" | head -1 | tr -d '\r')
  [ "$QUESTION" = "(not set)" ] && QUESTION=""
fi
[ -n "$TITLE" ] || TITLE=$(printf '%s' "$NAME" | tr '-' ' ')
# One line each: a newline would end the header comment or the JavaScript string early.
QUESTION=$(printf '%s' "$QUESTION" | tr '\r\n' '  ')
TITLE=$(printf '%s' "$TITLE" | tr '\r\n' '  ')
[ -n "$QUESTION" ] || QUESTION="(not set)"
DATE=$(date +%Y-%m-%d)

# Literal replacement through ENVIRON, so &, / and \ in the text arrive as typed. Each
# placeholder gets the escaping its spot needs: an HTML comment cannot hold "--", the
# <title> needs & and < escaped, the JavaScript string needs \ and ' escaped.
fill() { # fill <starter file> <destination>
  Q="$QUESTION" T="$TITLE" D="$DATE" awk '
    function rep(s, from, to,   out, i) {
      out = ""
      while ((i = index(s, from)) > 0) { out = out substr(s, 1, i - 1) to; s = substr(s, i + length(from)) }
      return out s
    }
    BEGIN {
      BINMODE = 3
      q = ENVIRON["Q"]; t = ENVIRON["T"]; d = ENVIRON["D"]
      qc = rep(q, "--", "- -")
      th = rep(rep(t, "&", "&amp;"), "<", "&lt;")
      tj = rep(rep(t, "\\", "\\\\"), "\047", "\\\047")
    }
    {
      l = $0
      if (index(l, "const TITLE = \047@TITLE@\047")) l = rep(l, "@TITLE@", tj)
      else l = rep(l, "@TITLE@", th)
      l = rep(rep(l, "@QUESTION@", qc), "@DATE@", d)
      print l
    }' "$1" > "$2"
}

if [ "$ADDING" = 1 ]; then
  for m in $ADD; do
    if [ -e "$DEST/$m" ]; then printf 'kept\t%s\n' "$REL/$m"
    else fill "$LEAN/$m" "$DEST/$m" || { echo "one-shot-new: cannot write $REL/$m" >&2; exit 1; }; printf 'added\t%s\n' "$REL/$m"; fi
  done
  exit 0
fi
mkdir -p "$DEST/assets" "$DEST/vendor" "$DEST/evidence" || { echo "one-shot-new: cannot make $REL" >&2; exit 1; }
printf 'created\t%s\n' "$REL"
printf 'time\t%s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
for f in $FILES; do
  fill "$LEAN/$f" "$DEST/$f" || { echo "one-shot-new: cannot write $REL/$f" >&2; exit 1; }
  printf 'file\t%s\n' "$REL/$f"
done
cat > "$DEST/assets/provenance.yaml" <<'EOF' || { echo "one-shot-new: cannot write $REL/assets/provenance.yaml" >&2; exit 1; }
# Where each file in assets/ and vendor/ came from, one entry per file. The field names are the
# provenance record's, so the entries carry over when the game grows.
# - path: assets/hit.wav      # relative to this game's folder
#   origin: ai                # ai | bought | cc0 | you | outsourced | template | plugin | licensed | code | unknown
#   tool: "what made or fetched it: the generator, or the script for code"
#   model: "the model ID, when a model made it or an AI wrote its code"
#   source: {vendor: "who made or sold it", product: "its name", url: "where from"}   # a download
#   licence: {id: CC0-1.0}    # a download: the SPDX id where one exists
#   date: 2026-01-31
#   ships: true               # false for a file only the build uses
#   placeholder: true         # until it is replaced; leave the line out otherwise
EOF
printf 'file\t%s\n' "$REL/assets/provenance.yaml"
printf 'dir\t%s\n' "$REL/vendor" "$REL/evidence"
if [ -f "$ROOT/design/game-brief.md" ]; then
  cp "$ROOT/design/game-brief.md" "$DEST/brief.md" || { echo "one-shot-new: cannot copy the brief" >&2; exit 1; }
  printf 'file\t%s\n' "$REL/brief.md"
fi
exit 0
