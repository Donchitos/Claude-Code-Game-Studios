## anti_pillar_guards_test.gd — SaveLoadService Anti-Pillar serialization guards.
##
## Covers story-007 Acceptance Criteria:
##   AC-12  active_case excludes Settings values (save_load_settings_inclusion) — structural:
##          ActiveCaseSaveData has no Settings fields; Settings persist separately (ADR-0009).
##   AC-13  chain_data with an ephemeral field is rejected by the canonical validator
##          (chain_data_include_ephemeral_field), via _validate_active_case.
##
## Run:
##   addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot \
##     -a tests/unit/save_load/anti_pillar_guards_test.gd
##
## ADR: docs/architecture/adr-0011-save-load-storage-format.md
##      docs/architecture/adr-0008-amend-1-cycle-3-4-closure.md §A6 (ephemeral field ban)
## TR:  TR-save-*
extends GdUnitTestSuite


const _SaveLoadServiceScript: Script = preload("res://src/services/save_load_service.gd")
const _ActiveCaseScript: Script = preload("res://src/data/active_case_save_data.gd")


func _service() -> Node:
	var svc: Node = _SaveLoadServiceScript.new()
	get_tree().root.add_child(svc)
	auto_free(svc)
	return svc


# ─── AC-12 — active_case carries no Settings fields (structural) ──────────────

func test_active_case_save_data_has_no_settings_fields() -> void:
	# Settings keys must never appear in the active-case Resource — they live in a
	# separate user_settings.cfg (ADR-0009 / save_load_settings_inclusion).
	var active: Resource = _ActiveCaseScript.new()
	var settings_prefixes: PackedStringArray = ["display.", "audio.", "input.", "accessibility."]
	for prop: Dictionary in active.get_property_list():
		var name: String = prop["name"]
		for prefix: String in settings_prefixes:
			assert_bool(name.begins_with(prefix)).is_false()


func test_active_case_property_set_is_the_expected_save_fields() -> void:
	# Positive shape: the script-declared @export fields are exactly the save fields.
	var active: Resource = _ActiveCaseScript.new()
	var script_props: PackedStringArray = PackedStringArray()
	for prop: Dictionary in active.get_property_list():
		# Script variables carry PROPERTY_USAGE_SCRIPT_VARIABLE (bit 4096).
		if (int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
			script_props.append(prop["name"])
	assert_bool(script_props.has("save_file_version")).is_true()
	assert_bool(script_props.has("case_id")).is_true()
	assert_bool(script_props.has("workspace_data")).is_true()
	assert_bool(script_props.has("brief_editor_data")).is_true()
	# No settings field leaked into the declared set
	assert_bool(script_props.has("text_scale")).is_false()
	assert_bool(script_props.has("reduced_motion")).is_false()


# ─── AC-13 — ephemeral field in chain_data rejected ───────────────────────────

func test_active_case_with_ephemeral_chain_data_field_rejected() -> void:
	# Arrange — an active case whose workspace_data.chain_data_snapshot carries a
	# forbidden ephemeral field (last_touched_usec) in a node dict.
	var svc: Node = _service()
	var ws := WorkspaceData.new()
	ws.chain_data_snapshot = {
		"schema_version": 1,
		"nodes": [
			{
				"node_id": "n1", "label": "x", "parent_id": "", "evidence": [],
				"depth": 0, "child_count": 0, "evidence_count": 0,
				"last_touched_usec": 123456,   # forbidden ephemeral field (ADR-0008 amend-1 §A6)
			}
		],
		"edges": [], "total_evidence_count": 0, "max_depth_reached": 0,
		"submission_timestamp_unix": 1747500000,
	}
	var active: Resource = _ActiveCaseScript.new()
	active.workspace_data = ws

	var rejections: Array = []
	var cb: Callable = func(reason: String) -> void: rejections.append(reason)
	ws.submission_rejected.connect(cb)

	# Act
	var ok: bool = svc._validate_active_case(active)

	# Assert — rejected via the canonical validator + schema_violation emitted
	ws.submission_rejected.disconnect(cb)
	assert_bool(ok).is_false()
	assert_int(rejections.size()).is_equal(1)
	assert_str(rejections[0]).is_equal("schema_violation")


func test_active_case_with_clean_chain_data_validates() -> void:
	# A clean (allow-listed) chain_data passes.
	var svc: Node = _service()
	var ws := WorkspaceData.new()
	ws.chain_data_snapshot = {
		"schema_version": 1,
		"nodes": [
			{
				"node_id": "n1", "label": "x", "parent_id": "", "evidence": [],
				"depth": 0, "child_count": 0, "evidence_count": 0,
			}
		],
		"edges": [], "total_evidence_count": 0, "max_depth_reached": 0,
		"submission_timestamp_unix": 1747500000,
	}
	var active: Resource = _ActiveCaseScript.new()
	active.workspace_data = ws

	assert_bool(svc._validate_active_case(active)).is_true()


func test_validate_active_case_null_safe() -> void:
	# No active case / no workspace_data → nothing to validate → true.
	var svc: Node = _service()
	assert_bool(svc._validate_active_case(null)).is_true()
	var active: Resource = _ActiveCaseScript.new()  # workspace_data null by default
	assert_bool(svc._validate_active_case(active)).is_true()
