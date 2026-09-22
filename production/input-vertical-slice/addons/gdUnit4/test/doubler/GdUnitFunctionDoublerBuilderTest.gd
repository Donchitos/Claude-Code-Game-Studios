extends GdFunctionDoublerTest


func test_double_constructor_noargs() -> void:
	var doubler := GdUnitSpyFunctionDoubler.new()
	var fd := get_function_description("Object", "_init")
	var expected := """
		func _init() -> void:
			__init_doubler()
			super()
		""".dedent()
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_constructor_args() -> void:
	var fd := get_function_description_from(TestClassWithConstructorArgs, "_init")
	var doubler := GdUnitFunctionDoublerBuilder.new(fd)
	var expected := """
		func _init(name_:="", arg1_:=0) -> void:
			__init_doubler()
			super(name_, arg1_)
		""".dedent()
	assert_str("\n".join(doubler.build())).is_equal(expected)


func test_double_constructor_varargs() -> void:
	var fd := get_function_description_from(TestClassWithConstructorVarargs, "_init")
	var doubler := GdUnitFunctionDoublerBuilder.new(fd)
	var expected := """
		func _init(...varargs: Array) -> void:
			__init_doubler()
			super()
		""".dedent()
	assert_str("\n".join(doubler.build())).is_equal(expected)


func test_double_constructor_args_and_varargs() -> void:
	var fd := get_function_description_from(TestClassWithConstructorArgsAndVarargs, "_init")
	var doubler := GdUnitFunctionDoublerBuilder.new(fd)
	var expected := """
		func _init(name_:="", arg_:=0, ...varargs: Array) -> void:
			__init_doubler()
			super(name_, arg_)
		""".dedent()
	assert_str("\n".join(doubler.build())).is_equal(expected)


func test_double_coroutine_func() -> void:
	var fd := get_function_description_from(TestClassWithFunctions, "_on_test_pressed")
	var doubler := GdUnitFunctionDoublerBuilder.new(fd)
	var expected := """
		func _on_test_pressed(button_id_) -> void:
			var __args := [button_id_]


			await super(button_id_)
		""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.build())).is_equal(expected)
