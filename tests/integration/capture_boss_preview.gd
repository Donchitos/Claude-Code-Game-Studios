extends SceneTree

# Render evidence only; time-positioned fixture, not a manual playtest.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://src/core/GameRoot.tscn").instantiate()
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	if await game.request_start_battle(101, false) != 0:
		quit(1)
		return
	var battle = game.current_battle
	battle.player.hp = 1000000
	battle.player.attack_interval = 999.0
	battle.completed_active_ticks = 43199
	for tick in 241:
		battle.run_gameplay_phase(1.0 / 60.0)
	var hit_preview := "--hit-feedback" in OS.get_cmdline_user_args()
	if hit_preview:
		battle.player.hp = 100.0
		battle.player.apply_resolved_damage(16.8, "首领扇毒")
	battle.battle_ui.update_hud(battle)
	await process_frame
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://production/playtest-evidence")
	DirAccess.make_dir_recursive_absolute(folder)
	var status := root.get_texture().get_image().save_png(folder.path_join("hit-feedback-preview.png" if hit_preview else "boss-fan-preview.png"))
	print("BOSS_PREVIEW status=", status)
	game.queue_free()
	await process_frame
	quit(0 if status == OK else 1)
