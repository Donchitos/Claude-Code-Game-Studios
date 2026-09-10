class_name GdUnitFunctionDoublerBuilder
extends RefCounted

const TYPE_VOID = GdObjects.TYPE_VOID
const TYPE_VARIANT = GdObjects.TYPE_VARIANT
const TYPE_VARARG = GdObjects.TYPE_VARARG
const TYPE_FUNC = GdObjects.TYPE_FUNC
const TYPE_FUZZER = GdObjects.TYPE_FUZZER
const TYPE_ENUM = GdObjects.TYPE_ENUM

const DEFAULT_TYPED_RETURN_VALUES := {
	TYPE_NIL: "null",
	TYPE_BOOL: "false",
	TYPE_INT: "0",
	TYPE_FLOAT: "0.0",
	TYPE_STRING: "\"\"",
	TYPE_STRING_NAME: "&\"\"",
	TYPE_VECTOR2: "Vector2.ZERO",
	TYPE_VECTOR2I: "Vector2i.ZERO",
	TYPE_RECT2: "Rect2()",
	TYPE_RECT2I: "Rect2i()",
	TYPE_VECTOR3: "Vector3.ZERO",
	TYPE_VECTOR3I: "Vector3i.ZERO",
	TYPE_VECTOR4: "Vector4.ZERO",
	TYPE_VECTOR4I: "Vector4i.ZERO",
	TYPE_TRANSFORM2D: "Transform2D()",
	TYPE_PLANE: "Plane()",
	TYPE_QUATERNION: "Quaternion()",
	TYPE_AABB: "AABB()",
	TYPE_BASIS: "Basis()",
	TYPE_TRANSFORM3D: "Transform3D()",
	TYPE_PROJECTION: "Projection()",
	TYPE_COLOR: "Color()",
	TYPE_NODE_PATH: "NodePath()",
	TYPE_RID: "RID()",
	TYPE_OBJECT: "null",
	TYPE_CALLABLE: "Callable()",
	TYPE_SIGNAL: "Signal()",
	TYPE_DICTIONARY: "Dictionary()",
	TYPE_ARRAY: "Array()",
	TYPE_PACKED_BYTE_ARRAY: "PackedByteArray()",
	TYPE_PACKED_INT32_ARRAY: "PackedInt32Array()",
	TYPE_PACKED_INT64_ARRAY: "PackedInt64Array()",
	TYPE_PACKED_FLOAT32_ARRAY: "PackedFloat32Array()",
	TYPE_PACKED_FLOAT64_ARRAY: "PackedFloat64Array()",
	TYPE_PACKED_STRING_ARRAY: "PackedStringArray()",
	TYPE_PACKED_VECTOR2_ARRAY: "PackedVector2Array()",
	TYPE_PACKED_VECTOR3_ARRAY: "PackedVector3Array()",
	TYPE_PACKED_VECTOR4_ARRAY: "PackedVector4Array()",
	TYPE_PACKED_COLOR_ARRAY: "PackedColorArray()",
	GdObjects.TYPE_VARIANT: "null",
	GdObjects.TYPE_ENUM: "0"
}


# @GlobalScript enums
# needs to manually map because of https://github.com/godotengine/godot/issues/73835
const DEFAULT_ENUM_RETURN_VALUES = {
	"Side" : "SIDE_LEFT",
	"Corner" : "CORNER_TOP_LEFT",
	"Orientation" : "HORIZONTAL",
	"ClockDirection" : "CLOCKWISE",
	"HorizontalAlignment" : "HORIZONTAL_ALIGNMENT_LEFT",
	"VerticalAlignment" : "VERTICAL_ALIGNMENT_TOP",
	"InlineAlignment" : "INLINE_ALIGNMENT_TOP_TO",
	"EulerOrder" : "EULER_ORDER_XYZ",
	"Key" : "KEY_NONE",
	"KeyModifierMask" : "KEY_CODE_MASK",
	"MouseButton" : "MOUSE_BUTTON_NONE",
	"MouseButtonMask" : "MOUSE_BUTTON_MASK_LEFT",
	"JoyButton" : "JOY_BUTTON_INVALID",
	"JoyAxis" : "JOY_AXIS_INVALID",
	"MIDIMessage" : "MIDI_MESSAGE_NONE",
	"Error" : "OK",
	"PropertyHint" : "PROPERTY_HINT_NONE",
	"Variant.Type" : "TYPE_NIL",
	"Vector2.Axis" : "Vector2.AXIS_X",
	"Vector2i.Axis" : "Vector2i.AXIS_X",
	"Vector3.Axis" : "Vector3.AXIS_X",
	"Vector3i.Axis" : "Vector3i.AXIS_X",
	"Vector4.Axis" : "Vector4.AXIS_X",
	"Vector4i.Axis" : "Vector4i.AXIS_X",
}


