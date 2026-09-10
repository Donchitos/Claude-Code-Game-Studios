@warning_ignore_start("unsafe_method_access")
# GdUnit generated TestSuite
class_name CmdCommandHandlerTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/cmd/CmdCommandHandler.gd'

var _cmd_options: CmdOptions
var _cmd_instance: TestCommands


# small example of command class
class TestCommands:
	func cmd_no_arg() -> String:
		return ""

	func cmd_foo() -> String:
		return "cmd_foo"

	func cmd_arg(value: String) -> String:
		return value

	func cmd_args(values: PackedStringArray) -> Array:
		return values

	func cmd_x() -> String:
		return "cmd_x"


func before() -> void:
	# setup command options
	_cmd_options = CmdOptions.new([
		CmdOption.new("-a", "some help text a", "some description a"),
		CmdOption.new("-f, --foo", "some help text foo", "some description foo"),
		CmdOption.new("-arg, --arg", "some help text bar", "some description bar")
	],
	# advnaced options
	[
		CmdOption.new("-x", "some help text x", "some description x"),
	])
	_cmd_instance = TestCommands.new()


func test_register_cb() -> void:
	var cmd_handler: = CmdCommandHandler.new(_cmd_options)

	# register a single argumend cb
	cmd_handler.register_cb("-a", _cmd_instance.cmd_arg)
	assert_dict(cmd_handler._command_cbs).contains_key_value("-a", [_cmd_instance.cmd_arg, CmdCommandHandler.NO_CB])


func test_register_invalid_cb() -> void:
	var cmd_handler: = CmdCommandHandler.new(_cmd_options)
	# try to register a multi argumend cb
	cmd_handler.register_cb("-a", _cmd_instance.cmd_args)
	# verify the cb is not registered
	assert_dict(cmd_handler._command_cbs).is_empty()


func test_register_cbv() -> void:
	var cmd_handler: = CmdCommandHandler.new(_cmd_options)

	# register a single argumend cb
	cmd_handler.register_cbv("-a", _cmd_instance.cmd_args)
	assert_dict(cmd_handler._command_cbs).contains_key_value("-a", [CmdCommandHandler.NO_CB, _cmd_instance.cmd_args])


func test_register_invalid_cbv() -> void:
	var cmd_handler: = CmdCommandHandler.new(_cmd_options)
	# try to register a single argumend cb
	cmd_handler.register_cbv("-a", _cmd_instance.cmd_arg)
	# verify the cb is not registered
	assert_dict(cmd_handler._command_cbs).is_empty()


func test_register_cb_and_cbv() -> void:
	var cmd_handler: = CmdCommandHandler.new(_cmd_options)

	cmd_handler.register_cb("-a", _cmd_instance.cmd_arg)
	cmd_handler.register_cbv("-a", _cmd_instance.cmd_args)
	assert_dict(cmd_handler._command_cbs).contains_key_value("-a", [_cmd_instance.cmd_arg, _cmd_instance.cmd_args])


func test__validate_no_registerd_commands() -> void:
	var cmd_handler := CmdCommandHandler.new(_cmd_options)

	assert_result(cmd_handler._validate()).is_success()


func test__validate_registerd_commands() -> void:
	var cmd_handler: = CmdCommandHandler.new(_cmd_options)
	cmd_handler.register_cb("-a", _cmd_instance.cmd_no_arg)
	cmd_handler.register_cb("-f", _cmd_instance.cmd_foo)
	cmd_handler.register_cb("-arg", _cmd_instance.cmd_arg)

	assert_result(cmd_handler._validate()).is_success()


func test__validate_registerd_unknown_commands() -> void:
	var cmd_handler: = CmdCommandHandler.new(_cmd_options)
	cmd_handler.register_cb("-a", _cmd_instance.cmd_no_arg)
	cmd_handler.register_cb("-d", _cmd_instance.cmd_foo)
	cmd_handler.register_cb("-arg", _cmd_instance.cmd_arg)
	cmd_handler.register_cb("-y", _cmd_instance.cmd_x)

	assert_result(cmd_handler._validate())\
		.is_error()\
		.contains_message("The command '-d' is unknown, verify your CmdOptions!\nThe command '-y' is unknown, verify your CmdOptions!")


func test__validate_registerd_invalid_callbacks() -> void:
	var cmd_handler := CmdCommandHandler.new(_cmd_options)
	cmd_handler.register_cb("-a", _cmd_instance.cmd_no_arg)
	cmd_handler.register_cb("-arg", Callable(_cmd_instance, "cmd_not_exists"))

	assert_result(cmd_handler._validate())\
		.is_error()\
		.contains_message("Invalid function reference for command '-arg', Check the function reference!")


func test__validate_registerd_register_same_callback_twice() -> void:
	var cmd_handler: = CmdCommandHandler.new(_cmd_options)
	cmd_handler.register_cb("-a", _cmd_instance.cmd_no_arg)
	cmd_handler.register_cb("-arg", _cmd_instance.cmd_no_arg)
	assert_result(cmd_handler._validate())\
		.is_error()\
		.contains_message("The function reference 'cmd_no_arg' already registerd for command '-a'!")


func test_execute_no_commands() -> void:
	var cmd_handler: = CmdCommandHandler.new(_cmd_options)
	assert_result(cmd_handler.execute([])).is_success()


func test_execute_commands_no_cb_registered() -> void:
	var cmd_handler: = CmdCommandHandler.new(_cmd_options)
	assert_result(cmd_handler.execute([CmdCommand.new("-a")])).is_success()


func test_execute_commands_with_cb_registered() -> void:
	var cmd_handler: = CmdCommandHandler.new(_cmd_options)
	var cmd_spy: TestCommands = spy(_cmd_instance)

	cmd_handler.register_cb("-arg", cmd_spy.cmd_arg)
	cmd_handler.register_cbv("-arg", cmd_spy.cmd_args)
	cmd_handler.register_cb("-a", cmd_spy.cmd_no_arg)

	assert_result(cmd_handler.execute([CmdCommand.new("-a")])).is_success()

	verify(cmd_spy).cmd_no_arg()
	verify_no_more_interactions(cmd_spy)

	reset(cmd_spy)
	assert_result(cmd_handler.execute([
		CmdCommand.new("-a"),
		CmdCommand.new("-arg", ["some_value"]),
		CmdCommand.new("-arg", ["value1", "value2"])])).is_success()
	verify(cmd_spy).cmd_no_arg()
	verify(cmd_spy).cmd_arg("some_value")
	verify(cmd_spy).cmd_args(PackedStringArray(["value1", "value2"]))
	verify_no_more_interactions(cmd_spy)
