# this test suite fails on multiple stages and detects orphans
extends GdUnitTestSuite


var _orphans: Array[Node] = []
@warning_ignore("untyped_declaration")
var before_n1

func before() -> void:
	# create a node where never freed (orphan)
	before_n1 = Node.new()
	_orphans.append(before_n1)


func before_test() -> void:
	# create two node where never freed (orphan)
	var before_test_n1 := Node.new()
	var before_test_n2 := Node.new()
	_orphans.append_array([before_test_n1, before_test_n2])


# ends with warning and 3 orphan detected
func test_case1() -> void:
	# create three node where never freed (orphan)
	var n11 := Node.new()
	var n12 := Node.new()
	var n13 := Node.new()
	_orphans.append_array([n11, n12, n13])
	collect_orphan_node_details()


# ends with error and 4 orphan detected
func test_case2() -> void:
	# create four node where never freed (orphan)
	var n21 := Node.new()
	var n22 := Node.new()
	var n23 := Node.new()
	var n24 := Node.new()
	_orphans.append_array([n21, n22, n23, n24])
	fail("fail on test_case2()")
	collect_orphan_node_details()


# we manually freeing the orphans from the simulated testsuite to prevent memory leaks here
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for orphan in _orphans:
			orphan.free()
		_orphans.clear()
