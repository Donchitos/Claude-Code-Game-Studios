extends SceneTree
## Synthetic corruption fixture; uses real Profile and isolated double-slot storage.
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Codec = preload("res://src/campaign/campaign_arena_codec.gd")
const Profile = preload("res://src/campaign/campaign_profile.gd")
const Storage = preload("res://src/persistence/save_system.gd")
var evidence: String = preload("res://tests/fixtures/campaign_evidence.gd").create("upgrade-guard")
var failures := 0
var checks := 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _run() -> void:
	var c: Dictionary = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var paths := [evidence+"a.save",evidence+"b.save"]
	var storage = Storage.new()
	assert(storage.initialize(paths[0],paths[1]) == 0)
	var p = Profile.new()
	assert(p.initialize(c,storage))
	seed(711)
	assert(p.begin_run(0).status == "OK")
	var run: Dictionary = p.data.current_run
	var a = Arena.new()
	root.add_child(a)
	assert(a.configure(c,c.missions[0],run.loadout,str(run.seed).to_int()))
	a.state.player.xp = 100
	a.advance(1.0/60,Vector2.ZERO)
	check(Arena.validate_snapshot(c,a.mission,a.snapshot()),"first offered level retains valid unchosen sentinel")
	assert(a.choose_upgrade(a.state.offered[0]))
	var clean: Dictionary = a.snapshot()
	assert(p.save_run(clean))
	var before := [FileAccess.get_file_as_bytes(paths[0]),FileAccess.get_file_as_bytes(paths[1])]
	for mode in ["missing-choice-tick","missing-choice-bit"]:
		var bad: Dictionary = clean.duplicate(true)
		if mode == "missing-choice-tick": bad.state.encounter.last_upgrade_tick = -1
		else: bad.state.encounter.tutorial = int(bad.state.encounter.tutorial) & ~4
		bad.numeric_bits = Codec.bits(bad.state)
		check(not Arena.validate_snapshot(c,a.mission,bad),"reject contradictory "+mode)
		check(not p.save_run(bad) and p.error == "INVALID_BATTLE_CHECKPOINT","Profile rejects "+mode)
		check(FileAccess.get_file_as_bytes(paths[0]) == before[0] and FileAccess.get_file_as_bytes(paths[1]) == before[1],"both slots unchanged "+mode)
	storage.free()
	storage = Storage.new()
	assert(storage.initialize(paths[0],paths[1]) == 0)
	p = Profile.new()
	assert(p.initialize(c,storage))
	run = p.data.current_run
	var restored = Arena.new()
	root.add_child(restored)
	assert(restored.configure(c,c.missions[0],run.loadout,str(run.seed).to_int(),run.snapshot))
	for i in 179: restored.advance(1.0/60,Vector2.ZERO)
	check(restored.state.offered.is_empty() and restored.state.player.level == 2,"reliable disk state preserves 179-tick cooldown")
	restored.advance(1.0/60,Vector2.ZERO)
	check(not restored.state.offered.is_empty() and restored.state.player.level == 3,"disk cooldown opens at tick180")
	a.free()
	restored.free()
	storage.free()
	for path in paths: assert(DirAccess.remove_absolute(path) == OK)
	print("UPGRADE_GUARD checks=",checks," failures=",failures)
	quit(1 if failures else 0)
