# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name TestSuiteScannerTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/GdUnitTestSuiteScanner.gd'

func before_test() -> void:
	ProjectSettings.set_setting(GdUnitSettings.TEST_SUITE_NAMING_CONVENTION, GdUnitSettings.NAMING_CONVENTIONS.AUTO_DETECT)
	clean_temp_dir()


func after() -> void:
	clean_temp_dir()


func resolve_path(source_file :String) -> String:
	return GdUnitTestSuiteScanner.resolve_test_suite_path(source_file, "_test_")


func test_resolve_test_suite_path_project() -> void:
	# if no `src` folder found use test folder as root
	assert_str(resolve_path("res://foo.gd")).is_equal("res://_test_/foo_test.gd")
	assert_str(resolve_path("res://project_name/module/foo.gd")).is_equal("res://_test_/project_name/module/foo_test.gd")
	# otherwise build relative to 'src'
	assert_str(resolve_path("res://src/foo.gd")).is_equal("res://_test_/foo_test.gd")
	assert_str(resolve_path("res://project_name/src/foo.gd")).is_equal("res://project_name/_test_/foo_test.gd")
	assert_str(resolve_path("res://project_name/src/module/foo.gd")).is_equal("res://project_name/_test_/module/foo_test.gd")


func test_resolve_test_suite_path_plugins() -> void:
	assert_str(resolve_path("res://addons/plugin_a/foo.gd")).is_equal("res://addons/plugin_a/_test_/foo_test.gd")
	assert_str(resolve_path("res://addons/plugin_a/src/foo.gd")).is_equal("res://addons/plugin_a/_test_/foo_test.gd")


func test_resolve_test_suite_path__no_test_root() -> void:
	# from a project path
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/src/models/events/ModelChangedEvent.gd", ""))\
		.is_equal("res://project/src/models/events/ModelChangedEventTest.gd")
	# from a plugin path
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://addons/MyPlugin/src/models/events/ModelChangedEvent.gd", ""))\
		.is_equal("res://addons/MyPlugin/src/models/events/ModelChangedEventTest.gd")
	# located in user path
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("user://project/src/models/events/ModelChangedEvent.gd", ""))\
		.is_equal("user://project/src/models/events/ModelChangedEventTest.gd")


func test_resolve_test_suite_path__path_contains_src_folder() -> void:
	# from a project path
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/src/models/events/ModelChangedEvent.gd"))\
		.is_equal("res://project/test/models/events/ModelChangedEventTest.gd")
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/src/models/events/ModelChangedEvent.gd", "custom_test"))\
		.is_equal("res://project/custom_test/models/events/ModelChangedEventTest.gd")
	# from a plugin path
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://addons/MyPlugin/src/models/events/ModelChangedEvent.gd"))\
		.is_equal("res://addons/MyPlugin/test/models/events/ModelChangedEventTest.gd")
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://addons/MyPlugin/src/models/events/ModelChangedEvent.gd", "custom_test"))\
		.is_equal("res://addons/MyPlugin/custom_test/models/events/ModelChangedEventTest.gd")
	# located in user path
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("user://project/src/models/events/ModelChangedEvent.gd"))\
		.is_equal("user://project/test/models/events/ModelChangedEventTest.gd")
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("user://project/src/models/events/ModelChangedEvent.gd", "custom_test"))\
		.is_equal("user://project/custom_test/models/events/ModelChangedEventTest.gd")


func test_resolve_test_suite_path__path_not_contains_src_folder() -> void:
	# from a project path
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/models/events/ModelChangedEvent.gd"))\
		.is_equal("res://test/project/models/events/ModelChangedEventTest.gd")
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/models/events/ModelChangedEvent.gd", "custom_test"))\
		.is_equal("res://custom_test/project/models/events/ModelChangedEventTest.gd")
	# from a plugin path
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://addons/MyPlugin/models/events/ModelChangedEvent.gd"))\
		.is_equal("res://addons/MyPlugin/test/models/events/ModelChangedEventTest.gd")
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://addons/MyPlugin/models/events/ModelChangedEvent.gd", "custom_test"))\
		.is_equal("res://addons/MyPlugin/custom_test/models/events/ModelChangedEventTest.gd")
	# located in user path
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("user://project/models/events/ModelChangedEvent.gd"))\
		.is_equal("user://test/project/models/events/ModelChangedEventTest.gd")
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("user://project/models/events/ModelChangedEvent.gd", "custom_test"))\
		.is_equal("user://custom_test/project/models/events/ModelChangedEventTest.gd")


