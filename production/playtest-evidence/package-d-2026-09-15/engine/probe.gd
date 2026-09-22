extends SceneTree
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Profile = preload("res://src/campaign/campaign_profile.gd")
const Storage = preload("res://src/persistence/save_system.gd")
const Combat = preload("res://src/campaign/campaign_combat.gd")
var c: Dictionary
func _initialize():
	_run.call_deferred()
func make(index: int):
	var a = Arena.new()
	root.add_child(a)
	assert(a.configure(c,c.missions[index],{"character_id":"S1-C01","completed":index,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""},42))
	return a
func _run():
	c = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var stem := OS.get_temp_dir()+"/independent_d_engine_%d" % Time.get_ticks_usec()
	print("ISOLATED_STORAGE ",stem)
	var storage = Storage.new()
	assert(storage.initialize(stem+"a",stem+"b") == 0)
	var p = Profile.new()
	assert(p.initialize(c,storage))
	# Synthetic profile progression is solely a fault-fixture setup, not a journey claim.
	for i in 3:
		assert(p.begin_run(i).status == "OK")
		assert(p.finish_run(true,{}).status == "OK")
	assert(p.begin_run(3).status == "OK")
	var run: Dictionary = p.data.current_run
	var a = Arena.new()
	root.add_child(a)
	assert(a.configure(c,c.missions[3],run.loadout,str(run.seed).to_int()))
	assert(p.save_run(a.snapshot()))
	for i in 2:
		a.set_pos(a.state.player,Vector2(a.mission.clues[i][0],a.mission.clues[i][1]))
		a.advance(1.0/60,Vector2.ZERO)
		if a.state.event_id != "": a.choose_event(false)
	# Exercise documented exhausted capacity branch using frozen inert entities.
	while a.state.entities.size() < int(a.tuning.enemy_cap):
		var e: Dictionary = a.spawn_enemy("",Vector2(900,500),"target")
		e.hp = 100000
		e.max_hp = 100000
	a.set_pos(a.state.player,Vector2(a.mission.clues[2][0],a.mission.clues[2][1]))
	for i in 60:
		a.advance(1.0/60,Vector2.ZERO)
	print("FAULT error=",a.state.encounter.chapter.error," retry=",a.state.encounter.chapter.retry," arena_valid=",Arena.validate_snapshot(c,a.mission,a.snapshot()))
	print("FAULT_SAVE accepted=",p.save_run(a.snapshot())," profile_error=",p.error)
	storage.free()
	storage = Storage.new()
	assert(storage.initialize(stem+"a",stem+"b") == 0)
	p = Profile.new()
	print("FAULT_RELOAD profile=",p.initialize(c,storage))
	var b = Arena.new()
	root.add_child(b)
	run = p.data.current_run
	print("FAULT_RESTORE arena=",b.configure(c,c.missions[3],run.loadout,str(run.seed).to_int(),run.snapshot)," durable_error=",run.snapshot.state.encounter.chapter.error)
	a.free()
	b.free()
	storage.free()
	for index in [0,2,7]:
		a = make(index)
		a.state.player.hp = 1
		Combat.zone(a,a.player_world_position(),40,1000,0.2,"#ff0000","blast",true,0)
		a.advance(1.0/60,Vector2.ZERO)
		print("DEATH mission=",index+1," finished=",a.state.finished," elapsed=",a.state.elapsed," objective_elapsed=",a.state.objective.elapsed," valid=",Arena.validate_snapshot(c,a.mission,a.snapshot()))
		a.free()
	# Fresh boss replay with one independent roundtrip every tick.
	a = make(7)
	var invalid := []
	for i in 350:
		if not a.state.offered.is_empty(): a.choose_upgrade(a.state.offered[0])
		if a.state.event_id != "": a.choose_event(false)
		a.advance(1.0/60,Vector2.UP)
		if not Arena.validate_snapshot(c,a.mission,a.snapshot()): invalid.append(a.state.tick)
		if a.state.finished: break
	print("BOSS_NATURAL invalid_ticks=",invalid," last_tick=",a.state.tick)
	a.free()
	quit()
