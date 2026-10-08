# /review-all-gdds — Phase 6: Write Report and Flag GDDs

> Part of `/review-all-gdds`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 6: Write Report and Flag GDDs

Use `AskUserQuestion` for write permission:
- Prompt: "May I write this review to `design/gdd/gdd-cross-review-[date].md`?"
- Options: `[A] Yes — write the report` / `[B] No — skip`

> **`[date]` here means ISO 8601 — `YYYY-MM-DD`, e.g.
> `gdd-cross-review-2026-08-19.md`. This is not a style preference.**
> `.claude/scripts/review-scope.sh` picks the prior review with
> `sort | tail -1`, so lexical order IS chronological order only for ISO dates.
> Written as `aug-19-2026` or `19-08-2026`, the wrong file is chosen as the
> baseline, the changed-set is computed from it, and GDDs modified since the
> real last review silently escape the next one. That is the same
> quiet-escape failure the three fixes documented at the top of that script
> exist to prevent.

If any GDDs are flagged for revision, use a second `AskUserQuestion`:
- Prompt: "Should I update the systems index to mark these GDDs as needing revision? ([list of flagged GDDs])"
- Options: `[A] Yes — update systems index` / `[B] No — leave as-is`
- If yes: update each flagged GDD's Status field in systems-index.md to "Needs Revision".
  (Do NOT append parentheticals to the status value — other skills match "Needs Revision"
  as an exact string and parentheticals break that match.)

### Session State Update

After writing the report (and updating systems index if approved), silently
append to `production/session-state/active.md`:

    ## Session Extract — /review-all-gdds [date]
    - Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]
    - GDDs reviewed: [N of M present]
    - Phases not run: [names, or "None"]
    - Flagged for revision: [comma-separated list, or "None"]
    - Blocking issues: [N — brief one-line descriptions, or "None"]
    - Recommended next: [the Phase 7 handoff action, condensed to one line]
    - Report: design/gdd/gdd-cross-review-[date].md   ← only if user approved the write
    - Report: (not written — user declined at [date])  ← only if user declined the write

Use the appropriate line based on the user's response to the write-permission widget in Phase 6.

If `active.md` does not exist, create it with this block as the initial content.
Confirm in conversation: "Session state updated."

---
