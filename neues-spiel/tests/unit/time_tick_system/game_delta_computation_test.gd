## Unit test — Time & Tick System Story tick-002 (game_delta computation
## formula, clamp precedence, raw-delta preservation; ADR-0002 primary,
## ADR-0001 secondary).
##
## Proves: (1) the canonical formula `game_delta = clamp(raw_delta, 0,
## max_raw_delta) * time_warp * (paused ? 0 : 1)` within 1e-6 tolerance,
## across all three time_warp options and the paused=true zeroing case
## (AC-1, TR-time-tick-system-021); (2) the clamp is applied to raw_delta
## BEFORE the warp multiply -- an alt-tab-stall-sized raw_delta never leaks
## through unclamped, and the max_raw_delta boundary itself is inclusive
## (AC-2, TR-time-tick-system-031); (3) the engine's own raw delta parameter
## is only read, never written back to, and game_delta is a separately
## stored, additionally exposed derived value (AC-3, TR-time-tick-system-026).
##
## Per the story's Test Evidence and the tick-001 precedent
## (`autoload_config_boot_test.gd`): `time_tick_system.gd` deliberately
## carries no `class_name` (it would hide the "TimeTickSystem" Autoload
## singleton -- a Godot 4.7 parse error), so isolated instances are
## constructed via a preloaded [GDScript] and duck-typed at each access site.
## All inputs below are fixed literals -- deterministic, no random seeds, no
## time-dependent assertions, no scene tree, no Autoload registration.
class_name GameDeltaComputationTest
extends GdUnitTestSuite

const TimeTickSystemScript: GDScript = preload("res://src/time_tick_system/time_tick_system.gd")

## Floating-point tolerance shared by every formula assertion below (story
## AC-1: "within floating-point tolerance 1e-6").
const TOLERANCE: float = 0.000001


## Returns a fresh, never-autoloaded TimeTickSystem-script instance, wired
## with a GDD-default [TimeTickConfig] and already through [code]setup()[/code]
## -- isolated from the registered Autoload and the scene tree entirely.
## Untyped return -- see class doc comment.
func _new_system() -> Object:
	var system: Object = TimeTickSystemScript.new()
	@warning_ignore("unsafe_property_access")
	system.config = TimeTickConfig.new()
	@warning_ignore("unsafe_method_access")
	system.setup()
	return system


# ---------------------------------------------------------------------------
# AC-1 — formula (worked example + time_warp options + paused zeroing)
# ---------------------------------------------------------------------------

func test_compute_game_delta_worked_example_matches_formula() -> void:
	# Arrange — GDD Formulas worked example: raw_delta=0.0167, time_warp=2,
	# paused=false -> game_delta=0.0334.
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_property_access")
	system.time_warp = 2
	@warning_ignore("unsafe_property_access")
	system.paused = false

	# Act
	@warning_ignore("unsafe_method_access")
	var game_delta: float = system.compute_game_delta(0.0167)

	# Assert
	assert_float(game_delta).is_equal_approx(0.0334, TOLERANCE)


func test_compute_game_delta_each_warp_option_scales_linearly() -> void:
	# Arrange — GDD Core Rule 2 / this story's AC-1 edge case: time_warp in
	# {1, 2, 3}, unpaused, no clamp in play (raw_delta well under
	# max_raw_delta).
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_property_access")
	system.paused = false
	var raw_delta: float = 0.02

	for warp: int in [1, 2, 3]:
		@warning_ignore("unsafe_property_access")
		system.time_warp = warp

		# Act
		@warning_ignore("unsafe_method_access")
		var game_delta: float = system.compute_game_delta(raw_delta)

		# Assert
		assert_float(game_delta).is_equal_approx(raw_delta * float(warp), TOLERANCE)


