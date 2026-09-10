# GdUnit generated TestSuite
class_name GdUnitExecutionContextTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')


func before() -> void:
	ProjectSettings.set_setting(GdUnitSettings.TEST_FLAKY_CHECK, false)


func test_collect_report_statistics_with_errors() -> void:
	# setup execution context tree like is build by the executor run
	var ctx_suite := GdUnitExecutionContext.new("")
	var ts :GdUnitTestSuite = auto_free(GdUnitTestSuite.new())
	var tc :_TestCase = auto_free(create_test_case("test_case1", 0, ""))
	ts.add_child(tc)
	ctx_suite.test_suite = ts
	ctx_suite.orphan_monitor_start()

	# suite execution (GdUnitTestSuiteExecutor)
	if ctx_suite != null:
		var suite_err1 := ctx_suite.add_report(GdUnitReport.new().create(GdUnitReport.FAILURE, 1, "suite before error"))

		# test execution (GdUnitTestSuiteExecutionStage)
		var ctx_test := GdUnitExecutionContext.of_test_case(ctx_suite, tc)
		if ctx_test != null:
			# (GdUnitTestCaseSingleExecutionStage)
			var ctx_test_hook := GdUnitExecutionContext.of(ctx_test)
			var test_hook_err1 := ctx_test_hook.add_report(GdUnitReport.new().create(GdUnitReport.FAILURE, 3, "before_test error"))
			# test execution
			var ctx_test_call := GdUnitExecutionContext.of(ctx_test_hook)
			var test_err1 := ctx_test_call.add_report(GdUnitReport.new().create(GdUnitReport.FAILURE, 13, "test error_a"))
			var test_err2 := ctx_test_call.add_report(GdUnitReport.new().create(GdUnitReport.FAILURE, 14, "test error_b"))
			var test_err3 := ctx_test_call.add_report(GdUnitReport.new().create(GdUnitReport.FAILURE, 15, "test error_c"))
			ctx_test_call.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.TEST_CASE)

			var test_hook_err2 := ctx_test_hook.add_report(GdUnitReport.new().create(GdUnitReport.FAILURE, 4, "after_test error"))
			ctx_test_hook.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.TEST_HOOK_AFTER)

			# verify
			ctx_test.gc()
			var test_reports := ctx_test.collect_reports(true)
			var test_statisitcs := ctx_test.calculate_statistics(test_reports)
			assert_array(test_reports).contains_exactly([test_hook_err1, test_hook_err2, test_err1, test_err2, test_err3])
			assert_dict(test_statisitcs).is_equal({
				GdUnitEvent.RETRY_COUNT: 1,
				GdUnitEvent.ELAPSED_TIME: test_statisitcs[GdUnitEvent.ELAPSED_TIME],
				GdUnitEvent.FAILED: true,
				GdUnitEvent.ERRORS: false,
				GdUnitEvent.WARNINGS: false,
				GdUnitEvent.FLAKY: false,
				GdUnitEvent.SKIPPED: false,
				GdUnitEvent.FAILED_COUNT: 5,
				GdUnitEvent.ERROR_COUNT: 0,
				GdUnitEvent.SKIPPED_COUNT: 0,
				GdUnitEvent.ORPHAN_NODES: 0,
			})

		var suite_err2 := ctx_suite.add_report(GdUnitReport.new().create(GdUnitReport.FAILURE, 1, "suite after error"))

		# verify
		ctx_suite.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.SUITE_HOOK_AFTER)
		var suite_reports := ctx_suite.collect_reports(false)
		assert_array(suite_reports).contains_exactly([suite_err1, suite_err2])
		var suite_statisitcs := ctx_suite.calculate_statistics(suite_reports)
		assert_dict(suite_statisitcs).is_equal({
				GdUnitEvent.RETRY_COUNT: 1,
				GdUnitEvent.ELAPSED_TIME: suite_statisitcs[GdUnitEvent.ELAPSED_TIME],
				GdUnitEvent.FAILED: true,
				GdUnitEvent.ERRORS: false,
				GdUnitEvent.WARNINGS: false,
				GdUnitEvent.FLAKY: false,
				GdUnitEvent.SKIPPED: false,
				GdUnitEvent.FAILED_COUNT: 2,
				GdUnitEvent.ERROR_COUNT: 0,
				GdUnitEvent.SKIPPED_COUNT: 0,
				GdUnitEvent.ORPHAN_NODES: 0,
			})
		ctx_suite.dispose()


