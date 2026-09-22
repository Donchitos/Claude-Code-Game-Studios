## An Assertion Tool to verify array values
@abstract class_name GdUnitArrayAssert
extends GdUnitAssert


## Verifies that the current value is null.
@abstract func is_null() -> GdUnitArrayAssert


## Verifies that the current value is not null.
@abstract func is_not_null() -> GdUnitArrayAssert


## Verifies that the current Array is equal to the given one.
@abstract func is_equal(...expected: Array) -> GdUnitArrayAssert


## Verifies that the current Array is equal to the given one, ignoring case considerations.
@abstract func is_equal_ignoring_case(...expected: Array) -> GdUnitArrayAssert


## Verifies that the current Array is not equal to the given one.
@abstract func is_not_equal(...expected: Array) -> GdUnitArrayAssert


## Verifies that the current Array is not equal to the given one, ignoring case considerations.
@abstract func is_not_equal_ignoring_case(...expected: Array) -> GdUnitArrayAssert


## Overrides the default failure message by given custom message.
@abstract func override_failure_message(message: String) -> GdUnitArrayAssert


## Appends a custom message to the failure message.
@abstract func append_failure_message(message: String) -> GdUnitArrayAssert


## Verifies that the current Array is empty, it has a size of 0.
@abstract func is_empty() -> GdUnitArrayAssert


## Verifies that the current Array is not empty, it has a size of minimum 1.
@abstract func is_not_empty() -> GdUnitArrayAssert


## Verifies that the current Array is the same. [br]
## Compares the current by object reference equals
@abstract func is_same(expected: Variant) -> GdUnitArrayAssert


## Verifies that the current Array is NOT the same. [br]
## Compares the current by object reference equals
@abstract func is_not_same(expected: Variant) -> GdUnitArrayAssert


## Verifies that the current Array has a size of given value.
@abstract func has_size(expectd: int) -> GdUnitArrayAssert


## Verifies that the current Array contains the given values, in any order.[br]
## The values are compared by deep parameter comparision, for object reference compare you have to use [method contains_same]
@abstract func contains(...expected: Array) -> GdUnitArrayAssert


## Verifies that the current Array contains exactly only the given values and nothing else, in same order.[br]
## The values are compared by deep parameter comparision, for object reference compare you have to use [method contains_same_exactly]
@abstract func contains_exactly(...expected: Array) -> GdUnitArrayAssert


## Verifies that the current Array contains exactly only the given values and nothing else, in any order.[br]
## The values are compared by deep parameter comparision, for object reference compare you have to use [method contains_same_exactly_in_any_order]
@abstract func contains_exactly_in_any_order(...expected: Array) -> GdUnitArrayAssert


## Verifies that the current Array contains the given values, in any order.[br]
## The values are compared by object reference, for deep parameter comparision use [method contains]
@abstract func contains_same(...expected: Array) -> GdUnitArrayAssert


## Verifies that the current Array contains exactly only the given values and nothing else, in same order.[br]
## The values are compared by object reference, for deep parameter comparision use [method contains_exactly]
@abstract func contains_same_exactly(...expected: Array) -> GdUnitArrayAssert


## Verifies that the current Array contains exactly only the given values and nothing else, in any order.[br]
## The values are compared by object reference, for deep parameter comparision use [method contains_exactly_in_any_order]
@abstract func contains_same_exactly_in_any_order(...expected: Array) -> GdUnitArrayAssert


## Verifies that the current Array do NOT contains the given values, in any order.[br]
## The values are compared by deep parameter comparision, for object reference compare you have to use [method not_contains_same]
## [b]Example:[/b]
## [codeblock]
## # will succeed
## assert_array([1, 2, 3, 4, 5]).not_contains(6)
## # will fail
## assert_array([1, 2, 3, 4, 5]).not_contains(2, 6)
## [/codeblock]
@abstract func not_contains(...expected: Array) -> GdUnitArrayAssert


## Verifies that the current Array do NOT contains the given values, in any order.[br]
## The values are compared by object reference, for deep parameter comparision use [method not_contains]
## [b]Example:[/b]
## [codeblock]
## # will succeed
## assert_array([1, 2, 3, 4, 5]).not_contains(6)
## # will fail
## assert_array([1, 2, 3, 4, 5]).not_contains(2, 6)
## [/codeblock]
@abstract func not_contains_same(...expected: Array) -> GdUnitArrayAssert


## Extracts all values by given function name and optional arguments into a new ArrayAssert.
## If the elements not accessible by `func_name` the value is converted to `"n.a"`, expecting null values
@abstract func extract(func_name: String, ...func_args: Array) -> GdUnitArrayAssert


## Extracts all values by given extractor's into a new ArrayAssert.
## If the elements not extractable than the value is converted to `"n.a"`, expecting null values
## -- The argument type is Array[GdUnitValueExtractor]
@abstract func extractv(...extractors: Array) -> GdUnitArrayAssert
