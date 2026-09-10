extends GdUnitTestSuite

var _current_iterations : Dictionary
var _expected_iterations: Dictionary

# a simple test fuzzer where provided a hard coded value set
class TestFuzzer extends Fuzzer:
	var _data := [0, 1, 2, 3, 4, 5, 6, 23, 8, 9]


	func next_value() -> int:
		return _data.pop_front()


func max_value() -> int:
	return 10


func min_value() -> int:
	return 1


func get_fuzzer() -> Fuzzer:
	return Fuzzers.rangei(min_value(), max_value())


func before() -> void:
	# define expected iteration count
	_expected_iterations = {
		"test_fuzzer_has_same_instance_peer_iteration" : 10,
		"test_multiple_fuzzers_inject_value_with_seed" : 10,
		"test_fuzzer_iterations_default" : Fuzzer.ITERATION_DEFAULT_COUNT,
		"test_fuzzer_iterations_custom_value" : 234,
		"test_fuzzer_inject_value" : 100,
		"test_multiline_fuzzer_args": 23,
	}
	# inital values
	_current_iterations = {
		"test_fuzzer_has_same_instance_peer_iteration" : 0,
		"test_multiple_fuzzers_inject_value_with_seed" : 0,
		"test_fuzzer_iterations_default" : 0,
		"test_fuzzer_iterations_custom_value" : 0,
		"test_fuzzer_inject_value" : 0,
		"test_multiline_fuzzer_args": 0,
	}


func after() -> void:
	for test_case :String in _expected_iterations.keys():
		var current :int = _current_iterations[test_case]
		var expected :int = _expected_iterations[test_case]

		assert_int(current).override_failure_message("Expecting %s itertions but is %s checked test case %s" % [expected, current, test_case]).is_equal(expected)

var _fuzzer_instance_before : Fuzzer = null


func test_fuzzer_has_same_instance_peer_iteration(fuzzer := TestFuzzer.new(), _fuzzer_iterations := 10) -> void:
	_current_iterations["test_fuzzer_has_same_instance_peer_iteration"] += 1
	assert_object(fuzzer).is_not_null()
	if _fuzzer_instance_before != null:
		assert_object(fuzzer).is_same(_fuzzer_instance_before)
	_fuzzer_instance_before = fuzzer


func test_fuzzer_iterations_default(fuzzer := Fuzzers.rangei(-23, 22)) -> void:
	_current_iterations["test_fuzzer_iterations_default"] += 1
	assert_object(fuzzer).is_not_null()
	assert_int(fuzzer.next_value()).is_between(-23, 22)


func test_fuzzer_iterations_custom_value(_fuzzer := Fuzzers.rangei(-23, 22), _fuzzer_iterations := 234, _fuzzer_seed := 100) -> void:
	_current_iterations["test_fuzzer_iterations_custom_value"] += 1


func test_fuzzer_inject_value(fuzzer := Fuzzers.rangei(-23, 22), _fuzzer_iterations := 100) -> void:
	_current_iterations["test_fuzzer_inject_value"] += 1
	assert_object(fuzzer).is_not_null()
	assert_int(fuzzer.next_value()).is_between(-23, 22)


func test_fuzzer_with_timeout(fuzzer := Fuzzers.rangei(-23, 22), _fuzzer_iterations := 20, _timeout := 100) -> void:
	discard_error_interupted_by_timeout()
	assert_int(fuzzer.next_value()).is_between(-23, 22)

	if fuzzer.iteration_index() == 10:
		await await_millis(100)
	# we not expect more than 10 iterations it should be interuptead by a timeout
	assert_int(fuzzer.iteration_index()).is_less_equal(10)

var expected_value: Array[int] = [22, 3, -14, -16, 21, 20, 4, -23, -19, -5]


