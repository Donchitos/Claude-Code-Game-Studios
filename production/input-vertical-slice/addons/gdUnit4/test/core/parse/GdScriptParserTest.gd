extends GdUnitTestSuite

var _parser: GdScriptParser

const TYPE_VOID := GdObjects.TYPE_VOID
const TYPE_VARIANT := GdObjects.TYPE_VARIANT
const TYPE_VARARG := GdObjects.TYPE_VARARG
const TYPE_FUNC := GdObjects.TYPE_FUNC
const TYPE_FUZZER := GdObjects.TYPE_FUZZER
const TYPE_ENUM := GdObjects.TYPE_ENUM


func before() -> void:
	_parser = GdScriptParser.new()


func after() -> void:
	clean_temp_dir()


func test_parse_function_arguments() -> void:
	assert_array(_parser._parse_function_arguments("func foo():")) \
		.has_size(0)

	assert_array(_parser._parse_function_arguments("func foo() -> String:\n")) \
		.has_size(0)

	assert_array(_parser._parse_function_arguments("func foo(arg1, arg2, name):")) \
		.has_size(3)\
		.contains([
			{"name" : "arg1", "type" : TYPE_VARIANT, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "name", "type" : TYPE_VARIANT, "value" : GdFunctionArgument.UNDEFINED},
		])

	assert_array(_parser._parse_function_arguments('func foo(arg1 :int, arg2 :bool, name :String = "abc"):')) \
		.has_size(3)\
		.contains([
			{"name" : "arg1", "type" : TYPE_INT, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_BOOL, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "name", "type" : TYPE_STRING, "value" : '"abc"'},
		])

	assert_array(_parser._parse_function_arguments('func bar(arg1 :int, arg2 :int = 23, name :String = "test") -> String:')) \
		.has_size(3)\
		.contains([
			{"name" : "arg1", "type" : TYPE_INT, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_INT, "value" : "23"},
			{"name" : "name", "type" : TYPE_STRING, "value" : '"test"'},
		])

	assert_array(_parser._parse_function_arguments("func foo(arg1, arg2=value(1,2,3), name:=foo()):")) \
		.has_size(3)\
		.contains([
			{"name" : "arg1", "type" : TYPE_VARIANT, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : "value(1,2,3)"},
			{"name" : "name", "type" : TYPE_VARIANT, "value" : "foo()"},
		])

	# enum as prefix in value name
	assert_array(_parser._parse_function_arguments("func get_value( type := ENUM_A) -> int:"))\
		.has_size(1)\
		.contains([
			{"name" : "type", "type" : TYPE_VARIANT, "value" : "ENUM_A"},
		])

	assert_array(_parser._parse_function_arguments("func create_timer(timeout :float) -> Timer:")) \
		.has_size(1)\
		.contains([
			{"name" : "timeout", "type" : TYPE_FLOAT, "value" : GdFunctionArgument.UNDEFINED},
		])

	# array argument
	assert_array(_parser._parse_function_arguments("func foo(a :int, b :int, parameters = [[1, 2], [3, 4], [5, 6]]):")) \
		.has_size(3)\
		.contains([
			{"name" : "a", "type" : TYPE_INT, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "b", "type" : TYPE_INT, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "parameters", "type" : TYPE_VARIANT, "value" : "[[1, 2], [3, 4], [5, 6]]"},
		])

	assert_array(_parser._parse_function_arguments("func test_values(a:Vector2, b:Vector2, expected:Vector2, test_parameters:=[[Vector2.ONE,Vector2.ONE,Vector2(1,1)]]):"))\
		.has_size(4)\
		.contains([
			{"name" : "a", "type" : TYPE_VECTOR2, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "b", "type" : TYPE_VECTOR2, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "expected", "type" : TYPE_VECTOR2, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "test_parameters", "type" : TYPE_VARIANT, "value" : "[[Vector2.ONE,Vector2.ONE,Vector2(1,1)]]"},
		])


func test_parse_arguments_with_super_constructor() -> void:
	assert_array(_parser._parse_function_arguments('func foo().foo("abc"):')).is_empty()
	assert_array(_parser._parse_function_arguments('func foo(arg1 = "arg").foo("abc", arg1):'))\
		.has_size(1)\
		.contains([
			{"name" : "arg1", "type" : TYPE_VARIANT, "value" : '"arg"'},
		])


