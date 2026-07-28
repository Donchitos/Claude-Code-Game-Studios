class_name GdUnitCommandInspectorDebugTests
extends GdUnitBaseCommand

const  InspectorTreeMainPanel := preload("res://addons/gdUnit4/src/ui/parts/InspectorTreeMainPanel.gd")
const ID := "Debug Inspector Tests"


var _test_session_command: GdUnitCommandTestSession


func _init(test_session_command: GdUnitCommandTestSession) -> void:
	super(ID, GdUnitShortcut.ShortCut.RERUN_TESTS_DEBUG)
	icon =  GdUnitUiTools.get_icon("PlayStart")
	_test_session_command = test_session_command


func is_running() -> bool:
	return _test_session_command.is_running()


func execute(..._parameters: Array) -> void:
	var base_control := EditorInterface.get_base_control()
	var inspector: InspectorTreeMainPanel = base_control.get_meta("GdUnit4Inspector")
	var selected_item := inspector._tree.get_selected()
	var tests_to_execute := inspector.collect_test_cases(selected_item)

	_test_session_command.execute(tests_to_execute, true)
