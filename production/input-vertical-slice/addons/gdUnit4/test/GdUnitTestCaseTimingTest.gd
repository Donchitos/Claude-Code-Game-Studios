# this test suite simulates long running test cases
extends GdUnitTestSuite

var _iteration_timer_start := 0
var _test_values_current :Dictionary
var _test_values_expected :Dictionary

const SECOND:int = 1000
const MINUTE:int = SECOND*60

class TestCaseStatistics:
	var _test_before_calls :int
	var _test_after_calls :int


	func _init(before_calls := 0, after_calls := 0) -> void:
		_test_before_calls = before_calls
		_test_after_calls = after_calls


func before() -> void:
	_test_values_current = {
		"test_2s" : TestCaseStatistics.new(),
		"test_multi_yielding" : TestCaseStatistics.new(),
		"test_multi_yielding_with_fuzzer" : TestCaseStatistics.new()
	}
	_test_values_expected = {
		"test_2s" : TestCaseStatistics.new(1, 1),
		"test_multi_yielding" : TestCaseStatistics.new(1, 1),
		"test_multi_yielding_with_fuzzer" : TestCaseStatistics.new(5 , 5)
	}


func after() -> void:
	for test_case :String in _test_values_expected.keys():
		var current: TestCaseStatistics = _test_values_current[test_case]
		var expected: TestCaseStatistics = _test_values_expected[test_case]
		assert_int(current._test_before_calls)\
			.override_failure_message("Expect before_test called %s times but is %s for test case %s" % [expected._test_before_calls, current._test_before_calls, test_case])\
			.is_equal(expected._test_before_calls)
		assert_int(current._test_after_calls)\
			.override_failure_message("Expect after_test called %s times but is %s for test case %s" % [expected._test_before_calls, current._test_before_calls, test_case])\
			.is_equal(expected._test_after_calls)


func before_test() -> void:
	var current: TestCaseStatistics = _test_values_current[__active_test_case]
	current._test_before_calls +=1


func after_test() -> void:
	var current: TestCaseStatistics = _test_values_current[__active_test_case]
	current._test_after_calls +=1


func test_2s() -> void:
	var timer_start := Time.get_ticks_msec()
	await await_millis(2000)
	# subtract an offset of 100ms because the time is not accurate
	assert_int(Time.get_ticks_msec()-timer_start).is_between(2*SECOND-100, 2*SECOND+100)


func test_multi_yielding() -> void:
	var timer_start := Time.get_ticks_msec()
	prints("test_yielding")
	await get_tree().process_frame
	prints("4")
	await get_tree().create_timer(1.0).timeout
	prints("3")
	await get_tree().create_timer(1.0).timeout
	prints("2")
	await get_tree().create_timer(1.0).timeout
	prints("1")
	await get_tree().create_timer(1.0).timeout
	prints("Go")
	assert_int(Time.get_ticks_msec()-timer_start).is_greater_equal(4*(SECOND-50))


func test_multi_yielding_with_fuzzer(fuzzer := Fuzzers.rangei(0, 1000), fuzzer_iterations := 5) -> void:
	if fuzzer.iteration_index() > 5:
		fail("Should only called 5 times")
	if fuzzer.iteration_index() == 1:
		_iteration_timer_start = Time.get_ticks_msec()
	prints("test iteration %d" % fuzzer.iteration_index())
	prints("4")
	await get_tree().create_timer(1.0).timeout
	prints("3")
	await get_tree().create_timer(1.0).timeout
	prints("2")
	await get_tree().create_timer(1.0).timeout
	prints("1")
	await get_tree().create_timer(1.0).timeout
	prints("Go")
	if fuzzer.iteration_index() == 5:
		# elapsed time must be fuzzer_iterations times * 4s = 40s (using 3,9s because of inaccurate timings)
		assert_int(Time.get_ticks_msec()-_iteration_timer_start).is_greater_equal(3900*fuzzer_iterations)
