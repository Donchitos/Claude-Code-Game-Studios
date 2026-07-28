## An assertion tool to verify GDUnit asserts.
## This assert is for internal use only, to verify that failed asserts work as expected.
@abstract class_name GdUnitFailureAssert
extends GdUnitAssert


## Verifies that the current value is null.
@abstract func is_null() -> GdUnitFailureAssert


## Verifies that the current value is not null.
@abstract func is_not_null() -> GdUnitFailureAssert


## Verifies that the current value is equal to the given one.
@abstract func is_equal(expected: Variant) -> GdUnitFailureAssert


## Verifies that the current value is not equal to expected one.
@abstract func is_not_equal(expected: Variant) -> GdUnitFailureAssert


## Overrides the default failure message by given custom message.
@abstract func override_failure_message(message: String) -> GdUnitFailureAssert


## Appends a custom message to the failure message.
@abstract func append_failure_message(message: String) -> GdUnitFailureAssert


## Verifies if the executed assert was successful
@abstract func is_success() -> GdUnitFailureAssert


## Verifies if the executed assert has failed
@abstract func is_failed() -> GdUnitFailureAssert


## Verifies the failure line is equal to expected one.
@abstract func has_line(expected: int) -> GdUnitFailureAssert


## Verifies the failure message is equal to expected one.
@abstract func has_message(expected: String) -> GdUnitFailureAssert


## Verifies that the failure message starts with the expected message.
@abstract func starts_with_message(expected: String) -> GdUnitFailureAssert


## Verifies that the failure message contains the expected message.
@abstract func contains_message(expected: String) -> GdUnitFailureAssert
