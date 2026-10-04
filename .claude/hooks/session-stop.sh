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

# Claude Code Stop hook: Log session summary when Claude finishes
# Records what was worked on for audit trail and sprint tracking

# features.session_state: off => this hook is a no-op. Default `on`; see
# session_state_enabled() in yaml-helper.sh.
if [ -f .claude/hooks/yaml-helper.sh ]; then
    . .claude/hooks/yaml-helper.sh
    session_state_enabled || exit 0
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SESSION_LOG_DIR="production/session-logs"

mkdir -p "$SESSION_LOG_DIR" 2>/dev/null

# Log recent git activity from this session (check up to 8 hours for long sessions)
RECENT_COMMITS=$(git log --oneline --since="8 hours ago" 2>/dev/null)
MODIFIED_FILES=$(git diff --name-only 2>/dev/null)

# --- Archive active session state on shutdown (do NOT delete) ---
# active.md persists across clean exits so multi-session recovery works.
# It is only valid to delete active.md manually or when explicitly superseded.
# APPEND ONLY WHEN THE CONTENT CHANGED.
#
# The Stop hook fires once per RESPONSE, not once per session. Both blocks below
# appended unconditionally, so a long session wrote the whole of active.md on
# every turn. Measured on this repository before this guard:
#
#   3,187 Stop firings, 665 archived copies, session-log.md at 17.5 MB
#
# and session-logs/ is gitignored, so nothing ever surfaced it. The growth
# compounds: the larger active.md gets, the more each firing appends -- and
# rotate-session-state.sh caps active.md precisely because it grows, while the
# log accumulating full copies of it had no cap at all.
#
# Content hash, not mtime: an editor that rewrites a file unchanged would
# otherwise re-archive it. Same reasoning and same tool as review-receipts.sh --
# git hash-object is content-addressed and git is already called above.
#
# A hash that cannot be computed archives ANYWAY. For an audit trail the safe
# failure direction is a duplicate entry, never a lost one.
STATE_FILE="production/session-state/active.md"
STATE_HASH_FILE="$SESSION_LOG_DIR/.active-state.hash"
if [ -f "$STATE_FILE" ]; then
    STATE_HASH=$(git hash-object -- "$STATE_FILE" 2>/dev/null)
    if [ -z "$STATE_HASH" ] || [ "$STATE_HASH" != "$(cat "$STATE_HASH_FILE" 2>/dev/null)" ]; then
        {
            echo "## Archived Session State: $TIMESTAMP"
            cat "$STATE_FILE"
            echo "---"
            echo ""
        } >> "$SESSION_LOG_DIR/session-log.md" 2>/dev/null
        [ -n "$STATE_HASH" ] && printf '%s\n' "$STATE_HASH" > "$STATE_HASH_FILE" 2>/dev/null
    fi
fi

SUMMARY_HASH_FILE="$SESSION_LOG_DIR/.session-end.hash"
if [ -n "$RECENT_COMMITS" ] || [ -n "$MODIFIED_FILES" ]; then
    # Hash the CONTENT, not the rendered block: the block carries $TIMESTAMP,
    # which differs every firing and would defeat the comparison entirely.
    SUMMARY_HASH=$(printf '%s\n---\n%s' "$RECENT_COMMITS" "$MODIFIED_FILES" \
                   | git hash-object --stdin 2>/dev/null)
    if [ -z "$SUMMARY_HASH" ] || [ "$SUMMARY_HASH" != "$(cat "$SUMMARY_HASH_FILE" 2>/dev/null)" ]; then
        {
            echo "## Session End: $TIMESTAMP"
            if [ -n "$RECENT_COMMITS" ]; then
                echo "### Commits"
                echo "$RECENT_COMMITS"
            fi
            if [ -n "$MODIFIED_FILES" ]; then
                echo "### Uncommitted Changes"
                echo "$MODIFIED_FILES"
            fi
            echo "---"
            echo ""
        } >> "$SESSION_LOG_DIR/session-log.md" 2>/dev/null
        [ -n "$SUMMARY_HASH" ] && printf '%s\n' "$SUMMARY_HASH" > "$SUMMARY_HASH_FILE" 2>/dev/null
    fi
fi

# --- Subagent spawn tally (cost visibility) ---
# log-agent.sh has always written per-spawn records that nothing read, so the
# framework's dominant cost was invisible to the user. This turns those records
# into a running count.
#
# Ordering matters: everything above runs BEFORE stdin is touched. Stop hooks
# are piped JSON, but if stdin were ever absent the read would block until the
# 10s timeout killed the hook -- and the state archive above must not be lost
# to that. Read last, fail silent.
AUDIT_LOG="$SESSION_LOG_DIR/agent-audit.log"

if [ ! -t 0 ] && [ -f "$AUDIT_LOG" ]; then
    if command -v timeout >/dev/null 2>&1; then
        INPUT=$(timeout 2 cat 2>/dev/null)
    else
        INPUT=$(cat 2>/dev/null)
    fi

    if command -v jq >/dev/null 2>&1; then
        SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)
    else
        SESSION_ID=$(echo "$INPUT" | grep -oE '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"session_id"[[:space:]]*:[[:space:]]*"//;s/"$//')
    fi

    # No session id means no honest per-session number. Report nothing rather
    # than a total that silently spans every session in the log.
    if [ -n "$SESSION_ID" ] && [ "$SESSION_ID" != "unknown" ] && [ "$SESSION_ID" != "null" ]; then
        SPAWN_LINES=$(grep -F " | $SESSION_ID | Agent invoked: " "$AUDIT_LOG" 2>/dev/null)
        SPAWN_COUNT=$(printf '%s' "$SPAWN_LINES" | grep -c . 2>/dev/null)
        [ -z "$SPAWN_COUNT" ] && SPAWN_COUNT=0

        if [ "$SPAWN_COUNT" -gt 0 ]; then
            BREAKDOWN=$(printf '%s\n' "$SPAWN_LINES" \
                | sed 's/.*Agent invoked: //' \
                | sort | uniq -c | sort -rn)

            {
                echo "# Session Subagent Cost"
                echo ""
                echo "**Session:** \`$SESSION_ID\`  "
                echo "**Updated:** $TIMESTAMP"
                echo ""
                echo "Subagent spawns this session: **$SPAWN_COUNT**"
                echo ""
                echo "| Agent | Spawns |"
                echo "|-------|--------|"
                printf '%s\n' "$BREAKDOWN" | while read -r count name; do
                    [ -z "$name" ] && continue
                    echo "| $name | $count |"
                done
                echo ""
                echo "Each spawn is a fresh context window that re-reads its own inputs."
                echo "To reduce this: lower \`modes.review_mode\` (\`/settings modes.review_mode=solo\`)"
                echo "or \`modes.rigor\` (\`/settings modes.rigor=minimal\`)."
            } > "$SESSION_LOG_DIR/session-cost.md" 2>/dev/null

            echo "Subagent spawns this session: $SPAWN_COUNT (see production/session-logs/session-cost.md)"
        fi
    fi
fi

exit 0
