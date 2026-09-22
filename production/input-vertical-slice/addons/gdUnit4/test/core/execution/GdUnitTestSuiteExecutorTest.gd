# GdUnit generated TestSuite
class_name GdUnitTestSuiteExecutorTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/execution/GdUnitTestSuiteExecutor.gd'
const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")


const SUCCEEDED = true
const FAILED = false
const SKIPPED = true
const NOT_SKIPPED = false
const FLAKY = true
const FAILURES = true
const NO_FAILURES = false
const ERRORS = true
const NO_ERRORS = false
const WARNINGS = true
const NO_WARNING = false

var _collected_events: Array[GdUnitEvent] = []
func before() -> void:
	GdUnitSignals.instance().gdunit_event_debug.connect(_on_gdunit_event_debug)
	# we run without flaky check
	ProjectSettings.set_setting(GdUnitSettings.TEST_FLAKY_CHECK, false)


func after() -> void:
	GdUnitSignals.instance().gdunit_event_debug.disconnect(_on_gdunit_event_debug)


func after_test() -> void:
	_collected_events.clear()


func _on_gdunit_event_debug(event :GdUnitEvent) -> void:
	_collected_events.append(event)


func flating_message(message :String) -> String:
	return GdUnitTools.richtext_normalize(message)


func run_tests(tests :Array[GdUnitTestCase], settings := {}) -> Array[GdUnitEvent]:
	# run in a separate context to not affect the current test run
	await GdUnitThreadManager.run("test_executor_%d" % randi(), func() -> void:
		var executor := GdUnitTestSuiteExecutor.new(true)

		# apply custom run settints
		var saves_settings := {}
		for key: String in settings.keys():
			saves_settings[key] =  ProjectSettings.get_setting(key)
			ProjectSettings.set_setting(key, settings[key])

		# sync to main thread
		await get_tree().process_frame
		# execute all tests
		await executor.run_and_wait(tests)

		# restore settings
		for key: String in saves_settings.keys():
			ProjectSettings.set_setting(key, saves_settings[key])

	)
	return _collected_events


func assert_event_list(events :Array[GdUnitEvent], suite_name :String, test_case_names :Array[String]) -> void:
	var expected_events := Array()
	expected_events.append(tuple(GdUnitEvent.TESTSUITE_BEFORE, suite_name, any_class(GdUnitGUID), test_case_names.size()))
	for test_case in test_case_names:
		expected_events.append(tuple(GdUnitEvent.TESTCASE_BEFORE, suite_name, test_case, 0))
		expected_events.append(tuple(GdUnitEvent.TESTCASE_AFTER, suite_name, test_case, 0))
	expected_events.append(tuple(GdUnitEvent.TESTSUITE_AFTER, suite_name, any_class(GdUnitGUID), 0))

	# the suite hooks 2 + (test hocks 2 * test count)
	var expected_event_count := 2 + test_case_names.size() * 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	assert_array(events)\
		.extractv(extr("type"), extr("suite_name"), extr("test_name"), extr("total_count"))\
		.contains_exactly(expected_events)


func assert_test_counters(events :Array[GdUnitEvent]) -> GdUnitArrayAssert:
	var _events := events.filter(func(event: GdUnitEvent) -> bool:
		return event.type() in [GdUnitEvent.TESTSUITE_BEFORE, GdUnitEvent.TESTSUITE_AFTER, GdUnitEvent.TESTCASE_BEFORE, GdUnitEvent.TESTCASE_AFTER]
	)
	return assert_array(_events).extractv(extr("guid"), extr("type"), extr("error_count"), extr("failed_count"), extr("orphan_nodes"))


func assert_event_states(events :Array[GdUnitEvent]) -> GdUnitArrayAssert:
	var _events := events.filter(func(event: GdUnitEvent) -> bool:
		return event.type() in [GdUnitEvent.TESTSUITE_BEFORE, GdUnitEvent.TESTSUITE_AFTER, GdUnitEvent.TESTCASE_BEFORE, GdUnitEvent.TESTCASE_AFTER]
	)
	return assert_array(_events).extractv(extr("guid"), extr("is_success"), extr("is_skipped"), extr("is_warning"), extr("is_failed"), extr("is_error"))


