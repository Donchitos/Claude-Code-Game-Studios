# Story 002: Walkability predicates (is_standable / is_step_legal)

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-24 — 388/388 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-009`, `TR-villager-ai-behavior-010`, `TR-villager-ai-behavior-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (AI Pathfinding, Navigation & Room-Analysis)
**ADR Decision Summary**: Villager AI owns the walkability predicates as shared **pure functions** — the single source of truth every consumer (its own pathfinder, Build Validation, watchdog rescue BFS) calls. No duplicated rules or constants anywhere.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: Navigation/AI-pathfinding is a flagged HIGH-risk domain. These predicates read Voxel World occupancy directly (chunked accessor `get` by `Vector3i`); no `NavigationServer3D`. `AStarGrid3D` does not exist in 4.7 — irrelevant here (predicates are pure functions, not a grid).

**Control Manifest Rules (this layer)**:
- Required (Feature layer): Walkability = two shared pure functions owned by Villager AI: `is_standable(cell) -> bool` (solid below + clearance for the 2-block body) and `is_step_legal(from, to) -> bool` (|dy| ≤ 1; diagonal only if both flanking orthogonals passable). EVERY consumer calls these.
- Forbidden: duplicate walkability rules or constants (no plain 4/8-neighbor flood-fill, no second copy of clearance/step values); `NavigationServer3D`/`NavigationAgent3D`/`NavigationRegion3D`.
- Guardrail: predicates are pure queries against Voxel World data — no mutation, no caching state of their own.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] A cell is standable iff the cell below is solid (terrain or Built — blueprints are non-solid) AND the cell itself plus the two cells above are empty (`villager_clearance` = 3, a registered constant) — a cell without 3-cell vertical clearance is NOT standable (AC14).
- [ ] A Planned blueprint cell in the path is treated as passable (non-solid) — Building Core Rule 14b (AC17).
- [ ] A step between adjacent standable cells is legal iff height difference ≤ 1 cell; difference ≥ 2 is illegal (AC15). Orthogonal steps only.
- [ ] A diagonal step is legal only when both flanking orthogonal cells are also passable — no corner-cutting through walls (AC16).
- [ ] Both predicates are pure functions consulting Voxel World occupancy + the shared movement constants; they are the exact definition Build Validation later queries (TR-011) — no second copy exists.

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

- Signatures exactly: `func is_standable(cell: Vector3i) -> bool` and `func is_step_legal(from_cell: Vector3i, to_cell: Vector3i) -> bool`.
- Read `villager_clearance` (3) and `max_step_height` (1) from the registry / shared constants — never inline literals.
- Blueprint cells are non-solid for the "solid below" and "empty" checks — treat only Built/terrain as solid.
- No corner-cutting: for a diagonal from A to B, both orthogonal cells sharing A and B must be passable.
- These functions must be side-effect-free so the pathfinder, Build Validation BFS, and the watchdog rescue BFS (Story 014) can all call them identically.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: the 2-block body-column derivation (TR-098) that anti-stuck/seal reuse.
- Story 007: the AStar3D graph that is built from these predicates.

---

## QA Test Cases

- **AC14**: Given a cell with a solid cell below but only 2 empty cells above, When `is_standable` runs, Then false (needs full 3-cell clearance). Edge cases: exactly 3 clear = true; low ceiling of Built blocks = false.
- **AC17**: Given a Planned blueprint cell, When treated as an occupancy input, Then it is passable/non-solid. Edge cases: blueprint directly below a candidate stand cell → not "solid below".
- **AC15**: Given two adjacent standable cells with |dy| = 1, When `is_step_legal`, Then true; |dy| = 2 → false. Edge cases: |dy| = 0 flat step true.
- **AC16**: Given a diagonal step whose one flanking orthogonal cell is blocked, When `is_step_legal`, Then false. Edge cases: both flankers passable → true.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/villager_ai/walkability_predicates_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001 (config/scaffold + shared constants access)
- Unlocks: 003, 007, 014, 023
