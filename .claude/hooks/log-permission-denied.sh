#!/bin/bash
# Claude Code PermissionDenied hook: Record blocked tool calls in the audit trail
# Fires when a tool call is denied. The denial has already happened — this hook
# never grants a retry; it only records what was attempted.
#
# Input schema (PermissionDenied):
# { "tool_name": "Bash", "tool_input": {...}, "tool_use_id": "...",
#   "permission_mode": "...", "classifier_verdict": "..."|null, "denial_reason": "..." }
#
# Why this exists: settings.json denies force pushes, rm -rf, hard resets, and
# .env reads. When one of those fires, the attempt is worth a line in the audit
# trail — /security-audit and incident response both want that record.

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
    TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
    REASON=$(echo "$INPUT" | jq -r '.denial_reason // "not stated"' | tr '\n' ' ' | cut -c1-200)
    TARGET=$(echo "$INPUT" | jq -r '.tool_input.command // .tool_input.file_path // empty' | tr '\n' ' ' | cut -c1-200)
else
    TOOL_NAME=$(echo "$INPUT" | grep -oE '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:[[:space:]]*"//;s/"$//')
    REASON=$(echo "$INPUT" | grep -oE '"denial_reason"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:[[:space:]]*"//;s/"$//' | cut -c1-200)
    TARGET=""
    [ -z "$TOOL_NAME" ] && TOOL_NAME="unknown"
    [ -z "$REASON" ] && REASON="not stated"
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SESSION_LOG_DIR="production/session-logs"

mkdir -p "$SESSION_LOG_DIR" 2>/dev/null

{
    printf '%s | DENIED %s' "$TIMESTAMP" "$TOOL_NAME"
    [ -n "$TARGET" ] && printf ' | %s' "$TARGET"
    printf ' | %s\n' "$REASON"
} >> "$SESSION_LOG_DIR/permission-denials.log" 2>/dev/null

exit 0
