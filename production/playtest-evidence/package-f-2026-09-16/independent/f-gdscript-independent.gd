extends SceneTree
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Chapter = preload("res://src/campaign/campaign_chapter_one.gd")
func _initialize():
	_run.call_deferred()
func _run():
	var c = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var a = Arena.new()
	root.add_child(a)
	assert(a.configure(c,c.missions[7],{"character_id":"S1-C01","completed":7,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""},42))
	a.tuning.pickup_cap = 1
	a.drop_xp(Vector2.ZERO,3)
	a.state.pickups[0].ttl=0.001
	var boss=a.state.entities[0]
	boss.hp=boss.max_hp*0.2
	Chapter.boss(a,boss,a.player_world_position())
	assert(a.state.pickups.size()==1 and a.state.pickups[0].xp==39 and a.state.pickups[0].ttl==120)
	boss.hp=boss.max_hp*0.9
	Chapter.boss(a,boss,a.player_world_position())
	assert(a.state.encounter.chapter.boss_phase==2 and a.state.pickups[0].xp==39)
	a.drop_xp(Vector2(INF,0),12)
	a.drop_xp(Vector2.ZERO,NAN)
	a.drop_xp(Vector2.ZERO,-1)
	assert(a.state.pickups[0].xp==39)
	var elite=a.spawn_enemy(c.elites[0].id,Vector2.ZERO,"elite")
	assert(not elite.is_empty())
	elite.hp=0
	a._reap()
	assert(a.state.pickups.size()==1 and a.state.pickups[0].xp==39+float(c.tuning.elite_enemy_xp))
	a.free()
	print("INDEPENDENT_F_PROBE_PASS full-bank cross-phase/ttl/monotonic/nonfinite/elite-reap")
	quit()
