extends SceneTree
const Save = preload("res://src/persistence/save_system.gd")
class CrashSave extends Save:
	var cut := ""
	func _write_checkpoint(point: StringName) -> void:
		if String(point) == cut:
			print("CRASH_CUT_REACHED:", cut)
			OS.kill(OS.get_process_id())

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or not args[0].get_file().begins_with("save_crash_"):
		quit(2)
		return
	var save := CrashSave.new()
	root.add_child(save)
	if save.initialize(args[0].path_join("a.json"), args[0].path_join("b.json")) != Save.Status.OK:
		quit(3)
		return
	save.cut = args[1]
	save.commit_battle_result(true, 9, 99, 180.0, {"test": {"marker": "new"}})
	quit(4) # A selected crash point must not return normally.
