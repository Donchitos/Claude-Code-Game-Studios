class_name InputSystem
extends Node

## Minimal executable InputSystem contract for the formal vertical slice.
signal status_changed(status: int)

enum State {
	UNARMED,
	IDLE,
	ACTIVE,
	LOCK_PENDING,
	RESUME_LOCKED,
	TERMINATED,
}

enum InputStatus {
	OK = 0,
	INVALID_ARGUMENT = 1,
	INVALID_CONFIG = 2,
	INVALID_INPUT_MAP = 3,
	NON_FINITE_INPUT = 4,
	WRONG_STATE = 5,
	WRONG_PHASE = 6,
	STALE_TICK = 7,
	GENERATION_EXHAUSTED = 8,
	ACTION_CLEAR_FAILED = 9,
	JOYSTICK_REBUILD_FAILED = 10,
}

const MOVEMENT_ACTIONS := [&"touch_move_left", &"touch_move_right", &"touch_move_up", &"touch_move_down"]

var state: State = State.UNARMED
var callbacks_armed: bool = false
var runtime_ingress_armed: bool = false
var shield_bank_service_enabled: bool = false
var current_tick: int = 0
var generation: int = 0
var carrier := MovementIntentCarrier.new()
var host: VirtualJoystickHost

## Initializes InputMap validation and the host boundary.
func initialize(input_host: VirtualJoystickHost) -> int:
	if state != State.UNARMED or input_host == null:
		return _finish(InputStatus.WRONG_STATE)
	for action in MOVEMENT_ACTIONS:
		if not InputMap.has_action(action) or not InputMap.action_get_events(action).is_empty():
			return _finish(InputStatus.INVALID_INPUT_MAP)
	if Input.is_using_accumulated_input():
		Input.set_use_accumulated_input(false)
	if Input.is_using_accumulated_input():
		return _finish(InputStatus.INVALID_CONFIG)
	host = input_host
	if host.registered_active_vj_count() != 1:
		return _finish(InputStatus.JOYSTICK_REBUILD_FAILED)
	callbacks_armed = true
	state = State.IDLE
	return _finish(InputStatus.OK)

## Publishes one guarded top-level state transition.
func publish_runtime_state(next_state: State) -> int:
	if state == State.IDLE and next_state == State.ACTIVE:
		runtime_ingress_armed = true
		state = next_state
		return _finish(InputStatus.OK)
	if state == State.RESUME_LOCKED and next_state == State.ACTIVE:
		runtime_ingress_armed = true
		shield_bank_service_enabled = false
		state = next_state
		return _finish(InputStatus.OK)
	if state == State.ACTIVE and next_state == State.LOCK_PENDING:
		runtime_ingress_armed = false
		shield_bank_service_enabled = true
		state = next_state
		carrier.clear(current_tick)
		return _finish(InputStatus.OK)
	if state == State.LOCK_PENDING and next_state == State.RESUME_LOCKED:
		state = next_state
		return _finish(InputStatus.OK)
	return _finish(InputStatus.WRONG_STATE)

## Commits the sampled vector during MOVEMENT_COMMIT.
func run_phase(phase: StringName, sampled: Vector2, tick: int) -> int:
	if phase != &"MOVEMENT_COMMIT":
		return _finish(InputStatus.WRONG_PHASE)
	if state != State.ACTIVE or not runtime_ingress_armed:
		return _finish(InputStatus.WRONG_STATE)
	if not sampled.is_finite():
		carrier.clear(tick)
		return _finish(InputStatus.NON_FINITE_INPUT)
	current_tick = tick
	if sampled == Vector2.ZERO:
		carrier.clear(tick)
	else:
		carrier.write(sampled.normalized(), maxi(generation, 1), tick)
	return _finish(InputStatus.OK)

## Closes movement ingress before a pause barrier.
func cancel_input(tick: int) -> int:
	if state != State.ACTIVE:
		return _finish(InputStatus.WRONG_STATE)
	current_tick = tick
	carrier.clear(tick)
	runtime_ingress_armed = false
	shield_bank_service_enabled = true
	state = State.LOCK_PENDING
	return _finish(InputStatus.OK)

## Rebuilds the host at a new revision while input remains closed.
func ensure_rebuilt_after_invalidation(revision: int) -> int:
	if host == null:
		return _finish(InputStatus.JOYSTICK_REBUILD_FAILED)
	var result := host.ensure_rebuilt_after_invalidation(revision)
	if result != InputStatus.OK:
		return _finish(result)
	if host.registered_active_vj_count() != 1:
		return _finish(InputStatus.JOYSTICK_REBUILD_FAILED)
	return _finish(InputStatus.OK)

## Permanently closes this slice and releases the carrier.
func teardown() -> int:
	if state == State.TERMINATED:
		return _finish(InputStatus.OK)
	carrier.clear(current_tick)
	callbacks_armed = false
	runtime_ingress_armed = false
	shield_bank_service_enabled = false
	state = State.TERMINATED
	if host != null:
		host.teardown()
	return _finish(InputStatus.OK)

func _finish(status: int) -> int:
	status_changed.emit(status)
	return status

