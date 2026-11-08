#!/usr/bin/env bash
# inputs-check.sh — FOUND / EMPTY / ABSENT for each input a skill declares,
# so "Insufficient input — check this before producing any report" is one
# call instead of a Glob and a Read per input.
#
# Replaces the hand-run FOUND/ABSENT lists a skill builds from a Glob and a
# Read per input.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# Which inputs are required, and whether an ABSENT one makes a section
# NOT ASSESSED, is the calling skill's call. The exit code never says.
#
# Usage: bash .claude/scripts/inputs-check.sh [--root DIR] [--from FILE|-] [SPEC...]
#   SPEC        a path relative to the root: a file, a folder, or a glob.
#               `*` and `?` stay inside one folder, `**/` spans folders
#               (bash 3.2 has no globstar, so globs go through find), and a
#               trailing `/` matches folders instead of files. `*` matches
#               dot-files too. A backslash is read as `/` (design\gdd\*.md is
#               design/gdd/*.md); the row keeps the spec as it was given.
#   --from F    read more specs from F, one per line (`-` is stdin); blank
#               lines and lines starting with `#` are skipped
#   --root DIR  the project to check; defaults to the repo this script is in
#   -h, --help  this text
#
# Output: TSV. Four count rows first, so a reader knows how many specs were
# checked before reading any of them, then one row per spec in the order given:
#   inputs <n> / found <n> / empty <n> / absent <n>
#   <STATUS> <spec> <matches> <first match, or ->
# STATUS:
#   FOUND   at least one match holds something other than whitespace
#   EMPTY   matches exist but every one is blank: a zero-byte or
#           whitespace-only file, or a folder with no such file in it.
#           A file that exists is not yet data.
#   ABSENT  nothing matched
#
# Exit codes: 0 checked every spec (whatever they found); 1 the root or the
# --from file cannot be read; 2 usage error (no spec, an absolute path, a tab
# in a spec, an unknown flag). Reads only; never writes, never prompts.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
# Byte semantics: grep's [:space:] and sort order must not depend on the
# user's locale, or two machines would sort and classify one tree differently.
LC_ALL=C
export LC_ALL

TAB=$(printf '\t')
NL='
'
SPECS=""
ROOT_ARG=""
FROM=""
add_spec() { SPECS="$SPECS$1$NL"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --root|--from)
      [ $# -ge 2 ] || { echo "inputs-check: $1 needs a value" >&2; exit 2; }
      if [ "$1" = "--root" ]; then ROOT_ARG="$2"; else FROM="$2"; fi
      shift 2 ;;
    --root=*) ROOT_ARG="${1#--root=}"; shift ;;
    --from=*) FROM="${1#--from=}"; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --) shift; while [ $# -gt 0 ]; do add_spec "$1"; shift; done ;;
    -?*) echo "inputs-check: unknown argument: $1 (try --help)" >&2; exit 2 ;;
    *) add_spec "$1"; shift ;;
  esac
done

if [ -n "$FROM" ]; then
  if [ "$FROM" = "-" ]; then FROM_TEXT=$(cat)
  elif [ -f "$FROM" ]; then FROM_TEXT=$(cat "$FROM")
  else echo "inputs-check: cannot read --from file $FROM" >&2; exit 1
  fi
  FROM_SPECS=$(printf '%s\n' "$FROM_TEXT" | awk '{ sub(/\r$/, ""); sub(/^[ \t]+/, ""); sub(/[ \t]+$/, "");
    if ($0 != "" && substr($0, 1, 1) != "#") print }')
  [ -n "$FROM_SPECS" ] && SPECS="$SPECS$FROM_SPECS$NL"
fi

[ -n "$SPECS" ] || { echo "inputs-check: no input spec given (try --help)" >&2; exit 2; }

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "inputs-check: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$(dirname "$0")/../.." 2>/dev/null || { echo "inputs-check: cannot reach the repo root" >&2; exit 1; }
fi

# Validate every spec before checking any, so a usage error prints no rows.
# slashes SPEC — the spec with a backslash read as `/` (a Windows spec).
slashes() {
  case "$1" in *\\*) printf '%s' "$1" | tr '\\' '/' ;; *) printf '%s' "$1" ;; esac
}

