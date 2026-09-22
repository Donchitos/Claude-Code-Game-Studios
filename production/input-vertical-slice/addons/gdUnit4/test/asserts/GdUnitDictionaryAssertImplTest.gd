# GdUnit generated TestSuite
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/asserts/GdUnitDictionaryAssertImpl.gd'


func test_must_fail_has_invlalid_type() -> void:
	assert_failure(func() -> void: assert_dict(1)) \
		.is_failed() \
		.has_message("GdUnitDictionaryAssert inital error, unexpected type <int>")
	assert_failure(func() -> void: assert_dict(1.3)) \
		.is_failed() \
		.has_message("GdUnitDictionaryAssert inital error, unexpected type <float>")
	assert_failure(func() -> void: assert_dict(true)) \
		.is_failed() \
		.has_message("GdUnitDictionaryAssert inital error, unexpected type <bool>")
	assert_failure(func() -> void: assert_dict("abc")) \
		.is_failed() \
		.has_message("GdUnitDictionaryAssert inital error, unexpected type <String>")
	assert_failure(func() -> void: assert_dict([])) \
		.is_failed() \
		.has_message("GdUnitDictionaryAssert inital error, unexpected type <Array>")
	assert_failure(func() -> void: assert_dict(Resource.new())) \
		.is_failed() \
		.has_message("GdUnitDictionaryAssert inital error, unexpected type <Object>")


func test_is_null() -> void:
	assert_dict(null).is_null()

	assert_failure(func() -> void: assert_dict({}).is_null()) \
		.is_failed() \
		.has_message("Expecting: '<null>' but was '{ }'")


func test_is_not_null() -> void:
	assert_dict({}).is_not_null()

	assert_failure(func() -> void: assert_dict(null).is_not_null()) \
		.is_failed() \
		.has_message("Expecting: not to be '<null>'")


func test_is_equal() -> void:
	assert_dict({}).is_equal({})
	assert_dict({1:1}).is_equal({1:1})
	assert_dict({1:1, "key_a": "value_a"}).is_equal({1:1, "key_a": "value_a" })
	# different order is also equals
	assert_dict({"key_a": "value_a", 1:1}).is_equal({1:1, "key_a": "value_a" })

	# should fail
	assert_failure(func() -> void: assert_dict(null).is_equal({1:1})) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '{
				1: 1
			  }'
			 but was
			 '<null>'"""
			.dedent()
			.trim_prefix("\n")
		)
	assert_failure(func() -> void: assert_dict({}).is_equal({1:1})).is_failed()
	assert_failure(func() -> void: assert_dict({1:1}).is_equal({})).is_failed()
	assert_failure(func() -> void: assert_dict({1:1}).is_equal({1:2})).is_failed()
	assert_failure(func() -> void: assert_dict({1:2}).is_equal({1:1})).is_failed()
	assert_failure(func() -> void: assert_dict({1:1}).is_equal({1:1, "key_a": "value_a"})).is_failed()
	assert_failure(func() -> void: assert_dict({1:1, "key_a": "value_a"}).is_equal({1:1})).is_failed()
	assert_failure(func() -> void: assert_dict({1:1, "key_a": "value_a"}).is_equal({1:1, "key_b": "value_b"})).is_failed()
	assert_failure(func() -> void: assert_dict({1:1, "key_b": "value_b"}).is_equal({1:1, "key_a": "value_a"})).is_failed()
	assert_failure(func() -> void: assert_dict({"key_a": "value_a", 1:1}).is_equal({1:1, "key_b": "value_b"})).is_failed()
	assert_failure(func() -> void: assert_dict({1:1, "key_b": "value_b"}).is_equal({"key_a": "value_a", 1:1})) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '{
				1: 1,
				"key_a": "value_a"
			  }'
			 but was
			 '{
				1: 1,
				"key_b": "value_b"
			  }'"""
			.dedent()
			.trim_prefix("\n")
		)


