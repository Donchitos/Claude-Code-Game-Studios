class_name GdUnitMock
extends RefCounted

## do call the real implementation
const CALL_REAL_FUNC = "CALL_REAL_FUNC"
## do return a default value for primitive types or null
const RETURN_DEFAULTS = "RETURN_DEFAULTS"
## do return a default value for primitive types and a fully mocked value for Object types
## builds full deep mocked object
const RETURN_DEEP_STUB = "RETURN_DEEP_STUB"

var _value: Variant


func _init(value: Variant) -> void:
	_value = value


## Selects the mock to work on, used in combination with [method GdUnitTestSuite.do_return][br]
## Example:
## 	[codeblock]
## 		do_return(false).on(myMock).is_selected()
## 	[/codeblock]
func on(obj: Variant) -> Variant:
	if not GdUnitMock._is_mock_or_spy(obj, "__do_return"):
		return obj
	@warning_ignore("unsafe_method_access")
	return obj.__do_return(_value)


## [color=yellow]`checked` is obsolete, use `on` instead [/color]
func checked(obj :Object) -> Object:
	push_warning("Using a deprecated function 'checked' use `on` instead")
	return on(obj)


static func _is_mock_or_spy(obj: Variant, func_sig: String) -> bool:
	if obj is Object and not as_object(obj).has_method(func_sig):
		push_error("Error: You try to use a non mock or spy!")
		return false
	return true


static func as_object(value: Variant) -> Object:
	return value
