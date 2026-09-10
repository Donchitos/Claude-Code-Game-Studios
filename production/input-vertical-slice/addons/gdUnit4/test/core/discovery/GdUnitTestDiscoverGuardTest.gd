# GdUnit generated TestSuite
class_name GdUnitTestDiscoverGuardTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')



func test_inital() -> void:
	var discoverer: GdUnitTestDiscoverGuard = auto_free(GdUnitTestDiscoverGuard.new())

	assert_dict(discoverer._discover_cache).is_empty()


func test_sync_cache() -> void:
	# setup example tests
	var test1 := GdUnitTestCase.from("res://test/my_test_suite.gd", "res://test/my_test_suite.gd", 23, "test_a")
	var test2 := GdUnitTestCase.from("res://test/my_test_suite.gd", "res://test/my_test_suite.gd", 42, "test_b")

	# simulate running test dicovery
	var discoverer: GdUnitTestDiscoverGuard = auto_free(GdUnitTestDiscoverGuard.new())
	discoverer.sync_test_added(test1)
	discoverer.sync_test_added(test2)
	# verify the cache contains the discovered test id's
	assert_dict(discoverer._discover_cache).contains_key_value("res://test/my_test_suite.gd", [test1, test2])

	# simulate DISCOVER_START
	discoverer.handle_discover_events(GdUnitEventTestDiscoverStart.new())
	# verify the cache is cleaned
	assert_dict(discoverer._discover_cache).is_empty()


func test_discover_new_suite_GDScript() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.gd")
	assert_that(script).is_not_null()
	if script == null:
		return

	var discoverer: GdUnitTestDiscoverGuard = auto_free(GdUnitTestDiscoverGuard.new())
	# test initial the cache is empty
	assert_dict(discoverer._discover_cache).is_empty()

	# simulate discovery of a new test suite
	var discovered_tests: Array[GdUnitTestCase] = []
	# we overwrite the default discover sync to catch the tests and not emit `gdunit_test_discovered`
	await discoverer.discover(script, func(test_case: GdUnitTestCase) -> void:
		discovered_tests.append(test_case)
		# we need to manual update the cache here, this is normal made by gdunit_test_discovered signal
		discoverer.sync_test_added(test_case)
	)

	# verify the all tests are discovered
	assert_array(discovered_tests).has_size(12)
	assert_array(discovered_tests).extractv(extr("test_name"), extr("attribute_index")).contains_exactly([
		tuple("test_case1", -1),
		tuple("test_case2", -1),
		tuple("test_parameterized_static", 0),
		tuple("test_parameterized_static", 1),
		tuple("test_parameterized_static", 2),
		tuple("test_parameterized_static_external", 0),
		tuple("test_parameterized_static_external", 1),
		tuple("test_parameterized_static_external", 2),
		tuple("test_parameterized_dynamic", 0),
		tuple("test_parameterized_dynamic", 1),
		tuple("test_parameterized_dynamic", 2),
		tuple("test_日本語", -1),
	])

	# verify the cache now contains all discovered tests
	assert_dict(discoverer._discover_cache)\
		.contains_key_value(script.resource_path, discovered_tests)


func test_discover_deleted_test_GDScript() -> void:
	var script := load_non_cached("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.gd")
	# using debug mode to true to collect the change set
	var discoverer: GdUnitTestDiscoverGuard = auto_free(GdUnitTestDiscoverGuard.new(true))

	var discovered_tests: Array[GdUnitTestCase] = []
	var expected_deleted_tests: Array[GdUnitTestCase] = []
	# simulate initial discovery of a new test suite
	# we overwrite the default discover sync to catch the tests and not emit `gdunit_test_discovered`
	await discoverer.discover(script, func(test_case: GdUnitTestCase) -> void:
		# we need to manual update the cache here, this is normal made by gdunit_test_discovered signal
		discoverer.sync_test_added(test_case)
		discovered_tests.append(test_case)
		# we save the tests for later verify to delete
		if test_case.test_name in ["test_case1", "test_case2"]:
			expected_deleted_tests.append(test_case)
	)
	# verify the expected tests are collected
	assert_array(expected_deleted_tests).has_size(2)
	assert_array(discovered_tests).has_size(12)

	# we simmulate deleted tests
	script.source_code = script.source_code.replace("test_case1", "_test_case1").replace("test_case2", "_test_case2")
	assert_int(script.reload(true)).is_equal(OK)

	# calling the discover like when a script change is emited by a save action
	await discoverer.discover(script, func(test_case: GdUnitTestCase) -> void:
		# we need to manual update the cache here, this is normal made by gdunit_test_discovered signal
		discoverer.sync_test_added(test_case)
	)

	# verify discovery detects the two deleted tests
	var changed_tests: Array[GdUnitTestCase] = discoverer._discovered_changes["changed_tests"]
	var deleted_tests: Array[GdUnitTestCase] = discoverer._discovered_changes["deleted_tests"]
	var added_tests: Array[GdUnitTestCase] = discoverer._discovered_changes["added_tests"]
	assert_array(changed_tests).is_empty()
	assert_array(deleted_tests).contains_exactly(expected_deleted_tests)
	assert_array(added_tests).is_empty()

	# verify the cache now contains all discovered tests reduced by the deleted tests
	assert_array(discoverer._discover_cache.get(script.resource_path))\
		.extractv(extr("guid"), extr("test_name"), extr("attribute_index"), extr("line_number"))\
		.contains_exactly([
			tuple(discovered_tests[2].guid, "test_parameterized_static", 0, 18),
			tuple(discovered_tests[3].guid, "test_parameterized_static", 1, 18),
			tuple(discovered_tests[4].guid, "test_parameterized_static", 2, 18),
			tuple(discovered_tests[5].guid, "test_parameterized_static_external", 0, 26),
			tuple(discovered_tests[6].guid, "test_parameterized_static_external", 1, 26),
			tuple(discovered_tests[7].guid, "test_parameterized_static_external", 2, 26),
			tuple(discovered_tests[8].guid, "test_parameterized_dynamic", 0, 32),
			tuple(discovered_tests[9].guid, "test_parameterized_dynamic", 1, 32),
			tuple(discovered_tests[10].guid, "test_parameterized_dynamic", 2, 32),
			tuple(discovered_tests[11].guid, "test_日本語", -1, 38),
		])