func test_fuzzer_inject_value_with_seed(fuzzer := Fuzzers.rangei(-23, 22), _fuzzer_iterations := 10, _fuzzer_seed := 187772) -> void:
	assert_object(fuzzer).is_not_null()
	var iteration_index := fuzzer.iteration_index()-1
	var current := fuzzer.next_value()
	var expected := expected_value[iteration_index]
	assert_int(iteration_index).is_between(0, 9).is_less(10)
	assert_int(current)\
		.override_failure_message("Expect value %s checked test iteration %s\n but was %s" % [expected, iteration_index, current])\
		.is_equal(expected)

var expected_value_a: Array[int] = [22, -14, 21, 4, -19, -11, 5, 21, -6, -9]
var expected_value_b: Array[int] = [35, 38, 34, 39, 35, 41, 37, 35, 34, 39]


func test_multiple_fuzzers_inject_value_with_seed(fuzzer_a := Fuzzers.rangei(-23, 22), fuzzer_b := Fuzzers.rangei(33, 44), _fuzzer_iterations := 10, _fuzzer_seed := 187772) -> void:
	_current_iterations["test_multiple_fuzzers_inject_value_with_seed"] += 1
	assert_object(fuzzer_a).is_not_null()
	assert_object(fuzzer_b).is_not_null()
	var iteration_index_a := fuzzer_a.iteration_index()-1
	var current_a := fuzzer_a.next_value()
	var expected_a := expected_value_a[iteration_index_a]
	assert_int(iteration_index_a).is_between(0, 9).is_less(10)
	assert_int(current_a).is_between(-23, 22)
	assert_int(current_a)\
		.override_failure_message("Expect value %s checked test iteration %s\n but was %s" % [expected_a, iteration_index_a, current_a])\
		.is_equal(expected_a)
	var iteration_index_b := fuzzer_b.iteration_index()-1
	var current_b := fuzzer_b.next_value()
	var expected_b := expected_value_b[iteration_index_b]
	assert_int(iteration_index_b).is_between(0, 9).is_less(10)
	assert_int(current_b).is_between(33, 44)
	assert_int(current_b)\
		.override_failure_message("Expect value %s checked test iteration %s\n but was %s" % [expected_b, iteration_index_b, current_b])\
		.is_equal(expected_b)


func test_fuzzer_error_after_eight_iterations(fuzzer:=TestFuzzer.new(), _fuzzer_iterations := 10) -> void:
	assert_object(fuzzer).is_not_null()
	# should fail after 8 iterations
	if fuzzer.iteration_index() == 8:
		assert_failure(func() -> void: assert_int(fuzzer.next_value()).is_between(0, 9)) \
			.is_failed() \
			.has_message("Expecting:\n 23\n in range between\n 0 <> 9")
	else:
		assert_int(fuzzer.next_value()).is_between(0, 9)


func test_fuzzer_custom_func(fuzzer := get_fuzzer()) -> void:
	assert_object(fuzzer).is_not_null()
	assert_int(fuzzer.next_value()).is_between(1, 10)


func test_multiline_fuzzer_args(
	fuzzer_a := Fuzzers.rangev2(Vector2(-47, -47), Vector2(47, 47)),
	fuzzer_b := Fuzzers.rangei(0, 9),
	_fuzzer_iterations := 23) -> void:
		assert_object(fuzzer_a).is_not_null()
		assert_object(fuzzer_b).is_not_null()
		_current_iterations["test_multiline_fuzzer_args"] += 1


@warning_ignore("untyped_declaration")
func test_fuzzing_with_untyped_parameters(float_fuzzer = Fuzzers.rangef(-100.0, 100.0), _fuzzer_iterations = 10):
	assert_float(float_fuzzer.next_value()).is_between(-100.0, 100.0)


func test_boolean_fuzzer(bool_fuzzer := Fuzzers.boolean(), _fuzzer_iterations := 50) -> void:
	var value := bool_fuzzer.next_value()
	assert_bool(value in [true, false]).is_true()
