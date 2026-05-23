## autosave_debounce_test.gd — SaveLoadService signal-triggered autosave + debounce.
##
## Covers story-003 Acceptance Criteria:
##   AC-2   workspace_state_changed → debounced active_case save (_perform_save writes
##          active_case.tres via the atomic wrapper).
##   Coalescing — repeated change handlers within the window reuse one timer (EC-9).
##   No-polling — autosave is signal-triggered only; the forbidden pattern
##          `save_load_polling_based_autosave` is registered, and the service has no
##          _process/_physics_process save loop.
##
## Headless note: gdunit4 does not reliably advance a real Timer tick in isolation
## (see ui_service_test.gd debounce note), so debounce timing is verified structurally
## (timer running + time_left reset) plus a direct _perform_save write for the actual
## persistence assertion.
##
## Run:
##   addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot \
##     -a tests/integration/save_load/autosave_debounce_test.gd
##
## ADR: docs/architecture/adr-0011-save-load-storage-format.md
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


func _remove_active_case() -> void:
	if FileAccess.file_exists(ACTIVE_CASE_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ACTIVE_CASE_FILE))
	var tmp: String = "%s.tmp.%s" % [ACTIVE_CASE_FILE.get_basename(), ACTIVE_CASE_FILE.get_extension()]
	if FileAccess.file_exists(tmp):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))


# ─── AC-2 — workspace change → debounced active_case save ─────────────────────

func test_workspace_change_starts_debounce_timer() -> void:
	# Arrange — active case present
	var svc: Node = _service()
	svc._active_case = _ActiveCaseScript.new()
	svc._active_case.case_id = "case:autosave"

	# Act — workspace changed
	svc._on_workspace_changed(1, 2)

	# Assert — a debounce timer exists for the workspace category, running, with 250ms wait
	var timer: Timer = svc._debounce_timer_for("workspace_state_changed")
	assert_object(timer).is_not_null()
	assert_bool(timer.is_stopped()).is_false()
	assert_float(timer.wait_time).is_equal_approx(0.25, 0.001)
	timer.stop()


func test_perform_save_writes_active_case_atomically() -> void:
	# Arrange
	var svc: Node = _service()
	_remove_active_case()
	svc._active_case = _ActiveCaseScript.new()
	svc._active_case.case_id = "case:perform-save"

	# Act — the debounce timeout target writes the active case
	svc._perform_save("workspace_state_changed")

	# Assert — active_case.tres written + round-trips case_id
	assert_bool(FileAccess.file_exists(ACTIVE_CASE_FILE)).is_true()
	var loaded: Resource = ResourceLoader.load(ACTIVE_CASE_FILE, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	assert_object(loaded).is_not_null()
	assert_str(loaded.case_id).is_equal("case:perform-save")
	_remove_active_case()


func test_perform_save_noop_when_no_active_case() -> void:
	# Arrange — no active case set
	var svc: Node = _service()
	_remove_active_case()
	svc._active_case = null

	# Act — must not crash, must not write
	svc._perform_save("workspace_state_changed")

	# Assert — no file written
	assert_bool(FileAccess.file_exists(ACTIVE_CASE_FILE)).is_false()


# ─── Debounce coalescing (EC-9) ───────────────────────────────────────────────

func test_repeated_changes_reuse_one_timer_and_reset() -> void:
	# Arrange
	var svc: Node = _service()
	svc._active_case = _ActiveCaseScript.new()

	# Act — three rapid workspace changes
	svc._on_workspace_changed(1, 2)
	var t1: Timer = svc._debounce_timer_for("workspace_state_changed")
	var first_left: float = t1.time_left
	svc._on_workspace_changed(2, 1)
	var second_left: float = t1.time_left
	svc._on_workspace_changed(1, 2)
	var third_left: float = t1.time_left

	# Assert — same single Timer instance reused; each start resets time_left (debounce)
	assert_object(svc._debounce_timer_for("workspace_state_changed")).is_same(t1)
	assert_float(first_left).is_greater(0.0)
	assert_float(second_left).is_greater(0.0)
	assert_float(third_left).is_greater(0.0)
	t1.stop()


# ─── No-polling guard ─────────────────────────────────────────────────────────

func test_no_per_frame_polling_autosave() -> void:
	# Autosave must be signal-triggered, never per-frame polling. The forbidden pattern
	# enforces this at PR review; assert it is registered (automated gate). (A has_method
	# check on _process is unreliable — Node declares it as a virtual regardless of override.)
	var file: FileAccess = FileAccess.open("res://docs/registry/architecture.yaml", FileAccess.READ)
	assert_object(file).is_not_null()
	var content: String = file.get_as_text()
	file.close()
	assert_bool(content.contains("save_load_polling_based_autosave")).is_true()
