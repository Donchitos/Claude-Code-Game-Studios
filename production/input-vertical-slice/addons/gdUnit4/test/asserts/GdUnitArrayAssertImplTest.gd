# GdUnit generated TestSuite
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/asserts/GdUnitArrayAssertImpl.gd'

func before() -> void:
	ProjectSettings.set_setting(GdUnitSettings.REPORT_ASSERT_WARNINGS, false)


func test_is_null() -> void:
	assert_array(null).is_null()

	assert_failure(func() -> void: assert_array([]).is_null()) \
		.is_failed() \
		.has_message("Expecting: '<null>' but was '<empty>'")


func test_is_not_null() -> void:
	assert_array([]).is_not_null()

	assert_failure(func() -> void: assert_array(null).is_not_null()) \
		.is_failed() \
		.has_message("Expecting: not to be '<null>'")


func test_is_equal() -> void:
	assert_array([1, 2, 3, 4, 2, 5]).is_equal([1, 2, 3, 4, 2, 5])
	# should fail because the array not contains same elements and has diff size
	assert_failure(func() -> void: assert_array([1, 2, 4, 5]).is_equal([1, 2, 3, 4, 2, 5])) \
		.is_failed()
	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).is_equal([1, 2, 3, 4])) \
		.is_failed()
	# current array is bigger than expected
	assert_failure(func() -> void: assert_array([1, 2222, 3, 4, 5, 6]).is_equal([1, 2, 3, 4])) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '[1,    2, 3, 4]'
			 but was
			 '[1, 2222, 3, 4, 5, 6]'

			Differences found:
			Index	Current	Expected	1	2222	2	4	5	<N/A>	5	6	<N/A>	"""
			.dedent().trim_prefix("\n"))

	# expected array is bigger than current
	assert_failure(func() -> void: assert_array([1, 222, 3, 4]).is_equal([1, 2, 3, 4, 5, 6])) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '[1,   2, 3, 4, 5, 6]'
			 but was
			 '[1, 222, 3, 4]'

			Differences found:
			Index	Current	Expected	1	222	2	4	<N/A>	5	5	<N/A>	6	"""
			.dedent().trim_prefix("\n"))

	assert_failure(func() -> void: assert_array(null).is_equal([1, 2, 3])) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '[1, 2, 3]'
			 but was
			 '<null>'"""
			.dedent().trim_prefix("\n"))


func test_is_equal_variadic_args() -> void:
	assert_array([1, 2, 3, 4, 2, 5]).is_equal(1, 2, 3, 4, 2, 5)
	# should fail because the array not contains same elements and has diff size
	assert_failure(func() -> void: assert_array([1, 2, 4, 5]).is_equal(1, 2, 3, 4, 2, 5)) \
		.is_failed()
	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).is_equal(1, 2, 3, 4)) \
		.is_failed()
	# current array is bigger than expected
	assert_failure(func() -> void: assert_array([1, 2222, 3, 4, 5, 6]).is_equal(1, 2, 3, 4)) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '[1,    2, 3, 4]'
			 but was
			 '[1, 2222, 3, 4, 5, 6]'

			Differences found:
			Index	Current	Expected	1	2222	2	4	5	<N/A>	5	6	<N/A>	"""
			.dedent().trim_prefix("\n"))

	# expected array is bigger than current
	assert_failure(func() -> void: assert_array([1, 222, 3, 4]).is_equal(1, 2, 3, 4, 5, 6)) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '[1,   2, 3, 4, 5, 6]'
			 but was
			 '[1, 222, 3, 4]'

			Differences found:
			Index	Current	Expected	1	222	2	4	<N/A>	5	5	<N/A>	6	"""
			.dedent().trim_prefix("\n"))

	assert_failure(func() -> void: assert_array(null).is_equal(1, 2, 3)) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '[1, 2, 3]'
			 but was
			 '<null>'"""
			.dedent().trim_prefix("\n"))


func test_is_equal_big_arrays() -> void:
	var expeted := Array()
	expeted.resize(1000)
	for i in 1000:
		expeted[i] = i
	var current := expeted.duplicate()
	current[10] = "invalid"
	current[40] = "invalid"
	current[100] = "invalid"
	current[888] = "invalid"

	assert_failure(func() -> void: assert_array(current).is_equal(expeted)) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '[0, 1, 2, 3, 4, 5, 6, 7, 8, 9,      10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, ...]'
			 but was
			 '[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, invalid, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, ...]'

			Differences found:
			Index	Current	Expected	10	invalid	10	40	invalid	40	100	invalid	100	888	invalid	888	"""
			.dedent().trim_prefix("\n"))


func test_is_equal_ignoring_case() -> void:
	assert_array(["this", "is", "a", "message"]).is_equal_ignoring_case(["This", "is", "a", "Message"])
	# should fail because the array not contains same elements
	assert_failure(func() -> void: assert_array(["this", "is", "a", "message"]).is_equal_ignoring_case(["This", "is", "an", "Message"])) \
		.is_failed()
	assert_failure(func() -> void: assert_array(null).is_equal_ignoring_case(["This", "is"])) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '["This", "is"]'
			 but was
			 '<null>'"""
			.dedent().trim_prefix("\n"))


