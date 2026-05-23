## freeze_contract_test.gd — WorkspaceData.submit() freeze contract unit tests.
##
## Covers story-007 Acceptance Criteria (data-layer scope):
##   AC-24  chain_data_snapshot immutable post-freeze: the snapshot is an
##          independent copy. Mutating nodes (or any HypothesisNodeData) after
##          freeze does NOT affect chain_data_snapshot.
##          Verified via:
##            (3) mutation blocking — post-freeze tree mutations are AC-19 rejected,
##                AND direct HypothesisNodeData field mutation does not affect snapshot.
##            (4) instance distinctness — snapshot's nested evidence arrays are
##                independent copies; snapshot is not the same Dictionary instance
##                as a subsequent build_chain_data() call.
##          NOTE on AC-24 protocol step (1) JSON.stringify deep-equality vs fresh rebuild:
##            build_chain_data() embeds submission_timestamp_unix = Time.get_unix_time_from_system().
##            Two calls may produce different timestamps, making whole-dict JSON equality
##            non-deterministic. This test file therefore verifies independence via mutation
##            (steps 3 & 4) rather than whole-dict equality. AC-27b (byte-equality round-trip
##            of the SAME snapshot) is covered in freeze_recovery_test.gd.
##   AC-26  workspace_state_changed(ACTIVE, FROZEN) emits EXACTLY ONCE on submit().
##          Verified with a connected counter + captured args.
##
## ADR: docs/architecture/adr-0007-amend-1-chain-data-primitive-only.md
##      docs/architecture/adr-0008-workspace-layout.md §1
##
## Signal assertions use the project pattern for Resource signals (synchronous emit):
##   Manual connect + Array accumulator BEFORE the act — avoids gdunit4 v5.x polling-window miss.
##   IMPORTANT: use Array (reference type) as the accumulator, not a plain int counter.
##   GDScript lambda captures are by VALUE for primitives (int, float, bool) — a lambda
##   that does `count += 1` increments a captured copy, not the outer variable.
##   Arrays are reference types and ARE shared with the outer scope via the lambda.
##   Pattern matches workspace_state_machine_test.gd line 188 (captures: Array[Array]).
##   Ref: tests/unit/library/library_service_autoload_test.gd line 159.
##   Ref: tests/unit/workspace/chain_data_test.gd header note.
##
## Run:
##   addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot \
##     -a tests/unit/workspace/freeze_contract_test.gd
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


# ─── AC-26 — workspace_state_changed emits EXACTLY ONCE on submit() ──────────

func test_submit_emits_workspace_state_changed_exactly_once() -> void:
	# Arrange — small tree in ACTIVE state; connect capture BEFORE act
	var root: HypothesisNodeData = _make_node("root-A")
	var data: WorkspaceData = _data_with_nodes([root])
	assert_int(data.state).is_equal(WorkspaceData.WorkspaceState.ACTIVE)

	# NOTE: use Array (reference type) for the counter — int is a value type and
	# GDScript lambda captures are by value for primitives. captured.size() serves
	# as the emit count. Pattern matches workspace_state_machine_test.gd line 188.
	var captured: Array = []
	var cb: Callable = func(old_s: int, new_s: int) -> void:
		captured.append([old_s, new_s])
	data.workspace_state_changed.connect(cb)

	# Act
	var result: bool = data.submit()

	# Assert
	data.workspace_state_changed.disconnect(cb)
	assert_bool(result).is_true()
	assert_int(captured.size()).is_equal(1)
	assert_int(captured[0][0]).is_equal(WorkspaceData.WorkspaceState.ACTIVE)
	assert_int(captured[0][1]).is_equal(WorkspaceData.WorkspaceState.FROZEN)
	assert_int(data.state).is_equal(WorkspaceData.WorkspaceState.FROZEN)


func test_submit_from_non_active_state_does_not_emit() -> void:
	# Arrange — fresh INACTIVE data; connect capture BEFORE act
	var data: WorkspaceData = _make_data()
	assert_int(data.state).is_equal(WorkspaceData.WorkspaceState.INACTIVE)

	var captured: Array = []
	var cb: Callable = func(_old_s: int, _new_s: int) -> void:
		captured.append(true)
	data.workspace_state_changed.connect(cb)

	# Act — submit() on INACTIVE must be rejected
	var result: bool = data.submit()

	# Assert — no emit, no state change, returns false
	data.workspace_state_changed.disconnect(cb)
	assert_bool(result).is_false()
	assert_int(captured.size()).is_equal(0)
	assert_int(data.state).is_equal(WorkspaceData.WorkspaceState.INACTIVE)
	# Snapshot must never be populated on the reject path (assigned only after validation passes).
	assert_bool(data.chain_data_snapshot.is_empty()).is_true()