func test_discover_added_test_GDScript() -> void:
	var script := load_non_cached("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.gd")
	# using debug mode to true to collect the change set
	var discoverer: GdUnitTestDiscoverGuard = auto_free(GdUnitTestDiscoverGuard.new(true))

	var discovered_tests: Array[GdUnitTestCase] = []
	# simulate initial discovery of a new test suite
	# we overwrite the default discover sync to catch the tests and not emit `gdunit_test_discovered`
	await discoverer.discover(script, func(test_case: GdUnitTestCase) -> void:
		# we need to manual update the cache here, this is normal made by gdunit_test_discovered signal
		discoverer.sync_test_added(test_case)
		discovered_tests.append(test_case)
	)

	# we simmulate adding two new tests
	script.source_code += """
		func test_case3() -> void:
			assert_bool(true).is_equal(true);


		func test_case4() -> void:
			assert_bool(false).is_equal(false);
		""".dedent()
	assert_int(script.reload(true)).is_equal(OK)

	var expected_added_tests: Array[GdUnitTestCase] = []
	# calling the discover like when a script change is emited by a save action
	await discoverer.discover(script, func(test_case: GdUnitTestCase) -> void:
		# we need to manual update the cache here, this is normal made by gdunit_test_discovered signal
		discoverer.sync_test_added(test_case)
		expected_added_tests.append(test_case)
	)
	# verify the expected tests are collected
	assert_array(expected_added_tests).has_size(2)

	# verify discovery detects the two deleted tests
	var changed_tests: Array[GdUnitTestCase] = discoverer._discovered_changes["changed_tests"]
	var deleted_tests: Array[GdUnitTestCase] = discoverer._discovered_changes["deleted_tests"]
	var added_tests: Array[GdUnitTestCase] = discoverer._discovered_changes["added_tests"]
	assert_array(changed_tests).is_empty()
	assert_array(deleted_tests).is_empty()
	assert_array(added_tests).contains_exactly(expected_added_tests)

	# verify the cache now contains all discovered tests plus new discovered tests
	assert_array(discoverer._discover_cache.get(script.resource_path))\
		.extractv(extr("guid"), extr("test_name"), extr("attribute_index"), extr("line_number"))\
		.contains_exactly([
			tuple(discovered_tests[0].guid, "test_case1", -1, 10),
			tuple(discovered_tests[1].guid, "test_case2", -1, 14),
			tuple(discovered_tests[2].guid, "test_parameterized_static", 0, 18),
			tuple(discovered_tests[3].guid, "test_parameterized_static", 1, 18),
			tuple(discovered_tests[4].guid, "test_parameterized_static", 2, 18),
			tuple(discovered_tests[5].guid, "test_parameterized_static_external", 0, 26),
			tuple(discovered_tests[6].guid, "test_parameterized_static_external", 1, 26),
			tuple(discovered_tests[7].guid, "test_parameterized_static_external", 2, 26),
			tuple(discovered_tests[8].guid, "test_parameterized_dynamic", 0, 32),
			tuple(discovered_tests[9].guid, "test_parameterized_dynamic", 1, 32),
			tuple(discovered_tests[10].guid, "test_parameterized_dynamic", 2, 32),
			tuple(discovered_tests[11].guid, "test_日本語", -1, 38),
			tuple(expected_added_tests[0].guid, "test_case3", -1, 48),
			tuple(expected_added_tests[1].guid, "test_case4", -1, 52),
		])