@warning_ignore("unsafe_method_access", "unsafe_cast")
func assert_event_reports(events: Array[GdUnitEvent], expected_reports: Array) -> void:
	var _events: Array[GdUnitEvent] = events
	for event_index in _events.size():
		var event := _events[event_index]
		var current: Array[GdUnitReport] = event.reports()
		var expected: Array = expected_reports[event_index] if expected_reports.size() > event_index else []
		if expected.is_empty():
			for m in current.size():
				assert_str(flating_message(current[m].message() as String)).is_empty()
		for m in expected.size():
			if m < current.size():
				assert_str(flating_message(current[m].message() as String)).append_failure_message(event.test_name()).starts_with(str(expected[m]))
			else:
				assert_str("<N/A>").is_equal(expected[m])


func test_execute_success() -> void:
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteAllStagesSuccess.resource")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_case1: GdUnitTestCase = tests["test_case1"]
	var test_case2: GdUnitTestCase = tests["test_case2"]
	# simulate test suite execution
	var events := await run_tests(all_tests)

	# (before_test+after_test) * test count + before+after hooks
	var expected_event_count := tests.size() * 2 + 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	# verify all counters are zero / no errors, failures, orphans
	assert_test_counters(events).contains_exactly([
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_AFTER, 0, 0, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_AFTER, 0, 0, 0),
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_AFTER, 0, 0, 0),
	])
	# all tests passses
	assert_event_states(events).contains_exactly([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		# suite succeeds
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
	])
	# all success no reports expected
	assert_event_reports(events, [
			[], [], [], [], [], []
		])


func test_execute_failure_on_stage_before() -> void:
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteFailOnStageBefore.resource")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_case1: GdUnitTestCase = tests["test_case1"]
	var test_case2: GdUnitTestCase = tests["test_case2"]
	# simulate test suite execution
	var events := await run_tests(all_tests)

	# (before_test+after_test) * test count + before+after hooks
	var expected_event_count := tests.size() * 2 + 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	# we expect the testsuite is failing on stage 'before()' and commits one failure
	# reported finally at TESTSUITE_AFTER event
	assert_test_counters(events).contains_exactly([
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_AFTER, 0, 0, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_AFTER, 0, 0, 0),
		# report failure failed_count = 1
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_AFTER, 0, 1, 0),
	])
	assert_event_states(events).contains_exactly([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		# report suite is not success, is failed
		tuple(any_class(GdUnitGUID), FAILED, NOT_SKIPPED, NO_WARNING, FAILURES, NO_ERRORS),
	])
	# one failure at before()
	assert_event_reports(events, [
			[],
			[],
			[],
			[],
			[],
			["failed on before()"]
		])


func test_execute_failure_on_stage_after() -> void:
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteFailOnStageAfter.resource")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_case1: GdUnitTestCase = tests["test_case1"]
	var test_case2: GdUnitTestCase = tests["test_case2"]
	# simulate test suite execution
	var events := await run_tests(all_tests)

	# (before_test+after_test) * test count + before+after hooks
	var expected_event_count := tests.size() * 2 + 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	# we expect the testsuite is failing on stage 'after()' and commits one failure
	# reported finally at TESTSUITE_AFTER event
	assert_test_counters(events).contains_exactly([
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_AFTER, 0, 0, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_AFTER, 0, 0, 0),
		# report failure failed_count = 1
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_AFTER, 0, 1, 0),
	])
	# all tests passses
	assert_event_states(events).contains_exactly([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		# report suite faile on hook after()
		tuple(any_class(GdUnitGUID), FAILED, NOT_SKIPPED, NO_WARNING, FAILURES, NO_ERRORS),
	])
	# one failure at after()
	assert_event_reports(events, [
			[],
			[],
			[],
			[],
			[],
			["failed on after()"]
		])


func test_execute_failure_on_stage_before_test() -> void:
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteFailOnStageBeforeTest.resource")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_case1: GdUnitTestCase = tests["test_case1"]
	var test_case2: GdUnitTestCase = tests["test_case2"]
	# simulate test suite execution
	var events := await run_tests(all_tests)

	# (before_test+after_test) * test count + before+after hooks
	var expected_event_count := tests.size() * 2 + 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	# we expect the testsuite is failing on stage 'before_test()' and commits one failure on each test case
	# because is in scope of test execution
	assert_test_counters(events).contains_exactly([
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		# failure is count to the test
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_AFTER, 0, 1, 0),
		# failure is count to the test
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_AFTER, 0, 1, 0),
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_AFTER, 0, 0, 0),
	])
	# each test must be failed because of the failure on before_test() hook
	assert_event_states(events).contains_exactly([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, FAILED, NOT_SKIPPED, NO_WARNING, FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, FAILED, NOT_SKIPPED, NO_WARNING, FAILURES, NO_ERRORS),
		# report suite succeeds, no failures on suite hooks
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
	])
	# before_test() failure report is append to each test
	assert_event_reports(events, [
			[],
			[],
			# verify failure report is append to 'test_case1'
			["failed on before_test()"],
			[],
			# verify failure report is append to 'test_case2'
			["failed on before_test()"],
			[]
		])


