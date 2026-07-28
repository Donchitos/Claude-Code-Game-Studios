# Evidence: Story vox-007 — Chunked Mesher CW Winding + Backface Culling

**Story**: `production/epics/voxel-world/story-007-chunked-mesher-cw-winding-culling.md`
**Date**: 2026-07-24
**Engine**: Godot 4.7.stable.official.5b4e0cb0f (local install, `C:/Users/Leo/Downloads/Godot_v4.7-stable_win64.exe/`)
**Evidence type**: Visual/Feel — screenshot pass (sprint-4 QA plan: BLOCKING for
sprint/milestone exit, per `qa-plan-sprint-4-2026-07-24.md` Classification Note #1)

---

## Winding/culling convention — external source consulted (closes the flagged QA gap)

The sprint-4 QA plan flagged that `docs/engine-reference/godot/` does **not** document
Godot's front-face winding convention, and that the GDD/story both cite it as "an engine
fact" without a sourced verification — restating that claim would repeat the exact
"self-stored assumption" failure this story exists to fix.

**Source consulted: the engine itself, executed directly, not written documentation.**
Per the story's own audit rule ("face-winding audits must validate against the ENGINE's
actual documented behavior, never a self-stored assumption") and the task's explicit
instruction, the convention was derived from **first principles inside Godot 4.7.stable**
rather than from any doc page (official or internal):

1. Constructed a native `BoxMesh` (a Godot-authored primitive mesh, not hand-written
   geometry) and read its `surface_get_arrays(0)` — vertex positions, per-vertex normals,
   and the triangle index array, exactly as Godot's own mesh-generation code produced them.
2. For every one of the box's 12 triangles, computed the winding-derived normal
   `(v1-v0).cross(v2-v0)` from the triangle's own stored index order, and compared it to
   that triangle's own stored vertex normal.
3. Result (see the raw run below): **all 12 triangles produce a winding-derived normal
   that points OPPOSITE their own stored vertex normal.**
4. Because `BoxMesh` is a native Godot primitive that renders correctly (solid, no holes)
   under Godot's default backface-culling material settings, this proves — empirically,
   against this exact engine build — that Godot's FRONT-FACING winding (the winding that
   survives backface culling) is the one where `(corner1-corner0).cross(corner2-corner0)`
   points OPPOSITE a face's true outward normal. This is the CLOCKWISE-from-outside
   convention, matching the GDD/ADR's claim — but now verified against the engine's actual
   behavior rather than assumed from the GDD's own prose, closing the QA plan's flagged gap.

This derivation is **pinned as a permanent automated regression test**, not a one-time
manual check: `neues-spiel/tests/unit/voxel_world/mesher_winding_derivation_test.gd`
(`test_boxmesh_front_face_winding_is_clockwise_from_outward_normal`) reproduces the exact
same `BoxMesh` check on every test run, so a future engine upgrade that silently changed
this convention would fail immediately rather than reintroduce "missing faces" silently.
A second test in the same file
(`test_face_corners_table_matches_derived_cw_front_convention_for_every_face`) asserts
`VoxelWorldMesher.FACE_CORNERS` — the actual winding table the mesher ships — conforms to
this same derived rule for all 6 face directions.

Raw derivation output (captured during implementation, one representative triangle per box
face; full 12/12 in the pinned test):

```
tri=0  i=(0,2,4)   stored_n=(0,0,1)   winding_n=(0,0,-1)  dot=-1.0
tri=2  i=(1,3,5)   stored_n=(0,0,-1)  winding_n=(0,0,1)   dot=-1.0
tri=4  i=(8,10,12) stored_n=(1,0,0)   winding_n=(-1,0,0)  dot=-1.0
tri=6  i=(9,11,13) stored_n=(-1,0,0) winding_n=(1,0,0)    dot=-1.0
tri=8  i=(16,18,20) stored_n=(0,1,0) winding_n=(0,-1,0)   dot=-1.0
tri=10 i=(17,19,21) stored_n=(0,-1,0) winding_n=(0,1,0)   dot=-1.0
ccw_front_votes=0  cw_front_votes=12
CONCLUSION: Godot's FRONT-FACING winding (as stored by its own primitives) is
CW-from-outside.
```

**Recommendation carried forward** (per the QA plan): technical-director should add this
derived fact to `docs/engine-reference/godot/current-best-practices.md` so future
mesher-adjacent work cites a project doc instead of re-deriving it.

---

## AC-1 — CW winding + culling, no missing faces [TR-voxel-world-052]

**Implementation**: `neues-spiel/src/voxel_world/voxel_world_mesher.gd`
(`VoxelWorldMesher.FACE_CORNERS`, freshly derived per the rule above — never copied from
`prototypes/last-seal-vertical-slice/voxel_world.gd`, whose tables use the opposite,
CCW-front convention and rely on `CULL_DISABLED` to compensate).

