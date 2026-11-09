#!/usr/bin/env bash
# story-facts.sh — the facts skills read off story files by hand, one row per
# story, and with --lint the story-readiness rules each story trips.
#
# Replaces the hand-run story reads in /story-readiness, /story-done and
# /dev-story. story-status.sh still prints the route order /next-step and
# /sprint-status inject; the status column here applies its rule word for
# word, so the two never disagree.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# A LINT row is a rule that matched, with the numbers that made it match;
# READY, NEEDS WORK or BLOCKED is still the skill's to say.
#
# Usage: bash .claude/scripts/story-facts.sh [--root DIR] [--all | --sprint | PATH ...] [--lint]
#                                          [--granularity coarse|balanced|fine]
#   --all       every production/epics/**/story-*.md (the default)
#   --sprint    the stories production/sprint-status.yaml lists in its file:
#               entries, the only place a sprint names story paths
#   PATH ...    these story files, relative to the root
#   --lint      also print the rules each story trips
#   --granularity  the AC minimums --lint applies (below); default coarse
#   --root DIR  the project; defaults to the repo this script is in
#   -h, --help  this text
#
# Output: TSV. Counts first (stories <n> <scope>, then one count per state, and
# lint <n> with --lint), then
#   STORY <path> <state> <status> <type> <layer> <estimate> <tr_ids> <adrs>
#         <ac> <qa_cases> <test_evidence> <depends_on> <sprint_status>
#   LINT <path> <rule> <detail>
#   NOT_FOUND <path>            a PATH or a sprint file: entry that is not a file
# Columns (`-` means not there; UNFILLED means still the template's [bracket]):
#   state         story-status.sh's grouping of the first `Status:` line:
#                 COMPLETE, IN_REVIEW, IN_PROGRESS, TODO (Ready or Not Started),
#                 BLOCKED, OTHER or NO_STATUS
#   status        that line's value as written
#   type, layer, estimate   the header fields (`> **Type**: Logic` and the
#                 other forms story-status.sh reads)
#   tr_ids        every TR-<system>-<number> in the file, comma-separated
#   adrs          the ADR ids on the governing-ADR line (`ADR Governing
#                 Implementation`, `Governing ADRs`, `ADR`), or n/a
#   ac            `- [ ]` and `- [x]` items under `## Acceptance Criteria`
#   qa_cases      `- **AC-N**` items under `## QA Test Cases`
#   test_evidence the `Status:` line under `## Test Evidence`
#   depends_on    the `Depends on:` line under `## Dependencies`
#   sprint_status the story's status in sprint-status.yaml (--sprint only)
# LINT rules (from /story-readiness):
#   no_status, type_missing, type_unknown <value>, unfilled <field>,
#   no_tr_id, no_ac_section, ac_below_min <count> < <minimum> (<type>),
#   marker <TBD|TODO|UNRESOLVED> line <n>
#   The AC minimums by type are story-readiness's, and follow
#   --granularity (story_granularity, the AC load /create-stories writes to):
#     coarse (the default)  Logic 3, Integration 3, Visual/Feel 2, UI 2, Config/Data 1
#     balanced              Logic 2, Integration 2, Visual/Feel 2, UI 2, Config/Data 1
#     fine                  1 for every type
#   A marker counts as a whole word in capitals, outside code fences and HTML
#   comments. A <!-- inside a code span (`<!--`) opens no comment.
#
# Exit codes: 0 every story asked for was read; 1 the root cannot be read;
# 2 usage error; 3 --sprint with no sprint-status.yaml, or a PATH or file:
# entry that is not a file (its NOT_FOUND row is printed, the rest are still
# reported). Reads only; never writes, never prompts.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
# Byte semantics for awk, sort and tolower.
LC_ALL=C
export LC_ALL

SCOPE="all"; LINT=0; ROOT_ARG=""; PATHS=""; GRAN="coarse"
NL='
'
while [ $# -gt 0 ]; do
  case "$1" in
    --all) SCOPE="all"; shift ;;
    --sprint) SCOPE="sprint"; shift ;;
    --lint) LINT=1; shift ;;
    --root)
      [ $# -ge 2 ] || { echo "story-facts: --root needs a value" >&2; exit 2; }
      ROOT_ARG="$2"; shift 2 ;;
    --root=*) ROOT_ARG="${1#--root=}"; shift ;;
    --granularity)
      [ $# -ge 2 ] || { echo "story-facts: --granularity needs a value" >&2; exit 2; }
      GRAN="$2"; shift 2 ;;
    --granularity=*) GRAN="${1#--granularity=}"; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) echo "story-facts: unknown argument: $1 (try --help)" >&2; exit 2 ;;
    *) PATHS="$PATHS$1$NL"; SCOPE="paths"; shift ;;
  esac
