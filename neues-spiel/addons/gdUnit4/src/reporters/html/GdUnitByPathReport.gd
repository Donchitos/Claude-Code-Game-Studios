class_name GdUnitByPathReport
extends GdUnitReportSummary


func _init(p_path: String, report_summaries: Array[GdUnitReportSummary]) -> void:
	_resource_path = p_path
	_reports = report_summaries


# -> Dictionary[String, Array[GdUnitReportSummary]]
static func sort_reports_by_path(report_summaries: Array[GdUnitReportSummary]) -> Dictionary:
	var by_path := Dictionary()
	for report in report_summaries:
		var suite_path: String = ProjectSettings.localize_path(report.path())
		var suite_report: Array[GdUnitReportSummary] = by_path.get(suite_path, [] as Array[GdUnitReportSummary])
		suite_report.append(report)
		by_path[suite_path] = suite_report
	return by_path


func path() -> String:
	return _resource_path.replace("res://", "").trim_suffix("/")


func create_record(report_link: String) -> String:
	return GdUnitHtmlPatterns.build(GdUnitHtmlPatterns.TABLE_RECORD_PATH, self, report_link)


func write(report_dir: String) -> String:
	calculate_summary()
	var output_path := GdUnitHtmlPatterns.create_path_output_path(report_dir, path())
	var template := GdUnitHtmlPatterns.load_template("res://addons/gdUnit4/src/reporters/html/template/folder_report.html")
	var path_report := GdUnitHtmlPatterns.build(template, self, output_path, GdUnitHtmlPatterns.get_path_as_link(self))
	path_report = apply_testsuite_reports(report_dir, path_report, _reports)
	GdUnitHtmlPatterns.write_html_file(output_path, path_report)
	return output_path


func apply_testsuite_reports(report_dir: String, template: String, test_suite_reports: Array[GdUnitReportSummary]) -> String:
	var table_records := PackedStringArray()
	for report: GdUnitTestSuiteReport in test_suite_reports:
		var report_link := GdUnitHtmlPatterns.create_suite_output_path(report_dir, report.path(), report.name()).replace(report_dir, "..")
		@warning_ignore("return_value_discarded")
		table_records.append(GdUnitHtmlPatterns.create_suite_record(report_link, report))
	return template.replace(GdUnitHtmlPatterns.TABLE_BY_TESTSUITES, "\n".join(table_records))


func calculate_summary() -> void:
	for report: GdUnitTestSuiteReport in get_reports():
		_error_count += report.error_count()
		_failure_count += report.failure_count()
		_orphan_count += report.orphan_count()
		_skipped_count += report.skipped_count()
		_flaky_count += report.flaky_count()
		_duration += report.duration()
