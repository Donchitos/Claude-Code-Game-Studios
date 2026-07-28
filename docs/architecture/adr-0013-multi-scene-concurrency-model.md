# ADR-0013: Multi-Scene Concurrency Model (Valley + Dungeon)

## Status
Accepted (2026-07-11 — dependency ADR-0007 accepted after spike QQ3 PASS; see prototypes/perf-spike-qq3/REPORT.md. User-delegated decision.)

**(Slice propagation 2026-07-23 — RESOLVED; offset recomputed against the 16k span)** The `100_000`-unit dungeon offset is **KEPT**, but its justification is corrected from a *ratio* to an *absolute-gap* argument. Against the 16,000×16,000×32 target, Valley geometry spans `0…16_000` units, so the empty gap to the Dungeon origin is `100_000 − 16_000 = 84_000` units — a ~6.25× offset/span ratio (down from the old "50×" vs the 2000-cell span), but **84,000 units of absolute separation, vastly larger than any planned dungeon extent**, which is what actually prevents geometric overlap (a dungeon would have to be ~84 km across to bridge it). Increasing the offset to restore a larger *ratio* is **rejected**: float32 ULP scales with magnitude — ~7.8 mm at 100k (2⁻⁷), but ~31 mm at 500k and ~62 mm at 1M — so a larger offset trades imperceptible jitter for perceptible jitter at 1-unit cell scale, for no real gain in a separation that is already enormous in absolute terms. The `10_000` fallback remains non-viable (only 0.6× the world span — would overlap). Net: keep `100_000` as the documented sweet spot; the ~7.8 mm ULP stays imperceptible for a 1-unit voxel game. No Dungeon scene exists yet — not blocking; this closes the coordinate-budget item ADR-0015 would otherwise inherit. See `change-impact-2026-07-23-slice-batch.md`.

