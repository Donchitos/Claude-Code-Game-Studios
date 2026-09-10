extends GdUnitTestSuite


func test_discover_many_test() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.gd")

	var discovered_tests := []
	GdUnitTestDiscoverer.discover_tests(script,
		func discover(test_case: GdUnitTestCase) -> void:
			if test_case.test_name in ["test_case1", "test_case2", "test_parameterized_static"]:
				discovered_tests.append(test_case)
	)

	assert_array(discovered_tests)\
		.extractv(extr("test_name"), extr("display_name"))\
		.contains_exactly([
			tuple("test_case1", "test_case1"),
			tuple("test_case2", "test_case2"),
			tuple("test_parameterized_static", "test_parameterized_static:0 (1, 1)"),
			tuple("test_parameterized_static", "test_parameterized_static:1 (2, 2)"),
			tuple("test_parameterized_static", "test_parameterized_static:2 (3, 3)"),
		])


func test_discover_parameterized_test() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.gd")

	var discovered_tests := []
	GdUnitTestDiscoverer.discover_tests(script,
		func discover(test_case: GdUnitTestCase) -> void:
			if test_case.test_name == "test_parameterized_static":
				discovered_tests.append(test_case)
	)

	assert_array(discovered_tests)\
		.extractv(extr("test_name"), extr("display_name"))\
		.contains_exactly([
			tuple("test_parameterized_static", "test_parameterized_static:0 (1, 1)"),
			tuple("test_parameterized_static", "test_parameterized_static:1 (2, 2)"),
			tuple("test_parameterized_static", "test_parameterized_static:2 (3, 3)"),
		])


func test_discover_tests() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.gd")

	var discovered_tests := []
	GdUnitTestDiscoverer.discover_tests(script,\
		func discover(test_case: GdUnitTestCase) -> void:
			discovered_tests.append(test_case)
	)

	assert_array(discovered_tests)\
		.extractv(extr("test_name"), extr("display_name"))\
		.contains_exactly([
			tuple("test_case1", "test_case1"),
			tuple("test_case2", "test_case2"),
			tuple("test_parameterized_static", "test_parameterized_static:0 (1, 1)"),
			tuple("test_parameterized_static", "test_parameterized_static:1 (2, 2)"),
			tuple("test_parameterized_static", "test_parameterized_static:2 (3, 3)"),
			tuple("test_parameterized_static_external", "test_parameterized_static_external:0 (<null>)"),
			tuple("test_parameterized_static_external", "test_parameterized_static_external:1 (%s)" % Vector2.ONE),
			tuple("test_parameterized_static_external", "test_parameterized_static_external:2 (%s)" % Vector2i.ONE),
			tuple("test_parameterized_dynamic", "test_parameterized_dynamic:0 (<null>)"),
			tuple("test_parameterized_dynamic", "test_parameterized_dynamic:1 (%s)" % Vector2.ONE),
			tuple("test_parameterized_dynamic", "test_parameterized_dynamic:2 (%s)" % Vector2i.ONE),
			tuple("test_日本語", "test_日本語"),
		])


func test_discover_tests_on_GdUnitTestSuite() -> void:
	var script: GDScript = load("res://addons/gdUnit4/src/GdUnitTestSuite.gd")

	var discovered_tests := []
	GdUnitTestDiscoverer.discover_tests(script,\
		func discover(test_case: GdUnitTestCase) -> void:
			discovered_tests.append(test_case)
	)

	# we expect no test covered from the base implementaion of GdUnitTestSuite
	assert_array(discovered_tests).is_empty()


func test_discover_tests_inherited() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/scan_testsuite_inheritance/by_class_name/ExtendsExtendedTest.gd")

	var discovered_tests := []
	GdUnitTestDiscoverer.discover_tests(script,\
		func discover(test_case: GdUnitTestCase) -> void:
			discovered_tests.append(test_case)
	)

	assert_array(discovered_tests)\
		.extractv(extr("test_name"), extr("display_name"), extr("fully_qualified_name"))\
		.contains_exactly([
			tuple("test_foo3", "test_foo3", "addons.gdUnit4.test.core.resources.scan_testsuite_inheritance.by_class_name.ExtendsExtendedTest.test_foo3"),
			tuple("test_foo2", "test_foo2", "addons.gdUnit4.test.core.resources.scan_testsuite_inheritance.by_class_name.ExtendsExtendedTest.test_foo2"),
			tuple("test_foo1", "test_foo1", "addons.gdUnit4.test.core.resources.scan_testsuite_inheritance.by_class_name.ExtendsExtendedTest.test_foo1")
		])


