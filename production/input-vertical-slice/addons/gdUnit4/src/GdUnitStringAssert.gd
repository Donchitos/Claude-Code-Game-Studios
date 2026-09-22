## An Assertion Tool to verify String values
@abstract class_name GdUnitStringAssert
extends GdUnitAssert


## Verifies that the current value is null.
@abstract func is_null() -> GdUnitStringAssert


## Verifies that the current value is not null.
@abstract func is_not_null() -> GdUnitStringAssert


## Verifies that the current value is equal to the given one.
@abstract func is_equal(expected: Variant) -> GdUnitStringAssert


## Verifies that the current String is equal to the given one, ignoring case considerations.
@abstract func is_equal_ignoring_case(expected: Variant) -> GdUnitStringAssert


## Verifies that the current value is not equal to expected one.
@abstract func is_not_equal(expected: Variant) -> GdUnitStringAssert


## Verifies that the current String is not equal to the given one, ignoring case considerations.
@abstract func is_not_equal_ignoring_case(expected: Variant) -> GdUnitStringAssert


## Overrides the default failure message by given custom message.
@abstract func override_failure_message(message: String) -> GdUnitStringAssert


## Appends a custom message to the failure message.
@abstract func append_failure_message(message: String) -> GdUnitStringAssert


## Verifies that the current String is empty, it has a length of 0.
@abstract func is_empty() -> GdUnitStringAssert


## Verifies that the current String is not empty, it has a length of minimum 1.
@abstract func is_not_empty() -> GdUnitStringAssert


## Verifies that the current String contains the given String.
@abstract func contains(expected: String) -> GdUnitStringAssert


## Verifies that the current String does not contain the given String.
@abstract func not_contains(expected: String) -> GdUnitStringAssert


## Verifies that the current String does not contain the given String, ignoring case considerations.
@abstract func contains_ignoring_case(expected: String) -> GdUnitStringAssert


## Verifies that the current String does not contain the given String, ignoring case considerations.
@abstract func not_contains_ignoring_case(expected: String) -> GdUnitStringAssert


## Verifies that the current String starts with the given prefix.
@abstract func starts_with(expected: String) -> GdUnitStringAssert


## Verifies that the current String ends with the given suffix.
@abstract func ends_with(expected: String) -> GdUnitStringAssert


## Verifies that the current String has the expected length by used comparator.
@abstract func has_length(length: int, comparator: int = Comparator.EQUAL) -> GdUnitStringAssert
