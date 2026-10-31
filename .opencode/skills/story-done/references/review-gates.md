# Phase 6: Review gates at review mode full

Read only when the `review_gate` line says `skill-gates=run`. Run both gates before
the Phase 7 report. Each agent reads its own gate file; do not read it here.

## QL-TEST-COVERAGE

Skip it at `qa.level: minimal` (note `QL-TEST-COVERAGE skipped — qa.level minimal`)
and for a Config/Data story (no code tests).

Hand the review to the `qa-lead` agent with gate **QL-TEST-COVERAGE**. Brief:

- **Objective:** judge whether the story's tests cover what was specified, not
  only whether the files exist.
- **Give it:** the story path and type; the test files Phase 4 found (exact paths,
  or "none found"); the story's `## QA Test Cases` and `## Acceptance Criteria`;
  the GDD's acceptance criteria and edge cases for the system, or "no GDD for this
  system" (at `workflow: minimal` the story's own criteria are the spec).
- **Return:** ADEQUATE, GAPS, INADEQUATE, or NOT ASSESSED naming a missing input,
  with the gaps listed.
- **Boundaries:** it writes no file.

Act on the verdict:

- **ADEQUATE:** go on.
- **GAPS:** ADVISORY — "QA lead found coverage gaps: [list]. The story can close;
  address them in a follow-up story."
- **INADEQUATE:** BLOCKING — "critical logic is untested: [list]."
- **NOT ASSESSED:** never ADEQUATE. Supply the input and run it again, or carry it
  to the verdict, where it keeps the story at best NOT ASSESSED.

## LP-CODE-REVIEW

No implementation file yet: skip it, note `LP-CODE-REVIEW skipped — no
implementation files found`, and Reviewed by is `self, no independent review`.

Hand the review to the `lead-programmer` agent with gate **LP-CODE-REVIEW**. Brief:

- **Objective:** review the story's implementation against its GDD section and
  governing ADR.
- **Give it:** the implementation file paths, the story path, the GDD path and
  section, the ADR path. It reads the GDD and ADR by section, never whole.
- **Return:** APPROVE, CONCERNS, REJECT, or NOT ASSESSED naming a missing input.
- **Boundaries:** it edits no file.

Act on the verdict:

- **APPROVE:** Reviewed by is `lead-programmer`.
- **CONCERNS:** ask: "The lead programmer raised concerns. How do you want to go
  on?" Options: Revise the flagged issues / Accept and go on / Discuss further.
- **REJECT:** no COMPLETE verdict until the issues are fixed.
- **NOT ASSESSED:** never APPROVE. Supply the input and run it again, or carry it
  to the verdict, where it keeps the story at best NOT ASSESSED.
