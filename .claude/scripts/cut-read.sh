#!/usr/bin/env bash
# cut-read.sh — what /cut reads to see what exists, as rows: the brief's Features and their marks,
# its Keep, Avoid and Out of scope lines and its Dates line; project.goal; the built game's last
# check record (a one-shot) or smoke command (a project); the feel log; the
# polish list; and the stories traced to a Features item. It proposes nothing: which item to cut,
# and why, is /cut's call.
#
# The game is the one design/game-brief.md describes: the one-shot whose prototypes/<name>/brief.md
# is the same text (or, failing that, has the same title), else the project itself. A root with a
# package.json is a project, a grown one-shot included.
#
# Usage: bash .claude/scripts/cut-read.sh [--today YYYY-MM-DD] [--target YYYY-MM-DD] [--root DIR]
#   --today    the date the rows count from; default today
#   --target   a target date the person gave: adds the freeze proposed 70% of the way to it
#   --root     the project; defaults to the repo this script is in
#   -h, --help this text
#
# Output: TSV.
#   brief          <path>                      a brief /cut writes: design/game-brief.md, and the
#                                              game's folder copy while it is the same text
#   brief_differs  <path>                      the game's folder copy is other text: not written
#   brief          none                        no design/game-brief.md (exit 1)
#   title          <working title>
#   feature        <n> built|not_yet <item>    the Features list, numbered as /create-stories does
#   keep|avoid|out <line>                      each list's lines
#   cut            <line>                      a [-] row in Out of scope, after its [-]
#   recorded       <target> <freeze> <what>    the brief's Dates line
#   recorded       unreadable <line>           a Dates line not in /cut's shape
#   passed         freeze|target <date>        a recorded date before --today
#   proposed       freeze <date> <days>        --target: --today plus 70% of the days to the target
#   target_past    <date>                      --target not after --today: nothing proposed
#   goal           <value> set|unknown <file> | - unset   project.local.yaml, then project.yaml
#   dates          asked|not_asked|guess       asked for sell, early_access and publisher; guess
#                                              when the goal is unset or not one of the nine
#   game           one-shot <folder> | project .
#   record         <path> <time> fresh|stale [<a game file newer than it>] | none
#   open           <check> <why or ->          a fail in the record not marked deliberate
#   smoke          <command> | none <why>      a project: the engine table's smoke command
#   feel           <path> <passes> | none
#   polish         <path> <open> <ticked> | none | other_game <its title>
#   polish_row     open|ticked <row>
#   story          <n>|cut <status> <path>     a story whose Requirement is Brief MVP feature <n>,
#                                              or one /cut moved out (Brief Out of scope: <item>)
#   stories_other  <count>                     stories traced to something else
#
# Exit codes: 0 read; 1 no brief; 2 usage error.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
TODAY=""; TARGET=""; ROOT_ARG=""
use() { echo "cut-read: $1 (try --help)" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --today) [ $# -ge 2 ] || use "--today needs a date"; TODAY="$2"; shift 2 ;;
    --target) [ $# -ge 2 ] || use "--target needs a date"; TARGET="$2"; shift 2 ;;
    --root) [ $# -ge 2 ] || use "--root needs a folder"; ROOT_ARG="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) use "unknown argument: $1" ;;
  esac
done
[ -n "$TODAY" ] || TODAY=$(date +%Y-%m-%d)

# Day numbers (days from 1970-01-01) and back, for a date's validity and the freeze proposal.
DATES='
function dn(y, m, d,   era, yoe, doy) {
  y -= (m <= 2); era = int((y >= 0 ? y : y - 399) / 400); yoe = y - era * 400
  doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
  return era * 146097 + yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy - 719468
}
function day(s) { return dn(substr(s, 1, 4) + 0, substr(s, 6, 2) + 0, substr(s, 9, 2) + 0) }
function iso(z,   era, doe, yoe, doy, mp, d, m, y) {
  z += 719468; era = int((z >= 0 ? z : z - 146096) / 146097); doe = z - era * 146097
  yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365)
  doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100)); mp = int((5 * doy + 2) / 153)
  d = doy - int((153 * mp + 2) / 5) + 1; m = mp + (mp < 10 ? 3 : -9); y = yoe + era * 400 + (m <= 2)
  return sprintf("%04d-%02d-%02d", y, m, d)
}
function ok(s) { return s ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ && iso(day(s)) == s }'
okdate() { awk -v s="$1" "$DATES"' BEGIN { exit !ok(s) }'; }
okdate "$TODAY" || use "--today is a date, YYYY-MM-DD: $TODAY"
[ -z "$TARGET" ] || okdate "$TARGET" || use "--target is a date, YYYY-MM-DD: $TARGET"

