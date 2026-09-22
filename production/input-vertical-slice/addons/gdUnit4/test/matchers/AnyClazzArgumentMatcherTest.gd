# GdUnit generated TestSuite
class_name AnyClazzArgumentMatcherTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/matchers/AnyClazzArgumentMatcher.gd'


func test_is_match_reference() -> void:
	var matcher := AnyClazzArgumentMatcher.new(RefCounted)

	assert_bool(matcher.is_match(Resource.new())).is_true()
	assert_bool(matcher.is_match(RefCounted.new())).is_true()
	assert_bool(matcher.is_match(auto_free(Node.new()))).is_false()
	assert_bool(matcher.is_match(null)).is_false()
	assert_bool(matcher.is_match(0)).is_false()
	assert_bool(matcher.is_match(false)).is_false()
	assert_bool(matcher.is_match(true)).is_false()


func test_is_match_node() -> void:
	var matcher := AnyClazzArgumentMatcher.new(Node)

	assert_bool(matcher.is_match(auto_free(Node.new()))).is_true()
	assert_bool(matcher.is_match(auto_free(AnimationPlayer.new()))).is_true()
	assert_bool(matcher.is_match(auto_free(Timer.new()))).is_true()
	assert_bool(matcher.is_match(Resource.new())).is_false()
	assert_bool(matcher.is_match(RefCounted.new())).is_false()
	assert_bool(matcher.is_match(null)).is_false()
	assert_bool(matcher.is_match(0)).is_false()
	assert_bool(matcher.is_match(false)).is_false()
	assert_bool(matcher.is_match(true)).is_false()


func test_any_class() -> void:
	assert_object(any_class(Node)).is_instanceof(AnyClazzArgumentMatcher)


func test_to_string() -> void:
	assert_str(str(any_class(Node))).is_equal("any_class(<Node>)")
	assert_str(str(any_class(Object))).is_equal("any_class(<Object>)")
	assert_str(str(any_class(RefCounted))).is_equal("any_class(<RefCounted>)")
	assert_str(str(any_class(GdObjects))).is_equal("any_class(<GdObjects>)")
