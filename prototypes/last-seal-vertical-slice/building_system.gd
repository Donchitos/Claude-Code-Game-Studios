# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: full build->furnish->live loop, unguided <=5 min, cozy at scale
# Date: 2026-07-12
# Building System per design/gdd/building-system.md, slice-reduced:
# pick->preview->commit pipeline, wall(F1)/floor(F2)/roof-flat(F5) drag rasterization,
# blueprint-then-build with tick-driven construction (F3), undo/redo (max 50),
# pooled ghost previews (tool preview + blueprint progress), FIFO job queue,
# occupancy-provider deferral (Edge Case 6 / TR-building-system-037).
class_name BuildingSystem
extends Node3D

# --- Global constants (duplicated per file per CONTRACTS.md) ---
const AIR := 0
const BUILT_CELL_MIN_VALUE := 10  # WOOD(10)/STONE(11)/THATCH(12)/BED(20) -- player-built; terrain is 1..4
const TERRAIN_MIN_VALUE := 1      # TERRAIN_BASE per CONTRACTS.md -- 1..4 terrain height bands
const TERRAIN_MAX_VALUE := 4
# FEATURE 2 (2026-07-22, terrain dig orders): diggable terrain range -- the 4
# height bands (1..4) plus SAND(5); NOT water(40)/trunk(30)/leaves(31).
const DIGGABLE_MIN_VALUE := 1
const DIGGABLE_MAX_VALUE := 5
const DIG_BUILD_TICKS := 5  # tuning knob: dig duration, same order of magnitude as material build_ticks (4..8)
# ANTI-STUCK, FEATURE 2 (2026-07-23, "don't seal your last exit"): a non-dig
# completion that would leave its own builder with zero legal steps is
# refused (see report_on_site/_should_prevent_seal) -- but the SAME villager
# is allowed through after this many refused attempts on the SAME cell, so a
# genuinely sealed-in villager doesn't camp a job forever (the unstuck
# watchdog is the fallback safety net if it truly seals itself).
const SEAL_ABANDON_LIVELOCK_LIMIT := 3

# --- BUILD UX PACKAGE (2026-07-22, user-prioritized) ---
# Cell values duplicated per file per CONTRACTS.md (voxel_world.gd is the source of truth).
const _WOOD_VALUE := 10
const _STONE_VALUE := 11
const _THATCH_VALUE := 12
const _WALL_MATERIAL_VALUES: Array[int] = [_WOOD_VALUE, _STONE_VALUE]

# FEATURE 3: Room tool — perimeter walls + one door gap.
const ROOM_MIN_SIZE := 3

# FEATURE 5: House template — fixed 7x7 starter house stamp.
const HOUSE_FOOTPRINT := 7
const HOUSE_WALL_HEIGHT := 3

# FEATURE 1: hover highlight + build grid tuning knobs.
const HIGHLIGHT_BOX_SCALE := 1.02
const HIGHLIGHT_BOX_COLOR := Color(1.0, 0.92, 0.55, 0.95)   # warm yellow/white, unshaded
const HIGHLIGHT_FACE_COLOR := Color(1.0, 0.98, 0.85, 0.55)  # brighter quad on the hit face
const HIGHLIGHT_FACE_EPSILON := 0.01                        # push out along the normal, avoid z-fighting
const BUILD_GRID_RADIUS := 4     # 9x9 cells (radius 4 either side of the hovered column)
const BUILD_GRID_Y_OFFSET := 0.02
# VISIBILITY PACKAGE (2026-07-23, task 1a): ~30% of the previous 0.35 alpha --
# the grid read as too visually loud against the build-grid's purpose (a
# faint planning aid, not a hero visual).
const BUILD_GRID_COLOR := Color(1.0, 0.95, 0.7, 0.3)  # ~30% (user 2026-07-23)

# VISIBILITY PACKAGE (2026-07-23, task 2b): project selection wireframe outline
# -- deliberately distinct from HIGHLIGHT_BOX_COLOR (hover) so the two never
# read as the same affordance.
const SELECTION_BOX_COLOR := Color(0.35, 0.85, 1.0, 0.95)  # cyan
const SELECTION_BOX_INFLATE := 0.06  # world units, applied to the whole project bbox

enum Tool { NONE = 0, WALL = 1, FLOOR = 2, ROOF = 3, BLOCK = 4, FURNITURE = 5, ROOM = 6, ROOF_AUTO = 7, HOUSE = 8 }

# --- Build projects (2026-07-22, user direction: Stonehearth-style build projects) ---
enum ProjectState { DRAFT = 0, BUILDING = 1, PAUSED = 2, DONE = 3 }
const PROJECT_STATE_LABELS := {
	ProjectState.DRAFT: "DRAFT",
	ProjectState.BUILDING: "BUILDING",
	ProjectState.PAUSED: "PAUSED",
	ProjectState.DONE: "DONE",
}
# 26-neighborhood offsets (incl. self) used to test cell adjacency for project grouping.
const _NEIGHBORHOOD_26: Array[Vector3i] = [
	Vector3i(-1, -1, -1), Vector3i(0, -1, -1), Vector3i(1, -1, -1),
	Vector3i(-1, 0, -1), Vector3i(0, 0, -1), Vector3i(1, 0, -1),
	Vector3i(-1, 1, -1), Vector3i(0, 1, -1), Vector3i(1, 1, -1),
	Vector3i(-1, -1, 0), Vector3i(0, -1, 0), Vector3i(1, -1, 0),
	Vector3i(-1, 0, 0), Vector3i(0, 0, 0), Vector3i(1, 0, 0),
	Vector3i(-1, 1, 0), Vector3i(0, 1, 0), Vector3i(1, 1, 0),
	Vector3i(-1, -1, 1), Vector3i(0, -1, 1), Vector3i(1, -1, 1),
	Vector3i(-1, 0, 1), Vector3i(0, 0, 1), Vector3i(1, 0, 1),
	Vector3i(-1, 1, 1), Vector3i(0, 1, 1), Vector3i(1, 1, 1),
]

const FORMATIONS: Array[String] = ["Flat", "Gable", "Hip", "Shed"]  # only Flat commits (VS scope)

# Tuning knobs (design/gdd/building-system.md Tuning Knobs)
const DEFAULT_WALL_HEIGHT := 3
const MIN_WALL_HEIGHT := 1
const MAX_WALL_HEIGHT := 8
const DRAG_THRESHOLD_PX := 6.0
const MAX_CELLS_PER_COMMAND := 512
const PREVIEW_DEGRADATION_THRESHOLD := 128
const UNDO_STACK_DEPTH := 50
const CORNER_POOL_SIZE := 8

# Boundary-face mesh data (flush cell_size=1.0, cell = integer MIN corner; mirrors
# voxel_world's face-culled mesher convention: emit a face only where the 6-neighbor
# is absent). Each face's 4 corners are wound CCW as seen from outside along its
# direction, matching Godot's front-face/CULL_BACK convention (verified via cross
# product per face during authoring -- see building-system.md ghost rendering fix).
const _FACE_DIRS: Array[Vector3i] = [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0), Vector3i(0, -1, 0),
	Vector3i(0, 0, 1), Vector3i(0, 0, -1),
]
const _FACE_VERTS: Array = [
	[Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1)],  # +X
	[Vector3(0, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0)],  # -X
	[Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)],  # +Y
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)],  # -Y
	[Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1)],  # +Z
	[Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 0, 0)],  # -Z
]
# Same 4 local UV corners for every face (0,0)-(1,1) in TILE space, later remapped
# into the atlas sub-rect for that cell's value (_build_ghost_mesh). Order matches
# _FACE_VERTS' per-face winding; a slice-pragmatic simplification vs. voxel_world's
# per-direction UV orientation -- fine for a translucent preview, not the final build.
const _QUAD_UV: Array[Vector2] = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]

# Ghost tint (baked into vertex colors, multiplies the atlas texture underneath --
# see design/gdd/building-system.md Visual Requirements + the textured-ghost fix).
const GHOST_TINT_NEUTRAL := Color(0.85, 0.92, 1.0, 0.55)  # valid drag/single-cell tool preview
const GHOST_TINT_INVALID := Color(1.0, 0.6, 0.25, 0.6)    # invalid drag/single-cell preview subset
# VISIBILITY PACKAGE (2026-07-23, task 1b): bumped 0.30/0.45 -> 0.50/0.70 --
# full block texture reads MUCH clearer at these alphas; the dig-order tint
# pair is gone entirely (dig/demolition cells now render via the overlay
# marker box below instead of a tinted textured ghost -- task 1d).
const GHOST_TINT_DRAFT := Color(0.85, 0.92, 1.0, 0.50)    # draft blueprint cells -- not yet released
const GHOST_TINT_RELEASED := Color(0.85, 0.92, 1.0, 0.70) # released-but-unbuilt blueprint cells

# VISIBILITY PACKAGE (2026-07-23, task 1d): REPLACE/DIG overlay marker -- a
# slightly inflated, untextured translucent box on the AFFECTED TERRAIN CELL
# itself, orange for a Floor-tool terrain-replace, red for a dig/demolition.
# Alpha mirrors the draft/released split above (0.5/0.7). This REPLACES the
# old flat-tinted dig ghost mesh entirely (dig cells no longer get a textured
# ghost at all -- the overlay is their only visual, see task 1d note).
const OVERLAY_SCALE := 1.06
const OVERLAY_TINT_REPLACE_DRAFT := Color(1.0, 0.55, 0.15, 0.5)
const OVERLAY_TINT_REPLACE_RELEASED := Color(1.0, 0.55, 0.15, 0.7)
const OVERLAY_TINT_DIG_DRAFT := Color(0.8, 0.18, 0.15, 0.5)
const OVERLAY_TINT_DIG_RELEASED := Color(0.8, 0.18, 0.15, 0.7)

signal tool_changed(tool_id: int)
signal palette_changed(material_id: String)
signal wall_height_changed(h: int)
signal formation_changed(name: String)
signal undo_state_changed(can_undo: bool, can_redo: bool)
signal invalid_commit(world_pos: Vector3, reason: String)
signal construction_completed(cells: Array)
signal cells_removed(cells: Array)
signal blueprint_changed()
signal furniture_placed(cell: Vector3i, item_id: String)
signal furniture_removed(cell: Vector3i, item_id: String)
# CONTRACT ADDITION (FEATURE 1, this task): build/editor mode gate -- tools may
# only be armed while true; see set_build_mode()/get_build_mode(). Flagged for
# CONTRACTS.md update.
signal build_mode_changed(active: bool)
# CONTRACT ADDITION (2026-07-22, build projects): fires whenever a project is
# created, merged, renamed-by-merge, changes state, gains/loses a claim, or is
# cancelled -- HUD's projects panel does a full rebuild on this.
signal projects_changed()
# CONTRACT ADDITION (2026-07-23, persistent projects + click selection): fires
# whenever the selected project changes (id:int or null on deselect).
signal project_selected(id: Variant)

# --- Private state ---
var _voxel_world: Node3D
var _camera_input: Node3D
var _hud: CanvasLayer

var _tool: int = Tool.NONE
var _build_mode: bool = false  # FEATURE 1: tools may only arm while this is true
var _wall_height: int = DEFAULT_WALL_HEIGHT
var _formation_index: int = 0
var _material_index: int = 0

var _materials: Array = []       # ResourceItemDatabase.ItemDef, category "building_material"
var _furniture_items: Array = [] # ResourceItemDatabase.ItemDef, category "furniture_fixture"

# blueprint cell record: Vector3i -> {item_id: String, progress_ticks: int, claimed_by: int, needs_support: bool, project_id: int}
var _blueprint: Dictionary = {}
var _furniture_cells: Dictionary = {}  # Vector3i -> item_id (BUILT furniture only)

# Build projects (2026-07-22): id:int -> {id, name, state:ProjectState, all_cells:
# Dictionary(Vector3i->true, EVERY cell ever committed to this project, built or
# not -- the total_cells count), built_cells: Dictionary(Vector3i->true, subset of
# all_cells already written to voxel_world), claims: Dictionary(Vector3i->int
# villager_id, currently-claimed UNBUILT cells), restore_values: Dictionary
# (Vector3i->int, pre-existing value captured at commit time -- survives past the
# cell's blueprint entry being erased on completion, needed by cancel_project).
var _projects: Dictionary = {}
var _next_project_id: int = 1
var _cell_project: Dictionary = {}  # Vector3i -> project_id; reverse index, single source of truth for "who owns this cell"
# CLICK SELECTION (2026-07-23): int project id, or null when nothing selected.
var _selected_project_id: Variant = null

var _undo_stack: Array = []  # [{cells: Array[Vector3i], item_id: String, is_furniture: bool}]
var _redo_stack: Array = []

var _occupancy_provider: Callable = Callable()  # cb(cell: Vector3i) -> bool ; extra API, see summary
var _tick_count: int = 0  # reserved for future watchdog/unreachable-retry use (not implemented in slice)

# ANTI-STUCK, FEATURE 2 (2026-07-23): injected so report_on_site can simulate
# "would this write seal its builder in" without BuildingSystem tracking
# villager positions itself -- same injection pattern BuildValidation already
# uses for VillagerAI's static movement-graph predicates.
var _villager_ai_script: GDScript = null
var _position_provider: Callable = Callable()  # cb(villager_id: int) -> Variant (Vector3i or null)

var _pending_completions: Array[Dictionary] = []  # {cell, value, item_id, is_furniture} awaiting frame flush

# Pick / drag state
var _last_hit: Dictionary = {}
var _last_hit_valid: bool = false
var _is_pressed: bool = false
var _is_drag_active: bool = false
var _press_screen_pos: Vector2 = Vector2.ZERO
var _drag_start_cell: Vector3i = Vector3i.ZERO
var _drag_current_cell: Vector3i = Vector3i.ZERO
var _drag_plane_y: int = 0
var _drag_item_id: String = ""
var _drag_floor_replace: bool = false  # FEATURE 3: drag started on a terrain top surface

# FEATURE 1/2 (2026-07-22): removal-tool press/drag state -- Block tool +
# Ctrl. A box between start/current cell (axis-aligned, any of the 3 axes)
# is the "drag rect" the task spec calls for; a plain click is just a 1-cell
# box. Kept separate from _is_pressed/_is_drag_active (the WALL/FLOOR/ROOF
# build-drag state) since the removal tool's press handler runs its own path.
var _is_erase_pressed: bool = false
var _erase_drag_active: bool = false
var _erase_press_screen_pos: Vector2 = Vector2.ZERO
var _erase_start_cell: Vector3i = Vector3i.ZERO
var _erase_current_cell: Vector3i = Vector3i.ZERO

