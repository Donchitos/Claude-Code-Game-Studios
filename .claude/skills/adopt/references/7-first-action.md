# /adopt — Phase 7: Offer First Action

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 7: Offer First Action

After writing the plan, don't stop there. Pick the single highest-priority gap
and offer to handle it immediately using `AskUserQuestion`. Choose the first
branch that applies:

**If Phase 2g found a v1.0 project needing migration:** offer the converter run
described there — report what the dry run listed and ask "May I run the
converter? It writes `project.yaml` and `production/migration-report.md`."
Every other fix reads config through it, so it comes first.

**If there are parenthetical status values in systems-index.md:**
Use `AskUserQuestion`:
- "The most urgent fix is `systems-index.md` — [N] rows have parenthetical status
  values (e.g. `Needs Revision (see notes)`) that break /gate-check,
  /create-stories, and /architecture-review right now. I can fix these in-place."
  - "Fix it now — edit systems-index.md"
  - "I'll fix it myself"
  - "Done — leave me with the plan"

**If ADRs are missing `## Status` (and no parenthetical issue):**
Use `AskUserQuestion`:
- "The most urgent fix is adding `## Status` to [N] ADR(s): [list filenames].
  Without it, /story-readiness silently passes all ADR checks. Start with
  [first affected filename]?"
  - "Yes — retrofit [first affected filename] now"
  - "Retrofit all [N] ADRs one by one"
  - "I'll handle ADRs myself"

**If GDDs are missing Acceptance Criteria (and no blocking issues above):**
Use `AskUserQuestion`:
- "The most urgent gap is missing Acceptance Criteria in [N] GDD(s):
  [list filenames]. Without them, /create-stories can't generate stories.
  Start with [highest-priority GDD filename]?"
  - "Yes — add Acceptance Criteria to [GDD filename] now"
  - "Do all [N] GDDs one by one"
  - "I'll handle GDDs myself"

**Otherwise, if any BLOCKING or HIGH gap remains** (one no branch above names —
e.g. a missing TR registry):
Use `AskUserQuestion`:
- "The most urgent remaining gap is [first BLOCKING or HIGH item in the plan] —
  [one line on what it breaks]. Start on it now?"
  - "Yes — start on [item]"
  - "Show me that plan item first"
  - "Done — leave me with the plan"

**If no BLOCKING or HIGH gaps exist:**
Use `AskUserQuestion`:
- "No blocking gaps — this project is template-compatible. What next?"
  - "Walk me through the medium-priority improvements"
  - "Run /project-stage-detect for a broader health check"
  - "Done — I'll work through the plan at my own pace"

> **Adoption plan saved to `docs/adoption-plan-[date].md`.** Re-run `/adopt` at any time to re-check remaining gaps as you complete them.

---
