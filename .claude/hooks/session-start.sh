#!/bin/bash

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
  CCGS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
fi
[ -n "$CCGS_ROOT" ] && cd "$CCGS_ROOT" 2>/dev/null || true

# Claude Code SessionStart hook: Load project context at session start
# Outputs context information that Claude sees when a session begins
#
# Input schema (SessionStart): stdin IS supplied -- VERIFIED, not asserted.
# Observed on real harness events as a single line of JSON with session_id,
# transcript_path, cwd, hook_event_name and `source` ("clear", "compact").
# Do NOT read stdin here unboundedly -- the harness may leave it open, and a
# blocking read costs this hook its whole 10s budget on every session start.
#
# THIS HOOK MUST FINISH INSIDE ITS BUDGET. If it is killed partway, the
# session-state block never reaches context and the session starts blind --
# and nothing visible from inside the session says so. The early-exit gating
# and bounded reads below are what keep it inside 2s; treat them as load-
# bearing, not as optimisation.
#
# If that ever recurs, the diagnostic that works is a FIRE/DONE pair appended
# to a gitignored log at the top and bottom of this script -- "did it run at
# all" and "did it get here" are opposite failures with opposite fixes, and
# nothing else distinguishes them. /compact is good evidence: SessionStart runs
# again with source `compact`, and PostCompact output never reaches the
# conversation, so a checkpoint seen after /compact came from this script.

echo "=== Claude Code Game Studios — Session Context ==="

# Current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$BRANCH" ]; then
    echo "Branch: $BRANCH"

    # Recent commits
    echo ""
    echo "Recent commits:"
    git log --oneline -5 2>/dev/null | while read -r line; do
        echo "  $line"
    done
fi

# Resolve review_mode the same way skills do: resolve_setting applies the FULL
# chain (project.local.yaml -> project.yaml -> legacy review-mode.txt -> modes.rigor
# expansion -> default). modes.review_mode is rigor-fronted and locally overridable,
# so only resolve_setting reflects both a rigor-derived value (a project that set
# only `rigor: minimal` shows `solo`) and a local override. get_effective_yaml_key
# returns empty for a rigor-only project, which would leave the banner showing a
# stale `lean`.
REVIEW_MODE=""
if [ -f "project.yaml" ] && [ -f ".claude/hooks/yaml-helper.sh" ]; then
    source .claude/hooks/yaml-helper.sh
    REVIEW_MODE=$(resolve_setting modes.review_mode 2>/dev/null | cut -f1)
fi
if [ -z "$REVIEW_MODE" ] && [ -f "production/review-mode.txt" ]; then
    REVIEW_MODE=$(head -1 production/review-mode.txt 2>/dev/null | tr -d '[:space:]')
fi
# With nothing configured, rigor defaults to `minimal`, which resolves
# review_mode to `solo` -- what every skill runs. `lean` here named a review
# mode no skill was using.
if [ -z "$REVIEW_MODE" ]; then
    REVIEW_MODE="solo"
fi
echo ""
echo "Review mode: $REVIEW_MODE"

# Schema validation — surface invalid enum values in
# project.yaml and project.local.yaml so typos like `automation: chaotic`
# surface at session start rather than failing inside a skill.
if [ -f ".claude/hooks/yaml-helper.sh" ]; then
    if ! type validate_yaml_enum >/dev/null 2>&1; then
        source .claude/hooks/yaml-helper.sh
    fi
    # Hard-error guard: project.local.yaml requires a project.yaml base
    if ! BASE_ERR=$(validate_local_yaml_base 2>&1); then
        echo ""
        echo "[!] $BASE_ERR"
    fi
    if [ -f "project.yaml" ]; then
        SCHEMA_ERRORS=$(validate_yaml_enum project.yaml 2>&1)
        if [ -n "$SCHEMA_ERRORS" ]; then
            echo ""
            echo "[!] project.yaml schema errors:"
            echo "$SCHEMA_ERRORS" | sed 's/^/    /'
        fi
    fi
    if [ -f "project.local.yaml" ]; then
        SCHEMA_ERRORS=$(validate_yaml_enum project.local.yaml 2>&1)
        if [ -n "$SCHEMA_ERRORS" ]; then
            echo ""
            echo "[!] project.local.yaml schema errors:"
            echo "$SCHEMA_ERRORS" | sed 's/^/    /'
        fi
    fi
