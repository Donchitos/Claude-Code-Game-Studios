# GdUnit generated TestSuite
class_name CmdArgumentParserTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/cmd/CmdArgumentParser.gd'

var option_a := CmdOption.new("-a", "some help text a", "some description a")
var option_f := CmdOption.new("-f, --foo", "some help text foo", "some description foo")
var option_b := CmdOption.new("-b, --bar", "-b <value>", "comand with required argument", TYPE_STRING)
var option_c := CmdOption.new("-c, --calc", "-c [value]", "command with optional argument", TYPE_STRING, true)
var option_x := CmdOption.new("-x", "some help text x", "some description x")

var _cmd_options :CmdOptions


func before() -> void:
	# setup command options
	_cmd_options = CmdOptions.new([
		option_a,
		option_f,
		option_b,
		option_c,
	],
	# advnaced options
	[
		option_x,
	])


func test_parse_success() -> void:
	var parser := CmdArgumentParser.new(_cmd_options, "CmdTool.gd")

	assert_result(parser.parse([])).is_empty()
	# check with godot cmd argumnents before tool argument
	assert_result(parser.parse(["-d", "dir/dir/CmdTool.gd"])).is_empty()

	# if valid argument set than don't show the help by default
	var result := parser.parse(["-d", "dir/dir/CmdTool.gd", "-a"])
	assert_result(result).is_success()
	assert_array(result.value()).contains_exactly([
		CmdCommand.new("-a"),
	])


func test_parse_success_required_arg() -> void:
	var parser := CmdArgumentParser.new(_cmd_options, "CmdTool.gd")

	var result := parser.parse(["-d", "dir/dir/CmdTool.gd", "-a", "-b", "valueA", "-b", "valueB"])
	assert_result(result).is_success()
	assert_array(result.value()).contains_exactly([
		CmdCommand.new("-a"),
		CmdCommand.new("-b", ["valueA", "valueB"]),
	])

	# useing command long term
	result = parser.parse(["-d", "dir/dir/CmdTool.gd", "-a", "--bar", "value"])
	assert_result(result).is_success()
	assert_array(result.value()).contains_exactly([
		CmdCommand.new("-a"),
		CmdCommand.new("-b", ["value"])
	])


func test_parse_success_optional_arg() -> void:
	var parser := CmdArgumentParser.new(_cmd_options, "CmdTool.gd")

	# without argument
	var result := parser.parse(["-d", "dir/dir/CmdTool.gd", "-c", "-a"])
	assert_result(result).is_success()
	assert_array(result.value()).contains_exactly([
		CmdCommand.new("-c"),
		CmdCommand.new("-a")
	])

	# without argument at end
	result = parser.parse(["-d", "dir/dir/CmdTool.gd", "-a", "-c"])
	assert_result(result).is_success()
	assert_array(result.value()).contains_exactly([
		CmdCommand.new("-a"),
		CmdCommand.new("-c")
	])

	# with argument
	result = parser.parse(["-d", "dir/dir/CmdTool.gd", "-c", "argument", "-a"])
	assert_result(result).is_success()
	assert_array(result.value()).contains_exactly([
		CmdCommand.new("-c", ["argument"]),
		CmdCommand.new("-a")
	])


func test_parse_success_repead_cmd_args() -> void:
	var parser := CmdArgumentParser.new(_cmd_options, "CmdTool.gd")

	# without argument
	var result := parser.parse(["-d", "dir/dir/CmdTool.gd", "-c", "argument", "-a"])
	assert_result(result).is_success()
	assert_array(result.value()).contains_exactly([
		CmdCommand.new("-c", ["argument"]),
		CmdCommand.new("-a")
	])

	# with repeading commands argument
	result = parser.parse(["-d", "dir/dir/CmdTool.gd", "-c", "argument1", "-a",  "-c", "argument2",  "-c", "argument3"])
	assert_result(result).is_success()
	assert_array(result.value()).contains_exactly([
		CmdCommand.new("-c", ["argument1", "argument2", "argument3"]),
		CmdCommand.new("-a")
	])


func test_parse_error() -> void:
	var parser := CmdArgumentParser.new(_cmd_options, "CmdTool.gd")

	assert_result(parser.parse([])).is_empty()

	# if invalid arguemens set than return with error and show the help by default
	assert_result(parser.parse(["-d", "dir/dir/CmdTool.gd", "-unknown"])).is_error()\
		.contains_message("Unknown '-unknown' command!")
