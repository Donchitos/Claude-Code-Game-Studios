#!/usr/bin/env bash
# cut-apply.sh — write what the person picked on /cut's screen: cut Features items into Out of
# scope, bring marks up to date, write the brief's Dates line, keep the polish list, and set a
# cut item's story Status. It writes only what it is given: which items to cut, and why, is the
# person's pick through /cut. Everything is checked before anything is written.
#
# Moving an item renumbers the Features after it, and /create-stories traces a story to its item
# by number ("Brief MVP feature N"), so the stories after it are renumbered with it; a cut item's
# story points at its Out of scope row instead ("Brief Out of scope: <item>").
#
# Usage: bash .claude/scripts/cut-apply.sh --brief PATH [--brief PATH] [what to write]...
#   --brief PATH       a brief to write: cut-read.sh's brief rows (design/game-brief.md, and the
#                      game's folder copy while it is the same text). Two get the same edits
#   --cut N REASON     Features item N (cut-read.sh's numbers) leaves for the end of Out of scope
#                      as "- [-] <item> · cut: REASON (<today>)", plus " · was built" when it was
#                      [x]; its story's Status becomes "Blocked — BLOCKED: cut by /cut <today>: REASON"
#   --mark N           Features item N becomes [x]
#   --back ITEM built|not_yet   ITEM's [-] row goes back to the end of Features, [x] when built;
#                      its story points at it again and goes back to Ready
#   --dates TARGET FREEZE WHAT  the brief's line "**Dates:** target TARGET (WHAT) · freeze FREEZE":
#                      ISO dates, the freeze before the target, the target after today
#   --polish ROW       a row "- [ ] ROW" in design/polish-list.md; ROW ends " · from: <source>"
#   --tick ROW         the row ROW is ticked
#   --drop ROW         the row ROW is taken out
#   --today DATE       the date the rows carry; default today
#   --root DIR         the project; defaults to the repo this script is in
#   -h, --help         this text
#
# Output: TSV, then a wrote row per file changed.
#   cut       <n> <item>
#   marked    <n> <item>
#   back      <n> <item>                 its number in Features now
#   dates     <the line written>
#   story     blocked|moved|renumbered|back <path> <detail>   moved: a cut item's Complete story,
#                                        which keeps its status
#   polish    added|same|ticked|dropped <row>
#   polish    other_game <its title>     the polish list is another game's: nothing written (exit 4)
#   wrote     <path>
#   bad       <why>                      nothing is written (exit 2)
#
# Exit codes: 0 written, or nothing to change; 2 usage error or a bad row; 4 the polish list is
# another game's.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
TAB=$(printf '\t'); NL='
'
B1=""; B2=""; TODAY=""; ROOT_ARG=""
TMP=$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/cut-apply-$$")
mkdir -p "$TMP" && trap 'rm -rf "$TMP"' EXIT
OPS="$TMP/ops"; : > "$OPS"
use() { echo "cut-apply: $1 (try --help)" >&2; exit 2; }
line() { case "$1" in *"$TAB"*|*"$NL"*|"") use "$2 takes one line of text, no tabs" ;; esac; }
num() { case "$1" in ""|*[!0-9]*) use "$2 takes an item's number: $1" ;; esac; }
while [ $# -gt 0 ]; do
  case "$1" in
    --brief) [ $# -ge 2 ] || use "--brief needs a path"
             if [ -z "$B1" ]; then B1=$2; elif [ -z "$B2" ]; then B2=$2; else use "two briefs at most"; fi; shift 2 ;;
    --cut) [ $# -ge 3 ] || use "--cut needs a number and a reason"; num "$2" --cut; line "$3" "--cut's reason"
           printf 'cut\t%s\t%s\n' "$2" "$3" >> "$OPS"; shift 3 ;;
    --mark) [ $# -ge 2 ] || use "--mark needs a number"; num "$2" --mark; printf 'mark\t%s\n' "$2" >> "$OPS"; shift 2 ;;
    --back) [ $# -ge 3 ] || use "--back needs an item and built or not_yet"; line "$2" --back
            case "$3" in built|not_yet) ;; *) use "--back takes built or not_yet: $3" ;; esac
            printf 'back\t%s\t%s\n' "$2" "$3" >> "$OPS"; shift 3 ;;
    --dates) [ $# -ge 4 ] || use "--dates needs a target, a freeze and what the target is"; line "$4" "--dates' what"
             printf 'dates\t%s\t%s\t%s\n' "$2" "$3" "$4" >> "$OPS"; shift 4 ;;
    --polish|--tick|--drop) [ $# -ge 2 ] || use "$1 needs a row"; line "$2" "$1"
             printf '%s\t%s\n' "${1#--}" "$2" >> "$OPS"; shift 2 ;;
    --today) [ $# -ge 2 ] || use "--today needs a date"; TODAY="$2"; shift 2 ;;
    --root) [ $# -ge 2 ] || use "--root needs a folder"; ROOT_ARG="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) use "unknown argument: $1" ;;
  esac
done
[ -n "$TODAY" ] || TODAY=$(date +%Y-%m-%d)
[ -n "$B1" ] || use "--brief is needed: the brief to write, which also names the game"
ROOT="$(cd "${ROOT_ARG:-$HERE/../..}" 2>/dev/null && pwd)" || use "no such folder: $ROOT_ARG"
cd "$ROOT" || exit 2
for b in "$B1" ${B2:+"$B2"}; do [ -f "$b" ] || use "no such brief: $b"; done
[ -z "$B2" ] || cmp -s "$B1" "$B2" || use "$B1 and $B2 are not the same text: give the one to write"

# Valid ISO dates, as cut-read.sh checks them.
DATES='
function dn(y, m, d,   era, yoe, doy) {
  y -= (m <= 2); era = int((y >= 0 ? y : y - 399) / 400); yoe = y - era * 400
  doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
  return era * 146097 + yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy - 719468
}
function iso(z,   era, doe, yoe, doy, mp, d, m, y) {
  z += 719468; era = int((z >= 0 ? z : z - 146096) / 146097); doe = z - era * 146097
  yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365)
  doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100)); mp = int((5 * doy + 2) / 153)
  d = doy - int((153 * mp + 2) / 5) + 1; m = mp + (mp < 10 ? 3 : -9); y = yoe + era * 400 + (m <= 2)
  return sprintf("%04d-%02d-%02d", y, m, d)
}
function ok(s) { return s ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ && iso(dn(substr(s, 1, 4) + 0, substr(s, 6, 2) + 0, substr(s, 9, 2) + 0)) == s }'
awk -v s="$TODAY" "$DATES"' BEGIN { exit !ok(s) }' || use "--today is a date, YYYY-MM-DD: $TODAY"