**Material**: `neues-spiel/assets/shaders/terrain_chunk.gdshader` — ONE shared
`ShaderMaterial` instance (`VoxelWorldMesher._material`, constructed once), explicit
`render_mode cull_back` (never left at an implicit default). `CULL_DISABLED` does not
appear anywhere in `src/voxel_world/` or the shader — grep-guarded by
`tests/unit/voxel_world/mesher_material_contract_test.gd` (automated, part of the
headless suite, re-checked every run rather than only at story completion).

**Screenshot verification** — a real 128×128-cell seeded terrain extent (64 chunks),
meshed via the production `VoxelWorldMesher`, captured from two vantages via
`neues-spiel/tools/mesher_evidence.gd` / `.tscn`:

- `vox-007-terrain-20260724-1.png` — **top-down**. The full 128×128 extent renders as one
  continuous, solid land-mass against a solid sky-blue background — no holes, no gaps, no
  chunk-boundary seams across any of the 64 meshed chunks (confirming the mesher's
  cross-chunk neighbor lookups via `VoxelWorldGrid.get_cell` are correct, not just
  single-chunk-isolated). The thin dark lines visible are terrain-height-step side faces
  read nearly edge-on from directly above — expected shading, not a defect.
- `vox-007-terrain-20260724-2.png` — **low oblique** (the historically riskiest angle —
  the vertical slice's "missing faces" defect showed most clearly against cliff/side faces
  from a grazing angle). Side/cliff faces at every height transition render solidly and
  visibly, with no see-through gaps to the sky-blue background anywhere in the terrain
  silhouette. If winding were still CCW-front (the slice's bug) under this story's
  explicitly-enabled `cull_back` material, these near-camera side faces would be
  **backface-culled and invisible** — the fact that they render solidly, from this exact
  historically-failing angle, is the direct visual confirmation that CW winding + culling
  are both correctly in effect together (not just "no holes by coincidence").

**Pass condition met**: zero missing faces from either captured angle; back-faces are
genuinely culled (confirmed by the side faces rendering correctly under `cull_back`, not
by disabling culling); winding confirmed against the engine's actual behavior per the
derivation above, not a project assumption.

---

## AC-2 — Whole-chunk rebuild on cell_changed / cells_changed_batch [TR-voxel-world-025]

Covered by automated unit tests (not manual screenshot — the underlying signal-driven
rebuild is fully headless-testable), `neues-spiel/tests/unit/voxel_world/chunked_mesher_face_culling_test.gd`:

- `test_cell_changed_rebuilds_already_tracked_chunk` — place then remove a block inside an
  already-tracked (meshed) chunk; the chunk's `ArrayMesh` updates automatically (new face
  appears on placement, disappears on removal) with no manual rebuild call.
- `test_cells_changed_batch_rebuilds_already_tracked_chunk_exactly_once` — a bulk write
  touching two cells in one tracked chunk rebuilds it correctly via the batched signal.
- `test_cell_changed_in_untracked_chunk_does_not_build_it` — a change in a chunk never
  passed to `build_chunk()` is left alone (Story 015's view-window streaming scope, not
  this story's).
- `test_change_at_chunk_border_also_rebuilds_tracked_neighbor_chunk` — a solid cell placed
  at a chunk's edge correctly updates BOTH that chunk's and its already-tracked neighbor
  chunk's meshes (the shared boundary face is culled on both sides) — a correctness case
  beyond the story's literal AC wording but necessary for "no missing-face regressions" to
  hold across chunk boundaries, not just within a single chunk.

**Pass condition met**: chunk mesh updates reflect the new air/solid boundary exactly as
required, verified by direct vertex/index-count assertions on the rebuilt `ArrayMesh`.

---

## Additional automated coverage (face-culling correctness, "fully-solid reference chunk")

`chunked_mesher_face_culling_test.gd` also proves, against concrete geometric worked
examples (not just the two literal ACs above):

- An isolated solid cell emits all 6 faces (24 verts / 36 indices).
- A fully-buried cell (solid on all 6 sides) emits zero of its own faces.
- Two adjacent solid cells cull their shared internal face on BOTH sides (10 faces / 40
  verts, not 12/48).
- A fully-solid 3×3×3 block emits exactly its surface area (54 faces = 6×3²), proving the
  single interior cell contributes zero faces.
- A solid cell at the world edge (x=0) still emits its boundary-facing face — an
  out-of-bounds neighbor counts as air, not "no face."
- An empty chunk produces a tracked `MeshInstance3D` with `mesh == null` (not a crash, not
  a zero-vertex `ArrayMesh`).

---

## Sign-off

**Lead**: (awaiting qa-lead review — evidence prepared for that review, not yet
countersigned)
**Verdict pending**: screenshots and automated tests above are ready for qa-lead
inspection per sprint-4 DoD.
