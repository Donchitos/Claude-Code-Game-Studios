# Story 008: Burst ordering, pause & warp determinism (full-cycle tick anchors)

> **Epic**: Needs & Mood System
> **Status: Complete (2026-07-27 — own suite 9/9 green 0 orphans; full-gate re-verified by parent once the concurrent bv-008 lands)
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/needs-mood-system.md`
**Requirement**: `TR-needs-mood-system-051`, `TR-needs-mood-system-057`, `TR-needs-mood-system-062`, `TR-needs-mood-system-063`, `TR-needs-mood-system-066`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 (tick-driven execution, never raw delta) — primary; ADR-0002 (`max_ticks_per_frame` and `ticks_per_second` are Time & Tick's config, read never redefined)
**ADR Decision Summary**: Everything simulation-side runs off Time & Tick's `tick` signal — never `_physics_process` raw delta, never a per-consumer `Timer`. Pause is `game_delta = 0` (no ticks fire), and warp is a `game_delta` multiplier that changes tick *frequency*, never tick *meaning*. `SceneTree.paused` and `Engine.time_scale` are project-wide forbidden patterns.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: The tick burst cap is `TimeTickConfig.max_ticks_per_frame`, whose **landed default is 12** (Sprint 8 re-tune, `design/quick-specs/tick-rate-retune-2026-07-25.md`) — the GDD's burst-rule prose still says 10. Assert against the **config value**, never the literal. Ticks are delivered as N discrete synchronous signal emissions per frame, so per-tick in-order emission is the natural implementation, not a special case.

**Control Manifest Rules (this layer)**:
- Required (Feature): tick-driven via Time & Tick's signal; rates are functions of tick count, never wall-clock.
- Forbidden (project-wide, absolute): `SceneTree.paused` and `Engine.time_scale` — pause and warp are Time & Tick's, and this module simply receives fewer or more ticks.
- Forbidden: coalescing or deduplicating threshold signals across a burst.
- Guardrail: a full `max_ticks_per_frame` burst runs F1–F3 for every villager within the frame budget at the 20–30 population ceiling.

---

## Acceptance Criteria

*From GDD `design/gdd/needs-mood-system.md`, scoped to this story:*

- [ ] **AC21**: Given a tick burst of `max_ticks_per_frame` ticks, When processed, Then F1–F3 apply **per tick in order** and threshold signals are emitted per-tick in-order — never coalesced, never deduplicated across the burst. [TR-needs-mood-system-057]
- [ ] **AC22**: Given identical tick counts dispatched at 1× vs 3× warp, When F1/F2 apply, Then the resulting values are **identical** — rates are functions of tick count, never wall-clock (Edge Case 9). [TR-needs-mood-system-063]
- [ ] **AC23**: Given pause (zero ticks dispatched), When real time passes, Then values and mood are unchanged — no decay, no recovery, no mood drift (Edge Case 7). [TR-needs-mood-system-062]
- [ ] **AC27**: Given default values, When a full sleep cycle runs (100 → urgent → sheltered-bed recovery → satisfied), Then the urgent event fires at tick **1072** and the satisfied event at tick **1212** — EXACT tick counts, never wall-clock. [TR-needs-mood-system-066]
- [ ] All decay/recovery/mood math is reached only through Time & Tick's `tick` signal — a grep proves no `_process`/`_physics_process` simulation math and no `Timer` in this module. [TR-needs-mood-system-051]
- [ ] A hypothetical fast need crossing **both** thresholds inside one burst delivers urgent-then-satisfied in order, never a deduplicated nothing (Edge Case 6 — tested with a mock fast need; today's sleep rates cannot do this, which is numeric coincidence, not a guarantee).

---

## Implementation Notes

*Derived from ADR-0008/0002 Implementation Guidelines:*

- This story is mostly **proof**, not new mechanism: stories 002/003/005 already do the per-tick work. What lands here is the burst/pause/warp harness, the ordering guarantees, and the two anchor tick counts that make the whole system falsifiable.
- The tick-count anchors: 1072 = `ceil((100 − 25) / 0.07)`; 1212 = 1072 + `ceil(70 / 0.5)` = 1072 + 140 (sheltered bed, full rate). Derive them in the test from config, then assert the literal — if a future retune changes the config, the test must fail loudly rather than silently follow.
- Warp invariance is a *dispatch* property: the test dispatches N ticks in both scenarios and asserts identical values. Do not sample wall-clock anywhere in this module.
- Pause is the absence of ticks. There is nothing to implement for AC23 beyond proving no other code path mutates state — that is the value of the test.
- Burst ordering: the tick handler must be re-entrant-safe across N synchronous emissions in one frame; no per-frame batching, no "apply N ticks at once" shortcut (which would be the coalescing the burst rule forbids).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 002/003/005: the F1/F2/F3 math being exercised here.
- Story 009: whether the 1072/1212 anchors are the *desired* pacing at `ticks_per_second = 4.0`.
- Time & Tick: pause/warp/burst-cap behavior itself (already landed).

---

## QA Test Cases

- **AC21**: Given a burst of `config.max_ticks_per_frame` ticks (read from config, not the literal 10) with a need positioned to cross the urgency threshold mid-burst, When the burst is dispatched, Then the value equals the per-tick-applied result and exactly one urgent emission is observed at the correct within-burst position.
- **AC21 (ordering)**: Given a mock **fast** need that crosses both thresholds inside one burst, When dispatched, Then emissions are observed as urgent-then-satisfied, in that order, both present.
- **AC22**: Given two module instances, one dispatched 500 ticks "at 1×" and one 500 ticks "at 3× warp", When compared, Then need values and mood are bit-identical.
- **AC23**: Given a set-up module, When zero ticks are dispatched over any number of frames, Then all values, mood, and states are unchanged and no event is emitted.
- **AC27**: Given a villager at 100 with defaults, When ticks are dispatched one at a time and `start_recovery(bed_sheltered)` is issued on the urgent event, Then the urgent event is observed on tick **1072** and the satisfied event on tick **1212** — with boundary checks on 1071/1073 and 1211/1213.
- **Grep**: Given the module source, When grepped, Then zero `_process`/`_physics_process` simulation math, zero `Timer`, zero `SceneTree.paused`, zero `Engine.time_scale`.
- Edge cases: a burst that starts while a need is already Recovering credits exactly one increment per tick in the burst; a `stop_recovery` landing between two ticks of the same burst credits zero from that point on.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `neues-spiel/tests/unit/needs_mood/burst_pause_warp_determinism_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002 (decay/signals), 003 (recovery), 005 (mood)
- Unlocks: 009 (the anchors it must not silently break), 010
