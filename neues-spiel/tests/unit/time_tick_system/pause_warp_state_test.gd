## Unit test — Time & Tick System Story tick-003 (pause & time-warp state
## mutation API: [method TimeTickSystem.pause], [method TimeTickSystem.resume],
## [method TimeTickSystem.set_warp]; ADR-0002 primary, ADR-0001 secondary).
##
## Proves: (1) a selected time-warp is validated against the config's
## `time_warp_options` set, rejecting values outside {1,2,3} (AC-1, GDD AC2,
## TR-time-tick-system-023); (2) enabling Pause zeroes `game_delta` without
## discarding the stored `time_warp`, and disabling resumes at that exact
## stored speed (AC-2, GDD AC3/AC4, TR-time-tick-system-024); (3) a warp
## change made while paused is stored but has no effect until resumed --
## pause survives the warp change and the warp change survives the pause
## (AC-3, GDD AC5/AC20, TR-time-tick-system-040); (4) requesting pause (or
## resume, or the same warp value) while already in that state is idempotent
## -- no state change and no duplicate [signal TimeTickSystem.time_state_changed]
## emission (AC-4, GDD AC19, TR-time-tick-system-045); (5) rapid successive
## pause/warp changes are each applied immediately and independently, with no
## debounce (AC-5, GDD AC16, TR-time-tick-system-039).
##
## AC-6 (GDD AC21, TR-time-tick-system-046 -- a `time_warp` change never
## touches the tick accumulator's banked value) is NOT asserted here: the
## accumulator is story tick-004's field and does not exist yet in
## `time_tick_system.gd` (this story's Out of Scope). That joint assertion
## belongs to tick-004's test once the accumulator lands; this story's
## [method TimeTickSystem.set_warp] doc comment already states the
## constraint it must uphold.
##
## Per the tick-001/tick-002 precedent (`autoload_config_boot_test.gd`,
## `game_delta_computation_test.gd`): `time_tick_system.gd` deliberately
## carries no `class_name` (it would hide the "TimeTickSystem" Autoload
## singleton -- a Godot 4.7 parse error), so isolated instances are
## constructed via a preloaded [GDScript] and duck-typed at each access site.
##
## Signal-count assertions use a direct `.connect()` listener that APPENDS to
## a captured `Array`, never a reassigned captured scalar (a GDScript lambda
## closure over a reassigned local scalar does not write back to the outer
## scope -- only mutating a captured Array's contents does; see
## `boot_sequencing_gate_test.gd`'s documented finding). All inputs below are
## fixed literals -- deterministic, no random seeds, no time-dependent
## assertions, no scene tree, no Autoload registration.
class_name PauseWarpStateTest
extends GdUnitTestSuite

const TimeTickSystemScript: GDScript = preload("res://src/time_tick_system/time_tick_system.gd")

## Floating-point tolerance shared by the resumed-game_delta assertions below.
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
# AC-1 — warp set validated against config.time_warp_options (GDD AC2)
# ---------------------------------------------------------------------------

func test_set_warp_valid_value_accepted_and_stored() -> void:
	# Arrange
	var system: Object = auto_free(_new_system())

	# Act
	@warning_ignore("unsafe_method_access")
	var accepted: bool = system.set_warp(2)

	# Assert
	assert_bool(accepted).is_true()
	@warning_ignore("unsafe_property_access")
	assert_int(system.time_warp).is_equal(2)


func test_set_warp_rejects_zero_and_leaves_time_warp_unchanged() -> void:
	# Arrange — QA Test Cases edge case: reject 0.
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_property_access")
	var original_warp: int = system.time_warp

	# Act
	@warning_ignore("unsafe_method_access")
	var accepted: bool = system.set_warp(0)

	# Assert
	assert_bool(accepted).is_false()
	@warning_ignore("unsafe_property_access")
	assert_int(system.time_warp).is_equal(original_warp)


func test_set_warp_rejects_four_and_leaves_time_warp_unchanged() -> void:
	# Arrange — QA Test Cases edge case: reject 4.
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_property_access")
	var original_warp: int = system.time_warp

	# Act
	@warning_ignore("unsafe_method_access")
	var accepted: bool = system.set_warp(4)

	# Assert
	assert_bool(accepted).is_false()
	@warning_ignore("unsafe_property_access")
	assert_int(system.time_warp).is_equal(original_warp)


