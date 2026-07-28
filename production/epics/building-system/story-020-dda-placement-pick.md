# Story 020: DDA placement pick + surface-aware targeting + picked-block highlight

> **Epic**: Building System
> **Status: Complete (2026-07-24 — 491/491 suite green, parent-verified; highlight screenshot advisory deferred to first rendered integration)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-002` (pick half), `TR-building-system-043`, `TR-building-system-092`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 (Physics Backend & Picking Strategy) — primary; ADR-0014 (Chunked Voxel Rendering & Large-World Storage) — secondary
**ADR Decision Summary**: Block picking is a manual DDA grid-walk against Voxel World's cell data driven by Camera & Input's `get_world_ray()` — no collider of any kind involved. Building System's placement pick calls ONLY the DDA step, structurally incapable of hitting villagers.

**Engine**: Godot 4.7-stable | **Risk**: HIGH (shared rendering/picking domain — verify DDA + zero-physics against `docs/engine-reference/godot/`)
**Engine Notes**: Zero `intersect_ray`/`PhysicsDirectSpaceState3D`/`RayCast3D` in the pick path (grep-verifiable). The ghost-anchored `extra_solid` predicate lives on the ADR-0014 §4 `raycast_cells` path (Voxel World's read API), not here.

**Control Manifest Rules (this layer — Core / Presentation pick surface):**
- Required: block picking = manual DDA grid-walk (`raycast_cells()`) against the chunked accessor, driven by `get_world_ray()`; surface-aware targeting attaches to the picked face or replaces the picked block in place; drag locks its working plane to the surface picked at drag start.
- Forbidden: zero physics API calls in the pick path (grep: `intersect_ray|PhysicsDirectSpaceState3D` in `src/building_system/` = zero); zero `PhysicsServer3D`/`RayCast3D` in any picking path.
- Guardrail: hover picking is O(1) read; runs per-frame only while a tool is armed.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC8: GIVEN a drag started on a block at height y > 0, WHEN dragging, THEN all preview/committed cells lie on that block's plane, never the ground plane (Core Rule 3). [TR-043]
- [ ] Placement attaches to the picked block's face, or replaces the picked block in place (surface-aware targeting). [TR-043]
- [ ] The block under the cursor is visibly highlighted while a tool is armed. [TR-092]
- [ ] The pick path issues zero physics queries (grep-verifiable). [TR-002]

---

## Implementation Notes

*Derived from ADR-0004 + ADR-0014 §4 + building-system Core Rule 3, TR-002/043/092:*

- Forward Camera & Input's current mouse world-ray to Voxel World's `raycast_cells()` (DDA) to pick a cell/surface. No collider, no physics query.
- Surface-aware targeting: attach to the picked block's face (adjacent empty cell), or replace the picked block in place. Drag operations lock their working height/plane to the surface picked at drag start — never a fixed ground plane.
- Picked-block highlight: highlight the cell under the cursor while a tool is armed (prototype-validated as essential). Highlight is overlay presentation, never baked into committed-block materials.
- The ghost-anchored pick predicate (draft cells pick as solid; dig-orders/water do not) is ADR-0014 §4's `extra_solid` overlay on `raycast_cells` — coordinate with Voxel World; do not add a second pick path here.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 021: click-vs-drag discrimination and the commit trigger.
- Story 023: ghost preview rendering (this story provides the picked cell/surface it anchors to).
- Story 008: the villager-vs-project selection arbitration (a different pick consumer).

---

## QA Test Cases

**AC8 — working plane locked to picked surface**
- Given: a drag started on a block at height y > 0.
- When: dragging.
- Then: all preview/committed cells lie on that block's plane, never the ground plane.
- Edge cases: dragging off the block's edge keeps the locked plane; a pick on terrain top attaches to its face.

**Surface-aware attach/replace**
- Given: a picked block.
- When: the pick resolves.
- Then: the target is the adjacent face cell (attach) or the picked cell (replace), per tool mode.

**Zero physics (grep)**
- Given: the built pick path.
- When: `rg --glob "*.gd" "intersect_ray|PhysicsDirectSpaceState3D|RayCast3D" src/building_system/`.
- Then: zero matches.

**Highlight**
- Given: a tool armed with a valid pick.
- When: the cursor hovers a block.
- Then: that block is visibly highlighted; highlight clears when no valid pick.

---

## Test Evidence

**Story Type**: Logic (pick geometry unit-testable; highlight verified via grep + manual/screenshot)
**Required evidence**: `tests/unit/building_system/dda_placement_pick_test.gd` — must exist and pass; grep check for zero-physics.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 019 (tool SM), Camera & Input (`get_world_ray()`), Voxel World (`raycast_cells()`) — Foundation.
- Unlocks: Story 021 (commit pipeline), Story 023 (ghost anchoring), Stories 024–028 (tools).