func test_is_not_equal() -> void:
	assert_dict(null).is_not_equal({})
	assert_dict({}).is_not_equal(null)
	assert_dict({}).is_not_equal({1:1})
	assert_dict({1:1}).is_not_equal({})
	assert_dict({1:1}).is_not_equal({1:2})
	assert_dict({2:1}).is_not_equal({1:1})
	assert_dict({1:1}).is_not_equal({1:1, "key_a": "value_a"})
	assert_dict({1:1, "key_a": "value_a"}).is_not_equal({1:1})
	assert_dict({1:1, "key_a": "value_a"}).is_not_equal({1:1,  "key_b": "value_b"})

	# should fail
	assert_failure(func() -> void: assert_dict({}).is_not_equal({})).is_failed()
	assert_failure(func() -> void: assert_dict({1:1}).is_not_equal({1:1})).is_failed()
	assert_failure(func() -> void: assert_dict({1:1, "key_a": "value_a"}).is_not_equal({1:1, "key_a": "value_a"})).is_failed()
	assert_failure(func() -> void: assert_dict({"key_a": "value_a", 1:1}).is_not_equal({1:1, "key_a": "value_a"})) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '{
				1: 1,
				"key_a": "value_a"
			  }'
			 not equal to
			 '{
				1: 1,
				"key_a": "value_a"
			  }'"""
			.dedent()
			.trim_prefix("\n")
		)


func test_is_same() -> void:
	var dict_a := {}
	var dict_b := {"key"="value", "key2"="value"}
	var dict_c := {1:1, "key_a": "value_a"}
	var dict_d := {"key_a": "value_a", 1:1}
	assert_dict(dict_a).is_same(dict_a)
	assert_dict(dict_b).is_same(dict_b)
	assert_dict(dict_c).is_same(dict_c)
	assert_dict(dict_d).is_same(dict_d)

	assert_failure(func() -> void: assert_dict({}).is_same({})) \
		.is_failed()\
		.has_message("""
			Expecting:
			 '{ }'
			 to refer to the same object
			 '{ }'"""
			.dedent()
			.trim_prefix("\n")
		)
	assert_failure(func() -> void: assert_dict({1:1, "key_a": "value_a"}).is_same({1:1, "key_a": "value_a" })) \
		.is_failed()\
		.has_message("""
			Expecting:
			 '{
				1: 1,
				"key_a": "value_a"
			  }'
			 to refer to the same object
			 '{
				1: 1,
				"key_a": "value_a"
			  }'"""
			.dedent()
			.trim_prefix("\n")
		)


func test_is_not_same() -> void:
	var dict_a := {}
	var dict_b := {}
	var dict_c := {1:1, "key_a": "value_a"}
	var dict_d := {1:1, "key_a": "value_a"}
	assert_dict(dict_a).is_not_same(dict_b).is_not_same(dict_c).is_not_same(dict_d)
	assert_dict(dict_b).is_not_same(dict_a).is_not_same(dict_c).is_not_same(dict_d)
	assert_dict(dict_c).is_not_same(dict_a).is_not_same(dict_b).is_not_same(dict_d)
	assert_dict(dict_d).is_not_same(dict_a).is_not_same(dict_b).is_not_same(dict_c)

	assert_failure(func() -> void: assert_dict(dict_a).is_not_same(dict_a)) \
		.is_failed()\
		.has_message("""
			Expecting not same:
			 '{ }'"""
			.dedent()
			.trim_prefix("\n")
		)
	assert_failure(func() -> void: assert_dict(dict_c).is_not_same(dict_c)) \
		.is_failed()\
		.has_message("""
			Expecting not same:
			 '{
				1: 1,
				"key_a": "value_a"
			  }'"""
			.dedent()
			.trim_prefix("\n")
		)


func test_is_empty() -> void:
	assert_dict({}).is_empty()

	assert_failure(func() -> void: assert_dict(null).is_empty()) \
		.is_failed() \
		.has_message("Expecting:\n"
			+ " must be empty but was\n"
			+ " '<null>'")
	assert_failure(func() -> void: assert_dict({1:1}).is_empty()) \
		.is_failed() \
		.has_message("""
			Expecting:
			 must be empty but was
			 '{
				1: 1
			  }'"""
			.dedent()
			.trim_prefix("\n")
		)


func test_is_not_empty() -> void:
	assert_dict({1:1}).is_not_empty()
	assert_dict({1:1, "key_a": "value_a"}).is_not_empty()

	assert_failure(func() -> void: assert_dict(null).is_not_empty()) \
		.is_failed() \
		.has_message("Expecting:\n"
			+ " must not be empty")
	assert_failure(func() -> void: assert_dict({}).is_not_empty()).is_failed()