func test_submit_from_frozen_state_does_not_emit() -> void:
	# Arrange — legitimately reach FROZEN, then attempt second submit
	var root: HypothesisNodeData = _make_node("root-A")
	var data: WorkspaceData = _data_with_nodes([root])
	var first_result: bool = data.submit()
	assert_bool(first_result).is_true()
	assert_int(data.state).is_equal(WorkspaceData.WorkspaceState.FROZEN)
	# Capture the valid snapshot produced by the first freeze (canonical JSON).
	var snapshot_json_before: String = JSON.stringify(data.chain_data_snapshot, "", true)

	# Connect AFTER first freeze (only monitors second attempt)
	var captured: Array = []
	var cb: Callable = func(_old_s: int, _new_s: int) -> void:
		captured.append(true)
	data.workspace_state_changed.connect(cb)

	# Act — second submit from FROZEN must be rejected
	var result: bool = data.submit()

	# Assert
	data.workspace_state_changed.disconnect(cb)
	assert_bool(result).is_false()
	assert_int(captured.size()).is_equal(0)
	assert_int(data.state).is_equal(WorkspaceData.WorkspaceState.FROZEN)
	# The first freeze's snapshot must survive the rejected second submit unchanged
	# (the state guard returns before reaching the snapshot assignment).
	assert_str(JSON.stringify(data.chain_data_snapshot, "", true)).is_equal(snapshot_json_before)


# ─── AC-24 — chain_data_snapshot independence ────────────────────────────────

func test_chain_data_snapshot_populated_at_freeze() -> void:
	# Arrange — small tree with evidence
	var root: HypothesisNodeData = _make_node("root-A", "", 0, ["ev-1", "ev-2"])
	var data: WorkspaceData = _data_with_nodes([root])

	# Act
	var result: bool = data.submit()

	# Assert — snapshot is non-empty and has schema_version=1
	assert_bool(result).is_true()
	assert_bool(data.chain_data_snapshot.is_empty()).is_false()
	assert_int(data.chain_data_snapshot.get("schema_version", -1)).is_equal(1)
	assert_bool(data.chain_data_snapshot.has("nodes")).is_true()


func test_chain_data_snapshot_is_distinct_instance() -> void:
	# Arrange — ACTIVE tree
	var root: HypothesisNodeData = _make_node("root-A", "", 0, ["ev-1"])
	var data: WorkspaceData = _data_with_nodes([root])

	# Act
	data.submit()
	# Build a fresh chain_data after freeze (build_chain_data works from all non-INACTIVE states)
	var rebuilt: Dictionary = data.build_chain_data()

	# AC-24 step 1 (deterministic structural deep-equality vs a fresh rebuild).
	# submission_timestamp_unix is stripped from BOTH sides first: it is stamped from
	# Time.get_unix_time_from_system() per build, so two builds straddling a 1-second
	# boundary would differ — comparing it is a time-dependent assertion, forbidden by
	# test-standards.md. Stripping it leaves the structural content, which is byte-stable.
	var snap_stripped: Dictionary = data.chain_data_snapshot.duplicate(true)
	snap_stripped.erase("submission_timestamp_unix")
	var rebuilt_stripped: Dictionary = rebuilt.duplicate(true)
	rebuilt_stripped.erase("submission_timestamp_unix")
	assert_str(JSON.stringify(snap_stripped, "", true)).is_equal(
		JSON.stringify(rebuilt_stripped, "", true)
	)
	# AC-24 step 4 (instance distinctness): mutating the rebuilt dict's nodes array does
	# not affect the snapshot — they are independent Dictionary allocations.
	var snapshot_nodes_size_before: int = (data.chain_data_snapshot["nodes"] as Array).size()
	(rebuilt["nodes"] as Array).append({"injected": true})
	var snapshot_nodes_size_after: int = (data.chain_data_snapshot["nodes"] as Array).size()
	assert_int(snapshot_nodes_size_after).is_equal(snapshot_nodes_size_before)


func test_chain_data_snapshot_independent_of_post_freeze_node_mutation() -> void:
	# Arrange — tree with a root node whose label we will mutate after freeze
	var root: HypothesisNodeData = _make_node("root-A")
	root.label = "original-label"
	var data: WorkspaceData = _data_with_nodes([root])

	# Act — freeze; capture snapshot label
	data.submit()
	var snapshot_label_before: String = ""
	for nd: Dictionary in data.chain_data_snapshot["nodes"]:
		if nd["node_id"] == "root-A":
			snapshot_label_before = nd["label"]
			break
	assert_str(snapshot_label_before).is_equal("original-label")

	# Attempt mutation via WorkspaceData API (AC-19 guard will reject this; that is expected)
	data.update_node_label("root-A", "mutated-via-api")
	# ALSO directly mutate the HypothesisNodeData Resource field (bypasses AC-19 guard —
	# HypothesisNodeData fields are plain @export vars with no protection at the Resource level)
	data.nodes[0].label = "mutated-directly"

	# Assert — snapshot node label is unchanged by either mutation path
	var snapshot_label_after: String = ""
	for nd: Dictionary in data.chain_data_snapshot["nodes"]:
		if nd["node_id"] == "root-A":
			snapshot_label_after = nd["label"]
			break
	assert_str(snapshot_label_after).is_equal("original-label")
	# Confirm the live node was actually mutated (so we know we're testing the right thing)
	assert_str(data.nodes[0].label).is_equal("mutated-directly")


