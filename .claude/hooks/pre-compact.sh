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

# Claude Code PreCompact hook: log the compaction, and summarise session state.
#
# THIS OUTPUT DOES NOT REACH CLAUDE. Claude Code writes PreCompact stdout to the
# debug log and discards its systemMessage (hooks documentation). What survives
# a compaction is the file on disk: SessionStart fires again with source
# `compact`, and session-start.sh shows the CHECKPOINT then. The one effect
# here that lands is the compaction-log line at the end; the summary stays
# bounded for anyone reading the debug log. The notes below were written when
# the output was believed to reach the context -- the bounds still hold, the
# "into the context" reasoning does not.

# features.session_state: off => this hook is a no-op. Default `on`; see
# session_state_enabled() in yaml-helper.sh.
if [ -f .claude/hooks/yaml-helper.sh ]; then
    . .claude/hooks/yaml-helper.sh
    session_state_enabled || exit 0
fi

echo "=== SESSION STATE BEFORE COMPACTION ==="
echo "Timestamp: $(date)"

# --- Active session state: the CHECKPOINT region, BY REFERENCE ---
#
# Injecting `head -n 100` of active.md here would be wrong twice over.
#
# First, the cap bounds the wrong dimension. active.md's lines are long, so 100
# of them was 12.7 KB (~3,200 tokens) -- injected at the one moment context is
# scarcest, and growing with the file.
#
# Second: this was written believing hook output goes INTO the context that is
# about to be compacted. It does not (see the top of this file) -- PreCompact
# output reaches the debug log only, so a dump bought nothing, and
# session-start.sh, which runs after every compaction, is what restores the
# file. Pointer + a bounded checkpoint beats a dump on both cost and
# fidelity.
#
# So: emit only the region between the CHECKPOINT markers (bounded by the schema
# in .claude/docs/templates/session-state.md) plus a pointer to the whole file.
STATE_FILE="production/session-state/active.md"
if [ -f "$STATE_FILE" ]; then
    echo ""
    echo "## Active Session State — checkpoint from $STATE_FILE"
    CHECKPOINT=$(sed -n '/<!-- CHECKPOINT -->/,/<!-- \/CHECKPOINT -->/p' "$STATE_FILE" 2>/dev/null \
                 | grep -v '<!-- /\?CHECKPOINT -->')
    STATUS_BLOCK=$(sed -n '/<!-- STATUS -->/,/<!-- \/STATUS -->/p' "$STATE_FILE" 2>/dev/null \
                   | grep -v '<!-- /\?STATUS -->' | grep -E '^(Epic|Feature|Task):[[:space:]]*[^[:space:]]')
    [ -n "$STATUS_BLOCK" ] && printf '%s\n' "$STATUS_BLOCK"
    if [ -n "$CHECKPOINT" ]; then
        printf '%s\n' "$CHECKPOINT"
    else
        # No markers: an unmigrated or hand-written file. Fall back to a small
        # head slice rather than nothing -- but say so, because a missing
        # checkpoint is a real problem the user should fix, not absorb silently.
        echo "(no CHECKPOINT block — showing the first 20 lines instead;"
        echo " re-create this file from .claude/docs/templates/session-state.md)"
        head -n 20 "$STATE_FILE"
    fi
    echo ""
    echo "Full detail (NOT reproduced here — read the file if you need it): $STATE_FILE"
else
    echo ""
    echo "## No active session state file found"
    echo "Consider maintaining production/session-state/active.md for better recovery."
    echo "Template: .claude/docs/templates/session-state.md"
fi

# --- Files modified this session (unstaged + staged + untracked) ---
echo ""
echo "## Files Modified (git working tree)"

# BOUNDED. These three lists must never be emitted in full, one line per
# file, with no cap. (They were bounded believing this output goes into the
# compacting context; it reaches the debug log, where an unbounded dump still
# costs time and log size.) The checkpoint above was redesigned to be by-reference for exactly
# that reason (see the note at the top of this file); the lists below were left
# unbounded, so the hook still dumped whatever the working tree happened to
# contain at the moment context was scarcest. Measured on a tree with ~5k
# untracked files: 181,125 bytes, roughly 45,000 tokens, of which ~4,984 lines
# were this section. A fresh asset import or un-gitignored build output is
# enough to trigger it.
#
# A count plus a sample is what this section is actually for -- orienting the
# agent after compaction -- and the full list is one `git status` away.
_PC_CAP=20
_pc_list() { # $1=label  $2=newline-separated paths
    [ -n "$2" ] || return 0
    _n=$(printf '%s\n' "$2" | grep -c .)
    echo "$1 ($_n):"
    printf '%s\n' "$2" | head -n "$_PC_CAP" | while read -r f; do [ -n "$f" ] && echo "  - $f"; done
    if [ "$_n" -gt "$_PC_CAP" ]; then
        echo "  ... and $((_n - _PC_CAP)) more (run: git status)"
    fi
}

CHANGED=$(git diff --name-only 2>/dev/null)
STAGED=$(git diff --staged --name-only 2>/dev/null)
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null)

_pc_list "Unstaged changes" "$CHANGED"
_pc_list "Staged changes" "$STAGED"
_pc_list "New untracked files" "$UNTRACKED"

if [ -z "$CHANGED" ] && [ -z "$STAGED" ] && [ -z "$UNTRACKED" ]; then
    echo "  (no uncommitted changes)"
fi

# --- Work-in-progress design docs ---
echo ""
echo "## Design Docs — Work In Progress"

WIP_FOUND=false
# BOUNDED and BATCHED. One `grep -n` per design doc, printing every matching
# line from every file, fails twice over -- the same two ways as above:
# unbounded OUTPUT into a compacting context, and unbounded
# COST -- ~85ms per file, crossing this hook's 10s budget at roughly 90 GDDs.
# Measured: 220 docs 18262ms, 420 docs killed at the timeout.
#
# `xargs -0` bounds the spawn count by ARG_MAX rather than by file count, and
# the NUL delimiter keeps it portable: `-d` is GNU-only, BSD xargs rejects it,
# and the pipeline swallows that error silently. The
# report is capped. What the agent needs after compaction is "these docs are
# unfinished", not every TODO line in the project.
_WIP_HITS=$(printf '%s\n' design/gdd/*.md | tr '\n' '\0' \
    | xargs -0 grep -lE "TODO|WIP|PLACEHOLDER|\[TO BE|\[TBD\]" 2>/dev/null || true)
if [ -n "$_WIP_HITS" ]; then
    WIP_FOUND=true
    _wn=$(printf '%s\n' "$_WIP_HITS" | grep -c .)
    echo "$_wn design doc(s) contain TODO/WIP/PLACEHOLDER markers:"
    printf '%s\n' "$_WIP_HITS" | head -n "$_PC_CAP" | while read -r f; do
        [ -n "$f" ] && echo "  - $f"
    done
    if [ "$_wn" -gt "$_PC_CAP" ]; then
        echo "  ... and $((_wn - _PC_CAP)) more"
    fi
fi

if [ "$WIP_FOUND" = false ]; then
    echo "  (no WIP markers found in design docs)"
fi

# --- Log compaction event ---
SESSION_LOG_DIR="production/session-logs"
mkdir -p "$SESSION_LOG_DIR" 2>/dev/null
echo "Context compaction occurred at $(date)." \
    >> "$SESSION_LOG_DIR/compaction-log.txt" 2>/dev/null

echo ""
echo "## Recovery Instructions"
echo "After compaction, read $STATE_FILE to recover full working context."
echo "Then read any files listed above that are being actively worked on."
echo "=== END SESSION STATE ==="

exit 0
