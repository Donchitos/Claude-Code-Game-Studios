class_name GdUnitTestCaseReport
extends GdUnitReportSummary


var _suite_name: String
var _failure_reports: Array[GdUnitReport] = []


func _init(p_resource_path: String, p_suite_name: String, p_test_name: String, text_formatter: Callable) -> void:
	_resource_path = p_resource_path
	_suite_name = p_suite_name
	_name = p_test_name
	_text_formatter = text_formatter


func suite_name() -> String:
	return _suite_name


func failure_report() -> String:
	var report_message := ""
	for report in get_test_reports():
		report_message += _text_formatter.call(str(report)) + "\n"
	return report_message


func add_testcase_reports(reports: Array[GdUnitReport]) -> void:
	_failure_reports.append_array(reports)


func set_testcase_counters(
	p_error_count: int,
	p_failure_count: int,
	p_orphan_count: int,
	p_is_skipped: bool,
	p_is_flaky: bool,
	p_duration: int) -> void:
	_error_count = p_error_count
	_failure_count = p_failure_count
	_orphan_count = p_orphan_count
	_skipped_count = p_is_skipped
	_flaky_count = p_is_flaky as int
	_duration = p_duration


func get_test_reports() -> Array[GdUnitReport]:
	return _failure_reports
