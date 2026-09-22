class_name ProductionSpatialQueryBuffer
extends RefCounted

var handle_ids := PackedInt64Array()
var count: int = 0
var required_capacity: int = 0

func configure(capacity: int) -> void:
	handle_ids.resize(maxi(0, capacity))
	clear()

func clear() -> void:
	count = 0
	required_capacity = 0
