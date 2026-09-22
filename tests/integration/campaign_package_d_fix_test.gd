extends SceneTree
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Profile = preload("res://src/campaign/campaign_profile.gd")
const Storage = preload("res://src/persistence/save_system.gd")
const Combat = preload("res://src/campaign/campaign_combat.gd")
var failures := 0
var checks := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
class FaultStorage extends Storage:
	var fail := false
	func commit_domain_after_images(images: Dictionary) -> int:
		return Status.IO_ERROR if fail else super.commit_domain_after_images(images)
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
		if not a.state.offered.is_empty(): assert(a.choose_upgrade(a.state.offered[0]))
		if a.state.event_id != "": assert(a.choose_event(false))
		a.advance(1.0/60,Vector2.ZERO)
	print("FAULT error=",a.state.encounter.chapter.error," retry=",a.state.encounter.chapter.retry," arena_valid=",Arena.validate_snapshot(c,a.mission,a.snapshot()))
	var before: Dictionary = p.data
	var bytes_a := FileAccess.get_file_as_bytes(stem+"a")
	var bytes_b := FileAccess.get_file_as_bytes(stem+"b")
	check(not p.save_run(a.snapshot()),"reject poisoned checkpoint")
	check(p.data == before,"preserve reliable checkpoint")
	check(bytes_a == FileAccess.get_file_as_bytes(stem+"a") and bytes_b == FileAccess.get_file_as_bytes(stem+"b"),"poison rejection changes neither slot")
	var wrong: Dictionary = before.current_run.snapshot.duplicate(true)
	wrong.rng_seed = "999"
	check(not p.save_run(wrong),"reject another run seed")
	wrong = before.current_run.snapshot.duplicate(true)
	wrong.loadout.difficulty = 2
	check(not p.save_run(wrong),"reject another loadout")
	storage.free()
	storage = Storage.new()
	assert(storage.initialize(stem+"a",stem+"b") == 0)
	p = Profile.new()
	check(p.initialize(c,storage),"reload profile")
	var b = Arena.new()
	root.add_child(b)
	run = p.data.current_run
	check(b.configure(c,c.missions[3],run.loadout,str(run.seed).to_int(),run.snapshot),"restore reliable checkpoint")
	a.free()
	b.free()
	storage.free()
	for index in [0,2,7]:
		a = make(index)
		a.state.player.hp = 1
		Combat.zone(a,a.player_world_position(),40,1000,0.2,"#ff0000","blast",true,0)
		a.advance(1.0/60,Vector2.ZERO)
		check(a.state.finished and not a.state.victory,"death priority")
		check(Arena.validate_snapshot(c,a.mission,a.snapshot()),"terminal clock snapshot")
		var restored = Arena.new()
		root.add_child(restored)
		check(restored.configure(c,a.mission,a.loadout,42,a.snapshot()),"restore death")
		restored.free()
		a.free()
	# Fresh boss run: validate each tick; this is not a restore-continuity comparison.
	a = make(7)
	var invalid := []
	for i in 350:
		if not a.state.offered.is_empty(): a.choose_upgrade(a.state.offered[0])
		if a.state.event_id != "": a.choose_event(false)
		a.advance(1.0/60,Vector2.UP)
		if not Arena.validate_snapshot(c,a.mission,a.snapshot()): invalid.append(a.state.tick)
		if a.state.finished: break
	check(invalid.is_empty(),"boss every tick snapshot")
	a.free()
	# Navigation must follow each actionable clue through a serialization boundary.
	a = make(3)
	for i in 3:
		var expected := Vector2(a.mission.clues[i][0],a.mission.clues[i][1])
		check(a.navigation_target() == expected,"next clue navigation")
		var clone = Arena.new()
		root.add_child(clone)
		check(clone.configure(c,a.mission,a.loadout,42,JSON.parse_string(JSON.stringify(a.snapshot(),"",true,true))),"clue roundtrip")
		check(clone.navigation_target() == expected,"restored clue navigation")
		clone.free()
		a.set_pos(a.state.player,expected)
		a.advance(1.0/60,Vector2.ZERO)
		if a.state.event_id != "": a.choose_event(false)
	for e in a.state.entities:
		if e.target_id != "":
			a.set_pos(e,Vector2(150,150))
			check(a.navigation_target() == Vector2(150,150),"follow live hunt")
	check(not "3/3" in a.teaching_text("en"),"finished clues show hunt advice")
	a.free()
	# Fatal escort tick follows the same clock contract.
	a = make(2)
	a.state.objective.escort_hp = 0
	a.advance(1.0/60,Vector2.ZERO)
	check(a.state.reason == "escort_destroyed" and Arena.validate_snapshot(c,a.mission,a.snapshot()),"escort terminal clock")
	a.free()
	# A terminal checkpoint survives settlement I/O failure and resolves exactly once.
	var fault := FaultStorage.new()
	check(fault.initialize(stem+"death-a",stem+"death-b") == 0,"terminal slots")
	p = Profile.new()
	check(p.initialize(c,fault),"terminal profile")
	check(p.begin_run(0).status == "OK","terminal run")
	run = p.data.current_run
	a = Arena.new()
	root.add_child(a)
	check(a.configure(c,c.missions[0],run.loadout,str(run.seed).to_int()),"terminal arena")
	a.state.player.hp = 1
	Combat.zone(a,a.player_world_position(),40,1000,0.2,"#ff0000","blast",true,0)
	a.advance(1.0/60,Vector2.ZERO)
	check(p.save_run(a.snapshot()),"autosave fatal tick")
	fault.fail = true
	check(p.finish_run(false,a.stats()).status == "ERROR","settlement write fails")
	fault.free()
	storage = Storage.new()
	check(storage.initialize(stem+"death-a",stem+"death-b") == 0,"reload fatal disk")
	p = Profile.new()
	check(p.initialize(c,storage),"reload fatal profile")
	run = p.data.current_run
	check(a.configure(c,c.missions[0],run.loadout,str(run.seed).to_int(),run.snapshot) and a.state.finished,"restore fatal checkpoint")
	check(p.finish_run(false,a.stats()).status == "OK","retry settlement")
	check(p.finish_run(false,a.stats()).status == "ERROR" and p.data.stats.runs == 1,"settle exactly once")
	a.free()
	storage.free()
	for suffix in ["a","b","death-a","death-b"]: DirAccess.remove_absolute(stem+suffix)
	print("PACKAGE_D_FIX checks=",checks," failures=",failures)
	quit(1 if failures else 0)
