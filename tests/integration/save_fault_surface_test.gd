extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://src/core/GameRoot.tscn").instantiate()
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	# Expected injected fault; no disk access or real profile mutation.
	game._enter_fault("SAVE_COMMIT_FAILED")
	var ok: bool = game.has_node("FaultNotice") and game.state == game.State.CONTROLLED_FAULT
	ok = ok and await game.request_start_battle(101, false) == game.Status.WRONG_STATE
	ok = ok and game.request_progression_purchase(1) == game.Status.WRONG_STATE
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		ok = ok and game.get_node("FaultNotice").size == Vector2(1280, 720)
		ok = ok and root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://production/playtest-evidence/save-fault-preview.png")) == OK
	game.queue_free()
	await process_frame
	print("SAVE_FAULT_SURFACE_%s expected_injected_error=true" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
