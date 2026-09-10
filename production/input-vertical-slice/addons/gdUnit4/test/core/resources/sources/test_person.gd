extends RefCounted

var _first_name :String
var _last_name :String

func _init(first_name_ :String, last_name_ :String) -> void:
	_first_name = first_name_
	_last_name = last_name_

func first_name() -> String:
	return _first_name

func last_name() -> String:
	return _last_name

func fully_name() -> String:
	return _first_name + " " + _last_name
