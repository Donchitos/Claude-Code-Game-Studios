# This class implements the JUnit XML file format
# based checked https://github.com/windyroad/JUnit-Schema/blob/master/JUnit.xsd
class_name JUnitXmlReportWriter
extends GdUnitReportWriter

const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")

const ATTR_CLASSNAME := "classname"
const ATTR_ERRORS := "errors"
const ATTR_FAILURES := "failures"
const ATTR_HOST := "hostname"
const ATTR_ID := "id"
const ATTR_MESSAGE := "message"
const ATTR_NAME := "name"
const ATTR_PACKAGE := "package"
const ATTR_SKIPPED := "skipped"
const ATTR_FLAKY := "flaky"
const ATTR_TESTS := "tests"
const ATTR_TIME := "time"
const ATTR_TIMESTAMP := "timestamp"
const ATTR_TYPE := "type"

const HEADER := '<?xml version="1.0" encoding="UTF-8" ?>\n'


func output_format() -> String:
	return "XML"


func write(report_path: String, report: GdUnitReportSummary) -> String:
	var result_file: String = "%s/results.xml" % report_path
	DirAccess.make_dir_recursive_absolute(report_path)
	var file := FileAccess.open(result_file, FileAccess.WRITE)
	if file == null:
		push_warning("Can't saving the result to '%s'\n Error: %s" % [result_file, error_string(FileAccess.get_open_error())])
	else:
		file.store_string(build_junit_report(report_path, report))
	return result_file


func build_junit_report(report_path: String, report: GdUnitReportSummary) -> String:
	var iso8601_datetime := Time.get_date_string_from_system()
	var test_suites := XmlElement.new("testsuites")\
		.attribute(ATTR_ID, iso8601_datetime)\
		.attribute(ATTR_NAME, report_path.get_file())\
		.attribute(ATTR_TESTS, report.test_count())\
		.attribute(ATTR_FAILURES, report.failure_count())\
		.attribute(ATTR_SKIPPED, report.skipped_count())\
		.attribute(ATTR_FLAKY, report.flaky_count())\
		.attribute(ATTR_TIME, JUnitXmlReportWriter.to_time(report.duration()))\
		.add_childs(build_test_suites(report))
	var as_string := test_suites.to_xml()
	test_suites.dispose()
	return HEADER + as_string


func build_test_suites(summary: GdUnitReportSummary) -> Array:
	var test_suites: Array[XmlElement] = []
	for index in summary.get_reports().size():
		var suite_report :GdUnitTestSuiteReport = summary.get_reports()[index]
		var iso8601_datetime := Time.get_datetime_string_from_unix_time(suite_report.time_stamp())
		test_suites.append(XmlElement.new("testsuite")\
			.attribute(ATTR_ID, index)\
			.attribute(ATTR_NAME, suite_report.name())\
			.attribute(ATTR_PACKAGE, suite_report.path())\
			.attribute(ATTR_TIMESTAMP, iso8601_datetime)\
			.attribute(ATTR_HOST, "localhost")\
			.attribute(ATTR_TESTS, suite_report.test_count())\
			.attribute(ATTR_FAILURES, suite_report.failure_count())\
			.attribute(ATTR_ERRORS, suite_report.error_count())\
			.attribute(ATTR_SKIPPED, suite_report.skipped_count())\
			.attribute(ATTR_FLAKY, suite_report.flaky_count())\
			.attribute(ATTR_TIME, JUnitXmlReportWriter.to_time(suite_report.duration()))\
			.add_childs(build_test_cases(suite_report)))
	return test_suites


func build_test_cases(suite_report: GdUnitTestSuiteReport) -> Array:
	var test_cases: Array[XmlElement] = []
	for index in suite_report.get_reports().size():
		var report :GdUnitTestCaseReport = suite_report.get_reports()[index]
		test_cases.append( XmlElement.new("testcase")\
			.attribute(ATTR_NAME, JUnitXmlReportWriter.encode_xml(report.name()))\
			.attribute(ATTR_CLASSNAME, report.suite_name())\
			.attribute(ATTR_TIME, JUnitXmlReportWriter.to_time(report.duration()))\
			.add_childs(build_reports(report)))
	return test_cases


func build_reports(test_report: GdUnitTestCaseReport) -> Array:
	var failure_reports: Array[XmlElement] = []

	for report: GdUnitReport in test_report.get_test_reports():
		if report.is_failure():
			failure_reports.append(XmlElement.new("failure")\
				.attribute(ATTR_MESSAGE, "FAILED: %s:%d" % [test_report.get_resource_path(), report.line_number()])\
				.attribute(ATTR_TYPE, JUnitXmlReportWriter.to_type(report.type()))\
				.text(convert_rtf_to_text(report.message())))
		elif report.is_error():
			failure_reports.append(XmlElement.new("error")\
				.attribute(ATTR_MESSAGE, "ERROR: %s:%d" % [test_report.get_resource_path(), report.line_number()])\
				.attribute(ATTR_TYPE, JUnitXmlReportWriter.to_type(report.type()))\
				.text(convert_rtf_to_text(report.message())))
		elif report.is_skipped():
			failure_reports.append(XmlElement.new("skipped")\
				.attribute(ATTR_MESSAGE, "SKIPPED: %s:%d" % [test_report.get_resource_path(), report.line_number()])\
				.text(convert_rtf_to_text(report.message())))
	return failure_reports


func convert_rtf_to_text(bbcode: String) -> String:
	return GdUnitTools.richtext_normalize(bbcode)


static func to_type(type: int) -> String:
	match type:
		GdUnitReport.SUCCESS:
			return "SUCCESS"
		GdUnitReport.WARN:
			return "WARN"
		GdUnitReport.FAILURE:
			return "FAILURE"
		GdUnitReport.ORPHAN:
			return "ORPHAN"
		GdUnitReport.TERMINATED:
			return "TERMINATED"
		GdUnitReport.INTERUPTED:
			return "INTERUPTED"
		GdUnitReport.ABORT:
			return "ABORT"
	return "UNKNOWN"


static func to_time(duration: int) -> String:
	return "%4.03f" % (duration / 1000.0)


static func encode_xml(value: String) -> String:
	return value.xml_escape(true)


#static func to_ISO8601_datetime() -> String:
	#return "%04d-%02d-%02dT%02d:%02d:%02d" % [date["year"], date["month"], date["day"],  date["hour"], date["minute"], date["second"]]
