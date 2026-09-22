@warning_ignore_start("redundant_await", "unsafe_method_access")
# GdUnit generated TestSuite
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/GdUnitSceneRunner.gd'


var _runner :GdUnitSceneRunner
var _scene_spy :Node


func before_test() -> void:
	_scene_spy = spy("res://addons/gdUnit4/test/mocker/resources/scenes/TestScene.tscn")
	_runner = scene_runner(_scene_spy)
	# do handle outstanding events
	await _runner.await_input_processed()
	assert_initial_action_state()
	assert_inital_mouse_state()
	assert_inital_key_state()
	# reset to inital state
	reset(_scene_spy)
	verify_no_more_interactions(_scene_spy)


# asserts to action strings
func assert_initial_action_state() -> void:
	for action in InputMap.get_actions():
		assert_bool(Input.is_action_pressed(action, true)).is_false()


# asserts to KeyList Enums
func assert_inital_key_state() -> void:
	# scacode 4194304-4194415
	for key in range(KEY_SPECIAL, KEY_LAUNCHF):
		assert_bool(Input.is_key_pressed(key)).is_false()
		assert_bool(Input.is_physical_key_pressed(key)).is_false()
	# keycode 32-255
	for key in range(KEY_SPACE, KEY_SECTION):
		assert_bool(Input.is_key_pressed(key)).is_false()
		assert_bool(Input.is_physical_key_pressed(key)).is_false()


#asserts to Mouse ButtonList Enums
func assert_inital_mouse_state() -> void:
	for button :int in [
		MOUSE_BUTTON_LEFT,
		MOUSE_BUTTON_MIDDLE,
		MOUSE_BUTTON_RIGHT,
		MOUSE_BUTTON_XBUTTON1,
		MOUSE_BUTTON_XBUTTON2,
		MOUSE_BUTTON_WHEEL_UP,
		MOUSE_BUTTON_WHEEL_DOWN,
		MOUSE_BUTTON_WHEEL_LEFT,
		MOUSE_BUTTON_WHEEL_RIGHT,
		]:
		assert_bool(Input.is_mouse_button_pressed(button))\
			.override_failure_message("Expecting mouse button %s is not pressed state!" % 1)\
			.is_false()
	assert_that(Input.get_mouse_button_mask())\
		.override_failure_message("Expecting mouse button mask %s is '0'!" % Input.get_mouse_button_mask())\
		.is_equal(0)


func test_reset_to_inital_state_on_release() -> void:
	var runner := scene_runner("res://addons/gdUnit4/test/mocker/resources/scenes/TestScene.tscn")
	# simulate mouse buttons and key press but we never released it
	runner.simulate_action_press("ui_up")
	runner.simulate_mouse_button_press(MOUSE_BUTTON_LEFT)
	runner.simulate_mouse_button_press(MOUSE_BUTTON_RIGHT)
	runner.simulate_mouse_button_press(MOUSE_BUTTON_MIDDLE)
	runner.simulate_key_press(KEY_0)
	runner.simulate_key_press(KEY_X)
	await await_idle_frame()
	assert_bool(Input.is_action_pressed("ui_up")).is_true()
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)).is_true()
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)).is_true()
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)).is_true()
	assert_bool(Input.is_key_pressed(KEY_0)).is_true()
	assert_bool(Input.is_key_pressed(KEY_X)).is_true()
	# unreference the scene runner to enforce reset to initial Input state
	runner._notification(NOTIFICATION_PREDELETE)
	await await_idle_frame()
	assert_bool(Input.is_action_pressed("ui_up")).is_false()
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)).is_false()
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)).is_false()
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)).is_false()
	assert_bool(Input.is_key_pressed(KEY_0)).is_false()
	assert_bool(Input.is_key_pressed(KEY_X)).is_false()


func test_simulate_action_press() -> void:
	# iterate over some example actions
	var actions_to_simmulate :Array[String] = ["ui_up", "ui_down", "ui_left", "ui_right"]
	for action in actions_to_simmulate:
		assert_bool(InputMap.has_action(action)).is_true()
		_runner.simulate_action_press(action)
		await _runner.await_input_processed()

		assert_bool(Input.is_action_pressed(action))\
			.override_failure_message("Expect the action '%s' is pressed" % action).is_true()
		assert_float(Input.get_action_strength(action))\
			.is_equal_approx(1.0, 0.1)
		assert_float(_runner.get_property("_last_pressed_strength"))\
			.is_equal_approx(1.0, 0.1)

	# other actions are not pressed
	for action :String in ["ui_accept", "ui_select", "ui_cancel"]:
		assert_bool(Input.is_action_pressed(action))\
			.override_failure_message("Expect the action '%s' is NOT pressed" % action).is_false()


func test_simulate_action_release() -> void:
	# iterate over some example actions
	var actions_to_simmulate :Array[String] = ["ui_up", "ui_down", "ui_left", "ui_right"]
	for action in actions_to_simmulate:
		assert_bool(InputMap.has_action(action)).is_true()
		_runner.simulate_action_press(action)
		await await_idle_frame()
		_runner.simulate_action_release(action)

		assert_bool(Input.is_action_just_released(action))\
			.override_failure_message("Expect the action '%s' is released" % action).is_true()
	# other actions are not pressed
	for action :String in ["ui_accept", "ui_select", "ui_cancel"]:
		assert_bool(Input.is_action_pressed(action))\
			.override_failure_message("Expect the action '%s' is NOT pressed" % action).is_false()


