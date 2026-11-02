#!/usr/bin/env bash
# plan-math.sh — the date and percentage arithmetic planning skills do by
# hand: days between two dates, a percentage with a zero guard, the sprint file
# for a sprint number in any form, and the current sprint's progress from
# production/sprint-status.yaml.
#
# Replaces the arithmetic a sprint or milestone planning step would otherwise
# do by hand.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# `progress` prints which /sprint-status band its numbers fall in, as the
# rule row that matched; On Track, At Risk or Behind is still the skill's to
# say. Velocity is not computed: no skill defines it yet.
#
# Usage: bash .claude/scripts/plan-math.sh <command> [args] [--root DIR] [--today YYYY-MM-DD]
#   days START END          whole days from START to END (negative if END is earlier)
#   pct PART WHOLE [--places N]
#                           PART / WHOLE * 100, rounded half up to N places
#                           (default 0); a WHOLE of 0 prints - and says so
#   sprint N|latest         the production/sprints/ file for sprint N, written
#                           3, 03, 003 or sprint-3; latest is the highest number
#   progress                the current sprint, from production/sprint-status.yaml
#   --today D               the date "today" means (default: today's date)
#   --root DIR              the project; defaults to the repo this script is in
#   -h, --help              this text
# Dates are YYYY-MM-DD and must exist: a month outside 01-12 or a day past
# the month's end (2026-02-29, 2026-04-31) is a bad date. In
# sprint-status.yaml such a date reads as missing.
#
# Output: TSV.
#   days     days <n> <START>..<END>
#   pct      pct <value> <PART>/<WHOLE>
#   sprint   sprint <n> <path>
#   progress sprint, start, end, today; days_total (end - start), days_elapsed
#            (today - start), days_left (end - today); time_pct (elapsed /
#            total); stories, done, and one row per yaml status; done_pct;
#            gap (time_pct - done_pct, in points; below 0 is ahead);
#            band <name> <rule> from /sprint-status's bands with
#            scope-check's edges: On Track gap <= 10, At Risk 10 < gap <= 25,
#            Behind gap > 25; must_have and must_have_done; time_left_pct;
#            updated_days_ago (today - the yaml's updated date)
#   Percentages in progress are whole numbers, and the gap and band are taken
#   from those, so what a reader sees is what the band was decided on. A value
#   that cannot be worked out (no dates, no stories) is `-`.
#
# Exit codes: 0 done; 1 the root cannot be read; 2 usage error (a bad date or
# number, an unknown command); 3 no such sprint file, or no sprint-status.yaml
# for progress; 4 two files hold the same sprint number (both are named).
# Reads only; never writes, never prompts.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
# Byte semantics for awk and sort.
LC_ALL=C
export LC_ALL

usage() { echo "plan-math: $1 (try --help)" >&2; exit 2; }
# is_date D — YYYY-MM-DD and a real day: month 01-12, day 01 to the month's
# last (29 February only in a leap year).
is_date() {
  case "$1" in [0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]) ;; *) return 1 ;; esac
  _y=$((10#${1%%-*})); _m=${1#*-}; _m=$((10#${_m%-*})); _d=$((10#${1##*-}))
  case $_m in
    1|3|5|7|8|10|12) _n=31 ;;
    4|6|9|11) _n=30 ;;
    2) if [ $((_y % 4)) -eq 0 ] && { [ $((_y % 100)) -ne 0 ] || [ $((_y % 400)) -eq 0 ]; }; then _n=29; else _n=28; fi ;;
    *) return 1 ;;
  esac
  [ "$_d" -ge 1 ] && [ "$_d" -le "$_n" ]
}
is_num() { case "$1" in ''|*[!0-9.]*|*.*.*) return 1 ;; esac; return 0; }

CMD=""; ROOT_ARG=""; TODAY=""; PLACES=0; ARGS=""
NL='
'
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --root) [ $# -ge 2 ] || usage "--root needs a value"; ROOT_ARG="$2"; shift 2 ;;
    --root=*) ROOT_ARG="${1#--root=}"; shift ;;
    --today) [ $# -ge 2 ] || usage "--today needs a date"; TODAY="$2"; shift 2 ;;
    --today=*) TODAY="${1#--today=}"; shift ;;
    --places) [ $# -ge 2 ] || usage "--places needs a number"; PLACES="$2"; shift 2 ;;
    -?*) usage "unknown argument: $1" ;;
    *) if [ -z "$CMD" ]; then CMD="$1"; else ARGS="$ARGS$1$NL"; fi; shift ;;
  esac
done
[ -n "$TODAY" ] || TODAY=$(date +%Y-%m-%d)
is_date "$TODAY" || usage "--today must be a real YYYY-MM-DD date, got $TODAY"
case "$PLACES" in [0-9]) ;; *) usage "--places takes 0-9" ;; esac
set --
while IFS= read -r a; do [ -n "$a" ] && set -- "$@" "$a"; done <<EOF
$ARGS
EOF

