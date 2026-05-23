## edge_cases_test.gd — WorkspaceData tree-structural edge cases + chain_data validation suite.
##
## Covers story-012 Edge Cases and Performance Gates (scope-split mirror of story-007):
##
## REAL TESTS (implemented — testable against existing WorkspaceData + HypothesisNodeData):
##   EC-1   Empty tree: INACTIVE → {} ; ACTIVE with no nodes → {schema_version:1, nodes:[], ...}
##   EC-2   Single root + single evidence → chain_data counts verified
##   EC-3   Max tree builds + JSON round-trip: 3 roots × 2-branch × depth-3 × 5 ev/node (45 nodes)
##   EC-4   Depth-4 rejected: add_child_to_node on depth-3 node → false + "max_depth" (AC-12)
##   EC-5   Cycle rejected: reparent ancestor onto descendant → false + "cycle" (AC-13)
##   EC-12  Memo at exactly 500 codepoints: no truncation, no signal
##   EC-13  Memo at 501 codepoints: truncated to 500 + "memo_truncated" emitted
##   EC-16  Pillar 1 — memo_text field injected into chain_data node → validate returns false
##   EC-17  Pillar 1 — settings key injected into chain_data node → validate returns false
##   AC-52  Forbidden-field fuzz: 5 forbidden ephemeral names all rejected
##   AC-52b Settings-inclusion fuzz: 5 settings keys all rejected
##
## SKIP-STUB TESTS (deferred — feature/service not yet implemented):
##   EC-6   Dedup (drag-drop pipeline — story 004)
##   EC-7   Drop non-existent library_id + announce (LibraryService + UIService.announce_text)
##   EC-8   Drop on non-ACTIVE state guard (drag-drop — story 004)
##   EC-9   Window resize mid-drag (UI drag-drop)
##   EC-10  State transition during pending citation (story 004)
##   EC-11  Corrupted active_case.tres → .backup recovery (SaveLoadService)
##   EC-14  Korean IME composition at cap boundary (VR-D7 dependent)
##   EC-15  Memo focus loss mid-IME (UI/IME)
##   EC-18  WorkspaceData reference after case unload (Case Browser)
##   EC-19  Drag while Browser scene swapping (Case Browser)
##   EC-20  Auto-resubmit schema_version mismatch → CriticalBanner (story 008)
##   EC-21  Camera2D pan clamp (UI — camera)
##   EC-22  Gamepad two-step with mid-process transition (story 004)
##   EC-23  Focus loss off-window → restore (UI focus)
##   EC-24  Simultaneous SettingsService changes race (SettingsService)
##
## Signal assertion pattern (synchronous Resource signals):
##   Manual connect() + Array accumulator BEFORE act, assert AFTER, disconnect AFTER.
##   Use Array (reference type) — never a plain int (lambda captures primitives by value).
##   See freeze_contract_test.gd header lines 25-34.
##
## Determinism note: build_chain_data() embeds submission_timestamp_unix.
##   When comparing whole dicts, strip that key first (see EC-3).
##
## ADR: docs/architecture/adr-0007-amend-1-chain-data-primitive-only.md
##      docs/architecture/adr-0008-workspace-layout.md §1
##
## Run:
##   addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot \
##     -a tests/unit/workspace/edge_cases_test.gd
extends GdUnitTestSuite


# ─── Helpers ──────────────────────────────────────────────────────────────────

## Returns a fresh WorkspaceData in INACTIVE state.
func _make_data() -> WorkspaceData:
	return WorkspaceData.new()


## Returns a HypothesisNodeData with the given fields pre-set.
## depth must be set by the caller to match the intended tree level (story 003
## enforces the invariant at construction; here we set it manually for fixtures).
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
## Circumvents add_first_root_node so we can build arbitrary trees including child nodes.
func _data_with_nodes(node_list: Array[HypothesisNodeData]) -> WorkspaceData:
	var data: WorkspaceData = _make_data()
	for n: HypothesisNodeData in node_list:
		data.nodes.append(n)
	data._transition_to_active()
	return data


# ─── EC-1 — Empty tree ────────────────────────────────────────────────────────

