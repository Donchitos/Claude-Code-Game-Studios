## The test suite main execution stage.[br]
class_name GdUnitTestSuiteExecutionStage
extends IGdUnitExecutionStage

const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")

var _stage_before :IGdUnitExecutionStage = GdUnitTestSuiteBeforeStage.new()
var _stage_after :IGdUnitExecutionStage = GdUnitTestSuiteAfterStage.new()
var _stage_test :IGdUnitExecutionStage = GdUnitTestCaseExecutionStage.new()
var _fail_fast := false


## Executes all tests of an test suite.[br]
## It executes synchronized following stages[br]
##  -> before() [br]
##  -> run all test cases [br]
##  -> after() [br]
func _execute(context :GdUnitExecutionContext) -> void:
	if context.test_suite.__is_skipped:
		await fire_test_suite_skipped(context)
	else:
		@warning_ignore("return_value_discarded")
		GdUnitMemoryObserver.guard_instance(context.test_suite.__awaiter)
		context.save_project_settings()
		await _stage_before.execute(context)
		for test_case_index in context.test_suite.get_child_count():
			# iterate only over test cases
			var test_case := context.test_suite.get_child(test_case_index) as _TestCase
			if not is_instance_valid(test_case):
				continue
			context.test_suite.set_active_test_case(test_case.test_name())
			var test_case_context := GdUnitExecutionContext.of_test_case(context, test_case)
			await _stage_test.execute(test_case_context)
			# stop on first error or if fail fast is enabled
			if test_case.is_terminated() or (_fail_fast and not test_case_context.is_success()):
				break
			if test_case.is_interupted():
				# it needs to go this hard way to kill the outstanding awaits of a test case when the test timed out
				# we delete the current test suite where is execute the current test case to kill the function state
				# and replace it by a clone without function state
				context.test_suite = await clone_test_suite(context.test_suite)
		await _stage_after.execute(context)
		context.restore_project_settings()
		GdUnitMemoryObserver.unguard_instance(context.test_suite.__awaiter)

	await (Engine.get_main_loop() as SceneTree).process_frame


# clones a test suite and moves the test cases to new instance
func clone_test_suite(test_suite :GdUnitTestSuite) -> GdUnitTestSuite:
	await (Engine.get_main_loop() as SceneTree).process_frame
	dispose_timers(test_suite)
	await GdUnitMemoryObserver.gc_guarded_instance("Manually free on awaiter", test_suite.__awaiter)
	var parent := test_suite.get_parent()
	var _test_suite := GdUnitTestSuite.new()
	parent.remove_child(test_suite)
	copy_properties(test_suite, _test_suite)
	for child in test_suite.get_children():
		test_suite.remove_child(child)
		_test_suite.add_child(child)
	parent.add_child(_test_suite)
	@warning_ignore("return_value_discarded")
	GdUnitMemoryObserver.guard_instance(_test_suite.__awaiter)
	# finally free current test suite instance
	test_suite.free()
	await (Engine.get_main_loop() as SceneTree).process_frame
	return _test_suite


func dispose_timers(test_suite :GdUnitTestSuite) -> void:
	GdUnitTools.release_timers()
	for child in test_suite.get_children():
		if child is Timer:
			(child as Timer).stop()
			test_suite.remove_child(child)
			child.free()


func copy_properties(source :Object, target :Object) -> void:
	if not source is _TestCase and not source is GdUnitTestSuite:
		return
	for property in source.get_property_list():
		var property_name :String = property["name"]
		if property_name == "__awaiter":
			continue
		target.set(property_name, source.get(property_name))


func fire_test_suite_skipped(context :GdUnitExecutionContext) -> void:
	var test_suite := context.test_suite
	var skip_count := test_suite.get_child_count()
	fire_event(GdUnitEvent.new()\
		.suite_before(context.get_test_suite_path(), test_suite.get_name(), skip_count))


	for test_case_index in context.test_suite.get_child_count():
			# iterate only over test cases
			var test_case := context.test_suite.get_child(test_case_index) as _TestCase
			if not is_instance_valid(test_case):
				continue
			var test_case_context := GdUnitExecutionContext.of_test_case(context, test_case)
			fire_event(GdUnitEvent.new().test_before(test_case.id()))
			# use skip count 0 because we counted it over the complete test suite
			fire_test_skipped(test_case_context, 0)


	var statistics := {
		GdUnitEvent.ORPHAN_NODES: 0,
		GdUnitEvent.ELAPSED_TIME: 0,
		GdUnitEvent.WARNINGS: false,
		GdUnitEvent.ERRORS: false,
		GdUnitEvent.ERROR_COUNT: 0,
		GdUnitEvent.FAILED: false,
		GdUnitEvent.FAILED_COUNT: 0,
		GdUnitEvent.SKIPPED_COUNT: skip_count,
		GdUnitEvent.SKIPPED: true
	}
	var report := GdUnitReport.new().create(GdUnitReport.SKIPPED, -1, GdAssertMessages.test_suite_skipped(test_suite.__skip_reason, skip_count))
	fire_event(GdUnitEvent.new().suite_after(context.get_test_suite_path(), test_suite.get_name(), statistics, [report]))
	await (Engine.get_main_loop() as SceneTree).process_frame


func fire_test_skipped(context: GdUnitExecutionContext, skip_count := 1) -> void:
	var test_case := context.test_case
	var statistics := {
		GdUnitEvent.ORPHAN_NODES: 0,
		GdUnitEvent.ELAPSED_TIME: 0,
		GdUnitEvent.WARNINGS: false,
		GdUnitEvent.ERRORS: false,
		GdUnitEvent.ERROR_COUNT: 0,
		GdUnitEvent.FAILED: false,
		GdUnitEvent.FAILED_COUNT: 0,
		GdUnitEvent.SKIPPED: true,
		GdUnitEvent.SKIPPED_COUNT: skip_count,
	}
	var report := GdUnitReport.new() \
		.create(GdUnitReport.SKIPPED, test_case.line_number(), GdAssertMessages.test_skipped("Skipped from the entire test suite"))
	fire_event(GdUnitEvent.new().test_after(test_case.id(), test_case.test_name(), statistics, [report]))


func set_debug_mode(debug_mode :bool = false) -> void:
	super.set_debug_mode(debug_mode)
	_stage_before.set_debug_mode(debug_mode)
	_stage_after.set_debug_mode(debug_mode)
	_stage_test.set_debug_mode(debug_mode)


func fail_fast(enabled :bool) -> void:
	_fail_fast = enabled
