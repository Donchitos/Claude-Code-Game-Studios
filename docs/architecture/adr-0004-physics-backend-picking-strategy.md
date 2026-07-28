# ADR-0004: 3D Physics Backend & Villager Hit-Testing Strategy

## Status
Accepted (2026-07-11 — per architecture-review-2026-07-11 recommendation; user-delegated decision. Not spike-gated and no dependency on a spike-gated ADR.)

## Date
2026-07-11

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7-stable |
| **Domain** | Physics |
| **Knowledge Risk** | HIGH — Jolt is now the default 3D physics engine since 4.6, a genuine behavior change from pre-cutoff (~4.3) GodotPhysics3D-only knowledge |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md`, `modules/physics.md` |
| **Post-Cutoff APIs Used** | Jolt as the default 3D physics engine (4.6+) — no Jolt-specific API is used directly, only the engine-level default |
| **Verification Required** | Completed — `godot-specialist` validation run 2026-07-11 before finalizing (see Engine Specialist Validation note in Consequences). Found and fixed one functional blocker (villager-hit query was missing `collide_with_areas = true`); backend choice and mechanism confirmed sound. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0014 (Chunked Voxel Rendering; formerly ADR-0014 (formerly ADR-0003), whose DDA-picking conclusion ADR-0014 carries over unchanged) — settled that block picking uses manual DDA, not physics, which narrows this ADR's scope to villager-hit testing only |
| **Enables** | Villager Info UI `/dev-story` implementation; any future physics usage (Squad & Combat hitboxes, VS+) inherits this ADR's backend choice and layer-numbering convention |
| **Blocks** | Villager Info UI's villager-hit query implementation |
| **Ordering Note** | None beyond depending on ADR-0014 (formerly ADR-0003) |

## Context

### Problem Statement
Villager Info UI requires "a dedicated physics query on a dedicated villager collision layer, fully separate from and never consulted by the block-picking query" (TR-villager-info-ui-014), with nearest-wins tie-break resolution against block picks (TR-villager-info-ui-015/016). This is, after ADR-0014 (formerly ADR-0003), the *only* physics usage anywhere in the 11 MVP GDDs — Voxel World blocks carry no collision at all, Camera & Input's ground-plane intersection is pure math, and Villager AI's movement/walkability is cell-data-driven, not physics-simulated. Two things still need deciding: which 3D physics backend the project uses (Godot 4.6+ defaults new projects to Jolt, a change from pre-cutoff knowledge), and the concrete mechanism + collision-layer numbering for villager hit-testing, since no layer convention exists yet.

### Constraints
- Godot 4.7-stable; Jolt Physics 3D is the engine's own default for new projects since 4.6
- Villagers do not need physical collision response (they don't fall, get pushed, or collide with terrain via Godot physics) — only ray-detectability for click-to-select
- Population ceiling 20-30 villagers (villager-ai-behavior.md) — the hit-test query must stay cheap at that scale, once per click, not per frame
- Must be structurally separate from block picking (ADR-0014 (formerly ADR-0003)'s DDA mechanism has no collision layer at all, so "separate" is automatic, not just conventional)

### Requirements
- A villager must be detectable by a single ray query, returning hit distance for tie-break comparison against a block-pick distance
- Building System's placement raycast (DDA, ADR-0014 (formerly ADR-0003)) must be structurally incapable of hitting a villager — not just configured to ignore them
- A project-wide collision-layer numbering scheme must exist so future systems (Squad & Combat hitboxes, VS+) don't collide (pun intended) with this ADR's layer assignment

## Decision

**Jolt Physics 3D (Godot's own default since 4.6, unchanged) as the project's 3D physics backend. Villagers carry a dedicated `Area3D`-based collision shape on Layer 1 ("villagers"), ray-detectable only — no physical collision response — queried via `PhysicsDirectSpaceState3D.intersect_ray()` with a `collision_mask` limited to Layer 1.**

**1. Physics backend: Jolt, no override.** Godot 4.7 defaults new projects to Jolt; this project has no feature anywhere in its 11 MVP GDDs that needs a GodotPhysics3D-specific capability (the one commonly-cited gap, `HingeJoint3D.damp`, is irrelevant — nothing in this project uses joints at all). Given the *only* physics usage is a single ray query against a static-shaped detection volume, the backend choice has essentially no functional impact either way — Jolt is chosen because it's the zero-configuration default and offers better determinism/stability generally, not because any specific Jolt capability is required.

**2. Villager hit-testing: `Area3D` + dedicated layer + `intersect_ray`.** Each villager instance carries a child `Area3D` with a `CollisionShape3D` (a simple capsule or cylinder approximating the villager's bounding volume), `collision_layer = 1` (the villagers bit), `collision_mask = 0` (villagers don't need to detect anything themselves — only to be detected). `Area3D` is chosen over `StaticBody3D`/`CharacterBody3D` because no physical collision *response* is ever needed — villagers never push or get pushed by anything through Godot physics; the shape exists purely so a ray query can find it.

Villager Info UI's click handler, when Building UI reports no armed tool (per TR-villager-info-ui-001's gate), runs a combined pick on click:
1. Manual DDA against Voxel World's data (ADR-0014 (formerly ADR-0003)'s `raycast_cells()`) → block hit distance, or none
2. `get_world_3d().direct_space_state.intersect_ray()` with `collision_mask = 1` (villagers only), **`collide_with_areas = true`, `collide_with_bodies = false`** (villagers are `Area3D`-only; `PhysicsRayQueryParameters3D` defaults to bodies-only detection, so this must be set explicitly or the query silently returns no hit, every time — confirmed via engine specialist validation, see Consequences) → villager hit distance, or none
3. Nearest wins by ray-parametric distance; if both hits exist within `pick_tie_epsilon` of each other, the villager wins (per TR-villager-info-ui-015's stated tie-break rule)

Building System's own placement pick (ToolArmed/Dragging) calls only step 1 (DDA) — it has no `collision_mask` to configure because it performs no physics query at all, so it is *structurally* incapable of hitting a villager, satisfying TR-villager-info-ui-014's separation requirement by construction rather than by convention.

**3. Collision layer numbering convention (new, project-wide):**

| Layer | Name | Purpose | Assigned by |
|---|---|---|---|
| 1 | `villagers` | Ray-detectable, no physical response | This ADR |
| 2–8 | *(reserved)* | Future gameplay physics (Squad & Combat hitboxes, VS+; any future system needing a distinct layer) | Future ADRs, on demand |
| 9–20 | *(reserved)* | Godot editor/engine internal use conventions, left untouched | N/A |

No other MVP system claims a layer, since blocks have none (ADR-0014 (formerly ADR-0003)) and nothing else uses physics.

### Architecture Diagram
```
Villager Info UI click handler (Idle/no-armed-tool only):
  Camera & Input.get_world_ray()
        │
        ├──► Voxel World.raycast_cells() [DDA, no physics] → block_dist | none
        │
        └──► direct_space_state.intersect_ray(mask=Layer1) → villager_dist | none
                    ▲
                    │ ray-detectable only, collision_layer=1, collision_mask=0
             Villager's Area3D + CollisionShape3D (capsule)

  Resolve: nearest wins; villager wins if |block_dist - villager_dist| <= pick_tie_epsilon

