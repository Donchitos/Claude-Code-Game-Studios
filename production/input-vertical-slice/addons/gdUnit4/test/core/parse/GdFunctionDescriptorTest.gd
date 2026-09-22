# GdUnit generated TestSuite
class_name GdFunctionDescriptorTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/parse/GdFunctionDescriptor.gd'

const RETURN_TYPE_VARIANTS_SOURCE := """
	enum MyEnum { A, B }

	@warning_ignore("untyped_declaration")
	func inferred_void_pass():
		pass

	func explicit_void_pass() -> void:
		pass

	@warning_ignore("untyped_declaration")
	func inferred_void_return():
		return

	func explicit_void_return() -> void:
		return

	@warning_ignore("untyped_declaration")
	func inferred_int():
		return 42

	func explicit_int() -> int:
		return 42

	@warning_ignore("untyped_declaration")
	func inferred_bool():
		return true

	func explicit_bool() -> bool:
		return true

	@warning_ignore("untyped_declaration")
	func inferred_double():
		return 4.7

	func explicit_double() -> float:
		return 4.7

	@warning_ignore("untyped_declaration")
	func inferred_string():
		return "abc"

	func explicit_string() -> String:
		return "abc"

	@warning_ignore("untyped_declaration")
	func inferred_object():
		return Object.new()

	func explicit_object() -> Object:
		return Object.new()

	@warning_ignore("untyped_declaration")
	func inferred_enum():
		return MyEnum.A

	func explicit_enum() -> MyEnum:
		return MyEnum.A
	"""

var _return_type_variants_script: GDScript

func before() -> void:
	_return_type_variants_script = GdScriptTestHelper.build_tmp_script(RETURN_TYPE_VARIANTS_SOURCE)


func test_extract_from_func_without_return_type() -> void:
	# void add_sibling(sibling: Node, force_readable_name: bool = false)
	var method_descriptor := GdScriptTestHelper.get_class_method_descriptor("Node", "add_sibling")
	var fd := GdFunctionDescriptor.extract_from(method_descriptor)
	assert_str(fd.name()).is_equal("add_sibling")
	assert_bool(fd.is_virtual()).is_false()
	assert_bool(fd.is_static()).is_false()
	assert_bool(fd.is_engine()).is_true()
	assert_bool(fd.is_vararg()).is_false()
	assert_int(fd.return_type()).is_equal(GdObjects.TYPE_VOID)
	assert_array(fd.args()).contains_exactly([
		GdFunctionArgument.new("sibling", GdObjects.TYPE_NODE),
		GdFunctionArgument.new("force_readable_name", TYPE_BOOL, false)
	])


func test_extract_from_func_with_return_type() -> void:
	# Node find_child(pattern: String, recursive: bool = true, owned: bool = true) const
	var method_descriptor := GdScriptTestHelper.get_class_method_descriptor("Node", "find_child")
	var fd := GdFunctionDescriptor.extract_from(method_descriptor)
	assert_str(fd.name()).is_equal("find_child")
	assert_bool(fd.is_virtual()).is_false()
	assert_bool(fd.is_static()).is_false()
	assert_bool(fd.is_engine()).is_true()
	assert_bool(fd.is_vararg()).is_false()
	assert_int(fd.return_type()).is_equal(TYPE_OBJECT)
	assert_array(fd.args()).contains_exactly([
		GdFunctionArgument.new("pattern", TYPE_STRING),
		GdFunctionArgument.new("recursive", TYPE_BOOL, true),
		GdFunctionArgument.new("owned", TYPE_BOOL, true),
	])


func test_extract_from_func_with_vararg() -> void:
	# Error emit_signal(signal: StringName, ...) vararg
	var method_descriptor := GdScriptTestHelper.get_class_method_descriptor("Node", "emit_signal")
	var fd := GdFunctionDescriptor.extract_from(method_descriptor)
	assert_str(fd.name()).is_equal("emit_signal")
	assert_bool(fd.is_virtual()).is_false()
	assert_bool(fd.is_static()).is_false()
	assert_bool(fd.is_engine()).is_true()
	assert_bool(fd.is_vararg()).is_true()
	assert_int(fd.return_type()).is_equal(GdObjects.TYPE_ENUM)
	assert_array(fd.args()).contains_exactly([GdFunctionArgument.new("signal", TYPE_STRING_NAME)])
	assert_array(fd.varargs()).contains_exactly([
		GdFunctionArgument.new("varargs", GdObjects.TYPE_VARARG, '')
	])


