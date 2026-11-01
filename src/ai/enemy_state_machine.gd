class_name EnemyStateMachine
extends RefCounted
## Deterministic 7-state AI State Machine for Sector 9 combatants:
## PATROL -> SUSPICIOUS -> ENGAGED -> SEARCH -> RETURN, plus STUNNED and DEAD interrupts.

const PerceptionScript = preload("res://src/ai/ai_perception.gd")

signal state_changed(old_state: State, new_state: State)

enum State {
	PATROL,
	SUSPICIOUS,
	ENGAGED,
	SEARCH,
	RETURN,
	STUNNED,
	DEAD,
}

var current_state: State = State.PATROL
var last_known_target_pos: Vector3 = Vector3.ZERO
var search_timer: float = 0.0

const SEARCH_DURATION: float = 5.0


func transition_to(new_state: State) -> void:
	if new_state == current_state:
		return

	var old_state: State = current_state
	current_state = new_state

	if new_state == State.SEARCH:
		search_timer = SEARCH_DURATION

	state_changed.emit(old_state, new_state)


## Evaluate sensory inputs and determine next state transition.
func update_state(delta: float, suspicion: float, has_los: bool, is_stunned: bool, is_dead: bool, target_pos: Vector3) -> State:
	if is_dead:
		transition_to(State.DEAD)
		return current_state

	if is_stunned:
		transition_to(State.STUNNED)
		return current_state

	# Recover from stun
	if current_state == State.STUNNED and not is_stunned:
		transition_to(State.ENGAGED if has_los else State.SEARCH)

	match current_state:
		State.PATROL:
			if suspicion >= PerceptionScript.SUSPICION_THRESHOLD_ALERT or has_los:
				last_known_target_pos = target_pos
				transition_to(State.ENGAGED)
			elif suspicion >= PerceptionScript.SUSPICION_THRESHOLD_AWARE:
				last_known_target_pos = target_pos
				transition_to(State.SUSPICIOUS)

		State.SUSPICIOUS:
			if has_los or suspicion >= PerceptionScript.SUSPICION_THRESHOLD_ALERT:
				last_known_target_pos = target_pos
				transition_to(State.ENGAGED)
			elif suspicion <= 5.0:
				transition_to(State.RETURN)

		State.ENGAGED:
			if has_los:
				last_known_target_pos = target_pos
			else:
				# Target broke line of sight
				transition_to(State.SEARCH)

		State.SEARCH:
			if has_los:
				last_known_target_pos = target_pos
				transition_to(State.ENGAGED)
			else:
				search_timer -= delta
				if search_timer <= 0.0:
					transition_to(State.RETURN)

		State.RETURN:
			if has_los or suspicion >= PerceptionScript.SUSPICION_THRESHOLD_AWARE:
				transition_to(State.SUSPICIOUS)
			# Reaching patrol point transitions back to PATROL
			else:
				transition_to(State.PATROL)

	return current_state


func reset() -> void:
	current_state = State.PATROL
	last_known_target_pos = Vector3.ZERO
	search_timer = 0.0