fi

# --- Stage source agreement ---
# `project.stage` in project.yaml is authoritative; production/stage.txt is a
# legacy mirror kept for unmigrated hooks. Twelve consumers read the mirror --
# including detect-gaps.sh and yaml-helper.sh -- so when the two disagree, part
# of the system acts on one stage and part on the other, silently.
#
# Warn, never reconcile. Only /gate-check should change a stage (on a PASS, or
# a CONCERNS whose risks you accepted), so a hook that "helpfully" rewrote the
# mirror would be advancing a phase gate nobody passed. Helpers emit
# observations, never verdicts (CLAUDE.md).
STAGE_YAML=""
STAGE_TXT=""
if [ -f "project.yaml" ] && command -v get_yaml_key >/dev/null 2>&1; then
    STAGE_YAML=$(get_yaml_key project.yaml project.stage 2>/dev/null)
fi
if [ -f "production/stage.txt" ]; then
    STAGE_TXT=$(head -1 production/stage.txt 2>/dev/null | tr -d '\r' | sed 's/[[:space:]]*$//')
fi
if [ -n "$STAGE_YAML" ] && [ -n "$STAGE_TXT" ] && [ "$STAGE_YAML" != "$STAGE_TXT" ]; then
    echo ""
    echo "[!] Stage sources disagree:"
    echo "      project.yaml  project.stage : $STAGE_YAML   (authoritative)"
    echo "      production/stage.txt        : $STAGE_TXT   (legacy mirror)"
    echo "    Twelve consumers read the mirror, so part of the system is acting on"
    echo "    each value. Only /gate-check should change a stage (on a PASS, or a"
    echo "    CONCERNS whose risks you accepted) — do not hand-edit either file to"
    echo "    silence this."
fi

# Current sprint (find most recent sprint file)
LATEST_SPRINT=$(ls -t production/sprints/sprint-*.md 2>/dev/null | head -1)
if [ -n "$LATEST_SPRINT" ]; then
    echo ""
    echo "Active sprint: $(basename "$LATEST_SPRINT" .md)"
fi

