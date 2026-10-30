#!/usr/bin/env bash
# set-stage.sh — write the project stage to project.yaml and the legacy
# production/stage.txt, read both back, and say whether they agree.
#
# Replaces the hand-run stage write: the primary write to project.yaml, the
# legacy fallback write to production/stage.txt, and the check that both
# landed. /start and /gate-check call it.
#
# THE ASK STAYS IN THE SKILL. A stage moves only on a /gate-check PASS (or a
# CONCERNS whose risks the user accepted) with the user's yes; this script
# never decides that and never prompts. Run it after the yes.
#
# Usage: bash .claude/scripts/set-stage.sh <Stage> [--dry-run] [--root DIR]
#   <Stage>     one of: Concept, Systems Design, Technical Setup,
#               Pre-Production, Production, Polish, Release (quote the
#               two-word names)
#   --dry-run   say what would change; write nothing
#   --root DIR  the project to write; defaults to the repo this script is in
#   -h, --help  this text
#
# What it writes in project.yaml (comments, other keys and line endings kept):
#   - a `stage:` line under `project:` gets the new value, keeping its quotes
#     and any inline comment; when project.stage is set more than once, the
#     last one is edited, because that is the one every reader uses
#   - a `project:` block with no `stage:` gets one as its first line
#   - no `project:` block: one is added after the `framework:` block, or at the
#     end of the file when there is no `framework:` block
#   - no project.yaml: it is created from /gate-check's minimal template
# production/stage.txt gets the stage name with no trailing newline.
# A file already holding the stage is left byte-for-byte alone. Both new texts
# are made in full and the old files backed up before either target is changed.
# A failed second write restores the first, so a call leaves both stages new or
# both as they were. Targets are copied over in place, so they keep their modes,
# symlinks and hard links.
#
# Output: TSV.
#   project.yaml <replaced|inserted|added-block|created|unchanged> <line or ->
#   stage.txt    <written|unchanged> -
#   stage_yaml   <value read back> project.yaml
#   stage_txt    <value read back> production/stage.txt
#
# Exit codes: 0 both files hold the stage; 1 cannot read the root, write a file,
# or find project-state.sh or the framework version; 2 usage error; 3 <Stage>
# is not a stage name; 4 the two files disagree after writing; 5 project.yaml
# has a layout this script will not edit (`project:` as a one-line value).
# A 3 or a 5 writes nothing.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
# Byte semantics for awk: the BOM and CR tests below compare bytes.
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
STAGE=""
DRY=0
ROOT_ARG=""
Y_NEW=""; Y_OLD=""; T_NEW=""; T_OLD=""
cleanup_temps() {
  [ -n "$Y_NEW" ] && rm -f "$Y_NEW"
  [ -n "$Y_OLD" ] && rm -f "$Y_OLD"
  [ -n "$T_NEW" ] && rm -f "$T_NEW"
  [ -n "$T_OLD" ] && rm -f "$T_OLD"
  return 0
}
trap cleanup_temps 0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --root)
      [ $# -ge 2 ] || { echo "set-stage: --root needs a value" >&2; exit 2; }
      ROOT_ARG="$2"; shift 2 ;;
    --root=*) ROOT_ARG="${1#--root=}"; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) echo "set-stage: unknown argument: $1 (try --help)" >&2; exit 2 ;;
    *)
      [ -z "$STAGE" ] || { echo "set-stage: one stage only (quote two-word names: \"Systems Design\")" >&2; exit 2; }
      STAGE="$1"; shift ;;
  esac
done
[ -n "$STAGE" ] || { echo "set-stage: no stage given (try --help)" >&2; exit 2; }

# The seven stage names: project.stage's enum in yaml-helper.sh.
STAGES="Concept|Systems Design|Technical Setup|Pre-Production|Production|Polish|Release"
ok=1; oldIFS="$IFS"; IFS='|'
for s in $STAGES; do [ "$STAGE" = "$s" ] && ok=0; done
IFS="$oldIFS"
if [ "$ok" != 0 ]; then
  echo "set-stage: '$STAGE' is not a stage. Allowed: $STAGES" >&2
  exit 3
fi

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "set-stage: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$HERE/../.." 2>/dev/null || { echo "set-stage: cannot reach the repo root" >&2; exit 1; }
fi
[ -f "$HERE/project-state.sh" ] || { echo "set-stage: $HERE/project-state.sh is missing; cannot read the stage back" >&2; exit 1; }

# publish_file SOURCE TARGET — copy the bytes over TARGET in place. This keeps
# its mode and keeps a symlink/hard link in place; a rename would replace them.
publish_file() {
  cat "$1" > "$2" 2>/dev/null
}

