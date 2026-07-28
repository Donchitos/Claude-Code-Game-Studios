# Story 003: Pause & time-warp state (toggle, store, independence)

> **Epic**: Time & Tick System
> **Status: Complete (2026-07-23 — 193/193 suite green, parent-verified; AC-6 correctly deferred to tick-004)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: `design/gdd/time-tick-system.md`
**Requirement**: `TR-time-tick-system-023`, `TR-time-tick-system-024`, `TR-time-tick-system-040`, `TR-time-tick-system-045`, `TR-time-tick-system-039`, `TR-time-tick-system-046`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (config for `time_warp_options`) — primary; ADR-0001 — secondary (Autoload API surface Building UI calls)
**ADR Decision Summary**: Pause and time-warp are independent, self-owned runtime state (never Godot globals). Warp speeds come from the config `time_warp_options` set.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Pause/warp are owned as plain runtime state; do NOT reach for `SceneTree.paused` or `Engine.time_scale` (project-wide ban — they would freeze/​speed camera and UI too).

**Control Manifest Rules (this layer)**:
- Forbidden: `SceneTree.paused` (pause is `game_delta = 0`, owned here); `Engine.time_scale` (warp is the `game_delta` multiplier, owned here).
- Required: never write to a config Resource at runtime — `time_warp` is owned runtime state, not a config field.

---

## Acceptance Criteria

*From GDD `design/gdd/time-tick-system.md`, scoped to this story:*

- [ ] Selected time-warp is exactly one of {1, 2, 3} (GDD AC2). [TR-time-tick-system-023]
- [ ] Enabling Pause sets `game_delta` to 0 WITHOUT discarding the stored `time_warp`; disabling resumes at that exact stored speed (GDD AC3, AC4). [TR-time-tick-system-024]
- [ ] A time-warp change while paused is stored but has no effect until resumed; pause survives the warp change and the warp change survives the pause (GDD AC5, AC20). [TR-time-tick-system-040]
- [ ] Requesting pause while already paused is idempotent — state unchanged, no duplicate side effects (audio dampen, signal emissions) (GDD AC19). [TR-time-tick-system-045]
- [ ] Rapid successive Pause/warp toggles are each applied immediately and independently — no debounce (GDD AC16). [TR-time-tick-system-039]
- [ ] Any external `time_warp` change does NOT modify the tick accumulator's banked value (GDD AC21). [TR-time-tick-system-046]

---

## Implementation Notes

*Derived from ADR-0002 / ADR-0001 Implementation Guidelines:*

- Model `paused: bool` and `time_warp: int` as independent owned state. Pause is a factor in the `game_delta` formula (Story 002), not a mutation of `time_warp`.
- Guard the pause setter for idempotency: if already in the requested state, return early WITHOUT re-emitting `paused`-changed signals or re-triggering side effects.
- Validate incoming warp against the config `time_warp_options` set; reject values outside {1,2,3}.
- Warp changes touch only the multiplier applied to future `game_delta` — never the accumulator's stored value (that guarantee is asserted jointly with Story 004).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: the `game_delta` formula that consumes this state.
- Story 004: the tick accumulator whose banked value AC21 protects.
- Story 006: `Engine.time_scale`-stays-default integration assertion; Building UI wiring.

---

## QA Test Cases

- **AC-1 (warp set)**: Given a warp selection; When applied; Then stored value ∈ {1,2,3}. Edge cases: reject 0 and 4.
- **AC-2 (pause stores warp)**: Given `time_warp=3`; When pause enabled then disabled; Then resume warp is 3, not 1.
- **AC-3 (warp while paused)**: Given paused at 3x; When warp set to 2x then unpaused; Then game resumes at 2x. [AC20]
- **AC-4 (idempotent pause)**: Given already paused; When pause requested again; Then no state change and no second side-effect emission (spy on signal count).
- **AC-5 (no debounce)**: Given N rapid toggles in one frame; When each processed; Then final state matches the last toggle, each applied independently.
- **AC-6 (accumulator untouched by warp)**: Given a non-zero accumulator; When `time_warp` changes; Then the accumulator's stored value is unchanged (joint assertion with Story 004).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/time_tick_system/pause_warp_state_test.gd` (GdUnit4) — deterministic; must pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (game_delta formula must be DONE — pause is a factor in it).
- Unlocks: Story 004, Story 006.
