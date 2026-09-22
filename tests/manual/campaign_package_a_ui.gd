extends SceneTree
## Isolated in-memory UI fixture; never opens the player's save slots.
var game: Control
var OUT: String = preload("res://tests/fixtures/campaign_evidence.gd").create("campaign_package_a_ui")
func _initialize() -> void:
	_run.call_deferred()
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")
func _run() -> void:
	assert("--campaign-validation" in OS.get_cmdline_user_args())
	root.size = Vector2i(1280, 720)
	game = load("res://src/campaign/CampaignGame.tscn").instantiate()
	root.add_child(game)
	await process_frame
	assert(game.profile_ready)
	var d: Dictionary = game.profile.data
	d.pages = 100
	assert(game.storage.commit_domain_after_images({"campaign_game": d}) == 0)
	game.reload_profile()
	for i in 3:
		assert(game.profile.purchase_branch(i))
	game.show_page("characters")
	await process_frame
	var count := 0
	for button in game.ui.buttons:
		if "需完成8程" in button.text:
			assert(button.disabled)
			count += 1
	assert(count == 3)
	game.ui.content.get_parent().scroll_vertical = int(game.ui.content.get_child(8).position.y)
	await capture("growth-zh")
	assert(game.profile.update_settings({"locale": "en", "font_scale": 1.3}))
	root.size = Vector2i(960, 540)
	game.show_page("characters")
	await process_frame
	game.ui.content.get_parent().scroll_vertical = int(game.ui.content.get_child(8).position.y)
	await capture("growth-en-130")
	game.profile_ready = false
	game.fail("LEGACY_ACTIVE_RUN_REQUIRES_PREVIOUS_VERSION")
	await capture("legacy-error-en-130")
	game.queue_free()
	await process_frame
	await process_frame
	print("PACKAGE_A_UI_PASS")
	quit()
