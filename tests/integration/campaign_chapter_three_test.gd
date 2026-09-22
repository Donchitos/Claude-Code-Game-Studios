extends SceneTree
## ADR-0011 targeted mechanics and negative admission cases (fixtures, not playtests).
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Tide = preload("res://src/campaign/campaign_chapter_three.gd")
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
	for index in range(16,24):
		var a = make(index)
		check(a.snapshot().schema == Tide.FORMAT)
		check(Arena.validate_snapshot(c,a.mission,a.snapshot()))
		a.free()
	var hunt = make(17)
	check(hunt.state.entities[0].id == "S1-E03")
	var bad: Dictionary = hunt.snapshot()
	bad.state.entities[0].id = "S1-E01"
	check(not Arena.validate_snapshot(c,hunt.mission,bad))
	bad = hunt.snapshot()
	bad.state.entities.clear()
	bad.numeric_bits = hunt.Codec.bits(bad.state)
	check(not Arena.validate_snapshot(c,hunt.mission,bad))
	hunt.free()
	# Fixed sluice order: out-of-order seals take no damage, and each completed
	# seal floods exactly its own flat while the others keep their rest phase.
	var sluice = make(20)
	for entity in sluice.state.entities:
		if entity.family == "target" and int(entity.ordinal)==1:
			var gate: float = entity.hp
			sluice.damage_enemy(entity,100000)
			check(entity.hp == gate)
	var broken := {}
	for index in 3:
		var layout: Dictionary = sluice.Encounter.layout(c,sluice.mission)
		sluice.emit_layout_root(layout.roots[index],index)
		check(sluice.state.zones.any(func(z):return z.get("tide_flat",-1)==index))
		var duplicated: Dictionary = sluice.snapshot()
		duplicated.state.zones.append(duplicated.state.zones[-1].duplicate(true))
		duplicated.numeric_bits = sluice.Codec.bits(duplicated.state)
		check(not Arena.validate_snapshot(c,sluice.mission,duplicated))
		var corrupt: Dictionary = sluice.snapshot()
		corrupt.state.zones[-1].tide_flat = (index+1)%3
		corrupt.numeric_bits = sluice.Codec.bits(corrupt.state)
		check(not Arena.validate_snapshot(c,sluice.mission,corrupt))
		for entity in sluice.state.entities:
			if entity.family == "target" and int(entity.ordinal)==index: sluice.damage_enemy(entity,100000)
		sluice.advance(1.0/60,Vector2.ZERO)
		broken[index] = true
		for other in 3: check(Tide.flat_flooded(sluice.mission,sluice.state,other) == broken.has(other))
		check(Arena.validate_snapshot(c,sluice.mission,sluice.snapshot()))
	check(sluice.state.victory)
	sluice.free()
	# A broken seal floods its flat permanently: the surge must re-arm the moment the
	# previous zone dies — never stacking a second live zone on the same flat (double
	# drain), and never falling dark for a rest period it no longer has.
	var flood = make(20)
	for entity in flood.state.entities:
		if entity.family == "target" and int(entity.ordinal)==0: flood.damage_enemy(entity,100000)
	flood.advance(1.0/60,Vector2.ZERO)
	check(Tide.flat_flooded(flood.mission,flood.state,0))
	var live_ticks := {0:0,1:0,2:0}
	for tick in 500:
		if flood.state.finished: break
		if not flood.state.offered.is_empty(): check(flood.choose_upgrade(Bot.choice(flood,c)))
		var live := {}
		for z in flood.state.zones:
			if z.has("tide_flat"):
				var flat := int(z.tide_flat)
				live[flat] = live.get(flat,0)+1
		for flat in 3: check(live.get(flat,0) <= 1)
		live_ticks[0] += 1 if live.get(0,0) > 0 else 0
		flood.advance(1.0/60,Bot.direction(flood,flood.mission,tick))
	# Back-to-back re-arm: a 240-tick zone life with no rest stays lit for the whole
	# window (at most one boundary tick dark), which itself proves at least two re-arms.
	check(live_ticks[0] >= 499)
	check(Arena.validate_snapshot(c,flood.mission,flood.snapshot()))
	flood.free()
	var boss = make(23)
	var corrupt_boss: Dictionary = boss.snapshot()
	corrupt_boss.state.entities[0].family = "enemy"
	corrupt_boss.numeric_bits = boss.Codec.bits(corrupt_boss.state)
	check(not Arena.validate_snapshot(c,boss.mission,corrupt_boss))
	var e: Dictionary = boss.state.entities[0]
	boss.state.zones.clear()
	e.hp = e.max_hp*0.2
	Tide.boss(boss,e,Vector2.ZERO)
	check(boss.state.zones.size()==16)
	var east := 0
	var west := 0
	for z in boss.state.zones:
		if z.has("tide_flat"): continue
		if z.kind == "line":
			check(is_equal_approx(z.delay,1.3) and is_equal_approx(z.angle,PI/2.0) and is_equal_approx(z.length,1250.0))
			# The wall must be anchored mid-arena so the segment spans the full field
			# height; a midline anchor covers only one half (regression guard).
			check(is_equal_approx(z.y,-625.0))
			east += 1 if z.x > 0.0 else 0
			west += 1 if z.x < 0.0 else 0
	check(east==4 and west==4)
	check(not boss.state.projectiles.is_empty())
	boss.state.zones.clear()
	e.timer = 0.0
	Tide.boss(boss,e,Vector2.ZERO)
	check(boss.state.zones.size()==16)
	east = 0
	west = 0
	for z in boss.state.zones:
		if z.kind == "line":
			east += 1 if z.x > 0.0 else 0
			west += 1 if z.x < 0.0 else 0
	check(east==4 and west==4)
	boss.state.zones.clear()
	e.hp = e.max_hp
	e.phase = 0
	e.timer = 0.0
	Tide.boss(boss,e,Vector2.ZERO)
	check(boss.state.zones.size()==2)
	for z in boss.state.zones: check(z.x > 0.0)
	boss.state.zones.clear()
	e.timer = 0.0
	Tide.boss(boss,e,Vector2.ZERO)
	check(boss.state.zones.size()==2)
	for z in boss.state.zones: check(z.x < 0.0)
	boss.state.zones.clear()
	e.hp = e.max_hp*0.5
	e.phase = 0
	e.timer = 0.0
	Tide.boss(boss,e,Vector2.ZERO)
	check(boss.state.zones.size()==3)
	# A lowered phase must not re-issue already-granted phase rewards.
	var relapse: Dictionary = boss.snapshot()
	check(Arena.validate_snapshot(c,boss.mission,relapse))
	relapse.state.entities[0].phase = 0.0
	relapse.numeric_bits = boss.Codec.bits(relapse.state)
	check(not Arena.validate_snapshot(c,boss.mission,relapse))
	boss.state.zones.clear()
	# Clear the timer so a full board is refused by the capacity pre-check
	# itself, not by the cooldown early-return.
	e.timer = 0.0
	for i in 127: boss.Combat.zone(boss,Vector2.ZERO,20,1,1,"#ffffff","blast",true,1)
	Tide.boss(boss,e,Vector2.ZERO)
	check(boss.state.zones.size()==127)
	boss.state.zones.clear()
	e.timer = 0.0
	e.hp = e.max_hp*0.2
	for i in 112: boss.Combat.zone(boss,Vector2.ZERO,20,1,1,"#ffffff","blast",true,1)
	Tide.boss(boss,e,Vector2.ZERO)
	check(boss.state.zones.size()==128)
	boss.state.zones.clear()
	e.hp = 0
	e.timer = 0
	Tide.boss(boss,e,Vector2.ZERO)
	check(boss.state.zones.is_empty())
	boss.free()
	for ranks in [[0,0,0],[5,5,5]]:
		for index in range(16,24):
			var a = make(index,ranks)
			var event_count := 0
			for tick in 30000:
				if a.state.finished: break
				if not a.state.offered.is_empty(): check(a.choose_upgrade(Bot.choice(a,c)))
				if a.state.event_id != "":
					if index==18: check(a.state.objective.waypoint>=2)
					event_count+=1
					check(a.choose_event(false))
				a.advance(1.0/60,Bot.direction(a,a.mission,tick))
			print("CH3_FIXTURE ",index," ranks=",ranks," win=",a.state.victory," seconds=",a.state.elapsed)
			check(a.state.victory)
			check(Arena.validate_snapshot(c,a.mission,a.snapshot()))
			if index==18: check(event_count==1)
			a.free()
	print("CHAPTER_THREE_CHECKS ",checks," PASS")
	quit()
