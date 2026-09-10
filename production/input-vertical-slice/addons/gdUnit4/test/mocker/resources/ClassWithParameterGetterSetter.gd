class_name ClassWithParameterGetterSetter
extends RefCounted


var _session_count: int = 42:
	get:
		return _session_count
	set(value):
		_session_count = value


func session_count() -> int:
	return _session_count
