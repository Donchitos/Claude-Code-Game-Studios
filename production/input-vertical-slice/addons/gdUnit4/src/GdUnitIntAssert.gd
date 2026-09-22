## An Assertion Tool to verify integer values
@abstract class_name GdUnitIntAssert
extends GdUnitAssert


## Verifies that the current value is null.
@abstract func is_null() -> GdUnitIntAssert


## Verifies that the current value is not null.
@abstract func is_not_null() -> GdUnitIntAssert


## Verifies that the current value is equal to the given one.
@abstract func is_equal(expected: Variant) -> GdUnitIntAssert


## Verifies that the current value is not equal to expected one.
@abstract func is_not_equal(expected: Variant) -> GdUnitIntAssert


## Overrides the default failure message by given custom message.
@abstract func override_failure_message(message: String) -> GdUnitIntAssert


## Appends a custom message to the failure message.
@abstract func append_failure_message(message: String) -> GdUnitIntAssert


## Verifies that the current value is less than the given one.
@abstract func is_less(expected: int) -> GdUnitIntAssert


## Verifies that the current value is less than or equal the given one.
@abstract func is_less_equal(expected: int) -> GdUnitIntAssert


## Verifies that the current value is greater than the given one.
@abstract func is_greater(expected: int) -> GdUnitIntAssert


## Verifies that the current value is greater than or equal the given one.
@abstract func is_greater_equal(expected: int) -> GdUnitIntAssert


## Verifies that the current value is even.
@abstract func is_even() -> GdUnitIntAssert


## Verifies that the current value is odd.
@abstract func is_odd() -> GdUnitIntAssert


## Verifies that the current value is negative.
@abstract func is_negative() -> GdUnitIntAssert


## Verifies that the current value is not negative.
@abstract func is_not_negative() -> GdUnitIntAssert


## Verifies that the current value is equal to zero.
@abstract func is_zero() -> GdUnitIntAssert


## Verifies that the current value is not equal to zero.
@abstract func is_not_zero() -> GdUnitIntAssert


## Verifies that the current value is in the given set of values.
@abstract func is_in(expected: Array) -> GdUnitIntAssert


## Verifies that the current value is not in the given set of values.
@abstract func is_not_in(expected: Array) -> GdUnitIntAssert


## Verifies that the current value is between the given boundaries (inclusive).
@abstract func is_between(from: int, to: int) -> GdUnitIntAssert
