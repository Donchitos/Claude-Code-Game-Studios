# Test Evidence: [Story Title]

> **Story**: `[path to story file]`
> **Story Type**: [Visual/Feel | UI]
> **Date**: [date]
> **Tester**: [who performed the test]
> **Build / Commit**: [version or git hash]

---

## What Was Tested

[One paragraph describing the feature or behaviour that was validated. Include
the acceptance criteria numbers from the story that this evidence covers.]

**Acceptance criteria covered**: [AC-1, AC-2, AC-3]

---

## Acceptance Criteria Results

| # | Criterion (from story) | Result | Notes |
|---|----------------------|--------|-------|
| AC-1 | [exact criterion text] | PASS / FAIL | [any observations] |
| AC-2 | [exact criterion text] | PASS / FAIL | |
| AC-3 | [exact criterion text] | PASS / FAIL | |

---

## Screenshots / Video

List all captured evidence below. Store files in the same directory as this
document or in `production/qa/evidence/[story-slug]/`.

**The file must actually be on disk.** Visual/Feel and UI gates are BLOCKING by
default, and `/story-done` and `/test-evidence-review` glob for the image — a
filename listed here with no file beside it does not satisfy the gate.

| # | Filename | What It Shows | Acceptance Criterion |
|---|----------|--------------|----------------------|
| 1 | `[filename.png]` | [brief description of what is visible] | AC-1 |
| 2 | `[filename.png]` | | AC-2 |

*If video: note the timestamp and what it demonstrates.*

---

## Test Conditions

- **Game state at start**: [e.g., "fresh save, player at level 1, no items"]
- **Platform / hardware**: [e.g., "Windows 11, GTX 1080, 1080p"]
- **Framerate during test**: [e.g., "stable 60fps" or "~45fps — within budget"]
- **Any special setup required**: [e.g., "dev menu used to trigger specific state"]

---

## Observations

[Anything noteworthy that didn't cause a FAIL but should be recorded. Examples:
minor visual jitter, frame dip under load, behaviour that technically passes
but felt slightly off. These become candidates for polish work.]

- [Observation 1]
- [Observation 2]

If nothing notable: *No significant observations.*

---

## Sign-Off

A **Visual/Feel** story needs the lead sign-off below — the art-director, or the
designer who owns the feature — before `/story-done` marks it COMPLETE. A **UI**
story is closed by the retained screenshot of each screen it touched; a sign-off
here is welcome but not required (`.claude/docs/coding-standards.md`).

**Solo developers**: you may sign as the lead yourself. The intent is that
someone deliberately reviews the evidence before marking complete.

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead (art-director / designer) | | | [ ] Approved |

*Optional:* add a row for anyone else whose review your team wants, such as the
developer or the QA lead. `/story-done` and `/test-evidence-review` treat every
row in this table as required, so add one only for someone who will sign.

**Any sign-off can be marked "Deferred — [reason]"** if the person is
unavailable. Deferred sign-offs must be resolved before the story advances
past the sprint review.

---

*Template: `.claude/docs/templates/test-evidence.md`*
*Used for: Visual/Feel and UI story type evidence records*
*Location: `production/qa/evidence/[story-slug]-evidence.md`*
