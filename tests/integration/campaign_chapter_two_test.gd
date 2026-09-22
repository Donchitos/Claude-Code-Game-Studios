extends SceneTree
## ADR-0010 targeted mechanics and negative admission cases (fixtures, not playtests).
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Thermal = preload("res://src/campaign/campaign_chapter_two.gd")
const Bot = preload("res://tests/fixtures/campaign_c_bot.gd")
var c: Dictionary
var checks := 0
func check(ok: bool) -> void:
	checks += 1
	assert(ok)
func make(index: int, ranks: Array = [0,0,0]):
	var a := Arena.new()
	root.add_child(a)
	check(a.configure(c,c.missions[index],{"character_id":"S1-C01","completed":64 if ranks[0]==5 else index,"branches":ranks,"difficulty":0,"pill_id":"","challenge_id":""},711))
	return a
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	c = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	check(not c.is_empty())
	for index in range(8,16):
		var a = make(index)
		check(a.snapshot().schema == Thermal.FORMAT)
		check(Arena.validate_snapshot(c,a.mission,a.snapshot()))
		a.free()
	var hunt = make(11)
	check(hunt.state.entities[0].id == "S1-E02")
	var bad: Dictionary = hunt.snapshot()
	bad.state.entities[0].id = "S1-E01"
	# Remove numeric receipts only via snapshot() below, so corruption reaches semantics.
	check(not Arena.validate_snapshot(c,hunt.mission,bad))
	bad = hunt.snapshot()
	bad.state.entities.clear()
	bad.numeric_bits = hunt.Codec.bits(bad.state)
	check(not Arena.validate_snapshot(c,hunt.mission,bad))
	hunt.free()
	for order in [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]]:
		var a = make(14)
		for index in order:
			var layout: Dictionary = a.Encounter.layout(c,a.mission)
			a.emit_layout_root(layout.roots[index],index)
			check(a.state.zones.any(func(z):return z.get("thermal_vent",-1)==index))
			var corrupt: Dictionary = a.snapshot()
			corrupt.state.zones[-1].thermal_vent = (index+1)%3
			corrupt.numeric_bits = a.Codec.bits(corrupt.state)
			check(not Arena.validate_snapshot(c,a.mission,corrupt))
			for entity in a.state.entities:
				if entity.family == "target" and int(entity.ordinal)==index: a.damage_enemy(entity,100000)
			a.advance(1.0/60,Vector2.ZERO)
			check(Thermal.vent_closed(a.mission,a.state,index))
			check(not a.state.zones.any(func(z):return z.get("thermal_vent",-1)==index))
			check(Arena.validate_snapshot(c,a.mission,a.snapshot()))
		check(a.state.victory)
		a.free()
	var boss = make(15)
	var corrupt_boss: Dictionary = boss.snapshot()
	corrupt_boss.state.entities[0].family = "enemy"
	corrupt_boss.numeric_bits = boss.Codec.bits(corrupt_boss.state)
	check(not Arena.validate_snapshot(c,boss.mission,corrupt_boss))
	var e: Dictionary = boss.state.entities[0]
	var hp: float = e.hp
	boss.damage_enemy(e,100)
	check(is_equal_approx(hp-e.hp,35))
	check(not Thermal.door_open(boss.mission,179) and Thermal.door_open(boss.mission,180))
	check(Thermal.door_open(boss.mission,329) and not Thermal.door_open(boss.mission,330))
	boss.state.tick=180
	hp=e.hp
	boss.damage_enemy(e,100)
	check(is_equal_approx(hp-e.hp,100))
	boss.state.zones.clear()
	e.hp=e.max_hp*0.2
	for i in 127: boss.Combat.zone(boss,Vector2.ZERO,20,1,1,"#ffffff","blast",true,1)
	Thermal.boss(boss,e,Vector2.ZERO)
	check(boss.state.zones.size()==127)
	boss.state.zones.clear()
	Thermal.boss(boss,e,Vector2.ZERO)
	check(boss.state.zones.size()==3)
	for z in boss.state.zones: check(is_equal_approx(z.delay,1.3))
	boss.state.zones.clear()
	e.hp=0
	e.timer=0
	Thermal.boss(boss,e,Vector2.ZERO)
	check(boss.state.zones.is_empty())
	boss.free()
	for ranks in [[0,0,0],[5,5,5]]:
		for index in range(8,16):
			var a = make(index,ranks)
			var event_count := 0
			for tick in 30000:
				if a.state.finished: break
				if not a.state.offered.is_empty(): check(a.choose_upgrade(Bot.choice(a,c)))
				if a.state.event_id != "":
					if index==13: check(a.state.objective.waypoint>=3)
					event_count+=1
					check(a.choose_event(false))
				a.advance(1.0/60,Bot.direction(a,a.mission,tick))
			print("CH2_FIXTURE ",index," ranks=",ranks," win=",a.state.victory," seconds=",a.state.elapsed)
			check(a.state.victory)
			check(Arena.validate_snapshot(c,a.mission,a.snapshot()))
			if index==13: check(event_count==1)
			a.free()
	print("CHAPTER_TWO_CHECKS ",checks," PASS")
	quit()
