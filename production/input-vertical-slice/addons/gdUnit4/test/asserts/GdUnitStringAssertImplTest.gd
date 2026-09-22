# GdUnit generated TestSuite
class_name GdUnitStringAssertImplTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/asserts/GdUnitStringAssertImpl.gd'


func test_is_null() -> void:
	assert_str(null).is_null()

	assert_failure(func() -> void: assert_str("abc").is_null()) \
		.is_failed() \
		.starts_with_message("Expecting: '<null>' but was 'abc'")


func test_is_not_null() -> void:
	assert_str("abc").is_not_null()
	assert_str(&"abc").is_not_null()

	assert_failure(func() -> void: assert_str(null).is_not_null()) \
		.is_failed() \
		.has_message("Expecting: not to be '<null>'")


func test_is_equal() -> void:
	assert_str("This is a test message").is_equal("This is a test message")
	assert_str("abc").is_equal("abc")
	assert_str("abc").is_equal(&"abc")
	assert_str(&"abc").is_equal("abc")
	assert_str(&"abc").is_equal(&"abc")

	assert_failure(func() -> void: assert_str("This is a test message").is_equal("This is a test Message")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a test Message'
			 but was
			 'This is a test Mmessage'""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str(null).is_equal("This is a test Message")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a test Message'
			 but was
			 '<null>'""".dedent().trim_prefix("\n"))


func test_is_equal_pipe_character() -> void:
	assert_failure(func() -> void: assert_str("AAA|BBB|CCC").is_equal("AAA|BBB.CCC")) \
		.is_failed()


func test_is_equal_ignoring_case() -> void:
	assert_str("This is a test message").is_equal_ignoring_case("This is a test Message")
	assert_str("This is a test message").is_equal_ignoring_case(&"This is a test Message")
	assert_str(&"This is a test message").is_equal_ignoring_case("This is a test Message")
	assert_str(&"This is a test message").is_equal_ignoring_case(&"This is a test Message")

	assert_failure(func() -> void: assert_str("This is a test message").is_equal_ignoring_case("This is a Message")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a Message'
			 but was
			 'This is a Mtest message' (ignoring case)""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str(null).is_equal_ignoring_case("This is a Message")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a Message'
			 but was
			 '<null>' (ignoring case)""".dedent().trim_prefix("\n"))


func test_is_not_equal() -> void:
	assert_str(null).is_not_equal("This is a test Message")
	assert_str("This is a test message").is_not_equal("This is a test Message")
	assert_str("This is a test message").is_not_equal(&"This is a test Message")
	assert_str(&"This is a test message").is_not_equal("This is a test Message")
	assert_str(&"This is a test message").is_not_equal(&"This is a test Message")

	assert_failure(func() -> void: assert_str("This is a test message").is_not_equal("This is a test message")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a test message'
			 not equal to
			 'This is a test message'""".dedent().trim_prefix("\n"))


func test_is_not_equal_ignoring_case() -> void:
	assert_str(null).is_not_equal_ignoring_case("This is a Message")
	assert_str("This is a test message").is_not_equal_ignoring_case("This is a Message")
	assert_str("This is a test message").is_not_equal_ignoring_case(&"This is a Message")
	assert_str(&"This is a test message").is_not_equal_ignoring_case("This is a Message")
	assert_str(&"This is a test message").is_not_equal_ignoring_case(&"This is a Message")

	assert_failure(func() -> void: assert_str("This is a test message").is_not_equal_ignoring_case("This is a test Message")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a test Message'
			 not equal to
			 'This is a test message'""".dedent().trim_prefix("\n"))


func test_is_empty() -> void:
	assert_str("").is_empty()
	assert_str(&"").is_empty()

	assert_failure(func() -> void: assert_str(" ").is_empty()) \
		.is_failed() \
		.has_message("""
			Expecting:
			 must be empty but was
			 ' '""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str("abc").is_empty()) \
		.is_failed() \
		.has_message("""
			Expecting:
			 must be empty but was
			 'abc'""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str(&"abc").is_empty()) \
		.is_failed() \
		.has_message("""
			Expecting:
			 must be empty but was
			 'abc'""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str(null).is_empty()) \
		.is_failed() \
		.has_message("""
			Expecting:
			 must be empty but was
			 '<null>'""".dedent().trim_prefix("\n"))


func test_is_not_empty() -> void:
	assert_str(" ").is_not_empty()
	assert_str("	").is_not_empty()
	assert_str("abc").is_not_empty()
	assert_str(&"abc").is_not_empty()

	assert_failure(func() -> void: assert_str("").is_not_empty()) \
		.is_failed() \
		.has_message("""
			Expecting:
			 must not be empty""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str(null).is_not_empty()) \
		.is_failed() \
		.has_message("""
			Expecting:
			 must not be empty""".dedent().trim_prefix("\n"))


