# /dev-story — Phase 7: Update Session State

> Part of `/dev-story`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 7: Update Session State

Silently update the checkpoint in `production/session-state/active.md` —
**overwrite the `<!-- CHECKPOINT -->` … `<!-- /CHECKPOINT -->` block, never
append** (schema: `.claude/docs/templates/session-state.md`). `session-start.sh`
shows exactly that block when the next session opens, so it is what a cold
resume starts from:

```
<!-- CHECKPOINT -->
**Updated:** [date]
**Branch:** `[current git branch]`
**Current task:** /dev-story — [story-path] ([story title])
**Next step:** /story-done [story-path] (at standard/full: /code-review [files] first)
**Blocked on:** [nothing, or the blocker]
**Files in progress:** [files changed, comma-separated; test file included]
**Run result:** [the Phase 6 `Run result:` line, verbatim — `/story-done` reads it here]
**Open questions:** [none, or one line each]
<!-- /CHECKPOINT -->
```

**Next step** follows the Phase 6 result — the line above is the Implementation
Complete one. On **INCOMPLETE** write
`**Next step:** /dev-story [story-path] — resume: [the breakage Phase 6 named]`.
On **BLOCKED** (Phase 2) write the unblocking action instead —
`/architecture-decision accept ADR-NNNN`, the dependency story to finish, the
manifest diff to review — and fill **Blocked on**. `/help` reads this line: a
checkpoint that says `/story-done` tells it the work is written.

If `active.md` does not exist, create it from the template. If it exists with no
markers (a file from before the schema), insert the template's STATUS and
CHECKPOINT blocks at the top and leave the rest untouched. Confirm: "Session
state updated."

---
