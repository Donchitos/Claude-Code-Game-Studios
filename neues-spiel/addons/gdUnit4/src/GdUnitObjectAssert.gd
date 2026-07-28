## An Assertion Tool to verify Object values
@abstract class_name GdUnitObjectAssert
extends GdUnitAssert


## Verifies that the current value is null.
@abstract func is_null() -> GdUnitObjectAssert


## Verifies that the current value is not null.
@abstract func is_not_null() -> GdUnitObjectAssert


## Verifies that the current value is equal to the given one.
@abstract func is_equal(expected: Variant) -> GdUnitObjectAssert


## Verifies that the current value is not equal to expected one.
@abstract func is_not_equal(expected: Variant) -> GdUnitObjectAssert


## Overrides the default failure message by given custom message.
@abstract func override_failure_message(message: String) -> GdUnitObjectAssert


## Appends a custom message to the failure message.
@abstract func append_failure_message(message: String) -> GdUnitObjectAssert


## Verifies that the current object is the same as the given one.
@abstract func is_same(expected: Variant) -> GdUnitObjectAssert


## Verifies that the current object is not the same as the given one.
@abstract func is_not_same(expected: Variant) -> GdUnitObjectAssert


## Verifies that the current object is an instance of the given type.
@abstract func is_instanceof(type: Variant) -> GdUnitObjectAssert


## Verifies that the current object is not an instance of the given type.
@abstract func is_not_instanceof(type: Variant) -> GdUnitObjectAssert


## Checks whether the current object inherits from the specified type.
@abstract func is_inheriting(type: Variant) -> GdUnitObjectAssert


## Checks whether the current object does NOT inherit from the specified type.
@abstract func is_not_inheriting(type: Variant) -> GdUnitObjectAssert
