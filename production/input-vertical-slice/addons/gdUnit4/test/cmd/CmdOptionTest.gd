# GdUnit generated TestSuite
class_name CmdOptionTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/cmd/CmdOption.gd'


func test_commands() -> void:
	assert_array(CmdOption.new("-a", "help a", "describe a").commands())\
		.contains_exactly(["-a"])
	assert_array(CmdOption.new("-a, --aaa", "help a", "describe a").commands())\
		.contains_exactly(["-a", "--aaa"])
	# containing space or tabs
	assert_array(CmdOption.new("-b ,  --bb	", "help a", "describe a")\
		.commands()).contains_exactly(["-b", "--bb"])


func test_short_command() -> void:
	assert_str(CmdOption.new("-a, --aaa", "help a", "describe a").short_command()).is_equal("-a")


func test_help() -> void:
	assert_str(CmdOption.new("-a, --aaa", "help a", "describe a").help()).is_equal("help a")


func test_description() -> void:
	assert_str(CmdOption.new("-a, --aaa", "help a", "describe a").description()).is_equal("describe a")


func test_type() -> void:
	assert_int(CmdOption.new("-a", "", "").type()).is_equal(TYPE_NIL)
	assert_int(CmdOption.new("-a", "", "", TYPE_STRING).type()).is_equal(TYPE_STRING)
	assert_int(CmdOption.new("-a", "", "", TYPE_BOOL).type()).is_equal(TYPE_BOOL)


func test_is_argument_optional() -> void:
	assert_bool(CmdOption.new("-a", "", "").is_argument_optional()).is_false()
	assert_bool(CmdOption.new("-a", "", "", TYPE_BOOL, false).is_argument_optional()).is_false()
	assert_bool(CmdOption.new("-a", "", "", TYPE_BOOL, true).is_argument_optional()).is_true()


func test_has_argument() -> void:
	assert_bool(CmdOption.new("-a", "", "").has_argument()).is_false()
	assert_bool(CmdOption.new("-a", "", "", TYPE_NIL).has_argument()).is_false()
	assert_bool(CmdOption.new("-a", "", "", TYPE_BOOL).has_argument()).is_true()


func test_describe() -> void:
	assert_str(CmdOption.new("-a, --aaa", "help a", "describe a").describe())\
		.is_equal('  ["-a", "--aaa"]                  describe a \n                                   help a\n')
