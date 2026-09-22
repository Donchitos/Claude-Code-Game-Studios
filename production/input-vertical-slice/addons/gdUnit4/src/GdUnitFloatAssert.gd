## An Assertion Tool to verify float values
@abstract class_name GdUnitFloatAssert
extends GdUnitAssert


## Verifies that the current value is null.
@abstract func is_null() -> GdUnitFloatAssert


## Verifies that the current value is not null.
@abstract func is_not_null() -> GdUnitFloatAssert


## Verifies that the current value is equal to the given one.
@abstract func is_equal(expected: Variant) -> GdUnitFloatAssert


## Verifies that the current value is not equal to expected one.
@abstract func is_not_equal(expected: Variant) -> GdUnitFloatAssert


## Verifies that the current and expected value are approximately equal.
@abstract func is_equal_approx(expected: float, approx: float) -> GdUnitFloatAssert


## Overrides the default failure message by given custom message.
@abstract func override_failure_message(message: String) -> GdUnitFloatAssert


## Appends a custom message to the failure message.
@abstract func append_failure_message(message: String) -> GdUnitFloatAssert


## Verifies that the current value is less than the given one.
@abstract func is_less(expected: float) -> GdUnitFloatAssert


## Verifies that the current value is less than or equal the given one.
@abstract func is_less_equal(expected: float) -> GdUnitFloatAssert


## Verifies that the current value is greater than the given one.
@abstract func is_greater(expected: float) -> GdUnitFloatAssert


## Verifies that the current value is greater than or equal the given one.
@abstract func is_greater_equal(expected: float) -> GdUnitFloatAssert


## Verifies that the current value is negative.
@abstract func is_negative() -> GdUnitFloatAssert


## Verifies that the current value is not negative.
@abstract func is_not_negative() -> GdUnitFloatAssert


## Verifies that the current value is equal to zero.
@abstract func is_zero() -> GdUnitFloatAssert


## Verifies that the current value is not equal to zero.
@abstract func is_not_zero() -> GdUnitFloatAssert


## Verifies that the current value is in the given set of values.
@abstract func is_in(expected: Array) -> GdUnitFloatAssert


## Verifies that the current value is not in the given set of values.
@abstract func is_not_in(expected: Array) -> GdUnitFloatAssert


## Verifies that the current value is between the given boundaries (inclusive).
@abstract func is_between(from: float, to: float) -> GdUnitFloatAssert