ROOT="$(cd "${ROOT_ARG:-$HERE/../..}" 2>/dev/null && pwd)" || use "no such folder: $ROOT_ARG"
cd "$ROOT" || exit 2
BRIEF=design/game-brief.md
[ -f "$BRIEF" ] || { printf 'brief\tnone\n'; exit 1; }
yget() { [ -f "$2" ] && YG_PATH=$1 awk -f "$HERE/yaml-get.awk" "$2"; }

# ---- Which game: a one-shot whose brief is this one, or the project -----------------------------
GAME=project; FOLDER=""; COPY=""
if [ ! -f package.json ]; then
  TL=$(grep -m1 '^# Game Brief:' "$BRIEF" | tr -d '\r'); SAME=""
  for d in prototypes/*/; do
    d=${d%/}; [ -f "$d/brief.md" ] || continue
    if cmp -s "$d/brief.md" "$BRIEF"; then COPY=$d; break; fi
    [ -z "$SAME" ] && [ -n "$TL" ] && [ "$(grep -m1 '^# Game Brief:' "$d/brief.md" | tr -d '\r')" = "$TL" ] && SAME=$d
  done
  FOLDER=${COPY:-$SAME}; [ -n "$FOLDER" ] && GAME=one-shot
fi
printf 'brief\t%s\n' "$BRIEF"
if [ -n "$COPY" ]; then printf 'brief\t%s\n' "$COPY/brief.md"
elif [ -n "$FOLDER" ]; then printf 'brief_differs\t%s\n' "$FOLDER/brief.md"; fi

# ---- The brief ------------------------------------------------------------------------------------
awk -v today="$TODAY" "$DATES"'
  function clean(s) { gsub(/\t/, " ", s); sub(/[ \t]+$/, "", s); return s }
  { sub(/\r$/, "") }
  incom { if (index($0, "-->")) incom = 0; next }
  /^[ \t]*<!--/ { if (!index($0, "-->")) incom = 1; next }
  /^# Game Brief:/ && !t { t = $0; sub(/^# Game Brief: */, "", t); print "title\t" clean(t); next }
  /^## / {
    h = $0; sub(/^## +/, "", h); sec = ""
    if (h ~ /^(Features|MVP)([^A-Za-z]|$)/) sec = "feature"
    else if (h ~ /^Keep([^A-Za-z]|$)/) sec = "keep"
    else if (h ~ /^Avoid([^A-Za-z]|$)/) sec = "avoid"
    else if (h ~ /^Out of scope([^A-Za-z]|$)/) sec = "out"
    next
  }
  /^---[ \t]*$/ { sec = ""; next }
  /^\*\*Dates:\*\*/ {
    d = clean($0); sub(/^\*\*Dates:\*\* */, "", d); sep = ") · freeze "; p = index(d, sep)
    tg = substr(d, 8, 10); fz = substr(d, p + length(sep))
    if (substr(d, 1, 7) == "target " && substr(d, 18, 2) == " (" && p > 20 && ok(tg) && ok(fz)) {
      print "recorded\t" tg "\t" fz "\t" substr(d, 20, p - 20)
      if (fz < today) print "passed\tfreeze\t" fz
      if (tg < today) print "passed\ttarget\t" tg
    } else print "recorded\tunreadable\t" d
    next
  }
  sec == "feature" {
    if ($0 ~ /^[-*] \[[xX]\] /) { mk = "built"; it = substr($0, 7) }
    else if ($0 ~ /^[-*] \[ \] /) { mk = "not_yet"; it = substr($0, 7) }
    else if ($0 ~ /^[-*] \[.\][ \t]*$/ || $0 ~ /^[-*] \[-\]/) next
    else if ($0 ~ /^[-*] /) { mk = "not_yet"; it = substr($0, 3) }
    else if ($0 ~ /^[0-9]+\. /) { mk = "not_yet"; it = $0; sub(/^[0-9]+\. +/, "", it) }
    else next
    it = clean(it); if (it != "") print "feature\t" (++n) "\t" mk "\t" it
    next
  }
  sec != "" && /^[-*] / {
    it = clean(substr($0, 3)); if (it == "") next
    if (sec == "out" && it ~ /^\[-\] /) print "cut\t" substr(it, 5)
    else print sec "\t" it
  }' "$BRIEF"