func test_test_suite_exists() -> void:
	var path_exists := "res://addons/gdUnit4/test/resources/core/GeneratedPersonTest.gd"
	var path_not_exists := "res://addons/gdUnit4/test/resources/core/FamilyTest.gd"
	assert_bool(GdUnitTestSuiteScanner.test_suite_exists(path_exists)).is_true()
	assert_bool(GdUnitTestSuiteScanner.test_suite_exists(path_not_exists)).is_false()


func test_test_case_exists() -> void:
	var test_suite_path := "res://addons/gdUnit4/test/resources/core/GeneratedPersonTest.gd"
	assert_bool(GdUnitTestSuiteScanner.test_case_exists(test_suite_path, "name")).is_true()
	assert_bool(GdUnitTestSuiteScanner.test_case_exists(test_suite_path, "last_name")).is_false()


func test_create_test_suite_pascal_case_path() -> void:
	var temp_dir := create_temp_dir("TestSuiteScannerTest")
	# checked source with class_name is set
	var source_path := "res://addons/gdUnit4/test/core/resources/naming_conventions/PascalCaseWithClassName.gd"
	var suite_path := temp_dir + "/test/MyClassTest1.gd"
	var result := GdUnitTestSuiteScanner.create_test_suite(suite_path, source_path)
	assert_bool(result.is_success()).is_true()
	assert_str(result.value()).is_equal(suite_path)
	assert_file(result.value()).exists()\
		.is_file()\
		.is_script()\
		.contains_exactly([
			"# GdUnit generated TestSuite",
			"class_name PascalCaseWithClassNameTest",
			"extends GdUnitTestSuite",
			"@warning_ignore('unused_parameter')",
			"@warning_ignore('return_value_discarded')",
			"",
			"# TestSuite generated from",
			"const __source: String = '%s'" % source_path,
			""])
	# checked source with class_name is NOT set
	source_path = "res://addons/gdUnit4/test/core/resources/naming_conventions/PascalCaseWithoutClassName.gd"
	suite_path = temp_dir + "/test/MyClassTest2.gd"
	result = GdUnitTestSuiteScanner.create_test_suite(suite_path, source_path)
	assert_bool(result.is_success()).is_true()
	assert_str(result.value()).is_equal(suite_path)
	assert_file(result.value()).exists()\
		.is_file()\
		.is_script()\
		.contains_exactly([
			"# GdUnit generated TestSuite",
			"class_name PascalCaseWithoutClassNameTest",
			"extends GdUnitTestSuite",
			"@warning_ignore('unused_parameter')",
			"@warning_ignore('return_value_discarded')",
			"",
			"# TestSuite generated from",
			"const __source: String = '%s'" % source_path,
			""])


func test_create_test_suite_snake_case_path() -> void:
	var temp_dir := create_temp_dir("TestSuiteScannerTest")
	# checked source with class_name is set
	var source_path :="res://addons/gdUnit4/test/core/resources/naming_conventions/snake_case_with_class_name.gd"
	var suite_path := temp_dir + "/test/my_class_test1.gd"
	var result := GdUnitTestSuiteScanner.create_test_suite(suite_path, source_path)
	assert_bool(result.is_success()).is_true()
	assert_str(result.value()).is_equal(suite_path)
	assert_file(result.value()).exists()\
		.is_file()\
		.is_script()\
		.contains_exactly([
			"# GdUnit generated TestSuite",
			"class_name SnakeCaseWithClassNameTest",
			"extends GdUnitTestSuite",
			"@warning_ignore('unused_parameter')",
			"@warning_ignore('return_value_discarded')",
			"",
			"# TestSuite generated from",
			"const __source: String = '%s'" % source_path,
			""])
	# checked source with class_name is NOT set
	source_path ="res://addons/gdUnit4/test/core/resources/naming_conventions/snake_case_without_class_name.gd"
	suite_path = temp_dir + "/test/my_class_test2.gd"
	result = GdUnitTestSuiteScanner.create_test_suite(suite_path, source_path)
	assert_bool(result.is_success()).is_true()
	assert_str(result.value()).is_equal(suite_path)
	assert_file(result.value()).exists()\
		.is_file()\
		.is_script()\
		.contains_exactly([
			"# GdUnit generated TestSuite",
			"class_name SnakeCaseWithoutClassNameTest",
			"extends GdUnitTestSuite",
			"@warning_ignore('unused_parameter')",
			"@warning_ignore('return_value_discarded')",
			"",
			"# TestSuite generated from",
			"const __source: String = '%s'" % source_path,
			""])