## Date
2026-07-11

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7-stable |
| **Domain** | Rendering / Core (multi-scene concurrency) |
| **Knowledge Risk** | HIGH per the Phase 0 gap inventory |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md`, `modules/rendering.md` |
| **Post-Cutoff APIs Used** | None identified |
| **Verification Required** | Confirmed via `godot-specialist` validation (2026-07-11) — all API claims accurate for 4.7-stable; one required addition (GI/lighting-bleed clause) applied. See Engine Specialist Validation note in Consequences. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0014 (Chunked Voxel Rendering; formerly ADR-0003 — no block physics collision either way — no GridMap physics collision), ADR-0004 (collision-layer convention), ADR-0007 (zero `NavigationServer3D` usage) — all three substantially narrow this ADR's actual scope |
| **Enables** | Dungeon System, Squad & Combat System, and any future Scene/World Management VS+ work depending on a settled multi-scene model |
| **Blocks** | Any Dungeon-scene implementation work |
| **Ordering Note** | Not MVP-blocking — no Dungeon scene exists yet; deferred until that work actually begins |

## Context

### Problem Statement
`scene-world-management.md` requires Valley to keep simulating in real time while a Dungeon scene (VS+) has player focus, and explicitly names an unresolved partitioning question: `WorldEnvironment`, `Camera3D.current`, audio listeners, `NavigationServer3D` maps (RVO crosstalk), input routing, and GI/lighting bleed, framed as "shared `World3D` vs. separate SubViewports" (TR-scene-world-management-033). This ADR is narrower in practice than it first appears: ADR-0003 already disabled GridMap's physics collision (nothing needs it), ADR-0004 established that the *only* physics usage anywhere in this project is villager hit-testing via a dedicated `Area3D` collision layer, and ADR-0007 established that pathfinding uses a hand-rolled `AStar3D` graph, never `NavigationServer3D`. The "`NavigationServer3D` maps (RVO crosstalk)" concern the GDD names is therefore moot for this project specifically — there is no `NavigationServer3D` map to crosstalk, because nothing uses one.

### Constraints
- Exactly one scene receives player input/render focus at a time (TR-scene-world-management-010, already established) — Valley and Dungeon are never simultaneously visible or input-active
- Valley must keep ticking/simulating (needs decay, build timers, villager AI) while backgrounded, per Scene/World Management's core design
- This project uses no `NavigationServer3D` (ADR-0007) and no physics collision on voxel blocks (ADR-0003) — only a narrow, single-purpose `Area3D` layer for villager click-selection (ADR-0004)
- `DirectionalLight3D` (a "sun"/global directional light) is not distance-limited — unlike point/spot lights, spatial separation alone does not isolate it between two scenes sharing a `World3D`

### Requirements
- Valley's background simulation must continue uninterrupted while Dungeon has focus, without Valley's geometry, lighting, or audio interfering with what the player sees/hears in the Dungeon
- The mechanism must not require new rendering infrastructure (extra Viewports/render targets) unless the isolation this project actually needs can't be achieved without one
- Global, non-distance-limited rendering state (directional lighting, environment/fog/sky, active camera, active audio listener) must be explicitly and unambiguously controlled per active scene — not left to implicit engine stacking rules

## Decision

**Shared `World3D` (not separate SubViewports), with Dungeon content instantiated at a large spatial offset from Valley's origin, and explicit per-scene control of the handful of global (non-distance-limited) rendering/audio nodes: one `WorldEnvironment` with its `Environment` resource swapped on scene switch, `Camera3D.current` toggled, the active `AudioListener3D` toggled, and each scene's `DirectionalLight3D` visibility toggled.**

**1. Shared `World3D`, not separate SubViewports.** Separate SubViewports would give genuine, structural isolation (each with its own `World3D`, camera-current, environment) at the cost of maintaining a second render target/Viewport even though only one is ever shown at a time. Given this project's already-minimal physics/navigation footprint (point 3 below), the isolation SubViewports would buy is small relative to their cost — a shared `World3D` with explicit control over the few genuinely global nodes achieves the same practical isolation more simply.

**2. Spatial offset prevents geometric/physical overlap.** The Dungeon scene's root node is instantiated at a large, fixed offset from Valley's origin (e.g. `Vector3(100_000, 0, 0)`, far outside Voxel World's bounded extent (2000x2000x32 since the 2026-07-11 large-world decision, ADR-0014)) — a standard, simple technique for multi-level games sharing one `World3D`. This prevents any spatial collision between Valley's and Dungeon's static geometry, and — since Voxel World has no physics collision at all (ADR-0003) and the only physics-using system (villager `Area3D` hit-testing, ADR-0004) is Valley-specific — there is no cross-scene physics query concern to resolve beyond this offset.

**3. `NavigationServer3D` crosstalk is a non-issue for this project.** ADR-0007 established that Villager AI's pathfinding uses a hand-rolled `AStar3D` graph, never `NavigationServer3D`. Whatever Dungeon-specific navigation Squad & Combat/Dungeon System eventually needs (not yet designed) is a decision for THAT system's own future ADR — this ADR does not need to resolve `NavigationServer3D` map partitioning because nothing in this project's current design uses `NavigationServer3D` at all.

**4. Global rendering/audio state is explicitly, unambiguously controlled — never left to implicit stacking rules.** Three genuinely global (non-distance-limited) concerns exist regardless of spatial offset:
   - **Environment/fog/sky**: ONE persistent `WorldEnvironment` node exists; its `.environment` resource property is swapped (`valley_environment` ↔ `dungeon_environment`) on scene switch — not multiple `WorldEnvironment` nodes relying on Godot's tree-proximity stacking rule, which this design deliberately avoids needing to reason about.
   - **Active camera**: each scene's `Camera3D.current` is set `true` only while that scene is active; the backgrounded scene's camera is `current = false` (following the same "exactly one scene has focus" contract already established elsewhere).
   - **Active audio listener**: each scene's `AudioListener3D` is set as the current listener only while that scene is active, mirroring the camera-current pattern.
   - **Directional lighting**: each scene's `DirectionalLight3D` (if any) has its `visible` explicitly toggled per active scene — spatial offset does NOT isolate a directional light (it is not distance-limited by design), so this must be an explicit, per-scene toggle, not an implicit consequence of the spatial-offset trick that handles point/spot/area lights correctly.

   Point/spot/area lights (e.g. a hearth `OmniLight3D` in Valley) require no special handling — their range is bounded, and the spatial offset already keeps them well outside the other scene's geometry.

   **GI/lighting bleed** (explicitly named in TR-scene-world-management-033): no GDD currently specifies a global illumination system (SDFGI/VoxelGI/LightmapGI) for this project — the Visual Direction Note describes a stylized voxel look with warm lighting but does not commit to a GI technique, and none of the 11 approved MVP GDDs reference one. If SDFGI is adopted later, its cascades are camera-centered with a bounded extent, so the spatial offset above resolves cross-scene bleed automatically (Dungeon's cascades, centered on the Dungeon camera 100,000 units away, would never reach Valley's geometry). If no GI system is ever adopted, this concern is moot. This ADR does not commit to a GI technique — that remains an open decision for whichever future art/rendering pass addresses it.

**5. Input routing is unchanged — already resolved by an existing contract, and requires the same manual discipline under EITHER approach.** `scene-world-management.md`'s own Open Question suggested SubViewports "would isolate input for free" — **this is incorrect, corrected during this ADR's validation**: plain `_input()`/`_unhandled_input()` callbacks are dispatched by the `SceneTree` globally, not scoped to a `Viewport`/`SubViewport` — a node inside one SubViewport still receives these calls even while a different SubViewport is displayed. `SubViewport.handle_input_locally` only affects GUI/mouse-picking for `Control` nodes rendered into that viewport, not general `_input`/`_unhandled_input` isolation. This means BOTH alternatives require the identical manual discipline this project already has via Camera & Input's `Suspended` pattern (ADR-0001-era) — SubViewports would have bought no input-isolation benefit at all, further narrowing the case for Alternative B.

### Architecture Diagram
```
Shared World3D:
  Valley content   — instantiated at origin (0,0,0), within its bounded
                      ~100×32×100 extent
  Dungeon content  — instantiated at a large fixed offset, e.g.
                      (100_000, 0, 0) — spatially far from Valley

