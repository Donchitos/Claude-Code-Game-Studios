class_name GdUnitOrphanNodeInfo
extends RefCounted


var _id: int
var _type: String
var _stack_element: GdUnitStackTraceElement


func _init(id: int, type: String, stack_element: GdUnitStackTraceElement) -> void:
	_id = id
	_type = type
	_stack_element = stack_element
