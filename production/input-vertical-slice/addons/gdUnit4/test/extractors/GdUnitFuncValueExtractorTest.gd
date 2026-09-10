# GdUnit generated TestSuite
class_name GdUnitFuncValueExtractorTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/extractors/GdUnitFuncValueExtractor.gd'


class TestNode extends Resource:
	var _parent :TestNode = null
	var _children := Array()

	func _init(name :String, parent :TestNode = null) -> void:
		set_name(name)
		_parent = parent
		if _parent:
			_parent._children.append(self)


	func _notification(what :int) -> void:
		if what == NOTIFICATION_PREDELETE:
			_parent = null
			_children.clear()


	func get_parent() -> TestNode:
		return _parent


	func get_children() -> Array:
		return _children



func test_extract_value_success() -> void:
	var node :TestNode = auto_free(TestNode.new("node_a"))

	assert_str(GdUnitFuncValueExtractor.new("get_name", []).extract_value(node)).is_equal("node_a")


func test_extract_value_func_not_exists() -> void:
	var node :TestNode = TestNode.new("node_a")

	assert_str(GdUnitFuncValueExtractor.new("get_foo", []).extract_value(node)).is_equal("n.a.")


func test_extract_value_on_null_value() -> void:
	assert_str(GdUnitFuncValueExtractor.new("get_foo", []).extract_value(null)).is_null()


func test_extract_value_chanined() -> void:
	var parent :TestNode = TestNode.new("parent")
	var node :TestNode = auto_free(TestNode.new("node_a", parent))

	assert_str(GdUnitFuncValueExtractor.new("get_name", []).extract_value(node)).is_equal("node_a")
	assert_str(GdUnitFuncValueExtractor.new("get_parent.get_name", []).extract_value(node)).is_equal("parent")


func test_extract_value_chanined_array_values() -> void:
	var parent :TestNode = TestNode.new("parent")
	auto_free(TestNode.new("node_a", parent))
	auto_free(TestNode.new("node_b", parent))
	auto_free(TestNode.new("node_c", parent))

	assert_array(GdUnitFuncValueExtractor.new("get_children.get_name", []).extract_value(parent))\
		.contains_exactly(["node_a", "node_b", "node_c"])
