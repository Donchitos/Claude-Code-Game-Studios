class_name GdUnitRunnerConfig
extends Resource

const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")

const CONFIG_VERSION = "5.0"
const VERSION = "version"
const TESTS = "tests"
const SERVER_PORT = "server_port"
const EXIT_FAIL_FAST = "exit_on_first_fail"

const CONFIG_FILE = "res://addons/gdUnit4/GdUnitRunner.cfg"

var _config := {
		VERSION : CONFIG_VERSION,
		# a set of directories or testsuite paths as key and a optional set of testcases as values

		TESTS : Array([], TYPE_OBJECT, "RefCounted", GdUnitTestCase),

		# the port of running test server for this session
		SERVER_PORT : -1,

		# Exit on first failure
		EXIT_FAIL_FAST : false
	}


func version() -> String:
	return _config[VERSION]


func clear() -> GdUnitRunnerConfig:
	_config[TESTS] = Array([], TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	return self


func set_server_port(port: int) -> GdUnitRunnerConfig:
	_config[SERVER_PORT] = port
	return self


func server_port() -> int:
	return _config.get(SERVER_PORT, -1)


func do_fail_fast(fail_fast: bool) -> GdUnitRunnerConfig:
	_config[EXIT_FAIL_FAST] = fail_fast
	return self


func is_fail_fast() -> bool:
	return _config.get(EXIT_FAIL_FAST, false)


func add_test_cases(tests: Array[GdUnitTestCase]) -> GdUnitRunnerConfig:
	test_cases().append_array(tests)
	return self


func test_cases() -> Array[GdUnitTestCase]:
	return _config.get(TESTS, [])


func save_config(path: String = CONFIG_FILE) -> GdUnitResult:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var error := FileAccess.get_open_error()
		return GdUnitResult.error("Can't write test runner configuration '%s'! %s" % [path, error_string(error)])

	var to_save := {
		VERSION : CONFIG_VERSION,
		EXIT_FAIL_FAST : is_fail_fast(),
		SERVER_PORT : server_port(),
		TESTS : Array()
	}

	var tests: Array = to_save.get(TESTS)
	for test in test_cases():
		tests.append(inst_to_dict(test))
	file.store_string(JSON.stringify(to_save, "\t"))
	return GdUnitResult.success(path)


func load_config(path: String = CONFIG_FILE) -> GdUnitResult:
	if not FileAccess.file_exists(path):
		return GdUnitResult.warn("Can't find test runner configuration '%s'! Please select a test to run." % path)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var error := FileAccess.get_open_error()
		return GdUnitResult.error("Can't load test runner configuration '%s'! ERROR: %s." % [path, error_string(error)])
	var content := file.get_as_text()
	if not content.is_empty() and content[0] == '{':
		# Parse as json
		var test_json_conv := JSON.new()
		var error := test_json_conv.parse(content)
		if error != OK:
			return GdUnitResult.error("The runner configuration '%s' is invalid! The format is changed please delete it manually and start a new test run." % path)
		var config: Dictionary = test_json_conv.get_data()
		if not config.has(VERSION):
			return GdUnitResult.error("The runner configuration '%s' is invalid! The format is changed please delete it manually and start a new test run." % path)

		var default: Array[Dictionary] =  Array([], TYPE_DICTIONARY, "", null)
		var tests_as_json: Array = config.get(TESTS, default)
		_config = config
		_config[TESTS] = convert_test_json_to_test_cases(tests_as_json)


		fix_value_types()
	return GdUnitResult.success(path)


func convert_test_json_to_test_cases(jsons: Array) -> Array[GdUnitTestCase]:
	if jsons.is_empty():
		return []
	var tests := jsons.map(func(d: Dictionary) -> GdUnitTestCase:
		var test: GdUnitTestCase = dict_to_inst(d)
		# we need o covert manually to the corect type becaus JSON do not handle typed values
		test.guid = GdUnitGUID.new(str(d["guid"]))
		test.attribute_index = test.attribute_index as int
		test.line_number = test.line_number as int
		return test
	)
	return Array(tests, TYPE_OBJECT, "RefCounted", GdUnitTestCase)


func fix_value_types() -> void:
	# fix float value to int json stores all numbers as float
	var server_port_: int = _config.get(SERVER_PORT, -1)
	_config[SERVER_PORT] = server_port_


func convert_Array_to_PackedStringArray(data: Dictionary) -> void:
	for key in data.keys() as Array[String]:
		var values :Array = data[key]
		data[key] = PackedStringArray(values)


func _to_string() -> String:
	return str(_config)