func test_simulate_key_press() -> void:
	# iterate over some example keys
	for key :int in [KEY_A, KEY_D, KEY_X, KEY_0]:
		_runner.simulate_key_press(key)
		await _runner.await_input_processed()

		var event := InputEventKey.new()
		event.keycode = key as Key
		event.physical_keycode = key as Key
		event.unicode = key
		event.pressed = true
		verify(_scene_spy, 1)._input(event)
		assert_bool(Input.is_key_pressed(key)).is_true()
	# verify all this keys are still handled as pressed
	assert_bool(Input.is_key_pressed(KEY_A)).is_true()
	assert_bool(Input.is_key_pressed(KEY_D)).is_true()
	assert_bool(Input.is_key_pressed(KEY_X)).is_true()
	assert_bool(Input.is_key_pressed(KEY_0)).is_true()
	# other keys are not pressed
	assert_bool(Input.is_key_pressed(KEY_B)).is_false()
	assert_bool(Input.is_key_pressed(KEY_G)).is_false()
	assert_bool(Input.is_key_pressed(KEY_Z)).is_false()
	assert_bool(Input.is_key_pressed(KEY_1)).is_false()


# Simulates pressing shift+A
# Verified with "res://addons/gdUnit4/test/core/InputEventTestScene.tscn"
func test_simulate_key_press_SHIFT_and_A() -> void:
	# press shift + A
	_runner.simulate_key_press(KEY_SHIFT)
	_runner.simulate_key_press(KEY_A)
	await _runner.await_input_processed()

	# We expect key A is pressed and also the modifier shift key
	assert_bool(Input.is_key_pressed(KEY_A)).is_true()
	assert_bool(Input.is_key_pressed(KEY_SHIFT)).is_true()
	assert_bool(Input.is_key_pressed(KEY_ALT)).is_false()
	assert_bool(Input.is_key_pressed(KEY_CTRL)).is_false()
	assert_bool(Input.is_key_pressed(KEY_META)).is_false()

	# In addition we need to verify we emit two input events:
	# first the shift key is pressing (Shift)
	var event := InputEventKey.new()
	event.keycode = KEY_SHIFT
	event.physical_keycode = KEY_SHIFT
	event.unicode = KEY_SHIFT as int
	event.pressed = true
	event.shift_pressed = false
	event.alt_pressed = false
	event.ctrl_pressed = false
	event.meta_pressed = false
	verify(_scene_spy, 1)._input(event)

	# second in addition the key A is pressing (Shift+A)
	event = InputEventKey.new()
	event.keycode = KEY_A
	event.physical_keycode = KEY_A
	event.unicode = KEY_A as int
	event.pressed = true
	event.shift_pressed = true
	event.alt_pressed = false
	event.ctrl_pressed = false
	event.meta_pressed = false
	verify(_scene_spy, 1)._input(event)
	verify_no_more_interactions(_scene_spy)


# Simulate pressing key A and shift
# Verified with "res://addons/gdUnit4/test/core/InputEventTestScene.tscn"
func test_simulate_key_press_A_and_SHIFT() -> void:
	# press key A + shift
	_runner.simulate_key_press(KEY_A)
	_runner.simulate_key_press(KEY_SHIFT)
	await _runner.await_input_processed()

	# We expect key A is pressed and also the modifier shift key
	assert_bool(Input.is_key_pressed(KEY_A)).is_true()
	assert_bool(Input.is_key_pressed(KEY_SHIFT)).is_true()
	assert_bool(Input.is_key_pressed(KEY_ALT)).is_false()
	assert_bool(Input.is_key_pressed(KEY_CTRL)).is_false()
	assert_bool(Input.is_key_pressed(KEY_META)).is_false()

	# In addition we need to verify we emit two input events:
	# first the shift a is pressing (A)
	var event := InputEventKey.new()
	event.keycode = KEY_A
	event.physical_keycode = KEY_A
	event.unicode = KEY_A as int
	event.pressed = true
	event.shift_pressed = false
	event.alt_pressed = false
	event.ctrl_pressed = false
	event.meta_pressed = false
	verify(_scene_spy, 1)._input(event)

	# second in addition the key shift is pressing (Shift)
	event = InputEventKey.new()
	event.keycode = KEY_SHIFT
	event.physical_keycode = KEY_SHIFT
	event.unicode = KEY_SHIFT as int
	event.pressed = true
	event.shift_pressed = false
	event.alt_pressed = false
	event.ctrl_pressed = false
	event.meta_pressed = false
	verify(_scene_spy, 1)._input(event)
	verify_no_more_interactions(_scene_spy)


# Simulate releasing key shift+A
# Verified with "res://addons/gdUnit4/test/core/InputEventTestScene.tscn"
func test_simulate_key_released_SHIFT_and_A() -> void:
	# release shift + A
	_runner.simulate_key_release(KEY_SHIFT)
	_runner.simulate_key_release(KEY_A)
	await _runner.await_input_processed()

	# We expect key A is NOT pressed (it was released) and no modifier keys
	assert_bool(Input.is_key_pressed(KEY_A)).is_false()
	assert_bool(Input.is_key_pressed(KEY_SHIFT)).is_false()
	assert_bool(Input.is_key_pressed(KEY_ALT)).is_false()
	assert_bool(Input.is_key_pressed(KEY_CTRL)).is_false()
	assert_bool(Input.is_key_pressed(KEY_META)).is_false()

	# In addition we need to verify we emit two input events:
	# first the shift+a key is released (Shift+A)
	var event := InputEventKey.new()
	event.keycode = KEY_A
	event.physical_keycode = KEY_A
	event.unicode = KEY_A as int
	event.pressed = false
	event.shift_pressed = true
	event.alt_pressed = false
	event.ctrl_pressed = false
	event.meta_pressed = false
	verify(_scene_spy, 1)._input(event)

	# second in addition the shift is released (Shift)
	event = InputEventKey.new()
	event.keycode = KEY_SHIFT
	event.physical_keycode = KEY_SHIFT
	event.unicode = KEY_SHIFT as int
	event.pressed = false
	event.shift_pressed = false
	event.alt_pressed = false
	event.ctrl_pressed = false
	event.meta_pressed = false
	verify(_scene_spy, 1)._input(event)
	verify_no_more_interactions(_scene_spy)


