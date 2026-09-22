extends SceneTree
const Root = preload("res://src/campaign/campaign_game_root.gd")
const Profile = preload("res://src/campaign/campaign_profile.gd")
const Storage = preload("res://src/persistence/save_system.gd")
const Combat = preload("res://src/campaign/campaign_combat.gd")
class FailSettlement extends Storage:
	var fail_settlement := false
	func commit_domain_after_images(images: Dictionary) -> int:
		if fail_settlement and images.get("campaign_game",{}).get("current_run") == null:
			return Status.IO_ERROR
		return super.commit_domain_after_images(images)
func _initialize():
	_run.call_deferred()
func _run():
	if DisplayServer.get_name() != "headless":
		quit(2)
		return
	for kind in ["player", "escort"]:
		var stem = OS.get_temp_dir()+"/campaign_d_death_" + kind + str(Time.get_ticks_usec())
		var g = Root.new()
		root.add_child(g)
		g.set_physics_process(false)
		g.storage.free()
		var fs = FailSettlement.new()
		g.add_child(fs)
		assert(fs.initialize(stem+"a",stem+"b") == 0)
		g.storage = fs
		g.profile = Profile.new()
		assert(g.profile.initialize(g.catalog, fs))
		var index = 0 if kind == "player" else 2
		for i in index:
			assert(g.profile.begin_run(i).status == "OK")
			assert(g.profile.finish_run(true,{}).status == "OK")
		var before_runs = g.profile.data.stats.runs
		assert(g.start_mission(index))
		var a = g.arena
		if kind == "player":
			a.state.player.hp = 1
			Combat.zone(a,a.player_world_position(),40,1000,0.2,"#ff0000","blast",true,0)
		else:
			a.state.objective.escort_hp = 1
			a.set_pos(a.state.player, Vector2(700,700))
			Combat.zone(a,a.pos(a.state.objective),40,1000,0.2,"#ff0000","blast",true,0)
		fs.fail_settlement = true
		g.autosave_clock = float(g.catalog.tuning.save_interval)
		g._physics_process(1.0/60)
		print("FATAL ",kind," reason=",a.state.reason," clock=",a.state.elapsed,"/",a.state.objective.elapsed," blocked=",g.persistence_blocked," snapshot_finished=",g.profile.data.current_run.snapshot.state.finished)
		assert(a.state.reason == ("player_dead" if kind == "player" else "escort_destroyed"))
		assert(g.persistence_blocked and g.profile.data.current_run.snapshot.state.finished)
		g.free()
		var restored = Storage.new()
		assert(restored.initialize(stem+"a",stem+"b") == 0)
		g = Root.new()
		root.add_child(g)
		g.set_physics_process(false)
		g.storage.free()
		g.storage = restored
		g.add_child(restored)
		g.profile = Profile.new()
		assert(g.profile.initialize(g.catalog,restored))
		assert(g.continue_run())
		assert(g.arena == null and g.page == "result")
		assert(g.profile.data.stats.runs == before_runs + 1)
		assert(not g.continue_run())
		assert(g.profile.finish_run(false,{}).status == "ERROR")
		print("ROOT_DISK_DEATH_PASS ",kind," runs=",g.profile.data.stats.runs," page=",g.page)
		g.free()
		DirAccess.remove_absolute(stem+"a")
		DirAccess.remove_absolute(stem+"b")
	quit()
