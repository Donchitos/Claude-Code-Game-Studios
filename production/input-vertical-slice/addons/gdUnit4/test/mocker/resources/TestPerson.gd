class_name TestPerson
extends Object

var _name :String
var _value :int
var _address :Address

class Address:
	var _street :String
	var _code :int

	func _init(street :String, code :int) -> void:
		_street = street
		_code = code


func _init(name_ :String, street :String, code :int) -> void:
	_name = name_
	_value = 1024
	_address = Address.new(street, code)

func name() -> String:
	return _name
