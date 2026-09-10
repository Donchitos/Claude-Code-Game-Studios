extends EditorInspectorPlugin


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass


func _can_handle(_object :Object) -> bool:
	return true


@warning_ignore("unused_parameter")
func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	return false
