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

# Claude Code PostToolUse hook: Advises running skill-test after skill file changes
# Fires when any file inside .claude/skills/ is written or edited.
#
# Exit behavior:
#   exit 0 = advisory only (non-blocking)
#
# Input schema (PostToolUse for Write|Edit):
# { "tool_name": "Write", "tool_input": { "file_path": "...", "content": "..." } }

INPUT=$(cat)

# Parse file path -- use jq if available, fall back to grep
if command -v jq >/dev/null 2>&1; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
    FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# Normalize path separators (Windows backslash to forward slash).
#
# TWO rules, and the order matters. The hook input is JSON, so a Windows path
# arrives escaped: "C:\\Users\\x". jq unescapes it to a single backslash, but
# the grep fallback CANNOT -- it hands back the raw two-character `\\`. A
# single `s|\\|/|g` then turns each of those into its own slash, producing
# `.claude//skills//help//SKILL.md`, which no path test below matches. The hook
# went silent on every Windows edit whenever jq was absent -- and jq is absent
# on a stock Windows Git Bash, which is this project's primary platform.
#
# Rule 1 collapses the escaped pair to one slash; rule 2 handles an already
# unescaped separator (the jq path, or a POSIX caller). Running both is safe
# for either input because rule 1 finds nothing to do on unescaped text.
FILE_PATH=$(printf '%s' "$FILE_PATH" | sed 's|\\\\|/|g; s|\\|/|g')

# Make the path project-relative, as validate-assets.sh does. Claude Code sends
# it ABSOLUTE, and a match on `/.claude/skills/` anywhere in it also fired on
# the user's own skills in ~/.claude/skills/, naming a skill this project does
# not have. Strip the project root in either spelling Git Bash gives it; a path
# still absolute is outside the project.
_VS_ROOT=$(pwd); _VS_ROOT_W=$(pwd -W 2>/dev/null || printf '%s' "$_VS_ROOT")
shopt -s nocasematch
case "$FILE_PATH" in
    "$_VS_ROOT"/*)   REL_PATH="${FILE_PATH:${#_VS_ROOT}+1}" ;;
    "$_VS_ROOT_W"/*) REL_PATH="${FILE_PATH:${#_VS_ROOT_W}+1}" ;;
    /*|[A-Za-z]:/*)  exit 0 ;;
    *)               REL_PATH="${FILE_PATH#./}" ;;
esac
shopt -u nocasematch

# Only act on files inside this project's .claude/skills/
case "$REL_PATH" in
    .claude/skills/*) ;;
    *) exit 0 ;;
esac

# Extract skill name from path (.claude/skills/[skill-name]/SKILL.md)
SKILL_NAME=$(echo "$REL_PATH" | grep -oE '^\.claude/skills/[^/]+' | sed 's|\.claude/skills/||')

if [ -z "$SKILL_NAME" ]; then
    exit 0
fi

# Advisory, so exit 0 -- and therefore hook JSON, not stderr, which on exit 0
# reaches the debug log only. See hook_warn in yaml-helper.sh.
_VS_MSG="Skill modified: $SKILL_NAME. Run /skill-test static $SKILL_NAME to validate structural compliance."
[ -f .claude/hooks/yaml-helper.sh ] && . .claude/hooks/yaml-helper.sh 2>/dev/null
if command -v hook_warn >/dev/null 2>&1; then
    hook_warn PostToolUse "$_VS_MSG"
else
    printf '%s\n' "$_VS_MSG" >&2
fi

exit 0
