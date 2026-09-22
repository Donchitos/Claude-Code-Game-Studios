@warning_ignore_start("unsafe_method_access")
extends GdUnitTestSuite

var _rpc_called: String = ""


@rpc("call_local")
func do_rpc(rpc_name: String, value: Variant) -> void:
	_rpc_called = rpc_name + str(value)


@rpc("call_local", "any_peer", "unreliable", 1)
func do_rpc_on_peer(arg1: Variant, arg2: Variant) -> void:
	_rpc_called = str(arg1) + str(arg2)


func test_callable_functions() -> void:
	# supported Callable functions to double see https://docs.godotengine.org/en/stable/classes/class_callable.html#methods
	assert_array(CallableDoubler.callable_functions()).contains_exactly_in_any_order([
		# we allow to default constructor, is need to create at least the spy
		"_init",
		"bind",
		"bindv",
		"call",
		"call_deferred",
		"callv",
		"get_bound_arguments",
		"get_bound_arguments_count",
		"get_method",
		"get_object",
		"get_object_id",
		"hash",
		"is_custom",
		"is_null",
		"is_standard",
		"is_valid",
		"rpc",
		"rpc_id",
		"unbind"])


func test_exclude_functions() -> void:
	assert_array(CallableDoubler.excluded_functions())\
		# it should not exclude callable function
		.not_contains(CallableDoubler.callable_functions())



func test_call() -> void:
	var cb := func(x: int) -> String:
		return "is_called %s" % x
	var cb_spy :Variant = spy(cb)

	# do use the spy to call the callable
	var result :Variant = cb_spy.call(42)
	# verify is called by validate the result
	assert_that(result).is_equal("is_called 42")
	# verify should be successfull
	verify(cb_spy).call(42)
	# verify with a not used argument must fail
	assert_failure(func() -> void: verify(cb_spy).call(23)).is_failed()


func test_call_with_binded_value() -> void:
	var cb := func(x: int, y: int) -> String:
		return "is_called %s.%s" % [x, y]
	var cb_spy :Variant = spy(cb.bind(24))

	# do use the spy to call the callable
	var result :Variant = cb_spy.call(42)
	# verify is called by validate the result
	assert_that(result).is_equal("is_called 42.24")
	# verify should be successfull
	verify(cb_spy).call(42)
	# verify with a not used argument must fail
	assert_failure(func() -> void: verify(cb_spy).call(23)).is_failed()


# we not able to stub on callv because the original signature of Callabe:callv and Object:callv are different
# and a spy is a specialized object delegator to the original implementation as object instance
# a Callable is not inherits form object so it makes it impossible to spy/mock on `callv`
func _test_callv() -> void:
	var cb := func(x: int, y: int) -> String:
		return "is_called %s.%s" % [x, y]
	var cb_spy :Variant = spy(cb.bind(24))

	# do use the spy to call the callable
	var result :Variant = cb_spy.callv([42])
	# verify is called by validate the result
	assert_that(result).is_equal("is_called 42.24")
	# verify should be successfull
	verify(cb_spy).callv([42, 24])


func test_bind_vararg() -> void:
	var cb := func(x: int, y: int) -> String:
		return "is_called %s.%s" % [x, y]
	var cb_spy :Variant = spy(cb)
	cb_spy.bind(24, 25, 26)
	assert_array(cb_spy.get_bound_arguments()).contains_exactly([24, 25, 26])


func test_bind() -> void:
	var cb := func(x: int, y: int) -> String:
		return "is_called %s.%s" % [x, y]
	var cb_spy :Variant = spy(cb)
	cb_spy.bind(24)
	assert_array(cb_spy.get_bound_arguments()).contains_exactly([24])

	# verify bind is called
	verify(cb_spy).bind(24)
	# verify bind is not called with 23
	assert_failure(func() -> void: verify(cb_spy).bind(23)).is_failed()

	# do use the spy to call the callable
	var result :Variant = cb_spy.call(42)
	# verify is called by validate the result
	assert_that(result).is_equal("is_called 42.24")
	# verify should be successfull
	verify(cb_spy).call(42)


func test_bindv() -> void:
	var cb := func(a1: int, a2: int, a3: int, a4: int) -> String:
		return "is_called %s %s %s %s" % [a1, a2, a3, a4]
	var cb_spy :Variant = spy(cb)
	cb_spy.bindv([21,22,23])

	# verify bindv is called
	verify(cb_spy).bindv([21,22,23])
	# verify bindv is not called with [21,22,27]
	assert_failure(func() -> void: verify(cb_spy).bindv([21,22,27])).is_failed()
	# finally check via call it resolves all values
	assert_str(cb_spy.call(42)).is_equal("is_called 42 21 22 23")


func test_unbind() -> void:
	var cb := func(a1: int, a2: int, a3: int) -> String:
		return "is_called %s %s %s" % [a1, a2, a3]
	var cb_spy :Variant = spy(cb.bindv([21,22,23]))
	cb_spy.unbind(1)

	# verify unbind is called
	verify(cb_spy).unbind(1)
	# verify unbind is not called with argument 2
	assert_failure(func() -> void: verify(cb_spy).unbind(2)).is_failed()
	# finally check via call it resolves all values
	assert_str(cb_spy.call(42)).is_equal("is_called 21 22 23")