# Simulate pressed key shift+A
# Verified with "res://addons/gdUnit4/test/core/InputEventTestScene.tscn"
func test_simulate_key_pressed_SHIFT_and_A() -> void:
	# release shift + A
	await _runner.simulate_key_pressed(KEY_SHIFT)
	await _runner.simulate_key_pressed(KEY_A)

	# We expect key A is NOT pressed (it was press and released) and no modifier keys
	assert_bool(Input.is_key_pressed(KEY_A)).is_false()
	assert_bool(Input.is_key_pressed(KEY_SHIFT)).is_false()
	assert_bool(Input.is_key_pressed(KEY_ALT)).is_false()
	assert_bool(Input.is_key_pressed(KEY_CTRL)).is_false()
	assert_bool(Input.is_key_pressed(KEY_META)).is_false()

	# In addition, we need to check whether we output two input events:
	# first the shift key is pressing (Shift+A)
	var event := InputEventKey.new()
	event.keycode = KEY_A
	event.physical_keycode = KEY_A
	event.unicode = KEY_A as int
	event.pressed = true
	event.shift_pressed = true
	event.alt_pressed = false
	event.ctrl_pressed = false
	event.meta_pressed = false
	verify(_scene_spy, 1)._input(event)

	# second in addition the key A is released (Shift+A)
	event = InputEventKey.new()
	event.keycode = KEY_A
	event.physical_keycode = KEY_A
	event.unicode = KEY_A as int
	event.pressed = false
	event.shift_pressed = true
	event.alt_pressed = false
	event.ctrl_pressed = false
	event.meta_pressed = false
	verify(_scene_spy, 1)._input(event)


# Simulate pressing key A + set shift modifier
# @deprecated
func test_simulate_key_press_A_with_shift_modifier() -> void:
	# press key A + modifier shift
	_runner.simulate_key_press(KEY_A, true)
	await _runner.await_input_processed()

	# We expect key A is pressing only and no modifier keys
	assert_bool(Input.is_key_pressed(KEY_A)).is_true()
	assert_bool(Input.is_key_pressed(KEY_SHIFT)).is_false()
	assert_bool(Input.is_key_pressed(KEY_ALT)).is_false()
	assert_bool(Input.is_key_pressed(KEY_CTRL)).is_false()
	assert_bool(Input.is_key_pressed(KEY_META)).is_false()

	# In addition we need to verify we emit one input events:
	# the key A + modifier shift is pressing (Shift+A)
	var event := InputEventKey.new()
	event = InputEventKey.new()
	event.keycode = KEY_A
	event.physical_keycode = KEY_A
	event.unicode = KEY_A as int
	event.pressed = true
	event.shift_pressed = true
	event.alt_pressed = false
	event.ctrl_pressed = false
	event.meta_pressed = false
	verify(_scene_spy, 1)._input(event)
	verify_no_more_interactions(_scene_spy)


# Simulate releasing key A + set shift modifier
# @deprecated
func test_simulate_key_released_A_with_shift_modifier() -> void:
	# release key A + modifiere shift
	_runner.simulate_key_release(KEY_A, true)
	await _runner.await_input_processed()

	# We expect key A is NOT pressing and also no modifier keys
	assert_bool(Input.is_key_pressed(KEY_A)).is_false()
	assert_bool(Input.is_key_pressed(KEY_SHIFT)).is_false()
	assert_bool(Input.is_key_pressed(KEY_ALT)).is_false()
	assert_bool(Input.is_key_pressed(KEY_CTRL)).is_false()
	assert_bool(Input.is_key_pressed(KEY_META)).is_false()

	# In addition we need to verify we emit one input events:
	# The key A and modifier shift is released (Shift+A)
	var event := InputEventKey.new()
	event.keycode = KEY_A
	event.physical_keycode = KEY_A
	event.unicode = KEY_A as int
	event.pressed = false
	event.shift_pressed = true
	event.alt_pressed = false
	event.ctrl_pressed = false
	event.meta_pressed = false
	verify(_scene_spy, 1)._input(event)
	verify_no_more_interactions(_scene_spy)


