# GdUnit generated TestSuite
class_name CmdCommandTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/cmd/CmdCommand.gd'


func test_create() -> void:
	var cmd_a := CmdCommand.new("cmd_a")
	assert_str(cmd_a.name()).is_equal("cmd_a")
	assert_array(cmd_a.arguments()).is_empty()

	var cmd_b := CmdCommand.new("cmd_b", ["arg1"])
	assert_str(cmd_b.name()).is_equal("cmd_b")
	assert_array(cmd_b.arguments()).contains_exactly(["arg1"])

	assert_object(cmd_a).is_not_equal(cmd_b)


func test_add_argument() -> void:
	var cmd_a := CmdCommand.new("cmd_a")
	cmd_a.add_argument("arg1")
	cmd_a.add_argument("arg2")
	assert_str(cmd_a.name()).is_equal("cmd_a")
	assert_array(cmd_a.arguments()).contains_exactly(["arg1", "arg2"])

	var cmd_b := CmdCommand.new("cmd_b", ["arg1"])
	cmd_b.add_argument("arg2")
	cmd_b.add_argument("arg3")
	assert_str(cmd_b.name()).is_equal("cmd_b")
	assert_array(cmd_b.arguments()).contains_exactly(["arg1", "arg2", "arg3"])
