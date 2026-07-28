class_name GdFunctionDescriptor
extends RefCounted

var _is_virtual :bool
var _is_static :bool
var _is_engine :bool
var _is_coroutine :bool
var _name :String
var _source_path: String
var _line_number :int
var _return_type :int
var _return_class :String
var _args : Array[GdFunctionArgument]
var _varargs :Array[GdFunctionArgument]



static func create(p_name: String, p_source_path: String, p_source_line: int, p_return_type: int, p_args: Array[GdFunctionArgument] = []) -> GdFunctionDescriptor:
	var fd := GdFunctionDescriptor.new(p_name, p_source_line, false, false, false, p_return_type, "", p_args)
	fd.enrich_file_info(p_source_path, p_source_line)
	return fd

static func create_static(p_name: String, p_source_path: String, p_source_line: int, p_return_type: int, p_args: Array[GdFunctionArgument] = []) -> GdFunctionDescriptor:
	var fd := GdFunctionDescriptor.new(p_name, p_source_line, false, true, false, p_return_type, "", p_args)
	fd.enrich_file_info(p_source_path, p_source_line)
	return fd


func _init(p_name :String,
	p_line_number :int,
	p_is_virtual :bool,
	p_is_static :bool,
	p_is_engine :bool,
	p_return_type :int,
	p_return_class :String,
	p_args : Array[GdFunctionArgument],
	p_varargs :Array[GdFunctionArgument] = []) -> void:
	_name = p_name
	_line_number = p_line_number
	_return_type = p_return_type
	_return_class = p_return_class
	_is_virtual = p_is_virtual
	_is_static = p_is_static
	_is_engine = p_is_engine
	_is_coroutine = false
	_args = p_args
	_varargs = p_varargs


func with_return_class(clazz_name: String) -> GdFunctionDescriptor:
	_return_class = clazz_name
	return self


func name() -> String:
	return _name


func source_path() -> String:
	return _source_path


func line_number() -> int:
	return _line_number


func is_virtual() -> bool:
	return _is_virtual


func is_static() -> bool:
	return _is_static


func is_engine() -> bool:
	return _is_engine


func is_vararg() -> bool:
	return not _varargs.is_empty()


func is_coroutine() -> bool:
	return _is_coroutine


func is_parameterized() -> bool:
	for current in _args:
		var arg :GdFunctionArgument = current
		if arg.name() in GdFunctionArgument.ARG_PARAMETERIZED_TEST:
			return true
	return false


func is_private() -> bool:
	return name().begins_with("_") and not is_virtual()


func return_type() -> int:
	return _return_type


func return_type_as_string() -> String:
	if return_type() == TYPE_NIL:
		return "void"
	if (return_type() == TYPE_OBJECT or return_type() == GdObjects.TYPE_ENUM) and not _return_class.is_empty():
		return _return_class
	return GdObjects.type_as_string(return_type())


func set_argument_value(arg_name: String, value: String) -> void:
	var argument: GdFunctionArgument = _args.filter(func(arg: GdFunctionArgument) -> bool:
		return arg.name() == arg_name
		).front()
	if argument != null:
		argument.set_value(value)


func enrich_arguments(arguments: Array[Dictionary]) -> void:
	for arg_index: int in arguments.size():
		var arg: Dictionary = arguments[arg_index]
		if arg["type"] != GdObjects.TYPE_VARARG:
			var arg_name: String = arg["name"]
			var arg_value: String = arg["value"]
			set_argument_value(arg_name, arg_value)


func enrich_file_info(p_source_path: String, p_line_number: int) -> void:
	_source_path = p_source_path
	_line_number = p_line_number


func args() -> Array[GdFunctionArgument]:
	return _args


func varargs() -> Array[GdFunctionArgument]:
	return _varargs


func typed_args() -> String:
	var collect := PackedStringArray()
	for arg in args():
		@warning_ignore("return_value_discarded")
		collect.push_back(arg._to_string())
	for arg in varargs():
		@warning_ignore("return_value_discarded")
		collect.push_back(arg._to_string())
	return ", ".join(collect)


func _to_string() -> String:
	var fsignature := "virtual " if is_virtual() else ""
	if _return_type == TYPE_NIL:
		return fsignature + "[Line:%s] func %s(%s):" % [line_number(), name(), typed_args()]
	var func_template := fsignature + "[Line:%s] func %s(%s) -> %s:"
	if is_static():
		func_template= "[Line:%s] static func %s(%s) -> %s:"
	return func_template % [line_number(), name(), typed_args(), return_type_as_string()]


