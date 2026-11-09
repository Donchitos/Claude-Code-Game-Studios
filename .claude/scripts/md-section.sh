#!/usr/bin/env bash
# md-section.sh — find, read and edit sections of a Markdown file by heading,
# so a skill hands over a heading and the words instead of grepping a fixed
# number of lines (a `grep -A 15` window stops wherever 15 lines end, not where
# the section does).
#
# Replaces the hand-run section steps in /create-control-manifest, /create-epics,
# /create-stories, /dev-story, /propagate-design-change and /story-done.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# A section's status is the rule below applied to its lines; whether a
# Placeholder section blocks anything is the calling skill's call.
#
# Usage: bash .claude/scripts/md-section.sh <command> FILE [args]
#   list FILE                       every heading: level, first and last line, title
#   status FILE [HEADING ...]       COMPLETE / EMPTY / PLACEHOLDER per section
#                                   (every section when no HEADING is given)
#   extract FILE HEADING [--body]   the section's lines (--body: without its heading)
#   replace FILE HEADING            the section's body, subsections included,
#                                   becomes stdin; the heading stays
#   insert-before FILE HEADING      stdin goes in just above the heading, a
#                                   blank line after it and, when text is on
#                                   the line above, a blank line before it
#   set-field FILE FIELD VALUE [--after FIELD2]
#                                   a header field line (`> **Status**: Ready`,
#                                   `**Status:** Ready`, `- **Status**: Ready`,
#                                   `Status: Ready`) gets VALUE; when the field is
#                                   missing, --after adds it below FIELD2 in
#                                   FIELD2's style
#   -h, --help                      this text
#
# HEADING is the title as written, matched without regard to case, extra
# spaces, a leading number (`1. Overview` matches `Overview`), an HTML comment
# (`Overview <!-- fill me -->`) or emphasis (`**Rules**`, `__Rules__`; a `_`
# inside a word counts). Prefix it with #s (`'## Status'`) to match one level
# only.
#
# The rules every command shares:
#   - A heading is 1 to 6 `#` and a space, after at most 3 spaces of indent.
#   - A section runs from its heading to the line before the next heading of
#     the same or a higher level, so `###` subsections stay inside a `##` one.
#   - Lines inside a ``` or ~~~ code fence (3 or more, closed by at least as
#     many) and inside an HTML comment are never headings. A <!-- inside a
#     code span (`<!--`) opens no comment.
#   - Status, over the section's lines below its heading, fences skipped:
#       PLACEHOLDER  a line holds one of /art-bible's markers: [To be designed],
#                    [TBD], [To be written], or a line starting TODO or _TODO
#                    (HTML comments are not searched: a comment is not content)
#       EMPTY        no line holds text: blank lines, HTML comments, `---`
#                    rules and subheadings do not count
#       COMPLETE     anything else
#
# Output: TSV.
#   list:      headings <n>, then  <level> <first> <last> <title>
#   status:    sections, complete, empty, placeholder, not_found counts, then
#              <STATUS> <first>-<last> <title>  (NOT_FOUND - <HEADING> for a miss)
#   extract:   the lines themselves
#   writes:    file <path> <replaced|inserted|set|added|unchanged>, line <n>
#
# Exit codes: 0 done; 1 cannot read or write FILE; 2 usage error (unknown
# command, nothing on stdin, a newline in VALUE); 3 HEADING or FIELD not found;
# 4 HEADING matches more than one heading (nothing is written; a level prefix
# or a longer title tells them apart). A write makes the new file in full
# first, then copies it over FILE in place, so FILE keeps its mode and a
# symlink stays one; it keeps the file's LF or CRLF line ends, and a write
# that changes nothing leaves the file's bytes alone. Never prompts.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
# Byte semantics for awk: the CR tests and tolower below compare bytes.
LC_ALL=C
export LC_ALL

usage() { echo "md-section: $1 (try --help)" >&2; exit 2; }

[ $# -gt 0 ] || usage "no command"
case "$1" in
  -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  list|status|extract|replace|insert-before|set-field) CMD="$1"; shift ;;
  *) usage "unknown command: $1" ;;
