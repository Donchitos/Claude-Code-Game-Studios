extends SceneTree
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Codec = preload("res://src/campaign/campaign_arena_codec.gd")
var c: Dictionary
const Encounter = preload("res://src/campaign/campaign_encounter.gd")
var checks := 0
func _initialize():
	_run.call_deferred()
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		push_error(label)
		quit(1)
		assert(ok,label)
func make(index: int):
	var a = Arena.new()
	root.add_child(a)
	check(a.configure(c,c.missions[index],{"character_id":"S1-C01","completed":index,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""},42),"configure")
	return a
func step(a):
	if not a.state.offered.is_empty(): a.choose_upgrade(a.state.offered[0])
	if a.state.event_id != "": a.choose_event(false)
	a.advance(1.0/60,Vector2.ZERO)
func _run():
	c = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var a = make(3)
	check(a.state.entities.is_empty(),"hunt initially absent")
	for i in 3:
		a.set_pos(a.state.player,Vector2(a.mission.clues[i][0],a.mission.clues[i][1]))
		step(a)
		check(a.state.encounter.chapter.clues == i+1,"ordered clue")
		if i == 0:
			check(a.state.event_id != "","first clue event")
			var frozen = a.snapshot()
			a.advance(1.0/60,Vector2.RIGHT)
			check(a.snapshot() == frozen,"event freezes")
			check(a.choose_event(false),"resolve once")
			check(not a.choose_event(false),"no double event")
	check(a.state.encounter.chapter.hunt_spawned,"hunt spawned")
	check(a.state.entities.any(func(e): return e.target_id == a.mission.target_ids[0] and e.id == "S1-E01"),"designated identity")
	check(Arena.validate_snapshot(c,a.mission,a.snapshot()),"hunt valid")
	var bad = a.snapshot()
	bad.state.encounter.chapter.clues = 0
	bad.numeric_bits = Codec.bits(bad.state)
	check(not Arena.validate_snapshot(c,a.mission,bad),"hunt semantic forgery")
	for e in a.state.entities:
		if e.target_id == a.mission.target_ids[0]: a.damage_enemy(e,100000)
	step(a)
	check(a.state.victory and a.state.target_deaths.has(a.mission.target_ids[0]),"hunt real death completes")
	check(Arena.validate_snapshot(c,a.mission,a.snapshot()),"dead hunt snapshot valid")
	var terminal = Arena.new()
	root.add_child(terminal)
	check(terminal.configure(c,a.mission,a.loadout,42,a.snapshot()) and terminal.state.victory,"dead hunt restores without resurrection")
	terminal.free()
	a.free()
	for index in [4,5,6,7]:
		a = make(index)
		for i in 180: step(a)
		check(Arena.validate_snapshot(c,a.mission,a.snapshot()),"C snapshot")
		var b = Arena.new()
		root.add_child(b)
		check(b.configure(c,a.mission,a.loadout,42,a.snapshot()),"C restore")
		for i in 200:
			step(a)
			step(b)
		check(JSON.stringify(a.snapshot(),"",true,true)==JSON.stringify(b.snapshot(),"",true,true),"C 200 tick continuation")
		a.free()
		b.free()
	a = make(6)
	var first = a.state.entities[0]
	a.damage_enemy(first,100000)
	step(a)
	check(a.state.encounter.chapter.root_mask == 1,"anchor closes north root")
	check(not a.state.zones.any(func(z): return z.get("layout_root",-1)==0),"pending root cancelled")
	check(Arena.validate_snapshot(c,a.mission,a.snapshot()),"closed root snapshot")
	a.free()
	a = make(3)
	a.state.player.xp = a.xp_required()
	a.set_pos(a.state.player,Vector2(a.mission.clues[0][0],a.mission.clues[0][1]))
	a.advance(1.0/60,Vector2.ZERO)
	check(not a.state.offered.is_empty() and a.state.event_id == "","upgrade precedes clue event")
	check(Arena.validate_snapshot(c,a.mission,a.snapshot()),"queued clue event can resume")
	a.choose_upgrade(a.state.offered[0])
	check(a.state.event_id != "","event offered after upgrade")
	var base = a.spawn_enemy("S1-N01",Vector2(800,500))
	a.choose_event(true)
	var risk = a.spawn_enemy("S1-N01",Vector2(800,500))
	check(risk.max_hp > base.max_hp and risk.damage > base.damage,"risk pressure affects later enemies")
	check(Arena.validate_snapshot(c,a.mission,a.snapshot()),"resolved risk can resume")
	a.free()
	# Saturation fixture: ordinary enemies cannot consume the hunt reservation.
	a = make(3)
	for i in 179: check(not a.spawn_enemy("S1-N01",Vector2(-800,500)).is_empty(),"fill ordinary capacity")
	check(a.spawn_enemy("S1-N01",Vector2(-800,500)).is_empty(),"reserved hunt slot")
	a.state.encounter.chapter.clues = 3
	a.Chapter.advance(a)
	check(a.state.encounter.chapter.hunt_spawned and a.state.entities.size()==180,"reserved target installed")
	a.free()
	a = make(3)
	for i in 180: a.spawn_enemy("S1-E01",Vector2(-800,500),"elite")
	a.state.encounter.chapter.clues = 3
	for i in 59: a.Chapter.advance(a)
	check(a.state.encounter.chapter.error == "" and not a.state.encounter.chapter.hunt_spawned,"capacity remains pending")
	a.Chapter.advance(a)
	check(a.state.encounter.chapter.error != "" and not a.state.victory,"bounded capacity fails safely")
	check(not Arena.validate_snapshot(c,a.mission,a.snapshot()),"error state cannot overwrite valid save")
	a.free()
	# Halfway remains reached after later progress; never reset the spawn index.
	a = make(4)
	var stage: Dictionary = a.mission.encounter_stages[1].duplicate(true)
	stage.value = 1 # Explicit half-threshold predicate fixture; G schedules both groups at start.
	a.state.objective.hold = a.mission.hold_seconds*0.5-0.01
	check(not Encounter.reached(stage,a.state,a.mission),"half threshold not early")
	a.state.objective.hold += 0.01
	check(Encounter.reached(stage,a.state,a.mission),"half threshold exact")
	a.state.objective.waypoint = 1
	a.state.objective.hold = 0
	check(Encounter.reached(stage,a.state,a.mission),"half threshold remains consumed")
	a.free()
	for mode in ["clue_radius","event_pool","charge_clock","boss_clock","unknown_trigger"]:
		var m: Dictionary = c.missions[7 if mode=="boss_clock" else 3].duplicate(true)
		match mode:
			"clue_radius": m.clue_radius = -1
			"event_pool": m.event_ids[2] = "S1-RISK04"
			"charge_clock": m.hunt_charge.warning_ticks = 0
			"boss_clock": m.boss_chapter.cooldown_ticks = 1
			"unknown_trigger": m.encounter_stages[0].trigger = "FAKE"
		check(not Encounter.valid_definition(c,m),"invalid C definition " + mode)
	print("PACKAGE_C_PASS checks=",checks)
	quit()
