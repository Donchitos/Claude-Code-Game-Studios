#!/bin/bash
# Claude Code FileChanged hook: Notice design docs edited outside the session
# Fires when a watched file changes on disk. The edit has already happened —
# this hook is advisory and never blocks.
#
# Input schema (FileChanged):
# { "file_path": "...", "watch_pattern": "...", "timestamp": "ISO8601" }
#
# Why this exists: a GDD edited in an external editor is invisible to the
# session. Architecture decisions traced to that GDD may now be stale, which is
# exactly what /propagate-design-change is for. Without this the drift is only
# caught at the next /architecture-review, which may be weeks later.

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // empty')
else
    FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:[[:space:]]*"//;s/"$//')
fi

# Normalize path separators (Windows backslash to forward slash)
FILE_PATH=$(echo "$FILE_PATH" | sed 's|\\|/|g')

[ -z "$FILE_PATH" ] && exit 0

# Only act on design documents — the matcher should already scope this, but a
# regex matcher can be broader than intended, so re-check here.
if ! echo "$FILE_PATH" | grep -qE '(^|/)design/.*\.md$'; then
    exit 0
fi

DOC_NAME=$(basename "$FILE_PATH")

echo "=== Design Doc Changed Outside Session: $DOC_NAME ===" >&2
echo "$FILE_PATH was edited on disk." >&2
echo "If this changed rules, formulas, or acceptance criteria, run:" >&2
echo "  /propagate-design-change $FILE_PATH" >&2
echo "to find ADRs and stories that may now be stale." >&2
echo "=====================================================" >&2

exit 0
