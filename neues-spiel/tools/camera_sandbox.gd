## Camera feel-check sandbox tool (Sprint-4 QA plan ADVISORY windowed
## camera-feel check). NOT part of the production boot chain and NOT wired
## into `GameWorld`/`Valley` -- a standalone tool scene, run WINDOWED (a real,
## driven [Camera3D] needs a live viewport; this cannot usefully run
## headless). It:
##  1. Constructs a real [VoxelWorldGrid] + the real production
##     [VoxelWorldMesher] (same classes `src/voxel_world/` ships -- mirrors
##     `tools/mesher_evidence.gd`'s precedent: evidence/feel-checks FOR the
##     production classes, never a reimplementation of them) and generates a
##     modest, deterministic, seeded terrain extent with some height variety.
##  2. Lights the terrain via the real, shipped [WorldLighting] production
##     class (Story presentation-004, AC6) driving a local
##     [DirectionalLight3D] + [WorldEnvironment] this tool still hosts itself
##     (this standalone sandbox never boots a real `GameWorld`/`Valley`, so
##     there is no shipped Valley to read the lighting FROM -- reusing the
##     real [WorldLighting] class + its real `.tres` config is what keeps
##     this tool from hand-rolling a second, independently-drifting lighting
##     recipe, which is exactly what this story closes).
##  3. Hosts a real [CameraInput] (the same production class
##     `src/camera_input/` ships, ADR-0002) as a child node -- once its
##     `config` is assigned and [method CameraInput.setup] is called, it owns
##     ALL input itself (middle-drag orbit, Q/E yaw, mouse-wheel zoom, WASD
##     pan) via its own `_unhandled_input`/`_process`; this tool never
##     reimplements any of that input handling.
##  4. Drives a real [Camera3D]'s transform every frame from
##     [method CameraInput.get_camera_position] / [method CameraInput.get_target]
##     -- the ONLY per-frame work this tool's own script does.
##  5. Shows a small on-screen control-legend [Label] (top-left, baked into
##     the scene) and wires Esc (`ui_cancel`, Godot's built-in default action)
##     to quit.
##
## Run via (WINDOWED -- do not pass --headless):
##   Godot_v4.7-stable_win64.exe --path neues-spiel res://tools/camera_sandbox.tscn
extends Node3D

## Deterministic seeded terrain extent for this feel-check -- modest but with
## some height variety (see [method _build_and_mesh_world]'s amplitude/
## frequency overrides), still fast to mesh in one shot at boot.
## [member CameraInputConfig.world_width_cells]/`world_depth_cells` below are
## set to match, so WASD pan clamps to the SAME extent this tool actually
## meshed.
const WORLD_EXTENT_CELLS := 160

var _grid: VoxelWorldGrid
var _mesher: VoxelWorldMesher

@onready var _camera: Camera3D = $Camera3D
@onready var _light: DirectionalLight3D = $DirectionalLight3D
@onready var _world_environment: WorldEnvironment = $WorldEnvironment
@onready var _camera_input: CameraInput = $CameraInput

## Story presentation-004 (AC6) -- the real, shipped lighting module, reused
## here instead of a hand-rolled recipe. Not itself a scene child (this tool
## does not need it Inspector-wired; it is constructed and `setup()` exactly
## once in [method _setup_lighting_and_sky]).
var _world_lighting: WorldLighting


func _ready() -> void:
	_build_and_mesh_world()
	_setup_lighting_and_sky()
	_setup_camera_input()
	_camera.current = true
	# This node's own [method _process] (which mirrors CameraInput's derived
	# position/target onto the real Camera3D) must run AFTER CameraInput's
	# own _process (WASD pan) each frame, or a held pan key would visibly lag
	# one frame behind. CameraInput is left at the default process_priority
	# (0); bumping this root node's priority to 1 guarantees that ordering.
	process_priority = 1


