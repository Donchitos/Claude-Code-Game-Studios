# Story 014: Rescue-target BFS (F5 expanding-ring search)

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-25 — 910/910 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-25

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-100`, `TR-villager-ai-behavior-105`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (shared predicates) — primary; ADR-0009 (deterministic rescue target)
**ADR Decision Summary**: Rescue-target selection is a bounded expanding-ring BFS for the nearest standable, unoccupied cell within `unstuck_rescue_search_radius`, tie-broken by the F2 lexicographic (y,x,z) convention. If none is found, the radius doubles up to `unstuck_rescue_max_radius` before deferring to the next tick.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: BFS calls the shared `is_standable` (Story 002) — never a duplicate rule. Determinism via lexicographic tie-break. This is the target-selection half of the watchdog (trigger is Story 015).

**Control Manifest Rules (this layer)**:
- Required (Feature): watchdog rescue-target BFS via expanding-ring search (`unstuck_rescue_search_radius`/`_max_radius`) with the F2 lexicographic tie-break; calls the shared predicates.
- Forbidden: unbounded teleport-anywhere; a duplicated standability rule; non-deterministic tie-break.
- Guardrail: bounded ring search — radius doubles up to a ceiling, then defers.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [x] `rescue_target = nearest(cell)` such that `cell` is standable (Rule 8) and unoccupied (no other villager's `current_cell`), found by an expanding-ring BFS from `current_cell` out to `unstuck_rescue_search_radius`; tie-break lexicographic (y, x, z). — `VillagerRescueTargetSearch.find_rescue_target`
- [x] Given no standable, unoccupied cell within `unstuck_rescue_search_radius`, the radius doubles (up to `unstuck_rescue_max_radius`) before a rescue defers to the next tick (AC53, Edge Case 14). — `find_rescue_target`'s doubling loop; integration test `rescue_search_expansion_test.gd`
- [x] Given the search still finds no cell at `unstuck_rescue_max_radius`, the rescue defers to the next tick and a `villager_unstuck_search_failed` event fires exactly once for the stuck episode (not once per tick). — `RescueSearchFailureGate` (flag owned here; watchdog Story 015 owns episode reset + actual event emission)
- [x] Occupancy for "unoccupied" is derived from other villagers' discrete `current_cell`, not `_visual_position`. — body-column overlap check against caller-supplied `current_cell` values, never `_visual_position`

---

## Implementation Notes

*Derived from ADR-0007/0009 (F5) Implementation Guidelines:*

- BFS uses the shared `is_standable` predicate and the body-column occupancy (Story 003) to reject cells whose column collides with another villager.
- Deterministic ordering: expand rings outward, within a ring order by lexicographic (y,x,z).
- Expose the search as a function the watchdog (Story 015) calls; the once-per-episode `villager_unstuck_search_failed` flag is owned here (the watchdog owns the per-episode lifecycle).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 015: the watchdog trigger, teleport, claim-release, and success telemetry.

---

## QA Test Cases

- **AC (nearest standable)**: Given a stuck cell with a standable unoccupied cell 2 rings away, When BFS runs, Then that cell is returned (within `unstuck_rescue_search_radius`).
- **AC (tie-break)**: Given two equidistant valid cells, When BFS runs, Then the lexicographically (y,x,z) smaller is chosen, identically across runs.
- **AC53**: Given no cell within the initial radius, When search completes, Then the radius doubles up to `unstuck_rescue_max_radius`; if still none, defer + `villager_unstuck_search_failed` fires exactly once per episode.
- Edge cases: occupied cells (other villagers' current_cell) excluded; a fixture needing radius expansion (integration-scale).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/villager_ai/rescue_target_bfs_test.gd` — must exist and pass. (AC53 radius-expansion may use `tests/integration/villager_ai/rescue_search_expansion_test.gd` for the multi-cell fixture.)

**Status**: [x] Created — both files present and passing (6 unit + 3 integration test functions)

---

## Dependencies

- Depends on: 002 (is_standable), 003 (body-column occupancy)
- Unlocks: 015