func test_ec_1_inactive_state_build_chain_data_returns_empty_dict() -> void:
	# Arrange
	var data: WorkspaceData = _make_data()
	assert_int(data.state).is_equal(WorkspaceData.WorkspaceState.INACTIVE)

	# Act
	var cd: Dictionary = data.build_chain_data()

	# Assert — INACTIVE must return {} per AC-23
	assert_bool(cd.is_empty()).is_true()


func test_ec_1_active_empty_tree_returns_valid_structure_with_zeros() -> void:
	# Arrange — ACTIVE state but zero nodes added
	var data: WorkspaceData = _make_data()
	data._transition_to_active()

	# Act
	var cd: Dictionary = data.build_chain_data()

	# Assert — structure is present with correct zero-state values
	assert_int(cd.get("schema_version", -1)).is_equal(1)
	assert_int((cd["nodes"] as Array).size()).is_equal(0)
	assert_int((cd["edges"] as Array).size()).is_equal(0)
	assert_int(cd["total_evidence_count"]).is_equal(0)
	assert_int(cd["max_depth_reached"]).is_equal(0)
	assert_bool(cd.has("submission_timestamp_unix")).is_true()
	# No errors emitted
	var rejection_captures: Array = []
	var cb: Callable = func(reason: String) -> void: rejection_captures.append(reason)
	data.submission_rejected.connect(cb)
	var valid: bool = data.validate_chain_data(cd)
	data.submission_rejected.disconnect(cb)
	assert_bool(valid).is_true()
	assert_int(rejection_captures.size()).is_equal(0)


# ─── EC-2 — Single root + single evidence ────────────────────────────────────

func test_ec_2_single_root_single_evidence_chain_data_counts() -> void:
	# Arrange — one root, one evidence item
	var root: HypothesisNodeData = _make_node("root-A", "", 0, ["ev-001"])
	var data: WorkspaceData = _data_with_nodes([root])

	# Act
	var cd: Dictionary = data.build_chain_data()

	# Assert — exactly 1 node, no edges, counts are 1
	assert_int((cd["nodes"] as Array).size()).is_equal(1)
	assert_int((cd["edges"] as Array).size()).is_equal(0)
	assert_int(cd["total_evidence_count"]).is_equal(1)

	var node_dict: Dictionary = cd["nodes"][0]
	assert_int(node_dict["evidence_count"]).is_equal(1)
	assert_int(node_dict["child_count"]).is_equal(0)
	assert_str(node_dict["node_id"]).is_equal("root-A")


# ─── EC-3 — Max tree builds + JSON round-trip ────────────────────────────────
#
# Tree shape: 3 roots (depth 0), each root has 2 children (depth 1),
# each child has 2 children (depth 2), each of those has 2 children (depth 3).
# Node count:
#   depth 0: 3 roots
#   depth 1: 3 * 2 = 6 children
#   depth 2: 6 * 2 = 12 grandchildren
#   depth 3: 12 * 2 = 24 great-grandchildren
#   TOTAL: 3 + 6 + 12 + 24 = 45 nodes
# Evidence: 5 per node × 45 = 225 total

