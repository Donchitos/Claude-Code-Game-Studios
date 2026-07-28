# Slice Module Contracts (Day 1) — the integration source of truth

> VERTICAL SLICE — NOT FOR PRODUCTION. Every module implements EXACTLY these
> signatures so parallel-written modules integrate without rework. Slice-quality:
> constants instead of .tres configs are fine; keep the architecture SHAPE
> (setup() wiring, signals, clock split) from docs/architecture/control-manifest.md.

## Global constants (duplicated per file is fine in slice; keep values identical)

```gdscript
const CHUNK := 16
const MAX_Y := 32
const WORLD_SIZE := 2000              # cells per horizontal axis (full data world)
const REGION_RADIUS_CHUNKS := 12      # meshed/playable window radius around center
const SEED := 1337
# Cell ids (byte values in packed chunks)
const AIR := 0
const TERRAIN_BASE := 1               # 1..4 terrain height bands
const WOOD := 10
const STONE := 11
const THATCH := 12
const BED := 20
```

World center cell = `Vector3i(WORLD_SIZE/2, 0, WORLD_SIZE/2)`; the playable
region is the chunk window `center_chunk ± REGION_RADIUS_CHUNKS` (exclusive
upper bound), i.e. 384×384 cells. Camera pan and building are clamped to it.

## Clock rule (absolute)

Camera + UI + ghost preview run on **raw delta**. Simulation (construction
ticks, needs, villager movement progress) advances ONLY via
`TimeTickSystem.game_delta` / its `tick` signal. Never blend.

## TimeTickSystem (Autoload, res://time_tick_system.gd) — WRITTEN, do not modify

```gdscript
signal tick                            # fired per simulation tick (never while paused)
signal time_state_changed(paused: bool, warp: int)
var game_delta: float                  # read-only by convention, updated in _physics_process
func set_paused(p: bool) -> void
func toggle_paused() -> void
func set_warp(w: int) -> void          # 1, 2, 3
func get_paused() -> bool
func get_warp() -> int
# Constants: TICKS_PER_SECOND=4.0, MAX_TICKS_PER_FRAME=10, MAX_RAW_DELTA=0.1
```

## ResourceItemDatabase (Autoload, res://resource_item_database.gd) — WRITTEN, do not modify

```gdscript
func is_ready() -> bool
func get_by_id(id: String) -> ItemDef            # null if unknown
func list_by_category(category: String) -> Array[ItemDef]
# ItemDef (inner class, getter-only): id, display_name, category, cell_value(int),
#   color(Color), build_ticks(int)
# ids: "wood_block", "stone_block", "thatch_block", "bed"
# categories: "building_material", "furniture_fixture"
```

## VoxelWorld (res://voxel_world.gd, Node3D, injected)

```gdscript
signal cell_changed(changes: Array)    # Array of {cell: Vector3i, before: int, after: int} — ONE emission per write call (batched)
func setup() -> void                   # terrain gen (region window only) + initial mesh build; SYNCHRONOUS
func get_cell(cell: Vector3i) -> int   # 0 = air / out of bounds handled: returns -1 out of world bounds
func set_cells(changes: Array) -> Array          # [{cell, value}] -> returns [{cell, before, after}]; ONE cell_changed emission; remeshes affected chunks
func raycast_cells(origin: Vector3, dir: Vector3, max_dist := 200.0, extra_solid := Callable()) -> Dictionary
    # DDA. {} on miss; else {cell: Vector3i, normal: Vector3i} (normal = face stepped through, for attach-placement).
    # extra_solid (2026-07-22, FEATURE 3 ghost snapping), if valid: Callable(cell: Vector3i) -> bool,
    # an additional solidity predicate checked alongside real voxel data (building_system threads its
    # blueprint-cell lookup through this while build mode is active, so the ray also stops on ghosts).
    # Solidity itself (2026-07-22, BUG A fix) now excludes WATER(40) -- every other non-air value
    # (terrain 1..5, built 10..29, trunk/leaves 30/31) was already solid and still is.
func is_in_region(cell: Vector3i) -> bool        # inside the playable window AND 0 <= y < MAX_Y
func get_region_aabb() -> AABB                   # playable region in world units (for camera clamp)
func terrain_height(x: int, z: int) -> int      # deterministic noise height (for spawn placement)
```

Meshing: per-cell face culling (face emitted where cell borders AIR), one
ArrayMesh per 16×16-column chunk, vertex colors from ItemDef color / terrain
band colors, whole-chunk rebuild on change (adjacent chunk too when a border
cell changes). `vertex_color_use_as_albedo`, proper winding + backface culling.

## CameraInput (res://camera_input.gd, Node3D with child Camera3D, injected)