func test_execute_failure_on_stage_after_test() -> void:
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteFailOnStageAfterTest.resource")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_case1: GdUnitTestCase = tests["test_case1"]
	var test_case2: GdUnitTestCase = tests["test_case2"]
	# simulate test suite execution
	var events := await run_tests(all_tests)

	# (before_test+after_test) * test count + before+after hooks
	var expected_event_count := tests.size() * 2 + 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	# we expect the testsuite is failing on stage 'after_test()' and commits one failure on each test case
	# because is in scope of test execution
	assert_test_counters(events).contains_exactly([
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		# failure is count to the test
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_AFTER, 0, 1, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		# failure is count to the test
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_AFTER, 0, 1, 0),
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_AFTER, 0, 0, 0),
	])
	# each test must be failed because of the failure on after_test() hook
	assert_event_states(events).contains_exactly([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, FAILED, NOT_SKIPPED, NO_WARNING, FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, FAILED, NOT_SKIPPED, NO_WARNING, FAILURES, NO_ERRORS),
		# report suite succeeds, no failures on suite hooks
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
	])

	# 'after_test' failure report is append to each test
	assert_event_reports(events, [
			[],
			[],
			# verify failure report is append to 'test_case1'
			["failed on after_test()"],
			[],
			# verify failure report is append to 'test_case2'
			["failed on after_test()"],
			[]
		])


func test_execute_failure_on_stage_test_case1() -> void:
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteFailOnStageTestCase1.resource")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_case1: GdUnitTestCase = tests["test_case1"]
	var test_case2: GdUnitTestCase = tests["test_case2"]
	# simulate test suite execution
	var events := await run_tests(all_tests)

	# (before_test+after_test) * test count + before+after hooks
	var expected_event_count := tests.size() * 2 + 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	# we expect the test case 'test_case1' is failing and commits one failure
	assert_test_counters(events).contains_exactly([
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		# test has one failure
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_AFTER, 0, 1, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_AFTER, 0, 0, 0),
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_AFTER, 0, 0, 0),
	])
	# test_case1 is failing only
	assert_event_states(events).contains_exactly([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, FAILED, NOT_SKIPPED, NO_WARNING, FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		# report suite succeeds, no failures on the suite hooks
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
	])
	# only 'test_case1' reports a failure
	assert_event_reports(events, [
			[],
			[],
			# verify failure report is append to 'test_case1'
			["failed on test_case1()"],
			[],
			[],
			[]
		])


func test_execute_failure_on_multiple_stages() -> void:
	# this is a more complex failure state, we expect to find multipe failures on different stages
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteFailOnMultipeStages.resource")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_case1: GdUnitTestCase = tests["test_case1"]
	var test_case2: GdUnitTestCase = tests["test_case2"]
	# simulate test suite execution
	var events := await run_tests(all_tests)

	# (before_test+after_test) * test count + before+after hooks
	var expected_event_count := tests.size() * 2 + 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	# we expect failing on multiple stages
	assert_test_counters(events).contains_exactly([
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		# the first test has two failures plus one from 'before_test'
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_AFTER, 0, 3, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		# the second test has no failures but one from 'before_test'
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_AFTER, 0, 1, 0),
		# and one failure is on stage 'after' found
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_AFTER, 0, 1, 0),
	])
	# each test is failing in addition to failing test hooks
	assert_event_states(events).contains_exactly([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, FAILED, NOT_SKIPPED, NO_WARNING, FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, FAILED, NOT_SKIPPED, NO_WARNING, FAILURES, NO_ERRORS),
		# report suite is not success, is failed on after() hook
		tuple(any_class(GdUnitGUID), FAILED, NOT_SKIPPED, NO_WARNING, FAILURES, NO_ERRORS),
	])
	# only 'test_case1' reports a 'real' failures plus test setup stage failures
	assert_event_reports(events, [
			[],
			[],
			# verify failure reports to 'test_case1'
			["failed on before_test()", "failed 1 on test_case1()", "failed 2 on test_case1()"],
			[],
			# verify failure reports to 'test_case2'
			["failed on before_test()"],
			# and one failure detected at stage 'after'
			["failed on after()"]
		])


