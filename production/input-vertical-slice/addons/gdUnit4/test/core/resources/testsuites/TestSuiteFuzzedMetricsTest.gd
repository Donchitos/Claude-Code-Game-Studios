# this test suite simulates long running test cases
extends GdUnitTestSuite
@warning_ignore('unused_parameter')


class TestCaseStatistics:
	var _testcase_before_called := 0
	var _testcase_after_called := 0
	var _test_called := 0
	var _expected_calls :int

	func _init(expected_calls :int) -> void:
		_expected_calls = expected_calls

	func count_test_before_test() -> void:
		_testcase_before_called +=1

	func count_test_after_test() -> void:
		_testcase_after_called +=1

	func count_test() -> void:
		_test_called += 1


var _metrics: Dictionary[String, TestCaseStatistics] = {
	"test_execute_3times" : TestCaseStatistics.new(3),
	"test_execute_5times" : TestCaseStatistics.new(5)
}

var _stack : Array
var _before_called := 0
var _after_called := 0


func before() -> void:
	_before_called += 1
	# init the stack
	_stack = []


func after() -> void:
	_after_called += 1
	assert_that(_before_called)\
		.override_failure_message("Expecting 'before' is called only one times")\
		.is_equal(1)
	assert_that(_after_called)\
		.override_failure_message("Expecting 'after' is called only one times")\
		.is_equal(1)

	for test_case :String in _metrics.keys():
		var statistics: TestCaseStatistics = _metrics[test_case]
		assert_int(statistics._testcase_before_called)\
			.override_failure_message("Expect before_test called %s times but is %s for test case %s" % [statistics._expected_calls, statistics._testcase_before_called, test_case])\
			.is_equal(statistics._expected_calls)
		assert_int(statistics._test_called)\
			.override_failure_message("Expect test called %s times but is %s for test case %s" % [statistics._expected_calls, statistics._test_called, test_case])\
			.is_equal(statistics._expected_calls)
		assert_int(statistics._testcase_after_called)\
			.override_failure_message("Expect after_test called %s times but is %s for test case %s" % [statistics._expected_calls, statistics._testcase_after_called, test_case])\
			.is_equal(statistics._expected_calls)


func before_test() -> void:
	_metrics[__active_test_case].count_test_before_test()
	# clean the stack before every test run
	_stack.clear()


func after_test() -> void:
	_metrics[__active_test_case].count_test_after_test()


func test_execute_3times(_fuzzer := Fuzzers.rangei(0, 1000), _fuzzer_iterations := 3) -> void:
	_metrics[__active_test_case].count_test()


func test_execute_5times(_fuzzer := Fuzzers.rangei(0, 1000), _fuzzer_iterations := 5) -> void:
	_metrics[__active_test_case].count_test()
