## A tuple implementation for GdUnit4 test assertions and value extraction.
## @tutorial(GdUnit4 Array Assertions): https://mikeschulze.github.io/gdUnit4/latest/testing/assert-array/#extractv
## @tutorial(GdUnit4 Testing Framework): https://mikeschulze.github.io/gdUnit4/
## [br]
## The GdUnitTuple class is a utility container designed specifically for the GdUnit4
## testing framework. It enables advanced assertion operations, particularly when
## extracting and comparing multiple values from complex test results.
## [br]
## [b]Primary Use Cases in Testing:[/b] [br]
## - Extracting multiple properties from test objects with [method extractv]## [br]
## - Grouping related assertion values for comparison## [br]
## - Returning multiple values from test helper methods## [br]
## - Organizing expected vs actual value pairs in assertions## [br]
## [br]
## [b]Example Usage in Tests:[/b]
## [codeblock]
## func test_player_stats_after_level_up():
##     var player = Player.new()
##     player.level_up()
##
##     # Extract multiple properties using tuple
##     assert_array([player]) \
##         .extractv(extr("name"), extr("level"), extr("hp")) \
##         .contains(tuple("Hero", 2, 150))
##
## func test_enemy_spawn_positions():
##     var enemies: Array = spawn_enemies(3)
##
##     # Verify multiple enemies have correct position data
##     assert_array(enemies) \
##         .extractv(extr("position.x"), extr("position.y")) \
##         .contains_exactly([
##             tuple(100, 200),
##             tuple(150, 200),
##             tuple(200, 200)
##         ])
## [/codeblock]
## [br]
## [b]Integration with GdUnit4 Assertions:[/b] [br]
## Tuples work seamlessly with array assertion methods like: [br]
## - [code]contains()[/code] - Check if extracted values contain specific tuples [br]
## - [code]contains_exactly()[/code] - Verify exact tuple matches [br]
## - [code]is_equal()[/code] - Compare tuple equality [br]
## [br]
## [b]Note:[/b] This class is part of the GdUnit4 testing framework's internal
## utilities and is primarily intended for use within test assertions rather
## than production code.
class_name GdUnitTuple
extends RefCounted

var _values: Array = []


## Initializes a new GdUnitTuple with test values.
## [br]
## Creates a tuple to hold multiple values extracted from test objects
## or expected values for assertions. Commonly used with the [code]tuple()[/code]
## helper function in GdUnit4 tests.
## [br]
## [b]Parameters:[/b]
## - [code]...args[/code]: Variable number of values to store.
func _init(...args: Array) -> void:
	_values = args


## Returns the tuple's values as an array for assertion comparisons.
## [br]
## Provides access to the stored test values. Used internally by GdUnit4's
## assertion system when comparing tuples in test validations.
## [br]
## [b]Returns:[/b]
## An [Array] containing all values stored in the tuple.
func values() -> Array:
	return _values


## Returns a string representation for test output and debugging.
## [br]
## Formats the tuple for display in test results, error messages, and debug logs.
## This method is automatically called by GdUnit4 when displaying assertion
## failures involving tuples.
## [br]
## [b]Returns:[/b]
## A [String] in the format "tuple([value1, value2, ...])"
func _to_string() -> String:
	return "tuple(%s)" % str(_values)
