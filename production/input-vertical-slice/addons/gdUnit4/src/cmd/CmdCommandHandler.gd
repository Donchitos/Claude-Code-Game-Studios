class_name CmdCommandHandler
extends RefCounted

const CB_SINGLE_ARG = 0
const CB_MULTI_ARGS = 1
const NO_CB := Callable()

var _cmd_options :CmdOptions
# holds the command callbacks by key:<cmd_name>:String and value: [<cb single arg>, <cb multible args>]:Array
# Dictionary[String, Array[Callback]
var _command_cbs :Dictionary



func _init(cmd_options: CmdOptions) -> void:
	_cmd_options = cmd_options


# register a callback function for given command
# cmd_name short name of the command
# fr_arg a funcref to a function with a single argument
func register_cb(cmd_name: String, cb: Callable) -> CmdCommandHandler:
	var registered_cb: Array = _command_cbs.get(cmd_name, [NO_CB, NO_CB])
	if registered_cb[CB_SINGLE_ARG]:
		push_error("A function for command '%s' is already registered!" % cmd_name)
		return self

	if not _validate_cb_signature(cb, TYPE_STRING):
		push_error(
			("The callback '%s:%s' for command '%s' has invalid function signature. "
			+"The callback signature must be 'func name(value: PackedStringArray)'")
			% [cb.get_object().get_class(), cb.get_method(), cmd_name])
		return null

	registered_cb[CB_SINGLE_ARG] = cb
	_command_cbs[cmd_name] = registered_cb
	return self


# register a callback function for given command
# cb a funcref to a function with a variable number of arguments but expects all parameters to be passed via a single Array.
func register_cbv(cmd_name: String, cb: Callable) -> CmdCommandHandler:
	var registered_cb: Array = _command_cbs.get(cmd_name, [NO_CB, NO_CB])
	if registered_cb[CB_MULTI_ARGS]:
		push_error("A function for command '%s' is already registered!" % cmd_name)
		return self

	if not _validate_cb_signature(cb, TYPE_PACKED_STRING_ARRAY):
		push_error(
			("The callback '%s:%s' for command '%s' has invalid function signature. "
			+"The callback signature must be 'func name(value: PackedStringArray)'")
			% [cb.get_object().get_class(), cb.get_method(), cmd_name])
		return null

	registered_cb[CB_MULTI_ARGS] = cb
	_command_cbs[cmd_name] = registered_cb
	return self


func _validate() -> GdUnitResult:
	var errors := PackedStringArray()
	# Dictionary[StringName, String]
	var registered_cbs := Dictionary()

	for cmd_name in _command_cbs.keys() as Array[String]:
		var cb: Callable = (_command_cbs[cmd_name][CB_SINGLE_ARG]
			if _command_cbs[cmd_name][CB_SINGLE_ARG]
			else _command_cbs[cmd_name][CB_MULTI_ARGS])
		if cb != NO_CB and not cb.is_valid():
			@warning_ignore("return_value_discarded")
			errors.append("Invalid function reference for command '%s', Check the function reference!" % cmd_name)
		if _cmd_options.get_option(cmd_name) == null:
			@warning_ignore("return_value_discarded")
			errors.append("The command '%s' is unknown, verify your CmdOptions!" % cmd_name)
		# verify for multiple registered command callbacks
		if cb != NO_CB:
			var cb_method := cb.get_method()
			if registered_cbs.has(cb_method):
				var already_registered_cmd :String = registered_cbs[cb_method]
				@warning_ignore("return_value_discarded")
				errors.append("The function reference '%s' already registerd for command '%s'!" % [cb_method, already_registered_cmd])
			else:
				registered_cbs[cb_method] = cmd_name
	if errors.is_empty():
		return GdUnitResult.success(true)
	return GdUnitResult.error("\n".join(errors))


func execute(commands: Array[CmdCommand]) -> GdUnitResult:
	var result := _validate()
	if result.is_error():
		return result
	for cmd in commands:
		var cmd_name := cmd.name()
		if _command_cbs.has(cmd_name):
			var cb_s: Callable = _command_cbs.get(cmd_name)[CB_SINGLE_ARG]
			var arguments := cmd.arguments()
			var cmd_option := _cmd_options.get_option(cmd_name)

			if arguments.is_empty():
				cb_s.call()
			elif arguments.size() > 1:
				var cb_m: Callable = _command_cbs.get(cmd_name)[CB_MULTI_ARGS]
				cb_m.call(arguments)
			else:
				if cmd_option.type() == TYPE_BOOL:
					cb_s.call(true if arguments[0] == "true" else false)
				else:
					cb_s.call(arguments[0])

	return GdUnitResult.success(true)


func _validate_cb_signature(cb: Callable, arg_type: int) -> bool:
	for m in cb.get_object().get_method_list():
		if m["name"] == cb.get_method():
			@warning_ignore("unsafe_cast")
			return _validate_func_arguments(m["args"] as Array, arg_type)
	return true


func _validate_func_arguments(arguments: Array, arg_type: int) -> bool:
	# validate we have a single argument
	if arguments.size() > 1:
		return false
	# a cb with no arguments is also valid
	if arguments.size() == 0:
		return true
	# validate argument type
	var arg: Dictionary = arguments[0]
	@warning_ignore("unsafe_cast")
	if arg["usage"] as int == PROPERTY_USAGE_NIL_IS_VARIANT:
		return true
	if arg["type"] != arg_type:
		return false
	return true
