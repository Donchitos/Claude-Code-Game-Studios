## A fuzzer that generates random Vector2 values within a specified rectangular range.[br]
##
## This is particularly useful for testing 2D physics, movement
## systems, UI positioning, sprite coordinates, or any code that processes 2D vectors.[br]
##
## The fuzzer generates vectors where each component (x, y) is independently randomized
## within its respective range, creating a uniform distribution over the rectangular area.[br]
##
## [b]Usage example:[/b]
## [codeblock]
## # Test 2D movement within screen bounds
## func test_movement(fuzzer := Vector2Fuzzer.new(Vector2.ZERO, Vector2(1920, 1080)), _fuzzer_iterations := 200) -> void:
##     var position := fuzzer.next_value()
##     player.set_position(position)
##
## [/codeblock]
class_name Vector2Fuzzer
extends Fuzzer


## Minimum bounds for the generated vectors (inclusive for both x and y).
var _from: Vector2
## Maximum bounds for the generated vectors (inclusive for both x and y).
var _to: Vector2


func _init(from: Vector2, to: Vector2) -> void:
	assert(from <= to, "Invalid range!")
	_from = from
	_to = to


## Generates a random Vector2 within the configured rectangular range.[br]
##
## Returns a Vector2 where each component is independently randomized:[br]
## - x: random float between [code]_from.x[/code] and [code]_to.x[/code][br]
## - y: random float between [code]_from.y[/code] and [code]_to.y[/code][br]
##
## The distribution is uniform over the rectangular area defined by the bounds.[br]
##
## @returns A random Vector2 within the specified range.
func next_value() -> Vector2:
	var x := randf_range(_from.x, _to.x)
	var y := randf_range(_from.y, _to.y)
	return Vector2(x, y)
