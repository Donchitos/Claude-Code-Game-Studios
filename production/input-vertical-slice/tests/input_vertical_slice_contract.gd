extends SceneTree

const InputSystemScript := preload("res://src/input_system.gd")
const HostScript := preload("res://src/virtual_joystick_host.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_input_map()
	_check_state_machine()
	_check_rebuild_and_teardown()
	var exit_code := 0
	if failures.is_empty():
		print("INPUT_VERTICAL_SLICE_CONTRACT_PASS tests=18")
	else:
		exit_code = 1
		for failure in failures:
			push_error(failure)
		print("INPUT_VERTICAL_SLICE_CONTRACT_FAIL failures=%s" % failures.size())
	await process_frame
	quit(exit_code)

func _check_input_map() -> void:
	var movement := [&"touch_move_left", &"touch_move_right", &"touch_move_up", &"touch_move_down"]
	var meta := [&"ui_focus_next", &"ui_focus_previous", &"ui_focus_left", &"ui_focus_right", &"ui_activate", &"ui_back", &"ui_increment", &"ui_decrement"]
	for action in movement:
		_expect(InputMap.has_action(action), "missing movement action %s" % action)
		_expect(InputMap.action_get_deadzone(action) == 0.0, "movement deadzone is not zero: %s" % action)
		_expect(InputMap.action_get_events(action).is_empty(), "movement action has event binding: %s" % action)
	for action in meta:
		_expect(InputMap.has_action(action), "missing Meta UI action %s" % action)
	_expect(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", true) == false, "mouse-to-touch emulation must be false")
	_expect(ProjectSettings.get_setting("input_devices/buffering/agile_event_flushing", true) == false, "agile event flushing must be false")

func _check_state_machine() -> void:
	var host: VirtualJoystickHost = HostScript.new()
	_expect(host.initialize(), "VirtualJoystickHost initialize failed")
	_expect(host.registered_active_vj_count() == 1, "expected exactly one registered VJ")

	var input_system: InputSystem = InputSystemScript.new()
	_expect(input_system.initialize(host) == InputSystem.InputStatus.OK, "InputSystem initialize failed")
	_expect(input_system.state == InputSystem.State.IDLE, "initialize must end in IDLE")
	_expect(input_system.callbacks_armed, "callbacks must be armed after initialize")
	_expect(not input_system.runtime_ingress_armed, "runtime ingress must be closed in IDLE")
	_expect(input_system.publish_runtime_state(InputSystem.State.ACTIVE) == InputSystem.InputStatus.OK, "IDLE to ACTIVE failed")
	_expect(input_system.run_phase(&"MOVEMENT_COMMIT", Vector2(3.0, 4.0), 1) == InputSystem.InputStatus.OK, "movement commit failed")
	_expect(input_system.carrier.direction.is_equal_approx(Vector2(0.6, 0.8)), "carrier direction was not normalized")
	_expect(input_system.carrier.is_active, "carrier must be active for non-zero input")
	_expect(input_system.cancel_input(2) == InputSystem.InputStatus.OK, "cancel failed")
	_expect(input_system.state == InputSystem.State.LOCK_PENDING, "cancel must enter LOCK_PENDING")
	_expect(input_system.carrier.direction == Vector2.ZERO and not input_system.carrier.is_active, "cancel must clear carrier")
	_expect(input_system.publish_runtime_state(InputSystem.State.RESUME_LOCKED) == InputSystem.InputStatus.OK, "LOCK_PENDING to RESUME_LOCKED failed")
	_expect(input_system.publish_runtime_state(InputSystem.State.ACTIVE) == InputSystem.InputStatus.OK, "RESUME_LOCKED to ACTIVE failed")
	_expect(input_system.run_phase(&"MOVEMENT_COMMIT", Vector2.ZERO, 3) == InputSystem.InputStatus.OK, "zero movement commit failed")
	_expect(input_system.carrier.press_generation == -1, "zero movement must clear generation")
	input_system.teardown()
	input_system.queue_free()
	host.queue_free()

func _check_rebuild_and_teardown() -> void:
	var host: VirtualJoystickHost = HostScript.new()
	_expect(host.initialize(), "rebuild host initialize failed")
	var input_system: InputSystem = InputSystemScript.new()
	_expect(input_system.initialize(host) == InputSystem.InputStatus.OK, "rebuild InputSystem initialize failed")
	_expect(input_system.ensure_rebuilt_after_invalidation(1) == InputSystem.InputStatus.OK, "valid rebuild failed")
	_expect(host.registered_active_vj_count() == 1, "rebuild must preserve exactly one active VJ")
	_expect(input_system.ensure_rebuilt_after_invalidation(0) == InputSystem.InputStatus.INVALID_ARGUMENT, "invalid revision must fail closed")
	_expect(input_system.teardown() == InputSystem.InputStatus.OK, "teardown failed")
	_expect(input_system.state == InputSystem.State.TERMINATED, "teardown must enter TERMINATED")
	_expect(not input_system.callbacks_armed and not input_system.runtime_ingress_armed, "teardown must close callbacks and ingress")
	_expect(host.registered_active_vj_count() == 0, "teardown must remove registered VJ")
	input_system.queue_free()
	host.queue_free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
