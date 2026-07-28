@tool
class_name GdUnitInputCapture
extends Control

signal input_completed(input_event: InputEventKey)


var _tween: Tween
var _input_event: InputEventKey


func _ready() -> void:
	reset()
	self_modulate = Color.WHITE
	_tween = create_tween()
	@warning_ignore("return_value_discarded")
	_tween.set_loops()
	@warning_ignore("return_value_discarded")
	_tween.tween_property(%Label, "self_modulate", Color(1, 1, 1, .8), 1.0).from_current().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)


func reset() -> void:
	_input_event = InputEventKey.new()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var _event := event as InputEventKey
		match _event.keycode:
			KEY_CTRL:
				_input_event.ctrl_pressed = true
			KEY_SHIFT:
				_input_event.shift_pressed = true
			KEY_ALT:
				_input_event.alt_pressed = true
			KEY_META:
				_input_event.meta_pressed = true
			_:
				_input_event.keycode = _event.keycode
		_apply_input_modifiers(_event)
		accept_event()

	if event is InputEventKey and not event.is_pressed():
		input_completed.emit(_input_event)
		hide()


func _apply_input_modifiers(event: InputEvent) -> void:
	if event is InputEventWithModifiers:
		var _event := event as InputEventWithModifiers
		_input_event.meta_pressed = _event.meta_pressed or _input_event.meta_pressed
		_input_event.alt_pressed = _event.alt_pressed or _input_event.alt_pressed
		_input_event.shift_pressed = _event.shift_pressed or _input_event.shift_pressed
		_input_event.ctrl_pressed = _event.ctrl_pressed or _input_event.ctrl_pressed
