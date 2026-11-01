extends SceneTree
## New combat contracts are exercised against real resources and physics bodies.

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred(&"run_tests")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func run_tests() -> void:
	var state = load("res://assets/data/player_combat_default.tres").duplicate()
	state.reset()
	check(state.has_method(&"advance"), "Damage state supports shield recharge and stun timers")
	if state.has_method(&"advance"):
		state.max_shield = 40.0
		state.refill_shield()
		state.apply_damage(55.0, 1)
		check(state.shield == 0.0 and state.health == 85.0, "Shield absorbs first and overflow damages health")
		state.apply_damage(50.0, 0)
		check(state.health == 85.0, "Friendly damage is rejected")
		state.advance(1.0)
		check(state.shield == 0.0, "Shield waits before recharging")
		state.advance(5.0)
		check(state.shield > 0.0 and state.shield <= 40.0, "Shield recharges within cap")
		state.apply_stun(0.5)
		check(not state.try_fire(), "Stun blocks shooting")
		state.advance(0.6)
		check(state.try_fire(), "Shooting resumes after stun")
		state.apply_damage(1000.0, 1)
		check(not state.try_fire(), "Zero health blocks shooting")
		state.reset()
		check(state.health == 100.0 and state.stun_remaining == 0.0, "Reset restores combat state")
	check(ResourceLoader.exists("res://src/combat/weapon_controller.gd"), "World weapon controller exists")
	if ResourceLoader.exists("res://src/combat/weapon_controller.gd"):
		await test_weapons(state)
	await test_3d_aiming_and_juice(state)
	print("Combat systems: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_weapons(state: Resource) -> void:
	var controller = load("res://src/combat/weapon_controller.gd").new()
	controller.state = state
	root.add_child(controller)
	controller.set_process(false)
	check(controller.profiles.size() == 4, "Four actual weapon profiles load")
	check(controller.profiles[0].capacity == 7, "Pistol keeps seven rounds")
	var target = load("res://src/combat/damageable_prop.gd").new()
	target.position = Vector3(0, 0, -4)
	target.max_health = 200.0
	root.add_child(target)
	await physics_frame
	await physics_frame
	check(controller.fire_at(Vector3.ZERO, Vector3.FORWARD, false), "Loaded world weapon fires")
	check(target.health < 200.0, "Ray hit damages actual physics target")
	var after: float = target.health
	check(not controller.fire_at(Vector3.ZERO, Vector3.FORWARD, false), "Cooldown rejects rapid duplicate fire")
	check(target.health == after, "Rejected shot has no damage")
	controller.advance(1.0)
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 2, 0.5)
	collision.shape = shape
	wall.add_child(collision)
	wall.position.z = -2.0
	root.add_child(wall)
	await physics_frame
	await physics_frame
	controller.fire_at(Vector3.ZERO, Vector3.FORWARD, false)
	check(target.health == after, "Solid cover blocks damage")
	wall.queue_free()
	await physics_frame
	await physics_frame
	target.team = 0
	controller.advance(1.0)
	controller.fire_at(Vector3.ZERO, Vector3.FORWARD, false)
	check(target.health == after, "Friendly world target is protected")
	controller.select_weapon(1)
	check(state.ammo == 8, "Shock profile has separate loaded magazine")
	controller.select_weapon(0)
	check(state.ammo == 4, "Switching back does not refill spent magazine")
	state.reload()
	state.advance(2.0)
	check(state.ammo == 7, "Unlimited R refill remains available")
	controller.select_weapon(1)
	target.team = 1
	controller.advance(1.0)
	controller.fire_at(Vector3.ZERO, Vector3.FORWARD, false)
	check(target.stun_remaining > 0.0, "Shock weapon stuns a real target")
	controller.select_weapon(2)
	controller.advance(1.0)
	target.position.z = -1.0
	await physics_frame
	await physics_frame
	var pellet_hits := [0]
	target.hit_received.connect(func(_damage): pellet_hits[0] += 1)
	var rounds: int = state.ammo
	controller.fire_at(Vector3.ZERO, Vector3.FORWARD, false)
	check(pellet_hits[0] > 1 and state.ammo == rounds - 1, "Shotgun emits multiple damaging pellets for one round")
	controller.select_weapon(3)
	check(state.ammo == 12, "Carbine has separate 12-round magazine")
	check(controller.current_profile().distance == 35.0, "Carbine has long engagement distance")
	controller.advance(1.0)
	var prev_hp: float = target.health
	controller.fire_at(Vector3.ZERO, Vector3.FORWARD, false)
	check(target.health == prev_hp - 30.0, "Carbine deals 30 damage per shot")
	controller.reset_weapon()
	target.reset_target()
	check(state.ammo == 7 and target.health == 200.0, "World reset restores target and pistol")
	target.queue_free()
	controller.queue_free()
	await process_frame


func test_3d_aiming_and_juice(state: Resource) -> void:
	var PlayerScript = load("res://src/player/player_controller.gd")
	check(PlayerScript.has_method(&"calculate_3d_aim_direction"), "Controller exposes 3D aim calculation")
	if PlayerScript.has_method(&"calculate_3d_aim_direction"):
		var cam_origin := Vector3(0.0, 16.0, 11.2)
		var weapon_origin := Vector3(0.0, 0.86, 0.0)
		var ray_far: Vector3 = (Vector3(0.0, 0.0, -10.0) - cam_origin).normalized()
		var ray_close: Vector3 = (Vector3(0.0, 0.0, -1.5) - cam_origin).normalized()
		var dir_far: Vector3 = PlayerScript.calculate_3d_aim_direction(
			cam_origin, ray_far, weapon_origin, 0.0)
		var dir_close: Vector3 = PlayerScript.calculate_3d_aim_direction(
			cam_origin, ray_close, weapon_origin, 0.0)
		check(dir_close.y < -0.3, "Close aim points steeply downward toward feet")
		check(is_zero_approx(dir_far.y), "Far aim beyond 6m levels out completely to horizontal")
		check(dir_far.is_normalized() and dir_close.is_normalized(), "3D aim directions are normalized")
		var fallback: Vector3 = PlayerScript.calculate_3d_aim_direction(
			Vector3.ZERO, Vector3.FORWARD, weapon_origin, 0.0)
		check(fallback.is_normalized(), "Fallback direction is normalized and finite")

	var PistolScript = load("res://src/combat/pistol_visual.gd")
	var pistol = PistolScript.new()
	pistol.tuning = state
	root.add_child(pistol)
	pistol.aim_pitch = -0.35
	pistol.is_reloading = true
	pistol._process(0.1)
	check(pistol.rotation.x < 0.0, "Visual pistol pitches downward with aim")
	check(pistol._slide.rotation.z < 0.0, "Visual pistol slide tilts into reload stance")
	pistol.reset_visual()
	check(is_zero_approx(pistol.aim_pitch) and not pistol.is_reloading, "Reset clears pitch and reload state")
	pistol.queue_free()

	var FeedbackScript = load("res://src/combat/shot_feedback.gd")
	var feedback = FeedbackScript.new()
	root.add_child(feedback)
	feedback.eject_casing(Vector3.ZERO, Vector3.RIGHT)
	check(feedback._casings.size() == 1, "Eject casing spawns physical casing")
	feedback.spawn_impact_sparks(Vector3.FORWARD, Vector3.UP, true)
	check(feedback._sparks.size() > 0, "Spawn sparks generates impact debris")
	feedback.reset_effects()
	check(feedback._casings.is_empty() and feedback._sparks.is_empty(), "Reset clears active casings and sparks")
	feedback.queue_free()
	await process_frame
