extends GdUnitTestSuite


const DiscoverExampleTestSuite : GDScript = preload("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.gd")

func test_discover_tests_on_path() -> void:
	var runner: GdUnitTestCIRunner = auto_free(GdUnitTestCIRunner.new())

	runner.add_test_suite("res://addons/gdUnit4/test/core/discovery/resources/")

	var tests := runner.discover_tests()
	if GdUnit4CSharpApiLoader.is_api_loaded():
		assert_array(tests).has_size(14)
	else:
		assert_array(tests).has_size(12)


func test_discover_tests_on_file() -> void:
	var runner: GdUnitTestCIRunner = auto_free(GdUnitTestCIRunner.new())

	runner.add_test_suite("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.gd")

	var tests := runner.discover_tests()
	assert_array(tests).has_size(12)


func test_discover_tests_on_path_and_skip_suite() -> void:
	var runner: GdUnitTestCIRunner = auto_free(GdUnitTestCIRunner.new())

	runner.add_test_suite("res://addons/gdUnit4/test/core/discovery/resources/")
	runner.skip_test_suite("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.gd")

	# It will be discover two tests from DiscoverExampleTestSuite.cs
	var tests := runner.discover_tests()
	if ClassDB.class_exists("CSharpScript"):
		assert_array(tests).has_size(2)
	else:
		assert_array(tests).is_empty()


func test_is_skipped_entire_suite_by_full_path() -> void:
	var runner: GdUnitTestCIRunner = auto_free(GdUnitTestCIRunner.new())

	var tests: Array[GdUnitTestCase] = []
	GdUnitTestDiscoverer.discover_tests(DiscoverExampleTestSuite,
		func(test: GdUnitTestCase) -> void:
			tests.append(test)
	)

	runner.skip_test_suite("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.gd")

	# Verify all tests are skipped
	for test in tests:
		assert_bool(runner.is_skipped(test)).override_failure_message("Expect '%s' is skipped" % test.test_name).is_true()


func test_is_skipped_entire_suite_by_name() -> void:
	var runner: GdUnitTestCIRunner = auto_free(GdUnitTestCIRunner.new())

	var tests: Array[GdUnitTestCase] = []
	GdUnitTestDiscoverer.discover_tests(DiscoverExampleTestSuite,
		func(test: GdUnitTestCase) -> void:
			tests.append(test)
	)

	# Skip entire suite
	runner.skip_test_suite("DiscoverExampleTestSuite")
	# try also skip an non existing suite
	runner.skip_test_suite("NotExistingTestSuite")

	# Verify all tests are skipped
	for test in tests:
		assert_bool(runner.is_skipped(test)).override_failure_message("Expect '%s' is skipped" % test.test_name).is_true()


func test_is_skipped_single_test_by_full_path() -> void:
	var runner: GdUnitTestCIRunner = auto_free(GdUnitTestCIRunner.new())

	var tests: Array[GdUnitTestCase] = []
	GdUnitTestDiscoverer.discover_tests(DiscoverExampleTestSuite,
		func(test: GdUnitTestCase) -> void:
			tests.append(test)
	)

	# Skip a single test by using full path
	runner.skip_test_suite("res://addons/gdUnit4/test/core/discovery/resources/DiscoverExampleTestSuite.gd:test_case1")
	# and by short suite name
	runner.skip_test_suite("DiscoverExampleTestSuite:test_case2")

	# Verify all tests are skipped
	for test in tests:
		if test.test_name in ["test_case1", "test_case2"]:
			assert_bool(runner.is_skipped(test)).override_failure_message("Expect '%s' is skipped" % test.test_name).is_true()
		else:
			assert_bool(runner.is_skipped(test)).override_failure_message("Expect '%s' is NOT skipped" % test.test_name).is_false()
