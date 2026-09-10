# GdUnit generated TestSuite
class_name GdUnitToolsTest
extends GdUnitTestSuite

const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/GdUnitTools.gd'


class InnerTestNodeClass extends Node:
	pass

class InnerTestRefCountedClass extends RefCounted:
	pass


func test_free_instance() -> void:
	# on valid instances
	assert_bool(await GdUnitTools.free_instance(RefCounted.new())).is_true()
	assert_bool(await GdUnitTools.free_instance(Node.new())).is_true()
	assert_bool(await GdUnitTools.free_instance(JavaClass.new())).is_true()
	assert_bool(await GdUnitTools.free_instance(InnerTestNodeClass.new())).is_true()
	assert_bool(await GdUnitTools.free_instance(InnerTestRefCountedClass.new())).is_true()

	# on invalid instances
	assert_bool(await GdUnitTools.free_instance(null)).is_false()
	assert_bool(await GdUnitTools.free_instance(RefCounted)).is_false()

	# on already freed instances
	var node := Node.new()
	node.free()
	assert_bool(await GdUnitTools.free_instance(node)).is_false()


func test_richtext_normalize() -> void:
	assert_that(GdUnitTools.richtext_normalize("")).is_equal("")
	assert_that(GdUnitTools.richtext_normalize("This is a Color Message")).is_equal("This is a Color Message")

	var message := """
		[color=green]line [/color][color=aqua]11:[/color] [color=#CD5C5C]Expecting:[/color]
			must be empty but was
		'[color=#1E90FF]after[/color]'
		"""
	assert_that(GdUnitTools.richtext_normalize(message)).is_equal("""
		line 11: Expecting:
			must be empty but was
		'after'
		""")
