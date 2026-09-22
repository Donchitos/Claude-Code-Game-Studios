class_name T2
extends Node2D

var t3 := T3.new()

func _ready() -> void:
	set_name("T2")
	# This node is tracked as orphan but we can not collect details from the script_backtraces
	var _x2 := Node2D.new()
	prints("_x2", _x2.get_instance_id())
