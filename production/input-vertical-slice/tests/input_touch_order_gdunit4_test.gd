extends GdUnitTestSuite

func test_screen_touch_drag_release_uses_real_scene_runner_path() -> void:
	var runner := scene_runner("res://main.tscn")
	await await_idle_frame()
	var scene := runner.scene()
	assert_object(scene).is_not_null()
	assert_object(scene.host).is_not_null()

	var touch_id := 7
	# The scene runner uses the project's 360x640 test viewport override.
	var start := Vector2(90.0, 450.0)
	runner.simulate_screen_touch_press(touch_id, start)
	await await_idle_frame()
	assert_bool(scene.host.claim_active).is_true()

	runner.simulate_screen_touch_drag(touch_id, start + Vector2(96.0, 0.0))
	await await_idle_frame()
	assert_bool(Input.is_action_pressed(&"touch_move_right")).is_true()
	assert_bool(Input.is_action_pressed(&"touch_move_left")).is_false()

	runner.simulate_screen_touch_release(touch_id)
	await await_idle_frame()
	assert_bool(scene.host.claim_active).is_false()
	for action in [&"touch_move_left", &"touch_move_right", &"touch_move_up", &"touch_move_down"]:
		assert_bool(Input.is_action_pressed(action)).is_false()
