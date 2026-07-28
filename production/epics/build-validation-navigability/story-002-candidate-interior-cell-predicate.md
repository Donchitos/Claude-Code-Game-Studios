# Story 002: Candidate interior cell predicate (standable + roofed, furniture-transparent)

> **Epic**: Build Validation & Navigability
> **Status: Complete (2026-07-26 — 1004/1004 suite green 0 orphans, parent-verified)
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-26

## Context

**GDD**: `design/gdd/build-validation-navigability.md`
**Requirement**: `TR-build-validation-navigability-021`, `TR-build-validation-navigability-022`, `TR-build-validation-navigability-023`, `TR-build-validation-navigability-031`, `TR-build-validation-navigability-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (AI Pathfinding, Navigation & Room Analysis)
**ADR Decision Summary**: Villager AI owns the walkability predicates as shared pure functions; every consumer — Build Validation included — calls `is_standable`/`is_step_legal` directly. Build Validation is a read-only consumer of Villager AI's walkability, never a caller into its pathfinding internals, and never duplicates the rules or the constants.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `VoxelWorldGrid.get_cell()` returns `null` out of bounds — the landed predicates already treat that as neither solid nor passable. Use `get_cell` / `get_chunk_snapshot` for the roof scan; do not iterate the world.

**Control Manifest Rules (this layer)**:
- Required (Feature): walkability = the two shared pure functions owned by Villager AI; **every** consumer calls these — single source of truth.
- Forbidden: a plain 4/8-neighbor flood-fill in Build Validation; a second copy of the clearance/step values; any `NavigationServer3D`/`NavigationAgent3D`/`NavigationRegion3D` reference.
- Guardrail: predicates are pure queries — no mutation, no caching state of their own.

**RESOLVED — furniture transparency is satisfied by construction; this story is
NOT blocked on `building-028`** (was Epic Known Conflict 1). Technical-director
ruling **BV-1**, `production/architecture-decisions-m02-preflight-2026-07-26.md`
— **PROVISIONAL, pending user ratification** (away-mode ruling; treat as the
planning assumption until ratified).

**Ruling: furniture is not voxel data. It never enters `VoxelWorldGrid`.**
`CellContents` does not change. Furniture occupancy lives in a Building-System-owned
furniture registry keyed by placed-item identity (`building-028`), and
`ConstructionTickLoop` must **exclude `Category.FURNITURE` from its `bulk_write`
payload** — that is a **blocking AC on `building-028`**, not on this story.
Consequently a furniture cell reads **empty** from the grid, and Rule 1's
transparency clause is satisfied with **no branch anywhere in Build Validation
and no change to `is_standable`**. It is the identical mechanism the landed
`is_standable` doc comment already relies on for Planned blueprint cells.

**Consequence: story 002 loses its hard `building-028` dependency entirely.** The
furniture-transparency AC becomes a **proof-by-construction** test (a completed
furniture cell reads empty, so candidacy is unchanged). This story can start as
soon as 001 does. The hard blocker moved off Cluster A's critical path and onto
`building-028`'s own AC list.

**Walkability call form** (BV-4): standability is reached **statically** via
`VillagerWalkabilityRules.is_standable(voxel_world, cell)`. There is no injected
walkability provider and no `VillagerAi` reference in this module.

---

## Acceptance Criteria

*From GDD `design/gdd/build-validation-navigability.md`, scoped to this story:*

- [ ] A **candidate interior cell** is a cell that is **standable per Villager AI's Rule 8, consumed verbatim** (solid cell directly below — built floor or terrain — and the cell plus the two cells above it empty, `villager_clearance` = 3) **AND roofed**: scanning straight up from the cell, the NEAREST solid cell sits at most `max_room_height` above it. [TR-021]
- [ ] **GIVEN** an interior cell with roof exactly `max_room_height` above, **WHEN** analyzed, **THEN** it is a candidate cell; **GIVEN** one cell higher, **THEN** it is not (AC6, Rule 1 boundary). [TR-021]
- [ ] For this analysis, furniture occupancy is **transparent**: a cell occupied by furniture evaluates as if empty (furniture never counts as floor, wall, or roof), so a furniture item's own cell has a well-defined candidate status. **Satisfied by construction per BV-1** — furniture never enters the grid, so this is asserted as a property (a furniture-occupied cell reads empty ⇒ identical candidacy), **not** implemented as a branch and **not** dependent on `building-028`. [TR-022]
- [ ] **"Solid" means Voxel World block occupancy only** — character positions (including a villager mid-F4-vacate) never affect candidacy; this analysis reads only static physical occupancy. [TR-023]
- [ ] **GIVEN** blueprint (unbuilt) cells forming a would-be roof, **WHEN** analyzed, **THEN** they do NOT count as solid — analysis is built-only in MVP (AC23, Rule 7). [TR-031]
- [ ] **GIVEN** mocked changed walkability constants in the registry, **WHEN** reachability is evaluated, **THEN** the updated values are used — no independent copies (AC24, Rule 2 verbatim-consumption). [TR-010]

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

- Standability is **not** re-derived here: call `VillagerWalkabilityRules.is_standable(voxel_world, cell)` statically (BV-4). Its landed implementation already checks solid-below + `VILLAGER_CLEARANCE` passability and treats out-of-bounds as blocking.
- Furniture transparency needs **no code**. Under BV-1 a completed furniture cell is never written to `VoxelWorldGrid`, so it reads empty exactly as a Planned blueprint cell does. Write the AC as a property assertion over the grid, not as a furniture-aware branch — a branch here would be the defect BV-1 exists to prevent.
- The roof scan is a straight upward walk from the cell: find the nearest solid cell; candidate iff that distance ≤ `max_room_height`. Standability already guarantees the roof is at least `villager_clearance` cells up — a crawlspace (roof 1–2 above the floor) is never interior (Edge Case 13), and that falls out of the predicate rather than needing its own branch.
- Blueprint cells are non-solid **by construction**: a Planned/UnderConstruction cell has not been written to the grid yet, so `get_cell` reads it empty. AC23 should assert that property, not add a blueprint-aware branch.
- Character transparency likewise falls out: `VoxelWorldGrid` stores blocks, not villagers. AC24's registry-constant test is the guard that no local copy was introduced; AC38 (story 003) is the guard that occupancy stays invisible end-to-end.
- Keep the predicate a pure query — no memoization, no cached snapshot. Rule 11's snapshot is edge-detection memory (story 005), never a compute cache.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: orthogonal region formation and `min_room_cells` counting.
- Story 004: the outside-connection trace and the Room/Sealed verdict.
- Story 006: shelter classification of the furniture item itself.

---

## QA Test Cases

- **AC6**: Given an interior cell with roof exactly `max_room_height` above, When analyzed, Then candidate; given one cell higher, Then not candidate.
- **AC23**: Given a blueprint-only would-be roof above a standable cell, When analyzed, Then the cell is not roofed and not a candidate.
- **AC24**: Given mocked walkability constants changed in the registry, When candidacy is evaluated, Then the changed values take effect — proving no local copy.
- **Furniture transparency (proof by construction, BV-1)**: Given a cell recorded as furniture-occupied in a stub furniture registry but — per BV-1 — absent from `VoxelWorldGrid`, When analyzed, Then the cell's candidate status is identical to the same cell with no furniture at all; and given a furniture item placed where a wall/floor/roof would be needed, Then that structural role is NOT satisfied. No `building-028` code is required to run this test.
- Edge cases: cell at the world boundary (out-of-bounds reads never solid, never passable); a crawlspace with roof 2 above the floor yields zero candidate cells; open sky above a standable cell (no solid within `max_room_height`) is not a candidate.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `neues-spiel/tests/unit/build_validation/candidate_cell_test.gd` — must exist and pass.

**Status**: [x] Created — `neues-spiel/src/build_validation/candidate_cell_rules.gd` +
`neues-spiel/tests/unit/build_validation/candidate_cell_test.gd` (14 tests)

---

## Dependencies

- Depends on: 001 (config + DI scaffold). **No external blocker** — the `building-028` dependency is **dropped** per BV-1; furniture transparency is proven by construction. Transitively requires `villager-ai-026` via story 001.
- Unlocks: 003, 010

