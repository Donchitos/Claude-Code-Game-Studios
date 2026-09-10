@warning_ignore_start("unsafe_method_access")
# GdUnit generated TestSuite
extends GdUnitTestSuite


var _handler :GdUnitCommandHandler


func before() -> void:
	_handler = GdUnitCommandHandler.new()


func after() -> void:
	_handler.free()


func test_command_shortcut() -> void:
	assert_str(_handler.command_shortcut(GdUnitCommandInspectorRunTests.ID).get_as_text()).is_equal("Alt+F5")
	assert_str(_handler.command_shortcut(GdUnitCommandInspectorDebugTests.ID).get_as_text()).is_equal("Alt+F6")
	assert_str(_handler.command_shortcut(GdUnitCommandRunTestsOverall.ID).get_as_text()).is_equal("Alt+F7")
	assert_str(_handler.command_shortcut(GdUnitCommandStopTestSession.ID).get_as_text()).is_equal("Alt+F8")
	assert_str(_handler.command_shortcut(GdUnitCommandScriptEditorRunTests.ID).get_as_text()).is_equal("Ctrl+Alt+F5")
	assert_str(_handler.command_shortcut(GdUnitCommandScriptEditorDebugTests.ID).get_as_text()).is_equal("Ctrl+Alt+F6")
	assert_str(_handler.command_shortcut(GdUnitCommandScriptEditorCreateTest.ID).get_as_text()).is_equal("Ctrl+Alt+F10")
	if Engine.get_version_info().hex >= 0x40600:
		assert_str(_handler.command_shortcut(GdUnitCommandFileSystemRunTests.ID).get_as_text()).is_equal("Alt+Shift+F5")
		assert_str(_handler.command_shortcut(GdUnitCommandFileSystemDebugTests.ID).get_as_text()).is_equal("Alt+Shift+F6")
	else:
		assert_str(_handler.command_shortcut(GdUnitCommandFileSystemRunTests.ID).get_as_text()).is_equal("Shift+Alt+F5")
		assert_str(_handler.command_shortcut(GdUnitCommandFileSystemDebugTests.ID).get_as_text()).is_equal("Shift+Alt+F6")


## actually needs to comment out, it produces a lot of leaked instances
func _test__check_test_run_stopped_manually() -> void:
	var inspector :GdUnitCommandHandler = mock(GdUnitCommandHandler, CALL_REAL_FUNC)

	# simulate no test is running
	do_return(false).on(inspector).is_test_running_but_stop_pressed()
	inspector.check_test_run_stopped_manually()
	verify(inspector, 0).cmd_stop(any_int())

	# simulate the test runner was manually stopped by the editor
	do_return(true).on(inspector).is_test_running_but_stop_pressed()
	inspector.check_test_run_stopped_manually()
	verify(inspector, 1).cmd_stop()
