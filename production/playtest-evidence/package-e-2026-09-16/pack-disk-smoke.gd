extends SceneTree
var game: Control
var slot_a: String
var slot_b: String
func _initialize():
	_run.call_deferred()
func _run():
	assert(DisplayServer.get_name() != "headless")
	assert(not "--campaign-validation" in OS.get_cmdline_user_args())
	assert(OS.get_user_data_dir().contains("Spirit Nexus E 20260916"))
	slot_a = OS.get_user_data_dir()+"/campaign_game_a.save"
	slot_b = OS.get_user_data_dir()+"/campaign_game_b.save"
	# Only remove the two test-created files if neither existed before this test.
	assert(not FileAccess.file_exists(slot_a) and not FileAccess.file_exists(slot_b))
	game = load("res://src/campaign/CampaignGame.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	assert(game.profile_ready and game.storage._slot_a_path != "")
	assert(game.start_mission(0))
	for i in 120: game.arena.advance(1.0/60,Vector2.RIGHT)
	assert(game.save_and_home())
	game.queue_free()
	await process_frame
	await process_frame
	game = load("res://src/campaign/CampaignGame.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	assert(game.profile_ready and game.continue_run())
	assert(game.arena.state.tick == 120)
	game.ui.update_hud()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/production/playtest-evidence/package-e-2026-09-16/pack-disk-smoke.png")
	game.queue_free()
	await process_frame
	await process_frame
	assert(DirAccess.remove_absolute(slot_a) == OK)
	assert(DirAccess.remove_absolute(slot_b) == OK)
	print("E_PACK_DISK_SMOKE_PASS 120 ticks saved and reloaded; isolated test slots removed ",OS.get_user_data_dir())
	quit()
