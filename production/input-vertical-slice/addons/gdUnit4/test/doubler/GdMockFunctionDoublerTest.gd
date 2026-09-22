# GdUnit generated TestSuite
extends GdFunctionDoublerTest


func test_double_return_typed_function_without_arg() -> void:
	var doubler := GdUnitMockFunctionDoubler.new()
	# String get_class() const
	var fd := get_function_description("Object", "get_class")
	var expected := """
		func get_class() -> String:
			var __args := []

			if __is_prepare_return_value():
				__save_function_return_value("get_class", __args)
				return ""

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("get_class", __args)
					return ""
				else:
					__verifier.save_function_interaction("get_class", __args)

			if __is_do_not_call_real_func("get_class", __args):
				return __return_mock_value("get_class", __args, "")

			return super()
		""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_return_typed_function_with_args() -> void:
	var doubler := GdUnitMockFunctionDoubler.new()
	# bool is_connected(signal: String, callable_: Callable)) const
	var fd := get_function_description("Object", "is_connected")
	var expected := """
		func is_connected(signal_, callable_) -> bool:
			var __args := [signal_, callable_]

			if __is_prepare_return_value():
				__save_function_return_value("is_connected", __args)
				return false

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("is_connected", __args)
					return false
				else:
					__verifier.save_function_interaction("is_connected", __args)

			if __is_do_not_call_real_func("is_connected", __args):
				return __return_mock_value("is_connected", __args, false)

			return super(signal_, callable_)
	""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_return_untyped_function_with_args() -> void:
	var doubler := GdUnitMockFunctionDoubler.new()

	# void disconnect(signal: StringName, callable: Callable)
	var fd := get_function_description("Object", "disconnect")
	var expected := """
		func disconnect(signal_, callable_) -> void:
			var __args := [signal_, callable_]

			if __is_prepare_return_value():
				push_error("Mocking functions with return type void is not allowed!")
				return

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("disconnect", __args)
					return
				else:
					__verifier.save_function_interaction("disconnect", __args)

			if __is_do_not_call_real_func("disconnect", __args):
				return

			super(signal_, callable_)
	""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_int_function_with_varargs() -> void:
	var doubler := GdUnitMockFunctionDoubler.new()
	# Error emit_signal(signal: StringName, ...) vararg
	var fd := get_function_description("Object", "emit_signal")
	var expected := """
		func emit_signal(signal_, ...varargs_: Array) -> Error:
			var __args := [signal_] + varargs_

			if __is_prepare_return_value():
				__save_function_return_value("emit_signal", __args)
				return OK

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("emit_signal", __args)
					return OK
				else:
					__verifier.save_function_interaction("emit_signal", __args)

			if __is_do_not_call_real_func("emit_signal", __args):
				return __return_mock_value("emit_signal", __args, OK)

			match varargs_.size():
				0: return super(signal_)
				1: return super(signal_, varargs_[0])
				2: return super(signal_, varargs_[0], varargs_[1])
				3: return super(signal_, varargs_[0], varargs_[1], varargs_[2])
				4: return super(signal_, varargs_[0], varargs_[1], varargs_[2], varargs_[3])
				5: return super(signal_, varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4])
				6: return super(signal_, varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5])
				7: return super(signal_, varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6])
				8: return super(signal_, varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6], varargs_[7])
				9: return super(signal_, varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6], varargs_[7], varargs_[8])
				10: return super(signal_, varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6], varargs_[7], varargs_[8], varargs_[9])
				_: push_error("To many varradic arguments.")
			return OK
	""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_untyped_function_with_varargs() -> void:
	var doubler := GdUnitMockFunctionDoubler.new()

	# void emit_custom(signal_name, args__ ...) vararg const
	var fd := GdFunctionDescriptor.new("emit_custom", false, false, false, TYPE_NIL, "",
		[GdFunctionArgument.new("signal", TYPE_SIGNAL)],
		GdFunctionDescriptor._build_varargs(true))
	var expected := """
		func emit_custom(signal_, ...varargs_: Array) -> void:
			var __args := [signal_] + varargs_

			if __is_prepare_return_value():
				push_error("Mocking functions with return type void is not allowed!")
				return

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("emit_custom", __args)
					return
				else:
					__verifier.save_function_interaction("emit_custom", __args)

			if __is_do_not_call_real_func("emit_custom", __args):
				return

			match varargs_.size():
				0: super(signal_)
				1: super(signal_, varargs_[0])
				2: super(signal_, varargs_[0], varargs_[1])
				3: super(signal_, varargs_[0], varargs_[1], varargs_[2])
				4: super(signal_, varargs_[0], varargs_[1], varargs_[2], varargs_[3])
				5: super(signal_, varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4])
				6: super(signal_, varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5])
				7: super(signal_, varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6])
				8: super(signal_, varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6], varargs_[7])
				9: super(signal_, varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6], varargs_[7], varargs_[8])
				10: super(signal_, varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6], varargs_[7], varargs_[8], varargs_[9])
				_: push_error("To many varradic arguments.")
			return
	""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_virtual_script_function_without_arg() -> void:
	var doubler := GdUnitMockFunctionDoubler.new()

	# void _ready() virtual
	var fd := get_function_description("Node", "_ready")
	var expected := """
		func _ready() -> void:
			var __args := []

			if __is_prepare_return_value():
				push_error("Mocking functions with return type void is not allowed!")
				return

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("_ready", __args)
					return
				else:
					__verifier.save_function_interaction("_ready", __args)

			if __is_do_not_call_real_func("_ready", __args):
				return

			super()
	""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_virtual_script_function_with_arg() -> void:
	var doubler := GdUnitMockFunctionDoubler.new()

	# void _input(event: InputEvent) virtual
	var fd := get_function_description("Node", "_input")
	var expected := """
		func _input(event_) -> void:
			var __args := [event_]

			if __is_prepare_return_value():
				push_error("Mocking functions with return type void is not allowed!")
				return

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("_input", __args)
					return
				else:
					__verifier.save_function_interaction("_input", __args)

			if __is_do_not_call_real_func("_input", __args):
				return

			super(event_)
	""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)
