#!/usr/bin/env bash
# skill-lint.sh — the facts a static skill check reads off a skill by eye: which
# frontmatter fields are there, how many phase headings, which verdict words,
# whether it asks before writing, how it ends, whether it sets a fork context,
# and what its argument hint says. Checks 1-7 of /skill-test static.
#
# Replaces the by-hand reading of checks 1-7 over a skill's SKILL.md and its
# references/, the counting that goes wrong across 75 skills.
#
# OBSERVATIONS, NEVER VERDICTS (CLAUDE.md, "Helpers in .claude/scripts/"). It
# prints what it found, check by check, and nothing here is a PASS, WARN or
# FAIL: whether three phase headings are enough, whether `HIGH` in a skill is a
# severity or a word, whether a hint matches its modes, and the one verdict the
# skill reports (COMPLIANT, WARNINGS, NON-COMPLIANT, NOT ASSESSED) stay with
# /skill-test. The rows hold the numbers and words those calls need.
#
# Usage: bash .claude/scripts/skill-lint.sh <name>|all [--root DIR]
#   <name>      one skill, the folder name under .claude/skills/
#   all         every folder under .claude/skills/ that holds a SKILL.md
#   --root DIR  the project; defaults to the repo this script is in
#   -h, --help  this text
#
# Output: TSV. First `skills <n> .claude/skills`, then for each skill
#   skill   <name>  files=<SKILL.md + references read>  lines=<n>
#   check1  <name>  frontmatter=<ok|missing|unclosed|bad@LINE>  missing=<list|->  name=<match|mismatch:<v>|absent>
#   check2  <name>  phases=<distinct numbered phase headings>  h2=<distinct ## headings>  h2_total=<all of them>
#   check3  <name>  verdicts=<WORD:count,...|->  assessment_words=<in the description|->
#   check4  <name>  may_i_write=<n>  before_writing=<n>  approval=<n>  ask_write_lines=<n>  write_tools=<Write,Edit|->
#   check5  <name>  last_section=<heading|->  skills_named=<in that section|->  next_phrases=<whole skill>/<last section>
#   check6  <name>  context_fork=<yes|no>  phases=<n>  h2=<n>
#   check7  <name>  hint=<text|empty|absent>  args_section=<first Arguments/Parse heading@line|->
# and last `checked <N> of <M>`: skills read, skills found. A folder with no
# SKILL.md, or a SKILL.md that cannot be read, prints `NOT_READ <name> <reason>`
# and is not counted as read, so a skill that was not linted never looks clean.
# A references file that cannot be read is left out of files= and the counts.
# Every check row is printed for every skill, including check6 for a skill that
# sets no fork context: a skipped check says so (context_fork=no).
#
# How things are counted:
#   - headings are `## ` lines outside fenced code; a numbered phase is
#     `## Phase N...` or `## N.`; each heading text counts once, so a phase
#     repeated across SKILL.md and a reference file is one
#   - frontmatter is SKILL.md's, between the first two `---` lines; fields are
#     top-level `key:` lines
#   - verdict words are whole uppercase words from /skill-test check 3's three
#     lists, in SKILL.md and references together
#   - the Check 4 phrases are matched ignoring case; ask_write_lines counts lines
#     holding both "ask" and "writ"
#   - the last section is the last `## ` heading of SKILL.md and the text after
#     it; skills_named lists the /names in it that are skill folders
#
# Exit codes: 0 done; 1 cannot read the root or find .claude/skills; 2 usage
# error; 3 no such skill. Reads only; never prompts.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
# Byte semantics for awk and sort.
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
usage() { echo "skill-lint: $1 (try --help)" >&2; exit 2; }
WHICH=""; ROOT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --root) [ $# -ge 2 ] || usage "--root needs a value"; ROOT_ARG="$2"; shift 2 ;;
    --root=*) ROOT_ARG="${1#--root=}"; shift ;;
    -?*) usage "unknown argument: $1" ;;
    *) [ -z "$WHICH" ] || usage "one skill name or all"; WHICH="$1"; shift ;;
  esac
done
[ -n "$WHICH" ] || usage "no skill name given"
case "$WHICH" in */*|*\\*|.*) usage "'$WHICH' is not a skill folder name" ;; esac

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "skill-lint: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$HERE/../.." 2>/dev/null || { echo "skill-lint: cannot reach the repo root" >&2; exit 1; }
fi
SK=".claude/skills"
[ -d "$SK" ] || { echo "skill-lint: no $SK folder under $(pwd)" >&2; exit 1; }

# Every folder under .claude/skills/, so skills_named can tell a skill from a path.
NAMES="|"
for d in "$SK"/*/; do
  [ -d "$d" ] || continue
  d=${d%/}; NAMES="$NAMES${d##*/}|"
done

if [ "$WHICH" = all ]; then
  LIST_NAMES=""
  for d in "$SK"/*/; do
    [ -d "$d" ] || continue
    d=${d%/}; LIST_NAMES="$LIST_NAMES${d##*/}
"
  done
