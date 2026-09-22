# GdUnit generated TestSuite
class_name GdUnitResultTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/GdUnitResult.gd'


func test_serde() -> void:
	var value := {
		"info" : "test",
		"meta" : 42
	}
	var source := GdUnitResult.success(value)
	var serialized_result := GdUnitResult.serialize(source)
	var deserialised_result := GdUnitResult.deserialize(serialized_result)
	assert_object(deserialised_result)\
		.is_instanceof(GdUnitResult) \
		.is_equal(source)


func test_or_else_on_success() -> void:
	var result := GdUnitResult.success("some value")
	assert_str(result.value()).is_equal("some value")
	assert_str(result.or_else("other value")).is_equal("some value")


func test_or_else_on_warning() -> void:
	var result := GdUnitResult.warn("some warning message")
	assert_object(result.value()).is_null()
	assert_str(result.or_else("other value")).is_equal("other value")


func test_or_else_on_error() -> void:
	var result := GdUnitResult.error("some error message")
	assert_object(result.value()).is_null()
	assert_str(result.or_else("other value")).is_equal("other value")
