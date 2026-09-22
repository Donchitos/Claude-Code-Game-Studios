## A fuzzer that generates random floating-point values within a specified range.[br]
##
## This is particularly useful for testing numerical calculations,
## physics simulations, shader parameters, or any code that processes floating-point
## values.[br]
##
## [b]Usage example:[/b]
## [codeblock]
## func test_calculate_damage(fuzzer := FloatFuzzer.new(0.0, 100.0), _fuzzer_iterations := 500):
##     var damage := fuzzer.next_value()
##     var result = calculate_damage_reduction(damage)
##     assert_float(result).is_between(0.0, damage)
## [/codeblock]
## [br]
## [b]Note:[/b] The range is inclusive on both ends, and values are uniformly distributed.
class_name FloatFuzzer
extends Fuzzer

## Minimum value (inclusive) for generated floats.
var _from: float = 0
## Maximum value (inclusive) for generated floats.
var _to: float = 0

func _init(from: float, to: float) -> void:
	assert(from <= to, "Invalid range!")
	_from = from
	_to = to


## Generates a random float value within the configured range.[br]
##
## Returns a uniformly distributed random float between [member _from] and
## [member _to] (inclusive). Each call produces a new random value.[br]
##
## @returns A random float value within the specified range.
func next_value() -> float:
	return randf_range(_from, _to)
