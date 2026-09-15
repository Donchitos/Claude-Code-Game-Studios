class_name ProductionVirtualJoystickHost
extends Control

## Owns exactly one Godot 4.7.1 built-in VirtualJoystick.
signal movement_pressed
signal movement_released
signal shield_fault(status: int)

@onready var shield: ProductionMovementIngressShield = $MovementIngressShield

const JOYSTICK_DYNAMIC := 1
const VISIBILITY_WHEN_TOUCHED := 1

var joystick: Control
var claim_active: bool = false
var gesture_epoch: int = 1
var last_rebuild_revision: int = 0
var _input_config: Dictionary = {}


## Creates the registered joystick from external configuration.
## Example: `host.initialize(config["input"])`.
func initialize(input_config: Dictionary) -> bool:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if joystick != null or not ClassDB.class_exists(&"VirtualJoystick"):
		return false
	if shield == null or not shield.configure(int(input_config.get("shield_bank_capacity", 0))):
		return false
	shield.fault_latched.connect(func(status: int) -> void: shield_fault.emit(status))
	_input_config = input_config.duplicate(true)
	var candidate := _build_joystick(_input_config)
	if candidate == null:
		return false
	candidate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(candidate)
	candidate.pressed.connect(_on_joystick_pressed)
	candidate.released.connect(_on_joystick_released)
	candidate.mouse_filter = Control.MOUSE_FILTER_STOP
	joystick = candidate
	return true

func set_shield_service_enabled(enabled: bool) -> void:
	if shield != null:
		shield.set_service_enabled(enabled, gesture_epoch)

func shield_held_count() -> int:
	return 0 if shield == null else shield.held_count()

func can_resume() -> bool:
	return not claim_active and shield_held_count() == 0

## Returns the active joystick census. Example: `assert(host.active_joystick_count() == 1)`.
func active_joystick_count() -> int:
	return 1 if is_instance_valid(joystick) and not joystick.is_queued_for_deletion() else 0

## Acknowledges an input-layout revision while ingress is closed.
## Example: `host.rebuild_after_invalidation(2)`.
func rebuild_after_invalidation(revision: int) -> bool:
	if revision <= 0 or claim_active or active_joystick_count() != 1:
		return false
	if revision == last_rebuild_revision:
		return true
	var old := joystick
	var candidate := _build_joystick(_input_config)
	if candidate == null:
		return false
	old.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if old.pressed.is_connected(_on_joystick_pressed):
		old.pressed.disconnect(_on_joystick_pressed)
	if old.released.is_connected(_on_joystick_released):
		old.released.disconnect(_on_joystick_released)
	remove_child(old)
	candidate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(candidate)
	candidate.pressed.connect(_on_joystick_pressed)
	candidate.released.connect(_on_joystick_released)
	joystick = candidate
	last_rebuild_revision = revision
	gesture_epoch += 1
	shield.clear_for_rebuild(gesture_epoch)
	candidate.mouse_filter = Control.MOUSE_FILTER_STOP
	old.queue_free()
	return true

## Releases the joystick and invalidates late callbacks. Example: `host.teardown()`.
func teardown() -> void:
	gesture_epoch += 1
	claim_active = false
	if shield != null:
		shield.set_service_enabled(false, gesture_epoch)
	last_rebuild_revision = 0
	if joystick != null:
		joystick.queue_free()
		joystick = null

func _on_joystick_pressed() -> void:
	if claim_active:
		return
	claim_active = true
	movement_pressed.emit()

func _on_joystick_released(_input_vector: Vector2) -> void:
	claim_active = false
	movement_released.emit()

func _build_joystick(input_config: Dictionary) -> Control:
	var candidate := ClassDB.instantiate(&"VirtualJoystick") as Control
	if candidate == null:
		return null
	candidate.name = "MovementVirtualJoystick"
	candidate.set("joystick_mode", JOYSTICK_DYNAMIC)
	candidate.set("visibility_mode", VISIBILITY_WHEN_TOUCHED)
	candidate.set("joystick_size", float(input_config.get("joystick_size", 158.4)))
	candidate.set("tip_size", float(input_config.get("tip_size", 71.28)))
	candidate.set("deadzone_ratio", float(input_config.get("deadzone_ratio", 0.15)))
	candidate.set("clampzone_ratio", float(input_config.get("clampzone_ratio", 1.0)))
	var offset: Array = input_config.get("initial_offset_ratio", [0.5, 0.72])
	candidate.set("initial_offset_ratio", Vector2(float(offset[0]), float(offset[1])))
	candidate.set("action_left", &"touch_move_left")
	candidate.set("action_right", &"touch_move_right")
	candidate.set("action_up", &"touch_move_up")
	candidate.set("action_down", &"touch_move_down")
	candidate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return candidate
