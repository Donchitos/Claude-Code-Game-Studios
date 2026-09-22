extends RefCounted
## Per-process evidence runs: never reuse a dated release or another test's slots.
static func create(suite: String) -> String:
	var content: String = FileAccess.get_file_as_string("res://assets/config/campaign_game.json").sha256_text()
	var base := "res://production/playtest-evidence/runs"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-root="):
			base = argument.trim_prefix("--evidence-root=")
	var parent: String = base.path_join(content.substr(0,12)).path_join(suite)
	assert(DirAccess.make_dir_recursive_absolute(parent) == OK)
	var directory := DirAccess.open(parent)
	assert(directory != null)
	var run_name := "%d-%d-%d" % [int(Time.get_unix_time_from_system()),OS.get_process_id(),Time.get_ticks_usec()]
	# Atomic creation fails instead of ever reusing a previous output directory.
	assert(directory.make_dir(run_name) == OK)
	var result: String = parent.path_join(run_name)+"/"
	var manifest := FileAccess.open(result+"run.json",FileAccess.WRITE)
	assert(manifest != null)
	manifest.store_string(JSON.stringify({"suite":suite,"content_hash":content,"engine":Engine.get_version_info().string,"arguments":Array(OS.get_cmdline_user_args()),"scope":"automated test evidence, not human or release certification"},"\t"))
	manifest.close()
	print("CAMPAIGN_EVIDENCE ",ProjectSettings.globalize_path(result))
	return result
