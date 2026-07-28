# Story 005: Max-ticks-per-frame safety cap

> **Epic**: Time & Tick System
> **Status: Complete (2026-07-24 — 311/311 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 0.5 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: `design/gdd/time-tick-system.md`
**Requirement**: `TR-time-tick-system-035`, `TR-time-tick-system-037`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (`max_ticks_per_frame` from config) — primary
**ADR Decision Summary**: The catch-up cap is a config tunable. Excess accumulated time beyond the cap is discarded, not deferred — this system only bounds overload, it does not fix it.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Uses `floor()` on the accumulator/​interval ratio; keep in float64. No engine-specific API risk here.

**Control Manifest Rules (this layer)**:
- Required: tunables (`max_ticks_per_frame`) from config, never hardcoded.
- Guardrail: repeatedly hitting the cap is a performance SIGNAL (fix via profiling), not something this system corrects.

---

## Acceptance Criteria

*From GDD `design/gdd/time-tick-system.md`, scoped to this story:*

- [ ] `ticks_to_fire = min(floor(tick_accumulator / tick_interval), max_ticks_per_frame)`; excess accumulated time beyond the cap is DISCARDED, not deferred (GDD AC11). [TR-time-tick-system-035]
- [ ] Repeatedly hitting the cap across consecutive frames gets no special handling here — it is only a performance signal; this system bounds overload but does not fix it (GDD Edge Case). [TR-time-tick-system-037]

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

- After accumulating `game_delta`, compute `raw_ticks = floor(tick_accumulator / tick_interval)`, then fire `min(raw_ticks, max_ticks_per_frame)` ticks. Discard the remainder by subtracting only the fired ticks' interval AND clearing the excess (the discarded time is not carried — per GDD, "excess time beyond the cap is discarded, not deferred").
- Worked example (GDD, `ticks_per_second=4.0`): a 12.3 s alt-tab stall → `raw_ticks=49` → capped to 10, remaining 9.8 s silently discarded (no catch-up cascade next frame).
- Consumer caveat (embed in the API doc comment): downstream invariants phrased as "exactly N ticks per interval" hold only barring a discard event — consumers must derive durations from observed tick COUNTS. [TR-time-tick-system-036]

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: the base accumulator/subtraction loop this cap wraps.
- Story 007: re-tuning `max_ticks_per_frame` against production load.

---

## QA Test Cases

- **AC-1 (cap + discard)**: Given accumulator = 12.3 s, `tick_interval=0.25`, `max_ticks_per_frame=10`; When processed; Then exactly 10 ticks fire and the ~9.8 s excess is discarded (next frame does NOT fire catch-up ticks from it). Edge cases: `raw_ticks` exactly = cap (fires all, no discard); `raw_ticks` = cap+1 (one discarded).
- **AC-2 (signal, not correction)**: Given the cap is hit on consecutive frames; When observed; Then no internal state accrues to "catch up" later — behaviour is memoryless past the discard.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/time_tick_system/max_ticks_cap_test.gd` (GdUnit4) — deterministic; must pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004 (tick accumulator must be DONE).
- Unlocks: Story 007 (re-tune consumes the cap value).
