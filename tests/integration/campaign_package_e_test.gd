extends SceneTree
## Boundary fixtures, not player-experience or natural evolution evidence.
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Encounter = preload("res://src/campaign/campaign_encounter.gd")
const Codec = preload("res://src/campaign/campaign_arena_codec.gd")
var c: Dictionary
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void:
	_run.call_deferred()
func make(index: int = 0):
	var a = Arena.new()
	root.add_child(a)
	assert(a.configure(c,c.missions[index],{"character_id":"S1-C01","completed":index,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""},42))
	return a
func _run() -> void:
	c = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var a = make()
	check(a.xp_required() == 6,"chapter one first level costs six")
	a.state.player.xp = 100
	a.advance(1.0/60,Vector2.ZERO)
	check(a.state.player.level == 2 and a.state.player.xp == 94,"one debit only")
	check(a.choose_upgrade(a.state.offered[0]),"choose legal candidate")
	check(a.state.offered.is_empty() and a.queued_upgrades() == 5,"queue remains as unspent XP")
	var start_tick: int = a.state.tick
	var snap: Dictionary = a.snapshot()
	check(Arena.validate_snapshot(c,a.mission,snap),"cooldown snapshot valid")
	var b = make()
	check(b.configure(c,b.mission,snap.loadout,42,JSON.parse_string(JSON.stringify(snap,"",true,true))),"JSON exact cooldown restore")
	for i in 179:
		a.advance(1.0/60,Vector2.ZERO)
		b.advance(1.0/60,Vector2.ZERO)
	check(a.state.offered.is_empty() and a.state.tick == start_tick+179,"no popup before 180 active ticks")
	a.advance(1.0/60,Vector2.ZERO)
	b.advance(1.0/60,Vector2.ZERO)
	check(not a.state.offered.is_empty() and a.state.player.level == 3,"popup at 180 ticks")
	check(a.snapshot() == b.snapshot(),"restored simulation/RNG match at popup")
	var frozen: Dictionary = a.snapshot()
	a.advance(0.25,Vector2.RIGHT)
	check(a.snapshot() == frozen,"modal time does not consume active ticks")
	for value in [-2, a.state.tick+1, 0.5, "bad"]:
		var bad: Dictionary = snap.duplicate(true)
		bad.state.encounter.last_upgrade_tick = value
		bad.numeric_bits = Codec.bits(bad.state)
		check(not Arena.validate_snapshot(c,a.mission,bad),"invalid cooldown rejected")
	a.free()
	b.free()
	a = make(3)
	a.state.player.xp = 16
	a.set_pos(a.state.player,Vector2(a.mission.clues[0][0],a.mission.clues[0][1]))
	a.advance(1.0/60,Vector2.ZERO)
	check(a.choose_upgrade(a.state.offered[0]),"clue with queued upgrade accepted")
	check(a.state.event_id == "" and a.state.offered.is_empty(),"event waits through queued-upgrade interval")
	check(Arena.validate_snapshot(c,a.mission,a.snapshot()),"waiting clue/cooldown snapshot valid")
	b = make(3)
	snap = JSON.parse_string(JSON.stringify(a.snapshot(),"",true,true))
	check(b.configure(c,b.mission,snap.loadout,42,snap),"waiting clue restores")
	for i in 180:
		a.advance(1.0/60,Vector2.ZERO)
		b.advance(1.0/60,Vector2.ZERO)
	check(not a.state.offered.is_empty() and a.state.event_id == "","queued upgrade still precedes event")
	check(a.snapshot() == b.snapshot(),"waiting clue continues deterministically")
	check(a.choose_upgrade(a.state.offered[0]),"last queued upgrade resolves")
	check(a.state.event_id != "" and a.queued_upgrades() == 0,"event opens after queue drains")
	check(Arena.validate_snapshot(c,a.mission,a.snapshot()),"event checkpoint valid after queue")
	a.free()
	b.free()
	a = make()
	a.state.player.xp = 100
	a.state.player.hp = 0
	a.advance(1.0/60,Vector2.ZERO)
	check(a.state.finished and a.state.offered.is_empty() and a.state.player.level == 1,"terminal precedes XP queue")
	a.free()
	a = make(16)
	check(a.xp_required() == 6,"chapter three local calibration applies six-plus-four")
	a.free()
	a = make(24)
	check(a.xp_required() == 6 and a.xp_required(2) == 10 and a.mission.upgrade_interval_ticks == 180,"ADR-0012 extends six-plus-four with three-second upgrade spacing")
	a.free()
	# Every accepted point must exclude the maximum view plus enemy visual extent.
	a = make()
	var accepted := 0
	for p in [Vector2.ZERO,Vector2(-720,0),Vector2(930,610),Vector2(-930,-610)]:
		a.set_pos(a.state.player,p)
		for sector in 4:
			for attempt in 40:
				var q: Vector2 = Encounter.spawn_point(a,sector)
				if not q.is_finite(): continue
				accepted += 1
				var offset: Vector2 = (q-p).abs()
				check(offset.x > 640+80 or offset.y > 360+80,"spawn outside maximum view with margin")
	check(accepted > 100,"spawn policy still admits candidates")
	check(a.spawn_enemy("S1-N01",Vector2(INF,INF)).is_empty(),"invalid candidate never allocates")
	a.free()
	print("PACKAGE_E checks=",checks," failures=",failures," accepted=",accepted)
	quit(1 if failures else 0)