# ---- The brief: cuts, marks, items back, the Dates line -----------------------------------------
: > "$TMP/rows"; : > "$TMP/map"; : > "$TMP/bad"
if grep -qE '^(cut|mark|back|dates)'"$TAB" "$OPS"; then
  awk -v ops="$OPS" -v today="$TODAY" -v out="$TMP/brief" -v rows="$TMP/rows" -v map="$TMP/map" -v badf="$TMP/bad" "$DATES"'
    function bad(m) { print "bad\t" m >> badf; err = 1 }
    function clean(s) { gsub(/\t/, " ", s); sub(/[ \t]+$/, "", s); return s }
    BEGIN {
      while ((getline l < ops) > 0) {
        split(l, f, "\t")
        if (f[1] == "cut") { if ((f[2] + 0) in why) bad("item " f[2] " is cut twice"); why[f[2] + 0] = f[3]; nc++ }
        else if (f[1] == "mark") mark[f[2] + 0] = 1
        else if (f[1] == "back") { nb++; bi[nb] = f[2]; bs[nb] = f[3] }
        else if (f[1] == "dates") { dt = f[2]; df = f[3]; dw = f[4]; hasd = 1 }
      }
    }
    { if (sub(/\r$/, "")) eol = "\r"; L[++n] = $0 }
    END {
      for (i = 1; i <= n; i++) {
        l = L[i]
        if (incom) { if (index(l, "-->")) incom = 0; if (sec != "") end_[sec] = i; continue }
        if (l ~ /^## /) {
          h = l; sub(/^## +/, "", h); sec = ""
          if (h ~ /^(Features|MVP)([^A-Za-z]|$)/) sec = "f"; else if (h ~ /^Out of scope([^A-Za-z]|$)/) sec = "o"
          if (sec != "") { head[sec] = i; end_[sec] = i }
          continue
        }
        if (l ~ /^---[ \t]*$/) { sec = ""; continue }
        if (l ~ /^\*\*Dates:\*\*/) { dl = i; continue }
        if (l ~ /^[ \t]*<!--/) { if (!index(l, "-->")) incom = 1; if (sec != "") end_[sec] = i; continue }
        if (sec == "" || l ~ /^[ \t]*$/) continue
        end_[sec] = i
        if (l ~ /^[-*] \[.\][ \t]*$/ || l ~ /^[-*][ \t]*$/) { ph[i] = sec; continue }   # an empty placeholder
        if (sec == "o") {
          if (l ~ /^[-*] /) last["o"] = i
          if (l ~ /^[-*] \[-\] /) { it = substr(l, 7); p = index(it, " · cut: "); if (p) it = substr(it, 1, p - 1); ocut[clean(it)] = i }
          continue
        }
        if (l ~ /^[-*] \[-\]/) continue
        if (l ~ /^[-*] \[[xX]\] /) { mk = "x"; it = substr(l, 7) }
        else if (l ~ /^[-*] \[ \] /) { mk = " "; it = substr(l, 7) }
        else if (l ~ /^[-*] /) { mk = "u"; it = substr(l, 3) }
        else if (l ~ /^[0-9]+\. /) { mk = "u"; it = l; sub(/^[0-9]+\. +/, "", it) }
        else continue
        it = clean(it); if (it == "") { ph[i] = sec; continue }
        fn++; fl[fn] = i; fit[fn] = it; fmk[fn] = mk; last["f"] = i
      }
      for (k in why) if (k + 0 < 1 || k + 0 > fn) bad("no Features item " k ": the list has " fn)
      for (k in mark) { if (k + 0 < 1 || k + 0 > fn) bad("no Features item " k " to mark: the list has " fn); else if (k in why) bad("item " k " is both cut and marked") }
      if (nc && !("o" in head)) bad("no Out of scope section to move the cuts to")
      if (nb && !("f" in head)) bad("no Features section to bring an item back to")
      for (j = 1; j <= nb; j++) if (!(bi[j] in ocut)) bad("no cut row in Out of scope for: " bi[j])
      if (hasd) {
        if (!ok(dt) || !ok(df)) bad("--dates takes two dates, YYYY-MM-DD: " dt " " df)
        else if (df >= dt) bad("the freeze " df " is not before the target " dt)
        else if (dt <= today) bad("the target " dt " is not after today, " today)
      }
      if (err) exit 2
      # The rows to add, and each item number before and after.
      c = 0
      for (k = 1; k <= fn; k++) {
        if (k in why) {
          c++; drop[fl[k]] = 1
          cutrows = cutrows "- [-] " fit[k] " · cut: " why[k] " (" today ")" (fmk[k] == "x" ? " · was built" : "") eol "\n"
          print "cut\t" k "\t" fit[k] >> rows; print "cut\t" k "\t" fit[k] "\t" why[k] >> map
        } else {
          if (k - c != k) print "num\t" k "\t" (k - c) >> map
          if (k in mark) { print "marked\t" k "\t" fit[k] >> rows
            if (fmk[k] == " ") sub(/\[ \]/, "[x]", L[fl[k]]); else if (fmk[k] == "u") L[fl[k]] = "- [x] " fit[k] }
        }
      }
      for (j = 1; j <= nb; j++) {
        drop[ocut[bi[j]]] = 1
        backrows = backrows "- [" (bs[j] == "built" ? "x" : " ") "] " bi[j] eol "\n"
        print "back\t" (fn - c + j) "\t" bi[j] >> rows; print "back\t" bi[j] "\t" (fn - c + j) >> map
      }
      opos = ("o" in last) ? last["o"] : end_["o"]; fpos = ("f" in last) ? last["f"] : end_["f"]
      if (hasd) { dline = "**Dates:** target " dt " (" dw ") · freeze " df; print "dates\t" dline >> rows }
      for (i = 1; i <= n; i++) {
        if (i == dl && hasd) printf "%s%s\n", dline, eol > out
        else if (!(i in drop) && !(ph[i] == "o" && nc) && !(ph[i] == "f" && nb)) printf "%s%s\n", L[i], eol > out
        if (i == opos && nc) printf "%s", cutrows > out
        if (i == fpos && nb) printf "%s", backrows > out
      }
      if (hasd && !dl) { if (L[n] !~ /^[ \t]*$/) printf "%s\n", eol > out; printf "%s%s\n", dline, eol > out }
    }' "$B1"
  RC=$?
  [ "$RC" = 0 ] || [ -s "$TMP/bad" ] || { echo "cut-apply: the brief could not be read" >&2; exit 2; }
fi

# ---- The stories: a cut item's Status and Requirement, and the numbers after it ------------------
if [ -s "$TMP/map" ] && [ ! -s "$TMP/bad" ]; then
  set -- production/epics/*/story-*.md
  if [ -f "$1" ]; then
    i=0
    for s in "$@"; do
      i=$((i + 1))
      awk -v map="$TMP/map" -v today="$TODAY" -v path="$s" -v out="$TMP/story-$i" -v rows="$TMP/rows" '
        BEGIN {
          while ((getline l < map) > 0) {
            split(l, f, "\t")
            if (f[1] == "cut") { ci[f[2]] = f[3]; cw[f[2]] = f[4] } else if (f[1] == "num") nn[f[2]] = f[3]; else if (f[1] == "back") bn[f[2]] = f[3]
          }
        }
        { if (sub(/\r$/, "")) eol = "\r"; L[++n] = $0 }
        function strip(s) { sub(/^[ \t]+/, "", s); sub(/^> /, "", s); sub(/^- /, "", s); gsub(/\*/, "", s); return s }
        function status(i, v,   l, p, q, head, after, lead) {   # the value after "Status:", kept its prefix
          l = L[i]; p = index(l, "Status"); q = index(substr(l, p + 6), ":")
          head = substr(l, 1, p + 5 + q); after = substr(l, p + 6 + q); lead = after; sub(/[^* \t].*$/, "", lead)
          if (lead !~ / $/) lead = lead " "
          L[i] = head lead v
        }
        END {
          for (i = 1; i <= n; i++) {
            s = strip(L[i])
            if (!si && s ~ /^Status:/) { si = i; sv = tolower(substr(s, 8)); sub(/^[ \t]+/, "", sv) }
            if (!ri && s ~ /^Requirement:/) ri = i
          }
          if (!ri) exit
          l = L[ri]
          if (match(l, /Brief MVP feature [0-9]+/)) {
            k = substr(l, RSTART + 18, RLENGTH - 18)
            if (k in ci) {
              L[ri] = substr(l, 1, RSTART - 1) "Brief Out of scope: " ci[k] substr(l, RSTART + RLENGTH)
              if (si && sv !~ /^(complete|done)([^a-z]|$)/) {
                status(si, "Blocked — BLOCKED: cut by /cut " today ": " cw[k]); print "story\tblocked\t" path "\tfeature " k >> rows
              } else print "story\tmoved\t" path "\tfeature " k ", its status kept" >> rows
            } else if (k in nn) {
              L[ri] = substr(l, 1, RSTART - 1) "Brief MVP feature " nn[k] substr(l, RSTART + RLENGTH)
              print "story\trenumbered\t" path "\tfeature " k " -> " nn[k] >> rows
            } else exit
          } else if ((p = index(l, "Brief Out of scope: ")) > 0) {
            it = substr(l, p + 20); sub(/`.*$/, "", it); sub(/[ \t]+$/, "", it)
            if (!(it in bn)) exit
            L[ri] = substr(l, 1, p - 1) "Brief MVP feature " bn[it] substr(l, p + 20 + length(it))
            if (si && sv ~ /^blocked/) status(si, "Ready")
            print "story\tback\t" path "\tfeature " bn[it] >> rows
          } else exit
          for (i = 1; i <= n; i++) printf "%s%s\n", L[i], eol > out
        }' "$s"
      [ -f "$TMP/story-$i" ] && printf '%s\t%s\n' "$TMP/story-$i" "$s" >> "$TMP/stories"
    done
  fi
fi

# ---- The polish list ------------------------------------------------------------------------------
PL=design/polish-list.md
if grep -qE '^(polish|tick|drop)'"$TAB" "$OPS" && [ ! -s "$TMP/bad" ]; then
  TITLE=$(sed -n 's/^# Game Brief: *//p' "$B1" | head -1 | tr -d '\r')
  [ -n "$TITLE" ] || TITLE=$(basename "$(dirname "$ROOT/$B1")")
  [ -f "$PL" ] && cp "$PL" "$TMP/polish-in" || : > "$TMP/polish-in"
  awk -v ops="$OPS" -v want="$TITLE" -v today="$TODAY" -v out="$TMP/polish" -v rows="$TMP/rows" -v badf="$TMP/bad" '
    function bad(m) { print "bad\t" m >> badf; err = 1 }
    # The game by name: the title without a trailing mark such as *(guessed title)*, which belongs to the brief.
    function name(x) { sub(/[ \t]*\*\([^)]*\)\*[ \t]*$/, "", x); return x }
    { if (sub(/\r$/, "")) eol = "\r"; L[++n] = $0 }
    END {
      if (n) {
        for (i = 1; i <= n; i++) if (L[i] ~ /^# Polish list: /) { t = substr(L[i], 16); break }
        if (name(t) != name(want)) { print "polish\tother_game\t" t >> rows; exit 4 }
      } else { L[++n] = "# Polish list: " name(want); L[++n] = "<!-- /cut " today ". Tick [x] when done. Each row says where it came from. -->" }
      for (i = 1; i <= n; i++) {
        if (L[i] ~ /^<!-- \/cut [0-9-]+\. /) sub(/^<!-- \/cut [0-9-]+\./, "<!-- /cut " today ".", L[i])
        if (L[i] ~ /^- \[ \] /) op[substr(L[i], 7)] = i
        else if (L[i] ~ /^- \[[xX]\] /) tk[substr(L[i], 7)] = i
      }
      while ((getline l < ops) > 0) {
        a = substr(l, 1, index(l, "\t") - 1); r = substr(l, index(l, "\t") + 1)
        if (a == "polish") {
          if (r !~ / · from: [^ ]/) bad("a polish row ends \" · from: <source>\": " r)
          else if ((r in op) || (r in tk)) print "polish\tsame\t" r >> rows
          else { L[++n] = "- [ ] " r; op[r] = n; print "polish\tadded\t" r >> rows }
        } else if (a == "tick") {
          if (r in op) { L[op[r]] = "- [x] " r; tk[r] = op[r]; delete op[r]; print "polish\tticked\t" r >> rows }
          else if (r in tk) print "polish\tsame\t" r >> rows
          else bad("no polish row to tick: " r)
        } else if (a == "drop") {
          if (r in op) { gone[op[r]] = 1; delete op[r] } else if (r in tk) { gone[tk[r]] = 1; delete tk[r] }
          else { bad("no polish row to drop: " r); continue }
          print "polish\tdropped\t" r >> rows
        }
      }
      if (err) exit 2
      for (i = 1; i <= n; i++) if (!(i in gone)) printf "%s%s\n", L[i], eol > out
    }' "$TMP/polish-in"
  RC=$?
  if [ "$RC" = 4 ]; then cat "$TMP/rows"; exit 4; fi
fi

# ---- Write, only when every check passed ----------------------------------------------------------
if [ -s "$TMP/bad" ]; then cat "$TMP/bad"; exit 2; fi
cat "$TMP/rows"
put() { # put <new> <path>: the path takes the new text when it differs
  [ -f "$1" ] || return 0
  if [ ! -f "$2" ] || ! cmp -s "$1" "$2"; then
    mkdir -p "$(dirname "$2")" && cp "$1" "$2" && printf 'wrote\t%s\n' "$2" || { echo "cut-apply: could not write $2" >&2; exit 1; }
  fi
}
for b in "$B1" ${B2:+"$B2"}; do put "$TMP/brief" "$b"; done
[ -f "$TMP/stories" ] && while IFS="$TAB" read -r t s; do put "$t" "$s"; done < "$TMP/stories"
put "$TMP/polish" "$PL"
exit 0
