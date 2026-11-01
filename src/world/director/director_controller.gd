class_name DirectorController
extends RefCounted
## Full AI Director managing 4 pacing states (CALM, BUILDUP, PEAK, RECOVERY),
## tension scoring, 120s grace period, and non-repeating event selection.

signal pacing_changed(old_state: PacingState, new_state: PacingState, tension: float)
signal event_dispatched(event_name: String, intensity: float)

enum PacingState {
	CALM,       # Baseline quiet exploration
	BUILDUP,    # Escalating tension and enemy spawns
	PEAK,       # Climactic intensity / maximum threat
	RECOVERY,   # Relief window following high exhaustion or low health
}

var current_state: PacingState = PacingState.CALM
var tension: float = 0.0
var session_elapsed: float = 0.0
var state_timer: float = 0.0
var last_event: String = ""

const FIRST_ROOM_GRACE_TIME: float = 120.0 # First 2 minutes capped below PEAK
const RECOVERY_DURATION: float = 15.0


func advance(delta: float, health_ratio: float, ammo_ratio: float, alarm_level: int) -> PacingState:
	if delta <= 0.0:
		return current_state

	session_elapsed += delta
	state_timer += delta

	# Calculate continuous tension score (0.0 - 100.0)
	var health_threat: float = (1.0 - clampf(health_ratio, 0.0, 1.0)) * 45.0
	var ammo_threat: float = (1.0 - clampf(ammo_ratio, 0.0, 1.0)) * 20.0
	var alarm_threat: float = float(clampi(alarm_level, 0, 4)) * 8.75
	var time_threat: float = clampf(session_elapsed / 300.0, 0.0, 1.0) * 15.0

	tension = clampf(health_threat + ammo_threat + alarm_threat + time_threat, 0.0, 100.0)

	# Exhaustion relief: If player health is critically low (< 25%), force RECOVERY
	if health_ratio < 0.25 and current_state != PacingState.RECOVERY:
		_transition_to(PacingState.RECOVERY)
		return current_state

	match current_state:
		PacingState.CALM:
			if tension >= 35.0:
				_transition_to(PacingState.BUILDUP)

		PacingState.BUILDUP:
			if tension >= 75.0:
				# 120s Grace Period: PEAK is blocked during the first 120 seconds
				if session_elapsed >= FIRST_ROOM_GRACE_TIME:
					_transition_to(PacingState.PEAK)
				else:
					# Hold at high buildup
					pass
			elif tension <= 20.0:
				_transition_to(PacingState.CALM)

		PacingState.PEAK:
			if tension <= 45.0 or state_timer >= 25.0:
				_transition_to(PacingState.RECOVERY)

		PacingState.RECOVERY:
			if state_timer >= RECOVERY_DURATION:
				_transition_to(PacingState.CALM)

	return current_state


func pick_next_event(candidate_events: Array[String]) -> String:
	if candidate_events.is_empty():
		return ""

	var pool: Array[String] = []
	for ev in candidate_events:
		if ev != last_event:
			pool.append(ev)

	if pool.is_empty():
		pool = candidate_events

	var selected: String = pool[0]
	last_event = selected
	event_dispatched.emit(selected, tension)
	return selected


func _transition_to(new_state: PacingState) -> void:
	if new_state == current_state:
		return

	var old: PacingState = current_state
	current_state = new_state
	state_timer = 0.0
	pacing_changed.emit(old, current_state, tension)


func reset() -> void:
	current_state = PacingState.CALM
	tension = 0.0
	session_elapsed = 0.0
	state_timer = 0.0
	last_event = ""