# Ghost rendering: merged, face-culled, TEXTURED meshes (real block tile per cell,
# translucent) -- one surface per tint, not per cell. Texture source: voxel_world's
# atlas (see get_atlas() addition, building_system.gd write-up).
var _atlas_texture: Texture2D
var _atlas_uv_rect: Callable = Callable()  # (cell_value: int) -> Rect2
var _mat_ghost_valid: StandardMaterial3D    # blueprint meshes + valid drag/single-cell preview
var _mat_ghost_invalid: StandardMaterial3D  # invalid drag/single-cell preview subset
# FEATURE 2: blueprint ghosts split into two meshes (tint carries per-vertex, so
# both share _mat_ghost_valid) -- draft cells render dimmer, released-but-unbuilt
# cells render stronger so the player can see which cells will start construction.
var _blueprint_draft_mesh_instance: MeshInstance3D
var _blueprint_released_mesh_instance: MeshInstance3D
# VISIBILITY PACKAGE (2026-07-23, task 1d): untextured overlay-marker material
# + 4 mesh instances (dig draft/released, replace draft/released) -- see
# _build_overlay_mesh/_refresh_overlay_mesh. Replaces the old dig-only tinted
# ghost mesh pair entirely.
var _mat_overlay: StandardMaterial3D
var _overlay_dig_draft_mesh_instance: MeshInstance3D
var _overlay_dig_released_mesh_instance: MeshInstance3D
var _overlay_replace_draft_mesh_instance: MeshInstance3D
var _overlay_replace_released_mesh_instance: MeshInstance3D
var _preview_valid_mesh: MeshInstance3D
var _preview_invalid_mesh: MeshInstance3D

# Corner-marker degrade path only (>128-cell drags) -- still small boxes, still pooled
var _box_mesh: BoxMesh
var _mat_valid: StandardMaterial3D
var _mat_invalid: StandardMaterial3D
var _corner_pool: Array[MeshInstance3D] = []

# FEATURE 1 (2026-07-22): hover highlight (wireframe target-cell box + brighter
# hit-face quad) and the 9x9 build-grid overlay. Reuses the SAME per-frame pick
# in _update_pick — no extra raycast.
var _mat_highlight_box: StandardMaterial3D
var _highlight_box_instance: MeshInstance3D
var _mat_highlight_face: StandardMaterial3D
var _highlight_face_instance: MeshInstance3D
var _mat_build_grid: StandardMaterial3D
var _build_grid_instance: MeshInstance3D
var _last_grid_column: Vector2i = Vector2i(999999, 999999)  # forces a rebuild on first hover

# CLICK SELECTION (2026-07-23): world-space wireframe outline around the
# selected project's cell-set bounding box. Independent of build mode/tool --
# selection is always-on per task spec.
var _mat_selection_box: StandardMaterial3D
var _selection_box_instance: MeshInstance3D

func _process(_delta: float) -> void:
	if _voxel_world == null or _camera_input == null:
		return
	if _tool != Tool.NONE and not (_hud != null and _hud.is_hover_suppressing()):
		_update_pick()
	else:
		_last_hit_valid = false
		_hide_all_ghosts()
	_flush_batched_signals()

## Wires the system to its three dependencies and builds the ghost pools. Call once at boot.
func setup(voxel_world: Node3D, camera_input: Node3D, hud: CanvasLayer) -> void:
	_voxel_world = voxel_world
	_camera_input = camera_input
	_hud = hud
	_materials = ResourceItemDatabase.list_by_category("building_material")
	_furniture_items = ResourceItemDatabase.list_by_category("furniture_fixture")
	_build_ghost_visuals()
	_build_highlight_visuals()
	_build_selection_visuals()
	_camera_input.action_fired.connect(_on_action_fired)
	_camera_input.build_click.connect(_on_build_click)
	TimeTickSystem.tick.connect(_on_tick)
	blueprint_changed.connect(_on_blueprint_changed)
	projects_changed.connect(_refresh_selection_visual)
	if not _materials.is_empty():
		var item: ResourceItemDatabase.ItemDef = _materials[_material_index]
		palette_changed.emit(item.id)
	wall_height_changed.emit(_wall_height)
	formation_changed.emit(FORMATIONS[_formation_index])
	tool_changed.emit(_tool)
	build_mode_changed.emit(_build_mode)
	_emit_undo_state()

## Currently armed tool (see Tool enum; 0 = None).
func get_active_tool() -> int:
	return _tool

## True while any tool other than None is armed.
func is_tool_armed() -> bool:
	return _tool != Tool.NONE

## True while build/editor mode is active (FEATURE 1). Tools may only be armed
## while this is true; arming a tool while false auto-enables it (see _set_tool).
func get_build_mode() -> bool:
	return _build_mode

## Enables/disables build/editor mode. Disabling aborts any in-progress drag,
## disarms the current tool, and hides all ghosts. Enabling alone does not arm
## a tool (the toolbar stays available for the player to pick one).
func set_build_mode(active: bool) -> void:
	if _build_mode == active:
		return
	_build_mode = active
	if not active:
		if _is_pressed:
			_abort_drag()
		if _is_erase_pressed:
			_abort_erase_drag()
		if _tool != Tool.NONE:
			_tool = Tool.NONE
			tool_changed.emit(_tool)
		_hide_all_ghosts()
	build_mode_changed.emit(_build_mode)

## Thin compat wrapper (build-projects upgrade, 2026-07-22): releases EVERY
## DRAFT-state project (see release_project()) and returns the total cell
## count released. No-op (returns 0) if there are no draft projects.
func release_drafts() -> int:
	var draft_ids: Array = []
	var count: int = 0
	for id in _projects.keys():
		var p: Dictionary = _projects[id]
		if int(p["state"]) == ProjectState.DRAFT:
			draft_ids.append(id)
			count += p["all_cells"].size()
	for id in draft_ids:
		release_project(id)
	return count

## FEATURE 2: number of blueprint cells still in DRAFT state (not yet released).
func get_draft_count() -> int:
	var count: int = 0
	for entry in _blueprint.values():
		if bool(entry.get("draft", false)):
			count += 1
	return count

## Combined Planned + UnderConstruction blueprint set. Returns a deep copy (safe to read, not to mutate).
func get_blueprint_cells() -> Dictionary:
	return _blueprint.duplicate(true)

## FIFO-by-commit-order claim of the next open cell whose support (if any) is already Built.
## Only serves cells belonging to a BUILDING-state project (build projects, 2026-07-22) --
## DRAFT/PAUSED/DONE projects never hand out new claims. Returns the claimed
## Vector3i cell, or null if nothing is claimable right now.
func claim_job(villager_id: int) -> Variant:
	for cell in _blueprint.keys():
		var entry: Dictionary = _blueprint[cell]
		if bool(entry.get("draft", false)):
			continue  # FEATURE 2: drafts are not yet released for construction
		if int(entry["claimed_by"]) != 0 or bool(entry.get("ready", false)):
			continue
		var project_id: int = int(entry.get("project_id", -1))
		if project_id != -1 and _projects.has(project_id) and int(_projects[project_id]["state"]) != ProjectState.BUILDING:
			continue  # PAUSED (no new claims) / DONE / (DRAFT already caught above)
		if bool(entry["needs_support"]):
			var support_cell: Vector3i = cell + Vector3i(0, -1, 0)
			if _voxel_world.get_cell(support_cell) == AIR:
				continue  # support not yet Built -- skip, do not block the FIFO scan
		entry["claimed_by"] = villager_id
		if project_id != -1 and _projects.has(project_id):
			_projects[project_id]["claims"][cell] = villager_id
		return cell
	return null

## Releases a claim without canceling the blueprint cell (banked progress is kept).
func release_job(cell: Vector3i) -> void:
	if not _blueprint.has(cell):
		return
	var entry: Dictionary = _blueprint[cell]
	entry["claimed_by"] = 0
	var project_id: int = int(entry.get("project_id", -1))
	if project_id != -1 and _projects.has(project_id):
		_projects[project_id]["claims"].erase(cell)

## Called by the villager once per tick while it is on site. Advances progress; on completion
## queues the cell for this frame's batched construction_completed flush (deferred if occupied).
func report_on_site(cell: Vector3i) -> void:
	if not _blueprint.has(cell):
		return
	var entry: Dictionary = _blueprint[cell]
	var is_dig: bool = bool(entry.get("dig", false))
	if not is_dig and bool(entry["needs_support"]):
		var support_cell: Vector3i = cell + Vector3i(0, -1, 0)
		if _voxel_world.get_cell(support_cell) == AIR:
			return  # TR-building-system-050: construction cannot start until support is Built
	var build_ticks: int
	var write_value: int = AIR
	var write_item_id: String = ""
	var is_demolition: bool = bool(entry.get("demolition", false))
	if is_dig:
		# FEATURE 2: dig orders have no material/def -- fixed duration.
		# A plain terrain dig always completes to AIR (removed, not replaced).
		# A DEMOLITION (task 3b, "a demolition is a dig on a built cell")
		# instead completes to the project's captured restore_value, honoring
		# a Floor-tool terrain-replace cell's original ground.
		build_ticks = DIG_BUILD_TICKS
		if is_demolition:
			write_value = int(entry.get("restore_value", AIR))
	else:
		var def: ResourceItemDatabase.ItemDef = ResourceItemDatabase.get_by_id(String(entry["item_id"]))
		if def == null:
			return
		build_ticks = def.build_ticks
		write_value = def.cell_value
		write_item_id = def.id
	entry["progress_ticks"] = int(entry["progress_ticks"]) + 1
	if int(entry["progress_ticks"]) < build_ticks:
		return
	if bool(entry.get("ready", false)):
		return  # already queued for write; the flush owns it now
	# ANTI-STUCK FEATURE 2 ("don't seal your last exit"): a non-dig completion
	# never gets to wall off its own claiming villager's last exit -- release
	# the claim back to the queue instead (banked progress_ticks is kept, so
	# whoever claims next resumes right at the completion threshold).
	# is_job_claimed_by lets VillagerAI notice the silent release and go find
	# different work. Digs/demolitions FREE a cell, so they can never seal
	# anyone in and are exempt.
	if not is_dig:
		var claimer: int = int(entry.get("claimed_by", 0))
		if claimer != 0 and _should_prevent_seal(cell, write_value, claimer, entry):
			release_job(cell)
			return
	# Blueprint entry SURVIVES until the write actually lands (the flush
	# re-checks occupancy at write time and erases on success) — so
	# get_blueprint_cells() == empty always means "fully built".
	entry["ready"] = true
	_pending_completions.append({
		"cell": cell,
		"value": write_value,
		"item_id": write_item_id,
		"is_furniture": bool(entry["needs_support"]),
		"is_dig": is_dig,
		"is_demolition": is_demolition,
	})

## ANTI-STUCK FEATURE 2 livelock guard: the SAME villager re-claiming/
## re-abandoning the SAME cell is allowed through after
## SEAL_ABANDON_LIVELOCK_LIMIT refused attempts (the unstuck watchdog rescues
## it afterwards if it truly sealed itself) -- keeps a single trapped-looking
## villager from parking a job forever. Counter lives on the blueprint entry
## itself so it survives the claimed_by resets a release causes.
func _should_prevent_seal(cell: Vector3i, write_value: int, claimer: int, entry: Dictionary) -> bool:
	var prior_villager: int = int(entry.get("seal_abandon_villager", 0))
	var prior_count: int = int(entry.get("seal_abandon_count", 0)) if prior_villager == claimer else 0
	if prior_count >= SEAL_ABANDON_LIVELOCK_LIMIT:
		entry["seal_abandon_villager"] = 0
		entry["seal_abandon_count"] = 0
		return false
	if not _would_seal_builder(cell, write_value, claimer):
		return false
	entry["seal_abandon_villager"] = claimer
	entry["seal_abandon_count"] = prior_count + 1
	return true

## ANTI-STUCK FEATURE 2: true if writing `write_value` into `write_cell` would
## leave `villager_id` with zero legal steps from its OWN current cell. Fails
## OPEN (returns false, i.e. never blocks completion) if the villager script/
## position provider isn't wired, the villager's position is unknown, or the
## villager somehow already occupies the write cell itself (shouldn't happen
## -- the on-site rules never let a builder stand in its own target cell).
func _would_seal_builder(write_cell: Vector3i, write_value: int, villager_id: int) -> bool:
	if _villager_ai_script == null or not _position_provider.is_valid():
		return false
	var builder_variant: Variant = _position_provider.call(villager_id)
	if not (builder_variant is Vector3i):
		return false
	var builder_cell: Vector3i = builder_variant
	if builder_cell == write_cell:
		return false
	return not _villager_ai_script.has_escape_after_write(_voxel_world, builder_cell, write_cell, write_value)

## Combined Voxel World blocks + blueprint view (TR-building-system-060).
func is_cell_occupied_planned(cell: Vector3i) -> bool:
	if _blueprint.has(cell):
		return true
	return _voxel_world.get_cell(cell) != AIR

## BUILT furniture only (Vector3i -> item_id). Returns a deep copy.
func get_furniture_cells() -> Dictionary:
	return _furniture_cells.duplicate(true)

# --- Click selection (2026-07-23) ---

## The project owning `cell`, if any -- built OR still-blueprint (draft/
## released/demolition) cells are all covered, since _cell_project is
## populated the instant a cell is committed, long before it's built. Returns
## null if `cell` belongs to no tracked project.
func get_project_at_cell(cell: Vector3i) -> Variant:
	if not _cell_project.has(cell):
		return null
	return int(_cell_project[cell])

## Selects a project (drives the HUD panel card highlight + the world
## wireframe outline). Passing an id that doesn't exist (or null) deselects.
func select_project(id: Variant) -> void:
	if id != null and not _projects.has(int(id)):
		id = null
	if _selected_project_id == id:
		return
	_selected_project_id = id
	project_selected.emit(_selected_project_id)
	_refresh_selection_visual()

## Currently selected project id, or null.
func get_selected_project() -> Variant:
	return _selected_project_id

## Convenience for click-on-empty-ground / Esc.
func deselect_project() -> void:
	select_project(null)

# --- Build projects (2026-07-22) ---

## Array of project-info Dictionaries: id, name, state:int (ProjectState),
## state_label:String, total_cells, built_cells, worker_ids:Array[int]
## (currently-claiming villagers, deduped). Sorted by id (creation order).
func get_projects() -> Array:
	var out: Array = []
	for id in _projects.keys():
		var p: Dictionary = _projects[id]
		var worker_ids: Array[int] = []
		var seen: Dictionary = {}
		for wid in p["claims"].values():
			var w: int = int(wid)
			if not seen.has(w):
				seen[w] = true
				worker_ids.append(w)
		# CHANGE ORDERS (2026-07-23, task 3a): pending draft entries can now
		# exist on a project regardless of its own top-level state (a DONE/
		# BUILDING/PAUSED project can have newly-attached change-order drafts
		# awaiting release) -- surfaced here so the HUD can show "Aenderungen
		# geplant" + a release button instead of silently hiding them.
		var draft_cells: int = 0
		for entry in _blueprint.values():
			if int(entry.get("project_id", -1)) == id and bool(entry.get("draft", false)):
				draft_cells += 1
		out.append({
			"id": id,
			"name": p["name"],
			"state": int(p["state"]),
			"state_label": String(PROJECT_STATE_LABELS.get(int(p["state"]), "?")),
			"total_cells": p["all_cells"].size(),
			"built_cells": p["built_cells"].size(),
			"worker_ids": worker_ids,
			"draft_cells": draft_cells,
			"demolishing": bool(p.get("demolishing", false)),
		})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["id"]) < int(b["id"]))
	return out

