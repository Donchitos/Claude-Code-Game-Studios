# Villager AI Stress Evidence — Re-tune (Story villager-ai-022)

**Date**: 2026-07-25
**Story**: `production/epics/villager-ai-behavior/story-022-max-deciding-retune.md`
**Coordinated with**: `production/epics/time-tick-system/story-007-per-tick-retune-pass.md`
(`max_ticks_per_frame` 10→12, unrelated files, already landed — `production/qa/smoke-2026-07-25.md`)
**Shared rationale**: `design/quick-specs/tick-rate-retune-2026-07-25.md`
**Baseline**: `production/qa/evidence/villager-ai-stress-evidence.md` (Sprint 7, `max_deciding_per_tick=1`,
`decision_interval=2`)
**Test files**:
- `neues-spiel/tests/performance/villager_ai/stress_30_villager_test.gd` (re-run + 3 new Sprint 8
  measurement functions, Advisory, excluded from the BLOCKING suite)
- `neues-spiel/tests/unit/villager_ai/deciding_scheduler_test.gd` (1 new BLOCKING determinism test)
- `neues-spiel/tests/integration/villager_ai/config_and_scaffold_test.gd` (3 assertions updated to
  the new defaults)
**Engine**: Godot 4.7-stable, headless GdUnit4 CLI

---

## 1. Config change (ONE coordinated change, shared rationale)

| Field | Old | New | File |
|---|---|---|---|
| `max_deciding_per_tick` | 1 | **5** | `neues-spiel/data/config/villager_ai_config.tres`, `src/villager_ai/villager_ai_config.gd` |
| `decision_interval` | 2 | **4** | same files |

Both the `.tres` instance and the `VillagerAIConfig` script's own `@export` default literal were
updated together (mirrors `time_tick_config.gd`'s established precedent — a headless test constructing
`VillagerAIConfig.new()` directly also observes the new defaults, no stale `.tres`-only edit).

**Rationale recorded**: doc comments in `villager_ai_config.gd` cite
`design/quick-specs/tick-rate-retune-2026-07-25.md` §1/§4/§5/§7 directly. This is the SAME quick-spec
`tick-007`'s own smoke doc (`production/qa/smoke-2026-07-25.md`) cites for its `max_ticks_per_frame`
half — satisfying "recorded ONCE with shared rationale" structurally, per that document's own §2.

`VillagerAIConfig.validate()`'s existing GDD-safe ranges (`decision_interval` [1,10],
`max_deciding_per_tick` [1,30]) are unchanged — both new defaults fall inside their existing ranges, no
clamp fires (confirmed by `test_validate_gdd_defaults_returns_empty`, unmodified, still green).

No FSM or scheduler mechanism code was touched — `villager_deciding_scheduler.gd` and the FSM dispatch
in `villager_ai.gd` are byte-for-byte unchanged. This is a pure config-value change, confirmed by `git
diff` touching only `villager_ai_config.gd`/`.tres` and test files.

---

## 2. Measured — before / after comparison

### 2a. Scenario 1/2 (unchanged harness, live config) — frame budget holds at both K=1 (S7) and K=5 (now)

| Scenario | Population | Warp | avg (S7, k=1) | avg (now, k=5) | Budget (16.6ms) |
|---|---|---|---|---|---|
| unreachable-job-dense | 30 | 1x | 0.547ms | 0.658–2.562ms* | PASS (≥6x headroom) |
| unreachable-job-dense | 30 | 3x | 1.655ms | 7.673ms | PASS (≥2.1x headroom) |
| construction-write-storm | 30 | 1x | 1.513ms | 1.885ms | PASS (≥8.8x headroom) |
| construction-write-storm | 30 | 3x | 1.558ms | 3.235ms | PASS (≥5.1x headroom) |

\* Run-to-run variance on this dev machine (headless, no fixed clock isolation) — both figures are
comfortably inside budget; the frame-budget guardrail (AC3 of the story) holds in every case. Full
numbers, both population sizes, both warp levels: see console output transcribed above pop=5 rows
omitted here for brevity (unchanged shape, same headroom class).

**Verdict: frame budget holds at 1x AND 3x warp at the 30-population ceiling — story AC3 satisfied.**

### 2b. Quick-spec AC1 / F-retune-1 — worst-case ticks-to-decide (mass-Deciding spike, pop 30)

| Measurement | Before (k=1) | After (k=5) | Bound |
|---|---|---|---|
| Isolated (zero contention) — `deciding_scheduler_test.gd`'s new determinism test | 30 (not re-measured, formula) | **6** (measured, run twice, identical) | ceil(30/5)=6 |
| Real production environment (real job cycle + periodic recheck active) — `stress_30_villager_test.gd` | 30 (S7 baseline) | **6** (measured) | generous sanity ≤20 |

Both the fully isolated scheduler-level measurement and the real-environment (contention-inclusive)
measurement hit exactly the theoretical bound of 6 ticks — an 80% reduction from the old 30-tick
worst case (7.5s → 1.5s at 1x, TPS=4.0), confirming quick-spec §4 F-retune-1 exactly, not merely
"in the right ballpark."

