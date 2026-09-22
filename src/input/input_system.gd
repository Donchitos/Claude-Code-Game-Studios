class_name ProductionInputSystem
extends Node

## STEAM_PC adapter; MOBILE_TOUCH implementation remains an isolated future port.
enum State { UNARMED, IDLE, ACTIVE, LOCK_PENDING, FROZEN, RESUME_LOCKED, TERMINATED }
enum Status { OK, INVALID_CONFIG, INVALID_INPUT_MAP, INVALID_ARGUMENT, NON_FINITE_INPUT,
	ACTION_CLEAR_FAILED, GENERATION_EXHAUSTED, WRONG_STATE, WRONG_PHASE, STALE_TICK, JOYSTICK_REBUILD_FAILED }
enum Source { NONE, KEYBOARD, GAMEPAD }
const PC_MOVEMENT_ACTIONS := [&"move_left", &"move_right", &"move_up", &"move_down"]
const TOUCH_MOVEMENT_ACTIONS := [&"touch_move_left", &"touch_move_right", &"touch_move_up", &"touch_move_down"]

var state := State.UNARMED
var carrier: ProductionMovementIntentCarrier
var context: PcMovementContext
var source_reader: PcInputSource
var current_tick := 0
var generation := 0
var callbacks_armed := false
var ingress_armed := false
var shield_bank_service_enabled := false
var neutral_required := false
var focused := true
var source := Source.NONE
var stick_deadzone := 0.0
var sample_count := 0
var _first_resume_tick := false

## Validates the explicit profile and receives GameRoot-owned per-battle storage.
func initialize(input_config: Dictionary, movement: ProductionMovementIntentCarrier,
		phase_context: PcMovementContext, reader: PcInputSource = null) -> Status:
	if state != State.UNARMED:
		return Status.WRONG_STATE
	var deadzone := float(input_config.get("stick_deadzone", NAN))
	if input_config.get("active_profile", "") != "STEAM_PC" or int(input_config.get("profile_revision", 0)) != 1 \
			or not is_finite(deadzone) or deadzone <= 0.0 or deadzone >= 1.0 \
			or movement == null or phase_context == null or phase_context.battle_generation < 1:
		return Status.INVALID_CONFIG
	# Config floats are float64; reject thresholds rounded out of domain by real_t.
	var engine_deadzone := Vector2(deadzone, 0.0).x
	if not is_finite(engine_deadzone) or engine_deadzone <= 0.0 or engine_deadzone >= 1.0:
		return Status.INVALID_CONFIG
	for action: StringName in PC_MOVEMENT_ACTIONS:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			return Status.INVALID_INPUT_MAP
		for event: InputEvent in InputMap.action_get_events(action):
			if not event is InputEventKey:
				return Status.INVALID_INPUT_MAP
	if Input.is_using_accumulated_input():
		return Status.INVALID_CONFIG
	carrier = movement
	context = phase_context
	source_reader = reader if reader != null else PcInputSource.new()
	source_reader.refresh_devices()
	# Match the engine Vector2 component precision at the inclusive threshold.
	stick_deadzone = engine_deadzone
	source_reader.poll(stick_deadzone)
	neutral_required = source_reader.keyboard_held or not source_reader.all_sticks_neutral
	callbacks_armed = true
	state = State.IDLE
	return Status.OK

## Opens the PC consumer after GameRoot has unpaused behind its physical gate.
func activate() -> Status:
	if (state != State.IDLE and state != State.RESUME_LOCKED) or not focused:
		return Status.WRONG_STATE
	state = State.ACTIVE
	ingress_armed = true
	return Status.OK

## Atomically closes scalar ingress before carrier cleanup or engine setters.
func cancel_input(reason: StringName, _tick: int) -> Status:
	if reason == &"" or state not in [State.ACTIVE, State.LOCK_PENDING, State.FROZEN, State.RESUME_LOCKED]:
		return Status.WRONG_STATE
	if state == State.ACTIVE:
		state = State.LOCK_PENDING
	ingress_armed = false
	shield_bank_service_enabled = false
	neutral_required = true
	source = Source.NONE
	carrier.clear(current_tick)
	return Status.OK

## Samples exactly once for the currently open PC movement lease.
func run_phase(phase: StringName, frame: PcMovementContext, lease: int) -> Status:
	if phase != &"MOVEMENT_COMMIT":
		return Status.WRONG_PHASE
	if frame == null or frame != context or not frame.open or frame.retired or lease != frame.lease_id or frame.tick <= current_tick:
		return Status.STALE_TICK
	if state != State.ACTIVE or not ingress_armed or not focused:
		return Status.WRONG_STATE
	current_tick = frame.tick
	sample_count += 1
	source_reader.poll(stick_deadzone)
	if not source_reader.valid or not source_reader.keyboard.is_finite() or not source_reader.stick.is_finite():
		carrier.clear(current_tick)
		return Status.NON_FINITE_INPUT
	var neutral := not source_reader.keyboard_held and source_reader.all_sticks_neutral
	if neutral_required or _first_resume_tick:
		neutral_required = not neutral
		_first_resume_tick = false
		carrier.clear(current_tick)
		source = Source.NONE
		return Status.OK
	var next_source := Source.NONE
	var vector := Vector2.ZERO
	if source_reader.keyboard_held:
		vector = source_reader.keyboard
		next_source = Source.KEYBOARD
	elif source_reader.stick.length() > stick_deadzone:
		vector = source_reader.stick
		next_source = Source.GAMEPAD
	if vector == Vector2.ZERO:
		# Opposing held keys suspend output without ending an existing keyboard epoch.
		# A different or fully released source retires it; its next nonzero sample
		# receives a new generation below.
		if next_source != source:
			source = Source.NONE
		carrier.clear(current_tick)
		return Status.OK
	if next_source != source:
		if generation == 9223372036854775807:
			carrier.clear(current_tick)
			return Status.GENERATION_EXHAUSTED
		generation += 1
		source = next_source
	var scale := maxf(absf(vector.x), absf(vector.y))
	var scaled := vector / scale
	return Status.OK if carrier.write(scaled / scaled.length(), generation, current_tick) else Status.NON_FINITE_INPUT

## Closes the battle consumer for a manual or choice pause.
func lock_for_pause(tick: int) -> Status:
	return cancel_input(&"PAUSE", tick)

## Marks completion of the current PC simulation pause barrier.
func confirm_paused() -> Status:
	if state != State.LOCK_PENDING:
		return Status.WRONG_STATE
	state = State.FROZEN
	return Status.OK

## Held sources remain a neutral barrier, never a technical failure.
func prepare_resume() -> Status:
	if state != State.FROZEN or not focused:
		return Status.WRONG_STATE
	state = State.RESUME_LOCKED
	_first_resume_tick = true
	return Status.OK

## Retires the sampled source after a controller connection/mapping change.
func invalidate_sources() -> void:
	if not callbacks_armed:
		return
	source = Source.NONE
	neutral_required = true
	carrier.clear(current_tick)
	source_reader.refresh_devices()

## Receives app-root focus state; refocus never opens movement by itself.
func set_focused(value: bool) -> void:
	focused = value
	if not value:
		invalidate_sources()

## Terminal commit precedes all fallible node cleanup.
func teardown() -> Status:
	state = State.TERMINATED
	callbacks_armed = false
	ingress_armed = false
	shield_bank_service_enabled = false
	source = Source.NONE
	if carrier != null:
		carrier.clear(current_tick)
	if context != null:
		context.retire()
	return Status.OK

## PC has no callback-driven touch fault mailbox.
func service_pending_input_fault(_tick: int) -> Status:
	return Status.OK
