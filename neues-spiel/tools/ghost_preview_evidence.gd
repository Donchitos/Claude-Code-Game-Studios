## Story building-023 screenshot-evidence capture tool (Visual/Feel ADVISORY
## evidence gate: "production/qa/evidence/ghost-preview-rendering-evidence.md
## (screenshots) + lead sign-off"). NOT part of the production boot chain and
## NOT wired into `GameWorld`/`Valley` -- a standalone tool scene, run
## WINDOWED (headless cannot render a viewport texture), mirroring
## `tools/mesher_evidence.gd`'s established pattern exactly: real production
## classes (VoxelWorldGrid/VoxelWorldMesher/ToolStateMachine/PlacementPick/
## CommitPipeline/GhostPreview), a fixed deterministic extent, captured
## vantages written to `production/qa/evidence/`.
##
## Captures, in order:
##  1. AC1/TR-093: the live ghost preview following a VALID pick -- State Blue
##     translucent per-cell ghost(s).
##  2. TR-093: the SAME pick, but with nothing selected (Core Rule 9's
##     material-availability rejection) -- State Orange translucent ghost(s).
##  3. AC50: a drag whose candidate set exceeds `preview_degradation_threshold`
##     -- a wireframe bounding-box outline instead of per-cell ghosts.
##  4. TR-069: two PERSISTED blueprint ghosts side by side -- one Planned
##     (lower alpha), one UnderConstruction (higher alpha) -- read distinctly
##     at a glance.
##
## This tool drives [PlacementPick] via [method PlacementPick.resolve_pick]'s
## explicit-ray parameter throughout (this codebase's established
## direct-method-call test/tool convention, e.g. `mesher_evidence.gd`'s own
## direct-construction precedent) rather than a fully-aimed [CameraInput] --
## a bare, never-`setup()`'d [CameraInput] placeholder satisfies
## [PlacementPick]'s wiring assert only. The tool's OWN [Camera3D] (a separate
## node) frames the screenshot.
##
## Run via (WINDOWED -- do not pass --headless):
##   Godot_v4.7-stable_win64.exe --path neues-spiel res://tools/ghost_preview_evidence.tscn
extends Node3D

const WORLD_EXTENT_CELLS := 32

const EVIDENCE_FILE_NAMES: Dictionary[String, String] = {
	"valid": "building-023-ghost-preview-valid-blue-20260726-1.png",
	"invalid": "building-023-ghost-preview-invalid-orange-20260726-1.png",
	"degraded": "building-023-ghost-preview-degraded-outline-20260726-1.png",
	"persistent": "building-023-ghost-preview-planned-vs-under-construction-20260726-1.png",
}

var _grid: VoxelWorldGrid
var _mesher: VoxelWorldMesher
var _machine: ToolStateMachine
var _pick: PlacementPick
var _pipeline: CommitPipeline
var _preview: GhostPreview

@onready var _camera: Camera3D = $Camera3D
@onready var _light: DirectionalLight3D = $DirectionalLight3D
@onready var _world_environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	_build_and_mesh_world()
	_setup_lighting_and_sky()
	_build_building_system_harness()
	await _run_capture_sequence()


## Builds a real [VoxelWorldGrid] + [VoxelWorldMesher] terrain patch -- mirrors
## `tools/mesher_evidence.gd`'s established construction precedent -- a flat
## solid slab at y=0 so every pick attaches cleanly at y=1.
func _build_and_mesh_world() -> void:
	_grid = VoxelWorldGrid.new()
	add_child(_grid)
	var config := VoxelWorldConfig.new()
	config.world_width_cells = WORLD_EXTENT_CELLS
	config.world_depth_cells = WORLD_EXTENT_CELLS
	_grid.config = config
	_grid.setup()
	var changes: Dictionary[Vector3i, CellContents] = {}
	for x in WORLD_EXTENT_CELLS:
		for z in WORLD_EXTENT_CELLS:
			changes[Vector3i(x, 0, z)] = CellContents.new(1, 0)
	_grid.bulk_write(changes)

	_mesher = VoxelWorldMesher.new()
	add_child(_mesher)
	_mesher.grid = _grid
	_mesher.setup()

	var chunk_span: int = WORLD_EXTENT_CELLS / VoxelWorldGrid.CHUNK_SIZE
	for chunk_x in chunk_span:
		for chunk_z in chunk_span:
			_mesher.build_chunk(Vector2i(chunk_x, chunk_z))