# extract function description given by Object.get_method_list()
static func extract_from(descriptor :Dictionary, is_engine_ := true) -> GdFunctionDescriptor:
	var func_name: String = descriptor["name"]
	var function_flags: int = descriptor["flags"]
	var return_descriptor: Dictionary = descriptor["return"]
	var clazz_name: String = return_descriptor["class_name"]
	var is_virtual_: bool = function_flags & METHOD_FLAG_VIRTUAL
	var is_static_: bool = function_flags & METHOD_FLAG_STATIC
	var is_vararg_: bool = function_flags & METHOD_FLAG_VARARG

	return GdFunctionDescriptor.new(
		func_name,
		-1,
		is_virtual_,
		is_static_,
		is_engine_,
		_extract_return_type(return_descriptor),
		clazz_name,
		_extract_args(descriptor),
		_build_varargs(is_vararg_)
	)

# temporary exclude GlobalScope enums
const enum_fix := [
	"Side",
	"Corner",
	"Orientation",
	"ClockDirection",
	"HorizontalAlignment",
	"VerticalAlignment",
	"InlineAlignment",
	"EulerOrder",
	"Error",
	"Key",
	"MIDIMessage",
	"MouseButton",
	"MouseButtonMask",
	"JoyButton",
	"JoyAxis",
	"PropertyHint",
	"PropertyUsageFlags",
	"MethodFlags",
	"Variant.Type",
	"Control.LayoutMode"]


static func _extract_return_type(return_info :Dictionary) -> int:
	var type :int = return_info["type"]
	var usage :int = return_info["usage"]
	if type == TYPE_INT and usage & PROPERTY_USAGE_CLASS_IS_ENUM:
		return GdObjects.TYPE_ENUM
	if type == TYPE_NIL and usage & PROPERTY_USAGE_NIL_IS_VARIANT:
		return GdObjects.TYPE_VARIANT
	if type == TYPE_NIL and usage == 6:
		return GdObjects.TYPE_VOID
	return type


static func _extract_args(descriptor :Dictionary) -> Array[GdFunctionArgument]:
	var args_ :Array[GdFunctionArgument] = []
	var arguments :Array = descriptor["args"]
	var defaults :Array = descriptor["default_args"]
	# iterate backwards because the default values are stored from right to left
	while not arguments.is_empty():
		var arg :Dictionary = arguments.pop_back()
		var arg_name := _argument_name(arg)
		var arg_type := _argument_type(arg)
		var arg_type_hint := _argument_hint(arg)
		#var arg_class: StringName = arg["class_name"]
		var default_value: Variant = GdFunctionArgument.UNDEFINED if defaults.is_empty() else defaults.pop_back()
		args_.push_front(GdFunctionArgument.new(arg_name, arg_type, default_value, arg_type_hint))
	return args_


static func _build_varargs(p_is_vararg :bool) -> Array[GdFunctionArgument]:
	var varargs_ :Array[GdFunctionArgument] = []
	if not p_is_vararg:
		return varargs_
	varargs_.push_back(GdFunctionArgument.new("varargs", GdObjects.TYPE_VARARG, ''))
	return varargs_


static func _argument_name(arg :Dictionary) -> String:
	return arg["name"]


static func _argument_type(arg :Dictionary) -> int:
	var type :int = arg["type"]
	var usage :int = arg["usage"]

	if type == TYPE_OBJECT:
		if arg["class_name"] == "Node":
			return GdObjects.TYPE_NODE
		if arg["class_name"] == "Fuzzer":
			return GdObjects.TYPE_FUZZER

	# if the argument untyped we need to scan the assignef value type
	if type == TYPE_NIL and usage == PROPERTY_USAGE_NIL_IS_VARIANT:
		return GdObjects.TYPE_VARIANT
	return type


static func _argument_hint(arg :Dictionary) -> int:
	var hint :int = arg["hint"]
	var hint_string :String = arg["hint_string"]

	match hint:
		PROPERTY_HINT_ARRAY_TYPE:
			return GdObjects.string_to_type(hint_string)
		_:
			return 0


static func _argument_type_as_string(arg :Dictionary) -> String:
	var type := _argument_type(arg)
	match type:
		TYPE_NIL:
			return ""
		TYPE_OBJECT:
			var clazz_name :String = arg["class_name"]
			if not clazz_name.is_empty():
				return clazz_name
			return ""
		_:
			return GdObjects.type_as_string(type)