func test_collect_report_statistics_with_errors_on_suite_hooks() -> void:
	# setup execution context tree like is build by the executor run
	var ctx_suite := GdUnitExecutionContext.new("")
	var ts :GdUnitTestSuite = auto_free(GdUnitTestSuite.new())
	var tc :_TestCase = auto_free(create_test_case("test_case1", 0, ""))
	ts.add_child(tc)
	ctx_suite.test_suite = ts
	ctx_suite.orphan_monitor_start()

	# suite execution (GdUnitTestSuiteExecutor)
	if ctx_suite != null:
		var suite_err1 := ctx_suite.add_report(GdUnitReport.new().create(GdUnitReport.FAILURE, 1, "suite before error"))

		# test execution (GdUnitTestSuiteExecutionStage)
		var ctx_test := GdUnitExecutionContext.of_test_case(ctx_suite, tc)
		if ctx_test != null:
			# (GdUnitTestCaseSingleExecutionStage)
			var ctx_test_hook := GdUnitExecutionContext.of(ctx_test)
			# test execution
			var ctx_test_call := GdUnitExecutionContext.of(ctx_test_hook)
			ctx_test_call.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.TEST_CASE)

			ctx_test_hook.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.TEST_HOOK_AFTER)

			# verify
			ctx_test.gc()
			var test_reports := ctx_test.collect_reports(true)
			var test_statisitcs := ctx_test.calculate_statistics(test_reports)
			assert_array(test_reports).is_empty()
			assert_dict(test_statisitcs).is_equal({
				GdUnitEvent.RETRY_COUNT: 1,
				GdUnitEvent.ELAPSED_TIME: test_statisitcs[GdUnitEvent.ELAPSED_TIME],
				GdUnitEvent.FAILED: false,
				GdUnitEvent.ERRORS: false,
				GdUnitEvent.WARNINGS: false,
				GdUnitEvent.FLAKY: false,
				GdUnitEvent.SKIPPED: false,
				GdUnitEvent.FAILED_COUNT: 0,
				GdUnitEvent.ERROR_COUNT: 0,
				GdUnitEvent.SKIPPED_COUNT: 0,
				GdUnitEvent.ORPHAN_NODES: 0,
			})

		var suite_err2 := ctx_suite.add_report(GdUnitReport.new().create(GdUnitReport.FAILURE, 1, "suite after error"))

		# verify
		ctx_suite.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.SUITE_HOOK_AFTER)
		var suite_reports := ctx_suite.collect_reports(false)
		assert_array(suite_reports).contains_exactly([suite_err1, suite_err2])
		var suite_statisitcs := ctx_suite.calculate_statistics(suite_reports)
		assert_dict(suite_statisitcs).is_equal({
				GdUnitEvent.RETRY_COUNT: 1,
				GdUnitEvent.ELAPSED_TIME: suite_statisitcs[GdUnitEvent.ELAPSED_TIME],
				GdUnitEvent.FAILED: true,
				GdUnitEvent.ERRORS: false,
				GdUnitEvent.WARNINGS: false,
				GdUnitEvent.FLAKY: false,
				GdUnitEvent.SKIPPED: false,
				GdUnitEvent.FAILED_COUNT: 2,
				GdUnitEvent.ERROR_COUNT: 0,
				GdUnitEvent.SKIPPED_COUNT: 0,
				GdUnitEvent.ORPHAN_NODES: 0,
			})
		ctx_suite.dispose()


func test_collect_report_statistics_only_errors_on_test_hooks() -> void:
	# setup execution context tree like is build by the executor run
	var ctx_suite := GdUnitExecutionContext.new("")
	var ts :GdUnitTestSuite = auto_free(GdUnitTestSuite.new())
	var tc :_TestCase = auto_free(create_test_case("test_case1", 0, ""))
	ts.add_child(tc)
	ctx_suite.test_suite = ts
	ctx_suite.orphan_monitor_start()

	# suite execution (GdUnitTestSuiteExecutor)
	if ctx_suite != null:
		# test execution (GdUnitTestSuiteExecutionStage)
		var ctx_test := GdUnitExecutionContext.of_test_case(ctx_suite, tc)
		if ctx_test != null:
			# (GdUnitTestCaseSingleExecutionStage)
			var ctx_test_hook := GdUnitExecutionContext.of(ctx_test)

			var err1 := ctx_test_hook.add_report(GdUnitReport.new().create(GdUnitReport.FAILURE, 1, "error on before_test()"))
			# test execution
			var ctx_test_call := GdUnitExecutionContext.of(ctx_test_hook)
			ctx_test_call.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.TEST_CASE)

			ctx_test_hook.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.TEST_HOOK_AFTER)

			# verify
			ctx_test.gc()
			var test_reports := ctx_test.collect_reports(true)
			var test_statisitcs := ctx_test.calculate_statistics(test_reports)
			assert_array(test_reports).contains_exactly([err1])
			assert_dict(test_statisitcs).is_equal({
				GdUnitEvent.RETRY_COUNT: 1,
				GdUnitEvent.ELAPSED_TIME: test_statisitcs[GdUnitEvent.ELAPSED_TIME],
				GdUnitEvent.FAILED: true,
				GdUnitEvent.ERRORS: false,
				GdUnitEvent.WARNINGS: false,
				GdUnitEvent.FLAKY: false,
				GdUnitEvent.SKIPPED: false,
				GdUnitEvent.FAILED_COUNT: 1,
				GdUnitEvent.ERROR_COUNT: 0,
				GdUnitEvent.SKIPPED_COUNT: 0,
				GdUnitEvent.ORPHAN_NODES: 0,
			})

		# verify
		ctx_suite.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.SUITE_HOOK_AFTER)
		var suite_reports := ctx_suite.collect_reports(false)
		assert_array(suite_reports).is_empty()
		var suite_statisitcs := ctx_suite.calculate_statistics(suite_reports)
		assert_dict(suite_statisitcs).is_equal({
				GdUnitEvent.RETRY_COUNT: 1,
				GdUnitEvent.ELAPSED_TIME: suite_statisitcs[GdUnitEvent.ELAPSED_TIME],
				GdUnitEvent.FAILED: false,
				GdUnitEvent.ERRORS: false,
				GdUnitEvent.WARNINGS: false,
				GdUnitEvent.FLAKY: false,
				GdUnitEvent.SKIPPED: false,
				GdUnitEvent.FAILED_COUNT: 0,
				GdUnitEvent.ERROR_COUNT: 0,
				GdUnitEvent.SKIPPED_COUNT: 0,
				GdUnitEvent.ORPHAN_NODES: 0,
			})
		ctx_suite.dispose()


