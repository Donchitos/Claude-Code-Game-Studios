## boot_load_recovery_test.gd — SaveLoadService boot load + corruption recovery.
##
## Covers story-004 Acceptance Criteria:
##   AC-7   active_case.tres corrupt → renamed to .backup + save_corrupted("active_case")
##          emitted + load returns null (boot continues fresh). EC-3.
##   AC-15  casebook.tres with 5 entries → _load_casebook() returns Casebook with 5 entries.
##   AC-16  session_meta.cfg → last_active_case_id + workspace_f2_hint_seen read back. AC-16.
##
## Strategy: create the service (boots on whatever is in user://saves/), then CLEAN the
## canonical files, write a pristine fixture, and call the specific load method directly
## so the assertion is deterministic (independent of the autoload's boot timing).
##
## Run:
##   addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot \
##     -a tests/integration/save_load/boot_load_recovery_test.gd
##
## ADR: docs/architecture/adr-0011-save-load-storage-format.md
## TR:  TR-save-*
extends GdUnitTestSuite


const _SaveLoadServiceScript: Script = preload("res://src/services/save_load_service.gd")
const _ActiveCaseScript: Script = preload("res://src/data/active_case_save_data.gd")
const _CasebookScript: Script = preload("res://src/data/casebook.gd")
const _CasebookEntryScript: Script = preload("res://src/data/casebook_entry.gd")

const ACTIVE_CASE_FILE: String = "user://saves/active_case.tres"
const CASEBOOK_FILE: String = "user://saves/casebook.tres"
const SESSION_META_FILE: String = "user://saves/session_meta.cfg"


func _service() -> Node:
	var svc: Node = _SaveLoadServiceScript.new()
	get_tree().root.add_child(svc)
	auto_free(svc)
	return svc


func _rm(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# ─── AC-7 — corrupt active_case → .backup + save_corrupted ───────────────────

func test_corrupt_active_case_renamed_to_backup_and_signals() -> void:
	# Arrange — service (boots on whatever exists), then write a pristine corrupt file
	var svc: Node = _service()
	_rm(ACTIVE_CASE_FILE)
	_rm(ACTIVE_CASE_FILE + ".backup")
	var f: FileAccess = FileAccess.open(ACTIVE_CASE_FILE, FileAccess.WRITE)
	f.store_string("this is not a valid .tres {{{ garbage")
	f.close()

	var corrupted: Array = []
	var cb: Callable = func(category: String) -> void: corrupted.append(category)
	svc.save_corrupted.connect(cb)

	# Act — load attempt detects corruption
	var result: Variant = svc._load_active_case_or_recover()

	# Assert — null returned; original renamed to .backup; signal emitted once
	svc.save_corrupted.disconnect(cb)
	assert_object(result).is_null()
	assert_bool(FileAccess.file_exists(ACTIVE_CASE_FILE)).is_false()
	assert_bool(FileAccess.file_exists(ACTIVE_CASE_FILE + ".backup")).is_true()
	assert_int(corrupted.size()).is_equal(1)
	assert_str(corrupted[0]).is_equal("active_case")

	# Cleanup
	_rm(ACTIVE_CASE_FILE + ".backup")


func test_absent_active_case_returns_null_without_backup() -> void:
	# EC-2 fresh start: no file → null, no backup, no signal
	var svc: Node = _service()
	_rm(ACTIVE_CASE_FILE)
	_rm(ACTIVE_CASE_FILE + ".backup")
	var corrupted: Array = []
	var cb: Callable = func(_c: String) -> void: corrupted.append(true)
	svc.save_corrupted.connect(cb)

	var result: Variant = svc._load_active_case_or_recover()

	svc.save_corrupted.disconnect(cb)
	assert_object(result).is_null()
	assert_bool(FileAccess.file_exists(ACTIVE_CASE_FILE + ".backup")).is_false()
	assert_int(corrupted.size()).is_equal(0)


# ─── AC-15 — casebook eager load ──────────────────────────────────────────────

func test_casebook_loads_five_entries() -> void:
	# Arrange — write a casebook with 5 entries
	var svc: Node = _service()
	_rm(CASEBOOK_FILE)
	var book: Resource = _CasebookScript.new()
	for i: int in range(5):
		var entry: Resource = _CasebookEntryScript.new()
		entry.case_id = "case:2026-%03d" % i
		entry.verdict = "파기"
		entry.final_score = 0.5 + i * 0.1
		book.entries.append(entry)
	assert_int(ResourceSaver.save(book, CASEBOOK_FILE)).is_equal(OK)

	# Act
	var loaded: Resource = svc._load_casebook()

	# Assert — 5 entries, sampled fields correct
	assert_object(loaded).is_not_null()
	assert_int(loaded.entries.size()).is_equal(5)
	assert_str(loaded.entries[0].case_id).is_equal("case:2026-000")
	assert_str(loaded.entries[4].case_id).is_equal("case:2026-004")
	assert_float(loaded.entries[2].final_score).is_equal_approx(0.7, 0.0001)

	_rm(CASEBOOK_FILE)


func test_absent_casebook_returns_empty() -> void:
	# EC-2: no casebook → fresh empty Casebook (not null, no error)
	var svc: Node = _service()
	_rm(CASEBOOK_FILE)
	var loaded: Resource = svc._load_casebook()
	assert_object(loaded).is_not_null()
	assert_int(loaded.entries.size()).is_equal(0)


# ─── AC-16 — session meta load ────────────────────────────────────────────────

func test_session_meta_values_read_back() -> void:
	# Arrange — write session_meta.cfg
	var svc: Node = _service()
	_rm(SESSION_META_FILE)
	var cfg := ConfigFile.new()
	cfg.set_value("session", "last_active_case_id", "case:2026-001")
	cfg.set_value("hints", "workspace_f2_hint_seen", true)
	assert_int(cfg.save(SESSION_META_FILE)).is_equal(OK)

	# Act
	svc._load_session_meta()

	# Assert
	assert_str(svc.last_active_case_id).is_equal("case:2026-001")
	assert_bool(svc.workspace_f2_hint_seen).is_true()

	_rm(SESSION_META_FILE)


func test_absent_session_meta_keeps_defaults() -> void:
	var svc: Node = _service()
	_rm(SESSION_META_FILE)
	svc._load_session_meta()
	assert_str(svc.last_active_case_id).is_equal("")
	assert_bool(svc.workspace_f2_hint_seen).is_false()
