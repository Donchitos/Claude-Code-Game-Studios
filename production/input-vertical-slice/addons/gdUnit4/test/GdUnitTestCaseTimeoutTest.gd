# this test suite simulates long running test cases
extends GdUnitTestSuite

const SECOND :int = 1000
const MINUTE :int = SECOND*60

var _before_arg :String
var _test_arg :String


func before() -> void:
	# use some variables to test clone test suite works as expected
	_before_arg = "---before---"


func before_test() -> void:
	# set failing test to success if failed by timeout
	discard_error_interupted_by_timeout()
	_test_arg = "abc"


# without custom timeout should execute the complete test
func test_timeout_after_test_completes() -> void:
	assert_str(_before_arg).is_equal("---before---")
	var counter := 0
	await await_millis(1000)
	prints("A","1s")
	counter += 1
	await await_millis(1000)
	prints("A","2s")
	counter += 1
	await await_millis(1000)
	prints("A","3s")
	counter += 1
	await await_millis(1000)
	prints("A","5s")
	counter += 2
	prints("A","end test test_timeout_after_test_completes")
	assert_int(counter).is_equal(5)


# set test timeout to 2s
@warning_ignore("unused_parameter")
func test_timeout_2s(timeout:=2000) -> void:
	assert_str(_before_arg).is_equal("---before---")
	prints("B", "0s")
	await await_millis(1000)
	prints("B", "1s")
	await await_millis(1000)
	prints("B", "2s")
	await await_millis(1000)
	# this line should not reach if timeout aborts the test case after 2s
	fail("The test case must be interupted by a timeout after 2s")
	prints("B", "3s")
	prints("B", "end")


# set test timeout to 4s
@warning_ignore("unused_parameter")
func test_timeout_4s(timeout:=4000) -> void:
	assert_str(_before_arg).is_equal("---before---")
	prints("C", "0s")
	await await_millis(1000)
	prints("C", "1s")
	await await_millis(1000)
	prints("C", "2s")
	await await_millis(1000)
	prints("C", "3s")
	await await_millis(4000)
	# this line should not reach if timeout aborts the test case after 4s
	fail("The test case must be interupted by a timeout after 4s")
	prints("C", "7s")
	prints("C", "end")


@warning_ignore("unused_parameter")
func test_timeout_single_yield_wait(timeout:=3000) -> void:
	assert_str(_before_arg).is_equal("---before---")
	prints("D", "0s")
	await await_millis(6000)
	prints("D", "6s")
	# this line should not reach if timeout aborts the test case after 3s
	fail("The test case must be interupted by a timeout after 3s")
	prints("D", "end test test_timeout")


@warning_ignore("unused_parameter")
func test_timeout_long_running_test_abort(timeout:=4000) -> void:
	assert_str(_before_arg).is_equal("---before---")
	prints("E", "0s")
	var start_time := Time.get_ticks_msec()
	var sec_start_time := Time.get_ticks_msec()

	# simulate long running function
	while true:
		var elapsed_time := Time.get_ticks_msec() - start_time
		var sec_time := Time.get_ticks_msec() - sec_start_time

		if sec_time > 1000:
			sec_start_time = Time.get_ticks_msec()
			prints("E", LocalTime.elapsed(elapsed_time))

		# give system time to check for timeout
		await await_millis(200)

		# exit while after 4500ms inclusive 500ms offset
		if elapsed_time > 4500:
			break

	# this line should not reach if timeout aborts the test case after 4s
	fail("The test case must be abort interupted by a timeout 4s")
	prints("F", "end test test_timeout")


@warning_ignore("unused_parameter", "unused_variable")
func test_timeout_fuzzer(fuzzer := Fuzzers.rangei(-23, 22), timeout:=2000) -> void:
	discard_error_interupted_by_timeout()
	fuzzer.next_value()
	# wait each iteration 200ms
	await await_millis(200)
	# we expects the test is interupped after 10 iterations because each test takes 200ms
	# and the test should not longer run than 2000ms
	assert_int(fuzzer.iteration_index())\
		.override_failure_message("The test must be interupted after around 10 iterations")\
		.is_less_equal(10)
