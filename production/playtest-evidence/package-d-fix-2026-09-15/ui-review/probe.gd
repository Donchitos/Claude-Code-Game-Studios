extends SceneTree
const OUT = "res://production/playtest-evidence/package-d-fix-2026-09-15/ui-review/"
const Chapter = preload("res://src/campaign/campaign_chapter_one.gd")
var game
var observations = []
func _initialize():
	_run.call_deferred()
func capture(name):
	game.arena.queue_redraw()
	game.camera.position = game.arena.player_world_position()
	game.camera.force_update_scroll()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func fixture(index):
	assert(game.arena.configure(game.catalog,game.catalog.missions[index],{"character_id":"S1-C01","completed":index,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""},42))
	game.arena.set_pos(game.arena.state.player,Vector2.ZERO)
	for i in 4:
		game.arena.state.skills[game.catalog.skills[i].id] = 5
		game.arena.state.passives[game.catalog.passives[i].id] = 5
func _run():
	assert("--campaign-validation" in OS.get_cmdline_user_args())
	game = load("res://src/campaign/CampaignGame.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	assert(game.start_mission(0))
	fixture(7)
	for e in game.arena.state.entities:
		if e.target_id != "":
			e.hp = e.max_hp*0.5
			e.timer = 0
			Chapter.boss(game.arena,e,Vector2.ZERO)
	# Layout-root rendering fixture deliberately straddles HUD; emitted through production API.
	game.arena.emit_layout_root({"center":[-240,-260],"radius":140,"damage":10,"active_ticks":120,"warning_ticks":72})
	assert(game.arena.state.encounter.chapter.landings.size() == 2)
	for dim in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1216,1108)]:
		root.size = dim
		for lang in ["zh-CN","en"]:
			for scale in [1.0,1.15,1.3]:
				assert(game.profile.update_settings({"locale":lang,"font_scale":scale}))
				game.ui.render("battle")
				await capture("warnings-%dx%d-%s-%d" % [dim.x,dim.y,lang,roundi(scale*100)])
				var rect = game.ui.hud.get_parent().get_parent().get_global_rect()
				var center = game.arena.get_global_transform_with_canvas()*game.arena.player_world_position()
				assert(not rect.intersects(Rect2(center-Vector2(120,120),Vector2(240,240))))
				observations.append({"size":str(dim),"locale":lang,"scale":scale,"hud":str(rect),"center":str(center),"boss_landings":2,"layout_root_warning":true})
	root.size = Vector2i(960,540)
	game.ui.overlay("pause")
	await capture("pause-full-build-en-130")
	fixture(0)
	game.ui.render("battle")
	game.fail("INVALID_BATTLE_CHECKPOINT")
	await capture("checkpoint-error-en-130")
	assert(game.ui.buttons.size() == 1)
	assert(game.ui.buttons[0].text == "Reload saved progress")
	game.ui.navigate(&"ui_activate")
	await process_frame
	assert(game.arena == null and game.modal == "" and game.page == "home")
	assert(game.continue_run())
	observations.append({"error_reload_via_focused_ui":true,"continued_reliable_memory_run":true})
	fixture(3)
	for i in 3:
		assert(game.arena.navigation_target() == Vector2(game.arena.mission.clues[i][0],game.arena.mission.clues[i][1]))
		game.ui.render("battle")
		await capture("hunt-clue-%d" % i)
		game.arena.set_pos(game.arena.state.player,game.arena.navigation_target())
		game.arena.advance(1.0/60,Vector2.ZERO)
		if game.arena.state.event_id != "": game.arena.choose_event(false)
	var found = false
	for e in game.arena.state.entities:
		if e.target_id != "":
			game.arena.set_pos(e,Vector2(350,-140))
			assert(game.arena.navigation_target() == Vector2(350,-140))
			found = true
	assert(found)
	game.ui.render("battle")
	await capture("hunt-live-target")
	observations.append({"next_clues_0_1_2":true,"live_target_tracks_entity":true,"found_teaching":game.arena.teaching_text("en")})
	var f = FileAccess.open(OUT+"probe.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(observations,"\t"))
	f.close()
	print("UI_REVIEW_PASS rows=",observations.size()," persistence=memory")
	game.queue_free()
	await process_frame
	quit()
