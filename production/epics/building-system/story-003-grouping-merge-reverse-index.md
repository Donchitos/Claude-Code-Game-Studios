# Story 003: 26-neighborhood grouping/merge + cell→project reverse index

> **Epic**: Building System
> **Status: Complete (2026-07-24 — 843/843 suite green 0 orphans, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-107`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary
**ADR Decision Summary**: Mutually 26-adjacent blueprint cells belong to one project; a commit bridging existing projects merges them so every resulting cell belongs to exactly one project (batch-merge guarantee). Selection uses a cell→project reverse index (`project_at_cell(cell) -> int`, O(1)).

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (ADR-0016 knowledge risk LOW)
**Engine Notes**: `Dictionary[Vector3i, int]` typed reverse index (4.4+ typed Dictionaries). Vector3i integer arithmetic is exact — no epsilon comparisons.

**Control Manifest Rules (this layer — Core)**:
- Required: 26-neighborhood grouping/merge is deterministic; a commit bridging existing projects merges them; selection via cell→project reverse index (`project_at_cell`, O(1)) — the DDA→owning-project resolution ADR-0010 §4 calls into.
- Forbidden: never make grouping order-dependent (must resolve via a union-find pass over the whole batch before any single cell's membership is finalized).
- Guardrail: grouping/merge is bounded by the committed batch's neighborhood, not world size; reverse-index lookup is O(1) per cell.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC55: GIVEN two separate commits whose cells are 26-adjacent (F6), WHEN the second commits, THEN both sets of cells belong to exactly one Build Project (Rule 14c). [TR-107]
- [ ] AC56: GIVEN a single commit batch that touches two previously separate same-kind projects at once, WHEN resolved, THEN both merge into one project keyed by the lower (earlier-created) project id, deterministically regardless of cell iteration order (Rule 14c, Edge Case 13). [TR-107]
- [ ] A purely diagonal touch (Chebyshev distance == 1 including corner/edge adjacency) triggers a merge; one cell of empty space between two cells does not (F6). [TR-107]
- [ ] The reverse index maps every project cell back to its owning project in O(1). [TR-107]

---

## Implementation Notes

*Derived from ADR-0016 Decision §2/§6 + building-system Rule 14c, F6:*

- Adjacency predicate F6: `is_26_adjacent(a, b) = (chebyshev_distance(a, b) == 1)`, `chebyshev_distance = max(|a.x−b.x|, |a.y−b.y|, |a.z−b.z|)`. Full 3D Moore neighborhood (edge- and corner-touching included), not face-only (6) or edge-only (18). The neighborhood size is the `project_merge_neighborhood` tuning knob (default 26; enum-safe range {6,18,26}, only 26 playtest-validated).
- Grouping is resolved by a **union-find pass over the whole batch** before any single cell's membership is finalized — the outcome must never depend on iteration order within the batch.
- Same-kind only: a new cell attaches to an existing project of the SAME kind (build vs dig — Story 013 enforces the dig partition). When a commit's cells touch two or more previously separate same-kind projects, all merge into one.
- On merge, the lowest-numbered (earliest-created) project id survives and absorbs the others' cells and worker-attribution records.
- Maintain the reverse index (`project_at_cell(cell) -> int`, or -1) as cells are assigned/merged; keep it consistent through merges (re-key absorbed cells to the surviving id).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 007: change orders (attaching to an already-released/DONE project instead of merging into a Draft project).
- Story 008: the world-click → `project_at_cell` selection routing (this story builds the index; 008 consumes it).
- Story 013: the dig-kind partition rule that forbids build↔dig merges.

---

## QA Test Cases

**AC55 — adjacent commits merge to one project**
- Given: commit A creates project P1; commit B's cells are 26-adjacent to a P1 cell.
- When: B commits.
- Then: all A and B cells share exactly one project id.
- Edge cases: diagonal-only touch (e.g. (4,1,4)↔(5,1,5), distance 1) merges; a one-cell gap ((4,1,4)↔(6,1,4), distance 2) does not merge.

**AC56 — deterministic bridging merge**
- Given: two separate projects P1 (id lower) and P2; a single commit batch whose cells are 26-adjacent to both.
- When: the union-find pass resolves.
- Then: one project remains, keyed by P1's (lower) id, absorbing P2's cells and worker records; result is identical for any cell iteration order.
- Edge cases: shuffling batch cell order yields the same surviving id and membership; three-way bridge merges all into the lowest id.

**Reverse index**
- Given: a project with N cells.
- When: `project_at_cell` is queried for each cell.
- Then: each returns the owning project id in O(1); a non-project cell returns -1.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/building_system/grouping_merge_reverse_index_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (project entity + cell model).
- Unlocks: Story 007 (change orders), Story 008 (click-selection), Story 013 (dig partition), Story 018 (batch contract).
