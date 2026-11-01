extends SceneTree
## Integration regression test for P1-I01: full mechanics lab initialization, subsystem wiring, and reset.

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
	var lab_scene: PackedScene = load("res://src/lab/mechanics_lab.tscn")
	_check(lab_scene != null, "Mechanics lab scene loads successfully")

	var lab: Node3D = lab_scene.instantiate()
	root.add_child(lab)
	await process_frame
	await process_frame

	# 1. Player & Camera verified
	_check(is_instance_valid(lab._player), "Player controller instantiated and valid")
	_check(is_instance_valid(lab._camera), "Player camera instantiated and valid")
	_check(lab._player.camera == lab._camera, "Camera injected into player controller")

	# 2. Combat & Weapons verified
	_check(is_instance_valid(lab.weapon), "Weapon controller instantiated")
	_check(lab.weapon.profiles.size() == 4, "Four weapon profiles loaded in lab")
	_check(is_instance_valid(lab._pistol), "Pistol visual instantiated")

	# 3. Roles verified
	_check(is_instance_valid(lab.breaker_role), "Breaker role attached")
	_check(is_instance_valid(lab.scout_role), "Scout role attached")
	_check(lab.active_role_id == "operator" and lab.roles.current_profile().role_id == &"operator", "Starts with integrated Operator profile")

	# 4. Arena fixtures & New Modules verified
	_check(is_instance_valid(lab.combat_range), "Combat range initialized")
	_check(is_instance_valid(lab.combat_range.throwable_prop), "Throwable power cell fixture placed in lab")
	_check(is_instance_valid(lab.combat_range.loot_crate), "Interactive loot crate placed in lab")
	_check(is_instance_valid(lab.combat_range.laser_corridor), "Laser corridor obstacle placed in lab")
	_check(lab.combat_range.enemies.size() >= 2, "Active enemy bots placed in lab")

	# 5. Helper & Recovery verified
	_check(is_instance_valid(lab.helper_bot), "AI helper bot deployed in lab")
	_check(is_instance_valid(lab.recovery), "Recovery system active")
	_check(is_instance_valid(lab.combo_manager), "Combo manager active")

	# 6. Reset test
	lab._reset_lab()
	_check(lab._player.global_position.distance_to(Vector3(0.0, 0.75, 5.0)) < 0.1, "Lab reset restores player to spawn")
	_check(lab.combat.health == 100.0, "Lab reset restores player health")

	lab.queue_free()
	await process_frame

	print("P1 Core Integration tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
