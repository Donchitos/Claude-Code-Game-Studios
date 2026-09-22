# GdUnit generated TestSuite
class_name GdUnitResultAssertImplTest
extends GdUnitTestSuite


# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/asserts/GdUnitResultAssertImpl.gd'


func test_is_null() -> void:
	assert_result(null).is_null()

	assert_failure(func() -> void: assert_result(GdUnitResult.success("")).is_null()) \
		.is_failed() \
		.has_message('Expecting: \'<null>\' but was <{ "state": 0, "value": "\\"\\"", "warn_msg": "", "err_msg": "" }>')


func test_is_not_null() -> void:
	assert_result(GdUnitResult.success("")).is_not_null()

	assert_failure(func() -> void: assert_result(null).is_not_null()) \
		.is_failed() \
		.has_message("Expecting: not to be '<null>'")


func test_is_empty() -> void:
	assert_result(GdUnitResult.empty()).is_empty()

	assert_failure(func() -> void: assert_result(GdUnitResult.warn("a warning")).is_empty()) \
		.is_failed() \
		.has_message("Expecting the result must be a EMPTY but was WARNING:\n 'a warning'")
	assert_failure(func() -> void: assert_result(GdUnitResult.error("a error")).is_empty()) \
		.is_failed() \
		.has_message("Expecting the result must be a EMPTY but was ERROR:\n 'a error'")
	assert_failure(func() -> void: assert_result(null).is_empty()) \
		.is_failed() \
		.has_message("Expecting the result must be a EMPTY but was <null>.")


func test_is_success() -> void:
	assert_result(GdUnitResult.success("")).is_success()

	assert_failure(func() -> void: assert_result(GdUnitResult.warn("a warning")).is_success()) \
		.is_failed() \
		.has_message("Expecting the result must be a SUCCESS but was WARNING:\n 'a warning'")
	assert_failure(func() -> void: assert_result(GdUnitResult.error("a error")).is_success()) \
		.is_failed() \
		.has_message("Expecting the result must be a SUCCESS but was ERROR:\n 'a error'")
	assert_failure(func() -> void: assert_result(null).is_success()) \
		.is_failed() \
		.has_message("Expecting the result must be a SUCCESS but was <null>.")


func test_is_warning() -> void:
	assert_result(GdUnitResult.warn("a warning")).is_warning()

	assert_failure(func() -> void: assert_result(GdUnitResult.success("value")).is_warning()) \
		.is_failed() \
		.has_message("Expecting the result must be a WARNING but was SUCCESS.")
	assert_failure(func() -> void: assert_result(GdUnitResult.error("a error")).is_warning()) \
		.is_failed() \
		.has_message("Expecting the result must be a WARNING but was ERROR:\n 'a error'")
	assert_failure(func() -> void: assert_result(null).is_warning()) \
		.is_failed() \
		.has_message("Expecting the result must be a WARNING but was <null>.")


func test_is_error() -> void:
	assert_result(GdUnitResult.error("a error")).is_error()

	assert_failure(func() -> void: assert_result(GdUnitResult.success("")).is_error()) \
		.is_failed() \
		.has_message("Expecting the result must be a ERROR but was SUCCESS.")
	assert_failure(func() -> void: assert_result(GdUnitResult.warn("a warning")).is_error()) \
		.is_failed() \
		.has_message("Expecting the result must be a ERROR but was WARNING:\n 'a warning'")
	assert_failure(func() -> void: assert_result(null).is_error()) \
		.is_failed() \
		.has_message("Expecting the result must be a ERROR but was <null>.")


func test_contains_message() -> void:
	assert_result(GdUnitResult.error("a error")).contains_message("a error")
	assert_result(GdUnitResult.warn("a warning")).contains_message("a warning")

	assert_failure(func() -> void: assert_result(GdUnitResult.success("")).contains_message("Error 500")) \
		.is_failed() \
		.has_message("Expecting:\n 'Error 500'\n but the GdUnitResult is a success.")
	assert_failure(func() -> void: assert_result(GdUnitResult.warn("Warning xyz!")).contains_message("Warning aaa!")) \
		.is_failed() \
		.has_message("Expecting:\n 'Warning aaa!'\n but was\n 'Warning xyz!'.")
	assert_failure(func() -> void: assert_result(GdUnitResult.error("Error 410")).contains_message("Error 500")) \
		.is_failed() \
		.has_message("Expecting:\n 'Error 500'\n but was\n 'Error 410'.")
	assert_failure(func() -> void: assert_result(null).contains_message("Error 500")) \
		.is_failed() \
		.has_message("Expecting:\n 'Error 500'\n but was\n '<null>'.")


func test_is_value() -> void:
	assert_result(GdUnitResult.success("")).is_value("")
	var result_value :Node = auto_free(Node.new())
	assert_result(GdUnitResult.success(result_value)).is_value(result_value)

	assert_failure(func() -> void: assert_result(GdUnitResult.success("")).is_value("abc")) \
		.is_failed() \
		.has_message("Expecting to contain same value:\n 'abc'\n but was\n '<empty>'.")
	assert_failure(func() -> void: assert_result(GdUnitResult.success("abc")).is_value("")) \
		.is_failed() \
		.has_message("Expecting to contain same value:\n '<empty>'\n but was\n 'abc'.")
	assert_failure(func() -> void: assert_result(GdUnitResult.success(result_value)).is_value("")) \
		.is_failed() \
		.has_message("Expecting to contain same value:\n '<empty>'\n but was\n <Node>.")
	assert_failure(func() -> void: assert_result(null).is_value("")) \
		.is_failed() \
		.has_message("Expecting to contain same value:\n '<empty>'\n but was\n '<null>'.")


func test_override_failure_message() -> void:
	assert_object(assert_result(GdUnitResult.success("")).override_failure_message("error")).is_instanceof(GdUnitResultAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_result(GdUnitResult.success("")) \
			.override_failure_message("Custom failure message") \
			.is_null()) \
		.is_failed() \
		.has_message("Custom failure message")


func test_append_failure_message() -> void:
	assert_object(assert_result(GdUnitResult.success("")).append_failure_message("error")).is_instanceof(GdUnitResultAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_result(GdUnitResult.success("")) \
			.append_failure_message("custom failure data") \
			.is_error()) \
		.is_failed() \
		.has_message("""
			Expecting the result must be a ERROR but was SUCCESS.
			Additional info:
			 custom failure data""".dedent().trim_prefix("\n"))


# tests if an assert fails the 'is_failure' reflects the failure status
func test_is_failure() -> void:
	# initial is false
	assert_bool(is_failure()).is_false()

	# checked success assert
	assert_result(null).is_null()
	assert_bool(is_failure()).is_false()

	# checked faild assert
	assert_failure(func() -> void: assert_result(RefCounted.new()).is_null()).is_failed()
	assert_bool(is_failure()).is_true()

	# checked next success assert
	assert_result(null).is_null()
	# is true because we have an already failed assert
	assert_bool(is_failure()).is_true()
