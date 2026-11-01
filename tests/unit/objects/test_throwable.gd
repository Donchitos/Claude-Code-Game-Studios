extends SceneTree
## Unit tests for ThrowableProp: carrying, throwing, trajectory calculation, and landing.

const ThrowablePropScript = preload("res://src/objects/throwable_prop.gd")

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
	var prop: CharacterBody3D = ThrowablePropScript.new()
	prop.position = Vector3(0.0, 0.0, 0.0)
	root.add_child(prop)
	await process_frame

	# 1. Starts idle on ground
	_check(prop.current_state == ThrowablePropScript.State.IDLE_ON_GROUND, "Prop starts in IDLE_ON_GROUND state")

	# Mock carrier player
	var carrier = Node3D.new()
	carrier.position = Vector3(2.0, 0.0, 2.0)
	root.add_child(carrier)

	# 2. Pick up
	var picked: bool = prop.pick_up(carrier)
	_check(picked and prop.current_state == ThrowablePropScript.State.CARRIED, "Prop attaches to carrier")
	_check(prop._collision.disabled, "Picking up disables collision to prevent self-push")

	# Follow carrier position
	prop._physics_process(0.1)
	_check(prop.global_position.y > 1.0, "Carried prop sits above carrier origin")

	# 3. Parabolic arc prediction calculation
	var arc_points: Array[Vector3] = ThrowablePropScript.calculate_throw_arc(
		Vector3(0.0, 1.5, 0.0),
		Vector3(0.0, 8.0, -12.0),
		24.0,
		30
	)
	_check(arc_points.size() > 5, "Trajectory arc generated multiple sample points")
	_check(arc_points[0].y == 1.5, "First arc point starts at throw origin")
	_check(arc_points[arc_points.size() - 1].y == 0.0, "Final arc point intersects ground level (0.0)")

	# 4. Throwing
	var throw_vel := Vector3(0.0, 6.0, -10.0)
	var thrown: bool = prop.throw_object(throw_vel)
	_check(thrown and prop.current_state == ThrowablePropScript.State.THROWN, "Throw transitions state to THROWN")
	_check(not prop._collision.disabled, "Throw re-enables physics collision")
	_check(prop.velocity == throw_vel, "Prop inherits throw velocity vector")

	# 5. Dropping
	prop.drop_object()
	_check(prop.current_state == ThrowablePropScript.State.IDLE_ON_GROUND, "Drop transitions to IDLE_ON_GROUND")

	# 6. Reset
	prop.reset_prop()
	_check(prop.global_position.is_zero_approx(), "Reset returns prop to spawn origin")

	carrier.queue_free()
	prop.queue_free()
	await process_frame

	print("ThrowableProp tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
