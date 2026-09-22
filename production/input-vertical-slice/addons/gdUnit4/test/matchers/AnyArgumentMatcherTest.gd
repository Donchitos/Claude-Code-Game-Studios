# GdUnit generated TestSuite
class_name AnyArgumentMatcherTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/matchers/AnyArgumentMatcher.gd'


func test_is_match() -> void:
	var matcher := AnyArgumentMatcher.new()

	assert_bool(matcher.is_match(null)).is_true()
	assert_bool(matcher.is_match("")).is_true()
	assert_bool(matcher.is_match("abc")).is_true()
	assert_bool(matcher.is_match(true)).is_true()
	assert_bool(matcher.is_match(false)).is_true()
	assert_bool(matcher.is_match(0)).is_true()
	assert_bool(matcher.is_match(100010)).is_true()
	assert_bool(matcher.is_match(1.2)).is_true()
	assert_bool(matcher.is_match(RefCounted.new())).is_true()
	assert_bool(matcher.is_match(auto_free(Node.new()))).is_true()


func test_any() -> void:
	assert_object(any()).is_instanceof(AnyArgumentMatcher)


func test_to_string() -> void:
	assert_str(str(any())).is_equal("any()")