# Simulate pressed key A + set shift modifier
# @deprecated
func test_simulate_key_pressed_A_with_shift_modifier() -> void:
	# release key A + modifier shift
	await _runner.simulate_key_pressed(KEY_A, true)

	# We expect key A is NOT pressing (was press and released) and also no modifier keys
	assert_bool(Input.is_key_pressed(KEY_SHIFT)).is_false()
	assert_bool(Input.is_key_pressed(KEY_ALT)).is_false()
	assert_bool(Input.is_key_pressed(KEY_CTRL)).is_false()
	assert_bool(Input.is_key_pressed(KEY_META)).is_false()
	assert_bool(Input.is_key_pressed(KEY_A)).is_false()

	# In addition, we need to check whether we output two input events:
	# first the key a + modifier shift is pressing (Shift+A)
	var event := InputEventKey.new()
	event.keycode = KEY_A
	event.physical_keycode = KEY_A
	event.unicode = KEY_A as int
	event.pressed = true
	event.shift_pressed = true
	event.alt_pressed = false
	event.ctrl_pressed = false
	event.meta_pressed = false
	verify(_scene_spy, 1)._input(event)

	# second in addition  the key a + modifier shift is released (Shift+A)
	event = InputEventKey.new()
	event.keycode = KEY_A
	event.physical_keycode = KEY_A
	event.unicode = KEY_A as int
	event.pressed = false
	event.shift_pressed = true
	event.alt_pressed = false
	event.ctrl_pressed = false
	event.meta_pressed = false
	verify(_scene_spy, 1)._input(event)
	verify_no_more_interactions(_scene_spy)


func test_simulate_many_keys_press() -> void:
	# press and hold keys W and Z
	_runner.simulate_key_press(KEY_W)
	_runner.simulate_key_press(KEY_Z)
	await _runner.await_input_processed()

	assert_bool(Input.is_key_pressed(KEY_W)).is_true()
	assert_bool(Input.is_physical_key_pressed(KEY_W)).is_true()
	assert_bool(Input.is_key_pressed(KEY_Z)).is_true()
	assert_bool(Input.is_physical_key_pressed(KEY_Z)).is_true()

	#now release key w
	_runner.simulate_key_release(KEY_W)
	await _runner.await_input_processed()

	assert_bool(Input.is_key_pressed(KEY_W)).is_false()
	assert_bool(Input.is_physical_key_pressed(KEY_W)).is_false()
	assert_bool(Input.is_key_pressed(KEY_Z)).is_true()
	assert_bool(Input.is_physical_key_pressed(KEY_Z)).is_true()


@warning_ignore("unsafe_property_access")
func test_simulate_keypressed_as_action() -> void:
	# add custom action `player_jump` for key 'Space' is pressed
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	InputMap.add_action("player_jump")
	InputMap.action_add_event("player_jump", event)
	var runner := scene_runner("res://addons/gdUnit4/test/core/resources/scenes/input_actions/InputEventTestScene.tscn")

	# precondition checks
	var action_event := InputMap.action_get_events("player_jump")
	assert_array(action_event).contains_exactly([event])
	assert_bool(Input.is_action_just_released("player_jump", true)).is_false()
	assert_bool(Input.is_action_just_released("ui_accept", true)).is_false()
	assert_bool(Input.is_action_just_released("ui_select", true)).is_false()
	@warning_ignore("unsafe_property_access")
	assert_bool(runner.scene()._player_jump_action_released).is_false()

	await runner.simulate_key_pressed(KEY_SPACE)
	# it is important do not wait for next frame here, otherwise the input action cache is cleared and can't be use to verify
	assert_bool(Input.is_action_just_released("player_jump", true)).is_true()
	assert_bool(Input.is_action_just_released("ui_accept", true)).is_true()
	assert_bool(Input.is_action_just_released("ui_select", true)).is_true()
	@warning_ignore("unsafe_property_access")
	assert_bool(runner.scene()._player_jump_action_released).is_true()

	# test a key event is not trigger the custom action event
	# simulate press only space+ctrl
	runner._reset_input_to_default()
	# @deprecated
	runner.simulate_key_pressed(KEY_SPACE, false, true)
	# it is important do not wait for next frame here, otherwise the input action cache is cleared and can't be use to verify
	assert_bool(Input.is_action_just_released("player_jump", true)).is_false()
	assert_bool(Input.is_action_just_released("ui_accept", true)).is_false()
	assert_bool(Input.is_action_just_released("ui_select", true)).is_false()
	@warning_ignore("unsafe_property_access")
	assert_bool(runner.scene()._player_jump_action_released).is_false()

	# cleanup custom action
	InputMap.action_erase_events("player_jump")
	InputMap.erase_action("player_jump")


func test_simulate_set_mouse_pos() -> void:
	# save current global mouse pos
	var gmp := _runner.get_global_mouse_position()
	# set mouse to pos 100, 100
	_runner.set_mouse_position(Vector2(100, 100))
	await _runner.await_input_processed()
	var event := InputEventMouseMotion.new()
	event.position = Vector2(100, 100)
	GodotVersionFixures.set_event_global_position(event, gmp)
	verify(_scene_spy, 1)._input(event)

	# set mouse to pos 800, 400
	gmp = _runner.get_global_mouse_position()
	_runner.set_mouse_position(Vector2(800, 400))
	await _runner.await_input_processed()
	event = InputEventMouseMotion.new()
	event.position = Vector2(800, 400)
	GodotVersionFixures.set_event_global_position(event, gmp)
	verify(_scene_spy, 1)._input(event)

	# and again back to 100,100
	reset(_scene_spy)
	gmp = _runner.get_global_mouse_position()
	_runner.set_mouse_position(Vector2(100, 100))
	await _runner.await_input_processed()
	event = InputEventMouseMotion.new()
	event.position = Vector2(100, 100)
	GodotVersionFixures.set_event_global_position(event, gmp)
	verify(_scene_spy, 1)._input(event)


