extends GdUnitTestSuite


var test_retries := {
	"test_flaky_success" = 0,
	"test_flaky_fail" = 0,
	"test_success" = 0,
	"test_parameterized_flaky:0" = 0,
	"test_parameterized_flaky:1" = 0,
	"test_parameterized_flaky:2" = 0,
	"test_parameterized_flaky:3" = 0,
	"test_parameterized_flaky:4" = 0,
	"test_parameterized_flaky:5" = 0,
	"test_fuzzed_flaky_success" = 0,
	"test_fuzzed_flaky_fail" = 0
}

var _run_with_retries: int = GdUnitSettings.get_flaky_max_retries()


class ValueSetFuzzer extends Fuzzer:
	var _values := [0,1,2,3,4]

	func next_value() -> Variant:
		return _values.pop_front()


func before() -> void:
	prints("run with max retries", _run_with_retries)


func after() -> void:
	var retry_count :int = test_retries["test_flaky_success"]
	assert_int(retry_count)\
		.override_failure_message("Expecting 3 retries to succeed for test 'test_flaky_success'\n but was %d" % retry_count)\
		.is_equal(3)
	retry_count = test_retries["test_flaky_fail"]
	assert_int(retry_count)\
		.override_failure_message("Expecting %d retries for test 'test_flaky_fail'\n but was %d" % [_run_with_retries, retry_count])\
		.is_equal(_run_with_retries)
	retry_count = test_retries["test_success"]
	assert_int(retry_count)\
		.override_failure_message("Expecting one test iteration to succeed 'test_success'\n but was %d" % retry_count)\
		.is_equal(1)
	# verify retry count of paramaterized test
	retry_count = test_retries["test_parameterized_flaky:0"]
	assert_int(retry_count)\
		.override_failure_message("Expecting one test iteration to succeed 'test_parameterized_flaky:0'\n but was %d" % retry_count)\
		.is_equal(1)
	retry_count = test_retries["test_parameterized_flaky:1"]
	assert_int(retry_count)\
		.override_failure_message("Expecting one test iteration to succeed 'test_parameterized_flaky:1'\n but was %d" % retry_count)\
		.is_equal(1)
	retry_count = test_retries["test_parameterized_flaky:2"]
	assert_int(retry_count)\
		.override_failure_message("Expecting %d test iteration to fail 'test_parameterized_flaky:2'\n but was %d" % [_run_with_retries, retry_count])\
		.is_equal(_run_with_retries)
	retry_count = test_retries["test_parameterized_flaky:3"]
	assert_int(retry_count)\
		.override_failure_message("Expecting one test iteration to succeed 'test_parameterized_flaky:3'\n but was %d" % retry_count)\
		.is_equal(1)
	retry_count = test_retries["test_parameterized_flaky:4"]
	assert_int(retry_count)\
		.override_failure_message("Expecting 3 test iteration to succeed 'test_parameterized_flaky:4'\n but was %d" % retry_count)\
		.is_equal(3)
	# fuzzed tests
	retry_count = test_retries["test_fuzzed_flaky_success"]
	assert_int(retry_count)\
		.override_failure_message("Expecting 3 retries to succeed for test 'test_fuzzed_flaky_success'\n but was %d" % retry_count)\
		.is_equal(3)
	retry_count = test_retries["test_fuzzed_flaky_fail"]
	assert_int(retry_count)\
		.override_failure_message("Expecting %d retries for test 'test_fuzzed_flaky_fail'\n but was %d" % [_run_with_retries, retry_count])\
		.is_equal(_run_with_retries)


func test_flaky_success() -> void:
	test_retries["test_flaky_success"] += 1
	var retry_count :int = test_retries["test_flaky_success"]
	# do retry between 1 and 3
	assert_int(retry_count).is_less_equal(3)
	if retry_count <= 2:
		fail("failure 1: failed at retry %d" % retry_count)
		fail("failure 2: failed at retry %d" % retry_count)


func test_flaky_fail() -> void:
	test_retries["test_flaky_fail"] += 1
	var retry_count :int = test_retries["test_flaky_fail"]
	# do retry between 1 and 5
	assert_int(retry_count).is_less_equal(6)
	if retry_count < 6:
		fail("failed on  test retry %d" % retry_count)


func test_success() -> void:
	test_retries["test_success"] += 1
	var retry_count :int = test_retries["test_success"]
	# do retry only one time
	assert_int(retry_count).is_equal(1)
	assert_bool(true).is_true()


@warning_ignore("unused_parameter")
func test_parameterized_flaky(test_index: int, expected_retry_count :int, test_parameters := [
	[0, 1],
	[1, 1],
	[2, 6],
	[3, 1],
	[4, 3]]) -> void:

	var test_case_name := "test_parameterized_flaky:%d" % test_index
	test_retries[test_case_name] += 1
	var retry_count :int = test_retries[test_case_name]
	assert_int(retry_count).is_less_equal(expected_retry_count)

	if test_index == 2 or test_index == 4:
		# do fail if retry_count less expected count to fail
		if retry_count < expected_retry_count:
			fail("failed at retry %d" % retry_count)


@warning_ignore("unused_parameter")
func test_fuzzed_flaky_success(fuzzer := ValueSetFuzzer.new(), fuzzer_iterations := 5) -> void:
	var fuzzer_value :int = fuzzer.next_value()
	if fuzzer_value == 0:
		test_retries["test_fuzzed_flaky_success"] += 1
	var retry_count :int = test_retries["test_fuzzed_flaky_success"]
	# do retry between 1 and 3
	assert_int(retry_count).is_less_equal(3)

	if retry_count <= 2:
		fail("failure 1: failed at retry %d" % retry_count)
		fail("failure 2: failed at retry %d" % retry_count)


@warning_ignore("unused_parameter")
func test_fuzzed_flaky_fail(fuzzer := ValueSetFuzzer.new(), fuzzer_iterations := 5) -> void:
	var fuzzer_value :int = fuzzer.next_value()
	if fuzzer_value == 0:
		test_retries["test_fuzzed_flaky_fail"] += 1
	var retry_count :int = test_retries["test_fuzzed_flaky_fail"]
	# do retry between 1 and 3
	assert_int(retry_count).is_less_equal(6)

	if retry_count < 6:
		fail("failed at retry %d" % retry_count)
