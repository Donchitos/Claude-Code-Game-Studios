@abstract class_name GdUnitFileAssert
extends GdUnitAssert


## Verifies that the current value is null.
@abstract func is_null() -> GdUnitFileAssert


## Verifies that the current value is not null.
@abstract func is_not_null() -> GdUnitFileAssert


## Verifies that the current value is equal to the given one.
@abstract func is_equal(expected: Variant) -> GdUnitFileAssert


## Verifies that the current value is not equal to expected one.
@abstract func is_not_equal(expected: Variant) -> GdUnitFileAssert


## Overrides the default failure message by given custom message.
@abstract func override_failure_message(message: String) -> GdUnitFileAssert


## Appends a custom message to the failure message.
@abstract func append_failure_message(message: String) -> GdUnitFileAssert


@abstract func is_file() -> GdUnitFileAssert


@abstract func exists() -> GdUnitFileAssert


@abstract func is_script() -> GdUnitFileAssert


@abstract func contains_exactly(expected_rows :Array) -> GdUnitFileAssert
