#!/usr/bin/env bash
# flaky-stats.sh — per-test runs, passes, fails, skips, fail percentage and
# pass/fail pattern across several test runs, with the threshold row each
# test's rate fell in, read from the result files and logs /test-flakiness
# parses, so one table replaces grepping every log by hand.
#
# Replaces the hand-run parse and tiering of a flakiness review, and the
# "which tests failed in which runs" counting done from the same logs.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# The tier row (high, moderate, low, below-low, suspected, always-fail) is the
# rule that matched, printed with its text. Whether to quarantine, what to tell
# the user and what "confirmed" means stay in the skill.
#
# Usage: bash .claude/scripts/flaky-stats.sh [--root DIR] [--format F] [--runs] [--all] [FILE ...]
#   FILE        one test run per file, in run order (the order of the pattern);
#               relative to the root. With none, the files under test-results/,
#               reports/ and Saved/Logs/ named *.xml, *.log or *.txt, sorted by
#               path: pass the files yourself when their names do not sort in
#               run order
#   --format F  auto (default: found per file), junit, nunit, unreal or text
#   --runs      also print one RUN row per file
#   --all       also list tests with no fail and no skip (default: only tests
#               with at least one fail or skip are listed; the rest are counted)
#   --root DIR  the project; defaults to the repo this script is in
#   -h, --help  this text
#
# What it parses (one result per test case, in file order):
#   junit   gdUnit4's JUnit XML: each <testcase>; id is classname.name (name
#           alone when there is no classname); a <failure> or <error> inside it
#           is a fail, else <skipped> is a skip, else a pass
#   nunit   Unity's NUnit XML: each <test-case>; id is its fullname (name when
#           none); result Passed is a pass, Failed a fail, and every other
#           value (Inconclusive, Skipped) a skip, so only Passed and Failed
#           enter the history, as /test-flakiness says
#   unreal  lines holding "Test Completed. Result={W}": Success is a pass, Fail
#           a fail, any other word a skip and listed as `unrecognised`; id is
#           Path={...}, else Name={...}; a result with neither is counted as
#           no_id and kept out of the tests
#   text    a line with PASSED or FAILED as a whole word (Godot), or Test passed
#           or Test failed (Unity): the id is the line without the marker, a
#           leading ISO timestamp, ANSI colour codes, timing words like 12ms or
#           (0.5s), and the punctuation [](): > | * - , around it. A line with
#           more than one marker (a summary) is not a result
# CDATA sections and comments are skipped, XML entities in ids are decoded, a
# tag may run over several lines.
#
# Output: TSV. Counts first, then rows:
#   scan <dir> <present|absent>   per default folder (only when no FILE given)
#   runs <analysed> <read>        files holding at least one result, files read
#   tests <n>                     distinct test ids
#   clean <n> <rule>              tests with a counted result and no fail
#   flaky <n> <rule>              tests with both a pass and a fail
#   tier <name> <n> <rule>        high, moderate, low, below-low, suspected
#   always_fail <n> <rule>        tests with a fail and no pass
#   no_result <n> <rule>          tests with only skips
#   data_note <text | ->          "fewer than 5 runs" when analysed < 5
#   no_id <n>                     results with no test name, kept out
#   unrecognised <format> <word> <n>   result words the skill does not name
#   RUN <n> <path> <format> <results> <pass> <fail> <skip> <no_id>   (--runs)
#   TEST <id> <runs> <pass> <fail> <skip> <fail_pct> <pattern> <flaky> <tier> <rule>
#       runs = pass + fail (skips are not runs); fail_pct = fail / runs,
#       truncated (not rounded) to one decimal so a printed value never sits
#       on the far side of a tier edge, or - when runs is 0; pattern = P, F or
#       S per result in file order; tier = the name above, or none (no fail) or
#       no-result; rows sorted by fail rate, highest first, then by id
#
# The tiers, with every edge in exactly one (the skill's text puts 5% in two
# and says nothing below 1%). fail_pct is the exact ratio, not the printed one:
#   fail_pct > 25           high         (the skill's ">25%")
#   5 <= fail_pct <= 25     moderate     (the skill's "5-25%"; 5 and 25 here)
#   1 <= fail_pct < 5       low          (the skill's "1-5%"; 1 here, 5 is moderate)
#   0 < fail_pct < 1        below-low    (named; the skill gives it no tier)
# and before the tiers:
#   no pass, at least one fail   always-fail   (the skill leaves it unclassified;
#                                              by its own definition it is not flaky)
#   a pass and a fail, but fewer than 3 runs   suspected   (the skill: "with
#       fewer than 3 runs every finding is suspected"; counted per test, as the
#       skill's own example reasons from one test's data points)
#
# Exit codes: 0 parsed at least one result; 1 the root cannot be read; 2 usage
# error; 3 no files to read (none given and none found, or a named file is
# missing); 4 files were read and held no result. Reads only; never writes,
# never prompts.
#
# bash 3.2 and BWK awk safe, no Python. BWK awk's split() with
# a one-character separator also splits on newlines, so split() is used here
# only on a single line.