func test_simulate_set_mouse_pos_with_modifiers() -> void:
	var is_alt := false
	var is_control := false
	var is_shift := false

	for modifier :int in [KEY_SHIFT, KEY_CTRL, KEY_ALT]:
		is_alt = is_alt or KEY_ALT == modifier
		is_control = is_control or KEY_CTRL == modifier
		is_shift = is_shift or KEY_SHIFT == modifier

		for mouse_button :int in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			# simulate press shift, set mouse pos and final press mouse button
			var gmp := _runner.get_global_mouse_position()
			_runner.simulate_key_press(modifier)
			_runner.set_mouse_position(Vector2.ZERO)
			_runner.simulate_mouse_button_press(mouse_button)
			await _runner.await_input_processed()

			var event := InputEventMouseButton.new()
			event.position = Vector2.ZERO
			event.global_position = gmp
			event.alt_pressed = is_alt
			event.ctrl_pressed = is_control
			event.shift_pressed = is_shift
			event.pressed = true
			event.button_index = mouse_button as MouseButton
			event.button_mask = GdUnitSceneRunnerImpl.MAP_MOUSE_BUTTON_MASKS.get(mouse_button)
			verify(_scene_spy, 1)._input(event)
			assert_bool(Input.is_mouse_button_pressed(mouse_button)).is_true()
			# finally release it
			_runner.simulate_mouse_button_release(mouse_button)
			await _runner.await_input_processed()


func test_simulate_mouse_move() -> void:
	_runner.set_mouse_position(Vector2(10, 10))
	var gmp := _runner.get_global_mouse_position()
	_runner.simulate_mouse_move(Vector2(400, 100))
	await _runner.await_input_processed()

	var event := InputEventMouseMotion.new()
	event.position = Vector2(400, 100)
	GodotVersionFixures.set_event_global_position(event, gmp)
	event.relative = Vector2(400, 100) - Vector2(10, 10)
	verify(_scene_spy, 1)._input(event)

	# move mouse to next pos
	gmp = _runner.get_global_mouse_position()
	_runner.simulate_mouse_move(Vector2(55, 42))
	await await_idle_frame()

	event = InputEventMouseMotion.new()
	event.position = Vector2(55, 42)
	GodotVersionFixures.set_event_global_position(event, gmp)
	event.relative = Vector2(55, 42) - Vector2(400, 100)
	verify(_scene_spy, 1)._input(event)


func test_simulate_mouse_move_relative() -> void:
	#OS.window_minimized = false
	_runner.set_mouse_position(Vector2(10, 10))
	await _runner.await_input_processed()
	assert_that(_runner.get_mouse_position()).is_equal(Vector2(10, 10))

	# move the mouse in time of 1 second
	# the final position is current + relative = Vector2(10, 10) + (Vector2(900, 400)
	await _runner.simulate_mouse_move_relative(Vector2(900, 400), 1)
	assert_vector(_runner.get_mouse_position()).is_equal_approx(Vector2(910, 410), Vector2.ONE)

	# move the mouse back in time of 0.1 second
	# Use the negative value of the previously moved action to move it back to the starting position
	await _runner.simulate_mouse_move_relative(Vector2(-900, -400), 0.1)
	assert_vector(_runner.get_mouse_position()).is_equal_approx(Vector2(10, 10), Vector2.ONE)


func test_simulate_mouse_move_absolute() -> void:
	#OS.window_minimized = false
	_runner.set_mouse_position(Vector2(10, 10))
	await _runner.await_input_processed()
	assert_that(_runner.get_mouse_position()).is_equal(Vector2(10, 10))

	# move the mouse in time of 1 second
	await _runner.simulate_mouse_move_absolute(Vector2(900, 400), 1)
	assert_vector(_runner.get_mouse_position()).is_equal_approx(Vector2(900, 400), Vector2.ONE)

	# move the mouse back in time of 0.1 second
	await _runner.simulate_mouse_move_absolute(Vector2(10, 10), 0.1)
	assert_vector(_runner.get_mouse_position()).is_equal_approx(Vector2(10, 10), Vector2.ONE)


func test_simulate_mouse_button_press_left() -> void:
	# simulate mouse button press and hold
	var gmp := _runner.get_global_mouse_position()
	_runner.simulate_mouse_button_press(MOUSE_BUTTON_LEFT)
	await _runner.await_input_processed()

	var event := InputEventMouseButton.new()
	event.position = Vector2.ZERO
	event.global_position = gmp
	event.pressed = true
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = GdUnitSceneRunnerImpl.MAP_MOUSE_BUTTON_MASKS.get(MOUSE_BUTTON_LEFT)
	verify(_scene_spy, 1)._input(event)
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)).is_true()


func test_simulate_mouse_button_press_left_doubleclick() -> void:
	# simulate mouse button press double_click
	var gmp := _runner.get_global_mouse_position()
	_runner.simulate_mouse_button_press(MOUSE_BUTTON_LEFT, true)
	await _runner.await_input_processed()

	var event := InputEventMouseButton.new()
	event.position = Vector2.ZERO
	event.global_position = gmp
	event.pressed = true
	event.double_click = true
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = GdUnitSceneRunnerImpl.MAP_MOUSE_BUTTON_MASKS.get(MOUSE_BUTTON_LEFT)
	verify(_scene_spy, 1)._input(event)
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)).is_true()