func test_create_test_case() -> void:
	# store test class checked temp dir
	var tmp_path := create_temp_dir("TestSuiteScannerTest")
	var source_path := "res://addons/gdUnit4/test/resources/core/Person.gd"
	# generate new test suite with test 'test_last_name()'
	var test_suite_path := tmp_path + "/test/PersonTest.gd"
	var result := GdUnitTestSuiteScanner.create_test_case(test_suite_path, "last_name", source_path)
	assert_bool(result.is_success()).is_true()
	var info :Dictionary = result.value()
	assert_int(info.get("line")).is_equal(11)
	assert_file(info.get("path")).exists()\
		.is_file()\
		.is_script()\
		.contains_exactly([
			"# GdUnit generated TestSuite",
			"class_name PersonTest",
			"extends GdUnitTestSuite",
			"@warning_ignore('unused_parameter')",
			"@warning_ignore('return_value_discarded')",
			"",
			"# TestSuite generated from",
			"const __source: String = '%s'" % source_path,
			"",
			"",
			"func test_last_name() -> void:",
			"	# remove this line and complete your test",
			"	assert_not_yet_implemented()",
			""])
	# try to add again
	result = GdUnitTestSuiteScanner.create_test_case(test_suite_path, "last_name", source_path)
	assert_bool(result.is_success()).is_true()
	assert_that(result.value()).is_equal({"line" : 16, "path": test_suite_path})


# https://github.com/MikeSchulze/gdUnit4/issues/25
func test_build_test_suite_path() -> void:
	# checked project root
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://new_script.gd")).is_equal("res://test/new_script_test.gd")

	# checked project without src folder
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://foo/bar/new_script.gd")).is_equal("res://test/foo/bar/new_script_test.gd")

	# project code structured by 'src'
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://src/new_script.gd")).is_equal("res://test/new_script_test.gd")
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://src/foo/bar/new_script.gd")).is_equal("res://test/foo/bar/new_script_test.gd")
	# folder name contains 'src' in name
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://foo/srcare/new_script.gd")).is_equal("res://test/foo/srcare/new_script_test.gd")

	# checked plugins without src folder
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://addons/plugin/foo/bar/new_script.gd")).is_equal("res://addons/plugin/test/foo/bar/new_script_test.gd")
	# plugin code structured by 'src'
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://addons/plugin/src/foo/bar/new_script.gd")).is_equal("res://addons/plugin/test/foo/bar/new_script_test.gd")

	# checked user temp folder
	var tmp_path := create_temp_dir("projectX/entity")
	var source_path := tmp_path + "/Person.gd"
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path(source_path)).is_equal("user://tmp/test/projectX/entity/PersonTest.gd")


func test_scan_by_inheritance_class_name() -> void:
	var scanner :GdUnitTestSuiteScanner = GdUnitTestSuiteScanner.new()
	var test_suites := scanner.scan("res://addons/gdUnit4/test/core/resources/scan_testsuite_inheritance/by_class_name/")

	assert_array(test_suites).has_size(3)
	# sort by names
	assert_array(test_suites).extract("resource_path")\
		.contains_exactly_in_any_order([
			"res://addons/gdUnit4/test/core/resources/scan_testsuite_inheritance/by_class_name/BaseTest.gd",
			"res://addons/gdUnit4/test/core/resources/scan_testsuite_inheritance/by_class_name/ExtendedTest.gd",
			"res://addons/gdUnit4/test/core/resources/scan_testsuite_inheritance/by_class_name/ExtendsExtendedTest.gd"])


func test_get_test_case_line_number() -> void:
	assert_int(GdUnitTestSuiteScanner.get_test_case_line_number("res://addons/gdUnit4/test/core/GdUnitTestSuiteScannerTest.gd", "get_test_case_line_number")).is_equal(255)
	assert_int(GdUnitTestSuiteScanner.get_test_case_line_number("res://addons/gdUnit4/test/core/GdUnitTestSuiteScannerTest.gd", "unknown")).is_equal(-1)


