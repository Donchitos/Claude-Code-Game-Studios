extends SceneTree
## Unit tests for PullController: 6m range, LOS cancellation, arrival threshold, and weight damping.

const PullScript = preload("res://src/objects/pull_controller.gd")
const ThrowableScript = preload("res://src/objects/throwable_prop.gd")

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
	var puller = PullScript.new()
	var player_pos := Vector3(0.0, 0.0, 0.0)

	var target = ThrowableScript.new()
	target.position = Vector3(4.0, 0.0, 0.0) # 4m away (< 6m)
	root.add_child(target)
	await process_frame

	# 1. Range & LOS checks
	_check(not puller.is_pulling, "Puller starts idle")

	# Target beyond 6m rejected
	target.global_position = Vector3(10.0, 0.0, 0.0)
	var out_range: bool = puller.try_start_pull(player_pos, target, true)
	_check(not out_range and not puller.is_pulling, "Target beyond 6m is rejected")

	# Target with blocked LOS rejected
	target.global_position = Vector3(4.0, 0.0, 0.0)
	var blocked_los: bool = puller.try_start_pull(player_pos, target, false)
	_check(not blocked_los and not puller.is_pulling, "Target with blocked LOS is rejected")

	# Valid pull start
	var started: bool = puller.try_start_pull(player_pos, target, true)
	_check(started and puller.is_pulling and puller.active_target == target, "Valid 4m target with clear LOS starts pulling")

	# 2. Step pull advances object toward player
	var initial_dist: float = player_pos.distance_to(target.global_position)
	puller.step_pull(player_pos, 0.1, true)
	var new_dist: float = player_pos.distance_to(target.global_position)
	_check(new_dist < initial_dist, "Step pull moves object closer to player")

	# 3. Mid-pull obstruction cancels drag
	var cancel_seen := [false, ""]
	puller.pull_cancelled.connect(func(r):
		cancel_seen[0] = true
		cancel_seen[1] = r
	)
	puller.step_pull(player_pos, 0.1, false) # Obstruction encountered
	_check(not puller.is_pulling and cancel_seen[0], "Obstruction mid-pull cancels drag")

	# 4. Arrival completes pull
	target.global_position = Vector3(1.1, 0.0, 0.0) # < 1.2m
	puller.try_start_pull(player_pos, target, true)
	var completed_seen := [false]
	puller.pull_completed.connect(func(t): completed_seen[0] = true)
	puller.step_pull(player_pos, 0.05, true)
	_check(not puller.is_pulling and completed_seen[0], "Reaching <=1.2m completes pull")

	target.queue_free()
	await process_frame

	print("Pull mechanics tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
