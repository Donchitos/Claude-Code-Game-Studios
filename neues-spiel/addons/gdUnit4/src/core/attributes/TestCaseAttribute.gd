class_name TestCaseAttribute
extends Resource
## Holds configuration and metadata for individual test cases.[br]
## [br]
## This class defines test behaviors and properties such as:[br]
## - Test timeouts[br]
## - Skip conditions[br]
## - Fuzzing parameters[br]
## - Random seed values[br]


## When set, no specific timeout value is configured and test will use the [code]test_timeout[/code][br]
## value from [GdUnitSettings].
const DEFAULT_TIMEOUT := -1


## The maximum time in milliseconds for test completion.[br]
## The test fails if execution exceeds this duration.[br]
## [br]
## When set to [constant DEFAULT_TIMEOUT], uses the value from [method GdUnitSettings.test_timeout].
var timeout: int = DEFAULT_TIMEOUT:
	set(value):
		timeout = value
	get:
		if timeout == DEFAULT_TIMEOUT:
			# get the default timeout from the settings
			timeout = GdUnitSettings.test_timeout()
		return timeout


## The seed used for random number generation in the test.[br]
## Ensures reproducible results for randomized test scenarios.[br]
## A value of -1 indicates no specific seed is set.
var test_seed: int = -1


## Controls whether this test should be skipped during execution.[br]
## Useful for temporarily disabling tests without removing them.
var is_skipped := false


## Documents why the test is being skipped.[br]
## [br]
## Should explain the reason for skipping and ideally include:[br]
## - Why the test was disabled[br]
## - Under what conditions it should be re-enabled[br]
## - Any related issues or tickets
var skip_reason := "Unknown"


## Number of iterations to run when using fuzzers.[br]
## [br]
## Fuzzers generate random test data to help find edge cases.[br]
## Higher values provide better coverage but increase test duration.
var fuzzer_iterations: int = Fuzzer.ITERATION_DEFAULT_COUNT


## Array of fuzzer configurations for test parameters.[br]
## [br]
## Each [GdFunctionArgument] defines how random test data[br]
## should be generated for a particular parameter.
var fuzzers: Array[GdFunctionArgument] = []


# There is a bug in `duplicate` see https://github.com/godotengine/godot/issues/98644
# we need in addition to overwrite default values with the source values
@warning_ignore("native_method_override")
func clone() -> Resource:
	var copy: TestCaseAttribute = TestCaseAttribute.new()
	copy.timeout = timeout
	copy.test_seed = test_seed
	copy.is_skipped = is_skipped
	copy.skip_reason = skip_reason
	copy.fuzzer_iterations = fuzzer_iterations
	copy.fuzzers = fuzzers.duplicate()
	return copy
