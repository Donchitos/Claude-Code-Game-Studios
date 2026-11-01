extends SceneTree
## Unit tests for RecoveryController and HelperBot: downed state, bleedout, helper rescue and revive.

const RecoveryScript = preload("res://src/recovery/recovery_controller.gd")
const HelperScript = preload("res://src/team/helpers/helper_bot.gd")

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
	var recovery = RecoveryScript.new()

	# 1. Starts healthy
	_check(recovery.current_state == RecoveryScript.State.HEALTHY, "Starts in HEALTHY state")

	# 2. Enter Downed (Sistem Çöktü)
	var state_observed := [-1, -1]
	recovery.state_changed.connect(func(o, n):
		state_observed[0] = o
		state_observed[1] = n
	)
	recovery.enter_downed()
	_check(recovery.current_state == RecoveryScript.State.DOWNED, "Transitions to DOWNED (Sistem Çöktü)")
	_check(state_observed[0] == RecoveryScript.State.HEALTHY and state_observed[1] == RecoveryScript.State.DOWNED, "State changed signal emitted")
	_check(recovery.bleedout_remaining == RecoveryScript.MAX_BLEEDOUT_TIME, "Bleedout timer starts at 20.0s")

	# 3. Bleedout decay
	recovery.update(2.0)
	_check(recovery.bleedout_remaining <= 18.0, "Bleedout timer counts down")

	# 4. Helper Bot rescue
	var helper = HelperScript.new()
	helper.set_physics_process(false)
	var player = Node3D.new()
	player.position = Vector3(0.0, 0.0, 0.0)
	helper.position = Vector3(1.0, 0.0, 0.0) # within 1.8m revive reach
	helper.target_player = player
	helper.recovery_system = recovery
	root.add_child(player)
	root.add_child(helper)
	await process_frame

	# Step revive
	_check(recovery.revive_progress == 0.0, "Revive starts at 0% progress")
	helper._physics_process(1.5) # Half revive
	_check(recovery.revive_progress > 0.4, "Helper channels revive progress")

	# Complete revive
	var revived_hp := [0.0]
	recovery.revived.connect(func(hp): revived_hp[0] = hp)
	helper._physics_process(2.0) # Finish revive
	_check(recovery.current_state == RecoveryScript.State.HEALTHY, "Full revive restores HEALTHY state")
	_check(revived_hp[0] == 35.0, "Revive restores 35.0 HP")

	# 5. Bleedout expiration
	recovery.enter_downed()
	var expired_seen := [false]
	recovery.bleedout_expired.connect(func(): expired_seen[0] = true)
	recovery.update(21.0) # Exceed 20s
	_check(recovery.current_state == RecoveryScript.State.DEAD and expired_seen[0], "Bleedout timeout transitions to DEAD")

	# 6. Reset
	recovery.reset()
	_check(recovery.current_state == RecoveryScript.State.HEALTHY, "Reset restores HEALTHY state")
	_check(recovery.bleedout_remaining == RecoveryScript.MAX_BLEEDOUT_TIME, "Reset restores bleedout timer")

	player.queue_free()
	helper.queue_free()
	await process_frame

	print("Recovery tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
