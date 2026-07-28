## A fuzzer that generates random integer values with optional even/odd constraints.[br]
##
## It supports three modes: normal (any integer), even-only,
## and odd-only generation. This is useful for testing array indices, loop counters,
## enumeration values, or any code that processes integer values.[br]
##
## [b]Usage example:[/b]
## [codeblock]
## # Test with any integer in range
## func test_array_access(fuzzer = IntFuzzer.new(0, 99), fuzzer_iterations = 100):
##     var index = fuzzer.next_value()
##     var array = create_array(100)
##     assert(array[index] != null)
##
## # Test with only even numbers
## func test_even_processing(fuzzer := IntFuzzer.new(0, 100, IntFuzzer.EVEN)):
##     var even_num := fuzzer.next_value()
##     assert_int(even_num % 2).is_equal(0)
## [/codeblock]
class_name IntFuzzer
extends Fuzzer


## Generates any integer within the range.
enum {
	NORMAL, ## Generate any integer within the specified range.
	EVEN,   ## Generate only even integers within the specified range.
	ODD     ## Generate only odd integers within the specified range.
}


## Minimum value (inclusive) for generated integers.
var _from: int = 0
## Maximum value (inclusive) for generated integers.
var _to: int = 0
## Generation mode: NORMAL, EVEN, or ODD.
var _mode: int = NORMAL


func _init(from: int, to: int, mode: int = NORMAL) -> void:
	assert(from <= to, "Invalid range!")
	_from = from
	_to = to
	_mode = mode


## Generates a random integer value based on the configured mode.[br]
##
## Returns a random integer between [member _from] and [member _to] (inclusive).[br]
## The value will be constrained according to the [member _mode]:[br]
## - [constant NORMAL]: Any integer in the range[br]
## - [constant EVEN]: Only even integers[br]
## - [constant ODD]: Only odd integers[br]
##
## [b]Example:[/b]
## [codeblock]
## var normal_fuzzer = IntFuzzer.new(1, 10, IntFuzzer.NORMAL)
## var even_fuzzer = IntFuzzer.new(1, 10, IntFuzzer.EVEN)
## var odd_fuzzer = IntFuzzer.new(1, 10, IntFuzzer.ODD)
##
## print(normal_fuzzer.next_value())  # Could be any: 1, 2, 3, ..., 10
## print(even_fuzzer.next_value())    # Only even: 2, 4, 6, 8, 10
## print(odd_fuzzer.next_value())     # Only odd: 1, 3, 5, 7, 9
## [/codeblock]
##
## @returns A random integer value within the specified range and mode
func next_value() -> int:
	var value := randi_range(_from, _to)
	match _mode:
		NORMAL:
			return value
		EVEN:
			return int((value / 2.0) * 2)
		ODD:
			return int((value / 2.0) * 2 + 1)
		_:
			return value