func test_contains() -> void:
	assert_str("This is a test message").contains("a test")
	assert_str("This is a test message").contains(&"a test")
	assert_str(&"This is a test message").contains("a test")
	assert_str(&"This is a test message").contains(&"a test")
	# must fail because of camel case difference
	assert_failure(func() -> void: assert_str("This is a test message").contains("a Test")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a test message'
			 do contains
			 'a Test'""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str(null).contains("a Test")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '<null>'
			 do contains
			 'a Test'""".dedent().trim_prefix("\n"))


func test_not_contains() -> void:
	assert_str(null).not_contains("a tezt")
	assert_str("This is a test message").not_contains("a tezt")
	assert_str("This is a test message").not_contains(&"a tezt")
	assert_str(&"This is a test message").not_contains("a tezt")
	assert_str(&"This is a test message").not_contains(&"a tezt")

	assert_failure(func() -> void: assert_str("This is a test message").not_contains("a test")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a test message'
			 not do contain
			 'a test'""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str(&"This is a test message").not_contains("a test")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a test message'
			 not do contain
			 'a test'""".dedent().trim_prefix("\n"))


func test_contains_ignoring_case() -> void:
	assert_str("This is a test message").contains_ignoring_case("a Test")
	assert_str("This is a test message").contains_ignoring_case(&"a Test")
	assert_str(&"This is a test message").contains_ignoring_case("a Test")
	assert_str(&"This is a test message").contains_ignoring_case(&"a Test")

	assert_failure(func() -> void: assert_str("This is a test message").contains_ignoring_case("a Tesd")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a test message'
			 contains
			 'a Tesd'
			 (ignoring case)""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str(null).contains_ignoring_case("a Tesd")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '<null>'
			 contains
			 'a Tesd'
			 (ignoring case)""".dedent().trim_prefix("\n"))


func test_not_contains_ignoring_case() -> void:
	assert_str(null).not_contains_ignoring_case("a Test")
	assert_str("This is a test message").not_contains_ignoring_case("a Tezt")
	assert_str("This is a test message").not_contains_ignoring_case(&"a Tezt")
	assert_str(&"This is a test message").not_contains_ignoring_case("a Tezt")
	assert_str(&"This is a test message").not_contains_ignoring_case(&"a Tezt")

	assert_failure(func() -> void: assert_str("This is a test message").not_contains_ignoring_case("a Test")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a test message'
			 not do contains
			 'a Test'
			 (ignoring case)""".dedent().trim_prefix("\n"))


func test_starts_with() -> void:
	assert_str("This is a test message").starts_with("This is")
	assert_str("This is a test message").starts_with(&"This is")
	assert_str(&"This is a test message").starts_with("This is")
	assert_str(&"This is a test message").starts_with(&"This is")

	assert_failure(func() -> void: assert_str("This is a test message").starts_with("This iss")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a test message'
			 to start with
			 'This iss'""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str("This is a test message").starts_with("this is")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a test message'
			 to start with
			 'this is'""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str("This is a test message").starts_with("test")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a test message'
			 to start with
			 'test'""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str(null).starts_with("test")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '<null>'
			 to start with
			 'test'""".dedent().trim_prefix("\n"))


func test_ends_with() -> void:
	assert_str("This is a test message").ends_with("test message")
	assert_str("This is a test message").ends_with(&"test message")
	assert_str(&"This is a test message").ends_with("test message")
	assert_str(&"This is a test message").ends_with(&"test message")

	assert_failure(func() -> void: assert_str("This is a test message").ends_with("tes message")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a test message'
			 to end with
			 'tes message'""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str("This is a test message").ends_with("a test")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'This is a test message'
			 to end with
			 'a test'""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str(null).ends_with("a test")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '<null>'
			 to end with
			 'a test'""".dedent().trim_prefix("\n"))


func test_has_length() -> void:
	assert_str("This is a test message").has_length(22)
	assert_str(&"This is a test message").has_length(22)
	assert_str("").has_length(0)
	assert_str(&"").has_length(0)

	assert_failure(func() -> void: assert_str("This is a test message").has_length(23)) \
		.is_failed() \
		.has_message("""
			Expecting size:
			 23 but was 22 in
			 'This is a test message'""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str(null).has_length(23)) \
		.is_failed() \
		.has_message("""
			Expecting size:
			 23 but was <null> in
			 '<null>'""".dedent().trim_prefix("\n"))


func test_has_length_less_than() -> void:
	assert_str("This is a test message").has_length(23, Comparator.LESS_THAN)
	assert_str("This is a test message").has_length(42, Comparator.LESS_THAN)
	assert_str(&"This is a test message").has_length(42, Comparator.LESS_THAN)

	assert_failure(func() -> void: assert_str("This is a test message").has_length(22, Comparator.LESS_THAN)) \
		.is_failed() \
		.has_message("""
			Expecting size to be less than:
			 22 but was 22 in
			 'This is a test message'""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str(null).has_length(22, Comparator.LESS_THAN)) \
		.is_failed() \
		.has_message("""
			Expecting size to be less than:
			 22 but was <null> in
			 '<null>'""".dedent().trim_prefix("\n"))


