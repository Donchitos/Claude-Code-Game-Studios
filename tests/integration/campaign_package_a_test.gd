extends SceneTree
## Package A: real dual-slot compatibility, purchase boundaries and failed publication.
const Profile = preload("res://src/campaign/campaign_profile.gd")
const Storage = preload("res://src/persistence/save_system.gd")
class FaultStorage extends Storage:
	var fail := false
	func commit_domain_after_images(images: Dictionary) -> int:
		return Status.IO_ERROR if fail else super.commit_domain_after_images(images)
var checks := 0
var failures := 0
var catalog: Dictionary
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PACKAGE_A " + label)
func _run() -> void:
	catalog = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var base_storage := Storage.new()
	check(base_storage.initialize() == 0, "storage")
	var base := Profile.new()
	check(base.initialize(catalog, base_storage), "new profile")
	var initial: Dictionary = base.data
	base_storage.free()
	for rank in 5:
		var gate: int = [0, 8, 24, 40, 56][rank]
		for completed in ([0] if gate == 0 else [gate - 1, gate]):
			for branch in 3:
				var d := initial.duplicate(true)
				d.completed = completed
				d.pages = 1000
				d.branches[branch] = rank
				_fix_stats(d)
				var s := FaultStorage.new()
				s.initialize("", "", {"campaign_game": d})
				var p := Profile.new()
				check(p.initialize(catalog, s), "load rank %d at %d" % [rank, completed])
				check(p.branch_requirement(branch) == gate, "same gate for UI and authority")
				var before := s.profile_snapshot()
				var allowed: bool = completed >= gate
				check(p.purchase_branch(branch) == allowed, "purchase boundary")
				if allowed:
					check(p.data.branches[branch] == rank + 1 and p.data.pages == 1000 - 4 * (rank + 1), "exact cost and rank")
				else:
					check(p.error == "BRANCH_CHAPTER_LOCKED" and s.profile_snapshot() == before and _same(p.data, d), "locked zero mutation")
				s.free()
	var rich := initial.duplicate(true)
	rich.branches = [5, 5, 5]
	rich.pages = 200
	_fix_stats(rich)
	var old := Storage.new()
	old.initialize("", "", {"campaign_game": rich})
	var preserved := Profile.new()
	check(preserved.initialize(catalog, old) and _same(preserved.data, rich), "grandfather existing high ranks")
	check(not preserved.purchase_branch(0) and preserved.branch_requirement(0) == -1, "max rank")
	old.free()
	var faulty := FaultStorage.new()
	rich.branches = [0, 0, 0]
	_fix_stats(rich)
	faulty.initialize("", "", {"campaign_game": rich})
	var p := Profile.new()
	check(p.initialize(catalog, faulty), "fault setup")
	faulty.fail = true
	var before := faulty.profile_snapshot()
	check(not p.purchase_branch(0) and p.is_storage_locked() and _same(p.data, rich) and faulty.profile_snapshot() == before, "IO failure no rank/currency publication")
	faulty.free()
	_test_disk(initial)
	for invalid in [null, [], [0, 8, 24, 40], [0, 8, 7, 40, 56], [0, 8.5, 24, 40, 56], [0, 8, 24, 40, 65]]:
		var c := catalog.duplicate(true)
		c.tuning.progression_unlock_completed = invalid
		var s := Storage.new()
		s.initialize()
		check(not Profile.new().initialize(c, s), "reject malformed gate data")
		s.free()
	print("PACKAGE_A_%s checks=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
func _test_disk(initial: Dictionary) -> void:
	var seed_storage := Storage.new()
	seed_storage.initialize()
	var source := Profile.new()
	source.initialize(catalog, seed_storage)
	source.begin_run(0)
	var active: Dictionary = source.data
	seed_storage.free()
	var stem := OS.get_temp_dir() + "/package_a_%d" % Time.get_ticks_usec()
	for hash_value in [Profile.LEGACY_CONTENT_HASH, "f".repeat(64)]:
		active.current_run.content_hash = hash_value
		active.settings.erase("fullscreen") # Must reject before this migration writes.
		var a := stem + "a.save"
		var b := stem + "b.save"
		var writer := Storage.new()
		writer.initialize(a, b)
		check(writer.commit_domain_after_images({"campaign_game": active}) == 0, "write old active slot")
		check(writer.commit_domain_after_images({"campaign_game": active}) == 0, "write second old slot")
		writer.free()
		var bytes_a := FileAccess.get_file_as_bytes(a)
		var bytes_b := FileAccess.get_file_as_bytes(b)
		var reader := Storage.new()
		check(reader.initialize(a, b) == 0, "read disk slots")
		var p := Profile.new()
		check(not p.initialize(catalog, reader), "reject mismatched active")
		check(p.error == ("LEGACY_ACTIVE_RUN_REQUIRES_PREVIOUS_VERSION" if hash_value == Profile.LEGACY_CONTENT_HASH else "UNKNOWN_ACTIVE_RUN_CONTENT"), "diagnostic route")
		check(p.data.is_empty() and not p.update_settings({"master": 0.2}) and not p.abandon_run(), "blocked cannot mutate")
		check(FileAccess.get_file_as_bytes(a) == bytes_a and FileAccess.get_file_as_bytes(b) == bytes_b, "both slots byte identical")
		reader.free()
		DirAccess.remove_absolute(a)
		DirAccess.remove_absolute(b)
	var home := initial.duplicate(true)
	home.pages = 777
	home.branches = [5, 4, 3]
	_fix_stats(home)
	var s := Storage.new()
	s.initialize(stem + "a.save", stem + "b.save")
	s.commit_domain_after_images({"campaign_game": home})
	s.free()
	s = Storage.new()
	s.initialize(stem + "a.save", stem + "b.save")
	var p := Profile.new()
	check(p.initialize(catalog, s) and _same(p.data, home), "old home real disk progress retained")
	s.free()
	DirAccess.remove_absolute(stem + "a.save")
	if FileAccess.file_exists(stem + "b.save"): DirAccess.remove_absolute(stem + "b.save")

func _fix_stats(d: Dictionary) -> void:
	for key in ["completed", "wins", "runs", "total_runs", "victories"]:
		d.stats[key] = d.completed
	d.stats.character_wins = {} if d.completed == 0 else {d.character_id: d.completed}
	var ranks: int = int(d.branches[0]) + int(d.branches[1]) + int(d.branches[2])
	d.stats.total_branch_levels = ranks
	d.stats.branches_purchased = ranks

func _same(a: Dictionary, b: Dictionary) -> bool:
	return JSON.parse_string(JSON.stringify(a, "", true, true)) == JSON.parse_string(JSON.stringify(b, "", true, true))
