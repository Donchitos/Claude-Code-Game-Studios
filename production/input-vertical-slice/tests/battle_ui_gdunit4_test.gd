extends GdUnitTestSuite

const FocusManifestScript := preload("res://src/directional_focus_manifest.gd")

func test_battle_ui_exposes_eight_meta_rows_and_canonical_focus_manifest() -> void:
	var runner := scene_runner("res://main.tscn")
	await await_idle_frame()
	var scene := runner.scene()
	var battle_ui: BattleUiSlice = scene.battle_ui
	assert_object(battle_ui).is_not_null()
	assert_int(battle_ui.meta_actions.size()).is_equal(8)
	assert_int(battle_ui.meta_buttons.size()).is_equal(8)
	assert_int(battle_ui.directional_focus_manifest.size()).is_equal(8)
	for row in battle_ui.directional_focus_manifest:
		assert_str(row["profile_id"]).is_equal("battle_meta")
		assert_str(row["variant_id"]).is_equal("default")
		assert_str(row["algorithm_version"]).is_equal(FocusManifestScript.ALGORITHM_VERSION)
	assert_that(battle_ui.directional_focus_manifest[0]["right_node_id"]).is_equal("Meta_01")
	assert_that(battle_ui.directional_focus_manifest[1]["left_node_id"]).is_equal("Meta_00")
	assert_that(battle_ui.directional_focus_manifest[0]["left_node_id"]).is_equal(0)

func test_focus_manifest_filters_ineligible_nodes() -> void:
	var nodes: Array[Dictionary] = [
		{"node_id": "a", "center": Vector2(0, 0), "stable_order": 0, "visible": true, "enabled": true, "focusable": true},
		{"node_id": "hidden", "center": Vector2(50, 0), "stable_order": 1, "visible": false, "enabled": true, "focusable": true},
		{"node_id": "b", "center": Vector2(100, 0), "stable_order": 2, "visible": true, "enabled": true, "focusable": true},
	]
	var manifest := FocusManifestScript.build(nodes, "profile", "variant")
	assert_int(manifest.size()).is_equal(2)
	assert_that(manifest[0]["right_node_id"]).is_equal("b")
