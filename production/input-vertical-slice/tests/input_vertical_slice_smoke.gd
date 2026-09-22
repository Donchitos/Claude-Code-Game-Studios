extends SceneTree

const InputSystemScript := preload("res://src/input_system.gd")
const CarrierScript := preload("res://src/movement_intent_carrier.gd")

func _init() -> void:
	var input_system: InputSystem = InputSystemScript.new()
	var carrier := CarrierScript.new()
	carrier.write(Vector2.RIGHT, 1, 7)
	assert(carrier.direction == Vector2.RIGHT)
	assert(carrier.is_active)
	carrier.clear(8)
	assert(carrier.direction == Vector2.ZERO)
	assert(not carrier.is_active)

	assert(InputMap.has_action(&"touch_move_left"))
	assert(InputMap.has_action(&"touch_move_right"))
	assert(InputMap.has_action(&"touch_move_up"))
	assert(InputMap.has_action(&"touch_move_down"))
	for action in [&"touch_move_left", &"touch_move_right", &"touch_move_up", &"touch_move_down"]:
		assert(InputMap.action_get_deadzone(action) == 0.0)
		assert(InputMap.action_get_events(action).is_empty())

	input_system.queue_free()
	print("INPUT_VERTICAL_SLICE_SMOKE_PASS")
	quit()

