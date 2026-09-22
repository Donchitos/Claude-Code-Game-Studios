extends SceneTree
## Regression: post-AI damage must leave a resumable exact phase; attacks commit atomically.
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Bot = preload("res://tests/fixtures/campaign_c_bot.gd")
const Tide = preload("res://src/campaign/campaign_chapter_three.gd")
func _initialize(): _run.call_deferred()
func _run():
	var c: Dictionary = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var l := {"character_id":"S1-C01","completed":23,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""}
	var a := Arena.new()
	root.add_child(a)
	assert(a.configure(c,c.missions[23],l,711))
	var transitions := 0
	var last_phase := 0
	for tick in 15000:
		if a.state.finished: break
		if not a.state.offered.is_empty(): assert(a.choose_upgrade(Bot.choice(a,c)))
		if a.state.event_id!="": assert(a.choose_event(false))
		a.advance(1.0/60,Bot.direction(a,a.mission,tick))
		for e in a.state.entities:
			if e.family!="boss": continue
			assert(e.phase==mini(2,int((1.0-maxf(0,e.hp)/e.max_hp)*3.0)))
			if int(e.phase)>last_phase:
				transitions+=int(e.phase)-last_phase
				last_phase=int(e.phase)
				var snap := a.snapshot()
				assert(Arena.validate_snapshot(c,a.mission,snap))
				var restored := Arena.new()
				root.add_child(restored)
				assert(restored.configure(c,a.mission,l,711,JSON.parse_string(JSON.stringify(snap,"",true,true))))
				assert(restored.snapshot()==snap)
				restored.free()
	assert(a.state.victory and transitions==2)
	a.free()
	for count in [388,389,400]:
		a=Arena.new()
		root.add_child(a)
		assert(a.configure(c,c.missions[23],l,711))
		var e: Dictionary=a.state.entities[0]
		e.hp=e.max_hp*0.2
		Tide.boss_damage(a,e)
		for i in count: a.Combat.projectile(a,Vector2.ZERO,Vector2.RIGHT,1,4,1,"#ffffff","straight",1,0,true)
		var aim: float=e.aim
		Tide.boss(a,e,Vector2.ZERO)
		if count==388:
			assert(a.state.zones.size()==16 and a.state.projectiles.size()==400 and e.aim!=aim and e.timer>0)
		else:
			assert(a.state.zones.is_empty() and a.state.projectiles.size()==count and e.aim==aim and e.timer==0)
		a.free()
	print("CH3_BOUNDARY_PASS natural_phase_transitions=2 capacity=388/389/400")
	quit()
