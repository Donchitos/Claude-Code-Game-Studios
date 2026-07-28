# Story 007: AStar3D graph build & shortest-path query

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-24 — 563/563 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-035`, `TR-villager-ai-behavior-072`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (AI Pathfinding, Navigation & Room-Analysis)
**ADR Decision Summary**: Travel pathfinding uses `AStar3D` (a standalone graph-search utility, NOT `NavigationServer3D`) — one point per standable cell, connections between legal-step pairs, queried via `get_id_path()`/`get_point_path()`. Point IDs are a deterministic `Vector3i → int64` bit-pack, never an incrementing counter.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: `AStarGrid3D` does NOT exist in Godot 4.7 (only `AStarGrid2D`) — manual `AStar3D` graph management is the only built-in option. `AStar3D` IDs are never auto-recycled on `remove_point()` — hence the deterministic bit-pack. F1's diagonal=1.4/orthogonal=1.0 maps onto AStar3D's default Euclidean heuristic between cell centers — no custom cost override needed for MVP.

**Control Manifest Rules (this layer)**:
- Required (Feature): Travel pathfinding via `AStar3D`: graph built once at boot, point IDs deterministic bit-packed `x&0x1FFFFF | y<<21 | z<<42`, never an incrementing counter. Points come from the shared `is_standable`; connections from `is_step_legal`.
- Forbidden: `NavigationServer3D`/`NavigationAgent3D`/`NavigationRegion3D` (grep-verifiable); an incrementing-counter ID scheme; duplicated walkability constants.
- Guardrail: nav graph covers a bounded settlement-core region (`nav_region_size` default 200, measured limit ≤200×200 — build ~1.1 s boot-only, query p95 9.2 ms), never the full world.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] The graph is built once at boot from Voxel World's initial terrain — one point per standable cell (via `is_standable`), connections for every legal-step pair (via `is_step_legal`).
- [ ] Point IDs are the deterministic `Vector3i → int64` bit-pack (`_cell_to_astar_id`) — the same cell always yields the same ID; no counter state.
- [ ] `get_id_path()`/`get_point_path()` return a shortest path whose step costs approximate orthogonal = 1.0, diagonal = 1.4 (F1); `path_length_cells` is derivable from the returned path.
- [ ] `travel_time_game_seconds = path_length_cells / move_speed`; `path_length_cells = 0` (target is current/adjacent cell) yields immediate arrival.
- [ ] The graph is scoped to the settlement-core region bound (`nav_region_size`), never the full world.

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

- `var _astar: AStar3D = AStar3D.new()`; `func _cell_to_astar_id(cell) -> int: return (cell.x & 0x1FFFFF) | ((cell.y & 0x1FFFFF) << 21) | ((cell.z & 0x1FFFFF) << 42)`.
- Add points only for cells passing `is_standable`; connect only pairs passing `is_step_legal`.
- Do not override `_compute_cost`/`_estimate_cost` for MVP — the Euclidean heuristic between cell centers already yields ~1.0/~1.41 (revisit only if a mismatch is measured).
- Incremental patching on writes is Story 008 — this story builds and queries the static graph.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: incremental add/remove of points/connections on `cell_changed`.
- Story 009: the Traveling state that consumes returned paths.
- Story 010: F2 job selection that ranks by path length.

---

## QA Test Cases

- **AC (build)**: Given a small synthetic standable region, When the graph is built, Then a point exists for every standable cell and connections exist for every legal-step pair (and none for illegal steps).
- **AC (deterministic IDs)**: Given the same cell, When `_cell_to_astar_id` is called repeatedly, Then it returns the identical ID; distinct cells yield distinct IDs across the region bound.
- **AC (path cost)**: Given a path with orthogonal and diagonal steps, When queried, Then `path_length_cells` reflects ~1.0/~1.4 weighting; a target on the current/adjacent cell yields length 0.
- Edge cases: unreachable target returns an empty path; region-bound edge cells.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/villager_ai/astar_graph_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002 (walkability predicates)
- Unlocks: 008, 009, 010, 014, 019, 020