func test_ec_3_max_tree_builds_and_serializes_correctly() -> void:
	# Arrange — build the deepest valid tree using the public mutation API
	var data: WorkspaceData = WorkspaceData.new()
	var ev_ids: Array[String] = ["ev-1", "ev-2", "ev-3", "ev-4", "ev-5"]

	# Lay down 3 roots at depth 0
	for r: int in range(3):
		var root_id: String = "r%d" % r
		var root: HypothesisNodeData = HypothesisNodeData.new()
		root.node_id = root_id
		root.label = "root-%d" % r
		data.add_first_root_node(root)  # transitions INACTIVE→ACTIVE on first call
		for ev: String in ev_ids:
			data.attach_evidence(root_id, ev)

		# 2 children at depth 1 per root
		for c: int in range(2):
			var child_id: String = "r%dc%d" % [r, c]
			var child: HypothesisNodeData = HypothesisNodeData.new()
			child.node_id = child_id
			child.label = "child-%d-%d" % [r, c]
			var ok_c: bool = data.add_child_to_node(root_id, child)
			assert_bool(ok_c).is_true()
			for ev: String in ev_ids:
				data.attach_evidence(child_id, ev)

			# 2 grandchildren at depth 2 per child
			for gc: int in range(2):
				var gc_id: String = "r%dc%dgc%d" % [r, c, gc]
				var grandchild: HypothesisNodeData = HypothesisNodeData.new()
				grandchild.node_id = gc_id
				grandchild.label = "gc-%d-%d-%d" % [r, c, gc]
				var ok_gc: bool = data.add_child_to_node(child_id, grandchild)
				assert_bool(ok_gc).is_true()
				for ev: String in ev_ids:
					data.attach_evidence(gc_id, ev)

				# 2 great-grandchildren at depth 3 (MAX_TREE_DEPTH) per grandchild
				for ggc: int in range(2):
					var ggc_id: String = "r%dc%dgc%dggc%d" % [r, c, gc, ggc]
					var ggchild: HypothesisNodeData = HypothesisNodeData.new()
					ggchild.node_id = ggc_id
					ggchild.label = "ggc-%d-%d-%d-%d" % [r, c, gc, ggc]
					var ok_ggc: bool = data.add_child_to_node(gc_id, ggchild)
					assert_bool(ok_ggc).is_true()
					for ev: String in ev_ids:
						data.attach_evidence(ggc_id, ev)

	# Act
	var cd: Dictionary = data.build_chain_data()

	# Assert — node count: 3 + 6 + 12 + 24 = 45
	assert_int((cd["nodes"] as Array).size()).is_equal(45)
	# Total evidence: 45 nodes × 5 = 225
	assert_int(cd["total_evidence_count"]).is_equal(225)
	# Max depth reached: 3 (MAX_TREE_DEPTH)
	assert_int(cd["max_depth_reached"]).is_equal(3)

	# JSON round-trip: stringify → parse_string must succeed without data loss.
	# Note: Godot's JSON.parse_string returns all numbers as float (Godot JSON
	# round-trips ints as floats). We therefore verify structural integrity —
	# that the parse succeeds and the top-level keys survive — rather than
	# asserting byte-identical re-stringified output.
	var json_str: String = JSON.stringify(cd, "", true)
	assert_bool(json_str.is_empty()).is_false()
	var parsed: Variant = JSON.parse_string(json_str)
	assert_bool(parsed != null).is_true()
	var parsed_dict: Dictionary = parsed as Dictionary
	# Top-level keys must survive the round-trip
	assert_bool(parsed_dict.has("schema_version")).is_true()
	assert_bool(parsed_dict.has("nodes")).is_true()
	assert_bool(parsed_dict.has("edges")).is_true()
	assert_bool(parsed_dict.has("total_evidence_count")).is_true()
	assert_bool(parsed_dict.has("max_depth_reached")).is_true()
	# Key presence only (no value comparison — purely structural, zero time-sensitivity)
	assert_bool(parsed_dict.has("submission_timestamp_unix")).is_true()
	# Node count must survive (JSON.parse_string converts int → float, so cast)
	assert_int((parsed_dict["nodes"] as Array).size()).is_equal(45)
	# total_evidence_count must survive (cast from float)
	assert_int(int(parsed_dict["total_evidence_count"])).is_equal(225)


# ─── EC-4 — Depth-4 rejected ─────────────────────────────────────────────────

func test_ec_4_add_child_to_depth3_node_rejected_emits_max_depth() -> void:
	# Arrange — build chain to depth 3 (maximum allowed)
	var data: WorkspaceData = WorkspaceData.new()
	var a: HypothesisNodeData = HypothesisNodeData.new()
	a.node_id = "A"
	data.add_first_root_node(a)       # depth 0
	var b: HypothesisNodeData = HypothesisNodeData.new()
	b.node_id = "B"
	data.add_child_to_node("A", b)    # depth 1
	var c: HypothesisNodeData = HypothesisNodeData.new()
	c.node_id = "C"
	data.add_child_to_node("B", c)    # depth 2
	var d: HypothesisNodeData = HypothesisNodeData.new()
	d.node_id = "D"
	data.add_child_to_node("C", d)    # depth 3 — should succeed

	# Connect signal accumulator BEFORE the act
	var violation_captures: Array = []
	var cb: Callable = func(reason: String) -> void: violation_captures.append(reason)
	data.tree_invariant_violation.connect(cb)

	# Act — attempt depth 4: parent D is at depth 3
	var e: HypothesisNodeData = HypothesisNodeData.new()
	e.node_id = "E"
	var result: bool = data.add_child_to_node("D", e)

	# Assert — rejected; "max_depth" emitted; E not in nodes; cross-link AC-12
	data.tree_invariant_violation.disconnect(cb)
	assert_bool(result).is_false()
	assert_int(violation_captures.size()).is_equal(1)
	assert_str(violation_captures[0]).is_equal("max_depth")
	assert_int(data.nodes.size()).is_equal(4)  # A, B, C, D — E not added


