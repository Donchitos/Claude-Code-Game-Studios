extends GdUnitTestSuite


func test_do_skip_as_first_param(
	_do_skip := false,
	_fuzzer := Fuzzers.rangei(0, 10),
	_fuzzer_iterations := 3) -> void:
	pass


func test_do_skip_in_middle(
		_fuzzer_a := Fuzzers.rangei(0, 10),
		_do_skip := false,
		_fuzzer_iterations := 3) -> void:
	pass


func test_do_skip_as_last_param(
	_fuzzer := Fuzzers.rangei(0, 10),
	_fuzzer_iterations := 3,
	_do_skip := false) -> void:
	pass