else
  [ -d "$SK/$WHICH" ] || { echo "skill-lint: no skill folder $SK/$WHICH" >&2; exit 3; }
  LIST_NAMES="$WHICH
"
fi

printf 'skills\t%s\t%s\n' "$(printf '%s' "$LIST_NAMES" | grep -c .)" "$SK"

# One line per file, SKILL.md first: name TAB path. A folder with no SKILL.md
# gets a line with an empty path, which the awk reports as NOT_READ.
{
  while IFS= read -r n; do
    [ -n "$n" ] || continue
    if [ -f "$SK/$n/SKILL.md" ]; then
      printf '%s\t%s\n' "$n" "$SK/$n/SKILL.md"
      for r in "$SK/$n/references/"*.md; do [ -f "$r" ] && printf '%s\t%s\n' "$n" "$r"; done
    else
      printf '%s\t\n' "$n"
    fi
  done <<EOF
$LIST_NAMES
EOF
} | SK_NAMES="$NAMES" awk -F'\t' '
  # VERDICTS: /skill-test Check 3 three lists, as written there: the gate and
  # review verdicts, the go and no-go verdicts, the severity scale.
  BEGIN {
    BINMODE = 3; split("", rs)
    VERDICTS = "PASS FAIL CONCERNS APPROVED BLOCKED COMPLETE READY COMPLIANT NON-COMPLIANT PROCEED PIVOT KILL GO NO-GO CRITICAL HIGH MEDIUM LOW"
  }
  # cnt(s, w): whole-word occurrences of w in s (no letter, digit, _ or - on either side).
  function cnt(s, w,    re, n) {
    re = "(^|[^A-Za-z0-9_-])" w "([^A-Za-z0-9_-]|$)"; n = 0
    while (match(s, re)) { n++; s = substr(s, RSTART + RLENGTH - 1) }
    return n
  }
  function occ(s, p,    n, i) {
    n = 0
    while ((i = index(s, p)) > 0) { n++; s = substr(s, i + length(p)) }
    return n
  }
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); return s }
  function unq(s,    q) {
    q = substr(s, 1, 1)
    if ((q == "\"" || q == "\047") && substr(s, length(s), 1) == q && length(s) >= 2) return substr(s, 2, length(s) - 2)
    return s
  }
  function reset() {
    split("", fmv); split("", h2seen); split("", phseen); split("", vcount); split("", named)
    fmstate = "missing"; badline = 0; h2total = 0; h2dist = 0; phdist = 0
    may = 0; bef = 0; apr = 0; askw = 0; nextall = 0; nextlast = 0; lastsec = ""; lastskills = ""
    argsh = ""; argsat = 0; nfiles = 0; nlines = 0; skillread = 0; unreadable = ""
    nextsec = 0; secskills = ""
  }
  function flush(   i, k, req, miss, nm, vs, wt, tools, fm, hint, aw, w, ctx) {
    if (cur == "") return
    if (!skillread) {
      printf "NOT_READ\t%s\t%s\n", cur, (unreadable != "" ? unreadable : "no SKILL.md")
      return
    }
    read++
    printf "skill\t%s\tfiles=%d\tlines=%d\n", cur, nfiles, nlines
    # check 1: the five fields Check 1 requires
    req = "name description argument-hint user-invocable allowed-tools"
    n = split(req, ra, " "); miss = ""
    for (i = 1; i <= n; i++) if (!(ra[i] in fmv)) miss = miss (miss == "" ? "" : ",") ra[i]
    if (fmstate == "bad") fm = "bad@" badline; else fm = fmstate
    if (!("name" in fmv)) nm = "absent"
    else if (unq(fmv["name"]) == cur) nm = "match"
    else nm = "mismatch:" unq(fmv["name"])
    printf "check1\t%s\tfrontmatter=%s\tmissing=%s\tname=%s\n", cur, fm, (miss == "" ? "-" : miss), nm
    # check 2
    printf "check2\t%s\tphases=%d\th2=%d\th2_total=%d\n", cur, phdist, h2dist, h2total
    # check 3
    vs = ""
    n = split(VERDICTS, va, " ")
    for (i = 1; i <= n; i++) if (vcount[va[i]] > 0) vs = vs (vs == "" ? "" : ",") va[i] ":" vcount[va[i]]
    aw = ""
    # The judgements Check 3 names (a review, audit, check, gate or readiness
    # judgement) and three words descriptions use for the same promise (ready,
    # validate, assess). Whole words, so "Reviews" is not counted as "review".
    n = split("review audit check gate ready readiness validate assess", wa, " ")
    for (i = 1; i <= n; i++) if (cnt(tolower(fmv["description"]), wa[i]) > 0) aw = aw (aw == "" ? "" : ",") wa[i]
    printf "check3\t%s\tverdicts=%s\tassessment_words=%s\n", cur, (vs == "" ? "-" : vs), (aw == "" ? "-" : aw)
    # check 4
    tools = ""
    if (cnt(fmv["allowed-tools"], "Write") > 0) tools = "Write"
    if (cnt(fmv["allowed-tools"], "Edit") > 0) tools = tools (tools == "" ? "" : ",") "Edit"
    printf "check4\t%s\tmay_i_write=%d\tbefore_writing=%d\tapproval=%d\task_write_lines=%d\twrite_tools=%s\n", cur, may, bef, apr, askw, (tools == "" ? "-" : tools)
    # check 5
    printf "check5\t%s\tlast_section=%s\tskills_named=%s\tnext_phrases=%d/%d\n", cur, (lastsec == "" ? "-" : lastsec), (lastskills == "" ? "-" : lastskills), nextall, nextlast
    # check 6
    ctx = ("context" in fmv && unq(fmv["context"]) == "fork") ? "yes" : "no"
    printf "check6\t%s\tcontext_fork=%s\tphases=%d\th2=%d\n", cur, ctx, phdist, h2dist
    # check 7
    if (!("argument-hint" in fmv)) hint = "absent"
    else { hint = unq(trim(fmv["argument-hint"])); if (hint == "") hint = "empty" }
    printf "check7\t%s\thint=%s\targs_section=%s\n", cur, hint, (argsh == "" ? "-" : argsh "@" argsat)
  }
  function scan(path, isskill,    l, ll, n, infm, infence, key, v, h, sec, p, nmx, rc, started, nm2, cut, curkey, x) {
    n = 0; infm = 0; infence = 0; started = 0; curkey = ""
    while ((rc = (getline l < path)) > 0) {
      n++; nlines++
      sub(/\r$/, "", l)
      if (isskill && n == 1) {
        if (l == "---") { infm = 1; fmstate = "unclosed"; continue }
        fmstate = "missing"
      }
      # Verdict words count in the frontmatter too: /prototype advertises PROCEED,
      # PIVOT and KILL in its description.
      if (l ~ /[A-Z][A-Z]/) {
        nm2 = split(VERDICTS, va2, " ")
        for (x = 1; x <= nm2; x++) vcount[va2[x]] += cnt(l, va2[x])
      }
      if (infm) {
        if (l == "---") { infm = 0; fmstate = (fmstate == "bad" ? "bad" : "ok"); continue }
        if (trim(l) == "" || substr(trim(l), 1, 1) == "#") continue
        if (substr(l, 1, 1) == " " || substr(l, 1, 1) == "\t" || substr(l, 1, 2) == "- ") {
          if (curkey != "") fmv[curkey] = fmv[curkey] " " trim(l)
          continue
        }
        p = index(l, ":")
        if (p < 2 || substr(l, 1, 1) == "#") { if (fmstate != "bad") { badline = n; fmstate = "bad" } ; continue }
        curkey = substr(l, 1, p - 1); sub(/[ \t]+$/, "", curkey)
        fmv[curkey] = trim(substr(l, p + 1))
        continue
      }
      if (l ~ /^[ \t]*(```|~~~)/) infence = !infence
      ll = tolower(l)
      # Check 4 phrases, then Check 5 phrases, as those checks list them.
      may += occ(ll, "may i write"); bef += occ(ll, "before writing"); apr += occ(ll, "approval")
      if (ll ~ /(^|[^a-z])ask/ && ll ~ /(^|[^a-z])writ/) askw++
      p = occ(ll, "next step") + occ(ll, "recommended next") + occ(ll, "follow-up") + occ(ll, "follow up") + occ(ll, "after this")
      nextall += p
      if (isskill) nextsec += p
      if (!infence && substr(l, 1, 3) == "## ") {
        h = trim(substr(l, 4)); h2total++
        if (!(h in h2seen)) { h2seen[h] = 1; h2dist++ }
        if ((h ~ /^Phase [0-9]/ || h ~ /^[0-9]+\./) && !(h in phseen)) { phseen[h] = 1; phdist++ }
        if (isskill) {
          lastsec = h; nextsec = p; secskills = ""
          if (argsh == "" && h ~ /([Aa]rgument|Parse)/) { argsh = h; argsat = n }
        }
      }
      if (isskill && lastsec != "") {
        # /names in the last section that are skill folders
        cut = l
        while (match(cut, /(^|[^A-Za-z0-9_\/.~-])\/[a-z][a-z0-9-]*/)) {
          nm3 = substr(cut, RSTART, RLENGTH); sub(/^[^\/]*\//, "", nm3)
          if (index(ENVIRON["SK_NAMES"], "|" nm3 "|") > 0 && index("," secskills ",", "," nm3 ",") == 0) secskills = secskills (secskills == "" ? "" : ",") nm3
          cut = substr(cut, RSTART + RLENGTH)
        }
        lastskills = secskills; nextlast = nextsec
      }
    }
    if (rc < 0) { unreadable = "cannot read " path; return 0 }
    close(path)
    nfiles++
    if (isskill) skillread = 1
    return 1
  }
  BEGIN { cur = ""; total = 0; read = 0; reset() }
  {
    if ($1 != cur) { flush(); cur = $1; total++; reset() }
    if ($2 == "") next
    scan($2, ($2 ~ /\/SKILL\.md$/))
  }
  END { flush(); printf "checked\t%d of %d\n", read, total }
'
exit 0
