#!/usr/bin/env bash
# code-markers.sh — TODO, FIXME and HACK markers, debug output calls,
# placeholder names and long files in the game's source, with how many files
# were scanned, so a checklist reads counts with their denominator instead of
# grepping by hand.
#
# Replaces the scans a release or launch checklist, a tech-debt pass or a
# milestone review would otherwise run by hand, so they all read the same
# counts.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# Whether a FIXME blocks a release is the checklist's rule. A scan that found
# nothing because there was nothing to scan says so: scanned_files 0, and exit
# 3 when the code root itself is unknown.
#
# Usage: bash .claude/scripts/code-markers.sh [--root DIR] [--long N] [--exclude PATTERN ...] [PATH ...]
#   PATH          folders or files to scan, relative to the root or absolute;
#                 default: the code root project-state.sh resolves (src/,
#                 Assets/ or Source/)
#   --exclude P   skip paths matching the shell pattern P (relative to the
#                 root, * matching across folders), e.g. 'Assets/Plugins/*'
#   --long N      a file of more than N lines is long (default 500, /tech-debt's)
#   --root DIR    the project; defaults to the repo this script is in
#   -h, --help    this text
#
# What counts:
#   source files  .gd .cs .cpp .cc .c .h .hpp .rs .py .js .ts .lua .java .kt:
#                 every extension the hooks and helpers already treat as code
#                 (session-start, statusline, project-state, detect-gaps,
#                 validate-commit), scene and resource files left out
#   markers       TODO, FIXME and HACK as whole words in capitals, anywhere in
#                 the line (a marker is a marker in a comment or a string)
#   debug calls   by language: GDScript print, prints, printt, printraw,
#                 print_rich, print_debug; C# Debug.Log* and print; C and C++
#                 UE_LOG, AddOnScreenDebugMessage, printf; JavaScript and
#                 TypeScript console.log, console.debug, debugger; Python and
#                 Lua print; Rust println!, eprintln!, dbg!; Java and Kotlin
#                 System.out.print* and println
#   placeholders  placeholder, temp_ or wip_ in any case (/launch-checklist's)
#   long files    more than --long lines. Function length is not measured: no
#                 skill defines how, per language.
#
# Output: TSV. Counts first:
#   scanned_files <n> <paths>, scanned_lines <n>, todo, fixme, hack, debug,
#   placeholder <n>, long_files <n> <rule>
#   MARK <TODO|FIXME|HACK> <path> <line>
#   DEBUG <call> <path> <line>
#   PLACEHOLDER <word> <path> <line>
#   LONG <path> <lines>
#
# Exit codes: 0 scanned (whatever it found, none included); 1 the root cannot
# be read; 2 usage error; 3 no PATH given and the code root is unset or invalid
# (prints scanned_files 0 code_root unset, or code_root invalid for a bad
# engine.code_root). Reads only; never writes, never prompts.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
# Byte semantics for awk, sort and tolower.
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT_ARG=""; LONG=500; PATHS=""; EXCL=""; SKIP_TOP=""
NL='
'
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "code-markers: --root needs a value" >&2; exit 2; }; ROOT_ARG="$2"; shift 2 ;;
    --root=*) ROOT_ARG="${1#--root=}"; shift ;;
    --long) [ $# -ge 2 ] || { echo "code-markers: --long needs a number" >&2; exit 2; }; LONG="$2"; shift 2 ;;
    --exclude) [ $# -ge 2 ] || { echo "code-markers: --exclude needs a pattern" >&2; exit 2; }; EXCL="$EXCL$2$NL"; shift 2 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) echo "code-markers: unknown argument: $1 (try --help)" >&2; exit 2 ;;
    *) PATHS="$PATHS${1%/}$NL"; shift ;;
  esac
done
case "$LONG" in ''|*[!0-9]*) echo "code-markers: --long takes a whole number" >&2; exit 2 ;; esac

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "code-markers: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$HERE/../.." 2>/dev/null || { echo "code-markers: cannot reach the repo root" >&2; exit 1; }
fi

