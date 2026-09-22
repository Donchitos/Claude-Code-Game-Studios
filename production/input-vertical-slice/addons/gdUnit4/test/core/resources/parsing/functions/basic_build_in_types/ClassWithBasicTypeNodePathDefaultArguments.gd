class_name ClassWithBasicTypeNodePathDefaultArguments
extends RefCounted


func on_node_path_case1(value: NodePath) -> NodePath:
	return value


func on_node_path_case2(value: NodePath = "foo1") -> NodePath:
	return value


func on_node_path_case3(value: NodePath = NodePath("foo2")) -> NodePath:
	return value


func on_node_path_case4(value := NodePath(NodePath("foo3"))) -> NodePath:
	return value
