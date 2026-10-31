# Phase 4: Producer review (PR-EPIC)

Read only when the `review_gate` line says `skill-gates=run` (`review_mode: full`).
Run it once every epic in scope is defined and before any write. The agent reads its
own gate file; do not read it here.

Hand the review to the `producer` agent with gate **PR-EPIC**. Brief:

- **Objective:** judge whether the epic structure for this layer is realistic to
  deliver.
- **Give it:** every epic defined in Phase 3 with its scope summary and governing
  ADR count, the layer being processed, the milestone timeline and the team's
  capacity (from `production/milestones/` and `project.yaml`'s `team.size`, or
  "none recorded").
- **Return:** REALISTIC, CONCERNS, UNREALISTIC, or NOT ASSESSED naming a missing
  input, with reasons.
- **Boundaries:** it writes no file.

Act on the verdict:

- **REALISTIC:** go to Phase 5.
- **CONCERNS:** ask "The producer raised concerns about the epic structure. How do
  you want to go on?" Options: Go on as planned — I accept the concerns / Revise the
  epic boundaries / Stop — I want to rethink the scope. Revise: change the epics,
  show them again, and run the review again. Stop: `Verdict: BLOCKED — user is
  rethinking the epic scope`.
- **UNREALISTIC:** offer to split overscoped epics or merge underscoped ones,
  show the revised epics, and run the review again before writing.
- **NOT ASSESSED:** it is not REALISTIC. Name what was missing, then supply it and
  run it again; or, when the user chooses to go on without it, go to Phase 5 and
  state `PR-EPIC: NOT ASSESSED — [input]` in the reply and the closing block.

Write no epic until the review resolves.