func test_is_equal_ignoring_case_variadic_args() -> void:
	assert_array(["this", "is", "a", "message"]).is_equal_ignoring_case("This", "is", "a", "Message")
	# should fail because the array not contains same elements
	assert_failure(func() -> void: assert_array(["this", "is", "a", "message"]).is_equal_ignoring_case("This", "is", "an", "Message")) \
		.is_failed()
	assert_failure(func() -> void: assert_array(null).is_equal_ignoring_case(["This", "is"])) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '["This", "is"]'
			 but was
			 '<null>'"""
			.dedent().trim_prefix("\n"))


func test_is_not_equal() -> void:
	assert_array(null).is_not_equal([1, 2, 3])
	assert_array([1, 2, 3, 4, 5]).is_not_equal([1, 2, 3, 4, 5, 6])
	# should fail because the array  contains same elements
	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).is_not_equal([1, 2, 3, 4, 5])) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '[1, 2, 3, 4, 5]'
			 not equal to
			 '[1, 2, 3, 4, 5]'"""
			.dedent().trim_prefix("\n"))


func test_is_not_equal_variadic_args() -> void:
	assert_array(null).is_not_equal(1, 2, 3)
	assert_array([1, 2, 3, 4, 5]).is_not_equal(1, 2, 3, 4, 5, 6)
	# should fail because the array  contains same elements
	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).is_not_equal(1, 2, 3, 4, 5)) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '[1, 2, 3, 4, 5]'
			 not equal to
			 '[1, 2, 3, 4, 5]'"""
			.dedent().trim_prefix("\n"))


func test_is_not_equal_ignoring_case() -> void:
	assert_array(null).is_not_equal_ignoring_case(["This", "is", "an", "Message"])
	assert_array(["this", "is", "a", "message"]).is_not_equal_ignoring_case(["This", "is", "an", "Message"])
	# should fail because the array contains same elements ignoring case sensitive
	assert_failure(func() -> void: assert_array(["this", "is", "a", "message"]).is_not_equal_ignoring_case(["This", "is", "a", "Message"])) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '["This", "is", "a", "Message"]'
			 not equal to (case insensitiv)
			 '["this", "is", "a", "message"]'"""
			.dedent().trim_prefix("\n"))