if [ -z "$PATHS" ]; then
  [ -f "$HERE/project-state.sh" ] || { echo "code-markers: $HERE/project-state.sh is missing; pass a PATH" >&2; exit 1; }
  CRROW=$(bash "$HERE/project-state.sh" --root . | awk -F'\t' '$1 == "code_root" { print $2 "\t" $3 }')
  CR=$(printf '%s' "$CRROW" | cut -f1)
  case "$(printf '%s' "$CRROW" | cut -f2)" in
    invalid:*)
      printf 'scanned_files\t0\tcode_root invalid\n'
      echo "code-markers: the code root is $(printf '%s' "$CRROW" | cut -f2); fix engine.code_root in project.yaml or pass a PATH" >&2
      exit 3 ;;
  esac
  if [ -z "$CR" ] || [ "$CR" = "-" ]; then
    printf 'scanned_files\t0\tcode_root unset\n'
    echo "code-markers: the code root is unset (no engine set and no single src/, Assets/ or Source/); pass a PATH" >&2
    exit 3
  fi
  PATHS="$CR$NL"
  # A root of `.` (a flat web game) leaves out the framework's own folders, and
  # find does not enter them. The same list as CODE_ROOT_SKIP in yaml-helper.sh.
  CODE_ROOT_SKIP=".claude .git production design docs tests studio-tests prototypes tools node_modules dist"
  [ "$CR" = "." ] && SKIP_TOP="$CODE_ROOT_SKIP"
fi

# src_find DIR -- the source files under DIR. For `.` with SKIP_TOP set, the
# folders it names at the top are pruned, not walked and filtered afterwards.
src_find() {
  local d
  set -- "$1" -type f \( -name '*.gd' -o -name '*.cs' -o -name '*.cpp' -o -name '*.cc' -o -name '*.c' \
    -o -name '*.h' -o -name '*.hpp' -o -name '*.rs' -o -name '*.py' -o -name '*.js' -o -name '*.ts' \
    -o -name '*.lua' -o -name '*.java' -o -name '*.kt' \)
  if [ "$1" = "." ] && [ -n "$SKIP_TOP" ]; then
    shift
    set -- \) -prune -o \( "$@" \) -print
    for d in $SKIP_TOP; do set -- -o -path "./$d" "$@"; done
    shift   # the first -o
    find . \( "$@" 2>/dev/null
  else
    find "$@" 2>/dev/null
  fi
}

LIST=""
while IFS= read -r p; do
  [ -n "$p" ] || continue
  # A Windows path's backslashes as slashes, so its file names read alike.
  case "$p" in [A-Za-z]:\\*) p=$(printf '%s' "$p" | sed 's|\\|/|g') ;; esac
  LIST="$LIST$(src_find "$p")$NL"
done <<EOF
$PATHS
EOF

