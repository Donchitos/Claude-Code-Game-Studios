extends SceneTree
func _initialize():
	_run.call_deferred()
func _run():
	assert("--campaign-validation" in OS.get_cmdline_user_args())
	var game = load("res://src/campaign/CampaignGame.tscn").instantiate()
	root.add_child(game)
	await process_frame
	assert(game.profile_ready and game.profile.data.completed == 0 and game.profile.data.current_run == null)
	assert(game.storage._slot_a_path == "" and game.storage._slot_b_path == "")
	game.set_physics_process(false)
	assert(game.start_mission(0))
	for i in 120: game.arena.advance(1.0/60,Vector2.RIGHT)
	assert(game.arena.state.tick == 120)
	game.camera.position = game.arena.player_world_position()
	game.ui.update_hud()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/production/playtest-evidence/package-d-2026-09-15/pack-smoke.png")
	game.queue_free()
	await process_frame
	await process_frame
	print("D_PACK_GRAPHICAL_SMOKE_PASS temporary_profile nonhuman 120_ticks")
	quit()
