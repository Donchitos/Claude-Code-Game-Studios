# ADR-0003: Voxel World Rendering Approach

## Status
Superseded by ADR-0014 (2026-07-11 — the large-world scope change, user/creative-director decision, moved the world bound from ~100×32×100 to 2000×2000×32; GridMap fails measurably at that scale. This ADR remains the correct record for the old bound; its spike PASS stands for that scope. Picking (§3) and ghost previews (§4) carry over into ADR-0014 unchanged.)

## Date
2026-07-11

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7-stable |
| **Domain** | Rendering |
| **Knowledge Risk** | HIGH — confirmed in the Phase 0 gap inventory of `architecture.md`; this is the project's keystone rendering decision |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md`, `modules/rendering.md`, `modules/physics.md` |
| **Post-Cutoff APIs Used** | GridMap's dedicated MeshLibrary editor (4.7, authoring-workflow only, no runtime API change) |
| **Verification Required** | See Engine Specialist Validation note in Consequences — GridMap's collision-generation granularity (per-cell vs. batched) was specifically verified, since it directly determines whether TR-voxel-world-018's collider-scalability trap applies |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0004 (3D Physics Backend & Picking/Raycast Strategy) — this ADR's picking-mechanism conclusion (manual DDA against the data layer, no block physics colliders) significantly narrows that ADR's scope to villager/UI collision only |
| **Blocks** | Voxel World and Building System `/dev-story` implementation |
| **Ordering Note** | Was provisional pending the pre-VS performance spike — spike PASSED 2026-07-11 (draw calls 1598/2000, 60 FPS held at ADR-ceiling scale; see prototypes/perf-spike-qq3/REPORT.md). Alternative C remains the named escape hatch if settlement density ever pushes past the ~20% draw-call margin |

## Context

### Problem Statement
Voxel World's own GDD leaves its rendering representation as an explicit open architecture decision (TR-voxel-world-025), carried forward from `game-concept.md`'s Open Questions and flagged as the systems-index's top High-Risk item: "GridMap vs. MultiMeshInstance3D vs. chunked/greedy mesher unresolved; the concept prototype validated the interaction (per-block placement/undo) using individual MeshInstance3D nodes, not GridMap's fixed-palette model. Township-scale performance unproven." This decision also directly determines the picking mechanism (TR-voxel-world-017/018) and how Building System's blueprint ghost previews render (TR-building-system-003/035/039/041) — it cannot be decided in isolation from those two consumers.

### Constraints
- World is bounded, not infinite: ~100×32×100 cells target (TR-voxel-world-016), sparse-stored, tens-of-MB target — this is a small hand-shaped valley, not an open-world voxel game
- `cell_size` is a fixed constant = 1.0, flush blocks, no gaps (TR-voxel-world-012)
- Each cell holds exactly one of: empty, or a single block record `{block-type id, material id}` — no layering, ever (TR-voxel-world-003)
- The concept prototype (2026-07-09, verdict PROCEED) validated per-block placement/undo, surface-aware DDA-raycast picking, and drag-locked-to-picked-surface using individual `MeshInstance3D` nodes — the *feel* is proven; the *rendering representation* used to prove it is explicitly not assumed to be the production choice
- Performance budget: ≤2000 draw calls (PC mid-range), 60 FPS / 16.6ms frame budget, 4GB memory ceiling (`technical-preferences.md`)
- Blueprint ghosts (Building System) need a visually distinct preview state (semi-transparent/tinted), re-rasterized live every frame during drag, with a degrade-to-outline fallback above `preview_degradation_threshold` cells

