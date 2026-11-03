#!/usr/bin/env bash
# project-state.sh — the project facts several skills work out by hand: is an
# engine set, is there a concept, where is the code root, how many design,
# architecture and production files exist, what stage the project says it is
# at, and which phase the files on disk point to.
#
# Replaces the hand-run checks in /help (stage to phase, the artifact ladder),
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
#                   .claude/hooks/yaml-helper.sh; never defaults to src
#   source_files    `unknown` when code_root is unset: unknown is not zero
#   origin_url      raw origin URL from .git/config; a .git pointer file uses
#                   Git to locate the readable config, reported as its source
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
  # help/SKILL.md Step 2's map from a stage name to a workflow-catalog phase key.
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
# The code root each engine's own toolchain builds from
# (.claude/docs/directory-structure.md): Godot src/, Unity Assets/, Unreal Source/.
case "$(printf '%s' "$ENGINE" | tr '[:upper:]' '[:lower:]')" in
  godot) CODE_ROOT="src" ;;
  unity) CODE_ROOT="Assets" ;;
  unreal*) CODE_ROOT="Source" ;;
esac
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

if [ -n "$CODE_ROOT" ]; then
  # The source extensions detect-gaps.sh check 1 counts.
  SRC_FILES=$(count "$CODE_ROOT" -type f \( -name '*.gd' -o -name '*.cs' -o -name '*.cpp' \
              -o -name '*.c' -o -name '*.h' -o -name '*.hpp' -o -name '*.rs' -o -name '*.py' \
              -o -name '*.js' -o -name '*.ts' \))
  SSRC="$CODE_ROOT"
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

ORIGIN=""; ORIGIN_CONFIG=".git/config"
if [ -f .git ] && command -v git >/dev/null 2>&1; then
  ORIGIN_CONFIG=$(
    # --root selected this cwd. A caller's repository variables must not
    # redirect this metadata lookup to a different checkout.
    unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE \
          GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES \
          GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM
    command git rev-parse --git-path config 2>/dev/null
  ) || ORIGIN_CONFIG=""
fi
if [ -f "$ORIGIN_CONFIG" ]; then
  ORIGIN=$(awk '
    { sub(/\r$/, "") }
    /^[ \t]*\[/ { inorigin = ($0 ~ /^[ \t]*\[remote "origin"\]/); next }
    inorigin && /^[ \t]*url[ \t]*=/ { sub(/^[ \t]*url[ \t]*=[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
  ' "$ORIGIN_CONFIG")
fi

row root "$ROOT" -
row engine "$ENGINE" "${ESRC:-unset}"
row code_root "$CODE_ROOT" "${CSRC:-unset}"
row source_files "$SRC_FILES" "$SSRC"
row concept "$CONCEPT" "$( [ -n "$CONCEPT" ] && echo found || echo absent )"
row systems_index "$SYSIDX" "$( [ -n "$SYSIDX" ] && echo found || echo absent )"
row gdd_files "$GDD" "design/gdd/*.md"
row adr "$ADR" "docs/architecture/adr-*.md"
row story "$STORY" "production/epics/**/story-*.md"
row prototype "$PROTO" "prototypes/*/"
row sprint "$SPRINT" "production/sprints/*.md"
row milestone "$MILE" "production/milestones/*.md"
row origin_url "$ORIGIN" "$( [ -f "$ORIGIN_CONFIG" ] && printf '%s' "$ORIGIN_CONFIG" || echo absent )"
stage_rows

# help/SKILL.md Step 2's ladder, most advanced match first. 10 is help's own
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
