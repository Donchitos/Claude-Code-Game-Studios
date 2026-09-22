extends RefCounted


func no_arg_multiline(
) -> void:
	pass


func single_arg_multiline(
	_arg1: int
) -> void:
	pass


func multi_arg_multiline(
	_arg1: int,
	_arg2: String,
	_arg3: String
) -> void:
	pass


## See https://github.com/godot-gdunit-labs/gdUnit4/issues/1096
func multi_arg_with_backslashes_multiline(\
	_arg1: int,\
	_arg2: String,\
	_arg3: String\
) -> void:
	pass
