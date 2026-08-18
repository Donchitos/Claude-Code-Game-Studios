#!/bin/bash
# Claude Code PostToolUseFailure hook: Record failed tool calls in the audit trail
# Fires after a tool call fails. The failure has already happened — this hook is
# side-effect only and never blocks.
#
# Input schema (PostToolUseFailure):
# { "tool_name": "Bash", "tool_input": {...}, "tool_use_id": "...",
#   "error": "...", "timestamp": "ISO8601" }
#
# Why this exists: /retrospective and /test-flakiness are only as good as the
# record they read. Without this, a session's failed builds, failed test runs,
# and broken edits leave no trace once the conversation is compacted.

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
    TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
    ERROR_MSG=$(echo "$INPUT" | jq -r '.error // "no error text"' | tr '\n' ' ' | cut -c1-300)
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // .tool_input.file_path // empty' | tr '\n' ' ' | cut -c1-200)
else
    TOOL_NAME=$(echo "$INPUT" | grep -oE '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:[[:space:]]*"//;s/"$//')
    ERROR_MSG=$(echo "$INPUT" | grep -oE '"error"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:[[:space:]]*"//;s/"$//' | cut -c1-300)
    CMD=""
    [ -z "$TOOL_NAME" ] && TOOL_NAME="unknown"
    [ -z "$ERROR_MSG" ] && ERROR_MSG="no error text"
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SESSION_LOG_DIR="production/session-logs"

mkdir -p "$SESSION_LOG_DIR" 2>/dev/null

{
    printf '%s | FAILED %s' "$TIMESTAMP" "$TOOL_NAME"
    [ -n "$CMD" ] && printf ' | %s' "$CMD"
    printf ' | %s\n' "$ERROR_MSG"
} >> "$SESSION_LOG_DIR/tool-failures.log" 2>/dev/null

exit 0