func _setup_lighting_and_sky() -> void:
	_light.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	_light.light_energy = 1.1

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.55, 0.72, 0.85)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.35, 0.35, 0.4)
	environment.ambient_light_energy = 1.0
	_world_environment.environment = environment


## Wires the real Building System chain this story's evidence needs --
## [ToolStateMachine]/[PlacementPick]/[CommitPipeline]/[GhostPreview] -- the
## SAME production classes `src/building_system/` ships, called directly.
func _build_building_system_harness() -> void:
	# `_machine`/`_pick`/its `CameraInput` placeholder/`_pipeline` are
	# deliberately NEVER added to the scene tree -- this tool drives every
	# pick via `resolve_pick`'s explicit-ray parameter directly (never
	# `update_pick`'s camera-driven path), mirroring this codebase's
	# established direct-method-call test convention; a bare `CameraInput`
	# with no `.config`/`setup()` would otherwise crash the instant the
	# engine's automatic per-frame `_process()` dispatch reached it. Only
	# `_preview` (whose pooled `MeshInstance3D` children must actually render
	# for a screenshot to show them) is added below.
	_machine = ToolStateMachine.new()

	_pick = PlacementPick.new()
	_pick.camera_input = CameraInput.new()
	_pick.voxel_world = _grid
	_pick.tool_state_machine = _machine
	_pick.config = PlacementPickConfig.new()
	_pick.setup()

	_pipeline = CommitPipeline.new()
	_pipeline.placement_pick = _pick
	_pipeline.voxel_world = _grid
	_pipeline.config = CommitPipelineConfig.new()
	_pipeline.setup()
	# Force the "no RID reachable" fallback (this class's own documented
	# behavior for a bare/untethered construction) rather than resolving the
	# REAL `ResourceItemDatabase` Autoload this windowed run boots for real --
	# `setup()` lazily resolved it above since it IS reachable here (unlike a
	# headless unit test), so it must be cleared back to null explicitly for
	# a placeholder id to be trusted at face value.
	_pipeline.resource_item_database = null
	_pipeline.set_selected_item(&"placeholder_material")

	_preview = GhostPreview.new()
	add_child(_preview)
	_preview.tool_state_machine = _machine
	_preview.placement_pick = _pick
	_preview.commit_pipeline = _pipeline
	_preview.config = GhostPreviewConfig.new()
	_preview.setup()

	_machine.arm_tool(&"block")


func _run_capture_sequence() -> void:
	_camera.current = true
	await _capture_valid_vantage()
	await _capture_invalid_vantage()
	await _capture_degraded_vantage()
	await _capture_persistent_vantage()
	get_tree().quit()


## AC1/TR-093: a valid pick -- State Blue translucent ghost.
func _capture_valid_vantage() -> void:
	_pick.resolve_pick(Vector3(8.5, 20.0, 8.5), Vector3(0.0, -1.0, 0.0))
	_camera.position = Vector3(8.0, 4.5, 12.5)
	_camera.look_at(Vector3(8.5, 1.5, 8.5), Vector3.UP)
	for _i in 3:
		await get_tree().process_frame
	print("ghost_preview_evidence: valid tint = %s" % _preview.get_live_preview_material().albedo_color)
	_capture_and_save(EVIDENCE_FILE_NAMES["valid"])


