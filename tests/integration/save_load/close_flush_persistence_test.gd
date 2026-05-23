## close_flush_persistence_test.gd — SaveLoadService close-request flush + full-session round-trip.
##
## Covers story-008 Acceptance Criteria:
##   AC-14  Full-session reconstruction: edits made through the debounced autosave are
##          recoverable after a flush + reload (only the final < 250ms window may be lost).
##   Close-flush: a pending (dirty) debounced save is performed synchronously on flush;
##          a no-op when nothing is pending (EC-10).
##
## Note: NOTIFICATION_WM_CLOSE_REQUEST itself calls get_tree().quit() and cannot be
## exercised in-process, so the flush LOGIC (_flush_pending_save) is tested directly.
##
## Run:
##   addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot \
##     -a tests/integration/save_load/close_flush_persistence_test.gd
##
## ADR: docs/architecture/adr-0011-save-load-storage-format.md (§3.4 game-exit flush)
## TR:  TR-save-*
extends GdUnitTestSuite


const _SaveLoadServiceScript: Script = preload("res://src/services/save_load_service.gd")
const _ActiveCaseScript: Script = preload("res://src/data/active_case_save_data.gd")

const ACTIVE_CASE_FILE: String = "user://saves/active_case.tres"


func _service() -> Node:
	var svc: Node = _SaveLoadServiceScript.new()
	get_tree().root.add_child(svc)
	auto_free(svc)
	return svc


func _rm_active_case() -> void:
	for p: String in [ACTIVE_CASE_FILE, "%s.tmp.%s" % [ACTIVE_CASE_FILE.get_basename(), ACTIVE_CASE_FILE.get_extension()]]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


# ─── Close-flush drains a pending debounced save ──────────────────────────────

func test_flush_writes_pending_dirty_save() -> void:
	# Arrange — active case + a pending (running) debounce timer
	var svc: Node = _service()
	_rm_active_case()
	svc._active_case = _ActiveCaseScript.new()
	svc._active_case.case_id = "case:flush"
	svc._on_workspace_changed(1, 2)   # starts the workspace debounce timer (dirty)
	var timer: Timer = svc._debounce_timer_for("workspace_state_changed")
	assert_bool(timer.is_stopped()).is_false()

	# Act — flush (simulates the close-request path without quitting)
	svc._flush_pending_save()

	# Assert — timer drained (stopped) + active_case written
	assert_bool(timer.is_stopped()).is_true()
	assert_bool(FileAccess.file_exists(ACTIVE_CASE_FILE)).is_true()
	var loaded: Resource = ResourceLoader.load(ACTIVE_CASE_FILE, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	assert_object(loaded).is_not_null()
	assert_str(loaded.case_id).is_equal("case:flush")
	_rm_active_case()


func test_flush_is_noop_when_nothing_pending() -> void:
	# Arrange — active case set but NO pending change (no running timer)
	var svc: Node = _service()
	_rm_active_case()
	svc._active_case = _ActiveCaseScript.new()
	svc._active_case.case_id = "case:clean"

	# Act — flush with no dirty timer
	svc._flush_pending_save()

	# Assert — nothing written (no spurious save)
	assert_bool(FileAccess.file_exists(ACTIVE_CASE_FILE)).is_false()


# ─── AC-14 — full-session reconstruction round-trip ───────────────────────────

func test_full_session_reconstructs_latest_edits_after_flush() -> void:
	# Arrange — simulate a session: several debounced edits to the active case, the last
	# of which is still pending in the debounce window when the app closes.
	var svc: Node = _service()
	_rm_active_case()
	var active: Resource = _ActiveCaseScript.new()
	active.case_id = "case:2026-session"
	svc._active_case = active

	# Edit 1 committed (simulate the debounce having fired earlier)
	svc._perform_save("workspace_state_changed")
	# Edit 2 mutates the in-memory state and is still pending (dirty) at close
	active.case_id = "case:2026-session-EDIT2"
	svc._on_workspace_changed(2, 1)   # dirty

	# Act — close flush drains the pending edit
	svc._flush_pending_save()

	# Assert — reloaded state reflects the LATEST edit (not the earlier committed one)
	var loaded: Resource = ResourceLoader.load(ACTIVE_CASE_FILE, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	assert_object(loaded).is_not_null()
	assert_str(loaded.case_id).is_equal("case:2026-session-EDIT2")
	_rm_active_case()
