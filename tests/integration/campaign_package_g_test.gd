extends SceneTree
## G scheduling and retained high-progression fixtures, not new-player evidence.
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Bot = preload("res://tests/fixtures/campaign_c_bot.gd")
var c: Dictionary
var checks := 0
func check(ok: bool) -> void:
	checks += 1
	assert(ok)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	c = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	for index in [1,6]:
		var m: Dictionary = c.missions[index]
		check(m.encounter_stages.map(func(s): return int(s.value)) == [0,0,1])
		var boundary := Arena.new()
		root.add_child(boundary)
		var base_loadout := {"character_id":"S1-C01","completed":index,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""}
		check(boundary.configure(c,m,base_loadout,711))
		for tick in 89: boundary.advance(1.0/60,Vector2.ZERO)
		check(boundary.state.tick == 89 and boundary.state.encounter.counts[1][0] == 0)
		var restored := Arena.new()
		root.add_child(restored)
		check(restored.configure(c,m,base_loadout,711,JSON.parse_string(JSON.stringify(boundary.snapshot(),"",true,true))))
		for branch in [boundary,restored]: branch.advance(1.0/60,Vector2.ZERO)
		check(boundary.state.encounter.counts[1][0] == 1 and boundary.snapshot() == restored.snapshot())
		boundary.free()
		restored.free()
		for high in [false,true]:
			var a := Arena.new()
			root.add_child(a)
			var loadout := {"character_id":"S1-C01","completed":64 if high else index,"branches":[5,5,5] if high else [0,0,0],"difficulty":0,"pill_id":"","challenge_id":""}
			check(a.configure(c,m,loadout,711))
			check(a.state.encounter.stage_ticks == [0,0,-1])
			var hp: float = a.state.entities[1].hp
			a.damage_enemy(a.state.entities[1],100000)
			check(a.state.entities[1].hp == hp)
			for tick in 30000:
				if a.state.finished: break
				if not a.state.offered.is_empty(): check(a.choose_upgrade(Bot.choice(a,c)))
				if a.state.event_id != "": check(a.choose_event(false))
				a.advance(1.0/60,Bot.direction(a,m,tick))
			check(a.state.victory)
			check(Arena.validate_snapshot(c,m,a.snapshot()))
			if index == 6: check(a.state.encounter.chapter.root_mask == 7)
			a.free()
	check(c.missions[2].encounter_stages.map(func(s): return int(s.value)) == [0,2,3])
	check(c.missions[4].encounter_stages.map(func(s): return int(s.value)) == [0,0,2,2])
	for index in [2,4]:
		var a := Arena.new()
		root.add_child(a)
		check(a.configure(c,c.missions[index],{"character_id":"S1-C01","completed":index,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""},711))
		a.advance(1.0/60,Vector2.ZERO)
		if index == 2: check(a.state.encounter.stage_ticks == [0,-1,-1])
		for tick in 30000:
			if a.state.finished: break
			if not a.state.offered.is_empty(): check(a.choose_upgrade(Bot.choice(a,c)))
			if a.state.event_id != "": check(a.choose_event(false))
			a.advance(1.0/60,Bot.direction(a,a.mission,tick))
		check(a.state.victory and Arena.validate_snapshot(c,a.mission,a.snapshot()))
		var stages: Array = a.state.encounter.stage_ticks
		if index == 2:
			check(stages[0] == 0 and stages[1] > 1 and stages[2] > stages[1])
		else:
			check(stages[0] == stages[1] and stages[2] == stages[3] and stages[2] > stages[0])
		a.free()
	print("PACKAGE_G_CHECKS ",checks," PASS")
	quit()
