extends SceneTree

const HostScript := preload("res://src/virtual_joystick_host.gd")

var failures: Array[String] = []
var root_control: Control
var host: VirtualJoystickHost

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	Input.set_use_accumulated_input(false)
	root_control = Control.new()
	root_control.name = "TouchOrderFixtureRoot"
	root_control.size = Vector2(720.0, 1280.0)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_root().add_child(root_control)
	host = HostScript.new()
	host.name = "TouchOrderFixtureHost"
	host.size = root_control.size
	host.mouse_filter = Control.MOUSE_FILTER_PASS
	root_control.add_child(host)
	_expect(host.initialize(), "host initialize failed")
	await process_frame
	_expect(host.registered_active_vj_count() == 1, "fixture must have one active VJ")

	var press := InputEventScreenTouch.new()
	press.window_id = get_root().get_window_id()
	press.index = 7
	press.position = Vector2(320.0, 640.0)
	press.pressed = true
	get_root().get_viewport().push_input(press, true)
	await process_frame
	_expect(host.claim_active, "press must establish VJ claim")

	var drag := InputEventScreenDrag.new()
	drag.window_id = get_root().get_window_id()
	drag.index = 7
	drag.position = Vector2(410.0, 640.0)
	drag.relative = Vector2(90.0, 0.0)
	get_root().get_viewport().push_input(drag, true)
	await process_frame
	_expect(Input.is_action_pressed(&"touch_move_right"), "drag must publish right movement action")

	var release := InputEventScreenTouch.new()
	release.window_id = get_root().get_window_id()
	release.index = 7
	release.position = drag.position
	release.pressed = false
	get_root().get_viewport().push_input(release, true)
	await process_frame
	_expect(not host.claim_active, "release must clear VJ claim")
	_expect(not Input.is_action_pressed(&"touch_move_left"), "release must clear left action")
	_expect(not Input.is_action_pressed(&"touch_move_right"), "release must clear right action")
	_expect(not Input.is_action_pressed(&"touch_move_up"), "release must clear up action")
	_expect(not Input.is_action_pressed(&"touch_move_down"), "release must clear down action")

	host.teardown()
	root_control.queue_free()
	await process_frame
	if failures.is_empty():
		print("INPUT_TOUCH_ORDER_FIXTURE_PASS tests=10")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("INPUT_TOUCH_ORDER_FIXTURE_FAIL failures=%s" % failures.size())
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