while IFS= read -r spec; do
  [ -z "$spec" ] && continue
  case "$(slashes "$spec")" in
    /*|[A-Za-z]:*) echo "inputs-check: specs are relative to the root, got $spec" >&2; exit 2 ;;
    *"$TAB"*) echo "inputs-check: a spec cannot contain a tab (the output is TSV)" >&2; exit 2 ;;
  esac
done <<EOF
$SPECS
EOF

# has_content PATH — a file with a non-whitespace byte, or a folder holding one.
has_content() {
  if [ -f "$1" ]; then
    grep -q '[^[:space:]]' "$1" 2>/dev/null
    return
  fi
  [ -d "$1" ] || return 1
  find "$1" -type f 2>/dev/null | while IFS= read -r f; do
    if grep -q '[^[:space:]]' "$f" 2>/dev/null; then echo y; break; fi
  done | grep -q y
}

# glob_matches SPEC — every path under the root the glob names, sorted.
glob_matches() {
  local g="$1" type=f base
  case "$g" in */) type=d; g="${g%/}" ;; esac
  # The base folder is the part before the first component holding a glob
  # character; find starts there so a glob never walks the whole project.
  base=$(printf '%s\n' "$g" | awk -F/ '{ b = ""; for (i = 1; i < NF; i++) {
           if (index($i, "*") || index($i, "?") || index($i, "[")) break
           b = (b == "") ? $i : b "/" $i } print (b == "") ? "." : b }')
  [ -d "$base" ] || return 0
  find "$base" -type "$type" 2>/dev/null | GLOB="$g" awk '
    function g2re(g,    i, n, c, j, cls, out) {
      out = "^"; n = length(g); i = 1
      while (i <= n) {
        c = substr(g, i, 1)
        if (c == "*") {
          if (substr(g, i + 1, 1) == "*") {
            if (substr(g, i + 2, 1) == "/") { out = out "(.*/)?"; i += 3; continue }
            out = out ".*"; i += 2; continue
          }
          out = out "[^/]*"
        } else if (c == "?") out = out "[^/]"
        else if (c == "[" && (j = index(substr(g, i + 1), "]")) > 1) {
          cls = substr(g, i + 1, j - 1)
          if (substr(cls, 1, 1) == "!") cls = "^" substr(cls, 2)
          out = out "[" cls "]"; i += j + 1; continue
        } else if (index("\\.+()^$|{}[]", c) > 0) out = out "\\" c
        else out = out c
        i++
      }
      return out "$"
    }
    BEGIN { re = g2re(ENVIRON["GLOB"]) }
    { sub(/^\.\//, "") }
    $0 ~ re
  ' | sort
}

ROWS=""; N=0; NF_=0; NE=0; NA=0
while IFS= read -r spec; do
  [ -z "$spec" ] && continue
  # What is matched: a Windows spec's backslashes as slashes (find prints
  # slashes, so design\gdd\*.md matched nothing), then ./ dropped.
  pat=$(slashes "$spec"); pat="${pat#./}"
  spec="${spec#./}"; spec="${spec#.\\}"
  N=$((N + 1))
  case "$pat" in
    *[][*?]*) matches=$(glob_matches "$pat") ;;
    */) if [ -d "${pat%/}" ]; then matches="${pat%/}"; else matches=""; fi ;;
    *) if [ -e "${pat%/}" ]; then matches="${pat%/}"; else matches=""; fi ;;
  esac
  if [ -z "$matches" ]; then
    NA=$((NA + 1)); ROWS="${ROWS}ABSENT$TAB$spec${TAB}0$TAB-$NL"
    continue
  fi
  count=0; first=""; status=EMPTY
  while IFS= read -r m; do
    count=$((count + 1))
    [ -z "$first" ] && first="$m"
    [ "$status" = EMPTY ] && has_content "$m" && status=FOUND
  done <<EOF
$matches
EOF
  # A plain folder spec counts the files inside it, not the folder itself.
  if [ -d "$matches" ] && [ "$matches" = "${pat%/}" ]; then
    count=$(find "$matches" -type f 2>/dev/null | wc -l | tr -d ' ')
    first=$(find "$matches" -type f 2>/dev/null | sort | head -1)
  fi
  if [ "$status" = FOUND ]; then NF_=$((NF_ + 1)); else NE=$((NE + 1)); fi
  ROWS="$ROWS$status$TAB$spec$TAB$count$TAB${first:--}$NL"
done <<EOF
$SPECS
EOF

printf 'inputs\t%s\nfound\t%s\nempty\t%s\nabsent\t%s\n' "$N" "$NF_" "$NE" "$NA"
printf '%s' "$ROWS"
exit 0