# restore_file TARGET BACKUP EXISTED — return TARGET to its pre-call contents.
# A failed open leaves the old bytes in place, so only write when they differ.
restore_file() {
  if [ "$3" = 1 ]; then
    if [ -f "$1" ] && cmp -s "$2" "$1"; then return 0; fi
    cat "$2" > "$1" 2>/dev/null
  else
    [ ! -e "$1" ] || rm -f "$1" 2>/dev/null
  fi
}

# --- project.yaml ----------------------------------------------------------
Y_ACTION=""; Y_LINE="-"; Y_NEW=""
if [ ! -f project.yaml ]; then
  Y_ACTION="created"
  # The framework version these scripts ship with; update-check.sh holds the
  # one copy a release bumps.
  VERSION=$(sed -n 's/^UPDATE_CHECK_VERSION="\([^"]*\)".*/\1/p' "$HERE/../hooks/update-check.sh" 2>/dev/null | head -1)
  [ -n "$VERSION" ] || { echo "set-stage: no framework version in $HERE/../hooks/update-check.sh; project.yaml not created" >&2; exit 1; }
  Y_NEW=$(mktemp "./.ccgs-stage-XXXXXX" 2>/dev/null) || { echo "set-stage: cannot create a temporary file in $(pwd)" >&2; exit 1; }
  # /gate-check's minimal template (references/6-update-stage.md, 6.1).
  {
    echo "# CCGS project configuration — single source of truth for project settings."
    echo "# Schema: grep the \`## <key>\` section of .claude/docs/effects-map.md —"
    echo "# it is ~31k tokens whole, ~900 per section. Do not open it entire."
    echo ""
    echo "schema_version: 1"
    echo ""
    echo "framework:"
    echo "  version: $VERSION"
    echo "  last_upgraded: $(date +%Y-%m-%d)"
    echo ""
    echo "project:"
    echo "  stage: $STAGE"
  } > "$Y_NEW"
