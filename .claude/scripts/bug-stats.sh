#!/usr/bin/env bash
# bug-stats.sh — bug counts by severity, status and system, with each bug's
# age, read from the bug files /bug-report writes, so a skill reads one table
# instead of grepping every BUG file for its Severity and Status lines.
#
# Replaces the hand-run bug counts in /release-checklist, /milestone-review,
# /bug-triage, /team-qa, /day-one-patch, /regression-suite and /team-release,
# and the session-start note's open-bug count.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# Whether an open S2 fails a gate, which statuses a skill treats as open, and
# when a bug is "old" stay in the skill: every status is counted as written,
# so a skill with a different rule can still apply it.
#
# Usage: bash .claude/scripts/bug-stats.sh [--root DIR] [--today YYYY-MM-DD] [DIR ...]
#   DIR         folders to search for bug files at any depth, relative to the
#               root or absolute; default production/qa/bugs/, one level
#               (where /bug-report writes)
#   --today D   the date ages count to (default: today); fixes reruns and tests
#   --root DIR  the project; defaults to the repo this script is in
#   -h, --help  this text
#
# A bug file is BUG-<number>.md, the name /bug-report gives it (bug-0003.md,
# in any case, too): a /bug-triage report (bug-triage-<date>.md) or other
# notes named bug-*.md are not bugs. A file found twice, through folders that
# overlap (including relative and absolute aliases), is read once; an empty
# one is a bug with no fields, so it is open.
#
# What it reads from each file (the header block /bug-report writes):
#   ID, Title, Severity, Priority, Status, Reported and System, as `**Field**:`
#   lines (`- **System**:` too). The FIRST Status line is the bug's status: a
#   Fix Record or Closure Record further down adds its own Status line, and the
#   header is the one /bug-report and /hotfix keep current.
#   Severity is the first S1-S4 in its value, whatever the spelling (S1-Critical,
#   S1 — Critical, S1 (Critical)); priority the first P1-P4. A value still in
#   the template's [brackets] is no severity (open_unrated).
#
# Output: TSV. Counts first:
#   bugs <n> <scope>
#   open <n> <rule>        open = a status other than Closed or Verified Fixed
#                          (/release-checklist's and /team-qa's rule; a bug
#                          with no Status line is open)
#   closed <n>
#   open_s1 .. open_s4 <n>, open_unrated <n> (open, with no S1-S4)
#   status <value as written> <n>     one row per status value, sorted
#   system <system> <open> <open S1/S2>   open bugs per system, most first
#   oldest_open <id> <days>           the open bug reported longest ago
#   BUG <id> <path> <severity> <priority> <state> <status> <reported> <age_days> <system> <title>
# `-` means not there; state is OPEN or CLOSED; age_days is whole days from
# Reported (the first YYYY-MM-DD in it) to --today.
#
# Exit codes: 0 read every bug file found (none is fine: bugs 0); 1 the root
# cannot be read; 2 usage error (a bad --today, an unknown flag). Reads only;
# never writes, never prompts.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
# Byte semantics for awk, sort and tolower.
LC_ALL=C
export LC_ALL

ROOT_ARG=""; TODAY=""; DIRS=""
NL='
'
while [ $# -gt 0 ]; do
  case "$1" in
    --today)
      [ $# -ge 2 ] || { echo "bug-stats: --today needs a date" >&2; exit 2; }
      TODAY="$2"; shift 2 ;;
    --today=*) TODAY="${1#--today=}"; shift ;;
    --root)
      [ $# -ge 2 ] || { echo "bug-stats: --root needs a value" >&2; exit 2; }
      ROOT_ARG="$2"; shift 2 ;;
    --root=*) ROOT_ARG="${1#--root=}"; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) echo "bug-stats: unknown argument: $1 (try --help)" >&2; exit 2 ;;
    *) DIRS="$DIRS$1$NL"; shift ;;
  esac
done
[ -n "$TODAY" ] || TODAY=$(date +%Y-%m-%d)
case "$TODAY" in
  [0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]) ;;
  *) echo "bug-stats: --today must be YYYY-MM-DD, got $TODAY" >&2; exit 2 ;;
esac

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "bug-stats: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$(dirname "$0")/../.." 2>/dev/null || { echo "bug-stats: cannot reach the repo root" >&2; exit 1; }
fi
PROJECT_ROOT=$(pwd -P)

