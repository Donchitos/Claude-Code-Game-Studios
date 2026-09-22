extends GdUnitTestSuite

const InputSystemScript := preload("res://src/input_system.gd")
const HostScript := preload("res://src/virtual_joystick_host.gd")

var host: VirtualJoystickHost
var input_system: InputSystem

func before_test() -> void:
	host = auto_free(HostScript.new())
	add_child(host)
	assert_bool(host.initialize()).is_true()
	input_system = auto_free(InputSystemScript.new())
	add_child(input_system)

func after_test() -> void:
	if input_system != null:
		input_system.teardown()
	input_system = null
	host = null

func test_state_and_movement_contract() -> void:
	assert_int(host.registered_active_vj_count()).is_equal(1)
	assert_int(input_system.initialize(host)).is_equal(InputSystem.InputStatus.OK)
	assert_int(input_system.state).is_equal(InputSystem.State.IDLE)
	assert_bool(input_system.callbacks_armed).is_true()
	assert_bool(input_system.runtime_ingress_armed).is_false()
	assert_int(input_system.publish_runtime_state(InputSystem.State.ACTIVE)).is_equal(InputSystem.InputStatus.OK)
	assert_int(input_system.run_phase(&"MOVEMENT_COMMIT", Vector2(3.0, 4.0), 1)).is_equal(InputSystem.InputStatus.OK)
	assert_that(input_system.carrier.direction).is_equal(Vector2(0.6, 0.8))
	assert_bool(input_system.carrier.is_active).is_true()

func test_cancel_resume_and_teardown_contract() -> void:
	assert_int(input_system.initialize(host)).is_equal(InputSystem.InputStatus.OK)
	assert_int(input_system.publish_runtime_state(InputSystem.State.ACTIVE)).is_equal(InputSystem.InputStatus.OK)
	assert_int(input_system.cancel_input(2)).is_equal(InputSystem.InputStatus.OK)
	assert_int(input_system.state).is_equal(InputSystem.State.LOCK_PENDING)
	assert_bool(input_system.runtime_ingress_armed).is_false()
	assert_bool(input_system.shield_bank_service_enabled).is_true()
	assert_int(input_system.publish_runtime_state(InputSystem.State.RESUME_LOCKED)).is_equal(InputSystem.InputStatus.OK)
	assert_int(input_system.publish_runtime_state(InputSystem.State.ACTIVE)).is_equal(InputSystem.InputStatus.OK)
	assert_int(input_system.teardown()).is_equal(InputSystem.InputStatus.OK)
	assert_int(input_system.state).is_equal(InputSystem.State.TERMINATED)
	assert_bool(input_system.callbacks_armed).is_false()
	assert_bool(input_system.runtime_ingress_armed).is_false()
	assert_bool(input_system.shield_bank_service_enabled).is_false()

func test_vj_claim_reset_and_rebuild_reentrancy_contract() -> void:
	assert_int(host.registered_active_vj_count()).is_equal(1)
	var initial_epoch := host.gesture_epoch
	var initial_generation := host.press_generation
	host.joystick.pressed.emit()
	host.joystick.pressed.emit()
	assert_bool(host.claim_active).is_true()
	assert_int(host.press_generation).is_equal(initial_generation + 1)
	assert_int(host.ensure_rebuilt_after_invalidation(1)).is_equal(HostScript.STATUS_WRONG_STATE)
	assert_int(host.gesture_epoch).is_equal(initial_epoch)

	host.joystick.released.emit(Vector2.ZERO)
	assert_bool(host.claim_active).is_false()
	assert_int(host.reset_claim()).is_equal(HostScript.STATUS_OK)
	assert_int(host.press_generation).is_equal(-1)
	assert_int(host.ensure_rebuilt_after_invalidation(1)).is_equal(HostScript.STATUS_OK)
	assert_int(host.rebuild_count).is_equal(1)
	assert_int(host.gesture_epoch).is_equal(initial_epoch + 1)
	assert_int(host.ensure_rebuilt_after_invalidation(1)).is_equal(HostScript.STATUS_OK)
	assert_int(host.rebuild_count).is_equal(1)
	assert_int(host.gesture_epoch).is_equal(initial_epoch + 1)
	assert_bool(host.initialize()).is_false()
