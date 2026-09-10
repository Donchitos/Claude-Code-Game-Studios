## Base interface for fuzz testing.[br]
##
## Fuzzer is an abstract base class that provides the foundation for creating
## custom fuzzers used in automated testing. Fuzz testing (fuzzing) is a software
## testing technique that involves providing invalid, unexpected, or random data
## as inputs to a program to find bugs and potential security vulnerabilities.
## [br][br]
## To use a fuzzer in your test cases, add optional parameters to your test function:
## [codeblock]
## func test_foo(fuzzer := Fuzzers.randomInt(), _fuzzer_iterations := 10, _fuzzer_seed := 12345):
##     var value := fuzzer.next_value()
##     # Test logic using the fuzzed value
## [/codeblock]
## [br]
## @tutorial(Fuzzing on Wikipedia): https://en.wikipedia.org/wiki/Fuzzing
@abstract
class_name Fuzzer
extends RefCounted

## Default number of iterations for fuzz testing when not specified.
const ITERATION_DEFAULT_COUNT := 1000
## Parameter name for passing the fuzzer instance to test functions.
const ARGUMENT_FUZZER_INSTANCE := "fuzzer"
## Parameter name for specifying the number of iterations in test functions.
const ARGUMENT_ITERATIONS := "fuzzer_iterations"
## Parameter name for specifying the random seed in test functions.
const ARGUMENT_SEED := "fuzzer_seed"

## Current iteration index during fuzzing execution.
var _iteration_index := 0
## Maximum number of iterations to run for this fuzzer.
var _iteration_limit := ITERATION_DEFAULT_COUNT


## Generates the next fuzz value.[br]
##
## This abstract method must be implemented by derived classes to provide
## the specific fuzzing logic for generating test values.[br]
##
## [b]Example implementation:[/b]
## [codeblock]
## func next_value() -> int:
##     return randi_range(0, 100)
## [/codeblock]
##
## @returns The next generated fuzz value. The type depends on the specific fuzzer implementation.
@abstract
func next_value() -> Variant


## Returns the current iteration index.[br]
##
## Useful for tracking progress during fuzzing or for debugging purposes
## when a specific iteration causes a failure.[br]
##
## [b]Example:[/b]
## [codeblock]
## if fuzzer.iteration_index() % 100 == 0:
##     print("Processed %d iterations" % fuzzer.iteration_index())
## [/codeblock]
##
## @returns The current iteration index, starting from 0.
func iteration_index() -> int:
	return _iteration_index


## Returns the maximum number of iterations for this fuzzer.[br]
##
## This value determines how many times the fuzzer will generate values
## during a test run. It can be overridden by the [code]fuzzer_iterations[/code]
## parameter in test functions.[br]
##
## [b]Example:[/b]
## [codeblock]
## print("Running %d fuzzing iterations" % fuzzer.iteration_limit())
## [/codeblock]
##
## @returns The maximum number of iterations to be executed.
func iteration_limit() -> int:
	return _iteration_limit
