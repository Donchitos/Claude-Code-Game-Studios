#!/bin/bash
# story-status.sh -- the story files' Status lines, in the order the minimal
# route takes them. Injected into /help and /sprint-status before the model reads
# either skill:
#
#   !`bash "${CLAUDE_SKILL_DIR}/../../scripts/story-status.sh"`
#
# WHY A SCRIPT. The route's rule is "an In Review story is next (its work is
# written; close it), else an In Progress one, else the first Ready or Not
# Started one in build order". Given every status line at once, a small model
# ranked them by file order and got the Ready/Not Started case wrong; listing the
# stories already in the route's order leaves nothing to rank. (In Review comes
# first: its work is already written, /story-done is quick, and closing it
# keeps finished work from piling up behind started work.)
#
# OBSERVATIONS ONLY (CLAUDE.md): each line is a story and the status as written.
# The skill decides what the first line means; nothing here says "next".
#
# Output, one line per unfinished story, file-name (build) order within a group:
#   IN_REVIEW    <path>
#   IN_PROGRESS  <path>
#   TODO         <path>  (Ready | Not Started)
#   BLOCKED      <path>  (<status as written>)
#   OTHER        <path>  (<status as written>)   -- e.g. "Not Done", "Draft"
#   NO_STATUS    <path>
#   COMPLETE     <done> of <total>
# or `STORIES      none` when there are no story files.
#
# Reads the same files and Status formats as statusline.sh's story count
# (production/epics/*/story-*.md; `Status: X`, `**Status:** X`,
# `> **Status**: X`, `- **Status**: X`) and counts "done" by the same rule --
# the value's leading word, in any case, is Complete or Done: `Done.` counts,
# `Not Done` and `Completed` do not -- so the two cannot disagree on "done".
# Builtins and one awk -- no Python, no per-file process.

# The project root is two levels above this file: the injected command runs from
# wherever the skill's shell starts, which need not be the root.
cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null || { echo "STORIES      none"; exit 0; }

files=()
for f in production/epics/*/story-*.md; do
  [ -f "$f" ] && files+=("$f")
done
if [ "${#files[@]}" -eq 0 ]; then
  echo "STORIES      none"
  exit 0
fi

printf '%s\n' "${files[@]}" | LC_ALL=C sort | awk '
  {
    f = $0; st = ""; found = 0
    while ((getline line < f) > 0) {
      sub(/\r$/, "", line); sub(/^[ \t]+/, "", line)
      sub(/^> /, "", line); sub(/^- /, "", line); gsub(/\*/, "", line)
      if (line ~ /^Status:/) {
        st = substr(line, 8); sub(/^[ \t]+/, "", st); sub(/[ \t]+$/, "", st)
        found = 1; break
      }
    }
    close(f)
    n++; s = tolower(st)
    if (!found)                                   { other[++no] = "NO_STATUS    " f }
    else if (s ~ /^(complete|done)([^a-z]|$)/)    { done++ }
    else if (s ~ /^in progress([^a-z]|$)/)        { prog[++np] = "IN_PROGRESS  " f }
    else if (s ~ /^in review([^a-z]|$)/)          { rev[++nr]  = "IN_REVIEW    " f }
    else if (s ~ /^(ready|not started)([^a-z]|$)/) { todo[++nt] = "TODO         " f "  (" st ")" }
    else if (s ~ /^blocked([^a-z]|$)/)            { blk[++nb]  = "BLOCKED      " f "  (" st ")" }
    else                                          { other[++no] = "OTHER        " f "  (" st ")" }
  }
  END {
    for (i = 1; i <= nr; i++) print rev[i]
    for (i = 1; i <= np; i++) print prog[i]
    for (i = 1; i <= nt; i++) print todo[i]
    for (i = 1; i <= nb; i++) print blk[i]
    for (i = 1; i <= no; i++) print other[i]
    printf "COMPLETE     %d of %d\n", done, n
  }'
exit 0