SCOPE=$(printf '%s' "$PATHS" | awk 'NF' | tr '\n' ',' | sed 's/,$//')
# The file list goes to awk on stdin, never as arguments: a large project
# would pass thousands of paths, past the command-line limit of some systems.
printf '%s' "$LIST" | awk 'NF { sub(/^\.\//, ""); print }' | sort -u | \
LONG="$LONG" SCOPE="$SCOPE" EXCL="$EXCL" awk '
  # A shell pattern as an anchored regex; * and ? match across folders too.
  function pat2re(g,    i, c, out) {
    out = "^"
    for (i = 1; i <= length(g); i++) {
      c = substr(g, i, 1)
      if (c == "*") out = out ".*"
      else if (c == "?") out = out "."
      else if (index("\\.+()^$|{}", c) > 0) out = out "\\" c
      else out = out c
    }
    return out "$"
  }
  BEGIN {
    long = ENVIRON["LONG"] + 0
    nx = split(ENVIRON["EXCL"], xs, "\n")
    # Each listed file becomes an awk input file, unless an --exclude matches it.
    # "./" in front of a relative one keeps a name like x=1.gd from reading as
    # an awk assignment; an absolute one (/..., C:/...) is opened as it is.
    # The file count comes from the list: an empty file has no line for awk to
    # see, and it was still scanned.
    # The list arrives on /dev/stdin, named, so the main input stays the files: with
    # a bare getline, gawk read the first file as more of stdin and skipped its FNR 1.
    while ((getline f < "/dev/stdin") > 0) lst[++nlst] = f
    for (j = 1; j <= nlst; j++) {
      skip = 0
      for (i = 1; i <= nx; i++) if (xs[i] != "" && lst[j] ~ pat2re(xs[i])) skip = 1
      if (!skip) { ARGV[ARGC++] = (lst[j] ~ /^(\/|[A-Za-z]:)/) ? lst[j] : "./" lst[j]; nfiles++ }
    }
  }
  function ext(p,    e) { e = p; sub(/^.*\./, "", e); return tolower(e) }
  # The first debug call on the line for the file type, or "".
  function debug_call(s, e) {
    if (e == "gd") return m(s, "(^|[^A-Za-z0-9_.])(print_rich|print_debug|printraw|printt|prints|print)\\(")
    if (e == "cs") { if (match(s, /Debug\.Log[A-Za-z]*\(/)) return substr(s, RSTART, RLENGTH - 1); return m(s, "(^|[^A-Za-z0-9_.])print\\(") }
    if (e ~ /^(c|cc|cpp|h|hpp)$/) { if (match(s, /UE_LOG\(|AddOnScreenDebugMessage\(/)) return substr(s, RSTART, RLENGTH - 1); return m(s, "(^|[^A-Za-z0-9_.])printf\\(") }
    if (e == "js" || e == "ts") { if (match(s, /console\.(log|debug)\(/)) return substr(s, RSTART, RLENGTH - 1); return m(s, "(^|[^A-Za-z0-9_])debugger([^A-Za-z0-9_]|$)") }
    if (e == "py" || e == "lua") return m(s, "(^|[^A-Za-z0-9_.])print\\(")
    if (e == "rs") { if (match(s, /(eprintln|println|dbg)!\(/)) return substr(s, RSTART, RLENGTH - 1); return "" }
    if (e == "java" || e == "kt") { if (match(s, /System\.out\.print[a-z]*\(/)) return substr(s, RSTART, RLENGTH - 1); return m(s, "(^|[^A-Za-z0-9_.])println\\(") }
    return ""
  }
  # The name in a match of re, without the boundary character or the "(".
  function m(s, re,    t) {
    if (!match(s, re)) return ""
    t = substr(s, RSTART, RLENGTH); sub(/^[^A-Za-z_]/, "", t); sub(/[^A-Za-z_!]$/, "", t); sub(/\($/, "", t); return t
  }
  function flush() {
    if (path == "") return
    lines += FNRlast
    if (FNRlast > long) { nlong++; rows[++nr] = "LONG\t" path "\t" FNRlast }
    path = ""
  }
  FNR == 1 { flush(); path = FILENAME; sub(/^\.\//, "", path); e = ext(path) }
  {
    FNRlast = FNR
    s = $0; sub(/\r$/, "", s)
    # Markers: whole words in capitals; every one on the line counts.
    t = " " s " "
    while (match(t, /[^A-Za-z0-9_](TODO|FIXME|HACK)[^A-Za-z0-9_]/)) {
      w = substr(t, RSTART + 1, RLENGTH - 2); cnt[w]++
      rows[++nr] = "MARK\t" w "\t" path "\t" FNR
      t = substr(t, RSTART + RLENGTH - 1)
    }
    if ((c = debug_call(s, e)) != "") { ndebug++; rows[++nr] = "DEBUG\t" c "\t" path "\t" FNR }
    if (match(tolower(s), /placeholder|temp_|wip_/)) { nph++; rows[++nr] = "PLACEHOLDER\t" substr(tolower(s), RSTART, RLENGTH) "\t" path "\t" FNR }
  }
  END {
    flush()
    printf "scanned_files\t%d\t%s\nscanned_lines\t%d\n", nfiles, ENVIRON["SCOPE"], lines
    printf "todo\t%d\nfixme\t%d\nhack\t%d\ndebug\t%d\nplaceholder\t%d\n", cnt["TODO"], cnt["FIXME"], cnt["HACK"], ndebug, nph
    printf "long_files\t%d\tmore than %d lines\n", nlong, long
    for (i = 1; i <= nr; i++) print rows[i]
  }
'
exit 0
