extends SceneTree
const Root = preload("res://src/campaign/campaign_game_root.gd")
func _initialize():
	_run.call_deferred()
func _run():
	var g = Root.new()
	root.add_child(g)
	g.set_physics_process(false)
	assert(g.profile_ready)
	for i in 3:
		assert(g.profile.begin_run(i).status == "OK")
		assert(g.profile.finish_run(true,{}).status == "OK")
	assert(g.start_mission(3))
	var a = g.arena
	for i in 2:
		a.set_pos(a.state.player,Vector2(a.mission.clues[i][0],a.mission.clues[i][1]))
		a.advance(1.0/60,Vector2.ZERO)
		if a.state.event_id != "": a.choose_event(false)
	assert(g.profile.save_run(a.snapshot()))
	while a.state.entities.size() < int(a.tuning.enemy_cap):
		var e: Dictionary = a.spawn_enemy("",Vector2(900,500),"target")
		e.hp = 100000
		e.max_hp = 100000
	a.set_pos(a.state.player,Vector2(a.mission.clues[2][0],a.mission.clues[2][1]))
	for i in 60: a.advance(1.0/60,Vector2.ZERO)
	g.fail(a.state.encounter.chapter.error)
	print("ROOT_FAULT modal=",g.modal," paused=",g.paused)
	g.dismiss_error()
	print("ROOT_HOME saved=",g.save_and_home()," page=",g.page," durable_error=",g.profile.data.current_run.snapshot.state.encounter.chapter.error)
	print("ROOT_CONTINUE result=",g.continue_run()," modal=",g.modal," error=",g.error)
	g.free()
	quit()
