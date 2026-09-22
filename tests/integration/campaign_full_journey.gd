extends SceneTree
## Sixty-four real missions, legal fresh progression, disk resume at stage/choice boundaries.
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Bot = preload("res://tests/fixtures/campaign_c_bot.gd")
const Profile = preload("res://src/campaign/campaign_profile.gd")
const Storage = preload("res://src/persistence/save_system.gd")
var evidence: String = preload("res://tests/fixtures/campaign_evidence.gd").create("journey-full-campaign")
var failed := false
var rows: Array = []
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var c: Dictionary = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var stem := OS.get_temp_dir()+"/full_campaign_journey_%d" % Time.get_ticks_usec()
	var storage := Storage.new()
	assert(storage.initialize(stem+"a",stem+"b") == 0)
	var profile := Profile.new()
	assert(profile.initialize(c,storage))
	seed(977 if "--alternate-build" in OS.get_cmdline_user_args() else 711)
	for index in 64:
		for branch in 3:
			if profile.data.pages >= 4 and profile.data.branches[branch] < (1 if index < 8 else 2 if index < 24 else 3 if index < 40 else 4 if index < 56 else 5): assert(profile.purchase_branch(branch))
		if index < 56: assert(not profile.purchase_branch(0))
		if index >= 16 and "--alternate-build" in OS.get_cmdline_user_args(): assert(profile.select_character("S1-C03"))
		if "--regional-build" in OS.get_cmdline_user_args():
			assert(profile.select_character("S1-C%02d" % (index/8+1)))
		var pill := ""
		if "--prepared-route" in OS.get_cmdline_user_args() and index>=56 and c.missions[index].kind in ["CLEANSE","BREAK","SURVIVE"]:
			pill="S1-PREP08"
			assert(profile.cultivate(pill)) # Uses only herbs actually earned by this new profile.
		assert(profile.begin_run(index,pill).status == "OK")
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
		var choice_seconds: Array = []
		var compared_ticks := 0
		for tick in 30000:
			if arena.state.finished: break
			if not arena.state.offered.is_empty():
				assert(arena.choose_upgrade(Bot.choice(arena,c)))
				choices += 1
				choice_seconds.append(arena.state.elapsed)
			if arena.state.event_id != "": assert(arena.choose_event("--risk-route" in OS.get_cmdline_user_args()))
			arena.advance(1.0/60,Bot.direction(arena,c.missions[index],tick))
			var tide := false
			if index == 20: tide = int(arena.state.tick) % 450 >= 90
			elif index == 23:
				# The boss can die and leave the entity list empty (or shifted) on this
				# very tick; only its live aim matters, so scan instead of indexing [0].
				for entity in arena.state.entities:
					if entity.family == "boss":
						tide = float(entity.aim) < 0.0
						break
			var phases: Array = []
			for entity in arena.state.entities:
				if entity.family == "boss": phases.append(entity.phase)
			var stages := JSON.stringify([arena.state.encounter.stage_ticks,arena.state.event_id,arena.state.event_done,arena.state.encounter.last_upgrade_tick,arena.state.objective.completed_ids,tide,phases])
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
				if not next.configure(c,c.missions[index],run.loadout,str(run.seed).to_int(),run.snapshot):
					FileAccess.open("/tmp/full-failed-restore.json",FileAccess.WRITE).store_string(JSON.stringify({"run":run,"original":snap},"\t",true,true))
					print("RESTORE_FAILED index=",index," tick=",snap.state.tick," seed=",run.seed)
					quit(1)
					return
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
				if not next.configure(c,c.missions[index],run.loadout,str(run.seed).to_int(),run.snapshot):
					FileAccess.open("/tmp/full-failed-restore.json",FileAccess.WRITE).store_string(JSON.stringify({"run":run,"original":snap},"\t",true,true))
					print("RESTORE_FAILED index=",index," tick=",snap.state.tick," seed=",run.seed)
					quit(1)
					return
				arena.free()
				arena = next
				restores += 1
		var row := {"mission":c.missions[index].id,"victory":arena.state.victory,"elapsed":arena.state.elapsed,"choices":choices,"restores":restores,"stages":arena.state.encounter.stage_ticks,"skipped":arena.state.encounter.skipped,"level":arena.state.player.level,"hp":arena.state.player.hp,"escort_hp":arena.state.objective.escort_hp}
		row["run_seed"] = str(run.seed)
		row["pill_id"] = run.loadout.pill_id
		row["herbs_remaining"] = profile.data.herbs
		row.choice_seconds = choice_seconds
		row.kills = arena.state.player.kills
		row.uncollected_xp = arena.state.pickups.reduce(func(total,item): return total+float(item.xp),0.0)
		row.collected_xp = float(arena.state.player.xp)
		for level in range(1,int(arena.state.player.level)): row.collected_xp += arena.xp_required(level)
		row.compared_ticks = compared_ticks
		row.elite_kills = arena.state.statistics.elite_kills
		row.branches = run.loadout.branches
		row.character = run.loadout.character_id
		row.event_done = arena.state.event_done
		row.skills = arena.state.skills
		row.evolved = arena.state.evolved
		rows.append(row)
		print("FULL_JOURNEY ",JSON.stringify(row))
		if not arena.state.victory:
			failed = true
			arena.free()
			break
		assert(profile.finish_run(true,arena.stats()).status == "OK")
		arena.free()
	if profile.data.completed == 64:
		assert(profile.data.ending_seen)
		storage.free()
		storage = Storage.new()
		assert(storage.initialize(stem+"a",stem+"b") == 0)
		profile = Profile.new()
		assert(profile.initialize(c,storage))
		assert(profile.data.completed == 64 and profile.data.ending_seen and profile.data.current_run == null)
		print("ENDING_DISK_RELOAD_PASS")
	var filename := "journey-regional.json" if "--regional-build" in OS.get_cmdline_user_args() else "journey-alternate.json" if "--alternate-build" in OS.get_cmdline_user_args() else "journey.json"
	var file := FileAccess.open(evidence+filename,FileAccess.WRITE)
	file.store_string(JSON.stringify({"catalog_hash":c.content_hash,"missions":rows,"completed":profile.data.completed,"branches":profile.data.branches,"scope":"real new-profile sequential sixty-four missions, bot not human"},"\t"))
	file.close()
	failed = failed or profile.data.completed != 64
	storage.free()
	DirAccess.remove_absolute(stem+"a")
	DirAccess.remove_absolute(stem+"b")
	print("FULL_CAMPAIGN_JOURNEY_", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
