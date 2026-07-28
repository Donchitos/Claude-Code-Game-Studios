# Story 004: Outside-connection trace & Room/Sealed verdict

> **Epic**: Build Validation & Navigability
> **Status: Complete (2026-07-26 — 1083/1083 suite green 0 orphans, parent-verified)
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/build-validation-navigability.md`
**Requirement**: `TR-build-validation-navigability-025`, `TR-build-validation-navigability-008`, `TR-build-validation-navigability-009`, `TR-build-validation-navigability-026`, `TR-build-validation-navigability-027`, `TR-build-validation-navigability-056`, `TR-build-validation-navigability-057`, `TR-build-validation-navigability-058`, `TR-build-validation-navigability-037`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (AI Pathfinding, Navigation & Room Analysis)
**ADR Decision Summary**: Build Validation's reachability trace is a full-connectivity walk from a region's interior to any open-sky standable cell — a plain BFS over cells that pass `is_standable`/`is_step_legal`, calling those two shared functions directly. It is not `NavigationServer3D`, not a navmesh, and not a read of Villager AI's `AStar3D` graph. Reference shape: the ADR's `_trace_reachability` Key Interface.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: `AStarGrid3D` does **not** exist in Godot 4.7 and is irrelevant here regardless — this is a BFS, not a shortest-path query. `NavigationServer3D`/`NavigationAgent3D`/`NavigationRegion3D` are grep-forbidden in this module.

**Control Manifest Rules (this layer)**:
- Required (Feature): `is_step_legal(from, to)` = |dy| ≤ 1, diagonal legal **only if both flanking orthogonals are passable**; every consumer calls the shared function.
- Required: Build Validation runs its own independent BFS; never touches Villager AI's `AStar3D` instance.
- Forbidden: a plain 4/8-neighbor flood-fill as the traversal graph; re-implementing or approximating the step rules; blocking, reverting, or auto-fixing a placement.
- Guardrail: O(region size) per pass; ~12k-connected-cell one-frame boundary is a documented accepted risk, not a bug to fix here.

---

## Acceptance Criteria

*From GDD `design/gdd/build-validation-navigability.md`, scoped to this story:*

- [ ] A candidate region is a **valid room** iff it has at least `min_room_cells` interior cells AND at least one villager-walkable connection to the outside world. [TR-025]
- [ ] **The reach graph is the villager movement graph, consumed verbatim** (standability with `villager_clearance` = 3, orthogonal steps with `max_step_height` = 1, and diagonal steps ONLY when both flanking orthogonal cells are passable — no corner-cutting). It is NOT a plain 4- or 8-neighbor flood-fill: it is exactly the graph a villager may walk. [TR-008]
- [ ] **The outside world** is any standable cell that is NOT roofed (no solid cell within `max_room_height` straight above — open sky). The connection test walks the movement graph outward from the region's interior cells until it reaches an open-sky standable cell, or exhausts all reachable cells (→ Sealed). Reaching another enclosed space's interior is NOT "outside". [TR-009]
- [ ] The trace **may pass through any standable cell, including another region's interior** — a region whose only path to open sky runs through its corner-neighbor's interior and door IS outside-connected (Edge Case 14). [TR-026]
- [ ] A candidate region with NO walkable connection to the outside is a **sealed space** — never a room. [TR-027]
- [ ] **AC1**: **GIVEN** a 3×3 interior with full roof, floor, walls, and one 1-wide × 3-high walkable gap (step 0), **WHEN** analyzed, **THEN** it is a valid room. [TR-025]
- [ ] **AC2**: **GIVEN** the same structure fully sealed, **WHEN** the completion signal fires, **THEN** the region becomes Sealed and is not a room (Edge Case 2). [TR-027]
- [ ] **AC4**: **GIVEN** a candidate region of exactly `min_room_cells` with a walkable connection, **WHEN** analyzed, **THEN** it is a valid room; **GIVEN** one cell fewer, **THEN** it is not (Edge Case 9). [TR-025]
- [ ] **AC5**: **GIVEN** a room whose only opening leads onto a 2-cell drop, **WHEN** analyzed, **THEN** the region is Sealed (step-height violation); **GIVEN** an opening with less than 3 cells of vertical clearance, **THEN** likewise Sealed (clearance violation); **GIVEN** an opening whose outward path leads only into roofed pockets that never reach an open-sky standable cell, **THEN** likewise Sealed (Edge Case 4). [TR-009]
- [ ] **AC8**: **GIVEN** a valid room split in two by removing a connecting roof/floor segment, **WHEN** analyzed, **THEN** two independent regions result, each independently evaluated against Rule 2 (Edge Case 7). [TR-058]
- [ ] **AC9**: **GIVEN** terrain forming the floor and one wall, **WHEN** analyzed, **THEN** the enclosure can be a valid room (Edge Case 5). [TR-056]
- [ ] **AC10**: **GIVEN** a roof on pillars with no walls (floored, reachable, ≥ min cells), **WHEN** analyzed, **THEN** it IS a valid room (Edge Case 6 — accepted MVP behavior). [TR-057]
- [ ] **AC29**: **GIVEN** a region whose only outside connection requires a diagonal step with both flanking orthogonal cells passable, **WHEN** analyzed, **THEN** it is a valid room. [TR-008]
- [ ] **AC30**: **GIVEN** the same geometry with either flanking cell blocked, **WHEN** analyzed, **THEN** the region is Sealed (no corner-cutting, consumed verbatim from Villager AI Rule 9). [TR-008]
- [ ] **AC37**: **GIVEN** two candidate regions touching only corner-to-corner where region A's sole path to open sky is a legal flanked diagonal into region B and out B's door, **WHEN** analyzed, **THEN** A and B are TWO regions and BOTH are valid rooms; **GIVEN** either flanking cell of that diagonal blocked, **THEN** A is Sealed while B remains a room (Edge Case 14). [TR-026]
- [ ] **AC25**: **GIVEN** any invalid/sealed configuration, **WHEN** the player completes the placement, **THEN** the Building System's completion signal and world state are unmodified — no block/revert call is ever observed (Rule 9 never-blocks, verified via mock call-count). [TR-037]

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

- The trace is the ADR's `_trace_reachability` shape: visited `Dictionary[Vector3i, bool]`, frontier `Array[Vector3i]`, early-return `true` on the first open-sky standable cell, `false` on frontier exhaustion.
- `_standable_neighbors(current)` must call **both** shared predicates: candidate neighbours are the 8 in-plane offsets at Δy ∈ {-1, 0, +1}, filtered by `is_standable(neighbor)` and `is_step_legal(current, neighbor)`. The landed `is_step_legal` already implements the flanked-diagonal rule and assumes both endpoints are standable — honour that contract.
- "Open sky" reuses story 002's roof scan with the result inverted: standable AND no solid within `max_room_height` straight above. Do not write a second scan.
- The trace deliberately walks through other regions' interiors — that is AC37's intent, not a leak. Region membership (orthogonal, story 003) and traversal (movement graph, here) are separate by design.
- AC8's split is a *consequence* of re-running formation + verdict on the affected region after a removal; no dedicated split algorithm.
- **AC10 is intended behavior, not a defect.** The roof-on-pillars carport is an accepted MVP design gap (GDD VS Open Question 1). Do not add a wall-coverage requirement.
- AC25 is a negative assertion over a mocked Building System: assert the block/revert call-count is 0. This module has no write path at all — the test guards that it stays that way.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: region membership/formation.
- Story 005: the pass trigger, snapshot, and the never-calls-villager-APIs guard (AC33).
- Story 006: shelter classification of furniture inside the verdicted region.
- Story 008: the sealed-space warning emission (this story produces the Sealed *state*, not the signal).

---

## QA Test Cases

- **AC1 / AC2**: 3×3 interior with a 1×3 gap → Room; the same structure sealed → Sealed.
- **AC4**: region of exactly `min_room_cells` with a connection → Room; one cell fewer → not.
- **AC5**: three separate Sealed cases — 2-cell drop, sub-3 clearance opening, and an opening into roofed-pocket-only space.
- **AC8**: remove a connecting segment from a valid room → two regions, each independently evaluated.
- **AC9 / AC10**: terrain-as-structure enclosure → Room; roof-on-pillars → Room.
- **AC29 / AC30**: flanked diagonal legal → Room; either flanker blocked → Sealed.
- **AC37**: corner-touching A/B, A's only sky path through B → both Rooms; flanker blocked → A Sealed, B Room.
- **AC25**: mocked Building System — assert block/revert call-count = 0 across every invalid configuration above.
- Edge cases: a region whose interior is entirely open-sky-adjacent (trivially connected); a chain of enclosed spaces that never reaches sky (Sealed); a region of size ≥ `min_room_cells` with zero legal steps out.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `neues-spiel/tests/unit/build_validation/room_verdict_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 003 (region formation), 002 (candidate predicate + roof scan)
- Unlocks: 005, 006, 010

