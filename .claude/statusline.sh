#!/usr/bin/env bash

# --- work from the project root ----------------------------------------------
# Every path below is repo-relative, so a hook invoked with a working directory
# that is not the repo root would silently read and write the WRONG TREE --
# returning a near-empty result instead of the session-recovery block, and
# creating stray trees such as docs/production/session-logs/ on write.
#
# PRECEDENCE IS LOAD-BEARING. A cwd that IS a project root carries real
# information and must win: a caller sitting inside another project means that
# project, not this one. Resolving to the script's own location first would
# override them. So, in order:
#   1. cwd holds project.yaml   -> cwd   (a project root)
#   2. cwd holds .claude/       -> cwd   (a project root not yet configured)
#   3. CLAUDE_PROJECT_DIR       -> that  (populated in the hook environment)
#   4. this script's location   -> <root>/.claude/hooks/../.. by construction
# Rule 4 always works and needs no environment at all; rules 1-2 stop it from
# overriding a caller that legitimately means somewhere else.
#
# NOT an upward search: that resolves a nested project to its parent's config.
if [ -f "project.yaml" ] || [ -d ".claude" ]; then
  CCGS_ROOT="$PWD"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}" ]; then
  CCGS_ROOT="$CLAUDE_PROJECT_DIR"
else
  CCGS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)"
fi
[ -n "$CCGS_ROOT" ] && cd "$CCGS_ROOT" 2>/dev/null || true

# Claude Code Game Studios — Status Line
# Receives JSON on stdin, outputs a single-line status.
#
# Segments: ctx% | model | production stage [| Epic > Feature > Task]

input=$(cat)

# --- Parse JSON (jq with grep fallback) ---
# project_dir first: current_dir follows every `cd`, so after `cd src` the
# status line looked for project.yaml in src/ and fell back to guessing.
if command -v jq &>/dev/null; then
  model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
  used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
  cwd=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // .cwd // ""')
