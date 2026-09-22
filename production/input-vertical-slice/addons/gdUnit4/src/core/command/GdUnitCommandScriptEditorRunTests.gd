class_name GdUnitCommandScriptEditorRunTests
extends GdUnitCommandScriptEditor


const ID := "Run ScriptEditor Tests"


func _init(test_session_command: GdUnitCommandTestSession) -> void:
	super(ID, GdUnitShortcut.ShortCut.RUN_TESTCASE, test_session_command)
	icon =  GdUnitUiTools.get_icon("Play")


func execute(..._parameters: Array) -> void:
	execute_tests(false)