# ─── EC-5 — Cycle rejected ───────────────────────────────────────────────────

func test_ec_5_reparent_ancestor_onto_descendant_rejected_emits_cycle() -> void:
	# Arrange — build A→B (B is child of A), then reparent A to be a child of B (cycle)
	var data: WorkspaceData = WorkspaceData.new()
	var a: HypothesisNodeData = HypothesisNodeData.new()
	a.node_id = "A"
	data.add_first_root_node(a)       # A is root, depth 0
	var b: HypothesisNodeData = HypothesisNodeData.new()
	b.node_id = "B"
	data.add_child_to_node("A", b)    # B is child of A, depth 1

	# Connect signal accumulator BEFORE the act
	var violation_captures: Array = []
	var cb: Callable = func(reason: String) -> void: violation_captures.append(reason)
	data.tree_invariant_violation.connect(cb)

	# Act — reparent("A", "B"): make A a child of its own descendant B → cycle
	var result: bool = data.reparent("A", "B")

	# Assert — rejected; "cycle" emitted; cross-link AC-13
	data.tree_invariant_violation.disconnect(cb)
	assert_bool(result).is_false()
	assert_int(violation_captures.size()).is_equal(1)
	assert_str(violation_captures[0]).is_equal("cycle")
	# Tree state must be unchanged
	assert_str(a.parent_id).is_equal("")   # A is still a root
	assert_str(b.parent_id).is_equal("A")  # B still under A
	assert_int(a.depth).is_equal(0)
	assert_int(b.depth).is_equal(1)


# ─── EC-6 — DEDUP (skip-stub) ────────────────────────────────────────────────

func test_ec_6_evidence_dedup_on_drop(_do_skip := true, _skip_reason := "deferred: drag-drop pipeline (story 004) not implemented") -> void:
	# Blocking dependency: drag-drop pipeline + LibraryService dedup (story 004).
	# attach_evidence does NOT deduplicate at this layer (duplicates are appended).
	# Dedup logic lives in story 004's DragDrop controller.
	pass


# ─── EC-7 — Drop non-existent library_id + announce (skip-stub) ──────────────

func test_ec_7_drop_nonexistent_library_id_announce(_do_skip := true, _skip_reason := "deferred: LibraryService.validate + UIService.announce_text not implemented") -> void:
	# Blocking dependency: LibraryService (validates library_id exists) +
	# UIService.announce_text (accessibility announcement on invalid drop).
	pass


# ─── EC-8 — Drop on non-ACTIVE state guard (skip-stub) ───────────────────────

func test_ec_8_drop_on_non_active_state_guard(_do_skip := true, _skip_reason := "deferred: drag-drop pipeline (story 004) not implemented") -> void:
	# Blocking dependency: drag-drop state guard is in story 004 DragDrop controller.
	pass


# ─── EC-9 — Window resize mid-drag (skip-stub) ───────────────────────────────

func test_ec_9_window_resize_mid_drag(_do_skip := true, _skip_reason := "deferred: drag-drop UI (story 004) not implemented") -> void:
	# Blocking dependency: drag-drop UI layer (story 004).
	pass


# ─── EC-10 — State transition during pending citation (skip-stub) ─────────────

func test_ec_10_state_transition_during_pending_citation(_do_skip := true, _skip_reason := "deferred: pending_citation flow (story 004) not implemented") -> void:
	# Blocking dependency: pending_citation two-step KB/gamepad flow (story 004).
	pass


# ─── EC-11 — Corrupted active_case.tres → backup recovery (skip-stub) ────────

func test_ec_11_corrupted_save_backup_recovery(_do_skip := true, _skip_reason := "deferred: SaveLoadService (ADR-0011) not implemented") -> void:
	# Blocking dependency: SaveLoadService + crash-recovery backup logic (story 008).
	pass


