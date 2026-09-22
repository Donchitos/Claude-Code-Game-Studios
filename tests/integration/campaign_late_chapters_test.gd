extends SceneTree
## ADR-0012 fixtures: complete definitions, target identity, recovery and atomic attacks.
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Late = preload("res://src/campaign/campaign_late_chapters.gd")
var failures := 0
var checks := 0
func check(value: bool) -> void:
	checks += 1
	if not value: failures+=1; push_error("CHECK_FAILED %d" % checks)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var c: Dictionary = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	check(not c.is_empty())
	for index in range(24,64):
		var a := Arena.new()
		root.add_child(a)
		var l := {"character_id":"S1-C01","completed":index,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""}
		check(a.configure(c,c.missions[index],l,711))
		check(a.snapshot().schema == Late.FORMAT)
		check(Arena.validate_snapshot(c,a.mission,a.snapshot()))
		if a.mission.kind in ["HUNT","BOSS","BREAK"]:
			var bad := a.snapshot()
			bad.state.entities.clear()
			bad.numeric_bits = a.Codec.bits(bad.state)
			check(not Arena.validate_snapshot(c,a.mission,bad))
		if a.mission.kind == "HUNT": check(a.state.entities[0].id == "S1-E%02d" % a.mission.chapter)
		if a.mission.kind == "BOSS":
			var e: Dictionary = a.state.entities[0]
			a.damage_enemy(e,e.max_hp*0.4)
			check(e.phase == 1)
			check(Arena.validate_snapshot(c,a.mission,a.snapshot()))
			var b := Arena.new()
			root.add_child(b)
			check(b.configure(c,a.mission,l,711,JSON.parse_string(JSON.stringify(a.snapshot(),"",true,true))))
			check(b.snapshot() == a.snapshot())
			b.free()
			while a.state.zones.size()<128: a.Combat.zone(a,Vector2.ZERO,10,1,1,"#ffffff","blast",true,1)
			var aim: float = e.aim
			Late.boss(a,e,Vector2.ZERO)
			check(e.timer == 0 and e.aim == aim and a.state.zones.size()==128)
		a.free()
	print("LATE_CHAPTERS_RESULT checks=",checks," failures=",failures)
	quit(1 if failures else 0)
