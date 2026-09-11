extends SceneTree
const Save = preload("res://src/persistence/save_system.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	for cut: String in ["before_open", "after_open", "after_store", "after_flush", "after_readback"]:
		var folder := OS.get_temp_dir().path_join("save_crash_%d_%s" % [Time.get_ticks_usec(), cut])
		check(DirAccess.make_dir_recursive_absolute(folder) == OK, "create fixture")
		var a := folder.path_join("a.json")
		var b := folder.path_join("b.json")
		var seed := Save.new()
		root.add_child(seed)
		check(seed.initialize(a, b) == Save.Status.OK, "seed load")
		check(seed.commit_battle_result(false, 2, 3, 90.0, {"test": {"marker": "old"}}) == Save.Status.OK, "seed commit")
		var original := FileAccess.get_file_as_bytes(a)
		seed.free()
		var output: Array = []
		var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tests/integration/save_crash_worker.gd", "--", folder, cut], output, true)
		check(code != 0 and "CRASH_CUT_REACHED:" + cut in str(output), "child actually reached crash boundary")
		var recovered := Save.new()
		root.add_child(recovered)
		check(recovered.initialize(a, b) == Save.Status.OK, "restart can recover")
		var profile := recovered.profile_snapshot()
		var generation := int(profile.get("generation", -1))
		check(generation in [1, 2], "only complete old or new result allowed")
		check(int(profile.get("total_runs", -1)) == generation, "no duplicate result")
		var expected := "old" if generation == 1 else "new"
		check(profile.get("domains", {}).get("test", {}).get("marker", "") == expected, "domain and summary commit together")
		check(int(profile.get("best_kills", -1)) == (3 if generation == 1 else 99), "no mixed summary")
		if cut in ["before_open", "after_open"]:
			check(generation == 1, "pre-write cut recovers old")
		if cut in ["after_flush", "after_readback"]:
			check(generation == 2, "post-flush process kill recovers new")
		check(FileAccess.get_file_as_bytes(a) == original, "previous slot unchanged")
		recovered.free()
		print("SAVE_CRASH_CASE cut=%s generation=%d child_exit=%d" % [cut, generation, code])
		# Delete only the two known temporary fixture files and their empty directory.
		for path: String in [a, b]:
			if FileAccess.file_exists(path):
				check(DirAccess.remove_absolute(path) == OK, "cleanup fixture file")
		check(DirAccess.remove_absolute(folder) == OK, "cleanup empty fixture directory")
	print("SAVE_CRASH_%s cases=5 platform=%s" % ["PASS" if failures == 0 else "FAIL", OS.get_name()])
	quit(0 if failures == 0 else 1)