func test_has_size() -> void:
	assert_dict({}).has_size(0)
	assert_dict({1:1}).has_size(1)
	assert_dict({1:1, 2:1}).has_size(2)
	assert_dict({1:1, 2:1, 3:1}).has_size(3)

	assert_failure(func() -> void: assert_dict(null).has_size(0))\
		.is_failed() \
		.has_message("Expecting: not to be '<null>'")
	assert_failure(func() -> void: assert_dict(null).has_size(1)).is_failed()
	assert_failure(func() -> void: assert_dict({}).has_size(1)).is_failed()
	assert_failure(func() -> void: assert_dict({1:1}).has_size(0)).is_failed()
	assert_failure(func() -> void: assert_dict({1:1}).has_size(2)) \
		.is_failed() \
		.has_message("""
			Expecting size:
			 2
			 but was
			 1"""
			.dedent()
			.trim_prefix("\n")
		)

class TestObj:
	var _name :String
	var _value :int

	func _init(name :String = "Foo", value :int = 0) -> void:
		_name = name
		_value = value

	func _to_string() -> String:
		return "class:%s:%d" % [_name, _value]


func test_contains_keys() -> void:
	var key_a := TestObj.new()
	var key_b := TestObj.new()
	var key_c := TestObj.new()
	var key_d := TestObj.new("D")

	assert_dict({1:1, 2:2, 3:3}).contains_keys([2])
	assert_dict({1:1, 2:2, "key_a": "value_a"}).contains_keys([2, "key_a"])
	assert_dict({key_a:1, key_b:2, key_c:3}).contains_keys([key_a, key_b])
	assert_dict({key_a:1, key_c:3 }).contains_keys([key_b])
	assert_dict({key_a:1, 3:3}).contains_keys([key_a, key_b])


	assert_failure(func() -> void: assert_dict({1:1, 3:3}).contains_keys([2])) \
		.is_failed() \
		.has_message("""
			Expecting contains keys:
			 '[1, 3]'
			 to contains:
			 '[2]'
			 but can't find key's:
			 '[2]'"""
			.dedent()
			.trim_prefix("\n")
		)
	assert_failure(func() -> void: assert_dict({1:1, 3:3}).contains_keys([1, 4])) \
		.is_failed() \
		.has_message("""
			Expecting contains keys:
			 '[1, 3]'
			 to contains:
			 '[1, 4]'
			 but can't find key's:
			 '[4]'"""
			.dedent()
			.trim_prefix("\n")
		)
	assert_failure(func() -> void: assert_dict(null).contains_keys([1, 4])) \
		.is_failed() \
		.has_message("Expecting: not to be '<null>'")
	assert_failure(func() -> void: assert_dict({key_a:1, 3:3}).contains_keys([key_a, key_d])) \
		.is_failed() \
		.has_message("""
			 Expecting contains keys:
			  '[class:Foo:0, 3]'
			  to contains:
			  '[class:Foo:0, class:D:0]'
			  but can't find key's:
			  '[class:D:0]'"""
			.dedent().trim_prefix("\n"))


func test_contains_keys_variadic_args() -> void:
	var key_a := TestObj.new()
	var key_b := TestObj.new()
	var key_c := TestObj.new()
	var key_d := TestObj.new("D")

	assert_dict({1:1, 2:2, 3:3}).contains_keys(2)
	assert_dict({1:1, 2:2, "key_a": "value_a"}).contains_keys(2, "key_a")
	assert_dict({key_a:1, key_b:2, key_c:3}).contains_keys(key_a, key_b)
	assert_dict({key_a:1, key_c:3 }).contains_keys(key_b)
	assert_dict({key_a:1, 3:3}).contains_keys(key_a, key_b)

	assert_failure(func() -> void: assert_dict({1:1, 3:3}).contains_keys(2)) \
		.is_failed() \
		.has_message("""
			Expecting contains keys:
			 '[1, 3]'
			 to contains:
			 '[2]'
			 but can't find key's:
			 '[2]'"""
			.dedent()
			.trim_prefix("\n")
		)
	assert_failure(func() -> void: assert_dict({1:1, 3:3}).contains_keys(1, 4)) \
		.is_failed() \
		.has_message("""
			Expecting contains keys:
			 '[1, 3]'
			 to contains:
			 '[1, 4]'
			 but can't find key's:
			 '[4]'"""
			.dedent()
			.trim_prefix("\n")
		)
	assert_failure(func() -> void: assert_dict(null).contains_keys(1, 4)) \
		.is_failed() \
		.has_message("Expecting: not to be '<null>'")
	assert_failure(func() -> void: assert_dict({key_a:1, 3:3}).contains_keys(key_a, key_d)) \
		.is_failed() \
		.has_message("""
			 Expecting contains keys:
			  '[class:Foo:0, 3]'
			  to contains:
			  '[class:Foo:0, class:D:0]'
			  but can't find key's:
			  '[class:D:0]'"""
			.dedent().trim_prefix("\n"))