### Requirements
- Render up to ~320,000 possible cells (world bound) at 60 FPS within the draw-call budget
- Support O(1) cell read/write at the data layer (already Voxel World's own contract, TR-voxel-world-019) without forcing an expensive re-render of the whole world on every edit
- Support "first occupied cell along a ray" picking (TR-voxel-world-017) without the per-cell-collider scalability trap the GDD explicitly names (TR-voxel-world-018)
- Support a separate, always-small, semi-transparent ghost/preview rendering path that doesn't interfere with committed-block rendering

## Decision

**GridMap for committed-block rendering, with physics collision disabled — picking uses a manual DDA grid-walk against Voxel World's own data dictionary, not Godot physics at all — and a small pooled `MeshInstance3D` layer for blueprint ghost previews.**

**1. Committed blocks render via `GridMap`.** GridMap's data model is an almost exact match for Voxel World's own: `Vector3i`-addressed cells, one item per cell, a fixed uniform cell size. `GridMap.set_cell_item(cell, item_id, orientation)` / `clear_cell_item` (item_id = -1) directly implements Voxel World's low-level write API (TR-voxel-world-007), and GridMap renders its used cells via internal `MultiMeshInstance`-based batching per mesh type — confirmed unchanged in 4.7 (only the authoring workflow, via the new dedicated MeshLibrary editor, changed). The tier-0 MVP palette (wood/stone/thatch blocks + bed) is small; the MeshLibrary grows as Resource & Item Database's tier list grows, with no structural change needed.

**2. GridMap's physics collision is disabled (`use_collision = false`).** Nothing in the MVP or Vertical Slice GDDs requires Godot-physics collision against voxel blocks: Villager AI's walkability is a custom cell-data predicate (clearance/step-height rules, TR-villager-ai-behavior-009/010), not a `CharacterBody3D`-vs-terrain physics query — villagers interpolate between cells per the F1 formula, they don't fall or collide against real geometry. Note: GridMap's built-in collision is *not* actually the per-cell collider trap TR-voxel-world-018 warns about — Godot bakes GridMap collision at the octant level (default `cell_octant_size = 8`, one `ConcavePolygonShape3D` per 8×8×8-cell chunk registered against a single `PhysicsServer3D` body), not one collider per cell. Disabling it here is simply because nothing needs it — an unused-capability removal, not a scalability workaround — and it also means block picking (next point) has no collider to depend on either way.

**3. Picking uses a manual DDA grid-walk against Voxel World's own occupancy dictionary — not a physics raycast.** Voxel World already holds the authoritative occupied-cell data (a `Dictionary[Vector3i, CellData]` per ADR considerations already established); a DDA walk along the camera's world-ray (from Camera & Input's `get_world_ray()`, per `architecture.md`'s API Boundaries) against that same dictionary returns the first occupied cell directly, with no collider of any kind. This is strictly cheaper than a physics query for this use case (no `PhysicsServer3D` round-trip, no collision-layer bookkeeping) and matches the concept prototype's already-validated DDA-raycast picking approach exactly — the interaction feel that was proven survives the rendering-representation change unmodified, because picking was never actually derived from the rendering geometry in the first place.

**4. Blueprint ghosts render via a small pool of `MeshInstance3D` nodes, separate from GridMap.** GridMap cells are binary — committed or empty — with no natural "preview" state, and ghosts must be visually distinct (tint/transparency) and re-rasterize live every frame during a drag. Ghost counts are always small and bounded (`max_cells_per_command` = 512, and TR-building-system-035 already degrades to an outline above `preview_degradation_threshold`), so a pool of individually-instanced `MeshInstance3D` nodes — reusing the same mesh assets as the MeshLibrary items, with a `material_override` for the ghost tint — is simple, correct, and cheap at this bounded scale. No custom per-instance shader/custom-data plumbing is needed (which a MultiMesh-based ghost layer would require to vary tint per-instance).

### Architecture Diagram
```
Committed blocks:
  Voxel World data (Dictionary[Vector3i, CellData])
        │  bulk_write() / set_cell() / clear_cell()
        ▼
  GridMap.set_cell_item(cell, item_id, orientation)  [use_collision = false]
        │  (internal MultiMeshInstance batching, unchanged since pre-4.4)
        ▼
  Rendered world (draw calls batched per mesh type, not per cell)

Picking (Building System commit pipeline, Villager Info UI block-vs-villager tie-break):
  Camera & Input.get_world_ray() → manual DDA walk against Voxel World's
  OWN data dictionary (NOT GridMap, NOT PhysicsServer3D) → first occupied
  cell along ray, or none

Blueprint ghosts (always small, bounded by max_cells_per_command=512):
  Building System's blueprint cell set → pool of MeshInstance3D nodes,
  material_override = ghost tint, degrades to outline above
  preview_degradation_threshold
```

### Key Interfaces
```gdscript
# Voxel World's raycast_cells() (already specified in architecture.md's API
# Boundaries) is implemented as a manual DDA walk, NOT a physics query:
func raycast_cells(from: Vector3, to: Vector3) -> RaycastResult:
    # DDA grid-walk against the internal Dictionary[Vector3i, CellData];
    # no PhysicsServer3D call, no collider of any kind.
    ...

# GridMap sync (internal to Voxel World's implementation, not a public API):
func _on_cell_changed(cell: Vector3i, before: CellData, after: CellData) -> void:
    if after.is_empty():
        _grid_map.set_cell_item(cell, GridMap.INVALID_CELL_ITEM)
    else:
        _grid_map.set_cell_item(cell, _mesh_library_id_for(after.block_type_id))

# Building System's ghost pool (implementation detail, not a public API):
# a fixed-size Array[MeshInstance3D], reused per drag, material_override set
# to a shared ghost material resource; hidden and count reset each frame.
```

## Alternatives Considered

### Alternative A: GridMap — CHOSEN
- **Description**: as detailed in Decision above.
- **Pros**: near-exact match for Voxel World's own data model (fixed cell size, one item per cell, `Vector3i` addressing); free editor tooling (4.7's dedicated MeshLibrary editor); internal instanced rendering already optimized by the engine; trivial runtime cell mutation (`set_cell_item`); world-boundedness (~320k cell ceiling) is comfortably within GridMap's proven use range for tile/voxel-builder-style games.
- **Cons**: fixed-palette model (one MeshLibrary item per cell) — no per-cell arbitrary color/material variation beyond what the palette defines; not designed for a per-cell "preview" state, requiring the separate ghost-pool mechanism above.
- **Rejection Reason**: N/A — chosen.