## Releases every still-DRAFT blueprint entry owned by this project so
## claim_job() can serve them. Generalized (2026-07-23, task 3a change orders)
## beyond DRAFT-state projects: a DONE/BUILDING/PAUSED project can have
## pending change-order drafts attached (see _assign_project) -- releasing
## those bumps a DONE project back to BUILDING (until complete, then DONE
## again); a BUILDING/PAUSED project's own state is left alone (PAUSED stays
## PAUSED -- claim_job's pause gate still blocks new claims regardless of the
## per-cell draft flag). No-op if there is nothing to release.
func release_project(id: int) -> void:
	if not _projects.has(id):
		return
	var p: Dictionary = _projects[id]
	var released_any: bool = false
	for cell in _blueprint.keys():
		var entry: Dictionary = _blueprint[cell]
		if int(entry.get("project_id", -1)) == id and bool(entry.get("draft", false)):
			entry["draft"] = false
			released_any = true
	if not released_any:
		return
	var state: int = int(p["state"])
	if state == ProjectState.DRAFT or state == ProjectState.DONE:
		p["state"] = ProjectState.BUILDING
	blueprint_changed.emit()
	projects_changed.emit()

## BUILDING -> PAUSED: no NEW claims are handed out (claim_job gates on project
## state). A job a villager ALREADY claimed before the pause is allowed to
## finish -- report_on_site/the completion flush don't check project state,
## only claim_job does. This matches Stonehearth's "let them finish the plank
## in their hands" feel and avoids yanking a villager mid-swing.
func pause_project(id: int) -> void:
	if not _projects.has(id):
		return
	var p: Dictionary = _projects[id]
	if int(p["state"]) != ProjectState.BUILDING:
		return
	p["state"] = ProjectState.PAUSED
	projects_changed.emit()

## PAUSED -> BUILDING: claim_job may resume handing out this project's cells.
func resume_project(id: int) -> void:
	if not _projects.has(id):
		return
	var p: Dictionary = _projects[id]
	if int(p["state"]) != ProjectState.PAUSED:
		return
	p["state"] = ProjectState.BUILDING
	projects_changed.emit()

## "Alles ueber Auftraege" (2026-07-23, task 3c, user decision): cancel/Abriss
## is no longer an instant world write. Any still-UNBUILT blueprint entry
## (draft or released -- nothing built yet, so nothing to tear down) is
## discarded instantly, since a plan is free. Every already-BUILT cell instead
## becomes a RELEASED demolition order -- workers tear it down block by block
## through the normal job pipeline (see _create_demolition_entry /
## _flush_batched_signals). The project is marked "demolishing" (surfaced via
## get_projects()) and reaches its terminal removed state -- simply dropped
## from _projects, per _untrack_cell -- only once every one of its cells is
## actually gone (built cells shrink out as their demolition job completes;
## see 3b/3c). Emits blueprint_changed/projects_changed immediately; further
## cells_removed/furniture_removed emissions land later, per completed
## demolition job, exactly like any other build/dig completion.
func cancel_project(id: int) -> void:
	if not _projects.has(id):
		return
	var p: Dictionary = _projects[id]
	var all_cells: Array = p["all_cells"].keys()
	for cell: Vector3i in all_cells:
		if p["built_cells"].has(cell):
			if not _blueprint.has(cell):
				_create_demolition_entry(cell, id, true)  # released immediately -- no manual start step
			else:
				_blueprint[cell]["draft"] = false
			p["demolishing"] = true
		else:
			if _blueprint.has(cell):
				_blueprint.erase(cell)
			_untrack_cell(cell)
	blueprint_changed.emit()
	projects_changed.emit()

## Extra API (not in CONTRACTS.md) -- see write-up: lets VillagerAI report whether a character
## currently occupies a cell, so construction can defer per Edge Case 6 / TR-building-system-037.
func set_occupancy_provider(cb: Callable) -> void:
	_occupancy_provider = cb

## Extra API (not in CONTRACTS.md) -- ANTI-STUCK FEATURE 2 (2026-07-23):
## injects VillagerAI's script so the seal-prevention check can call its
## static is_standable/is_step_legal/has_escape_after_write helpers (same
## injection pattern BuildValidation already uses).
func set_villager_ai_script(script: GDScript) -> void:
	_villager_ai_script = script

## Extra API (not in CONTRACTS.md) -- ANTI-STUCK FEATURE 2: cb(villager_id:
## int) -> Variant (Vector3i or null); lets the seal-prevention check find a
## claiming villager's current cell without BuildingSystem tracking positions
## itself.
func set_position_provider(cb: Callable) -> void:
	_position_provider = cb

## ANTI-STUCK FEATURE 2: true while `cell`'s blueprint entry is currently
## claimed by exactly `villager_id`. Lets VillagerAI detect a claim that was
## silently released out from under it (e.g. by the seal-prevention check in
## report_on_site) without changing report_on_site's CONTRACTS.md signature.
func is_job_claimed_by(cell: Vector3i, villager_id: int) -> bool:
	if not _blueprint.has(cell):
		return false
	return int(_blueprint[cell].get("claimed_by", 0)) == villager_id

# --- Input routing ---

func _on_action_fired(action_name: String) -> void:
	match action_name:
		"tool_select_1":
			_set_tool(Tool.WALL)
		"tool_select_2":
			_set_tool(Tool.FLOOR)
		"tool_select_3":
			_set_tool(Tool.ROOF)
		"tool_select_4":
			_set_tool(Tool.BLOCK)
		"tool_select_5":
			_set_tool(Tool.FURNITURE)
		"build_cancel":
			_on_cancel()
		"undo":
			_undo()
		"redo":
			_redo()
		"height_step_up":
			_set_wall_height(_wall_height + 1)
		"height_step_down":
			_set_wall_height(_wall_height - 1)
		"palette_next":
			_cycle_palette(1)
		"palette_prev":
			_cycle_palette(-1)
		"formation_next":
			_cycle_formation(1)
		"formation_prev":
			_cycle_formation(-1)
		_:
			pass

func _on_build_click(pressed: bool) -> void:
	if pressed:
		_on_press()
	else:
		_on_release()

func _on_tick() -> void:
	_tick_count += 1  # reserved; construction progress itself is driven by report_on_site calls

func _on_blueprint_changed() -> void:
	_refresh_blueprint_ghosts()

# --- Tool / mode state machine ---

func _set_tool(t: int) -> void:
	# FEATURE 1: arming any tool while build mode is off auto-enables it.
	if t != Tool.NONE and not _build_mode:
		_build_mode = true
		build_mode_changed.emit(true)
	if _tool == t:
		return
	if _is_pressed:
		_abort_drag()
	if _is_erase_pressed:
		_abort_erase_drag()
	_tool = t
	_hide_all_ghosts()
	tool_changed.emit(_tool)

func _on_cancel() -> void:
	# Heal stale press state (a release can be lost to HUD consumption or
	# synthetic input): only treat as drag-abort if LMB is REALLY down.
	if _is_pressed and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_is_pressed = false
	if _is_erase_pressed and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_is_erase_pressed = false
	if _is_pressed:
		_abort_drag()
		return
	if _is_erase_pressed:
		_abort_erase_drag()
		return
	if _tool != Tool.NONE:
		_tool = Tool.NONE
		_hide_all_ghosts()
		tool_changed.emit(_tool)
		return
	# CLICK SELECTION (2026-07-23, task 2b): deselect BEFORE exiting build mode.
	if _selected_project_id != null:
		select_project(null)
		return
	# FEATURE 1 Esc chain extension: no tool armed but build mode still on ->
	# exit build mode (the toolbar/context panel closes on the next Esc).
	if _build_mode:
		set_build_mode(false)

func _abort_drag() -> void:
	_is_pressed = false
	_is_drag_active = false
	_hide_all_ghosts()

func _abort_erase_drag() -> void:
	_is_erase_pressed = false
	_erase_drag_active = false
	_hide_all_ghosts()

func _set_wall_height(h: int) -> void:
	var clamped: int = clampi(h, MIN_WALL_HEIGHT, MAX_WALL_HEIGHT)
	if clamped == _wall_height:
		return
	_wall_height = clamped
	wall_height_changed.emit(_wall_height)

func _cycle_palette(direction: int) -> void:
	if _materials.is_empty():
		return
	_material_index = wrapi(_material_index + direction, 0, _materials.size())
	var item: ResourceItemDatabase.ItemDef = _materials[_material_index]
	palette_changed.emit(item.id)

func _cycle_formation(direction: int) -> void:
	_formation_index = wrapi(_formation_index + direction, 0, FORMATIONS.size())
	formation_changed.emit(FORMATIONS[_formation_index])

func select_material(item_id: String) -> void:
	for i in _materials.size():
		if _materials[i].id == item_id:
			_material_index = i
			palette_changed.emit(item_id)
			return

func set_formation(formation_name: String) -> void:
	var idx: int = FORMATIONS.find(formation_name)
	if idx >= 0:
		_formation_index = idx
		formation_changed.emit(formation_name)

func _current_material() -> ResourceItemDatabase.ItemDef:
	if _materials.is_empty():
		return null
	return _materials[_material_index]

func _current_furniture() -> ResourceItemDatabase.ItemDef:
	if _furniture_items.is_empty():
		return null
	return _furniture_items[0]

# --- Per-frame pick + preview ---

func _update_pick() -> void:
	var ray: Dictionary = _camera_input.get_world_ray()
	# FEATURE 3 (ghost snapping): while build mode is active, the pick ray also
	# stops at blueprint cells (any state, but NOT dig-orders -- those are
	# holes-to-be) as if they were solid, so a new drag can anchor/stack on a
	# drafted wall/floor before it's actually built.
	var extra_solid: Callable = Callable(self, "_is_blueprint_solid_for_pick") if _build_mode else Callable()
	var hit: Dictionary = _voxel_world.raycast_cells(ray.origin, ray.dir, 200.0, extra_solid)
	if hit.is_empty():
		_last_hit_valid = false
		_hide_all_ghosts()
		return
	_last_hit_valid = true
	_last_hit = hit
	_update_highlight(hit)   # FEATURE 1: reuses this same pick, no extra raycast
	match _tool:
		Tool.BLOCK:
			_update_block_ghost(hit)
		Tool.FURNITURE:
			_update_furniture_ghost(hit)
		Tool.WALL, Tool.FLOOR, Tool.ROOF, Tool.ROOM:
			if _is_pressed:
				_update_drag_shape(hit)
			else:
				_update_single_cell_preview(hit)
		Tool.HOUSE:
			_update_house_ghost(hit)
		Tool.ROOF_AUTO:
			pass  # click-only tool -- the shared hover highlight is enough feedback

func _update_block_ghost(hit: Dictionary) -> void:
	_hide_corner_pool()
	if _camera_input.remove_modifier_held:
		if _is_erase_pressed:
			_update_erase_drag_preview(hit)
			return
		var cell: Vector3i = hit.cell
		# FEATURE 1/2: the removal tool now also erases draft blueprint cells
		# and queues terrain dig orders, not just built cells -- see _is_erasable_cell.
		var valid: bool = _is_erasable_cell(cell)
		# Removal preview textures with the REAL existing block/terrain, not a selection.
		_render_tool_preview([cell] if valid else [], [] if valid else [cell], _erase_preview_value(cell))
	else:
		var target: Vector3i = hit.cell + hit.normal
		var item: ResourceItemDatabase.ItemDef = _current_material()
		var valid2: bool = item != null and _is_cell_valid_for_commit(target, false)
		var value: int = item.cell_value if item != null else 0
		_render_tool_preview([target] if valid2 else [], [] if valid2 else [target], value)

func _update_furniture_ghost(hit: Dictionary) -> void:
	_hide_corner_pool()
	var target: Vector3i = hit.cell + hit.normal
	var item: ResourceItemDatabase.ItemDef = _current_furniture()
	var valid: bool = item != null and _is_cell_valid_for_commit(target, true)
	var value: int = item.cell_value if item != null else 0
	_render_tool_preview([target] if valid else [], [] if valid else [target], value)

func _update_single_cell_preview(hit: Dictionary) -> void:
	var target: Vector3i = hit.cell + hit.normal
	_drag_floor_replace = false
	if _tool == Tool.FLOOR and _is_terrain_top_surface(hit):
		# FEATURE 3: floor picked on a terrain top surface digs INTO that plane
		# instead of sitting one cell above it (Stonehearth flush floors).
		target = hit.cell
		_drag_floor_replace = true
	var cells: Array[Vector3i] = _rasterize_for_tool(_tool, target, target, target.y)
	var item: ResourceItemDatabase.ItemDef = _current_material()
	_render_drag_ghosts(cells, item.cell_value if item != null else 0)

func _update_drag_shape(hit: Dictionary) -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	if not _is_drag_active and mouse_pos.distance_to(_press_screen_pos) >= DRAG_THRESHOLD_PX:
		_is_drag_active = true
	var current_cell: Vector3i = hit.cell + hit.normal
	_drag_current_cell = current_cell
	var end_cell: Vector3i = current_cell if _is_drag_active else _drag_start_cell
	var raw_cells: Array[Vector3i] = _rasterize_for_tool(_tool, _drag_start_cell, end_cell, _drag_plane_y)
	var clipped: Array[Vector3i] = []
	for c in raw_cells:
		if _voxel_world.is_in_region(c):
			clipped.append(c)
	# Material is LOCKED at drag-press (_drag_item_id), not re-read live, so a
	# palette change mid-drag doesn't retexture an in-progress preview.
	var locked_item: ResourceItemDatabase.ItemDef = ResourceItemDatabase.get_by_id(_drag_item_id)
	_render_drag_ghosts(clipped, locked_item.cell_value if locked_item != null else 0)

## FEATURE 3: true when a pick hit a raw terrain cell (value 1..4) on its top
## face (+Y normal) -- the surface the Floor tool digs into rather than
## building one cell above.
func _is_terrain_top_surface(hit: Dictionary) -> bool:
	var value: int = _voxel_world.get_cell(hit.cell)
	return value >= TERRAIN_MIN_VALUE and value <= TERRAIN_MAX_VALUE and hit.normal == Vector3i(0, 1, 0)

## FEATURE 3: extra-solid predicate threaded into voxel_world.raycast_cells
## while build mode is active. Dig-order cells are excluded (they're going to
## become holes, not solid) -- though in practice they still sit on real
## terrain that's already solid via the normal voxel check regardless.
func _is_blueprint_solid_for_pick(cell: Vector3i) -> bool:
	var entry: Dictionary = _blueprint.get(cell, {})
	if entry.is_empty():
		return false
	return not bool(entry.get("dig", false))


# --- SLICE VIEW (2026-07-22): ghost/highlight visibility filtering ---
# Chunk terrain itself is clipped by chunk_terrain.gdshader (y_cut uniform,
# no remesh). Ghosts/previews/highlights are separate MeshInstance3D nodes
# with their own materials, so they respect the cut via a plain visibility
# rule instead: any cell above the current slice level is filtered out
# before its mesh is ever built.

func _is_cell_visible_at_slice(cell: Vector3i) -> bool:
	if _voxel_world == null:
		return true
	return cell.y <= _voxel_world.get_slice_level()

func _slice_filter_array(cells: Array) -> Array:
	var out: Array = []
	for c in cells:
		if _is_cell_visible_at_slice(c):
			out.append(c)
	return out

