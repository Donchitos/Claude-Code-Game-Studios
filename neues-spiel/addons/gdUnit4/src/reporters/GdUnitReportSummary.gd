class_name GdUnitReportSummary
extends RefCounted

var _resource_path: String
var _name: String
var _test_count := 0
var _failure_count := 0
var _error_count := 0
var _orphan_count := 0
var _skipped_count := 0
var _flaky_count := 0
var _duration := 0
var _reports: Array[GdUnitReportSummary] = []
var _text_formatter: Callable


func _init(text_formatter: Callable) -> void:
	_text_formatter = text_formatter


func name() -> String:
	return _name


func path() -> String:
	return _resource_path.get_base_dir().replace("res://", "")


func get_resource_path() -> String:
	return _resource_path


func suite_count() -> int:
	return _reports.size()


func suite_executed_count() -> int:
	var executed := _reports.size()
	for report in _reports:
		if report.test_count() == report.skipped_count():
			executed -= 1
	return executed


func test_count() -> int:
	var count := _test_count
	for report in _reports:
		count += report.test_count()
	return count


func test_executed_count() -> int:
	return test_count() - skipped_count()


func success_count() -> int:
	return test_count() - error_count() - failure_count() - flaky_count() - skipped_count()


func error_count() -> int:
	return _error_count


func failure_count() -> int:
	return _failure_count


func skipped_count() -> int:
	return _skipped_count


func flaky_count() -> int:
	return _flaky_count


func orphan_count() -> int:
	return _orphan_count


func duration() -> int:
	return _duration


func get_reports() -> Array:
	return _reports


func add_report(report: GdUnitReportSummary) -> void:
	_reports.append(report)


func report_state() -> String:
	return calculate_state(error_count(), failure_count(), orphan_count(), flaky_count(), skipped_count())


func succes_rate() -> String:
	return calculate_succes_rate(test_count(), error_count(), failure_count())


@warning_ignore("shadowed_variable")
func add_testcase(resource_path: String, suite_name: String, test_name: String) -> void:
	for report: GdUnitTestSuiteReport in _reports:
		if report.get_resource_path() == resource_path:
			var test_report := GdUnitTestCaseReport.new(resource_path, suite_name, test_name, _text_formatter)
			report.add_or_create_test_report(test_report)


func add_reports(
	p_resource_path: String,
	p_test_name: String,
	p_reports: Array[GdUnitReport]) -> void:

	for report:GdUnitTestSuiteReport in _reports:
		if report.get_resource_path() == p_resource_path:
			report.add_testcase_reports(p_test_name, p_reports)


func add_testsuite_report(p_resource_path: String, p_suite_name: String, p_test_count: int) -> void:
	_reports.append(GdUnitTestSuiteReport.new(p_resource_path, p_suite_name, p_test_count, _text_formatter))


func add_testsuite_reports(
	p_resource_path: String,
	p_reports: Array = []) -> void:

	for report:GdUnitTestSuiteReport in _reports:
		if report.get_resource_path() == p_resource_path:
			report.set_reports(p_reports)


func set_counters(
	p_resource_path: String,
	p_test_name: String,
	p_error_count: int,
	p_failure_count: int,
	p_orphan_count: int,
	p_is_skipped: bool,
	p_is_flaky: bool,
	p_duration: int) -> void:

	for report: GdUnitTestSuiteReport in _reports:
		if report.get_resource_path() == p_resource_path:
			report.set_testcase_counters(p_test_name, p_error_count, p_failure_count, p_orphan_count,
				p_is_skipped, p_is_flaky, p_duration)


func update_testsuite_counters(
	p_resource_path: String,
	p_error_count: int,
	p_failure_count: int,
	p_orphan_count: int,
	p_skipped_count: int,
	p_flaky_count: int,
	p_duration: int) -> void:

	for report:GdUnitTestSuiteReport in _reports:
		if report.get_resource_path() == p_resource_path:
			report._update_testsuite_counters(p_error_count, p_failure_count, p_orphan_count, p_skipped_count, p_flaky_count, p_duration)
	_update_summary_counters(p_error_count, p_failure_count, p_orphan_count, p_skipped_count, p_flaky_count, 0)


func _update_summary_counters(
	p_error_count: int,
	p_failure_count: int,
	p_orphan_count: int,
	p_skipped_count: int,
	p_flaky_count: int,
	p_duration: int) -> void:

	_error_count += p_error_count
	_failure_count += p_failure_count
	_orphan_count += p_orphan_count
	_skipped_count += p_skipped_count
	_flaky_count += p_flaky_count
	_duration += p_duration


func calculate_state(p_error_count :int, p_failure_count :int, p_orphan_count :int, p_flaky_count: int, p_skipped_count: int) -> String:
	if p_error_count > 0:
		return "ERROR"
	if p_failure_count > 0:
		return "FAILED"
	if p_flaky_count > 0:
		return "FLAKY"
	if p_orphan_count > 0:
		return "WARNING"
	if p_skipped_count > 0:
		return "SKIPPED"
	return "PASSED"


func calculate_succes_rate(p_test_count :int, p_error_count :int, p_failure_count :int) -> String:
	if p_failure_count == 0:
		return "100%"
	var count := p_test_count-p_failure_count-p_error_count
	if count < 0:
		return "0%"
	return "%d" % (( 0 if count < 0 else count) * 100.0 / p_test_count) + "%"


func create_summary(_report_dir :String) -> String:
	return ""
