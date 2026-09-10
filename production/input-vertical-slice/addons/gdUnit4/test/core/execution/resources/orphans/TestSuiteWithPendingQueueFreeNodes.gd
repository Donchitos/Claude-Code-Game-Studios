extends GdUnitTestSuite


var _holder: Node


func before_test() -> void:
	_holder = Node.new()
	add_child(_holder)
	for _index in range(0, 10):
		_holder.add_child(Node.new())


func after_test() -> void:
	remove_child(_holder)
	_holder.free()


func test_removes_and_queues_children_for_free() -> void:
	# The nodes are pending for deletion and must not be reported as orphans
	for child: Node in _holder.get_children():
		_holder.remove_child(child)
		child.queue_free()
	assert_int(_holder.get_child_count()).is_equal(0)
