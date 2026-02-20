#!/bin/bash
# Claude Code PostToolUse hook: Validates asset files after Write/Edit
# Checks naming conventions for files in assets/ directory
# Exit 0 = success (non-blocking, PostToolUse cannot block)
#
# Input schema (PostToolUse for Write/Edit):
# { "tool_name": "Write", "tool_input": { "file_path": "assets/data/foo.json", "content": "..." } }

INPUT=$(cat)

# Parse file path -- use jq if available, fall back to grep
if command -v jq >/dev/null 2>&1; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
    FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# Normalize path separators (Windows backslash to forward slash)
FILE_PATH=$(echo "$FILE_PATH" | sed 's|\\|/|g')

# Only check files in assets/
if ! echo "$FILE_PATH" | grep -qE '(^|/)assets/'; then
    exit 0
fi

FILENAME=$(basename "$FILE_PATH")
WARNINGS=""

# Check naming convention (lowercase with underscores only) -- uses grep -E instead of grep -P
if echo "$FILENAME" | grep -qE '[A-Z[:space:]-]'; then
    WARNINGS="$WARNINGS\nNAMING: $FILE_PATH must be lowercase with underscores (got: $FILENAME)"
fi

# Check JSON validity for data files
if echo "$FILE_PATH" | grep -qE '(^|/)assets/data/.*\.json$'; then
    if [ -f "$FILE_PATH" ]; then
        # Find a working Python command
        PYTHON_CMD=""
        for cmd in python python3 py; do
            if command -v "$cmd" >/dev/null 2>&1; then
                PYTHON_CMD="$cmd"
                break
            fi
        done

        if [ -n "$PYTHON_CMD" ]; then
            if ! "$PYTHON_CMD" -m json.tool "$FILE_PATH" > /dev/null 2>&1; then
                WARNINGS="$WARNINGS\nFORMAT: $FILE_PATH is not valid JSON"
            fi
        fi
    fi
fi

if [ -n "$WARNINGS" ]; then
    echo -e "=== Asset Validation ===$WARNINGS\n========================" >&2
fi

exit 0