else
  model=$(echo "$input" | grep -oE '"display_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
  used_pct=$(echo "$input" | grep -oE '"used_percentage"[[:space:]]*:[[:space:]]*[0-9]+' | head -1 | sed 's/.*: *//')
  cwd=$(echo "$input" | grep -oE '"project_dir"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
  [ -z "$cwd" ] && cwd=$(echo "$input" | grep -oE '"current_dir"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
  [ -z "$model" ] && model="Unknown"
fi

# Normalize Windows paths
cwd=$(echo "$cwd" | sed 's|\\|/|g')
[ -z "$cwd" ] && cwd="."

# --- Context usage ---
if [ -n "$used_pct" ]; then
  ctx_label="ctx: ${used_pct}%"
else
  ctx_label="ctx: --"
fi

# --- Config helper, sourced ONCE, interpreter resolved ONCE ---
# Every read is `$(get_yaml_key ...)`, a subshell, so the interpreter the
# helper caches on first use never reached this shell, and every read probed
# for Python again first -- one interpreter spawn per setting read instead of
# one for the whole render. Resolving it here, in this shell, lets every
# subshell inherit it. Success is whether the function exists, not the
# source's exit status.
project_yaml="$cwd/project.yaml"
yaml_helper="$cwd/.claude/hooks/yaml-helper.sh"
helper=false
if [ -f "$yaml_helper" ]; then
  source "$yaml_helper" 2>/dev/null
  command -v get_yaml_key >/dev/null 2>&1 && helper=true
  [ "$helper" = true ] && [ -f "$project_yaml" ] && _yaml_helper_resolve_python >/dev/null 2>&1
fi

# --- Production stage ---
# Priority 1: project.stage from project.yaml
stage=""
if [ -f "$project_yaml" ] && [ "$helper" = true ]; then
  stage=$(get_yaml_key "$project_yaml" project.stage 2>/dev/null)
fi
# Priority 2: legacy stage.txt fallback
if [ -z "$stage" ]; then
  stage_file="$cwd/production/stage.txt"
  if [ -f "$stage_file" ]; then
    stage=$(head -1 "$stage_file" | tr -d '\r\n')
  fi
fi

# Priority 3: Auto-detect from artifacts
if [ -z "$stage" ]; then
  concept_file="$cwd/design/gdd/game-concept.md"
  systems_file="$cwd/design/gdd/systems-index.md"
  tech_prefs="$cwd/.claude/docs/technical-preferences.md"

  has_concept=false
  has_systems=false
  engine_configured=false
  src_count=0

  [ -f "$concept_file" ] && has_concept=true
  [ -f "$systems_file" ] && has_systems=true

  # Check if engine is configured (project.yaml first, fall back to technical-preferences.md)
  if [ -f "$project_yaml" ] && [ "$helper" = true ]; then
    engine_name=$(get_yaml_key "$project_yaml" engine.name 2>/dev/null)
    [ -n "$engine_name" ] && engine_configured=true
  fi
  if [ "$engine_configured" = false ] && [ -f "$tech_prefs" ]; then
    # Leading whitespace tolerated, matching detect-gaps.sh and the migrator.
    # This is the THIRD copy of "is the engine configured in
    # technical-preferences.md" in the tree, and it was the last one still
    # anchored to column 0 -- an indented bullet read as unconfigured here while
    # the other two read it as configured, so the auto-detect ladder below
    # dropped the project to an earlier stage than the rest of the system saw.
    engine_line=$(grep -m1 -E '^[[:space:]]*-[[:space:]]+\*\*Engine\*\*:' "$tech_prefs" 2>/dev/null || true)
    if [ -n "$engine_line" ] && ! echo "$engine_line" | grep -q "TO BE CONFIGURED"; then
      engine_configured=true
    fi
  fi

  # Count source files (language-agnostic) under the engine's code root --
  # src/, Assets/ or Source/ (directory-structure.md). Counting src/ alone left
  # every Unity and Unreal project at 0, so this ladder never reached
  # Production. Capped at the threshold below: the status line runs on every
  # turn, and Unity's Assets/ can hold thousands of files, so find stops at 10.
  code_root=""
  if [ "$helper" = true ] && command -v resolve_code_root >/dev/null 2>&1; then
    code_root=$(cd "$cwd" 2>/dev/null && resolve_code_root 2>/dev/null | cut -f1)
  fi
  if [ -n "$code_root" ] && [ -d "$cwd/$code_root" ]; then
    src_count=$(find "$cwd/$code_root" -type f \( -name "*.gd" -o -name "*.cs" -o -name "*.cpp" -o -name "*.h" -o -name "*.py" -o -name "*.rs" -o -name "*.lua" -o -name "*.tscn" -o -name "*.tres" \) 2>/dev/null | head -n 10 | wc -l | tr -d ' ')
  fi

  # Check for ADRs (signals Pre-Production phase)
  has_adrs=false
  if ls "$cwd/docs/architecture/"adr-*.md 2>/dev/null | head -1 | grep -q .; then
    has_adrs=true
  fi

  # Determine stage (check from most-advanced backward)
  if [ "$src_count" -ge 10 ] 2>/dev/null; then
    stage="Production"
  elif [ "$has_adrs" = true ]; then
    stage="Pre-Production"
  elif [ "$engine_configured" = true ]; then
    stage="Technical Setup"
  elif [ "$has_systems" = true ]; then
    stage="Systems Design"
  elif [ "$has_concept" = true ]; then
    stage="Concept"
  else
    stage="Concept"
  fi
fi

# --- Process posture (modes.rigor) ---
# Locked to project.yaml (not locally overridable) with a plain terminal default
# in _yaml_helper_defaults, so a direct get_yaml_key read + default is exact.
# Deliberately NOT resolve_setting: that assumes PWD is the project root, unsafe
# here since the status line works from an absolute $cwd and never cd's.
#
# The default applies ONLY when nothing contradicts it. If `rigor` is
# unset but a knob it fronts is set explicitly, the project's real process weight
# is whatever that knob says, and printing 'standard' actively misreports it —
# migration is the common case, writing `modes.review_mode` and no `modes.rigor`,
# so every v1.0 upgrader running full director reviews read 'Production · standard'.
# Suppress instead of guessing, matching the unconfigured-project behaviour: no
# config, no claim. Suppression is correct rather than lossy — the fronted knobs
# disagree with each other in this state, so there is no single honest posture.
rigor=""
rigor_val=""   # the resolved rigor, kept even when the displayed posture is suppressed
if [ -f "$project_yaml" ] && [ "$helper" = true ]; then
  rigor=$(get_yaml_key "$project_yaml" modes.rigor 2>/dev/null)
  rigor_val="$rigor"
  if [ -z "$rigor" ]; then
    # The default comes from its single source. This line hard-coded 'standard'
    # and kept printing it after 1.1.0 flipped the default to 'minimal' --
    # 'Concept · standard' on the shipped project.yaml while every skill resolved
    # minimal. Read in-process: a $(get_yaml_default ...) is a spawn every turn.
    while IFS= read -r _d; do
      case "$_d" in "modes.rigor::"*) rigor="${_d#modes.rigor::}"; break ;; esac
    done <<EOF
$_yaml_helper_defaults
EOF
    rigor_val="$rigor"
    # Cheap pre-filter first. This hook runs every turn, and the common case
    # (nothing fronted set) must not cost a get_yaml_key subprocess per key.
    # The grep is a deliberate SUPERSET — it matches the leaf names anywhere at
    # depth, so a false positive only costs the precise checks below, while a
    # miss is impossible. Never let it decide on its own: a bare `size:` under
    # some unrelated block would suppress the posture with no reason.
    _fronted='^[[:space:]]+(review_mode|workflow|density|level|story_granularity|size):[[:space:]]*[^[:space:]#]'
    for _f in "$project_yaml" "$cwd/project.local.yaml"; do
      [ -f "$_f" ] || continue
      grep -qE "$_fronted" "$_f" 2>/dev/null || continue
      for _k in modes.review_mode modes.workflow docs.density qa.level \
                modes.story_granularity team.size; do
        if [ -n "$(get_yaml_key "$_f" "$_k" 2>/dev/null)" ]; then rigor=""; break; fi
      done
      [ -z "$rigor" ] && break
    done
  fi
fi

# --- Minimal path position (workflow: minimal) ---
# Nothing on the minimal path runs /gate-check, so project.stage never leaves
# Concept there: 'Concept · minimal' for a project with most of its stories
# built. At that tier the path position is the honest stage -- stories Complete
# of stories written, from the header Status lines /dev-story and /story-done
# keep. project.stage itself is left alone: only a /gate-check PASS (or a
# CONCERNS whose risks you accepted) moves it.
# Gated on the RESOLVED workflow: an explicit modes.workflow wins, otherwise it
# follows rigor. Gating on rigor alone left an explicit `workflow: minimal`
# under another rigor showing Concept. Builtins only -- no spawn per story.
path_pos=""
_wf=""
if [ -f "$project_yaml" ] && [ "$helper" = true ]; then
  _wf="$rigor_val"
  IFS= read -r -d '' _yaml < "$project_yaml"
  case "$_yaml" in
    *[[:space:]]workflow:*)
      _w=$(get_yaml_key "$project_yaml" modes.workflow 2>/dev/null)
      [ -n "$_w" ] && _wf="$_w" ;;
  esac
fi
if [ "$_wf" = "minimal" ]; then
  _total=0; _done=0
  for _s in "$cwd"/production/epics/*/story-*.md; do
    [ -f "$_s" ] || continue
    _total=$((_total+1))
    while IFS= read -r _line || [ -n "$_line" ]; do
      # Normalise `> **Status**: X`, `**Status:** X`, `- Status: X` to
      # `Status: X`, then match the value's leading word EXACTLY, in any case:
      # a substring match on *Done* counted "Not Done". The word ends at the
      # first non-letter, so `Done.` and `Complete, verified` count -- the
      # rule story-status.sh applies, which /help and /sprint-status read.
      # `|| [ -n ]` reads a last line with no newline, which read -r drops.
      _l="${_line%$'\r'}"; _l="${_l#"${_l%%[![:space:]]*}"}"; _l="${_l#> }"; _l="${_l#- }"; _l="${_l//\*/}"
      case "$_l" in
        Status:*)
          _v="${_l#Status:}"; _v="${_v#"${_v%%[![:space:]]*}"}"; _v="${_v%%[!A-Za-z]*}"
          case "$_v" in [Cc][Oo][Mm][Pp][Ll][Ee][Tt][Ee]|[Dd][Oo][Nn][Ee]) _done=$((_done+1)) ;; esac
          break ;;
      esac
    done < "$_s"
  done
  if [ "$_total" -gt 0 ]; then path_pos="Minimal · ${_done}/${_total} stories"
  else path_pos="Minimal · brief"; fi