func test_collect_report_statistics_all_tests_skipped() -> void:
	# setup execution context tree like is build by the executor run
	var ctx_suite := GdUnitExecutionContext.new("")
	var ts :GdUnitTestSuite = auto_free(GdUnitTestSuite.new())
	var tc :_TestCase = auto_free(create_test_case("test_case1", 0, ""))
	ts.add_child(tc)
	ctx_suite.test_suite = ts
	ctx_suite.orphan_monitor_start()

	# suite execution (GdUnitTestSuiteExecutor)
	if ctx_suite != null:
		# test execution (GdUnitTestSuiteExecutionStage)
		# simulate 10 test running as skipped
		for index in range(0, 10):
			var ctx_test := GdUnitExecutionContext.of_test_case(ctx_suite, tc)
			if ctx_test != null:
				var ctx_test_hook := GdUnitExecutionContext.of(ctx_test)
				# test execution
				var ctx_test_call := GdUnitExecutionContext.of(ctx_test_hook)
				ctx_test_call.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.TEST_CASE)
				var expected_report := ctx_test_call.add_report(GdUnitReport.new().create(GdUnitReport.SKIPPED, index*5, "skipped test %d" % index))

				ctx_test_hook.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.TEST_HOOK_AFTER)
				# verify
				ctx_test.gc()
				var test_reports := ctx_test.collect_reports(true)
				var test_statisitcs := ctx_test.calculate_statistics(test_reports)
				assert_array(test_reports).contains_exactly([expected_report])
				assert_dict(test_statisitcs).is_equal({
					GdUnitEvent.RETRY_COUNT: 1,
					GdUnitEvent.ELAPSED_TIME: test_statisitcs[GdUnitEvent.ELAPSED_TIME],
					GdUnitEvent.FAILED: false,
					GdUnitEvent.ERRORS: false,
					GdUnitEvent.WARNINGS: false,
					GdUnitEvent.FLAKY: false,
					GdUnitEvent.SKIPPED: true,
					GdUnitEvent.FAILED_COUNT: 0,
					GdUnitEvent.ERROR_COUNT: 0,
					GdUnitEvent.SKIPPED_COUNT: 1,
					GdUnitEvent.ORPHAN_NODES: 0,
				})

		# verify
		ctx_suite.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.SUITE_HOOK_AFTER)
		var suite_reports := ctx_suite.collect_reports(false)
		assert_array(suite_reports).is_empty()
		var suite_statisitcs := ctx_suite.calculate_statistics(suite_reports)
		assert_dict(suite_statisitcs).is_equal({
				GdUnitEvent.RETRY_COUNT: 1,
				GdUnitEvent.ELAPSED_TIME: suite_statisitcs[GdUnitEvent.ELAPSED_TIME],
				GdUnitEvent.FAILED: false,
				GdUnitEvent.ERRORS: false,
				GdUnitEvent.WARNINGS: false,
				GdUnitEvent.FLAKY: false,
				GdUnitEvent.SKIPPED: false,
				GdUnitEvent.FAILED_COUNT: 0,
				GdUnitEvent.ERROR_COUNT: 0,
				GdUnitEvent.SKIPPED_COUNT: 0,
				GdUnitEvent.ORPHAN_NODES: 0,
			})
		ctx_suite.dispose()