# The arithmetic, shared by every command. days(): days since a fixed origin
# for the Gregorian date; only differences are used. The year is counted from
# March, so a leap day falls at its end and the month term needs no table.
# pct(): half up (away from zero), so 12.5 is 13 at 0 places (printf alone
# rounds half to even), in whole numbers: PART and WHOLE are scaled to integers
# first, so 23/40 (57.5) is 58 and not the 57 a float product gives.
AWK_LIB='
  function days(s,    p) { split(s, p, "-"); return dn(p[1] + 0, p[2] + 0, p[3] + 0) }
  function dn(y, m, d) {
    if (m <= 2) { y--; m += 12 }
    return 365 * y + int(y / 4) - int(y / 100) + int(y / 400) + int((153 * (m - 3) + 2) / 5) + d
  }
  # A real date: month 01-12, day within the month, leap years counted.
  function real_date(s,    p, n) {
    if (s !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) return 0
    split(s, p, "-"); p[1] += 0; p[2] += 0; p[3] += 0
    if (p[2] < 1 || p[2] > 12 || p[3] < 1) return 0
    n = substr("312831303130313130313031", 2 * p[2] - 1, 2) + 0
    if (p[2] == 2 && p[1] % 4 == 0 && (p[1] % 100 != 0 || p[1] % 400 == 0)) n = 29
    return p[3] <= n
  }
  # dec(s): s as the whole number DN over 10^DP ("12.5" is 125 and 1).
  function dec(s,    i, neg) {
    s = "" s; neg = (substr(s, 1, 1) == "-"); if (neg) s = substr(s, 2)
    DP = 0; i = index(s, ".")
    if (i > 0) { DP = length(s) - i; s = substr(s, 1, i - 1) substr(s, i + 1) }
    DN = s + 0; if (neg) DN = -DN
  }
  function pct(part, whole, places,    f, i, n, d, pd, neg, m, q, r, ip) {
    dec(whole); if (DN == 0) return "-"
    d = DN; dec(part); n = DN; pd = DP; dec(whole)
    f = 1; for (i = 0; i < places; i++) f *= 10
    # part / whole * 100 * f, as the fraction n / d of whole numbers.
    n = n * 100 * f; for (i = 0; i < DP; i++) n *= 10
    for (i = 0; i < pd; i++) d *= 10
    neg = ((n < 0) != (d < 0)); if (n < 0) n = -n; if (d < 0) d = -d
    # Half up: floor((2n + d) / 2d), the float quotient corrected exactly.
    m = 2 * n + d; q = int(m / (2 * d)); r = m - q * 2 * d
    if (r < 0) q--; else if (r >= 2 * d) q++
    if (places == 0) return sprintf("%s%d", (neg && q > 0) ? "-" : "", q)
    ip = int(q / f)
    return sprintf("%s%d.%0" places "d", (neg && q > 0) ? "-" : "", ip, q - ip * f)
  }
'

case "$CMD" in
  days)
    [ $# -eq 2 ] || usage "days needs START and END"
    is_date "$1" && is_date "$2" || usage "dates are real YYYY-MM-DD dates"
    awk -v a="$1" -v b="$2" "$AWK_LIB"'BEGIN { printf "days\t%d\t%s..%s\n", days(b) - days(a), a, b }'
    exit 0 ;;
  pct)
    [ $# -eq 2 ] || usage "pct needs PART and WHOLE"
    is_num "$1" && is_num "$2" || usage "PART and WHOLE are numbers"
    awk -v p="$1" -v w="$2" -v n="$PLACES" "$AWK_LIB"'BEGIN {
      v = pct(p + 0, w + 0, n + 0)
      printf "pct\t%s\t%s\n", v, (v == "-") ? "zero denominator" : p "/" w }'
    exit 0 ;;
  sprint|progress) ;;
  "") usage "no command" ;;
  *) usage "unknown command: $CMD" ;;
esac

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "plan-math: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$(dirname "$0")/../.." 2>/dev/null || { echo "plan-math: cannot reach the repo root" >&2; exit 1; }
fi