done
case "$GRAN" in
  coarse|balanced|fine) ;;
  *) echo "story-facts: --granularity takes coarse, balanced or fine, not: $GRAN" >&2; exit 2 ;;
esac

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "story-facts: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$(dirname "$0")/../.." 2>/dev/null || { echo "story-facts: cannot reach the repo root" >&2; exit 1; }
fi

YAML="production/sprint-status.yaml"
SPRINT=""     # "path<TAB>status" per story, from the yaml
case "$SCOPE" in
  all) LIST=$(find production/epics -type f -name 'story-*.md' 2>/dev/null | sort) ;;
  sprint)
    [ -f "$YAML" ] || { echo "story-facts: no $YAML; --sprint has no story paths to read (try --all)" >&2; exit 3; }
    # Each `- ` entry under stories: gives one story; its file: and status:
    # values, quotes and trailing comments removed.
    SPRINT=$(Q="'" awk '
      # A value: quoted (to its closing quote) or bare (to a " #" comment).
      function val(s,    c, e) {
        sub(/^[^:]*:[ \t]*/, "", s); c = substr(s, 1, 1)
        if (c == "\"" || c == ENVIRON["Q"]) { e = index(substr(s, 2), c); return (e > 0) ? substr(s, 2, e - 1) : substr(s, 2) }
        sub(/[ \t]+#.*$/, "", s); sub(/[ \t]+$/, "", s); return s
      }
      { sub(/\r$/, "") }
      /^stories:/ { in_s = 1; next }
      /^[^ \t#-]/ { if (in_s) { emit(); in_s = 0 } }
      function emit() { if (f != "") printf "%s\t%s\n", f, (st == "" ? "-" : st); f = ""; st = "" }
      in_s && /^[ \t]*- / { emit() }
      in_s && /^[ \t]*(- )?file:/ { f = val($0) }
      in_s && /^[ \t]*(- )?status:/ { st = val($0) }
      END { if (in_s) emit() }
    ' "$YAML")
    LIST=$(printf '%s\n' "$SPRINT" | cut -f1 | awk 'NF') ;;
  paths) LIST=$(printf '%s' "$PATHS" | awk 'NF') ;;
esac

FILES=""; MISSED=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  f="${f#./}"
  if [ -f "$f" ]; then FILES="$FILES$f$NL"; else MISSED="$MISSED$f$NL"; fi
done <<EOF
$LIST
EOF


SCOPE_LABEL="$SCOPE"
[ "$SCOPE" = all ] && SCOPE_LABEL="production/epics/**/story-*.md"
[ "$SCOPE" = sprint ] && SCOPE_LABEL="$YAML"

# The file list goes to awk on stdin, never as arguments: thousands of paths
# would pass the command-line limit of some systems. Each becomes an input
# file, "./" in front so a name like x=1.md is not read as an assignment.
printf '%s' "$FILES" | awk 'NF { sub(/^\.\//, ""); print }' | \
LINT="$LINT" GRAN="$GRAN" SPRINT="$SPRINT" SCOPE_LABEL="$SCOPE_LABEL" awk '
  BEGIN {
    BINMODE = 3   # Git for Windows gawk reads in text mode otherwise; harmless elsewhere
    # The list arrives on /dev/stdin, named, so the main input stays the files: with
    # a bare getline, gawk read the first file as more of stdin and skipped its FNR 1.
    while ((getline f < "/dev/stdin") > 0) lst[++nlst] = f
    for (i = 1; i <= nlst; i++) ARGV[ARGC++] = "./" lst[i]
    lint = (ENVIRON["LINT"] == "1")
    n = split(ENVIRON["SPRINT"], sl, "\n")
    for (i = 1; i <= n; i++) if (sl[i] != "") { split(sl[i], kv, "\t"); k = kv[1]; sub(/^\.\//, "", k); ystat[k] = kv[2] }
    # The header fields read as columns or checked for an unfilled [bracket].
    nfl = split("Type,Layer,Estimate,Epic,Manifest Version", fl, ",")
    # story-readiness: the fewest acceptance criteria each story type needs, at
    # the granularity the stories were written to (/create-stories writes 5-10
    # ACs a story at coarse, 2-4 at balanced, 1 at fine).
    acmin["logic"] = 3; acmin["integration"] = 3; acmin["visual/feel"] = 2; acmin["ui"] = 2; acmin["config/data"] = 1
    if (ENVIRON["GRAN"] == "balanced") { acmin["logic"] = 2; acmin["integration"] = 2 }
    if (ENVIRON["GRAN"] == "fine") for (k in acmin) acmin[k] = 1
    ntypes = split("Logic Integration Visual/Feel UI Config/Data", tnames, " ")
  }
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
  function clean(s) { gsub(/\t/, " ", s); s = trim(s); return (s == "") ? "-" : s }
  # story-status.sh normalisation: trim, one "> " and one "- " off, every * out.
  function fnorm(s) { sub(/^[ \t]+/, "", s); sub(/^> /, "", s); sub(/^- /, "", s); gsub(/\*/, "", s); return s }
  function fval(s, name,    t) {     # value of field `name` on line s, or "\001" when it is not that field
    t = fnorm(s)
    if (tolower(substr(t, 1, length(name) + 1)) != tolower(name) ":") return "\001"
    return trim(substr(t, length(name) + 2))
  }
  function bracketed(v) { return substr(v, 1, 1) == "[" }
  # Where a code span that opens with the k backticks ending just before t
  # closes: the index in t of a run of exactly k backticks, or 0 when none
  # does on this line (the opening run is then plain text).
  function span_end(t, k,    i, j) {
    i = 1
    while (i <= length(t)) {
      if (substr(t, i, 1) != "`") { i++; continue }
      j = i; while (substr(t, j, 1) == "`") j++
      if (j - i == k) return i
      i = j
    }
    return 0
  }
  function fence_of(s,    n, c, k) {
    n = 0; while (n < 3 && substr(s, n + 1, 1) == " ") n++
    s = substr(s, n + 1); c = substr(s, 1, 1)
    if (c != "`" && c != "~") return ""
    k = 0; while (substr(s, k + 1, 1) == c) k++
    return (k >= 3) ? substr(s, 1, k) : ""
  }
  function closes(s, f,    n, c, k) {
    n = 0; while (n < 3 && substr(s, n + 1, 1) == " ") n++
    s = substr(s, n + 1); c = substr(f, 1, 1)
    k = 0; while (substr(s, k + 1, 1) == c) k++
    return k >= length(f) && trim(substr(s, k + 1)) == ""
  }
  function add_ids(list, s, pat,    id) {
    while (match(s, pat)) {
      id = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
      if (index("," list ",", "," id ",") == 0) list = list (list == "" ? "" : ",") id
    }
    return list
  }
  function lintrow(rule, detail) { nl++; lrows[nl] = "LINT\t" path "\t" rule "\t" detail }

  function flush(    s, state, t, tl, i, known, m) {
    if (path == "") return
    s = tolower(status)
    if (!has_status) state = "NO_STATUS"
    else if (s ~ /^(complete|done)([^a-z]|$)/) state = "COMPLETE"
    else if (s ~ /^in progress([^a-z]|$)/) state = "IN_PROGRESS"
    else if (s ~ /^in review([^a-z]|$)/) state = "IN_REVIEW"
    else if (s ~ /^(ready|not started)([^a-z]|$)/) state = "TODO"
    else if (s ~ /^blocked([^a-z]|$)/) state = "BLOCKED"
    else state = "OTHER"
    cnt[state]++
    t = (type == "") ? "-" : (bracketed(type) ? "UNFILLED" : type)
    adrv = "-"
    if (adr_line != "") { adrv = add_ids("", tolower(adr_line), "adr-[0-9]+"); if (adrv == "") adrv = (tolower(adr_line) ~ /n\/a/) ? "n/a" : (bracketed(adr_line) ? "UNFILLED" : "-") }
    nst++
    rows[nst] = "STORY\t" path "\t" state "\t" clean(status) "\t" t "\t" clean(bracketed(layer) ? "UNFILLED" : layer) "\t" \
      clean(bracketed(estimate) ? "UNFILLED" : estimate) "\t" (trs == "" ? "-" : trs) "\t" adrv "\t" \
      (has_ac ? ac : "-") "\t" (has_qa ? qa : "-") "\t" clean(te) "\t" clean(dep) "\t" ((path in ystat) ? ystat[path] : "-")
    if (lint) {
      if (!has_status) lintrow("no_status", "-")
      if (type == "") lintrow("type_missing", "-")
      else if (!bracketed(type)) {
        known = ""; tl = tolower(type)
        for (i = 1; i <= ntypes; i++) if (tl == tolower(tnames[i])) known = tl
        if (known == "") lintrow("type_unknown", clean(type))
        else if (has_ac && ac < acmin[known]) lintrow("ac_below_min", ac " < " acmin[known] " (" type ")")
      }
      for (i = 1; i <= nunf; i++) lintrow("unfilled", unf[i])
      if (trs == "") lintrow("no_tr_id", "-")
      if (!has_ac) lintrow("no_ac_section", "-")
      for (m = 1; m <= nmark; m++) lintrow("marker", marks[m])
    }
    path = ""
  }

  FNR == 1 {
    flush()
    path = substr(FILENAME, 3); infence = ""; incomment = 0; sec = ""
    status = ""; has_status = 0; type = ""; layer = ""; estimate = ""; trs = ""; adr_line = ""
    ac = 0; has_ac = 0; qa = 0; has_qa = 0; te = ""; dep = ""; nunf = 0; nmark = 0
    split("", seenf)
  }
  {
    line = $0; sub(/\r$/, "", line)
    # The Status line exactly as story-status.sh finds it: the first anywhere.
    if (!has_status) { v = fval(line, "Status"); if (v != "\001" && substr(fnorm(line), 1, 7) == "Status:") { status = v; has_status = 1 } }
    if (infence) { if (closes(line, infence)) infence = ""; next }
    f = fence_of(line); if (f != "") { infence = f; next }
    # What is left of the line outside HTML comments. A <!-- inside a code
    # span (`<!--`) is text: a span is a run of backticks closed by a run as
    # long on the same line.
    cstart = incomment; rest = ""; s = line
    while (s != "") {
      if (incomment) { p = index(s, "-->"); if (p == 0) { s = ""; break } s = substr(s, p + 3); incomment = 0; continue }
      p = index(s, "<!--"); bq = index(s, "`")
      if (bq > 0 && (p == 0 || bq < p)) {
        bk = 0; while (substr(s, bq + bk, 1) == "`") bk++
        be = span_end(substr(s, bq + bk), bk)
        bn = (be > 0) ? bq + bk + be - 1 + bk : bq + bk
        rest = rest substr(s, 1, bn - 1); s = substr(s, bn)
        continue
      }
      if (p == 0) { rest = rest s; s = ""; break }
      rest = rest substr(s, 1, p - 1); s = substr(s, p + 4); incomment = 1
    }
    if (!cstart && line ~ /^ ? ? ?#+[ \t]/) {
      h = line; sub(/^ */, "", h); k = 0; while (substr(h, k + 1, 1) == "#") k++
      if (k <= 6) { if (k <= 2) { t = tolower(substr(h, k + 1)); gsub(/^[ \t]+|[ \t#]+$/, "", t); sec = (k == 2) ? t : "" } ; next }
    }
    r = trim(rest)
    if (r == "") next
    # Header fields: the first line of each, anywhere outside fences.
    for (i = 1; i <= nfl; i++) {
      nm = fl[i]
      if (!(nm in seenf) && (v = fval(r, nm)) != "\001") {
        seenf[nm] = 1
        if (nm == "Type") type = v; else if (nm == "Layer") layer = v; else if (nm == "Estimate") estimate = v
        if (bracketed(v)) unf[++nunf] = nm
      }
    }
    if (adr_line == "") {
      if ((v = fval(r, "ADR Governing Implementation")) != "\001" || (v = fval(r, "Governing ADRs")) != "\001" || (v = fval(r, "ADR")) != "\001") adr_line = (v == "") ? "-" : v
    }
    trs = add_ids(trs, r, "TR-[A-Za-z0-9][A-Za-z0-9-]*-[0-9]+")
    if (sec == "acceptance criteria") { has_ac = 1; if (r ~ /^[-*] \[[ xX]\]/) ac++ }
    if (sec == "qa test cases") { has_qa = 1; if (r ~ /^[-*] \*\*AC-[0-9]+\*\*/) qa++ }
    if (sec == "test evidence" && te == "" && (v = fval(r, "Status")) != "\001") te = v
    if (sec == "dependencies" && dep == "" && (v = fval(r, "Depends on")) != "\001") dep = v
    # TBD, TODO and UNRESOLVED as whole words in capitals.
    s = " " r " "
    while (match(s, /[^A-Za-z0-9_](TBD|TODO|UNRESOLVED)[^A-Za-z0-9_]/)) {
      marks[++nmark] = substr(s, RSTART + 1, RLENGTH - 2) " line " FNR
      s = substr(s, RSTART + RLENGTH - 1)
    }
  }
  END {
    flush()
    printf "stories\t%d\t%s\n", nst, ENVIRON["SCOPE_LABEL"]
    split("COMPLETE IN_REVIEW IN_PROGRESS TODO BLOCKED OTHER NO_STATUS", st, " ")
    for (i = 1; i <= 7; i++) printf "%s\t%d\n", tolower(st[i]), cnt[st[i]] + 0
    if (lint) printf "lint\t%d\n", nl
    for (i = 1; i <= nst; i++) print rows[i]
    for (i = 1; i <= nl; i++) print lrows[i]
  }
'

rc=0
while IFS= read -r m; do
  [ -n "$m" ] || continue
  printf 'NOT_FOUND\t%s\n' "$m"; rc=3
done <<EOF
$MISSED
EOF
exit $rc
