extends SceneTree

var failures := 0
var checks := 0
const EVIDENCE := "res://production/playtest-evidence/pc-input-r3-r8-2026-09-11"

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func capture_surface(game: ProductionGameRoot, surface: String, controls: Array) -> void:
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = dimensions
		await process_frame
		await process_frame
		game._process(0.0)
		for control: Control in controls:
			check(control.is_visible_in_tree() and control.get_viewport_rect().encloses(control.get_global_rect()), surface + " visible " + control.name + " " + str(dimensions))
			check(control.size.y >= control.get_combined_minimum_size().y, surface + " text height fits " + control.name)
		var focus := root.gui_get_focus_owner()
		check(focus != null and focus.is_visible_in_tree() and not (focus is BaseButton and focus.disabled), surface + " reachable focus")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(EVIDENCE + "/" + surface + "-%dx%d.png" % [dimensions.x, dimensions.y]) == OK, surface + " capture")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(EVIDENCE)
	var game := load("res://src/core/GameRoot.tscn").instantiate() as ProductionGameRoot
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	var home := game.current_page as ProductionHomeScreen
	await capture_surface(game, "home", [home._title, home._subtitle, home._wallet_label, home._progression_status, home._start_button] + home._branch_buttons)
	check(await game.request_start_battle(43, false) == 0, "start")
	var battle := game.current_battle
	var ui := battle.battle_ui
	battle.stage._spawn_left = 999.0
	await capture_surface(game, "active", [ui._hud_label, ui._hint, ui._pause_button])
	Input.action_press(&"move_right")
	game._physics_process(1.0 / 60.0)
	var held_position := battle.player.position
	check(game.request_pause() == 0, "pause held")
	game._process(0.0)
	check(ui._overlay_subtitle.text.contains(ProductionBattleUI.NEUTRAL_HINT), "ordinary pause explains barrier")
	await capture_surface(game, "pause", [ui._overlay_title, ui._overlay_subtitle, ui._choice_buttons[0]])
	check(game.request_resume() == 0, "resume held")
	game._physics_process(1.0 / 60.0)
	game._process(0.0)
	check(ui._hint.text == ProductionBattleUI.NEUTRAL_HINT and battle.player.position == held_position, "held resume shows wait and does not move")
	battle.pending_upgrade = true
	check(game.request_pause(true) == 0, "upgrade held")
	game._process(0.0)
	check(ui._overlay_subtitle.text.contains(ProductionBattleUI.NEUTRAL_HINT), "upgrade explains upcoming barrier")
	await capture_surface(game, "upgrade", [ui._overlay_title, ui._overlay_subtitle] + ui._choice_buttons)
	game._on_upgrade_selected(0)
	game._physics_process(1.0 / 60.0)
	game._process(0.0)
	check(battle.player.position == held_position and ui._hint.text == ProductionBattleUI.NEUTRAL_HINT, "upgrade resume held remains explained")
	Input.action_release(&"move_right")
	game._physics_process(1.0 / 60.0)
	game._process(0.0)
	check(not battle.input_system.neutral_required and ui._hint.text == ProductionBattleUI.MOVEMENT_HINT and not ui._overlay_subtitle.text.contains(ProductionBattleUI.NEUTRAL_HINT), "barrier clears both explanations")
	# Invoke the real topology callback with no claim of a connected physical pad.
	Input.action_press(&"move_right")
	game._on_joy_connection_changed(919, true)
	game._physics_process(1.0 / 60.0)
	game._process(0.0)
	check(ui._hint.text == ProductionBattleUI.NEUTRAL_HINT and battle.player.position == held_position, "active topology change waits visibly")
	await capture_surface(game, "active-neutral", [ui._hud_label, ui._hint, ui._pause_button])
	Input.action_release(&"move_right")
	game._physics_process(1.0 / 60.0)
	game._process(0.0)
	check(ui._hint.text == ProductionBattleUI.MOVEMENT_HINT, "topology wait clears")
	await game.request_end_battle(true)
	var settlement := game.current_page as ProductionSettlementScreen
	await capture_surface(game, "settlement", [settlement._title, settlement._summary, settlement._retry, settlement._home])
	game.queue_free()
	await process_frame
	print("PC_UI_SURFACES_%s checks=%d renderer=%s physical_device=false" % ["PASS" if failures == 0 else "FAIL", checks, DisplayServer.get_name()])
	quit(0 if failures == 0 else 1)
