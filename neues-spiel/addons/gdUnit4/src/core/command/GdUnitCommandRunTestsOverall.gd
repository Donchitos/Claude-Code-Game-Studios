class_name GdUnitCommandRunTestsOverall
extends GdUnitBaseCommand

const ID := "Run Tests Overall"


var _test_session_command: GdUnitCommandTestSession


func _init(test_session_command: GdUnitCommandTestSession) -> void:
	super(ID, GdUnitShortcut.ShortCut.RUN_TESTS_OVERALL)
	icon = GdUnitUiTools.get_run_overall_icon()
	_test_session_command = test_session_command


func is_running() -> bool:
	return _test_session_command.is_running()


func execute(..._parameters: Array) -> void:
	var tests_to_execute := await GdUnitTestDiscoverer.run()
	_test_session_command.execute(tests_to_execute, true)
