class_name RPCGdUnitEvent
extends RPC


static func of(p_event: GdUnitEvent) -> RPCGdUnitEvent:
	return RPCGdUnitEvent.new(p_event)


func event() -> GdUnitEvent:
	return GdUnitEvent.new().deserialize(_data)


func _to_string() -> String:
	return "RPCGdUnitEvent: " + str(_data)
