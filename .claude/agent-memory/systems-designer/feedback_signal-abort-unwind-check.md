---
name: feedback-signal-abort-unwind-check
description: When reviewing a signal-based side-effect discipline rule (begin=reversible/complete=irreversible-success-only), always verify a complementary abort signal exists for reversible-effect unwind
metadata:
  type: feedback
---

When a GDD narrows a "complete" signal to fire only on success (to protect
irreversible effects from firing on a failed/aborted operation), always check
whether the *reversible* effects that were bound to the paired "begin" signal
have a defined path back out on failure. Narrowing "complete" to success-only
closes the irreversible-effect trap but, if no complementary abort signal is
added, silently opens a mirror-image trap: reversible effects (e.g. suspended
input/camera/UI state) that were supposed to "unwind cleanly on abort" have no
signal telling them to unwind — because the only signal available (COMPLETE)
now deliberately never fires on the failure path.

**Why:** Found in `design/gdd/scene-world-management.md` re-review #2
(2026-07-10). Core Rule 7 was added at re-review #1 specifically to fix an
undo-abort trap (irreversible Building undo-clear firing on transition-begin).
The fix correctly gated irreversible effects to COMPLETE-only, but nothing
was added to tell Camera & Input / Building System / Building UI / Villager
Info UI (all chained via a Suspended-state propagation keyed to the same
begin/complete signals) how to exit Suspended when a transition instead
ABORTS. Result: a single failed scene load permanently freezes all player
input (Camera & Input never un-suspends -> Building System, which chains off
it, never un-suspends -> UI stays hidden) with no defined escape hatch. This
directly contradicted the GDD's own AC8 ("player remains in the source scene
with full control" after an abort). Confirmed by grepping camera-input.md and
building-system.md for "abort"/"fail" — neither defines a recovery path.

**How to apply:** Any time you review or design a system with a
begin/complete signal pair where complete is (or becomes) success-only gated,
explicitly trace every consumer that reacted to "begin" and ask "what tells
this consumer to undo that reaction if the operation instead fails?" If the
answer is "the same complete signal," that's the bug. Look for either (a) a
success:bool payload on complete so reversible-effect listeners can react to
BOTH outcomes while irreversible listeners still gate on success=true, or (b)
a distinct abort/failure signal dedicated to reversible-effect unwind. Also
check for the same terminology trap in any related debounce/lock logic:
if a "second trigger is ignored until the first completes" rule is worded
using the same word "completes," verify it's keyed to the underlying STATE
exit (which typically covers both outcomes) rather than the success-only
SIGNAL — otherwise the debounce gets stuck too.