# ─── EC-12 — Memo at exactly 500 codepoints: no truncation ───────────────────

func test_ec_12_memo_at_exactly_500_ascii_codepoints_no_truncation() -> void:
	# Arrange — root node; memo of exactly 500 ASCII chars (500 codepoints)
	var data: WorkspaceData = WorkspaceData.new()
	var root: HypothesisNodeData = HypothesisNodeData.new()
	root.node_id = "root-A"
	data.add_first_root_node(root)
	var memo_500: String = "X".repeat(500)
	assert_int(memo_500.length()).is_equal(500)  # fixture sanity

	# Connect accumulator BEFORE act
	var violation_captures: Array = []
	var cb: Callable = func(reason: String) -> void: violation_captures.append(reason)
	data.tree_invariant_violation.connect(cb)

	# Act
	data.update_node_memo("root-A", memo_500)

	# Assert — memo set to the full 500 chars; NO memo_truncated signal
	data.tree_invariant_violation.disconnect(cb)
	assert_int(data._find_node("root-A").memo.length()).is_equal(500)
	assert_int(violation_captures.size()).is_equal(0)


func test_ec_12_memo_at_exactly_500_hangul_codepoints_no_truncation() -> void:
	# Korean Hangul (가-힣) is 1 codepoint per char in GDScript String.length().
	# Using ASCII for the cap test is sufficient; this variant confirms Korean
	# codepoint counting works identically. Use plain Hangul (가 = U+AC00) —
	# no CJK Compatibility Ideograph hazard here (test-standards.md).
	var data: WorkspaceData = WorkspaceData.new()
	var root: HypothesisNodeData = HypothesisNodeData.new()
	root.node_id = "root-K"
	data.add_first_root_node(root)
	var korean_500: String = ""
	for _i: int in range(500):
		korean_500 += "가"
	assert_int(korean_500.length()).is_equal(500)  # fixture sanity

	var violation_captures: Array = []
	var cb: Callable = func(reason: String) -> void: violation_captures.append(reason)
	data.tree_invariant_violation.connect(cb)

	# Act
	data.update_node_memo("root-K", korean_500)

	# Assert — 500 Korean codepoints: no truncation, no signal
	data.tree_invariant_violation.disconnect(cb)
	assert_int(data._find_node("root-K").memo.length()).is_equal(500)
	assert_int(violation_captures.size()).is_equal(0)


# ─── EC-13 — Memo 501 codepoints → truncated + signal ────────────────────────

func test_ec_13_memo_at_501_codepoints_truncated_to_500_emits_signal() -> void:
	# Arrange — 501 ASCII chars = 501 codepoints → must truncate to 500
	# Note: announce (UIService.announce_text) is out of scope — test only truncation + signal
	var data: WorkspaceData = WorkspaceData.new()
	var root: HypothesisNodeData = HypothesisNodeData.new()
	root.node_id = "root-A"
	data.add_first_root_node(root)
	var memo_501: String = "Y".repeat(501)

	# Connect accumulator BEFORE act
	var violation_captures: Array = []
	var cb: Callable = func(reason: String) -> void: violation_captures.append(reason)
	data.tree_invariant_violation.connect(cb)

	# Act
	data.update_node_memo("root-A", memo_501)

	# Assert — truncated to 500; "memo_truncated" emitted exactly once
	data.tree_invariant_violation.disconnect(cb)
	assert_int(data._find_node("root-A").memo.length()).is_equal(500)
	assert_int(violation_captures.size()).is_equal(1)
	assert_str(violation_captures[0]).is_equal("memo_truncated")


# ─── EC-14 — Korean IME composition at cap boundary (skip-stub) ──────────────

func test_ec_14_korean_ime_composition_at_cap_boundary(_do_skip := true, _skip_reason := "deferred: VR-D7 Korean IME composition event handling not implemented") -> void:
	# Blocking dependency: IME composition events (VR-D7 requirement).
	pass


# ─── EC-15 — Memo focus loss mid-IME (skip-stub) ─────────────────────────────

func test_ec_15_memo_focus_loss_mid_ime(_do_skip := true, _skip_reason := "deferred: UI/IME focus-loss commit behavior not implemented") -> void:
	# Blocking dependency: UI/IME focus handling (memo input UI node).
	pass


