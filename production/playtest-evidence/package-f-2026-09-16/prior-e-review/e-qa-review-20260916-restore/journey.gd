extends SceneTree
## Eight real missions, legal fresh progression, disk resume at stage/choice boundaries.
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
	var stem := "/tmp/e-qa-review-20260916-restore/journey_%d" % Time.get_ticks_usec()
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
		var compared_ticks := 0
		for tick in 30000:
			if arena.state.finished: break
			if not arena.state.offered.is_empty():
				assert(arena.choose_upgrade(Bot.choice(arena,c)))
				choices += 1
			if arena.state.event_id != "": assert(arena.choose_event("--risk-route" in OS.get_cmdline_user_args()))
			arena.advance(1.0/60,Bot.direction(arena,c.missions[index],tick))
			var stages := JSON.stringify([arena.state.encounter.stage_ticks,arena.state.encounter.get("chapter",{}).get("clues",0),arena.state.encounter.get("chapter",{}).get("root_mask",0),arena.state.encounter.get("chapter",{}).get("attacks",[]),arena.state.event_id,arena.state.event_done,arena.state.encounter.last_upgrade_tick])
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
				# Compare the uninterrupted live branch with the real disk restore.
				# Reset the restored branch to the saved point after this look-ahead probe.
				for future in 200:
					if arena.state.finished: break
					for branch in [arena,next]:
						if not branch.state.offered.is_empty(): assert(branch.choose_upgrade(Bot.choice(branch,c)))
						if branch.state.event_id != "": assert(branch.choose_event("--risk-route" in OS.get_cmdline_user_args()))
						branch.advance(1.0/60,Bot.direction(branch,c.missions[index],tick+future+1))
					assert(JSON.stringify(next.snapshot(),"",true,true) == JSON.stringify(arena.snapshot(),"",true,true))
					compared_ticks += 1
				assert(JSON.stringify(next.snapshot(),"",true,true) == JSON.stringify(arena.snapshot(),"",true,true))
				assert(Arena.validate_snapshot(c,c.missions[index],next.snapshot()))
				assert(next.configure(c,c.missions[index],run.loadout,str(run.seed).to_int(),run.snapshot))
				arena.free()
				arena = next
				restores += 1
		var row := {"mission":c.missions[index].id,"victory":arena.state.victory,"elapsed":arena.state.elapsed,"choices":choices,"restores":restores,"stages":arena.state.encounter.stage_ticks,"skipped":arena.state.encounter.skipped,"level":arena.state.player.level,"hp":arena.state.player.hp,"escort_hp":arena.state.objective.escort_hp}
		row.compared_ticks = compared_ticks
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
	var file := FileAccess.open("/tmp/e-qa-review-20260916-restore/journey-alternate.json" if "--alternate-build" in OS.get_cmdline_user_args() else "/tmp/e-qa-review-20260916-restore/journey.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"catalog_hash":c.content_hash,"missions":rows,"completed":profile.data.completed,"scope":"real new-profile sequential eight missions, bot not human"},"\t"))
	file.close()
	failed = failed or profile.data.completed != 8
	if "--qa-production-evolution" in OS.get_cmdline_user_args():
		failed = failed or not rows.any(func(row): return not row.evolved.is_empty())
	storage.free()
	DirAccess.remove_absolute(stem+"a")
	DirAccess.remove_absolute(stem+"b")
	print("PACKAGE_E_JOURNEY_", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
