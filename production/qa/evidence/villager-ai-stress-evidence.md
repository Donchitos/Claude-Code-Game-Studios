# Villager AI Stress Evidence — Story villager-ai-025

**Date**: 2026-07-24
**Story**: `production/epics/villager-ai-behavior/story-025-perf-stress-validation.md`
**Test file**: `neues-spiel/tests/performance/villager_ai/stress_30_villager_test.gd`
**Status**: Advisory/Performance — self-declared Nice, not a Done/smoke blocker
(Sprint 7 QA plan Call-out 1). Recorded here for the deferred Sprint 8
tick-007+villager-ai-022 coordinated re-tune (milestone criterion #4).
**Engine**: Godot 4.7-stable · **Hardware**: dev machine (same class as
`prototypes/perf-spike-qq3/REPORT.md`) · **Run**: headless GdUnit4 CLI,
`res://tests/performance` (deliberately excluded from `tests/run-tests.cmd`'s
`unit`+`integration` globs — Advisory, never joins the BLOCKING gate)

---

## Methodology (read before the numbers)

There is no live renderer in headless GdUnit4, so "frame time" is a documented
proxy, same spirit as `prototypes/perf-spike-qq3/REPORT.md`'s own vsync-masked
methodology: one measured **sample** = one rendered-frame equivalent —

1. Once per sample: for every villager still travelling (`is_moving()`, the
   SAME guard the real `VillagerAi._process()` uses), call
   `advance_travel_progress(1000.0)` — mimics the engine calling `_process()`
   on every AI node once per frame. The large `game_delta` only shortens how
   many samples a real multi-cell path needs to complete; it does not change
   the O(1) per-call cost being measured.
2. Any injected write-storm for that sample (Scenario 2 only).
3. `ticks_per_sample` consecutive `tick.emit()` calls via `MockTimeTickSystem`
   — **1** for "1x", **3** for "3x warp" (modeling "N global ticks can land in
   the same rendered frame under warp," matching perf-spike-qq3's own
   warp1-vs-warp3 approach).

Steps 1–3 are timed as one sample via `Time.get_ticks_usec()`. All runs use
production defaults: `max_deciding_per_tick = 1` (ADR-0008 spike-tuned value),
`decision_interval = 2`, `job_candidate_count = 5`,
`max_selection_candidates = 15`.

**Scope caveat (honest, not silently padded)**: the GDD's own OQ3 spike
wishlist also names Breather step-away and bed-drift pathing as stress axes.
Neither exists as real behavior in this codebase yet —
`VillagerAi._tick_breather` / `_tick_wandering` are still empty stubs (later,
unlanded stories; Needs & Mood and the Unstuck Watchdog are undesigned too).
This harness measures exactly what IS real and landed: Deciding-pass
staggering (005), F2 selection under an unreachable-job-dense queue (010),
the real claim→travel→build→report cycle at population scale (011/012), and
Voxel-World write-storm cost against the re-path filter (008/009).

---

## Measured numbers

### Scenario 1 — unreachable-job-dense Deciding stress
20 mutually-isolated single-cell islands, zero reachable jobs — GDD F2's own
documented worst case: every Deciding pass burns the full
`max_selection_candidates` (15) pathfind-attempt cap before falling through to
Wandering, and Rule 2's periodic `decision_interval` recheck regenerates this
worst case every ~2 ticks for the whole run (sustained, not one-shot). 150
samples per warp level.

| Population | Warp | avg | p95 | max | Budget (16.6 ms) |
|---|---|---|---|---|---|
| 5 | 1x | 0.523 ms | 0.535 ms | 0.604 ms | ✅ (≈31x headroom) |
| 5 | 3x | 1.581 ms | 1.625 ms | 1.751 ms | ✅ (≈9.5x headroom) |
| 30 | 1x | 0.547 ms | 0.585 ms | 0.613 ms | ✅ (≈28x headroom) |
| 30 | 3x | 1.655 ms | 1.738 ms | 1.830 ms | ✅ (≈9.1x headroom) |

Structural: every villager ends the run in `Wandering` with no claim held
(F2's fall-through floor holds at 30-population scale, never stuck in
Deciding).

### Scenario 2 — real claim→travel→build→report cycle + construction write-storm
60 reachable job targets on the same connected platform; a parallel
"construction happening elsewhere" write-storm (`bulk_write`, 10 far-away
cells alternating solid/empty) fires every sample, exercising the Rule 10b
re-path filter's aggregate per-population fan-out cost. 150 samples per warp
level.

| Population | Warp | avg | p95 | max | Budget (16.6 ms) |
|---|---|---|---|---|---|
| 5 | 1x | 1.230 ms | 1.317 ms | 2.804 ms | ✅ (≈5.9x headroom) |
| 5 | 3x | 1.701 ms | 1.816 ms | 2.012 ms | ✅ (≈8.2x headroom) |
| 30 | 1x | 1.513 ms | 2.958 ms | 3.016 ms | ✅ (≈5.5x headroom) |
| 30 | 3x | 1.558 ms | 1.664 ms | 1.715 ms | ✅ (≈9.7x headroom) |

Structural: at least one job reached `BUILT` in every run (the real
claim→travel→build→report cycle survives the write-storm at both population
sizes, not merely "ticks fired").

### Scenario 3 — synchronized mass-Deciding spike (30 villagers)
All 30 villagers force-re-enqueued in the same tick (models "a large
command's completion frees many jobs at once," GDD Rule 10c). Drained over 60
ticks.

| Metric | Value |
|---|---|
| Runnable ids per tick (ADR-0008 invariant) | **≤ 1 every single tick, all 60 ticks** — the stagger held throughout, never spiked to 30 |
| Per-tick wall-clock cost, drain window | avg 0.195 ms / p95 0.211 ms / max 0.227 ms |
| Queue depth over the drain window | avg 29.5 / p95 30.0 / max 30.0 (of 30) |

**Finding, corrected from the original test assumption**: the queue does
**not** drain to zero and go quiet within the window — at these defaults
(`decision_interval = 2`, `max_deciding_per_tick = 1`, population = 30),
Rule 2's periodic recheck fires **unconditionally every tick for every
villager, regardless of state** (`_check_decision_interval_trigger`), which
re-enqueues roughly `population / decision_interval` ≈ 15 villagers every 2
ticks — a sustained re-enqueue rate of ~7.5/tick against a drain rate of only
1/tick. The queue reaches a **chronically busy, but bounded** steady state
(never above population size, thanks to the scheduler's own idempotent
dedup guard), not quiescence. The safety property ADR-0008 actually names —
bounded worst-case per-tick Deciding cost, never a synchronized all-at-once
spike — held perfectly throughout. This is the load-bearing result; "goes
quiet" was this test's own incorrect initial assumption, corrected before
this report was written.

---

## Comparison to the pre-VS spike baseline (`prototypes/perf-spike-qq3/REPORT.md`)

- The pre-VS spike (GDScript stand-in, S2) measured **one Deciding pass** at
  avg 11 ms / p95 35 ms, and found `max_deciding_per_tick = 4` broke the 3x
  budget (p95 83.3 ms) while `= 1` held (p95 16.667 ms, vsync-masked — i.e.
  "held 60 FPS," true headroom invisible).
- This story's production-code measurement is **not directly comparable
  pass-for-pass** — the spike measured isolated Deciding-pass cost; this
  harness measures whole-tick cost across the full population (Deciding +
  travel + construction crediting + re-path filtering), and this codebase's
  real production Deciding pass (real `AStar3D` queries against a
  ~2,500-cell region graph, real F2 candidate ranking) is markedly cheaper
  than the spike's own conservative brute-force GDScript stand-in — worst
  observed per-tick cost across every scenario above is 3.02 ms, well under
  even the spike's already-passing 16.667 ms figure.
- **New finding this story surfaces that the spike did not**: Rule 2's
  perpetual periodic recheck load (Scenario 3) keeps the Deciding queue
  chronically near-full at 30 population with today's defaults — worth
  carrying into the Sprint 8 `ticks_per_second` / `max_ticks_per_frame` /
  `max_deciding_per_tick` coordinated re-tune (milestone criterion #4) as
  context: `max_deciding_per_tick = 1` still keeps every measured per-tick
  cost far under budget, but the STANDING queue depth (not just per-tick
  cost) may be worth a look if a future story wants "how many ticks until a
  freshly-urgent need actually gets decided" to stay low at full population.

---

## Verdict

**PASS at production-code scale** — every measured envelope holds comfortably
under the 16.6 ms budget at both the Vertical Slice-adjacent (5) and Full
Vision ceiling (30) populations, at both 1x and 3x warp, for every stress axis
this harness could honestly exercise against landed code. Advisory per its own
declaration — this does not block MVP Done or any other Sprint 7 story; it is
recorded for the Sprint 8 re-tune decision.
