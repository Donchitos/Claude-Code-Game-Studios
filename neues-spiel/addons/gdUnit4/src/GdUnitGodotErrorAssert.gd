## An assertion tool to verify for Godot runtime errors like assert() and push notifications like push_error().
@abstract class_name GdUnitGodotErrorAssert
extends GdUnitAssert


## Verifies that the current value is null.
@abstract func is_null() -> GdUnitGodotErrorAssert


## Verifies that the current value is not null.
@abstract func is_not_null() -> GdUnitGodotErrorAssert


## Verifies that the current value is equal to the given one.
@abstract func is_equal(expected: Variant) -> GdUnitGodotErrorAssert


## Verifies that the current value is not equal to expected one.
@abstract func is_not_equal(expected: Variant) -> GdUnitGodotErrorAssert


## Overrides the default failure message by given custom message.
@abstract func override_failure_message(message: String) -> GdUnitGodotErrorAssert


## Appends a custom message to the failure message.
@abstract func append_failure_message(message: String) -> GdUnitGodotErrorAssert


## Verifies if the executed code runs without any runtime errors
## Usage:
##     [codeblock]
##		await assert_error(<callable>).is_success()
##     [/codeblock]
@abstract func is_success() -> GdUnitGodotErrorAssert


## Verifies if the executed code runs into a runtime error
## Usage:
##     [codeblock]
##		await assert_error(<callable>).is_runtime_error(<expected error message>)
##     [/codeblock]
@abstract func is_runtime_error(expected_error: Variant) -> GdUnitGodotErrorAssert


## Verifies if the executed code has a push_warning() used
## Usage:
##     [codeblock]
##		await assert_error(<callable>).is_push_warning(<expected push warning message>)
##     [/codeblock]
@abstract func is_push_warning(expected_warning: Variant) -> GdUnitGodotErrorAssert


## Verifies if the executed code has a push_error() used
## Usage:
##     [codeblock]
##		await assert_error(<callable>).is_push_error(<expected push error message>)
##     [/codeblock]
@abstract func is_push_error(expected_error: Variant) -> GdUnitGodotErrorAssert