## Builds a real [VoxelWorldGrid] with a deterministic seeded terrain extent,
## then meshes every chunk in that extent via a real [VoxelWorldMesher] --
## the SAME production classes `src/voxel_world/` ships, called directly
## (mirrors `tools/mesher_evidence.gd`'s established pattern: a fixed extent
## meshed once at boot, not Story 015's view-window streaming).
func _build_and_mesh_world() -> void:
	_grid = VoxelWorldGrid.new()
	add_child(_grid)
	var world_config := VoxelWorldConfig.new()
	world_config.world_width_cells = WORLD_EXTENT_CELLS
	world_config.world_depth_cells = WORLD_EXTENT_CELLS
	world_config.amplitude = 6.0
	world_config.frequency = 0.04
	_grid.config = world_config
	_grid.generate_terrain()

	_mesher = VoxelWorldMesher.new()
	add_child(_mesher)
	_mesher.grid = _grid
	_mesher.setup()

	var chunk_span: int = WORLD_EXTENT_CELLS / VoxelWorldGrid.CHUNK_SIZE
	for chunk_x in chunk_span:
		for chunk_z in chunk_span:
			_mesher.build_chunk(Vector2i(chunk_x, chunk_z))


## Story presentation-004 (AC6) -- lights the terrain via the real, shipped
## [WorldLighting] class + the real `.tres` config, instead of this tool's
## own former hand-rolled (and NOT golden-hour -- a plain blue-sky readability
## rig) recipe. This tool's own [DirectionalLight3D]/[WorldEnvironment] nodes
## are still hosted locally (this sandbox never boots a real `Valley` to read
## lighting from), but the VALUES applied to them now come from the same
## config every other consumer reads.
func _setup_lighting_and_sky() -> void:
	_world_lighting = WorldLighting.new()
	add_child(_world_lighting)
	_world_lighting.config = load("res://data/config/world_lighting_config.tres")
	_world_lighting.directional_light = _light
	_world_lighting.world_environment = _world_environment
	_world_lighting.setup()


## Wires the child [CameraInput]'s config and calls its own explicit
## [method CameraInput.setup] entry point (ADR-0001) -- never reads it before
## that, matching the production wiring contract. `start_distance` is bumped
## from [CameraInputConfig]'s own default (18.0) to 45.0 for a sensible
## initial framing of this tool's larger-than-default 160x160 extent; every
## other knob is left at its GDD default.
func _setup_camera_input() -> void:
	var camera_config := CameraInputConfig.new()
	camera_config.world_width_cells = WORLD_EXTENT_CELLS
	camera_config.world_depth_cells = WORLD_EXTENT_CELLS
	camera_config.start_distance = 45.0
	_camera_input.config = camera_config
	_camera_input.setup()

	# CameraInput exposes no public setter for its initial orbit target
	# ([method CameraInput.get_target] is read-only; [method CameraInput.setup]
	# always resets the target to Vector3.ZERO) -- deliberately, since the
	# GDD's only sanctioned target mutation is the WASD pan formula. This tool
	# seeds it directly, ONCE, immediately after setup(), purely so the sandbox
	## opens already framing the terrain's center instead of its (0,0,0)
	# corner. This is a documented, deliberate reach into CameraInput's
	# internal state for this standalone feel-check tool only -- never done in
	# production code, and camera_input.gd itself is untouched.
	var center: float = float(WORLD_EXTENT_CELLS) / 2.0
	_camera_input._target = Vector3(center, 4.0, center)


## This tool's ONE per-frame job: mirror the real [Camera3D]'s transform from
## [CameraInput]'s derived, never-independently-stored position/target every
## frame [TR-camera-input-021] -- [CameraInput] itself owns all input
## handling; this tool never reimplements any of it.
func _process(_delta: float) -> void:
	_camera.position = _camera_input.get_camera_position()
	_camera.look_at(_camera_input.get_target(), Vector3.UP)


## Esc quits -- `ui_cancel` is Godot's built-in default action for Escape
## (already registered at the engine level, no `project.godot` change needed).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_tree().quit()