static var def_constructor := """
	func _init({constructor_args}) -> void:
		__init_doubler()
		super({args})
	""".dedent()


static var def_verify_block := """
	# verify block
	var __verifier := __get_verifier()
	if __verifier != null:
		if __verifier.is_verify_interactions():
			__verifier.verify_interactions("{func_name}", __args)
			{default_return}
		else:
			__verifier.save_function_interaction("{func_name}", __args)
	""".dedent().indent("\t").trim_suffix("\n")


static var def_prepare_block := """
	if __is_prepare_return_value():
		__save_function_return_value("{func_name}", __args)
		{default_return}
	""".dedent().indent("\t").trim_suffix("\n")


static var def_void_prepare_block := """
	if __is_prepare_return_value():
		push_error("Mocking functions with return type void is not allowed!")
		return
	""".dedent().indent("\t").trim_suffix("\n")


static var def_mock_return := """
	if __is_do_not_call_real_func("{func_name}", __args):
		return __return_mock_value("{func_name}", __args, {default_return})
	""".dedent().indent("\t").trim_suffix("\n")


static var def_void_mock_return := """
	if __is_do_not_call_real_func("{func_name}", __args):
		return
	""".dedent().indent("\t").trim_suffix("\n")


var fd: GdFunctionDescriptor
var func_args: Array
var default_return: String
var verify_block: String = ""
var prepare_block: String = ""
var mock_return: String = ""


func _init(descriptor: GdFunctionDescriptor) -> void:
	# verify all default types are covered
	for type_key in TYPE_MAX:
		if not DEFAULT_TYPED_RETURN_VALUES.has(type_key):
			push_error("missing default definitions! Expexting %d bud is %d" % [DEFAULT_TYPED_RETURN_VALUES.size(), TYPE_MAX])
			prints("missing default definition for type", type_key)
			assert(DEFAULT_TYPED_RETURN_VALUES.has(type_key), "Missing Type default definition!")

	fd = descriptor
	func_args = argument_names()
	default_return = default_return_value()


func build_func_signature() -> String:
	var return_type := ":" if fd._return_type == TYPE_VARIANT else " -> %s:" % fd.return_type_as_string()
	return "{static}func {func_name}({args}){return_type}".format({
			"static" : "static " if fd.is_static() else "",
			"func_name": fd.name(),
			"args": arguments_full_quilified(),
			"return_type": return_type
		})


func arguments_full_quilified() -> String:
	var collect := PackedStringArray()
	for arg in fd.args():
		var name := argument_name(arg)
		if arg.has_default():
			var signature := "{argument_name}{arg_typed}={arg_value}".format({
				"argument_name" : name,
				"arg_typed" : ":"+GdObjects.type_as_string(arg.type()) if arg.type() == GdObjects.TYPE_VARIANT else "",
				"arg_value" : arg.value_as_string()
			})
			collect.push_back(signature)
		else:
			collect.push_back(name)
	if fd.is_vararg():
		var arg_descriptor := fd.varargs()[0]
		collect.push_back("...%s_: Array" % arg_descriptor.name())
	return ", ".join(collect)


func argument_name(arg: GdFunctionArgument) -> String:
	return arg.name() + "_"


func argument_names() -> PackedStringArray:
	return fd.args().map(argument_name)


func argument_default(arg :GdFunctionArgument) -> String:
	return (arg.value_as_string()
		if arg.has_default()
		else DEFAULT_TYPED_RETURN_VALUES.get(arg.type(), "null"))


func build_constructor_arguments() -> String:
	var arguments := PackedStringArray()
	for arg in fd.args():
		var default_value := argument_default(arg)
		var arg_signature := "{name}:{type}={default}".format({
			"name" : argument_name(arg),
			"type" : "Variant" if default_value == "null" else "",
			"default" : default_value
		})
		arguments.append(arg_signature)
	if fd.is_vararg():
		arguments.append("...varargs: Array")
	return ", ".join(arguments)


