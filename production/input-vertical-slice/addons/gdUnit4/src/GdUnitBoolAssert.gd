## An Assertion Tool to verify boolean values
@abstract class_name GdUnitBoolAssert
extends GdUnitAssert


## Verifies that the current value is null.
@abstract func is_null() -> GdUnitBoolAssert


## Verifies that the current value is not null.
@abstract func is_not_null() -> GdUnitBoolAssert


## Verifies that the current value is equal to the given one.
@abstract func is_equal(expected: Variant) -> GdUnitBoolAssert


## Verifies that the current value is not equal to the given one.
@abstract func is_not_equal(expected: Variant) -> GdUnitBoolAssert


## Overrides the default failure message by given custom message.
@abstract func override_failure_message(message: String) -> GdUnitBoolAssert


## Appends a custom message to the failure message.
@abstract func append_failure_message(message: String) -> GdUnitBoolAssert


## Verifies that the current value is true.
@abstract func is_true() -> GdUnitBoolAssert


## Verifies that the current value is false.
@abstract func is_false() -> GdUnitBoolAssert