func _slice_filter_dict_keys(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in d.keys():
		if _is_cell_visible_at_slice(k):
			out[k] = d[k]
	return out


# --- FEATURE 1 (2026-07-22): hover highlight + build grid ---
# Both driven from the SAME per-frame pick _update_pick() already computes —
# no extra raycast added.

func _build_highlight_visuals() -> void:
	_mat_highlight_box = StandardMaterial3D.new()
	_mat_highlight_box.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_highlight_box.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_highlight_box.vertex_color_use_as_albedo = true
	_mat_highlight_box.albedo_color = Color.WHITE
	_mat_highlight_box.no_depth_test = true  # a wireframe box should read through the block it targets

	var half: float = HIGHLIGHT_BOX_SCALE * 0.5
	var corners: Array[Vector3] = [
		Vector3(-half, -half, -half), Vector3(half, -half, -half), Vector3(half, -half, half), Vector3(-half, -half, half),
		Vector3(-half, half, -half), Vector3(half, half, -half), Vector3(half, half, half), Vector3(-half, half, half),
	]
	var edge_pairs: Array = [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]]
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	for pair: Array in edge_pairs:
		verts.append(corners[pair[0]])
		verts.append(corners[pair[1]])
		colors.append(HIGHLIGHT_BOX_COLOR)
		colors.append(HIGHLIGHT_BOX_COLOR)
	var box_mesh := ArrayMesh.new()
	var box_arrays: Array = []
	box_arrays.resize(Mesh.ARRAY_MAX)
	box_arrays[Mesh.ARRAY_VERTEX] = verts
	box_arrays[Mesh.ARRAY_COLOR] = colors
	box_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, box_arrays)
	box_mesh.surface_set_material(0, _mat_highlight_box)

	_highlight_box_instance = MeshInstance3D.new()
	_highlight_box_instance.mesh = box_mesh
	_highlight_box_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_highlight_box_instance.visible = false
	add_child(_highlight_box_instance)

	_mat_highlight_face = StandardMaterial3D.new()
	_mat_highlight_face.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_highlight_face.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_highlight_face.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_highlight_face.albedo_color = HIGHLIGHT_FACE_COLOR

	_highlight_face_instance = MeshInstance3D.new()
	_highlight_face_instance.material_override = _mat_highlight_face
	_highlight_face_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_highlight_face_instance.visible = false
	add_child(_highlight_face_instance)

	_mat_build_grid = StandardMaterial3D.new()
	_mat_build_grid.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_build_grid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_build_grid.vertex_color_use_as_albedo = true
	_mat_build_grid.albedo_color = Color.WHITE

	_build_grid_instance = MeshInstance3D.new()
	_build_grid_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_build_grid_instance.visible = false
	add_child(_build_grid_instance)


## Maps the current tool + hit to the cell the click would actually affect
## (placement: hit cell + face normal; removal/dig: the hit cell itself) --
## used ONLY for the hover highlight, mirrors each tool's own press logic.
func _compute_target_cell(hit: Dictionary) -> Vector3i:
	match _tool:
		Tool.BLOCK:
			if _camera_input.remove_modifier_held:
				return hit.cell
			return hit.cell + hit.normal
		Tool.FURNITURE, Tool.WALL, Tool.ROOF, Tool.ROOM:
			return hit.cell + hit.normal
		Tool.FLOOR:
			if _is_terrain_top_surface(hit):
				return hit.cell
			return hit.cell + hit.normal
		Tool.ROOF_AUTO, Tool.HOUSE:
			return hit.cell
		_:
			return hit.cell


func _update_highlight(hit: Dictionary) -> void:
	var target: Vector3i = _compute_target_cell(hit)
	if not _is_cell_visible_at_slice(target):
		_highlight_box_instance.visible = false
		_highlight_face_instance.visible = false
	else:
		_highlight_box_instance.global_position = _cell_center(target)
		_highlight_box_instance.visible = true
		if hit.normal != Vector3i.ZERO and _is_cell_visible_at_slice(hit.cell):
			_rebuild_highlight_face_quad(hit.cell, hit.normal)
			_highlight_face_instance.visible = true
		else:
			_highlight_face_instance.visible = false

	var column := Vector2i(target.x, target.z)
	if column != _last_grid_column:
		_last_grid_column = column
		_rebuild_build_grid(target)


## Brighter quad exactly on the hit face, pushed out along the normal by a
## small epsilon to avoid z-fighting with the terrain/block surface. Reuses
## the ghost mesher's own _FACE_DIRS/_FACE_VERTS tables (already CCW-wound for
## the outward-facing convention).
func _rebuild_highlight_face_quad(cell: Vector3i, normal: Vector3i) -> void:
	var face_index: int = _FACE_DIRS.find(normal)
	if face_index == -1:
		_highlight_face_instance.visible = false
		return
	var origin: Vector3 = Vector3(cell.x, cell.y, cell.z) + Vector3(normal) * HIGHLIGHT_FACE_EPSILON
	var face_verts: Array = _FACE_VERTS[face_index]
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var n := Vector3(normal)
	for v: Vector3 in face_verts:
		verts.append(origin + v)
		normals.append(n)
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_highlight_face_instance.mesh = mesh


## BUILD GRID: translucent cell-grid overlay following terrain_height per
## column, floating BUILD_GRID_Y_OFFSET above the surface. Rebuilt only when
## the hovered cell's column changes (not every frame).
func _rebuild_build_grid(center_cell: Vector3i) -> void:
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	for dz in range(-BUILD_GRID_RADIUS, BUILD_GRID_RADIUS + 1):
		for dx in range(-BUILD_GRID_RADIUS, BUILD_GRID_RADIUS + 1):
			var gx: int = center_cell.x + dx
			var gz: int = center_cell.z + dz
			if not _is_cell_visible_at_slice(Vector3i(gx, center_cell.y, gz)):
				continue
			var h: int = _voxel_world.terrain_height(gx, gz)
			var y: float = float(h) + BUILD_GRID_Y_OFFSET
			var p0 := Vector3(gx, y, gz)
			var p1 := Vector3(gx + 1, y, gz)
			var p2 := Vector3(gx + 1, y, gz + 1)
			var p3 := Vector3(gx, y, gz + 1)
			for pair: Array in [[p0, p1], [p1, p2], [p2, p3], [p3, p0]]:
				verts.append(pair[0])
				verts.append(pair[1])
				colors.append(BUILD_GRID_COLOR)
				colors.append(BUILD_GRID_COLOR)
	if verts.is_empty():
		_build_grid_instance.visible = false
		return
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh.surface_set_material(0, _mat_build_grid)
	_build_grid_instance.mesh = mesh
	_build_grid_instance.visible = true


# --- FEATURE 4 (2026-07-22): Auto-Roof ("Dach") ---
# Click-only tool: clicking a cell belonging to ANY project that already has
# walls (draft or later) adds a flat thatch roof over that project's XZ
# bounding box, one cell above its highest cell (built or still-planned).
# Cells already occupied (blueprint or solid) are skipped.

func _handle_roof_auto_press(hit: Dictionary) -> void:
	var cell: Vector3i = hit.cell
	if not _cell_project.has(cell):
		invalid_commit.emit(_cell_center(cell), "keine Projekt-Zelle")
		return
	var project_id: int = int(_cell_project[cell])
	if not _project_has_walls(project_id):
		invalid_commit.emit(_cell_center(cell), "Projekt hat keine Waende")
		return
	if not _apply_roof_to_project(project_id):
		invalid_commit.emit(_cell_center(cell), "Dach: nichts zu bauen")


func _project_has_walls(project_id: int) -> bool:
	if not _projects.has(project_id):
		return false
	var p: Dictionary = _projects[project_id]
	for c: Vector3i in p["all_cells"].keys():
		var value: int
		if _blueprint.has(c):
			var def: ResourceItemDatabase.ItemDef = ResourceItemDatabase.get_by_id(String(_blueprint[c].get("item_id", "")))
			value = def.cell_value if def != null else AIR
		else:
			value = _voxel_world.get_cell(c)
		if _WALL_MATERIAL_VALUES.has(value):
			return true
	return false


func _project_xz_bbox(project: Dictionary) -> Dictionary:
	var cells: Array = project["all_cells"].keys()
	if cells.is_empty():
		return {}
	var first: Vector3i = cells[0]
	var x0: int = first.x
	var x1: int = first.x
	var z0: int = first.z
	var z1: int = first.z
	for c: Vector3i in cells:
		x0 = mini(x0, c.x)
		x1 = maxi(x1, c.x)
		z0 = mini(z0, c.z)
		z1 = maxi(z1, c.z)
	return {"x0": x0, "x1": x1, "z0": z0, "z1": z1}


func _project_max_cell_y(project: Dictionary) -> int:
	var max_y: int = -999999
	for c: Vector3i in project["all_cells"].keys():
		max_y = maxi(max_y, c.y)
	return max_y


## Adds a flat thatch roof over `project_id`'s XZ bounding box, one cell above
## its current highest cell. Judgment call (documented in CONTRACTS.md): if
## the project is DONE, this re-opens it (state -> BUILDING) since it once
## again has pending work; if DRAFT, the new cells join as drafts (released
## together later); if BUILDING, the new cells are added already-released
## (draft:false) so claim_job serves them immediately; if PAUSED, they're
## added released but won't be claimed until the project is resumed (matches
## existing pause semantics). Returns false if there is nothing new to roof
## (bbox fully occupied already, or the project doesn't exist).
func _apply_roof_to_project(project_id: int) -> bool:
	if not _projects.has(project_id):
		return false
	var project: Dictionary = _projects[project_id]
	var bbox: Dictionary = _project_xz_bbox(project)
	if bbox.is_empty():
		return false
	var roof_y: int = _project_max_cell_y(project) + 1
	var roof_cells: Array[Vector3i] = []
	for x in range(int(bbox["x0"]), int(bbox["x1"]) + 1):
		for z in range(int(bbox["z0"]), int(bbox["z1"]) + 1):
			var c := Vector3i(x, roof_y, z)
			if not _voxel_world.is_in_region(c):
				continue
			if _blueprint.has(c):
				continue
			if _voxel_world.get_cell(c) != AIR:
				continue
			roof_cells.append(c)
	if roof_cells.is_empty():
		return false
	var release_now: bool = int(project["state"]) == ProjectState.BUILDING or int(project["state"]) == ProjectState.DONE
	if int(project["state"]) == ProjectState.DONE:
		project["state"] = ProjectState.BUILDING
	var restore_values: Dictionary = {}
	for c: Vector3i in roof_cells:
		var restore_value: int = _voxel_world.get_cell(c)
		restore_values[c] = restore_value
		project["restore_values"][c] = restore_value
		project["all_cells"][c] = true
		_cell_project[c] = project_id
		_blueprint[c] = {
			"item_id": "thatch_block",
			"progress_ticks": 0,
			"claimed_by": 0,
			"needs_support": false,
			"draft": not release_now,
			"restore_value": restore_value,
			"project_id": project_id,
			"dig": false,
		}
	_push_command(roof_cells, "thatch_block", false, restore_values, false, project_id, false)
	blueprint_changed.emit()
	projects_changed.emit()
	return true


# --- FEATURE 5 (2026-07-22): House template ("Haus") ---
# Fixed 7x7 starter house stamp: flush floor (terrain-replace), perimeter
# walls 3 high with 1 door gap, thatch roof on top. Valid only where all 49
# columns share the same terrain_height and the volume is clear.

## Computes the full house layout anchored so the given XZ is the house's
## MIN corner (_update_house_ghost/_handle_house_press center it on the
## cursor by subtracting HOUSE_FOOTPRINT/2 first). Returns
## {"valid": bool, "h": int, "floor": Array[Vector3i], "walls": Array[Vector3i],
## "roof": Array[Vector3i], "door_col": Vector2i}; "valid" false means every
## other key is a placeholder.
func _house_layout(anchor_min: Vector2i) -> Dictionary:
	var invalid_result: Dictionary = {"valid": false, "h": 0, "floor": [], "walls": [], "roof": [], "door_col": Vector2i.ZERO}
	var x0: int = anchor_min.x
	var z0: int = anchor_min.y
	var x1: int = x0 + HOUSE_FOOTPRINT - 1
	var z1: int = z0 + HOUSE_FOOTPRINT - 1
	if not _voxel_world.is_in_region(Vector3i(x0, 0, z0)) or not _voxel_world.is_in_region(Vector3i(x1, 0, z1)):
		return invalid_result
	var h: int = _voxel_world.terrain_height(x0, z0)
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			if _voxel_world.terrain_height(x, z) != h:
				return invalid_result
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			var floor_cell := Vector3i(x, h - 1, z)
			var floor_value: int = _voxel_world.get_cell(floor_cell)
			if floor_value < TERRAIN_MIN_VALUE or floor_value > TERRAIN_MAX_VALUE:
				return invalid_result  # not plain terrain -- can't flush-replace safely
			if _blueprint.has(floor_cell):
				return invalid_result
			for dy in range(0, HOUSE_WALL_HEIGHT + 1):  # h..h+2 walls/interior, h+3 roof
				var c := Vector3i(x, h + dy, z)
				if _voxel_world.get_cell(c) != AIR or _blueprint.has(c):
					return invalid_result
	var door_col: Vector2i = _room_door_column(x0, x1, z0, z1)
	var floor_cells: Array[Vector3i] = []
	var wall_cells: Array[Vector3i] = []
	var roof_cells: Array[Vector3i] = []
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			floor_cells.append(Vector3i(x, h - 1, z))
			roof_cells.append(Vector3i(x, h + HOUSE_WALL_HEIGHT, z))
			var edge: bool = x == x0 or x == x1 or z == z0 or z == z1
			if edge and Vector2i(x, z) != door_col:
				for dy in range(HOUSE_WALL_HEIGHT):
					wall_cells.append(Vector3i(x, h + dy, z))
	return {"valid": true, "h": h, "floor": floor_cells, "walls": wall_cells, "roof": roof_cells, "door_col": door_col}


func _update_house_ghost(hit: Dictionary) -> void:
	_hide_corner_pool()
	var anchor_min := Vector2i(hit.cell.x - HOUSE_FOOTPRINT / 2, hit.cell.z - HOUSE_FOOTPRINT / 2)
	var layout: Dictionary = _house_layout(anchor_min)
	if not bool(layout["valid"]):
		var footprint_cells: Array[Vector3i] = []
		var guess_h: int = _voxel_world.terrain_height(hit.cell.x, hit.cell.z)
		for x in range(anchor_min.x, anchor_min.x + HOUSE_FOOTPRINT):
			for z in range(anchor_min.y, anchor_min.y + HOUSE_FOOTPRINT):
				footprint_cells.append(Vector3i(x, guess_h, z))
		_preview_valid_mesh.visible = false
		var invalid_values: Dictionary = _slice_filter_dict_keys(_uniform_cell_values(footprint_cells, _WOOD_VALUE))
		if invalid_values.is_empty():
			_preview_invalid_mesh.visible = false
		else:
			_preview_invalid_mesh.mesh = _build_ghost_mesh(invalid_values, GHOST_TINT_INVALID)
			_preview_invalid_mesh.visible = true
		return
	var values: Dictionary = {}
	for c: Vector3i in layout["floor"]:
		values[c] = _WOOD_VALUE
	for c: Vector3i in layout["walls"]:
		values[c] = _WOOD_VALUE
	for c: Vector3i in layout["roof"]:
		values[c] = _THATCH_VALUE
	values = _slice_filter_dict_keys(values)
	_preview_invalid_mesh.visible = false
	if values.is_empty():
		_preview_valid_mesh.visible = false
	else:
		_preview_valid_mesh.mesh = _build_ghost_mesh(values, GHOST_TINT_NEUTRAL)
		_preview_valid_mesh.visible = true