func build_arguments() -> String:
	return "\tvar __args := [{args}]{varargs}".format({
		"args" : ", ".join(func_args),
		"varargs" : " + varargs_" if fd.is_vararg() else ""
	})


func build_super_calls() -> String:
	if !fd.is_vararg():
		return 'super(%s)\n' % ", ".join(func_args)

	var match_block := "match varargs_.size():\n"
	for index in range(0, 11):
		match_block += '{index}: super({args})\n'.format({
			"index" : index,
			"args" : ", ".join(func_args + build_vararg_list(index))
		}).indent("\t")
	match_block += '_: push_error("To many varradic arguments.")\n'.indent("\t")
	match_block += "return\n" if is_void_func() else "return %s\n" % default_return
	return match_block


func build_vararg_list(count: int) -> Array:
	var arg_list := []
	for index in count:
		arg_list.append("varargs_[%d]" % index)
	return arg_list


func default_return_value() -> String:
	var return_type: Variant = fd.return_type()
	if return_type == GdObjects.TYPE_ENUM:
		var enum_class := fd._return_class
		if DEFAULT_ENUM_RETURN_VALUES.has(enum_class):
			return DEFAULT_ENUM_RETURN_VALUES.get(fd._return_class, "0")

		var enum_path := enum_class.split(".")
		if enum_path.size() >= 2:
			var keys := ClassDB.class_get_enum_constants(enum_path[0], enum_path[1])
			if not keys.is_empty():
				return "%s.%s" % [enum_path[0], keys[0]]
			var enum_value: Variant = get_enum_default(enum_class)
			if enum_value != null:
				return str(enum_value)
		# we need fallback for @GlobalScript enums,
		return DEFAULT_ENUM_RETURN_VALUES.get(fd._return_class, "0")
	return DEFAULT_TYPED_RETURN_VALUES.get(return_type, "invalid")


# Determine the enum default by reflection
func get_enum_default(value: String) -> Variant:
	var script := GDScript.new()
	script.source_code = """
	extends RefCounted

	static func get_enum_default() -> Variant:
		return %s.values()[0]

	""".dedent() % value
	var err := script.reload()
	if err != OK:
		push_error("Cant get enum values form '%s', %s" % [value, error_string(err)])
		return 0
	@warning_ignore("unsafe_method_access")
	return script.new().call("get_enum_default")


func is_void_func() -> bool:
	return fd.return_type() == TYPE_NIL or fd.return_type() == TYPE_VOID


func with_verify_block() -> GdUnitFunctionDoublerBuilder:
	verify_block = def_verify_block.format({
		"func_name" : fd.name(),
		"default_return" : "return" if is_void_func() else "return " + default_return
	})
	return self


func with_prepare_block() -> GdUnitFunctionDoublerBuilder:
	if fd.return_type() == TYPE_NIL or fd.return_type() == GdObjects.TYPE_VOID:
		prepare_block = def_void_prepare_block
		return self

	prepare_block = def_prepare_block.format({
		"func_name" : fd.name(),
		"default_return" : "return" if is_void_func() else "return " + default_return
	})
	return self


func with_mocked_return_value() -> GdUnitFunctionDoublerBuilder:
	if is_void_func():
		mock_return = def_void_mock_return.format({
			"func_name" : fd.name(),
		})
	else:
		mock_return = def_mock_return.format({
			"func_name" : fd.name(),
			"default_return" : '"no_arg"' if is_void_func() else default_return
		})
	return self


func build() -> PackedStringArray:
	if fd.name() == "_init":
		return [def_constructor.format({
			"constructor_args" : build_constructor_arguments(),
			"args" : ", ".join(func_args)
		})]

	var func_body: PackedStringArray = []
	func_body.append(build_func_signature())
	func_body.append(build_arguments())
	if not prepare_block.is_empty():
		func_body.append(prepare_block)
	func_body.append(verify_block)
	if not mock_return.is_empty():
		func_body.append(mock_return)
	func_body.append("")
	var super_calls := build_super_calls()
	if not is_void_func():
		super_calls = super_calls.replace("super(", "return super(" )
	if fd.is_coroutine():
		super_calls = super_calls.replace("super(", "await super(" )
	func_body.append(super_calls.indent("\t"))
	return func_body
