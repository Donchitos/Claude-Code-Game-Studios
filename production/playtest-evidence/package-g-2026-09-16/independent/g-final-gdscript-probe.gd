extends SceneTree
const Arena=preload("res://src/campaign/campaign_arena.gd")
const Chapter=preload("res://src/campaign/campaign_chapter_one.gd")
const Encounter=preload("res://src/campaign/campaign_encounter.gd")
func _initialize():
	_run.call_deferred()
func _run():
	var c=load("res://src/campaign/campaign_catalog.gd").load_catalog()
	for bad in [1,"true",null]:
		var m=c.missions[7].duplicate(true)
		m["boss_phase_entry_warning"]=bad
		assert(not Encounter.valid_definition(c,m))
	var wrong=c.missions[0].duplicate(true)
	wrong["boss_phase_entry_warning"]=true
	assert(not Encounter.valid_definition(c,wrong))
	for enabled in [false,true]:
		var m=c.missions[7].duplicate(true)
		m.boss_phase_entry_warning=enabled
		var a=Arena.new()
		root.add_child(a)
		assert(a.configure(c,m,{"character_id":"S1-C01","completed":7,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""},42))
		a.advance(1.0/60,Vector2.ZERO)
		var e=a.state.entities[0]
		e.timer=2.5
		a.damage_enemy(e,e.max_hp*0.8)
		while a.state.zones.size()<125: a.Combat.zone(a,Vector2(800,500),10,0,1,"#ff0000","blast",true,1)
		Chapter.boss(a,e,a.player_world_position())
		assert(a.state.encounter.chapter.attacks[2]==0 and a.state.encounter.chapter.landings.is_empty())
		assert((e.timer==0) if enabled else (e.timer==2.5))
		var total=0.0
		for item in a.state.pickups: total+=item.xp
		assert(total==36)
		a.state.zones.pop_back()
		Chapter.boss(a,e,a.player_world_position())
		assert(a.state.encounter.chapter.attacks[2]==(1 if enabled else 0))
		assert(a.state.zones.size()==(128 if enabled else 124))
		total=0.0
		for item in a.state.pickups: total+=item.xp
		assert(total==36)
		assert(Arena.validate_snapshot(c,m,a.snapshot()))
		a.free()
	print("G_FINAL_INDEPENDENT_PASS flag admission/false-mode/125-124 capacity/retry/no-repeat-XP/valid snapshots")
	quit()
