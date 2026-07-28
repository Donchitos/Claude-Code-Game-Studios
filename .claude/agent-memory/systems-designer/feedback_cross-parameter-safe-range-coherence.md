---
name: feedback-cross-parameter-safe-range-coherence
description: Individually-safe tuning-knob ranges can combine to violate a hard invariant (value domain overflow) or the doc's own stated design-intent target (pacing/feel) — check knobs at their extremes IN COMBINATION, not just one at a time
metadata:
  type: feedback
---

A Tuning Knobs table documents each knob's safe range in isolation ("knob A:
0.2–2.0", "knob B: 80–100"). That does not mean every combination of
extremes from different knobs is safe. Two failure shapes to check for:

1. **Hard invariant violation**: a formula's stated output domain (e.g., "a
   need is a float 0–100") can be breached by a combination of two knobs at
   their legal extremes even though neither knob alone breaches it. Compute
   the formula's worst case using the MIN of one knob and the MAX of
   another (and vice versa), not just each knob's own midpoint/default.
2. **Design-intent drift**: the doc states a target feel/pacing (e.g., "a
   ~10-minute heartbeat") and calls out ONE knob's dangerous extreme (e.g.,
   "0.2 ≈ tamagotchi territory, avoid") but only in one direction, or only
   for one knob — leaving the opposite extreme, or a second knob's extreme,
   or a *combination* of two knobs both at their slow/fast end, silently
   able to blow the same target by an equal or larger margin with no
   warning anywhere in the table.

**Why:** Found in `design/gdd/needs-mood-system.md` (2026-07-10 first full
review). F2's recovery formula has "no clamp at 100 during recovery" (the
satisfied_threshold cross is the only exit, overshoot is accepted). Taken
alone, `satisfied_threshold` (safe range 80–100) and `base_recovery_per_tick`
(safe range 0.2–2.0) are each individually reasonable — but
`satisfied_threshold=100` combined with `base_recovery_per_tick=2.0` (both
legal) lets a single tick push a need value from e.g. 99.0 to 101.0,
breaching the need's own declared 0–100 domain (Core Rule 1, F1's value
range) and propagating into F3's mean_active/mood, which assumes the same
0–100 domain. Separately, `decay_per_tick`'s Tuning Knobs note flags only
the FAST extreme (0.2 ≈ tamagotchi, avoid) — the SLOW extreme (0.03) yields
a time-to-urgent of ~20.8 min, over 2x the stated "~9 min" default pacing
and the Game Feel section's explicit "~10-minute heartbeat" claim, with zero
warning. And `base_recovery_per_tick` (min 0.2) × `ground_penalty` (min 0.1)
combine to a 0.02/tick ground-recovery rate — a single ground-sleep cycle of
~29 minutes real time, wildly outside the stated feel target, with no
combined-knobs warning anywhere.

**How to apply:** For every formula in the Formulas section, identify which
Tuning Knobs feed it. Compute the formula's output at (a) each knob at its
own extreme with others at default, AND (b) two or more feeding knobs
simultaneously at whichever combination of their extremes is worst-case for
the formula's stated domain or the doc's stated design-intent target. If (b)
breaches something (b) alone wouldn't have, flag it — even though every
individual range in isolation is "safe" per the table.