### Alternative B: Manual `MultiMeshInstance3D`
- **Description**: hand-manage a `MultiMesh` resource per material/mesh type, tracking cell→instance-index mapping directly.
- **Pros**: full control over per-instance data (could encode ghost tint via per-instance custom-data channels, avoiding a separate ghost-pool layer); no GridMap fixed-cell-size assumption if one were ever needed (not the case here, per Constraints).
- **Cons**: reimplements, by hand, everything GridMap already provides for free — editor tooling, cell↔instance bookkeeping, collision-baking option (moot here since collision is disabled either way) — for a world whose data model already matches GridMap's assumptions exactly. The per-instance custom-data ghost-tint capability is a real advantage but doesn't offset the implementation cost given ghosts are bounded and small enough that a simple `MeshInstance3D` pool works fine.
- **Rejection Reason**: strictly more implementation work than Alternative A for no capability this project's constraints actually need.

### Alternative C: Chunked / greedy mesher
- **Description**: group cells into fixed-size chunks (e.g. 16×16×16), mesh each chunk as one combined `ArrayMesh` with hidden-face culling and/or greedy face-merging; remesh affected chunks on edit.
- **Pros**: best rendering performance at large scale (fewest draw calls, fewest vertices) — the standard technique for genuinely large/open voxel worlds (Minecraft-style).
- **Cons**: this is not that kind of game — the world is a small, bounded, hand-shaped valley (~320k cell ceiling, likely far smaller in practice for MVP/VS), not an open/infinite terrain. The implementation cost is the highest of the three alternatives, and per-edit remeshing (even partial/chunk-scoped) fights the frequent live-editing interaction pattern the concept prototype validated (drag-to-place, live ghost re-rasterization, undo/redo) — every undo/redo step would trigger a chunk remesh rather than GridMap's O(1) `set_cell_item` call.
- **Rejection Reason**: solves a scale problem this project doesn't have, at the highest implementation cost of the three, while fighting the already-validated live-editing feel. **Named as the explicit escape hatch** if the pre-VS performance spike finds GridMap insufficient at Township scale — not rejected as permanently wrong, rejected as premature.

## Consequences

### Positive
- Voxel World's low-level write API (`set_cell`/`clear_cell`/`bulk_write`) maps almost directly onto `GridMap.set_cell_item` calls — minimal translation layer.
- Avoids unnecessary physics overhead and any incidental collision interactions by disabling GridMap collision entirely, since no gameplay system needs it — GridMap's own collision generation is actually octant-batched (not per-cell), so TR-voxel-world-018's named trap wouldn't have applied to it directly either way, but there's still no reason to pay for a capability nothing consumes.
- The concept prototype's validated DDA-raycast picking feel carries over unmodified, because picking was designed against the data layer, not the rendering representation.
- Ghost rendering is simple and correct at the bounded scale this project actually has (≤512 cells per command, further outline-degraded above `preview_degradation_threshold`).

### Negative
- GridMap's fixed-palette model means any future "recolor a single block without changing its type" feature (not currently in any GDD) would need a MeshLibrary entry per color variant, or a departure from this ADR.
- Two rendering paths exist (GridMap for committed blocks, pooled `MeshInstance3D` for ghosts) rather than one unified system — a small but real seam a future contributor must understand.
- If Alternative C ever becomes necessary post-spike, migrating away from GridMap means rewriting both the committed-block rendering AND re-deriving how picking/ghosts interact with the new representation — this ADR's "escape hatch" framing acknowledges that cost up front rather than hiding it.

