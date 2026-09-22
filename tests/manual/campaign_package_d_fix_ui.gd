extends SceneTree
## Render fixtures with full builds; no human or campaign completion claims.
var OUT: String = preload("res://tests/fixtures/campaign_evidence.gd").create("campaign_package_d_fix_ui")
var game: Control
var failures := 0
func _initialize():
	_run.call_deferred()
func capture(name: String):
	game.arena.queue_redraw()
	game.camera.force_update_scroll()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func _run():
	assert("--campaign-validation" in OS.get_cmdline_user_args())
	game = load("res://src/campaign/CampaignGame.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	assert(game.start_mission(0))
	for i in 4:
		game.arena.state.skills[game.catalog.skills[i].id] = 5
		game.arena.state.passives[game.catalog.passives[i].id] = 5
	var rows: Array = []
	for dimensions in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1216,1108)]:
		root.size = dimensions
		for locale in ["zh-CN","en"]:
			for scale in [1.0,1.15,1.3]:
				assert(game.profile.update_settings({"font_scale":scale,"locale":locale}))
				game.ui.render("battle")
				game.camera.position = game.arena.player_world_position()
				await capture("hud-%dx%d-%s-%d" % [dimensions.x,dimensions.y,locale,roundi(scale*100)])
				var panel: Control = game.ui.hud.get_parent().get_parent()
				var rect := panel.get_global_rect()
				var center: Vector2 = game.arena.get_global_transform_with_canvas()*game.arena.player_world_position()
				var safe := Rect2(center-Vector2(120,120),Vector2(240,240))
				var clear: bool = not rect.intersects(safe) and not game.ui.guidance.get_global_rect().intersects(safe)
				if not clear: failures += 1
				rows.append({"size":str(dimensions),"locale":locale,"scale":scale,"hud":str(rect),"center":str(center),"clear":clear})
	root.size = Vector2i(960,540)
	game.ui.overlay("pause")
	await capture("pause-full-build-en-130")
	game.arena.state.objective.extraction_ready = true
	game.arena.set_pos(game.arena.state.player,game.arena.target_position(0)+Vector2(420,160))
	game.camera.position = game.arena.player_world_position()
	game.ui.render("battle")
	await capture("extraction-en-130")
	assert(game.profile.update_settings({"locale":"zh-CN"}))
	game.ui.render("battle")
	await capture("extraction-zh-130")
	var file := FileAccess.open(OUT+"ui-matrix.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"fixtures":rows,"failures":failures},"\t"))
	file.close()
	print("D_UI samples=",rows.size()," failures=",failures)
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