func test_simmulate_flaky_test(retry_count: int, is_flaky: bool, is_failed: bool, _test_parameters := [
	[1, false, true],
	[2, false, true],
	[3, true, false],]) -> void:
	# setup execution context tree like is build by the executor run
	var ctx_suite := GdUnitExecutionContext.new("")
	var ts :GdUnitTestSuite = auto_free(GdUnitTestSuite.new())
	var tc :_TestCase = auto_free(create_test_case("test_case1", 0, ""))
	ts.add_child(tc)
	ctx_suite.test_suite = ts
	ctx_suite.orphan_monitor_start()

	if ctx_suite != null:
		# test execution
		var ctx_test := GdUnitExecutionContext.of_test_case(ctx_suite, tc)
		if ctx_test != null:
			var expected_reports := []
			for retry in range(0, retry_count):
				# before/after context
				var ctx_test_hook := GdUnitExecutionContext.of(ctx_test)
				# test context
				var ctx_test_call := GdUnitExecutionContext.of(ctx_test_hook)
				# let the first two retrys fail and the last retry succeeds
				if retry < 2:
					expected_reports.append(ctx_test_call.add_report(GdUnitReport.new().create(GdUnitReport.FAILURE, 42, "error")))
					expected_reports.append(ctx_test_call.add_report(GdUnitReport.new().create(GdUnitReport.FAILURE, 43, "error")))

				ctx_test_hook.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.TEST_HOOK_AFTER)

			ctx_test.gc()
			var reports := ctx_test.collect_reports(true)
			assert_array(reports).contains_exactly(expected_reports)
			var statistics := ctx_test.calculate_statistics(reports)
			#for key: String in statistics.keys():
			#	prints("%13s: %s" % [key, statistics[key]])
			#prints()
			assert_dict(statistics).is_equal({
				GdUnitEvent.RETRY_COUNT: retry_count,
				GdUnitEvent.ELAPSED_TIME: statistics[GdUnitEvent.ELAPSED_TIME],
				GdUnitEvent.FAILED: is_failed,
				GdUnitEvent.ERRORS: false,
				GdUnitEvent.WARNINGS: false,
				GdUnitEvent.FLAKY: is_flaky,
				GdUnitEvent.SKIPPED: false,
				GdUnitEvent.FAILED_COUNT: 0 if is_flaky else retry_count*2,
				GdUnitEvent.ERROR_COUNT: 0,
				GdUnitEvent.SKIPPED_COUNT: 0,
				GdUnitEvent.ORPHAN_NODES: 0,
			})
			assert_bool(statistics[GdUnitEvent.FLAKY]).override_failure_message("Shold be marked as %s" %  "flaky" if is_flaky else "").is_equal(is_flaky)
			assert_bool(statistics[GdUnitEvent.FAILED]).override_failure_message("Expect be failing: %s" % is_failed).is_equal(is_failed)

		ctx_suite.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.SUITE_HOOK_AFTER)
		var suite_reports := ctx_suite.collect_reports(false)
		assert_array(suite_reports).is_empty()
		var suite_statisitcs := ctx_suite.calculate_statistics(suite_reports)
		assert_dict(suite_statisitcs).is_equal({
				GdUnitEvent.RETRY_COUNT: 1,
				GdUnitEvent.ELAPSED_TIME: suite_statisitcs[GdUnitEvent.ELAPSED_TIME],
				GdUnitEvent.FAILED: false, # no suite hook failures
				GdUnitEvent.ERRORS: false,
				GdUnitEvent.WARNINGS: false,
				GdUnitEvent.FLAKY: false,
				GdUnitEvent.SKIPPED: false,
				GdUnitEvent.FAILED_COUNT: 0,
				GdUnitEvent.ERROR_COUNT: 0,
				GdUnitEvent.SKIPPED_COUNT: 0,
				GdUnitEvent.ORPHAN_NODES: 0,
			})
		ctx_suite.dispose()

static func create_test_case(p_name: String, p_line_number: int, p_script_path: String) -> _TestCase:
	var test_case := GdUnitTestCase.new()
	test_case.test_name = p_name
	test_case.line_number = p_line_number
	test_case.source_file = p_script_path
	var attribute := TestCaseAttribute.new()
	return _TestCase.new(test_case, attribute, null)


static func has_failures(context: GdUnitExecutionContext) -> bool:
	var statistics := context.calculate_statistics(context.collect_reports(true))

	return statistics[GdUnitEvent.FAILED]


static func count_failures(context: GdUnitExecutionContext) -> int:
	var statistics := context.calculate_statistics(context.collect_reports(true))

	return statistics[GdUnitEvent.FAILED_COUNT]
