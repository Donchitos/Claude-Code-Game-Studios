class_name JUnitXmlReportWriterIntegrationTest
extends GdUnitReportWriterIntegrationTest


func before() -> void:
	_setup_base("xml_reports/report_1", JUnitXmlReportWriter.new())


func _patch_out_timings(content: String) -> String:
	return _replace_timestamps(_replace_time_values(_replace_date_ids(content)))


func test_write_report() -> void:
	var tests: Array[GdUnitTestCase] = []
	tests.append_array(_load_test_cases("TestSuiteAllStagesSuccess.resource"))
	tests.append_array(_load_test_cases("TestSuiteFailOnMultipeStages.resource"))
	tests.append_array(_load_test_cases("TestCaseSkipped.resource"))
	_test_session = GdUnitTestSession.new(tests, _report_dir)
	await run_tests(tests)

	_report_writer.write(_test_session.report_path, _report_summary)

	_assert_report_matches(
		_report_dir + "/results.xml",
		RESOURCE_REPORTS + "report_1/results.xml"
	)