func test_parse_arguments_default_build_in_type_string() -> void:
	assert_array(_parser._parse_function_arguments('func foo(arg1 :String, arg2="default"):')) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : '"default"'},
		])

	assert_array(_parser._parse_function_arguments('func foo(arg1 :String, arg2 :="default"):')) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : '"default"'},
		])

	assert_array(_parser._parse_function_arguments('func foo(arg1 :String, arg2 :String ="default"):')) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_STRING, "value" : '"default"'},
		])


func test_parse_arguments_default_build_in_type_string_with_escaped_quote() -> void:
	# https://github.com/godot-gdunit-labs/gdUnit4/issues/1309
	# an escaped double quote inside a callable argument value must not be treated as the string end
	assert_array(_parser._parse_function_arguments(
		"""func foo(arg1: String, arg2: String, test_parameters := _parameters_string_arg('abc', "d\\"ef")):"""))\
		.has_size(3)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "test_parameters", "type" : TYPE_VARIANT, "value" : """_parameters_string_arg('abc', "d\\"ef")"""},
		])

	# same for an escaped single quote inside a single quoted argument value
	assert_array(_parser._parse_function_arguments(
		"""func foo(arg1: String, arg2: String, test_parameters := _parameters_string_arg("abc", 'd\\'ef')):"""))\
		.has_size(3)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "test_parameters", "type" : TYPE_VARIANT, "value" : """_parameters_string_arg("abc", 'd\\'ef')"""},
		])


func test_parse_arguments_default_build_in_type_boolean() -> void:
	assert_array(_parser._parse_function_arguments("func foo(arg1 :String, arg2=false):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : 'false'},
		])

	assert_array(_parser._parse_function_arguments("func foo(arg1 :String, arg2 :=false):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : 'false'},
		])

	assert_array(_parser._parse_function_arguments("func foo(arg1 :String, arg2 :bool=false):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_BOOL, "value" : 'false'},
		])


func test_parse_arguments_default_build_in_type_float() -> void:
	assert_array(_parser._parse_function_arguments("func foo(arg1 :String, arg2=3.14):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : '3.14'},
		])

	assert_array(_parser._parse_function_arguments("func foo(arg1 :String, arg2 :=3.14):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : '3.14'},
		])

	assert_array(_parser._parse_function_arguments("func foo(arg1 :String, arg2 :float=3.14):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_FLOAT, "value" : '3.14'},
		])


func test_parse_arguments_default_build_in_type_array() -> void:
	assert_array(_parser._parse_function_arguments("func foo(arg1 :String, arg2 :Array=[]):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_ARRAY, "value" : '[]'},
		])

	assert_array(_parser._parse_function_arguments("func foo(arg1 :String, arg2 :Array=Array()):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_ARRAY, "value" : 'Array()'},
		])

	assert_array(_parser._parse_function_arguments("func foo(arg1 :String, arg2 :Array=[1, 2, 3]):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_ARRAY, "value" : '[1, 2, 3]'},
		])

	assert_array(_parser._parse_function_arguments("func foo(arg1 :String, arg2 :=[1, 2, 3]):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : '[1, 2, 3]'},
		])

	assert_array(_parser._parse_function_arguments("func foo(arg1 :String, arg2=[]):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : '[]'},
		])

	assert_array(_parser._parse_function_arguments("func foo(arg1 :String, arg2 :Array=[1, 2, 3], arg3 := false):")) \
		.has_size(3)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_ARRAY, "value" : '[1, 2, 3]'},
			{"name" : "arg3", "type" : TYPE_VARIANT, "value" : 'false'},
		])


func test_parse_arguments_default_build_in_type_color() -> void:
	assert_array(_parser._parse_function_arguments("func foo(arg1 :String, arg2=Color.RED):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : 'Color.RED'},
		])

	assert_array(_parser._parse_function_arguments("func foo(arg1 :String, arg2 :=Color.RED):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : 'Color.RED'},
		])

	assert_array(_parser._parse_function_arguments("func foo(arg1 :String, arg2 :Color=Color.RED):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_COLOR, "value" : 'Color.RED'},
		])


