# GdUnit generated TestSuite
class_name GdUnitHtmlPatternsTest
extends GdUnitTestSuite


func _make_suite_report(resource_path: String, suite_name: String) -> GdUnitTestSuiteReport:
	return GdUnitTestSuiteReport.new(resource_path, suite_name, 1, func(s: String) -> String: return s)


#region create_suite_record
func test_href_is_quoted() -> void:
	var report := _make_suite_report("res://test/game_test.gd", "game_test")
	var html := GdUnitHtmlPatterns.create_suite_record("./test_suites/game_test.html", report)
	assert_str(html).contains('href="./test_suites/game_test.html"')


func test_href_is_quoted_when_link_contains_spaces() -> void:
	var report := _make_suite_report("res://my test/game_test.gd", "game_test")
	var link := "./test_suites/my_test.game_test.html"
	var html := GdUnitHtmlPatterns.create_suite_record(link, report)
	assert_str(html).contains('href="%s"' % link)


func test_href_is_not_unquoted() -> void:
	var report := _make_suite_report("res://my test/game_test.gd", "game_test")
	var link := "./test_suites/my_test.game_test.html"
	var html := GdUnitHtmlPatterns.create_suite_record(link, report)
	assert_str(html).not_contains("href=%s" % link)
#endregion


#region get_path_as_link
func test_get_path_as_link_simple() -> void:
	var report := _make_suite_report("res://test/suite/game_test.gd", "game_test")
	assert_str(GdUnitHtmlPatterns.get_path_as_link(report)).is_equal("../path/test.suite.html")


func test_get_path_as_link_converts_slashes_to_dots() -> void:
	var report := _make_suite_report("res://a/b/c/game_test.gd", "game_test")
	assert_str(GdUnitHtmlPatterns.get_path_as_link(report)).is_equal("../path/a.b.c.html")
#endregion


#region create_suite_output_path
func test_create_suite_output_path_converts_slashes_to_dots() -> void:
	var result := GdUnitHtmlPatterns.create_suite_output_path("/reports", "test/suite", "MyTest")
	assert_str(result).is_equal("/reports/test_suites/test.suite.MyTest.html")


func test_create_suite_output_path_replaces_spaces_with_underscores() -> void:
	var result := GdUnitHtmlPatterns.create_suite_output_path("/reports", "my test/suite", "MyTest")
	assert_str(result).is_equal("/reports/test_suites/my_test.suite.MyTest.html")
#endregion


#region create_path_output_path
func test_create_path_output_path_converts_slashes_to_dots() -> void:
	var result := GdUnitHtmlPatterns.create_path_output_path("/reports", "test/suite")
	assert_str(result).is_equal("/reports/path/test.suite.html")


func test_create_path_output_path_replaces_spaces_with_underscores() -> void:
	var result := GdUnitHtmlPatterns.create_path_output_path("/reports", "my test/suite")
	assert_str(result).is_equal("/reports/path/my_test.suite.html")
#endregion


#region write_html_file
func test_write_html_file_creates_file_with_content() -> void:
	var dir := GdUnitFileAccess.create_temp_dir("html_patterns_test/write_content")
	var output_path := dir + "/output.html"
	GdUnitHtmlPatterns.write_html_file(output_path, "<html>test</html>")
	assert_bool(FileAccess.file_exists(output_path)).is_true()
	assert_str(FileAccess.open(output_path, FileAccess.READ).get_as_text()).is_equal("<html>test</html>")


func test_write_html_file_creates_missing_directory() -> void:
	var dir := GdUnitFileAccess.create_temp_dir("html_patterns_test")
	var output_path := dir + "/new_subdir/output.html"
	GdUnitHtmlPatterns.write_html_file(output_path, "<html/>")
	assert_bool(FileAccess.file_exists(output_path)).is_true()


func test_write_html_file_overwrites_existing_content() -> void:
	var dir := GdUnitFileAccess.create_temp_dir("html_patterns_test/overwrite")
	var output_path := dir + "/output.html"
	GdUnitHtmlPatterns.write_html_file(output_path, "<html>first</html>")
	GdUnitHtmlPatterns.write_html_file(output_path, "<html>second</html>")
	assert_str(FileAccess.open(output_path, FileAccess.READ).get_as_text()).is_equal("<html>second</html>")
#endregion
