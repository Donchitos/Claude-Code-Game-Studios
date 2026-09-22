extends SceneTree
## Three real missions, legal fresh progression, one disk resume at every new stage.
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Bot = preload("res://tests/fixtures/campaign_c_bot.gd")
const Profile = preload("res://src/campaign/campaign_profile.gd")
const Storage = preload("res://src/persistence/save_system.gd")
var failed := false
var rows: Array = []
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var c: Dictionary = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var stem := OS.get_temp_dir()+"/package_c_journey_%d" % Time.get_ticks_usec()
	var storage := Storage.new()
	assert(storage.initialize(stem+"a",stem+"b") == 0)
	var profile := Profile.new()
	assert(profile.initialize(c,storage))
	seed(977 if "--alternate-build" in OS.get_cmdline_user_args() else 711)
	for index in 8:
		for branch in 3:
			if profile.data.pages >= 4 and profile.data.branches[branch] == 0: assert(profile.purchase_branch(branch))
		assert(profile.begin_run(index).status == "OK")
		var run: Dictionary = profile.data.current_run
		var arena := Arena.new()
		root.add_child(arena)
		assert(arena.configure(c,c.missions[index],run.loadout,str(run.seed).to_int()))
		# Include the setup boundary before the first waypoint can advance.
		var initial := arena.snapshot()
		assert(profile.save_run(initial))
		storage.free()
		storage = Storage.new()
		assert(storage.initialize(stem+"a",stem+"b") == 0)
		profile = Profile.new()
		assert(profile.initialize(c,storage))
		run = profile.data.current_run
		arena.free()
		arena = Arena.new()
		root.add_child(arena)
		assert(arena.configure(c,c.missions[index],run.loadout,str(run.seed).to_int(),run.snapshot))
		var last_stages := JSON.stringify(arena.state.encounter.stage_ticks)
		var restores := 1
		var choices := 0
		var last_choice_tick := -1
		var choice_gaps := []
		var invalid_ticks := []
		for tick in 30000:
			if arena.state.finished: break
			if not arena.state.offered.is_empty():
				assert(arena.choose_upgrade(Bot.choice(arena,c)))
				choices += 1
				if last_choice_tick >= 0: choice_gaps.append(arena.state.tick-last_choice_tick)
				last_choice_tick = arena.state.tick
			if arena.state.event_id != "": assert(arena.choose_event(false))
			arena.advance(1.0/60,Bot.direction(arena,c.missions[index],tick))
			if not Arena.validate_snapshot(c,c.missions[index],arena.snapshot()):
				if invalid_ticks.size()<10: invalid_ticks.append(arena.state.tick)
			var stages := JSON.stringify([arena.state.encounter.stage_ticks,arena.state.encounter.get("chapter",{}).get("clues",0),arena.state.encounter.get("chapter",{}).get("root_mask",0),arena.state.encounter.get("chapter",{}).get("attacks",[]),arena.state.event_id,arena.state.event_done])
			if stages != last_stages and not arena.state.finished:
				last_stages = stages
				var snap := arena.snapshot()
				assert(Arena.validate_snapshot(c,c.missions[index],snap))
				assert(profile.save_run(snap))
				storage.free()
				storage = Storage.new()
				assert(storage.initialize(stem+"a",stem+"b") == 0)
				profile = Profile.new()
				assert(profile.initialize(c,storage))
				run = profile.data.current_run
				var next := Arena.new()
				root.add_child(next)
				assert(next.configure(c,c.missions[index],run.loadout,str(run.seed).to_int(),run.snapshot))
				assert(JSON.stringify(next.snapshot(),"",true,true) == JSON.stringify(snap,"",true,true))
				arena.free()
				arena = next
				restores += 1
		var row := {"mission":c.missions[index].id,"victory":arena.state.victory,"elapsed":arena.state.elapsed,"choices":choices,"restores":restores,"stages":arena.state.encounter.stage_ticks,"skipped":arena.state.encounter.skipped,"level":arena.state.player.level,"hp":arena.state.player.hp,"escort_hp":arena.state.objective.escort_hp}
		row.choice_gaps = choice_gaps
		row.invalid_ticks = invalid_ticks
		row.elite_kills = arena.state.statistics.elite_kills
		row.chapter = arena.state.encounter.get("chapter",{})
		row.skills = arena.state.skills
		row.evolved = arena.state.evolved
		rows.append(row)
		print("C_JOURNEY ",JSON.stringify(row))
		if not arena.state.victory:
			failed = true
			arena.free()
			break
		assert(profile.finish_run(true,arena.stats()).status == "OK")
		arena.free()
	var file := FileAccess.open("res://production/playtest-evidence/package-d-2026-09-15/qa/journey-alternate.json" if "--alternate-build" in OS.get_cmdline_user_args() else "res://production/playtest-evidence/package-d-2026-09-15/qa/journey.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"catalog_hash":c.content_hash,"missions":rows,"completed":profile.data.completed,"scope":"real new-profile sequential eight missions, bot not human"},"\t"))
	file.close()
	failed = failed or profile.data.completed != 8
	storage.free()
	DirAccess.remove_absolute(stem+"a")
	DirAccess.remove_absolute(stem+"b")
	print("PACKAGE_C_JOURNEY_", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
