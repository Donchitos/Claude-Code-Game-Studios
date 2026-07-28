## An Assertion Tool to verify Vector values
@abstract class_name GdUnitVectorAssert
extends GdUnitAssert


## Verifies that the current value is null.
@abstract func is_null() -> GdUnitVectorAssert


## Verifies that the current value is not null.
@abstract func is_not_null() -> GdUnitVectorAssert


## Verifies that the current value is equal to the given one.
@abstract func is_equal(expected: Variant) -> GdUnitVectorAssert


## Verifies that the current value is not equal to expected one.
@abstract func is_not_equal(expected: Variant) -> GdUnitVectorAssert


## Verifies that the current and expected value are approximately equal.
@abstract func is_equal_approx(expected: Variant, approx: Variant) -> GdUnitVectorAssert


## Overrides the default failure message by given custom message.
@abstract func override_failure_message(message: String) -> GdUnitVectorAssert


## Appends a custom message to the failure message.
@abstract func append_failure_message(message: String) -> GdUnitVectorAssert


## Verifies that the current value is less than the given one.
@abstract func is_less(expected: Variant) -> GdUnitVectorAssert


## Verifies that the current value is less than or equal the given one.
@abstract func is_less_equal(expected: Variant) -> GdUnitVectorAssert


## Verifies that the current value is greater than the given one.
@abstract func is_greater(expected: Variant) -> GdUnitVectorAssert


## Verifies that the current value is greater than or equal the given one.
@abstract func is_greater_equal(expected: Variant) -> GdUnitVectorAssert


## Verifies that the current value is between the given boundaries (inclusive).
@abstract func is_between(from: Variant, to: Variant) -> GdUnitVectorAssert


## Verifies that the current value is not between the given boundaries (inclusive).
@abstract func is_not_between(from: Variant, to: Variant) -> GdUnitVectorAssert
