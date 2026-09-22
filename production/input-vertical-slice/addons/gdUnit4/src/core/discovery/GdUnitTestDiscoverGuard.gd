## Guards and tracks test case changes during test discovery and file modifications.[br]
## [br]
## This guard maintains a cache of discovered tests to track changes between test runs and during[br]
## file modifications. It is optimized for performance using simple but effective test identity checks.[br]
## [br]
## Test Change Detection:[br]
## - Moved tests: The test implementation remains at a different line number[br]
## - Renamed tests: The test line position remains but the test name changed[br]
## - Deleted tests: A previously discovered test was removed[br]
## - Added tests: A new test was discovered[br]
## [br]
## Cache Management:[br]
## - Maintains test identity through unique GdUnitTestCase GUIDs[br]
## - Maps source files to their discovered test cases[br]
## - Tracks only essential metadata (line numbers, names) to minimize memory use[br]
## [br]
## Change Detection Strategy:[br]
## The guard uses a lightweight approach by comparing only line numbers and test names.[br]
## This avoids expensive operations like test content parsing or similarity checks.[br]
## [br]
## Event Handling:[br]
## - Emits events on test changes through GdUnitSignals[br]
## - Synchronizes cache with test discovery events[br]
## - Notifies UI about test changes[br]
## [br]
## Example usage:[br]
## [codeblock]
## # Create guard for tracking test changes
## var guard := GdUnitTestDiscoverGuard.new()
##
## # Connect to test discovery events
## GdUnitSignals.instance().gdunit_test_discovered.connect(guard.sync_test_added)
##
## # Discover tests and track changes
## await guard.discover(test_script)
## [/codeblock]
class_name GdUnitTestDiscoverGuard
extends Object



static func instance() -> GdUnitTestDiscoverGuard:
	return GdUnitSingleton.instance("GdUnitTestDiscoverGuard", func() -> GdUnitTestDiscoverGuard:
		return GdUnitTestDiscoverGuard.new()
	)


## Maps source files to their discovered test cases.[br]
## [br]
## Key: Test suite source file path[br]
## Value: Array of [class GdUnitTestCase] instances
var _discover_cache := {}


## Tracks discovered test changes for debug purposes.[br]
## [br]
## Available in debug mode only. Contains dictionaries:[br]
## - changed_tests: Tests that were moved or renamed[br]
## - deleted_tests: Tests that were removed[br]
## - added_tests: New tests that were discovered
var _discovered_changes := {}


## Controls test change debug tracking.[br]
## [br]
## When true, maintains _discovered_changes for debugging.[br]
## Used primarily in tests to verify change detection.
var _is_debug := false


## Creates a new guard instance.[br]
## [br]
## [param is_debug] When true, enables change tracking for debugging.
func _init(is_debug := false) -> void:
	_is_debug = is_debug
	# Register for discovery events to sync the cache
	@warning_ignore("return_value_discarded")
	GdUnitSignals.instance().gdunit_test_discover_added.connect(sync_test_added)
	GdUnitSignals.instance().gdunit_test_discover_deleted.connect(sync_test_deleted)
	GdUnitSignals.instance().gdunit_test_discover_modified.connect(sync_test_modified)
	GdUnitSignals.instance().gdunit_event.connect(handle_discover_events)


## Adds a discovered test to the cache.[br]
## [br]
## [param test_case] The test case to add to the cache.
func sync_test_added(test_case: GdUnitTestCase) -> void:
	var test_cases: Array[GdUnitTestCase] = _discover_cache.get_or_add(test_case.source_file, Array([], TYPE_OBJECT, "RefCounted", GdUnitTestCase))
	test_cases.append(test_case)


## Removes a test from the cache.[br]
## [br]
## [param test_case] The test case to remove from the cache.
func sync_test_deleted(test_case: GdUnitTestCase) -> void:
	var test_cases: Array[GdUnitTestCase] = _discover_cache.get_or_add(test_case.source_file, Array([], TYPE_OBJECT, "RefCounted", GdUnitTestCase))
	test_cases.erase(test_case)


## Updates a test from the cache.[br]
## [br]
## [param test_case] The test case to update from the cache.
func sync_test_modified(changed_test: GdUnitTestCase) -> void:
	var test_cases: Array[GdUnitTestCase] = _discover_cache.get_or_add(changed_test.source_file, Array([], TYPE_OBJECT, "RefCounted", GdUnitTestCase))
	for test in test_cases:
		if test.guid == changed_test.guid:
			test.test_name = changed_test.test_name
			test.display_name = changed_test.display_name
			test.line_number = changed_test.line_number
			break


## Handles test discovery events.[br]
## [br]
## Resets the cache when a new discovery starts.[br]
## [param event] The discovery event to handle.
func handle_discover_events(event: GdUnitEvent) -> void:
	# reset the cache on fresh discovery
	if event.type() == GdUnitEvent.DISCOVER_START:
		_discover_cache = {}


