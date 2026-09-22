extends SceneTree
## Run this script with the preserved PCK, then the new project, using isolated slots.
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[0]
	var stem := args[1]
	var c: Dictionary = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var s = load("res://src/persistence/save_system.gd").new()
	assert(s.initialize(stem + "a.save", stem + "b.save") == 0)
	var p = load("res://src/campaign/campaign_profile.gd").new()
	if mode == "blocked":
		assert(not p.initialize(c, s))
		assert(p.error == "LEGACY_ACTIVE_RUN_REQUIRES_PREVIOUS_VERSION")
	else:
		assert(p.initialize(c, s))
		if mode == "prepare":
			assert(c.content_hash == (args[2] if args.size() > 2 else "71d615925151600c8a1255808f20a03d5d44f5fa4efd9f047874e231f45949ca"))
			assert(p.begin_run(0).status == "OK")
			var a = load("res://src/campaign/campaign_arena.gd").new()
			root.add_child(a)
			var run: Dictionary = p.data.current_run
			assert(a.configure(c, c.missions[0], run.loadout, str(run.seed).to_int()))
			for i in 30: a.advance(1.0 / 60.0, Vector2.RIGHT)
			assert(p.save_run(a.snapshot()))
			a.free()
		elif mode == "finish":
			assert(p.data.current_run != null)
			var a = load("res://src/campaign/campaign_arena.gd").new()
			root.add_child(a)
			var run: Dictionary = p.data.current_run
			assert(a.configure(c, c.missions[0], run.loadout, str(run.seed).to_int(), run.snapshot))
			a.advance(1.0 / 60.0, Vector2.RIGHT)
			assert(a.state.tick > run.snapshot.state.tick)
			a.free()
			assert(p.abandon_run()) # Explicit isolated test action, not a player save.
		elif mode == "home":
			assert(p.data.current_run == null and p.data.next_run_id == 2)
	print("LEGACY_PROBE_PASS ", mode, " ", c.content_hash)
	s.free()
	quit()
