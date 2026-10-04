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

# Claude Code PostToolUse hook: Validates asset files after Write/Edit
# Checks JSON validity of data files and, in Godot's assets/, naming conventions.
# Asset roots per engine: Godot assets/, Unity Assets/, Unreal Content/.
#
# Exit behavior:
#   exit 0 = success or advisory warnings only
#   exit 2 = build-breaking issue (a data file that is not valid JSON)
#
# A PostToolUse hook CANNOT block -- the write has already happened by the time
# this runs (see .claude/docs/hooks-reference/hook-input-schemas.md). The only
# question is who hears about it, and that is what the exit code selects:
#   exit 1 -> stderr goes to the USER only. Claude never sees it, so a JSON file
#             it just corrupted looks like it wrote cleanly and it moves on.
#   exit 2 -> stderr is fed back to CLAUDE as actionable feedback, so it can fix
#             the file it just wrote.
# Exiting 1 while printing "ERRORS (Blocking) ... fix before proceeding" would be
# a promise the hook cannot keep, delivered to the one party who cannot act on it.
#
# Input schema (PostToolUse for Write/Edit):
# { "tool_name": "Write", "tool_input": { "file_path": "assets/data/foo.json", "content": "..." } }

INPUT=$(cat)

# Parse file path -- use jq if available, fall back to grep
if command -v jq >/dev/null 2>&1; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
    FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# Normalize path separators (Windows backslash to forward slash).
# Two rules, order significant -- see the long note in validate-skill-change.sh.
# Short version: hook input is JSON, so a Windows path arrives as `\\`. Without
# jq the fallback cannot unescape it, and a single-rule sed turns each escaped
# pair into two slashes, so `assets/` never matches and this hook silently
# validates nothing on Windows.
FILE_PATH=$(printf '%s' "$FILE_PATH" | sed 's|\\\\|/|g; s|\\|/|g')

# Make the path project-relative. Claude Code sends a file tool's path
# ABSOLUTE, with native separators (C:\... on Windows), so an unanchored
# `(^|/)assets/` matched every file in a project with any parent folder named
# assets, and node_modules/*/assets/ too. Strip the project root in either
# spelling Git Bash gives it (/c/Users/... from pwd, C:/Users/... from pwd -W,
# drive letter in either case); a path still absolute is outside the project.
_VA_ROOT=$(pwd); _VA_ROOT_W=$(pwd -W 2>/dev/null || printf '%s' "$_VA_ROOT")
shopt -s nocasematch
case "$FILE_PATH" in
    "$_VA_ROOT"/*)   REL_PATH="${FILE_PATH:${#_VA_ROOT}+1}" ;;
    "$_VA_ROOT_W"/*) REL_PATH="${FILE_PATH:${#_VA_ROOT_W}+1}" ;;
    /*|[A-Za-z]:/*)  exit 0 ;;
    *)               REL_PATH="${FILE_PATH#./}" ;;
esac
shopt -u nocasematch

# Only check files under an asset root.
case "$REL_PATH" in
    assets/*|Assets/*|Content/*) ;;
    *) exit 0 ;;
esac

FILENAME=$(basename "$REL_PATH")
WARNINGS=""   # Style/convention issues -- exit 0 with advisory message
ERRORS=""     # Build-breaking issues -- exit 2 so Claude hears about it

# ADVISORY: naming convention -- lowercase with underscores, the Godot
# convention, so only in Godot's assets/. Unity and Unreal name assets in
# PascalCase with type prefixes; warning on every one of them trains the user
# to ignore this hook. Naming issues warn, never block.
# Uses grep -E (POSIX) not grep -P (Perl) for Windows Git Bash compatibility
case "$REL_PATH" in
    assets/*)
        if echo "$FILENAME" | grep -qE '[A-Z[:space:]-]'; then
            WARNINGS="$WARNINGS\n  NAMING: $REL_PATH must be lowercase with underscores (got: $FILENAME)"
        fi ;;
esac

# BLOCKING: Check JSON validity for data files, in any engine's data folder --
# the same set validate-commit.sh blocks on.
# Invalid JSON will break runtime loading -- this is a build-breaking error
if echo "$REL_PATH" | grep -qE '^(assets|Assets|Content)/(.*/)?[Dd]ata/.*\.[Jj][Ss][Oo][Nn]$'; then
    FILE_PATH="$REL_PATH"
    if [ -f "$FILE_PATH" ]; then
        # Find a working Python command
        PYTHON_CMD=""
        # Run it, do not just find it: the Windows Store `python` placeholder
        # passes `command -v`, then fails, and valid JSON was reported invalid.
        for cmd in python python3 py; do
            if command -v "$cmd" >/dev/null 2>&1 && "$cmd" -c 'import sys; sys.exit(sys.version_info[0] < 3)' >/dev/null 2>&1; then
                PYTHON_CMD="$cmd"
                break
            fi
        done

        if [ -n "$PYTHON_CMD" ]; then
            # utf-8-sig, as validate-commit.sh reads it: `json.tool` rejected a
            # file with a UTF-8 BOM that the commit check then accepted.
            if ! "$PYTHON_CMD" -c 'import json, sys; json.load(open(sys.argv[1], encoding="utf-8-sig"))' "$FILE_PATH" > /dev/null 2>&1; then
                ERRORS="$ERRORS\n  FORMAT: $FILE_PATH is not valid JSON — fix syntax errors before continuing"
            fi
        else
            # Say so rather than skipping in silence. This is the only BLOCKING
            # check in this hook, so without an interpreter the hook exits 0 on
            # a file it never opened -- indistinguishable from valid JSON. The
            # sibling validate-commit.sh blocks in this case; this half, which
            # runs after the file is written, says so instead.
            WARNINGS="$WARNINGS\n  UNCHECKED: cannot validate JSON (python not found) — $FILE_PATH"
        fi
    fi
fi

# Report build-breaking issues. exit 2 routes this to Claude, not just the user,
# so the file that was already written can actually be corrected. Any warnings
# ride along on the same channel.
if [ -n "$ERRORS" ]; then
    echo -e "=== Asset Validation: ERRORS ===$ERRORS\n================================\nThe file was written but is broken. Fix it now, before continuing." >&2
    [ -n "$WARNINGS" ] && echo -e "=== Asset Validation: Warnings ===$WARNINGS" >&2
    exit 2
fi

# Warnings alone do not need a fix now, but they must be seen: stderr on exit 0
# reaches the debug log only. Hook JSON reaches the user and Claude -- see
# hook_warn in yaml-helper.sh. stderr stays as the fallback without the helper.
if [ -n "$WARNINGS" ]; then
    _VA_MSG=$(echo -e "=== Asset Validation: Warnings ===$WARNINGS\n==================================\n(Warnings are advisory. Fix before final commit.)")
    [ -f .claude/hooks/yaml-helper.sh ] && . .claude/hooks/yaml-helper.sh 2>/dev/null
    if command -v hook_warn >/dev/null 2>&1; then
        hook_warn PostToolUse "$_VA_MSG"
    else
        printf '%s\n' "$_VA_MSG" >&2
    fi
fi

exit 0
