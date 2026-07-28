# Story 004: Neighbor lookup + DDA cell-picking on the data layer

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-23 — 232/232 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-031`, `TR-voxel-world-017`, `TR-voxel-world-049`, `TR-voxel-world-047`, `TR-voxel-world-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 (Physics Backend & Picking Strategy) — primary; ADR-0014 secondary
**ADR Decision Summary**: Block picking is a manual DDA grid-walk against Voxel World's cell data, driven by Camera & Input's `get_world_ray()`. Zero physics colliders on blocks; zero `PhysicsServer3D`/`RayCast3D` in any picking path.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: Per-cell colliders for tens of thousands of terrain cells are a known Jolt/scene-tree scalability trap — DDA on the data layer avoids them entirely. `raycast_cells` must be grep-clean of physics APIs.

**Control Manifest Rules (this layer)**:
- Required: block picking = manual DDA grid-walk against chunked accessor data.
- Forbidden: zero `PhysicsServer3D`/`RayCast3D`/`intersect_ray` in any Voxel World picking path (grep-verifiable).
- Guardrail: raycast is read-only and cheap regardless of call frequency (per-frame hover picking).

---

## Acceptance Criteria

- [ ] `get_neighbors(cell)` returns the cell's grid neighbors via exact `Vector3i` offsets (part of the read API). [TR-voxel-world-031]
- [ ] `raycast_cells` correctly returns the first occupied cell along a ray (or none), independent of the eventual rendering mechanism (AC12). [TR-voxel-world-049, -017]
- [ ] Repeated raycasts (e.g., every hover frame) never mutate grid state (AC13). [TR-voxel-world-047]
- [ ] No physics colliders or physics-ray APIs are used for picking (AC12 mechanism). [TR-voxel-world-018]

---

## Implementation Notes

*Derived from ADR-0004 / ADR-0014:*

- Implement `raycast_cells(origin, direction, max_distance)` as a DDA (Amanatides–Woo style) grid walk stepping cell-to-cell, returning the first occupied cell and its hit face (or none). Consumers pass the ray from Camera & Input's `get_world_ray()` (Building System forwards it — Voxel World never calls Camera & Input).
- The `extra_solid` ghost-anchoring predicate (uncommitted ghost/draft cells picking as solid; dig-orders/water not picking) is added later by the Building System slice — this story implements the base DDA against committed cells only. Keep the signature extensible for an optional predicate overlay (ADR-0014 §4).
- `get_neighbors` uses fixed integer offsets; bounds-check via Story 001's out-of-grid rule.

---

## Out of Scope

- The `extra_solid` overlay predicate for ghost/draft picking (Building System slice, ADR-0014 §4).
- Camera-side ray production — see camera-input epic Story 006.

---

## QA Test Cases

- **AC-1 (raycast first-hit)**: [TR-voxel-world-049]
  - Given: a grid with a single occupied cell at (5,0,0)
  - When: `raycast_cells` from (−1,0.5,0.5) toward +x
  - Then: returns (5,0,0) as first hit; a ray missing all cells returns none
  - Edge cases: ray origin inside an occupied cell; ray grazing a cell edge (floor semantics); ray exiting world bounds returns none
- **AC-2 (read purity under load)**: [TR-voxel-world-047]
  - Given: a populated grid snapshot
  - When: 10,000 raycasts
  - Then: grid snapshot unchanged
- **AC-3 (no physics APIs)**: [TR-voxel-world-018]
  - Given: the Voxel World source
  - When: grep `intersect_ray|PhysicsServer3D|RayCast3D` over `src/voxel_world/`
  - Then: zero matches

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/voxel_world/dda_raycast_test.gd` OR documented playtest — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (storage + accessors)
- Unlocks: Building System placement pick (later epic); mesh picking consumers
