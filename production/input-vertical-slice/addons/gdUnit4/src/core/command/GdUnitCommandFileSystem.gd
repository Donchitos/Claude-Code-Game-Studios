@abstract class_name GdUnitCommandFileSystem
extends GdUnitBaseCommand


var _test_session_command: GdUnitCommandTestSession

func _init(p_id: String, p_shortcut: GdUnitShortcut.ShortCut, test_session_command: GdUnitCommandTestSession) -> void:
	super(p_id, p_shortcut)
	_test_session_command = test_session_command


func is_running() -> bool:
	return _test_session_command.is_running()


func execute_tests(paths: PackedStringArray, with_debug: bool) -> void:
	var suite_scaner := GdUnitTestSuiteScanner.new()
	var scripts: Array[Script]

	for resource_path in paths:
		# directories and test-suites are valid to enable the menu
		if DirAccess.dir_exists_absolute(resource_path):
			scripts.append_array(suite_scaner.scan_directory(resource_path))
			continue

		var file_type := resource_path.get_extension()
		if file_type == "gd" or file_type == "cs":
			var script := GdUnitTestSuiteScanner.load_with_disabled_warnings(resource_path)

			if GdUnitTestSuiteScanner.is_test_suite(script):
				scripts.append(script)

	GdUnitSignals.instance().gdunit_event.emit(GdUnitEventTestDiscoverStart.new())
	var tests_to_execute: Array[GdUnitTestCase] = []
	for script in scripts:
		GdUnitTestDiscoverer.discover_tests(script, func(test_case: GdUnitTestCase) -> void:
			tests_to_execute.append(test_case)
			GdUnitTestDiscoverSink.discover(test_case)
		)
	GdUnitSignals.instance().gdunit_event.emit(GdUnitEventTestDiscoverEnd.new(0, 0))
	GdUnitTestDiscoverer.console_log_discover_results(tests_to_execute)
	_test_session_command.execute(tests_to_execute, with_debug)
