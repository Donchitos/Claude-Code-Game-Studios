## A fuzzer that generates random boolean values for testing.[br]
##
## This is useful for testing code paths that
## depend on boolean conditions, flags, or toggle states.[br]
##
## [b]Usage example:[/b]
## [codeblock]
## func test_toggle_feature(fuzzer := BoolFuzzer.new(), _fuzzer_iterations = 100):
##     var enabled := fuzzer.next_value()
##     my_feature.set_enabled(enabled)
##     assert_bool(my_feature.is_enabled()),is_equal(enabled)
## [/codeblock]
class_name BoolFuzzer
extends Fuzzer


## Generates a random boolean value.[br]
##
## Returns either [code]true[/code] or [code]false[/code] with equal probability.
## This method is called automatically during fuzz testing iterations.[br]
##
## @returns A randomly generated boolean value ([code]true[/code] or [code]false[/code]).
func next_value() -> bool:
	return randi() % 2