# ─── EC-16 — Pillar 1: memo_body field injected into chain_data ───────────────

func test_ec_16_pillar1_memo_body_field_injection_rejected() -> void:
	# Arrange — manually construct a poisoned chain_data with memo_text
	# plus all 7 valid fields (making an 8-field node dict)
	var data: WorkspaceData = _make_data()
	var rejection_captures: Array = []
	var cb: Callable = func(reason: String) -> void: rejection_captures.append(reason)
	data.submission_rejected.connect(cb)

	var poisoned_cd: Dictionary = {
		"schema_version": 1,
		"nodes": [
			{
				"node_id": "root-A",
				"label": "test label",
				"parent_id": "",
				"evidence": [],
				"depth": 0,
				"child_count": 0,
				"evidence_count": 0,
				"memo_text": "INJECTED Pillar-1 violation",
			}
		],
		"edges": [],
		"total_evidence_count": 0,
		"max_depth_reached": 0,
		"submission_timestamp_unix": 1747500000,
	}

	# Act
	var result: bool = data.validate_chain_data(poisoned_cd)

	# Assert — cross-link AC-10/AC-52
	data.submission_rejected.disconnect(cb)
	assert_bool(result).is_false()
	assert_int(rejection_captures.size()).is_equal(1)
	assert_str(rejection_captures[0]).is_equal("schema_violation")


# ─── EC-17 — Pillar 1: settings key injected into chain_data ─────────────────

func test_ec_17_pillar1_settings_key_injection_rejected() -> void:
	# Arrange — settings keys are not in ALLOWED_NODE_FIELDS; they must be caught
	var data: WorkspaceData = _make_data()
	var rejection_captures: Array = []
	var cb: Callable = func(reason: String) -> void: rejection_captures.append(reason)
	data.submission_rejected.connect(cb)

	var poisoned_cd: Dictionary = {
		"schema_version": 1,
		"nodes": [
			{
				"node_id": "root-A",
				"label": "test label",
				"parent_id": "",
				"evidence": [],
				"depth": 0,
				"child_count": 0,
				"evidence_count": 0,
				"display.text_scale": 1.0,
			}
		],
		"edges": [],
		"total_evidence_count": 0,
		"max_depth_reached": 0,
		"submission_timestamp_unix": 1747500000,
	}

	# Act
	var result: bool = data.validate_chain_data(poisoned_cd)

	# Assert
	data.submission_rejected.disconnect(cb)
	assert_bool(result).is_false()
	assert_int(rejection_captures.size()).is_equal(1)
	assert_str(rejection_captures[0]).is_equal("schema_violation")


# ─── EC-18 — WorkspaceData reference after case unload (skip-stub) ────────────

func test_ec_18_workspace_data_reference_after_case_unload(_do_skip := true, _skip_reason := "deferred: Case Browser unload lifecycle not implemented") -> void:
	# Blocking dependency: Case Browser scene management + WorkspaceData lifecycle
	# boundary logging (Case Browser epic).
	pass


# ─── EC-19 — Drag while Browser scene swapping (skip-stub) ───────────────────

func test_ec_19_drag_during_browser_scene_swap(_do_skip := true, _skip_reason := "deferred: Case Browser scene transition during drag-drop not implemented") -> void:
	# Blocking dependency: Case Browser scene transitions (Case Browser epic).
	pass


# ─── EC-20 — Auto-resubmit schema_version mismatch → CriticalBanner (skip-stub)

func test_ec_20_auto_resubmit_schema_version_mismatch(_do_skip := true, _skip_reason := "deferred: SaveLoadService (ADR-0011) + UIService.announce_text (story 008) not implemented") -> void:
	# Blocking dependency: SaveLoadService schema_version migration check +
	# UIService.announce_text CriticalBanner (story 008).
	pass


# ─── EC-21 — Camera2D pan clamp (skip-stub) ──────────────────────────────────

func test_ec_21_camera2d_pan_clamp(_do_skip := true, _skip_reason := "deferred: UI camera pan/clamp not implemented") -> void:
	# Blocking dependency: Camera2D pan clamp implementation (UI epic).
	pass


# ─── EC-22 — Gamepad two-step with mid-process transition (skip-stub) ─────────

