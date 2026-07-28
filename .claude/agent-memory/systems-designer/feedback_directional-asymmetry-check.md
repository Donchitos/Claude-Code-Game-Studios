---
name: feedback-directional-asymmetry-check
description: When a transition/signal contract is worded around one direction of a bidirectional operation (e.g. "load"), verify the reverse direction (e.g. "unload") is covered by the same contract, not silently assumed
metadata:
  type: feedback
---

When a state machine has a bidirectional transition (A→B and B→A using the
same state, e.g. a shared "Transitioning" state for both dungeon-entry and
dungeon-exit), and the failure/abort contract for that state is worded using
language specific to ONE direction's mechanics (e.g. "the target scene fails
to LOAD"), explicitly check whether that wording still makes sense for the
reverse direction's actual mechanics. Do not assume symmetric prose implies
symmetric coverage.

**Why:** Found in `design/gdd/scene-world-management.md` re-review #3
(2026-07-10). Core Rule 5 establishes that returning from a dungeon is an
UNLOAD/free of the Dungeon scene plus reconnection to the Valley scene, which
was NEVER unloaded (Core Rule 4 — it keeps simulating in the background).
But the three-signal abort contract (Core Rule 7), the Transitioning row's
Exit Condition, and the Edge Case row are all worded exclusively as "the
target scene fails to LOAD." For the entry direction this is correct; for
the return direction it is close to meaningless (the "target," Valley, is
already loaded and running — there is nothing to load). The GDD never
explicitly states what a return-transition failure IS (an unload failure? a
teardown/reconnect failure?) or whether return transitions can abort at all.
Left unresolved, this is a real state-machine hole: if a return's teardown
fails for any reason, there may be no signal defined that fires (neither
COMPLETE, which requires "target finishes loading," nor ABORT, which
requires "the load fails") — a literal deadlock in the Transitioning state,
and, worse, no documented safeguard against a player being stranded in a
dungeon whose exit keeps aborting on repeated retries.

**How to apply:** For any shared bidirectional transition state, ask "does
this contract's failure language literally apply to BOTH directions' actual
engine operations, or was it written with only one direction in mind?" Trace
the reverse direction's concrete mechanics (unload vs. load, teardown vs.
setup, disconnect vs. connect) against every place the failure/abort
language appears (Core Rules, States table Exit Condition, Edge Cases, ACs)
and flag any spot where the wording doesn't obviously generalize. Also check
whether repeated-failure/retry-loop stranding is addressed — a contract that
correctly restores "full control in the source scene" per single abort can
still trap a player forever if the source scene IS the place they're trying
to leave and nothing bounds retry attempts.
