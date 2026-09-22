extends SceneTree
## In-memory real-catalog bot UI journey; overview explicitly uses a preview camera.
const Bot = preload("res://tests/fixtures/campaign_c_bot.gd")
const Arena = preload("res://src/campaign/campaign_arena.gd")
var game: Control
var OUT: String = preload("res://tests/fixtures/campaign_evidence.gd").create("campaign_package_c_ui")
func _initialize() -> void:
	_run.call_deferred()
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func _run() -> void:
	assert("--campaign-validation" in OS.get_cmdline_user_args())
	root.size = Vector2i(1280,720)
	game = load("res://src/campaign/CampaignGame.tscn").instantiate()
	root.add_child(game)
	await process_frame
	assert(game.profile_ready)
	game.set_physics_process(false)
	for index in 8:
		assert(game.start_mission(index))
		var captured := false
		var phases_seen: Array = []
		for i in 24000:
			if game.arena == null: break
			if not game.arena.state.offered.is_empty(): game.arena.choose_upgrade(Bot.choice(game.arena,game.catalog))
			if game.arena.state.event_id != "":
				game.ui.overlay("event")
				await capture("mission-%d-event" % (index+1))
				game.arena.choose_event(false)
				game.ui.render("battle")
			game.arena.advance(1.0/60,Bot.direction(game.arena,game.catalog.missions[index],i))
			game.camera.position = game.arena.player_world_position()
			game.ui.update_hud()
			if index == 3:
				for enemy in game.arena.state.entities:
					if enemy.target_id != "" and not phases_seen.has(int(enemy.phase)):
						await capture("hunt-state-%d" % enemy.phase)
						phases_seen.append(int(enemy.phase))
			if index == 6:
				var mask: int = game.arena.state.encounter.chapter.root_mask
				if not phases_seen.has(mask):
					await capture("roots-mask-%d" % mask)
					phases_seen.append(mask)
			if index == 7:
				var phase: int = game.arena.state.encounter.chapter.boss_phase
				if not phases_seen.has(phase) and game.arena.state.encounter.chapter.attacks[phase] > 0:
					await capture("boss-phase-%d" % (phase+1))
					phases_seen.append(phase)
			if not captured and game.arena.state.elapsed >= (46 if index == 0 else 3):
				await capture("mission-%d-normal" % (index+1))
				captured = true
			if game.arena.state.finished:
				assert(game.arena.state.victory)
				game._sync_battle()
				break
		assert(game.profile.data.completed == index+1)
	await capture("preparation-result-zh")
	assert(game.profile.update_settings({"locale":"en","font_scale":1.3}))
	root.size = Vector2i(960,540)
	game.show_page("result")
	await capture("preparation-result-en-130")
	game.show_page("characters")
	assert(game.page == "characters" and game.arena == null and game.profile.data.current_run == null)
	game.show_page("cultivation")
	assert(game.page == "cultivation")
	assert(game.profile.update_settings({"locale":"zh-CN","font_scale":1.0}))
	root.size = Vector2i(1280,720)
	# Standalone preview arenas use valid prescribed unlock counts; not campaign clears.
	for index in [3,6]:
		var a := Arena.new()
		game.world.add_child(a)
		assert(a.configure(game.catalog,game.catalog.missions[index],{"character_id":"S1-C01","completed":index,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""},42))
		game.arena = a
		game.ui.render("battle")
		game.camera.position = Vector2.ZERO
		game.camera.zoom = Vector2(0.5,0.5)
		for i in 1:
			if not a.state.offered.is_empty(): a.choose_upgrade(a.state.offered[0])
			a.advance(1.0/60,Vector2.ZERO)
		game.ui.update_hud()
		game.ui.body.visible = false
		var banner = game.ui._label(game.ui,"布局预览 · 非通关证据 / LAYOUT PREVIEW",16)
		banner.position = Vector2(700,20)
		banner.size = Vector2(560,50)
		await capture("layout-%d-overview" % index)
		banner.queue_free()
		game.arena = null
		a.free()
	game.queue_free()
	await process_frame
	await process_frame
	print("PACKAGE_C_UI_PASS")
	quit()