func test_discover_renamed_test_GDScript() -> void:
	var script := load_non_cached("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.gd")
	# using debug mode to true to collect the change set
	var discoverer: GdUnitTestDiscoverGuard = auto_free(GdUnitTestDiscoverGuard.new(true))

	var discovered_tests: Array[GdUnitTestCase] = []
	var expected_renamed_tests: Array[GdUnitTestCase] = []
	# simulate initial discovery of a new test suite
	# we overwrite the default discover sync to catch the tests and not emit `gdunit_test_discovered`
	await discoverer.discover(script, func(test_case: GdUnitTestCase) -> void:
		# we need to manual update the cache here, this is normal made by gdunit_test_discovered signal
		discoverer.sync_test_added(test_case)
		discovered_tests.append(test_case)
		# we save the tests for later verify as renemaed
		if test_case.test_name in ["test_case1", "test_case2"]:
			expected_renamed_tests.append(test_case)
	)
	# verify the expected tests are collected
	assert_array(expected_renamed_tests).has_size(2)

	# we simmulate deleted tests
	script.source_code = script.source_code.replace("test_case1", "test_case11").replace("test_case2", "test_foo")
	assert_int(script.reload(true)).is_equal(OK)

	# calling the discover like when a script change is emited by a save action
	await discoverer.discover(script, func(test_case: GdUnitTestCase) -> void:
		# we need to manual update the cache here, this is normal made by gdunit_test_discovered signal
		discoverer.sync_test_added(test_case)
	)

	# verify discovery detects the two deleted tests
	var changed_tests: Array[GdUnitTestCase] = discoverer._discovered_changes["changed_tests"]
	var deleted_tests: Array[GdUnitTestCase] = discoverer._discovered_changes["deleted_tests"]
	var added_tests: Array[GdUnitTestCase] = discoverer._discovered_changes["added_tests"]
	assert_array(changed_tests).contains_exactly(expected_renamed_tests)
	assert_array(deleted_tests).is_empty()
	assert_array(added_tests).is_empty()

	# verify the cache now contains all discovered tests inclusive renamed once
	assert_array(discoverer._discover_cache.get(script.resource_path))\
		.extractv(extr("guid"), extr("test_name"), extr("attribute_index"), extr("line_number"))\
		.contains_exactly([
			tuple(discovered_tests[0].guid, "test_case11", -1, 10),
			tuple(discovered_tests[1].guid, "test_foo", -1, 14),
			tuple(discovered_tests[2].guid, "test_parameterized_static", 0, 18),
			tuple(discovered_tests[3].guid, "test_parameterized_static", 1, 18),
			tuple(discovered_tests[4].guid, "test_parameterized_static", 2, 18),
			tuple(discovered_tests[5].guid, "test_parameterized_static_external", 0, 26),
			tuple(discovered_tests[6].guid, "test_parameterized_static_external", 1, 26),
			tuple(discovered_tests[7].guid, "test_parameterized_static_external", 2, 26),
			tuple(discovered_tests[8].guid, "test_parameterized_dynamic", 0, 32),
			tuple(discovered_tests[9].guid, "test_parameterized_dynamic", 1, 32),
			tuple(discovered_tests[10].guid, "test_parameterized_dynamic", 2, 32),
			tuple(discovered_tests[11].guid, "test_日本語", -1, 38),
		])


