## An Assertion Tool to verify dictionary
@abstract class_name GdUnitDictionaryAssert
extends GdUnitAssert


## Verifies that the current value is null.
@abstract func is_null() -> GdUnitDictionaryAssert


## Verifies that the current value is not null.
@abstract func is_not_null() -> GdUnitDictionaryAssert


## Verifies that the current dictionary is equal to the given one, ignoring order.
@abstract func is_equal(expected: Variant) -> GdUnitDictionaryAssert


## Verifies that the current dictionary is not equal to the given one, ignoring order.
@abstract func is_not_equal(expected: Variant) -> GdUnitDictionaryAssert


## Overrides the default failure message by given custom message.
@abstract func override_failure_message(message: String) -> GdUnitDictionaryAssert


## Appends a custom message to the failure message.
@abstract func append_failure_message(message: String) -> GdUnitDictionaryAssert


## Verifies that the current dictionary is empty, it has a size of 0.
@abstract func is_empty() -> GdUnitDictionaryAssert


## Verifies that the current dictionary is not empty, it has a size of minimum 1.
@abstract func is_not_empty() -> GdUnitDictionaryAssert


## Verifies that the current dictionary is the same. [br]
## Compares the current by object reference equals
@abstract func is_same(expected: Variant) -> GdUnitDictionaryAssert


## Verifies that the current dictionary is NOT the same. [br]
## Compares the current by object reference equals
@abstract func is_not_same(expected: Variant) -> GdUnitDictionaryAssert


## Verifies that the current dictionary has a size of given value.
@abstract func has_size(expected: int) -> GdUnitDictionaryAssert


## Verifies that the current dictionary contains the given key(s).[br]
## The keys are compared by deep parameter comparision, for object reference compare you have to use [method contains_same_keys]
@abstract func contains_keys(...expected: Array) -> GdUnitDictionaryAssert


## Verifies that the current dictionary contains the given key and value.[br]
## The key and value are compared by deep parameter comparision, for object reference compare you have to use [method contains_same_key_value]
@abstract func contains_key_value(key: Variant, value: Variant) -> GdUnitDictionaryAssert


## Verifies that the current dictionary not contains the given key(s).[br]
## The keys are compared by deep parameter comparision, for object reference compare you have to use [method not_contains_same_keys]
@abstract func not_contains_keys(...expected: Array) -> GdUnitDictionaryAssert


## Verifies that the current dictionary contains the given key(s).[br]
## The keys are compared by object reference, for deep parameter comparision use [method contains_keys]
@abstract func contains_same_keys(expected: Array) -> GdUnitDictionaryAssert


## Verifies that the current dictionary contains the given key and value.[br]
## The key and value are compared by object reference, for deep parameter comparision use [method contains_key_value]
@abstract func contains_same_key_value(key: Variant, value: Variant) -> GdUnitDictionaryAssert


## Verifies that the current dictionary not contains the given key(s).
## The keys are compared by object reference, for deep parameter comparision use [method not_contains_keys]
@abstract func not_contains_same_keys(...expected: Array) -> GdUnitDictionaryAssert
