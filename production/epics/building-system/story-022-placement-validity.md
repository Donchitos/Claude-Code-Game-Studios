# Story 022: Placement validity checks

> **Epic**: Building System
> **Status: Complete (2026-07-24 — 651/651 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-049`, `TR-building-system-084`, `TR-building-system-085`, `TR-building-system-060`, `TR-building-system-050`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary; ADR-0014 (large-world storage / combined-view) — secondary
**ADR Decision Summary**: Placement validity is owned by Building System (geometric availability only); the combined "planned occupancy" view is Voxel World blocks + this system's blueprint cells. Livability is never a placement blocker (Build Validation's domain).

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `max_cells_per_command` default 512 bounds preview size, undo payload, and job-queue injection in one number. No post-cutoff APIs.

**Control Manifest Rules (this layer — Core):**
- Required: validity is geometric availability only (in bounds; empty or replace-in-place; material/furniture selected + available; cell count ≤ `max_cells_per_command`; furniture support holds); planned occupancy queries the combined view (Voxel World blocks + blueprint cells).
- Forbidden: never block a placement for livability/navigability reasons (Build Validation owns that); never treat raw Voxel World state as "what the player has built or plans to build."
- Guardrail: validity is O(cells-in-command); the cell cap bounds every per-command quantity at once.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC10: GIVEN a commit targets a cell already holding a constructed block or terrain (not replace-in-place), WHEN `build_place` fires, THEN it is rejected with visible feedback and no blueprint is created. [TR-049]
- [ ] AC11: GIVEN a commit targets a cell holding a blueprint cell, WHEN `build_place` fires, THEN it is rejected (Edge Case 3). [TR-085]
- [ ] AC14: GIVEN a terrain cell, WHEN replace-in-place targets it, THEN the commit is rejected (Edge Case 2). [TR-084]
- [ ] AC39: GIVEN a drag whose cell count would exceed `max_cells_per_command`, WHEN committed, THEN it is rejected with visible feedback and zero blueprint cells are created. [TR-049]
- [ ] AC42: GIVEN an armed placement tool with no material/furniture selected, WHEN `build_place` fires on an otherwise valid pick, THEN the commit is rejected with visible feedback. [TR-049]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Core Rules 9/10 + Edge Cases 2/3, TR-049/084/085/060/050:*

- A commit is valid iff, for every target cell: inside world bounds; empty (or the picked cell in a replace-in-place); a material/furniture entry is selected and available (MVP: tier-0 set plus `bed`); total cell count ≤ `max_cells_per_command` (512); furniture support holds (Story 028).
- Blueprint cells count as occupied for validity (Edge 3) — query the combined "planned occupancy" view (Voxel World blocks ∪ blueprint cells), never raw Voxel World state alone (TR-060).
- Replace-in-place targeting terrain is invalid (Edge 2 — replacing is removal + placement, and terrain isn't removable via the plain path); attaching to a terrain face is valid.
- Invalid commits are rejected with visible feedback (near the cursor, non-punishing) — never silently.
- Validity here is geometric availability ONLY — never block for livability/navigability (Build Validation's domain, TR-051).
- Furniture-support clarification (TR-050): a blueprint floor cell counts as support for a furniture blueprint, but that furniture cell's construction may only start once its support is Built (feeds Story 029/030).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 023: rendering the valid/invalid ghost tint (this story computes the validity bool it consumes).
- Story 028: the furniture footprint/support geometry (this story calls the support predicate).
- Build Validation & Navigability livability checks — separate MVP system, M02.

---

## QA Test Cases

**AC10 / AC11 / AC14 — occupancy + terrain rejections**
- Given: commits targeting (a) an occupied constructed/terrain cell (non-replace), (b) a cell holding a blueprint cell, (c) terrain via replace-in-place.
- When: `build_place` fires.
- Then: each is rejected with visible feedback; zero blueprint cells created.
- Edge cases: replace-in-place of a player-built block IS valid; attach to a terrain face IS valid.

**AC39 — cell cap**
- Given: a drag whose cell count exceeds `max_cells_per_command`.
- When: committed.
- Then: rejected with feedback; zero cells created.

**AC42 — no material selected**
- Given: an armed placement tool, valid pick, no material/furniture selected.
- When: `build_place` fires.
- Then: rejected with feedback.

**Combined-view occupancy**
- Given: a blueprint cell at X (invisible to Voxel World data).
- When: a new commit targets X.
- Then: rejected (blueprint counts as occupied in the combined view).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/placement_validity_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 021 (commit pipeline). Coordinates with Story 028 (furniture support), Resource & Item Database (palette availability).
- Unlocks: Story 023 (tint), all tool stories (validity gate).
