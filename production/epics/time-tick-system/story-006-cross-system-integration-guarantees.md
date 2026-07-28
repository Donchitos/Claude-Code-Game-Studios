# Story 006: Cross-system integration guarantees (Engine.time_scale untouched, transition non-suspension)

> **Epic**: Time & Tick System
> **Status: Complete (2026-07-24 — 669/669 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 0.5 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-24

## Context

**GDD**: `design/gdd/time-tick-system.md`
**Requirement**: `TR-time-tick-system-025`, `TR-time-tick-system-027`, `TR-time-tick-system-030`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (Inter-System Reference & DI Pattern) — primary (this system consumes nothing, including Scene/World Management); ADR-0002 — secondary
**ADR Decision Summary**: Time & Tick has an explicit non-dependency contract — no system calls into it on transition events; warp/pause persist across all scene transitions as global state. The engine-global `Engine.time_scale` stays at default 1.0.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: The `Engine.time_scale` / `SceneTree.paused` ban is a project-wide guardrail; this story adds the regression assertion that `Engine.time_scale` reads 1.0 throughout gameplay. Autoload readies before the Main Scene, so its clock is live before any transition can occur.

**Control Manifest Rules (this layer)**:
- Forbidden (project-wide, absolute): `SceneTree.paused`, `Engine.time_scale` — grep must return zero in this system.
- Required: this Autoload has zero upstream dependencies; no transition API surface exists on it (the former time-warp-reset function is retired).

---

## Acceptance Criteria

*From GDD `design/gdd/time-tick-system.md`, scoped to this story:*

- [ ] `Engine.time_scale` remains at its default (1.0) regardless of this system's pause/warp state (GDD AC6). [TR-time-tick-system-025]
- [ ] When a scene transition begins, this system's `game_delta` continues to be computed normally — not suspended (GDD AC7). [TR-time-tick-system-027]
- [ ] Across a full transition (begin → complete), this system's state (`time_warp`, `paused`, accumulator) is untouched — no API of this system is invoked by transition events (GDD AC8). [TR-time-tick-system-030]

---

## Implementation Notes

*Derived from ADR-0001 Implementation Guidelines:*

- Add a grep-verifiable regression check that `Engine.time_scale` and `SceneTree.paused` are never touched (the pause/warp mechanism is Story 003's self-owned multiplier).
- Confirm the system exposes NO transition-reset entry point (the retired time-warp-reset function must not exist). Scene/World Management does not call into Time & Tick.
- The transition-persistence guarantee is behavioural: drive a mock transition sequence and assert `time_warp`/`paused`/accumulator are unchanged and `game_delta` kept computing.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: the pause/warp state itself.
- Story 004: the accumulator whose persistence this story asserts.
- Building UI wiring of the pause/warp API (TR-041) — Building UI is Milestone 02 Presentation scope.

---

## QA Test Cases

- **AC-1 (time_scale default)**: Given any sequence of pause/warp changes; When `Engine.time_scale` is read; Then it is 1.0. Edge cases: warp 3x + paused; also grep asserts zero `Engine.time_scale`/`SceneTree.paused` writes.
- **AC-2 (transition non-suspension)**: Given a transition begins; When frames advance; Then `game_delta` is still computed each frame.
- **AC-3 (state untouched)**: Given `time_warp=3, paused=true`, accumulator=X; When a mock transition begins and completes; Then all three values are unchanged and no Time & Tick API was invoked by the transition.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/time_tick_system/transition_persistence_test.gd` (GdUnit4) with a mock transition driver, PLUS a grep assertion (`rg --glob "*.gd"` for `Engine.time_scale|SceneTree.paused` in this system → zero). Must pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (pause/warp state), Story 004 (accumulator) — both DONE.
- Unlocks: None (integration guarantee; consumed by the milestone E2E LOOP test).
