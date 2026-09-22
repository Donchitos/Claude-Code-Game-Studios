# GdUnit generated TestSuite
class_name CmdOptionsTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/cmd/CmdOptions.gd'


var option_a := CmdOption.new("-a", "some help text a", "some description a")
var option_f := CmdOption.new("-f, --foo", "some help text foo", "some description foo")
var option_b := CmdOption.new("-b, --bar", "some help text bar", "some description bar")
var option_x := CmdOption.new("-x", "some help text x", "some description x")

var _cmd_options :CmdOptions


func before() -> void:
	# setup command options
	_cmd_options = CmdOptions.new([
		option_a,
		option_f,
		option_b,
	],
	# advnaced options
	[
		option_x,
	])


func test_get_option() -> void:
	assert_object(_cmd_options.get_option("-a")).is_same(option_a)
	assert_object(_cmd_options.get_option("-f")).is_same(option_f)
	assert_object(_cmd_options.get_option("--foo")).is_same(option_f)
	assert_object(_cmd_options.get_option("-b")).is_same(option_b)
	assert_object(_cmd_options.get_option("--bar")).is_same(option_b)
	assert_object(_cmd_options.get_option("-x")).is_same(option_x)
	# for not existsing command
	assert_object(_cmd_options.get_option("-z")).is_null()


func test_default_options() -> void:
	assert_array(_cmd_options.default_options()).contains_exactly([
		option_a,
		option_f,
		option_b])


func test_advanced_options() -> void:
	assert_array(_cmd_options.advanced_options()).contains_exactly([option_x])


func test_options() -> void:
	assert_array(_cmd_options.options()).contains_exactly([
		option_a,
		option_f,
		option_b,
		option_x])
