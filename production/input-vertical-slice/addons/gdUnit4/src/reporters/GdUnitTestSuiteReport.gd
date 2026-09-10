class_name GdUnitTestSuiteReport
extends GdUnitReportSummary

var _time_stamp: int
var _failure_reports: Array[GdUnitReport] = []


func _init(p_resource_path: String, p_name: String, p_test_count: int, text_formatter: Callable) -> void:
	_resource_path = p_resource_path
	_name = p_name
	_test_count = p_test_count
	_time_stamp = Time.get_unix_time_from_system() as int
	_text_formatter = text_formatter


func failure_report() -> String:
	var report_message := ""
	for report in _failure_reports:
		report_message += _text_formatter.call(str(report))
	return report_message


func set_duration(p_duration :int) -> void:
	_duration = p_duration


func time_stamp() -> int:
	return _time_stamp


func duration() -> int:
	return _duration


func set_skipped(skipped :int) -> void:
	_skipped_count += skipped


func set_orphans(orphans :int) -> void:
	_orphan_count = orphans


func set_failed(count :int) -> void:
	_failure_count += count


func set_reports(failure_reports :Array[GdUnitReport]) -> void:
	_failure_reports = failure_reports


func add_or_create_test_report(test_report: GdUnitTestCaseReport) -> void:
	_reports.append(test_report)


func _update_testsuite_counters(
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


func set_testcase_counters(
	test_name: String,
	p_error_count: int,
	p_failure_count: int,
	p_orphan_count: int,
	p_is_skipped: bool,
	p_is_flaky: bool,
	p_duration: int) -> void:
	if _reports.is_empty():
		return
	var test_report: GdUnitTestCaseReport = _reports.filter(func (report: GdUnitTestCaseReport) -> bool:
		return report.name() == test_name
	).back()
	if test_report:
		test_report.set_testcase_counters(p_error_count, p_failure_count, p_orphan_count, p_is_skipped, p_is_flaky, p_duration)


func add_testcase_reports(test_name: String, reports: Array[GdUnitReport]) -> void:
	if reports.is_empty():
		return
	# we lookup to latest matching report because of flaky tests could be retry the tests
	# and resultis in multipe report entries with the same name
	var test_report: GdUnitTestCaseReport = _reports.filter(func (report: GdUnitTestCaseReport) -> bool:
		return report.name() == test_name
	).back()
	if test_report:
		test_report.add_testcase_reports(reports)
