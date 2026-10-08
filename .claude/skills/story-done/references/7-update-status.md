# /story-done — Phase 7: Update Story Status

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 7: Update Story Status

**Reached one of two ways**: normally, immediately after a COMPLETE or
COMPLETE-WITH-NOTES verdict in Phase 6; or, after a BLOCKED **or NOT ASSESSED**
verdict, only if the user explicitly asks to close the story despite the
blockers (Phase 6 does not advance here on its own in either case).

**Automation note**: This is the story-completion gate. Closing a story whose
verdict is BLOCKED (failing acceptance criteria) **or NOT ASSESSED** (criteria
nobody could evaluate) — the "Accept deviations as-is and close anyway" option —
is a `scope_changes` decision. Call
`is_always_ask_category scope_changes`; when it returns 0 (the default), this
gate prompts via `AskUserQuestion` **regardless of `modes.automation`** —
autonomous mode must NOT silently close a BLOCKED story, even when the user's
own request is what got you here. For a COMPLETE or COMPLETE-WITH-NOTES
verdict, autonomous mode may pick "Close the story (Recommended)" and record
it via `log_decision`.

Use `AskUserQuestion` before writing anything:
- Prompt: "Verification complete. How do you want to proceed?"
- Options:
  - `Close the story — update file, mark Complete, log notes (Recommended)`
  - `Close and log advisory deviations as tech debt in docs/tech-debt-register.md`
  - `There are issues I want to fix first — don't close yet`
  - `Accept deviations as-is and close anyway`

If "Close", "Close and log tech debt", or "Accept deviations": edit the story file.
If "Close and log tech debt": after updating the story file, also append the advisory deviations to `docs/tech-debt-register.md` (create the file if it does not exist).
If "Fix first": stop here and list what the user flagged. Do not write any files.

1. Update the status field: `Status: Complete`
2. Update the `Last Updated:` field in the story header to today's date (format: `YYYY-MM-DD`). If the field does not exist, add it after the `Status:` line.
3. Add a `## Completion Notes` section at the bottom:

```markdown
## Completion Notes
**Completed**: [date]
**Criteria**: [X/Y passing] ([any deferred items listed])
**Deviations**: [None] or [list of advisory deviations]
**Test Evidence**: [Logic: test file at path | Visual/Feel: evidence doc at path | None required (Config/Data)]
**Code Review**: [Pending / Complete / Skipped]
```

4. If the user chose "Close and log tech debt": append each advisory deviation to `docs/tech-debt-register.md` as one row of `/tech-debt`'s register table — the format under "Debt Register Format" in `.claude/skills/tech-debt/SKILL.md` — so `/tech-debt report` can date it from its `Added` column:
   ```
   | TD-[next free NNN] | [category] | [deviation description] — from [story file path] | [files] | [S/M/L/XL] | [Low/Med/High/Critical] | — | Open | [YYYY-MM-DD] | Backlog |
   ```
   Category is one of `/tech-debt`'s six (Architecture, Code Quality, Test, Documentation, Dependency, Performance); Effort and Impact are your estimate from the deviation; Priority stays `—` until `/tech-debt prioritize` scores it; `Added` is today. If the file does not exist, create it with that format's heading, `Last updated:` and `Total items:` lines and table header; if it exists, update those two lines (and add the table header first if the file has none yet).

5. **Update `production/sprint-status.yaml`** (if it exists):
   - Find the entry matching this story's file path or ID
   - Set `status: done` and `completed: [today's date]`
   - Update the top-level `updated` field
   - This is a silent update — no extra approval needed (already approved in step above)

6. **Suggest a git commit**: Output a ready-to-use commit command covering the implementation files from the dev-story summary and the updated story file:

```
Suggested commit:
git add [code-root and test-root files changed during implementation] [story-file-path]
git commit -m "feat: [story title] ([TR-ID])"
```

The `validate-commit.sh` hook blocks invalid data JSON and warns on hardcoded gameplay values and TODOs without an owner. It does not read the commit message: the story and design references go there from you.

### Session State Update

After updating the story file, silently update the checkpoint in
`production/session-state/active.md` — **overwrite the `<!-- CHECKPOINT -->` …
`<!-- /CHECKPOINT -->` block, never append** (schema:
`.claude/docs/templates/session-state.md`). `session-start.sh` shows exactly
that block when the next session opens. Fill **Next step** from Phase 8, so it
names the same next story the user is shown:

    <!-- CHECKPOINT -->
    **Updated:** [date]
    **Branch:** `[current git branch]`
    **Current task:** /story-done — [story file path] closed: [COMPLETE / COMPLETE WITH NOTES / NOT ASSESSED / BLOCKED]
    **Next step:** [/story-done [next story path] for an In Review story, else /dev-story [next story path] — or "build order done: play the build" — or the blocker to clear when every unfinished story is blocked — or the sprint's next step]
    **Blocked on:** [nothing, or what blocked this verdict]
    **Files in progress:** none
    **Open questions:** [tech debt logged: N items, or none]
    <!-- /CHECKPOINT -->

If `active.md` does not exist, create it from the template. If it exists with no
markers (a file from before the schema), insert the template's STATUS and
CHECKPOINT blocks at the top and leave the rest untouched.
Confirm in conversation: "Session state updated."

---
