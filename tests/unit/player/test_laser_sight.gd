extends SceneTree
## Unit tests for TacticalLaserSight: color themes, raycast collision cutoff, and dot positioning.

const LaserSightScript = preload("res://src/combat/laser_sight.gd")
const PropScript = preload("res://src/combat/damageable_prop.gd")

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
	var laser = LaserSightScript.new()
	root.add_child(laser)
	await process_frame

	# 1. Weapon color themes
	laser.set_weapon_theme(0)
	_check(laser.current_color.r > 0.8 and laser.current_color.g < 0.4, "Weapon 0 sets red laser theme")

	laser.set_weapon_theme(1)
	_check(laser.current_color.b > 0.8 and laser.current_color.g > 0.7, "Weapon 1 sets cyan shock theme")

	laser.set_weapon_theme(2)
	_check(laser.current_color.r > 0.8 and laser.current_color.g > 0.5 and laser.current_color.b < 0.4, "Weapon 2 sets amber shotgun theme")

	laser.set_weapon_theme(3)
	_check(laser.current_color.g > 0.8 and laser.current_color.r < 0.4, "Weapon 3 sets emerald carbine theme")

	# 2. Raycast against physical obstacle
	var obstacle = PropScript.new()
	obstacle.position = Vector3(0.0, 1.0, -8.0)
	root.add_child(obstacle)
	await physics_frame
	await physics_frame

	var space := obstacle.get_world_3d().direct_space_state
	var muzzle_pos := Vector3(0.0, 1.0, 0.0)
	var aim_dir := Vector3(0.0, 0.0, -1.0)

	var hit_endpoint: Vector3 = laser.update_laser(muzzle_pos, aim_dir, space)
	_check(hit_endpoint.z > -8.5 and hit_endpoint.z < -7.0, "Laser stops at physical obstacle contact point")
	_check(laser._box.size.z < 9.0, "Laser beam length scales to obstacle distance")
	_check(laser._dot_mesh.global_position == hit_endpoint, "Laser contact dot positions at collision point")

	# 3. Disabling
	laser.is_enabled = false
	laser.update_laser(muzzle_pos, aim_dir, space)
	_check(not laser.visible, "Disabling laser hides visual beam")

	obstacle.queue_free()
	laser.queue_free()
	await process_frame

	print("LaserSight tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
