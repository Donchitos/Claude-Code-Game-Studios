extends GdUnitTestSuite

@warning_ignore_start("unused_private_class_variable")
var _member_node1 := T2.new() # produces an orphan Node2D


func after() -> void:
	await get_tree().process_frame
	collect_orphan_node_details()


func _after_test() -> void:
	collect_orphan_node_details()


func test_orphans2() -> void:
	var _func_ref2 := RefCounted.new() # is refcounted and never orphan
	var _func_obj2 := Object.new() # produces an orphan Object
	var _func_node2 := Node3D.new() # produces an orphan Node3D
	collect_orphan_node_details()


func test_orphans3() -> void:
	var _func_node3 := Node3D.new() # produces an orphan Node3D
	var t2 := T2.new()
	add_child(t2)
	collect_orphan_node_details()


func test_with_scene_orphans() -> void:
	# run scene with orphan nodes
	var runner := scene_runner("res://addons/gdUnit4/test/core/execution/resources/OrphanScene.tscn")
	@warning_ignore("redundant_await")
	await runner.simulate_frames(10)
	collect_orphan_node_details()


func test_load_scene_orphans() -> void:
	# run scene with orphan nodes
	var _scene :Node2D = preload("res://addons/gdUnit4/test/core/execution/resources/OrphanScene.tscn").instantiate()
	collect_orphan_node_details()


func _test_no_orphans() -> void:
	var _func_node2 :Node3D = auto_free(Node3D.new())
	collect_orphan_node_details()