### Risks
- **Risk** (resolved during this ADR's validation, kept here for record): GridMap's actual collision-generation granularity was uncertain in the first draft, which incorrectly assumed GridMap collision was per-cell and framed disabling it as dodging TR-voxel-world-018's named trap. `godot-specialist` review confirmed GridMap collision is octant-batched (default `cell_octant_size = 8`), not per-cell — the trap as described doesn't apply to GridMap's own collision generation. The decision to disable collision is unaffected (nothing needs it), but the earlier "eliminates a scalability trap" framing was corrected to "removes an unused capability" — see Decision §2 and Consequences → Positive above.
- **Risk**: the pre-VS performance spike (Township-scale, 20-30 villagers, per `villager-ai-behavior.md`) has not run yet — this ADR's conclusion is reasoned from the GDDs' stated constraints, not measured.
  **Mitigation**: RESOLVED — spike QQ3 PASSED 2026-07-11 (see prototypes/perf-spike-qq3/REPORT.md); Alternative C remains the named fallback should settlement density exceed the measured ~20% draw-call margin.
- **Risk**: GridMap's MeshLibrary must grow correctly as Resource & Item Database's tier list grows post-MVP — a manual sync point between two systems that don't otherwise talk to each other at runtime (per ADR-0001, RID is Autoload-tier, read-only, no write-back).
  **Mitigation**: MeshLibrary population happens once at boot, driven by iterating RID's `list_all_ids()` for `building_material`/`furniture_fixture` categories — a one-directional, boot-time-only dependency, not a runtime coupling.

**Engine Specialist Validation** (2026-07-11, `godot-specialist`, run before finalizing this ADR): confirmed GridMap's MultiMeshInstance-based rendering is unchanged in 4.7 per `current-best-practices.md`. Found and corrected one factual error in the initial draft: GridMap collision is octant-batched (`cell_octant_size = 8` default, one `ConcavePolygonShape3D` per 8×8×8-cell chunk), not per-cell — so TR-voxel-world-018's per-cell-collider trap does not literally apply to GridMap's own collision generation the way the first draft claimed. The decision to disable collision (nothing needs it) and the manual-DDA-picking approach (sound and, given collision is disabled, actually necessary rather than merely preferred — there would be no collider for a physics raycast to hit) both stand. Verdict: "needs a specific correction, not a blocker... the architectural decision itself... is sound and safe to accept once that text is corrected." Correction applied above.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|----------------------------|
| voxel-world.md | TR-voxel-world-025: "Rendering representation... is an open architecture decision" | This ADR — GridMap chosen |
| voxel-world.md | TR-voxel-world-017/018: raycast picking without the per-cell-collider scalability trap | Manual DDA against the data layer; no block colliders exist at all |
| building-system.md | TR-building-system-002/026: pick→preview→commit pipeline requires a raycast query every frame a tool is armed | Same manual-DDA `raycast_cells()` API, called every frame during ToolArmed/Dragging |
| building-system.md | TR-building-system-003/035/039/041: ghost preview re-rasterization, degrade-to-outline, aggregate ghost rendering requirement | Pooled `MeshInstance3D` ghost layer, separate from GridMap |
| villager-info-ui.md | TR-villager-info-ui-014/015: villager-hit query fully separate from block-picking, nearest-wins tie-break with epsilon | Confirms block picking (this ADR) uses no physics layer at all, so it cannot collide with the villager collision layer by construction — the separation is structural, not just a convention |
| game-concept.md | Open Question: "Voxel rendering approach at production scale: GridMap vs MultiMeshInstance3D vs a chunked/greedy mesher?" | Resolved here, provisionally pending the pre-VS spike |

## Performance Implications
- **CPU**: GridMap's internal batching keeps draw calls proportional to distinct mesh types in view, not cell count — well within the ≤2000 draw-call budget for the tier-0 MVP palette (3 materials + 1 furniture item). Manual DDA picking is O(ray length in cells), bounded by camera distance clamps already established in `camera-input.md`.
- **Memory**: Sparse `Dictionary[Vector3i, CellData]` at the data layer (already Voxel World's own target, tens of MB); GridMap's rendering-side memory is proportional to used cells and MeshLibrary size, not world bound.
- **Load Time**: GridMap population from Voxel World's data at boot (terrain generation + save/load) is a batch of `set_cell_item` calls, one per occupied cell — not measured yet, a candidate check for the pre-VS spike.
- **Network**: N/A — single-player project.

## Migration Plan
N/A — no existing code. If the pre-VS spike triggers a move to Alternative C, that migration plan will be written as part of resolving Open Question QQ3, not here.

## Validation Criteria
- The pre-VS performance spike (named in `villager-ai-behavior.md`, tracked as `architecture.md` QQ3) measures draw calls, frame time, and memory at Township-scale block counts under this ADR's approach; a PASS keeps this ADR Accepted as-is, a FAIL triggers Alternative C's migration.
- `GridMap.use_collision` is confirmed `false` in the implemented scene — grep/inspector-verifiable.
- Zero `PhysicsServer3D`/`RayCast3D` usage exists anywhere in Voxel World's or Building System's picking code path — grep-verifiable once implementation exists.

## Related Decisions
- Enables ADR-0004 (3D Physics Backend & Picking/Raycast Strategy), which now scopes down to villager/UI collision only (block picking is settled here).
- Depends on nothing; informed by `architecture.md`'s Open Question QQ3 and the concept prototype report (`prototypes/building-concept/REPORT.md`).
