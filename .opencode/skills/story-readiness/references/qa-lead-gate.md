# Phase 5: QA lead review (QL-STORY-READY)

Read only when the `review_gate` line says `skill-gates=run` (`review_mode: full`).

Hand the review to the `qa-lead` agent, once per story, with gate
**QL-STORY-READY**. The agent reads its own gate file; do not read it here.

Brief:
- **Objective:** judge whether this story's acceptance criteria are testable enough
  to implement against.
- **Give it:** the story path; its type (Logic / Integration / Visual/Feel / UI /
  Config/Data), which the gate branches on; every acceptance criterion, verbatim;
  the requirement it covers (TR-ID and text); each dependency and its state
  (exists, Draft, missing); this run's verdict.
- **Return:** ADEQUATE, GAPS with the list, INADEQUATE with the list, or NOT
  ASSESSED naming the missing input.
- **Boundaries:** it reads the story and the files the brief names; it edits
  nothing.

Act on its report:

- **ADEQUATE**: the story is cleared.
- **GAPS**: show the gaps, then ask: "How do you want to handle these?" Options:
  Draft the fixes / Accept and go on / Discuss further.
- **INADEQUATE**: the story is not READY. The verdict becomes at least NEEDS WORK
  (BLOCKED stays BLOCKED). List the gaps, restate the verdict, then ask whether to
  draft fixes or go on anyway. If the user goes on, the verdict stays and the
  report says "proceeding despite QL-STORY-READY: INADEQUATE (user override)".
  Never a silent READY.
- **NOT ASSESSED**: the gate judged nothing; never read it as ADEQUATE. Name the
  missing input and offer to supply it and run the gate again. Otherwise a READY
  verdict becomes NOT ASSESSED; NEEDS WORK and BLOCKED stand.
