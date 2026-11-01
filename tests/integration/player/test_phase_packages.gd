extends SceneTree
## Real-world integration of selected movement/combat/interaction packages.
var checks := 0
var failures := 0
var lab: Node3D
var pinned_target: Node3D

func _process(_delta: float) -> bool:
	if is_instance_valid(pinned_target) and is_instance_valid(lab):
		root.warp_mouse(lab._camera.unproject_position(pinned_target.global_position))
	return false
func _initialize() -> void:
	call_deferred(&"run_tests")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func run_tests() -> void:
	lab = load("res://src/lab/mechanics_lab.tscn").instantiate()
	root.add_child(lab)
	root.grab_focus()
	create_timer(25.0).timeout.connect(func():
		printerr("PHASE PACKAGES timeout: visible focus/rendering could not complete")
		quit(2))
	Input.action_press(&"camera_center")
	root.warp_mouse(Vector2(640, 360))
	await create_timer(0.3).timeout
	check(lab.get("weapon") != null, "Lab wires world weapon controller")
	check(lab.get("interaction") != null, "Lab wires interaction controller")
	if lab.get("weapon") != null and lab.get("interaction") != null:
		await test_world()
	print("PHASE PACKAGES: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_world() -> void:
	var target = lab.combat_range.targets[0]
	var origin: Vector3 = target.global_position + Vector3(0, 0, 2)
	check(lab.weapon.fire_at(origin, Vector3.FORWARD, false), "Real lab shot accepted")
	check(target.health < target.max_health, "Actual lab target takes damage")
	var door = lab.combat_range.door
	lab._player.reset_to(door.global_position + Vector3(0, 0, 1.5))
	lab.interaction.set_candidate(door, lab._player.global_position, true)
	lab.interaction.step(true, true, 0.02)
	check(door.completed, "E short action opens real lab door")
	lab._reset_lab()
	check(not door.completed and target.health == target.max_health, "F5 resets opened door and target")
	lab.combat.refill_shield()
	lab.combat.apply_damage(50.0, 1)
	check(lab.combat.shield == 0 and lab.combat.health == 90, "Lab damage respects shield overflow")
	lab.set_paused(true)
	check(not lab.try_fire() and not lab.reload_weapon(), "Pause blocks combat commands")
	check(lab.interaction.progress == 0.0, "Pause cancels interaction")
	lab.set_paused(false)
	lab._reset_lab()
	lab.combat.apply_stun(0.5)
	check(not lab.reload_weapon(), "Stun blocks reload commands")
	lab._reset_lab()
	await test_keyboard_interaction()
	await test_breakable_cover()
	await test_lab_options()
	await test_real_occlusion()
	for obstacle in [["JumpLow", -2.0, 0.45], ["JumpMedium", -6.0, 0.75]]:
		lab._player.reset_to(Vector3(0, 0.75, obstacle[1] + 1.1))
		await create_timer(0.15).timeout
		Input.action_press(&"camera_center")
		Input.action_press(&"move_forward")
		Input.action_press(&"jump")
		await create_timer(0.65).timeout
		Input.action_release(&"jump")
		Input.action_release(&"move_forward")
		check(lab._player.position.z < obstacle[1] - 0.3, "%s jump traverses obstacle" % obstacle[0])
	Input.action_release(&"camera_center")
	lab._reset_lab()
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://production/qa/evidence/phase-packages")
	var result := root.get_texture().get_image().save_png("res://production/qa/evidence/phase-packages/lab.png")
	check(result == OK, "Visible package evidence saved")

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	await process_frame
	await process_frame

func test_keyboard_interaction() -> void:
	var terminal = lab.combat_range.terminal
	pinned_target = terminal
	lab._player.reset_to(Vector3(3.0, 0.75, 8.2))
	lab._camera.snap_to_target()
	await create_timer(0.15).timeout
	var mouse := InputEventMouseMotion.new()
	mouse.position = lab._camera.unproject_position(terminal.global_position)
	root.warp_mouse(mouse.position)
	Input.parse_input_event(mouse)
	await key(KEY_E, true)
	await create_timer(0.25).timeout
	check(lab.interaction.progress > 0.0 and not terminal.completed, "Actual E starts terminal hold")
	await key(KEY_E, false)
	check(lab.interaction.progress == 0.0, "Actual E release cancels")
	await key(KEY_E, true)
	await create_timer(1.6).timeout
	await key(KEY_E, false)
	check(terminal.completed and lab.combat_range.door.completed, "Terminal E completion opens linked door")
	pinned_target = null
	lab._reset_lab()

func test_breakable_cover() -> void:
	var cover = lab.combat_range.get_node("BreakableCover")
	cover.receive_hit(100.0, 0)
	await physics_frame
	check(not cover.visible, "Destroyed cover disappears")
	lab._reset_lab()
	await physics_frame
	check(cover.visible and cover.health == 60.0, "Reset restores destroyed cover")

func test_lab_options() -> void:
	await key(KEY_2, true)
	await key(KEY_2, false)
	check(lab.weapon.selected == 1 and lab.combat.ammo == 8, "Key 2 selects shock weapon and HUD capacity")
	await key(KEY_1, true)
	await key(KEY_1, false)
	await key(KEY_F6, true)
	await key(KEY_F6, false)
	check(lab._reduced_effects and lab._feedback.reduced, "F6 reduces feedback")
	lab.try_fire()
	check(not lab._pistol.get_node("MuzzleFlash").visible, "Reduced effects suppress flash")
	await key(KEY_F6, true)
	await key(KEY_F6, false)
	await key(KEY_F7, true)
	await key(KEY_F7, false)
	lab.combat.ammo = 0
	lab.combat.reserve_ammo = 3
	lab.reload_weapon()
	check(lab.combat.ammo == 0, "Limited sample waits before refilling")
	await create_timer(2.1).timeout
	check(lab.combat.ammo == 3 and lab.combat.reserve_ammo == 0, "Limited sample consumes finite reserve after two seconds")
	lab.reload_weapon()
	check(lab.combat.ammo == 3, "Empty reserve cannot create ammunition")
	await key(KEY_F7, true)
	await key(KEY_F7, false)
	lab.reload_weapon()
	await create_timer(2.1).timeout
	check(lab.combat.ammo == 7, "Default unlimited reload is preserved with two-second delay")
	lab._reset_lab()

func test_real_occlusion() -> void:
	var terminal = lab.combat_range.terminal
	lab._player.reset_to(Vector3(3, 0.75, 8.2))
	var wall := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1, 2, 0.25)
	collider.shape = shape
	wall.add_child(collider)
	wall.position = (terminal.global_position + lab._player.global_position) * 0.5
	lab.add_child(wall)
	await physics_frame
	await physics_frame
	check(not lab.combat_range.clear_sight(lab._player, terminal), "Actual wall blocks player-to-terminal line of sight")
	wall.queue_free()
	await physics_frame
	await physics_frame
	check(lab.combat_range.clear_sight(lab._player, terminal), "Removing wall restores line of sight")
	lab._reset_lab()