#if GDUNIT4NET_API_V5
func test_discover_csharp_tests(_do_skip := !GdUnit4CSharpApiLoader.is_api_loaded()) -> void:
	var script :Script = load("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.cs")
	var discovered_tests := []
	GdUnitTestDiscoverer.discover_tests(script,\
		func discover(test_case: GdUnitTestCase) -> void:
			discovered_tests.append(test_case)
	)
	assert_array(discovered_tests)\
		.extractv(extr("test_name"), extr("display_name"), extr("fully_qualified_name"))\
		.contains_exactly([
			tuple("TestCase1", "TestCase1", "gdUnit4.addons.gdUnit4.test.core.discovery.resources.DiscoverExampleTestSuite.TestCase1"),
			tuple("TestCase2", "TestCase2", "gdUnit4.addons.gdUnit4.test.core.discovery.resources.DiscoverExampleTestSuite.TestCase2")
		])
#endif


func test_scan_test_directories() -> void:
	assert_array(GdUnitTestDiscoverer.scan_test_directories("res://", "test", [])).contains_exactly([
		"res://addons/gdUnit4/test"
	])
	# for root folders
	assert_array(GdUnitTestDiscoverer.scan_test_directories("res://", "", [])).contains_exactly([
		"res://addons", "res://assets"
	])
	assert_array(GdUnitTestDiscoverer.scan_test_directories("res://", "/", [])).contains_exactly([
		"res://addons", "res://assets"
	])
	assert_array(GdUnitTestDiscoverer.scan_test_directories("res://", "res://", [])).contains_exactly([
		"res://addons", "res://assets"
	])
	# a test folder not exists
	assert_array(GdUnitTestDiscoverer.scan_test_directories("res://", "notest", [])).is_empty()
	# for excluded folder (contain .gdignore file)
	assert_array(GdUnitTestDiscoverer.scan_test_directories("res://", "excluded", [])).is_empty()


func test_scan_all_test_directories() -> void:
	# Test when test_root_folder is empty
	assert_array(GdUnitTestDiscoverer.scan_all_test_directories("")).contains_exactly(["res://"])

	# Test when test_root_folder is "/"
	assert_array(GdUnitTestDiscoverer.scan_all_test_directories("/")).contains_exactly(["res://"])

	# Test when test_root_folder is "res://"
	assert_array(GdUnitTestDiscoverer.scan_all_test_directories("res://")).contains_exactly(["res://"])

	# Test when test_root_folder is set to a specific folder
	assert_array(GdUnitTestDiscoverer.scan_all_test_directories("test")).contains_exactly(["res://addons/gdUnit4/test"])

	# Test when test_root_folder is set to something which doesn't exist
	assert_array(GdUnitTestDiscoverer.scan_all_test_directories("notest")).is_empty()


func test_discover_tests_with_fuzzers() -> void:
	# Setup
	var script: GDScript = load("res://addons/gdUnit4/test/core/parse/resources/TestSuiteWithFuzzers.gd")

	# Act
	var tests := GdUnitTestDiscoverer.discover_tests_from_gd_script(script)

	# Verify
	assert_array(tests)\
		.extractv(
			extr("suite_name"),
			extr("test_name"),
			extr("source_file"),
			extr("line_number"),
			extr("attribute_index"))\
		.contains_exactly(
			tuple("TestSuiteWithFuzzers", "test_do_skip_as_first_param", script.resource_path, 4, -1),
			tuple("TestSuiteWithFuzzers", "test_do_skip_in_middle", script.resource_path, 11, -1),
			tuple("TestSuiteWithFuzzers", "test_do_skip_as_last_param", script.resource_path, 18, -1),
		)