func test_discover_moved_test_GDScript() -> void:
	var script := load_non_cached("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.gd")
	# using debug mode to true to collect the change set
	var discoverer: GdUnitTestDiscoverGuard = auto_free(GdUnitTestDiscoverGuard.new(true))

	var discovered_tests: Array[GdUnitTestCase] = []
	var expected_renamed_tests: Array[GdUnitTestCase] = []
	# simulate initial discovery of a new test suite
	# we overwrite the default discover sync to catch the tests and not emit `gdunit_test_discovered`
	await discoverer.discover(script, func(test_case: GdUnitTestCase) -> void:
		# we need to manual update the cache here, this is normal made by gdunit_test_discovered signal
		discoverer.sync_test_added(test_case)
		discovered_tests.append(test_case)
		# we save the tests for later verify as renemaed
		if test_case.test_name in ["test_parameterized_static_external", "test_parameterized_dynamic"]:
			expected_renamed_tests.append(test_case)
	)
	# verify the expected tests are collected (2 test each with a dataset of 3 == 6)
	assert_array(expected_renamed_tests).extractv(extr("test_name"), extr("attribute_index"), extr("line_number"))\
		.contains_exactly([
			tuple("test_parameterized_static_external", 0, 26),
			tuple("test_parameterized_static_external", 1, 26),
			tuple("test_parameterized_static_external", 2, 26),
			tuple("test_parameterized_dynamic", 0, 32),
			tuple("test_parameterized_dynamic", 1, 32),
			tuple("test_parameterized_dynamic", 2, 32),
		])

	# we insert two new lines before test test_parameterized_static_external (test source_line is now changed)
	var source_code_index := script.source_code.find("func test_parameterized_static_external")
	script.source_code = script.source_code.insert(source_code_index-1, "\n\n")
	assert_int(script.reload(true)).is_equal(OK)

	# calling the discover like when a script change is emited by a save action
	await discoverer.discover(script, func(test_case: GdUnitTestCase) -> void:
		# we need to manual update the cache here, this is normal made by gdunit_test_discovered signal
		discoverer.sync_test_added(test_case)
	)

	# verify discovery detects the moved tests by two lines
	var changed_tests: Array[GdUnitTestCase] = discoverer._discovered_changes["changed_tests"]
	assert_array(changed_tests).extractv(extr("guid"), extr("test_name"), extr("attribute_index"), extr("line_number"))\
		.contains_exactly([
			tuple(expected_renamed_tests[0].guid, "test_parameterized_static_external", 0, 28),
			tuple(expected_renamed_tests[1].guid, "test_parameterized_static_external", 1, 28),
			tuple(expected_renamed_tests[2].guid, "test_parameterized_static_external", 2, 28),
			tuple(expected_renamed_tests[3].guid, "test_parameterized_dynamic", 0, 34),
			tuple(expected_renamed_tests[4].guid, "test_parameterized_dynamic", 1, 34),
			tuple(expected_renamed_tests[5].guid, "test_parameterized_dynamic", 2, 34),
			tuple(discovered_tests[11].guid, "test_日本語", -1, 40),
		])
	# and no added or removed tests
	assert_array(discoverer._discovered_changes["deleted_tests"]).is_empty()
	assert_array(discoverer._discovered_changes["added_tests"]).is_empty()

	# verify the cache contains all discovered tests inclusive line_number changes
	assert_array(discoverer._discover_cache.get(script.resource_path))\
		.extractv(extr("guid"), extr("test_name"), extr("attribute_index"), extr("line_number"))\
		.contains_exactly([
			tuple(discovered_tests[0].guid, "test_case1", -1, 10),
			tuple(discovered_tests[1].guid, "test_case2", -1, 14),
			tuple(discovered_tests[2].guid, "test_parameterized_static", 0, 18),
			tuple(discovered_tests[3].guid, "test_parameterized_static", 1, 18),
			tuple(discovered_tests[4].guid, "test_parameterized_static", 2, 18),
			# the following tests has line_number changes
			tuple(discovered_tests[5].guid, "test_parameterized_static_external", 0, 28),
			tuple(discovered_tests[6].guid, "test_parameterized_static_external", 1, 28),
			tuple(discovered_tests[7].guid, "test_parameterized_static_external", 2, 28),
			tuple(discovered_tests[8].guid, "test_parameterized_dynamic", 0, 34),
			tuple(discovered_tests[9].guid, "test_parameterized_dynamic", 1, 34),
			tuple(discovered_tests[10].guid, "test_parameterized_dynamic", 2, 34),
			tuple(discovered_tests[11].guid, "test_日本語", -1, 40),
		])


#if GDUNIT4NET_API_V5
func test_discover_on_csharp_script(_do_skip := !GdUnit4CSharpApiLoader.is_api_loaded()) -> void:
	var discoverer :GdUnitTestDiscoverGuard = auto_free(GdUnitTestDiscoverGuard.new())
	var discovered_tests: Array[GdUnitTestCase] = []
	var script := load_non_cached("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.cs")
	# simulate initial discovery of a new test suite
	# we overwrite the default discover sync to catch the tests and not emit `gdunit_test_discovered`
	await discoverer.discover(script, func(test_case: GdUnitTestCase) -> void:
		# we need to manual update the cache here, this is normal made by gdunit_test_discovered signal
		discoverer.sync_test_added(test_case)
		discovered_tests.append(test_case)
	)

	assert_array(discovered_tests)\
		.extractv(extr("test_name"), extr("display_name"), extr("fully_qualified_name"))\
		.contains_exactly([
			tuple("TestCase1", "TestCase1", "gdUnit4.addons.gdUnit4.test.core.discovery.resources.DiscoverExampleTestSuite.TestCase1"),
			tuple("TestCase2", "TestCase2", "gdUnit4.addons.gdUnit4.test.core.discovery.resources.DiscoverExampleTestSuite.TestCase2")
		])
#endif


# we need to load the scripts freshly uncached because of script changes during test execution
func load_non_cached(resource_path: String) -> Script:
	return ResourceLoader.load(resource_path, "Script", ResourceLoader.CACHE_MODE_IGNORE)