func test_is_not_equal_ignoring_case_varadic_args() -> void:
	assert_array(null).is_not_equal_ignoring_case("This", "is", "an", "Message")
	assert_array(["this", "is", "a", "message"]).is_not_equal_ignoring_case("This", "is", "an", "Message")
	# should fail because the array contains same elements ignoring case sensitive
	assert_failure(func() -> void: assert_array(["this", "is", "a", "message"]).is_not_equal_ignoring_case("This", "is", "a", "Message")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '["This", "is", "a", "Message"]'
			 not equal to (case insensitiv)
			 '["this", "is", "a", "message"]'"""
			.dedent().trim_prefix("\n"))


func test_is_empty() -> void:
	assert_array([]).is_empty()

	assert_failure(func() -> void: assert_array([1, 2, 3]).is_empty()) \
		.is_failed() \
		.has_message("""
			Expecting:
			 must be empty but was
			 '[1, 2, 3]'"""
			.dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_array(null).is_empty()) \
		.is_failed() \
		.has_message("""
			Expecting:
			 must be empty but was
			 '<null>'"""
			.dedent().trim_prefix("\n"))


func test_is_not_empty() -> void:
	assert_array(null).is_not_empty()
	assert_array([1]).is_not_empty()

	assert_failure(func() -> void: assert_array([]).is_not_empty()) \
		.is_failed() \
		.has_message("Expecting:\n must not be empty")


func test_is_same() -> void:
	var value := [0]
	assert_array(value).is_same(value)

	assert_failure(func() -> void: assert_array(value).is_same(value.duplicate()))\
		.is_failed()\
		.has_message("Expecting:\n '[0]'\n to refer to the same object\n '[0]'")


func test_is_not_same() -> void:
	assert_array([0]).is_not_same([0])
	var value := [0]
	assert_failure(func() -> void: assert_array(value).is_not_same(value))\
		.is_failed()\
		.has_message("Expecting not same:\n '[0]'")


func test_has_size() -> void:
	assert_array([1, 2, 3, 4, 5]).has_size(5)
	assert_array(["a", "b", "c", "d", "e", "f"]).has_size(6)

	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).has_size(4)) \
		.is_failed() \
		.has_message("""
			Expecting size:
			 4
			 but was
			 5"""
			.dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_array(null).has_size(4)) \
		.is_failed() \
		.has_message("""
			Expecting size:
			 4
			 but was
			 '<null>'"""
			.dedent().trim_prefix("\n"))


func test_contains() -> void:
	assert_array([1, 2, 3, 4, 5]).contains([])
	assert_array([1, 2, 3, 4, 5]).contains([5, 2])
	assert_array([1, 2, 3, 4, 5]).contains([5, 4, 3, 2, 1])
	var valueA := TestObj.new("A", 0)
	var valueB := TestObj.new("B", 0)
	assert_array([valueA, valueB]).contains([TestObj.new("A", 0)])

	# should fail because the array not contains 7 and 6
	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).contains([2, 7, 6])) \
		.is_failed() \
		.has_message("""
			Expecting contains elements:
			 '[1, 2, 3, 4, 5]'
			 do contains (in any order)
			 '[2, 7, 6]'
			but could not find elements:
			 '[7, 6]'"""
			.dedent().trim_prefix("\n"))

	assert_failure(func() -> void: assert_array(null).contains([2, 7, 6])) \
		.is_failed() \
		.has_message("""
			Expecting contains elements:
			 '<null>'
			 do contains (in any order)
			 '[2, 7, 6]'
			but could not find elements:
			 '[2, 7, 6]'"""
			.dedent().trim_prefix("\n"))

	assert_failure(func() -> void: assert_array([valueA, valueB]).contains([TestObj.new("C", 0)])) \
		.is_failed() \
		.has_message("""
			Expecting contains elements:
			 '[class:A, class:B]'
			 do contains (in any order)
			 '[class:C]'
			but could not find elements:
			 '[class:C]'"""
			.dedent().trim_prefix("\n"))


func test_contains_variadic_args() -> void:
	assert_array([1, 2, 3, 4, 5]).contains()
	assert_array([1, 2, 3, 4, 5]).contains(5, 2)
	assert_array([1, 2, 3, 4, 5]).contains(5, 4, 3, 2, 1)
	var valueA := TestObj.new("A", 0)
	var valueB := TestObj.new("B", 0)
	assert_array([valueA, valueB]).contains(TestObj.new("A", 0))

	# should fail because the array not contains 7 and 6
	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).contains(2, 7, 6)) \
		.is_failed() \
		.has_message("""
			Expecting contains elements:
			 '[1, 2, 3, 4, 5]'
			 do contains (in any order)
			 '[2, 7, 6]'
			but could not find elements:
			 '[7, 6]'"""
			.dedent().trim_prefix("\n"))

	assert_failure(func() -> void: assert_array(null).contains(2, 7, 6)) \
		.is_failed() \
		.has_message("""
			Expecting contains elements:
			 '<null>'
			 do contains (in any order)
			 '[2, 7, 6]'
			but could not find elements:
			 '[2, 7, 6]'"""
			.dedent().trim_prefix("\n"))

	assert_failure(func() -> void: assert_array([valueA, valueB]).contains(TestObj.new("C", 0))) \
		.is_failed() \
		.has_message("""
			Expecting contains elements:
			 '[class:A, class:B]'
			 do contains (in any order)
			 '[class:C]'
			but could not find elements:
			 '[class:C]'"""
			.dedent().trim_prefix("\n"))


func test_contains_exactly() -> void:
	assert_array([1, 2, 3, 4, 5]).contains_exactly([1, 2, 3, 4, 5])
	var valueA := TestObj.new("A", 0)
	var valueB := TestObj.new("B", 0)
	assert_array([valueA, valueB]).contains_exactly([TestObj.new("A", 0), valueB])

	# should fail because the array contains the same elements but in a different order
	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).contains_exactly([1, 4, 3, 2, 5])) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '[1, 2, 3, 4, 5]'
			 do contains (in same order)
			 '[1, 4, 3, 2, 5]'
			 but has different order at position 1
			 '2' vs '4'"""
			.dedent().trim_prefix("\n"))

	# should fail because the array contains more elements and in a different order
	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5, 6, 7]).contains_exactly([1, 4, 3, 2, 5])) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '[1, 2, 3, 4, 5, 6, 7]'
			 do contains (in same order)
			 '[1, 4, 3, 2, 5]'
			but some elements where not expected:
			 '[6, 7]'"""
			.dedent().trim_prefix("\n"))

	# should fail because the array contains less elements and in a different order
	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).contains_exactly([1, 4, 3, 2, 5, 6, 7])) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '[1, 2, 3, 4, 5]'
			 do contains (in same order)
			 '[1, 4, 3, 2, 5, 6, 7]'
			but could not find elements:
			 '[6, 7]'"""
			.dedent().trim_prefix("\n"))

	assert_failure(func() -> void: assert_array(null).contains_exactly([1, 4, 3])) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '<null>'
			 do contains (in same order)
			 '[1, 4, 3]'
			but could not find elements:
			 '[1, 4, 3]'"""
			.dedent().trim_prefix("\n"))

	assert_failure(func() -> void: assert_array([valueA, valueB]).contains_exactly([valueB, TestObj.new("A", 0)])) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '[class:A, class:B]'
			 do contains (in same order)
			 '[class:B, class:A]'
			 but has different order at position 0
			 'class:A' vs 'class:B'"""
		.dedent().trim_prefix("\n"))


