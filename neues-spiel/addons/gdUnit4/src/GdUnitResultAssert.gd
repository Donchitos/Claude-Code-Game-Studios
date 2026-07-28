## An Assertion Tool to verify Results
@abstract class_name GdUnitResultAssert
extends GdUnitAssert


## Verifies that the current value is null.
@abstract func is_null() -> GdUnitResultAssert


## Verifies that the current value is not null.
@abstract func is_not_null() -> GdUnitResultAssert


## Verifies that the current value is equal to the given one.
@abstract func is_equal(expected: Variant) -> GdUnitResultAssert


## Verifies that the current value is not equal to expected one.
@abstract func is_not_equal(expected: Variant) -> GdUnitResultAssert


## Overrides the default failure message by given custom message.
@abstract func override_failure_message(message: String) -> GdUnitResultAssert


## Appends a custom message to the failure message.
@abstract func append_failure_message(message: String) -> GdUnitResultAssert


## Verifies that the result is ends up with empty
@abstract func is_empty() -> GdUnitResultAssert


## Verifies that the result is ends up with success
@abstract func is_success() -> GdUnitResultAssert


## Verifies that the result is ends up with warning
@abstract func is_warning() -> GdUnitResultAssert


## Verifies that the result is ends up with error
@abstract func is_error() -> GdUnitResultAssert


## Verifies that the result contains the given message
@abstract func contains_message(expected: String) -> GdUnitResultAssert


## Verifies that the result contains the given value
@abstract func is_value(expected: Variant) -> GdUnitResultAssert
