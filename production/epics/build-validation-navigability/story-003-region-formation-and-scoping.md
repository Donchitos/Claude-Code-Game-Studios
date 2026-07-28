# Story 003: Candidate region formation & affected-region scoping

> **Epic**: Build Validation & Navigability
> **Status: Complete (2026-07-26 — 1053/1053 suite green 0 orphans, agent-verified; parent re-verifies with the concurrent vox-021)
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/build-validation-navigability.md`
**Requirement**: `TR-build-validation-navigability-024`, `TR-build-validation-navigability-020`, `TR-build-validation-navigability-023`, `TR-build-validation-navigability-059`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (AI Pathfinding, Navigation & Room Analysis)
**ADR Decision Summary**: Build Validation runs its own independent BFS/flood-fill over cells that pass the shared predicates — a full-connectivity question, not a shortest-path one. It never touches Villager AI's `AStar3D` instance. Backing store is Voxel World's own cell storage, giving O(affected-region) lookups natively.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `Dictionary[Vector3i, bool]` visited-sets are the ADR's reference shape. `VoxelWorldGrid` is chunked with paged residency (ADR-0015) — an unbounded flood-fill can walk across chunk boundaries; use `get_cell`, never a full-world iteration.

**Control Manifest Rules (this layer)**:
- Required (Feature): Build Validation runs its own independent BFS calling the shared predicates.
- Forbidden: a plain 4/8-neighbor flood-fill used as the *movement* graph (region **membership** is orthogonal by design — the distinction is load-bearing, see Implementation Notes); `NavigationServer3D` in any form.
- Guardrail: BFS is O(region size) per pass; **documented accepted-risk boundary — Build Validation BFS exceeds one frame above ~12k connected cells** (ADR-0007 + spike report). Do not add a knob to bound it; the unbounded behavior is the specified MVP design (TR-020).

---

## Acceptance Criteria

*From GDD `design/gdd/build-validation-navigability.md`, scoped to this story:*

- [ ] A **candidate region** is a maximal orthogonally-connected set of candidate interior cells — orthogonal adjacency defines region **membership only**; movement/reachability uses the villager movement graph (Rule 2, story 004). [TR-024]
- [ ] **GIVEN** two interiors connected by a gap, **WHEN** analyzed, **THEN** they form ONE region with one status (AC7, Edge Case 1). [TR-024]
- [ ] **GIVEN** a region at the world edge, **WHEN** analyzed, **THEN** the boundary is neither wall nor opening; reachability uses in-bounds cells only (AC11, Edge Case 12). [TR-059]
- [ ] **GIVEN** a mocked character occupying an otherwise-candidate interior cell, **WHEN** analyzed, **THEN** that cell's candidate status, its region's membership, and the region's Room/Sealed verdict are all identical to the unoccupied case — character positions never affect the analysis (AC38, Rule 1's block-occupancy-only clause; companion to AC33's never-calls-villager-APIs check). [TR-023]
- [ ] Region detection is fully recomputed for the affected region per event, with no caching and no incremental delta in MVP — analysis scope is bounded by connectivity itself, deliberately unbounded by any knob. [TR-020]
- [ ] Region size is counted so `min_room_cells` can be applied by the verdict step (story 004) — a region carries its interior cell set, not just a boolean.

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

- Two different adjacency notions coexist and must not be conflated: **membership** is orthogonal (6-neighbour in 3D / 4-neighbour in-plane), **traversal** is the villager movement graph (story 004). Getting this backwards is exactly what makes AC37's corner-touching case wrong.
- Region formation is a plain BFS/DFS over candidate cells (story 002's predicate) seeded from the affected cells of the triggering pass. `Dictionary[Vector3i, bool]` visited-set, `Array[Vector3i]` frontier — the ADR's reference shape.
- **Affected-region scoping**: the seed set is the pass's changed cells plus their candidate neighbourhood; expand by connectivity from there. Never seed from the whole world (that is the load pass's job, story 005).
- AC38 is a property, not a branch: because the analysis only ever reads `VoxelWorldGrid` block data, a mocked character cannot influence it. Assert the property; do not add character-filtering code.
- `min_room_cells` is *applied* in story 004 (it is a Rule 2 room-validity condition, not a membership condition). This story only guarantees the count is available.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: the candidate-cell predicate.
- Story 004: `min_room_cells` thresholding, the outside trace, Room/Sealed verdicts, and the region-split evaluation (AC8).
- Story 005: the incremental snapshot and the pass trigger.

---

## QA Test Cases

- **AC7**: Given two roofed interiors joined by a candidate-cell gap, When analyzed, Then exactly one region is produced covering both.
- **AC11**: Given candidate cells running up to the world boundary, When analyzed, Then the boundary contributes neither wall nor opening and no out-of-bounds cell enters the region.
- **AC38**: Given a mocked character standing on an otherwise-candidate cell, When analyzed, Then candidate status, region membership, and the region's verdict are byte-identical to the unoccupied run.
- Edge cases: two regions touching only corner-to-corner remain TWO regions (membership is orthogonal — the traversal consequence is AC37 in story 004); a single candidate cell forms a region of size 1; a region spanning a chunk boundary is formed correctly.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `neues-spiel/tests/unit/build_validation/region_formation_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002 (candidate-cell predicate)
- Unlocks: 004

