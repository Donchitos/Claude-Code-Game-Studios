class_name BattleUiSlice
extends Control

const FocusManifestScript := preload("res://src/directional_focus_manifest.gd")

const META_ACTIONS := [
	&"ui_focus_next",
	&"ui_focus_previous",
	&"ui_focus_left",
	&"ui_focus_right",
	&"ui_activate",
	&"ui_back",
	&"ui_increment",
	&"ui_decrement",
]

var meta_actions: Array = META_ACTIONS.duplicate()
var directional_focus_manifest: Array[Dictionary] = []
var meta_buttons: Array[Button] = []

func build() -> void:
	var title := Label.new()
	title.name = "MetaUiTitle"
	title.text = "META UI · 8-row mapped input"
	title.position = Vector2(32.0, 230.0)
	add_child(title)

	var grid := GridContainer.new()
	grid.name = "MetaUiGrid"
	grid.columns = 4
	grid.position = Vector2(32.0, 262.0)
	grid.size = Vector2(520.0, 150.0)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	add_child(grid)

	var nodes: Array[Dictionary] = []
	for index in meta_actions.size():
		var action: StringName = meta_actions[index]
		var button := Button.new()
		button.name = "Meta_%02d" % index
		button.text = String(action).trim_prefix("ui_").replace("_", " ").to_upper()
		button.custom_minimum_size = Vector2(122.0, 42.0)
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		grid.add_child(button)
		meta_buttons.append(button)
		nodes.append({
			"node_id": button.name,
			"center": Vector2((index % 4) * 130.0 + 61.0, (index / 4) * 50.0 + 21.0),
			"stable_order": index,
			"visible": true,
			"enabled": true,
			"focusable": true,
		})

	directional_focus_manifest = FocusManifestScript.build(nodes, "battle_meta", "default")
	for row in directional_focus_manifest:
		var button := get_node("MetaUiGrid/%s" % row["node_id"]) as Button
		if typeof(row["left_node_id"]) != TYPE_INT:
			button.focus_neighbor_left = button.get_path_to(get_node("MetaUiGrid/%s" % row["left_node_id"]))
		if typeof(row["right_node_id"]) != TYPE_INT:
			button.focus_neighbor_right = button.get_path_to(get_node("MetaUiGrid/%s" % row["right_node_id"]))

	print("INPUT_VERTICAL_SLICE_UI_OK meta_rows=%s direction_manifest_rows=%s" % [meta_actions.size(), directional_focus_manifest.size()])