fi

# --- Epic/Feature/Task breadcrumb (Production+ only) ---
breadcrumb=""
if [ "$stage" = "Production" ] || [ "$stage" = "Polish" ] || [ "$stage" = "Release" ]; then
  state_file="$cwd/production/session-state/active.md"
  if [ -f "$state_file" ]; then
    # Parse structured STATUS block
    in_block=false
    epic="" feature="" task=""
    while IFS= read -r line; do
      case "$line" in
        *"<!-- STATUS -->"*) in_block=true; continue ;;
        *"<!-- /STATUS -->"*) break ;;
      esac
      if [ "$in_block" = true ]; then
        case "$line" in
          Epic:*) epic=$(echo "$line" | sed 's/^Epic: *//') ;;
          Feature:*) feature=$(echo "$line" | sed 's/^Feature: *//') ;;
          Task:*) task=$(echo "$line" | sed 's/^Task: *//') ;;
        esac
      fi
    done < "$state_file"

    # Build breadcrumb from whatever is set
    parts=""
    [ -n "$epic" ] && parts="$epic"
    [ -n "$feature" ] && parts="${parts:+$parts > }$feature"
    [ -n "$task" ] && parts="${parts:+$parts > }$task"
    [ -n "$parts" ] && breadcrumb=" | $parts"
  fi
fi

# --- Assemble ---
if [ -n "$path_pos" ]; then segment="$path_pos"; else segment="${stage}${rigor:+ · $rigor}"; fi
printf "%s" "${ctx_label} | ${model} | ${segment}${breadcrumb}"
