extends SceneTree
## Reward ownership/capacity fixtures, not balance or human experience evidence.
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Chapter = preload("res://src/campaign/campaign_chapter_one.gd")
var c: Dictionary
var checks := 0
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func make(index: int):
	var a = Arena.new()
	root.add_child(a)
	assert(a.configure(c,c.missions[index],{"character_id":"S1-C01","completed":index,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""},42))
	# Entry warnings are actual attack receipts; create a legal first active tick
	# before applying the phase-damage fixture.
	if index == 7: a.advance(1.0/60,Vector2.ZERO)
	return a
func total_xp(a) -> float:
	var total: float = a.state.player.xp
	for level in range(1,int(a.state.player.level)): total += a.xp_required(level)
	for item in a.state.pickups: total += float(item.xp)
	return total
func _run() -> void:
	c = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var a = make(3)
	a.set_pos(a.state.player,Vector2(a.mission.clues[0][0],a.mission.clues[0][1]))
	a.advance(1.0/60,Vector2.ZERO)
	check(total_xp(a) == 8 and a.state.pickups.size() == 1,"first clue creates visible reward")
	var snap: Dictionary = JSON.parse_string(JSON.stringify(a.snapshot(),"",true,true))
	var b = make(3)
	check(b.configure(c,b.mission,snap.loadout,42,snap),"clue reward restores")
	for branch in [a,b]:
		assert(branch.choose_event(false))
		branch.advance(1.0/60,Vector2.ZERO)
	check(total_xp(a) == 8 and a.snapshot() == b.snapshot(),"no repeated clue reward after resume or touching same clue")
	a.free()
	b.free()
	a = make(7)
	var boss: Dictionary = a.state.entities[0]
	a.damage_enemy(boss,boss.max_hp*0.4)
	Chapter.boss(a,boss,a.player_world_position())
	check(a.state.encounter.chapter.boss_phase == 1 and total_xp(a) == 18,"phase break emits reward")
	snap = JSON.parse_string(JSON.stringify(a.snapshot(),"",true,true))
	b = make(7)
	check(b.configure(c,b.mission,snap.loadout,42,snap),"phase reward snapshot restores")
	Chapter.boss(b,b.state.entities[0],b.player_world_position())
	check(total_xp(b) == 18,"restored phase does not pay twice")
	a.damage_enemy(boss,boss.max_hp*0.3)
	Chapter.boss(a,boss,a.player_world_position())
	check(total_xp(a) == 36,"second break pays once")
	Chapter.boss(a,boss,a.player_world_position())
	check(total_xp(a) == 36,"repeated boss update pays nothing")
	a.free()
	b.free()
	a = make(7)
	a.damage_enemy(a.state.entities[0],a.state.entities[0].max_hp*0.8)
	Chapter.boss(a,a.state.entities[0],a.player_world_position())
	check(total_xp(a) == 36,"crossing two phases pays two finite rewards")
	a.free()
	a = make(0)
	a.tuning.pickup_cap = 1
	a.drop_xp(Vector2.ZERO,3)
	a.drop_xp(Vector2(200,0),18)
	check(a.state.pickups.size() == 1 and total_xp(a) == 21,"full pickup bank preserves full reward")
	a.state.pickups.clear()
	a.set_pos(a.state.player,Vector2.ZERO)
	a.drop_xp(Vector2(250,0),6)
	for i in 30: a._pickups(1.0/60)
	check(a.state.player.xp == 6 and a.state.pickups.is_empty(),"320 radius and 600 speed collect an approached mote")
	a.free()
	a = make(5)
	a.set_pos(a.state.player,Vector2.ZERO)
	a.drop_xp(Vector2(250,0),6)
	for i in 30: a._pickups(1.0/60)
	check(a.state.player.xp == 0,"06 attraction unchanged")
	a.free()
	a = make(16)
	check(a.mission.has("pickup_attract_radius") and not a.mission.has("clue_xp"),"chapter three carries the ch2-parity pickup tuning; clue XP stays chapter one")
	a.free()
	a = make(24)
	check(a.mission.pickup_attract_radius == 320 and a.mission.pickup_attract_speed == 600 and not a.mission.has("clue_xp"),"ADR-0012 late chapters attract pickups without granting chapter-one clue XP")
	a.free()
	for terminal in ["victory","timeout"]:
		a = make(0)
		a.state.player.xp = 100
		if terminal == "victory":
			a.state.elapsed = float(a.mission.target_seconds)
			a.state.objective.extraction_ready = true
			a.state.objective.extraction_was_inside = false
			a.set_pos(a.state.player,a.target_position(0))
		else:
			a.state.elapsed = float(a.mission.timeout_seconds)
		a.state.objective.elapsed = a.state.elapsed
		a.state.tick = roundi(a.state.elapsed*60)
		a.advance(1.0/60,Vector2.ZERO)
		check(a.state.finished and a.state.offered.is_empty() and a.state.player.level == 1,"same-tick "+terminal+" precedes upgrade")
		check(bool(a.state.victory) == (terminal == "victory"),"expected terminal result "+terminal)
		a.free()
	print("PACING_REWARDS checks=",checks," failures=",failures)
	quit(1 if failures else 0)
