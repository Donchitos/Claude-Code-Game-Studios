# Story 004: Deterministic position model & movement interpolation

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-24 — 524/524 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-029`, `TR-villager-ai-behavior-046`, `TR-villager-ai-behavior-042`, `TR-villager-ai-behavior-048`, `TR-villager-ai-behavior-073`, `TR-villager-ai-behavior-093`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009 (Deterministic Movement & Occupancy Ordering)
**ADR Decision Summary**: Two-layer position model — `current_cell` is DISCRETE, tick-boundary-quantized, the sole authoritative value for every logic query; `_visual_position` is CONTINUOUS, lerped every frame on `game_delta` for rendering ONLY and never read by any logic. `current_cell` becomes `to_cell` atomically at tick-boundary arrival. Work progress credited only at tick boundaries.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `_intra_tick_progress` is advanced by the tick system (`game_delta`), NOT raw `_delta` — villagers must NOT glide while paused. Set the visual node's `physics_interpolation_mode = OFF` explicitly (defends against project-wide interpolation flips → double interpolation). Never use `SceneTree.paused` / `Engine.time_scale`.

**Control Manifest Rules (this layer)**:
- Required (Core): Occupancy authoritative value = discrete `current_cell: Vector3i` — changes ONLY at tick boundaries, atomically; `_visual_position` is render-only. Visual lerp `_visual_position = _from_cell.lerp(_to_cell, _intra_tick_progress)` advances via `game_delta` ticks only (frozen during pause). Villager visual node sets `physics_interpolation_mode = OFF` explicitly.
- Forbidden: reading `_visual_position` outside movement/rendering (grep-verifiable); integrating raw `_delta` into `_intra_tick_progress`; flipping `current_cell` at interpolation midpoint; snap/teleport during ordinary travel (the watchdog rescue is the ONE sanctioned exception, Story 015).
- Guardrail: negligible — two existing-scale fields, no new data structures.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] `get_current_cell()` returns `from_cell` for a mid-transit villager (progress > 0, < 1) — never `to_cell` and never an interpolation-derived value.
- [ ] `current_cell` updates to `to_cell` in a single atomic assignment at the tick boundary where arrival is credited — no mid-interpolation flip.
- [ ] The first work-progress increment after arrival is credited at the NEXT tick boundary, never partially (AC13, applies to every Traveling→Working transition incl. a 1-cell adjacent step).
- [ ] Given injected `game_delta` values (incl. a warped value), per-step displacement never exceeds `move_speed × game_delta` — property check over ≥5 samples against the movement-update function directly (AC20).
- [ ] Under pause, position is unchanged as real time passes; under 2x warp, wall-clock travel halves while game-time cost is constant (AC21). `_visual_position` freezes during pause (advanced on `game_delta`, not raw delta).

---

## Implementation Notes

*Derived from ADR-0009 Implementation Guidelines:*

- Fields: `current_cell: Vector3i` (authoritative), `_from_cell`, `_to_cell`, `_visual_position: Vector3` (cosmetic), `_intra_tick_progress` (tick-owned).
- `_process(delta)` recomputes `_visual_position = _from_cell.lerp(_to_cell, _intra_tick_progress)` ONLY — never touches `current_cell`, never integrates raw `_delta`.
- `_on_tick()` performs the atomic `current_cell = _to_cell` at arrival (one of exactly two sanctioned mutation points; the watchdog rescue is the other — Story 015).
- F1 travel-time: `travel_time_game_seconds = path_length_cells / move_speed`; orthogonal step = 1.0, diagonal = 1.4. Consumers count observed ticks, never derive durations from clock arithmetic (max_ticks_per_frame discard caveat).
- Explicitly set `physics_interpolation_mode = OFF` on the villager visual node.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: the body-column derived from `current_cell`.
- Story 009: the Traveling state machine that drives `_from_cell`/`_to_cell`/re-path.
- Story 015: the sanctioned watchdog-rescue mutation of `current_cell`.

---

## QA Test Cases

- **AC (get_current_cell)**: Given a villager mid-transit (from set, to set, progress in (0,1)), When `get_current_cell()`, Then it returns `from_cell`. Edge cases: progress exactly 0 and exactly 1.
- **AC13**: Given arrival between two ticks, When Working begins, Then the first increment credits at the next tick boundary, never partial.
- **AC20**: Given ≥5 injected `game_delta` samples incl. a warped one, When movement updates, Then per-step displacement ≤ `move_speed × game_delta` every sample (property-based, no real engine frames).
- **AC21**: Given pause, When real time passes, Then position unchanged; Given 2x warp, Then wall-clock travel halves, game-time cost constant.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/villager_ai/deterministic_position_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001 (scaffold/config), 003 (body-column reads current_cell)
- Unlocks: 008, 009, 013
