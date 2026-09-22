@abstract class_name GdUnitCommandScriptEditor
extends GdUnitBaseCommand

var _test_session_command: GdUnitCommandTestSession

func _init(p_id: String, p_shortcut: GdUnitShortcut.ShortCut, test_session_command: GdUnitCommandTestSession) -> void:
	super(p_id, p_shortcut)
	_test_session_command = test_session_command


func is_running() -> bool:
	return _test_session_command.is_running()


func execute_tests(with_debug: bool) -> void:
	var selected_tests := PackedStringArray()
	if _is_active_script_editor():
		var cursor_line := _active_base_editor().get_caret_line()
		#run test case?
		var regex := RegEx.new()
		@warning_ignore("return_value_discarded")
		regex.compile("(^func[ ,\t])(test_[a-zA-Z0-9_]*)")
		var result := regex.search(_active_base_editor().get_line(cursor_line))
		if result:
			var func_name := result.get_string(2).strip_edges()
			if func_name.begins_with("test_"):
				selected_tests.append(func_name)

	var tests_to_execute := _collect_tests(_active_script(), selected_tests)
	_test_session_command.execute(tests_to_execute, with_debug)


func _collect_tests(script: Script, tests: PackedStringArray) -> Array[GdUnitTestCase]:
	# Update test discovery
	var tests_to_execute: Array[GdUnitTestCase] = []
	GdUnitSignals.instance().gdunit_event.emit(GdUnitEventTestDiscoverStart.new())
	GdUnitTestDiscoverer.discover_tests(script, func(test: GdUnitTestCase) -> void:
		if tests.is_empty() or tests.has(test.test_name):
			tests_to_execute.append(test)
			GdUnitTestDiscoverSink.discover(test)
	)
	GdUnitSignals.instance().gdunit_event.emit(GdUnitEventTestDiscoverEnd.new(0, 0))
	GdUnitTestDiscoverer.console_log_discover_results(tests_to_execute)
	return tests_to_execute


func _is_active_script_editor() -> bool:
	return EditorInterface.get_script_editor().get_current_editor() != null


func _active_base_editor() -> TextEdit:
	return EditorInterface.get_script_editor().get_current_editor().get_base_editor()


func _active_script() -> Script:
	return EditorInterface.get_script_editor().get_current_script()
