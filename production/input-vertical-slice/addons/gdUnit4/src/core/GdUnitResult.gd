class_name GdUnitResult
extends RefCounted

enum {
	SUCCESS,
	WARN,
	ERROR,
	EMPTY
}

var _state: int
var _warn_message := ""
var _error_message := ""
var _value :Variant = null


static func empty() -> GdUnitResult:
	var result := GdUnitResult.new()
	result._state = EMPTY
	return result


static func success(p_value: Variant = "") -> GdUnitResult:
	assert(p_value != null, "The value must not be NULL")
	var result := GdUnitResult.new()
	result._value = p_value
	result._state = SUCCESS
	return result


static func warn(p_warn_message: String, p_value: Variant = null) -> GdUnitResult:
	assert(not p_warn_message.is_empty()) #,"The message must not be empty")
	var result := GdUnitResult.new()
	result._value = p_value
	result._warn_message = p_warn_message
	result._state = WARN
	return result


static func error(p_error_message: String) -> GdUnitResult:
	assert(not p_error_message.is_empty(), "The message must not be empty")
	var result := GdUnitResult.new()
	result._value = null
	result._error_message = p_error_message
	result._state = ERROR
	return result


func is_success() -> bool:
	return _state == SUCCESS


func is_warn() -> bool:
	return _state == WARN


func is_error() -> bool:
	return _state == ERROR


func is_empty() -> bool:
	return _state == EMPTY


func value() -> Variant:
	return _value


func value_as_string() -> String:
	return _value


func or_else(p_value: Variant) -> Variant:
	if not is_success():
		return p_value
	return value()


func error_message() -> String:
	return _error_message


func warn_message() -> String:
	return _warn_message


func _to_string() -> String:
	return str(GdUnitResult.serialize(self))


static func serialize(result: GdUnitResult) -> Dictionary:
	if result == null:
		push_error("Can't serialize a Null object from type GdUnitResult")
	return {
		"state" : result._state,
		"value" : var_to_str(result._value),
		"warn_msg" : result._warn_message,
		"err_msg" : result._error_message
	}


static func deserialize(config: Dictionary) -> GdUnitResult:
	var result := GdUnitResult.new()
	var cfg_value: String = config.get("value", "")
	result._value = str_to_var(cfg_value)
	result._warn_message = config.get("warn_msg", null)
	result._error_message = config.get("err_msg", null)
	result._state = config.get("state")
	return result
