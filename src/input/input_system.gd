class_name ProductionInputSystem
extends Node

## State machine for movement ingress. GameRoot is the only caller of run_phase.
enum State {
	UNARMED,
	IDLE,
	ACTIVE,
	LOCK_PENDING,
	FROZEN,
	RESUME_LOCKED,
	TERMINATED,
}

enum Status {
	OK,
	INVALID_CONFIG,
	INVALID_INPUT_MAP,
	INVALID_ARGUMENT,
	NON_FINITE_INPUT,
	ACTION_CLEAR_FAILED,
	GENERATION_EXHAUSTED,
	WRONG_STATE,
	WRONG_PHASE,
	STALE_TICK,
	JOYSTICK_REBUILD_FAILED,
}

const PC_MOVEMENT_ACTIONS := [&"move_left", &"move_right", &"move_up", &"move_down"]
const TOUCH_MOVEMENT_ACTIONS := [&"touch_move_left", &"touch_move_right", &"touch_move_up", &"touch_move_down"]

var state: State = State.UNARMED
var carrier := ProductionMovementIntentCarrier.new()
var host: ProductionVirtualJoystickHost
var current_tick: int = 0
var generation: int = 0
var callbacks_armed: bool = false
var ingress_armed: bool = false
var pending_release: bool = false
var pending_input_status: Status = Status.OK


## Validates project input invariants and arms the host.
## Example: `assert(input_system.initialize(host) == Status.OK)`.
func initialize(input_host: ProductionVirtualJoystickHost) -> Status:
	if state != State.UNARMED or input_host == null:
		return Status.WRONG_STATE
	for action: StringName in PC_MOVEMENT_ACTIONS:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			return Status.INVALID_INPUT_MAP
	for action: StringName in TOUCH_MOVEMENT_ACTIONS:
		if not InputMap.has_action(action) or not InputMap.action_get_events(action).is_empty():
			return Status.INVALID_INPUT_MAP
	if Input.is_using_accumulated_input():
		return Status.INVALID_CONFIG
	if input_host.active_joystick_count() != 1:
		return Status.INVALID_CONFIG
	host = input_host
	host.movement_pressed.connect(_on_movement_pressed)
	host.movement_released.connect(_on_movement_released)
	host.shield_fault.connect(_on_shield_fault)
	callbacks_armed = true
	state = State.IDLE
	return Status.OK

## Opens movement ingress after the battle scope is active.
## Example: `input_system.activate()`.
func activate() -> Status:
	if state != State.IDLE and state != State.RESUME_LOCKED:
		return Status.WRONG_STATE
	if host == null or not host.can_resume():
		return Status.WRONG_STATE
	host.set_shield_service_enabled(false)
	ingress_armed = true
	state = State.ACTIVE
	return Status.OK

## Consumer-close entry used by the GameRoot POST_DEFERRED_BARRIER.
func cancel_input(reason: StringName, tick: int) -> Status:
	if reason == &"" or state != State.ACTIVE:
		return Status.WRONG_STATE
	current_tick = maxi(current_tick, tick)
	carrier.clear(current_tick)
	ingress_armed = false
	state = State.LOCK_PENDING
	if host != null:
		host.set_shield_service_enabled(true)
	return Status.OK

## Commits one sampled movement vector for a monotonically increasing physics tick.
## Example: `input_system.run_phase(&"MOVEMENT_COMMIT", 8)`.
func run_phase(phase: StringName, tick: int) -> Status:
	if phase != &"MOVEMENT_COMMIT":
		return Status.WRONG_PHASE
	if tick <= current_tick:
		return Status.STALE_TICK
	current_tick = tick
	if pending_input_status != Status.OK:
		var status := pending_input_status
		pending_input_status = Status.OK
		carrier.clear(tick)
		return status
	if state != State.ACTIVE or not ingress_armed:
		return Status.WRONG_STATE
	if pending_release:
		pending_release = false
		carrier.clear(tick)
		return Status.OK
	var pc_vector := Input.get_vector(PC_MOVEMENT_ACTIONS[0], PC_MOVEMENT_ACTIONS[1], PC_MOVEMENT_ACTIONS[2], PC_MOVEMENT_ACTIONS[3], 0.0)
	var touch_vector := Input.get_vector(TOUCH_MOVEMENT_ACTIONS[0], TOUCH_MOVEMENT_ACTIONS[1], TOUCH_MOVEMENT_ACTIONS[2], TOUCH_MOVEMENT_ACTIONS[3], 0.0)
	var action_vector := pc_vector if pc_vector != Vector2.ZERO else touch_vector
	if not action_vector.is_finite():
		carrier.clear(tick)
		return Status.NON_FINITE_INPUT
	if action_vector == Vector2.ZERO:
		carrier.clear(tick)
		return Status.OK
	var scale := maxf(absf(action_vector.x), absf(action_vector.y))
	if not is_finite(scale) or scale <= 0.0:
		carrier.clear(tick)
		return Status.NON_FINITE_INPUT
	var scaled := action_vector / scale
	var length := scaled.length()
	if not is_finite(length) or length <= 0.0:
		carrier.clear(tick)
		return Status.NON_FINITE_INPUT
	var normalized := scaled / length
	if not carrier.write(normalized, maxi(generation, 1), tick):
		carrier.clear(tick)
		return Status.NON_FINITE_INPUT
	return Status.OK

## Closes ingress and clears movement before SceneTree pause.
## Example: `input_system.lock_for_pause(12)`.
func lock_for_pause(tick: int) -> Status:
	return cancel_input(&"MANUAL", tick)

## Completes the pause barrier. Example: `input_system.confirm_paused()`.
func confirm_paused() -> Status:
	if state != State.LOCK_PENDING:
		return Status.WRONG_STATE
	state = State.FROZEN
	return Status.OK

## Moves a safely paused input instance to the resume-locked state.
func prepare_resume() -> Status:
	if state != State.FROZEN or host == null or not host.can_resume():
		return Status.WRONG_STATE
	state = State.RESUME_LOCKED
	return Status.OK

## Rebuilds input after a layout invalidation while ingress is closed.
## Example: `input_system.rebuild_after_invalidation(3)`.
func rebuild_after_invalidation(revision: int) -> Status:
	if state != State.RESUME_LOCKED or host == null:
		return Status.WRONG_STATE
	return Status.OK if host.rebuild_after_invalidation(revision) else Status.JOYSTICK_REBUILD_FAILED

## Permanently closes this battle-owned input system. Example: `input_system.teardown()`.
func teardown() -> Status:
	if state == State.TERMINATED:
		return Status.OK
	carrier.clear(current_tick)
	pending_release = false
	pending_input_status = Status.OK
	ingress_armed = false
	callbacks_armed = false
	state = State.TERMINATED
	if host != null:
		host.teardown()
	return Status.OK

## Main-thread observer for callback-latched failures.
func service_pending_input_fault(tick: int) -> Status:
	if pending_input_status == Status.OK:
		return Status.OK
	var status := pending_input_status
	pending_input_status = Status.OK
	carrier.clear(maxi(tick, current_tick))
	return status

func _on_movement_pressed() -> void:
	if callbacks_armed and state == State.ACTIVE:
		if generation == 9223372036854775807:
			pending_input_status = Status.GENERATION_EXHAUSTED
			ingress_armed = false
			return
		generation += 1

func _on_movement_released() -> void:
	if callbacks_armed:
		pending_release = true

func _on_shield_fault(raw_status: int) -> void:
	if callbacks_armed and pending_input_status == Status.OK:
		pending_input_status = Status.INVALID_ARGUMENT if raw_status == 1 else Status.INVALID_CONFIG
