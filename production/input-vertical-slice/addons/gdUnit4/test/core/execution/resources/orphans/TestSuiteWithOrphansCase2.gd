extends GdUnitTestSuite

@warning_ignore_start("unused_private_class_variable")
# Create an orphan node
var _member_node := Node3D.new()
@warning_ignore("untyped_declaration")
var _before_untyped
var _before_with_type: Node


func before() -> void:
	_before_untyped = Node.new()
	_before_with_type = Node.new()


func test_no_orphans_at_function() -> void:
	# Create an orphan node with using auto_free tool.
	var _node1 :Node3D = auto_free(Node3D.new())

	# Create an orphan node and release it manually.
	var _node2 := Node3D.new()
	_node2.free()


func test_orphans_at_function_without_details() -> void:
	# Create an orphan node
	var _node := Node3D.new() # produces an orphan Node3D

	# We adding this to collect details about
	collect_orphan_node_details()


func test_orphans_at_function_with_details() -> void:
	# Create an orphan node
	@warning_ignore("untyped_declaration")
	var _node = Node3D.new()

	# We adding this to collect details about
	collect_orphan_node_details()