func test_compute_game_delta_paused_returns_exact_zero_same_frame() -> void:
	# Arrange — GDD Formulas worked example, same frame with paused=true ->
	# 0.0 exactly, regardless of the stored (non-discarded) time_warp value.
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_property_access")
	system.time_warp = 3
	@warning_ignore("unsafe_property_access")
	system.paused = true

	# Act
	@warning_ignore("unsafe_method_access")
	var game_delta: float = system.compute_game_delta(0.0167)

	# Assert
	assert_float(game_delta).is_zero()


# ---------------------------------------------------------------------------
# AC-2 — clamp precedence (clamp before warp multiply)
# ---------------------------------------------------------------------------

func test_compute_game_delta_raw_delta_exceeding_max_clamps_before_warp_multiply() -> void:
	# Arrange — GDD Edge Cases "alt-tab stall": raw_delta=12.3s, far beyond
	# the GDD-default max_raw_delta=0.1s. Expected result uses the CLAMPED
	# ceiling, never the raw 12.3 value, multiplied by time_warp afterward.
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_property_access")
	var max_raw_delta: float = system.config.max_raw_delta
	@warning_ignore("unsafe_property_access")
	system.time_warp = 3
	@warning_ignore("unsafe_property_access")
	system.paused = false

	# Act
	@warning_ignore("unsafe_method_access")
	var game_delta: float = system.compute_game_delta(12.3)

	# Assert — clamp-then-multiply, not multiply-then-clamp.
	assert_float(game_delta).is_equal_approx(max_raw_delta * 3.0, TOLERANCE)
	assert_float(game_delta).is_less(12.3 * 3.0)


func test_compute_game_delta_raw_delta_equal_max_raw_delta_boundary_is_unclamped() -> void:
	# Arrange — boundary case: raw_delta exactly equals max_raw_delta (clamp
	# ceiling is inclusive, per `clampf`).
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_property_access")
	var max_raw_delta: float = system.config.max_raw_delta
	@warning_ignore("unsafe_property_access")
	system.time_warp = 1
	@warning_ignore("unsafe_property_access")
	system.paused = false

	# Act
	@warning_ignore("unsafe_method_access")
	var game_delta: float = system.compute_game_delta(max_raw_delta)

	# Assert
	assert_float(game_delta).is_equal_approx(max_raw_delta, TOLERANCE)


func test_compute_game_delta_raw_delta_zero_returns_zero() -> void:
	# Arrange — boundary case: raw_delta=0 (lower clamp bound).
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_property_access")
	system.time_warp = 2
	@warning_ignore("unsafe_property_access")
	system.paused = false

	# Act
	@warning_ignore("unsafe_method_access")
	var game_delta: float = system.compute_game_delta(0.0)

	# Assert
	assert_float(game_delta).is_zero()


# ---------------------------------------------------------------------------
# AC-3 — raw engine delta preserved / game_delta is an additional exposed value
# ---------------------------------------------------------------------------

func test_physics_process_computes_game_delta_without_mutating_raw_delta_input() -> void:
	# Arrange — a local standing in for "the engine delta passed to other
	# nodes/systems this frame."
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_property_access")
	system.time_warp = 2
	@warning_ignore("unsafe_property_access")
	system.paused = false
	var raw_delta: float = 0.0167

	# Act
	@warning_ignore("unsafe_method_access")
	system._physics_process(raw_delta)

	# Assert — the raw_delta value is completely unmodified (no write-back),
	# while game_delta is a distinct, additionally-exposed derived value
	# (TR-time-tick-system-026).
	assert_float(raw_delta).is_equal_approx(0.0167, TOLERANCE)
	@warning_ignore("unsafe_method_access")
	assert_float(system.get_game_delta()).is_equal_approx(0.0334, TOLERANCE)


func test_get_game_delta_before_any_physics_frame_returns_zero() -> void:
	# Arrange + Act — a freshly set-up system, no _physics_process call yet.
	var system: Object = auto_free(_new_system())

	# Assert
	@warning_ignore("unsafe_method_access")
	assert_float(system.get_game_delta()).is_zero()
