## An Assertion Tool to verify for emitted signals until a waiting time
@abstract class_name GdUnitSignalAssert
extends GdUnitAssert


## Verifies that the current value is null.
@abstract func is_null() -> GdUnitSignalAssert


## Verifies that the current value is not null.
@abstract func is_not_null() -> GdUnitSignalAssert


## Verifies that the current value is equal to the given one.
@abstract func is_equal(expected: Variant) -> GdUnitSignalAssert


## Verifies that the current value is not equal to expected one.
@abstract func is_not_equal(expected: Variant) -> GdUnitSignalAssert


## Overrides the default failure message by given custom message.
@abstract func override_failure_message(message: String) -> GdUnitSignalAssert


## Appends a custom message to the failure message.
@abstract func append_failure_message(message: String) -> GdUnitSignalAssert


## Verifies that the specified signal is emitted with the expected arguments.[br]
##
## This assertion waits for a signal to be emitted from the object under test and
## validates that it was emitted with the correct arguments. The function supports
## both typed signals (Signal type) and string-based signal names for flexibility
## in different testing scenarios.[br]
## [br]
## [b]Parameters:[/b][br]
## [param signal_name]: The signal to monitor. Can be either:[br]
##   • A [Signal] reference (recommended for type safety)[br]
##   • A [String] with the signal name
## [param signal_args]: Optional expected signal arguments.[br]
##   When provided, verifies the signal was emitted with exactly these values.[br]
## [br]
## [b]Returns:[/b][br]
## [GdUnitSignalAssert] - Returns self for method chaining.[br]
## [br]
## [b]Examples:[/b]
## [codeblock]
## signal signal_a(value: int)
## signal signal_b(name: String, count: int)
##
## # Wait for signal emission without checking arguments
## # Using Signal reference (type-safe)
## await assert_signal(instance).is_emitted(signal_a)
## # Using string name (dynamic)
## await assert_signal(instance).is_emitted("signal_a")
##
## # Wait for signal emission with specific argument
## await assert_signal(instance).is_emitted(signal_a, 10)
##
## # Wait for signal with multiple arguments
## await assert_signal(instance).is_emitted(signal_b, "test", 42)
##
## # Wait max 500ms for signal with argument 10
## await assert_signal(instance).wait_until(500).is_emitted(signal_a, 10)
## [/codeblock]
## [br]
## [b]Note:[/b] This is an async operation - use [code]await[/code] when calling.[br]
## The assertion fails if the signal is not emitted within the timeout period.
@abstract func is_emitted(signal_name: Variant, ...signal_args: Array) -> GdUnitSignalAssert


## Verifies that the specified signal is NOT emitted with the expected arguments.[br]
##
## This assertion waits for a specified time period and validates that a signal
## was not emitted with the given arguments. Useful for ensuring certain conditions
## don't trigger unwanted signals or for verifying signal filtering logic.[br]
## [br]
## [b]Parameters:[/b][br]
## [param signal_name]: The signal to monitor. Can be either:[br]
##   • A [Signal] reference (recommended for type safety)[br]
##   • A [String] with the signal name
## [param signal_args]: Optional expected signal arguments.[br]
##   When provided, verifies the signal was not emitted with these specific values.[br]
##   If omitted, verifies the signal was not emitted at all.[br]
## [br]
## [b]Returns:[/b][br]
## [GdUnitSignalAssert] - Returns self for method chaining.[br]
## [br]
## [b]Examples:[/b]
## [codeblock]
## signal signal_a(value: int)
## signal signal_b(name: String, count: int)
##
## # Verify signal is not emitted at all (without checking arguments)
## await assert_signal(instance).wait_until(500).is_not_emitted(signal_a)
## await assert_signal(instance).wait_until(500).is_not_emitted("signal_a")
##
## # Verify signal is not emitted with specific argument
## await assert_signal(instance).wait_until(500).is_not_emitted(signal_a, 10)
##
## # Verify signal is not emitted with multiple arguments
## await assert_signal(instance).wait_until(500).is_not_emitted(signal_b, "test", 42)
##
## # Can be emitted with different arguments (this passes)
## instance.emit_signal("signal_a", 20)  # Emits with 20, not 10
## await assert_signal(instance).wait_until(500).is_not_emitted(signal_a, 10)
## [/codeblock]
## [br]
## [b]Note:[/b] This is an async operation - use [code]await[/code] when calling.[br]
## The assertion fails if the signal IS emitted with the specified arguments within the timeout period.
@abstract func is_not_emitted(signal_name: Variant, ...signal_args: Array) -> GdUnitSignalAssert


## Verifies that the specified signal exists on the emitter object.[br]
##
## This assertion checks if a signal is defined on the object under test,
## regardless of whether it has been emitted. Useful for validating that
## objects have the expected signals before testing their emission.[br]
## [br]
## [b]Parameters:[/b][br]
## [param signal_name]: The signal to check. Can be either:[br]
##   • A [Signal] reference (recommended for type safety)[br]
##   • A [String] with the signal name
## [br]
## [b]Returns:[/b][br]
## [GdUnitSignalAssert] - Returns self for method chaining.[br]
## [br]
## [b]Examples:[/b]
## [codeblock]
## signal my_signal(value: int)
## signal another_signal()
##
## # Verify signal exists using Signal reference
## assert_signal(instance).is_signal_exists(my_signal)
##
## # Verify signal exists using string name
## assert_signal(instance).is_signal_exists("my_signal")
##
## # Chain with other assertions
## assert_signal(instance) \
##     .is_signal_exists(my_signal) \
##     .is_emitted(my_signal, 42)
##
## [/codeblock]
## [br]
## [b]Note:[/b] This only checks signal definition, not emission.[br]
## The assertion fails if the signal is not defined on the object.
@abstract func is_signal_exists(signal_name: Variant) -> GdUnitSignalAssert


## Sets the assert signal timeout in ms, if the time over a failure is reported.[br]
## Example:
## [codeblock]
## do wait until 5s the instance has emitted the signal `signal_a`[br]
## assert_signal(instance).wait_until(5000).is_emitted("signal_a")
## [/codeblock]
@abstract func wait_until(timeout: int) -> GdUnitSignalAssert
