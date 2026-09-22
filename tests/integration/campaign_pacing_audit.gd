extends SceneTree
## Read-only telemetry from ordinary eight-mission play; no simulation edits.
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Bot = preload("res://tests/fixtures/campaign_c_bot.gd")
const Profile = preload("res://src/campaign/campaign_profile.gd")
const Storage = preload("res://src/persistence/save_system.gd")
var evidence: String = preload("res://tests/fixtures/campaign_evidence.gd").create("pacing-audit")
func _initialize() -> void:
	_run.call_deferred()
func objective_key(a) -> Array:
	var chapter: Dictionary = a.state.encounter.get("chapter",{})
	return [a.state.objective.progress,a.state.objective.waypoint,chapter.get("clues",0),chapter.get("boss_phase",0)]
func _run() -> void:
	var c: Dictionary = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var s := Storage.new()
	assert(s.initialize(evidence+"a.save",evidence+"b.save") == 0)
	var p := Profile.new()
	assert(p.initialize(c,s))
	var alternate := "--alternate-build" in OS.get_cmdline_user_args()
	seed(977 if alternate else 711)
	var rows := []
	for index in 8:
		for branch in 3:
			if p.data.pages >= 4 and p.data.branches[branch] == 0: assert(p.purchase_branch(branch))
		assert(p.begin_run(index).status == "OK")
		var run: Dictionary = p.data.current_run
		var a := Arena.new()
		root.add_child(a)
		assert(a.configure(c,c.missions[index],run.loadout,str(run.seed).to_int()))
		var changes: Array = [{"seconds":0,"objective":objective_key(a)}]
		var choices: Array = []
		var nearby_ticks := 0
		var hostile_zone_ticks := 0
		var max_enemies := 0
		var last_key := objective_key(a)
		for tick in 30000:
			if a.state.finished: break
			if not a.state.offered.is_empty():
				assert(a.choose_upgrade(Bot.choice(a,c)))
				choices.append(a.state.elapsed)
			if a.state.event_id != "": assert(a.choose_event("--risk-route" in OS.get_cmdline_user_args()))
			a.advance(1.0/60,Bot.direction(a,c.missions[index],tick))
			var near := false
			var live := 0
			for e in a.state.entities:
				if e.family != "target" and e.hp > 0:
					live += 1
					near = near or a.pos(e).distance_to(a.player_world_position()) < 320
			max_enemies = maxi(max_enemies,live)
			if near: nearby_ticks += 1
			if a.state.zones.any(func(z): return bool(z.hostile)): hostile_zone_ticks += 1
			var key := objective_key(a)
			if key != last_key:
				changes.append({"seconds":a.state.elapsed,"objective":key})
				last_key = key
		var stages := []
		var planned := 0
		var attempted := 0
		for i in a.mission.encounter_stages.size():
			var stage: Dictionary = a.mission.encounter_stages[i]
			var counts: Array = a.state.encounter.counts[i]
			var total := 0
			var done := 0
			for j in stage.rows.size():
				total += int(stage.rows[j].count)
				done += int(counts[j])
			planned += total
			attempted += done
			stages.append({"id":stage.id,"trigger_seconds":float(a.state.encounter.stage_ticks[i])/60 if a.state.encounter.stage_ticks[i]>=0 else -1,"planned":total,"attempted":done})
		assert(a.state.victory)
		rows.append({"mission":a.mission.id,"kind":a.mission.kind,"elapsed":a.state.elapsed,"choices":choices,"objective_changes":changes,"planned":planned,"attempted":attempted,"skipped":a.state.encounter.skipped,"stages":stages,"nearby_enemy_seconds":float(nearby_ticks)/60,"hostile_zone_seconds":float(hostile_zone_ticks)/60,"max_live_non_target":max_enemies,"kills":a.state.player.kills,"damage_taken":a.state.statistics.damage_taken,"chapter":a.state.encounter.get("chapter",{}),"evolved":a.state.evolved})
		assert(p.finish_run(true,a.stats()).status == "OK")
		a.free()
	assert(p.data.completed == 8)
	var file := FileAccess.open(evidence+"pacing-audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"catalog_hash":c.content_hash,"alternate":alternate,"rows":rows,"scope":"natural bot telemetry; nearby means live non-target within 320 world units; hostile zones may be remote or warning; neither is human engagement"},"\t"))
	file.close()
	s.free()
	assert(DirAccess.remove_absolute(evidence+"a.save") == OK)
	assert(DirAccess.remove_absolute(evidence+"b.save") == OK)
	print("PACING_AUDIT_PASS ",JSON.stringify(rows))
	quit()
