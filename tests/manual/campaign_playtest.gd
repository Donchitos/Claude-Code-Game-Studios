extends SceneTree
## Graphical viewport evidence, isolated memory profile. No production save changes.
var OUT: String = preload("res://tests/fixtures/campaign_evidence.gd").create("campaign_playtest")
var game: Control
func _initialize() -> void:
	_run.call_deferred()
func _capture(name: String) -> void:
	await process_frame
	await process_frame
	var badge: Label
	if "visual-fixture" in name:
		badge = game.ui._label(game.ui, "VISUAL FIXTURE · NOT A CAMPAIGN CLEAR", 13, Color("d9b978"))
		badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		badge.offset_left = 24
		badge.offset_right = 850
		badge.offset_top = -65
		badge.offset_bottom = -42
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")
	print("CAMPAIGN_SCREENSHOT ", name, " viewport=", root.size)
	if badge != null:
		badge.queue_free()
func _run() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://src/campaign/CampaignGame.tscn").instantiate()
	root.add_child(game)
	await process_frame
	if game.profile == null:
		quit(1)
		return
	print("GRAPHICAL_CATALOG_HASH ", game.catalog.content_hash)
	await _capture("home-1280-zh")
	game.show_page("chapters")
	await _capture("chapters-1280-zh")
	game.command("update_settings", {"locale": "en", "font_scale": 1.3})
	root.size = Vector2i(960, 540)
	game.show_page("home")
	await _capture("home-960-en-130")
	game.show_page("settings")
	await _capture("settings-960-en-130")
	game.command("update_settings", {"locale": "zh-CN", "font_scale": 1.0})
	root.size = Vector2i(1280, 720)
	game.show_page("home")
	game.show_page("settings")
	await _capture("settings-1280-zh")
	game.show_page("home")
	if "--battle" in OS.get_cmdline_user_args():
		game.set_physics_process(false)
		if not game.start_mission(0):
			quit(1)
			return
		for i in 120:
			game._physics_process(1.0 / 60)
		await _dual("battle")
		game.pause_battle()
		await _dual("pause")
		if not game.save_and_home() or not game.continue_run():
			print("GRAPHICAL_SAVE_RESTORE_FAILED")
			game.queue_free()
			await process_frame
			quit(1)
			return
		await _capture("restored-1280")
		root.grab_focus()
		await process_frame
		if game.modal == "pause":
			game.resume_battle()
		var captured := false
		var event_captured := false
		var dense_captured := false
		for i in 18000:
			if game.arena == null or game.modal == "error":
				break
			if game.modal == "pause":
				root.grab_focus()
				await process_frame
				game.resume_battle()
			if game.modal == "upgrade":
				if not captured:
					await _dual("draft")
					captured = true
				_release_movement()
				game.choose(game.arena.state.offered[0])
				game._physics_process(1.0 / 60)
			if game.modal == "event":
				await _dual("event")
				event_captured = true
				game.choose(false)
				break
			if not dense_captured and float(game.arena.state.elapsed) > 20:
				await _dual("battle-active")
				dense_captured = true
			var pos: Vector2 = game.arena.player_world_position()
			var goal := Vector2.ZERO
			var nearest := INF
			for pickup: Dictionary in game.arena.state.pickups:
				var point := Vector2(pickup.x, pickup.y)
				if pos.distance_squared_to(point) < nearest:
					nearest = pos.distance_squared_to(point)
					goal = point
			var dir := pos.direction_to(goal)
			for enemy: Dictionary in game.arena.state.entities:
				var away := pos - Vector2(enemy.x, enemy.y)
				if away.length() < 90 and away.length() > 0:
					dir += away.normalized() * (90 - away.length()) / 25
			for pair in [["move_left", dir.x < -.2], ["move_right", dir.x > .2], ["move_up", dir.y < -.2], ["move_down", dir.y > .2]]:
				if pair[1]: Input.action_press(pair[0])
				else: Input.action_release(pair[0])
			game._physics_process(1.0 / 60)
			if i % 60 == 0:
				await process_frame
		print("GRAPHICAL_NATURAL_DRAFT ", captured, " EVENT ", event_captured, " ACTIVE ", dense_captured)
		for action in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(action)
		await _boss_visual_fixture()
		await _event_visual_fixture()
	game.audio.shutdown()
	await create_timer(0.1).timeout
	game.queue_free()
	await process_frame
	quit()

