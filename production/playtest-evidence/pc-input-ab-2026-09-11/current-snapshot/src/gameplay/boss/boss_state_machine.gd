class_name ProductionBossStateMachine
extends RefCounted

enum Status {
	OK,
	INVALID_ARGUMENT,
	NOT_INITIALIZED,
	DUPLICATE_RECEIPT,
}

enum State {
	UNINITIALIZED,
	ARRIVAL_LOCK,
	TRACK_P1,
	PHASE_SHIFT,
	TRACK_P2,
	DEATH_LATCHED,
}

const DUE_TICK := 43200
const ARRIVAL_LOCK_TICKS := 120
const PHASE_SHIFT_TICKS := 90
const PHASE_THRESHOLD_RATIO := 0.50
const FOG_START_RADIUS := 10.0
const FOG_END_RADIUS := 4.5
const FOG_SHRINK_TICKS := 3600
const RING_PROJECTILE_COUNT := 8

var state: State = State.UNINITIALIZED
var state_ticks := 0
var active_age_ticks := 0
var phase_code := 1
var phase_transition_pending := false
var phase_transition_generation := 0
var fog_anchor := Vector2.ZERO
var fog_elapsed_ticks := 0
var fog_generation := 0

var _resolved_max_hp := 0.0
var _last_damage_receipt_id := 0
var _schedule_claimed := false


func initialize(resolved_max_hp: float) -> int:
	if state != State.UNINITIALIZED or not is_finite(resolved_max_hp) or resolved_max_hp <= 0.0:
		return Status.INVALID_ARGUMENT
	_resolved_max_hp = resolved_max_hp
	state = State.ARRIVAL_LOCK
	return Status.OK

## Claims the mandatory row once when execution reaches or skips over tick 43200.
func consider_mandatory_spawn(completed_before_tick: int, terminal_locked: bool, boss_already_exists: bool) -> Dictionary:
	if completed_before_tick < 0:
		return {"status": Status.INVALID_ARGUMENT, "spawn": false}
	if _schedule_claimed or terminal_locked or completed_before_tick + 1 < DUE_TICK:
		return {"status": Status.OK, "spawn": false}
	_schedule_claimed = true
	return {"status": Status.OK, "spawn": not boss_already_exists}

## Records the phase-6 applied HP receipt; lethal wins over the 50% transition.
func apply_hp_receipt(receipt_id: int, hp_before: float, hp_after: float) -> int:
	if state == State.UNINITIALIZED \
			or receipt_id <= 0 \
			or not is_finite(hp_before) \
			or not is_finite(hp_after) \
			or hp_before < 0.0 \
			or hp_after < 0.0 \
			or hp_after > hp_before:
		return Status.INVALID_ARGUMENT
	if receipt_id <= _last_damage_receipt_id:
		return Status.DUPLICATE_RECEIPT
	_last_damage_receipt_id = receipt_id
	if hp_after <= 0.0:
		state = State.DEATH_LATCHED
		state_ticks = 0
		phase_transition_pending = false
		return Status.OK
	var threshold_hp := _resolved_max_hp * PHASE_THRESHOLD_RATIO
	if phase_code == 1 and not phase_transition_pending and hp_before > threshold_hp and hp_after <= threshold_hp:
		phase_transition_pending = true
		phase_transition_generation += 1
	return Status.OK

## Advances exactly one Active tick. Paused callers freeze the FSM by not calling it.
func run_active_tick(committed_player_position: Vector2) -> int:
	if state == State.UNINITIALIZED or not committed_player_position.is_finite():
		return Status.INVALID_ARGUMENT
	if state == State.DEATH_LATCHED:
		return Status.OK
	if state == State.TRACK_P1 and phase_transition_pending:
		_enter_phase_shift(committed_player_position)
		return Status.OK
	active_age_ticks += 1
	state_ticks += 1
	match state:
		State.ARRIVAL_LOCK:
			if active_age_ticks >= ARRIVAL_LOCK_TICKS:
				if phase_transition_pending:
					_enter_phase_shift(committed_player_position)
				else:
					state = State.TRACK_P1
					state_ticks = 0
		State.PHASE_SHIFT:
			if state_ticks >= PHASE_SHIFT_TICKS:
				state = State.TRACK_P2
				state_ticks = 0
				phase_code = 2
				phase_transition_pending = false
				fog_generation += 1
		State.TRACK_P2:
			fog_elapsed_ticks += 1
	return Status.OK

func fog_safe_radius() -> float:
	var ratio := clampf(float(fog_elapsed_ticks) / float(FOG_SHRINK_TICKS), 0.0, 1.0)
	return lerpf(FOG_START_RADIUS, FOG_END_RADIUS, ratio)

static func ring_directions(action_generation: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	if action_generation < 0:
		return result
	result.resize(RING_PROJECTILE_COUNT)
	var initial_degrees := float(action_generation % 2) * 22.5
	for index in RING_PROJECTILE_COUNT:
		result[index] = Vector2.RIGHT.rotated(deg_to_rad(initial_degrees + 45.0 * index))
	return result

func _enter_phase_shift(committed_player_position: Vector2) -> void:
	state = State.PHASE_SHIFT
	state_ticks = 0
	fog_anchor = committed_player_position
