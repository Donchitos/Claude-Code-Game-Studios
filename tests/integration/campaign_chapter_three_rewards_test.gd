extends SceneTree
## Threshold-crossing hunt/boss rewards survive restore without re-issue (ADR-0011).
const Arena=preload("res://src/campaign/campaign_arena.gd")
const Tide=preload("res://src/campaign/campaign_chapter_three.gd")
func _initialize(): _run.call_deferred()
func xp(a):
	var value=0.0
	for p in a.state.pickups:value+=p.xp
	return value
func _run():
	var c=load("res://src/campaign/campaign_catalog.gd").load_catalog()
	for index in [17,23]:
		var a=Arena.new();root.add_child(a)
		var l={"character_id":"S1-C01","completed":index,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""}
		assert(a.configure(c,c.missions[index],l,42))
		a.advance(1.0/60,Vector2.ZERO)
		var e=a.state.entities[0]
		var before=float(e.hp)
		e.hp=e.max_hp*0.2
		if index==17: Tide.hunt_damage(a,e,before)
		else: Tide.boss(a,e,a.player_world_position())
		var expected=16 if index==17 else 36
		assert(xp(a)==expected)
		if index==17:
			# The phase break interrupts the dive timer; non-crossing hits leave it alone.
			assert(float(e.timer)==float(e.cooldown))
			e.timer=0.05
			Tide.hunt_damage(a,e,e.hp)
			assert(float(e.timer)==0.05)
		var snap=a.snapshot()
		assert(Arena.validate_snapshot(c,a.mission,snap))
		var b=Arena.new();root.add_child(b)
		assert(b.configure(c,c.missions[index],l,42,JSON.parse_string(JSON.stringify(snap,"",true,true))))
		var restored=b.state.entities[0]
		if index==17:
			# A post-restore hit from the restored health crosses no threshold again.
			restored.hp=restored.max_hp*0.1
			Tide.hunt_damage(b,restored,restored.max_hp*0.2)
		else: Tide.boss(b,restored,b.player_world_position())
		assert(xp(b)==expected)
		a.free();b.free()
	print("CH3_THRESHOLD_XP_RESTORE_NO_REPEAT_PASS")
	quit()