func test_simulate_mouse_button_press_right() -> void:
	# simulate mouse button press and hold
	var gmp := _runner.get_global_mouse_position()
	_runner.simulate_mouse_button_press(MOUSE_BUTTON_RIGHT)
	await _runner.await_input_processed()

	var event := InputEventMouseButton.new()
	event.position = Vector2.ZERO
	event.global_position = gmp
	event.pressed = true
	event.button_index = MOUSE_BUTTON_RIGHT
	event.button_mask = GdUnitSceneRunnerImpl.MAP_MOUSE_BUTTON_MASKS.get(MOUSE_BUTTON_RIGHT)
	verify(_scene_spy, 1)._input(event)
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)).is_true()


func test_simulate_mouse_button_press_left_and_right() -> void:
	# simulate mouse button press left+right
	var gmp := _runner.get_global_mouse_position()
	_runner.simulate_mouse_button_press(MOUSE_BUTTON_LEFT)
	_runner.simulate_mouse_button_press(MOUSE_BUTTON_RIGHT)
	await _runner.await_input_processed()

	# results in two events, first is left mouse button
	var event := InputEventMouseButton.new()
	event.position = Vector2.ZERO
	event.global_position = gmp
	event.pressed = true
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	verify(_scene_spy, 1)._input(event)

	# second is left+right and combined mask
	event = InputEventMouseButton.new()
	event.position = Vector2.ZERO
	event.global_position = gmp
	event.pressed = true
	event.button_index = MOUSE_BUTTON_RIGHT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT|MOUSE_BUTTON_MASK_RIGHT
	verify(_scene_spy, 1)._input(event)
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)).is_true()
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)).is_true()
	assert_that(Input.get_mouse_button_mask()).is_equal(MOUSE_BUTTON_MASK_LEFT|MOUSE_BUTTON_MASK_RIGHT)


func test_simulate_mouse_button_press_left_and_right_and_release() -> void:
	# simulate mouse button press left+right
	var gmp := _runner.get_global_mouse_position()
	_runner.simulate_mouse_button_press(MOUSE_BUTTON_LEFT)
	_runner.simulate_mouse_button_press(MOUSE_BUTTON_RIGHT)
	await _runner.await_input_processed()

	# will results into two events
	# first for left mouse button
	var event := InputEventMouseButton.new()
	event.position = Vector2.ZERO
	event.global_position = gmp
	event.pressed = true
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	verify(_scene_spy, 1)._input(event)

	# second is left+right and combined mask
	event = InputEventMouseButton.new()
	event.position = Vector2.ZERO
	event.global_position = gmp
	event.pressed = true
	event.button_index = MOUSE_BUTTON_RIGHT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT|MOUSE_BUTTON_MASK_RIGHT
	verify(_scene_spy, 1)._input(event)
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)).is_true()
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)).is_true()
	assert_that(Input.get_mouse_button_mask()).is_equal(MOUSE_BUTTON_MASK_LEFT|MOUSE_BUTTON_MASK_RIGHT)

	# now release the right button
	gmp = _runner.get_global_mouse_position()
	_runner.simulate_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	await _runner.await_input_processed()
	# will result in right button press false but stay with mask for left pressed
	event = InputEventMouseButton.new()
	event.position = Vector2.ZERO
	event.global_position = gmp
	event.pressed = false
	event.button_index = MOUSE_BUTTON_RIGHT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	verify(_scene_spy, 1)._input(event)
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)).is_true()
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)).is_false()
	assert_that(Input.get_mouse_button_mask()).is_equal(MOUSE_BUTTON_MASK_LEFT)

	# finally relase left button
	gmp = _runner.get_global_mouse_position()
	_runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await _runner.await_input_processed()
	# will result in right button press false but stay with mask for left pressed
	event = InputEventMouseButton.new()
	event.position = Vector2.ZERO
	event.global_position = gmp
	event.pressed = false
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = 0
	verify(_scene_spy, 1)._input(event)
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)).is_false()
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)).is_false()
	assert_that(Input.get_mouse_button_mask()).is_equal(0)


func test_simulate_mouse_button_pressed() -> void:
	for mouse_button :int in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
		# simulate mouse button press and release
		var gmp := _runner.get_global_mouse_position()
		_runner.simulate_mouse_button_pressed(mouse_button)
		await _runner.await_input_processed()

		# it genrates two events, first for press and second as released
		var event := InputEventMouseButton.new()
		event.position = Vector2.ZERO
		event.global_position = gmp
		event.pressed = true
		event.button_index = mouse_button as MouseButton
		event.button_mask = GdUnitSceneRunnerImpl.MAP_MOUSE_BUTTON_MASKS.get(mouse_button)
		verify(_scene_spy, 1)._input(event)

		event = InputEventMouseButton.new()
		event.position = Vector2.ZERO
		event.global_position = gmp
		event.pressed = false
		event.button_index = mouse_button as MouseButton
		event.button_mask = 0
		verify(_scene_spy, 1)._input(event)
		assert_bool(Input.is_mouse_button_pressed(mouse_button)).is_false()
		verify(_scene_spy, 2)._input(any_class(InputEventMouseButton))
		reset(_scene_spy)