```gdscript
signal action_fired(action_name: String)   # tool_select_1..5, build_cancel, undo, redo,
                                            # height_step_up/down, palette_next/prev, formation_next/prev,
                                            # time_pause, time_speed_up/down
signal build_click(pressed: bool)           # LMB press/release IN WORLD (only fired from _unhandled_input)
var remove_modifier_held: bool              # Ctrl held (slice shortcut for Block-tool remove)
func setup(world_aabb: AABB) -> void        # registers InputMap actions at runtime (slice shortcut), clamps pan to aabb
func get_world_ray() -> Dictionary          # {origin: Vector3, dir: Vector3} from current mouse pos — ALWAYS valid
func get_camera() -> Camera3D
```

Orbit rig per camera-input GDD: position derived target+spherical(distance,yaw,pitch),
pitch clamp 0.3..1.4 rad, distance 8..120, WASD pan yaw-relative scaled by
distance, Q/E yaw steps, middle-drag rotate, wheel zoom multiplicative. Raw
delta, clamped to 0.1. Pan target clamped to world_aabb (xz).

## BuildingSystem (res://building_system.gd, Node3D, injected)

```gdscript
signal tool_changed(tool_id: int)                 # 0=None, 1=Wall, 2=Floor, 3=Roof, 4=Block, 5=Furniture
signal palette_changed(material_id: String)      # current material item id
signal wall_height_changed(h: int)               # 1..8, default 3
signal formation_changed(name: String)           # "Flat" only functional; picker shows 4
signal undo_state_changed(can_undo: bool, can_redo: bool)
signal invalid_commit(world_pos: Vector3, reason: String)
signal construction_completed(cells: Array)      # batched per frame: Array[Vector3i] built this frame
signal cells_removed(cells: Array)               # batched: undo/remove of BUILT cells
signal blueprint_changed()                        # blueprint set changed (commit/cancel/complete)
signal furniture_placed(cell: Vector3i, item_id: String)
signal furniture_removed(cell: Vector3i, item_id: String)
func setup(voxel_world, camera_input, hud) -> void
func get_active_tool() -> int
func is_tool_armed() -> bool
func get_blueprint_cells() -> Dictionary          # Vector3i -> {item_id, progress_ticks, claimed_by}
func claim_job(villager_id: int) -> Variant       # nearest-by-air-dist open cell or null; locks it
func release_job(cell: Vector3i) -> void
func report_on_site(cell: Vector3i) -> void       # villager on site: progress++ per tick (called from its tick)
func is_cell_occupied_planned(cell: Vector3i) -> bool  # blocks + blueprints combined view
func get_furniture_cells() -> Dictionary          # Vector3i -> item_id (BUILT furniture only)
# --- Stonehearth build workflow (2026-07-21, user direction) ---
signal build_mode_changed(active: bool)
func set_build_mode(active: bool) -> void         # off: aborts drag, disarms, hides ghosts
func get_build_mode() -> bool                     # tools arm only in build mode (arming auto-enables)
func release_drafts() -> int                      # thin compat wrapper (2026-07-22): releases every DRAFT project, returns total cell count released
func get_draft_count() -> int
# --- Stonehearth build PROJECTS (2026-07-22, user direction) ---
signal projects_changed()                          # created/merged/state change/claim change/cancelled
func get_projects() -> Array
    # Array of {id:int, name:String, state:int (0 DRAFT/1 BUILDING/2 PAUSED/3 DONE),
    #   state_label:String, total_cells:int, built_cells:int, worker_ids:Array[int],
    #   draft_cells:int (2026-07-23: pending change-order drafts, ANY state),
    #   demolishing:bool (2026-07-23: true once cancel_project/Abriss queued
    #     demolition orders for its built cells -- see addendum)}
func is_job_claimed_by(cell: Vector3i, villager_id: int) -> bool  # ANTI-STUCK FEATURE 2
    # (2026-07-23): true while cell's blueprint entry is claimed by exactly
    # villager_id -- lets VillagerAI detect a claim silently released out from
    # under it (seal-prevention refusing a completion) without changing
    # report_on_site's signature.
func set_villager_ai_script(script: GDScript) -> void  # ANTI-STUCK FEATURE 2: injects
    # VillagerAI's script (static is_standable/is_step_legal/has_escape_after_write)
func set_position_provider(cb: Callable) -> void    # ANTI-STUCK FEATURE 2:
    # cb(villager_id:int) -> Variant (Vector3i cell or null)
func release_project(id: int) -> void              # releases every still-DRAFT entry owned by
                                                     #   this project regardless of the project's OWN
                                                     #   state (2026-07-23: generalized beyond
                                                     #   DRAFT-only projects for change orders --
                                                     #   DRAFT/DONE -> BUILDING; BUILDING/PAUSED
                                                     #   unchanged). No-op if nothing to release.
func pause_project(id: int) -> void                 # BUILDING -> PAUSED; no NEW claims, but a job a
                                                     #   villager already claimed is allowed to finish
func resume_project(id: int) -> void                # PAUSED -> BUILDING
func cancel_project(id: int) -> void                # 2026-07-23 REWRITE, "Alles ueber Auftraege":
                                                     #   unbuilt blueprint entries are discarded
                                                     #   instantly (free); BUILT cells instead become
                                                     #   RELEASED demolition orders (see addendum) --
                                                     #   the project is marked demolishing and only
                                                     #   disappears once every cell is actually gone.
# --- Click selection (2026-07-23, PERSISTENT PROJECTS + VISIBILITY PACKAGE) ---
signal project_selected(id: Variant)                # fires on select/deselect (id:int or null)
func get_project_at_cell(cell: Vector3i) -> Variant # project id or null; covers built AND
                                                     #   still-blueprint (draft/released/demolition)
                                                     #   cells, since _cell_project is populated the
                                                     #   instant a cell is committed
func select_project(id: Variant) -> void            # invalid id -> deselect
func get_selected_project() -> Variant               # id:int or null
func deselect_project() -> void                      # convenience for select_project(null)
```

