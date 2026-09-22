extends SceneTree
## Promoted from the independent chapter-two review regression probe.
const Arena=preload("res://src/campaign/campaign_arena.gd")
const Thermal=preload("res://src/campaign/campaign_chapter_two.gd")
func _initialize(): _run.call_deferred()
func xp(a):
	var value=0.0
	for p in a.state.pickups:value+=p.xp
	return value
func _run():
	var c=load("res://src/campaign/campaign_catalog.gd").load_catalog()
	for index in [11,15]:
		var a=Arena.new();root.add_child(a)
		var l={"character_id":"S1-C01","completed":index,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""}
		assert(a.configure(c,c.missions[index],l,42))
		a.advance(1.0/60,Vector2.ZERO)
		var e=a.state.entities[0]
		e.hp=e.max_hp*0.2
		if index==11: Thermal.hunt_damage(a,e)
		else: Thermal.boss(a,e,a.player_world_position())
		var expected=16 if index==11 else 36
		assert(xp(a)==expected)
		var snap=a.snapshot()
		assert(Arena.validate_snapshot(c,a.mission,snap))
		var b=Arena.new();root.add_child(b)
		assert(b.configure(c,c.missions[index],l,42,JSON.parse_string(JSON.stringify(snap,"",true,true))))
		if index==11: Thermal.hunt_damage(b,b.state.entities[0])
		else: Thermal.boss(b,b.state.entities[0],b.player_world_position())
		assert(xp(b)==expected)
		a.free();b.free()
	print("CH2_PHASE_XP_CROSS_TWO_RESTORE_NO_REPEAT_PASS")
	quit()