## Registers a callback for discovered tests.[br]
## [br]
## Default sink writes to [class GdUnitTestDiscoverSink].
static func default_discover_sink(test_case: GdUnitTestCase) -> void:
	GdUnitTestDiscoverSink.discover(test_case)


## Finds a test case by its unique identifier.[br]
## [br]
## Searches through all cached test cases across all test suites[br]
## to find a test with the matching GUID.[br]
## [br]
## [param id] The GUID of the test to find[br]
## Returns the matching test case or null if not found.
func find_test_by_id(id: GdUnitGUID) -> GdUnitTestCase:
	for test_sets: Array[GdUnitTestCase] in _discover_cache.values():
		for test in test_sets:
			if test.guid.equals(id):
				return test

	return null


func get_discovered_tests() -> Array[GdUnitTestCase]:
	var discovered_tests: Array[GdUnitTestCase] = []
	for test_sets: Array[GdUnitTestCase] in _discover_cache.values():
		discovered_tests.append_array(test_sets)
	return discovered_tests


## Discovers tests in a script and tracks changes.[br]
## [br]
## Handles both GDScript and C# test suites.[br]
## The guard maintains test identity through changes.[br]
## [br]
## [param script] The test script to analyze[br]
## [param discover_sink] Optional callback for test discovery events
func discover(script: Script, discover_sink: Callable = default_discover_sink) -> void:
	# Verify the script has no errors before run test discovery
	var result := script.reload(true)
	if result != OK:
		return

	if _is_debug:
		_discovered_changes["changed_tests"] = Array([], TYPE_OBJECT, "RefCounted", GdUnitTestCase)
		_discovered_changes["deleted_tests"] = Array([], TYPE_OBJECT, "RefCounted", GdUnitTestCase)
		_discovered_changes["added_tests"] = Array([], TYPE_OBJECT, "RefCounted", GdUnitTestCase)

	if GdUnitTestSuiteScanner.is_test_suite(script):
		# for cs scripts we need to recomplie before discover new tests
		if script.get_class() == "CSharpScript":
			await rebuild_project(script)

		# rediscover all tests
		var source_file := script.resource_path
		var discovered_tests: Array[GdUnitTestCase] = []

		GdUnitTestDiscoverer.discover_tests(script, func(test_case: GdUnitTestCase) -> void:
			discovered_tests.append(test_case)
		)

		# The suite is never discovered, we add all discovered tests
		if not _discover_cache.has(source_file):
			for test_case in discovered_tests:
				discover_sink.call(test_case)
			return

		sync_moved_tests(source_file, discovered_tests)
		sync_renamed_tests(source_file, discovered_tests)
		sync_deleted_tests(source_file, discovered_tests)
		sync_added_tests(source_file, discovered_tests, discover_sink)


## Synchronizes moved tests between discover cycles.[br]
## [br]
## A test is considered moved when:[br]
## - It has the same name[br]
## - But a different line number[br]
## [br]
## [param source_file] suite source path[br]
## [param discovered_tests] Newly discovered tests
func sync_moved_tests(source_file: String, discovered_tests: Array[GdUnitTestCase]) -> void:
	@warning_ignore("unsafe_method_access")
	var cache: Array[GdUnitTestCase] = _discover_cache.get(source_file).duplicate()
	for discovered_test in discovered_tests:
		# lookup in cache
		var original_tests: Array[GdUnitTestCase] = cache.filter(is_test_moved.bind(discovered_test))
		for test in original_tests:
			# update the line_number
			var line_number_before := test.line_number
			test.line_number = discovered_test.line_number
			GdUnitSignals.instance().gdunit_test_discover_modified.emit(test)
			if _is_debug:
				prints("-> moved test id:%s  %s: line:(%d -> %d)" % [test.guid, test.display_name, line_number_before, test.line_number])
				@warning_ignore("unsafe_method_access")
				_discovered_changes.get_or_add("changed_tests", Array([], TYPE_OBJECT, "RefCounted", GdUnitTestCase)).append(test)


## Synchronizes renamed tests between discover cycles.[br]
## [br]
## A test is considered renamed when:[br]
## - It has the same line number[br]
## - But a different name[br]
## [br]
## [param source_file] suite source path[br]
## [param discovered_tests] Newly discovered tests
func sync_renamed_tests(source_file: String, discovered_tests: Array[GdUnitTestCase]) -> void:
	@warning_ignore("unsafe_method_access")
	var cache: Array[GdUnitTestCase] = _discover_cache.get(source_file).duplicate()
	for discovered_test in discovered_tests:
		# lookup in cache
		var original_tests: Array[GdUnitTestCase] = cache.filter(is_test_renamed.bind(discovered_test))
		for test in original_tests:
			# update the renaming names
			var original_display_name := test.display_name
			test.test_name = discovered_test.test_name
			test.display_name = discovered_test.display_name
			GdUnitSignals.instance().gdunit_test_discover_modified.emit(test)
			if _is_debug:
				prints("-> renamed test id:%s  %s -> %s" % [test.guid, original_display_name, test.display_name])
				@warning_ignore("unsafe_method_access")
				_discovered_changes.get_or_add("changed_tests", Array([], TYPE_OBJECT, "RefCounted", GdUnitTestCase)).append(test)


