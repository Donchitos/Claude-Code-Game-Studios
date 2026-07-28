---
name: project-scene-world-management-review-history
description: Status and recurring defect pattern for design/gdd/scene-world-management.md across its review cycles (as of 2026-07-10 re-review #2)
metadata:
  type: project
---

`design/gdd/scene-world-management.md` has gone through 2 full reviews plus
2 post-review revisions, all on 2026-07-10. Full history in
`design/gdd/reviews/scene-world-management-review-log.md`.

- Review #1 (first full review): 3 blockers (warp-reset trap, reset-vs-signal
  race, missing boot-order). Fixed same session.
- Re-review #1: found the fix for one trap (warp-reset) reintroduced a new
  trap in a different subsystem (undo-abort trap via Building's undo-clear on
  transition-begin) — same irreversible-side-effect-on-begin bug class, plus
  a World Root topology contradiction. Fixed same session (Core Rule 7
  side-effect discipline: begin=reversible, complete=irreversible/success-only).
- Re-review #2 (my pass, 2026-07-10): found the re-review #1 fix (Core Rule 7)
  closed the irreversible-effect trap but opened a mirror-image trap on the
  *reversible*-effect side — see [[feedback-signal-abort-unwind-check]].
  Transition-abort now permanently freezes Camera & Input's Suspended state
  (cascading through Building System, Building UI, Villager Info UI), with no
  defined recovery signal, directly contradicting AC8 ("full control" after
  abort). Also found the Booting state's failure-exit was never formalized in
  the States table the way Transitioning's was (Edge Cases/AC17 describe
  boot-halt, but the States table's Booting row still only has the
  happy-path exit condition). Verdict: NEEDS REVISION (2 BLOCKING + several
  RECOMMENDED — AC13 missing scope tag, Core Rule 2's hosted-systems list
  incomplete vs. Dependencies table, cancel-order wording contradiction with
  building-system.md).

**Why this matters for future reviews:** this GDD has now shown the same
defect SHAPE three times in a row — a fix for one abort/failure-path bug
introduces a structurally similar bug elsewhere in the same signal chain.
**How to apply:** if asked to re-review this file again (re-review #3+),
specifically re-audit every signal-gated recovery/unwind path as its own
checklist item, not just re-verify the two bugs found in re-review #2.

- Re-review #3 (my pass, 2026-07-10, systems-designer only, targeted
  adversarial pass — not a full multi-specialist round): re-review #2's
  Core Rule 7 three-signal contract HOLDS at the rule-definition level and
  its reciprocal patches (camera-input.md States/Dependencies/AC10,
  building-system.md Rule 17/AC32b, Booting States-table failure-exit,
  cancel-ordering, AC10(c) math, AC19, AC13 tag, hosted-systems list) all
  verified HOLDING against the actual files. But found 2 new BLOCKING gaps,
  both propagation/coverage misses of the re-review #2 fix rather than a
  full mirror-trap: (1) the double-trigger debounce (Edge Case row 1 + AC7)
  is STILL worded "ignored until the first completes" — two-signal language
  left over after Core Rule 7 was extended to three signals; Core Rule 7
  itself says the debounce "releases on EITHER of them — never on complete
  alone," so the Edge Case/AC7 text directly contradicts the Core Rule this
  is the exact scenario [[feedback-signal-abort-unwind-check]] pre-flagged
  as a risk ("if a debounce rule uses the word 'completes', verify it's
  keyed to state exit, not the success-only signal") — the checklist item
  predicted the defect before finding it. (2) a NEW defect shape, not a
  repeat of the prior 3 rounds: [[feedback-directional-asymmetry-check]] —
  the abort contract is worded entirely around "target scene fails to
  LOAD," but Core Rule 5 defines the return direction as an UNLOAD of the
  Dungeon scene + reconnect to the already-running Valley, which the
  contract never addresses — a potential undefined-signal deadlock on
  return-teardown failure, and no documented safeguard against a
  repeated-abort retry-loop stranding the player in a dungeon. Also 2
  RECOMMENDED: boot-error HALT is referenced as a destination but has no
  row of its own in the States table (no Exit Condition defined at all —
  acceptable if genuinely terminal, but that must be stated, not implied by
  omission); AC16/the pause Edge Case only covers the transition-COMPLETE
  happy path, never testing abort-while-paused (raw-delta unwind under a
  paused game is unspecified). Verdict: NEEDS REVISION (2 BLOCKING + 2
  RECOMMENDED + 2 NICE-TO-HAVE).
**How to apply (updated):** the propagation-miss defect (finding shape #1
above) means "the Core Rule was fixed correctly" is NOT sufficient —
grep every OTHER place the same concept is described (Edge Cases, ACs,
Interactions, Dependencies) for stale terminology, even when the Core Rule
itself is fully correct. The directional-asymmetry defect (shape #2) means
future rounds should also check bidirectional transitions for one-direction-
only wording, independent of the signal-count pattern already tracked.
