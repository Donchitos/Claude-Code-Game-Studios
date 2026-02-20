#!/bin/bash
# Claude Code Stop hook: Log session summary when Claude finishes
# Records what was worked on for audit trail and sprint tracking

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SESSION_LOG_DIR="production/session-logs"

mkdir -p "$SESSION_LOG_DIR" 2>/dev/null

# Log recent git activity from this session (check up to 8 hours for long sessions)
RECENT_COMMITS=$(git log --oneline --since="8 hours ago" 2>/dev/null)
MODIFIED_FILES=$(git diff --name-only 2>/dev/null)

# --- Clean up active session state on normal shutdown ---
STATE_FILE="production/session-state/active.md"
if [ -f "$STATE_FILE" ]; then
    # Archive to session log before removing
    {
        echo "## Archived Session State: $TIMESTAMP"
        cat "$STATE_FILE"
        echo "---"
        echo ""
    } >> "$SESSION_LOG_DIR/session-log.md" 2>/dev/null
    rm "$STATE_FILE" 2>/dev/null
fi

if [ -n "$RECENT_COMMITS" ] || [ -n "$MODIFIED_FILES" ]; then
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
fi

exit 0