## Synchronizes deleted tests between discover cycles.[br]
## [br]
## A test is considered deleted when:[br]
## - It exists in the cache[br]
## - But is not found in the newly discovered tests[br]
## [br]
## [param source_file] suite source path[br]
## [param discovered_tests] Newly discovered tests
func sync_deleted_tests(source_file: String, discovered_tests: Array[GdUnitTestCase]) -> void:
	@warning_ignore("unsafe_method_access")
	var cache: Array[GdUnitTestCase] = _discover_cache.get(source_file).duplicate()
	# lookup in cache
	for test in cache:
		if not discovered_tests.any(test_equals.bind(test)):
			GdUnitSignals.instance().gdunit_test_discover_deleted.emit(test)
			if _is_debug:
				prints("-> deleted test id:%s  %s:%d" % [test.guid, test.display_name, test.line_number])
				@warning_ignore("unsafe_method_access")
				_discovered_changes.get_or_add("deleted_tests", Array([], TYPE_OBJECT, "RefCounted", GdUnitTestCase)).append(test)


## Synchronizes newly added tests between discover cycles.[br]
## [br]
## A test is considered added when:[br]
## - It exists in the newly discovered tests[br]
## - But is not found in the cache[br]
## [br]
## [param source_file] suite source path[br]
## [param discovered_tests] Newly discovered tests[br]
## [param discover_sink] Callback to handle newly discovered tests
func sync_added_tests(source_file: String, discovered_tests: Array[GdUnitTestCase], discover_sink: Callable) -> void:
	@warning_ignore("unsafe_method_access")
	var cache: Array[GdUnitTestCase] = _discover_cache.get(source_file).duplicate()
	# lookup in cache
	for test in discovered_tests:
		if not cache.any(test_equals.bind(test)):
			discover_sink.call(test)
			if _is_debug:
				prints("-> added test id:%s  %s:%d" % [test.guid, test.display_name, test.line_number])
				@warning_ignore("unsafe_method_access")
				_discovered_changes.get_or_add("added_tests", Array([], TYPE_OBJECT, "RefCounted", GdUnitTestCase)).append(test)


func is_test_renamed(left: GdUnitTestCase, right: GdUnitTestCase) -> bool:
	return left.line_number == right.line_number and left.test_name != right.test_name


func is_test_moved(left: GdUnitTestCase, right: GdUnitTestCase) -> bool:
	return left.line_number != right.line_number and left.test_name == right.test_name


func test_equals(left: GdUnitTestCase, right: GdUnitTestCase) -> bool:
	return left.display_name == right.display_name


# do rebuild the entire project, there is actual no way to enforce the Godot engine itself to do this
func rebuild_project(script: Script) -> void:
	var class_path := ProjectSettings.globalize_path(script.resource_path)
	print_rich("[color=CORNFLOWER_BLUE]GdUnitTestDiscoverGuard: CSharpScript change detected on: '%s' [/color]" % class_path)
	var scene_tree := Engine.get_main_loop() as SceneTree
	await scene_tree.process_frame

	var output := []
	var exit_code := OS.execute("dotnet", ["--version"], output)
	if exit_code == -1:
		print_rich("[color=CORNFLOWER_BLUE]GdUnitTestDiscoverGuard:[/color] [color=RED]Rebuild the project failed.[/color]")
		print_rich("[color=CORNFLOWER_BLUE]GdUnitTestDiscoverGuard:[/color] [color=RED]Can't find installed `dotnet`! Please check your environment is setup correctly.[/color]")
		return

	print_rich("[color=CORNFLOWER_BLUE]GdUnitTestDiscoverGuard:[/color] [color=DEEP_SKY_BLUE]Found dotnet v%s[/color]" % str(output[0]).strip_edges())
	output.clear()

	exit_code = OS.execute("dotnet", ["build"], output)
	print_rich("[color=CORNFLOWER_BLUE]GdUnitTestDiscoverGuard:[/color] [color=DEEP_SKY_BLUE]Rebuild the project ... [/color]")
	for out: String in output:
		print_rich("[color=DEEP_SKY_BLUE] 		%s" % out.strip_edges())
	await scene_tree.process_frame
