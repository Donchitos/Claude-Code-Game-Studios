# /story-done — Phase 5: Lead Programmer Code Review Gate

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 5: Lead Programmer Code Review Gate

**Review mode check** — apply before spawning LP-CODE-REVIEW:
- `solo` → skip. Note: "LP-CODE-REVIEW skipped — Solo mode." Proceed to Phase 6 (completion report).
- `lean` → use `AskUserQuestion` before proceeding:
  - Prompt: "Code review is skipped in lean mode. Did you run `/code-review` on the implemented files?"
  - Options:
    - `Yes — /code-review passed or was approved with suggestions`
    - `No — skipping code review for this story`
    - `No — I'll run /code-review before the sprint close-out`
  - Record the answer in the completion notes (Phase 7). All three options proceed to Phase 6.
- `full` → spawn as normal.

Spawn `lead-programmer` via `Agent` using gate **LP-CODE-REVIEW** (`.claude/docs/director-gates/lp-code-review.md`).

Pass: implementation file paths, story file path, relevant GDD section, governing ADR.

Present the verdict to the user. If CONCERNS, surface them via `AskUserQuestion`:
- Options: `Revise flagged issues` / `Accept and proceed` / `Discuss further`
If REJECT, do not proceed to Phase 6 verdict until the issues are resolved.
If NOT ASSESSED, name the input the gate said was missing and never treat it as APPROVE: supply it and re-run the gate, or carry it to Phase 6, where it keeps the verdict at best NOT ASSESSED.

If the story has no implementation files yet (verdict is being run before coding is done), skip this phase and note: "LP-CODE-REVIEW skipped — no implementation files found. Run after implementation is complete."

---
