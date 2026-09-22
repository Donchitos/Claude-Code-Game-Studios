extends GdUnitTestSuite


func test_no_orphans() -> void:
	# Create an orphan node with using auto_free tool.
	var _node1: Node3D = auto_free(Node3D.new())

	# Create an orphan node and release it manually.
	var _node2 := Node3D.new()
	_node2.free()


func test_orphans_one() -> void:
	# Create an orphan node
	var _node := Node3D.new() # produces an orphan Node3D

	# We adding this to collect details about
	collect_orphan_node_details()


func test_orphans_two() -> void:
	# Create an orphan node
	var _node := Node3D.new()

	# We adding this to collect details about
	collect_orphan_node_details()
