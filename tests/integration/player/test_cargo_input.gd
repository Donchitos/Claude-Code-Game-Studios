extends SceneTree
## Rendered input rehearsal; no headless execution (captures require frame_post_draw).
var lab: Node3D
var checks := 0
var failures := 0
var pinned: Node3D
var aiming_at := Vector3.ZERO
var pin_world := false

func _initialize() -> void:
	call_deferred(&"run_tests")

func _process(_delta: float) -> bool:
	if is_instance_valid(lab):
		if is_instance_valid(pinned):
			root.warp_mouse(lab._camera.unproject_position(pinned.global_position))
		elif pin_world:
			root.warp_mouse(lab._camera.unproject_position(aiming_at))
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
	create_timer(30).timeout.connect(func(): printerr("CARGO INPUT timed out"); quit(2))
	lab = load("res://src/lab/mechanics_lab.tscn").instantiate()
	root.add_child(lab)
	root.grab_focus()
	Input.action_press(&"camera_center")
	await create_timer(0.25).timeout
	check(root.has_focus(), "Window has focus for actual key events")
	for index in range(3):
		await key(KEY_F2, true)
		await key(KEY_F2, false)
	check(lab.roles.current_profile().role_id == &"yuk", "F2 cycles through implemented roles to Yük")
	var core = lab.cargo.items[1]
	lab._player.reset_to(Vector3(3.5, 0.75, 8.4))
	lab._camera.snap_to_target()
	pinned = core
	await create_timer(0.2).timeout
	await key(KEY_E, true)
	await key(KEY_E, false)
	check(lab.cargo.carrying_core(), "E picks up the aimed reachable core")
	check(is_equal_approx(lab._player.cargo_speed_multiplier, 0.75), "Core reduces actual player movement speed")
	var ammo: int = lab.combat.ammo
	check(not lab.try_fire() and lab.combat.ammo == ammo, "Core prevents shooting without losing ammo")
	pinned = null
	pin_world = true
	aiming_at = Vector3(1, 0.75, 5)
	await key(KEY_Q, true)
	check(lab.cargo.aiming and lab.cargo._preview.visible, "Holding Q renders the throw preview")
	await capture("yuk-trajectory-1280.png")
	await key(KEY_Q, false)
	check(not lab.cargo.carrying_core() and lab.cargo.throw_cooldown > 0, "Releasing Q throws instead of retaining the core")
	check(lab._player.cargo_speed_multiplier == 1.0, "Releasing the core removes the speed restriction")
	lab._reset_lab()
	lab._player.reset_to(Vector3(2, 0.75, 8.4))
	lab._camera.snap_to_target()
	pinned = lab.cargo.items[0]
	await create_timer(0.2).timeout
	await key(KEY_E, true)
	await key(KEY_E, false)
	check(lab.cargo.carried.size() == 1, "E also picks up ordinary cargo")
	await key(KEY_Q, true)
	lab.set_paused(true)
	await key(KEY_Q, false)
	check(not lab.cargo.aiming and lab.cargo.carried.size() == 1, "Pause during Q cancels without releasing cargo")
	lab.set_paused(false)
	await create_timer(0.1).timeout
	check(lab.cargo.carried.size() == 1, "Resuming does not release the cancelled throw")
	pinned = null
	lab._player.rotation.y = 0.0
	await key(KEY_G, true)
	await key(KEY_G, false)
	check(lab.cargo.carried.is_empty(), "G drops cargo in clear nearby space")
	lab._reset_lab()
	lab._player.reset_to(Vector3(0, 0.75, 5))
	lab._camera.snap_to_target()
	aiming_at = Vector3(0, 0.75, 3)
	await create_timer(0.1).timeout
	await key(KEY_F, true)
	await key(KEY_F, false)
	check(lab.cargo._utility_effects.size() == 1 and lab.cargo._utility_effects[0].kind == "smoke", "F deploys the selected smoke")
	await capture("yuk-smoke-1280.png")
	lab._reset_lab()
	await key(KEY_B, true)
	await key(KEY_B, false)
	check(lab.cargo.utility_mode == "bait", "B changes utility to bait")
	var pulses: Array = []
	lab.cargo.noise_emitted.connect(func(point, radius): pulses.append([point, radius]))
	await key(KEY_F, true)
	await key(KEY_F, false)
	check(pulses.size() > 0, "F bait produces a world noise signal in the running lab")
	root.size = Vector2i(960, 540)
	await create_timer(0.15).timeout
	await capture("yuk-bait-960.png")
	var hud: Label = lab._combat_hud.get_node("RoleStatus")
	check(root.get_visible_rect().encloses(hud.get_global_rect()), "Role HUD stays inside the smaller viewport")
	await key(KEY_F5, true)
	await key(KEY_F5, false)
	check(lab.cargo._utility_effects.is_empty() and lab.cargo.carried.is_empty(), "F5 clears cargo and active utilities")
	await key(KEY_F2, true)
	await key(KEY_F2, false)
	check(lab.roles.current_profile().role_id == &"scout", "F2 selects preserved Scout after Yük")
	await key(KEY_F2, true)
	await key(KEY_F2, false)
	check(lab.roles.current_profile().role_id == &"operator", "F2 returns from Scout to Operator")
	Input.action_release(&"camera_center")
	lab.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("CARGO INPUT: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