Global (non-distance-limited) state, explicitly toggled per active scene:
  WorldEnvironment.environment = valley_env | dungeon_env  (ONE node, swapped)
  Valley.Camera3D.current = true|false  (exactly one true across both scenes)
  Dungeon.Camera3D.current = true|false
  Valley.AudioListener3D current = true|false  (same pattern)
  Dungeon.AudioListener3D current = true|false
  Valley.DirectionalLight3D.visible = true|false  (explicit — NOT isolated
  Dungeon.DirectionalLight3D.visible = true|false   by spatial offset alone)

Not a concern for this project (confirmed by prior ADRs):
  NavigationServer3D map crosstalk — N/A, ADR-0007 uses no NavigationServer3D
  GridMap collision crosstalk — N/A, ADR-0003 disables GridMap collision
  Physics query crosstalk — narrowed to villager Area3D hit-testing only
  (ADR-0004), which is Valley-specific and spatially isolated by the offset
```

### Key Interfaces
```gdscript
# Scene/World Management's dungeon-entry/exit logic (extends its existing
# transition_begun/transition_ended contract, ADR-0001/0005):
func _activate_scene(scene: Node3D, camera: Camera3D, listener: AudioListener3D,
                      env: Environment, sun: DirectionalLight3D) -> void:
    camera.current = true
    listener.make_current()
    world_environment.environment = env
    if sun: sun.visible = true

func _deactivate_scene(camera: Camera3D, listener: AudioListener3D,
                        sun: DirectionalLight3D) -> void:
    camera.current = false
    # listener: the newly-activated scene's listener takes over via make_current()
    if sun: sun.visible = false