func test_parse_arguments_default_build_in_type_vector() -> void:
	assert_array(_parser._parse_function_arguments("func bar(arg1 :String, arg2 =Vector3.FORWARD):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : 'Vector3.FORWARD'},
		])

	assert_array(_parser._parse_function_arguments("func bar(arg1 :String, arg2 :=Vector3.FORWARD):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : 'Vector3.FORWARD'},
		])

	assert_array(_parser._parse_function_arguments("func bar(arg1 :String, arg2 :Vector3=Vector3.FORWARD):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VECTOR3, "value" : 'Vector3.FORWARD'},
		])


func test_parse_arguments_default_build_in_type_AABB() -> void:
	assert_array(_parser._parse_function_arguments("func bar(arg1 :String, arg2 := AABB()):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : 'AABB()'},
		])

	assert_array(_parser._parse_function_arguments("func bar(arg1 :String, arg2 :AABB=AABB()):")) \
		.has_size(2)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_AABB, "value" : 'AABB()'},
		])


func test_parse_arguments_default_build_in_types() -> void:
	assert_array(_parser._parse_function_arguments("func bar(arg1 :String, arg2 := Vector3.FORWARD, aabb := AABB()):")) \
		.has_size(3)\
		.contains([
			{"name" : "arg1", "type" : TYPE_STRING, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_VARIANT, "value" : 'Vector3.FORWARD'},
			{"name" : "aabb", "type" : TYPE_VARIANT, "value" : 'AABB()'},
		])


func test_parse_arguments_fuzzers() -> void:
	assert_array(_parser._parse_function_arguments("func test_foo(fuzzer_a = fuzz_a(), fuzzer_b := fuzz_b(), fuzzer_c :Fuzzer = fuzz_c(), fuzzer_iterations = 234, fuzzer_seed = 100):")) \
		.has_size(5)\
		.contains([
			{"name" : "fuzzer_a", "type" : TYPE_FUZZER, "value" : 'fuzz_a()'},
			{"name" : "fuzzer_b", "type" : TYPE_FUZZER, "value" : 'fuzz_b()'},
			{"name" : "fuzzer_c", "type" : TYPE_FUZZER, "value" : 'fuzz_c()'},
			{"name" : "fuzzer_iterations", "type" : TYPE_VARIANT, "value" : '234'},
			{"name" : "fuzzer_seed", "type" : TYPE_VARIANT, "value" : '100'},
		])


func test_parse_arguments_typed_dict() -> void:
	assert_array(_parser._parse_function_arguments('func generate(arg1: Dictionary[String,Variant], arg2 :Dictionary = {"a":1, "b":2}, arg3 := {}) -> void:'))\
		.has_size(3)\
		.contains([
			{"name" : "arg1", "type" : TYPE_DICTIONARY, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_DICTIONARY, "value" : '{"a":1, "b":2}'},
			{"name" : "arg3", "type" : TYPE_VARIANT, "value" : '{}'},
		])