func test_contains_key_value() -> void:
	assert_dict({1:1}).contains_key_value(1, 1)
	assert_dict({1:1, 2:2, 3:3}).contains_key_value(3, 3).contains_key_value(1, 1)

	assert_failure(func() -> void: assert_dict({1:1}).contains_key_value(1, 2)) \
		.is_failed() \
		.has_message("""
			Expecting contains key and value:
			 1 : 2
			 but contains
			 1 : 1"""
			.dedent()
			.trim_prefix("\n")
		)
	assert_failure(func() -> void: assert_dict(null).contains_key_value(1, 2)) \
		.is_failed() \
		.has_message("Expecting: not to be '<null>'")


func test_not_contains_keys() -> void:
	assert_dict({}).not_contains_keys([2])
	assert_dict({1:1, 3:3}).not_contains_keys([2])
	assert_dict({1:1, 3:3}).not_contains_keys([2, 4])

	assert_failure(func() -> void: assert_dict({1:1, 2:2, 3:3}).not_contains_keys([2, 4])) \
		.is_failed() \
		.has_message("""
			Expecting NOT contains keys:
			 '[1, 2, 3]'
			 do not contains:
			 '[2, 4]'
			 but contains key's:
			 '[2]'"""
			.dedent()
			.trim_prefix("\n")
		)
	assert_failure(func() -> void: assert_dict({1:1, 2:2, 3:3}).not_contains_keys([1, 2, 3, 4])) \
		.is_failed() \
		.has_message("""
			Expecting NOT contains keys:
			 '[1, 2, 3]'
			 do not contains:
			 '[1, 2, 3, 4]'
			 but contains key's:
			 '[1, 2, 3]'"""
			.dedent()
			.trim_prefix("\n")
		)
	assert_failure(func() -> void: assert_dict(null).not_contains_keys([1, 4])) \
		.is_failed() \
		.has_message("Expecting: not to be '<null>'")


func test_not_contains_keys_variadic_args() -> void:
	assert_dict({}).not_contains_keys(2)
	assert_dict({1:1, 3:3}).not_contains_keys(2)
	assert_dict({1:1, 3:3}).not_contains_keys(2, 4)

	assert_failure(func() -> void: assert_dict({1:1, 2:2, 3:3}).not_contains_keys(2, 4)) \
		.is_failed() \
		.has_message("""
			Expecting NOT contains keys:
			 '[1, 2, 3]'
			 do not contains:
			 '[2, 4]'
			 but contains key's:
			 '[2]'"""
			.dedent()
			.trim_prefix("\n")
		)
	assert_failure(func() -> void: assert_dict({1:1, 2:2, 3:3}).not_contains_keys(1, 2, 3, 4)) \
		.is_failed() \
		.has_message("""
			Expecting NOT contains keys:
			 '[1, 2, 3]'
			 do not contains:
			 '[1, 2, 3, 4]'
			 but contains key's:
			 '[1, 2, 3]'"""
			.dedent()
			.trim_prefix("\n")
		)
	assert_failure(func() -> void: assert_dict(null).not_contains_keys(1, 4)) \
		.is_failed() \
		.has_message("Expecting: not to be '<null>'")


func test_contains_same_keys() -> void:
	var key_a := TestObj.new()
	var key_b := TestObj.new()
	var key_c := TestObj.new()

	assert_dict({1:1, 2:2, 3:3}).contains_same_keys([2])
	assert_dict({1:1, 2:2, "key_a": "value_a"}).contains_same_keys([2, "key_a"])
	assert_dict({key_a:1, key_b:2, 3:3}).contains_same_keys([key_b])
	assert_dict({key_a:1, key_b:2, 3:3}).contains_same_keys([key_a, key_b])

	assert_failure(func() -> void: assert_dict({key_a:1, key_c:3 }).contains_same_keys([key_a, key_b])) \
		.is_failed() \
		.has_message("""
			Expecting contains SAME keys:
			 '[class:Foo:0, class:Foo:0]'
			 to contains:
			 '[class:Foo:0, class:Foo:0]'
			 but can't find key's:
			 '[class:Foo:0]'"""
			.dedent().trim_prefix("\n")
		)


