class_name CmdArgumentParser
extends RefCounted

var _options :CmdOptions
var _tool_name :String
var _parsed_commands :Dictionary = Dictionary()


func _init(p_options :CmdOptions, p_tool_name :String) -> void:
	_options = p_options
	_tool_name = p_tool_name


func parse(args :Array, ignore_unknown_cmd := false) -> GdUnitResult:
	_parsed_commands.clear()

	# parse until first program argument
	while not args.is_empty():
		var arg :String = args.pop_front()
		if arg.find(_tool_name) != -1:
			break

	if args.is_empty():
		return GdUnitResult.empty()

	# now parse all arguments
	while not args.is_empty():
		var cmd :String = args.pop_front()
		var option := _options.get_option(cmd)

		if option:
			if _parse_cmd_arguments(option, args) == -1:
				return GdUnitResult.error("The '%s' command requires an argument!" % option.short_command())
		elif not ignore_unknown_cmd:
			return GdUnitResult.error("Unknown '%s' command!" % cmd)
	return GdUnitResult.success(_parsed_commands.values())


func options() -> CmdOptions:
	return _options


func _parse_cmd_arguments(option: CmdOption, args: Array) -> int:
	var command_name := option.short_command()
	var command: CmdCommand = _parsed_commands.get(command_name, CmdCommand.new(command_name))

	if option.has_argument():
		if not option.is_argument_optional() and args.is_empty():
			return -1
		if _is_next_value_argument(args):
			var value: String = args.pop_front()
			command.add_argument(value)
		elif not option.is_argument_optional():
			return -1
	_parsed_commands[command_name] = command
	return 0


func _is_next_value_argument(args: PackedStringArray) -> bool:
	if args.is_empty():
		return false
	return _options.get_option(args[0]) == null