# BUG-<number>.md: -iname keeps a lowercase bug-0003.md, the digit keeps out
# bug-triage-<date>.md.
if [ -z "$DIRS" ]; then
  SCOPE="production/qa/bugs/BUG-*.md"
  LIST=$(find production/qa/bugs -maxdepth 1 -type f -iname 'bug-[0-9]*.md' 2>/dev/null | sort)
else
  SCOPE=$(printf '%s' "$DIRS" | awk 'NF' | tr '\n' ',' | sed 's/,$//')
  LIST=""
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    # A Windows path's backslashes as slashes, so its file names read alike.
    case "$d" in [A-Za-z]:\\*) d=$(printf '%s' "$d" | sed 's|\\|/|g') ;; esac
    # Resolve directory aliases before find: production, an absolute path to
    # it, and production/qa/.. must give the same spelling to each bug file.
    d=$(cd "$d" 2>/dev/null && pwd -P) || continue
    case "$d" in
      "$PROJECT_ROOT") d=. ;;
      "$PROJECT_ROOT"/*) d=./${d#"$PROJECT_ROOT"/} ;;
    esac
    LIST="$LIST$(find "$d" -type f -iname 'bug-[0-9]*.md' 2>/dev/null)$NL"
  done <<EOF
$DIRS
EOF
  # ./ dropped before the de-duplication, so ./production and production
  # name each file once.
  LIST=$(printf '%s' "$LIST" | awk 'NF { sub(/^\.\//, ""); print }' | sort -u)
fi

# The file list goes to awk on stdin, never as arguments: thousands of paths
# would pass the command-line limit of some systems. Each becomes an input
# file, "./" in front of a relative one so a name like x=1.md is not read as an
# assignment; an absolute one (/..., C:/...) is opened as it is.
printf '%s\n' "$LIST" | awk 'NF { sub(/^\.\//, ""); print }' | \
TODAY="$TODAY" SCOPE="$SCOPE" awk '
  BEGIN {
    BINMODE = 3; split(ENVIRON["TODAY"], t, "-"); today = days(t[1] + 0, t[2] + 0, t[3] + 0)
    # The list arrives on /dev/stdin, named, so the main input stays the files: with
    # a bare getline, gawk read the first file as more of stdin and skipped its FNR 1.
    while ((getline f < "/dev/stdin") > 0) lst[++nlst] = f
    for (i = 1; i <= nlst; i++) ARGV[ARGC++] = (lst[i] ~ /^(\/|[A-Za-z]:)/) ? lst[i] : "./" lst[i]
    na = 1
  }
  # Days since a fixed origin for the Gregorian date y-m-d. Only differences
  # are used, so the origin does not matter. The year is counted from March,
  # so a leap day falls at the end of it and the month term needs no table.
  function days(y, m, d) {
    if (m <= 2) { y--; m += 12 }
    return 365 * y + int(y / 4) - int(y / 100) + int(y / 400) + int((153 * (m - 3) + 2) / 5) + d
  }
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
  function clean(s) { gsub(/\t/, " ", s); s = trim(s); return (s == "") ? "-" : s }
  # The value of field `name` on line s (`**Name**:`, `- **Name**:`, `Name:`),
  # or "\001" when s is not that field. The same normalisation as story-status.sh.
  function fval(s, name,    u) {
    u = s; sub(/^[ \t]+/, "", u); sub(/^> /, "", u); sub(/^- /, "", u); gsub(/\*/, "", u)
    if (tolower(substr(u, 1, length(name) + 1)) != tolower(name) ":") return "\001"
    return trim(substr(u, length(name) + 2))
  }
  function flush(    sev, pri, closed, age, d, s, k) {
    if (path == "") return
    # A value still in the template [brackets] lists every level, so it has none.
    sev = (substr(sevv, 1, 1) != "[" && match(sevv, /[Ss][1-4]/)) ? toupper(substr(sevv, RSTART, RLENGTH)) : "-"
    pri = (substr(priv, 1, 1) != "[" && match(priv, /[Pp][1-4]/)) ? toupper(substr(priv, RSTART, RLENGTH)) : "-"
    s = tolower(statv)
    closed = (s ~ /^closed([^a-z]|$)/ || s ~ /^verified fixed([^a-z]|$)/)
    age = "-"; d = "-"
    if (match(repv, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
      d = substr(repv, RSTART, RLENGTH); split(d, p, "-"); age = today - days(p[1] + 0, p[2] + 0, p[3] + 0)
    }
    n++; k = (statv == "") ? "-" : clean(statv); stat[k]++
    if (closed) nclosed++
    else {
      nopen++; if (sev == "-") unrated++; else opensev[sev]++
      sy = clean(sysv); sys_open[sy]++; if (sev == "S1" || sev == "S2") sys_hi[sy]++
      if (age != "-" && (oldest == "" || age > oldest_age)) { oldest = idv; oldest_age = age }
    }
    rows[n] = "BUG\t" idv "\t" path "\t" sev "\t" pri "\t" (closed ? "CLOSED" : "OPEN") "\t" k "\t" d "\t" age "\t" clean(sysv) "\t" clean(titlev)
    path = ""
  }
  function begin(f) {
    flush(); path = f; sub(/^\.\//, "", path); infence = 0
    idv = path; sub(/^.*\//, "", idv); sub(/\.md$/, "", idv)
    seen_id = seen_sev = seen_pri = seen_stat = seen_rep = seen_sys = seen_title = 0
    sevv = priv = statv = repv = sysv = titlev = ""
  }
  # An empty file has no line, so no FNR 1: every listed file awk passed over
  # before f (all of them, for f "") is one, and is still a bug.
  function reach(f) {
    while (na < ARGC && ARGV[na] != f) { begin(ARGV[na]); flush(); na++ }
    if (na < ARGC) na++
  }
  FNR == 1 { reach(FILENAME); begin(FILENAME) }
  {
    line = $0; sub(/\r$/, "", line)
    if (line ~ /^[ \t]*(```|~~~)/) { infence = !infence; next }
    if (infence) next
    if (!seen_id && (v = fval(line, "ID")) != "\001") { seen_id = 1; if (v ~ /^[A-Za-z]+-[0-9]+/) { match(v, /^[A-Za-z]+-[0-9]+/); idv = toupper(substr(v, 1, RLENGTH)) } }
    if (!seen_title && (v = fval(line, "Title")) != "\001") { seen_title = 1; titlev = v }
    if (!seen_sev && (v = fval(line, "Severity")) != "\001") { seen_sev = 1; sevv = v }
    if (!seen_pri && (v = fval(line, "Priority")) != "\001") { seen_pri = 1; priv = v }
    if (!seen_stat && (v = fval(line, "Status")) != "\001") { seen_stat = 1; statv = v }
    if (!seen_rep && (v = fval(line, "Reported")) != "\001") { seen_rep = 1; repv = v }
    if (!seen_sys && (v = fval(line, "System")) != "\001") { seen_sys = 1; sysv = v }
  }
  END {
    flush(); reach("")
    printf "bugs\t%d\t%s\n", n, ENVIRON["SCOPE"]
    printf "open\t%d\tstatus other than Closed or Verified Fixed\n", nopen
    printf "closed\t%d\n", nclosed
    for (i = 1; i <= 4; i++) printf "open_s%d\t%d\n", i, opensev["S" i] + 0
    printf "open_unrated\t%d\n", unrated
    # Status rows sorted by value; system rows by open count, then name.
    ns = 0; for (k in stat) keys[++ns] = k
    for (i = 2; i <= ns; i++) { v = keys[i]; for (j = i - 1; j >= 1 && keys[j] > v; j--) keys[j + 1] = keys[j]; keys[j + 1] = v }
    for (i = 1; i <= ns; i++) printf "status\t%s\t%d\n", keys[i], stat[keys[i]]
    nn = 0; for (k in sys_open) sk[++nn] = k
    for (i = 2; i <= nn; i++) {
      v = sk[i]
      for (j = i - 1; j >= 1 && (sys_open[sk[j]] < sys_open[v] || (sys_open[sk[j]] == sys_open[v] && sk[j] > v)); j--) sk[j + 1] = sk[j]
      sk[j + 1] = v
    }
    for (i = 1; i <= nn; i++) printf "system\t%s\t%d\t%d\n", sk[i], sys_open[sk[i]], sys_hi[sk[i]] + 0
    if (oldest != "") printf "oldest_open\t%s\t%d\n", oldest, oldest_age
    else printf "oldest_open\t-\t-\n"
    for (i = 1; i <= n; i++) print rows[i]
  }
'
