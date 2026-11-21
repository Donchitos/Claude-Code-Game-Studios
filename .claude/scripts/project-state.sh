#!/usr/bin/env bash
# project-state.sh — the project facts several skills work out by hand: is an
# engine set, is there a concept, where is the code root, how many design,
# architecture and production files exist, what stage the project says it is
# at, and which phase the files on disk point to.
#
# Replaces the hand-run checks in /next-step (stage to phase, the artifact ladder),
# /start (engine, concept, code root, counts, origin), /adopt, /onboard,
# /day-one-patch, /project-stage-detect and /gate-check's read-back of the stage.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# `phase_inferred` is help's artifact ladder applied to the counts, printed with
# the rule that matched; whether it outranks `stage` is the calling skill's call.
#
# Usage: bash .claude/scripts/project-state.sh [--stage] [--root DIR]
#   --stage     print only the four stage rows (no file counts; cheap)
#   --root DIR  the project to read; defaults to the repo this script is in
#   -h, --help  this text
#
# Output: TSV, one `key<TAB>value<TAB>source` row per fact, in this order:
#   root, engine, code_root, source_files, concept, systems_index, gdd_files,
#   adr, story, prototype, sprint, milestone, origin_url,
#   stage_yaml, stage_txt, stage, phase, phase_inferred
# `-` means no value. Every row is always printed, so a missing row is a bug,
# never "nothing found".
#   engine          engine.name: project.local.yaml, then project.yaml, then
#                   the legacy `Engine:` line of .claude/docs/technical-preferences.md
#   code_root       the same answer and source label as resolve_code_root in
#                   .claude/hooks/yaml-helper.sh; never defaults to src. A bad
#                   engine.code_root prints `-` and `invalid: <reason>`
#   source_files    `unknown` when code_root is unset or invalid: unknown is not zero
#   stage_yaml      project.stage in project.yaml as written (even if invalid)
#   stage_txt       first non-blank line of production/stage.txt as written
#   stage           the resolved stage: a valid stage_yaml, else a valid
#                   stage_txt, else `-` (the resolve_setting order)
#   phase           the workflow-catalog phase key for `stage`
#
# Exit codes: 0 printed the facts; 1 the root is missing or unreadable;
# 2 usage error. Reads only; never writes, never prompts.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
# Byte semantics for awk, sort and grep. Under a UTF-8 locale gawk's substr()
# counts characters, so the 3-byte BOM test below would differ between awks.
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
STAGE_ONLY=0
ROOT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --stage) STAGE_ONLY=1; shift ;;
    --root)
      [ $# -ge 2 ] || { echo "project-state: --root needs a value" >&2; exit 2; }
      ROOT_ARG="$2"; shift 2 ;;
    --root=*) ROOT_ARG="${1#--root=}"; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "project-state: unknown argument: $1 (try --help)" >&2; exit 2 ;;
  esac
done

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "project-state: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$HERE/../.." 2>/dev/null || { echo "project-state: cannot reach the repo root" >&2; exit 1; }
fi
[ -f "$HERE/yaml-get.awk" ] || { echo "project-state: $HERE/yaml-get.awk is missing" >&2; exit 1; }
# `pwd -W` (Git Bash) prints C:/..., the form the other helpers report.
ROOT="$(pwd -W 2>/dev/null || pwd)"

# The seven stage names, in order. The same list as project.stage in
# yaml-helper.sh's _yaml_helper_enums; a value outside it is not a stage.
STAGES="Concept|Systems Design|Technical Setup|Pre-Production|Production|Polish|Release"

row() { printf '%s\t%s\t%s\n' "$1" "${2:--}" "${3:--}"; }

is_stage() {
  local v="$1" s oldIFS="$IFS"
  IFS='|'
  for s in $STAGES; do
    if [ "$v" = "$s" ]; then IFS="$oldIFS"; return 0; fi
  done
  IFS="$oldIFS"
  return 1
}

# yaml_get FILE DOTTED.PATH — print the scalar at the path, or nothing, with
# yaml-get.awk, the reader the bash/awk helpers share (its header has the rules).
yaml_get() {
  [ -f "$1" ] || return 0
  YG_PATH="$2" awk -f "$HERE/yaml-get.awk" "$1"
}

