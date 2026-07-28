# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: full build->furnish->live loop, unguided <=5 min, cozy at scale
# Date: 2026-07-12
extends Node3D

# ---------------------------------------------------------------------------
# CameraInput — free-orbit camera + raw input pipeline for the slice.
# Orbit rig per design/gdd/camera-input.md; values below are SLICE-SPECIFIC
# overrides handed down by the integrator (see deviations in the hand-off
# summary) — distance/yaw/pitch defaults and clamps differ from the GDD's
# tuning-knob table on purpose for this prototype.
# ---------------------------------------------------------------------------

const DISTANCE_DEFAULT: float = 24.0
const YAW_DEFAULT: float = 0.8
const PITCH_DEFAULT: float = 1.0  # colony-builder default: look AT the ground
const PITCH_MIN: float = 0.3
const PITCH_MAX: float = 1.4
const DISTANCE_MIN: float = 8.0
const DISTANCE_MAX: float = 120.0
const ZOOM_FACTOR_IN: float = 0.9
const ZOOM_FACTOR_OUT: float = 1.1
const MOUSE_DRAG_SENSITIVITY: float = 0.005
const Q_E_ROTATE_STEP: float = 0.35
const PAN_SPEED_FACTOR: float = 1.2
const MAX_RAW_DELTA: float = 0.1
const TARGET_Y: float = 10.0

const NAMED_ACTIONS: Array[String] = [
	"tool_select_1", "tool_select_2", "tool_select_3", "tool_select_4", "tool_select_5",
	"tool_select_6", "tool_select_7", "tool_select_8",
	"build_cancel", "undo", "redo",
	"height_step_up", "height_step_down",
	"palette_next", "palette_prev",
	"formation_next", "formation_prev",
	"time_pause", "time_speed_up", "time_speed_down",
	"slice_up", "slice_down", "slice_reset",
]

signal action_fired(action_name: String)  # tool_select_1..8, build_cancel, undo, redo,
											# height_step_up/down, palette_next/prev,
											# formation_next/prev, time_pause, time_speed_up/down,
											# slice_up/slice_down/slice_reset (BUILD UX PACKAGE, 2026-07-22)
signal build_click(pressed: bool)         # LMB press/release IN WORLD — _unhandled_input only

var remove_modifier_held: bool = false

var _camera: Camera3D
var _yaw: float = YAW_DEFAULT
var _pitch: float = PITCH_DEFAULT
var _distance: float = DISTANCE_DEFAULT
var _target_x: float = 0.0
var _target_z: float = 0.0
var _bounds_min: Vector3 = Vector3(-1000000.0, -1000000.0, -1000000.0)
var _bounds_max: Vector3 = Vector3(1000000.0, 1000000.0, 1000000.0)
var _rotating: bool = false


func _init() -> void:
	_camera = Camera3D.new()
	_camera.current = true
	add_child(_camera)


func _ready() -> void:
	_update_camera_transform()


func _process(delta: float) -> void:
	var raw_delta: float = clamp(delta, 0.0, MAX_RAW_DELTA)
	remove_modifier_held = Input.is_key_pressed(KEY_CTRL)
	_update_pan(raw_delta)
	_update_camera_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_LEFT:
				build_click.emit(mb.pressed)
			MOUSE_BUTTON_RIGHT:
				if mb.pressed:
					action_fired.emit("build_cancel")
			MOUSE_BUTTON_MIDDLE:
				_rotating = mb.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed:
					_zoom(ZOOM_FACTOR_IN)
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					_zoom(ZOOM_FACTOR_OUT)
		return

	if event is InputEventMouseMotion:
		if _rotating:
			var mm: InputEventMouseMotion = event as InputEventMouseMotion
			_yaw -= mm.relative.x * MOUSE_DRAG_SENSITIVITY
			_pitch = clamp(_pitch - mm.relative.y * MOUSE_DRAG_SENSITIVITY, PITCH_MIN, PITCH_MAX)
		return

	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and not ke.echo:
			if ke.physical_keycode == KEY_Q:
				_yaw += Q_E_ROTATE_STEP
			elif ke.physical_keycode == KEY_E:
				_yaw -= Q_E_ROTATE_STEP
		for action_name: String in NAMED_ACTIONS:
			if event.is_action_pressed(action_name, false, false):
				action_fired.emit(action_name)


