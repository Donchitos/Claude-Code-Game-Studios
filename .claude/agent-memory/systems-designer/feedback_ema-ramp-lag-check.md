---
name: feedback-ema-ramp-lag-check
description: An EMA/exponential-smoothing formula's commonly-cited step-response catch-up (e.g. "~63% after N ticks") does NOT describe its behavior against a continuously-moving (ramp) input — check the separate, often much larger, steady-state ramp lag (~= per-tick delta x smoothing window)
metadata:
  type: feedback
---

`value ← value + (target − value) / N` (an EMA/leaky-integrator smoothing
formula) is usually documented with its STEP-response behavior: "~63% caught
up after N ticks, ~95% after ~3N ticks." That characterization is only true
when `target` holds still. When `target` moves at a constant per-tick delta
δ (a ramp — e.g., a need value rising steadily during recovery, or falling
steadily during decay), the smoothed `value` does NOT converge to `target`;
it settles into a constant trailing offset (steady-state lag) of
approximately `δ × N`, and stays that far behind for as long as the ramp
continues. This is a standard control-theory result (first-order lag
tracking a ramp has nonzero steady-state error) but is easy to miss if a GDD
only quotes the step-response numbers.

**Why:** Found in `design/gdd/needs-mood-system.md` (2026-07-10 first full
review), F3's mood-smoothing EMA. The Tuning Knobs table describes
`mood_smoothing_ticks` purely via step-response framing ("~63% caught up
after 40 ticks, ~95% after 2 min"). But during an active bed-recovery
(F2's `base_recovery_per_tick`, default 0.5/tick, is a near-constant ramp on
`mean_active`), the derived steady-state lag is δ×N = 0.5×40 = 20 points —
i.e., displayed mood can trail the true need value by up to ~20 points
throughout a recovery event, not "63% caught up." At extreme-but-legal knob
combinations (`base_recovery_per_tick`=2.0, `mood_smoothing_ticks`=120) the
theoretical lag (240) exceeds the entire 0–100 need scale, meaning mood
would barely move for the whole recovery. This directly risks the doc's own
stated Game Feel goal ("mood visibly lifts") and Feel Acceptance Criteria.
(Decay, by contrast, has a small δ by design — default 0.07/tick × N=40 ≈
2.8 lag — negligible; the risk is concentrated on whichever ramp has the
largest δ, usually the recovery/fast-input side, not the decay/slow side.)

**How to apply:** Whenever a GDD uses EMA/exponential smoothing against an
input that is itself a monotonic ramp for extended periods (a recovery
curve, a build-progress bar, a resource-flow meter), compute steady-state
ramp lag = (the feeding formula's max per-tick delta) × (the smoothing
knob's value, at both default and its safe-range max) and compare it to the
values the ramp needs to cross (e.g., band thresholds). If the lag is a
material fraction of the range the ramp travels, or exceeds the gap between
consecutive display-band thresholds, flag it — the step-response framing in
the Tuning Knobs table is actively misleading for that use case.
