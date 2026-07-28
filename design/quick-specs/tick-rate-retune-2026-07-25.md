# Tick-Rate / Deciding-Budget Coordinated Re-Tune

> ⚠️ **PROVISIONAL — PENDING USER RATIFICATION.** This decision was produced
> under an away-mode delegation (systems-designer, autonomous pass) closing
> Milestone 01 criterion #4, deferred 4 sprints on this exact missing input.
> The values below are a recommendation with full rationale and worked math,
> NOT yet an approved config change. Nothing in `production/session-state/`
> was touched, nothing was committed, and no `.tres` file was edited. Before
> this becomes non-provisional: (1) the user ratifies the chosen values, (2)
> `story-025`'s stress harness is re-run at the new defaults to replace the
> [estimated] cost figures below with measured ones (Story 022 AC1 already
> requires this), (3) `story-007` / `story-022` are updated to record the
> coordinated change with this doc as the shared rationale artifact.

**Date**: 2026-07-25
**Author**: systems-designer (delegated, autonomous)
**Closes**: Milestone 01 criterion #4 (deferred 4 sprints — missing input was
this exact decision)
**Coordinates**: `production/epics/time-tick-system/story-007-per-tick-retune-pass.md`
(ticks_per_second / max_ticks_per_frame half) + `production/epics/villager-ai-behavior/story-022-max-deciding-retune.md`
(max_deciding_per_tick half) — **plus `decision_interval`, a third knob this
doc adds to the coordinated scope** (see §7 — neither story currently lists it).
**Measurement basis**: `production/qa/evidence/villager-ai-stress-evidence.md`
(Sprint 7, Story villager-ai-025 — Advisory, production-code, GdUnit4 headless)

---

## 1. Decision Summary

| Knob | Current | **Recommended** | Change | Owner story |
|------|---------|------------------|--------|--------------|
| `ticks_per_second` | 4.0 | **4.0 (no change)** | — | time-tick-system story-007 |
| `max_ticks_per_frame` | 10 | **12** | +2 | time-tick-system story-007 |
| `max_deciding_per_tick` | 1 | **5** | +4 | villager-ai-behavior story-022 |
| `decision_interval` | 2 ticks | **4 ticks** | +2 | *(new — needs a scope line added to story-022 or a new coordinated story)* |

One-line rationale per knob:
- **`ticks_per_second` unchanged** — already slice-validated feel decision
  (2.0→4.0, user: "villagers should work more"); re-raising it now would
  compound the still-open Needs & Mood real-time-drift debt a second time
  before the first instance is even paid down, and it isn't the lever that
  fixes the measured starvation (see §4).
- **`max_ticks_per_frame` 10→12** — the existing cap gives only ~25% margin
  over the ticks strictly needed to keep a max-`raw_delta`-clamped frame
  "honest" under a debug 20x warp gear; 12 gives ~50% margin, still mid-range
  in the documented 5–30 safe band.
- **`max_deciding_per_tick` 1→5** — the primary responsiveness lever; direct,
  isolated fix (doesn't ripple into Needs/Building per-tick rates the way
  raising `ticks_per_second` would); cuts the measured worst-case Deciding
  wait by ~80% at population 30 while keeping AI's own estimated worst-case
  frame share at roughly a third of the 16.6ms budget.
- **`decision_interval` 2→4 ticks** — restores the *original* 1.0s-at-1x
  cadence (the 2.0→4.0 tick-rate change silently halved it to 0.5s, an
  unflagged twin of the same real-time-drift bug already flagged for Needs &
  Mood — see §7); also directly reduces how often the periodic recheck
  floods the shared Deciding queue, which is the actual root cause of the
  chronic-backlog finding, independent of `max_deciding_per_tick`.

---

## 2. Measurement Basis (what this decision is grounded in)

From `villager-ai-stress-evidence.md` (production-code, not the pre-VS
GDScript stand-in):

- Worst observed per-tick cost across every stress axis at population 30,
  `max_deciding_per_tick=1`: **3.02ms**, vs the 16.6ms frame budget — **5.5x
  headroom**, at both 1x and 3x warp.