func test_rpc() -> void:
	_rpc_called = ""
	var cb_spy :Variant = spy(do_rpc)
	cb_spy.rpc("abc", 23)
	# verify the callable @rpc is called
	assert_that(_rpc_called).is_equal("abc23")

	# verify rpc is called
	verify(cb_spy).rpc("abc", 23)
	# verify rpc is not called with this argument s
	assert_failure(func() -> void: verify(cb_spy).rpc("abc", 43)).is_failed()


func test_rpc_id() -> void:
	_rpc_called = ""
	var cb_spy :Variant = spy(do_rpc_on_peer)
	cb_spy.rpc_id(1, "foo", "23")
	# verify the callable @rpc is called
	assert_that(_rpc_called).is_equal("foo23")

	# verify rpc_id is called
	verify(cb_spy).rpc_id(1, "foo", "23")
	# verify rpc_id is not called with this argument s
	assert_failure(func() -> void: verify(cb_spy).rpc_id(23, "arg1", "arg2")).is_failed()


func test_get_bound_arguments() -> void:
	var cb := func() -> void: return
	var cb_syp :Variant = spy(cb)

	verify(cb_syp, 0).get_bound_arguments()
	cb_syp.bind(1,2,3)
	assert_array(cb_syp.get_bound_arguments()).contains_exactly([1,2,3])
	verify(cb_syp, 1).get_bound_arguments()


func test_get_bound_arguments_count() -> void:
	var cb := func() -> void: return
	var cb_syp :Variant = spy(cb)

	verify(cb_syp, 0).get_bound_arguments_count()
	cb_syp.bind(1,2,3)
	assert_that(cb_syp.get_bound_arguments_count()).is_equal(3)
	verify(cb_syp, 1).get_bound_arguments_count()


func test_get_method() -> void:
	var cb_syp :Variant = spy(do_rpc)

	verify(cb_syp, 0).get_method()
	assert_that(cb_syp.get_method()).is_equal("do_rpc")
	verify(cb_syp, 1).get_method()


func test_get_object() -> void:
	var cb_syp :Variant = spy(do_rpc)

	verify(cb_syp, 0).get_object()
	assert_that(cb_syp.get_object()).is_same(self)
	verify(cb_syp, 1).get_object()


func test_get_object_id() -> void:
	var cb_syp :Variant = spy(do_rpc)

	verify(cb_syp, 0).get_object_id()
	assert_that(cb_syp.get_object_id()).is_equal(get_instance_id())
	verify(cb_syp, 1).get_object_id()


func test_hash() -> void:
	var cb_syp :Variant = spy(do_rpc)

	verify(cb_syp, 0).hash()
	assert_that(cb_syp.hash()).is_equal(do_rpc.hash())
	verify(cb_syp, 1).hash()


func test_is_custom_is_true() -> void:
	var cb_syp :Variant = spy(do_rpc)
	assert_that(do_rpc.is_custom()).is_true()

	verify(cb_syp, 0).is_custom()
	assert_that(cb_syp.is_custom()).is_true()
	verify(cb_syp, 1).is_custom()


func test_is_custom_is_false() -> void:
	var cb := Callable(self, "do_rpc")
	assert_that(cb.is_custom()).is_false()

	var cb_syp :Variant = spy(cb)
	verify(cb_syp, 0).is_custom()
	assert_that(cb_syp.is_custom()).is_false()
	verify(cb_syp, 1).is_custom()


func test_is_null() -> void:
	var cb_syp :Variant = spy(do_rpc)

	verify(cb_syp, 0).is_null()
	assert_that(cb_syp.is_null()).is_false()
	verify(cb_syp, 1).is_null()

	cb_syp = spy(Callable())
	assert_that(cb_syp.is_null()).is_true()


func test_is_standard_is_false() -> void:
	var cb_syp :Variant = spy(do_rpc)
	assert_that(do_rpc.is_standard()).is_false()

	verify(cb_syp, 0).is_standard()
	assert_that(cb_syp.is_standard()).is_false()
	verify(cb_syp, 1).is_standard()


func test_is_standard_is_true() -> void:
	var cb := Callable(self, "do_rpc")
	assert_that(cb.is_standard()).is_true()

	var cb_syp :Variant = spy(cb)
	verify(cb_syp, 0).is_standard()
	assert_that(cb_syp.is_standard()).is_true()
	verify(cb_syp, 1).is_standard()


func test_is_valid() -> void:
	var cb_syp :Variant = spy(do_rpc)

	verify(cb_syp, 0).is_valid()
	assert_that(cb_syp.is_valid()).is_true()
	verify(cb_syp, 1).is_valid()

	cb_syp = spy(Callable())
	assert_that(cb_syp.is_valid()).is_false()