# First non-blank line of a plain-text mirror, CR and outer spaces removed,
# inner spaces kept ("Systems Design"), as yaml-helper.sh get_legacy_key reads it.
first_line() {
  [ -f "$1" ] || return 0
  awk '{ sub(/\r$/, ""); sub(/^[ \t]+/, ""); sub(/[ \t]+$/, "");
         if (length($0) > 0) { printf "%s", $0; exit } }' "$1"
}

stage_rows() {
  local sy st stage="" src="" phase=""
  sy=$(yaml_get project.yaml project.stage)
  st=$(first_line production/stage.txt)
  if [ -n "$sy" ] && is_stage "$sy"; then stage="$sy"; src="project.yaml"
  elif [ -n "$st" ] && is_stage "$st"; then stage="$st"; src="production/stage.txt"
  fi
  # next-step/SKILL.md Step 2's map from a stage name to a workflow-catalog phase key.
  case "$stage" in
    "Concept") phase="concept" ;;
    "Systems Design") phase="systems-design" ;;
    "Technical Setup") phase="technical-setup" ;;
    "Pre-Production") phase="pre-production" ;;
    "Production") phase="production" ;;
    "Polish") phase="polish" ;;
    "Release") phase="release" ;;
  esac
  if [ -f project.yaml ]; then row stage_yaml "$sy" project.yaml; else row stage_yaml "" absent; fi
  if [ -f production/stage.txt ]; then row stage_txt "$st" production/stage.txt; else row stage_txt "" absent; fi
  row stage "$stage" "${src:-unset}"
  row phase "$phase" "$( [ -n "$phase" ] && echo stage || echo unset )"
}

if [ "$STAGE_ONLY" = 1 ]; then
  stage_rows
  exit 0
fi

# count DIR FIND-ARGS... — files find matches under DIR; 0 when DIR is absent.
count() {
  local d="$1"; shift
  [ -d "$d" ] || { echo 0; return; }
  find "$d" "$@" 2>/dev/null | wc -l | tr -d ' '
}

# --- engine and code root: resolve_code_root's three steps -----------------
ENGINE=""; ESRC=""; CODE_ROOT=""; CSRC=""
if [ -f project.local.yaml ]; then
  ENGINE=$(yaml_get project.local.yaml engine.name)
  [ -n "$ENGINE" ] && { ESRC="project.local.yaml"; CSRC="project.local.yaml"; }
fi
if [ -z "$ENGINE" ] && [ -f project.yaml ]; then
  ENGINE=$(yaml_get project.yaml engine.name)
  [ -n "$ENGINE" ] && { ESRC="project.yaml"; CSRC="engine.name"; }
fi
LEGACY=".claude/docs/technical-preferences.md"
if [ -z "$ENGINE" ] && [ -f "$LEGACY" ]; then
  # The legacy `Engine:` line, bold or bulleted; `[TO BE CONFIGURED]` and any
  # other bracketed placeholder mean unset. The same pipeline as resolve_code_root.
  ENGINE=$(grep -iE '^[[:space:]]*[-*]?[[:space:]]*\*{0,2}Engine\*{0,2}[[:space:]]*:' "$LEGACY" 2>/dev/null \
           | head -1 | sed 's/.*://' | tr -d '\r' \
           | sed 's/^[[:space:]]*//; s/[[:space:]].*$//; s/\*//g')
  case "$ENGINE" in
    *"[TO BE CONFIGURED]"*|"["*) ENGINE="" ;;
  esac
  [ -n "$ENGINE" ] && { ESRC="$LEGACY"; CSRC="$LEGACY"; }
fi
# The code root each engine's own toolchain builds from, from the engine table
# (Godot src/, Unity Assets/, Unreal Source/, Web src/): the one reader,
# engine-row.awk, which resolve_code_root uses too.
if [ -n "$ENGINE" ] && [ -f "$HERE/engine-row.awk" ] && [ -f "$HERE/../engines/engines.tsv" ]; then
  CODE_ROOT=$(awk -F'\t' -v engine="$ENGINE" -v col=code_root -f "$HERE/engine-row.awk" "$HERE/../engines/engines.tsv")