func test_simulate_mouse_button_pressed_doubleclick() -> void:
	for mouse_button :int in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
		# simulate mouse button press and release by double_click
		var gmp := _runner.get_global_mouse_position()
		_runner.simulate_mouse_button_pressed(mouse_button, true)
		await _runner.await_input_processed()

		# it genrates two events, first for press and second as released
		var event := InputEventMouseButton.new()
		event.position = Vector2.ZERO
		event.global_position = gmp
		event.pressed = true
		event.double_click = true
		event.button_index = mouse_button as MouseButton
		event.button_mask = GdUnitSceneRunnerImpl.MAP_MOUSE_BUTTON_MASKS.get(mouse_button)
		verify(_scene_spy, 1)._input(event)

		event = InputEventMouseButton.new()
		event.position = Vector2.ZERO
		event.global_position = gmp
		event.pressed = false
		event.double_click = false
		event.button_index = mouse_button as MouseButton
		event.button_mask = 0
		verify(_scene_spy, 1)._input(event)
		assert_bool(Input.is_mouse_button_pressed(mouse_button)).is_false()
		verify(_scene_spy, 2)._input(any_class(InputEventMouseButton))
		reset(_scene_spy)


func test_simulate_mouse_button_press_and_release() -> void:
	for mouse_button :int in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
		var gmp := _runner.get_global_mouse_position()
		# simulate mouse button press and release
		_runner.simulate_mouse_button_press(mouse_button)
		await _runner.await_input_processed()

		var event := InputEventMouseButton.new()
		event.position = Vector2.ZERO
		event.global_position = gmp
		event.pressed = true
		event.button_index = mouse_button as MouseButton
		event.button_mask = GdUnitSceneRunnerImpl.MAP_MOUSE_BUTTON_MASKS.get(mouse_button)
		verify(_scene_spy, 1)._input(event)
		assert_bool(Input.is_mouse_button_pressed(mouse_button)).is_true()

		# now simulate mouse button release
		gmp = _runner.get_global_mouse_position()
		_runner.simulate_mouse_button_release(mouse_button)
		await _runner.await_input_processed()

		event = InputEventMouseButton.new()
		event.position = Vector2.ZERO
		event.global_position = gmp
		event.pressed = false
		event.button_index = mouse_button as MouseButton
		#event.button_mask = 0
		verify(_scene_spy, 1)._input(event)
		assert_bool(Input.is_mouse_button_pressed(mouse_button)).is_false()


#####################################################################################################################
# Tests of simulate touch screen inputs                                                                             #
#####################################################################################################################
func test_simulate_screen_touch_press() -> void:
	# simulate pressing the touching screen
	_runner.simulate_screen_touch_press(0, Vector2(683, 339))
	await _runner.await_input_processed()

	# verify the InputEventScreenTouch is emitted
	assert_that(_runner.get_screen_touch_drag_position(0)).is_equal(Vector2(683, 339))
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = Vector2(683, 339)
	event.pressed = true
	event.double_tap = false
	verify(_scene_spy, 1)._input(event)
	verify(_scene_spy, 1)._on_touch_1_pressed()
	verify(_scene_spy, 0)._on_touch_1_released()


func test_simulate_screen_touch_press_double_click() -> void:
	# simulate pressing the touch screen by a double click
	_runner.simulate_screen_touch_press(0, Vector2(683, 339), true)
	await _runner.await_input_processed()

	# verify the InputEventScreenTouch is emitted
	assert_that(_runner.get_screen_touch_drag_position(0)).is_equal(Vector2(683, 339))
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = Vector2(683, 339)
	event.pressed = true
	event.double_tap = true
	verify(_scene_spy, 1)._input(event)
	verify(_scene_spy, 1)._on_touch_1_pressed()
	verify(_scene_spy, 0)._on_touch_1_released()


func test_simulate_screen_touch_pressed() -> void:
	# simulate has touched the screen
	_runner.simulate_screen_touch_pressed(0, Vector2(683, 339))
	await _runner.await_input_processed()

	# verify the InputEventScreenTouch is emitted
	assert_that(_runner.get_screen_touch_drag_position(0)).is_equal(Vector2(683, 339))
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = Vector2(683, 339)
	event.pressed = true
	event.double_tap = false
	verify(_scene_spy, 1)._input(event)
	event.pressed = false
	verify(_scene_spy, 1)._input(event)
	verify(_scene_spy, 1)._on_touch_1_pressed()
	verify(_scene_spy, 1)._on_touch_1_released()


func test_simulate_screen_touch_pressed_double_click() -> void:
	# simulate have touched the touch screen by a double click
	_runner.simulate_screen_touch_pressed(0, Vector2(683, 339), true)
	await _runner.await_input_processed()

	# verify the InputEventScreenTouch is emitted
	assert_that(_runner.get_screen_touch_drag_position(0)).is_equal(Vector2(683, 339))
	verify(_scene_spy, 1)._on_touch_1_pressed()
	verify(_scene_spy, 1)._on_touch_1_released()


func test_simulate_screen_touch_release() -> void:
	# setup touch is actual pressing
	_runner.simulate_screen_touch_press(0, Vector2(683, 339))
	# simulate no longer touches the screen
	_runner.simulate_screen_touch_release(0)
	await _runner.await_input_processed()

	# verify the InputEventScreenTouch is emitted
	assert_that(_runner.get_screen_touch_drag_position(0)).is_equal(Vector2(683, 339))
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = Vector2(683, 339)
	event.pressed = false
	event.double_tap = false
	verify(_scene_spy, 1)._input(event)
	verify(_scene_spy, 1)._on_touch_1_released()


func test_simulate_screen_touch_release_double_click() -> void:
	# setup touch is actual pressing
	_runner.simulate_screen_touch_press(0, Vector2(683, 339), true)
	# simulate that no longer touches the screen as a double click
	_runner.simulate_screen_touch_release(0, true)
	await _runner.await_input_processed()

	# verify the InputEventScreenTouch is emitted
	assert_that(_runner.get_screen_touch_drag_position(0)).is_equal(Vector2(683, 339))
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = Vector2(683, 339)
	event.pressed = false
	event.double_tap = true
	verify(_scene_spy, 1)._input(event)
	verify(_scene_spy, 1)._on_touch_1_released()


