extends SceneTree
## Produce an explicitly labelled bot-completed chapter-one sample, without synthetic unlocks.
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Profile = preload("res://src/campaign/campaign_profile.gd")
const Storage = preload("res://src/persistence/save_system.gd")
const Bot = preload("res://tests/fixtures/campaign_c_bot.gd")
func _initialize(): _run.call_deferred()
func _run():
	var folder := OS.get_cmdline_user_args()[0]
	assert(not FileAccess.file_exists(folder+"/campaign_game_a.save") and not FileAccess.file_exists(folder+"/campaign_game_b.save"))
	DirAccess.make_dir_recursive_absolute(folder)
	var c: Dictionary = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var s := Storage.new()
	assert(s.initialize(folder+"/campaign_game_a.save",folder+"/campaign_game_b.save")==0)
	var p := Profile.new()
	assert(p.initialize(c,s))
	seed(711)
	for index in 8:
		for branch in 3:
			if p.data.pages>=4 and p.data.branches[branch]==0: assert(p.purchase_branch(branch))
		assert(p.begin_run(index).status=="OK")
		var run: Dictionary = p.data.current_run
		var a := Arena.new()
		root.add_child(a)
		assert(a.configure(c,c.missions[index],run.loadout,str(run.seed).to_int()))
		for tick in 30000:
			if a.state.finished: break
			if not a.state.offered.is_empty(): assert(a.choose_upgrade(Bot.choice(a,c)))
			if a.state.event_id!="": assert(a.choose_event(false))
			a.advance(1.0/60,Bot.direction(a,a.mission,tick))
		assert(a.state.victory)
		assert(p.finish_run(true,a.stats()).status=="OK")
		a.free()
	assert(p.data.completed==8 and p.data.current_run==null)
	print("CHAPTER_TWO_START_PROFILE_PASS completed=8 branches=",p.data.branches," pages=",p.data.pages)
	s.free()
	quit()
