extends Object

const Type = preload("types.gd")

var type := -1 :
	get:
		return type
	set(value):
		type = value
		_set_type_name(value)

var type_name :String


func _set_type(t:int) -> void:
	type = t


func _set_type_name(type_ :int) -> void:
	type_name = Type.to_str(type_)
	print("type was set to %s" % type_name)
