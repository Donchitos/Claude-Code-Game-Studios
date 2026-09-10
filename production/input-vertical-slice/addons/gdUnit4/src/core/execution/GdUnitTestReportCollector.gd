# Collects all reports seperated as warnings, failures and errors
class_name GdUnitTestReportCollector
extends RefCounted


var _reports :Array[GdUnitReport] = []


static func __filter_is_error(report :GdUnitReport) -> bool:
	return report.is_error()


static func __filter_is_failure(report :GdUnitReport) -> bool:
	return report.is_failure()


static func __filter_is_warning(report :GdUnitReport) -> bool:
	return report.is_warning()


static func __filter_is_skipped(report :GdUnitReport) -> bool:
	return report.is_skipped()


static func __filter_is_orphan(report: GdUnitReport) -> bool:
	return report.is_orphan()


static func count_failures(reports_: Array[GdUnitReport]) -> int:
	return reports_.filter(__filter_is_failure).size()


static func count_errors(reports_: Array[GdUnitReport]) -> int:
	return reports_.filter(__filter_is_error).size()


static func count_warnings(reports_: Array[GdUnitReport]) -> int:
	return reports_.filter(__filter_is_warning).size()


static func count_skipped(reports_: Array[GdUnitReport]) -> int:
	return reports_.filter(__filter_is_skipped).size()


static func count_orphans(reports_: Array[GdUnitReport]) -> int:
	var orphan_reports := reports_.filter(__filter_is_orphan)
	if orphan_reports.is_empty():
		return 0
	## Collect orphan count from the reports
	var orphans := 0
	for report: GdUnitReport in orphan_reports:
		orphans += report._current_value
	return orphans


func has_failures() -> bool:
	return _reports.any(__filter_is_failure)


func has_errors() -> bool:
	return _reports.any(__filter_is_error)


func has_warnings() -> bool:
	return _reports.any(__filter_is_warning)


func has_skipped() -> bool:
	return _reports.any(__filter_is_skipped)


func reports() -> Array[GdUnitReport]:
	return _reports


func push_back(report :GdUnitReport) -> void:
	_reports.push_back(report)
