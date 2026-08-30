---
name: project_input-silent-discard-pattern
description: Cross-cutting design gap found in input.md — ambiguous/suppressed states resolve by silently discarding player input with zero rejection feedback, undermining Pillar 1's trust promise. Worth re-checking in sibling GDDs.
metadata:
  type: project
---

During the `/design-review` of `design/gdd/input.md` (2026-08-19), found that "silently discard, no queueing" is used as the default resolution strategy for *every* ambiguous or suppressed input state in the document: `DEATH_HOLD` suppression (all input), mid-action device switch (input on the non-active device), and pause-during-`BLESSING_SELECT` cancellation. None of these paths define a rejection cue (sound, visual flash, haptic pulse) — the player has no way to distinguish "the game intentionally ignored this input" from "the game is lagging/broken."

**Why this matters**: "What the Gods Left Behind"'s Pillar 1 (Sacrificio con Peso) requires every hero death to read as a legitimate player decision, never a technical accident — input.md's own Player Fantasy section stakes this explicitly ("la entrada del jugador debe ser tan confiable que... el jugador nunca pueda culpar al control"). A discard-with-zero-feedback pattern is exactly the kind of ambiguity that could make a death-adjacent moment feel like a technical accident, especially during `DEATH_HOLD` — the single highest-stakes moment in the whole input system — where a player instinctively mashing buttons in the moment of loss gets total silence back.

**How to apply**: When reviewing `permadeath.md`, `reliquias-bendiciones.md`, `control-y-seleccion-de-unidades.md`, or `ui-hud.md` (none had GDDs yet as of 2026-08-19 per input.md's provisional notes), check whether they inherit this same silent-discard pattern for their own ambiguous/suppressed states, and whether any of them define the missing rejection-feedback cue as a shared contract. Flag it again if still unaddressed — this is a systemic gap, not a one-off.

See also [[input-gdd-review-2026-08-19]] if a fuller memory of that review is written later.
