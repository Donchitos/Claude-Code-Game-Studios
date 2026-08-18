#!/bin/bash
# Claude Code StopFailure hook: Leave a recovery breadcrumb when a turn dies
# Fires when a turn ends because of an API error rather than normal completion.
# Output and exit code are ignored by Claude Code — this hook exists purely for
# its side effect on disk.
#
# Input schema (StopFailure):
# { "error_type": "rate_limit|overloaded|max_output_tokens|...",
#   "error_message": "...", "model": "...", "timestamp": "ISO8601" }
#
# Why this exists: context-management.md documents a recovery path that starts
# with reading production/session-state/active.md. When a session dies mid-task,
# that file has no record of *why*. This appends one line so the next session
# knows it is resuming from a failure rather than a clean stop.

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
    ERROR_TYPE=$(echo "$INPUT" | jq -r '.error_type // "unknown"')
    ERROR_MSG=$(echo "$INPUT" | jq -r '.error_message // empty' | tr '\n' ' ' | cut -c1-200)
else
    ERROR_TYPE=$(echo "$INPUT" | grep -oE '"error_type"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:[[:space:]]*"//;s/"$//')
    ERROR_MSG=""
    [ -z "$ERROR_TYPE" ] && ERROR_TYPE="unknown"
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SESSION_LOG_DIR="production/session-logs"
STATE_FILE="production/session-state/active.md"

mkdir -p "$SESSION_LOG_DIR" 2>/dev/null

echo "$TIMESTAMP | TURN FAILED: $ERROR_TYPE | $ERROR_MSG" >> "$SESSION_LOG_DIR/turn-failures.log" 2>/dev/null

# Stamp the state file so session recovery sees the interruption first.
if [ -f "$STATE_FILE" ]; then
    {
        echo ""
        echo "> **Turn interrupted $TIMESTAMP** — API error: \`$ERROR_TYPE\`."
        echo "> Work above this line may be incomplete. Verify the last task before continuing."
    } >> "$STATE_FILE" 2>/dev/null
fi

exit 0