func setup(world_aabb: AABB) -> void:
	_bounds_min = world_aabb.position
	_bounds_max = world_aabb.position + world_aabb.size
	# Slice default: start looking at the region center (not specified by the
	# GDD/contract — a reasonable default since no spawn target is given here).
	_target_x = clamp(_bounds_min.x + world_aabb.size.x * 0.5, _bounds_min.x, _bounds_max.x)
	_target_z = clamp(_bounds_min.z + world_aabb.size.z * 0.5, _bounds_min.z, _bounds_max.z)
	_register_actions()
	_update_camera_transform()


func get_world_ray() -> Dictionary:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	return {
		"origin": _camera.project_ray_origin(mouse_pos),
		"dir": _camera.project_ray_normal(mouse_pos),
	}


func get_camera() -> Camera3D:
	return _camera


func _register_actions() -> void:
	var tool_keys: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8]
	for i in range(tool_keys.size()):
		_add_key_action("tool_select_%d" % (i + 1), tool_keys[i])
	_add_key_action("build_cancel", KEY_ESCAPE)
	_add_key_action("undo", KEY_Z, true)
	_add_key_action("redo", KEY_Y, true)
	_add_key_action("height_step_up", KEY_R)
	_add_key_action("height_step_down", KEY_F)
	_add_key_action("palette_next", KEY_T)
	_add_key_action("palette_prev", KEY_G)
	_add_key_action("formation_next", KEY_B)
	_add_key_action("formation_prev", KEY_V)
	_add_key_action("time_pause", KEY_SPACE)
	_add_key_action("time_speed_up", KEY_EQUAL)
	_add_key_action("time_speed_up", KEY_KP_ADD)
	_add_key_action("time_speed_down", KEY_MINUS)
	_add_key_action("time_speed_down", KEY_KP_SUBTRACT)
	# BUILD UX PACKAGE (2026-07-22) — SLICE VIEW keys.
	_add_key_action("slice_up", KEY_PAGEUP)
	_add_key_action("slice_down", KEY_PAGEDOWN)
	_add_key_action("slice_reset", KEY_HOME)


func _add_key_action(action_name: String, physical_keycode: Key, require_ctrl: bool = false) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev: InputEventKey = InputEventKey.new()
	ev.physical_keycode = physical_keycode
	ev.ctrl_pressed = require_ctrl
	InputMap.action_add_event(action_name, ev)


func _update_pan(delta: float) -> void:
	var input_dir: Vector3 = Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.z -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.z += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1.0
	if input_dir.length_squared() <= 0.0:
		return
	input_dir = input_dir.normalized().rotated(Vector3.UP, _yaw)
	var pan: Vector3 = input_dir * PAN_SPEED_FACTOR * _distance * delta
	_target_x = clamp(_target_x + pan.x, _bounds_min.x, _bounds_max.x)
	_target_z = clamp(_target_z + pan.z, _bounds_min.z, _bounds_max.z)


## Terrain height provider (wired by GameWorld). Without it the camera's
## fixed-height target lets the EYE dive INSIDE hills — a backface-culled
## voxel world then reads as 'only outer faces render, see through to
## bedrock' (the user's long-standing report; none of the mesh fixes could
## ever change it because it was never a mesh problem).
var _height_provider: Callable = Callable()


func set_height_provider(cb: Callable) -> void:
	_height_provider = cb


func _terrain_h(x: float, z: float) -> float:
	if _height_provider.is_valid():
		return float(_height_provider.call(int(floor(x)), int(floor(z))))
	return 0.0


func _update_camera_transform() -> void:
	var offset: Vector3 = Vector3(
		_distance * sin(_yaw) * cos(_pitch),
		_distance * sin(_pitch),
		_distance * cos(_yaw) * cos(_pitch)
	)
	# Target rides the terrain surface instead of a fixed height.
	var target_y: float = TARGET_Y
	if _height_provider.is_valid():
		target_y = _terrain_h(_target_x, _target_z) + 1.0
	var target_pos: Vector3 = Vector3(_target_x, target_y, _target_z)
	var eye: Vector3 = target_pos + offset
	# The eye NEVER goes underground: keep it >= 2 cells above the terrain
	# at its own footprint (cheap sample; exact collision is out of slice scope).
	if _height_provider.is_valid():
		var min_eye_y: float = _terrain_h(eye.x, eye.z) + 2.0
		if eye.y < min_eye_y:
			eye.y = min_eye_y
	_camera.position = eye
	_camera.look_at(target_pos, Vector3.UP)


func _zoom(factor: float) -> void:
	_distance = clamp(_distance * factor, DISTANCE_MIN, DISTANCE_MAX)