func test_has_length_less_equal() -> void:
	assert_str("This is a test message").has_length(22, Comparator.LESS_EQUAL)
	assert_str("This is a test message").has_length(23, Comparator.LESS_EQUAL)
	assert_str(&"This is a test message").has_length(23, Comparator.LESS_EQUAL)

	assert_failure(func() -> void: assert_str("This is a test message").has_length(21, Comparator.LESS_EQUAL)) \
		.is_failed() \
		.has_message("""
			Expecting size to be less than or equal:
			 21 but was 22 in
			 'This is a test message'""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str(null).has_length(21, Comparator.LESS_EQUAL)) \
		.is_failed() \
		.has_message("""
			Expecting size to be less than or equal:
			 21 but was <null> in
			 '<null>'""".dedent().trim_prefix("\n"))


func test_has_length_greater_than() -> void:
	assert_str("This is a test message").has_length(21, Comparator.GREATER_THAN)
	assert_str(&"This is a test message").has_length(21, Comparator.GREATER_THAN)

	assert_failure(func() -> void: assert_str("This is a test message").has_length(22, Comparator.GREATER_THAN)) \
		.is_failed() \
		.has_message("""
			Expecting size to be greater than:
			 22 but was 22 in
			 'This is a test message'""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str(null).has_length(22, Comparator.GREATER_THAN)) \
		.is_failed() \
		.has_message("""
			Expecting size to be greater than:
			 22 but was <null> in
			 '<null>'""".dedent().trim_prefix("\n"))


func test_has_length_greater_equal() -> void:
	assert_str("This is a test message").has_length(21, Comparator.GREATER_EQUAL)
	assert_str("This is a test message").has_length(22, Comparator.GREATER_EQUAL)
	assert_str(&"This is a test message").has_length(22, Comparator.GREATER_EQUAL)

	assert_failure(func() -> void: assert_str("This is a test message").has_length(23, Comparator.GREATER_EQUAL)) \
		.is_failed() \
		.has_message("""
			Expecting size to be greater than or equal:
			 23 but was 22 in
			 'This is a test message'""".dedent().trim_prefix("\n"))
	assert_failure(func() -> void: assert_str(null).has_length(23, Comparator.GREATER_EQUAL)) \
		.is_failed() \
		.has_message("""
			Expecting size to be greater than or equal:
			 23 but was <null> in
			 '<null>'""".dedent().trim_prefix("\n"))


func test_fluentable() -> void:
	assert_str("value a").is_not_equal("a") \
		.is_equal("value a") \
		.has_length(7) \
		.is_equal("value a")


func test_must_fail_has_invlalid_type() -> void:
	assert_failure(func() -> void: assert_str(1)) \
		.is_failed() \
		.has_message("GdUnitStringAssert inital error, unexpected type <int>")
	assert_failure(func() -> void: assert_str(1.3)) \
		.is_failed() \
		.has_message("GdUnitStringAssert inital error, unexpected type <float>")
	assert_failure(func() -> void: assert_str(true)) \
		.is_failed() \
		.has_message("GdUnitStringAssert inital error, unexpected type <bool>")
	assert_failure(func() -> void: assert_str(Resource.new())) \
		.is_failed() \
		.has_message("GdUnitStringAssert inital error, unexpected type <Object>")


func test_override_failure_message() -> void:
	assert_object(assert_str("").override_failure_message("error")).is_instanceof(GdUnitStringAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_str("") \
			.override_failure_message("Custom failure message") \
			.is_null()) \
		.is_failed() \
		.has_message("Custom failure message")


func test_append_failure_message() -> void:
	assert_object(assert_str("").append_failure_message("error")).is_instanceof(GdUnitStringAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_str("") \
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
	assert_str(null).is_null()
	assert_bool(is_failure()).is_false()

	# checked failed assert
	assert_failure(func() -> void: assert_str(RefCounted.new()).is_null()) \
		.is_failed()
	assert_bool(is_failure()).is_true()

	# checked next success assert
	assert_str(null).is_null()
	# is true because we have an already failed assert
	assert_bool(is_failure()).is_true()


func test_日本語() -> void:
	assert_str("test_日本語").is_equal("test_日本語")
	assert_failure(func() -> void: assert_str("test_日本語").is_equal("test_本語")) \
		.is_failed() \
		.has_message("""
			Expecting:
			 'test_本語'
			 but was
			 'test_日本語'""".dedent().trim_prefix("\n"))


func test_is_equal_on_rich_text() -> void:
	assert_failure(func() -> void:
		assert_str("[color=ff00ff]test[/color]").is_equal("[color=ffff00]test[/color]")
	).is_failed() \
		# We expect for text containing bbcode tags is rendered with masked tags
		.has_message("""
			Expecting:
			 '[lb]color=ffff00]test[lb]/color]'
			 but was
			 '[lb]color=ff00ff]test[lb]/color]'""".dedent().trim_prefix("\n"))