## Commits the whole house as ONE draft project ("Haus %d"). NOTE (documented
## limitation, see CONTRACTS.md): the undo/redo command model assumes a
## single material per command; a House's mixed wood+thatch batch undoes
## correctly (restore_values are captured per-cell regardless of material)
## but a REDO of a cancelled/undone House will only recreate cells under the
## command's single recorded item_id ("wood_block") -- the thatch roof
## portion will not re-progress on redo. Accepted for this feature's scope.
func _handle_house_press(hit: Dictionary) -> void:
	var anchor_min := Vector2i(hit.cell.x - HOUSE_FOOTPRINT / 2, hit.cell.z - HOUSE_FOOTPRINT / 2)
	var layout: Dictionary = _house_layout(anchor_min)
	if not bool(layout["valid"]):
		invalid_commit.emit(_cell_center(hit.cell), "Haus passt hier nicht (Terrain uneben oder Platz belegt)")
		return
	_create_house_project(layout)


func _create_house_project(layout: Dictionary) -> void:
	var project_id: int = _create_project(false, "", false)
	_projects[project_id]["name"] = "Haus %d" % project_id
	var project: Dictionary = _projects[project_id]
	var all_typed: Array[Vector3i] = []
	var restore_values: Dictionary = {}

	var floor_cells: Array = layout["floor"]
	var wall_cells: Array = layout["walls"]
	var roof_cells: Array = layout["roof"]
	# floor_cells replace terrain (h-1 band) -- flagged for the overlay marker
	# (task 1d); walls/roof are placed into open air, not a terrain replace.
	var groups: Array = [[floor_cells, "wood_block", true], [wall_cells, "wood_block", false], [roof_cells, "thatch_block", false]]
	for group: Array in groups:
		var cells: Array = group[0]
		var item_id: String = String(group[1])
		var group_floor_replace: bool = bool(group[2])
		for c: Vector3i in cells:
			var restore_value: int = _voxel_world.get_cell(c)
			restore_values[c] = restore_value
			project["restore_values"][c] = restore_value
			project["all_cells"][c] = true
			_cell_project[c] = project_id
			_blueprint[c] = {
				"item_id": item_id,
				"progress_ticks": 0,
				"claimed_by": 0,
				"needs_support": false,
				"draft": true,
				"restore_value": restore_value,
				"project_id": project_id,
				"dig": false,
				"floor_replace": group_floor_replace,
			}
			all_typed.append(c)

	_push_command(all_typed, "wood_block", false, restore_values, true, project_id, false)
	blueprint_changed.emit()
	projects_changed.emit()

func _rasterize_for_tool(tool_id: int, start: Vector3i, cur: Vector3i, plane_y: int) -> Array[Vector3i]:
	match tool_id:
		Tool.WALL:
			return _rasterize_wall(start, cur, plane_y, _wall_height)
		Tool.FLOOR:
			return _rasterize_floor(start, cur, plane_y)
		Tool.ROOF:
			return _rasterize_roof_flat(start, cur, plane_y)
		Tool.ROOM:
			return _rasterize_room(start, cur, plane_y, _wall_height)
		_:
			return []

# --- Formulas F1/F2/F5 ---