func test_simulate_screen_touch_get_drag_position() -> void:
	# press the touch screen by two fingers
	_runner.simulate_screen_touch_press(0, Vector2(300, 100))
	_runner.simulate_screen_touch_press(1, Vector2(300, 200))

	# verify the drag position is saved for each index
	assert_that(_runner.get_screen_touch_drag_position(0)).is_equal(Vector2(300, 100))
	assert_that(_runner.get_screen_touch_drag_position(1)).is_equal(Vector2(300, 200))


func test_simulate_screen_touch_drag() -> void:
	_runner.simulate_screen_touch_drag(0, Vector2(300, 100))

	# verify the InputEventScreenTouch is emitted
	assert_that(_runner.get_screen_touch_drag_position(0)).is_equal(Vector2(300, 100))
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = Vector2(300, 100)
	event.relative = Vector2.ZERO
	event.pressure = 1.0
	verify(_scene_spy, 1)._input(event)

	# drag to next position
	_runner.simulate_screen_touch_drag(0, Vector2(400, 100))

	# verify the InputEventScreenTouch is emitted
	assert_that(_runner.get_screen_touch_drag_position(0)).is_equal(Vector2(400, 100))
	event.index = 0
	event.position = Vector2(400, 100)
	event.relative = Vector2(300, 100) - Vector2(400, 100)
	event.velocity = event.relative / get_tree().root.get_process_delta_time()
	event.pressure = 1.0
	verify(_scene_spy, 1)._input(event)


# Simulates a gesture in which two fingers are used as input
func test_simulate_screen_touch_gesture_press() -> void:
	# simulate gesture with two fingers is touching the screen
	# finger one has index=0
	_runner.simulate_screen_touch_press(0, Vector2(300, 100))
	# finger one has index=1
	_runner.simulate_screen_touch_press(1, Vector2(300, 200))

	# verify the InputEventScreenTouch is emitted for finger one
	var touch_fg1 := InputEventScreenTouch.new()
	touch_fg1.index = 0
	touch_fg1.position = Vector2(300, 100)
	touch_fg1.pressed = true
	touch_fg1.double_tap = false
	verify(_scene_spy, 1)._input(touch_fg1)

	# and verify the InputEventScreenTouch is emitted for finger one
	var touch_fg2 := InputEventScreenTouch.new()
	touch_fg2.index = 1
	touch_fg2.position = Vector2(300, 200)
	touch_fg2.pressed = true
	touch_fg2.double_tap = false
	verify(_scene_spy, 1)._input(touch_fg2)


# Simulates a gesture in which two fingers are used as input
func test_simulate_screen_touch_gesture_release() -> void:
	# setup two fingers are pressing the touch screen
	# finger one has index=0
	# finger one has index=1
	_runner.simulate_screen_touch_press(0, Vector2(300, 100))
	_runner.simulate_screen_touch_press(1, Vector2(300, 200))

	# simulate gesture with two fingers is untouch the screen
	_runner.simulate_screen_touch_release(0)
	_runner.simulate_screen_touch_release(1)

	# verify the InputEventScreenTouch is emitted for finger one
	var touch_fg1 := InputEventScreenTouch.new()
	touch_fg1.index = 0
	touch_fg1.position = Vector2(300, 100)
	touch_fg1.pressed = false
	touch_fg1.double_tap = false
	verify(_scene_spy, 1)._input(touch_fg1)

	# and verify the InputEventScreenTouch is emitted for finger one
	var touch_fg2 := InputEventScreenTouch.new()
	touch_fg2.index = 1
	touch_fg2.position = Vector2(300, 200)
	touch_fg2.pressed = false
	touch_fg2.double_tap = false
	verify(_scene_spy, 1)._input(touch_fg2)


# Simulates a gesture in which two fingers are used as input
func test_simulate_screen_touch_gesture_zoom_out() -> void:
	# setup two fingers are pressing the touch screen
	# finger one has index=0
	# finger one has index=1
	var finger_one := Vector2(300, 200)
	var finger_two := Vector2(300, 250)
	_runner.simulate_screen_touch_press(0, finger_one)
	_runner.simulate_screen_touch_press(1, finger_two)

	# now simulate gestures by moving the points of contact away from each other
	for y_pos in range(0, 105, 5):
		_runner.simulate_screen_touch_drag(0, finger_one - Vector2(0, y_pos))
		_runner.simulate_screen_touch_drag(1, finger_two + Vector2(0, y_pos))

	# verify final position are correct
	assert_that(_runner.get_screen_touch_drag_position(0)).is_equal(Vector2(300, 100))
	assert_that(_runner.get_screen_touch_drag_position(1)).is_equal(Vector2(300, 350))


func test_text_input_processing() -> void:
	_runner.move_window_to_foreground()
	var lineEdit := _runner.find_child("TextInput") as LineEdit

	# Focus the text input and clear any existing content
	lineEdit.grab_focus()
	assert_bool(lineEdit.has_focus()).is_true()
	lineEdit.text = ""

	# Type individual characters
	_runner.simulate_key_pressed(KEY_H)
	_runner.simulate_key_pressed(KEY_I)
	await _runner.await_input_processed()
	await _runner.simulate_frames(100)

	# Verify text accumulation
	assert_that(lineEdit.text).is_equal("HI");
