class_name GdUnitTestDiscoverer
extends RefCounted


static func run() -> Array[GdUnitTestCase]:
	console_log("Running test discovery ..")
	await (Engine.get_main_loop() as SceneTree).process_frame
	GdUnitSignals.instance().gdunit_event.emit(GdUnitEventTestDiscoverStart.new())

	# We run the test discovery in an extra thread so that the main thread is not blocked
	var t:= Thread.new()
	@warning_ignore("return_value_discarded")
	t.start(func () -> Array[GdUnitTestCase]:
		# Loading previous test session
		var runner_config := GdUnitRunnerConfig.new()
		runner_config.load_config()
		var recovered_tests := runner_config.test_cases()
		var test_suite_directories := scan_all_test_directories(GdUnitSettings.test_root_folder())
		var scanner := GdUnitTestSuiteScanner.new()

		var collected_tests: Array[GdUnitTestCase] = []
		var collected_test_suites: Array[Script] = []
		# collect test suites
		for test_suite_dir in test_suite_directories:
			collected_test_suites.append_array(scanner.scan_directory(test_suite_dir))

		# Do sync the main thread before emit the discovered test suites to the inspector
		await (Engine.get_main_loop() as SceneTree).process_frame
		for test_suites_script in collected_test_suites:
			discover_tests(test_suites_script, func(test_case: GdUnitTestCase) -> void:
				# Sync test uid from last test session
				recover_test_guid(test_case, recovered_tests)
				collected_tests.append(test_case)
				GdUnitTestDiscoverSink.discover(test_case)
			)

		console_log_discover_results(collected_tests)
		if !recovered_tests.is_empty():
			console_log("Recovered last test session successfully, %d tests restored." % recovered_tests.size(), true)
		return collected_tests
	)
	# wait unblocked to the tread is finished
	while t.is_alive():
		await (Engine.get_main_loop() as SceneTree).process_frame
	# needs finally to wait for finish
	var test_to_execute: Array[GdUnitTestCase] = await t.wait_to_finish()
	GdUnitSignals.instance().gdunit_event.emit(GdUnitEventTestDiscoverEnd.new(0, 0))
	return test_to_execute


## Restores the last test run session by loading the test run config file and rediscover the tests
static func restore_last_session() -> void:
	if GdUnitSettings.is_test_discover_enabled():
		return

	var runner_config := GdUnitRunnerConfig.new()
	var result := runner_config.load_config()
	# Report possible config loading errors
	if result.is_error():
		console_log("Recovery of the last test session failed: %s" % result.error_message(), true)
	# If no config file found, skip test recovery
	if result.is_warn():
		return

	# If no tests recorded, skip test recovery
	var test_cases := runner_config.test_cases()
	if test_cases.size() == 0:
		return

	# We run the test session restoring in an extra thread so that the main thread is not blocked
	var t:= Thread.new()
	t.start(func () -> void:
		# Do sync the main thread before emit the discovered test suites to the inspector
		await (Engine.get_main_loop() as SceneTree).process_frame
		console_log("Recovering last test session ..", true)
		GdUnitSignals.instance().gdunit_event.emit(GdUnitEventTestDiscoverStart.new())
		for test_case in test_cases:
			GdUnitTestDiscoverSink.discover(test_case)
		GdUnitSignals.instance().gdunit_event.emit(GdUnitEventTestDiscoverEnd.new(0, 0))
		console_log("Recovered last test session successfully, %d tests restored." % test_cases.size(), true)
	)
	t.wait_to_finish()


static func recover_test_guid(current: GdUnitTestCase, recovered_tests: Array[GdUnitTestCase]) -> void:
	for recovered_test in recovered_tests:
		if recovered_test.fully_qualified_name == current.fully_qualified_name:
			current.guid = recovered_test.guid


static func console_log_discover_results(tests: Array[GdUnitTestCase]) -> void:
	var grouped_by_suites := GdArrayTools.group_by(tests, func(test: GdUnitTestCase) -> String:
		return test.source_file
	)
	for suite_tests: Array in grouped_by_suites.values():
		var test_case: GdUnitTestCase = suite_tests[0]
		console_log("Discover: TestSuite %s with %d tests found" % [test_case.source_file, suite_tests.size()])
	console_log("Discover tests done, %d TestSuites and total %d Tests found. " % [grouped_by_suites.size(), tests.size()])
	console_log("")


static func console_log(message: String, on_console := false) -> void:
	prints(message)
	if on_console:
		GdUnitSignals.instance().gdunit_message.emit(message)


static func filter_tests(method: Dictionary) -> bool:
	var method_name: String = method["name"]
	return method_name.begins_with("test_")


static func default_discover_sink(test_case: GdUnitTestCase) -> void:
	GdUnitTestDiscoverSink.discover(test_case)


static func discover_tests(source_script: Script, discover_sink := default_discover_sink) -> void:
	if source_script is GDScript:
		var test_names := source_script.get_script_method_list()\
			.filter(filter_tests)\
			.map(func(method: Dictionary) -> String: return method["name"])
		# no tests discovered?
		if test_names.is_empty():
			return

		var parser := GdScriptParser.new()
		var fds := parser.get_function_descriptors(source_script as GDScript, test_names)
		for fd in fds:
			var resolver := GdFunctionParameterSetResolver.new(fd)
			for test_case in resolver.resolve_test_cases(source_script as GDScript):
				discover_sink.call(test_case)
	elif source_script.get_class() == "CSharpScript":
		if not GdUnit4CSharpApiLoader.is_api_loaded():
			return
		for test_case in GdUnit4CSharpApiLoader.discover_tests(source_script):
			discover_sink.call(test_case)


static func scan_all_test_directories(root: String) -> PackedStringArray:
	var base_directory := "res://"
	# If the test root folder is configured as blank, "/", or "res://", use the root folder as described in the settings panel
	if root.is_empty() or root == "/" or root == base_directory:
		return [base_directory]
	return scan_test_directories(base_directory, root, [])


static func scan_test_directories(base_directory: String, test_directory: String, test_suite_paths: PackedStringArray) -> PackedStringArray:
	print_verbose("Scannning for test directory '%s' at %s" % [test_directory, base_directory])
	for directory in DirAccess.get_directories_at(base_directory):
		if directory.begins_with("."):
			continue
		var current_directory := normalize_path(base_directory + "/" + directory)
		if FileAccess.file_exists(current_directory + "/.gdignore"):
			continue
		if GdUnitTestSuiteScanner.exclude_scan_directories.has(current_directory):
			continue
		if match_test_directory(directory, test_directory):
			@warning_ignore("return_value_discarded")
			test_suite_paths.append(current_directory)
		else:
			@warning_ignore("return_value_discarded")
			scan_test_directories(current_directory, test_directory, test_suite_paths)
	return test_suite_paths


static func normalize_path(path: String) -> String:
	return path.replace("///", "//")


static func match_test_directory(directory: String, test_directory: String) -> bool:
	return directory == test_directory or test_directory.is_empty() or test_directory == "/" or test_directory == "res://"
