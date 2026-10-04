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

# Claude Code SubagentStop hook: Log agent completion for audit trail
# Tracks when agents finish and their outcome
#
# Input schema (SubagentStop) — per Claude Code hooks reference:
# { "session_id": "...", "agent_id": "agent-abc123", "agent_type": "Explore",
#   "agent_transcript_path": "...", "last_assistant_message": "...", ... }
#
# The agent name is in `agent_type`, NOT `agent_name`. Reading `.agent_name`
# returns null on every invocation, so the fallback "unknown" is always used
# and the audit trail captures nothing useful.

# features.session_state: off => no audit trail. Default `on`; see
# session_state_enabled() in yaml-helper.sh.
if [ -f .claude/hooks/yaml-helper.sh ]; then
    . .claude/hooks/yaml-helper.sh
    session_state_enabled || exit 0
fi

INPUT=$(cat)

# SubagentStop also fires when Claude Code's own internal agents finish (prompt
# suggestions, /btw side questions). Those arrive with agent_type set to an
# empty string -- not a CCGS spawn, and each one was logged as "unknown". A
# MISSING agent_type is different and still logs as "unknown" below.
if printf '%s' "$INPUT" | grep -qE '"agent_type"[[:space:]]*:[[:space:]]*""'; then
    exit 0
fi

# Parse agent name -- use jq if available, fall back to grep
if command -v jq >/dev/null 2>&1; then
    AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_type // "unknown"' 2>/dev/null)
else
    AGENT_NAME=$(echo "$INPUT" | grep -oE '"agent_type"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"agent_type"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi
# OUTSIDE the branch, like SESSION_ID below. jq's `// "unknown"` substitutes for
# null and false but NOT for an empty string, so the jq path could emit a record
# with no agent name at all while the grep path guarded against it. One guard,
# both paths.
[ -z "$AGENT_NAME" ] && AGENT_NAME="unknown"

# Parse session id -- keeps the completion record in the same three-field shape
# as log-agent.sh so both sides of a spawn belong to an identifiable session.
if command -v jq >/dev/null 2>&1; then
    SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
else
    SESSION_ID=$(echo "$INPUT" | grep -oE '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"session_id"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi
[ -z "$SESSION_ID" ] && SESSION_ID="unknown"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SESSION_LOG_DIR="production/session-logs"

mkdir -p "$SESSION_LOG_DIR" 2>/dev/null

echo "$TIMESTAMP | $SESSION_ID | Agent completed: $AGENT_NAME" >> "$SESSION_LOG_DIR/agent-audit.log" 2>/dev/null

exit 0