Building System placement pick (ToolArmed/Dragging only):
  Camera & Input.get_world_ray() → Voxel World.raycast_cells() only
  (no physics query exists in this path — structurally cannot hit a villager)
```

### Key Interfaces
```gdscript
# Per-villager hit-test shape (implementation detail, not a public module API):
# Area3D child node, collision_layer = 1, collision_mask = 0,
# CollisionShape3D = capsule approximating the villager's silhouette.

# Villager Info UI's combined pick (internal to its click handler):
func _resolve_click(ray_origin: Vector3, ray_dir: Vector3) -> ClickResult:
    var block_hit := voxel_world.raycast_cells(ray_origin, ray_origin + ray_dir * MAX_PICK_DISTANCE)
    var space_state := get_world_3d().direct_space_state
    var query := PhysicsRayQueryParameters3D.create(
        ray_origin, ray_origin + ray_dir * MAX_PICK_DISTANCE
    )
    query.collision_mask = 1        # villagers layer only
    query.collide_with_areas = true # REQUIRED: villagers are Area3D-only;
    query.collide_with_bodies = false  # default is bodies-only, areas=false
    var villager_hit := space_state.intersect_ray(query)
    # nearest wins; villager wins within pick_tie_epsilon — see Decision
    ...
```

## Alternatives Considered

### Alternative A: Jolt Physics 3D (default) — CHOSEN
- **Description**: use Godot 4.7's default 3D physics backend with no override.
- **Pros**: zero configuration, the engine's own recommended default since 4.6, better determinism/stability than GodotPhysics3D generally.
- **Cons**: none identified for this project's minimal physics usage.
- **Rejection Reason**: N/A — chosen.

### Alternative B: GodotPhysics3D (legacy, explicit override)
- **Description**: explicitly set the project's physics engine back to GodotPhysics3D.
- **Pros**: only relevant if a future feature needs a GodotPhysics3D-specific capability (e.g. `HingeJoint3D.damp`, the one commonly-cited gap).
- **Cons**: swimming against the engine's own current default for no benefit this project needs.
- **Rejection Reason**: no GDD anywhere requires a GodotPhysics3D-specific feature; there is no reason to deviate from the default.

### Alternative C (mechanism choice): `StaticBody3D`/`CharacterBody3D` instead of `Area3D` for villager hit-testing
- **Description**: give villagers a solid collision body instead of a detection-only `Area3D`.
- **Pros**: none specific to this use case.
- **Cons**: implies physical collision response (villagers could physically block/be blocked by raycasts meant for other purposes, or by future physics-driven systems) that nothing in the MVP or VS GDDs wants — villagers move via cell-interpolation, not physics.
- **Rejection Reason**: `Area3D` is the more precise fit — detectable by ray queries without implying any physical solidity that isn't wanted.

## Consequences

### Positive
- The "structurally separate, never consulted by block picking" requirement (TR-villager-info-ui-014) is satisfied by construction — Building System's placement pick has no physics query to misconfigure, not just a convention to follow.
- Establishes a project-wide collision-layer numbering convention before any layer conflicts can occur, with headroom reserved for Squad & Combat's future hitbox needs.
- Zero-configuration physics backend choice, consistent with the engine's own current guidance.

### Negative
- A per-villager `Area3D` + `CollisionShape3D` is a small but real per-instance overhead (up to 20-30 at Full Vision ceiling) — expected to be negligible against the 16.6ms frame budget, but not yet measured (see Risks).

### Risks
- **Risk**: per-villager `Area3D` overhead at the population ceiling (20-30) has not been measured.
  **Mitigation**: the villager-hit query only runs once per player click (event-driven, not per-frame per TR-camera-input-style contracts elsewhere in this project) — expected to be well within budget, but folds into the same pre-VS performance spike already tracked as `architecture.md` Open Question QQ3 if it needs empirical confirmation.
- **Risk** (found during engine-specialist validation — CORRECTED, not just noted): `PhysicsRayQueryParameters3D` defaults to `collide_with_bodies = true`, `collide_with_areas = false`. The first draft's query only set `collision_mask = 1` and never set `collide_with_areas = true` — with villagers as `Area3D`-only and no `PhysicsBody3D` on Layer 1, that query would have silently returned an empty result on every single click, with no error. Fixed in Decision §2 and Key Interfaces above.
- **Risk** (residual, not fully solved): `intersect_ray`'s tie-break on genuinely equal-distance overlapping villager capsules is decided by the physics engine's internal broadphase, not by this project's stable villager processing order — TR-villager-info-ui-016's tie-break guarantee is therefore aspirational for that specific edge case, not enforced by construction.
  **Mitigation**: low-probability in normal play (villager capsules are not expected to overlap); if it proves to matter, a follow-up fix would query `intersect_shape` for all overlapping candidates within a small ray-neighborhood and apply the stable order manually — deferred, not blocking MVP.

**Engine Specialist Validation** (2026-07-11, `godot-specialist`, run before finalizing this ADR): confirmed Jolt-as-default is safe with no relevant gotchas (none of the Jolt 4.6/4.7 breaking-changes entries — `SoftBody3D` mass, `WorldBoundaryShape3D` sign convention, `Area3D`-vs-`SoftBody3D` overlap reporting — apply to this project's soft-body-free, joint-free physics usage). Confirmed `intersect_ray` returns a single nearest-hit result, never multiple candidates. **Found one functional blocker in the first draft**: the villager-hit query was missing `collide_with_areas = true` (the query default is bodies-only), which would have made villager selection silently non-functional — fixed above. Also flagged the TR-016 tie-break nuance addressed in the Risks entry above. Verdict: "needs a specific correction, not a reconsideration... backend choice and overall mechanism are sound." Both corrections applied.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|----------------------------|
| villager-info-ui.md | TR-villager-info-ui-014: "Villager-hit testing is a dedicated physics query on a dedicated villager collision layer, fully separate from and never consulted by the block-picking query; Building's placement raycast must ignore this layer" | `Area3D` on Layer 1, queried only by Villager Info UI; Building System's DDA pick has no physics query to configure at all |
| villager-info-ui.md | TR-villager-info-ui-015: "Villager-vs-block pick resolution: nearest wins by ray-parametric distance; explicit tie tolerance constant `pick_tie_epsilon`" | Combined pick resolver in Decision §2 |
| villager-info-ui.md | TR-villager-info-ui-016: "Multiple-villagers-along-ray resolution: nearest wins deterministically; equal-distance ties break via stable villager processing order" | `intersect_ray` returns a single nearest-hit `Dictionary` (never multiple candidates), satisfying "nearest wins" directly. The "stable processing order" tie-break for genuinely equal-distance overlapping villagers is **not enforced by the physics query itself** — engine specialist review confirmed `intersect_ray`'s internal broadphase, not GDScript-visible ordering, decides which single hit is returned on an exact-distance tie. This is treated as a residual, low-probability risk (villager capsules are not expected to overlap in normal play) rather than a solved guarantee — see Risks. |

## Performance Implications
- **CPU**: One `intersect_ray` call per player click (not per-frame) — negligible against the frame budget. Per-villager `Area3D` maintenance cost at 20-30 instances is expected negligible; folds into the pre-VS spike if empirical confirmation is needed.
- **Memory**: One `Area3D` + one `CollisionShape3D` (capsule) per villager — small, fixed per-instance cost.
- **Load Time**: N/A — villager shapes are created alongside villager instantiation, not a separate boot step.
- **Network**: N/A — single-player project.

## Migration Plan
N/A — no existing code.

## Validation Criteria
- `ProjectSettings` confirms Jolt as the active 3D physics engine (default, no override needed).
- Every villager instance has exactly one `Area3D` child with `collision_layer = 1`, `collision_mask = 0` — verifiable via a scene/test assertion.
- Building System's placement-pick code path contains zero physics API calls — grep-verifiable (`grep -rn "intersect_ray\|PhysicsDirectSpaceState3D" src/building_system/` should return zero matches once implementation exists).

## Related Decisions
- Depends on ADR-0014 (formerly ADR-0003) (Voxel World Rendering Approach) for the block-picking mechanism this ADR's tie-break logic compares against.
- Establishes the collision-layer numbering convention future ADRs (Squad & Combat, VS+) must extend, not redefine.