func test_chain_data_snapshot_evidence_arrays_are_independent_copies() -> void:
	# Arrange — node with 2 evidence entries
	var root: HypothesisNodeData = _make_node("root-A", "", 0, ["ev-1", "ev-2"])
	var data: WorkspaceData = _data_with_nodes([root])

	# Act
	data.submit()
	var snapshot_evidence: Array = []
	for nd: Dictionary in data.chain_data_snapshot["nodes"]:
		if nd["node_id"] == "root-A":
			snapshot_evidence = nd["evidence"]
			break
	var snapshot_evidence_size_before: int = snapshot_evidence.size()

	# Directly mutate the live HypothesisNodeData evidence array
	data.nodes[0].evidence.append("ev-injected-post-freeze")

	# Assert — snapshot evidence array is unaffected (it is a .duplicate() per build_chain_data)
	assert_int(snapshot_evidence.size()).is_equal(snapshot_evidence_size_before)
	assert_bool(snapshot_evidence.has("ev-injected-post-freeze")).is_false()


# ─── Validation-blocks-freeze contract ───────────────────────────────────────

func test_submit_valid_tree_passes_validation_and_freezes() -> void:
	# NOTE: build_chain_data() only ever produces allow-listed fields (it builds from
	# ALLOWED_NODE_FIELDS explicitly). Therefore a schema violation cannot be injected
	# through the normal submit() path — the validate_chain_data() call inside submit()
	# will always pass for a valid tree. Schema violation coverage is in chain_data_test.gd
	# (AC-10, AC-52) which tests validate_chain_data() directly with poisoned dicts.
	# This test asserts the positive-path contract: a valid tree freezes successfully.

	# Arrange — tree with root + child + evidence
	var root: HypothesisNodeData = _make_node("root-A", "", 0, ["ev-1"])
	var child: HypothesisNodeData = _make_node("child-A1", "root-A", 1, ["ev-2", "ev-3"])
	var data: WorkspaceData = _data_with_nodes([root, child])

	# Act
	var result: bool = data.submit()

	# Assert — submit succeeds; state is FROZEN; snapshot is populated
	assert_bool(result).is_true()
	assert_int(data.state).is_equal(WorkspaceData.WorkspaceState.FROZEN)
	assert_bool(data.chain_data_snapshot.is_empty()).is_false()
	assert_int(data.chain_data_snapshot.get("schema_version", -1)).is_equal(1)
	assert_int((data.chain_data_snapshot["nodes"] as Array).size()).is_equal(2)


# ─── State-guard branch coverage ──────────────────────────────────────────────

func test_submit_from_read_only_state_does_not_emit() -> void:
	# Arrange — drive ACTIVE → FROZEN → READ_ONLY (the fourth state guard branch)
	var root: HypothesisNodeData = _make_node("root-A")
	var data: WorkspaceData = _data_with_nodes([root])
	assert_bool(data.submit()).is_true()
	data._transition_to_read_only()
	assert_int(data.state).is_equal(WorkspaceData.WorkspaceState.READ_ONLY)
	var snapshot_json_before: String = JSON.stringify(data.chain_data_snapshot, "", true)

	# Connect AFTER reaching READ_ONLY (only monitors the rejected submit)
	var captured: Array = []
	var cb: Callable = func(_old_s: int, _new_s: int) -> void:
		captured.append(true)
	data.workspace_state_changed.connect(cb)

	# Act — submit() from READ_ONLY must be rejected (guard requires ACTIVE)
	var result: bool = data.submit()

	# Assert — no emit, no state change, snapshot unchanged
	data.workspace_state_changed.disconnect(cb)
	assert_bool(result).is_false()
	assert_int(captured.size()).is_equal(0)
	assert_int(data.state).is_equal(WorkspaceData.WorkspaceState.READ_ONLY)
	assert_str(JSON.stringify(data.chain_data_snapshot, "", true)).is_equal(snapshot_json_before)


# ─── Empty-tree submission (story-007 QA edge case) ───────────────────────────

func test_submit_empty_tree_freezes_with_empty_nodes() -> void:
	# Per story-007 QA "Edge cases: submit with empty tree (empty chain_data —
	# schema_version=1 with nodes=[])". An ACTIVE workspace with zero nodes is a valid
	# submission: build_chain_data() yields {schema_version:1, nodes:[], ...}, which
	# passes the allow-list validator, so submit() freezes successfully.

	# Arrange — ACTIVE with zero nodes
	var data: WorkspaceData = _make_data()
	data._transition_to_active()
	assert_int(data.state).is_equal(WorkspaceData.WorkspaceState.ACTIVE)

	# Act
	var result: bool = data.submit()

	# Assert — empty tree freezes; snapshot has schema_version=1 + empty nodes array
	assert_bool(result).is_true()
	assert_int(data.state).is_equal(WorkspaceData.WorkspaceState.FROZEN)
	assert_int(data.chain_data_snapshot.get("schema_version", -1)).is_equal(1)
	assert_int((data.chain_data_snapshot["nodes"] as Array).size()).is_equal(0)
