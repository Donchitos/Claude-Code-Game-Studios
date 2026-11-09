#!/usr/bin/env bash
# references-save.sh — save images the person pasted into this Claude Code session into the
# project's references/ folder, so the one-shot and every later change can look at them again.
#
# Claude Code hands a pasted image to the model as picture data, never as a file: the only copy
# is in the session's log, <config>/projects/<project>/<session id>.jsonl, where the message the
# person typed lists its paste numbers ("imagePasteIds":[3,4]) and holds its images in the same
# order. This reads that log. The log's format is Claude Code's own and undocumented (seen in
# 2.1.300 and 2.1.301); when the session or its log cannot be found it says so and saves nothing,
# and a picture it cannot find is reported missing, so the skill asks for the file instead.
#
# Usage: bash .claude/scripts/references-save.sh <N> [<N> ...] [--root DIR]
#   <N>         the number of a pasted image, as in [Image #N]
#   --root DIR  the project; defaults to the repo this script is in
#   -h, --help  this text
# CLAUDE_CODE_SESSION_ID names the session (Claude Code sets it); CLAUDE_CONFIG_DIR, when set,
# is the config folder in place of ~/.claude.
#
# Output: TSV.
#   log           <path>                  the session log read
#   saved         references/<file> <N>   a new file, pasted-<n>.<png|jpg|gif|webp>, n the
#                                         first number free
#   kept          references/<file> <N>   the same picture is already in references/
#   missing       <N>                     no pasted image with that number in the log
#   not_assessed  <why>                   no session id, no log for it, or no base64 decoder
#                                         (exit 3; nothing written)
#
# Exit codes: 0 every number saved or kept; 1 references/ cannot be made or a picture could
# not be written; 2 usage error; 3 not assessed; 4 a number had no pasted image (the others
# are still saved).
#
# references/ is made only when there is a picture to save. Only a message the person typed
# carries paste numbers, so a picture a tool returned is never taken for a paste.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
IDS=""; ROOT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "references-save: --root needs a value" >&2; exit 2; }; ROOT_ARG="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) echo "references-save: unknown argument: $1 (try --help)" >&2; exit 2 ;;
    ""|*[!0-9]*) echo "references-save: '$1' is not a paste number (the N of [Image #N])" >&2; exit 2 ;;
    *) IDS="$IDS $1"; shift ;;
  esac
done
[ -n "$IDS" ] || { echo "references-save: name at least one paste number (try --help)" >&2; exit 2; }

ROOT="${ROOT_ARG:-$HERE/../..}"
[ -d "$ROOT" ] || { echo "references-save: no such folder: $ROOT" >&2; exit 1; }
ROOT="$(cd "$ROOT" && pwd)"
REF="$ROOT/references"

not_assessed() { printf 'not_assessed\t%s\n' "$1"; exit 3; }

SID="${CLAUDE_CODE_SESSION_ID:-}"
[ -n "$SID" ] || not_assessed "no Claude Code session here (CLAUDE_CODE_SESSION_ID is not set)"
case "$SID" in *[!A-Za-z0-9-]*) not_assessed "not a session id this reads: $SID" ;; esac
CONF="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
LOG=""
for f in "$CONF"/projects/*/"$SID".jsonl; do
  [ -f "$f" ] && { LOG="$f"; break; }
done
[ -n "$LOG" ] || not_assessed "no log for session $SID under $CONF/projects"

DEC=""
for d in "base64 -d" "base64 -D" "openssl base64 -d -A"; do
  [ "$(printf 'QQ==' | $d 2>/dev/null)" = "A" ] && { DEC="$d"; break; }
done
[ -n "$DEC" ] || not_assessed "no base64 decoder found (base64 or openssl)"
printf 'log\t%s\n' "$LOG"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/references-save.XXXXXX")" || { echo "references-save: no temporary folder" >&2; exit 1; }
trap 'rm -rf "$WORK"' EXIT

# One pass over the log. A typed message's paste numbers pair, in order, with its image blocks;
# a later message with the same number wins. Each wanted picture lands in $WORK as <N>.b64 and
# <N>.type.
awk -v want="$IDS" -v out="$WORK" '
BEGIN { n = split(want, w, " "); for (i = 1; i <= n; i++) wanted[w[i]] = 1 }
index($0, "\"imagePasteIds\":[") {
  s = substr($0, index($0, "\"imagePasteIds\":[") + 17)
  s = substr(s, 1, index(s, "]") - 1)
  k = split(s, ids, ",")
  rest = $0; j = 0
  while (match(rest, /"type":"image","source":[{]"type":"base64","media_type":"image\/[a-z]+","data":"[A-Za-z0-9+\/=]*"/)) {
    j++
    blk = substr(rest, RSTART, RLENGTH)
    rest = substr(rest, RSTART + RLENGTH)
    if (j > k || !(ids[j] in wanted)) continue
    mt = blk; sub(/^.*"media_type":"image\//, "", mt); sub(/".*$/, "", mt)
    dt = blk; sub(/^.*"data":"/, "", dt); sub(/"$/, "", dt)
    media[ids[j]] = mt; data[ids[j]] = dt
  }
}
END {
  for (id in media) {
    printf "%s", data[id] > (out "/" id ".b64"); close(out "/" id ".b64")
    printf "%s", media[id] > (out "/" id ".type"); close(out "/" id ".type")
  }
}' "$LOG"

STATUS=0
for n in $IDS; do
  if [ ! -f "$WORK/$n.b64" ]; then
    printf 'missing\t%s\n' "$n"
    [ "$STATUS" -eq 0 ] && STATUS=4
    continue
  fi
  case "$(cat "$WORK/$n.type")" in
    png) ext=png ;; jpeg|jpg) ext=jpg ;; gif) ext=gif ;; webp) ext=webp ;; *) ext=img ;;
  esac
  if ! $DEC < "$WORK/$n.b64" > "$WORK/$n.bin" 2>/dev/null || [ ! -s "$WORK/$n.bin" ]; then
    echo "references-save: image $n could not be decoded" >&2; STATUS=1; continue
  fi
  same=""
  if [ -d "$REF" ]; then
    for f in "$REF"/*; do
      [ -f "$f" ] && cmp -s "$WORK/$n.bin" "$f" && { same="${f##*/}"; break; }
    done
  fi
  if [ -n "$same" ]; then
    printf 'kept\treferences/%s\t%s\n' "$same" "$n"
    continue
  fi
  mkdir -p "$REF" 2>/dev/null || { echo "references-save: cannot make $REF" >&2; exit 1; }
  i=1
  while :; do
    set -- "$REF"/pasted-$i.*
    [ -e "$1" ] || break
    i=$((i + 1))
  done
  if cp "$WORK/$n.bin" "$REF/pasted-$i.$ext" 2>/dev/null; then
    printf 'saved\treferences/pasted-%s.%s\t%s\n' "$i" "$ext" "$n"
  else
    echo "references-save: could not write $REF/pasted-$i.$ext" >&2; STATUS=1
  fi
done
exit "$STATUS"