# NOTE: Camera3D.current and AudioListener3D "current" exclusivity are scoped
# per-Viewport, not per-World3D — since both scenes share one Viewport,
# activating one camera/listener already demotes the other automatically.
# The explicit false/deactivation calls above are therefore redundant with
# that engine behavior, but kept for clarity and auditability (confirmed via
# engine-specialist validation — harmless, not a correctness requirement).
```

## Alternatives Considered

### Alternative A: Shared `World3D` + spatial offset + explicit global-state toggling — CHOSEN
- **Description**: as detailed in Decision above.
- **Pros**: no extra Viewport/render-target overhead; the only genuinely global concerns (environment, camera-current, audio-listener, directional light) are handled by explicit, unambiguous toggles rather than relying on engine stacking-priority rules; this project's already-minimal physics/navigation footprint (ADR-0014 (formerly ADR-0003), ADR-0004, ADR-0007) means the isolation gap versus separate SubViewports is small.
- **Cons**: relies on discipline (every global-state toggle must actually happen on every scene switch) rather than structural isolation — a missed toggle is a real bug class, mitigated by centralizing all toggles in one `_activate_scene`/`_deactivate_scene` pair rather than scattering them.
- **Rejection Reason**: N/A — chosen.

### Alternative B: Separate SubViewports (each with its own `World3D`)
- **Description**: Valley and Dungeon each render into their own `SubViewport`, each with an independent `World3D`, `Camera3D`-current, and `WorldEnvironment` — genuinely structurally isolated, no shared coordinate space at all.
- **Pros**: no spatial-offset trick needed; no risk of a missed global-state toggle causing crosstalk, since the two `World3D`s are entirely separate.
- **Cons**: an inactive `SubViewport` still exists as a render target (memory cost) even if not continuously updated; extra node/Viewport management overhead for isolation this project's minimal physics/navigation footprint doesn't clearly need; **does NOT provide the "free" input isolation the source GDD's Open Question assumed** — confirmed during this ADR's validation that plain `_input`/`_unhandled_input` callbacks are dispatched SceneTree-wide regardless of SubViewport boundaries, so this alternative would require the identical manual input-routing discipline as Alternative A, with none of the assumed benefit.
- **Rejection Reason**: solves a crosstalk problem that, for this project specifically (near-zero `NavigationServer3D`/physics usage per ADR-0014 (formerly ADR-0003)/0004/0007), is already narrow — and its one input-routing advantage, as originally assumed in `scene-world-management.md`'s own Open Question, turned out not to exist. The added Viewport-management complexity isn't justified by the isolation actually gained.

## Consequences

### Positive
- No new rendering infrastructure — one shared `World3D`, one `WorldEnvironment` node with a swapped resource.
- `NavigationServer3D` crosstalk, the GDD's own most technically alarming-sounding concern, is confirmed moot for this project by three prior ADRs — a good example of earlier decisions narrowing a later one rather than compounding its risk.
- Centralizing all global-state toggles in one `_activate_scene`/`_deactivate_scene` pair (rather than scattering them per-system) keeps the "did I forget to toggle X" risk auditable in one place.

### Negative
- Relies on discipline (the toggle pair must be called correctly on every transition) rather than structural isolation — mitigated by centralization, not eliminated.
- The spatial-offset magic number (e.g. `100_000`) is a project convention that must be documented and respected by anything that ever positions Dungeon content, or a sufficiently large or numerous Dungeon could theoretically approach Valley's space — not a concern at any planned scope, but worth a code comment where the constant is defined.

### Risks
- **Risk**: no GI (global illumination) system is currently specified by any GDD — if one is adopted later (SDFGI/VoxelGI/LightmapGI), its cross-scene bleed behavior should be re-checked against whichever technique is chosen, though the spatial offset is expected to resolve it automatically for camera-centered techniques like SDFGI (see Decision §4's GI note).
- **Risk** (float precision, low — flagged in the 2026-07-11 architecture review): the `100_000`-unit spatial offset places Dungeon geometry where single-precision `float32` (Godot's default non-double build) has a ULP of ~7.8 mm, baking sub-centimeter jitter into positions at that magnitude — a well-known large-world-coordinate ("floating origin") effect the engine does not auto-correct for single-precision builds. Imperceptible for a 1-unit-cell voxel game and not a practical blocker, but recorded here as a conscious trade-off rather than a silent assumption.
  **Mitigation**: the old `10_000` fallback is NO LONGER viable under ADR-0014 (2000-cell world span = only 5x margin); keep `100_000` (50x - sufficient) or relocate the Dungeon offset along -X; a double-precision engine build is the heavier alternative, unnecessary at any planned scope.
  **Mitigation**: not a current concern (no GI in use); revisit if/when a GI technique is adopted.

**Engine Specialist Validation** (2026-07-11, `godot-specialist`, run before finalizing this ADR): confirmed all four API claims are accurate for Godot 4.7-stable, unaffected by any 4.4–4.7 change. `DirectionalLight3D` is confirmed to model an infinite-distance light affecting the whole `World3D` uniformly regardless of node position — the ADR's central reasoning for why it (uniquely, among light types) needs an explicit per-scene toggle is correct. Swapping one `WorldEnvironment` node's `.environment` resource is confirmed valid and is actually the *safer* choice versus multiple `WorldEnvironment` nodes, since Godot's multi-`WorldEnvironment` stacking-priority rule is "a real footgun best avoided entirely" — this design sidesteps it by construction. `AudioListener3D`'s `current`/`make_current()`/`clear_current()`/`is_current()` API is confirmed correct and unaffected. One required addition applied: TR-scene-world-management-033 explicitly named GI/lighting bleed, which the first draft never addressed — added above (no GI system is currently specified by any GDD; the spatial offset would resolve it automatically for camera-centered techniques like SDFGI if one is adopted later). One optional clarification also applied: `Camera3D.current`/`AudioListener3D` "current" exclusivity is scoped per-Viewport, not per-`World3D`, making the explicit deactivation calls harmless-but-redundant rather than load-bearing — noted in Key Interfaces. Verdict: "safe to accept, with one required addition" — applied.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|----------------------------|
| scene-world-management.md | TR-scene-world-management-033: "Two-simultaneous-live-scenes partitioning strategy required for WorldEnvironment, Camera3D.current, audio listeners, NavigationServer3D maps (RVO crosstalk), input routing, and GI/lighting bleed — shared World3D vs. separate SubViewports" | Shared World3D + spatial offset + explicit global-state toggling, Decision §1-4; NavigationServer3D crosstalk confirmed moot via ADR-0007; input routing confirmed already resolved via existing Suspended contract |

## Performance Implications
- **CPU**: Negligible — no extra Viewport/render pass; toggling a handful of boolean/resource properties on scene switch is effectively free.
- **Memory**: No extra render target compared to Alternative B (SubViewports).
- **Load Time**: Unaffected — this ADR doesn't change the transition/loading sequence already established elsewhere.
- **Network**: N/A — single-player project.

## Migration Plan
N/A — no existing code, no Dungeon scene exists yet.

## Validation Criteria
- A test/manual walkthrough (once a Dungeon scene exists) confirms Valley's geometry, lighting, and audio are not visible/audible while the Dungeon is active, and vice versa.
- A code-review checklist item: every new global-state node (a new `DirectionalLight3D`, a new `AudioListener3D`, etc.) added to either scene must be wired into the centralized `_activate_scene`/`_deactivate_scene` pair.
- Grep-verifiable: no second `WorldEnvironment` node exists anywhere in the project (the shared-node-with-swapped-resource pattern is the only one used).

## Related Decisions
- Depends on ADR-0014 (formerly ADR-0003), ADR-0004, and ADR-0007, all of which narrow this ADR's actual scope by having already minimized this project's physics/navigation footprint.
- Reuses the Suspended-signal input-routing pattern already established across ADR-0001/ADR-0005.
