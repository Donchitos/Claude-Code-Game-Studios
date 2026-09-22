## An Assertion Tool to verify function callback values
@abstract class_name GdUnitFuncAssert
extends GdUnitAssert


## Verifies that the current value is null.
@abstract func is_null() -> GdUnitFuncAssert


## Verifies that the current value is not null.
@abstract func is_not_null() -> GdUnitFuncAssert


## Verifies that the current value is equal to the given one.
@abstract func is_equal(expected: Variant) -> GdUnitFuncAssert


## Verifies that the current value is not equal to expected one.
@abstract func is_not_equal(expected: Variant) -> GdUnitFuncAssert


## Overrides the default failure message by given custom message.
@abstract func override_failure_message(message: String) -> GdUnitFuncAssert


## Appends a custom message to the failure message.
@abstract func append_failure_message(message: String) -> GdUnitFuncAssert


## Verifies that the current value is true.
@abstract func is_true() -> GdUnitFuncAssert


## Verifies that the current value is false.
@abstract func is_false() -> GdUnitFuncAssert


## Sets the timeout in ms to wait the function returnd the expected value, if the time over a failure is emitted.[br]
## e.g.[br]
## do wait until 5s the function `is_state` is returns 10 [br]
## [code]assert_func(instance, "is_state").wait_until(5000).is_equal(10)[/code]
@abstract func wait_until(timeout: int) -> GdUnitFuncAssert