fi
if [ -z "$CODE_ROOT" ]; then
  # No usable engine: believe the tree only when exactly one root is present.
  # Names are compared exactly against the listing, never with `[ -d Assets ]`,
  # which is also true for Godot's assets/ on a case-insensitive filesystem.
  n=0; found=""
  for d in */; do
    d="${d%/}"
    case "$d" in src|Assets|Source) found="$d"; n=$((n + 1)) ;; esac
  done
  if [ "$n" = 1 ]; then CODE_ROOT="$found"; CSRC="detected"; else CSRC=""; fi
fi

# resolve_code_root's step 0, applied last here so the engine row is unchanged:
# engine.code_root in project.yaml (never project.local.yaml) beats the engine's
# folder, and a bad value leaves the root unset with its reason, never the
# engine's folder. code_root_check is _yh_code_root_check in yaml-helper.sh,
# copied: keep the two the same.
CODE_ROOT_SKIP=".claude .git production design docs tests studio-tests prototypes tools node_modules dist"
CODE_ROOT_DENY=".claude .git production design docs tests studio-tests prototypes"
TAB=$(printf '\t')
code_root_check() {
  local base="$1" v="$2" rest seg parent out first lo d actual
  v=$(printf '%s' "$v" | tr -d '\r')
  case "$v" in ""|"["*|"~"|null|Null|NULL) return 0 ;; esac
  case "$v" in *\\*) printf "\tengine.code_root: use / not \\\\ in '%s'" "$v"; return 0 ;; esac
  case "$v" in /*|"~"*|[A-Za-z]:*) printf "\tengine.code_root: absolute path '%s'" "$v"; return 0 ;; esac
  while :; do case "$v" in */) v="${v%/}" ;; ./*) v="${v#./}" ;; *) break ;; esac; done
  [ -z "$v" ] && v="."
  [ "$v" = "." ] && { printf '.'; return 0; }
  case "/$v/" in */../*) printf "\tengine.code_root: '..' not allowed in '%s'" "$v"; return 0 ;; esac
  case "/$v/" in */./*|*//*) printf "\tengine.code_root: '%s' is not a plain folder path" "$v"; return 0 ;; esac
  first="${v%%/*}"; lo=$(printf '%s' "$first" | tr '[:upper:]' '[:lower:]')
  for d in $CODE_ROOT_DENY; do
    [ "$lo" = "$d" ] && { printf "\tengine.code_root: framework folder '%s'" "$first"; return 0; }
  done
  parent="$base"; rest="$v"; out=""
  while [ -n "$rest" ]; do
    seg="${rest%%/*}"
    if [ "$seg" = "$rest" ]; then rest=""; else rest="${rest#*/}"; fi
    if [ ! -d "$parent/$seg" ]; then
      # A case-sensitive disk (Linux, some macOS) has no "$seg" spelled with other capitals:
      # name the spelling on disk, as a case-insensitive disk does below.
      actual=$(ls -1A "$parent" 2>/dev/null | LC_ALL=C grep -Fxi -- "$seg" | head -1)
      if [ -n "$actual" ] && [ -d "$parent/$actual" ]; then
        printf "\tengine.code_root: spelled '%s' on disk, not '%s'" "${out:+$out/}$actual" "${out:+$out/}$seg"; return 0
      fi
      printf "\tengine.code_root: no folder '%s'" "${out:+$out/}$seg"; return 0
    fi
    if ! ls -1A "$parent" 2>/dev/null | LC_ALL=C grep -Fxq -- "$seg"; then
      actual=$(ls -1A "$parent" 2>/dev/null | LC_ALL=C grep -Fxi -- "$seg" | head -1)
      printf "\tengine.code_root: spelled '%s' on disk, not '%s'" "${out:+$out/}$actual" "${out:+$out/}$seg"; return 0
    fi
    out="${out:+$out/}$seg"; parent="$parent/$seg"
  done
  printf '%s' "$out"
}
CRERR=""
if [ -f project.yaml ]; then
  ov=""
  # Bash only until the key is seen: most projects never set it.
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in *code_root*:*) ov=1; break ;; esac
  done < project.yaml
  if [ -n "$ov" ]; then
    chk=$(code_root_check . "$(yaml_get project.yaml engine.code_root)")
    case "$chk" in
      "") ;;
      "$TAB"*) CODE_ROOT=""; CSRC="invalid"; CRERR="${chk#"$TAB"}" ;;
      *) CODE_ROOT="$chk"; CSRC="engine.code_root" ;;
    esac
  fi
