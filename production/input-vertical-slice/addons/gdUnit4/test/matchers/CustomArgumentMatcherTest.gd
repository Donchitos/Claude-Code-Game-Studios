@warning_ignore_start("unsafe_method_access")
extends GdUnitTestSuite


class CustomArgumentMatcher extends GdUnitArgumentMatcher:
	var _peek :int

	func _init(peek :int) -> void:
		_peek = peek

	func is_match(value :Variant) -> bool:
		return value > _peek


func test_custom_matcher() -> void:
	var mocked_test_class : CustomArgumentMatcherTestClass = mock(CustomArgumentMatcherTestClass)

	mocked_test_class.set_value(1000)
	mocked_test_class.set_value(1001)
	mocked_test_class.set_value(1002)
	mocked_test_class.set_value(2002)

	# counts 1001, 1002, 2002 = 3 times
	verify(mocked_test_class, 3).set_value(CustomArgumentMatcher.new(1000))
	# counts 2002 = 1 times
	verify(mocked_test_class, 1).set_value(CustomArgumentMatcher.new(2000))
