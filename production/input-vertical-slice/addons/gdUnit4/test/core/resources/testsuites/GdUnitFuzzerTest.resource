# this test suite simulates long running test cases
extends GdUnitTestSuite
@warning_ignore('unused_parameter')

var _stack : Array

func before() -> void:
	# init the stack
	_stack = []

func before_test() -> void:
	# clean the stack before every test run
	_stack.clear()


@warning_ignore('unused_parameter')
func test_multi_yielding_with_fuzzer(fuzzer := Fuzzers.rangei(0, 1000), fuzzer_iterations := 10) -> void:
	# verify the used stack is cleaned by 'before_test'
	assert_array(_stack).is_empty()
	_stack.push_back(1)

	prints("test iteration %d" % fuzzer.iteration_index())
	prints("4")
	await get_tree().process_frame
	prints("3")
	await get_tree().process_frame
	prints("2")
	await get_tree().process_frame
	prints("1")
	await get_tree().process_frame
	prints("Go")

@warning_ignore('unused_parameter')
func test_multi_yielding_with_fuzzer_fail_after_3_iterations(fuzzer := Fuzzers.rangei(0, 1000), fuzzer_iterations := 10) -> void:
	prints("test iteration %d" % fuzzer.iteration_index())
	# should never be greater than 3 because we interuppted after three iterations
	assert_int(fuzzer.iteration_index()).is_less_equal(3)
	prints("4")
	await get_tree().process_frame
	prints("3")
	await get_tree().process_frame
	prints("2")
	await get_tree().process_frame
	prints("1")
	await get_tree().process_frame
	prints("Go")
	if fuzzer.iteration_index() >= 3:
		assert_bool(true).is_false()
