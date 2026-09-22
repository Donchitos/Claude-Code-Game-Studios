## Factory class providing convenient static methods to create various fuzzer instances.[br]
##
## Fuzzers is a utility class that simplifies the creation of different fuzzer types
## for testing purposes. It provides static factory methods that create pre-configured
## fuzzers with sensible defaults, making it easier to set up fuzz testing in your
## test suites without manually instantiating each fuzzer type.[br]
##
## This class acts as a central access point for all fuzzer types, improving code
## readability and reducing boilerplate in test cases.[br]
##
## @tutorial(Fuzzing Testing): https://en.wikipedia.org/wiki/Fuzzing
class_name Fuzzers
extends Resource


## Generates random strings with length between [param min_length] and
## [param max_length] (inclusive), using characters from [param charset].
## See [StringFuzzer] for detailed documentation and examples.
static func rand_str(min_length: int, max_length: int, charset := StringFuzzer.DEFAULT_CHARSET) -> StringFuzzer:
	return StringFuzzer.new(min_length, max_length, charset)


## Creates a [BoolFuzzer] for generating random boolean values.[br]
##
## See [BoolFuzzer] for detailed documentation and examples.
static func boolean() -> BoolFuzzer:
	return BoolFuzzer.new()


## Creates an [IntFuzzer] for generating random integers within a range.[br]
##
## Generates random integers between [param from] and [param to] (inclusive)
## using [constant IntFuzzer.NORMAL] mode.
## See [IntFuzzer] for detailed documentation and examples.
static func rangei(from: int, to: int) -> IntFuzzer:
	return IntFuzzer.new(from, to)


## Creates a [FloatFuzzer] for generating random floats within a range.[br]
##
## Generates random float values between [param from] and [param to] (inclusive).
## See [FloatFuzzer] for detailed documentation and examples.
static func rangef(from: float, to: float) -> FloatFuzzer:
	return FloatFuzzer.new(from, to)


## Creates a [Vector2Fuzzer] for generating random 2D vectors within a range.[br]
##
## Generates random Vector2 values where each component is bounded by
## [param from] and [param to] (inclusive).
## See [Vector2Fuzzer] for detailed documentation and examples.
static func rangev2(from: Vector2, to: Vector2) -> Vector2Fuzzer:
	return Vector2Fuzzer.new(from, to)


## Creates a [Vector3Fuzzer] for generating random 3D vectors within a range.[br]
##
## Generates random Vector3 values where each component is bounded by
## [param from] and [param to] (inclusive).
## See [Vector3Fuzzer] for detailed documentation and examples.
static func rangev3(from: Vector3, to: Vector3) -> Vector3Fuzzer:
	return Vector3Fuzzer.new(from, to)


## Creates an [IntFuzzer] that generates only even integers.[br]
##
## Generates random even integers between [param from] and [param to] (inclusive)
## using [constant IntFuzzer.EVEN] mode.
## See [IntFuzzer] for detailed documentation about even number generation.
static func eveni(from: int, to: int) -> IntFuzzer:
	return IntFuzzer.new(from, to, IntFuzzer.EVEN)


## Creates an [IntFuzzer] that generates only odd integers.[br]
##
## Generates random odd integers between [param from] and [param to] (inclusive)
## using [constant IntFuzzer.ODD] mode.
## See [IntFuzzer] for detailed documentation about odd number generation.
static func oddi(from: int, to: int) -> IntFuzzer:
	return IntFuzzer.new(from, to, IntFuzzer.ODD)
