extends SceneTree
## Visible lab rehearsal: real mouse input, paused shot rejection, and retained HUD frames.

var _lab: Node3D
var _failures := 0
var _checks := 0


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_lab = load("res://src/lab/mechanics_lab.tscn").instantiate()
	root.add_child(_lab)
	# Rehearse reload/input independently of pursuing bots killing the stationary player.
	# Damage/HUD behavior is exercised explicitly below.
	for enemy in _lab.combat_range.enemies:
		enemy.set_physics_process(false)
	root.grab_focus()
	for index in range(30):
		await process_frame
	if not root.has_focus():
		printerr("NOT ASSESSED: visible combat rehearsal requires window focus")
		quit(2)
		return
	var start: Vector3 = _lab._player.position
	await _key(KEY_D, true)
	await create_timer(0.35).timeout
	await _key(KEY_D, false)
	_expect(_lab._player.position.x > start.x + 0.5, "Focused keyboard input moves the player")
	_lab._reset_lab()
	await create_timer(0.15).timeout
	await _key(KEY_SPACE, true)
	await create_timer(0.08).timeout
	_expect(_lab._player.velocity.y > 0.0, "Space key jumps after focus recovery")
	_expect(Vector2(_lab._player.velocity.x, _lab._player.velocity.z).length() <= 6.0,
		"Space jump does not add horizontal boost")
	await _key(KEY_SPACE, false)
	_lab._reset_lab()
	await create_timer(0.15).timeout
	await _key(KEY_V, true)
	_expect(_lab._player.velocity.y <= 0.0, "Old V binding no longer jumps")
	await _key(KEY_V, false)
	_lab._reset_lab()
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(860, 330)
	Input.parse_input_event(motion)
	await create_timer(0.3).timeout
	await _capture("pistol-hud-initial.png")
	await _click(true)
	_expect(_lab.combat.ammo == 6, "Real held left click consumes exactly one round")
	await _capture("pistol-hud-shot.png")
	await _click(false)
	for index in range(6):
		await _click(true)
		await _click(false)
	_expect(_lab.combat.ammo == 0, "Seven mouse presses empty magazine")
	await _click(true)
	await _click(false)
	_expect(_lab.combat.ammo == 0, "Empty click leaves magazine at zero")
	await _capture("pistol-hud-empty.png")
	_expect(_lab.combat.reload_remaining > 0.0, "Empty magazine automatically reloads")
	_expect(_lab._combat_hud.get_node("ReloadStatus").visible, "HUD shows reload countdown")
	_lab.set_paused(true)
	var remaining: float = _lab.combat.reload_remaining
	await create_timer(0.25).timeout
	_expect(is_equal_approx(_lab.combat.reload_remaining, remaining), "Pause freezes reload timer")
	_lab.set_paused(false)
	await create_timer(2.1).timeout
	_expect(_lab.combat.ammo == 7, "Automatic reload refills after delay")
	await _click(true)
	await _click(false)
	for cycle in range(3):
		await _key(KEY_R, true)
		await _key(KEY_R, false)
		_expect(_lab.combat.ammo == 6 and _lab.combat.reload_remaining > 0.0, "Physical R starts timed reload")
		await create_timer(2.1).timeout
		_expect(_lab.combat.ammo == 7, "Physical R refills after two seconds")
		await _click(true)
		await _click(false)
	_lab.set_paused(true)
	await _key(KEY_R, true)
	await _key(KEY_R, false)
	_expect(_lab.combat.ammo == 6, "Paused R cannot reload")
	_lab.set_paused(false)
	_lab._reset_lab()
	_lab.set_paused(true)
	await _click(true)
	await _click(false)
	_expect(_lab.combat.ammo == 7, "Paused input cannot consume a round")
	_lab.set_paused(false)
	_lab.combat.apply_damage(40.0)
	await create_timer(0.08).timeout
	var bar: ProgressBar = _lab._combat_hud.get_node("HealthBar")
	_expect(bar.value < 100.0 and bar.value > 60.0, "Visible health animates after damage")
	await _capture("pistol-hud-damage-animation.png")
	await create_timer(0.3).timeout
	_expect(is_equal_approx(bar.value, 60.0), "Animated health settles at damaged value")
	await _capture("pistol-hud-damaged.png")
	_lab._reset_lab()
	_expect(bar.value == 100.0 and _lab.combat.ammo == 7, "Reset restores visible health and ammunition")
	root.size = Vector2i(960, 540)
	await create_timer(0.2).timeout
	var ammo: Label = _lab._combat_hud.get_node("Ammo")
	_expect(ammo.get_global_rect().end.x <= root.get_visible_rect().size.x, "Ammo remains in viewport after resize")
	await _capture("pistol-hud-small-window.png")
	print("COMBAT LAB: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	for index in range(3):
		await process_frame


func _click(pressed: bool) -> void:
	if pressed:
		await create_timer(0.22).timeout
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = Vector2(860, 330)
	Input.parse_input_event(event)
	for index in range(3):
		await process_frame


func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var directory := "user://integration-evidence"
	DirAccess.make_dir_recursive_absolute(directory)
	var result := root.get_texture().get_image().save_png(directory.path_join(filename))
	_expect(result == OK, "Screenshot saved: " + filename)


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + description)
