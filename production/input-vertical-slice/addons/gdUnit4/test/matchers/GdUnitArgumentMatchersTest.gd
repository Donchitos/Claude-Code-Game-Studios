# GdUnit generated TestSuite
class_name GdUnitArgumentMatchersTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/matchers/GdUnitArgumentMatchers.gd'


func test_arguments_to_chained_matcher() -> void:
	var matcher := GdUnitArgumentMatchers.to_matcher(["foo", false, 1])

	assert_object(matcher).is_instanceof(ChainedArgumentMatcher)
	assert_bool(matcher.is_match(["foo", false, 1])).is_true()
	assert_bool(matcher.is_match(["foo", false, 2])).is_false()
	assert_bool(matcher.is_match(["foo", true, 1])).is_false()
	assert_bool(matcher.is_match(["bar", false, 1])).is_false()
