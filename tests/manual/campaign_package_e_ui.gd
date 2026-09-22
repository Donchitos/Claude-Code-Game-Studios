extends SceneTree
## Actual resized camera/HUD fixtures; not natural play or Windows evidence.
var OUT: String = preload("res://tests/fixtures/campaign_evidence.gd").create("campaign_package_e_ui")
var game: Control
var checks := 0
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func settle() -> void:
	await process_frame
	await process_frame
	game._update_camera_view()
	game.camera.force_update_scroll()
	game.arena.queue_redraw()
	await RenderingServer.frame_post_draw
func _run() -> void:
	assert("--campaign-validation" in OS.get_cmdline_user_args())
	game = load("res://src/campaign/CampaignGame.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	assert(game.start_mission(0))
	game.arena.state.player.xp = 100
	game.arena.advance(1.0/60,Vector2.ZERO)
	assert(game.arena.choose_upgrade(game.arena.state.offered[0]))
	var rows: Array = []
	for dimensions in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1600,600),Vector2i(800,1000)]:
		root.size = dimensions
		for locale in ["zh-CN","en"]:
			assert(game.profile.update_settings({"font_scale":1.3,"locale":locale}))
			game.ui.render("battle")
			for p in [Vector2.ZERO,Vector2(-720,0),Vector2(900,580)]:
				game.arena.set_pos(game.arena.state.player,p)
				game.camera.position = p
				await settle()
				var screen: Rect2 = game.get_viewport_rect()
				var transform: Transform2D = game.arena.get_global_transform_with_canvas()
				var inverse := transform.affine_inverse()
				var visible := (inverse*screen.end-inverse*screen.position).abs()
				check(visible.x <= 1280.1 and visible.y <= 720.1,"maximum visible envelope")
				check((transform*p).distance_to(screen.get_center()) < 1,"camera remains player-centered")
				for sector in 4:
					var q: Vector2 = game.arena.Encounter.spawn_point(game.arena,sector)
					if q.is_finite():
						check(not screen.grow(70*game.camera.zoom.x).has_point(transform*q),"spawn silhouette outside actual viewport")
				var hud: Control = game.ui.hud.get_parent().get_parent()
				var safe := Rect2(transform*p-Vector2(120,120),Vector2(240,240))
				check(not hud.get_global_rect().intersects(safe) and not game.ui.guidance.get_global_rect().intersects(safe),"HUD leaves player center clear")
				check(screen.encloses(game.ui.guidance.get_global_rect()),"queue label stays in viewport")
				rows.append({"window":str(dimensions),"locale":locale,"player":str(p),"visible":str(visible),"zoom":str(game.camera.zoom),"queue":game.ui.guidance.text})
				if p == Vector2.ZERO:
					root.get_texture().get_image().save_png(OUT+"hud-%dx%d-%s.png" % [dimensions.x,dimensions.y,locale])
	var file := FileAccess.open(OUT+"ui.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows":rows,"checks":checks,"failures":failures},"\t"))
	file.close()
	print("PACKAGE_E_UI checks=",checks," failures=",failures)
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