if [ -n "$TARGET" ]; then
  awk -v t="$TARGET" -v today="$TODAY" "$DATES"' BEGIN {
    if (t <= today) { print "target_past\t" t; exit }
    days = day(t) - day(today); print "proposed\tfreeze\t" iso(day(today) + int(days * 7 / 10)) "\t" days }'
fi

# ---- The goal: whether dates are asked ------------------------------------------------------------
GOAL=""; GSRC=""
for yf in project.local.yaml project.yaml; do
  [ -z "$GOAL" ] || break
  GOAL=$(yget project.goal "$yf"); [ -n "$GOAL" ] && GSRC=$yf
done
case "$GOAL" in
  "") printf 'goal\t-\tunset\n'; D=guess ;;
  sell|early_access|publisher) printf 'goal\t%s\tset\t%s\n' "$GOAL" "$GSRC"; D=asked ;;
  jam|learn|hobby|portfolio|mobile|other) printf 'goal\t%s\tset\t%s\n' "$GOAL" "$GSRC"; D=not_asked ;;
  *) printf 'goal\t%s\tunknown\t%s\n' "$GOAL" "$GSRC"; D=guess ;;
esac
printf 'dates\t%s\n' "$D"

# ---- The built game -------------------------------------------------------------------------------
if [ "$GAME" = one-shot ]; then
  printf 'game\tone-shot\t%s\n' "$FOLDER"
  EV="$FOLDER/evidence"; REC="$EV/check-run.yaml"
  if [ -f "$REC" ]; then
    # Stale when a game file changed after the record: the brief, feel log and polish list are
    # not the game, and the evidence and dist folders are the checks' and the share's.
    NEWER=$(find "$FOLDER" \( -path "$EV" -o -path "$FOLDER/dist" \) -prune -o -type f \
      ! -name brief.md ! -name feel-log.md ! -name polish-list.md -newer "$REC" -print 2>/dev/null | head -1)
    awk -v rec="$REC" -v newer="$NEWER" '
      function flush() {
        if (id == "") return
        if (res == "fail" && mk != "deliberate") open_[++no] = id "\t" (why == "" ? "-" : why)
        id = ""
      }
      { sub(/\r$/, "") }
      /^time: / { tm = substr($0, 7); gsub(/"/, "", tm); next }
      /^checks:/ { inc = 1; next }
      /^[a-z_]+:/ { flush(); inc = 0; next }
      inc && /^  - id: / { flush(); id = substr($0, 9); res = ""; mk = ""; why = ""; next }
      inc && /^    result: / { res = substr($0, 13); next }
      inc && /^    mark: / { mk = substr($0, 11); next }
      inc && /^    why: / { why = substr($0, 10); sub(/^"/, "", why); sub(/"$/, "", why); gsub(/\\"/, "\"", why); next }
      END {
        flush()
        print "record\t" rec "\t" (tm == "" ? "-" : tm) "\t" (newer == "" ? "fresh" : "stale\t" newer)
        for (i = 1; i <= no; i++) print "open\t" open_[i]
      }' "$REC"
  else printf 'record\tnone\n'; fi
  FL="$FOLDER/feel-log.md"
else
  printf 'game\tproject\t.\n'
  printf 'record\tnone\n'
  ENG=""
  for yf in project.local.yaml project.yaml; do [ -n "$ENG" ] || ENG=$(yget engine.name "$yf"); done
  if [ -z "$ENG" ]; then printf 'smoke\tnone\tno engine set\n'
  else
    CMD=$(awk -F'\t' -v engine="$ENG" -v col=smoke -f "$HERE/engine-row.awk" "$HERE/../engines/engines.tsv" 2>/dev/null)
    if [ -n "$CMD" ]; then printf 'smoke\t%s\n' "$CMD"
    else printf 'smoke\tnone\tthe engine table has no smoke command for %s\n' "$ENG"; fi
  fi
  FL=design/feel-log.md
fi

# ---- The feel log ------------------------------------------------------------------------------
if [ -f "$FL" ]; then
  awk -v fl="$FL" '{ sub(/\r$/, "") }
    /^## Feel pass / { np++ }
    END {
      print "feel\t" fl "\t" (np + 0)
    }' "$FL"
else printf 'feel\tnone\n'; fi

# ---- The polish list ------------------------------------------------------------------------------
PL=design/polish-list.md
if [ -f "$PL" ]; then
  awk -v pl="$PL" -v want="$(sed -n 's/^# Game Brief: *//p' "$BRIEF" | head -1 | tr -d '\r')" '
    function name(x) { sub(/[ \t]*\*\([^)]*\)\*[ \t]*$/, "", x); return x } # as cut-apply.sh names the game
    { sub(/\r$/, "") }
    /^# Polish list: / && t == "" { t = substr($0, 16) }
    /^- \[ \] / { r[++n] = "open\t" substr($0, 7); o++ }
    /^- \[[xX]\] / { r[++n] = "ticked\t" substr($0, 7); k++ }
    END {
      if (t != "" && name(t) != name(want)) { print "polish\tother_game\t" t; exit }
      print "polish\t" pl "\t" (o + 0) "\t" (k + 0)
      for (i = 1; i <= n; i++) print "polish_row\t" r[i]
    }' "$PL"
else printf 'polish\tnone\t%s\n' "$PL"; fi

# ---- Stories traced to a Features item ------------------------------------------------------------
set -- production/epics/*/story-*.md
if [ -f "$1" ]; then
  awk '
    function done_() {
      if (fn == "") return
      if (req == "" || req == "other") other++
      else print "story\t" req "\t" (st == "" ? "-" : st) "\t" fn
    }
    FNR == 1 { done_(); fn = FILENAME; st = ""; req = "" }
    {
      l = $0; sub(/\r$/, "", l); sub(/^[ \t]+/, "", l); sub(/^> /, "", l); sub(/^- /, "", l); gsub(/\*/, "", l)
      if (st == "" && l ~ /^Status:/) { st = substr(l, 8); sub(/^[ \t]+/, "", st); sub(/[ \t]+$/, "", st) }
      if (req == "" && l ~ /^Requirement:/) {
        if (match(l, /Brief MVP feature [0-9]+/)) req = substr(l, RSTART + 18, RLENGTH - 18)
        else req = (index(l, "Brief Out of scope:") ? "cut" : "other")
      }
    }
    END { done_(); if (other) print "stories_other\t" other }' "$@"
fi
exit 0
