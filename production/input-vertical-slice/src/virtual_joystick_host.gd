class_name VirtualJoystickHost
extends Control

## Production-slice host for the Godot 4.7.1 built-in VirtualJoystick.
signal movement_pressed
signal movement_released

const JOYSTICK_DYNAMIC := 1
const VISIBILITY_WHEN_TOUCHED := 1
const STATUS_OK := 0
const STATUS_INVALID_ARGUMENT := 1
const STATUS_WRONG_STATE := 5
const STATUS_JOYSTICK_REBUILD_FAILED := 10

var joystick: Control
var claim_active: bool = false
var gesture_epoch: int = 1
var press_generation: int = -1
var last_rebuild_revision: int = 0
var rebuild_count: int = 0

## Creates exactly one registered joystick and keeps it inside the host.
func initialize() -> bool:
	if joystick != null:
		return false
	if not ClassDB.class_exists(&"VirtualJoystick"):
		return false

	joystick = ClassDB.instantiate(&"VirtualJoystick") as Control
	if joystick == null:
		return false
	joystick.name = "RegisteredVirtualJoystick"
	joystick.set("joystick_mode", JOYSTICK_DYNAMIC)
	joystick.set("visibility_mode", VISIBILITY_WHEN_TOUCHED)
	joystick.set("joystick_size", 158.0)
	joystick.set("tip_size", 71.0)
	joystick.set("deadzone_ratio", 0.15)
	joystick.set("clampzone_ratio", 1.0)
	joystick.set("initial_offset_ratio", Vector2(0.5, 0.5))
	joystick.set("action_left", &"touch_move_left")
	joystick.set("action_right", &"touch_move_right")
	joystick.set("action_up", &"touch_move_up")
	joystick.set("action_down", &"touch_move_down")
	joystick.mouse_filter = Control.MOUSE_FILTER_STOP
	joystick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(joystick)
	joystick.pressed.connect(_on_joystick_pressed)
	joystick.released.connect(_on_joystick_released)
	return true

## Rebuilds the joystick on a new input revision while keeping consumer closed.
func ensure_rebuilt_after_invalidation(input_rebuild_revision: int) -> int:
	if input_rebuild_revision <= 0:
		return STATUS_INVALID_ARGUMENT
	if joystick == null:
		return STATUS_JOYSTICK_REBUILD_FAILED
	if claim_active:
		return STATUS_WRONG_STATE
	if input_rebuild_revision == last_rebuild_revision:
		return STATUS_OK
	last_rebuild_revision = input_rebuild_revision
	rebuild_count += 1
	gesture_epoch += 1
	return STATUS_OK

## Clears a completed gesture before a rebuild or a new input epoch.
func reset_claim() -> int:
	if joystick == null:
		return STATUS_JOYSTICK_REBUILD_FAILED
	if claim_active:
		return STATUS_WRONG_STATE
	press_generation = -1
	return STATUS_OK

## Reports whether the host owns exactly one active joystick.
func registered_active_vj_count() -> int:
	return 1 if is_instance_valid(joystick) and not joystick.is_queued_for_deletion() else 0

## Removes the registered joystick and invalidates late callbacks.
func teardown() -> void:
	gesture_epoch += 1
	claim_active = false
	press_generation = -1
	last_rebuild_revision = 0
	rebuild_count = 0
	if joystick != null:
		joystick.queue_free()
		joystick = null

func _on_joystick_pressed() -> void:
	if claim_active:
		return
	claim_active = true
	press_generation += 1
	movement_pressed.emit()

func _on_joystick_released(_input_vector: Vector2) -> void:
	claim_active = false
	movement_released.emit()