func test__to_naming_convention() -> void:
	ProjectSettings.set_setting(GdUnitSettings.TEST_SUITE_NAMING_CONVENTION, GdUnitSettings.NAMING_CONVENTIONS.AUTO_DETECT)
	assert_str(GdUnitTestSuiteScanner._to_naming_convention("MyClass")).is_equal("MyClassTest")
	assert_str(GdUnitTestSuiteScanner._to_naming_convention("my_class")).is_equal("my_class_test")
	assert_str(GdUnitTestSuiteScanner._to_naming_convention("myclass")).is_equal("myclass_test")

	ProjectSettings.set_setting(GdUnitSettings.TEST_SUITE_NAMING_CONVENTION, GdUnitSettings.NAMING_CONVENTIONS.SNAKE_CASE)
	assert_str(GdUnitTestSuiteScanner._to_naming_convention("MyClass")).is_equal("my_class_test")
	assert_str(GdUnitTestSuiteScanner._to_naming_convention("my_class")).is_equal("my_class_test")
	assert_str(GdUnitTestSuiteScanner._to_naming_convention("myclass")).is_equal("myclass_test")

	ProjectSettings.set_setting(GdUnitSettings.TEST_SUITE_NAMING_CONVENTION, GdUnitSettings.NAMING_CONVENTIONS.PASCAL_CASE)
	assert_str(GdUnitTestSuiteScanner._to_naming_convention("MyClass")).is_equal("MyClassTest")
	assert_str(GdUnitTestSuiteScanner._to_naming_convention("my_class")).is_equal("MyClassTest")
	assert_str(GdUnitTestSuiteScanner._to_naming_convention("myclass")).is_equal("MyclassTest")


func test_is_script_format_supported() -> void:
	assert_bool(GdUnitTestSuiteScanner._is_script_format_supported("res://exampe.gd")).is_true()
	assert_bool(GdUnitTestSuiteScanner._is_script_format_supported("res://exampe.gdns")).is_false()
	assert_bool(GdUnitTestSuiteScanner._is_script_format_supported("res://exampe.vs")).is_false()
	assert_bool(GdUnitTestSuiteScanner._is_script_format_supported("res://exampe.tres")).is_false()


func test_resolve_test_suite_path() -> void:
	# forcing the use of a test folder next to the source folder
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/src/folder/myclass.gd", "test")).is_equal("res://project/test/folder/myclass_test.gd")
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/src/folder/MyClass.gd", "test")).is_equal("res://project/test/folder/MyClassTest.gd")
	# forcing to use source directory to create the test
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/src/folder/myclass.gd", "")).is_equal("res://project/src/folder/myclass_test.gd")
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/src/folder/MyClass.gd", "")).is_equal("res://project/src/folder/MyClassTest.gd")
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/src/folder/myclass.gd", "/")).is_equal("res://project/src/folder/myclass_test.gd")
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/src/folder/MyClass.gd", "/")).is_equal("res://project/src/folder/MyClassTest.gd")


func test_resolve_test_suite_path_with_src_folders() -> void:
	# forcing the use of a test folder next
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/folder/myclass.gd", "test")).is_equal("res://test/project/folder/myclass_test.gd")
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/folder/MyClass.gd", "test")).is_equal("res://test/project/folder/MyClassTest.gd")
	# forcing to use source directory to create the test
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/folder/myclass.gd", "")).is_equal("res://project/folder/myclass_test.gd")
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/folder/MyClass.gd", "")).is_equal("res://project/folder/MyClassTest.gd")
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/folder/myclass.gd", "/")).is_equal("res://project/folder/myclass_test.gd")
	assert_str(GdUnitTestSuiteScanner.resolve_test_suite_path("res://project/folder/MyClass.gd", "/")).is_equal("res://project/folder/MyClassTest.gd")


func test_build_test_attribute_rejects_fuzzer_after_config_argument() -> void:
	var source_path := "res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteWithFuzzerAfterConfigArg.gd"
	var script: GDScript = load(source_path)
	var fd: GdFunctionDescriptor = GdScriptParser.new().get_function_descriptors(script, ["test_fuzzer_after_do_skip"]).front()

	var attribute := GdUnitTestSuiteScanner.new()._build_test_attribute(script, fd)

	assert_bool(attribute.is_skipped).is_true()
	assert_str(attribute.skip_reason).is_equal(
		"Fuzzer argument 'fuzzer_value' must be declared before the test config argument(s) [\"do_skip\"].")


func test_scan_test_suite_exclude_non_test_suites() -> void:
	var scanner :GdUnitTestSuiteScanner = GdUnitTestSuiteScanner.new()
	var test_suites := scanner.scan("res://addons/gdUnit4/test/core/resources/scan_testsuite_inheritance/plugin/")

	# we expect the scanner do not break on scanning plugin classes
	assert_array(test_suites).is_empty()
