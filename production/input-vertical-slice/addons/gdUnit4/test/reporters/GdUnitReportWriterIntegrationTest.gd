class_name GdUnitReportWriterIntegrationTest
extends GdUnitTestSuite


const RESOURCE_REPORTS := "res://addons/gdUnit4/test/reporters/resources/"
const RESOURCE_SUITES := "res://addons/gdUnit4/test/reporters/resources/suites/folder with spaces/"

var _report_dir: String
var _reporter := GdUnitTestReporter.new()
var _report_summary: GdUnitReportSummary
var _report_writer: GdUnitReportWriter
var _test_session: GdUnitTestSession


#region test hooks
func _setup_base(report_dir_name: String, writer: GdUnitReportWriter) -> void:
	_report_dir = GdUnitFileAccess.create_temp_dir(report_dir_name)
	_report_writer = writer
	var formatter := func(s: String) -> String: return s
	_report_summary = GdUnitReportSummary.new(formatter)
	_reporter.init_summary()
	GdUnitSignals.instance().gdunit_event_debug.connect(_on_test_event)
	ProjectSettings.set_setting(GdUnitSettings.TEST_FLAKY_CHECK, false)


func after() -> void:
	GdUnitSignals.instance().gdunit_event_debug.disconnect(_on_test_event)
#endregion


func _on_test_event(event: GdUnitEvent) -> void:
	match event.type():
		GdUnitEvent.TESTSUITE_BEFORE:
			_reporter.init_statistics()
			_report_summary.add_testsuite_report(event.resource_path(), event.suite_name(), event.total_count())
		GdUnitEvent.TESTSUITE_AFTER:
			var statistics := _reporter.build_test_suite_statisitcs(event)
			_report_summary.update_testsuite_counters(
				event.resource_path(),
				_reporter.error_count(statistics),
				_reporter.failed_count(statistics),
				_reporter.orphan_nodes(statistics),
				_reporter.skipped_count(statistics),
				_reporter.flaky_count(statistics),
				event.elapsed_time())
			_report_summary.add_testsuite_reports(
				event.resource_path(),
				event.reports()
			)
		GdUnitEvent.TESTCASE_BEFORE:
			var test := _test_session.find_test_by_id(event.guid())
			_report_summary.add_testcase(test.source_file, test.suite_name, test.display_name)
		GdUnitEvent.TESTCASE_AFTER:
			_reporter.add_test_statistics(event)
			var test := _test_session.find_test_by_id(event.guid())
			_report_summary.set_counters(test.source_file,
				test.display_name,
				event.error_count(),
				event.failed_count(),
				event.orphan_nodes(),
				event.is_skipped(),
				event.is_flaky(),
				event.elapsed_time())
			_report_summary.add_reports(test.source_file, test.display_name, event.reports())


func run_tests(tests: Array[GdUnitTestCase], settings := {}) -> void:
	await GdUnitThreadManager.run("test_executor_%d" % randi(), func() -> void:
		var executor := GdUnitTestSuiteExecutor.new(true)

		var saves_settings := {}
		for key: String in settings.keys():
			saves_settings[key] = ProjectSettings.get_setting(key)
			ProjectSettings.set_setting(key, settings[key])

		await (Engine.get_main_loop() as SceneTree).process_frame
		await executor.run_and_wait(tests)

		for key: String in saves_settings.keys():
			ProjectSettings.set_setting(key, saves_settings[key])
	)


func _load_test_cases(suite_resource_path: String) -> Array[GdUnitTestCase]:
	var suite_failing_tests := GdUnitTestResourceLoader.load_tests(RESOURCE_SUITES + suite_resource_path)
	return Array(suite_failing_tests.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)


func _patch_out_timings(content: String) -> String:
	return content


#region test utils
func _replace_latency_values(input_text: String) -> String:
	var regex := RegEx.new()
	regex.compile("\\d{1,3}+ms")
	return regex.sub(input_text, "999ms", true)


func _replace_all_timestamps(input_text: String) -> String:
	var regex := RegEx.new()
	regex.compile("\\d{4}-\\d{2}-\\d{2}\\s\\d{2}:\\d{2}:\\d{2}")
	return regex.sub(input_text, "2026-04-22 18:27:14", true)


func _replace_time_values(input_text: String) -> String:
	var regex := RegEx.new()
	regex.compile('time="[\\d.]+"')
	return regex.sub(input_text, 'time="0.000"', true)


func _replace_date_ids(input_text: String) -> String:
	var regex := RegEx.new()
	regex.compile('id="\\d{4}-\\d{2}-\\d{2}"')
	return regex.sub(input_text, 'id="2026-01-01"', true)


func _replace_timestamps(input_text: String) -> String:
	var regex := RegEx.new()
	regex.compile("\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}")
	return regex.sub(input_text, "2026-01-01T00:00:00", true)
#endregion


func _assert_report_matches(actual_path: String, expected_path: String) -> void:
	var actual := _patch_out_timings(FileAccess.open(actual_path, FileAccess.READ).get_as_text())
	var expected := _patch_out_timings(FileAccess.open(expected_path, FileAccess.READ).get_as_text())
	assert_str(actual).is_equal(expected)
