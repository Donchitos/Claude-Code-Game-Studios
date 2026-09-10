# This test should detect orphan nodes created at 'before_test' hook
extends GdUnitTestSuite


var _member_node1: Node3D # will be orphan
var _member_node2: Node3D
var _member_node3: Node3D


func before_test() -> void:
	# Should be detected as an orhan because is never freed
	_member_node1 = Node3D.new()
	# Using auto_free should freeing the node by default
	_member_node2 = auto_free(Node3D.new())
	# Do manually freeing at 'after_test'
	_member_node3 = Node3D.new()


func after_test() -> void:
	# Do manual cleanup for node3
	_member_node3.free()


func after() -> void:
	assert_that(_member_node1).is_not_null()
	assert_that(_member_node2).is_null()
	assert_that(_member_node3).is_null()


func test_members() -> void:
	assert_that(_member_node1).is_not_null()
	assert_that(_member_node2).is_not_null()
	assert_that(_member_node3).is_not_null()
