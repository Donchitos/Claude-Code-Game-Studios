extends Node


func test_no_args() -> void:
	pass

@warning_ignore("unused_parameter")
func test_with_timeout(timeout:=2000) -> void:
	pass


@warning_ignore("unused_parameter")
func test_with_fuzzer(fuzzer := Fuzzers.rangei(-10, 22)) -> void:
	pass


@warning_ignore("unused_parameter")
func test_with_fuzzer_iterations(fuzzer := Fuzzers.rangei(-10, 22), fuzzer_iterations := 10) -> void:
	pass


@warning_ignore("unused_parameter")
func test_with_multible_fuzzers(fuzzer_a := Fuzzers.rangei(-10, 22), fuzzer_b := Fuzzers.rangei(23, 42), fuzzer_iterations := 10) -> void:
	pass


@warning_ignore("unused_parameter")
func test_multiline_arguments_a(fuzzer_a := Fuzzers.rangei(-10, 22), fuzzer_b := Fuzzers.rangei(23, 42),
	fuzzer_iterations := 42) -> void:
	pass


@warning_ignore("unused_parameter")
func test_multiline_arguments_b(
	fuzzer_a := Fuzzers.rangei(-10, 22),
	fuzzer_b := Fuzzers.rangei(23, 42),
	fuzzer_iterations := 23
	) -> void:
	pass


@warning_ignore("unused_parameter")
func test_multiline_arguments_c(
	timeout:=2000,
	fuzzer_a := Fuzzers.rangei(-10, 22),
	fuzzer_b := Fuzzers.rangei(23, 42),
	fuzzer_iterations := 33
	) -> void:
	pass