## TR-093: nothing selected -- State Orange translucent ghost. A DIFFERENT
## pick cell than the valid vantage -- GhostPreview recomputes on
## `PlacementPick.pick_changed`, which only fires when the resolved cell
## actually changes; re-resolving the SAME ray would re-fire a no-op and
## never pick up the new (now-invalid) selection state.
func _capture_invalid_vantage() -> void:
	_pipeline.set_selected_item(&"")
	_pick.resolve_pick(Vector3(24.5, 20.0, 24.5), Vector3(0.0, -1.0, 0.0))
	_camera.position = Vector3(24.0, 4.5, 28.5)
	_camera.look_at(Vector3(24.5, 1.5, 24.5), Vector3.UP)
	for _i in 3:
		await get_tree().process_frame
	print("ghost_preview_evidence: invalid tint = %s" % _preview.get_live_preview_material().albedo_color)
	_capture_and_save(EVIDENCE_FILE_NAMES["invalid"])
	_pipeline.set_selected_item(&"placeholder_material")


## AC50: a candidate set exceeding `preview_degradation_threshold` degrades
## to a wireframe bounding-box outline instead of per-cell ghosts.
func _capture_degraded_vantage() -> void:
	var threshold: int = _preview.config.preview_degradation_threshold
	var big_cells: Array[Vector3i] = []
	for i in (threshold + 20):
		big_cells.append(Vector3i(i % WORLD_EXTENT_CELLS, 1, i / WORLD_EXTENT_CELLS))
	_pipeline.set_cell_set_resolver(func(_d: bool, _p: Vector3i, _r: Vector3i) -> Array[Vector3i]: return big_cells)
	# A DIFFERENT pick cell than the previous two vantages -- GhostPreview
	# recomputes on `PlacementPick.pick_changed`, which only fires when the
	# resolved cell actually changes; re-resolving the SAME (8.5, 20, 8.5)
	# ray again would be a no-op re-fire and never pick up the new resolver.
	_pick.resolve_pick(Vector3(20.5, 20.0, 20.5), Vector3(0.0, -1.0, 0.0))

	_camera.position = Vector3(float(WORLD_EXTENT_CELLS) / 2.0, 40.0, float(WORLD_EXTENT_CELLS) / 2.0)
	_camera.look_at(Vector3(float(WORLD_EXTENT_CELLS) / 2.0, 0.0, float(WORLD_EXTENT_CELLS) / 2.0), Vector3(0.0, 0.0, -1.0))
	for _i in 3:
		await get_tree().process_frame
	print("ghost_preview_evidence: degraded=%s outline_visible=%s per_cell_count=%s" % [
		_preview.is_live_preview_degraded(), _preview.is_outline_visible(), _preview.get_visible_live_ghost_count()
	])
	_capture_and_save(EVIDENCE_FILE_NAMES["degraded"])
	_pipeline.set_cell_set_resolver(Callable())


## TR-069: two PERSISTED blueprint ghosts side by side -- Planned (lower
## alpha) vs UnderConstruction (higher alpha) -- read distinctly.
func _capture_persistent_vantage() -> void:
	var planned_cell := Vector3i(15, 1, 15)
	var under_construction_cell := Vector3i(18, 1, 15)
	var created_planned: Array[BlueprintCell] = _pipeline.commit([planned_cell])
	var created_under_construction: Array[BlueprintCell] = _pipeline.commit([under_construction_cell])
	created_under_construction[0].state = BlueprintCell.MicroState.UNDER_CONSTRUCTION
	_preview._refresh_blueprint_ghosts()

	_camera.position = Vector3(16.5, 4.0, 20.0)
	_camera.look_at(Vector3(16.5, 1.5, 15.0), Vector3.UP)
	for _i in 3:
		await get_tree().process_frame
	print("ghost_preview_evidence: planned_alpha=%s under_construction_alpha=%s" % [
		_preview.get_blueprint_ghost_material(planned_cell).albedo_color.a,
		_preview.get_blueprint_ghost_material(under_construction_cell).albedo_color.a,
	])
	print("ghost_preview_evidence: created_planned=%s" % created_planned.size())
	_capture_and_save(EVIDENCE_FILE_NAMES["persistent"])


func _capture_and_save(file_name: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	var evidence_dir: String = ProjectSettings.globalize_path("res://../production/qa/evidence")
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	var path: String = evidence_dir.path_join(file_name)
	var err: Error = image.save_png(path)
	if err != OK:
		push_error("ghost_preview_evidence: failed to save %s (error %d)" % [path, err])
	else:
		print("ghost_preview_evidence: saved %s" % path)
