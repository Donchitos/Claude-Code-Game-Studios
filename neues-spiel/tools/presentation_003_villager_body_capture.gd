## Presentation Experience story presentation-003 (Villager body view, hit
## proxy & slice hook) advisory screenshot capture tool.
##
## NOT part of the production boot chain -- standalone, run WINDOWED
## (headless cannot render a viewport texture), mirroring
## `tools/m01_c4_valley_ambient_capture.gd`'s established pattern: boots the
## REAL, UNMODIFIED `res://src/scene_world_management/game_world.tscn`
## through the real `ResourceItemDatabase` autoload, waits for the real boot
## gate to reach ACTIVE (which -- story scene-005 -- also drives real world
## genesis and this story's own `VillagerBodyPresenter.setup()`), then frames
## the camera on the hardwired villager's REAL [VillagerBodyView] (villager_id
## 0) for two captures:
##   1. A readable 2-block figure at settlement-camera distance.
##   2. The SAME villager sliced away via a real `set_slice_level()` call
##      below its own cell.
##
## Golden-hour lighting + a placeholder ground plane are supplied by THIS
## tool only (reused verbatim from `tools/m01_c4_valley_ambient_capture.gd`'s
## own `design/art/art-bible.md` §2.1 recipe) -- neither `Valley.tscn` nor
## `GameWorld.tscn` gains any lighting/environment node from this tool.
##
## Run via (WINDOWED -- do not pass --headless):
##   Godot_v4.7-stable_win64_console.exe --path neues-spiel res://tools/presentation_003_villager_body_capture.tscn
extends Node3D

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")

const EVIDENCE_DIR := "res://../production/qa/evidence"
const STANDING_PNG := "presentation-003-villager-body-standing-20260727-1.png"
const SLICED_PNG := "presentation-003-villager-body-sliced-20260727-2.png"

## Hard wall-clock safety cap (real seconds since boot) -- mirrors
## `tools/m01_c4_valley_ambient_capture.gd`'s own "the scene must self-quit"
## safety-cap precedent.
const SAFETY_CAP_SEC := 30.0

@onready var _camera: Camera3D = $Camera3D
@onready var _light: DirectionalLight3D = $DirectionalLight3D
@onready var _world_environment: WorldEnvironment = $WorldEnvironment

var _world: GameWorld
var _boot_start_usec: int = 0
var _phase: int = 0  # 0 = waiting for boot, 1 = settling/capture 1, 2 = sliced/capture 2, 3 = done
var _settle_frames_remaining: int = 5
var _view: VillagerBodyView = null

## Placeholder ground plane, capture-only (mirrors
## `tools/m01_c4_valley_ambient_capture.gd`'s own "no fixture-art pipeline
## exists yet" precedent) -- the real Valley boots with a genuinely empty
## [VoxelWorldGrid].
var _ground_plane: MeshInstance3D


func _ready() -> void:
	_boot_start_usec = Time.get_ticks_usec()
	_apply_golden_hour_lighting()
	_build_capture_only_ground_plane()
	_world = GameWorldScene.instantiate()
	add_child(_world)


func _build_capture_only_ground_plane() -> void:
	_ground_plane = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(12.0, 0.2, 12.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("8B6A4A")
	mesh.material = material
	_ground_plane.mesh = mesh
	_ground_plane.position = Vector3(0.5, -0.6, 0.5)
	add_child(_ground_plane)


## `design/art/art-bible.md` §2.1 golden-hour recipe, reused verbatim from
## `tools/m01_c4_valley_ambient_capture.gd`.
func _apply_golden_hour_lighting() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.85, 0.68, 0.5)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.98, 0.94, 0.86)
	environment.ambient_light_energy = 0.5
	environment.ssao_enabled = false
	_world_environment.environment = environment

	_light.rotation_degrees = Vector3(-42.0, -35.0, 0.0)
	_light.light_color = Color(1.0, 0.93, 0.80)
	_light.light_energy = 1.7
	_light.shadow_enabled = true
	_light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_light.directional_shadow_max_distance = 90.0
	_light.shadow_blur = 1.0

	_camera.current = true
	_camera.far = 200.0


func _process(_delta: float) -> void:
	var elapsed_since_boot_sec: float = (Time.get_ticks_usec() - _boot_start_usec) / 1000000.0
	if elapsed_since_boot_sec > SAFETY_CAP_SEC and _phase != 3:
		push_warning("presentation_003_villager_body_capture: SAFETY CAP hit (%0.1fs) -- forcing early quit" % elapsed_since_boot_sec)
		get_tree().quit()
		return

	match _phase:
		0:
			_wait_for_boot_active()
		1:
			_settle_and_capture_standing()
		2:
			_capture_sliced()
		_:
			pass


func _wait_for_boot_active() -> void:
	if _world.get_boot_state() != GameWorld.BootState.ACTIVE:
		return
	print("presentation_003_villager_body_capture: real GameWorld reached ACTIVE")
	var valley: Valley = _world.get_valley() as Valley
	var presenter: VillagerBodyPresenter = valley.get_villager_body_presenter()
	_view = presenter.get_view_for(0)
	if _view == null:
		push_error("presentation_003_villager_body_capture: no VillagerBodyView for villager_id 0")
		get_tree().quit()
		return
	_phase = 1


## Frames the camera on the hardwired villager's REAL body view at
## settlement-camera distance, holds a few settle frames so the just-moved
## camera's own frame is the one rendered, then captures the "standing,
## readable 2-block figure" PNG.
func _settle_and_capture_standing() -> void:
	var body_position: Vector3 = _view.global_position
	_camera.position = body_position + Vector3(-3.0, 2.2, 3.0)
	_camera.look_at(body_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)

	_settle_frames_remaining -= 1
	if _settle_frames_remaining > 0:
		return

	_capture_png(STANDING_PNG)
	_phase = 2
	_settle_frames_remaining = 3


## Slices the villager away via a REAL `set_slice_level()` call below its
## own discrete cell (the story's own Slice View contract -- TRAP 1/2:
## visibility + hit-proxy layer both flip, Selection is never touched), holds
## a few settle frames, then captures the "sliced away" PNG.
func _capture_sliced() -> void:
	if _settle_frames_remaining == 3:
		var current_cell: Vector3i = (_view.ai_source as VillagerAi).get_current_cell()
		_view.set_slice_level(current_cell.y - 1)

	_settle_frames_remaining -= 1
	if _settle_frames_remaining > 0:
		return

	_capture_png(SLICED_PNG)
	_phase = 3
	print("presentation_003_villager_body_capture: capture complete, quitting")
	get_tree().quit()


func _capture_png(file_name: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	var evidence_dir: String = ProjectSettings.globalize_path(EVIDENCE_DIR)
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	var path: String = evidence_dir.path_join(file_name)
	var err: Error = image.save_png(path)
	if err != OK:
		push_error("presentation_003_villager_body_capture: failed to save %s (error %d)" % [path, err])
	else:
		print("presentation_003_villager_body_capture: saved %s" % path)