func _rasterize_wall(start: Vector3i, cur: Vector3i, plane_y: int, height: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var line: Array[Vector2i] = _bresenham_line(Vector2i(start.x, start.z), Vector2i(cur.x, cur.z))
	for p in line:
		for h in range(height):
			cells.append(Vector3i(p.x, plane_y + h, p.y))
	return cells

func _rasterize_floor(start: Vector3i, cur: Vector3i, plane_y: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var x0: int = mini(start.x, cur.x)
	var x1: int = maxi(start.x, cur.x)
	var z0: int = mini(start.z, cur.z)
	var z1: int = maxi(start.z, cur.z)
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			cells.append(Vector3i(x, plane_y, z))
	return cells

func _rasterize_roof_flat(start: Vector3i, cur: Vector3i, plane_y: int) -> Array[Vector3i]:
	# Flat only (F5); one plane above the picked start surface (slice-reduced from "highest picked").
	return _rasterize_floor(start, cur, plane_y + 1)


## FEATURE 3 (2026-07-22): Room tool -- perimeter WALLS of the dragged ground
## rectangle at `height` (the existing wall-height setting), with an automatic
## 1-column full-height door gap centered on the edge nearest the camera
## (fallback -z edge, see _room_door_column). Empty (invalid) below
## ROOM_MIN_SIZE in either axis -- too small to fit a gap.
func _rasterize_room(start: Vector3i, cur: Vector3i, plane_y: int, height: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var x0: int = mini(start.x, cur.x)
	var x1: int = maxi(start.x, cur.x)
	var z0: int = mini(start.z, cur.z)
	var z1: int = maxi(start.z, cur.z)
	if (x1 - x0 + 1) < ROOM_MIN_SIZE or (z1 - z0 + 1) < ROOM_MIN_SIZE:
		return cells
	var door_col: Vector2i = _room_door_column(x0, x1, z0, z1)
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			var edge: bool = x == x0 or x == x1 or z == z0 or z == z1
			if not edge:
				continue
			if Vector2i(x, z) == door_col:
				continue  # door gap: full height, skipped entirely
			for dy in range(height):
				cells.append(Vector3i(x, plane_y + dy, z))
	return cells


## Picks the perimeter edge nearest the camera's XZ position (fallback: the
## -z edge, i.e. z == z0, if the camera reference is unavailable) and returns
## the column centered on that edge -- the Room/House door gap.
func _room_door_column(x0: int, x1: int, z0: int, z1: int) -> Vector2i:
	var x_mid: int = x0 + (x1 - x0) / 2
	var z_mid: int = z0 + (z1 - z0) / 2
	var best: Vector2i = Vector2i(x_mid, z0)  # fallback: -z edge
	if _camera_input == null:
		return best
	var cam: Camera3D = _camera_input.get_camera()
	if cam == null:
		return best
	var cx: float = cam.global_position.x
	var cz: float = cam.global_position.z
	var dists: Dictionary = {
		"min_x": absf(cx - float(x0)),
		"max_x": absf(cx - float(x1)),
		"min_z": absf(cz - float(z0)),
		"max_z": absf(cz - float(z1)),
	}
	var cols: Dictionary = {
		"min_x": Vector2i(x0, z_mid),
		"max_x": Vector2i(x1, z_mid),
		"min_z": Vector2i(x_mid, z0),
		"max_z": Vector2i(x_mid, z1),
	}
	var best_key: String = "min_z"
	var best_dist: float = float(dists["min_z"])
	for k in dists.keys():
		if float(dists[k]) < best_dist:
			best_dist = float(dists[k])
			best_key = String(k)
	return cols[best_key]

func _bresenham_line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var x0: int = a.x
	var y0: int = a.y
	var x1: int = b.x
	var y1: int = b.y
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return points

# --- Press / commit handling ---

func _on_press() -> void:
	if _tool == Tool.NONE:
		return
	if _hud != null and _hud.is_hover_suppressing():
		return
	if not _last_hit_valid:
		return
	match _tool:
		Tool.BLOCK:
			_handle_block_press(_last_hit)
		Tool.FURNITURE:
			_handle_furniture_press(_last_hit)
		Tool.WALL, Tool.FLOOR, Tool.ROOF, Tool.ROOM:
			_handle_drag_press(_last_hit)
		Tool.ROOF_AUTO:
			_handle_roof_auto_press(_last_hit)
		Tool.HOUSE:
			_handle_house_press(_last_hit)

func _on_release() -> void:
	if _is_erase_pressed:
		_commit_erase_drag()
		_is_erase_pressed = false
		_erase_drag_active = false
		_hide_all_ghosts()
		return
	if not _is_pressed:
		return
	match _tool:
		Tool.WALL, Tool.FLOOR, Tool.ROOF, Tool.ROOM:
			_commit_drag()
		_:
			pass
	_is_pressed = false
	_is_drag_active = false
	_hide_all_ghosts()

func _handle_block_press(hit: Dictionary) -> void:
	if _camera_input.remove_modifier_held:
		# FEATURE 1/2: removal is now a press+optional-drag (box) instead of an
		# instant single-cell action, so a drag rect can batch-erase multiple
		# cells (e.g. a whole door-gap column) -- see _commit_erase_drag.
		_is_erase_pressed = true
		_erase_drag_active = false
		_erase_press_screen_pos = get_viewport().get_mouse_position()
		_erase_start_cell = hit.cell
		_erase_current_cell = hit.cell
		return
	var item: ResourceItemDatabase.ItemDef = _current_material()
	if item == null:
		invalid_commit.emit(_cell_center(hit.cell), "no material selected")
		return
	var target: Vector3i = hit.cell + hit.normal
	if not _is_cell_valid_for_commit(target, false):
		invalid_commit.emit(_cell_center(target), "invalid target")
		return
	_create_blueprint_cells([target], item.id, false)

func _handle_furniture_press(hit: Dictionary) -> void:
	var item: ResourceItemDatabase.ItemDef = _current_furniture()
	if item == null:
		invalid_commit.emit(_cell_center(hit.cell), "no furniture selected")
		return
	var target: Vector3i = hit.cell + hit.normal
	if not _is_cell_valid_for_commit(target, true):
		invalid_commit.emit(_cell_center(target), "no support")
		return
	_create_blueprint_cells([target], item.id, true)

func _handle_drag_press(hit: Dictionary) -> void:
	var item: ResourceItemDatabase.ItemDef = _current_material()
	_drag_item_id = item.id if item != null else ""
	_is_pressed = true
	_is_drag_active = false
	_press_screen_pos = get_viewport().get_mouse_position()
	# FEATURE 3: floor drags that START on a terrain top surface target that
	# surface's own plane (dig-in) instead of attaching one cell above it.
	_drag_floor_replace = _tool == Tool.FLOOR and _is_terrain_top_surface(hit)
	var target: Vector3i = hit.cell if _drag_floor_replace else hit.cell + hit.normal
	_drag_start_cell = target
	_drag_current_cell = target
	_drag_plane_y = target.y

func _commit_drag() -> void:
	if not _last_hit_valid or (_hud != null and _hud.is_hover_suppressing()):
		return  # Suspended/miss mid-release: abort without commit (Edge Case 12)
	if _tool == Tool.ROOF and FORMATIONS[_formation_index] != "Flat":
		invalid_commit.emit(_cell_center(_drag_start_cell), "VS scope")
		return
	var end_cell: Vector3i = _drag_current_cell if _is_drag_active else _drag_start_cell
	var raw_cells: Array[Vector3i] = _rasterize_for_tool(_tool, _drag_start_cell, end_cell, _drag_plane_y)
	if _tool == Tool.ROOM and raw_cells.is_empty():
		invalid_commit.emit(_cell_center(_drag_start_cell), "Raum zu klein (min. %dx%d)" % [ROOM_MIN_SIZE, ROOM_MIN_SIZE])
		return
	var clipped: Array[Vector3i] = []
	for c in raw_cells:
		if _voxel_world.is_in_region(c):
			clipped.append(c)
	if clipped.is_empty():
		invalid_commit.emit(_cell_center(_drag_start_cell), "out of bounds")
		return
	if clipped.size() > MAX_CELLS_PER_COMMAND:
		invalid_commit.emit(_cell_center(_drag_start_cell), "exceeds max_cells_per_command")
		return
	if _drag_item_id.is_empty():
		invalid_commit.emit(_cell_center(_drag_start_cell), "no material selected")
		return
	var floor_replace: bool = _tool == Tool.FLOOR and _drag_floor_replace
	var valid_cells: Array[Vector3i] = []
	for c in clipped:
		var ok: bool = _is_cell_valid_for_floor_replace(c) if floor_replace else _is_cell_valid_for_commit(c, false)
		if ok:
			valid_cells.append(c)
	if valid_cells.is_empty():
		invalid_commit.emit(_cell_center(_drag_start_cell), "no valid cells")
		return
	_create_blueprint_cells(valid_cells, _drag_item_id, false, floor_replace)

func _remove_built_cell(cell: Vector3i) -> void:
	if not _voxel_world.is_in_region(cell):
		invalid_commit.emit(_cell_center(cell), "out of bounds")
		return
	var value: int = _voxel_world.get_cell(cell)
	if value < BUILT_CELL_MIN_VALUE or value >= 30:
		invalid_commit.emit(_cell_center(cell), "only built cells are removable")
		return
	# BUG B fix (2026-07-22, user report: removing a block leaves an invisible
	# hole / "no ground"): a Floor-tool commit REPLACES terrain (floor_replace)
	# -- its restore_value is the original terrain band, not AIR. This path
	# used to always write AIR, carving a hole down to nothing instead of
	# restoring the ground. Reuses the exact restore semantics undo/
	# cancel_project already rely on: the project's restore_values, looked up
	# via the cell's still-live _cell_project reverse index (built cells keep
	# their project entry until untracked below).
	var restore_to: int = AIR
	if _cell_project.has(cell):
		var owning_pid: int = int(_cell_project[cell])
		if _projects.has(owning_pid):
			restore_to = int(_projects[owning_pid]["restore_values"].get(cell, AIR))
	var applied: Array = _voxel_world.set_cells([{"cell": cell, "value": restore_to}])
	var removed: Array[Vector3i] = []
	for entry in applied:
		removed.append(entry.cell)
	if _furniture_cells.has(cell):
		var fid: String = _furniture_cells[cell]
		_furniture_cells.erase(cell)
		furniture_removed.emit(cell, fid)
	if _cell_project.has(cell):
		_untrack_cell(cell)
		projects_changed.emit()
	cells_removed.emit(removed)

func _is_cell_valid_for_commit(cell: Vector3i, is_furniture: bool) -> bool:
	if not _voxel_world.is_in_region(cell):
		return false
	if _voxel_world.get_cell(cell) != AIR:
		return false
	if _blueprint.has(cell):
		return false
	if is_furniture:
		var below: Vector3i = cell + Vector3i(0, -1, 0)
		var below_built: bool = _voxel_world.get_cell(below) != AIR
		if not below_built and not _blueprint.has(below):
			return false
	return true

## FEATURE 3: replace-mode validity for a Floor drag that digs into terrain --
## a covered cell is buildable if it is raw terrain (1..4, uneven ground gets
## flattened) OR air (fills dips), and not already claimed by another blueprint.
func _is_cell_valid_for_floor_replace(cell: Vector3i) -> bool:
	if not _voxel_world.is_in_region(cell):
		return false
	if _blueprint.has(cell):
		return false
	var value: int = _voxel_world.get_cell(cell)
	return value == AIR or (value >= TERRAIN_MIN_VALUE and value <= TERRAIN_MAX_VALUE)

## FEATURE 2: true if `cell` is a legal dig-order target right now -- in
## region, not already planned (build OR dig), raw diggable terrain (1..5),
## and not currently occupied by a villager's body column (same occupancy
## provider construction uses; reused here per task spec).
func _is_cell_valid_for_dig(cell: Vector3i) -> bool:
	if not _voxel_world.is_in_region(cell):
		return false
	if _blueprint.has(cell):
		return false
	var value: int = _voxel_world.get_cell(cell)
	if value < DIGGABLE_MIN_VALUE or value > DIGGABLE_MAX_VALUE:
		return false
	if _occupancy_provider.is_valid() and bool(_occupancy_provider.call(cell)):
		return false
	return true

# --- FEATURE 1/2: removal tool (draft erase / built removal / dig orders) ---

## Axis-aligned inclusive box between two corner cells (the "drag rect" the
## task spec calls for; a plain click is just a/a 1-cell box).
func _erase_box_cells(a: Vector3i, b: Vector3i) -> Array[Vector3i]:
	var min_c := Vector3i(mini(a.x, b.x), mini(a.y, b.y), mini(a.z, b.z))
	var max_c := Vector3i(maxi(a.x, b.x), maxi(a.y, b.y), maxi(a.z, b.z))
	var cells: Array[Vector3i] = []
	for x in range(min_c.x, max_c.x + 1):
		for y in range(min_c.y, max_c.y + 1):
			for z in range(min_c.z, max_c.z + 1):
				cells.append(Vector3i(x, y, z))
	return cells

## True while `cell` is something the removal tool can act on right now: a
## DRAFT blueprint entry (erased instantly), a BUILT cell (10..29, queued for
## a demolition order if it belongs to a tracked project -- task 3b -- else
## the old instant-removal fallback), or legal diggable terrain (1..5, queued
## as a dig order). False for AIR, water, trunk/leaves, non-draft blueprint
## entries, and occupied dig/demolition targets.
func _is_erasable_cell(cell: Vector3i) -> bool:
	if not _voxel_world.is_in_region(cell):
		return false
	if _blueprint.has(cell):
		var entry: Dictionary = _blueprint[cell]
		return bool(entry.get("draft", false))
	var value: int = _voxel_world.get_cell(cell)
	if value >= BUILT_CELL_MIN_VALUE and value < 30:
		if _cell_project.has(cell):
			return _is_cell_valid_for_demolition(cell)
		return true  # untracked built cell -- instant-removal fallback always available
	if value >= DIGGABLE_MIN_VALUE and value <= DIGGABLE_MAX_VALUE:
		return _is_cell_valid_for_dig(cell)
	return false

## The real value the removal-tool ghost should texture with: a draft's own
## material, the REAL built block for a pending demolition (restore_value is
## what it becomes AFTER demolition, not what's there now -- task 3b), the
## terrain it will remove for a plain dig entry, else whatever's actually in
## the voxel world.
func _erase_preview_value(cell: Vector3i) -> int:
	if _blueprint.has(cell):
		var entry: Dictionary = _blueprint[cell]
		if bool(entry.get("demolition", false)):
			return _voxel_world.get_cell(cell)
		if bool(entry.get("dig", false)):
			return int(entry.get("restore_value", AIR))
		var def: ResourceItemDatabase.ItemDef = ResourceItemDatabase.get_by_id(String(entry.get("item_id", "")))
		return def.cell_value if def != null else 0
	return _voxel_world.get_cell(cell)

func _update_erase_drag_preview(hit: Dictionary) -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	if not _erase_drag_active and mouse_pos.distance_to(_erase_press_screen_pos) >= DRAG_THRESHOLD_PX:
		_erase_drag_active = true
	_erase_current_cell = hit.cell
	var raw_box_cells: Array[Vector3i] = _erase_box_cells(_erase_start_cell, _erase_current_cell)
	var box_cells: Array[Vector3i] = []
	for bc: Vector3i in raw_box_cells:
		if _is_cell_visible_at_slice(bc):   # SLICE VIEW: ghosts respect the cut too
			box_cells.append(bc)
	var valid_values: Dictionary = {}
	var invalid_cells: Array[Vector3i] = []
	for c in box_cells:
		if _is_erasable_cell(c):
			valid_values[c] = _erase_preview_value(c)
		else:
			invalid_cells.append(c)
	if valid_values.is_empty():
		_preview_valid_mesh.visible = false
	else:
		_preview_valid_mesh.mesh = _build_ghost_mesh(valid_values, GHOST_TINT_NEUTRAL)
		_preview_valid_mesh.visible = true
	if invalid_cells.is_empty():
		_preview_invalid_mesh.visible = false
	else:
		_preview_invalid_mesh.mesh = _build_ghost_mesh(_uniform_cell_values(invalid_cells, 0), GHOST_TINT_INVALID)
		_preview_invalid_mesh.visible = true

func _commit_erase_drag() -> void:
	var box_cells: Array[Vector3i] = _erase_box_cells(_erase_start_cell, _erase_current_cell)
	var single: bool = box_cells.size() == 1
	for c in box_cells:
		_apply_erase_at(c, single)

## Single entry point for the removal tool (single click OR drag box):
## drafts erase instantly (no job, FEATURE 1), a BUILT cell belonging to a
## tracked project queues a DEMOLITION ORDER (task 3b -- villagers tear it
## down through the job pipeline, it is no longer removed instantly), an
## untracked built cell falls back to instant removal, raw terrain queues a
## dig order (FEATURE 2). `emit_invalid` is only true for the single-cell
## (non-drag) case, matching the old click UX -- a multi-cell drag silently
## skips cells it can't act on instead of spamming toasts.
func _apply_erase_at(cell: Vector3i, emit_invalid: bool) -> void:
	if _erase_blueprint_draft_cell(cell):
		return
	if not _voxel_world.is_in_region(cell):
		if emit_invalid:
			invalid_commit.emit(_cell_center(cell), "out of bounds")
		return
	var value: int = _voxel_world.get_cell(cell)
	if value >= BUILT_CELL_MIN_VALUE and value < 30:
		if _cell_project.has(cell):
			if _create_demolition_order(cell):
				return
			if emit_invalid:
				invalid_commit.emit(_cell_center(cell), "Abriss bereits geplant oder blockiert")
			return
		_remove_built_cell(cell)  # untracked built cell -- no project to route through a job
		return
	if value >= DIGGABLE_MIN_VALUE and value <= DIGGABLE_MAX_VALUE:
		if _create_dig_order(cell):
			return
		if emit_invalid:
			invalid_commit.emit(_cell_center(cell), "cell occupied or already planned")
		return
	if emit_invalid:
		invalid_commit.emit(_cell_center(cell), "nothing to remove")

## FEATURE 1: erases a single DRAFT-state blueprint cell immediately -- no
## villager job, it's a plan edit. Covers BOTH a not-yet-built draft (task
## 3e: a draft DEMOLITION order cancels the same way -- it's just plan
## editing) and a normal not-yet-built material draft. A demolition draft's
## underlying cell is still a real, built, project-owned cell -- so its
## project bookkeeping (all_cells/built_cells) is left untouched; only a
## non-demolition draft (never built) gets fully untracked from its project.
## Returns false (no-op) if `cell` isn't a draft blueprint entry -- callers
## fall through to the BUILT-cell removal / dig-order paths. Released/
## BUILDING/PAUSED entries are NEVER touched by this path (draft == false).
func _erase_blueprint_draft_cell(cell: Vector3i) -> bool:
	if not _blueprint.has(cell):
		return false
	var entry: Dictionary = _blueprint[cell]
	if not bool(entry.get("draft", false)):
		return false
	var is_demolition: bool = bool(entry.get("demolition", false))
	_blueprint.erase(cell)
	if not is_demolition:
		_untrack_cell(cell)
	blueprint_changed.emit()
	projects_changed.emit()
	return true

## FEATURE 2: queues `cell` (raw terrain, 1..5) as a dig order -- a blueprint
## entry marked "dig":true, grouped into its own DRAFT project ("Abbau %d",
## 26-neighborhood rule, never merged with build projects). Returns false if
## the cell isn't a legal dig target right now (see _is_cell_valid_for_dig).
func _create_dig_order(cell: Vector3i) -> bool:
	if not _is_cell_valid_for_dig(cell):
		return false
	_create_blueprint_cells([cell], "", false, false, true)
	return true

# --- Demolition orders (2026-07-23, task 3b) ---
# A demolition is "a dig on a built cell": same is_dig:true machinery (job
# pipeline, DIG_BUILD_TICKS duration, red overlay ghost -- task 1d), plus a
# "demolition":true sub-flag so completion writes the project's captured
# restore_value (e.g. the terrain band under a Floor-tool cell) instead of a
# terrain dig's hardcoded AIR, and so completion SHRINKS the owning project's
## cell tracking (_untrack_cell) instead of marking it "built" forever the way
# a terrain dig project does (see _flush_batched_signals/report_on_site).

## True while `cell` is a legal interactive demolition target right now: a
## real BUILT cell (10..29), tracked by a project, not already queued, and not
## blocked by a villager currently occupying it (same occupancy provider dig
## orders use).
func _is_cell_valid_for_demolition(cell: Vector3i) -> bool:
	if not _voxel_world.is_in_region(cell):
		return false
	if _blueprint.has(cell):
		return false
	if not _cell_project.has(cell):
		return false
	var value: int = _voxel_world.get_cell(cell)
	if value < BUILT_CELL_MIN_VALUE or value >= 30:
		return false
	if _occupancy_provider.is_valid() and bool(_occupancy_provider.call(cell)):
		return false
	return true

## Stamps the actual demolition blueprint entry on `cell` (owned by
## `project_id`, already known to be built). `released` false = draft (needs a
## manual release, e.g. via the interactive removal tool); true = released
## immediately (used by cancel_project's mass teardown -- task 3c, "Alles ueber
## Auftraege", no manual start step for an Abriss). Does NOT touch project
## all_cells/built_cells -- the cell stays exactly as tracked until the job
## actually completes (see _flush_batched_signals).
func _create_demolition_entry(cell: Vector3i, project_id: int, released: bool) -> void:
	var project: Dictionary = _projects[project_id]
	var restore_to: int = int(project["restore_values"].get(cell, AIR))
	_blueprint[cell] = {
		"item_id": "",
		"progress_ticks": 0,
		"claimed_by": 0,
		"needs_support": false,
		"draft": not released,
		"restore_value": restore_to,
		"project_id": project_id,
		"dig": true,
		"demolition": true,
		"floor_replace": false,
	}

## Interactive entry point (removal tool on a built project cell): queues a
## DRAFT demolition order, pushed onto the undo stack like any other plan
## edit (see 3d: undoing it before release/completion just cancels the plan,
## same as _erase_blueprint_draft_cell). Returns false if `cell` isn't a legal
## demolition target right now (see _is_cell_valid_for_demolition).
func _create_demolition_order(cell: Vector3i) -> bool:
	if not _is_cell_valid_for_demolition(cell):
		return false
	var project_id: int = int(_cell_project[cell])
	if not _projects.has(project_id):
		return false
	_create_demolition_entry(cell, project_id, false)
	var restore_to: int = int(_blueprint[cell]["restore_value"])
	_push_command([cell], "", false, {cell: restore_to}, false, project_id, true, true)
	blueprint_changed.emit()
	projects_changed.emit()
	return true

func _create_blueprint_cells(cells: Array, item_id: String, is_furniture: bool, is_floor_replace: bool = false, is_dig: bool = false) -> void:
	var typed_cells: Array[Vector3i] = []
	for c in cells:
		typed_cells.append(c)
	# Build projects (2026-07-22): the WHOLE batch shares one project -- merges
	# into an existing DRAFT project if any cell in the batch touches one,
	# otherwise starts a fresh project. See _assign_project. FEATURE 2: dig
	# cells only ever merge with other DRAFT dig projects, never build ones.
	var project_id: int = _assign_project(typed_cells, is_furniture, item_id, is_dig)
	var project: Dictionary = _projects[project_id]
	var restore_values: Dictionary = {}
	for c in typed_cells:
		# FEATURE 3 (floor-replace) / FEATURE 2 (dig): capture the cell's
		# PRE-EXISTING value (terrain id for a floor-replace or dig, AIR for
		# every normal build) so undo/cancel restores the correct thing
		# instead of assuming AIR. Also banked on the project (restore_values
		# survives past the blueprint entry being erased on completion --
		# needed by cancel_project to un-build/un-dig later).
		var restore_value: int = _voxel_world.get_cell(c)
		restore_values[c] = restore_value
		project["restore_values"][c] = restore_value
		_blueprint[c] = {
			"item_id": item_id,
			"progress_ticks": 0,
			"claimed_by": 0,
			"needs_support": is_furniture,
			"draft": true,  # FEATURE 2: new blueprint cells start as drafts
			"restore_value": restore_value,
			"project_id": project_id,
			"dig": is_dig,
			"floor_replace": is_floor_replace,  # VISIBILITY PACKAGE 1d: overlay marker classification
		}
	_push_command(typed_cells, item_id, is_furniture, restore_values, is_floor_replace, project_id, is_dig)
	blueprint_changed.emit()

# --- Build projects (2026-07-22) ---

## Grouping rule: merges the WHOLE incoming batch into an existing DRAFT-state
## project if ANY cell in the batch is within the 26-neighborhood of that
## project's cells; if the batch bridges multiple DRAFT projects, those
## projects are merged into one first. Otherwise starts a fresh project.
## Released/BUILDING/PAUSED/DONE projects never match (they never absorb new
## drafts -- an adjacent new commit starts its own fresh project instead).
## `is_dig` (FEATURE 2): dig cells only match/merge with other DRAFT projects
## that are ALSO dig projects -- a build wall and an adjacent dig order never
## fold into the same project even if they touch.
func _assign_project(cells: Array[Vector3i], is_furniture: bool, item_id: String, is_dig: bool = false) -> int:
	# CHANGE ORDERS (2026-07-23, task 3a -- REVERSES the earlier "released
	# projects never absorb drafts" rule): a DRAFT match is still merge-eligible
	# (multiple touched DRAFT projects fold into one survivor, exactly as
	# before). A BUILDING/PAUSED/DONE match is now ALSO eligible -- but as an
	# ATTACH, not a merge: the new cells join that SAME project as fresh draft
	# entries (see _create_blueprint_cells, which always stamps draft:true)
	# without touching its existing state or already-built cells. A DRAFT match
	# always wins over a released match if a batch happens to touch both (kept
	# simple; see CONTRACTS.md for the documented judgment call).
	var matched_draft: Dictionary = {}    # project_id -> true
	var matched_released: int = -1        # first BUILDING/PAUSED/DONE match found
	for c in cells:
		for offset in _NEIGHBORHOOD_26:
			var n: Vector3i = c + offset
			if not _cell_project.has(n):
				continue
			var pid: int = int(_cell_project[n])
			if not _projects.has(pid) or bool(_projects[pid].get("is_dig", false)) != is_dig:
				continue
			var pstate: int = int(_projects[pid]["state"])
			if pstate == ProjectState.DRAFT:
				matched_draft[pid] = true
			elif matched_released == -1:
				matched_released = pid
	var survivor_id: int = -1
	if not matched_draft.is_empty():
		var ids: Array = matched_draft.keys()
		ids.sort()
		survivor_id = int(ids[0])
		for i in range(1, ids.size()):
			_merge_project_into(survivor_id, int(ids[i]))
	elif matched_released != -1:
		survivor_id = matched_released
	if survivor_id == -1:
		survivor_id = _create_project(is_furniture, item_id, is_dig)
	var survivor: Dictionary = _projects[survivor_id]
	for c in cells:
		survivor["all_cells"][c] = true
		_cell_project[c] = survivor_id
	projects_changed.emit()
	return survivor_id

## Naming: buildings get "Projekt %d"; a furniture-only NEW project (bed) names
## itself after the item ("Bett %d"); a dig order gets "Abbau %d" (FEATURE 2)
## -- trivial-detection heuristic, only applies when the placement doesn't
## merge into an existing project.
func _create_project(is_furniture: bool, item_id: String, is_dig: bool = false) -> int:
	var id: int = _next_project_id
	_next_project_id += 1
	var name: String
	if is_dig:
		name = "Abbau %d" % id
	elif is_furniture and item_id == "bed":
		name = "Bett %d" % id
	else:
		name = "Projekt %d" % id
	_projects[id] = {
		"id": id,
		"name": name,
		"state": ProjectState.DRAFT,
		"all_cells": {},
		"built_cells": {},
		"claims": {},
		"restore_values": {},
		"is_dig": is_dig,
		"demolishing": false,
	}
	return id

## Folds absorb_id entirely into keep_id (cell sets, claims, restore_values,
## reverse index) and retags any surviving blueprint entries that still point
## at absorb_id. Both are assumed DRAFT (the only state _assign_project matches).
func _merge_project_into(keep_id: int, absorb_id: int) -> void:
	if keep_id == absorb_id or not _projects.has(absorb_id) or not _projects.has(keep_id):
		return
	var keep: Dictionary = _projects[keep_id]
	var absorb: Dictionary = _projects[absorb_id]
	for c in absorb["all_cells"].keys():
		keep["all_cells"][c] = true
		_cell_project[c] = keep_id
	for c in absorb["built_cells"].keys():
		keep["built_cells"][c] = true
	for c in absorb["claims"].keys():
		keep["claims"][c] = absorb["claims"][c]
	for c in absorb["restore_values"].keys():
		keep["restore_values"][c] = absorb["restore_values"][c]
	_projects.erase(absorb_id)
	for cell in _blueprint.keys():
		var entry: Dictionary = _blueprint[cell]
		if int(entry.get("project_id", -1)) == absorb_id:
			entry["project_id"] = keep_id

## Removes a single cell from whatever project owns it (undo of a still-pending
## commit, or a manual Ctrl+click removal of a built cell). Drops the project
## entirely once it owns zero cells.
func _untrack_cell(cell: Vector3i) -> void:
	if not _cell_project.has(cell):
		return
	var pid: int = _cell_project[cell]
	_cell_project.erase(cell)
	if not _projects.has(pid):
		return
	var p: Dictionary = _projects[pid]
	p["all_cells"].erase(cell)
	p["built_cells"].erase(cell)
	p["claims"].erase(cell)
	p["restore_values"].erase(cell)
	if p["all_cells"].is_empty():
		_projects.erase(pid)

## True while any blueprint entry (still Planned/UnderConstruction, including
## "ready" ones awaiting the completion flush) still points at this project --
## i.e. the project is NOT fully built yet.
func _project_has_pending_entries(pid: int) -> bool:
	for entry in _blueprint.values():
		if int(entry.get("project_id", -1)) == pid:
			return true
	return false

# --- Undo / redo ---

func _push_command(cells: Array[Vector3i], item_id: String, is_furniture: bool, restore_values: Dictionary, is_floor_replace: bool = false, project_id: int = -1, is_dig: bool = false, is_demolition: bool = false) -> void:
	_undo_stack.append({
		"cells": cells.duplicate(),
		"item_id": item_id,
		"is_furniture": is_furniture,
		"restore_values": restore_values.duplicate(),
		"is_floor_replace": is_floor_replace,
		"project_id": project_id,
		"is_dig": is_dig,
		"is_demolition": is_demolition,
	})
	if _undo_stack.size() > UNDO_STACK_DEPTH:
		_undo_stack.pop_front()  # Edge Case 9: oldest discarded silently
	_redo_stack.clear()
	_emit_undo_state()

## UNDO RESTRICTION (2026-07-23, task 3d): _undo operates on PLAN entries
## ONLY. A cell still present in _blueprint is still a pending plan (draft or
## released, never completed) -- cancelling it is safe and cheap. A cell NO
## LONGER in _blueprint has already been RESOLVED (built by a villager, or
## torn down by a completed demolition/dig job) -- undo is now a NO-OP for
## that cell; built-cell removal happens exclusively through demolition jobs
## (task 3b/3c), never through undo. SIMPLIFICATION documented here: this
## means undoing a command after ANY of its cells finished no longer reverts
## those finished cells (previously undo un-built completed construction and
## re-materialized completed demolitions/digs -- both are now impossible by
## design). A cancelled DRAFT demolition plan is un-tracked exactly like any
## other still-pending plan cancel EXCEPT it must NOT be stripped from its
## project's all_cells/built_cells (the underlying cell is still real, built,
## and owned by that project -- only the pending removal PLAN is cancelled).
func _undo() -> void:
	if _undo_stack.is_empty():
		return
	var cmd: Dictionary = _undo_stack.pop_back()
	var is_demolition: bool = bool(cmd.get("is_demolition", false))
	var any_cancelled := false
	for cell in cmd["cells"]:
		if not _blueprint.has(cell):
			continue  # already resolved (built or torn down) -- no-op, see docstring above
		_blueprint.erase(cell)
		if not is_demolition:
			_untrack_cell(cell)
		any_cancelled = true
	_redo_stack.append(cmd)
	if any_cancelled:
		blueprint_changed.emit()
		projects_changed.emit()
	_emit_undo_state()

func _redo() -> void:
	if _redo_stack.is_empty():
		return
	var cmd: Dictionary = _redo_stack.pop_back()
	if bool(cmd.get("is_demolition", false)):
		# SIMPLIFICATION (task 3d): re-attaching a torn-down-order to a fresh
		# synthetic project (the pattern every other redo below uses) would
		# double-own a cell that's still tracked by its ORIGINAL project --
		# out of scope for this prototype. Queue a new demolition manually via
		# the removal tool instead.
		invalid_commit.emit(_cell_center(cmd["cells"][0]), "redo: Abriss kann nicht wiederholt werden")
		_emit_undo_state()
		return
	var is_furniture: bool = bool(cmd["is_furniture"])
	var is_floor_replace: bool = bool(cmd.get("is_floor_replace", false))
	var is_dig: bool = bool(cmd.get("is_dig", false))
	var valid_cells: Array[Vector3i] = []
	for cell in cmd["cells"]:
		var ok: bool
		if is_dig:
			ok = _is_cell_valid_for_dig(cell)
		elif is_floor_replace:
			ok = _is_cell_valid_for_floor_replace(cell)
		else:
			ok = _is_cell_valid_for_commit(cell, is_furniture)
		if ok:
			valid_cells.append(cell)
	if valid_cells.is_empty():
		invalid_commit.emit(_cell_center(cmd["cells"][0]), "redo: no valid cells remain")
		_emit_undo_state()
		return
	# Build projects (2026-07-22): redo re-releases directly (draft:false), so
	# it gets its OWN fresh project already in BUILDING state rather than going
	# through the DRAFT-only merge rule in _assign_project.
	var project_id: int = _create_project(is_furniture, String(cmd["item_id"]), is_dig)
	_projects[project_id]["state"] = ProjectState.BUILDING
	var project: Dictionary = _projects[project_id]
	var restore_values: Dictionary = {}
	for cell in valid_cells:
		var restore_value: int = _voxel_world.get_cell(cell)
		restore_values[cell] = restore_value
		project["restore_values"][cell] = restore_value
		project["all_cells"][cell] = true
		_cell_project[cell] = project_id
		_blueprint[cell] = {
			"item_id": cmd["item_id"],
			"progress_ticks": 0,
			"claimed_by": 0,
			"needs_support": is_furniture,
			"draft": false,  # redo restores directly to released (see task summary)
			"restore_value": restore_value,
			"project_id": project_id,
			"dig": is_dig,
		}
	_undo_stack.append({
		"cells": valid_cells,
		"item_id": cmd["item_id"],
		"is_furniture": is_furniture,
		"restore_values": restore_values,
		"is_floor_replace": is_floor_replace,
		"project_id": project_id,
		"is_dig": is_dig,
		"is_demolition": false,
	})
	if _undo_stack.size() > UNDO_STACK_DEPTH:
		_undo_stack.pop_front()
	blueprint_changed.emit()
	_emit_undo_state()
	projects_changed.emit()

func _emit_undo_state() -> void:
	undo_state_changed.emit(not _undo_stack.is_empty(), not _redo_stack.is_empty())

# --- Batched construction completion (per-frame flush) ---

func _flush_batched_signals() -> void:
	if _pending_completions.is_empty():
		return
	# RACE CLOSURE (found by loop_test with tick bursts): occupancy must be
	# re-checked AT WRITE TIME — between report_on_site's tick and this frame
	# flush the villager can step INTO a completing cell's body column.
	# Occupied entries stay pending and retry next flush.
	var writes: Array = []
	var write_meta: Array = []
	var still_pending: Array[Dictionary] = []
	for c in _pending_completions:
		if _occupancy_provider.is_valid() and bool(_occupancy_provider.call(c["cell"])):
			still_pending.append(c)
			continue
		writes.append({"cell": c["cell"], "value": c["value"]})
		write_meta.append(c)
	_pending_completions = still_pending
	if writes.is_empty():
		return
	var applied: Array = _voxel_world.set_cells(writes)
	var completed_build_cells: Array[Vector3i] = []
	var completed_dig_cells: Array[Vector3i] = []
	var touched_projects: Dictionary = {}
	for i in applied.size():
		var res: Dictionary = applied[i]
		var meta: Dictionary = write_meta[i]
		var entry: Dictionary = _blueprint.get(res.cell, {})
		var project_id: int = int(entry.get("project_id", -1))
		var is_dig: bool = bool(meta.get("is_dig", false))
		var is_demolition: bool = bool(meta.get("is_demolition", false))
		_blueprint.erase(res.cell)
		if is_dig:
			completed_dig_cells.append(res.cell)
		else:
			completed_build_cells.append(res.cell)
		if bool(meta["is_furniture"]):
			_furniture_cells[res.cell] = meta["item_id"]
			furniture_placed.emit(res.cell, String(meta["item_id"]))
		elif is_dig and _furniture_cells.has(res.cell):
			# Demolished a cell that used to hold furniture (e.g. a built bed).
			var fid: String = _furniture_cells[res.cell]
			_furniture_cells.erase(res.cell)
			furniture_removed.emit(res.cell, fid)
		if project_id != -1 and _projects.has(project_id):
			var p: Dictionary = _projects[project_id]
			p["claims"].erase(res.cell)
			touched_projects[project_id] = true
			if is_demolition:
				# 3b/3c: a demolished cell LEAVES the project entirely (shrinks
				# all_cells/built_cells) instead of being marked "built" the
				# way a plain terrain-dig completion is below.
				_untrack_cell(res.cell)
			else:
				p["built_cells"][res.cell] = true
	# Build projects (2026-07-22): a project is DONE once every cell it ever
	# owned is built/dug and no blueprint entry still points at it.
	for pid in touched_projects.keys():
		if not _projects.has(pid):
			continue  # demolished down to zero cells -- project already gone (3c)
		var p2: Dictionary = _projects[pid]
		if int(p2["state"]) != ProjectState.DONE and not _project_has_pending_entries(pid):
			p2["state"] = ProjectState.DONE
	if not completed_build_cells.is_empty():
		construction_completed.emit(completed_build_cells)
	# FEATURE 2: dig completions fire cells_removed (not construction_completed)
	# so build_validation's room/shelter analysis re-runs around the new hole,
	# exactly as it does for a manual block removal.
	if not completed_dig_cells.is_empty():
		cells_removed.emit(completed_dig_cells)
	blueprint_changed.emit()
	if not touched_projects.is_empty():
		projects_changed.emit()

# --- Ghost pools (tool preview + blueprint progress) ---

func _build_ghost_visuals() -> void:
	# Merged, face-culled, TEXTURED ghost meshes: one shared material per tint
	# (blueprint + valid-preview share the neutral tint; invalid-preview gets its
	# own), one persistent MeshInstance3D per role. The atlas texture supplies the
	# real block look; tint is baked into each mesh's own vertex colors
	# (_build_ghost_mesh) and multiplies the sampled texel underneath.
	var atlas: Dictionary = _voxel_world.get_atlas()
	_atlas_texture = atlas.get("texture")
	_atlas_uv_rect = atlas.get("uv_rect", Callable())
	_mat_ghost_valid = _make_textured_ghost_material()
	_mat_ghost_invalid = _make_textured_ghost_material()
	_blueprint_draft_mesh_instance = _make_ghost_mesh_instance(_mat_ghost_valid)
	_blueprint_released_mesh_instance = _make_ghost_mesh_instance(_mat_ghost_valid)
	# VISIBILITY PACKAGE (2026-07-23, task 1d): untextured overlay-marker
	# material (shared, tint is per-vertex) -- REPLACES the old dig-only
	# tinted textured ghost mesh pair. Dig/demolition cells get no textured
	# ghost at all now; the inflated overlay box is their sole visual.
	_mat_overlay = _make_overlay_material()
	_overlay_dig_draft_mesh_instance = _make_ghost_mesh_instance(_mat_overlay)
	_overlay_dig_released_mesh_instance = _make_ghost_mesh_instance(_mat_overlay)
	_overlay_replace_draft_mesh_instance = _make_ghost_mesh_instance(_mat_overlay)
	_overlay_replace_released_mesh_instance = _make_ghost_mesh_instance(_mat_overlay)
	_preview_valid_mesh = _make_ghost_mesh_instance(_mat_ghost_valid)
	_preview_invalid_mesh = _make_ghost_mesh_instance(_mat_ghost_invalid)

	# Corner-marker degrade path: small solid boxes, simple albedo-tinted materials
	# (no vertex colors/UVs on a bare BoxMesh here -- kept as its own simple,
	# untextured material pair; an outline doesn't need to show the real tile).
	_box_mesh = BoxMesh.new()
	_box_mesh.size = Vector3.ONE

	_mat_valid = StandardMaterial3D.new()
	_mat_valid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_valid.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_valid.albedo_color = Color(0.35, 0.55, 0.9, 0.45)

	_mat_invalid = StandardMaterial3D.new()
	_mat_invalid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_invalid.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_invalid.albedo_color = Color(0.95, 0.55, 0.15, 0.45)

	for i in CORNER_POOL_SIZE:
		var mi := MeshInstance3D.new()
		mi.mesh = _box_mesh
		mi.scale = Vector3(0.25, 0.25, 0.25)
		mi.visible = false
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_corner_pool.append(mi)

func _make_textured_ghost_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _atlas_texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	# VISIBILITY PACKAGE (2026-07-23, task 1c): the alpha bump to 0.5/0.7 (from
	# 0.3/0.45) makes coplanar/overlapping translucent ghost faces sort far
	# more visibly than before -- force depth writes so overlapping ghost
	# layers (e.g. draft+released of the same project mid change-order) don't
	# alpha-sort against each other in an unstable order frame to frame.
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	return mat

## VISIBILITY PACKAGE (2026-07-23, task 1d): shared material for every
## overlay-marker mesh instance (dig/replace x draft/released) -- untextured,
## tint is per-vertex, double-sided (the inflated box is a plain color marker,
## not a real textured block, so seeing its inside from any angle is fine).
func _make_overlay_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color.WHITE
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	return mat

func _make_ghost_mesh_instance(mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	add_child(mi)
	return mi

## VISIBILITY PACKAGE (2026-07-23, task 1d): inflated (OVERLAY_SCALE), fully
## solid (all 6 faces always emitted, no neighbor culling -- these are sparse
## per-cell markers, not a merged solid volume) box per cell in `cells`,
## uniformly tinted. Reuses _FACE_DIRS/_FACE_VERTS geometry (recentered to
## -0.5..0.5 cell-local space, scaled, then re-offset to each cell's center).
func _build_overlay_mesh(cells: Array, tint: Color) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if cells.is_empty():
		return mesh
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for c in cells:
		var cell: Vector3i = c
		var center := Vector3(cell.x + 0.5, cell.y + 0.5, cell.z + 0.5)
		for i in _FACE_DIRS.size():
			var dir: Vector3i = _FACE_DIRS[i]
			var face_verts: Array = _FACE_VERTS[i]
			var base_index: int = verts.size()
			var normal := Vector3(dir.x, dir.y, dir.z)
			for v: Vector3 in face_verts:
				var local: Vector3 = (v - Vector3(0.5, 0.5, 0.5)) * OVERLAY_SCALE
				verts.append(center + local)
				normals.append(normal)
				colors.append(tint)
			indices.append(base_index)
			indices.append(base_index + 1)
			indices.append(base_index + 2)
			indices.append(base_index)
			indices.append(base_index + 2)
			indices.append(base_index + 3)
	if verts.is_empty():
		return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _refresh_overlay_mesh(instance: MeshInstance3D, cells: Array, tint: Color) -> void:
	if cells.is_empty():
		instance.visible = false
	else:
		instance.mesh = _build_overlay_mesh(cells, tint)
		instance.visible = true

## Boundary-face mesh for an arbitrary cell set: emits a quad only where the
## 6-neighbor is absent FROM THE SET (world contents are irrelevant here). Each
## cell samples its OWN atlas tile (cell_values: Vector3i -> cell_value) so a
## mixed blueprint (wood + thatch + bed) renders each cell's real texture; a
## uniform tint is baked into every vertex color and multiplies the sampled
## texel underneath. One surface -- see _FACE_DIRS/_FACE_VERTS/_QUAD_UV.
func _build_ghost_mesh(cell_values: Dictionary, tint: Color) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if cell_values.is_empty():
		return mesh
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	for c in cell_values.keys():
		var cell: Vector3i = c
		var origin: Vector3 = Vector3(cell.x, cell.y, cell.z)
		var uv_rect: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)
		if _atlas_uv_rect.is_valid():
			uv_rect = _atlas_uv_rect.call(int(cell_values[c]))
		for i in _FACE_DIRS.size():
			var dir: Vector3i = _FACE_DIRS[i]
			if cell_values.has(cell + dir):
				continue  # interior face -- neighbor is in the same set, cull it
			var base_index: int = verts.size()
			var normal: Vector3 = Vector3(dir.x, dir.y, dir.z)
			var face_verts: Array = _FACE_VERTS[i]
			for j in face_verts.size():
				verts.append(origin + face_verts[j])
				normals.append(normal)
				colors.append(tint)
				var local_uv: Vector2 = _QUAD_UV[j]
				uvs.append(Vector2(
					uv_rect.position.x + local_uv.x * uv_rect.size.x,
					uv_rect.position.y + local_uv.y * uv_rect.size.y))
			indices.append(base_index)
			indices.append(base_index + 1)
			indices.append(base_index + 2)
			indices.append(base_index)
			indices.append(base_index + 2)
			indices.append(base_index + 3)
	if verts.is_empty():
		return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

## Builds a Vector3i -> cell_value Dictionary for a cell list that shares ONE
## material (drag/single-cell previews are always one tool + one selection).
## Param deliberately UNTYPED: _render_tool_preview feeds it plain Arrays.
func _uniform_cell_values(cells: Array, value: int) -> Dictionary:
	var out: Dictionary = {}
	for c in cells:
		out[c] = value
	return out

func _render_drag_ghosts(cells: Array[Vector3i], cell_value: int) -> void:
	_hide_corner_pool()
	if cells.is_empty():
		_preview_valid_mesh.visible = false
		_preview_invalid_mesh.visible = false
		return
	var roof_invalid_formation: bool = _tool == Tool.ROOF and FORMATIONS[_formation_index] != "Flat"
	if cells.size() > PREVIEW_DEGRADATION_THRESHOLD:
		_preview_valid_mesh.visible = false
		_preview_invalid_mesh.visible = false
		_render_corner_markers(cells, not roof_invalid_formation)
		return
	var valid_cells: Array[Vector3i] = []
	var invalid_cells: Array[Vector3i] = []
	var floor_replace: bool = _tool == Tool.FLOOR and _drag_floor_replace
	for cell in cells:
		var valid: bool = false
		if not roof_invalid_formation:
			valid = _is_cell_valid_for_floor_replace(cell) if floor_replace else _is_cell_valid_for_commit(cell, _tool == Tool.FURNITURE)
		if valid:
			valid_cells.append(cell)
		else:
			invalid_cells.append(cell)
	_render_tool_preview(valid_cells, invalid_cells, cell_value)

## Rebuilds the two merged tool-preview meshes from an already-split cell set.
## Shared by the drag/hover preview (WALL/FLOOR/ROOF) and the single-cell
## BLOCK/FURNITURE preview (called with a 1-cell array on whichever side is
## valid). cell_value is uniform across one call -- only one tool/material is
## ever armed at a time (WALL/FLOOR/ROOF lock it at drag-press; see _drag_item_id).
func _render_tool_preview(valid_cells: Array, invalid_cells: Array, cell_value: int) -> void:
	# Untyped on purpose: call sites use inline `[x] if cond else []` literals,
	# which are plain Arrays — typed params raised runtime errors (user crash).
	valid_cells = _slice_filter_array(valid_cells)     # SLICE VIEW: ghosts respect the cut too
	invalid_cells = _slice_filter_array(invalid_cells)
	if valid_cells.is_empty():
		_preview_valid_mesh.visible = false
	else:
		_preview_valid_mesh.mesh = _build_ghost_mesh(_uniform_cell_values(valid_cells, cell_value), GHOST_TINT_NEUTRAL)
		_preview_valid_mesh.visible = true
	if invalid_cells.is_empty():
		_preview_invalid_mesh.visible = false
	else:
		_preview_invalid_mesh.mesh = _build_ghost_mesh(_uniform_cell_values(invalid_cells, cell_value), GHOST_TINT_INVALID)
		_preview_invalid_mesh.visible = true

func _render_corner_markers(cells: Array[Vector3i], valid: bool) -> void:
	var min_c: Vector3i = cells[0]
	var max_c: Vector3i = cells[0]
	for c in cells:
		min_c = Vector3i(mini(min_c.x, c.x), mini(min_c.y, c.y), mini(min_c.z, c.z))
		max_c = Vector3i(maxi(max_c.x, c.x), maxi(max_c.y, c.y), maxi(max_c.z, c.z))
	var corners: Array[Vector3i] = [
		Vector3i(min_c.x, min_c.y, min_c.z), Vector3i(max_c.x, min_c.y, min_c.z),
		Vector3i(min_c.x, max_c.y, min_c.z), Vector3i(max_c.x, max_c.y, min_c.z),
		Vector3i(min_c.x, min_c.y, max_c.z), Vector3i(max_c.x, min_c.y, max_c.z),
		Vector3i(min_c.x, max_c.y, max_c.z), Vector3i(max_c.x, max_c.y, max_c.z),
	]
	for i in corners.size():
		var mi: MeshInstance3D = _corner_pool[i]
		mi.global_position = _cell_center(corners[i])
		mi.material_override = _mat_valid if valid else _mat_invalid
		mi.visible = true

func _hide_all_ghosts() -> void:
	_preview_valid_mesh.visible = false
	_preview_invalid_mesh.visible = false
	_hide_corner_pool()
	if _highlight_box_instance != null:
		_highlight_box_instance.visible = false
	if _highlight_face_instance != null:
		_highlight_face_instance.visible = false
	if _build_grid_instance != null:
		_build_grid_instance.visible = false
		_last_grid_column = Vector2i(999999, 999999)  # force a rebuild next hover

func _hide_corner_pool() -> void:
	for mi in _corner_pool:
		mi.visible = false

## Rebuilds the two merged blueprint meshes (draft / released) from the current
## cell set (Planned + UnderConstruction combined -- no per-cell progress-alpha;
## see design/gdd/building-system.md Visual Requirements). Each cell textures
## with ITS OWN atlas tile (a mixed wood+thatch+bed blueprint renders each
## cell's real tile), since a command's cells can span multiple past commits.
## FEATURE 2: split by draft state so players can see what release_drafts()
## will affect (dim = draft, stronger = released-but-unbuilt).
## VISIBILITY PACKAGE (2026-07-23, tasks 1b/1d): dig/demolition entries no
## longer get a textured ghost mesh at all -- they render ONLY via the
## inflated overlay marker (red). Non-dig entries still get the normal
## textured draft/released ghost; ADDITIONALLY, any entry flagged
## floor_replace (a Floor-tool terrain-replace cell) gets an orange overlay
## marker on top, so "the ground here will be replaced" reads at a glance.
func _refresh_blueprint_ghosts() -> void:
	var draft_values: Dictionary = {}
	var released_values: Dictionary = {}
	var overlay_dig_draft: Array = []
	var overlay_dig_released: Array = []
	var overlay_replace_draft: Array = []
	var overlay_replace_released: Array = []
	for cell in _blueprint.keys():
		if not _is_cell_visible_at_slice(cell):   # SLICE VIEW: ghosts respect the cut too
			continue
		var entry: Dictionary = _blueprint[cell]
		var is_dig: bool = bool(entry.get("dig", false))
		var draft: bool = bool(entry.get("draft", false))
		if is_dig:
			if draft:
				overlay_dig_draft.append(cell)
			else:
				overlay_dig_released.append(cell)
			continue
		var def: ResourceItemDatabase.ItemDef = ResourceItemDatabase.get_by_id(String(entry["item_id"]))
		var value: int = def.cell_value if def != null else 0
		if draft:
			draft_values[cell] = value
		else:
			released_values[cell] = value
		if bool(entry.get("floor_replace", false)):
			if draft:
				overlay_replace_draft.append(cell)
			else:
				overlay_replace_released.append(cell)
	if draft_values.is_empty():
		_blueprint_draft_mesh_instance.visible = false
	else:
		_blueprint_draft_mesh_instance.mesh = _build_ghost_mesh(draft_values, GHOST_TINT_DRAFT)
		_blueprint_draft_mesh_instance.visible = true
	if released_values.is_empty():
		_blueprint_released_mesh_instance.visible = false
	else:
		_blueprint_released_mesh_instance.mesh = _build_ghost_mesh(released_values, GHOST_TINT_RELEASED)
		_blueprint_released_mesh_instance.visible = true
	_refresh_overlay_mesh(_overlay_dig_draft_mesh_instance, overlay_dig_draft, OVERLAY_TINT_DIG_DRAFT)
	_refresh_overlay_mesh(_overlay_dig_released_mesh_instance, overlay_dig_released, OVERLAY_TINT_DIG_RELEASED)
	_refresh_overlay_mesh(_overlay_replace_draft_mesh_instance, overlay_replace_draft, OVERLAY_TINT_REPLACE_DRAFT)
	_refresh_overlay_mesh(_overlay_replace_released_mesh_instance, overlay_replace_released, OVERLAY_TINT_REPLACE_RELEASED)


# --- Click selection visuals (2026-07-23, task 2b) ---

func _build_selection_visuals() -> void:
	_mat_selection_box = StandardMaterial3D.new()
	_mat_selection_box.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_selection_box.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_selection_box.vertex_color_use_as_albedo = true
	_mat_selection_box.albedo_color = Color.WHITE
	_mat_selection_box.no_depth_test = true  # reads through the structure it outlines, like the hover highlight

	_selection_box_instance = MeshInstance3D.new()
	_selection_box_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_selection_box_instance.visible = false
	add_child(_selection_box_instance)


## Arbitrary-size wireframe box between absolute world corners `lo`/`hi`
## (mesh vertices are ABSOLUTE coordinates -- the instance itself stays at
## identity transform, same convention _build_ghost_mesh uses).
func _build_wireframe_box_mesh(lo: Vector3, hi: Vector3, color: Color) -> ArrayMesh:
	var corners: Array[Vector3] = [
		Vector3(lo.x, lo.y, lo.z), Vector3(hi.x, lo.y, lo.z), Vector3(hi.x, lo.y, hi.z), Vector3(lo.x, lo.y, hi.z),
		Vector3(lo.x, hi.y, lo.z), Vector3(hi.x, hi.y, lo.z), Vector3(hi.x, hi.y, hi.z), Vector3(lo.x, hi.y, hi.z),
	]
	var edge_pairs: Array = [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]]
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	for pair: Array in edge_pairs:
		verts.append(corners[pair[0]])
		verts.append(corners[pair[1]])
		colors.append(color)
		colors.append(color)
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh.surface_set_material(0, _mat_selection_box)
	return mesh


## Rebuilds the selection wireframe from the selected project's cell-set
## bounding box (inflated by SELECTION_BOX_INFLATE). Connected to
## projects_changed so it stays in sync with attach/demolish/cancel; also
## clears the selection entirely if the selected project disappeared.
func _refresh_selection_visual() -> void:
	if _selected_project_id != null and not _projects.has(int(_selected_project_id)):
		_selected_project_id = null
		project_selected.emit(null)
	if _selected_project_id == null:
		_selection_box_instance.visible = false
		return
	var project: Dictionary = _projects[int(_selected_project_id)]
	var cells: Array = project["all_cells"].keys()
	if cells.is_empty():
		_selection_box_instance.visible = false
		return
	var min_c: Vector3i = cells[0]
	var max_c: Vector3i = cells[0]
	for c: Vector3i in cells:
		min_c = Vector3i(mini(min_c.x, c.x), mini(min_c.y, c.y), mini(min_c.z, c.z))
		max_c = Vector3i(maxi(max_c.x, c.x), maxi(max_c.y, c.y), maxi(max_c.z, c.z))
	var lo: Vector3 = Vector3(min_c.x, min_c.y, min_c.z) - Vector3.ONE * SELECTION_BOX_INFLATE
	var hi: Vector3 = Vector3(max_c.x + 1, max_c.y + 1, max_c.z + 1) + Vector3.ONE * SELECTION_BOX_INFLATE
	_selection_box_instance.mesh = _build_wireframe_box_mesh(lo, hi, SELECTION_BOX_COLOR)
	_selection_box_instance.visible = true


func _cell_center(cell: Vector3i) -> Vector3:
	return Vector3(cell.x + 0.5, cell.y + 0.5, cell.z + 0.5)