if [ "$CMD" = sprint ]; then
  [ $# -eq 1 ] || usage "sprint needs a number or latest"
  want=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]'); want="${want#sprint-}"; want="${want#sprint}"
  case "$want" in latest) ;; ''|*[!0-9]*) usage "sprint takes a number (3, 03, 003, sprint-3) or latest" ;; esac
  # Only sprint-<digits>.md is a sprint plan: retrospectives and reviews that
  # share the folder (sprint-3-retrospective.md) are not.
  LIST=$(find production/sprints -maxdepth 1 -type f -name 'sprint-[0-9]*.md' 2>/dev/null \
         | awk '{ b = $0; sub(/^.*\//, "", b) } b ~ /^sprint-[0-9]+\.md$/ { n = b; gsub(/[^0-9]/, "", n); print (n + 0) "\t" $0 }' | sort -n)
  [ -n "$LIST" ] || { echo "plan-math: no production/sprints/sprint-N.md files" >&2; exit 3; }
  if [ "$want" = latest ]; then want=$(printf '%s\n' "$LIST" | tail -1 | cut -f1); else want=$((10#$want)); fi
  HITS=$(printf '%s\n' "$LIST" | awk -F'\t' -v w="$want" '$1 == w { print $2 }')
  n=$(printf '%s' "$HITS" | awk 'NF' | wc -l | tr -d ' ')
  [ "$n" -gt 0 ] || { echo "plan-math: no sprint file for sprint $want" >&2; exit 3; }
  if [ "$n" -gt 1 ]; then
    echo "plan-math: sprint $want has $n files: $(printf '%s' "$HITS" | tr '\n' ' ')" >&2
    exit 4
  fi
  printf 'sprint\t%s\t%s\n' "$want" "${HITS#./}"
  exit 0
fi

# progress
YAML="production/sprint-status.yaml"
[ -f "$YAML" ] || { echo "plan-math: no $YAML" >&2; exit 3; }
TODAY="$TODAY" awk "$AWK_LIB"'
  BEGIN { BINMODE = 3 }
  function val(s,    c, e) {
    sub(/^[^:]*:[ \t]*/, "", s); c = substr(s, 1, 1)
    if (c == "\"" || c == "\047") { e = index(substr(s, 2), c); return (e > 0) ? substr(s, 2, e - 1) : substr(s, 2) }
    sub(/[ \t]+#.*$/, "", s); sub(/[ \t]+$/, "", s); return s
  }
  function d8(s) { return real_date(s) ? s : "" }
  { sub(/\r$/, "") }
  /^sprint:/ { sprint = val($0) } /^start:/ { start = d8(val($0)) } /^end:/ { end_ = d8(val($0)) }
  /^updated:/ { upd = d8(val($0)) }
  /^stories:/ { ins = 1; item_depth = -1; next }
  /^[^ \t#-]/ { ins = 0 }
  ins {
    match($0, /^ */); depth = RLENGTH
    item = ($0 ~ /^ *- / && (item_depth < 0 || depth == item_depth))
    if (item) {
      item_depth = depth; ns++
      match($0, /^ *- +/); field_depth = RLENGTH
      content = substr($0, field_depth + 1)
      if (content ~ /^(#|$)/ || content ~ /^([&!][^ \t]+[ \t]*)+(#.*)?$/) field_depth = -1
    }
    if (!item && field_depth < 0 && depth > item_depth && $0 !~ /^ *(#|$)/)
      field_depth = depth
    if (ns && (item || depth == field_depth)) {
      field = substr($0, (item ? field_depth : depth) + 1)
      if (field ~ /^status:/) st[ns] = val(field)
      if (field ~ /^priority:/) pr[ns] = val(field)
    }
  }
  END {
    today = ENVIRON["TODAY"]
    printf "sprint\t%s\nstart\t%s\nend\t%s\ntoday\t%s\n", (sprint == "" ? "-" : sprint), (start == "" ? "-" : start), (end_ == "" ? "-" : end_), today
    total = elapsed = left = tp = "-"
    if (start != "" && end_ != "") {
      total = days(end_) - days(start); elapsed = days(today) - days(start); left = days(end_) - days(today)
      tp = pct(elapsed, total, 0)
    }
    printf "days_total\t%s\ndays_elapsed\t%s\ndays_left\t%s\ntime_pct\t%s\n", total, elapsed, left, tp
    split("backlog ready-for-dev in-progress review done blocked", names, " ")
    for (i = 1; i <= ns; i++) { c[st[i]]++; if (pr[i] == "must-have") { mh++; if (st[i] == "done") mhd++ } }
    printf "stories\t%d\ndone\t%d\n", ns, c["done"] + 0
    for (i = 1; i <= 6; i++) printf "status\t%s\t%d\n", names[i], c[names[i]] + 0
    other = ns; for (i = 1; i <= 6; i++) other -= c[names[i]]
    printf "status\tother\t%d\n", other
    dp = pct(c["done"] + 0, ns, 0)
    printf "done_pct\t%s\n", dp
    if (tp != "-" && dp != "-") {
      gap = tp - dp; printf "gap\t%d\n", gap
      if (gap <= 10) printf "band\tOn Track\tgap <= 10\n"
      else if (gap <= 25) printf "band\tAt Risk\t10 < gap <= 25\n"
      else printf "band\tBehind\tgap > 25\n"
    } else printf "gap\t-\nband\t-\tno dates or no stories\n"
    printf "must_have\t%d\nmust_have_done\t%d\n", mh, mhd
    printf "time_left_pct\t%s\n", (tp == "-") ? "-" : 100 - tp
    printf "updated_days_ago\t%s\n", (upd == "") ? "-" : days(today) - days(upd)
  }
' "$YAML"
exit 0
