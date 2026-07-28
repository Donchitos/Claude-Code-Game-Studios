## A fuzzer that generates random Vector3 values within a specified box range.[br]
##
## This is particularly useful for testing 3D physics, spatial
## positioning, camera systems, particle effects, or any code that processes 3D vectors.[br]
##
## The fuzzer generates vectors where each component (x, y, z) is independently
## randomized within its respective range, creating a uniform distribution over the
## 3D box volume.[br]
##
## [b]Usage example:[/b]
## [codeblock]
## # Test 3D object placement within world bounds
## func test_spawn_position(fuzzer := Vector3Fuzzer.new(Vector3(-100, 0, -100), Vector3(100, 50, 100)), _fuzzer_iterations := 300):
##     var position := fuzzer.next_value()
##     var object = spawn_object(position)
##
## [/codeblock]
class_name Vector3Fuzzer
extends Fuzzer


## Minimum bounds for the generated vectors (inclusive for x, y, and z).
var _from: Vector3
## Maximum bounds for the generated vectors (inclusive for x, y, and z).
var _to: Vector3


func _init(from: Vector3, to: Vector3) -> void:
	assert(from <= to, "Invalid range!")
	_from = from
	_to = to


## Generates a random Vector3 within the configured box range.[br]
##
## Returns a Vector3 where each component is independently randomized:[br]
## - x: random float between [code]_from.x[/code] and [code]_to.x[/code][br]
## - y: random float between [code]_from.y[/code] and [code]_to.y[/code][br]
## - z: random float between [code]_from.z[/code] and [code]_to.z[/code][br]
##
## The distribution is uniform over the 3D box volume defined by the bounds.[br]
##
## @returns A random Vector3 within the specified range.
func next_value() -> Vector3:
	var x := randf_range(_from.x, _to.x)
	var y := randf_range(_from.y, _to.y)
	var z := randf_range(_from.z, _to.z)
	return Vector3(x, y, z)
