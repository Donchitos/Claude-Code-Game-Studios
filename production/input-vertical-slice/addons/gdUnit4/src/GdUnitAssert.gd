## Base interface of all GdUnit asserts
@abstract class_name GdUnitAssert
extends RefCounted


## Verifies that the current value is null.
@abstract func is_null() -> GdUnitAssert


## Verifies that the current value is not null.
@abstract func is_not_null() -> GdUnitAssert


## Verifies that the current value is equal to expected one.
@abstract func is_equal(expected: Variant) -> GdUnitAssert


## Verifies that the current value is not equal to expected one.
@abstract func is_not_equal(expected: Variant) -> GdUnitAssert


## Overrides the default failure message by given custom message.[br]
## This function allows you to replace the automatically generated failure message with a more specific
## or user-friendly message that better describes the test failure context.[br]
## Usage:
##     [codeblock]
##		# Override with custom context-specific message
##		func test_player_inventory():
##		    assert_that(player.get_item_count("sword"))\
##		        .override_failure_message("Player should have exactly one sword")\
##		        .is_equal(1)
##     [/codeblock]
@abstract func override_failure_message(message: String) -> GdUnitAssert


## Appends a custom message to the failure message.[br]
## This can be used to add additional information to the generated failure message
## while keeping the original assertion details for better debugging context.[br]
## Usage:
##     [codeblock]
##		# Add context to existing failure message
##		func test_player_health():
##		    assert_that(player.health)\
##		        .append_failure_message("Player was damaged by: %s" % last_damage_source)\
##		        .is_greater(0)
##     [/codeblock]
@abstract func append_failure_message(message: String) -> GdUnitAssert