Every blueprint entry also carries a `project_id: int`. Grouping rule: a
drag/placement's WHOLE cell batch merges into an existing DRAFT-state project
if any cell in the batch is within the 26-neighborhood of that project's
cells (bridging multiple DRAFT projects merges them into one); otherwise a
fresh project is created. **REVERSED (2026-07-23, PERSISTENT PROJECTS +
VISIBILITY PACKAGE, see addendum below):** a batch touching a
BUILDING/PAUSED/DONE project (instead of a DRAFT one) now ATTACHES to that
SAME project as fresh draft entries (a change order) rather than starting a
new project or being ignored — see the addendum for the full change-order/
demolition semantics this unlocks. A DRAFT match still wins over a
released/DONE match if a batch happens to touch both (documented judgment
call). `claim_job` only serves BUILDING-state projects and records the
claiming villager per project (surfaced via `worker_ids`).

### Removal tool: draft eraser + terrain dig orders (2026-07-22, this task)

The removal tool (Block tool + Ctrl) is now press+drag (a plain click is a
1-cell box; dragging forms an axis-aligned inclusive box between press and
release cells, any of the 3 axes). For every cell in the box:
1. A DRAFT blueprint entry (any project) is erased immediately -- no
   villager job, it's a plan edit. Released/BUILDING/PAUSED entries are
   untouched by this path (existing removal-job path still applies to them
   once built).
