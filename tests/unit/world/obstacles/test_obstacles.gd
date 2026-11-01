extends SceneTree
## Unit tests for HazardObstacle: laser grid evasion, electric water, shelf collapse, and disarming.

const HazardScript = preload("res://src/world/obstacles/hazard_obstacle.gd")

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
	# 1. Laser Grid evasion
	var laser = HazardScript.new()
	laser.hazard_type = HazardScript.HazardType.LASER_GRID
	root.add_child(laser)
	await process_frame

	var mock_player = CharacterBody3D.new()
	mock_player.set_script(load("res://src/player/player_controller.gd"))
	mock_player.tuning = load("res://assets/data/movement_default.tres")
	mock_player.is_slow_walking = false
	root.add_child(mock_player)

	var damage_observed := [0.0, 0.0] # [damage, stun]
	laser.hazard_triggered.connect(func(b, dmg, stun):
		damage_observed[0] = dmg
		damage_observed[1] = stun
	)

	# Standing player triggers laser
	laser._apply_hazard_effect(mock_player)
	_check(damage_observed[0] > 0.0, "Upright player crossing laser grid takes damage")

	# Crawling / slow walking player ducks under laser safely!
	damage_observed[0] = 0.0
	damage_observed[1] = 0.0
	mock_player.is_slow_walking = true
	laser._apply_hazard_effect(mock_player)
	_check(damage_observed[0] == 0.0, "Crawling / slow-walking player safely passes under laser grid")

	# 2. Electric Water shock & stun
	laser.hazard_type = HazardScript.HazardType.ELECTRIC_WATER
	laser._apply_hazard_effect(mock_player)
	_check(damage_observed[1] > 0.0, "Electric water inflicts stun duration")

	# 3. Disarming hazard
	_check(laser.is_active, "Hazard starts active")
	laser.disarm()
	_check(not laser.is_active, "Disarm deactivates hazard")
	damage_observed[0] = 0.0
	damage_observed[1] = 0.0
	laser._apply_hazard_effect(mock_player)
	_check(damage_observed[0] == 0.0 and damage_observed[1] == 0.0, "Disarmed hazard deals no damage")

	# 4. Collapsing Shelf
	var shelf = HazardScript.new()
	shelf.hazard_type = HazardScript.HazardType.COLLAPSING_SHELF
	root.add_child(shelf)
	await process_frame

	var shelf_cleared := [false]
	shelf.obstacle_cleared.connect(func(): shelf_cleared[0] = true)
	shelf.collapse_shelf()
	_check(not shelf.is_active and shelf_cleared[0], "Shelf collapses on impact and emits cleared signal")

	# 5. Reset
	laser.reset_hazard()
	_check(laser.is_active, "Reset restores hazard to active state")

	shelf.queue_free()
	mock_player.queue_free()
	laser.queue_free()
	await process_frame

	print("HazardObstacle tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
