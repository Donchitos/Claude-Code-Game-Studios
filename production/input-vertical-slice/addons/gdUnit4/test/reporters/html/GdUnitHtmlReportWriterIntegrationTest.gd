class_name GdUnitHtmlReportWriterIntegrationTest
extends GdUnitReportWriterIntegrationTest


func before() -> void:
	_setup_base("html_reports/report_1", GdUnitHtmlReportWriter.new())


func _patch_out_timings(content: String) -> String:
	return _replace_all_timestamps(_replace_latency_values(content))


func test_write_report() -> void:
	var tests: Array[GdUnitTestCase] = []
	tests.append_array(_load_test_cases("TestSuiteAllStagesSuccess.resource"))
	tests.append_array(_load_test_cases("TestSuiteFailOnMultipeStages.resource"))
	tests.append_array(_load_test_cases("TestCaseSkipped.resource"))
	_test_session = GdUnitTestSession.new(tests, _report_dir)
	await run_tests(tests)

	_report_writer.write(_test_session.report_path, _report_summary)

	var suite_report_path := "addons.gdUnit4.test.reporters.resources.suites.folder_with_spaces"
	_assert_report_matches(
		_report_dir + "/index.html",
		RESOURCE_REPORTS + "report_1/index.html"
	)
	_assert_report_matches(
		_report_dir + "/path/%s.html" % suite_report_path,
		RESOURCE_REPORTS + "report_1/path/%s.html" % suite_report_path
	)
	_assert_report_matches(
		_report_dir + "/test_suites/%s.TestSuiteAllStagesSuccess.html" % suite_report_path,
		RESOURCE_REPORTS + "report_1/test_suites/%s.TestSuiteAllStagesSuccess.html" % suite_report_path
	)
	_assert_report_matches(
		_report_dir + "/test_suites/%s.TestSuiteFailOnMultipeStages.html" % suite_report_path,
		RESOURCE_REPORTS + "report_1/test_suites/%s.TestSuiteFailOnMultipeStages.html" % suite_report_path
	)
	_assert_report_matches(
		_report_dir + "/test_suites/%s.TestCaseSkipped.html" % suite_report_path,
		RESOURCE_REPORTS + "report_1/test_suites/%s.TestCaseSkipped.html" % suite_report_path
	)
