## save_data_schema_test.gd — Save-data Resource classes + schema versioning.
##
## Covers story-002 Acceptance Criteria:
##   AC-10  Loading a save Resource that is MISSING a field → the field takes its
##          @export default (forward-compat for newly-added fields). EC-8.
##   AC-11  save_file_version greater than CURRENT_SAVE_FILE_VERSION → treated as
##          unsupported (corruption path); current/older versions are supported. EC-12.
##
## Strategy:
##   AC-10 is tested robustly without hand-crafting fragile .tres text: save a real
##   Resource via ResourceSaver, strip ONE field line from the serialized text, reload,
##   and assert that field is back at its @export default.
##   AC-11 is tested via SaveLoadService._is_save_version_supported(version).
##
## Run:
##   addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot \
##     -a tests/unit/save_load/save_data_schema_test.gd
##
## ADR: docs/architecture/adr-0011-save-load-storage-format.md
## TR:  TR-save-*
extends GdUnitTestSuite


const _SaveLoadServiceScript: Script = preload("res://src/services/save_load_service.gd")
const _CasebookEntryScript: Script = preload("res://src/data/casebook_entry.gd")
const _ActiveCaseScript: Script = preload("res://src/data/active_case_save_data.gd")

const TMP_PATH: String = "user://saves/test_schema_entry.tres"


func _service() -> Node:
	var svc: Node = _SaveLoadServiceScript.new()
	get_tree().root.add_child(svc)   # _ready creates user://saves/
	auto_free(svc)
	return svc


func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# ─── AC-10 — missing field falls back to @export default ──────────────────────

func test_loading_resource_with_missing_field_uses_export_default() -> void:
	# Arrange — a fully-populated CasebookEntry, saved to .tres
	_service()  # ensures saves/ exists
	_remove_if_exists(TMP_PATH)
	var entry: Resource = _CasebookEntryScript.new()
	entry.case_id = "case:schema-test"
	entry.verdict = "파기"
	entry.final_score = 0.87
	var save_err: Error = ResourceSaver.save(entry, TMP_PATH)
	assert_int(save_err).is_equal(OK)

	# Strip the `final_score = ...` line to simulate a file written by an OLDER class
	# that did not yet have that field.
	var f_read: FileAccess = FileAccess.open(TMP_PATH, FileAccess.READ)
	var text: String = f_read.get_as_text()
	f_read.close()
	var stripped_lines: PackedStringArray = PackedStringArray()
	for line: String in text.split("\n"):
		if not line.begins_with("final_score"):
			stripped_lines.append(line)
	var f_write: FileAccess = FileAccess.open(TMP_PATH, FileAccess.WRITE)
	f_write.store_string("\n".join(stripped_lines))
	f_write.close()

	# Act — load the field-stripped resource
	var loaded: Resource = ResourceLoader.load(TMP_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource

	# Assert — load succeeded; preserved fields intact; the missing field == @export default (0.0)
	assert_object(loaded).is_not_null()
	assert_str(loaded.case_id).is_equal("case:schema-test")
	assert_str(loaded.verdict).is_equal("파기")
	assert_float(loaded.final_score).is_equal_approx(0.0, 0.0001)   # @export default
	assert_int(loaded.save_file_version).is_equal(1)

	# Cleanup
	_remove_if_exists(TMP_PATH)


# ─── AC-11 — future save_file_version treated as unsupported (corruption) ─────

func test_future_save_version_is_unsupported() -> void:
	# Arrange
	var svc: Node = _service()

	# Assert — version gate: future > current is unsupported; current/older supported
	assert_bool(svc._is_save_version_supported(svc.CURRENT_SAVE_FILE_VERSION + 1)).is_false()
	assert_bool(svc._is_save_version_supported(svc.CURRENT_SAVE_FILE_VERSION)).is_true()
	assert_bool(svc._is_save_version_supported(1)).is_true()
	# Malformed versions
	assert_bool(svc._is_save_version_supported(0)).is_false()
	assert_bool(svc._is_save_version_supported(-1)).is_false()


func test_loaded_future_version_resource_reports_its_version() -> void:
	# A resource serialized with a future version round-trips its version field, so the
	# load path (story 004) can detect it via _is_save_version_supported.
	_service()
	_remove_if_exists(TMP_PATH)
	var entry: Resource = _CasebookEntryScript.new()
	entry.save_file_version = 99
	entry.case_id = "case:future"
	ResourceSaver.save(entry, TMP_PATH)

	var svc: Node = _service()
	var loaded: Resource = ResourceLoader.load(TMP_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	assert_object(loaded).is_not_null()
	assert_int(loaded.save_file_version).is_equal(99)
	assert_bool(svc._is_save_version_supported(loaded.save_file_version)).is_false()

	_remove_if_exists(TMP_PATH)


# ─── Resource class shape sanity ──────────────────────────────────────────────

func test_save_data_classes_carry_version_and_defaults() -> void:
	# Each save Resource declares save_file_version defaulting to 1.
	var entry: Resource = _CasebookEntryScript.new()
	assert_int(entry.save_file_version).is_equal(1)
	assert_float(entry.final_score).is_equal_approx(0.0, 0.0001)

	var active: Resource = _ActiveCaseScript.new()
	assert_int(active.save_file_version).is_equal(1)
	assert_str(active.case_id).is_equal("")
	assert_object(active.workspace_data).is_null()
