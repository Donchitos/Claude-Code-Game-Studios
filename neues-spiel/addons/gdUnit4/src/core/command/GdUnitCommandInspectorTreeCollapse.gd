class_name GdUnitCommandInspectorTreeCollapse
extends GdUnitBaseCommand

const  InspectorTreeMainPanel := preload("res://addons/gdUnit4/src/ui/parts/InspectorTreeMainPanel.gd")
const ID := "Inspector Tree Collapse"


func _init() -> void:
	super(ID, GdUnitShortcut.ShortCut.NONE)
	icon = GdUnitUiTools.get_icon("CollapseTree")


func is_running() -> bool:
	return false


func execute(..._parameters: Array) -> void:
	var inspector: InspectorTreeMainPanel = EditorInterface.get_base_control().get_meta("GdUnit4Inspector")
	var selected_item := inspector._tree.get_selected()
	if selected_item == null:
		selected_item = inspector._tree.get_root()
	else:
		selected_item = selected_item.get_parent()

	inspector.do_collapse_all(false, selected_item)
	inspector.do_collapse_all(true, selected_item)