func test_parse_arguments_variant() -> void:
	# remove this line and complete your test
	var args := _parser._parse_function_arguments('func generate(
		ucids: Array[int],
		position: Vector2i,
		size: Vector2i,
		style: int,
		text: Variant = "",
		button_name := "",
		type_in := 0,
		caption := "",
		show_everywhere := false')

	assert_array(args)\
		.has_size(9)\
		.contains([
			{"name" : "ucids",       "type" : TYPE_ARRAY, "value" : GdFunctionArgument.UNDEFINED, },
			{"name" : "position",    "type" : TYPE_VECTOR2I, "value" : GdFunctionArgument.UNDEFINED, },
			{"name" : "size",        "type" : TYPE_VECTOR2I, "value" : GdFunctionArgument.UNDEFINED },
			{"name" : "style",       "type" : TYPE_INT, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "text",        "type" : TYPE_VARIANT, "value" : '""'},
			{"name" : "button_name", "type" : TYPE_VARIANT, "value" : '""'},
			{"name" : "type_in",     "type" : TYPE_VARIANT, "value" : '0'},
			{"name" : "caption",     "type" : TYPE_VARIANT, "value" : '""'},
			{"name" : "show_everywhere", "type" : TYPE_VARIANT, "value" : 'false'},
			])


func test_parse_arguments_variadic() -> void:
	var args := _parser._parse_function_arguments('func call(...args: Array) -> Variant:')
	assert_array(args)\
		.has_size(1)\
		.contains([
			{"name" : "args", "type" : TYPE_VARARG, "value" : GdFunctionArgument.UNDEFINED}
		])

	var script := GDScript.new()
	script.source_code = """
	@warning_ignore("unused_parameter")
	func custom(name: String, ...varargs: Array) -> int:
		return 0
	""".dedent()
	script.reload()

	# Try to enrich function arguments should not affect the argumens on variadic argument
	var fds := _parser.get_function_descriptors(script, ["custom"])
	_parser._enrich_function_descriptor(script, fds)


func test_parse_arguments_typed_array() -> void:
	# remove this line and complete your test
	assert_array(_parser._parse_function_arguments("func generate(arg1: Array, arg2: Array = [1,2,3], arg3: Array[int] = [4,5,6], arg4 := []) -> void:"))\
		.has_size(4)\
		.contains([
			{"name" : "arg1", "type" : TYPE_ARRAY, "value" : GdFunctionArgument.UNDEFINED},
			{"name" : "arg2", "type" : TYPE_ARRAY, "value" : '[1,2,3]'},
			{"name" : "arg3", "type" : TYPE_ARRAY, "value" : '[4,5,6]'},
			{"name" : "arg4", "type" : TYPE_VARIANT, "value" : '[]'},
		])


class TestObject:
	var x: int


func test_parse_func_name() -> void:
	assert_str(_parser.parse_func_name("func foo():")).is_equal("foo")
	assert_str(_parser.parse_func_name("static func foo():")).is_equal("foo")
	assert_str(_parser.parse_func_name("func a() -> String:")).is_equal("a")
	# function name contains tokens e.g func or class
	assert_str(_parser.parse_func_name("func foo_func_class():")).is_equal("foo_func_class")
	# unicode characters in the name
	assert_str(_parser.parse_func_name("func test_日本語() -> void:")).is_equal("test_日本語")
	# should fail
	assert_str(_parser.parse_func_name("#func foo():")).is_empty()
	assert_str(_parser.parse_func_name("var x")).is_empty()


func test_load_source_code_inner_class_AtmosphereData() -> void:
	var base_class := AdvancedTestClass.new()
	@warning_ignore("unsafe_cast")
	var rows := _parser._load_inner_class(base_class.get_script() as GDScript, "AtmosphereData")
	var file_content := resource_as_string("res://addons/gdUnit4/test/core/resources/AtmosphereData.txt")
	assert_that(rows).is_equal(file_content)


func test_load_source_code_inner_class_SoundData() -> void:
	var base_class := AdvancedTestClass.new()
	@warning_ignore("unsafe_cast")
	var rows := _parser._load_inner_class(base_class.get_script() as GDScript, "SoundData")
	var file_content := resource_as_string("res://addons/gdUnit4/test/core/resources/SoundData.txt")
	assert_that(rows).is_equal(file_content)


func test_load_source_code_inner_class_Area4D() -> void:
	var base_class := AdvancedTestClass.new()
	@warning_ignore("unsafe_cast")
	var rows := _parser._load_inner_class(base_class.get_script() as GDScript, "Area4D")
	var file_content := resource_as_string("res://addons/gdUnit4/test/core/resources/Area4D.txt")
	assert_that(rows).is_equal(file_content)


func test_extract_function_signature() -> void:
	var script :GDScript = load("res://addons/gdUnit4/test/mocker/resources/ClassWithCustomFormattings.gd")
	var rows := script.source_code.split("\n")

	assert_that(_parser.extract_func_signature(rows, 12))\
		.is_equal("""
			func a1(set_name:String, path:String="", load_on_init:bool=false,
				set_auto_save:bool=false, set_network_sync:bool=false
			) -> void:""".dedent().trim_prefix("\n"))
	assert_that(_parser.extract_func_signature(rows, 19))\
		.is_equal("""
			func a2(set_name:String, path:String="", load_on_init:bool=false,
				set_auto_save:bool=false, set_network_sync:bool=false
			) -> 	void:""".dedent().trim_prefix("\n"))
	assert_that(_parser.extract_func_signature(rows, 26))\
		.is_equal("""
			func a3(set_name:String, path:String="", load_on_init:bool=false,
				set_auto_save:bool=false, set_network_sync:bool=false
			) -> void:""".dedent().trim_prefix("\n"))
	assert_that(_parser.extract_func_signature(rows, 33))\
		.is_equal("""
			func a4(set_name:String,
				path:String="",
				load_on_init:bool=false,
				set_auto_save:bool=false,
				set_network_sync:bool=false
			) -> void:""".dedent().trim_prefix("\n"))
	assert_that(_parser.extract_func_signature(rows, 43))\
		.is_equal("""
			func a5(
				value : Array,
				expected : String,
				test_parameters : Array = [
					[ ["a"], "a" ],
					[ ["a", "very", "long", "argument"], "a very long argument" ],
				]
			) -> void:""".dedent().trim_prefix("\n"))


func test_strip_leading_spaces() -> void:
	assert_str(GdScriptParser.TokenInnerClass._strip_leading_spaces("")).is_empty()
	assert_str(GdScriptParser.TokenInnerClass._strip_leading_spaces(" ")).is_empty()
	assert_str(GdScriptParser.TokenInnerClass._strip_leading_spaces("    ")).is_empty()
	assert_str(GdScriptParser.TokenInnerClass._strip_leading_spaces("	 ")).is_equal("	 ")
	assert_str(GdScriptParser.TokenInnerClass._strip_leading_spaces("var x=")).is_equal("var x=")
	assert_str(GdScriptParser.TokenInnerClass._strip_leading_spaces("class foo")).is_equal("class foo")


func test_parse_func_description() -> void:
	var script := GdScriptTestHelper.build_tmp_script("""

		@warning_ignore("unused_parameter")
		func foo0(arg1: int, arg2: bool=false) -> String:
			return ""

		@warning_ignore("unused_parameter")
		static func foo1(arg1: int, arg2: bool=false) -> String:
			return ""

		@warning_ignore("untyped_declaration", "unused_parameter")
		static func foo2(arg1: int, arg2: bool=true):
			return
	""")
	var fds := _parser.get_function_descriptors(script)

	assert_that(fds[0])\
		.is_equal(create("foo0", script.resource_path, 4, 5, TYPE_STRING, [
			GdFunctionArgument.new("arg1", TYPE_INT),
			GdFunctionArgument.new("arg2", TYPE_BOOL, false)
		]))

	# static function
	assert_that(fds[1])\
		.is_equal(create_static("foo1", script.resource_path, 8, 9, TYPE_STRING, [
			GdFunctionArgument.new("arg1", TYPE_INT),
			GdFunctionArgument.new("arg2", TYPE_BOOL, false)
		]))

	# static function without return type
	assert_that(fds[2])\
		.is_equal(create_static("foo2", script.resource_path, 12, 13, GdObjects.TYPE_VARIANT, [
			GdFunctionArgument.new("arg1", TYPE_INT),
			GdFunctionArgument.new("arg2", TYPE_BOOL, true)
		]))


func test_get_function_descriptors_return_type_enum() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/mocker/resources/ClassWithEnumReturnTypes.gd")
	var fds := _parser.get_function_descriptors(script, ["get_enum"])

	assert_that(fds[0])\
		.is_equal(create("get_enum", script.resource_path, 15, 16, GdObjects.TYPE_ENUM, [])
			.with_return_class("ClassWithEnumReturnTypes.TEST_ENUM")
		)


func test_parse_func_description_return_type_internal_class_enum() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/mocker/resources/ClassWithEnumReturnTypes.gd")
	var fds := _parser.get_function_descriptors(script, ["get_inner_class_enum"])

	assert_that(fds[0])\
		.is_equal(create("get_inner_class_enum", script.resource_path, 25, 26, GdObjects.TYPE_ENUM, [])
			.with_return_class("ClassWithEnumReturnTypes.InnerClass.TEST_ENUM")
		)


func test_parse_func_description_return_type_external_class_enum() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/mocker/resources/ClassWithEnumReturnTypes.gd")
	var fds := _parser.get_function_descriptors(script, ["get_external_class_enum"])

	assert_that(fds[0])\
		.is_equal(create("get_external_class_enum", script.resource_path, 20, 21, GdObjects.TYPE_ENUM, [])
			.with_return_class("CustomEnums.TEST_ENUM")
		)


func test_parse_class_inherits() -> void:
	var clazz_path := GdObjects.extract_class_path(CustomClassExtendsCustomClass)
	var clazz_name := GdObjects.extract_class_name_from_class_path(clazz_path)
	var result := _parser.parse(clazz_name, clazz_path)
	assert_result(result).is_success()

	# verify class extraction
	var clazz_desccriptor :GdClassDescriptor = result.value()
	assert_object(clazz_desccriptor).is_not_null()
	assert_str(clazz_desccriptor.name()).is_equal("CustomClassExtendsCustomClass")
	assert_bool(clazz_desccriptor.is_inner_class()).is_false()
	assert_array(clazz_desccriptor.functions())\
		.contains_exactly([
			create("foo2", "res://addons/gdUnit4/test/mocker/resources/CustomClassExtendsCustomClass.gd", 6, 7, GdObjects.TYPE_VARIANT),
			create("bar2", "res://addons/gdUnit4/test/mocker/resources/CustomClassExtendsCustomClass.gd", 9, 10, TYPE_STRING),
			create("foo", "res://addons/gdUnit4/test/mocker/resources/CustomResourceTestClass.gd", 4, 5, TYPE_STRING),
			create("foo_void", "res://addons/gdUnit4/test/mocker/resources/CustomResourceTestClass.gd", 10, 11, GdObjects.TYPE_VOID),
			create("bar", "res://addons/gdUnit4/test/mocker/resources/CustomResourceTestClass.gd", 13, 14, TYPE_STRING, [
				GdFunctionArgument.new("arg1", TYPE_INT),
				GdFunctionArgument.new("arg2", TYPE_INT, 23),
				GdFunctionArgument.new("name", TYPE_STRING, "test"),
			]),
			# see https://github.com/godotengine/godot/pull/118032
			create("foo5", "res://addons/gdUnit4/test/mocker/resources/CustomResourceTestClass.gd", 17, 18,
				GdObjects.TYPE_VARIANT if Engine.get_version_info()["minor"] >= 7 else GdObjects.TYPE_VOID),
		])


func test_get_class_name_pascal_case() -> void:
	assert_str(_parser.get_class_name(load("res://addons/gdUnit4/test/core/resources/naming_conventions/PascalCaseWithClassName.gd") as GDScript))\
		.is_equal("PascalCaseWithClassName")
	assert_str(_parser.get_class_name(load("res://addons/gdUnit4/test/core/resources/naming_conventions/PascalCaseWithoutClassName.gd") as GDScript))\
		.is_equal("PascalCaseWithoutClassName")


func test_get_class_name_snake_case() -> void:
	assert_str(_parser.get_class_name(load("res://addons/gdUnit4/test/core/resources/naming_conventions/snake_case_with_class_name.gd") as GDScript))\
		.is_equal("SnakeCaseWithClassName")
	assert_str(_parser.get_class_name(load("res://addons/gdUnit4/test/core/resources/naming_conventions/snake_case_without_class_name.gd") as GDScript))\
		.is_equal("SnakeCaseWithoutClassName")


func test_get_class_with_extends_in_same_line() -> void:
	assert_str(_parser.get_class_name(load("res://addons/gdUnit4/test/core/resources/naming_conventions/extends_on_same_line.gd") as GDScript))\
		.is_equal("ClassNameExtendsInSameLine")


func test_is_func_end() -> void:
	assert_bool(_parser.is_func_end("")).is_false()
	assert_bool(_parser.is_func_end("func test_a():")).is_true()
	assert_bool(_parser.is_func_end("func test_a() -> void:")).is_true()
	assert_bool(_parser.is_func_end("func test_a(arg1) :")).is_true()
	assert_bool(_parser.is_func_end("func test_a(arg1 ): ")).is_true()
	assert_bool(_parser.is_func_end("func test_a(arg1 ):	")).is_true()
	assert_bool(_parser.is_func_end("	):")).is_true()
	assert_bool(_parser.is_func_end("		):")).is_true()
	assert_bool(_parser.is_func_end("	-> void:")).is_true()
	assert_bool(_parser.is_func_end("		) -> void :")).is_true()
	assert_bool(_parser.is_func_end("func test_a(arg1, arg2 = {1:2} ):")).is_true()


func test_extract_func_signature_multiline() -> void:
	var source_code := """

		func test_parameterized(a: int, b :int, c :int, expected :int, test_parameters = [
			[1, 2, 3, 6],
			[3, 4, 5, 11],
			[6, 7, 8, 21] ]):

			assert_that(a+b+c).is_equal(expected)
		""".dedent().split("\n")

	var fs := _parser.extract_func_signature(source_code, 0)

	assert_that(fs).is_equal("""
		func test_parameterized(a: int, b :int, c :int, expected :int, test_parameters = [
			[1, 2, 3, 6],
			[3, 4, 5, 11],
			[6, 7, 8, 21] ]):"""
			.dedent()
			.trim_prefix("\n")
		)


func test_parse_func_description_paramized_test() -> void:
	var script := GdScriptTestHelper.build_tmp_script("""
		@warning_ignore("unused_parameter")
		func test_parameterized(a: int, b: int, c: int, expected: int, test_parameters: Array = [[1,2,3,6],[3,4,5,11],[6,7,8,21]]) -> Variant:
			return null
	""")
	var fds := GdScriptParser.new().get_function_descriptors(script, ["test_parameterized"])

	assert_that(fds[0]).is_equal(create("test_parameterized", script.resource_path, 3, 4, GdObjects.TYPE_VARIANT, [
		GdFunctionArgument.new("a", TYPE_INT),
		GdFunctionArgument.new("b", TYPE_INT),
		GdFunctionArgument.new("c", TYPE_INT),
		GdFunctionArgument.new("expected", TYPE_INT),
		GdFunctionArgument.new("test_parameters", TYPE_ARRAY, "[[1,2,3,6],[3,4,5,11],[6,7,8,21]]"),
	]))


func test_parse_func_description_paramized_test_with_comments() -> void:
	var source_code := """
		func test_parameterized(a: int, b :int, c :int, expected :int, test_parameters = [
			# before data set
			[1, 2, 3, 6], # after data set
			# between data sets
			[3, 4, 5, 11],
			[6, 7, 'string #ABCD', 21], # dataset with [comment] singn
			[6, 7, "string #ABCD", 21] # dataset with "#comment" singn
			#eof
		]):
			pass
		""".dedent().split("\n")

	var fs := _parser.extract_func_signature(source_code, 0)

	assert_that(fs).is_equal("""
		func test_parameterized(a: int, b :int, c :int, expected :int, test_parameters = [
			[1, 2, 3, 6],
			[3, 4, 5, 11],
			[6, 7, 'string #ABCD', 21],
			[6, 7, "string #ABCD", 21]
		]):"""
			.dedent()
			.trim_prefix("\n")
		)


func test_parse_func_descriptor_with_fuzzers() -> void:
	# using a mixure of typed and untyped default values
	var script := GdScriptTestHelper.build_tmp_script("""
		func fuzz_a() -> Fuzzer:
			return Fuzzers.rangef(0, 10)

		func fuzz_b() -> Fuzzer:
			return Fuzzers.rangef(0, 10)

		func fuzz_c() -> Fuzzer:
			return Fuzzers.rangef(0, 10)

		@warning_ignore("untyped_declaration", "unused_parameter", "inferred_declaration")
		func test_foo(fuzzer_a = fuzz_a(), fuzzer_b := fuzz_b(),
			fuzzer_c :Fuzzer = fuzz_c(),
			fuzzer = Fuzzers.rangei(-23, 22),
			fuzzer_iterations = 234,
			fuzzer_seed := 100):
			pass
	""")
	var fds := _parser.get_function_descriptors(script, ["test_foo"])
	# see https://github.com/godotengine/godot/pull/118032
	var untyped_return_type: int = GdObjects.TYPE_VARIANT if Engine.get_version_info()["minor"] >= 7 else GdObjects.TYPE_VOID

	assert_that(fds[0]).is_equal(create("test_foo", script.resource_path, 12, 17, untyped_return_type, [
		# all fuzzer must by type TYPE_FUZZER
		GdFunctionArgument.new("fuzzer_a", GdObjects.TYPE_FUZZER, "fuzz_a()"),
		GdFunctionArgument.new("fuzzer_b", GdObjects.TYPE_FUZZER, "fuzz_b()"),
		GdFunctionArgument.new("fuzzer_c", GdObjects.TYPE_FUZZER, "fuzz_c()"),
		GdFunctionArgument.new("fuzzer", GdObjects.TYPE_FUZZER, "Fuzzers.rangei(-23, 22)"),
		# untyped arg is TYPE_VARIANT
		GdFunctionArgument.new("fuzzer_iterations", GdObjects.TYPE_VARIANT, 234),
		# typed is TYPE_INT
		GdFunctionArgument.new("fuzzer_seed", TYPE_INT, 100)
	]))


func test_is_func_coroutine() -> void:
	var script := """
	extends RefCounted:
		func normal_function() -> void:
			print("normal")


		func await_function() -> void:
			print(await _await_function())


		func _await_function() -> String:
			await get_tree().process_frame
			return "test"


		func check_is_waiting() -> String:
			return is_await()


		func print_message() -> String:
			return "do await for timeout"
	"""

	var rows := script.split("\n")
	assert_bool(_parser.is_func_coroutine(rows, 2)).is_false()
	assert_bool(_parser.is_func_coroutine(rows, 6)).is_true()
	assert_bool(_parser.is_func_coroutine(rows, 10)).is_true()
	assert_bool(_parser.is_func_coroutine(rows, 15)).is_false()
	assert_bool(_parser.is_func_coroutine(rows, 19)).is_false()


func test_using_class_in_variable_name() -> void:
	var script := """
	extends RefCounted:
		func foo() -> void:
			var class1.a = "a"
			var class2 = "abc"


		func bar() -> void:
			print("bar")

	"""

	var rows := script.split("\n")
	assert_bool(_parser.is_func_coroutine(rows, 0)).is_false()
	assert_bool(_parser.is_func_coroutine(rows, 4)).is_false()


func test_find_end_line() -> void:
	var source := """
		extends RefCounted															# Line: 1


		func test_foo1() -> void:                                                   # Line: 4
			pass																	# Line: 5
		func test_foo2() -> void:													# Line: 6
			pass																	# Line: 7


		# Single comment
		func test_foo3() -> void:													# Line: 11
			# comment

			pass																	# Line: 14

		@warning_ignore("untyped_declaration")
		func test_with_paramset(													# Line: 17
			values: Array,
			expected: String,
			_test_parameters : Array = [
				[ ["a"], "a" ],
				[ ["a", "very", "long", "argument"], "a very long argument" ],
			]
		) -> void:
			var current := " ".join(values)
			assert_that(current.strip_edges()).is_equal(expected)(					# Line: 26

		## function doc
		## pla ...
		func test_end() -> void:													# Line: 30
			pass																	# Line: 31
		""".dedent().trim_prefix("\n")

	var rows := source.split("\n")
	# test_foo1()
	assert_int(_parser._parse_func_end_line(rows, 4)).is_equal(5)
	# test_foo2()
	assert_int(_parser._parse_func_end_line(rows, 6)).is_equal(7)
	# test_foo3()
	assert_int(_parser._parse_func_end_line(rows, 11)).is_equal(14)
	# test_with_paramset()
	assert_int(_parser._parse_func_end_line(rows, 17)).is_equal(26)
	# test_end()
	assert_int(_parser._parse_func_end_line(rows, 30)).is_equal(31)


static func create(func_name: String, source_path: String, begin_line: int, end_line: int, return_type: int, args: Array[GdFunctionArgument] = []) -> GdFunctionDescriptor:
	var fd := GdFunctionDescriptor.new(func_name, false, false, false, return_type, "", args)
	fd.enrich_file_info(source_path, begin_line, end_line)
	return fd


static func create_static(func_name: String, source_path: String, begin_line: int, end_line: int, return_type: int, args: Array[GdFunctionArgument]) -> GdFunctionDescriptor:
	var fd := GdFunctionDescriptor.new(func_name, false, true, false, return_type, "", args)
	fd.enrich_file_info(source_path, begin_line, end_line)
	return fd
