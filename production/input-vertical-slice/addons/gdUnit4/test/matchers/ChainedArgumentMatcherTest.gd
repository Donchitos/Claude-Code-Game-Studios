# GdUnit generated TestSuite
class_name ChainedArgumentMatcherTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/matchers/ChainedArgumentMatcher.gd'


func test_is_match_one_arg() -> void:
	var matchers := [
		EqualsArgumentMatcher.new("foo")
	]
	var matcher := ChainedArgumentMatcher.new(matchers)

	assert_bool(matcher.is_match(["foo"])).is_true()
	assert_bool(matcher.is_match(["bar"])).is_false()


func test_is_match_two_arg() -> void:
	var matchers := [
		EqualsArgumentMatcher.new("foo"),
		EqualsArgumentMatcher.new("value1")
	]
	var matcher := ChainedArgumentMatcher.new(matchers)

	assert_bool(matcher.is_match(["foo", "value1"])).is_true()
	assert_bool(matcher.is_match(["foo", "value2"])).is_false()
	assert_bool(matcher.is_match(["bar", "value1"])).is_false()


func test_is_match_different_arg_and_matcher() -> void:
	var matchers := [
		EqualsArgumentMatcher.new("foo")
	]
	var matcher := ChainedArgumentMatcher.new(matchers)
	assert_bool(matcher.is_match(["foo", "value"])).is_false()
