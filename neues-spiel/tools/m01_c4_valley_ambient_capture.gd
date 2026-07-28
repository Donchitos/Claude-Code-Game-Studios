## M01 Go/No-Go condition C4 golden-hour capture tool (`production/milestones/
## milestone-01-review-2026-07-26.md`; CD advisory #2,
## `production/qa/evidence/ambient-life-wave-1-evidence.md` sign-off point 2:
## "The integration story must place these components in the §2.1 golden-hour
## environment and re-shoot").
##
## NOT part of the production boot chain -- a standalone tool scene, run
## WINDOWED (headless cannot render a viewport texture), mirroring
## `tools/ambient_life_evidence.gd`/`tools/vox018_60fps_culling_measurement.gd`'s
## established pattern -- with ONE deliberate difference from both: instead of
## hand-building the ambient components again in isolation, this tool
## instantiates the REAL, UNMODIFIED `res://src/scene_world_management/
## game_world.tscn` (the project's actual `run/main_scene`) and lets it boot
## through the REAL `ResourceItemDatabase` autoload exactly like a real play
## session would -- proving `TorchFlicker` is genuinely wired into the shipped
## `Valley`, not a stand-in rebuild of it (the criterion's own wording: "visible
## in the build").
##
## Story presentation-004 (AC6, "The world has no sun") -- golden-hour
## lighting used to be supplied by THIS tool only (`_apply_golden_hour_
## lighting`, since removed), because before that story neither
## `Valley.tscn` nor `GameWorld.tscn` owned any lighting/environment node at
## all. That gap is now closed: `Valley` hosts a real [WorldLighting] module
## driving a real [DirectionalLight3D]/[WorldEnvironment], config-driven
## (ADR-0002, `res://data/config/world_lighting_config.tres`). This tool no
## longer applies its own recipe -- the real, unmodified `GameWorldScene`
## lights itself, and if it didn't, this capture would show that honestly
## instead of masking it.
##
## Run via (WINDOWED -- do not pass --headless):
##   Godot_v4.7-stable_win64_console.exe --path neues-spiel res://tools/m01_c4_valley_ambient_capture.tscn
extends Node3D

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")

const EVIDENCE_DIR := "res://../production/qa/evidence"
const TOPDOWN_PNG := "m01-c4-valley-golden-hour-20260726-1.png"
const CLOSEUP_PNG := "m01-c4-valley-golden-hour-torch-closeup-20260726-2.png"

## Hard wall-clock safety cap (real seconds since boot) -- forces an early
## quit if the real boot gate never settles, mirroring
## `tools/vox018_60fps_culling_measurement.gd`'s own "the scene must self-quit"
## safety-cap precedent.
const SAFETY_CAP_SEC := 30.0

@onready var _camera: Camera3D = $Camera3D

var _world: GameWorld
var _boot_start_usec: int = 0
var _phase: int = 0  # 0 = waiting for boot, 1 = settling, 2 = done
var _settle_frames_remaining: int = 5


## A small placeholder ground plane purely for THIS capture's own visual
## legibility (no fixture-art pipeline exists yet, mirrors
## `tools/ambient_life_evidence.gd`'s own "crude placeholder hut/room" shell
## precedent exactly) -- NOT part of `Valley`/`GameWorld` in any way; the real
## Valley boots with a genuinely empty [VoxelWorldGrid] (that class's own doc
## comment: "a fresh grid has no terrain yet," a future world-generation
## story's job). Without SOME surface to catch the warm key light, an empty
## scene reads as a flat color field regardless of how correctly
## [TorchFlicker] is wired -- this plane exists only so the shipped lighting
## and the torch glow are visibly legible in the screenshot.
var _ground_plane: MeshInstance3D


func _ready() -> void:
	_boot_start_usec = Time.get_ticks_usec()
	_camera.current = true
	_camera.far = 200.0
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


func _process(_delta: float) -> void:
	var elapsed_since_boot_sec: float = (Time.get_ticks_usec() - _boot_start_usec) / 1000000.0
	if elapsed_since_boot_sec > SAFETY_CAP_SEC and _phase != 2:
		push_warning("m01_c4_valley_ambient_capture: SAFETY CAP hit (%0.1fs) -- forcing early quit" % elapsed_since_boot_sec)
		get_tree().quit()
		return

	match _phase:
		0:
			_wait_for_boot_active()
		1:
			_settle_and_capture()
		_:
			pass


func _wait_for_boot_active() -> void:
	if _world.get_boot_state() != GameWorld.BootState.ACTIVE:
		return
	print("m01_c4_valley_ambient_capture: real GameWorld reached ACTIVE")
	_phase = 1


## Frames the camera on the hosted [TorchFlicker]'s real [Light3D] (the ONE
## Sub-scope A element actually wired into this real, running Valley -- see
## `src/scene_world_management/valley.gd`'s own class doc comment for the
## honest scope note on the other three), holds a few settle frames so the
## just-moved camera's own frame is the one rendered, then captures TWO PNGs
## at different real elapsed moments so the flicker is visible across frames
## (mirrors `tools/ambient_life_evidence.gd`'s own torch-vantage convention).
func _settle_and_capture() -> void:
	var valley: Valley = _world.get_valley() as Valley
	var torch_light: Light3D = valley.get_ambient_torch_light()
	var torch_world_position: Vector3 = torch_light.global_position

	# Sync the indicator sphere's rendered brightness to the REAL, currently
	# flickering `light_energy` value -- mirrors `tools/ambient_life_evidence.gd`'s
	# own `_update_torch_indicator` convention, so the capture visibly reflects
	# [TorchFlicker]'s live output, not a fixed default.
	var indicator: MeshInstance3D = torch_light.get_node_or_null(^"AmbientTorchIndicator") as MeshInstance3D
	if indicator != null:
		var material: StandardMaterial3D = indicator.mesh.surface_get_material(0) as StandardMaterial3D
		if material != null:
			material.emission_energy_multiplier = torch_light.light_energy

	_camera.position = torch_world_position + Vector3(-4.0, 2.5, 4.0)
	_camera.look_at(torch_world_position, Vector3.UP)

	_settle_frames_remaining -= 1
	if _settle_frames_remaining > 0:
		return

	if _settle_frames_remaining == 0:
		_capture_png(TOPDOWN_PNG)
		await get_tree().create_timer(0.6).timeout
		_capture_png(CLOSEUP_PNG)
		_phase = 2
		print("m01_c4_valley_ambient_capture: capture complete, quitting")
		get_tree().quit()


func _capture_png(file_name: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	var evidence_dir: String = ProjectSettings.globalize_path(EVIDENCE_DIR)
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	var path: String = evidence_dir.path_join(file_name)
	var err: Error = image.save_png(path)
	if err != OK:
		push_error("m01_c4_valley_ambient_capture: failed to save %s (error %d)" % [path, err])
	else:
		print("m01_c4_valley_ambient_capture: saved %s" % path)
