## freeze_recovery_test.gd — WorkspaceData crash recovery snapshot round-trip tests.
##
## Covers story-007 Acceptance Criteria (data-layer scope):
##   AC-27b  Crash recovery snapshot byte-equality:
##           save WorkspaceData (with chain_data_snapshot populated) via ResourceSaver
##           → load via ResourceLoader → JSON.stringify of loaded chain_data_snapshot
##           (sort_keys=true, empty-string indent) == JSON.stringify of the original
##           snapshot.
##
## ADR: docs/architecture/adr-0007-amend-1-chain-data-primitive-only.md
##      docs/architecture/adr-0008-workspace-layout.md §1 (BFS canonical ordering)
##
## NOTE on submission_timestamp_unix determinism:
##   build_chain_data() stamps submission_timestamp_unix = Time.get_unix_time_from_system().
##   For AC-27b (save→load round-trip of the SAME snapshot), the timestamp is baked
##   into chain_data_snapshot at submit() time. ResourceSaver/ResourceLoader preserves
##   the baked value, so JSON.stringify equality holds. This is deterministic per run.
##   Two separate calls to build_chain_data() may differ — but AC-27b never does that.
##
## Run:
##   addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot \
##     -a tests/unit/workspace/freeze_recovery_test.gd
extends GdUnitTestSuite


# ─── Helpers ──────────────────────────────────────────────────────────────────

## Returns a fresh WorkspaceData in INACTIVE state.
func _make_data() -> WorkspaceData:
	return WorkspaceData.new()


## Returns a HypothesisNodeData with the given fields pre-set.
## depth must be set by the caller to match the intended tree level.
func _make_node(
	id: String,
	parent: String = "",
	depth: int = 0,
	evidence: Array[String] = []
) -> HypothesisNodeData:
	var n := HypothesisNodeData.new()
	n.node_id = id
	n.label = "label-%s" % id
	n.parent_id = parent
	n.depth = depth
	n.evidence = evidence
	return n


## Drives WorkspaceData to ACTIVE state with the given nodes already appended.
## Mirrors the helper in chain_data_test.gd — independent copy, no shared state.
func _data_with_nodes(node_list: Array) -> WorkspaceData:
	var data: WorkspaceData = _make_data()
	for n: HypothesisNodeData in node_list:
		data.nodes.append(n)
	data._transition_to_active()
	return data


# ─── AC-27b — snapshot byte-equality after save/load round-trip ───────────────

func test_auto_resubmit_snapshot_byte_equality() -> void:
	# Arrange — build a tree with nodes at multiple depths + evidence
	var root_a: HypothesisNodeData = _make_node("root-A", "", 0, ["ev-1", "ev-2"])
	var root_b: HypothesisNodeData = _make_node("root-B", "", 0, ["ev-3"])
	var child_a1: HypothesisNodeData = _make_node("child-A1", "root-A", 1, ["ev-4"])
	var child_b1: HypothesisNodeData = _make_node("child-B1", "root-B", 1, [])
	var data: WorkspaceData = _data_with_nodes([root_a, root_b, child_a1, child_b1])
	assert_int(data.state).is_equal(WorkspaceData.WorkspaceState.ACTIVE)

	# Act — submit() populates chain_data_snapshot and freezes
	var submit_result: bool = data.submit()
	assert_bool(submit_result).is_true()
	assert_int(data.state).is_equal(WorkspaceData.WorkspaceState.FROZEN)
	assert_bool(data.chain_data_snapshot.is_empty()).is_false()

	# Capture the original snapshot JSON (canonical: sort_keys=true, empty indent)
	var original_snapshot: Dictionary = data.chain_data_snapshot
	var original_json: String = JSON.stringify(original_snapshot, "", true)
	assert_str(original_json).is_not_empty()

	# Save to a temp user:// path
	const SAVE_PATH: String = "user://test_freeze_recovery.tres"
	var save_err: Error = ResourceSaver.save(data, SAVE_PATH)
	assert_int(save_err).is_equal(OK)

	# Load back — use CACHE_MODE_IGNORE to force a fresh deserialization
	var loaded: WorkspaceData = ResourceLoader.load(
		SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE
	) as WorkspaceData
	assert_object(loaded).is_not_null()

	# Assert — JSON.stringify of loaded snapshot == JSON.stringify of original snapshot
	# Both use sort_keys=true and empty-string indent for canonical byte comparison
	# (ADR-0008 §1; matching the story-002 convention used in chain_data builds).
	var loaded_json: String = JSON.stringify(loaded.chain_data_snapshot, "", true)
	assert_str(loaded_json).is_equal(original_json)

	# Cleanup
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