func test_ec_22_gamepad_two_step_mid_process_transition(_do_skip := true, _skip_reason := "deferred: gamepad two-step citation attach (story 004) not implemented") -> void:
	# Blocking dependency: KB/gamepad two-step pending_citation flow (story 004).
	pass


# ─── EC-23 — Focus loss off-window → restore (skip-stub) ─────────────────────

func test_ec_23_focus_loss_off_window_restore(_do_skip := true, _skip_reason := "deferred: UI focus restoration on window re-focus not implemented") -> void:
	# Blocking dependency: UI focus management (UI epic).
	pass


# ─── EC-24 — Simultaneous SettingsService changes race (skip-stub) ────────────

func test_ec_24_simultaneous_settings_service_race(_do_skip := true, _skip_reason := "deferred: SettingsService not implemented") -> void:
	# Blocking dependency: SettingsService (not yet implemented).
	pass


# ─── AC-52 — Forbidden-field fuzz: 5 ephemeral names ────────────────────────

func test_ac_52_forbidden_ephemeral_field_fuzz_all_5_rejected() -> void:
	# AC-52: each of the 5 forbidden ephemeral field names must individually cause
	# validate_chain_data to return false and emit submission_rejected("schema_violation").
	# Tested in isolation so a failure points to the exact field name.
	var forbidden_fields: Array[String] = [
		"memo_text",
		"chain_data_internal",
		"__debug_payload",
		"evaluator_hint",
		"cached_score",
	]
	for forbidden_field: String in forbidden_fields:
		var data: WorkspaceData = _make_data()
		var rejection_captures: Array = []
		var cb: Callable = func(reason: String) -> void: rejection_captures.append(reason)
		data.submission_rejected.connect(cb)

		# Build a node dict with all 7 valid fields plus the forbidden field
		var poisoned_node: Dictionary = {
			"node_id": "root-X",
			"label": "x",
			"parent_id": "",
			"evidence": [],
			"depth": 0,
			"child_count": 0,
			"evidence_count": 0,
		}
		poisoned_node[forbidden_field] = "INJECTED"
		var cd: Dictionary = {
			"schema_version": 1,
			"nodes": [poisoned_node],
			"edges": [],
			"total_evidence_count": 0,
			"max_depth_reached": 0,
			"submission_timestamp_unix": 1747500000,
		}

		# Act
		var result: bool = data.validate_chain_data(cd)

		# Assert
		data.submission_rejected.disconnect(cb)
		assert_bool(result).is_false()
		assert_int(rejection_captures.size()).is_equal(1)
		assert_str(rejection_captures[0]).is_equal("schema_violation")


# ─── AC-52b — Settings-inclusion fuzz: 5 settings keys ──────────────────────

func test_ac_52b_settings_key_fuzz_all_5_rejected() -> void:
	# AC-52b: settings keys are not in ALLOWED_NODE_FIELDS and must ALL be rejected.
	# These represent Pillar 1 data-isolation: settings state must never enter chain_data.
	var settings_keys: Array[String] = [
		"display.text_scale",
		"display.reduced_motion",
		"display.high_contrast",
		"audio.master_volume",
		"input.gamepad_stick_deadzone",
	]
	for settings_key: String in settings_keys:
		var data: WorkspaceData = _make_data()
		var rejection_captures: Array = []
		var cb: Callable = func(reason: String) -> void: rejection_captures.append(reason)
		data.submission_rejected.connect(cb)

		var poisoned_node: Dictionary = {
			"node_id": "root-S",
			"label": "s",
			"parent_id": "",
			"evidence": [],
			"depth": 0,
			"child_count": 0,
			"evidence_count": 0,
		}
		poisoned_node[settings_key] = "INJECTED_SETTINGS"
		var cd: Dictionary = {
			"schema_version": 1,
			"nodes": [poisoned_node],
			"edges": [],
			"total_evidence_count": 0,
			"max_depth_reached": 0,
			"submission_timestamp_unix": 1747500000,
		}

		# Act
		var result: bool = data.validate_chain_data(cd)

		# Assert
		data.submission_rejected.disconnect(cb)
		assert_bool(result).is_false()
		assert_int(rejection_captures.size()).is_equal(1)
		assert_str(rejection_captures[0]).is_equal("schema_violation")