# GD-63
func test_execute_failure_and_orphans() -> void:
	# this is a more complex failure state, we expect to find multipe orphans on different stages
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/execution/resources/orphans/TestSuiteFailAndOrpahnsDetected.gd")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_case1: GdUnitTestCase = tests["test_case1"]
	var test_case2: GdUnitTestCase = tests["test_case2"]
	# simulate test suite execution
	var events := await run_tests(all_tests)

	# (before_test+after_test) * test count + before+after hooks
	var expected_event_count := tests.size() * 2 + 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	# we expect failing on multiple stages
	assert_test_counters(events).contains_exactly([
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		# the first test ends with a warning and in summ 5 orphans detected
		# 2 from stage 'before_test' + 3 from test itself
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_AFTER, 0, 0, 5),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		# the second test ends with a one failure and in summ 6 orphans detected
		# 2 from stage 'before_test' + 4 from test itself
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_AFTER, 0, 1, 6),
		# and one orphan detected from stage 'before'
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_AFTER, 0, 0, 1),
	])
	# is_success, is_warning, is_failed, is_error
	assert_event_states(events).contains_exactly([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		# test case succeeds with warnings
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, WARNINGS, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		# test case has failures and warnings
		tuple(test_case2.guid, FAILED, NOT_SKIPPED, WARNINGS, FAILURES, NO_ERRORS),
		# report suite is success but orphan warnings and failures
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, WARNINGS, NO_FAILURES, NO_ERRORS),
	])
	# only 'test_case1' reports a 'real' failures plus test setup stage failures
	assert_event_reports(events, [
			[],
			[],
			# ends with warnings
			["WARNING: Detected 2 possible orphan nodes.",
			 "WARNING: Detected 3 orphan nodes."],
			[],
			# ends with failure and warnings
			["WARNING: Detected 2 possible orphan nodes.",
			 "fail on test_case2()"],
			# and one warning detected at stage 'after'
			["WARNING: Detected 1 possible orphan nodes."]
		])


func test_execute_failure_and_orphans_report_orphan_disabled() -> void:
	# this is a more complex failure state, we expect to find multipe orphans on different stages
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/execution/resources/orphans/TestSuiteFailAndOrpahnsDetected.gd")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_case1: GdUnitTestCase = tests["test_case1"]
	var test_case2: GdUnitTestCase = tests["test_case2"]

	# simulate test suite execution whit disabled orphan detection
	var events := await run_tests(all_tests, {
		GdUnitSettings.REPORT_ORPHANS: false
	})

	# (before_test+after_test) * test count + before+after hooks
	var expected_event_count := tests.size() * 2 + 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	# we expect failing on multiple stages, no orphans reported
	assert_test_counters(events).contains_exactly([
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_AFTER, 0, 0, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		# one failure
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_AFTER, 0, 1, 0),
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_AFTER, 0, 0, 0),
	])
	# is_success, is_warning, is_failed, is_error
	assert_event_states(events).contains_exactly([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		# test case has success
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		# test case has a failure
		tuple(test_case2.guid, FAILED, NOT_SKIPPED, NO_WARNING, FAILURES, NO_ERRORS),
		# report suite succeeds with warnings and failures
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
	])
	# only 'test_case1' reports a failure, orphans are not reported
	assert_event_reports(events, [
			[],
			[],
			[],
			[],
			# ends with a failure
			["fail on test_case2()"],
			[]
		])


# GD-1291
func test_execute_success_with_pending_queue_free_nodes() -> void:
	# nodes released with queue_free() during a test are freed one frame later and must not be reported as orphans
	var tests := GdUnitTestResourceLoader.load_tests(
		"res://addons/gdUnit4/test/core/execution/resources/orphans/TestSuiteWithPendingQueueFreeNodes.gd")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_case1: GdUnitTestCase = tests["test_removes_and_queues_children_for_free"]
	# simulate test suite execution
	var events := await run_tests(all_tests)

	# (before_test+after_test) * test count + before+after hooks
	var expected_event_count := tests.size() * 2 + 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	# verify all counters are zero / no errors, failures, orphans
	assert_test_counters(events).contains_exactly([
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_AFTER, 0, 0, 0),
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_AFTER, 0, 0, 0),
	])
	# all tests passses
	assert_event_states(events).contains_exactly([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
	])
	# all success no reports expected
	assert_event_reports(events, [
			[], [], [], []
		])