func test_contains_exactly_variadic_args() -> void:
	assert_array([1, 2, 3, 4, 5]).contains_exactly(1, 2, 3, 4, 5)
	var valueA := TestObj.new("A", 0)
	var valueB := TestObj.new("B", 0)
	assert_array([valueA, valueB]).contains_exactly(TestObj.new("A", 0), valueB)

	# should fail because the array contains the same elements but in a different order
	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).contains_exactly(1, 4, 3, 2, 5)) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '[1, 2, 3, 4, 5]'
			 do contains (in same order)
			 '[1, 4, 3, 2, 5]'
			 but has different order at position 1
			 '2' vs '4'"""
			.dedent().trim_prefix("\n"))

	# should fail because the array contains more elements and in a different order
	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5, 6, 7]).contains_exactly(1, 4, 3, 2, 5)) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '[1, 2, 3, 4, 5, 6, 7]'
			 do contains (in same order)
			 '[1, 4, 3, 2, 5]'
			but some elements where not expected:
			 '[6, 7]'"""
			.dedent().trim_prefix("\n"))

	# should fail because the array contains less elements and in a different order
	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).contains_exactly(1, 4, 3, 2, 5, 6, 7)) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '[1, 2, 3, 4, 5]'
			 do contains (in same order)
			 '[1, 4, 3, 2, 5, 6, 7]'
			but could not find elements:
			 '[6, 7]'"""
			.dedent().trim_prefix("\n"))

	assert_failure(func() -> void: assert_array(null).contains_exactly(1, 4, 3)) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '<null>'
			 do contains (in same order)
			 '[1, 4, 3]'
			but could not find elements:
			 '[1, 4, 3]'"""
			.dedent().trim_prefix("\n"))

	assert_failure(func() -> void: assert_array([valueA, valueB]).contains_exactly(valueB, TestObj.new("A", 0))) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '[class:A, class:B]'
			 do contains (in same order)
			 '[class:B, class:A]'
			 but has different order at position 0
			 'class:A' vs 'class:B'"""
		.dedent().trim_prefix("\n"))


func test_contains_exactly_in_any_order() -> void:
	assert_array([1, 2, 3, 4, 5]).contains_exactly_in_any_order([1, 2, 3, 4, 5])
	assert_array([1, 2, 3, 4, 5]).contains_exactly_in_any_order([5, 3, 2, 4, 1])
	assert_array([1, 2, 3, 4, 5]).contains_exactly_in_any_order([5, 1, 2, 4, 3])
	var valueA := TestObj.new("A", 0)
	var valueB := TestObj.new("B", 0)
	assert_array([valueA, valueB]).contains_exactly_in_any_order([valueB, TestObj.new("A", 0)])

	# should fail because the array contains not exactly the same elements in any order
	assert_failure(func() -> void: assert_array([1, 2, 6, 4, 5]).contains_exactly_in_any_order([5, 3, 2, 4, 1, 9, 10])) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '[1, 2, 6, 4, 5]'
			 do contains exactly (in any order)
			 '[5, 3, 2, 4, 1, 9, 10]'
			but some elements where not expected:
			 '[6]'
			and could not find elements:
			 '[3, 9, 10]'"""
			.dedent().trim_prefix("\n"))

	#should fail because the array contains the same elements but in a different order
	assert_failure(func() -> void: assert_array([1, 2, 6, 9, 10, 4, 5]).contains_exactly_in_any_order([5, 3, 2, 4, 1])) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '[1, 2, 6, 9, 10, 4, 5]'
			 do contains exactly (in any order)
			 '[5, 3, 2, 4, 1]'
			but some elements where not expected:
			 '[6, 9, 10]'
			and could not find elements:
			 '[3]'"""
			.dedent().trim_prefix("\n"))

	assert_failure(func() -> void: assert_array(null).contains_exactly_in_any_order([1, 4, 3])) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '<null>'
			 do contains exactly (in any order)
			 '[1, 4, 3]'
			but could not find elements:
			 '[1, 4, 3]'"""
			.dedent().trim_prefix("\n"))

	assert_failure(func() -> void:  assert_array([valueA, valueB]).contains_exactly_in_any_order([valueB, TestObj.new("C", 0)])) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '[class:A, class:B]'
			 do contains exactly (in any order)
			 '[class:B, class:C]'
			but some elements where not expected:
			 '[class:A]'
			and could not find elements:
			 '[class:C]'"""
			.dedent().trim_prefix("\n"))


func test_contains_exactly_in_any_order_variadic_args() -> void:
	assert_array([1, 2, 3, 4, 5]).contains_exactly_in_any_order(1, 2, 3, 4, 5)
	assert_array([1, 2, 3, 4, 5]).contains_exactly_in_any_order(5, 3, 2, 4, 1)
	assert_array([1, 2, 3, 4, 5]).contains_exactly_in_any_order(5, 1, 2, 4, 3)
	var valueA := TestObj.new("A", 0)
	var valueB := TestObj.new("B", 0)
	assert_array([valueA, valueB]).contains_exactly_in_any_order(valueB, TestObj.new("A", 0))

	# should fail because the array contains not exactly the same elements in any order
	assert_failure(func() -> void: assert_array([1, 2, 6, 4, 5]).contains_exactly_in_any_order(5, 3, 2, 4, 1, 9, 10)) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '[1, 2, 6, 4, 5]'
			 do contains exactly (in any order)
			 '[5, 3, 2, 4, 1, 9, 10]'
			but some elements where not expected:
			 '[6]'
			and could not find elements:
			 '[3, 9, 10]'"""
			.dedent().trim_prefix("\n"))

	#should fail because the array contains the same elements but in a different order
	assert_failure(func() -> void: assert_array([1, 2, 6, 9, 10, 4, 5]).contains_exactly_in_any_order(5, 3, 2, 4, 1)) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '[1, 2, 6, 9, 10, 4, 5]'
			 do contains exactly (in any order)
			 '[5, 3, 2, 4, 1]'
			but some elements where not expected:
			 '[6, 9, 10]'
			and could not find elements:
			 '[3]'"""
			.dedent().trim_prefix("\n"))

	assert_failure(func() -> void: assert_array(null).contains_exactly_in_any_order(1, 4, 3)) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '<null>'
			 do contains exactly (in any order)
			 '[1, 4, 3]'
			but could not find elements:
			 '[1, 4, 3]'"""
			.dedent().trim_prefix("\n"))

	assert_failure(func() -> void:  assert_array([valueA, valueB]).contains_exactly_in_any_order(valueB, TestObj.new("C", 0))) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '[class:A, class:B]'
			 do contains exactly (in any order)
			 '[class:B, class:C]'
			but some elements where not expected:
			 '[class:A]'
			and could not find elements:
			 '[class:C]'"""
			.dedent().trim_prefix("\n"))


func test_contains_same() -> void:
	var valueA := TestObj.new("A", 0)
	var valueB := TestObj.new("B", 0)

	assert_array([valueA, valueB]).contains_same([valueA])

	assert_failure(func() -> void: assert_array([valueA, valueB]).contains_same([TestObj.new("A", 0)])) \
		.is_failed() \
		.has_message("""
			Expecting contains SAME elements:
			 '[class:A, class:B]'
			 do contains (in any order)
			 '[class:A]'
			but could not find elements:
			 '[class:A]'"""
			.dedent().trim_prefix("\n"))


func test_contains_same_variadic_args() -> void:
	var valueA := TestObj.new("A", 0)
	var valueB := TestObj.new("B", 0)

	assert_array([valueA, valueB]).contains_same(valueA)

	assert_failure(func() -> void: assert_array([valueA, valueB]).contains_same(TestObj.new("A", 0))) \
		.is_failed() \
		.has_message("""
			Expecting contains SAME elements:
			 '[class:A, class:B]'
			 do contains (in any order)
			 '[class:A]'
			but could not find elements:
			 '[class:A]'"""
			.dedent().trim_prefix("\n"))


func test_contains_same_exactly() -> void:
	var valueA := TestObj.new("A", 0)
	var valueB := TestObj.new("B", 0)
	assert_array([valueA, valueB]).contains_same_exactly([valueA, valueB])

	assert_failure(func() -> void: assert_array([valueA, valueB]).contains_same_exactly([valueB, valueA])) \
		.is_failed() \
		.has_message("""
			Expecting contains SAME exactly elements:
			 '[class:A, class:B]'
			 do contains (in same order)
			 '[class:B, class:A]'
			 but has different order at position 0
			 'class:A' vs 'class:B'"""
		.dedent().trim_prefix("\n"))

	assert_failure(func() -> void: assert_array([valueA, valueB]).contains_same_exactly([TestObj.new("A", 0), valueB])) \
		.is_failed() \
		.has_message("""
			Expecting contains SAME exactly elements:
			 '[class:A, class:B]'
			 do contains (in same order)
			 '[class:A, class:B]'
			but some elements where not expected:
			 '[class:A]'
			and could not find elements:
			 '[class:A]'"""
			.dedent().trim_prefix("\n"))


func test_contains_same_exactly_in_any_order() -> void:
	var valueA := TestObj.new("A", 0)
	var valueB := TestObj.new("B", 0)
	assert_array([valueA, valueB]).contains_same_exactly_in_any_order([valueB, valueA])

	assert_failure(func() -> void:  assert_array([valueA, valueB]).contains_same_exactly_in_any_order([valueB, TestObj.new("A", 0)])) \
		.is_failed() \
		.has_message("""
			Expecting contains SAME exactly elements:
			 '[class:A, class:B]'
			 do contains exactly (in any order)
			 '[class:B, class:A]'
			but some elements where not expected:
			 '[class:A]'
			and could not find elements:
			 '[class:A]'"""
			.dedent().trim_prefix("\n"))


func test_contains_same_exactly_in_any_order_variadic_args() -> void:
	var valueA := TestObj.new("A", 0)
	var valueB := TestObj.new("B", 0)
	assert_array([valueA, valueB]).contains_same_exactly_in_any_order(valueB, valueA)

	assert_failure(func() -> void:  assert_array([valueA, valueB]).contains_same_exactly_in_any_order(valueB, TestObj.new("A", 0))) \
		.is_failed() \
		.has_message("""
			Expecting contains SAME exactly elements:
			 '[class:A, class:B]'
			 do contains exactly (in any order)
			 '[class:B, class:A]'
			but some elements where not expected:
			 '[class:A]'
			and could not find elements:
			 '[class:A]'"""
			.dedent().trim_prefix("\n"))


func test_not_contains() -> void:
	assert_array([]).not_contains([0])
	assert_array([1, 2, 3, 4, 5]).not_contains([0])
	assert_array([1, 2, 3, 4, 5]).not_contains([0, 6])
	var valueA := TestObj.new("A", 0)
	var valueB := TestObj.new("B", 0)
	assert_array([valueA, valueB]).not_contains([TestObj.new("C", 0)])

	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).not_contains([5]))\
		.is_failed() \
		.has_message("""
			Expecting:
			 '[1, 2, 3, 4, 5]'
			 do not contains
			 '[5]'
			 but found elements:
			 '[5]'"""
			.dedent().trim_prefix("\n")
		)

	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).not_contains([1, 4, 6])) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '[1, 2, 3, 4, 5]'
			 do not contains
			 '[1, 4, 6]'
			 but found elements:
			 '[1, 4]'"""
			.dedent().trim_prefix("\n")
		)

	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).not_contains([6, 4, 1])) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '[1, 2, 3, 4, 5]'
			 do not contains
			 '[6, 4, 1]'
			 but found elements:
			 '[4, 1]'"""
			.dedent().trim_prefix("\n")
		)

	assert_failure(func() -> void: assert_array([valueA, valueB]).not_contains([TestObj.new("A", 0)])) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '[class:A, class:B]'
			 do not contains
			 '[class:A]'
			 but found elements:
			 '[class:A]'"""
			.dedent().trim_prefix("\n")
		)


