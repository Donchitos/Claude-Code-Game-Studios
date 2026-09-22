class_name GdUnitCommandScriptEditorDebugTests
extends GdUnitCommandScriptEditor


const ID := "Debug ScriptEditor Tests"


func _init(test_session_command: GdUnitCommandTestSession) -> void:
	super(ID, GdUnitShortcut.ShortCut.RUN_TESTCASE_DEBUG, test_session_command)
	icon =  GdUnitUiTools.get_icon("PlayStart")


func execute(..._parameters: Array) -> void:
	execute_tests(true)
