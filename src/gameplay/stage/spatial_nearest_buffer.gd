class_name ProductionSpatialNearestBuffer
extends RefCounted

var has_handle: bool = false
var handle_id: int = 0

func clear() -> void:
	has_handle = false
	handle_id = 0