func test_extract_from_descriptor_is_virtual_func() -> void:
	var method_descriptor := GdScriptTestHelper.get_class_method_descriptor("Node", "_enter_tree")
	var fd := GdFunctionDescriptor.extract_from(method_descriptor)
	assert_str(fd.name()).is_equal("_enter_tree")
	assert_bool(fd.is_virtual()).is_true()
	assert_bool(fd.is_static()).is_false()
	assert_bool(fd.is_engine()).is_true()
	assert_bool(fd.is_vararg()).is_false()
	assert_int(fd.return_type()).is_equal(GdObjects.TYPE_VOID)
	assert_array(fd.args()).is_empty()


func test_extract_from_descriptor_is_virtual_func_full_check() -> void:
	var methods := ClassDB.class_get_method_list("Node")
	var expected_virtual_functions := [
		"_process",
		"_physics_process",
		"_enter_tree",
		"_exit_tree",
		"_ready",
		"_get_configuration_warnings",
		"_get_accessibility_configuration_warnings",
		"_input",
		"_shortcut_input",
		"_unhandled_input",
		"_unhandled_key_input",
		"_get_focused_accessibility_element",
		"_init",
		"_to_string",
		"_notification",
		"_set",
		"_get",
		"_get_property_list",
		"_validate_property",
		"_property_can_revert",
		"_property_get_revert",
		"_iter_init",
		"_iter_next",
		"_iter_get"
	]

	var _count := 0
	for method_descriptor in methods:
		var fd := GdFunctionDescriptor.extract_from(method_descriptor)

		if fd.is_virtual():
			_count += 1
			assert_array(expected_virtual_functions).contains([fd.name()])
	assert_int(_count).is_equal(expected_virtual_functions.size())


func test_extract_from_func_with_return_type_variant() -> void:
	var method_descriptor := GdScriptTestHelper.get_class_method_descriptor("Node", "get")
	var fd := GdFunctionDescriptor.extract_from(method_descriptor)
	assert_str(fd.name()).is_equal("get")
	assert_bool(fd.is_virtual()).is_false()
	assert_bool(fd.is_static()).is_false()
	assert_bool(fd.is_engine()).is_true()
	assert_bool(fd.is_vararg()).is_false()
	assert_int(fd.return_type()).is_equal(GdObjects.TYPE_VARIANT)
	assert_array(fd.args()).contains_exactly([
		GdFunctionArgument.new("property", TYPE_STRING_NAME),
	])


#region extract_from return types
func test_extract_from_return_types(func_name: String, expected_type: int, _test_parameters := [
	# Explicit return expression: always the correc type
	["explicit_bool", TYPE_BOOL],
	["explicit_double", TYPE_FLOAT],
	["explicit_enum", GdObjects.TYPE_ENUM],
	["explicit_int", TYPE_INT],
	["explicit_object", TYPE_OBJECT],
	["explicit_string", TYPE_STRING],
	["explicit_void_pass", GdObjects.TYPE_VOID],
	["explicit_void_return", GdObjects.TYPE_VOID],
	# Inferred return expression: always TYPE_VARIANT
	["inferred_bool", GdObjects.TYPE_VARIANT],
	["inferred_double", GdObjects.TYPE_VARIANT],
	["inferred_enum", GdObjects.TYPE_VARIANT],
	["inferred_int", GdObjects.TYPE_VARIANT],
	["inferred_object", GdObjects.TYPE_VARIANT],
	["inferred_string", GdObjects.TYPE_VARIANT],
	["inferred_void_return", GdObjects.TYPE_VARIANT],
]) -> void:
	var method_descriptor := GdScriptTestHelper.get_script_method_descriptor(_return_type_variants_script, func_name)
	var fd := GdFunctionDescriptor.extract_from(method_descriptor, false)
	assert_int(fd.return_type()).is_equal(expected_type)


# Since Godot 4.7 (https://github.com/godotengine/godot/pull/118032), untyped functions
# correctly report TYPE_VARIANT via PROPERTY_USAGE_NIL_IS_VARIANT. On earlier versions,
# both untyped and explicit-void pass-body functions report usage=6 and are indistinguishable.
func test_extract_from_inferred_void_pass() -> void:
	var method_descriptor := GdScriptTestHelper.get_script_method_descriptor(_return_type_variants_script, "inferred_void_pass")
	var fd := GdFunctionDescriptor.extract_from(method_descriptor, false)
	var version := Engine.get_version_info()
	var expected_type: int = GdObjects.TYPE_VARIANT if version["minor"] >= 7 else GdObjects.TYPE_VOID
	assert_int(fd.return_type()).is_equal(expected_type)
#endregion


@warning_ignore("unused_parameter")
func example_signature(info: String, expected: int, test_parameters := [
	["aaa", 10],
	["bbb", 11],
]) -> void:
	pass
