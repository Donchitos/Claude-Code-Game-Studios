# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name GdUnitSignalAwaiterTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/GdUnitSignalAwaiter.gd'


class Monster extends Node:

	signal move(value :float)
	signal slide(value :float, x :int, z :int)

	var _pos :float = 0.0

	func _process(_delta :float) -> void:
		_pos += 0.2
		emit_signal(move.get_name(), _pos)
		emit_signal(slide.get_name(), _pos, 1 , 2)


func test_on_signal_with_single_arg() -> void:
	var monster :Monster = auto_free(Monster.new())
	add_child(monster)
	var signal_arg :Variant = await await_signal_on(monster, "move", [1.0])
	assert_float(signal_arg).is_equal(1.0)
	remove_child(monster)


func test_on_signal_with_many_args() -> void:
	var monster :Monster = auto_free(Monster.new())
	add_child(monster)
	var signal_args :Variant = await await_signal_on(monster, "slide", [1.0, 1, 2])
	assert_array(signal_args).is_equal([1.0, 1, 2])
	remove_child(monster)


func test_on_signal_fail() -> void:
	var monster :Monster = auto_free(Monster.new())
	add_child(monster)
	(
		await assert_failure_await( func x() -> void: await await_signal_on(monster, "move", [4.0]))
	).has_message("await_signal_on(move, [$v0]) timed out after 2000ms".replace("$v0", str(4.0)))
	remove_child(monster)
