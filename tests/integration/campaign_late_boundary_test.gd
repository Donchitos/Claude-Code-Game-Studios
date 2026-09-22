extends SceneTree
## ADR-0012: targeted fixtures, not playtest evidence.
const Arena=preload("res://src/campaign/campaign_arena.gd")
const Late=preload("res://src/campaign/campaign_late_chapters.gd")
var c: Dictionary
var failures:=0
var checks:=0
func check(ok: bool):
	checks+=1
	if not ok: failures+=1; push_error("CHECK_FAILED %d" % checks)
func make(index:int):
	var a=Arena.new();root.add_child(a)
	check(a.configure(c,c.missions[index],{"character_id":"S1-C01","completed":index,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""},711))
	return a
func xp(a):
	var total=0.0
	for p in a.state.pickups:total+=p.xp
	return total
func restore(a):
	var b=Arena.new();root.add_child(b)
	check(b.configure(c,a.mission,a.loadout,711,JSON.parse_string(JSON.stringify(a.snapshot(),"",true,true))))
	check(b.snapshot()==a.snapshot())
	return b
func _initialize():_run.call_deferred()
func _run():
	c=load("res://src/campaign/campaign_catalog.gd").load_catalog()
	for index in range(24,64):
		var a=make(index)
		if a.mission.kind=="ESCORT":
			a.advance(1.0/60,Vector2.ZERO)
			check(xp(a)==12)
			var b=restore(a)
			b.advance(1.0/60,Vector2.ZERO)
			var earned: float=xp(b)+b.state.player.xp
			for level in range(1,int(b.state.player.level)): earned+=b.xp_required(level)
			check(earned==12)
			b.free()
		if a.mission.kind=="BREAK":
			var bad=a.snapshot();bad.state.entities[0].ordinal=1;bad.numeric_bits=a.Codec.bits(bad.state)
			check(not Arena.validate_snapshot(c,a.mission,bad))
			var l=a.Encounter.layout(c,a.mission)
			a.emit_layout_root(l.roots[0],0)
			var z=a.state.zones[0].duplicate(true)
			a.damage_enemy(a.state.entities[0],100000)
			a.advance(1.0/60,Vector2.ZERO)
			check(Late.field_closed(a.mission,a.state,0))
			check(a.state.zones.any(func(item):return item.get("late_field",-1)==0))
			var b=restore(a);b.free()
			# Closed identity survives expiry, while other fields keep cycling.
			for t in 700:
				if not a.state.offered.is_empty():a.choose_upgrade(a.state.offered[0])
				a.advance(1.0/60,Vector2.ZERO)
			check(not a.state.zones.any(func(item):return item.get("late_field",-1)==0))
		if a.mission.kind in ["BREAK","HUNT","BOSS"]:
			var bad=a.snapshot();bad.state.target_deaths=[a.state.entities[0].target_id];bad.numeric_bits=a.Codec.bits(bad.state)
			check(not Arena.validate_snapshot(c,a.mission,bad))
		if a.mission.kind in ["HUNT","BOSS"]:
			var e=a.state.entities[0]
			var before=float(e.hp);e.hp=e.max_hp*.2
			Late.damage(a,e,before)
			var expected=36 if e.family=="boss" else 20
			check(xp(a)==expected)
			var b=restore(a)
			Late.damage(b,b.state.entities[0],b.state.entities[0].hp)
			check(xp(b)==expected)
			b.free()
		a.free()
	for count in [382,383,400]:
		var a=make(63);var e=a.state.entities[0]
		e.hp=e.max_hp*.2;Late.damage(a,e,e.max_hp)
		for i in count:a.Combat.projectile(a,Vector2.ZERO,Vector2.RIGHT,1,4,5,"#ffffff","straight",1,0,true)
		Late.boss(a,e,Vector2.ZERO)
		check(a.state.projectiles.size()==400 if count==382 else a.state.projectiles.size()==count)
		check(a.state.zones.size()==1 if count==382 else a.state.zones.is_empty())
		check(e.timer>0 if count==382 else e.timer==0)
		a.free()
	var a=make(63);var e=a.state.entities[0]
	e.timer=0.0
	Late.boss(a,e,Vector2.ZERO)
	var b=restore(a)
	# Deterministic warning expiration and moving projectiles, without other AI.
	for tick in 100:
		for branch in [a,b]:branch.Combat.advance_projectiles(branch,1.0/60)
		check(a.snapshot()==b.snapshot())
	check(not a.state.projectiles[0].has("delay"))
	var p=a.state.projectiles[0]
	a.set_pos(a.state.player,a.pos(p))
	a.Combat.zone(a,a.player_world_position(),100,1,1,"#ffffff","shield",false,0)
	a.Combat.advance_zones(a,1.0/60)
	check(not p.hostile)
	check(Arena.validate_snapshot(c,a.mission,a.snapshot()))
	var reflected=restore(a);reflected.free()
	a.free();b.free()
	print("LATE_BOUNDARY_RESULT checks=",checks," failures=",failures)
	quit(1 if failures else 0)
