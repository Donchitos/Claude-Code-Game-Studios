extends SceneTree
## Standalone combat state and actual HUD integration regression tests.

var _checks := 0
var _failures := 0


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_expect(ResourceLoader.exists("res://src/combat/player_combat.gd"), "Combat state exists")
	if not ResourceLoader.exists("res://src/combat/player_combat.gd"):
		_finish()
		return
	var state = load("res://assets/data/player_combat_default.tres").duplicate()
	state.reset()
	_expect(state.ammo == 7, "Actual preset starts with seven rounds")
	var shots := [0]
	state.fired.connect(func(): shots[0] += 1)
	for index in range(7):
		_expect(state.try_fire(), "Loaded pistol accepts shot %d" % (index + 1))
		_expect(state.ammo == 6 - index, "Accepted shot consumes one round")
	_expect(not state.try_fire(), "Eighth shot is rejected")
	_expect(state.ammo == 0 and shots[0] == 7, "Empty pistol emits no extra shot")
	state.apply_damage(25.0)
	_expect(is_equal_approx(state.health, 75.0), "Damage subtracts health")
	state.apply_damage(-10.0)
	_expect(is_equal_approx(state.health, 75.0), "Negative damage cannot heal")
	state.apply_damage(INF)
	_expect(is_equal_approx(state.health, 75.0), "Nonfinite damage is rejected")
	_expect(state.has_method(&"reload"), "Unlimited magazine reload is available")
	if state.has_method(&"reload"):
		for cycle in range(3):
			state.reload()
			state.advance(2.0)
			_expect(state.ammo == 7, "Reload refills magazine every time")
			_expect(state.health == 75.0, "Reload does not heal player")
			state.try_fire()
		state.reload()
	state.apply_damage(200.0)
	_expect(state.health == 0.0, "Lethal damage clamps to zero")
	state.reset()
	_expect(state.health == 100.0 and state.ammo == 7, "Reset restores health and magazine")
	_expect(ResourceLoader.exists("res://src/ui/player_hud.gd"), "HUD exists")
	if ResourceLoader.exists("res://src/ui/player_hud.gd"):
		await _test_hud(state)
	_expect(InputMap.has_action(&"fire"), "Actual project registers fire action")
	if InputMap.has_action(&"fire"):
		var left_click := false
		for event in InputMap.action_get_events(&"fire"):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				left_click = true
		_expect(left_click, "Fire uses actual left mouse button mapping")
	_expect(InputMap.has_action(&"reload"), "Actual project registers reload")
	if InputMap.has_action(&"reload"):
		var r_key := false
		for event in InputMap.action_get_events(&"reload"):
			if event is InputEventKey and event.physical_keycode == KEY_R:
				r_key = true
		_expect(r_key, "Reload is mapped to physical R")
	await _test_lab()
	_finish()


func _test_lab() -> void:
	var lab = load("res://src/lab/mechanics_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	_expect(lab.has_method(&"try_fire"), "Lab exposes guarded shooting")
	if lab.has_method(&"try_fire"):
		lab.set_process(false)
		lab.set_physics_process(false)
		lab._player.set_physics_process(false)
		lab._camera.set_process(false)
		lab.get_window().grab_focus()
		await process_frame
		var state = lab.combat
		_expect(lab.try_fire(), "Lab accepts loaded shot")
		_expect(state.ammo == 6, "Lab uses injected state")
		_expect(lab._pistol.get_node("MuzzleFlash").visible, "Accepted shot flashes muzzle")
		_expect(lab._pistol.has_node("MuzzleLight"), "Accepted shot has real room lighting")
		if lab._pistol.has_node("MuzzleLight"):
			_expect(lab._pistol.get_node("MuzzleLight").visible, "Shot lights nearby environment")
		lab._pistol._process(0.03)
		_expect(lab._pistol.get_node("Slide").position.z > 0.0, "Shot recoils slide")
		var pose: Vector3 = lab._pistol.get_node("Slide").position
		lab._pistol.confirm_hit(0.08)
		lab._pistol._process(0.02)
		_expect(lab._pistol.get_node("Slide").position == pose, "Hit-stop holds only the weapon pose")
		lab.weapon.select_weapon(3)
		_expect(lab._pistol.get_node("Slide/Barrel").mesh.size.z == 1.0, "Carbine has distinct long silhouette")
		lab.weapon.select_weapon(0)
		lab.set_paused(true)
		_expect(not lab.try_fire() and state.ammo == 6, "Pause blocks shots")
		lab.set_paused(false)
		lab._reset_lab()
		_expect(state.ammo == 7 and state.health == 100.0, "Lab reset restores state")
		_expect(not lab._pistol.get_node("MuzzleFlash").visible, "Lab reset clears flash")
		_expect(lab._pistol.get_node("Slide").position.is_zero_approx(), "Lab reset clears recoil")
	lab.queue_free()
	await process_frame
	# Audio playback is retired on the mixer thread, after node deletion.
	await create_timer(0.2).timeout


func _test_hud(state: Resource) -> void:
	var hud = load("res://src/ui/player_hud.gd").new()
	root.add_child(hud)
	hud.bind_state(state)
	var bar: ProgressBar = hud.get_node("HealthBar")
	_expect(not bar.show_percentage, "Health bar has no numeric text")
	var frame: StyleBoxFlat = bar.get_theme_stylebox(&"background")
	var fill: StyleBoxFlat = bar.get_theme_stylebox(&"fill")
	_expect(frame.border_color == Color.BLACK and frame.border_width_left > 0, "Health frame is black")
	_expect(fill.bg_color.r > 0.7 and fill.bg_color.g < 0.2, "Health fill is red")
	state.apply_damage(25.0)
	_expect(bar.value == 100.0, "Damage does not snap visible health")
	await create_timer(0.08).timeout
	_expect(bar.value < 100.0 and bar.value > 75.0, "Damage animates toward reduced health")
	hud.set_paused(true)
	var frozen: float = bar.value
	await create_timer(0.08).timeout
	_expect(is_equal_approx(bar.value, frozen), "Pause freezes health animation")
	hud.set_paused(false)
	state.apply_damage(25.0)
	await create_timer(0.4).timeout
	_expect(is_equal_approx(bar.value, 50.0), "Repeated damage retargets animation")
	_expect(hud._animation == null, "Finished health tween is released before later pause/resume")
	state.try_fire()
	_expect(hud.get_node("Ammo").text.contains("6 / 7"), "Ammo HUD observes accepted shots")
	_expect(hud.get_node("Ammo").anchor_right == 1.0 and hud.get_node("Ammo").anchor_bottom == 1.0,
		"Ammo stays bottom right")
	_expect(hud.get_node("Crosshair").text == "+", "Crosshair is a simple plus")
	state.reset()
	hud.reset_display()
	_expect(bar.value == 100.0 and hud.get_node("Ammo").text.contains("7 / 7"), "Reset restores actual HUD")
	hud.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + description)


func _finish() -> void:
	print("Combat tests: %d assertions; %d failures." % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
