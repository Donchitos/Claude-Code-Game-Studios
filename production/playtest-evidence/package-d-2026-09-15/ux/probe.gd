extends SceneTree
const OUT = "res://production/playtest-evidence/package-d-2026-09-15/ux/"
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	if not "--campaign-validation" in OS.get_cmdline_user_args():
		quit(2)
		return
	root.size = Vector2i(1280,720)
	var game = load("res://src/campaign/CampaignGame.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.start_mission(0)
	game.arena.configure(game.catalog,game.catalog.missions[3],game.profile.data.current_run.loadout,9214) # Isolated render fixture; not journey evidence.
	game.camera.position = game.arena.player_world_position()
	var report := {"scope":"independent Mac graphical layout fixture, no human input, memory storage", "samples":[]}
	for scale in [1.0,1.3]:
		game.command("update_settings", {"font_scale":scale,"locale":"en"})
		game.ui.render("battle")
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+"hunt-start-en-%d.png" % int(scale*100)))
		var panel: Control = game.ui.hud.get_parent().get_parent()
		var p: Vector2 = game.arena.player_world_position()
		var clue: Array = game.arena.mission.clues[0]
		report.samples.append({"font_scale":scale,"hud_rect":str(panel.get_global_rect()),"player_screen":str(game.arena.get_global_transform_with_canvas()*p),"player_world":str(p),"arrow_target":str(game.arena.target_position(0)),"next_clue":str(clue),"hud_text":game.ui.hud.text})
	var f := FileAccess.open(OUT+"probe.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"))
	f.close()
	game.queue_free()
	await process_frame
	quit()
