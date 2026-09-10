extends GdUnitTestSuite


func test_fuzzer_after_do_skip(
	_do_skip := false,
	fuzzer_value := Fuzzers.rangei(0, 10),
	_fuzzer_iterations := 2
) -> void:
	var value: int = fuzzer_value.next_value()
	assert_int(value).is_between(0, 10)
