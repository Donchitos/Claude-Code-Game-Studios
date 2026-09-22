extends SceneTree

const SaveSystem = preload("res://src/persistence/save_system.gd")

class ReadbackFault extends SaveSystem:
	var sabotage := false
	func _read_slot(path: String) -> Dictionary:
		var result := super._read_slot(path)
		if sabotage and result.get("valid", false):
			result["payload_sha256"] = "wrong-content-same-generation"
		return result

var _failures: int = 0
var _slot_a: String
var _slot_b: String

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var stem := "%s/zhangtian_save_test_%d" % [OS.get_temp_dir(), Time.get_ticks_usec()]
	_slot_a = stem + "_a.json"
	_slot_b = stem + "_b.json"
	var save := SaveSystem.new()
	root.add_child(save)
	_expect(save.call("initialize", _slot_a, _slot_b) == SaveSystem.Status.OK, "empty dual-slot profile must initialize")
	var first_status := int(save.call("commit_battle_result", true, 3, 42, 75.0))
	_expect(first_status == SaveSystem.Status.OK, "generation one must commit, status=%d" % first_status)
	var second_status := int(save.call("commit_battle_result", false, 2, 18, 31.0))
	_expect(second_status == SaveSystem.Status.OK, "generation two must commit, status=%d" % second_status)
	var current: Dictionary = save.call("profile_snapshot")
	_expect(int(current["generation"]) == 2 and int(current["total_runs"]) == 2 and int(current["victories"]) == 1, "profile totals must persist in memory")
	_expect(int(current["best_level"]) == 3 and int(current["best_kills"]) == 42 and is_equal_approx(float(current["best_seconds"]), 75.0), "best records must be monotonic")
	save.queue_free()
	await process_frame

	var corrupt := FileAccess.open(_slot_b, FileAccess.WRITE)
	if corrupt != null:
		corrupt.store_string("{corrupt")
		corrupt = null
	var recovered := SaveSystem.new()
	root.add_child(recovered)
	_expect(recovered.call("initialize", _slot_a, _slot_b) == SaveSystem.Status.OK, "one valid slot must recover")
	var recovered_profile: Dictionary = recovered.call("profile_snapshot")
	_expect(int(recovered_profile["generation"]) == 1 and int(recovered_profile["total_runs"]) == 1, "corrupt newest slot must fall back to previous generation")
	_expect(recovered.commit_battle_result(false, 2, 1, 2.0) == SaveSystem.Status.OK, "recovered profile writes inactive slot")
	recovered.queue_free()
	await process_frame
	# A lone valid even-generation slot moved to A must not be overwritten.
	DirAccess.remove_absolute(_slot_a)
	DirAccess.rename_absolute(_slot_b, _slot_a)
	var survivor := FileAccess.get_file_as_string(_slot_a)
	var moved := SaveSystem.new()
	root.add_child(moved)
	_expect(moved.initialize(_slot_a, _slot_b) == SaveSystem.Status.OK, "load moved valid slot")
	_expect(moved.commit_battle_result(false, 1, 0, 1.0) == SaveSystem.Status.OK, "write opposite physical slot")
	_expect(FileAccess.get_file_as_string(_slot_a) == survivor, "sole recovery slot preserved byte for byte")
	moved.free()
	for path: String in [_slot_a, _slot_b]:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string("broken-profile")
		file.close()
	var broken := SaveSystem.new()
	root.add_child(broken)
	_expect(broken.initialize(_slot_a, _slot_b) == SaveSystem.Status.CORRUPT_PROFILE, "both corrupt must fail closed")
	_expect(broken.commit_battle_result(false, 1, 0, 1.0) == SaveSystem.Status.NOT_INITIALIZED, "cannot overwrite corrupt profile")
	_expect(FileAccess.get_file_as_string(_slot_a) == "broken-profile" and FileAccess.get_file_as_string(_slot_b) == "broken-profile", "corrupt evidence retained")
	broken.free()
	var blocked := SaveSystem.new()
	root.add_child(blocked)
	_expect(blocked.initialize(stem + "/missing/a", stem + "/missing/b") == SaveSystem.Status.OK, "missing paths initially empty")
	_expect(blocked.commit_battle_result(false, 1, 0, 1.0) == SaveSystem.Status.IO_ERROR, "write failure")
	_expect(blocked.commit_battle_result(false, 1, 0, 1.0) == SaveSystem.Status.WRITE_BLOCKED, "write failure blocks retry")
	_expect(blocked.profile_snapshot()["generation"] == 0, "write failure does not publish memory")
	blocked.free()
	_cleanup()
	var uncertain := ReadbackFault.new()
	root.add_child(uncertain)
	_expect(uncertain.initialize(_slot_a, _slot_b) == SaveSystem.Status.OK, "readback fixture initializes")
	uncertain.sabotage = true
	_expect(uncertain.commit_battle_result(true, 1, 0, 1.0) == SaveSystem.Status.READBACK_FAILED, "same-generation wrong hash rejected")
	_expect(uncertain.profile_snapshot()["generation"] == 0, "unconfirmed commit not published")
	_expect(uncertain.commit_battle_result(true, 1, 0, 1.0) == SaveSystem.Status.WRITE_BLOCKED, "uncertain outcome prevents duplicate")
	uncertain.free()
	var restart := SaveSystem.new()
	root.add_child(restart)
	_expect(restart.initialize(_slot_a, _slot_b) == SaveSystem.Status.OK and restart.profile_snapshot()["total_runs"] == 1, "restart reconciles actual durable result")
	restart.free()
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_slot_a))
	var conflict_profile: Dictionary = JSON.parse_string(envelope["payload_json"])
	conflict_profile["best_kills"] = 99
	envelope["payload_json"] = JSON.stringify(conflict_profile)
	envelope["payload_sha256"] = String(envelope["payload_json"]).sha256_text()
	var conflict_file := FileAccess.open(_slot_b, FileAccess.WRITE)
	conflict_file.store_string(JSON.stringify(envelope))
	conflict_file.close()
	var conflict := SaveSystem.new()
	root.add_child(conflict)
	_expect(conflict.initialize(_slot_a, _slot_b) == SaveSystem.Status.CONFLICTING_SLOTS, "same generation differing content rejected")
	conflict.free()
	_cleanup()
	_finish()

func _cleanup() -> void:
	for path: String in [_slot_a, _slot_b]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("SAVE_SYSTEM_ASSERTION_FAILED %s" % message)

func _finish() -> void:
	if _failures == 0:
		print("SAVE_SYSTEM_PASS dual_slot=true sha256=true readback=true fallback=true")
		quit(0)
	else:
		print("SAVE_SYSTEM_FAIL failures=%d" % _failures)
		quit(1)
