## atomic_write_test.gd — SaveLoadService autoload bootstrap + atomic write wrapper.
##
## Covers story-001 Acceptance Criteria:
##   AC-1  _ready() creates user://saves/ silently when absent (idempotent if present).
##   AC-8  _save_resource_atomic success → target fully written, no .tmp left, round-trips.
##   AC-9  _save_resource_atomic with a failing temp write → returns false + existing
##         target left untouched (partial write never reaches the live file).
##
## Test strategy:
##   Preload the script (bypass class_name global cache — same as ui_service_test.gd).
##   _save_resource_atomic is pure file I/O; tests instantiate the service, exercise it
##   against unique user:// paths, and clean up after each test. AC-9 forces a temp-write
##   failure deterministically by pre-creating a DIRECTORY at the .tmp path, so
##   ResourceSaver.save cannot write a file there.
##
## Run:
##   addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot \
##     -a tests/integration/save_load/atomic_write_test.gd
##
## ADR: docs/architecture/adr-0011-save-load-storage-format.md
## TR:  TR-save-*
extends GdUnitTestSuite


const _SaveLoadServiceScript: Script = preload("res://src/services/save_load_service.gd")

const SAVES_DIR: String = "user://saves/"
const AC8_TARGET: String = "user://saves/test_ac8_atomic.tres"
const AC9_TARGET: String = "user://saves/test_ac9_preserve.tres"


# ─── Helpers ──────────────────────────────────────────────────────────────────

## Fresh SaveLoadService instance in the tree (so _ready runs), auto-freed.
func _make_service() -> Node:
	var svc: Node = _SaveLoadServiceScript.new()
	get_tree().root.add_child(svc)
	auto_free(svc)
	return svc


## A WorkspaceData carrying a recognizable marker in an @export field.
func _marker_resource(marker: String) -> WorkspaceData:
	var ws: WorkspaceData = WorkspaceData.new()
	ws.pending_citation = marker   # @export String — round-trips through .tres
	return ws


func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# ─── AC-1 — saves/ directory bootstrap ────────────────────────────────────────

func test_ready_creates_saves_dir_when_absent() -> void:
	# Arrange — remove the dir if a prior run left it (best-effort; dir may be non-empty
	# from other tests, so only assert creation, not pre-absence).
	# Act — _ready() runs on add_child
	_make_service()

	# Assert — the saves dir exists after _ready()
	assert_bool(DirAccess.dir_exists_absolute(SAVES_DIR)).is_true()


func test_ensure_saves_dir_is_idempotent_when_present() -> void:
	# Arrange — service (dir now exists)
	var svc: Node = _make_service()
	assert_bool(DirAccess.dir_exists_absolute(SAVES_DIR)).is_true()

	# Act — calling again must not error or recreate
	svc._ensure_saves_dir()

	# Assert — still present, no crash
	assert_bool(DirAccess.dir_exists_absolute(SAVES_DIR)).is_true()


# ─── AC-8 — atomic write success ──────────────────────────────────────────────

func test_save_resource_atomic_writes_target_and_removes_tmp() -> void:
	# Arrange
	var svc: Node = _make_service()
	# Temp path keeps a recognized extension: "x.tres" -> "x.tmp.tres"
	var ac8_tmp: String = "%s.tmp.%s" % [AC8_TARGET.get_basename(), AC8_TARGET.get_extension()]
	_remove_if_exists(AC8_TARGET)
	_remove_if_exists(ac8_tmp)
	var res: WorkspaceData = _marker_resource("AC8-marker")

	# Act
	var ok: bool = svc._save_resource_atomic(res, AC8_TARGET)

	# Assert — success; target exists; no leftover .tmp; round-trips the marker
	assert_bool(ok).is_true()
	assert_bool(FileAccess.file_exists(AC8_TARGET)).is_true()
	assert_bool(FileAccess.file_exists(ac8_tmp)).is_false()
	var loaded: WorkspaceData = ResourceLoader.load(AC8_TARGET, "", ResourceLoader.CACHE_MODE_IGNORE) as WorkspaceData
	assert_object(loaded).is_not_null()
	assert_str(loaded.pending_citation).is_equal("AC8-marker")

	# Cleanup
	_remove_if_exists(AC8_TARGET)


# ─── AC-9 — temp write failure preserves existing target ──────────────────────

func test_save_resource_atomic_failure_preserves_existing_target() -> void:
	# Arrange — write a valid target (marker A) via the atomic wrapper
	var svc: Node = _make_service()
	_remove_if_exists(AC9_TARGET)
	var first_ok: bool = svc._save_resource_atomic(_marker_resource("AC9-original"), AC9_TARGET)
	assert_bool(first_ok).is_true()

	# Force a temp-write failure: create a DIRECTORY at the .tmp path so
	# ResourceSaver.save cannot write a file there. (Temp path: "x.tres" -> "x.tmp.tres".)
	var tmp_path: String = "%s.tmp.%s" % [AC9_TARGET.get_basename(), AC9_TARGET.get_extension()]
	DirAccess.make_dir_recursive_absolute(tmp_path)
	assert_bool(DirAccess.dir_exists_absolute(tmp_path)).is_true()

	# Act — attempt to overwrite with marker B; temp write must fail
	var second_ok: bool = svc._save_resource_atomic(_marker_resource("AC9-NEW-should-not-land"), AC9_TARGET)

	# Assert — returned false; the existing target still holds marker A (untouched)
	assert_bool(second_ok).is_false()
	var loaded: WorkspaceData = ResourceLoader.load(AC9_TARGET, "", ResourceLoader.CACHE_MODE_IGNORE) as WorkspaceData
	assert_object(loaded).is_not_null()
	assert_str(loaded.pending_citation).is_equal("AC9-original")

	# Cleanup — remove the blocking dir + target
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))
	_remove_if_exists(AC9_TARGET)