func test_execute_error_on_test_timeout() -> void:
	# this tests a timeout on a test case reported as error
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteErrorOnTestTimeout.resource")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_case1: GdUnitTestCase = tests["test_case1"]
	var test_case2: GdUnitTestCase = tests["test_case2"]
	# simulate test suite execution
	var events := await run_tests(all_tests)

	# (before_test+after_test) * test count + before+after hooks
	var expected_event_count := tests.size() * 2 + 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	# we expect test_case1 fails by a timeout
	assert_test_counters(events).contains_exactly([
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_BEFORE, 0, 0, 0),
		# the first test timed out after 2s
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_AFTER, 1, 0, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_AFTER, 0, 0, 0),
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_AFTER, 0, 0, 0),
	])
	# test_case1 is interrupted by a timeout and fails
	assert_event_states(events).contains_exactly([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		# testcase ends with a timeout error
		tuple(test_case1.guid, FAILED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		# report suite has no failures and errors
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
	])
	# 'test_case1' reports a error triggered by test timeout
	assert_event_reports(events, [
			[],
			[],
			# verify error reports to 'test_case1'
			["Timeout !\n 'Test timed out after 2s 0ms'"],
			[],
			[],
			[]
		])


# This test checks if all test stages are called at each test iteration.
func test_execute_fuzzed_metrics() -> void:
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteFuzzedMetricsTest.gd")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)

	# simulate test suite execution
	var events := await run_tests(all_tests)
	assert_event_states(events).contains([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
	])
	assert_event_reports(events, [
			[],
			[],
			[],
			[],
			[],
			[]
		])


# This test checks if all test stages are called at each test iteration.
func test_execute_parameterized_metrics() -> void:
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteParameterizedMetricsTest.gd")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)

	# simulate test suite execution
	var events := await run_tests(all_tests)
	assert_event_states(events).contains([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
	])
	assert_event_reports(events, [
			[],
			[],
			[],
			[],
			[],
			[]
		])


func test_execute_failure_fuzzer_iteration() -> void:
	# this tests a timeout on a test case reported as error
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/GdUnitFuzzerTest.resource")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_multi_yielding_with_fuzzer: GdUnitTestCase = tests["test_multi_yielding_with_fuzzer"]
	var test_multi_yielding_with_fuzzer_fail_after_3_iterations: GdUnitTestCase = tests["test_multi_yielding_with_fuzzer_fail_after_3_iterations"]
	# simulate test suite execution
	var events := await run_tests(all_tests)

	# (before_test+after_test) * test count + before+after hooks
	var expected_event_count := tests.size() * 2 + 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	# we expect failing at 'test_multi_yielding_with_fuzzer_fail_after_3_iterations' after three iterations
	assert_test_counters(events).contains_exactly([
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_BEFORE, 0, 0, 0),
		tuple(test_multi_yielding_with_fuzzer.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		tuple(test_multi_yielding_with_fuzzer.guid, GdUnitEvent.TESTCASE_AFTER, 0, 0, 0),
		tuple(test_multi_yielding_with_fuzzer_fail_after_3_iterations.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		# test failed after 3 iterations
		tuple(test_multi_yielding_with_fuzzer_fail_after_3_iterations.guid, GdUnitEvent.TESTCASE_AFTER, 0, 1, 0),
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_AFTER, 0, 0, 0),
	])
	# is_success, is_warning, is_failed, is_error
	assert_event_states(events).contains_exactly([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_multi_yielding_with_fuzzer.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_multi_yielding_with_fuzzer.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_multi_yielding_with_fuzzer_fail_after_3_iterations.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_multi_yielding_with_fuzzer_fail_after_3_iterations.guid, FAILED, NOT_SKIPPED, NO_WARNING, FAILURES, NO_ERRORS),
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS)
	])
	# 'test_case1' reports a error triggered by test timeout
	assert_event_reports(events, [
			[],
			[],
			[],
			[],
			# must fail after three iterations
			["Found an error after 3 test iterations\n Expecting: 'false' but is 'true'"],
			[]
		])


