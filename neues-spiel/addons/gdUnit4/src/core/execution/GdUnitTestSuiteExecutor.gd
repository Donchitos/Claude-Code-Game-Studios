## The executor to run a test-suite
class_name GdUnitTestSuiteExecutor


# preload all asserts here
@warning_ignore("unused_private_class_variable")
var _assertions := GdUnitAssertions.new()
var _executeStage := GdUnitTestSuiteExecutionStage.new()
var _debug_mode : bool
var _terminated := false

func _init(debug_mode: bool = false) -> void:
	_executeStage.set_debug_mode(debug_mode)
	_debug_mode = debug_mode
	GdUnitSignals.instance().gdunit_test_session_terminate.connect(_on_testsession_terminated)


func _on_testsession_terminated() -> void:
	_terminated = true
	GdUnitThreadManager.interrupt()


func run_and_wait(tests: Array[GdUnitTestCase]) -> void:
	if !_debug_mode:
		GdUnitSignals.instance().gdunit_event.emit(GdUnitInit.new())

	var orphan_detection_enabled := GdUnitSettings.is_verbose_orphans()
	if not orphan_detection_enabled:
		prints("!!! Reporting orphan nodes is disabled. Please check GdUnit settings.")

	# first we group all tests by resource path
	var grouped_by_suites := GdArrayTools.group_by(tests, func(test: GdUnitTestCase) -> String:
		return test.suite_resource_path
	)
	var scanner := GdUnitTestSuiteScanner.new()
	for suite_path: String in grouped_by_suites.keys():
		if _terminated:
			break
		@warning_ignore("unsafe_call_argument")
		var suite_tests: Array[GdUnitTestCase] = Array(grouped_by_suites[suite_path], TYPE_OBJECT, "RefCounted", GdUnitTestCase)
		var script := GdUnitTestSuiteScanner.load_with_disabled_warnings(suite_path)
		if script.get_class() == "GDScript":
			var context := GdUnitExecutionContext.new(suite_path)
			var test_suite := scanner.load_suite(script as GDScript, suite_tests)
			context.test_suite = test_suite
			(Engine.get_main_loop() as SceneTree).root.add_child(test_suite)
			await _executeStage.execute(context)
			context.dispose()
		else:
			await GdUnit4CSharpApiLoader.execute(suite_tests)
	if !_debug_mode:
		GdUnitSignals.instance().gdunit_event.emit(GdUnitStop.new())


func fail_fast(enabled :bool) -> void:
	_executeStage.fail_fast(enabled)