func test_discover_tests_with_static_parameterset() -> void:
	# Setup
	var script: GDScript = load("res://addons/gdUnit4/test/core/parse/resources/TestSuiteWithStaticParameterSet.gd")

	# Act
	var tests := GdUnitTestDiscoverer.discover_tests_from_gd_script(script)

	# Verify
	assert_array(tests)\
		.extractv(
			extr("suite_name"),
			extr("test_name"),
			extr("source_file"),
			extr("line_number"),
			extr("attribute_index"))\
		.contains_exactly(
			tuple("TestSuiteWithStaticParameterSet", "test_parameterized_bool_value", script.resource_path, 20, 0),
			tuple("TestSuiteWithStaticParameterSet", "test_parameterized_bool_value", script.resource_path, 20, 1),
			tuple("TestSuiteWithStaticParameterSet", "test_parameterized_int_values", script.resource_path, 27, 0),
			tuple("TestSuiteWithStaticParameterSet", "test_parameterized_int_values", script.resource_path, 27, 1),
			tuple("TestSuiteWithStaticParameterSet", "test_parameterized_int_values", script.resource_path, 27, 2),
			tuple("TestSuiteWithStaticParameterSet", "test_parameterized_float_values", script.resource_path, 35, 0),
			tuple("TestSuiteWithStaticParameterSet", "test_parameterized_float_values", script.resource_path, 35, 1),
			tuple("TestSuiteWithStaticParameterSet", "test_parameterized_float_values", script.resource_path, 35, 2),
			tuple("TestSuiteWithStaticParameterSet", "test_parameterized_string_values", script.resource_path, 42, 0),
			tuple("TestSuiteWithStaticParameterSet", "test_parameterized_string_values", script.resource_path, 42, 1),
			tuple("TestSuiteWithStaticParameterSet", "test_parameterized_string_values", script.resource_path, 42, 2),
			tuple("TestSuiteWithStaticParameterSet", "test_parameterized_Vector2_values", script.resource_path, 50, 0),
			tuple("TestSuiteWithStaticParameterSet", "test_parameterized_Vector2_values", script.resource_path, 50, 1),
			tuple("TestSuiteWithStaticParameterSet", "test_parameterized_Vector2_values", script.resource_path, 50, 2),
			tuple("TestSuiteWithStaticParameterSet", "test_with_instance_parameters", script.resource_path, 58, 0),
			tuple("TestSuiteWithStaticParameterSet", "test_with_instance_parameters", script.resource_path, 58, 1),
			tuple("TestSuiteWithStaticParameterSet", "test_with_instance_parameters", script.resource_path, 58, 2),
			tuple("TestSuiteWithStaticParameterSet", "test_with_instance_parameters", script.resource_path, 58, 3),
			tuple("TestSuiteWithStaticParameterSet", "test_with_instance_parameters", script.resource_path, 58, 4),
		)


func test_discover_tests_with_dynamic_parameterset() -> void:
	# Setup
	var script: GDScript = load("res://addons/gdUnit4/test/core/parse/resources/TestSuiteWithDynamicParameterSet.gd")

	# Act
	var tests := GdUnitTestDiscoverer.discover_tests_from_gd_script(script)

	# Verify
	assert_array(tests)\
		.extractv(
			extr("suite_name"),
			extr("test_name"),
			extr("source_file"),
			extr("line_number"),
			extr("attribute_index"))\
		.contains_exactly(
			# test_with_dynamic_parameters_typed_array
			tuple("TestSuiteWithDynamicParameterSet", "test_with_dynamic_parameters_typed_array", script.resource_path, 25, 0),
			tuple("TestSuiteWithDynamicParameterSet", "test_with_dynamic_parameters_typed_array", script.resource_path, 25, 1),
			# test_with_dynamic_parameters_untyped_array
			tuple("TestSuiteWithDynamicParameterSet", "test_with_dynamic_parameters_untyped_array", script.resource_path, 29, 0),
			tuple("TestSuiteWithDynamicParameterSet", "test_with_dynamic_parameters_untyped_array", script.resource_path, 29, 1),
			# test_with_dynamic_parameterset
			tuple("TestSuiteWithDynamicParameterSet", "test_with_dynamic_parameterset", script.resource_path, 33, 0),
			tuple("TestSuiteWithDynamicParameterSet", "test_with_dynamic_parameterset", script.resource_path, 33, 1),
			tuple("TestSuiteWithDynamicParameterSet", "test_with_dynamic_parameterset", script.resource_path, 33, 2),
			tuple("TestSuiteWithDynamicParameterSet", "test_with_dynamic_parameterset", script.resource_path, 33, 3),
			tuple("TestSuiteWithDynamicParameterSet", "test_with_dynamic_parameterset", script.resource_path, 33, 4),
			tuple("TestSuiteWithDynamicParameterSet", "test_with_dynamic_parameterset", script.resource_path, 33, 5),
			tuple("TestSuiteWithDynamicParameterSet", "test_with_dynamic_parameterset", script.resource_path, 33, 6),
			tuple("TestSuiteWithDynamicParameterSet", "test_with_dynamic_parameterset", script.resource_path, 33, 7),
			tuple("TestSuiteWithDynamicParameterSet", "test_with_dynamic_parameterset", script.resource_path, 33, 8),
			tuple("TestSuiteWithDynamicParameterSet", "test_with_dynamic_parameterset", script.resource_path, 33, 9),
		)