func test_set_warp_rejected_value_does_not_emit_time_state_changed() -> void:
	# Arrange
	var system: Object = auto_free(_new_system())
	var emitted: Array = []
	@warning_ignore("unsafe_property_access")
	system.time_state_changed.connect(func(p: bool, w: int) -> void: emitted.append([p, w]))

	# Act
	@warning_ignore("unsafe_method_access")
	system.set_warp(0)
	@warning_ignore("unsafe_method_access")
	system.set_warp(4)

	# Assert — rejected values are a pure no-op, no side effect at all.
	assert_int(emitted.size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC-2 — pause stores warp; resume returns to the exact stored speed
# (GDD AC3, AC4)
# ---------------------------------------------------------------------------

func test_pause_sets_game_delta_zero_without_discarding_time_warp() -> void:
	# Arrange
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_method_access")
	system.set_warp(3)

	# Act
	@warning_ignore("unsafe_method_access")
	system.pause()

	# Assert — paused, but the stored warp survives untouched.
	@warning_ignore("unsafe_property_access")
	assert_bool(system.paused).is_true()
	@warning_ignore("unsafe_property_access")
	assert_int(system.time_warp).is_equal(3)
	@warning_ignore("unsafe_method_access")
	assert_float(system.compute_game_delta(0.0167)).is_zero()


func test_resume_restores_exact_stored_warp_speed_not_reset_to_one() -> void:
	# Arrange
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_method_access")
	system.set_warp(3)
	@warning_ignore("unsafe_method_access")
	system.pause()

	# Act
	@warning_ignore("unsafe_method_access")
	system.resume()

	# Assert — resumes at 3x, never reset to 1x.
	@warning_ignore("unsafe_property_access")
	assert_bool(system.paused).is_false()
	@warning_ignore("unsafe_property_access")
	assert_int(system.time_warp).is_equal(3)
	@warning_ignore("unsafe_method_access")
	assert_float(system.compute_game_delta(0.0167)).is_equal_approx(0.0167 * 3.0, TOLERANCE)


# ---------------------------------------------------------------------------
# AC-3 — warp change while paused: stored, no effect until resumed; pause
# survives the warp change and the warp change survives the pause
# (GDD AC5, AC20)
# ---------------------------------------------------------------------------

func test_warp_change_while_paused_is_stored_but_has_no_effect_until_resumed() -> void:
	# Arrange — paused at 3x (QA Test Case AC-3).
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_method_access")
	system.set_warp(3)
	@warning_ignore("unsafe_method_access")
	system.pause()

	# Act — change warp to 2x while still paused.
	@warning_ignore("unsafe_method_access")
	var accepted: bool = system.set_warp(2)

	# Assert — accepted and stored, but game_delta is still 0 (still paused).
	assert_bool(accepted).is_true()
	@warning_ignore("unsafe_property_access")
	assert_int(system.time_warp).is_equal(2)
	@warning_ignore("unsafe_property_access")
	assert_bool(system.paused).is_true()
	@warning_ignore("unsafe_method_access")
	assert_float(system.compute_game_delta(0.0167)).is_zero()

	# Act — unpause.
	@warning_ignore("unsafe_method_access")
	system.resume()

	# Assert — resumes at 2x: pause survived the warp change, the warp
	# change survived the pause.
	@warning_ignore("unsafe_property_access")
	assert_bool(system.paused).is_false()
	@warning_ignore("unsafe_property_access")
	assert_int(system.time_warp).is_equal(2)
	@warning_ignore("unsafe_method_access")
	assert_float(system.compute_game_delta(0.0167)).is_equal_approx(0.0167 * 2.0, TOLERANCE)


# ---------------------------------------------------------------------------
# AC-4 — idempotent pause/resume/warp: no state change, no duplicate
# signal emission (GDD AC19)
# ---------------------------------------------------------------------------

func test_pause_requested_twice_is_idempotent_no_duplicate_emission() -> void:
	# Arrange
	var system: Object = auto_free(_new_system())
	var emitted: Array = []
	@warning_ignore("unsafe_property_access")
	system.time_state_changed.connect(func(p: bool, w: int) -> void: emitted.append([p, w]))

	# Act — first pause actually changes state.
	@warning_ignore("unsafe_method_access")
	system.pause()

	# Assert
	assert_int(emitted.size()).is_equal(1)
	@warning_ignore("unsafe_property_access")
	assert_bool(system.paused).is_true()

	# Act — pause again while already paused.
	@warning_ignore("unsafe_method_access")
	system.pause()

	# Assert — no second emission, state unchanged.
	assert_int(emitted.size()).is_equal(1)
	@warning_ignore("unsafe_property_access")
	assert_bool(system.paused).is_true()


func test_resume_requested_while_already_running_is_idempotent_no_emission() -> void:
	# Arrange — default boot state is already unpaused.
	var system: Object = auto_free(_new_system())
	var emitted: Array = []
	@warning_ignore("unsafe_property_access")
	system.time_state_changed.connect(func(p: bool, w: int) -> void: emitted.append([p, w]))

	# Act
	@warning_ignore("unsafe_method_access")
	system.resume()

	# Assert — already running: no-op, no emission.
	assert_int(emitted.size()).is_equal(0)
	@warning_ignore("unsafe_property_access")
	assert_bool(system.paused).is_false()


func test_resume_requested_twice_after_pause_is_idempotent_no_duplicate_emission() -> void:
	# Arrange
	var system: Object = auto_free(_new_system())
	var emitted: Array = []
	@warning_ignore("unsafe_property_access")
	system.time_state_changed.connect(func(p: bool, w: int) -> void: emitted.append([p, w]))
	@warning_ignore("unsafe_method_access")
	system.pause()

	# Act — first resume actually changes state.
	@warning_ignore("unsafe_method_access")
	system.resume()

	# Assert
	assert_int(emitted.size()).is_equal(2)  # pause + resume

	# Act — resume again while already running.
	@warning_ignore("unsafe_method_access")
	system.resume()

	# Assert — no third emission.
	assert_int(emitted.size()).is_equal(2)
	@warning_ignore("unsafe_property_access")
	assert_bool(system.paused).is_false()


func test_set_warp_same_value_is_idempotent_no_duplicate_emission() -> void:
	# Arrange
	var system: Object = auto_free(_new_system())
	var emitted: Array = []
	@warning_ignore("unsafe_property_access")
	system.time_state_changed.connect(func(p: bool, w: int) -> void: emitted.append([p, w]))

	# Act — setting the already-current default value (1) is a no-op.
	@warning_ignore("unsafe_method_access")
	var accepted_noop: bool = system.set_warp(1)

	# Assert
	assert_bool(accepted_noop).is_true()
	assert_int(emitted.size()).is_equal(0)

	# Act — an actual change fires once.
	@warning_ignore("unsafe_method_access")
	system.set_warp(2)

	# Assert
	assert_int(emitted.size()).is_equal(1)

	# Act — requesting the same value again is idempotent.
	@warning_ignore("unsafe_method_access")
	var accepted_repeat: bool = system.set_warp(2)

	# Assert — no second emission.
	assert_bool(accepted_repeat).is_true()
	assert_int(emitted.size()).is_equal(1)


# ---------------------------------------------------------------------------
# AC-5 — rapid successive toggles, each applied immediately/independently,
# no debounce (GDD AC16)
# ---------------------------------------------------------------------------

func test_rapid_successive_pause_resume_toggles_each_applied_independently() -> void:
	# Arrange
	var system: Object = auto_free(_new_system())
	var history: Array = []
	@warning_ignore("unsafe_property_access")
	system.time_state_changed.connect(func(p: bool, w: int) -> void: history.append(p))

	# Act — five toggles in immediate succession, no delay of any kind.
	@warning_ignore("unsafe_method_access")
	system.pause()
	@warning_ignore("unsafe_method_access")
	system.resume()
	@warning_ignore("unsafe_method_access")
	system.pause()
	@warning_ignore("unsafe_method_access")
	system.resume()
	@warning_ignore("unsafe_method_access")
	system.pause()

	# Assert — every toggle applied and observed, in order, none dropped.
	assert_array(history).is_equal([true, false, true, false, true])
	@warning_ignore("unsafe_property_access")
	assert_bool(system.paused).is_true()


func test_rapid_successive_warp_changes_each_applied_independently() -> void:
	# Arrange
	var system: Object = auto_free(_new_system())
	var history: Array = []
	@warning_ignore("unsafe_property_access")
	system.time_state_changed.connect(func(p: bool, w: int) -> void: history.append(w))

	# Act — four warp changes in immediate succession.
	@warning_ignore("unsafe_method_access")
	system.set_warp(2)
	@warning_ignore("unsafe_method_access")
	system.set_warp(3)
	@warning_ignore("unsafe_method_access")
	system.set_warp(1)
	@warning_ignore("unsafe_method_access")
	system.set_warp(2)

	# Assert — every change applied and observed, in order, none dropped.
	assert_array(history).is_equal([2, 3, 1, 2])
	@warning_ignore("unsafe_property_access")
	assert_int(system.time_warp).is_equal(2)
