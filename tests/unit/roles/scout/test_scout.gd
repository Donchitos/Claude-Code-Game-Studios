extends SceneTree
## Unit tests for Göz (Scout) role: Recon Drone piloting, Sonar Scan detection, and cooldowns.

const ScoutScript = preload("res://src/roles/scout/scout_role.gd")
const DroneScript = preload("res://src/roles/scout/recon_drone.gd")

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
	var scout = ScoutScript.new()
	root.add_child(scout)
	await process_frame

	# 1. Initialization
	_check(scout.cooldown_q == 0.0 and scout.cooldown_f == 0.0, "Scout cooldowns start ready")
	_check(scout.active_drone == null, "Starts without active drone")

	var player = CharacterBody3D.new()
	player.position = Vector3(0.0, 0.0, 0.0)
	root.add_child(player)

	# 2. Recon Drone deployment
	var drone: Node3D = scout.toggle_drone(player, root)
	_check(is_instance_valid(drone) and scout.active_drone == drone, "Toggle drone deploys new ReconDrone")
	_check(drone.position.y > 1.0, "Drone spawns elevated above player")

	# Test drone driving motion
	if is_instance_valid(drone) and drone.has_method(&"drive"):
		drone.drive(Vector2(0.0, -1.0), Basis.IDENTITY, 0.25) # Forward
		_check(drone.velocity.length() > 5.0, "Drone flight velocity accelerates forward")

	# Drone recall via toggle
	var recalled_drone: Node3D = scout.toggle_drone(player, root)
	_check(recalled_drone == null, "Second toggle recalls drone")
	_check(scout.cooldown_q > 6.0, "Recall starts drone cooldown")

	# 3. Sonar Scan execution
	var target_near = Node3D.new()
	target_near.position = Vector3(5.0, 0.0, 0.0) # 5m away (< 18m)
	root.add_child(target_near)

	var target_far = Node3D.new()
	target_far.position = Vector3(25.0, 0.0, 0.0) # 25m away (> 18m)
	root.add_child(target_far)

	var detected_count: int = scout.trigger_sonar_scan(player.global_position, [target_near, target_far])
	_check(detected_count == 1, "Sonar scan detects target within 18m radius and ignores distant target")
	_check(scout.scanned_targets.has(target_near), "Scanned targets list contains nearby unit")
	_check(not scout.scanned_targets.has(target_far), "Distant target is excluded from scan")
	_check(scout.cooldown_f > 8.0, "Scan sets F cooldown to 10.0s")
	_check(scout.scan_reveal_timer > 5.0, "Scan reveal timer is active")

	# 4. Reset
	scout.reset_role()
	_check(scout.cooldown_q == 0.0 and scout.cooldown_f == 0.0, "Reset clears cooldowns")
	_check(scout.scanned_targets.is_empty(), "Reset clears scanned targets cache")

	target_near.queue_free()
	target_far.queue_free()
	player.queue_free()
	scout.queue_free()
	await process_frame

	print("ScoutRole tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
