extends SceneTree
## Unit tests for Bullet Decals & Ricochet Sparks: decal spawning, normal alignment, pool limits, and bounce ricochets.

const FeedbackScript = preload("res://src/combat/shot_feedback.gd")

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
	var feedback = FeedbackScript.new()
	root.add_child(feedback)
	await process_frame

	# 1. Spawn decal on surface
	_check(feedback._decals.is_empty(), "Starts with zero decals")
	feedback.spawn_impact_decal(Vector3(0.0, 0.0, -5.0), Vector3.UP)
	_check(feedback._decals.size() == 1, "Spawn impact decal adds 1 decal instance")
	_check(feedback._decals[0].remaining == 8.0, "Decal has 8.0s persistent lifetime")

	# 2. Maximum pool limit (32 decals) prevents memory bloat
	for i in range(40):
		feedback.spawn_impact_decal(Vector3(float(i), 0.0, 0.0), Vector3.UP)

	_check(feedback._decals.size() == feedback.MAX_DECALS, "Decal pool clamps strictly to MAX_DECALS (32)")

	# 3. Ricochet spark emission on non-penetrating surface impact
	var initial_sparks: int = feedback._sparks.size()
	# Incoming ray from (0, 1, 0) downward forward at 45 deg against floor normal UP (0, 1, 0)
	var incoming := Vector3(0.0, -1.0, -1.0).normalized()
	feedback.spawn_impact_sparks(Vector3(0.0, 0.0, -2.0), Vector3.UP, false, incoming)
	_check(feedback._sparks.size() > initial_sparks + 2, "Impact with incoming ray generates standard sparks + directional ricochet spark")

	# 4. Decal fade decay
	feedback._process(7.0) # Advance 7s (1s remaining < 2.0s fade threshold)
	_check(feedback._decals[0].remaining < 2.0, "Decal timer counts down toward fade")

	# 5. Reset clears all decals and sparks
	feedback.reset_effects()
	_check(feedback._decals.is_empty(), "Reset clears all active decals")
	_check(feedback._sparks.is_empty(), "Reset clears all active sparks")

	feedback.queue_free()
	await process_frame

	print("Bullet Decals tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
