class_name ProductionPoolBorrowBuffer
extends RefCounted

var borrow_id: int = 0
var slot_id: int = -1

func clear() -> void:
	borrow_id = 0
	slot_id = -1
