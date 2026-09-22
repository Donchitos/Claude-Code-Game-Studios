extends SceneTree
const Arena = preload("res://src/campaign/campaign_arena.gd")
func _initialize():
	_run.call_deferred()
func step(a):
	if not a.state.offered.is_empty(): a.choose_upgrade(a.state.offered[0])
	if a.state.event_id != "": a.choose_event(false)
	a.advance(1.0/60,Vector2.UP)
func _run():
	var c: Dictionary = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var l := {"character_id":"S1-C01","completed":7,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""}
	for phase in 3:
		var a = Arena.new()
		root.add_child(a)
		assert(a.configure(c,c.missions[7],l,42))
		# Phase-only fixture: HP is explicitly injected; not gameplay evidence.
		a.state.entities[0].hp = a.state.entities[0].max_hp * [1.0,0.6,0.3][phase]
		while a.state.encounter.chapter.landings.is_empty(): step(a)
		var s: Dictionary = JSON.parse_string(JSON.stringify(a.snapshot(),"",true,true))
		var b = Arena.new()
		root.add_child(b)
		assert(b.configure(c,c.missions[7],l,42,s))
		var equal := true
		for i in 200:
			step(a)
			step(b)
			if JSON.stringify(a.snapshot(),"",true,true) != JSON.stringify(b.snapshot(),"",true,true): equal = false
		print("BOSS_PENDING phase=",phase+1," saved_tick=",s.state.tick," pending=",s.state.encounter.chapter.landings.size()," next200_equal=",equal," advanced_ticks=",a.state.tick-s.state.tick)
		a.free()
		b.free()
	quit()