func test_not_contains_variadic_args() -> void:
	assert_array([]).not_contains(0)
	assert_array([1, 2, 3, 4, 5]).not_contains(0)
	assert_array([1, 2, 3, 4, 5]).not_contains(0, 6)
	var valueA := TestObj.new("A", 0)
	var valueB := TestObj.new("B", 0)
	assert_array([valueA, valueB]).not_contains(TestObj.new("C", 0))

	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).not_contains(5))\
		.is_failed() \
		.has_message("""
			Expecting:
			 '[1, 2, 3, 4, 5]'
			 do not contains
			 '[5]'
			 but found elements:
			 '[5]'"""
			.dedent().trim_prefix("\n")
		)

	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).not_contains(1, 4, 6)) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '[1, 2, 3, 4, 5]'
			 do not contains
			 '[1, 4, 6]'
			 but found elements:
			 '[1, 4]'"""
			.dedent().trim_prefix("\n")
		)

	assert_failure(func() -> void: assert_array([1, 2, 3, 4, 5]).not_contains(6, 4, 1)) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '[1, 2, 3, 4, 5]'
			 do not contains
			 '[6, 4, 1]'
			 but found elements:
			 '[4, 1]'"""
			.dedent().trim_prefix("\n")
		)

	assert_failure(func() -> void: assert_array([valueA, valueB]).not_contains(TestObj.new("A", 0))) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '[class:A, class:B]'
			 do not contains
			 '[class:A]'
			 but found elements:
			 '[class:A]'"""
			.dedent().trim_prefix("\n")
		)


func test_not_contains_same() -> void:
	var valueA := TestObj.new("A", 0)
	var valueB := TestObj.new("B", 0)
	var valueC := TestObj.new("B", 0)
	assert_array([valueA, valueB]).not_contains_same([valueC])

	assert_failure(func() -> void: assert_array([valueA, valueB]).not_contains_same([valueB])) \
		.is_failed() \
		.has_message("""
			Expecting SAME:
			 '[class:A, class:B]'
			 do not contains
			 '[class:B]'
			 but found elements:
			 '[class:B]'"""
			.dedent().trim_prefix("\n")
		)


func test_not_contains_same_variadic_args() -> void:
	var valueA := TestObj.new("A", 0)
	var valueB := TestObj.new("B", 0)
	var valueC := TestObj.new("B", 0)
	assert_array([valueA, valueB]).not_contains_same(valueC)

	assert_failure(func() -> void: assert_array([valueA, valueB]).not_contains_same(valueB)) \
		.is_failed() \
		.has_message("""
			Expecting SAME:
			 '[class:A, class:B]'
			 do not contains
			 '[class:B]'
			 but found elements:
			 '[class:B]'"""
			.dedent().trim_prefix("\n")
		)


func test_fluent() -> void:
	assert_array([])\
		.has_size(0)\
		.is_empty()\
		.is_not_null()\
		.contains([])\
		.contains_exactly([])


func test_must_fail_has_invlalid_type() -> void:
	assert_failure(func() -> void: assert_array(1)) \
		.is_failed() \
		.has_message("GdUnitArrayAssert inital error, unexpected type <int>")
	assert_failure(func() -> void: assert_array(1.3)) \
		.is_failed() \
		.has_message("GdUnitArrayAssert inital error, unexpected type <float>")
	assert_failure(func() -> void: assert_array(true)) \
		.is_failed() \
		.has_message("GdUnitArrayAssert inital error, unexpected type <bool>")
	assert_failure(func() -> void: assert_array(Resource.new())) \
		.is_failed() \
		.has_message("GdUnitArrayAssert inital error, unexpected type <Object>")


func test_extract() -> void:
	# try to extract checked base types
	assert_array([1, false, 3.14, null, Color.ALICE_BLUE]).extract("get_class") \
		.contains_exactly("n.a.", "n.a.", "n.a.", null, "n.a.")
	# extracting by a func without arguments
	assert_array([RefCounted.new(), 2, AStar3D.new(), auto_free(Node.new())]).extract("get_class") \
		.contains_exactly("RefCounted", "n.a.", "AStar3D", "Node")
	# extracting by a func with arguments
	assert_array([RefCounted.new(), 2, AStar3D.new(), auto_free(Node.new())]).extract("has_signal", ["tree_entered"]) \
		.contains_exactly(false, "n.a.", false, true)
	# extracting by a func with arguments using variadic syntax
	assert_array([RefCounted.new(), 2, AStar3D.new(), auto_free(Node.new())]).extract("has_signal", "tree_entered") \
		.contains_exactly(false, "n.a.", false, true)

	# try extract checked object via a func that not exists
	assert_array([RefCounted.new(), 2, AStar3D.new(), auto_free(Node.new())]).extract("invalid_func") \
		.contains_exactly("n.a.", "n.a.", "n.a.", "n.a.")
	# try extract checked object via a func that has no return value
	assert_array([RefCounted.new(), 2, AStar3D.new(), auto_free(Node.new())]).extract("remove_meta", [""]) \
		.contains_exactly(null, "n.a.", null, null)

	assert_failure(func() -> void: assert_array(null).extract("get_class").contains_exactly("AStar3D", "Node")) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '<null>'
			 do contains (in same order)
			 '["AStar3D", "Node"]'
			but could not find elements:
			 '["AStar3D", "Node"]'"""
			.dedent().trim_prefix("\n"))


