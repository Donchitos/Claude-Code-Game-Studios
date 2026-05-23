## crash_recovery_cascade_test.gd — SaveLoadService crash-recovery branch contract.
##
## Covers story-006 Acceptance Criteria (decision contract — end-to-end auto-resubmit
## DEFERRED until Workspace/Brief controllers + EvaluationService exist, TD-001):
##   AC-5   recovered workspace_data.state == FROZEN → "workspace_resubmit" branch.
##   AC-6   recovered brief_editor_data.state == SUBMITTING → "brief_resubmit" branch.
##   Single entry point — recovery dispatches from one active_case_recovered signal.
##
## Run:
##   addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot \
##     -a tests/integration/save_load/crash_recovery_cascade_test.gd
##
## ADR: docs/architecture/adr-0011-save-load-storage-format.md (+ ADR-0001 amend-2 §C3)
## TR:  TR-save-*
extends GdUnitTestSuite


const _SaveLoadServiceScript: Script = preload("res://src/services/save_load_service.gd")


## Duck-typed stand-in for the (not-yet-existing) BriefEditorData (state enum).
class MockBrief extends RefCounted:
	var state: int = 0   # 3 == SUBMITTING (SaveLoadService.BRIEF_SUBMITTING)


func _service() -> Node:
	var svc: Node = _SaveLoadServiceScript.new()
	get_tree().root.add_child(svc)
	auto_free(svc)
	return svc


func _frozen_workspace() -> WorkspaceData:
	var ws := WorkspaceData.new()
	ws._transition_to_active()
	ws._transition_to_frozen()
	return ws


func _active_workspace() -> WorkspaceData:
	var ws := WorkspaceData.new()
	ws._transition_to_active()
	return ws


# ─── AC-5 — FROZEN workspace → workspace_resubmit ─────────────────────────────

func test_frozen_workspace_selects_workspace_resubmit() -> void:
	var svc: Node = _service()
	var ws: WorkspaceData = _frozen_workspace()
	assert_int(ws.state).is_equal(WorkspaceData.WorkspaceState.FROZEN)

	assert_str(svc.recovery_branch_for(ws, null)).is_equal("workspace_resubmit")


func test_active_workspace_not_workspace_resubmit() -> void:
	var svc: Node = _service()
	var ws: WorkspaceData = _active_workspace()   # ACTIVE, not FROZEN
	assert_str(svc.recovery_branch_for(ws, null)).is_equal("none")


# ─── AC-6 — SUBMITTING brief → brief_resubmit ─────────────────────────────────

func test_submitting_brief_selects_brief_resubmit() -> void:
	var svc: Node = _service()
	var brief := MockBrief.new()
	brief.state = svc.BRIEF_SUBMITTING   # 3
	# workspace not frozen (null) → brief branch
	assert_str(svc.recovery_branch_for(null, brief)).is_equal("brief_resubmit")


func test_non_submitting_brief_is_none() -> void:
	var svc: Node = _service()
	var brief := MockBrief.new()
	brief.state = 0   # not SUBMITTING
	assert_str(svc.recovery_branch_for(null, brief)).is_equal("none")


# ─── Precedence + none ────────────────────────────────────────────────────────

func test_frozen_workspace_wins_over_submitting_brief() -> void:
	var svc: Node = _service()
	var ws: WorkspaceData = _frozen_workspace()
	var brief := MockBrief.new()
	brief.state = svc.BRIEF_SUBMITTING
	# Both eligible → workspace precedence (committed submission awaiting evaluation)
	assert_str(svc.recovery_branch_for(ws, brief)).is_equal("workspace_resubmit")


func test_neither_recovers_to_none() -> void:
	var svc: Node = _service()
	assert_str(svc.recovery_branch_for(null, null)).is_equal("none")


# ─── Single entry point — active_case_recovered emitted once at boot ──────────

func test_active_case_recovered_is_a_single_signal() -> void:
	# The recovery cascade has ONE entry point: the active_case_recovered signal exists
	# on the service (emitted once by boot load, story 004). Structural check that the
	# single-signal contract holds (no second recovery signal).
	var svc: Node = _service()
	assert_bool(svc.has_signal("active_case_recovered")).is_true()
	# No alternate/duplicate recovery signal
	assert_bool(svc.has_signal("brief_recovered")).is_false()
	assert_bool(svc.has_signal("workspace_recovered")).is_false()