set -u
# Byte semantics for awk, sort and tolower.
LC_ALL=C
export LC_ALL

ROOT_ARG=""; FORMAT="auto"; SHOWRUNS=0; ALL=0; FILES=""
NL='
'
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "flaky-stats: --root needs a value" >&2; exit 2; }; ROOT_ARG="$2"; shift 2 ;;
    --root=*) ROOT_ARG="${1#--root=}"; shift ;;
    --format) [ $# -ge 2 ] || { echo "flaky-stats: --format needs a value" >&2; exit 2; }; FORMAT="$2"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --runs) SHOWRUNS=1; shift ;;
    --all) ALL=1; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) echo "flaky-stats: unknown argument: $1 (try --help)" >&2; exit 2 ;;
    *) FILES="$FILES${1#./}$NL"; shift ;;
  esac
done
case "$FORMAT" in
  auto|junit|nunit|unreal|text) ;;
  *) echo "flaky-stats: --format takes auto, junit, nunit, unreal or text, got $FORMAT" >&2; exit 2 ;;
esac

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "flaky-stats: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$(dirname "$0")/../.." 2>/dev/null || { echo "flaky-stats: cannot reach the repo root" >&2; exit 1; }
fi

if [ -z "$FILES" ]; then
  # The folders the skill names: gdUnit4's reports/, the game-ci and saved
  # test-results/, and Unreal's Saved/Logs/.
  for d in test-results reports Saved/Logs; do
    if [ -d "$d" ]; then
      printf 'scan\t%s\tpresent\n' "$d"
      FILES="$FILES$(find "$d" -type f \( -name '*.xml' -o -name '*.log' -o -name '*.txt' \) 2>/dev/null)$NL"
    else
      printf 'scan\t%s\tabsent\n' "$d"
    fi
  done
  FILES=$(printf '%s' "$FILES" | awk 'NF' | sort -u)
  if [ -z "$FILES" ]; then
    echo "flaky-stats: no test result files under test-results/, reports/ or Saved/Logs/; name the files" >&2
    exit 3
  fi
else
  FILES=$(printf '%s' "$FILES" | awk 'NF')
  while IFS= read -r f; do
    [ -f "$f" ] || { echo "flaky-stats: no such file: $f" >&2; exit 3; }
  done <<EOF
$FILES
EOF
fi