- Scenario 3 (synchronized 30-villager mass-Deciding spike, matching Rule
  10c): the stagger safety property held (never more than 1 runnable per
  tick), but the **finding** is that Rule 2's unconditional periodic recheck
  re-enqueues ≈ population/`decision_interval` villagers every
  `decision_interval` ticks (≈15 every 2 ticks at pop 30) against a drain of
  only `max_deciding_per_tick`/tick — the queue never goes quiet, it sits
  chronically near-full (avg depth 29.5 of 30), bounded only by the
  scheduler's own dedup guard.
- ADR-0008's spike precedent (`max_deciding_per_tick=4` broke the 3x budget,
  p95 83.3ms) is **not applicable at face value** — that measurement used a
  "conservative brute-force GDScript stand-in" pre-dating real production
  code; this story's production-code worst case (3.02ms) is already far
  cheaper than even that spike's own passing threshold. The stress-evidence
  doc explicitly flags this gap as the reason a fresh re-tune is needed
  against production numbers, not the stale spike numbers.

---

## 3. Why `ticks_per_second` stays at 4.0

Two independent reasons this knob is *not* the lever to pull here:

1. **It doesn't fix the measured problem.** The chronic-queue-backlog
   finding is a *ticks-count* starvation (worst-case wait = `population /
   max_deciding_per_tick` ticks), not a *seconds-per-tick* problem. Raising
   `ticks_per_second` converts the same tick-count wait into fewer wall-clock
   seconds, but it does so by running the ENTIRE simulation faster — every
   other per-tick rate (Needs decay/recovery, Building's F3 progress) speeds
   up proportionally too, compounding the exact real-time-drift debt the GDD
   already flags as open and un-actioned ("Required re-tuning pass" in
   time-tick-system.md's Open Questions).
2. **It's the more expensive lever.** Total Deciding throughput = `ticks_per_second
   × max_deciding_per_tick` decisions/sec. Raising `max_deciding_per_tick`
   buys the same throughput increase in an isolated, single-system knob;
   raising `ticks_per_second` buys it by also multiplying every OTHER
   system's per-second workload (Needs ticks, Building progress ticks) for
   free that we don't need and haven't budgeted.

`ticks_per_second` was already the subject of a full slice-validated
decision this sprint cycle; re-opening it as part of a *performance* re-tune
(rather than a feel re-tune) risks silently re-litigating a creative
decision under a technical banner. Recommendation: leave it alone; escalate
to game-designer/creative-director only if a FUTURE feel-driven reason
arises to revisit it.

---

## 4. Formulas

### F-retune-1 — Worst-case Deciding-queue wait (pathological mass-event case)

`wait_ticks_max = ceil(population / max_deciding_per_tick)`

This is the bound Scenario 3 directly measures ("all N force-re-enqueued in
the same tick") — independent of `decision_interval`, since a one-off mass
event (e.g. Rule 10c's "large command completion frees many jobs at once")
isn't rate-limited by the periodic-recheck cadence.

| Symbol | Type | Range | Description |
|--------|------|-------|-------------|
| `population` | int | 1–30 (design ceiling; 60 included below as stress headroom, not a target) | Concurrent villager count |
| `max_deciding_per_tick` | int | 1–∞ (tuning knob) | Budget of new Deciding passes started per tick |
| `wait_ticks_max` | int | ≥ 1 | Worst-case ticks before the LAST villager in a synchronized mass-event gets its Deciding pass |

**Output range**: unbounded above in principle, but bounded in practice by
`population` (the scheduler's dedup guard caps queue depth at population
size) — so `wait_ticks_max ≤ population` always, regardless of tuning.

**Worked example — old values (`max_deciding_per_tick = 1`) vs new
(`= 5`), converted to wall-clock at `ticks_per_second = 4.0`, 1x**:

| Population | `wait_ticks_max` (old, K=1) | Wall-clock (old) | `wait_ticks_max` (new, K=5) | Wall-clock (new) | Reduction |
|---|---|---|---|---|---|
| 10 | 10 | 2.5 s | 2 | 0.5 s | 80% |
| 30 | 30 | **7.5 s** | 6 | **1.5 s** | 80% |
| 60 *(stress headroom, beyond the 30 ceiling)* | 60 | 15.0 s | 12 | 3.0 s | 80% |

This is the concrete answer to the constraint's framing ("a builder who
takes 7.5s to notice a job at pop 30 feels dead") — worst case drops to
1.5s at the design population ceiling.

### F-retune-2 — Steady-state periodic-recheck demand vs. supply

`demand_per_cycle ≈ ceil(population / decision_interval)` (villagers newly
re-enqueued by Rule 2's periodic recheck per `decision_interval`-tick window
— matches the evidence's own observed pattern of a clustered, not smoothly
amortized, burst)

`supply_per_cycle = max_deciding_per_tick × decision_interval`

The queue reaches **quiescence between cycles** (no chronic backlog) when
`supply_per_cycle ≥ demand_per_cycle`; otherwise it stays chronically busy,
bounded at `population` by the dedup guard (exactly what Scenario 3 measured
today).

| Symbol | Type | Range | Description |
|--------|------|-------|-------------|
| `decision_interval` | int (ticks) | 1–10 (GDD safe range) | Cadence of Rule 2's periodic re-evaluation |
| `demand_per_cycle` | int | 0–population | Villagers the periodic recheck tries to re-enqueue per cycle |
| `supply_per_cycle` | int | ≥ 0 | Deciding-pass capacity available in the same window |

**Worked example**:

| Config | Population | `demand_per_cycle` | `supply_per_cycle` | Verdict |
|---|---|---|---|---|
| Old (`decision_interval=2`, K=1) | 30 | 15 | 2 | **Chronic backlog** (matches measured avg depth 29.5/30) |
| New (`decision_interval=4`, K=5) | 30 | 8 | 20 | **Clears between cycles** — queue can reach near-empty steady state |
| New, at 60 (stress headroom) | 60 | 15 | 20 | Still clears |
| New, at 10 | 10 | 3 | 20 | Trivially clears |

This is the qualitative fix: today's queue is chronically near-full
regardless of population (bounded only by the dedup guard); under the new
values it should reach quiescence between recheck cycles at every population
up to and somewhat beyond the design ceiling.

---

## 5. Cost projection — `max_deciding_per_tick = 5` [ESTIMATED, not measured]

Per the design-docs provenance rule, this section is explicitly labeled: the
figures below are an **engineering estimate extrapolated from the
stress-evidence numbers**, not a new measurement. Story 022's AC1 already
requires the stress harness (Story 025) be re-run at the new default before
this value is considered validated — this section exists to show the
estimate is *plausible*, not to substitute for that re-run.

**Derivation**: Scenario 1 (pop 30, 1x) isolates a single worst-case
Deciding pass (full `max_selection_candidates=15` exhaustion) at
`max_deciding_per_tick=1`: max 0.613ms/tick. Scenario 2 (pop 30, 1x, real
cycle + write-storm) at the same K=1 measured max 3.016ms/tick — subtracting
the isolated Deciding cost gives an approximate non-Deciding baseline
(travel/build-credit/repath-filter) of **≈2.403ms**.

`estimated_worst_tick_cost(K) = 2.403 + K × 0.613` (ms) — a deliberately
worst-of-worst assumption (every one of the K slots hitting the pathological
full-exhaustion cost simultaneously; realistic average cost per slot is
almost certainly lower, since most periodic-recheck passes for a
non-urgent Working/Traveling villager are cheap "no-op" checks, not full F2
exhaustion sweeps).

| `max_deciding_per_tick` | Estimated worst-tick cost | % of 16.6ms budget |
|---|---|---|
| 1 (today, sanity check vs measured 3.016ms) | 3.02ms | 18% |
| **5 (recommended)** | **5.47ms** | **~33%** |
| 8 (considered, not chosen) | 7.31ms | ~44% |

33% leaves roughly two-thirds of the frame budget for rendering, voxel
streaming/meshing, and everything else sharing the 16.6ms frame — judged a
"small-ish fraction," consistent with the constraint, while still being a
real, non-trivial share worth re-confirming against a real measurement
before treating as final.

---

## 6. What Changes vs. Today

| Aspect | Today | After this re-tune |
|---|---|---|
| Worst-case wait for a fresh urgent need/job at pop 30 (mass-event case) | 30 ticks (7.5s @ 1x) | 6 ticks (1.5s @ 1x) |
| Deciding queue steady state at pop 30 | Chronically ~full (avg 29.5/30), never quiescent | Should clear between periodic-recheck cycles (demand 8 ≤ supply 20 per §4 F-retune-2) — to be confirmed by re-measurement |
| `decision_interval` real-time meaning | 2 ticks = **0.5s** at TPS=4.0 (silently halved from the originally-intended 1.0s by the 2.0→4.0 tick-rate change) | 4 ticks = **1.0s**, restoring original intent |
| `max_ticks_per_frame` margin under a stall-affected frame at 20x debug warp | ~25% margin (10 vs 8 strictly needed) | ~50% margin (12 vs 8) |
| AI's estimated worst-case per-tick cost | 3.02ms measured (18% of budget) | ~5.47ms estimated (33% of budget) — **requires re-measurement** |
| FSM / staggering mechanism | Unchanged | Unchanged — this is a pure config re-tune, no code/architecture change (per ADR-0008 and both stories' explicit "no FSM changes" constraint) |
| Determinism (ADR-0009) | Stable-order FIFO dequeue | Unchanged — stable order is independent of the budget value |

---

## 7. Coupled-Knob Finding: `decision_interval`'s Own Drift

Neither `story-007` nor `story-022` currently lists `decision_interval` in
scope. This doc surfaces why it belongs in the same coordinated change:

The GDD's own Tuning Knobs table states `decision_interval = 2 ticks (= 1.0s
at 1x)` — but that "1.0s" annotation was computed against the OLD
`ticks_per_second = 2.0`. Since the tick rate was raised to 4.0 (2026-07-23
slice revision) without a matching pass over `decision_interval`, the ACTUAL
real-time cadence silently became 0.5s — an unflagged twin of the exact
"required re-tuning pass" the GDD's Open Questions already calls out for
Needs & Mood's per-tick rates. Restoring `decision_interval` to 4 ticks
undoes that unintended side effect (back to 1.0s) while ALSO directly
reducing periodic-recheck queue pressure (§4 F-retune-2) — a rare case where
the "restore original intent" fix and the "fix the performance finding" fix
are the same number.

**Recommendation**: `story-022` (or a new coordinated story) should add
`decision_interval` to its Acceptance Criteria alongside `max_deciding_per_tick`,
citing this doc as the shared rationale artifact — matching the existing
"one coordinated change, shared rationale" pattern the two stories already
use for `ticks_per_second`/`max_ticks_per_frame` + `max_deciding_per_tick`.

---

## 8. Risk Notes

1. **Cost figures are estimated, not measured** (§5). Required follow-up:
   re-run Story 025's stress harness at `max_deciding_per_tick=5`,
   `decision_interval=4` before treating these values as non-provisional.
   Story 022 AC1 already requires this — this doc does not satisfy it.
2. **Burst-frame amplification**: raising `max_deciding_per_tick` multiplies
   the worst-case cost of any single frame that hits the
   `max_ticks_per_frame` cap (e.g. after an alt-tab stall). At the new
   values, a full 12-tick catch-up frame could drain up to 12×5=60 Deciding
   passes in one frame — an estimated ~37ms one-off hitch in the worst case.
   This is an ACCEPTED tradeoff per the GDD's own Edge Cases wording ("no
   special handling... this is a performance signal, must be fixed via
   profiling") and only occurs immediately after an already-degraded frame
   (the player has already seen a hitch) — but if this cap is observed being
   hit on CONSECUTIVE frames in real play (not a rare one-off), that is the
   GDD's own documented signal to profile further, not silently accept.
3. **20x is a debug-only gear, not shipped `time_warp_options`.** Production
   `time_warp_options` remains `{1, 2, 3}` per the GDD (unchanged by this
   doc). The `max_ticks_per_frame=12` recommendation gives comfortable
   margin for the debug 20x gear referenced in this delegation's constraints
   and in `story-007`'s open note, but this doc does NOT decide whether 20x
   ships as a debug-only production option — that remains `story-007`'s
   explicitly flagged open item.
4. **Population-ceiling stress figures (60) are headroom checks, not
   targets.** The design commitment is 20–30 villagers (Full Vision); 60 is
   included in §4's tables only to show the new values don't degenerate
   pathologically beyond the ceiling, not as a supported operating point.
5. **This is a config-only change.** No FSM, staggering mechanism, or
   scheduler code changes are implied or required — consistent with both
   stories' explicit "no FSM/staggering changes" constraints. If the
   re-measurement in Risk 1 finds `max_deciding_per_tick=5` insufficient or
   too costly, the correct response is adjusting THIS number again, not an
   architecture change (ADR-0008's `WorkerThreadPool` escape hatch remains
   named-but-not-adopted, unaffected by this decision).

---

## 9. Acceptance Criteria (for the stories that implement this)

1. **GIVEN** the re-tuned config (`max_deciding_per_tick=5`,
   `decision_interval=4`, `max_ticks_per_frame=12`, `ticks_per_second=4.0`
   unchanged), **WHEN** Story 025's stress harness re-runs Scenario 3 (30
   villagers, synchronized mass-Deciding) against production code, **THEN**
   the measured worst-case ticks-to-decide is ≤ 6 ticks (matching §4's
   `wait_ticks_max` bound) and per-tick wall-clock cost stays under the
   16.6ms frame budget at both 1x and 3x warp.
2. **GIVEN** the same re-tuned config, **WHEN** Scenario 1/2 (unreachable-job
   stress, real-cycle + write-storm) re-run, **THEN** the measured worst
   per-tick cost is compared against this doc's §5 estimate (~5.47ms) and
   the delta is recorded in the smoke-check evidence, whichever direction it
   falls.
3. **GIVEN** the periodic recheck at the new `decision_interval=4`, **WHEN**
   queue depth is sampled over a sustained run at population 30, **THEN**
   it reaches a depth measurably below the old chronic ~29.5/30 average
   (demonstrating quiescence between cycles per §4 F-retune-2) — not just a
   bounded-but-still-chronically-full state.
4. **GIVEN** `max_ticks_per_frame=12` and a simulated stall (`raw_delta`
   clamped to `max_raw_delta=0.1s`) at 20x warp, **WHEN** ticks are
   processed, **THEN** all 8 due ticks fire with no discard (confirms the
   ~50% margin claim in §1/§6).
5. **GIVEN** the re-tuned values, **WHEN** a determinism regression test
   runs the same synchronized-mass-Deciding scenario twice, **THEN** the
   dequeue order is identical both runs (stable villager order unaffected
   by the budget value change — ADR-0009 compliance, no regression).

---

## 10. Registry Impact (not yet applied)

`ticks_per_second` and `max_ticks_per_frame` are registered entities
(`design/registry/entities.yaml`). If this decision is ratified:
- `max_ticks_per_frame`: registry value 10 → 12, with this doc cited as the
  rationale (mirroring how the 2.0→4.0 `ticks_per_second` change was
  recorded).
- `max_deciding_per_tick` and `decision_interval` are NOT currently
  registered entities (villager-ai-behavior.md-local tuning knobs only,
  referenced by one GDD) — no registry action needed for those unless a
  second GDD starts depending on their exact values.

**This doc does not apply that registry edit** — per this delegation's
scope (provisional decision, no session-state/commit actions) and standard
protocol, the registry update is proposed here for the user's ratification
step, not applied unilaterally.

---

## 11. Open Follow-Ups (not resolved by this doc)

- Story 025 stress-harness re-run at the new defaults (Risk 1) — required
  before non-provisional.
- `story-022` / a new story needs `decision_interval` added to its scope
  (§7) — currently absent from both coordinating stories.
- The Needs & Mood real-time-rate re-tune (Milestone 02, already tracked in
  time-tick-system.md's Open Questions) remains separately outstanding —
  unaffected by this doc, which touches only AI-scheduling knobs.
- `story-007`'s open note on whether 20x/10x return as debug-only
  `time_warp_options` remains open (Risk 3) — this doc only ensures
  `max_ticks_per_frame` wouldn't collapse if/when that question resolves
  affirmatively.