func test_contains_same_key_value() -> void:
	var key_a := TestObj.new("A")
	var key_b := TestObj.new("B")
	var key_c := TestObj.new("C")
	var key_d := TestObj.new("A")

	assert_dict({key_a:1, key_b:2, key_c:3})\
		.contains_same_key_value(key_a, 1)\
		.contains_same_key_value(key_b, 2)

	assert_failure(func() -> void: assert_dict({key_a:1, key_b:2, key_c:3}).contains_same_key_value(key_a, 2)) \
		.is_failed() \
		.has_message("""
			Expecting contains SAME key and value:
			 <class:A:0> : 2
			 but contains
			 <class:A:0> : 1"""
			.dedent().trim_prefix("\n")
		)
	assert_failure(func() -> void: assert_dict({key_a:1, key_b:2, key_c:3}).contains_same_key_value(key_d, 1)) \
		.is_failed() \
		.has_message("""
			Expecting contains SAME keys:
			 '[class:A:0, class:B:0, class:C:0]'
			 to contains:
			 '[class:A:0]'
			 but can't find key's:
			 '[class:A:0]'"""
			.dedent().trim_prefix("\n")
		)


func test_not_contains_same_keys() -> void:
	var key_a := TestObj.new("A")
	var key_b := TestObj.new("B")
	var key_c := TestObj.new("C")
	var key_d := TestObj.new("A")

	assert_dict({}).not_contains_same_keys([key_a])
	assert_dict({key_a:1, key_b:2}).not_contains_same_keys([key_c, key_d])

	assert_failure(func() -> void: assert_dict({key_a:1, key_b:2}).not_contains_same_keys([key_c, key_b])) \
		.is_failed() \
		.has_message("""
			Expecting NOT contains SAME keys
			 '[class:A:0, class:B:0]'
			 do not contains:
			 '[class:C:0, class:B:0]'
			 but contains key's:
			 '[class:B:0]'"""
			.dedent().trim_prefix("\n")
		)


func test_not_contains_same_keys_variadic_args() -> void:
	var key_a := TestObj.new("A")
	var key_b := TestObj.new("B")
	var key_c := TestObj.new("C")
	var key_d := TestObj.new("A")

	assert_dict({}).not_contains_same_keys(key_a)
	assert_dict({key_a:1, key_b:2}).not_contains_same_keys(key_c, key_d)

	assert_failure(func() -> void: assert_dict({key_a:1, key_b:2}).not_contains_same_keys(key_c, key_b)) \
		.is_failed() \
		.has_message("""
			Expecting NOT contains SAME keys
			 '[class:A:0, class:B:0]'
			 do not contains:
			 '[class:C:0, class:B:0]'
			 but contains key's:
			 '[class:B:0]'"""
			.dedent().trim_prefix("\n")
		)


func test_override_failure_message() -> void:
	assert_object(assert_dict({1:1}).override_failure_message("error")).is_instanceof(GdUnitDictionaryAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_dict({1:1}) \
			.override_failure_message("Custom failure message") \
			.is_null()) \
		.is_failed() \
		.has_message("Custom failure message")


func test_append_failure_message() -> void:
	assert_object(assert_dict({1:1}).append_failure_message("error")).is_instanceof(GdUnitDictionaryAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_dict({1:1}) \
			.append_failure_message("custom failure data") \
			.is_empty()) \
		.is_failed() \
		.has_message("""
			Expecting:
			 must be empty but was
			 '{
				1: 1
			  }'
			Additional info:
			 custom failure data""".dedent().trim_prefix("\n"))


# tests if an assert fails the 'is_failure' reflects the failure status
func test_is_failure() -> void:
	# initial is false
	assert_bool(is_failure()).is_false()

	# checked success assert
	assert_dict({}).is_empty()
	assert_bool(is_failure()).is_false()

	# checked faild assert
	assert_failure(func() -> void: assert_dict({}).is_not_empty()).is_failed()
	assert_bool(is_failure()).is_true()

	# checked next success assert
	assert_dict({}).is_empty()
	# is true because we have an already failed assert
	assert_bool(is_failure()).is_true()

	# should abort here because we had an failing assert
	if is_failure():
		return
	assert_bool(true).override_failure_message("This line shold never be called").is_false()