2. A BUILT cell (10..29) queues the existing removal-job path (writes the
   cell's tracked `restore_value`, not always AIR -- see BUG B below).
3. Raw diggable terrain (1..5: the 4 height bands + SAND) queues a **dig
   order**: a blueprint entry with `"dig": true`, grouped into its own DRAFT
   project (name `"Abbau %d"`, 26-neighborhood rule, NEVER merges with build
   projects even if adjacent). Invalid if a villager currently occupies the
   cell's body column (same occupancy provider construction uses).

Dig orders flow through the exact same DRAFT -> `release_project` ->
`claim_job` -> `report_on_site` -> batched write pipeline as builds; a dig
job has no material (fixed duration, `DIG_BUILD_TICKS`) and always completes
to AIR. Dig completions fire `cells_removed` (not `construction_completed`),
same restore-on-cancel/undo semantics as builds (the pre-dig terrain value is
banked as `restore_value`/the project's `restore_values`). Ghosts: dig cells
render with a distinct reddish tint (`GHOST_TINT_DIG_DRAFT`/`_RELEASED`).

`get_blueprint_cells()` entries also carry `dig: bool` (default false).

### Addendum bug fixes (2026-07-22, this task)

- **Picking (voxel_world.raycast_cells)**: audited -- built cells (10..29)
  were ALREADY hit by the pre-existing uniform `v > AIR` solidity check; the
  real picking gap was DRAFT blueprint cells (AIR in real voxel data until
  built), now fixed by the `extra_solid` predicate above. Water(40) is now
  explicitly EXCLUDED from pick solidity (it previously registered as a
  solid hit, which read wrong for a decorative lake surface).
- **`_remove_built_cell`**: previously always wrote AIR, which meant
  removing a Floor-tool (terrain-replace) block carved a hole down to
  nothing instead of restoring the ground. Now looks up the cell's owning
  project (via the still-live `_cell_project` reverse index) and writes its
  tracked `restore_value`, matching the semantics `_undo()`/`cancel_project`
  already used. NOTE: audited voxel_world's chunk remeshing on cell writes --
  it is horizontal-only chunking (one full-height PackedByteArray per XZ
  chunk, no vertical chunk boundary exists) and already remeshes the correct
  adjacent chunk(s) on an X/Z chunk-edge write; no bug found there.

Pipeline per building GDD: pick(DDA via voxel_world.raycast_cells with
camera_input.get_world_ray()) -> ghost preview (pooled MeshInstance3D,
blue translucent valid / orange invalid) -> LMB drag rasterize (wall = line ×
height, floor/roof = rect, per F1/F2/F5) -> release commits blueprint cells ->
jobs queue -> villager builds over time (report_on_site) -> set_cells write.
Construction of a cell DEFERRED while villager occupies it. Undo = command
level, max 50. Ghost hidden while hud.is_hover_suppressing() OR ray miss.

## VillagerAI (res://villager_ai.gd, Node3D, injected)

```gdscript
signal state_changed(villager_id: int, state: int)   # 0 Deciding,1 Traveling,2 Working,3 Sleeping,4 Breather,5 Wandering
signal distress_changed(villager_id: int, kind: String)  # "trapped"|"ground_sleeping"|"" (cleared)
signal villager_unstuck(id: int, from_cell: Vector3i, to_cell: Vector3i)  # ANTI-STUCK
    # WATCHDOG (2026-07-23): fires whenever a permanently-stuck villager is teleport-rescued.
func setup(voxel_world, building_system, needs_mood) -> void   # spawns 1 villager near region center; builds AStar3D graph
func get_villager_ids() -> Array[int]
func get_info(villager_id: int) -> Dictionary   # {name, state:int, state_label:String, cell:Vector3i, visual_pos:Vector3, distress:String, has_bed:bool, unstuck_count:int}
func pick_villager(origin: Vector3, dir: Vector3, max_t: float) -> Variant   # id or null; slice: ray-vs-capsule math, no physics
static func is_standable(world, cell: Vector3i) -> bool
static func is_step_legal(world, from: Vector3i, to: Vector3i) -> bool
# --- ANTI-STUCK PACKAGE (2026-07-23, this task) ---
func get_unstuck_count() -> int                      # total teleport-rescues across every villager
func get_villager_cell(villager_id: int) -> Variant  # Vector3i or null; feeds BuildingSystem's position_provider
static func has_escape_after_write(world, builder_cell: Vector3i, write_cell: Vector3i, write_value: int) -> bool
    # true if builder_cell still has >=1 legal step after write_cell becomes solid (write_value) --
    # the seal-prevention primitive BuildingSystem.report_on_site calls before a non-dig completion.
```

FSM per GDD: priority urgent-sleep > work > wander; tick-driven; movement =
current_cell atomic at tick boundary + visual lerp on game_delta; graph patched
on cell_changed (region-bounded); bed claim via building_system.get_furniture_cells();
sleeping reports needs_mood.start_recovery/stop_recovery with source enum
("bed_sheltered"/"bed_unsheltered"/"ground_..."). Villager visual: capsule/box
stack, warm-ish color, no physics body.

## NeedsMood (res://needs_mood.gd, Node, injected)

```gdscript
signal need_urgent(villager_id: int, need: String)
signal need_satisfied(villager_id: int, need: String)
signal mood_band_changed(villager_id: int, band: int)   # 0 Happy, 1 Content, 2 Low
func setup(build_validation) -> void
func register_villager(villager_id: int) -> void
func start_recovery(villager_id: int, need: String, source: String) -> void
func stop_recovery(villager_id: int, need: String, reason: String) -> void
func is_urgent(villager_id: int, need: String) -> bool
func get_display(villager_id: int) -> Dictionary  # {sleep: float 0..100, band: int, band_label: String, why: String}  why="" when happy
```

F1 decay / F2 recovery (rates x1.0 bed_sheltered, x0.7 bed_unsheltered, x0.4
ground), F3 mood EMA + snap, F4 spawn init 100, tick-driven, urgency threshold
25, satisfied 90. Why templates per GDD ("tired — no bed", "tired — trapped!",
"sleeping rough — no shelter", "tired — bed unreachable").

## BuildValidation (res://build_validation.gd, Node, injected)

```gdscript
signal room_recognized(cells: Array, celebrate: bool)
signal sealed_space_warning(cells: Array, item_ids: Array, why: String)
signal unsheltered_furniture_info(cell: Vector3i, why: String)
signal shelter_status_changed(cell: Vector3i, sheltered: bool)
func setup(voxel_world, building_system, villager_ai_script) -> void  # connects to construction_completed/cells_removed/furniture events
func is_cell_sheltered(cell: Vector3i) -> bool
```

Event-driven region BFS per GDD: candidate interior = standable + roofed
(solid within 8 above); region = orthogonal connectivity; room = >=4 cells +
walkable outside connection (movement-graph walk to open sky). Emits per pass.

## HUD (res://hud.gd, CanvasLayer, injected) — layout per design/ux/hud.md

```gdscript
signal tool_button_pressed(tool_id: int)
signal material_selected(item_id: String)
signal formation_selected(name: String)
signal wall_height_set(h: int)
signal undo_pressed() / redo_pressed()
func setup(building_system, villager_ai, needs_mood, build_validation) -> void
func is_hover_suppressing() -> bool
func show_toast(key: String, severity: int, text: String) -> void   # severity 0 info, 1 warning; keyed refresh-in-place
func retire_toast(key: String) -> void
```

Zones per hud.md: toolbar bottom-center (5 tools + undo/redo), context panel
above it, time controls top-right, toasts below, issues anchor. Flat #262220
panels, #EDE6DA text, gold #F5A83C active highlight. Instant swaps. Villager
panel (res://villager_panel.gd, part of HUD scene): per design/ux/villager-panel.md
zone Z4 left; selection owned by it (click via camera_input.build_click when no
tool armed + villager_ai.pick_villager); overhead distress icon full-billboard.

## GameWorld (res://game_world.gd + GameWorld.tscn, root) — WRITTEN by integrator

Boot: RID ready -> voxel_world.setup() -> others' setup() in dependency order ->
environment (fog per art bible: distance fog to #6B8593 Threshold Cool, warm
DirectionalLight), warmth-as-reward: OmniLight3D (amber #F5A83C, energy ~1.2)
spawned at recognized-room center on room_recognized, removed when room lost.

## Addendum: BUILD UX PACKAGE (2026-07-22, this task)

### New tools / keys (BuildingSystem.Tool enum extended)

```gdscript
enum Tool { NONE = 0, WALL = 1, FLOOR = 2, ROOF = 3, BLOCK = 4, FURNITURE = 5,
            ROOM = 6, ROOF_AUTO = 7, HOUSE = 8 }
```
Keys 6/7/8 (`tool_select_6/7/8`, CameraInput) arm ROOM ("Raum")/ROOF_AUTO
("Dach")/HOUSE ("Haus") respectively, same auto-enable-build-mode semantics
as the existing 5 tools. HUD toolbar gained the 3 matching buttons (widened
`ZONE_HALF_WIDTH` 240->400 to fit).

- **ROOM** (drag, ground rect, min 3x3): perimeter WALLS at the current wall
  height with a 1-column full-height door gap centered on the edge nearest
  the camera (fallback: -z edge) — `_rasterize_room()`/`_room_door_column()`.
  Single project via the existing grouping rule.
- **ROOF_AUTO** (click-only, no drag): clicking any cell belonging to a
  project that has wall material (WOOD/STONE, draft or later) adds a flat
  thatch roof over that project's XZ bounding box at (max cell y + 1),
  skipping already-occupied cells — `_apply_roof_to_project()`. Joins the
  SAME project even if it's already BUILDING/PAUSED/DONE (a DONE project is
  reopened to BUILDING; new cells on a BUILDING project are added
  already-released so they're claimable immediately; PAUSED/DRAFT keep their
  existing semantics). No new project is ever created by this tool.
- **HOUSE** (click-only stamp): fixed 7x7 footprint — flush floor
  (terrain-replace), perimeter walls 3 high with 1 door gap, thatch roof —
  shown as a merged moving ghost centered on the cursor, valid only where
  all 49 columns share one `terrain_height` and the volume is clear.
  `_house_layout()` computes/validates; `_handle_house_press()` commits the
  whole stamp as ONE project ("Haus %d") mixing wood_block (floor+walls) and
  thatch_block (roof). **Known limitation**: the undo/redo command model
  assumes one material per command — undo restores correctly (per-cell
  `restore_value` capture is unconditional), but redoing a cancelled/undone
  House re-creates every cell under the command's single recorded item_id
  ("wood_block"), so the thatch roof portion will not re-progress after a
  redo. Accepted for this feature's scope (lowest task priority).

### Hover highlight + build grid (BuildingSystem, feature 1)

Always-on while a tool is armed, driven from the SAME per-frame pick
`_update_pick()` already computes (no extra raycast): a wireframe box
(1.02 scale, warm yellow/white, unshaded, `no_depth_test`) on the target
cell, a brighter quad on the hit face, and a translucent 9x9 line-grid
following `terrain_height` per column (+0.02 Y offset), rebuilt only when
the hovered column changes. No new public API — internal to BuildingSystem.

### Slice view (VoxelWorld + VillagerAI + HUD, feature 2)

**Approach chosen: shader clip (option a)**, not mesher-filter/remesh. The
single chunk `StandardMaterial3D` (shared by every chunk mesh) became a
`ShaderMaterial` using the new `res://chunk_terrain.gdshader`, which
replicates the previous look exactly (atlas texture, vertex-color-as-AO
modulate, `cull_disabled`, roughness 1 / no specular) and adds one `y_cut`
uniform with a fragment `discard` above it. Chosen over a *global* shader
uniform because there was already exactly one shared material instance for
every chunk — a plain per-material uniform gives the same "set once, every
chunk updates instantly, no remesh" result with less machinery. Open cut (no
cap faces) is accepted per task spec, since the mesher never emitted a top
face for a cell covered by real (non-air) terrain regardless of the visual
cut.

```gdscript
# VoxelWorld additions
signal slice_level_changed(level: int)   # fires only when the clamped level actually changes
func get_slice_level() -> int            # current cutoff cell-y; MAX_Y = off
func is_slice_active() -> bool           # level < MAX_Y
func set_slice_level(level: int) -> void # clamped 0..MAX_Y; pushes y_cut = level+1 to the shared material
func reset_slice_level() -> void         # convenience for Home/reset -> MAX_Y
```

Ghosts/preview/highlight/build-grid meshes are SEPARATE MeshInstance3D
materials (not the chunk shader), so they respect the cut via a plain
**visibility rule** instead: cells with `y > get_slice_level()` are filtered
out of the cell set before any ghost mesh is built (`_slice_filter_array`/
`_slice_filter_dict_keys` in building_system.gd).

VillagerAI subscribes to `voxel_world.slice_level_changed` directly in its
own `setup()` (no GameWorld broker needed) and hides a villager's
`visual_root` whenever `current_cell.y > _slice_level`.

Keys (CameraInput, runtime InputMap as usual): `slice_up` (PageUp),
`slice_down` (PageDown), `slice_reset` (Home) — wired in GameWorld directly
to `voxel_world.set_slice_level()`/`reset_slice_level()`. HUD's "Ebene: N"
label + ▼/▲ buttons (in the Z1 time-controls panel, which grew a 3rd row —
`TIME_CONTROLS_HEIGHT_ESTIMATE` 48->84) call `voxel_world.set_slice_level()`
directly too; the label hides itself when `is_slice_active()` is false.

### CONTRACT ADDITION: HUD.setup() 6th parameter

```gdscript
func setup(building_system: Node, camera_input: Node, villager_ai: Node,
           needs_mood: Node, build_validation: Node, voxel_world: Node = null) -> void
```
Needed for the slice-view indicator/buttons (`get_slice_level()`/
`is_slice_active()`/`set_slice_level()`). Defaults to `null` so existing
call sites without it don't break; GameWorld passes `voxel_world`.

## Addendum: PERSISTENT PROJECTS + VISIBILITY PACKAGE (2026-07-23, this task)

### 1. Visuals

- **Build grid** alpha cut to ~30% of its previous value (`BUILD_GRID_COLOR`
  0.35 -> 0.1) — it's a faint planning aid, not a hero visual.
- **Blueprint ghost alpha** bumped 0.30/0.45 -> **0.50/0.70** (draft/released)
  for the normal textured build ghost (`GHOST_TINT_DRAFT`/`GHOST_TINT_RELEASED`).
- **Ghost face audit finding**: `_build_ghost_mesh`'s per-set face culling
  (`if cell_values.has(cell + dir): continue`) was already correct — it only
  culls a face whose neighbor is in the SAME merged-mesh dictionary (draft-to-
  draft or released-to-released of the same tint), so every face touching
  real solid world geometry, air, or a DIFFERENT tint's cell set is always
  emitted, and `_refresh_blueprint_ghosts()` already reruns on every
  `blueprint_changed` emission (which fires on every relevant mutation), so
  meshes never go stale. **No missing-face bug was found in the culling
  algorithm.** The most likely explanation for the "missing faces" report is
  the very low pre-existing alpha (0.30/0.45) making faces hard to perceive
  against similarly-lit surroundings — directly addressed by the alpha bump
  above. As a defensive polish anyway (task's own ask), both the textured
  ghost material and the new overlay material now set
  `depth_draw_mode = DEPTH_DRAW_ALWAYS` (forces a depth write even though
  alpha < 1), reducing alpha-sort flicker between overlapping translucent
  ghost layers (e.g. a draft + released set of the same project mid change-
  order). Shadow casting was already off on every ghost mesh instance.
- **REPLACE/DIG overlay marker** (new): terrain cells that will be REPLACED
  (a Floor-tool terrain-replace entry, now flagged per-cell via a new
  `floor_replace: bool` blueprint-entry field) or DUG/DEMOLISHED (any
  `dig: true` entry — see section 3 below) additionally render a `1.06`-scale
  translucent, UNTEXTURED overlay box on the affected cell — orange
  (`OVERLAY_TINT_REPLACE_*`) for replace, red (`OVERLAY_TINT_DIG_*`) for
  dig/demolition, alpha 0.5/0.7 draft/released matching the ghost split.
  **This REPLACES the old dig-only tinted textured ghost mesh pair entirely**
  — a dig/demolition blueprint entry no longer gets a textured ghost at all,
  only the overlay (the real block already renders via the normal voxel mesh
  until the job completes, for a demolition). New internal API surface (not
  public, listed for the next agent's benefit):
  `_build_overlay_mesh(cells: Array, tint: Color) -> ArrayMesh`,
  `_refresh_overlay_mesh(instance, cells, tint)`, mesh instances
  `_overlay_dig_draft_mesh_instance` / `_overlay_dig_released_mesh_instance` /
  `_overlay_replace_draft_mesh_instance` / `_overlay_replace_released_mesh_instance`.

### 2. Persistent projects + click selection

- DONE projects were already never auto-removed and `_cell_project` was
  already kept alive for built cells (verified, no change needed) — the
  persistence requirement was already satisfied by the existing 2026-07-22
  build-projects implementation.
- New: `get_project_at_cell(cell) -> Variant` (project id or null; covers
  built AND still-blueprint cells), `select_project(id)`,
  `get_selected_project() -> Variant`, `deselect_project()`, signal
  `project_selected(id: Variant)`.
- Click routing lives in `hud.gd._on_build_click` (not building_system) since
  HUD already owns the villager-vs-tool arbitration: a tool armed skips
  selection entirely (unchanged priority); otherwise a raycast (same
  `extra_solid` blueprint predicate BuildingSystem uses for its own pick)
  resolves a cell, `get_project_at_cell` looks up ownership, and a hit
  selects + deselects the villager panel; a miss/non-project cell deselects
  the project and falls through to the existing villager-pick logic.
- Esc deselects the project BEFORE exiting build mode — inserted into
  `BuildingSystem._on_cancel()`'s existing chain (drag-abort -> erase-abort
  -> disarm tool -> **deselect project** -> exit build mode).
- World visual: a cyan wireframe box (`SELECTION_BOX_COLOR`, distinct from the
  warm-yellow hover highlight) around the selected project's cell-set
  bounding box, inflated by `SELECTION_BOX_INFLATE`. HUD: the project's card
  gets a gold border (matching the active-tool-button treatment) and the
  panel's `ScrollContainer.ensure_control_visible()` scrolls it into view.

### 3. Change orders + demolition jobs (REVERSES an earlier rule)

- **Adding**: `_assign_project`'s grouping rule now ALSO matches a
  BUILDING/PAUSED/DONE project (previously DRAFT-only) via the same
  26-neighborhood cell-adjacency test — the new cells ATTACH to that project
  as fresh `draft:true` entries (never merged/instantly released). A DRAFT
  match still wins if a batch happens to touch both kinds (judgment call).
  `get_projects()`'s new `draft_cells` field surfaces pending count regardless
  of the project's own top-level state; a DONE project with `draft_cells > 0`
  shows "Aenderungen geplant" in the HUD with a "Bau starten" button that
  calls the now-generalized `release_project(id)` (releases just the pending
  drafts; DRAFT/DONE -> BUILDING, BUILDING/PAUSED unchanged) — the project
  returns to DONE automatically once those cells complete (existing
  DONE-detection logic in `_flush_batched_signals`, unchanged).
- **Removing (task 3b, "a demolition is a dig on a built cell")**: the
  removal tool on a BUILT cell that belongs to a tracked project no longer
  removes it instantly — it creates a DRAFT demolition blueprint entry
  (`dig: true`, new `demolition: true` sub-flag) via `_create_demolition_order`,
  rendered through the red overlay above. Reuses the entire dig job pipeline
  (DRAFT -> release -> `claim_job` -> `report_on_site` -> batched write); a
  demolition's completion writes the project's captured `restore_value`
  (honors a Floor-tool terrain-replace cell's original ground) instead of a
  plain terrain dig's hardcoded AIR, and — unlike a plain terrain dig, which
  marks its cell "built" forever (the dig project persists as a permanent DONE
  record) — a completed demolition instead calls `_untrack_cell`, SHRINKING
  the owning project's `all_cells`/`built_cells` (and dropping the project
  entirely if that empties it out). `cells_removed` fires on completion so
  `build_validation` re-runs, same as any other removal. An untracked built
  cell (shouldn't normally occur in this codebase) still falls back to the
  old instant `_remove_built_cell` path. `_is_erasable_cell`/`_erase_preview_value`
  updated to route/texture accordingly (a demolition preview shows the REAL
  current block, not its post-demolition restore_value).
- **Cancel / Abriss ("Alles ueber Auftraege", user decision)**:
  `cancel_project(id)` no longer writes to the world directly. Every
  not-yet-built blueprint entry (draft or released) is discarded instantly
  (a plan is free); every already-BUILT cell instead gets a RELEASED
  demolition entry (`_create_demolition_entry`, bypasses the interactive
  occupancy gate — a decisive bulk teardown) and the project is flagged
  `demolishing: true` (surfaced via `get_projects()`; HUD hides its normal
  buttons and shows "Wird abgerissen"). The DONE-state "Abriss" button calls
  the exact same function. The project reaches its terminal removed state —
  simply dropped from `_projects`, per `_untrack_cell`'s existing empty-check
  — only once every one of its cells is actually gone (i.e. "dropped from the
  panel" IS the terminal state; no new ProjectState enum value was added).
- **Undo restriction (task 3d)**: `_undo`/`_redo` now operate on PLAN entries
  ONLY. **Simplification documented here**: a cell still present in
  `_blueprint` is still a pending plan (draft or released, never completed)
  and is cancelled as before; a cell NO LONGER in `_blueprint` has already
  been RESOLVED (built by a villager, or torn down by a completed
  demolition/dig job) and undo is now a **no-op** for that cell — it
  previously un-built completed construction and re-materialized completed
  demolitions/digs by writing `restore_values` back to the voxel world; that
  world-write path is gone from `_undo` entirely. A cancelled DRAFT demolition
  entry is un-tracked exactly like any other still-pending plan cancel EXCEPT
  it must NOT be stripped from its project's `all_cells`/`built_cells` (the
  underlying cell is still real, built, and owned by that project — only the
  pending removal plan is cancelled); `_push_command`/the undo/redo stack
  entries gained an `is_demolition: bool` field to drive this distinction.
  `_redo()` on a demolition command is a documented no-op (re-attaching a
  torn-down-order to a fresh synthetic project, the pattern every other redo
  path uses, would double-own a cell still tracked by its ORIGINAL project —
  out of scope for this prototype; queue a new demolition manually instead).
- **Eraser on a draft demolition entry** (task 3e) already falls through
  `_erase_blueprint_draft_cell`'s existing generic draft-cell-erase path
  (any `draft: true` entry, demolition or not) — just fixed to skip
  `_untrack_cell` for the demolition case (same reasoning as the undo
  restriction above: the built cell it targets must stay tracked).

## Addendum: ANTI-STUCK PACKAGE (2026-07-23, this task)

Slice-scope safety net against villagers getting PERMANENTLY stuck during
complex builds — NOT full build-order planning.

### 1. Unstuck watchdog (VillagerAI)

Per-villager stuck detection, evaluated every tick in `_update_watchdog`. A
villager is "stuck" when EITHER:
- (a) its current cell is not `is_standable` (buried/floating) — checked
  unconditionally, regardless of state; OR
- (b) it `has_destination` (state TRAVELING or WORKING — deliberately NOT
  WANDERING/BREATHER/SLEEPING/DECIDING, so an idle villager waiting between
  wander repicks is never flagged) AND `_has_any_legal_step(current_cell)` is
  false AND its cell hasn't changed since the previous tick.

`Villager.stuck_ticks` counts consecutive stuck ticks (reset to 0 the moment
the condition clears); at `STUCK_THRESHOLD_TICKS` (12, ~3s @ 4 tps) the
villager is teleport-rescued (`_rescue_villager`): moved to the nearest
standable, unoccupied cell found by `_find_rescue_cell` (ring search out to
`UNSTUCK_SEARCH_RADIUS` = 12, same-y first then nearby y via
`_RESCUE_DY_ORDER`, falling back to `_find_spawn_cell()` if nothing
qualifies), its path/claim cleared (a claimed job is released via the normal
`release_job` path — not lost, re-claimable by anyone), state reset to
DECIDING, and `villager_unstuck(id, from_cell, to_cell)` emitted. Telemetry:
`_unstuck_count` (total) + `Villager.unstuck_count` (per-villager, surfaced
via `get_info()`'s `unstuck_count` key), read through `get_unstuck_count()`.

### 2. Don't seal your last exit (BuildingSystem + VillagerAI)

Before a non-dig job completion writes its solid cell
(`report_on_site`, at the moment `progress_ticks` reaches `build_ticks`),
`_should_prevent_seal` asks `_would_seal_builder` whether the write would
leave the CLAIMING villager with zero legal steps out of its OWN current
cell. The simulation (`VillagerAI.has_escape_after_write`, a static method)
is deliberately cheap: a duck-typed proxy world (`_SealCheckWorld`) overrides
`get_cell` for exactly the one cell about to be written and forwards
everything else to the real world, then only the claiming villager's 24 (8
horizontal x 3 vertical) immediate neighbor steps are re-evaluated against
that proxy — no global connectivity analysis. If the write would seal the
builder in, the completion is refused: `release_job(cell)` puts the claim
back in the queue (progress_ticks stays banked; a different villager
approaching from elsewhere can complete it) and `report_on_site` returns
without setting `entry["ready"]`. `VillagerAI._tick_working` detects the
silent release via the new `is_job_claimed_by(cell, villager_id)` query
(rather than changing `report_on_site`'s CONTRACTS.md signature) and returns
to DECIDING to find different work instead of hammering the same cell.

**Livelock guard**: the SAME villager re-claiming and re-abandoning the SAME
cell is allowed through after `SEAL_ABANDON_LIVELOCK_LIMIT` (3) refused
attempts — tracked via `seal_abandon_villager`/`seal_abandon_count` fields on
the blueprint entry itself (survives the `claimed_by` reset a release
causes). The unstuck watchdog above is the fallback safety net if the 4th
attempt truly does seal the villager in.

Demolition/dig jobs are exempt (`is_dig` short-circuits the check) — they
FREE a cell, so they can never seal anyone in; the existing dig-under-own-
feet exclusion in `_find_onsite_path` is unaffected and unchanged.

New wiring (extra API, not previously in CONTRACTS.md — see the BuildingSystem
section above for signatures): `BuildingSystem.set_villager_ai_script`
(injects `VillagerAIScript`, same pattern `BuildValidation` already uses for
its static-method calls), `BuildingSystem.set_position_provider` (cb
`villager_id -> Vector3i|null`, fed by `VillagerAI.get_villager_cell`),
`BuildingSystem.is_job_claimed_by`. GameWorld wires the script right after
`building_system.setup()` (no live VillagerAI needed yet, just its preloaded
script) and the position provider in `_wire_optional_providers()` alongside
the other defensive `has_method` wiring.

### 3. F3 console (debug_console.gd)

`== SIM ==` block gained an `unstuck: N total` line
(`VillagerAI.get_unstuck_count()`); each villager's status row appends
`  unstuck:N` only when that villager's own count is > 0. Every
`villager_unstuck` emission is logged to the existing timestamped event feed
(`"Hilda unstuck (12, 8, 40) -> (13, 8, 41)"`).
