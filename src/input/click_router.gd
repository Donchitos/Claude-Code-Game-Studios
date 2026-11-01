class_name ClickRouter
extends RefCounted
## Deterministic click router and input coordinator.
## Manages left/right click press/hold/release lifecycle, focus gating, pause prevention,
## and priority resolution between weapon fire and nearby station interactions.

signal fire_requested(position: Vector2, is_hold: bool)
signal alt_action_requested(position: Vector2)
signal interaction_triggered(station: Node3D)

var can_fire: bool = true
var is_paused: bool = false
var has_focus: bool = true
var is_automatic_weapon: bool = false

var _left_down: bool = false
var _right_down: bool = false
var _hold_duration: float = 0.0

const HOLD_THRESHOLD: float = 0.22


## Update hold timer and process continuous automatic fire.
func advance(delta: float, current_mouse_pos: Vector2) -> void:
	if delta <= 0.0:
		return
	if not _can_act():
		_cancel_inputs()
		return

	if _left_down:
		_hold_duration += delta
		if is_automatic_weapon and _hold_duration >= HOLD_THRESHOLD:
			fire_requested.emit(current_mouse_pos, true)


## Process mouse button events with priority resolution.
func handle_mouse_button(button_index: int, pressed: bool, screen_pos: Vector2, hover_station: Node3D = null) -> bool:
	if not _can_act():
		_cancel_inputs()
		return false

	if button_index == MOUSE_BUTTON_LEFT:
		if pressed:
			_left_down = true
			_hold_duration = 0.0
			# If clicking directly on an interactable station within reach, prioritize interaction
			if hover_station != null and hover_station.has_method(&"activate"):
				interaction_triggered.emit(hover_station)
				return true
			# Otherwise fire weapon
			fire_requested.emit(screen_pos, false)
			return true
		else:
			_left_down = false
			_hold_duration = 0.0
			return true

	elif button_index == MOUSE_BUTTON_RIGHT:
		if pressed:
			_right_down = true
			alt_action_requested.emit(screen_pos)
			return true
		else:
			_right_down = false
			return true

	return false


## Check if gameplay inputs can be accepted.
func _can_act() -> bool:
	return has_focus and not is_paused and can_fire


## Cancel any ongoing button hold (e.g. on focus loss or pause).
func _cancel_inputs() -> void:
	_left_down = false
	_right_down = false
	_hold_duration = 0.0
