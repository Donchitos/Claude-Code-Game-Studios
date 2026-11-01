extends SceneTree
## Rendered role command wiring, cancellation and pause regressions.
var lab: Node3D
var checks := 0
var failures := 0
var pinned: Node3D

func _initialize() -> void:
	call_deferred(&"run_tests")

func _process(_delta: float) -> bool:
	if is_instance_valid(pinned) and is_instance_valid(lab):
		root.warp_mouse(lab._camera.unproject_position(pinned.global_position))
	return false

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + description)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	for index in range(4):
		await process_frame

func capture(_filename: String) -> void:
	await RenderingServer.frame_post_draw
	# Evidence writing is owned by the parent, outside this integration scope.

func run_tests() -> void:
	create_timer(35).timeout.connect(func(): printerr("ROLE INPUT timed out"); quit(2))
	lab = load("res://src/lab/mechanics_lab.tscn").instantiate()
	root.add_child(lab)
	# Isolate command/channel timing from autonomous combat damage.
	for enemy in lab.combat_range.enemies:
		enemy.set_physics_process(false)
	root.grab_focus()
	Input.action_press(&"camera_center")
	await create_timer(0.25).timeout
	check(root.has_focus(), "Window accepts role keys")
	lab.combat.apply_damage(50, 1)
	await key(KEY_F2, true)
	await key(KEY_F2, false)
	check(lab.roles.current_profile().role_id == &"kilit" and lab.weapon.selected == 1, "F2 equips Kilit shock weapon")
	pinned = lab.combat_range.role_stations[0]
	lab._player.reset_to(Vector3(7, 0.75, 8))
	lab._camera.snap_to_target()
	await create_timer(0.2).timeout
	await key(KEY_Q, true)
	await key(KEY_Q, false)
	check(lab.roles.is_hacking() and lab._player.ability_locked, "Q begins a locked hack through actual lab targeting")
	var ammo: int = lab.combat.ammo
	check(not lab.try_fire() and not lab.reload_weapon() and lab.combat.ammo == ammo, "Hack blocks shooting and reloading")
	await capture("kilit-hack.png")
	await key(KEY_W, true)
	await key(KEY_W, false)
	check(not lab.roles.is_hacking() and not lab._player.ability_locked, "Movement intent cancels hack and unlocks movement")
	await key(KEY_Q, true)
	await key(KEY_Q, false)
	lab.combat.apply_damage(1, 1)
	check(not lab.roles.is_hacking() and not lab._player.ability_locked, "Damage signal immediately cancels channel")
	await key(KEY_Q, true)
	await key(KEY_Q, false)
	lab.set_paused(true)
	check(not lab.roles.is_hacking() and not lab._player.ability_locked, "Pause cancels hack without completing target")
	lab.set_paused(false)
	await key(KEY_Q, true)
	await key(KEY_Q, false)
	await create_timer(3.1).timeout
	check(pinned.completed and lab.combat_range.role_stations[1].completed, "Full lab hack opens the linked role door")
	check(not lab._player.ability_locked and lab.roles.hack_cooldown_remaining > 0, "Successful channel releases movement and starts cooldown")
	await key(KEY_F5, true)
	await key(KEY_F5, false)
	check(not pinned.completed and lab.roles.hack_cooldown_remaining == 0, "F5 restores hacked lab systems and clears role cooldown")
	pinned = null
	lab.combat.health = 50
	await key(KEY_F2, true)
	await key(KEY_F2, false)
	check(lab.roles.current_profile().role_id == &"kirici" and lab.weapon.selected == 2, "F2 equips Kırıcı shotgun")
	check(lab.combat.max_health == 150 and lab.combat.health == 75, "Kırıcı health bonus preserves current health ratio")
	check(lab._player.role_walk_multiplier == 0.7 and lab.weapon.noise_multiplier == 1.5, "Kırıcı movement and shot noise modifiers are wired")
	lab._player.reset_to(Vector3(-6, 0.75, 11.8))
	lab._camera.snap_to_target()
	pinned = lab.combat_range.get_node("BreakableDoor")
	await create_timer(0.3).timeout
	var before: Vector3 = lab._player.global_position
	await key(KEY_Q, true)
	await key(KEY_Q, false)
	check(not pinned.visible and pinned.health == 0, "Actual Q breaks the lab door")
	check(lab._player.global_position.distance_to(before) < 0.05, "Actual Q does not dash player")
	pinned = null
	lab._player.reset_to(Vector3(0, 0.75, 5))
	lab._camera.snap_to_target()
	root.warp_mouse(lab._camera.unproject_position(Vector3(0, 0.75, 1)))
	await create_timer(0.2).timeout
	await key(KEY_F, true)
	await key(KEY_F, false)
	check(is_instance_valid(lab.roles.active_shield), "Actual F places shield on lab floor")
	if is_instance_valid(lab.roles.active_shield):
		var shield = lab.roles.active_shield
		lab.set_paused(true)
		var remaining: float = shield.remaining
		await create_timer(0.25).timeout
		check(shield.remaining == remaining, "Lab pause freezes active shield lifetime")
		await capture("kirici-shield.png")
		lab._reset_lab()
		check(lab.roles.active_shield == null and not shield.visible, "Paused F5 immediately removes active shield")
		lab.set_paused(false)
	Input.action_release(&"camera_center")
	lab.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("ROLE INPUT: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