# Current milestone
LATEST_MILESTONE=$(ls -t production/milestones/*.md 2>/dev/null | head -1)
if [ -n "$LATEST_MILESTONE" ]; then
    echo "Active milestone: $(basename "$LATEST_MILESTONE" .md)"
fi

# Open bug count
BUG_COUNT=0
for dir in tests/playtest production; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -name "BUG-*.md" 2>/dev/null | wc -l)
        BUG_COUNT=$((BUG_COUNT + count))
    fi
done
if [ "$BUG_COUNT" -gt 0 ]; then
    echo "Open bugs: $BUG_COUNT"
fi

# Code health quick check.
#
# Reads the ENGINE-SPECIFIC code root, not a literal `src/`. Hardcoding `src/`
# made this line Godot-only: on a Unity or Unreal project the directory test
# failed, the banner printed no code-health line at all, and a clean project and
# an unreadable one looked identical. See resolve_code_root in yaml-helper.sh.
#
# Sourcing here is defensive: the two source sites above are both conditional,
# so by this point the function may or may not exist.
if [ -f .claude/hooks/yaml-helper.sh ] && ! command -v resolve_code_root >/dev/null 2>&1; then
    . .claude/hooks/yaml-helper.sh 2>/dev/null
fi
if command -v resolve_code_root >/dev/null 2>&1; then
    CODE_ROOT=$(resolve_code_root 2>/dev/null | cut -f1)
else
    CODE_ROOT=""
fi
# Source files only, binaries skipped. Unity's code root is Assets/, which also
# holds every texture, model and audio file: an unfiltered grep read all of
# them, twice, inside this hook's 10s budget -- ahead of the session-state
# block below, so a timeout here lost the recovery too -- and counted each
# "Binary file ... matches" line as a TODO.
if [ -n "$CODE_ROOT" ] && [ -d "$CODE_ROOT" ]; then
    _SS_SRC=(--include='*.gd' --include='*.cs' --include='*.cpp' --include='*.h' --include='*.hpp'
             --include='*.c' --include='*.py' --include='*.rs' --include='*.lua')
    # tr: BSD wc (macOS) right-aligns its count, and these are printed as-is.
    TODO_COUNT=$(grep -rI "${_SS_SRC[@]}" "TODO" "$CODE_ROOT/" 2>/dev/null | wc -l | tr -d ' ')
    FIXME_COUNT=$(grep -rI "${_SS_SRC[@]}" "FIXME" "$CODE_ROOT/" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$TODO_COUNT" -gt 0 ] || [ "$FIXME_COUNT" -gt 0 ]; then
        echo ""
        echo "Code health: ${TODO_COUNT} TODOs, ${FIXME_COUNT} FIXMEs in ${CODE_ROOT}/"
    fi
fi

# --- engine reference vs configured engine -----------------------------------
# /setup-engine is the only thing that rewrites CLAUDE.md's ENGINE-REFERENCE-IMPORT
# line. Edit engine.name in project.yaml by hand and the import keeps loading the
# previous engine's reference as project instructions -- every session, silently.
# An OBSERVATION, never an action (CLAUDE.md): it reports, the user decides.
# Printed BEFORE the session state: hook output past 10,000 characters is cut
# to a preview, so a warning below a long checkpoint could be lost.
if [ -f project.yaml ] && [ -f CLAUDE.md ]; then
    ERI=$(grep -m1 -E '^@docs/engine-reference/[a-z]+/VERSION\.md' CLAUDE.md 2>/dev/null \
          | sed -n 's|^@docs/engine-reference/\([a-z]*\)/VERSION\.md.*|\1|p')
    # engine.name, not the first `name:` line: `project.name: Marrow` above the
    # engine block read as engine "marrow" and warned on a correct project. The
    # first word only, so "Unreal Engine 5" is the unreal reference folder.
    CFG=$(awk '/^engine:/ { e = 1; next } e && /^[^[:space:]#]/ { exit }
               e && /^[[:space:]]+name:/ { sub(/^[[:space:]]+name:[[:space:]]*/, ""); gsub(/["'"'"']/, "");
                                           split($0, w, /[[:space:]#]/); print w[1]; exit }' \
          project.yaml 2>/dev/null | tr '[:upper:]' '[:lower:]')
    if [ -n "$ERI" ] && [ -n "$CFG" ] && [ "$ERI" != "$CFG" ]; then
        echo ""
        echo "!! ENGINE REFERENCE MISMATCH"
        echo "   project.yaml engine.name : $CFG"
        echo "   CLAUDE.md imports        : docs/engine-reference/$ERI/VERSION.md"
        echo "   Every session is loading the $ERI reference on a $CFG project."
        echo "   Fix: re-run /setup-engine, or edit the ENGINE-REFERENCE-IMPORT line."
    fi
fi

# --- Active session state recovery ---
# Only THIS block is gated by features.session_state, not the whole hook: the
# sprint/milestone/git context above is not part of the session-state pipeline
# and a user who turns that pipeline off still wants it. Gating the whole hook
# (as the original spec's "exit early at the top" wording implies) would take
# the branch and stage context away with it.
#
# Fail OPEN: this hook only sources yaml-helper.sh conditionally, so
# session_state_enabled may be undefined. An undefined function is falsey, which
# would silently suppress the recovery checkpoint -- the one piece of output
# whose absence the user cannot notice. Show the state unless we positively
# determined the flag is off.
STATE_FILE="production/session-state/active.md"
if [ -f .claude/hooks/yaml-helper.sh ] && ! command -v session_state_enabled >/dev/null 2>&1; then
    . .claude/hooks/yaml-helper.sh
fi
if [ -f "$STATE_FILE" ] && { ! command -v session_state_enabled >/dev/null 2>&1 || session_state_enabled; }; then
    echo ""
    echo "=== ACTIVE SESSION STATE DETECTED ==="
    echo "A previous session left state at: $STATE_FILE"
    echo "Read this file to recover context and continue where you left off."
    echo ""
    # The CHECKPOINT region -- the same region pre-compact.sh reads.
    #
    # Previewing `tail -20` here while pre-compact takes `head -100` would put two
    # consumers on opposite ends of one file, so which slice you got would
    # depend on which hook happened to fire. Neither was wrong, because
    # nothing defined where the recoverable state lived. The schema in
    # .claude/docs/templates/session-state.md defines it; both read it now.
    CHECKPOINT=$(sed -n '/<!-- CHECKPOINT -->/,/<!-- \/CHECKPOINT -->/p' "$STATE_FILE" 2>/dev/null \
                 | grep -v '<!-- /\?CHECKPOINT -->')
    TOTAL_LINES=$(wc -l < "$STATE_FILE" 2>/dev/null | tr -d ' ')
    # A sed range whose END address never matches runs to EOF. So a file with an
    # opening marker and NO closing one produced a non-empty capture of the whole
    # remaining file and took the healthy branch below -- silently previewing
    # narrative under a "Checkpoint:" heading, with no warning and no template
    # named. Emptiness cannot distinguish "no block" from
    # "unterminated block"; only the markers can, so test them directly.
    # rotate-session-state.sh already checks the CLOSING marker and refuses.
    # Two consumers of one region must agree on what malformed means.
    # `<!-- CHECKPOINT -->` cannot match `<!-- /CHECKPOINT -->` -- the slash sits
    # where the space would be -- so these two counts are independent.
    CP_OPEN=$(grep -c '<!-- CHECKPOINT -->' "$STATE_FILE" 2>/dev/null | tr -d ' ')
    CP_CLOSE=$(grep -c '<!-- /CHECKPOINT -->' "$STATE_FILE" 2>/dev/null | tr -d ' ')
    if [ "${CP_OPEN:-0}" -gt 0 ] && [ "${CP_CLOSE:-0}" -eq 0 ]; then
        echo "  [!] CHECKPOINT block is not terminated — no <!-- /CHECKPOINT --> marker."
        echo "      Not previewing it: without the closing marker the checkpoint"
        echo "      cannot be told from the narrative, and everything to the end"
        echo "      of the file would be shown as if it were recoverable state."
        echo "      Re-create from .claude/docs/templates/session-state.md."
        echo "  ... ($TOTAL_LINES total lines — read the full file to continue)"
    elif [ -n "$CHECKPOINT" ]; then
        # Capped at 25 lines / 3,000 characters. Claude Code keeps 10,000
        # characters of hook output and shows only a 2,000-character preview
        # past that, so an uncapped checkpoint could cut itself -- and anything
        # printed after it -- out of what Claude sees.
        echo "Checkpoint:"
        printf '%s\n' "$CHECKPOINT" | awk '
            { n++; c += length($0) + 1 }
            n > 25 || c > 3000 { cut = 1; exit }
            { print }
            END { if (cut) exit 3 }'
        if [ $? -eq 3 ]; then
            echo "  ... checkpoint truncated ($(printf '%s\n' "$CHECKPOINT" | wc -l | tr -d ' ') lines) — read $STATE_FILE for the rest"
        fi
        echo "  ... ($TOTAL_LINES total lines — read the full file for detail)"
    else
        echo "Quick summary (first 20 lines — no CHECKPOINT block in this file):"
        head -20 "$STATE_FILE" 2>/dev/null
        echo "  ... ($TOTAL_LINES total lines — read the full file to continue)"
        echo "  NOTE: re-create from .claude/docs/templates/session-state.md so"
        echo "        recovery reads a bounded checkpoint instead of a slice."
    fi
    # Rotation is an OBSERVATION, never an action: helpers in .claude/scripts/
    # emit observations, never verdicts (CLAUDE.md). The user decides.
    if [ "${TOTAL_LINES:-0}" -gt 200 ] 2>/dev/null; then
        echo "  Note: $TOTAL_LINES lines. Narrative can be rotated into"
        echo "        production/session-logs/ — bash .claude/scripts/rotate-session-state.sh"
    fi
    echo "=== END SESSION STATE PREVIEW ==="
fi

echo "==================================="
exit 0
