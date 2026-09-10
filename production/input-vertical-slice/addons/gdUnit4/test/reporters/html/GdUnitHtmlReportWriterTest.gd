# GdUnit generated TestSuite
class_name GdUnitHtmlReportWriterTest
extends GdUnitTestSuite


const SNAPSHOT_DIR := "res://addons/gdUnit4/test/reporters/html/resources"

var _report_dir: String


func before() -> void:
	_report_dir = GdUnitFileAccess.create_temp_dir("html_report_writer_test")
	var formatter := func(s: String) -> String: return s
	var summary := GdUnitReportSummary.new(formatter)
	summary.add_testsuite_report("res://my test suite/SomeTest.gd", "SomeTest", 1)
	GdUnitHtmlReportWriter.new().write(_report_dir, summary)


#region space replacement in generated hrefs
func test_suite_href_in_index_replaces_spaces_with_underscores() -> void:
	var index_html := FileAccess.open(_report_dir + "/index.html", FileAccess.READ).get_as_text()
	assert_str(index_html).contains('href="./test_suites/my_test_suite.SomeTest.html"')


func test_path_href_in_index_replaces_spaces_with_underscores() -> void:
	var index_html := FileAccess.open(_report_dir + "/index.html", FileAccess.READ).get_as_text()
	assert_str(index_html).contains('href="./path/my_test_suite.html"')


func test_breadcrumb_href_in_suite_report_replaces_spaces_with_underscores() -> void:
	var suite_html := FileAccess.open(
		_report_dir + "/test_suites/my_test_suite.SomeTest.html", FileAccess.READ
	).get_as_text()
	assert_str(suite_html).contains('href="../path/my_test_suite.html"')


func test_suite_file_uses_underscores_not_spaces() -> void:
	assert_bool(FileAccess.file_exists(_report_dir + "/test_suites/my_test_suite.SomeTest.html")).is_true()
	assert_bool(FileAccess.file_exists(_report_dir + "/test_suites/my test suite.SomeTest.html")).is_false()
#endregion