func test_execute_add_child_on_before_GD_106() -> void:
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteFailAddChildStageBefore.resource")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_case1: GdUnitTestCase = tests["test_case1"]
	var test_case2: GdUnitTestCase = tests["test_case2"]
	# simulate test suite execution
	var events := await run_tests(all_tests)

	# (before_test+after_test) * test count + before+after hooks
	var expected_event_count := tests.size() * 2 + 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	# verify all counters are zero / no errors, failures, orphans
	assert_test_counters(events).contains_exactly([
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		tuple(test_case1.guid, GdUnitEvent.TESTCASE_AFTER, 0, 0, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_BEFORE, 0, 0, 0),
		tuple(test_case2.guid, GdUnitEvent.TESTCASE_AFTER, 0, 0, 0),
		tuple(any_class(GdUnitGUID), GdUnitEvent.TESTSUITE_AFTER, 0, 0, 0),
	])
	assert_event_states(events).contains_exactly([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
	])
	# all success no reports expected
	assert_event_reports(events, [
			[], [], [], [], [], []
		])


func test_execute_parameterizied_tests() -> void:
	# this is a more complex failure state, we expect to find multipe failures on different stages
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteParameterizedTests.resource")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_0: GdUnitTestCase = find_test(tests, "test_dictionary_div_number_types:0")
	var test_1: GdUnitTestCase = find_test(tests, "test_dictionary_div_number_types:1")
	var test_2: GdUnitTestCase = find_test(tests, "test_dictionary_div_number_types:2")
	var test_3: GdUnitTestCase = find_test(tests, "test_dictionary_div_number_types:3")

	# simulate test suite execution
	# run the tests with to compare type save
	var original_mode :Variant = ProjectSettings.get_setting(GdUnitSettings.REPORT_ASSERT_STRICT_NUMBER_TYPE_COMPARE)
	ProjectSettings.set_setting(GdUnitSettings.REPORT_ASSERT_STRICT_NUMBER_TYPE_COMPARE, true)
	var events := await run_tests(all_tests, {
		GdUnitSettings.REPORT_ASSERT_STRICT_NUMBER_TYPE_COMPARE : true
	})
	# the test is partial failing because of diverent type in the dictionary
	assert_array(events).extractv(
		extr("type"), extr("guid"), extr("is_warning"), extr("is_error"), extr("is_failed"), extr("orphan_nodes"))\
		.contains([
			tuple(GdUnitEvent.TESTCASE_AFTER, test_0.guid, NO_WARNING, NO_ERRORS, FAILURES, 0),
			tuple(GdUnitEvent.TESTCASE_AFTER, test_1.guid, NO_WARNING, NO_ERRORS, NO_FAILURES, 0),
			tuple(GdUnitEvent.TESTCASE_AFTER, test_2.guid, NO_WARNING, NO_ERRORS, FAILURES, 0),
			tuple(GdUnitEvent.TESTCASE_AFTER, test_3.guid, NO_WARNING, NO_ERRORS, NO_FAILURES, 0)
		])

	# rerun the same tests again with allow to compare type unsave
	ProjectSettings.set_setting(GdUnitSettings.REPORT_ASSERT_STRICT_NUMBER_TYPE_COMPARE, false)
	# simulate test suite execution
	events = await run_tests(all_tests)
	ProjectSettings.set_setting(GdUnitSettings.REPORT_ASSERT_STRICT_NUMBER_TYPE_COMPARE, original_mode)

	# the test should now be successful
	assert_array(events).extractv(
		extr("type"), extr("guid"), extr("is_warning"), extr("is_error"), extr("is_failed"), extr("orphan_nodes"))\
		.contains([
			tuple(GdUnitEvent.TESTCASE_AFTER, test_0.guid, NO_WARNING, NO_ERRORS, NO_FAILURES, 0),
			tuple(GdUnitEvent.TESTCASE_AFTER, test_1.guid, NO_WARNING, NO_ERRORS, NO_FAILURES, 0),
			tuple(GdUnitEvent.TESTCASE_AFTER, test_2.guid, NO_WARNING, NO_ERRORS, NO_FAILURES, 0),
			tuple(GdUnitEvent.TESTCASE_AFTER, test_3.guid, NO_WARNING, NO_ERRORS, NO_FAILURES, 0)
		])