esac
[ $# -gt 0 ] || usage "$CMD needs a FILE"
FILE="$1"; shift
[ -f "$FILE" ] && [ -r "$FILE" ] || { echo "md-section: cannot read $FILE" >&2; exit 1; }

HEADS=""; BODY_ONLY=0; FIELD=""; VALUE=""; AFTER=""
NL='
'
case "$CMD" in
  list) [ $# -eq 0 ] || usage "list takes only FILE" ;;
  status) for h in "$@"; do HEADS="$HEADS$h$NL"; done ;;
  extract|replace|insert-before)
    [ $# -ge 1 ] || usage "$CMD needs a HEADING"
    HEADS="$1$NL"; shift
    if [ "$CMD" = extract ] && [ "${1:-}" = "--body" ]; then BODY_ONLY=1; shift; fi
    [ $# -eq 0 ] || usage "unexpected argument: $1" ;;
  set-field)
    [ $# -ge 2 ] || usage "set-field needs FIELD and VALUE"
    FIELD="$1"; VALUE="$2"; shift 2
    if [ "${1:-}" = "--after" ]; then
      [ $# -ge 2 ] || usage "--after needs a FIELD"
      AFTER="$2"; shift 2
    fi
    [ $# -eq 0 ] || usage "unexpected argument: $1"
    case "$VALUE" in *"$NL"*) usage "VALUE cannot hold a newline" ;; esac ;;
esac

DIR=$(dirname "$FILE")
STDIN_FILE=""; NEW=""; STATUS_FILE=""
cleanup() { rm -f "$STDIN_FILE" "$NEW" "$STATUS_FILE"; }
trap cleanup EXIT
if [ "$CMD" = replace ] || [ "$CMD" = insert-before ] || [ "$CMD" = set-field ]; then
  NEW=$(mktemp "$DIR/.ccgs-md-XXXXXX" 2>/dev/null) || { echo "md-section: cannot create a temporary file in $DIR" >&2; exit 1; }
  STATUS_FILE="$NEW.status"
fi
if [ "$CMD" = replace ] || [ "$CMD" = insert-before ]; then
  STDIN_FILE="$NEW.in"
  # CR off; blank lines at both ends dropped.
  awk '{ sub(/\r$/, ""); l[++n] = $0; if ($0 !~ /^[ \t]*$/) { if (!f) f = n; e = n } }
       END { for (i = f; f && i <= e; i++) print l[i] }' > "$STDIN_FILE"
  [ -s "$STDIN_FILE" ] || usage "nothing on stdin to write"
fi

# One awk pass parses the file (headings, fences, comments, markers) into
# arrays; END runs the command. Arguments arrive through the environment, so a
# backslash in a title is not taken as an escape.
AWK_PROG='
  # Git for Windows gawk reads files in text mode and drops the CR of a CRLF
  # line; BINMODE 3 keeps every byte. Other awks treat it as a plain variable.
  BEGIN { BINMODE = 3 }

  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
  # A title for matching: no HTML comment (an unclosed one runs to the end),
  # no * emphasis and no _ at a word edge (a _ inside a word stays), lower
  # case, single spaces, no leading "1." or "1)".
  function norm(s,    p, e) {
    while ((p = index(s, "<!--")) > 0) {
      e = index(substr(s, p + 4), "-->")
      s = (e == 0) ? substr(s, 1, p - 1) : substr(s, 1, p - 1) " " substr(s, p + e + 6)
    }
    gsub(/\*+/, "", s)
    s = " " s " "; gsub(/[ \t]_+/, " ", s); gsub(/_+[ \t]/, " ", s)
    s = tolower(trim(s)); gsub(/[ \t]+/, " ", s)
    if (s ~ /^[0-9]+[.)]? /) sub(/^[0-9]+[.)]? /, "", s)
    return s
  }
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
  # The fence a line opens ("```", "~~~~", ...), or "" when it opens none.
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

  {
    raw[NR] = $0
    line = $0; sub(/\r$/, "", line)
    if (NR == 1) crlf = ($0 ~ /\r$/)
    lvl[NR] = 0; text[NR] = 0; mark[NR] = 0
    if (infence) {
      if (closes(line, infence)) infence = ""
      next
    }
    # Fence-looking lines inside an HTML comment are comment content.
    f = incomment ? "" : fence_of(line)
    if (f != "") { infence = f; text[NR] = 1; next }
    # HTML comments: what is left of the line outside them. A line that starts
    # inside a comment, or opens one, is never a heading. A <!-- inside a code
    # span (`<!--`) is text, as Markdown reads it: a span is a run of
    # backticks closed by a run as long on the same line.
    cstart = incomment
    rest = ""; s = line
    while (s != "") {
      if (incomment) {
        p = index(s, "-->"); if (p == 0) { s = ""; break }
        s = substr(s, p + 3); incomment = 0
      } else {
        p = index(s, "<!--"); b = index(s, "`")
        if (b > 0 && (p == 0 || b < p)) {
          k = 0; while (substr(s, b + k, 1) == "`") k++
          e = span_end(substr(s, b + k), k)
          q = (e > 0) ? b + k + e - 1 + k : b + k
          rest = rest substr(s, 1, q - 1); s = substr(s, q)
          continue
        }
        if (p == 0) { rest = rest s; s = ""; break }
        rest = rest substr(s, 1, p - 1); s = substr(s, p + 4); incomment = 1
      }
    }
    startcomment = (line ~ /^[ \t]*<!--/)
    # A heading: up to 3 spaces, 1-6 #, then a space or the end of the line.
    h = line; n = 0; while (n < 3 && substr(h, n + 1, 1) == " ") n++
    h = substr(h, n + 1); k = 0; while (substr(h, k + 1, 1) == "#") k++
    if (!cstart && !startcomment && k >= 1 && k <= 6 && (length(h) == k || substr(h, k + 1, 1) == " " || substr(h, k + 1, 1) == "\t")) {
      t = trim(substr(h, k + 1))
      # A closing run of # (after a space) is not part of the title.
      if (t ~ /(^| )#+$/) { sub(/#+$/, "", t); t = trim(t) }
      lvl[NR] = k; title[NR] = t; nh++; hl[nh] = NR
      next
    }
    r = trim(rest)
    if (r != "" && r !~ /^(---+|\*\*\*+|___+)$/) text[NR] = 1
    if (rest ~ /\[To be designed\]|\[TBD\]|\[To be written\]/ || line ~ /^_?TODO/) mark[NR] = 1
  }

  function last_of(i,    j) {     # last line of the section that heading i opens
    for (j = i + 1; j <= nh; j++) if (lvl[hl[j]] <= lvl[hl[i]]) return hl[j] - 1
    return NR
  }
  function status_of(i,    a, b, L, any) {
    a = hl[i]; b = last_of(i); any = 0
    for (L = a + 1; L <= b; L++) { if (mark[L]) return "PLACEHOLDER"; if (text[L]) any = 1 }
    return any ? "COMPLETE" : "EMPTY"
  }
  # Headings that match a HEADING argument; "##" in front pins the level.
  function find(arg,    want, wl, i, m) {
    want = trim(arg); wl = 0
    while (substr(want, wl + 1, 1) == "#") wl++
    want = norm(substr(want, wl + 1)); m = 0
    for (i = 1; i <= nh; i++)
      if (norm(title[hl[i]]) == want && (wl == 0 || lvl[hl[i]] == wl)) { m++; found[m] = i }
    return m
  }
  function one(arg,    m, i, s) {
    m = find(arg)
    if (m == 0) { printf "md-section: no heading \"%s\" in the file\n", arg > "/dev/stderr"; exit 3 }
    if (m > 1) {
      s = ""; for (i = 1; i <= m; i++) s = s (i > 1 ? ", " : "") hl[found[i]]
      printf "md-section: \"%s\" matches %d headings (lines %s); add a level (\"## %s\") or a longer title. Nothing was written.\n", arg, m, s, trim(arg) > "/dev/stderr"
      exit 4
    }
    return found[1]
  }
  function out(s) { printf "%s%s\n", s, (crlf ? "\r" : "") }
  # A header field line: its prefix through the colon (and a closing **) and
  # the spaces after it, so the value can be swapped and the style kept.
  function field_prefix(line, name,    norm_line, p, q, low) {
    norm_line = line; sub(/^[ \t]*/, "", norm_line); sub(/^> ?/, "", norm_line); sub(/^- /, "", norm_line)
    gsub(/\*/, "", norm_line)
    low = tolower(norm_line)
    if (substr(low, 1, length(name) + 1) != tolower(name) ":") return ""
    p = index(tolower(line), tolower(name)); if (p == 0) return ""
    q = p + length(name); while (substr(line, q, 1) == "*") q++
    if (substr(line, q, 1) != ":") return ""
    q++; while (substr(line, q, 1) == "*") q++
    while (substr(line, q, 1) == " " || substr(line, q, 1) == "\t") q++
    return substr(line, 1, q - 1)
  }

  END {
    cmd = ENVIRON["CMD"]
    if (cmd == "list") {
      print "headings\t" nh
      for (i = 1; i <= nh; i++) { t = title[hl[i]]; gsub(/\t/, " ", t); printf "%d\t%d\t%d\t%s\n", lvl[hl[i]], hl[i], last_of(i), t }
      exit 0
    }
    if (cmd == "status") {
      nreq = split(ENVIRON["HEADS"], req, "\n"); rows = 0; nc = ne = np = nf = 0
      if (ENVIRON["HEADS"] == "") { for (i = 1; i <= nh; i++) pick[++rows] = i }
      else for (r = 1; r <= nreq; r++) {
        if (req[r] == "") continue
        m = find(req[r])
        if (m == 0) { rows++; pick[rows] = 0; miss[rows] = req[r]; continue }
        for (j = 1; j <= m; j++) pick[++rows] = found[j]
      }
      for (r = 1; r <= rows; r++) {
        if (pick[r] == 0) { nf++; line_[r] = "NOT_FOUND\t-\t" miss[r]; continue }
        i = pick[r]; st = status_of(i); t = title[hl[i]]; gsub(/\t/, " ", t)
        if (st == "COMPLETE") nc++; else if (st == "EMPTY") ne++; else np++
        line_[r] = st "\t" hl[i] "-" last_of(i) "\t" t
      }
      printf "sections\t%d\ncomplete\t%d\nempty\t%d\nplaceholder\t%d\nnot_found\t%d\n", rows - nf, nc, ne, np, nf
      for (r = 1; r <= rows; r++) print line_[r]
      exit 0
    }
    if (cmd == "extract") {
      split(ENVIRON["HEADS"], req, "\n"); i = one(req[1])
      a = hl[i] + (ENVIRON["BODY_ONLY"] == "1" ? 1 : 0); b = last_of(i)
      for (L = a; L <= b; L++) { s = raw[L]; sub(/\r$/, "", s); print s }
      exit 0
    }
    sf = ENVIRON["STATUS_FILE"]
    if (cmd == "replace" || cmd == "insert-before") {
      split(ENVIRON["HEADS"], req, "\n"); i = one(req[1])
      nb = 0; while ((getline s < ENVIRON["STDIN_FILE"]) > 0) body[++nb] = s
      a = hl[i]; b = last_of(i)
      if (cmd == "replace") {
        for (L = 1; L <= a; L++) print raw[L]
        out(""); for (k = 1; k <= nb; k++) out(body[k])
        if (b < NR) out("")
        for (L = b + 1; L <= NR; L++) print raw[L]
        print "replaced\t" a > sf
      } else {
        same = (a - nb - 1 >= 1)
        # Already there: the block sits on lines a-nb-1 .. a-2, a blank line at a-1.
        for (k = 1; same && k <= nb; k++) { s = raw[a - nb - 2 + k]; sub(/\r$/, "", s); if (s != body[k]) same = 0 }
        if (same) { s = raw[a - 1]; sub(/\r$/, "", s); if (s !~ /^[ \t]*$/) same = 0 }
        # Text on the line above the heading gets a blank line before the
        # block, as one already parts the block from the heading, so the
        # block never joins the paragraph above.
        sep = 0
        if (!same && a > 1) { s = raw[a - 1]; sub(/\r$/, "", s); if (s !~ /^[ \t]*$/) sep = 1 }
        for (L = 1; L < a; L++) print raw[L]
        if (!same) { if (sep) out(""); for (k = 1; k <= nb; k++) out(body[k]); out("") }
        for (L = a; L <= NR; L++) print raw[L]
        print (same ? "unchanged" : "inserted") "\t" (same ? a - nb - 1 : a + sep) > sf
      }
      exit 0
    }
    if (cmd == "set-field") {
      name = ENVIRON["FIELD"]; val = ENVIRON["VALUE"]; after = ENVIRON["AFTER"]
      at = 0; aft = 0
      for (L = 1; L <= NR; L++) {
        # Only lines with text outside fences and comments: a field quoted in a
        # code sample or a comment is not the header field.
        if (lvl[L] > 0 || !text[L]) continue
        s = raw[L]; sub(/\r$/, "", s)
        if (!at && (p = field_prefix(s, name)) != "") { at = L; pre = p; cur = substr(s, length(p) + 1) }
        if (after != "" && !aft && (p = field_prefix(s, after)) != "") { aft = L; apre = p }
      }
      if (at) {
        if (cur == val) { for (L = 1; L <= NR; L++) print raw[L]; print "unchanged\t" at > sf; exit 0 }
        cr = (raw[at] ~ /\r$/)
        for (L = 1; L <= NR; L++) {
          if (L == at) printf "%s%s%s\n", pre, val, (cr ? "\r" : ""); else print raw[L]
        }
        print "set\t" at > sf; exit 0
      }
      if (after == "") { printf "md-section: no \"%s\" field in the file (add --after FIELD to add it)\n", name > "/dev/stderr"; exit 3 }
      if (!aft) { printf "md-section: no \"%s\" field, and no \"%s\" field to add it after\n", name, after > "/dev/stderr"; exit 3 }
      # The new line copies FIELD2 line style: its prefix with the name swapped.
      p = index(tolower(apre), tolower(after))
      npre = substr(apre, 1, p - 1) name substr(apre, p + length(after))
      cr = (raw[aft] ~ /\r$/)
      for (L = 1; L <= NR; L++) { print raw[L]; if (L == aft) printf "%s%s%s\n", npre, val, (cr ? "\r" : "") }
      print "added\t" aft + 1 > sf; exit 0
    }
  }
'
export CMD HEADS BODY_ONLY FIELD VALUE AFTER STDIN_FILE STATUS_FILE
# Into the temp file for a write; straight to stdout otherwise, never through
# /dev/stdout, which reopens a redirected stdout at offset 0 and overwrites it.
if [ -n "$NEW" ]; then awk "$AWK_PROG" "$FILE" > "$NEW"; else awk "$AWK_PROG" "$FILE"; fi
rc=$?
[ "$rc" = 0 ] || exit "$rc"
[ -n "$NEW" ] || exit 0

IFS="$(printf '\t')" read -r ACTION LINE < "$STATUS_FILE"
if [ "$ACTION" != "unchanged" ] && cmp -s "$NEW" "$FILE"; then ACTION="unchanged"; fi
if [ "$ACTION" != "unchanged" ]; then
  # Copied over FILE in place, not moved: FILE keeps its mode, a symlink stays
  # a symlink and a hard link sees the change.
  cat "$NEW" > "$FILE" 2>/dev/null || { echo "md-section: could not write $FILE" >&2; exit 1; }
fi
printf 'file\t%s\t%s\nline\t%s\t-\n' "$FILE" "$ACTION" "$LINE"
exit 0
