extends SceneTree
## Natural F combat -> legal preterminal disk restore -> terminal -> one settlement.
## No changes to Arena state, catalog timing, HP, XP, or encounter counters.
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Bot = preload("res://tests/fixtures/campaign_c_bot.gd")
const Profile = preload("res://src/campaign/campaign_profile.gd")
const Storage = preload("res://src/persistence/save_system.gd")
const Root = preload("res://src/campaign/campaign_game_root.gd")
class RejectSettlement extends Storage:
	var reject := false
	func commit_domain_after_images(images: Dictionary) -> int:
		if reject and images.get("campaign_game",{}).get("current_run") == null:
			return Status.IO_ERROR
		return super.commit_domain_after_images(images)
var evidence: String = preload("res://tests/fixtures/campaign_evidence.gd").create("terminal-disk")
var rows: Array = []
func _initialize() -> void:
	_run.call_deferred()
func canonical(value: Dictionary) -> String:
	return JSON.stringify(value,"",true,true)
func make_storage(stem: String):
	var s := RejectSettlement.new()
	assert(s.initialize(stem+"a.save",stem+"b.save") == 0)
	return s
func slot_bytes(stem: String) -> Array:
	return [FileAccess.get_file_as_bytes(stem+"a.save"),FileAccess.get_file_as_bytes(stem+"b.save")]
func make_root(s):
	var g := Root.new()
	root.add_child(g)
	g.set_physics_process(false)
	g.storage.free()
	g.storage = s
	g.add_child(s)
	g.profile = Profile.new()
	assert(g.profile.initialize(g.catalog,s))
	return g
func _run() -> void:
	assert("--campaign-validation" in OS.get_cmdline_user_args())
	var c: Dictionary = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	for mode in ["victory","timeout"]:
		var stem: String = evidence+mode+"-"
		var s = make_storage(stem)
		var p := Profile.new()
		assert(p.initialize(c,s))
		seed(711)
		assert(p.begin_run(0).status == "OK")
		var run: Dictionary = p.data.current_run
		var a := Arena.new()
		root.add_child(a)
		assert(a.configure(c,c.missions[0],run.loadout,str(run.seed).to_int()))
		# This private bot navigation hint only changes inputs. The actual mission
		# remains byte-identical to the catalog, including its deadline and exit.
		var navigation: Dictionary = c.missions[0].duplicate(true)
		if mode == "timeout": navigation.target_seconds = navigation.timeout_seconds+10
		var before: Dictionary = {}
		var movement := Vector2.ZERO
		for tick in 30000:
			if not a.state.offered.is_empty(): assert(a.choose_upgrade(Bot.choice(a,c)))
			if a.state.event_id != "": assert(a.choose_event(false))
			before = a.snapshot()
			movement = Bot.direction(a,navigation,tick)
			a.advance(1.0/60,movement)
			if a.state.finished: break
		assert(a.mission == c.missions[0])
		assert(a.state.finished and a.state.reason == ("extracted" if mode == "victory" else "timeout"))
		assert(not before.state.finished and before.state.tick+1 == a.state.tick)
		var terminal := a.snapshot()
		var stats := a.stats()
		assert(Arena.validate_snapshot(c,c.missions[0],before))
		assert(p.save_run(before))
		s.free()
		s = make_storage(stem)
		p = Profile.new()
		assert(p.initialize(c,s))
		var b := Arena.new()
		root.add_child(b)
		run = p.data.current_run
		assert(b.configure(c,c.missions[0],run.loadout,str(run.seed).to_int(),run.snapshot))
		b.advance(1.0/60,movement)
		assert(canonical(b.snapshot()) == canonical(terminal))
		assert(Arena.validate_snapshot(c,c.missions[0],b.snapshot()))
		assert(p.save_run(b.snapshot()))
		var terminal_bytes := slot_bytes(stem)
		var run_id: int = int(p.data.current_run.run_id)
		var before_pages: int = int(p.data.pages)
		a.free()
		b.free()
		s.free()
		# Restore the real terminal checkpoint in Root. Fail the actual settlement
		# transaction, then rebuild a second Root to retry that same run once.
		s = make_storage(stem)
		s.reject = true
		var g = make_root(s)
		assert(g.continue_run())
		assert(g.persistence_blocked and g.profile.data.current_run.snapshot.state.finished)
		assert(slot_bytes(stem) == terminal_bytes)
		g.free()
		g = make_root(make_storage(stem))
		assert(g.continue_run())
		assert(g.arena == null and g.page == "result" and g.profile.data.current_run == null)
		assert(g.profile.data.last_resolved_run_id == run_id and g.profile.data.stats.runs == 1)
		assert(g.profile.data.completed == (1 if mode == "victory" else 0))
		assert(g.profile.data.stats.wins == (1 if mode == "victory" else 0))
		var resolved: Dictionary = g.profile.data
		var resolved_bytes := slot_bytes(stem)
		assert(not g.continue_run())
		assert(g.profile.finish_run(mode == "victory",stats).status == "ERROR")
		assert(g.profile.data == resolved and slot_bytes(stem) == resolved_bytes)
		g.free()
		g = make_root(make_storage(stem))
		assert(preload("res://src/campaign/campaign_arena_validation.gd").same_values(g.profile.data,JSON.parse_string(JSON.stringify(resolved,"",true,true))) and not g.continue_run())
		assert(slot_bytes(stem) == resolved_bytes)
		rows.append({"mode":mode,"tick":terminal.state.tick,"elapsed":terminal.state.elapsed,"hp":terminal.state.player.hp,"level":terminal.state.player.level,"reason":terminal.state.reason,"reward_pages":resolved.pages-before_pages,"runs":resolved.stats.runs,"run_id":run_id,"preterminal_replay_equal":true,"settlement_failure_zero_write":true,"duplicate_settlement_zero_write":true})
		g.free()
		assert(DirAccess.remove_absolute(stem+"a.save") == OK)
		assert(DirAccess.remove_absolute(stem+"b.save") == OK)
	var file := FileAccess.open(evidence+"terminal-disk.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"catalog_hash":c.content_hash,"rows":rows,"scope":"natural first mission victory and deliberate timeout, synchronous IO failure, no process kill"},"\t"))
	file.close()
	print("TERMINAL_DISK_PASS ",JSON.stringify(rows))
	quit()
