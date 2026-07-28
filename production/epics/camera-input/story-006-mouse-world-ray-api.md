# Story 006: Mouse world-ray API + ground-plane intersection (always computable)

> **Epic**: Camera & Input
> **Status: Complete (2026-07-24 — 401/401 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/camera-input.md`
**Requirement**: `TR-camera-input-028`, `TR-camera-input-029`, `TR-camera-input-038`, `TR-camera-input-050`, `TR-camera-input-036`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 (Physics Backend & Picking Strategy) — primary; ADR-0014 (ghost-anchoring `extra_solid` predicate contract) secondary
**ADR Decision Summary**: `get_world_ray()` drives both the DDA block pick and the villager `Area3D` `intersect_ray` — Camera & Input owns the ray, not the pick semantics. The ray is always computable, even Suspended. The ghost-anchored picking predicate (`extra_solid`: ghost/draft cells pick as solid; dig-orders/water do not) lives on ADR-0014's DDA path, NOT on the ray producer.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `origin = camera.project_ray_origin(mouse_screen_pos)`, `direction = camera.project_ray_normal(mouse_screen_pos)` — re-confirm the 4.7 signatures against `docs/engine-reference/godot/` (unchanged since 4.3, but verify). Both must be computed from the SAME screen point in the SAME frame (don't cache one and recompute the other — Suspended freezes could desync them).

**Control Manifest Rules (this layer)**:
- Required: `get_world_ray()` always computable (incl. Suspended); origin+direction from the same screen point same frame.
- Forbidden: no direct Voxel World call (Building System forwards the ray); no "is the ray available?" branch for callers.
- Guardrail: the ray is the single producer consumed by DDA block pick (ADR-0014) and villager `Area3D` pick (ADR-0004).

---

## Acceptance Criteria

- [ ] `get_world_ray()` returns a valid ray (origin + direction) from the camera projection + mouse screen position, always computable — including Suspended (AC12). [TR-camera-input-028, -029]
- [ ] Origin and direction are computed from the same screen point in the same frame (AC14). [TR-camera-input-038]
- [ ] Round-trip: intersecting the ray with the ground plane and re-projecting to screen space yields the original mouse position within 1 pixel (AC21). [TR-camera-input-050]
- [ ] Camera & Input never calls Voxel World — it only provides the ray (AC — no direct connection). [TR-camera-input-036]

---

## Implementation Notes

*Derived from ADR-0004 / ADR-0014:*

- Implement `get_world_ray() -> {origin, direction}` and `get_ground_plane_intersection()`. Compute both origin and direction from a single sampled mouse screen point within the same call/frame; never cache one and recompute the other.
- Verify `project_ray_origin`/`project_ray_normal` signatures against the 4.7 engine reference before use.
- The `extra_solid` ghost-anchoring predicate is NOT implemented here — it is an overlay on Voxel World's `raycast_cells` DDA path (ADR-0014 §4, voxel-world Story 004 keeps the signature extensible). This story's contract is only: produce a correct, always-available ray; Building System forwards it to the DDA pick and applies the predicate downstream.

---

## Out of Scope

- The `extra_solid` predicate itself (Voxel World / Building System, ADR-0014 §4).
- Villager `Area3D` hit-test (Villager Info UI / ADR-0004 pick, later epic) — consumes this ray but is not built here.

---

## QA Test Cases

- **AC-1 (always computable, incl. Suspended)**: [TR-camera-input-029]
  - Given: the camera Active, then Suspended (frozen transform)
  - When: `get_world_ray()` is queried in both states
  - Then: both return a valid ray with no error and no availability branch; the Suspended ray uses the frozen transform
- **AC-2 (same screen point, same frame)**: [TR-camera-input-038]
  - Given: a mouse screen position P
  - When: origin and direction are computed
  - Then: both derive from P in the same frame (no cached/desynced pair)
- **AC-3 (round-trip projection)**: [TR-camera-input-050]
  - Given: mouse at P
  - When: ray ∩ ground plane, then re-project to screen
  - Then: result within 1 pixel of P
  - Edge cases: ray parallel to ground plane (no intersection) handled without crash
- **AC-4 (no Voxel World call)**: [TR-camera-input-036]
  - Given: the Camera & Input source
  - When: grep for Voxel World references
  - Then: none — Camera & Input only exposes the ray

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/camera_input/mouse_world_ray_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (camera projection / derivation)
- Unlocks: Building System DDA pick (voxel-world Story 004 consumer); villager pick (later); Story 007 (ray computable while Suspended)
