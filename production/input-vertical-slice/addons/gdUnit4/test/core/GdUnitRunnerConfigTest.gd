# GdUnit generated TestSuite
class_name GdUnitRunnerConfigTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/GdUnitRunnerConfig.gd'


func test_initial_config() -> void:
	var config := GdUnitRunnerConfig.new()
	assert_array(config.test_cases()).is_empty()


func test_clear_on_initial_config() -> void:
	var config := GdUnitRunnerConfig.new()
	config.clear()
	assert_array(config.test_cases()).is_empty()


func test_set_server_port() -> void:
	var config := GdUnitRunnerConfig.new()
	# intial value
	assert_int(config.server_port()).is_equal(-1)

	config.set_server_port(1000)
	assert_int(config.server_port()).is_equal(1000)


func test_load_fail() -> void:
	var config := GdUnitRunnerConfig.new()

	assert_result(config.load_config("invalid_path"))\
		.is_warning()\
		.contains_message("Can't find test runner configuration 'invalid_path'! Please select a test to run.")


func test_save_load() -> void:
	var config := GdUnitRunnerConfig.new()
	# add some dummy conf
	config.set_server_port(1000)
	# create a set of test cases
	var test_to_save: Array[GdUnitTestCase] = [
		GdUnitTestCase.from("res://test/example_suite.gd", "res://test/example_suite.gd", 10, "test_a"),
		GdUnitTestCase.from("res://test/example_suite.gd", "res://test/example_suite.gd", 14, "test_b"),
		GdUnitTestCase.from("res://test/example_suite.gd", "res://test/example_suite.gd", 16, "test_c")
	]
	config.add_test_cases(test_to_save)

	var config_file := create_temp_dir("test_save_load") + "/testconf.cfg"

	assert_result(config.save_config(config_file)).is_success()
	assert_file(config_file).exists()

	var config2 := GdUnitRunnerConfig.new()
	assert_result(config2.load_config(config_file)).is_success()
	# verify the config has original enties
	assert_str(config2.version()).is_equal(GdUnitRunnerConfig.CONFIG_VERSION)
	assert_array(config2.test_cases()).contains_exactly_in_any_order(test_to_save)


func test_add_test_cases() -> void:

	var config := GdUnitRunnerConfig.new()
	# add some dummy conf
	config.set_server_port(1000)
	# create a set of test cases
	config.add_test_cases([
		GdUnitTestCase.from("res://test/example_suite.gd", "res://test/example_suite.gd", 10, "test_a"),
		GdUnitTestCase.from("res://test/example_suite.gd", "res://test/example_suite.gd", 14, "test_b"),
		GdUnitTestCase.from("res://test/example_suite.gd", "res://test/example_suite.gd", 16, "test_c")
	])

	var config_file := create_temp_dir("test_save_load") + "/testconf.cfg"

	assert_result(config.save_config(config_file)).is_success()
	assert_file(config_file).exists()
