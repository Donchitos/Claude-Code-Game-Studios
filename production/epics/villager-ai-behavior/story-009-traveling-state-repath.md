# Story 009: Traveling state — path following & mid-travel re-path

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-24 — 598/598 suite green, parent-verified)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-036`, `TR-villager-ai-behavior-046`, `TR-villager-ai-behavior-092`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009 (Deterministic Movement) — primary; ADR-0007 (AStar3D paths)
**ADR Decision Summary**: The Traveling state follows the computed AStar3D path cell-by-cell on discrete `current_cell`; a blocking Voxel World write redirects/aborts the step in the same synchronous call stack (before the next `_process` advances `_visual_position`), bounding the visual-clipping window.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: Synchronous signal emission is load-bearing for the race closure — the re-path filter (Story 008) fires within the write's call stack. Movement is cell-interpolation, never a physics body / `CharacterBody3D`.

**Control Manifest Rules (this layer)**:
- Required (Core): race closure relies on synchronous signals — `cell_changed` fires synchronously, the re-path filter redirects in the same call stack; `current_cell` remains `from_cell` for the whole transit.
- Forbidden: snap/teleport during ordinary travel; reading `_visual_position` for any logic; keeping travel toward a dead target.
- Guardrail: re-path only when the write intersects the remaining path (Story 008 filter).

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] A Traveling villager follows the computed path cell-by-cell; arrival on site transitions to the next state (Working/Sleeping/etc.).
- [ ] Given a Voxel World write blocks the current path mid-travel, the villager re-paths from its current cell (AC18, Edge Case 1).
- [ ] Given a Traveling villager whose target becomes invalid before arrival (bed destroyed, job voided) with no re-path possible, it exits to Deciding and re-selects — never keeps traveling toward a dead target (AC19).
- [ ] For a job whose target becomes unreachable mid-travel: report to Building System (orange ghost), release the claim, pick the next job (F2, via Story 011); for a bed: fall back to ground sleep; for a wander target: pick a new one.
- [ ] The redirect happens in the write's synchronous call stack, before the next frame advances `_visual_position` toward newly-solid geometry.

---

## Implementation Notes

*Derived from ADR-0009/0007 Implementation Guidelines:*

- `_tick_traveling()` advances along the AStar3D `get_id_path()` result; each step is a `from_cell`→`to_cell` transit with tick-boundary arrival (Story 004).
- On a re-path signal from Story 008's filter, recompute the path from `current_cell`; if empty/unreachable, exit to Deciding with the appropriate per-target fallback (job/bed/wander).
- Do not reason about `_visual_position` — all logic reads `current_cell`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: the write-intersection filter that fires the re-path.
- Story 011: claim release / next-job selection on unreachable job.
- Story 015: the watchdog rescue (a different exit than re-path).

---

## QA Test Cases

- **AC18**: Given a blocking write mid-travel, When the `cell_changed` fires, Then the villager re-paths from its current cell (Integration, real graph patch).
- **AC19**: Given the travel target is voided with no re-path, When detected, Then the villager exits to Deciding and re-selects.
- **AC (race closure)**: Given a write at the villager's `to_cell` mid-transit, When the synchronous signal fires, Then the redirect occurs before `_visual_position` advances further (assert same call stack).
- Edge cases: per-target fallback (job→report+release, bed→ground sleep, wander→new target).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/villager_ai/traveling_repath_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 008 (graph patching + re-path filter), 004 (position model), 006 (Deciding exit)
- Unlocks: 012, 018, 019