else
  Y_NEW=$(mktemp "./.ccgs-stage-XXXXXX" 2>/dev/null) || { echo "set-stage: cannot create a temporary file in $(pwd)" >&2; exit 1; }
  Y_STATUS="$Y_NEW.status"
  # Parse every line the way project-state.sh's yaml_get does, note where
  # project.stage and the `project:` and `framework:` blocks are, then print
  # the file with one line replaced or a few lines inserted.
  STAGE="$STAGE" STATUS="$Y_STATUS" awk '
    # opens(s, n): when line s (at indent n, its leading spaces removed) opens
    # a block scalar (a value of | or >, with any indicators), the indent its
    # text must exceed; else -1. Its text is never a key, as in yaml-get.awk.
    function opens(s, n,    r, p, v) {
      r = s
      if (r == "-" || substr(r, 1, 2) == "- ") {
        r = substr(r, 2); sub(/^ +/, "", r)
        if (r ~ /^[|>][-+0-9]*[ \t]*(#.*)?$/) return n
        n = n + length(s) - length(r)
      }
      if (r == "" || r ~ /^[:# \t]/) return -1
      p = index(r, ":"); if (p == 0) return -1
      v = substr(r, p + 1); sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      return (v ~ /^[|>][-+0-9]*[ \t]*(#.*)?$/) ? n : -1
    }
    # Git for Windows gawk reads files in text mode and drops the CR of a CRLF
    # line; BINMODE 3 keeps every byte. Other awks treat it as a plain variable.
    BEGIN { BINMODE = 3 }
    { raw[NR] = $0 }
    END {
      stage = ENVIRON["STAGE"]; depth = 0; nst = 0; laststage = 0; blk = -1
      projkind = ""; projline = 0; fwline = 0; crlf = (raw[1] ~ /\r$/)
      for (L = 1; L <= NR; L++) {
        line = raw[L]
        # "\357\273\277" is the UTF-8 byte-order mark.
        if (L == 1 && substr(line, 1, 3) == "\357\273\277") line = substr(line, 4)
        sub(/\r$/, "", line)
        n = 0
        while (substr(line, n + 1, 1) == " ") n++
        s = substr(line, n + 1)
        t = s
        sub(/^[ \t]+/, "", t)
        kind[L] = "other"
        if (t == "") { kind[L] = "blank"; continue }
        if (substr(t, 1, 1) == "#") { kind[L] = "comment"; continue }
        # A block scalar text line stays "other": content of the block above it.
        if (blk >= 0) { if (n > blk) continue; blk = -1 }
        blk = opens(s, n)
        c = substr(s, 1, 1)
        if (c == ":" || c == "#" || c == "\t") continue
        p = index(s, ":")
        if (p == 0) continue
        key = substr(s, 1, p - 1)
        sub(/[ \t]+$/, "", key)
        v = substr(s, p + 1)
        sub(/^[ \t]+/, "", v)
        sub(/[ \t]+$/, "", v)
        q = substr(v, 1, 1)
        if (q == "#") v = ""
        else if (q == "\"" || q == "\047") {
          rest = substr(v, 2); e = index(rest, q)
          v = (e > 0) ? substr(rest, 1, e - 1) : rest
        } else {
          h = index(v, " #")
          if (h > 0) { v = substr(v, 1, h - 1); sub(/[ \t]+$/, "", v) }
        }
        while (depth > 0 && ind[depth] >= n) depth--
        full = ""
        for (i = 1; i <= depth; i++) full = full keys[i] "."
        full = full key
        kind[L] = "key"; indent[L] = n; top[L] = (depth == 0)
        if (v == "") { depth++; ind[depth] = n; keys[depth] = key }
        if (full == "project") {
          projkind = (v == "") ? "map" : "scalar"; projline = L
          # A one-line value replaces the block, and the stage inside it.
          if (v != "") laststage = 0
        }
        if (full == "framework" && v == "") fwline = L
        if (full == "project.stage") {
          nst++; stlines = stlines (nst > 1 ? "," : "") L
          laststage = L; curval = v; colon[L] = n + p
        }
      }
      eol = crlf ? "\r" : ""
      action = ""; at = 0
      if (projkind == "scalar") {
        print "unsupported\t" projline > ENVIRON["STATUS"]; exit 0
      }
      if (laststage > 0) {
        at = laststage
        if (curval == stage) action = "unchanged"
        else {
          action = "replaced"
          line = raw[at]; cr = (line ~ /\r$/); sub(/\r$/, "", line)
          pre = substr(line, 1, colon[at]); after = substr(line, colon[at] + 1)
          lead = after; sub(/[^ \t].*$/, "", lead); if (lead == "") lead = " "
          a = after; sub(/^[ \t]+/, "", a)
          q = substr(a, 1, 1)
          if (a == "") tail = ""
          else if (q == "#") tail = " " a
          else if (q == "\"" || q == "\047") {
            e = index(substr(a, 2), q)
            tail = (e > 0) ? substr(a, e + 2) : ""
            stage = q stage q
          } else {
            # Keep an inline comment and the spaces before it; drop the old value.
            h = index(a, " #"); tail = ""
            if (h > 0) { tok = substr(a, 1, h - 1); sub(/[ \t]+$/, "", tok); tail = substr(a, length(tok) + 1) }
          }
          raw[at] = pre lead stage tail (cr ? "\r" : "")
        }
      } else if (projkind == "map") {
        action = "inserted"; at = projline
        ci = indent[projline] + 2
        for (L = projline + 1; L <= NR; L++) {
          if (kind[L] != "key") continue
          if (indent[L] > indent[projline]) ci = indent[L]
          break
        }
        pad = ""; for (i = 0; i < ci; i++) pad = pad " "
        ins[projline] = pad "stage: " stage eol
        at = projline + 1
      } else {
        action = "added-block"
        if (fwline > 0) {
          last = fwline
          for (L = fwline + 1; L <= NR; L++) {
            if (kind[L] == "key" && top[L]) break
            if (kind[L] != "blank" && kind[L] != "comment") last = L
          }
        } else last = NR
        sep = (last > 0 && kind[last] != "blank") ? eol "\n" : ""
        ins[last] = sep "project:" eol "\n  stage: " stage eol
        at = last + (sep != "" ? 3 : 2)
      }
      for (L = 1; L <= NR; L++) {
        print raw[L]
        if (L in ins) print ins[L]
      }
      if (NR == 0 && (0 in ins)) print ins[0]
      printf "%s\t%s\t%s\n", action, at, (nst > 1 ? stlines : "") > ENVIRON["STATUS"]
    }
  ' project.yaml > "$Y_NEW"
  IFS="$(printf '\t')" read -r Y_ACTION Y_LINE Y_DUPS < "$Y_STATUS" 2>/dev/null
  rm -f "$Y_STATUS"
  if [ "${Y_ACTION:-}" = "unsupported" ]; then
    rm -f "$Y_NEW"
    echo "set-stage: project.yaml line $Y_LINE sets \`project:\` to a one-line value, so it has no \`stage:\` to edit." >&2
    echo "  Expected layout: a block, \`project:\` on its own line and \`  stage: <Stage>\` under it. Nothing was written." >&2
    exit 5
  fi
  [ -n "${Y_ACTION:-}" ] || { rm -f "$Y_NEW"; echo "set-stage: could not parse project.yaml; nothing was written" >&2; exit 1; }
  if [ -n "${Y_DUPS:-}" ]; then
    echo "set-stage: project.stage is set more than once in project.yaml (lines $Y_DUPS); line $Y_LINE is the one readers use, so that is the one edited" >&2
  fi
  [ "$Y_ACTION" = "unchanged" ] && { rm -f "$Y_NEW"; Y_NEW=""; }
fi

# --- production/stage.txt --------------------------------------------------
T_ACTION="written"
if [ -f production/stage.txt ] && printf '%s' "$STAGE" | cmp -s - production/stage.txt; then
  T_ACTION="unchanged"
fi

if [ "$DRY" = 1 ]; then
  [ -n "$Y_NEW" ] && rm -f "$Y_NEW"
  printf 'project.yaml\t%s\t%s\nstage.txt\t%s\t-\n' "$Y_ACTION" "$Y_LINE" "$T_ACTION"
  exit 0
fi

Y_EXISTED=0
[ -f project.yaml ] && Y_EXISTED=1
T_EXISTED=0
[ -f production/stage.txt ] && T_EXISTED=1

# Prepare both outputs and backups before changing either target. The stage
# file goes first: if its write fails, project.yaml has not been touched.
if [ "$T_ACTION" = "written" ]; then
  mkdir -p production 2>/dev/null || { echo "set-stage: cannot create production/" >&2; exit 1; }
  T_NEW=$(mktemp "production/.ccgs-stage-XXXXXX" 2>/dev/null) || { echo "set-stage: cannot create a temporary file in production/" >&2; exit 1; }
  printf '%s' "$STAGE" > "$T_NEW" || { rm -f "$T_NEW"; echo "set-stage: could not write production/stage.txt" >&2; exit 1; }
  if [ "$T_EXISTED" = 1 ]; then
    T_OLD=$(mktemp "production/.ccgs-stage-XXXXXX" 2>/dev/null) || { echo "set-stage: cannot back up production/stage.txt" >&2; exit 1; }
    cat production/stage.txt > "$T_OLD" 2>/dev/null || { echo "set-stage: cannot back up production/stage.txt" >&2; exit 1; }
  fi
fi
if [ -n "$Y_NEW" ] && [ "$Y_EXISTED" = 1 ]; then
  Y_OLD=$(mktemp "./.ccgs-stage-XXXXXX" 2>/dev/null) || { echo "set-stage: cannot back up project.yaml" >&2; exit 1; }
  cat project.yaml > "$Y_OLD" 2>/dev/null || { echo "set-stage: cannot back up project.yaml" >&2; exit 1; }
fi

if [ "$T_ACTION" = "written" ]; then
  if ! publish_file "$T_NEW" production/stage.txt; then
    if restore_file production/stage.txt "$T_OLD" "$T_EXISTED"; then
      echo "set-stage: could not write production/stage.txt; both stage files were left unchanged" >&2
    else
      echo "set-stage: could not write production/stage.txt or restore it; project.yaml was not changed" >&2
    fi
    exit 1
  fi
fi

if [ -n "$Y_NEW" ] && ! publish_file "$Y_NEW" project.yaml; then
  echo "set-stage: could not write project.yaml; rolling back production/stage.txt" >&2
  ROLLBACK_OK=1
  restore_file project.yaml "$Y_OLD" "$Y_EXISTED" || ROLLBACK_OK=0
  if [ "$T_ACTION" = "written" ]; then
    restore_file production/stage.txt "$T_OLD" "$T_EXISTED" || ROLLBACK_OK=0
  fi
  if [ "$ROLLBACK_OK" = 0 ]; then
    echo "set-stage: rollback could not restore every stage file; inspect both before going on" >&2
  else
    echo "set-stage: both stage files were restored to their previous values" >&2
  fi
  exit 1
fi

cleanup_temps
Y_NEW=""; Y_OLD=""; T_NEW=""; T_OLD=""

# --- read back through the one reader -------------------------------------
BACK=$(bash "$HERE/project-state.sh" --stage --root .)
SY=$(printf '%s\n' "$BACK" | awk -F'\t' '$1 == "stage_yaml" { print $2 }')
ST=$(printf '%s\n' "$BACK" | awk -F'\t' '$1 == "stage_txt" { print $2 }')
printf 'project.yaml\t%s\t%s\nstage.txt\t%s\t-\n' "$Y_ACTION" "$Y_LINE" "$T_ACTION"
printf 'stage_yaml\t%s\tproject.yaml\nstage_txt\t%s\tproduction/stage.txt\n' "$SY" "$ST"
if [ "$SY" != "$STAGE" ] || [ "$ST" != "$STAGE" ]; then
  echo "set-stage: after writing, project.yaml reads '$SY' and production/stage.txt reads '$ST', not '$STAGE'." >&2
  echo "  A split stage misleads every reader; fix the file that differs before going on." >&2
  exit 4
fi
exit 0
