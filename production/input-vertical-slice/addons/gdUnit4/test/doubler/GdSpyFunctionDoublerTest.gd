extends GdFunctionDoublerTest


func test_double_virtual_return_void_function_without_arg() -> void:
	var doubler := GdUnitSpyFunctionDoubler.new()
	# void _ready() virtual
	var fd := get_function_description("Node", "_ready")
	var expected := """
		func _ready() -> void:
			var __args := []

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("_ready", __args)
					return
				else:
					__verifier.save_function_interaction("_ready", __args)

			super()
		""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_virtual_return_void_function_with_arg() -> void:
	var doubler := GdUnitSpyFunctionDoubler.new()
	# void _input(event: InputEvent) virtual
	var fd := get_function_description("Node", "_input")
	var expected := """
		func _input(event_) -> void:
			var __args := [event_]

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("_input", __args)
					return
				else:
					__verifier.save_function_interaction("_input", __args)

			super(event_)
		""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_return_typed_function_without_arg() -> void:
	var doubler := GdUnitSpyFunctionDoubler.new()
	# String get_class() const
	var fd := get_function_description("Object", "get_class")
	var expected := """
		func get_class() -> String:
			var __args := []

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("get_class", __args)
					return ""
				else:
					__verifier.save_function_interaction("get_class", __args)

			return super()
		""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_return_typed_function_with_args() -> void:
	var doubler := GdUnitSpyFunctionDoubler.new()
	# bool is_connected(signal_: String,Callable(target: Object,method: String)) const
	var fd := get_function_description("Object", "is_connected")
	var expected := """
		func is_connected(signal_, callable_) -> bool:
			var __args := [signal_, callable_]

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("is_connected", __args)
					return false
				else:
					__verifier.save_function_interaction("is_connected", __args)

			return super(signal_, callable_)
		""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_return_void_function_with_args() -> void:
	var doubler := GdUnitSpyFunctionDoubler.new()
	# void disconnect(signal_: StringName, callable_: Callable)
	var fd := get_function_description("Object", "disconnect")
	var expected := """
		func disconnect(signal_, callable_) -> void:
			var __args := [signal_, callable_]

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("disconnect", __args)
					return
				else:
					__verifier.save_function_interaction("disconnect", __args)

			super(signal_, callable_)
		""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_return_void_function_without_args() -> void:
	var doubler := GdUnitSpyFunctionDoubler.new()
	# void free()
	var fd := get_function_description("Object", "free")
	var expected := """
		func free() -> void:
			var __args := []

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("free", __args)
					return
				else:
					__verifier.save_function_interaction("free", __args)

			super()
		""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_return_typed_function_with_args_and_varargs() -> void:
	var doubler := GdUnitSpyFunctionDoubler.new()
	# Error emit_signal(signal_: StringName, ...) vararg
	var fd := get_function_description("Object", "emit_signal")
	var expected := """
		func emit_signal(signal_, ...varargs_: Array) -> Error:
			var __args := [signal_] + varargs_

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("emit_signal", __args)
					return OK
				else:
					__verifier.save_function_interaction("emit_signal", __args)

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


func test_double_return_void_function_only_varargs() -> void:
	var doubler := GdUnitSpyFunctionDoubler.new()
	# void bar(s...) vararg
	var fd := GdFunctionDescriptor.new("bar", false, false, false, TYPE_NIL, "void", [], GdFunctionDescriptor._build_varargs(true))
	var expected := """
		func bar(...varargs_: Array) -> void:
			var __args := [] + varargs_

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("bar", __args)
					return
				else:
					__verifier.save_function_interaction("bar", __args)

			match varargs_.size():
				0: super()
				1: super(varargs_[0])
				2: super(varargs_[0], varargs_[1])
				3: super(varargs_[0], varargs_[1], varargs_[2])
				4: super(varargs_[0], varargs_[1], varargs_[2], varargs_[3])
				5: super(varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4])
				6: super(varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5])
				7: super(varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6])
				8: super(varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6], varargs_[7])
				9: super(varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6], varargs_[7], varargs_[8])
				10: super(varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6], varargs_[7], varargs_[8], varargs_[9])
				_: push_error("To many varradic arguments.")
			return
		""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_return_typed_function_only_varargs() -> void:
	var doubler := GdUnitSpyFunctionDoubler.new()
	# String bar(s...) vararg
	var fd := GdFunctionDescriptor.new("bar", false, false, false, TYPE_STRING, "String", [], GdFunctionDescriptor._build_varargs(true))
	var expected := """
		func bar(...varargs_: Array) -> String:
			var __args := [] + varargs_

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("bar", __args)
					return ""
				else:
					__verifier.save_function_interaction("bar", __args)

			match varargs_.size():
				0: return super()
				1: return super(varargs_[0])
				2: return super(varargs_[0], varargs_[1])
				3: return super(varargs_[0], varargs_[1], varargs_[2])
				4: return super(varargs_[0], varargs_[1], varargs_[2], varargs_[3])
				5: return super(varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4])
				6: return super(varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5])
				7: return super(varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6])
				8: return super(varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6], varargs_[7])
				9: return super(varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6], varargs_[7], varargs_[8])
				10: return super(varargs_[0], varargs_[1], varargs_[2], varargs_[3], varargs_[4], varargs_[5], varargs_[6], varargs_[7], varargs_[8], varargs_[9])
				_: push_error("To many varradic arguments.")
			return ""
		""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_static_return_void_function_without_args() -> void:
	var doubler := GdUnitSpyFunctionDoubler.new()
	# void foo()
	var fd := GdFunctionDescriptor.new("foo", false, true, false, TYPE_NIL, "", [])
	var expected := """
		static func foo() -> void:
			var __args := []

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("foo", __args)
					return
				else:
					__verifier.save_function_interaction("foo", __args)

			super()
		""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_static_return_void_function_with_args() -> void:
	var doubler := GdUnitSpyFunctionDoubler.new()
	var fd := GdFunctionDescriptor.new("foo", false, true, false, TYPE_NIL, "", [
		GdFunctionArgument.new("arg1", TYPE_BOOL),
		GdFunctionArgument.new("arg2", TYPE_STRING, "default")
	])
	var expected := """
		static func foo(arg1_, arg2_="default") -> void:
			var __args := [arg1_, arg2_]

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("foo", __args)
					return
				else:
					__verifier.save_function_interaction("foo", __args)

			super(arg1_, arg2_)
		""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)


func test_double_static_script_function_with_args_return_bool() -> void:
	var doubler := GdUnitSpyFunctionDoubler.new()

	var fd := GdFunctionDescriptor.new("foo", false, true, false, TYPE_BOOL, "", [
		GdFunctionArgument.new("arg1", TYPE_BOOL),
		GdFunctionArgument.new("arg2", TYPE_STRING, "default")
	])
	var expected := """
		static func foo(arg1_, arg2_="default") -> bool:
			var __args := [arg1_, arg2_]

			# verify block
			var __verifier := __get_verifier()
			if __verifier != null:
				if __verifier.is_verify_interactions():
					__verifier.verify_interactions("foo", __args)
					return false
				else:
					__verifier.save_function_interaction("foo", __args)

			return super(arg1_, arg2_)
		""".dedent().trim_prefix("\n")
	assert_str("\n".join(doubler.double(fd))).is_equal(expected)
