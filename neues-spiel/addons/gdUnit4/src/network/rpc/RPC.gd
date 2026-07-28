class_name RPC
extends RefCounted


var _data: Dictionary = {}


func _init(obj: Object = null) -> void:
	if obj != null:
		if obj.has_method("serialize"):
			_data = obj.call("serialize")
		else:
			_data = inst_to_dict(obj)


func get_data() -> Object:
	return dict_to_inst(_data)


func serialize() -> String:
	return JSON.stringify(inst_to_dict(self))


# using untyped version see comments below
static func deserialize(json_value: String) -> Object:
	var json := JSON.new()
	var err := json.parse(json_value)
	if err != OK:
		push_error("Can't deserialize JSON, error at line %d:\n	error: %s \n	json: '%s'"
			% [json.get_error_line(), json.get_error_message(), json_value])
		return null
	var result: Dictionary = json.get_data()
	if not typeof(result) == TYPE_DICTIONARY:
		push_error("Can't deserialize JSON. Expecting dictionary, error at line %d:\n	error: %s \n	json: '%s'"
			% [result.error_line, result.error_string, json_value])
		return null
	return dict_to_inst(result)