func _dual(name: String) -> void:
	await _capture(name + "-1280-zh")
	game.command("update_settings", {"locale": "en", "font_scale": 1.3})
	root.size = Vector2i(960, 540)
	await _capture(name + "-960-en-130")
	game.command("update_settings", {"locale": "zh-CN", "font_scale": 1.0})
	root.size = Vector2i(1280, 720)

func _boss_visual_fixture() -> void:
	# Visual-only fixture: original boss definition and genuine simulation, no invented clears.
	# Does not validate normal mission unlocking or claim a boss victory.
	if game.arena != null and not game.save_and_home():
		return
	var mission: Dictionary = {}
	for row: Dictionary in game.catalog.missions:
		if str(row.kind).to_upper() == "BOSS":
			mission = row
			break
	var arena: Node2D = load("res://src/campaign/campaign_arena.gd").new()
	var loadout := {"character_id": game.profile.data.character_id, "difficulty": 0, "branches": [0, 0, 0], "completed": 0, "pill_id": "", "challenge_id": ""}
	if not arena.configure(game.catalog, mission, loadout, 9214):
		arena.free()
		return
	game.arena = arena
	game.world.add_child(arena)
	game.page = "battle"
	game.ui.render("battle")
	for i in 1800:
		if arena.state.finished:
			break
		if not arena.state.offered.is_empty():
			arena.choose_upgrade(arena.state.offered[0])
		if arena.state.event_id != "":
			arena.choose_event(false)
		arena.advance(1.0 / 60, Vector2.ZERO)
		game.camera.position = arena.player_world_position()
		game.ui.update_hud()
		var warning := false
		for zone: Dictionary in arena.state.zones:
			warning = warning or (zone.hostile and float(zone.delay) > 0.2)
		if warning:
			print("BOSS_VISUAL_FIXTURE mission=", mission.id, " elapsed=", arena.state.elapsed, " no_progression_or_victory_claim")
			await _dual("boss-warning-visual-fixture")
			break
		if i % 60 == 0:
			await process_frame
	game._destroy_arena()

func _release_movement() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)

func _event_visual_fixture() -> void:
	# Legal unlocked loadout fixture; no profile/current_run/completion writes.
	var arena: Node2D = load("res://src/campaign/campaign_arena.gd").new()
	var loadout := {"character_id": game.profile.data.character_id, "difficulty": 0, "branches": [0, 0, 0], "completed": 3, "pill_id": "", "challenge_id": ""}
	if not arena.configure(game.catalog, game.catalog.missions[0], loadout, 9214):
		arena.free()
		return
	game.arena = arena
	game.world.add_child(arena)
	game.page = "battle"
	game.ui.render("battle")
	for i in 3600:
		if arena.state.finished:
			break
		if not arena.state.offered.is_empty():
			arena.choose_upgrade(arena.state.offered[0])
		arena.advance(1.0 / 60, Vector2.ZERO)
		game.camera.position = arena.player_world_position()
		game.ui.update_hud()
		if arena.state.event_id != "":
			game.modal = "event"
			game.ui.overlay("event")
			print("EVENT_VISUAL_FIXTURE id=", arena.state.event_id, " elapsed=", arena.state.elapsed, " legal_completed_loadout=3 no_profile_writes")
			await _dual("event-unlocked-visual-fixture")
			break
		if i % 60 == 0:
			await process_frame
	game._destroy_arena()
