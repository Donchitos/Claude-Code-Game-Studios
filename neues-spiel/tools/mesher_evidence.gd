## Story vox-007 screenshot-evidence capture tool (sprint-4 QA plan BLOCKING
## manual-evidence gate for the mesher CW-winding/culling exit criterion).
## NOT part of the production boot chain and NOT wired into
## `GameWorld`/`Valley` -- a standalone tool scene, run WINDOWED (headless
## cannot render a viewport texture). It:
##  1. Constructs a real [VoxelWorldGrid] + the real production
##     [VoxelWorldMesher] (same classes `src/voxel_world/` ships -- this is
##     evidence FOR the production mesher, not a reimplementation of it) and
##     generates a modest, deterministic, seeded terrain extent.
##  2. Meshes every chunk in that extent directly (a fixed extent, per the
##     story's Out-of-Scope note -- view-window streaming is Story 015, not
##     exercised here).
##  3. Adds a [DirectionalLight3D] + [WorldEnvironment] so shaded faces read
##     clearly, and captures TWO vantages: top-down, then a low oblique sweep
##     (the oblique angle is where the vertical slice's historical "missing
##     faces" defect showed most clearly against cliff/side faces).
##  4. Writes both PNGs to `production/qa/evidence/` and quits.
##
## Run via (WINDOWED -- do not pass --headless):
##   Godot_v4.7-stable_win64.exe --path neues-spiel res://tools/mesher_evidence.tscn
extends Node3D

## Kept well within [VoxelWorldConfig]'s validated 256-2048 range would be
## nicer, but this tool assigns [member VoxelWorldConfig] directly and never
## calls [method VoxelWorldGrid.setup] (matching this codebase's established
## direct-config-assignment test precedent, e.g.
## `tests/unit/voxel_world/chunked_cell_storage_test.gd`) -- so the
## clamp-on-`validate()` path never runs and this modest, fast-to-mesh extent
## is used as-is, per the task's own "modest extent, e.g. 128x128" guidance.
const WORLD_EXTENT_CELLS := 128

## Evidence output file names (sprint-4 QA plan naming:
## `vox-007-terrain-YYYYMMDD-N.png`).
const EVIDENCE_FILE_NAMES: Array[String] = [
	"vox-007-terrain-20260724-1.png",  # vantage 1: top-down
	"vox-007-terrain-20260724-2.png",  # vantage 2: low oblique
]

var _grid: VoxelWorldGrid
var _mesher: VoxelWorldMesher

@onready var _camera: Camera3D = $Camera3D
@onready var _light: DirectionalLight3D = $DirectionalLight3D
@onready var _world_environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	_build_and_mesh_world()
	_setup_lighting_and_sky()
	await _run_capture_sequence()


## Builds a real [VoxelWorldGrid] with a deterministic seeded terrain extent,
## then meshes every chunk in that extent via a real [VoxelWorldMesher] --
## the SAME production classes `src/voxel_world/` ships, called directly
## (this tool's `build_chunk` loop stands in for Story 015's view-window
## streaming, out of this story's scope).
func _build_and_mesh_world() -> void:
	_grid = VoxelWorldGrid.new()
	add_child(_grid)
	var config := VoxelWorldConfig.new()
	config.world_width_cells = WORLD_EXTENT_CELLS
	config.world_depth_cells = WORLD_EXTENT_CELLS
	_grid.config = config
	_grid.generate_terrain()

	_mesher = VoxelWorldMesher.new()
	add_child(_mesher)
	_mesher.grid = _grid
	_mesher.setup()

	var chunk_span: int = WORLD_EXTENT_CELLS / VoxelWorldGrid.CHUNK_SIZE
	for chunk_x in chunk_span:
		for chunk_z in chunk_span:
			_mesher.build_chunk(Vector2i(chunk_x, chunk_z))


## A directional "sun" + a solid sky background (not black) so a hole in the
## mesh (a missing face) shows the SKY color through it -- the "no
## see-through cliffs" check depends on the background being visually
## distinct from terrain, not merely on shading.
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


## Captures the two required vantages (sprint-4 QA plan: "full 360°/pitch
## orbit" is a manual-review concept; this automated tool captures the two
## anchor angles the task calls out explicitly -- top-down and low oblique,
## the latter historically where the vertical slice's missing faces showed).
## Waits 3 frames after each camera move before capturing, so the moved
## camera's frame is actually the one rendered into the viewport texture.
func _run_capture_sequence() -> void:
	var center: float = float(WORLD_EXTENT_CELLS) / 2.0
	_camera.current = true

	# Vantage 1: top-down.
	_camera.position = Vector3(center, 100.0, center)
	_camera.look_at(Vector3(center, 0.0, center), Vector3(0.0, 0.0, -1.0))
	for _i in 3:
		await get_tree().process_frame
	_capture_and_save(EVIDENCE_FILE_NAMES[0])

	# Vantage 2: low oblique sweep -- camera held above terrain height (terrain
	# tops out well under y=14 at this config's base_height/amplitude
	# defaults) but aimed at a shallow downward angle across a long diagonal
	# of the meshed extent, so cliff/side faces are seen edge-on.
	_camera.position = Vector3(center - 60.0, 14.0, center - 60.0)
	_camera.look_at(Vector3(center + 20.0, 2.0, center + 20.0), Vector3.UP)
	for _i in 3:
		await get_tree().process_frame
	_capture_and_save(EVIDENCE_FILE_NAMES[1])

	get_tree().quit()


## Captures the current viewport frame and writes it to
## `production/qa/evidence/[param file_name]` (repo-root-relative -- the
## Godot project root is `neues-spiel/`, one level below the repo root where
## `production/` lives).
func _capture_and_save(file_name: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	var evidence_dir: String = ProjectSettings.globalize_path("res://../production/qa/evidence")
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	var path: String = evidence_dir.path_join(file_name)
	var err: Error = image.save_png(path)
	if err != OK:
		push_error("mesher_evidence: failed to save %s (error %d)" % [path, err])
	else:
		print("mesher_evidence: saved %s" % path)