# The file list goes to awk on stdin, never as arguments (a long list passes
# the command-line limit of some systems); each file gets "./" in front so a
# name like x=1.log is not read as an awk assignment.
printf '%s\n' "$FILES" | FORMAT="$FORMAT" SHOWRUNS="$SHOWRUNS" ALL="$ALL" awk '
  BEGIN {
    BINMODE = 3
    fmtarg = ENVIRON["FORMAT"]
    # The list arrives on /dev/stdin, named, so the main input stays the files.
    while ((getline f < "/dev/stdin") > 0) {
      if (f == "") continue
      nf++; lst[nf] = f
      av = (f ~ /^(\/|[A-Za-z]:)/) ? f : "./" f
      fidx[av] = nf
      fmt[nf] = (fmtarg == "auto") ? detect(f) : fmtarg
      ARGV[ARGC++] = av
    }
  }
  # Detect actual XML elements with the same scanner used for result parsing,
  # so comments, CDATA and quoted tag contents cannot change the format.
  # Logs without XML test markers stay on the original cheap text scan.
  function detect(f,    l, candidate, un, result) {
    candidate = 0; un = 0
    while ((getline l < f) > 0) {
      if (index(l, "<test-case") > 0 || index(l, "<testcase") > 0) candidate = 1
      if (index(l, "Test Completed. Result={") > 0) un = 1
    }
    close(f)
    if (!candidate) return un ? "unreal" : "text"
    detecting = 1; detect_nu = 0; detect_ju = 0
    pend = ""; skipterm = ""
    while ((getline l < f) > 0) {
      sub(/\r$/, "", l)
      xml_line(l)
    }
    close(f)
    result = detect_nu ? "nunit" : (detect_ju ? "junit" : (un ? "unreal" : "text"))
    detecting = 0; pend = ""; skipterm = ""
    return result
  }
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
  # XML entities in an id; &amp; last so &amp;lt; stays &lt;.
  function xd(s) {
    gsub(/&lt;/, "<", s); gsub(/&gt;/, ">", s); gsub(/&quot;/, "\042", s); gsub(/&apos;/, "\047", s)
    gsub(/&amp;/, "\\&", s)
    return s
  }
  # The value of attribute name in tag t; the name must follow white space, so
  # name= does not match classname= or fullname=.
  function attr(t, name,    re, q, rest, e) {
    re = "[ \t]" name "[ \t]*=[ \t]*[\042\047]"
    if (!match(t, re)) return ""
    q = substr(t, RSTART + RLENGTH - 1, 1)
    rest = substr(t, RSTART + RLENGTH)
    e = index(rest, q)
    return trim(xd(e ? substr(rest, 1, e - 1) : rest))
  }
  function unrec(f, w,    k) {
    k = f "\t" w
    if (!(k in uc)) uo[++nu] = k
    uc[k]++
  }
  function record(id, code) {
    if (id == "") { noid++; rnoid[curj]++; return }
    gsub(/\t/, " ", id)
    if (!(id in seen)) { seen[id] = 1; order[++nt] = id }
    if (code == "P") { tp[id]++; rp[curj]++ }
    else if (code == "F") { tf[id]++; rf[curj]++ }
    else { ts[id]++; rs[curj]++ }
    pat[id] = pat[id] code
    rres[curj]++
  }
  # The index of the > that closes the tag starting at s (a > inside quotes
  # does not), or 0.
  function tag_end(s,    i, n, c, qc) {
    n = length(s); qc = ""
    for (i = 2; i <= n; i++) {
      c = substr(s, i, 1)
      if (qc != "") { if (c == qc) qc = ""; continue }
      if (c == "\042" || c == "\047") qc = c
      else if (c == ">") return i
    }
    return 0
  }
  function xml_tag(t,    c2, closing, name, selfc, id, r, c) {
    c2 = substr(t, 2, 1)
    if (c2 == "?" || c2 == "!") return
    closing = (c2 == "/")
    name = substr(t, closing ? 3 : 2)
    sub(/[ \t\/>].*$/, "", name)
    selfc = (substr(t, length(t) - 1, 1) == "/")
    if (detecting) {
      if (!closing && name == "test-case") detect_nu = 1
      else if (!closing && name == "testcase") detect_ju = 1
      return
    }
    if (cf == "nunit") {
      if (!closing && name == "test-case") {
        id = attr(t, "fullname"); if (id == "") id = attr(t, "name")
        r = attr(t, "result")
        if (r == "Passed") record(id, "P")
        else if (r == "Failed") record(id, "F")
        else {
          record(id, "S")
          if (r != "Inconclusive" && r != "Skipped") unrec("nunit", (r == "") ? "(none)" : r)
        }
      }
      return
    }
    # junit
    if (closing) {
      if (name == "testcase" && jopen) { record(jid, jcode); jopen = 0 }
      return
    }
    if (name == "testcase") {
      if (jopen) { record(jid, jcode); jopen = 0 }
      id = attr(t, "name"); c = attr(t, "classname")
      jid = (c != "") ? c "." id : id
      jcode = "P"
      if (selfc) record(jid, "P"); else jopen = 1
      return
    }
    if (jopen) {
      if (name == "failure" || name == "error") jcode = "F"
      else if (name == "skipped" && jcode != "F") jcode = "S"
    }
  }
  function xml_line(s,    p, q) {
    if (pend != "") { s = pend " " s; pend = "" }
    while (s != "") {
      if (skipterm != "") {
        p = index(s, skipterm)
        if (p == 0) return
        s = substr(s, p + length(skipterm)); skipterm = ""
        continue
      }
      p = index(s, "<")
      if (p == 0) return
      s = substr(s, p)
      if (substr(s, 1, 9) == "<![CDATA[") { skipterm = "]]>"; s = substr(s, 10); continue }
      if (substr(s, 1, 4) == "<!--") { skipterm = "-->"; s = substr(s, 5); continue }
      q = tag_end(s)
      if (q == 0) { pend = s; return }
      xml_tag(substr(s, 1, q)); s = substr(s, q + 1)
    }
  }
  function brace(s, key,    p, e) {
    p = index(s, key "={")
    if (p == 0) return ""
    s = substr(s, p + length(key) + 2); e = index(s, "}")
    return trim(e ? substr(s, 1, e - 1) : s)
  }
  function unreal_line(s,    mk, p, rest, q, w, id, code) {
    mk = "Test Completed. Result={"
    p = index(s, mk)
    if (p == 0) return
    rest = substr(s, p + length(mk)); q = index(rest, "}")
    if (q == 0) return
    w = substr(rest, 1, q - 1); rest = substr(rest, q + 1)
    id = brace(rest, "Path"); if (id == "") id = brace(rest, "Name")
    if (w == "Success") code = "P"
    else if (w == "Fail") code = "F"
    else { code = "S"; unrec("unreal", w) }
    record(id, code)
  }
  function text_line(s,    hp, hf, tpz, tfl, code, marker, p, t, n, a, i, out) {
    gsub(/\033\[[0-9;]*m/, "", s)
    hp = match(s, /(^|[^A-Za-z0-9_])PASSED([^A-Za-z0-9_]|$)/) > 0
    hf = match(s, /(^|[^A-Za-z0-9_])FAILED([^A-Za-z0-9_]|$)/) > 0
    tpz = index(s, "Test passed") > 0
    tfl = index(s, "Test failed") > 0
    if (hp + hf + tpz + tfl != 1) return
    if (hp) { code = "P"; marker = "PASSED" }
    else if (hf) { code = "F"; marker = "FAILED" }
    else if (tpz) { code = "P"; marker = "Test passed" }
    else { code = "F"; marker = "Test failed" }
    p = index(s, marker)
    t = substr(s, 1, p - 1) " " substr(s, p + length(marker))
    sub(/^[ \t]*[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][T ][0-9:.]+Z?[ \t]*/, "", t)
    n = split(t, a, " "); out = ""
    for (i = 1; i <= n; i++) {
      if (a[i] ~ /^\(?[0-9][0-9.]*(ms|s)\)?$/) continue
      out = (out == "") ? a[i] : out " " a[i]
    }
    while (out != "" && index(" []():>|*-,", substr(out, 1, 1)) > 0) out = substr(out, 2)
    while (out != "" && index(" []():>|*-,", substr(out, length(out), 1)) > 0) out = substr(out, 1, length(out) - 1)
    record(out, code)
  }
  function endfile() {
    if (jopen) { record(jid, jcode); jopen = 0 }
  }
  # fail rate as tenths of a percent, truncated: 1/3 -> 33.3, 2/3 -> 66.6
  function pct1(f, n,    v) {
    if (n == 0) return "-"
    v = int(f * 1000 / n)
    return sprintf("%d.%d", int(v / 10), v % 10)
  }
  # Sets TIER and RULE for a test with p passes and f fails. fail_pct is
  # compared as the exact ratio f/n, by cross-multiplying, never as a printed
  # or rounded number.
  function classify(p, f,    n) {
    n = p + f
    if (n == 0) { TIER = "no-result"; RULE = "only skipped results"; return }
    if (f == 0) { TIER = "none"; RULE = "no fail in the counted results"; return }
    if (p == 0) { TIER = "always-fail"; RULE = "no pass in the counted results"; return }
    if (n < 3) { TIER = "suspected"; RULE = "flaky, fewer than 3 results"; return }
    if (f * 100 > 25 * n) { TIER = "high"; RULE = "fail_pct > 25"; return }
    if (f * 100 >= 5 * n) { TIER = "moderate"; RULE = "5 <= fail_pct <= 25"; return }
    if (f * 100 >= n) { TIER = "low"; RULE = "1 <= fail_pct < 5"; return }
    TIER = "below-low"; RULE = "0 < fail_pct < 1"
  }
  # Does test a list before test b: higher fail rate first, tests with no
  # counted result last, then by id.
  function before(a, b) {
    if (kn[a] == 0 || kn[b] == 0) {
      if (kn[a] == 0 && kn[b] == 0) return ((order[a] "") < (order[b] ""))
      return (kn[b] == 0)
    }
    if (kf[a] * kn[b] != kf[b] * kn[a]) return (kf[a] * kn[b] > kf[b] * kn[a])
    return ((order[a] "") < (order[b] ""))
  }
  FNR >= 1 {
    if (FILENAME != curfn) {
      endfile(); curfn = FILENAME; curj = fidx[FILENAME]; cf = fmt[curj]
      pend = ""; skipterm = ""; jopen = 0
    }
    line = $0; sub(/\r$/, "", line)
    if (cf == "nunit" || cf == "junit") xml_line(line)
    else if (cf == "unreal") unreal_line(line)
    else text_line(line)
  }
  END {
    endfile()
    analysed = 0
    for (j = 1; j <= nf; j++) if (rres[j] > 0) analysed++
    for (k = 1; k <= nt; k++) {
      id = order[k]; kp[k] = tp[id] + 0; kf[k] = tf[id] + 0; ks[k] = ts[id] + 0; kn[k] = kp[k] + kf[k]
      classify(kp[k], kf[k]); kt[k] = TIER; kr[k] = RULE
      if (kn[k] > 0 && kf[k] == 0) nclean++
      if (kp[k] > 0 && kf[k] > 0) nflaky++
      tc[kt[k]]++
    }
    printf "runs\t%d\t%d\n", analysed, nf
    printf "tests\t%d\n", nt
    printf "clean\t%d\tno fail in the counted results\n", nclean
    printf "flaky\t%d\ta pass and a fail in the counted results\n", nflaky
    printf "tier\thigh\t%d\tfail_pct > 25\n", tc["high"]
    printf "tier\tmoderate\t%d\t5 <= fail_pct <= 25\n", tc["moderate"]
    printf "tier\tlow\t%d\t1 <= fail_pct < 5\n", tc["low"]
    printf "tier\tbelow-low\t%d\t0 < fail_pct < 1\n", tc["below-low"]
    printf "tier\tsuspected\t%d\tflaky, fewer than 3 results\n", tc["suspected"]
    printf "always_fail\t%d\tno pass in the counted results\n", tc["always-fail"]
    printf "no_result\t%d\tonly skipped results\n", tc["no-result"]
    printf "data_note\t%s\n", (analysed < 5) ? "fewer than 5 runs" : "-"
    printf "no_id\t%d\n", noid
    for (i = 1; i <= nu; i++) printf "unrecognised\t%s\t%d\n", uo[i], uc[uo[i]]
    if (ENVIRON["SHOWRUNS"] == "1")
      for (j = 1; j <= nf; j++)
        printf "RUN\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\n", j, lst[j], fmt[j], rres[j], rp[j], rf[j], rs[j], rnoid[j]
    nl = 0
    for (k = 1; k <= nt; k++) if (ENVIRON["ALL"] == "1" || kf[k] > 0 || ks[k] > 0) srt[++nl] = k
    for (i = 2; i <= nl; i++) {
      v = srt[i]
      for (j = i - 1; j >= 1 && before(v, srt[j]); j--) srt[j + 1] = srt[j]
      srt[j + 1] = v
    }
    for (i = 1; i <= nl; i++) {
      k = srt[i]
      printf "TEST\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%s\t%s\t%s\n", order[k], kn[k], kp[k], kf[k], ks[k], pct1(kf[k], kn[k]), \
        pat[order[k]], (kp[k] > 0 && kf[k] > 0) ? "yes" : "no", kt[k], kr[k]
    }
    exit ((analysed == 0) ? 4 : 0)
  }
'
exit $?