fi

if [ -n "$CODE_ROOT" ]; then
  # The source extensions detect-gaps.sh check 1 counts. A root of `.` (a flat
  # web game) does not enter the CODE_ROOT_SKIP folders at the top.
  set -- -type f \( -name '*.gd' -o -name '*.cs' -o -name '*.cpp' \
         -o -name '*.c' -o -name '*.h' -o -name '*.hpp' -o -name '*.rs' -o -name '*.py' \
         -o -name '*.js' -o -name '*.ts' \)
  if [ "$CODE_ROOT" = "." ]; then
    set -- \) -prune -o \( "$@" \) -print
    for d in $CODE_ROOT_SKIP; do set -- -o -path "./$d" "$@"; done
    shift
    SRC_FILES=$(find . \( "$@" 2>/dev/null | wc -l | tr -d ' ')
  else
    SRC_FILES=$(count "$CODE_ROOT" "$@")
  fi
  SSRC="$CODE_ROOT"
elif [ "$CSRC" = invalid ]; then
  SRC_FILES="unknown"; SSRC="code_root invalid"
else
  SRC_FILES="unknown"; SSRC="code_root unset"
fi

CONCEPT=""
for f in design/gdd/game-concept.md design/game-brief.md; do
  [ -f "$f" ] && { CONCEPT="$f"; break; }
done
SYSIDX=""
[ -f design/gdd/systems-index.md ] && SYSIDX="design/gdd/systems-index.md"

GDD=$(count design/gdd -maxdepth 1 -type f -name '*.md')
ADR=$(count docs/architecture -maxdepth 1 -type f -name 'adr-*.md')
STORY=$(count production/epics -type f -name 'story-*.md')
PROTO=$(count prototypes -mindepth 1 -maxdepth 1 -type d)
SPRINT=$(count production/sprints -maxdepth 1 -type f -name '*.md')
MILE=$(count production/milestones -maxdepth 1 -type f -name '*.md')

ORIGIN=""
if [ -f .git/config ]; then
  ORIGIN=$(awk '
    { sub(/\r$/, "") }
    /^[ \t]*\[/ { inorigin = ($0 ~ /^[ \t]*\[remote "origin"\]/); next }
    inorigin && /^[ \t]*url[ \t]*=/ { sub(/^[ \t]*url[ \t]*=[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
  ' .git/config)
fi

row root "$ROOT" -
row engine "$ENGINE" "${ESRC:-unset}"
if [ "$CSRC" = invalid ]; then row code_root "" "invalid: $CRERR"; else row code_root "$CODE_ROOT" "${CSRC:-unset}"; fi
row source_files "$SRC_FILES" "$SSRC"
row concept "$CONCEPT" "$( [ -n "$CONCEPT" ] && echo found || echo absent )"
row systems_index "$SYSIDX" "$( [ -n "$SYSIDX" ] && echo found || echo absent )"
row gdd_files "$GDD" "design/gdd/*.md"
row adr "$ADR" "docs/architecture/adr-*.md"
row story "$STORY" "production/epics/**/story-*.md"
row prototype "$PROTO" "prototypes/*/"
row sprint "$SPRINT" "production/sprints/*.md"
row milestone "$MILE" "production/milestones/*.md"
row origin_url "$ORIGIN" "$( [ -f .git/config ] && echo .git/config || echo absent )"
stage_rows

# next-step/SKILL.md Step 2's ladder, most advanced match first. 10 is next-step's own
# threshold for "the code root has real code in it".
SRC_MIN=10
NOTE=""
[ "$SRC_FILES" = "unknown" ] && NOTE=";source_files unknown"
if [ "$SRC_FILES" != "unknown" ] && [ "$SRC_FILES" -ge "$SRC_MIN" ]; then
  row phase_inferred production "source_files>=$SRC_MIN"
elif [ "$STORY" -ge 1 ]; then row phase_inferred pre-production "story>=1$NOTE"
elif [ "$ADR" -ge 1 ]; then row phase_inferred technical-setup "adr>=1$NOTE"
elif [ -n "$SYSIDX" ]; then row phase_inferred systems-design "systems_index$NOTE"
elif [ -n "$CONCEPT" ]; then row phase_inferred concept "concept$NOTE"
else row phase_inferred concept "nothing$NOTE"
fi
exit 0
