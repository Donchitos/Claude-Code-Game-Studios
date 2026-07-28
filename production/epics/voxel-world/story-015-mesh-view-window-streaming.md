# Story 015: Mesh view-window streaming with per-frame build + unload budgets

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-24 — 682/682 suite green, parent-verified — unlocks milestone criterion #12 measurement)
> **Layer**: Presentation (mesher tier)
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-025`, `TR-voxel-world-026`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014 — primary; ADR-0015 (time-based budget discipline) secondary
**ADR Decision Summary**: View-window streaming with per-frame budgets for BOTH chunk mesh builds AND unloads (`queue_free` bursts caused the prototype's only hitch); `visibility_range_end` on chunk instances. Draw calls are decoupled from world size via the streamed view window.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: The initial view-window mesh build (~2.6 s at 2000×2000×32) runs behind Scene/World Management's transition overlay. Staggered unload discipline is required — the slice's single 133 ms hitch came from an unload burst.

**Control Manifest Rules (this layer)**:
- Required: view-window streaming with per-frame budgets for chunk mesh builds AND unloads; `visibility_range_end` on chunk instances; staggered unload.
- Forbidden: `queue_free` bursts (unload all at once); baking state colors into committed-block materials.
- Guardrail: draw calls ≤ 2000; 60 FPS on the production window with culling re-enabled.

---

## Acceptance Criteria

- [ ] The mesher streams chunk mesh builds/unloads within the camera view window; draw calls stay decoupled from world size (bounded by the view window, not the full extent). [TR-voxel-world-025]
- [ ] Per-frame budgets bound BOTH mesh builds and unloads; unloads are staggered, not burst. [TR-voxel-world-025]
- [ ] The initial view-window build runs behind the transition overlay (not on a visible frozen frame). [TR-voxel-world-026]

---

## Implementation Notes

*Derived from ADR-0014 / ADR-0015:*

- Drive meshed-chunk membership from the camera view window (view radius). Build `ArrayMesh` chunks (Story 007) for entering chunks and unload leaving ones, each bounded by a per-frame budget (align with ADR-0015's time-based discipline; a time budget is preferred over a fixed count). Stagger `queue_free` so unloads do not burst.
- Set `visibility_range_end` on chunk instances for distance culling. Keep draw calls within the ≤ 2000 budget via the view window.
- The mesh view window (visual) is distinct from the data resident set (Story 010) — they share a camera focus point but govern different resources (ArrayMeshes vs packed-array data). Consume an injected camera focus point.

---

## Out of Scope

- Story 007: the chunk mesh geometry itself (CW winding, culling).
- Story 010–014: the data residency tier (this story streams meshes, not data pages).

---

## QA Test Cases

- **AC-1 (view-window bound draw calls)**: [TR-voxel-world-025]
  - Setup: a world larger than the view window; move the injected camera focus across it
  - Verify: meshed-chunk count and draw calls track the view window, not world size; draw calls stay ≤ 2000
  - Pass condition: distant chunks are unloaded; entering chunks are built; 60 FPS holds with culling enabled
- **AC-2 (staggered unload, no hitch)**: [TR-voxel-world-025]
  - Setup: a fast camera sweep causing many chunks to leave the window at once
  - Verify: frame-time trace during the sweep
  - Pass condition: unloads are staggered within the per-frame budget; no unload-burst hitch (no 100 ms+ spike)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/voxel_world/mesh_view_window_streaming_test.gd` OR documented playtest — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 007 (chunk mesher), Story 010 (residency for data behind the view window), Story 012 (time-budget discipline); consumes an injected camera focus point (Camera & Input epic)
- Unlocks: Story 016 (streaming/budget tuning); integrated playable build performance gate
