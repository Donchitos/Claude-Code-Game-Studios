#!/bin/bash
# rotate-session-state.sh — move active.md's narrative into the session log,
# leaving the checkpoint behind.
#
# WHY THIS EXISTS
# active.md is two things at once: a small machine-read CHECKPOINT that hooks
# inject, and a free-form narrative for humans. Only the first is bounded by the
# schema. Left alone the second grows without limit -- it reached 712 lines /
# 44 KB before this script existed -- and every session paid to preview a file
# that was mostly history the commit log already records.
#
# Rotation keeps the checkpoint, appends the narrative to a dated file under
# production/session-logs/, and starts the Notes section fresh. Nothing is
# deleted.
#
# EXPLICIT INVOCATION ONLY. No hook calls this. session-start.sh observes that
# the file is large and names this script; the user decides whether to run it.
# Helpers here emit observations, never verdicts (CLAUDE.md) -- and silently
# moving a user's working notes would be a verdict.
#
# Usage:
#   bash .claude/scripts/rotate-session-state.sh            # rotate
#   bash .claude/scripts/rotate-session-state.sh --dry-run  # show, change nothing
#   bash .claude/scripts/rotate-session-state.sh --help

set -u
cd "$(dirname "$0")/../.." || exit 1

STATE="production/session-state/active.md"
LOGDIR="production/session-logs"
DRY=0

case "${1:-}" in
  --help|-h)
    sed -n '2,30p' "$0" | sed 's/^# \?//'
    exit 0 ;;
  --dry-run) DRY=1 ;;
  "") ;;
  *) echo "unknown argument: $1 (try --help)" >&2; exit 2 ;;
esac

if [ ! -f "$STATE" ]; then
  echo "no session state at $STATE — nothing to rotate"
  exit 0
fi

if ! grep -q '<!-- /CHECKPOINT -->' "$STATE"; then
  echo "REFUSED: $STATE has no <!-- /CHECKPOINT --> marker."
  echo "  Rotation splits the file at that marker, so without it this script"
  echo "  cannot tell the checkpoint from the narrative and would move both."
  echo "  Re-create the file from .claude/docs/templates/session-state.md first."
  exit 3
fi

# Everything through the marker is the checkpoint; everything after is narrative.
SPLIT=$(grep -n '<!-- /CHECKPOINT -->' "$STATE" | head -1 | cut -d: -f1)
TOTAL=$(wc -l < "$STATE" | tr -d ' ')
NARRATIVE=$((TOTAL - SPLIT))

if [ "$NARRATIVE" -le 5 ]; then
  echo "narrative is $NARRATIVE lines — nothing worth rotating"
  exit 0
fi

# Date comes from the filesystem, not `date`, so a dry run and the real run
# agree and repeated runs on the same day append to one file.
STAMP=$(date +%Y-%m-%d 2>/dev/null || echo "undated")
ARCHIVE="$LOGDIR/session-state-$STAMP.md"

if [ "$DRY" = "1" ]; then
  echo "DRY RUN — no changes written"
  echo "  checkpoint kept : lines 1-$SPLIT"
  echo "  narrative moved : lines $((SPLIT + 1))-$TOTAL ($NARRATIVE lines)"
  echo "  destination     : $ARCHIVE"
  exit 0
fi

mkdir -p "$LOGDIR" 2>/dev/null

{
  echo ""
  echo "---"
  echo ""
  echo "## Rotated from active.md on $STAMP ($NARRATIVE lines)"
  echo ""
  tail -n "+$((SPLIT + 1))" "$STATE"
} >> "$ARCHIVE"

# Write the truncated state beside the file it replaces, not in a system temp
# dir. `${TMPDIR:-/tmp}` assumes /tmp exists and is writable; where it is not,
# the redirect failed, `&&` skipped the mv, and the script then printed
# "rotated N lines" and a line count it had not produced -- reporting a
# rotation that did not happen, while the narrative it had ALREADY appended to
# the archive stayed in active.md and got archived again on the next run.
# mktemp in the state directory needs no external writable location and keeps
# the mv on one filesystem, so it stays atomic.
TMP=$(mktemp "$(dirname "$STATE")/.ccgs-rotate-XXXXXX" 2>/dev/null) || TMP=""
if [ -z "$TMP" ]; then
  echo "rotate-session-state: FAILED — cannot create a temporary file in $(dirname "$STATE")" >&2
  echo "  $STATE is UNCHANGED. The narrative was appended to $ARCHIVE and is still" >&2
  echo "  in $STATE; remove one copy before rotating again." >&2
  exit 1
fi

if ! {
  head -n "$SPLIT" "$STATE"
  echo ""
  echo "---"
  echo ""
  echo "## Notes"
  echo ""
  echo "_Narrative through $STAMP rotated to \`$ARCHIVE\`._"
  echo ""
} > "$TMP"; then
  rm -f "$TMP"
  echo "rotate-session-state: FAILED — could not write $TMP" >&2
  echo "  $STATE is UNCHANGED (the narrative is now in BOTH $ARCHIVE and $STATE)." >&2
  exit 1
fi

if ! mv "$TMP" "$STATE"; then
  rm -f "$TMP"
  echo "rotate-session-state: FAILED — could not replace $STATE" >&2
  exit 1
fi

echo "rotated $NARRATIVE lines -> $ARCHIVE"
echo "$STATE is now $(wc -l < "$STATE" | tr -d ' ') lines"
