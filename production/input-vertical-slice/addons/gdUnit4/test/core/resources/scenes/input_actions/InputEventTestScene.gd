extends Control

var _player_jump_action_released := false

# enable for manual testing
func __init() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	InputMap.add_action("player_jump")
	InputMap.action_add_event("player_jump", event)


func _input(_event :InputEvent) -> void:
	if InputMap.has_action("player_jump"):
		_player_jump_action_released = Input.is_action_just_released("player_jump", true)
	#prints("_input2:player_jump", Input.is_action_just_released("player_jump"), Input.is_action_just_released("player_jump", true))
