extends SceneTree
## Unit tests for AIPerception & EnemyStateMachine: vision cones, hearing, suspicion, and state transitions.

const PerceptionScript = preload("res://src/ai/ai_perception.gd")
const StateMachineScript = preload("res://src/ai/enemy_state_machine.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred(&"_run_tests")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)


func _run_tests() -> void:
	var perception = PerceptionScript.new()
	var sm = StateMachineScript.new()

	var eye_pos := Vector3(0.0, 1.0, 0.0)
	var eye_forward := Vector3(0.0, 0.0, -1.0) # Looking forward (-Z)

	# 1. Vision Cone
	var in_front := Vector3(0.0, 1.0, -8.0)
	var behind := Vector3(0.0, 1.0, 8.0)
	var too_far := Vector3(0.0, 1.0, -25.0)

	_check(perception.is_in_sight_cone(eye_pos, eye_forward, in_front), "Target in front within 14m is inside sight cone")
	_check(not perception.is_in_sight_cone(eye_pos, eye_forward, behind), "Target behind is outside sight cone (no telepathy)")
	_check(not perception.is_in_sight_cone(eye_pos, eye_forward, too_far), "Target beyond 14m vision range is outside sight cone")

	# 2. Hearing
	var gunshot_near := Vector3(8.0, 1.0, 0.0)
	var gunshot_far := Vector3(30.0, 1.0, 0.0)
	_check(perception.can_hear_noise(eye_pos, gunshot_near, 20.0), "Nearby noise (8m) within 20m radius is heard")
	_check(not perception.can_hear_noise(eye_pos, gunshot_far, 20.0), "Distant noise (30m) is not heard")

	# 3. Suspicion meter accumulation & decay
	_check(perception.suspicion == 0.0, "Starts with zero suspicion")
	perception.update_suspicion(0.5, true, 6.0) # Visible target at 6m for 0.5s
	_check(perception.suspicion > 15.0, "Suspicion increases when target is visible")

	perception.update_suspicion(1.5, false, 20.0) # Target lost for 1.5s
	_check(perception.suspicion < 15.0, "Suspicion decays when target is no longer visible")

	# 4. State Machine Transitions
	_check(sm.current_state == StateMachineScript.State.PATROL, "Starts in PATROL state")

	# Rising suspicion transitions to SUSPICIOUS
	sm.update_state(0.1, 40.0, false, false, false, in_front)
	_check(sm.current_state == StateMachineScript.State.SUSPICIOUS, "Moderate suspicion (>=35) transitions to SUSPICIOUS")

	# Direct line of sight transitions to ENGAGED
	sm.update_state(0.1, 80.0, true, false, false, in_front)
	_check(sm.current_state == StateMachineScript.State.ENGAGED, "High suspicion / direct LOS transitions to ENGAGED")
	_check(sm.last_known_target_pos == in_front, "Engaged state tracks last known target position")

	# Target breaks line of sight -> transitions to SEARCH
	sm.update_state(0.1, 50.0, false, false, false, in_front)
	_check(sm.current_state == StateMachineScript.State.SEARCH, "Breaking LOS transitions to SEARCH state")
	_check(sm.search_timer == StateMachineScript.SEARCH_DURATION, "Search state initializes search timer")

	# Search timer expires -> transitions to RETURN
	sm.update_state(5.5, 0.0, false, false, false, in_front)
	_check(sm.current_state == StateMachineScript.State.RETURN or sm.current_state == StateMachineScript.State.PATROL, "Search expiry transitions to RETURN / PATROL")

	# 5. Stun interrupt
	sm.update_state(0.1, 0.0, false, true, false, in_front)
	_check(sm.current_state == StateMachineScript.State.STUNNED, "Stun flag immediately interrupts into STUNNED state")

	# 6. Death interrupt
	sm.update_state(0.1, 0.0, false, false, true, in_front)
	_check(sm.current_state == StateMachineScript.State.DEAD, "Death flag immediately transitions to DEAD state")

	# 7. Reset
	sm.reset()
	_check(sm.current_state == StateMachineScript.State.PATROL, "Reset restores PATROL state")

	print("AIPerception tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
