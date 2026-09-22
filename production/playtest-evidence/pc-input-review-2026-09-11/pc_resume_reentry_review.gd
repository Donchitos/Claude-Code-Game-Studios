extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var game = load("res://src/core/GameRoot.tscn").instantiate()
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	await game.request_start_battle(135, false)
	game.current_battle.stage._spawn_left = 999.0
	game.request_pause()
	game.current_battle.battle_ui._overlay.visibility_changed.connect(game._on_window_focus_exited, CONNECT_ONE_SHOT)
	var status: int = game.request_resume()
	print("REENTRY_AFTER_RESUME status=%s focused=%s tree_paused=%s root=%s input=%s ingress=%s ticks=%s" % [status, game.window_focused, paused, game.state, game.current_battle.input_system.state, game.current_battle.input_system.ingress_armed, game.current_battle.completed_active_ticks])
	game._on_window_focus_entered()
	game._physics_process(1.0 / 60.0)
	print("REENTRY_AFTER_REFOCUS focused=%s tree_paused=%s root=%s input=%s ticks=%s" % [game.window_focused, paused, game.state, game.current_battle.input_system.state, game.current_battle.completed_active_ticks])
	game.queue_free()
	await process_frame
	quit()
