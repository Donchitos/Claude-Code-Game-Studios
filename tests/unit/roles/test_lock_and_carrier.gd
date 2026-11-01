extends SceneTree
## Unit tests for Kilit (Lock) & Yük (Carrier) roles: EMP, remote hacking, decoys, and boosted throws.

const LockScript = preload("res://src/roles/lock/lock_role.gd")
const CarrierScript = preload("res://src/roles/carrier/carrier_role.gd")
const ThrowableScript = preload("res://src/objects/throwable_prop.gd")
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
	# 1. Kilit (Lock) Role
	var lock = LockScript.new()
	root.add_child(lock)
	await process_frame

	_check(lock.cooldown_q == 0.0 and lock.cooldown_f == 0.0, "Lock cooldowns start ready")

	# Test EMP Fuse Grid
	var laser = HazardScript.new()
	laser.position = Vector3(5.0, 0.0, 0.0) # within 12m
	root.add_child(laser)
	await process_frame

	var disarmed_count: int = lock.trigger_fuse_grid(Vector3.ZERO, [laser])
	_check(disarmed_count == 1 and not laser.is_active, "Fuse grid EMP disarms electronic devices within 12m")
	_check(lock.cooldown_q > 7.0, "EMP triggers 8.0s cooldown")

	# Test Remote Hack
	var mock_station = Node3D.new()
	var station_script = GDScript.new()
	station_script.source_code = "extends Node3D\nvar activated := false\nfunc activate() -> void: activated = true"
	station_script.reload()
	mock_station.set_script(station_script)
	mock_station.position = Vector3(6.0, 0.0, 0.0) # within 10m
	root.add_child(mock_station)

	var hack_started: bool = lock.start_remote_hack(Vector3.ZERO, mock_station)
	_check(hack_started and lock.current_hack_target == mock_station, "Remote hack starts within 10m range")

	# Advance remote hack
	lock._process(2.2) # Complete 2.0s hack
	_check(mock_station.get("activated") == true, "Remote hack completes and activates station")
	_check(lock.current_hack_target == null, "Hack target cleared upon completion")

	# 2. Yük (Carrier) Role
	var carrier = CarrierScript.new()
	root.add_child(carrier)

	var mock_player = CharacterBody3D.new()
	mock_player.position = Vector3(0.0, 0.0, 0.0)
	root.add_child(mock_player)

	# Deploy decoy
	var decoy: Node3D = carrier.deploy_decoy(mock_player, root)
	_check(is_instance_valid(decoy), "Deploy decoy spawns smoke decoy in front of player")
	_check(carrier.cooldown_q > 8.0, "Decoy sets Q cooldown to 9.0s")

	# Power throw
	var prop = ThrowableScript.new()
	root.add_child(prop)
	prop.pick_up(mock_player)

	var throw_observed := [Vector3.ZERO]
	carrier.power_throw_executed.connect(func(t, vel): throw_observed[0] = vel)

	var thrown: bool = carrier.execute_power_throw(prop, Vector3.FORWARD, 10.0)
	_check(thrown and prop.current_state == ThrowableScript.State.THROWN, "Power throw launches carried prop")
	# Base 10.0 * 1.55 = 15.5 m/s
	_check(throw_observed[0].length() > 14.5, "Power throw applies 1.55x boosted launch velocity")

	# Clean up
	if is_instance_valid(decoy): decoy.queue_free()
	prop.queue_free()
	mock_player.queue_free()
	mock_station.queue_free()
	laser.queue_free()
	carrier.queue_free()
	lock.queue_free()
	await process_frame

	print("Lock & Carrier tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
