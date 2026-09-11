extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	# Input actions are synthesized inside Godot, not physical keyboard evidence.
	root.size = Vector2i(1280, 720)
	var game = load("res://src/core/GameRoot.tscn").instantiate()
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	check(await game.request_start_battle(101, false) == 0, "start")
	var battle = game.current_battle
	battle.stage._spawn_left = 999.0
	Input.action_press("move_right")
	for tick in 30:
		game._physics_process(1.0 / 60.0)
	Input.action_release("move_right")
	check(battle.player.position.x > 100.0, "engine input action moves player")
	check(game.request_pause(false) == 0, "pause")
	var frozen: Vector2 = battle.player.position
	var frozen_ticks: int = battle.completed_active_ticks
	for tick in 10:
		game._physics_process(1.0 / 60.0)
	check(battle.player.position == frozen and battle.completed_active_ticks == frozen_ticks, "pause freezes gameplay")
	check(game.request_resume() == 0, "resume")
	game._physics_process(1.0 / 60.0)
	check(battle.player.position == frozen, "released input does not drift after resume")
	battle.player.apply_resolved_damage(16.8, "测试受击")
	battle.battle_ui.update_hud(battle)
	if DisplayServer.get_name() != "headless":
		for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(960, 540)]:
			root.size = dimensions
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var pause_rect: Rect2 = battle.battle_ui._pause_button.get_global_rect()
			# Canvas-items stretch retains logical coordinates at smaller pixel sizes.
			check(battle.battle_ui.get_viewport_rect().encloses(pause_rect), "pause control remains in resized logical viewport")
			var path := "res://production/playtest-evidence/macos-battle-%dx%d.png" % [dimensions.x, dimensions.y]
			check(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path)) == OK, "capture")
	game.queue_free()
	await process_frame
	print("MACOS_GRAPHICAL_%s renderer=%s synthetic_input=true" % ["PASS" if failures == 0 else "FAIL", DisplayServer.get_name()])
	quit(0 if failures == 0 else 1)
