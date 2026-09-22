class_name PcInputSource
extends RefCounted

## Reused sampling storage; connection lists refresh only on topology changes.
var keyboard := Vector2.ZERO
var stick := Vector2.ZERO
var keyboard_held := false
var all_sticks_neutral := true
var device_id := -1
var devices := PackedInt32Array()
var valid := true
const KEY_ACTIONS := [&"move_left", &"move_right", &"move_up", &"move_down"]

## Refreshes recognized mapped devices in deterministic ID order.
func refresh_devices() -> void:
	devices.clear()
	for device: int in Input.get_connected_joypads():
		if Input.is_joy_known(device):
			devices.append(device)
	devices.sort()
	device_id = -1 if devices.is_empty() else devices[0]

## Reads keyboard and mapped axes independently without applying two deadzones.
func poll(deadzone: float) -> void:
	keyboard = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down", 0.0)
	keyboard_held = false
	for action: StringName in KEY_ACTIONS:
		keyboard_held = keyboard_held or Input.is_action_pressed(action)
	stick = Vector2.ZERO
	all_sticks_neutral = true
	valid = keyboard.is_finite()
	for device: int in devices:
		var axis := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
		valid = valid and axis.is_finite()
		all_sticks_neutral = all_sticks_neutral and axis.is_finite() and axis.length() <= deadzone
		if device == device_id:
			stick = axis
