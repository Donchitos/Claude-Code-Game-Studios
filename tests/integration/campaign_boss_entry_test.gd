extends SceneTree
## Boundary fixtures for entry warnings, pending attacks and snapshot replay.
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Chapter = preload("res://src/campaign/campaign_chapter_one.gd")
const Bot = preload("res://tests/fixtures/campaign_c_bot.gd")
var c: Dictionary
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func make():
	var a := Arena.new()
	root.add_child(a)
	assert(a.configure(c,c.missions[7],{"character_id":"S1-C01","completed":7,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""},42))
	return a
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	c = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var a = make()
	a.advance(1.0/60,Vector2.ZERO)
	for id in a.state.skills: a.state.cooldowns[id] = 10.0
	var e: Dictionary = a.state.entities[0]
	e.timer = 2.5
	a.damage_enemy(e,e.max_hp*0.4)
	Chapter.boss(a,e,a.player_world_position())
	check(a.state.encounter.chapter.attacks[1] == 1,"phase entry publishes a full warning without old cooldown")
	check(a.state.encounter.chapter.landings.size() == 2,"phase one keeps two full delayed landings")
	var pending: Array = a.state.encounter.chapter.landings.duplicate(true)
	check(pending.size() == 2 and pending[0].tick == 55 and pending[1].tick == 85,"both pending landings retain full 54/84 tick warnings")
	a.damage_enemy(e,e.max_hp*0.3)
	Chapter.boss(a,e,a.player_world_position())
	check(a.state.encounter.chapter.landings == pending,"new phase preserves pending old attacks")
	check(a.state.encounter.chapter.attacks[2] == 0,"new warning waits until prior landings drain")
	var snap: Dictionary = JSON.parse_string(JSON.stringify(a.snapshot(),"",true,true))
	var b = make()
	check(b.configure(c,b.mission,snap.loadout,42,snap),"phase entry with pending landings restores")
	for tick in 100:
		for branch in [a,b]:
			if not branch.state.offered.is_empty(): assert(branch.choose_upgrade(Bot.choice(branch,c)))
			branch.advance(1.0/60,Vector2.LEFT)
		check(JSON.stringify(a.snapshot(),"",true,true) == JSON.stringify(b.snapshot(),"",true,true),"pending phase replay tick "+str(tick))
	check(a.state.encounter.chapter.attacks[2] == 1,"new phase warning released once after drain")
	check(a.state.encounter.chapter.first_warning[2] == 85,"new warning starts after last 54+30 old landing")
	check(Arena.validate_snapshot(c,a.mission,a.snapshot()),"post warning snapshot remains valid")
	a.free()
	b.free()
	a = make()
	e = a.state.entities[0]
	a.damage_enemy(e,e.max_hp*0.8)
	# Saturate the existing zone bank through its production entry point.
	for i in 128: a.Combat.zone(a,Vector2(800,500),10,0,1,"#ff0000","blast",true,1)
	Chapter.boss(a,e,a.player_world_position())
	check(a.state.encounter.chapter.attacks[2] == 0 and a.state.encounter.chapter.landings.is_empty(),"capacity full does not publish an invisible attack")
	a.state.zones.clear() # Fault fixture release, not natural-play evidence.
	Chapter.boss(a,e,a.player_world_position())
	check(a.state.encounter.chapter.attacks[2] == 1 and a.state.encounter.chapter.landings.size() == 1,"entry retries after capacity returns")
	a.damage_enemy(e,100000)
	a.advance(1.0/60,Vector2.ZERO)
	check(a.state.finished and a.state.victory and a.state.encounter.chapter.landings.is_empty(),"lethal hit ends immediately with no waiting for attacks")
	a.free()
	_capacity_boundaries()
	print("BOSS_ENTRY checks=",checks," failures=",failures)
	quit(failures)

## Preserve admission, disabled-mode and the exact four-zone capacity edge.
func _capacity_boundaries() -> void:
	for bad in [1,"true",null]:
		var m: Dictionary = c.missions[7].duplicate(true)
		m.boss_phase_entry_warning = bad
		check(not Arena.Encounter.valid_definition(c,m),"reject invalid entry flag")
	var wrong: Dictionary = c.missions[0].duplicate(true)
	wrong.boss_phase_entry_warning = true
	check(not Arena.Encounter.valid_definition(c,wrong),"reject flag on non-Boss")
	for enabled in [false,true]:
		var m: Dictionary = c.missions[7].duplicate(true)
		m.boss_phase_entry_warning = enabled
		var a = make()
		check(a.configure(c,m,a.loadout,42),"explicit optional mode configures")
		a.advance(1.0/60,Vector2.ZERO)
		var e: Dictionary = a.state.entities[0]
		e.timer = 2.5
		a.damage_enemy(e,e.max_hp*0.8)
		while a.state.zones.size() < 125: a.Combat.zone(a,Vector2(800,500),10,0,1,"#ff0000","blast",true,1)
		Chapter.boss(a,e,a.player_world_position())
		check(a.state.encounter.chapter.attacks[2] == 0 and a.state.encounter.chapter.landings.is_empty(),"125 zones cannot fit four new warnings")
		check(e.timer == (0 if enabled else 2.5),"disabled mode retains original cooldown")
		a.state.zones.pop_back() # Release one slot in this bounded capacity fixture.
		Chapter.boss(a,e,a.player_world_position())
		check(a.state.encounter.chapter.attacks[2] == (1 if enabled else 0),"124 slots admit enabled attack only")
		check(a.state.zones.size() == (128 if enabled else 124),"exact capacity has all four visible zones")
		var xp := 0.0
		for item in a.state.pickups: xp += float(item.xp)
		check(xp == 36,"capacity retry cannot repeat phase XP")
		check(Arena.validate_snapshot(c,m,a.snapshot()),"capacity boundary snapshot remains valid")
		a.free()