func test_execute_test_suite_is_skipped() -> void:
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteSkipped.resource")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_case1: GdUnitTestCase = tests["test_case1"]
	var test_case2: GdUnitTestCase = tests["test_case2"]
	# simulate test suite execution
	var events := await run_tests(all_tests)

	# (before_test+after_test) * test count + before+after hooks
	var expected_event_count := tests.size() * 2 + 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	# the entire test-suite is skipped
	assert_event_states(events).contains_exactly([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(any_class(GdUnitGUID), SUCCEEDED, SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
	])
	assert_event_reports(events, [
			[],
			[],
			["""
				This test is skipped!
				  Reason: 'Skipped from the entire test suite'
				""".dedent().trim_prefix("\n")],
			[],
			["""
				This test is skipped!
				  Reason: 'Skipped from the entire test suite'
				""".dedent().trim_prefix("\n")],
			# must fail after three iterations
			["""
				The Entire test-suite is skipped!
				  Skipped 2 tests
				  Reason: 'do not run this'
				""".dedent().trim_prefix("\n")]
		])


func test_execute_test_case_is_skipped() -> void:
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestCaseSkipped.resource")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_case1: GdUnitTestCase = tests["test_case1"]
	var test_case2: GdUnitTestCase = tests["test_case2"]
	# simulate test suite execution
	var events := await run_tests(all_tests)

	# (before_test+after_test) * test count + before+after hooks
	var expected_event_count := tests.size() * 2 + 2
	assert_array(events)\
		.override_failure_message("Expecting be %d events emitted, but counts %d." % [expected_event_count, events.size()])\
		.has_size(expected_event_count)

	# the test_case1 is skipped
	assert_event_states(events).contains_exactly([
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case1.guid, SUCCEEDED, SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(test_case2.guid, SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
		tuple(any_class(GdUnitGUID), SUCCEEDED, NOT_SKIPPED, NO_WARNING, NO_FAILURES, NO_ERRORS),
	])

	assert_event_reports(events, [
			[],
			[],
			["""
				This test is skipped!
				  Reason: 'do not run this'
				""".dedent().trim_prefix("\n")],
			[],
			[],
			[]
		])


func test_execute_test_case_is_flaky_and_failed() -> void:
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestCaseFlaky.resource")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_success := find_test(tests, "test_success")
	var test_flaky_success := find_test(tests, "test_flaky_success")
	var test_flaky_fail := find_test(tests, "test_flaky_fail")
	var test_parameterized_flaky0 := find_test(tests, "test_parameterized_flaky:0")
	var test_parameterized_flaky1 := find_test(tests, "test_parameterized_flaky:1")
	var test_parameterized_flaky2 := find_test(tests, "test_parameterized_flaky:2")
	var test_parameterized_flaky3 := find_test(tests, "test_parameterized_flaky:3")
	var test_parameterized_flaky4 := find_test(tests, "test_parameterized_flaky:4")
	var test_fuzzed_flaky_success := find_test(tests, "test_fuzzed_flaky_success")
	var test_fuzzed_flaky_fail := find_test(tests, "test_fuzzed_flaky_fail")

	# simulate flaky test suite execution
	var events := await run_tests(all_tests, {
		GdUnitSettings.TEST_FLAKY_CHECK : true,
		GdUnitSettings.TEST_FLAKY_MAX_RETRIES : 5
	})

	assert_array(events).extractv(extr("type"), extr("guid"), extr("is_flaky"), extr("is_success"))\
		.contains([
		tuple(GdUnitEvent.TESTSUITE_BEFORE, any_class(GdUnitGUID), false, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_success.guid, !FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_flaky_success.guid, FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_flaky_fail.guid, !FLAKY, FAILED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_parameterized_flaky0.guid, !FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_parameterized_flaky1.guid, !FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_parameterized_flaky2.guid, !FLAKY, FAILED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_parameterized_flaky3.guid, !FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_parameterized_flaky4.guid, FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_fuzzed_flaky_success.guid, FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_fuzzed_flaky_fail.guid, !FLAKY, FAILED),
		tuple(GdUnitEvent.TESTSUITE_AFTER, any_class(GdUnitGUID), !FLAKY, SUCCEEDED),
	])


func test_execute_test_case_is_flaky_and_success() -> void:
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/resources/testsuites/TestCaseFlaky.resource")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var test_success := find_test(tests, "test_success")
	var test_flaky_success := find_test(tests, "test_flaky_success")
	var test_flaky_fail := find_test(tests, "test_flaky_fail")
	var test_parameterized_flaky0 := find_test(tests, "test_parameterized_flaky:0")
	var test_parameterized_flaky1 := find_test(tests, "test_parameterized_flaky:1")
	var test_parameterized_flaky2 := find_test(tests, "test_parameterized_flaky:2")
	var test_parameterized_flaky3 := find_test(tests, "test_parameterized_flaky:3")
	var test_parameterized_flaky4 := find_test(tests, "test_parameterized_flaky:4")
	var test_fuzzed_flaky_success := find_test(tests, "test_fuzzed_flaky_success")
	var test_fuzzed_flaky_fail := find_test(tests, "test_fuzzed_flaky_fail")

	# simulate flaky test suite execution
	var events := await run_tests(all_tests, {
		GdUnitSettings.TEST_FLAKY_CHECK : true,
		GdUnitSettings.TEST_FLAKY_MAX_RETRIES : 6
	})

	# verify test execution results. all test should pass at least after 6 retries
	assert_array(events).extractv(extr("type"), extr("guid"), extr("is_flaky"), extr("is_success"))\
		.contains([
		tuple(GdUnitEvent.TESTSUITE_BEFORE, any_class(GdUnitGUID), false, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_success.guid, !FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_flaky_success.guid, FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_flaky_fail.guid, FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_parameterized_flaky0.guid, !FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_parameterized_flaky1.guid, !FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_parameterized_flaky2.guid, FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_parameterized_flaky3.guid, !FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_parameterized_flaky4.guid, FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_fuzzed_flaky_success.guid, FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTCASE_AFTER, test_fuzzed_flaky_fail.guid, FLAKY, SUCCEEDED),
		tuple(GdUnitEvent.TESTSUITE_AFTER, any_class(GdUnitGUID), !FLAKY, SUCCEEDED),
	])


func test_execute_push_error_monitoring_disabled() -> void:
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/execution/resources/error_monitoring/TestSuiteWithPushErrorTests.gd")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	# execute all tests
	var events := await run_tests(all_tests, {
		GdUnitSettings.REPORT_PUSH_ERRORS : false
	})

	assert_array(events).extractv(extr("type"), extr("test_name"), extr("is_success"))\
		.contains([
			tuple(GdUnitEvent.TESTCASE_AFTER, "test_without_push_errors", SUCCEEDED),
			tuple(GdUnitEvent.TESTCASE_AFTER, "test_with_push_error", SUCCEEDED),
			tuple(GdUnitEvent.TESTCASE_AFTER, "test_with_push_error_is_catched", SUCCEEDED),
			tuple(GdUnitEvent.TESTCASE_AFTER, "test_without_push_warning", SUCCEEDED),
			tuple(GdUnitEvent.TESTCASE_AFTER, "test_with_push_warning", SUCCEEDED),
			tuple(GdUnitEvent.TESTCASE_AFTER, "test_push_warning_is_catched", SUCCEEDED),
			tuple(GdUnitEvent.TESTSUITE_AFTER, "after", SUCCEEDED),
		])


func test_execute_push_error_monitoring_enabled() -> void:
	var tests := GdUnitTestResourceLoader.load_tests("res://addons/gdUnit4/test/core/execution/resources/error_monitoring/TestSuiteWithPushErrorTests.gd")
	var all_tests: Array[GdUnitTestCase] = Array(tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	# execute all tests
	var events := await run_tests(all_tests, {
		GdUnitSettings.REPORT_PUSH_ERRORS : true
	})

	assert_array(events).extractv(extr("type"), extr("test_name"), extr("is_success"))\
		.contains([
			tuple(GdUnitEvent.TESTCASE_AFTER, "test_without_push_errors", SUCCEEDED),
			tuple(GdUnitEvent.TESTCASE_AFTER, "test_with_push_error", FAILED),
			tuple(GdUnitEvent.TESTCASE_AFTER, "test_with_push_error_is_catched", SUCCEEDED),
			tuple(GdUnitEvent.TESTCASE_AFTER, "test_without_push_warning", SUCCEEDED),
			tuple(GdUnitEvent.TESTCASE_AFTER, "test_with_push_warning", FAILED),
			tuple(GdUnitEvent.TESTCASE_AFTER, "test_push_warning_is_catched", SUCCEEDED),
			tuple(GdUnitEvent.TESTSUITE_AFTER, "after", SUCCEEDED),
		])


func filter_by_test_case(events:  Array[GdUnitEvent], test: GdUnitTestCase) -> Array[GdUnitEvent]:
	return events.filter(func (event: GdUnitEvent) -> bool:
		return event.guid().equals(test.guid) and event.type() == GdUnitEvent.TESTCASE_AFTER
	)


func find_test(tests: Dictionary, test_name: String) -> GdUnitTestCase:
	for key: String in tests.keys():
		if key.begins_with(test_name):
			return tests[key]
	return null