class TestObj:
	var _name :String
	var _value :Variant
	var _x :Variant

	func _init(name :String, value :Variant, x :Variant = null) -> void:
		_name = name
		_value = value
		_x = x

	func get_name() -> String:
		return _name

	func get_value() -> Variant:
		return _value

	func get_x() -> Variant:
		return _x

	func get_x1() -> String:
		return "x1"

	func get_x2() -> String:
		return "x2"

	func get_x3() -> String:
		return "x3"

	func get_x4() -> String:
		return "x4"

	func get_x5() -> String:
		return "x5"

	func get_x6() -> String:
		return "x6"

	func get_x7() -> String:
		return "x7"

	func get_x8() -> String:
		return "x8"

	func get_x9() -> String:
		return "x9"

	func _to_string() -> String:
		return "class:" + _name


func test_extractv() -> void:
	# single extract
	assert_array([1, false, 3.14, null, Color.ALICE_BLUE])\
		.extractv(extr("get_class"))\
		.contains_exactly("n.a.", "n.a.", "n.a.", null, "n.a.")
	# tuple of two
	assert_array([TestObj.new("A", 10), TestObj.new("B", "foo"), Color.ALICE_BLUE, TestObj.new("C", 11)])\
		.extractv(extr("get_name"), extr("get_value"))\
		.contains_exactly(tuple("A", 10), tuple("B", "foo"), tuple("n.a.", "n.a."), tuple("C", 11))
	# tuple of three
	assert_array([TestObj.new("A", 10), TestObj.new("B", "foo", "bar"), TestObj.new("C", 11, 42)])\
		.extractv(extr("get_name"), extr("get_value"), extr("get_x"))\
		.contains_exactly(tuple("A", 10, null), tuple("B", "foo", "bar"), tuple("C", 11, 42))

	assert_failure(func() -> void:
			assert_array(null) \
				.extractv(extr("get_name"), extr("get_value"), extr("get_x")) \
				.contains_exactly(tuple("A", 10, null), tuple("B", "foo", "bar"), tuple("C", 11, 42))) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '<null>'
			 do contains (in same order)
			 '[tuple(["A", 10, <null>]), tuple(["B", "foo", "bar"]), tuple(["C", 11, 42])]'
			but could not find elements:
			 '[tuple(["A", 10, <null>]), tuple(["B", "foo", "bar"]), tuple(["C", 11, 42])]'"""
			.dedent().trim_prefix("\n"))


func test_extractv_chained_func() -> void:
	var root_a := TestObj.new("root_a", null)
	var obj_a := TestObj.new("A", root_a)
	var obj_b := TestObj.new("B", root_a)
	var obj_c := TestObj.new("C", root_a)
	var root_b := TestObj.new("root_b", root_a)
	var obj_x := TestObj.new("X", root_b)
	var obj_y := TestObj.new("Y", root_b)

	assert_array([obj_a, obj_b, obj_c, obj_x, obj_y])\
		.extractv(extr("get_name"), extr("get_value.get_name"))\
		.contains_exactly(
			tuple("A", "root_a"),
			tuple("B", "root_a"),
			tuple("C", "root_a"),
			tuple("X", "root_b"),
			tuple("Y", "root_b")
			)


func test_extract_chained_func() -> void:
	var root_a := TestObj.new("root_a", null)
	var obj_a := TestObj.new("A", root_a)
	var obj_b := TestObj.new("B", root_a)
	var obj_c := TestObj.new("C", root_a)
	var root_b := TestObj.new("root_b", root_a)
	var obj_x := TestObj.new("X", root_b)
	var obj_y := TestObj.new("Y", root_b)

	assert_array([obj_a, obj_b, obj_c, obj_x, obj_y])\
		.extract("get_value.get_name")\
		.contains_exactly(
			"root_a",
			"root_a",
			"root_a",
			"root_b",
			"root_b",
			)


func test_extractv_max_args() -> void:
		assert_array([TestObj.new("A", 10), TestObj.new("B", "foo", "bar"), TestObj.new("C", 11, 42)])\
		.extractv(\
			extr("get_name"),
			extr("get_x1"),
			extr("get_x2"),
			extr("get_x3"),
			extr("get_x4"),
			extr("get_x5"),
			extr("get_x6"),
			extr("get_x7"),
			extr("get_x8"),
			extr("get_x9"))\
		.contains_exactly(
			tuple("A", "x1", "x2", "x3", "x4", "x5", "x6", "x7", "x8", "x9"),
			tuple("B", "x1", "x2", "x3", "x4", "x5", "x6", "x7", "x8", "x9"),
			tuple("C", "x1", "x2", "x3", "x4", "x5", "x6", "x7", "x8", "x9"))


func test_override_failure_message() -> void:
	assert_object(assert_array([]).override_failure_message("error")).is_instanceof(GdUnitArrayAssert)
	assert_failure(func() -> void: assert_array([]) \
			.override_failure_message("Custom failure message") \
			.is_null()) \
		.is_failed() \
		.has_message("Custom failure message")


func test_append_failure_message() -> void:
	assert_object(assert_array([]).append_failure_message("error")).is_instanceof(GdUnitArrayAssert)
	assert_failure(func() -> void: assert_array([]) \
			.append_failure_message("custom failure data") \
			.is_not_empty()) \
		.is_failed() \
		.has_message("""
			Expecting:
			 must not be empty
			Additional info:
			 custom failure data""".dedent().trim_prefix("\n"))


# tests if an assert fails the 'is_failure' reflects the failure status
func test_is_failure() -> void:
	# initial is false
	assert_bool(is_failure()).is_false()

	# checked success assert
	assert_array([]).is_empty()
	assert_bool(is_failure()).is_false()

	# checked faild assert
	assert_failure(func() -> void: assert_array([]).is_not_empty()) \
		.is_failed()
	assert_bool(is_failure()).is_true()

	# checked next success assert
	assert_array([]).is_empty()
	# is true because we have an already failed assert
	assert_bool(is_failure()).is_true()

	# should abort here because we had an failing assert
	if is_failure():
		return
	assert_bool(true).override_failure_message("This line shold never be called").is_false()


class ExampleTestClass extends RefCounted:
	var _childs := Array()
	var _parent :RefCounted = null


	func add_child(child :ExampleTestClass) -> ExampleTestClass:
		_childs.append(child)
		child._parent = self
		return self


	func dispose() -> void:
		_parent = null
		_childs.clear()


func test_contains_exactly_stuck() -> void:
	var example_a := ExampleTestClass.new()\
		.add_child(ExampleTestClass.new())\
		.add_child(ExampleTestClass.new())
	var example_b := ExampleTestClass.new()\
		.add_child(ExampleTestClass.new())\
		.add_child(ExampleTestClass.new())
	# this test was stuck and ends after a while into an aborted test case
	# https://github.com/MikeSchulze/gdUnit3/issues/244
	assert_failure(func() -> void: assert_array([example_a, example_b]).contains_exactly(example_a, example_b, example_a))\
		.is_failed()
	# manual free because of cross references
	example_a.dispose()
	example_b.dispose()
