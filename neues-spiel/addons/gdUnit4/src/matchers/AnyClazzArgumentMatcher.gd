class_name AnyClazzArgumentMatcher
extends GdUnitArgumentMatcher

var _clazz :Object


func _init(clazz :Object) -> void:
	_clazz = clazz


func is_match(value :Variant) -> bool:
	if typeof(value) != TYPE_OBJECT:
		return false
	if is_instance_valid(value) and GdObjects.is_script(_clazz):
		@warning_ignore("unsafe_cast")
		return (value as Object).get_script() == _clazz
	return is_instance_of(value, _clazz)


func _to_string() -> String:
	if (_clazz as Object).is_class("GDScriptNativeClass"):
		@warning_ignore("unsafe_method_access")
		var instance :Object = _clazz.new()
		var clazz_name := instance.get_class()
		if not instance is RefCounted:
			instance.free()
		return "any_class(<"+clazz_name+">)";
	if _clazz is GDScript:
		var result := GdObjects.extract_class_name(_clazz)
		if result.is_success():
			return "any_class(<"+ result.value() + ">)"
	return "any_class()"
