## resolution_cascade_test.gd — SaveLoadService resolution cascade + revert guard.
##
## Covers story-005 Acceptance Criteria:
##   AC-3   evaluation_completed → casebook append + immediate write + active_case delete
##          + casebook_entry_added emit. (Handler tested directly; the EvaluationService
##          subscription is DEFERRED — TD-001.)
##   AC-4   save_active_case() on a Resolved case → push_error + false + active_case
##          untouched (save_load_revert_resolved, EC-5).
##
## Run:
##   addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot \
##     -a tests/integration/save_load/resolution_cascade_test.gd
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


## Duck-typed stand-in for the (not-yet-existing) EvaluationResult Resource.
class MockResult extends RefCounted:
	var case_id: String = ""
	var verdict: String = ""
	var final_score: float = 0.0


func _service() -> Node:
	var svc: Node = _SaveLoadServiceScript.new()
	get_tree().root.add_child(svc)
	auto_free(svc)
	return svc


func _rm(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# ─── AC-3 — evaluation_completed resolution cascade ───────────────────────────

func test_evaluation_completed_archives_and_deletes_active() -> void:
	# Arrange — active case present + empty casebook + a written active_case file
	var svc: Node = _service()
	_rm(ACTIVE_CASE_FILE)
	_rm(CASEBOOK_FILE)
	svc._casebook = _CasebookScript.new()
	svc._active_case = _ActiveCaseScript.new()
	svc._active_case.case_id = "case:resolve-1"
	ResourceSaver.save(svc._active_case, ACTIVE_CASE_FILE)   # active file exists pre-resolution
	assert_bool(FileAccess.file_exists(ACTIVE_CASE_FILE)).is_true()

	var added: Array = []
	var cb: Callable = func(entry: Object) -> void: added.append(entry)
	svc.casebook_entry_added.connect(cb)

	# Act — resolution
	var result := MockResult.new()
	result.case_id = "case:resolve-1"
	result.verdict = "파기"
	result.final_score = 0.91
	svc._on_evaluation_completed(result)

	# Assert — casebook has the entry; active_case deleted; casebook.tres written; signal fired
	svc.casebook_entry_added.disconnect(cb)
	assert_int(svc._casebook.entries.size()).is_equal(1)
	assert_str(svc._casebook.entries[0].case_id).is_equal("case:resolve-1")
	assert_float(svc._casebook.entries[0].final_score).is_equal_approx(0.91, 0.0001)
	assert_bool(FileAccess.file_exists(CASEBOOK_FILE)).is_true()
	assert_bool(FileAccess.file_exists(ACTIVE_CASE_FILE)).is_false()
	assert_object(svc._active_case).is_null()
	assert_int(added.size()).is_equal(1)

	_rm(CASEBOOK_FILE)


# ─── AC-4 — revert guard (anti-save-scumming) ─────────────────────────────────

func test_save_active_case_blocked_when_resolved() -> void:
	# Arrange — casebook already contains case:X; active_case has the same id
	var svc: Node = _service()
	_rm(ACTIVE_CASE_FILE)
	svc._casebook = _CasebookScript.new()
	var resolved: Resource = _CasebookEntryScript.new()
	resolved.case_id = "case:X"
	svc._casebook.entries.append(resolved)
	svc._active_case = _ActiveCaseScript.new()
	svc._active_case.case_id = "case:X"

	# Act — attempt to (re)save the Resolved case
	var ok: bool = svc.save_active_case()

	# Assert — rejected; no active_case file written
	assert_bool(ok).is_false()
	assert_bool(FileAccess.file_exists(ACTIVE_CASE_FILE)).is_false()


func test_save_active_case_allowed_when_not_resolved() -> void:
	# Arrange — casebook empty; active_case is in progress
	var svc: Node = _service()
	_rm(ACTIVE_CASE_FILE)
	svc._casebook = _CasebookScript.new()
	svc._active_case = _ActiveCaseScript.new()
	svc._active_case.case_id = "case:in-progress"

	# Act
	var ok: bool = svc.save_active_case()

	# Assert — saved
	assert_bool(ok).is_true()
	assert_bool(FileAccess.file_exists(ACTIVE_CASE_FILE)).is_true()
	_rm(ACTIVE_CASE_FILE)