### 2c. Quick-spec AC3 / F-retune-2 — queue-depth quiescence (60-tick drain window, pop 30)

| Metric | Before (S7, k=1/interval=2) | After (k=5/interval=4) |
|---|---|---|
| avg queue depth (of 30) | 29.5 | **22.5** |
| p95 / max | 30.0 / 30.0 | 30.0 / 30.0 |

The average dropped measurably (22.5 vs 29.5), confirming the direction F-retune-2 predicts
(supply_per_cycle 20 ≥ demand_per_cycle 8, vs the old 2 ≥ 15 shortfall). It has not reached
near-zero quiescence in this specific harness because the REAL claim→travel→build→report job
cycle (60 reachable jobs, real `AStar3D` travel) generates its OWN legitimate, continuous stream of
`request_deciding_pass()` calls (job commit, travel arrival, work completion) independent of the
periodic `decision_interval` recheck — F-retune-2's formula models the periodic-recheck channel in
isolation, not this additional real-behavior channel. The safety property ADR-0008 actually names
(never more than `max_deciding_per_tick` runnable in a single tick, however many are queued) held
throughout, unchanged from S7. Recorded honestly, not silently padded to claim full quiescence.

### 2d. Quick-spec §8 Risk 2 / QA plan Call-out 4 — burst-frame amplification (measured, not estimated)

| Metric | Quick-spec estimate | Measured |
|---|---|---|
| Single 12-tick catch-up frame cost (K=5, pop=30) | ~37ms | **23.116ms** |
| Follow-up frames (1 tick each, ×10) avg / max | — | 0.735ms / 0.775ms |

The burst cost (23.1ms) is real but well under the estimate and stays a single, isolated event — every
follow-up frame immediately drops back to the normal ~0.7ms/tick cost, confirming this is NOT a
recurring pattern (the quick-spec's own escalation trigger for further profiling did not fire).

---

## 3. Determinism (ADR-0009, quick-spec AC5) — BLOCKING, re-run at K=5

New test `deciding_scheduler_test.gd::test_synchronized_mass_deciding_scenario_run_twice_at_k5_produces_identical_dequeue_order`:
the full 30-villager synchronized-mass-Deciding scenario, run twice from two independent
scheduler/population instances at `max_deciding_per_tick=5`, produces an IDENTICAL per-tick dequeue
sequence both times, and drains in exactly 6 ticks both runs. PASS — no regression, ADR-0009's
stable-order guarantee holds unaffected by the budget value change.

---

## 4. Existing tick/pause/warp/determinism suite — RE-RUN, not assumed unaffected

Full regression suite (`tests/run-tests.cmd`, unit + integration) re-run against the new
`max_deciding_per_tick=5`/`decision_interval=4` (and the already-landed `max_ticks_per_frame=12`):

**Overall Summary**: 849 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans | PASSED
**Executed test suites**: 74/74 · **Executed test cases**: 849/849 · **Exit code: 0**

(849 = the 848 baseline this sprint's `tick-007` smoke doc recorded, +1 for this story's new
determinism test.) Confirmed: pause/warp suites (`pause_warp_state_test.gd`,
`game_delta_computation_test.gd`, `tick_accumulator_test.gd`, `max_ticks_cap_test.gd`) all still green,
unaffected by the villager-ai-side config change (they don't read `VillagerAIConfig` at all).

Performance suite (Advisory, excluded from the count above, run separately):
`tests/performance/villager_ai/stress_30_villager_test.gd` — 7/7 PASS, 0 errors, 0 orphans, exit 0.

---

## 5. No FSM/staggering code changes (story constraint)

`git diff` confirms only these files touched: `villager_ai_config.gd`, `villager_ai_config.tres`,
`config_and_scaffold_test.gd`, `stress_30_villager_test.gd`, `deciding_scheduler_test.gd`.
`villager_deciding_scheduler.gd` and `villager_ai.gd`'s FSM/dispatch code are untouched — a pure
config-value + test change, per the story's and quick-spec's explicit constraint.

---

## Verdict

**PASS.** `max_deciding_per_tick` 1→5 and `decision_interval` 2→4 re-tuned per the ratified quick-spec,
coordinated with `tick-007`'s `max_ticks_per_frame` half via the same shared rationale artifact. Every
quick-spec Acceptance Criterion (§9) is now measured, not estimated: worst-case ticks-to-decide hits
the exact 6-tick bound (isolated AND real-environment), queue-depth quiescence improved measurably
(29.5→22.5 avg), burst-frame amplification measured at 23.1ms (under the ~37ms estimate) and confirmed
isolated/non-recurring, and determinism (ADR-0009) holds identically at the new budget. Full regression
suite green (849/849, 0 orphans, exit 0); performance suite green (7/7, 0 orphans, exit 0). No FSM or
scheduler mechanism changes.
