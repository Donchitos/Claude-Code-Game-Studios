#!/bin/bash
# Claude Code PostToolUse hook: Keep the plugin manifest's agent list in sync
# Fires when any file inside .claude/agents/ is written or edited.
#
# Exit behavior:
#   exit 0 = advisory only (non-blocking)
#
# Input schema (PostToolUse for Write|Edit):
# { "tool_name": "Write", "tool_input": { "file_path": "...", "content": "..." } }
#
# Why this exists: .claude-plugin/plugin.json must list every agent file
# individually — the manifest schema rejects a bare directory path for `agents`
# (unlike `skills`, which accepts a directory). A new agent that is not listed
# simply does not exist for anyone who installed via the plugin, and nothing
# else in the repo would catch it.

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
    FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:[[:space:]]*"//;s/"$//')
fi

# Normalize path separators (Windows backslash to forward slash)
FILE_PATH=$(echo "$FILE_PATH" | sed 's|\\|/|g')

# Only act on agent definitions
if ! echo "$FILE_PATH" | grep -qE '(^|/)\.claude/agents/[^/]+\.md$'; then
    exit 0
fi

MANIFEST=".claude-plugin/plugin.json"
[ -f "$MANIFEST" ] || exit 0

AGENT_FILE=$(basename "$FILE_PATH")

if grep -q "\.claude/agents/$AGENT_FILE\"" "$MANIFEST"; then
    exit 0
fi

echo "=== Agent Not In Plugin Manifest: $AGENT_FILE ===" >&2
echo "$MANIFEST lists agents individually; this one is missing." >&2
echo "Anyone who installed via the plugin will not see it." >&2
echo "Add \"./.claude/agents/$AGENT_FILE\" to the \"agents\" array, then run:" >&2
echo "  claude plugin validate ." >&2
echo "==================================================" >&2

exit 0
