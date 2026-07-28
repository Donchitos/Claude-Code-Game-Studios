# Story 002: game_delta computation (formula, clamp, raw-delta preservation)

> **Epic**: Time & Tick System
> **Status: Complete (2026-07-23 — 146/146 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: `design/gdd/time-tick-system.md`
**Requirement**: `TR-time-tick-system-021`, `TR-time-tick-system-031`, `TR-time-tick-system-026`, `TR-time-tick-system-022`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (Tuning/Config Data Strategy) — primary (the `max_raw_delta` clamp value is config-driven); ADR-0001 — secondary (Autoload query surface)
**ADR Decision Summary**: Tunables come from typed config; the clamp ceiling `max_raw_delta` is read from config, never hardcoded. `game_delta` is a derived value the system additionally exposes; it never replaces raw engine delta.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Computation runs in `_physics_process` (fixed step). Verify `physics_ticks_per_second = 60` project default still holds in 4.7 — every worked example depends on it. The accumulator/`game_delta` must use GDScript `float` (float64), not a 32-bit packed float.

**Control Manifest Rules (this layer)**:
- Required: simulation runs on Time & Tick's `game_delta`; camera/UI/overlays run on raw engine delta — never blend the two clocks for one piece of state.
- Forbidden: `Engine.time_scale` / `SceneTree.paused` (project-wide absolute).
- Guardrail: `game_delta` + tick-accumulator computation stays under 0.5 ms combined per physics frame (measured in Story 007).

---

## Acceptance Criteria

*From GDD `design/gdd/time-tick-system.md`, scoped to this story:*

- [ ] `game_delta = clamp(raw_delta, 0, max_raw_delta) * time_warp * (paused ? 0 : 1)`, within floating-point tolerance 1e-6 (GDD AC1). [TR-time-tick-system-021]
- [ ] `raw_delta` is clamped to `max_raw_delta` BEFORE `game_delta` is computed and before all use in this system (GDD AC12). [TR-time-tick-system-031]
- [ ] Raw engine delta remains unmodified and available to every other system — this system only additionally computes/exposes `game_delta` (GDD AC15). [TR-time-tick-system-026]
- [ ] Simulation consumers query `game_delta`, never raw engine delta (GDD Core Rule 1). [TR-time-tick-system-022]

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

- Compute in `_physics_process(delta)`: clamp `delta` to `[0, max_raw_delta]` first, then multiply by `time_warp` and the pause factor. Store the result as the exposed `game_delta` (owned runtime state), leaving the engine's `delta` untouched.
- Expose `game_delta` via a public getter so injected-tier consumers can query it; do not push it into a config Resource.
- The clamp ceiling `max_raw_delta` is read from the Story 001 config, not a literal.
- Worked example (GDD Formulas): `raw_delta=0.0167, time_warp=2, paused=false → game_delta=0.0334`; same frame `paused=true → 0.0`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: the `time_warp` / `paused` state transitions this formula reads.
- Story 004: feeding `game_delta` into the tick accumulator.

---

## QA Test Cases

- **AC-1 (formula)**: Given `raw_delta`, `time_warp`, `paused`; When `game_delta` is computed; Then it equals `clamp(raw_delta,0,max_raw_delta)*time_warp*(paused?0:1)` within 1e-6. Edge cases: `time_warp` ∈ {1,2,3}; `paused=true` → exactly 0.0.
- **AC-2 (clamp precedence)**: Given `raw_delta` > `max_raw_delta` (e.g. 12.3 s stall); When computed; Then the clamp is applied before the warp multiply (result uses `max_raw_delta`, not the raw value). Edge cases: `raw_delta == max_raw_delta` boundary; `raw_delta = 0`.
- **AC-3 (raw preserved)**: Given a frame; When `game_delta` is computed; Then the engine `delta` passed to other nodes is unchanged. Edge cases: verify no write-back to the engine delta.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/time_tick_system/game_delta_computation_test.gd` (GdUnit4) — deterministic, fixed `raw_delta` inputs; must pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (config + Autoload skeleton must be DONE).
- Unlocks: Story 003, Story 004.
