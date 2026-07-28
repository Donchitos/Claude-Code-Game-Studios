## Unit test — Time & Tick System Story tick-004 (drift-free tick
## accumulator + global [signal TimeTickSystem.tick] broadcast; ADR-0008
## primary, ADR-0002 secondary).
##
## Proves: (1) the accumulator fires a tick each time it crosses
## `tick_interval` via SUBTRACTION, never a reset to `0.0`, and the exact
## GDD Formulas worked example (`time_warp=2`, `0.2200 -> +0.0334 -> 0.2534
## -> tick fires -> -0.25 -> 0.0034 carries forward`) holds bit-for-bit
## (AC-1, GDD AC9, TR-time-tick-system-032); (2) over a 10,000+-tick corpus
## driven by a fixed ODD `raw_delta` (deliberately not aligned to
## `tick_interval`), the accumulated drift between total simulated time and
## `tick_count * tick_interval` stays under one `tick_interval` -- the
## subtract-not-reset guarantee holding at scale, not just for one crossing
## (AC-2, GDD AC23, TR-time-tick-system-032/034); (3) `time_warp = N` scales
## the fired tick rate linearly over a fixed span of simulated time (AC-3,
## GDD AC10, TR-time-tick-system-028); (4) zero ticks fire while paused,
## across many physics frames (AC-4, GDD AC13, TR-time-tick-system-029);
## (5) M independent subscribers each observe exactly the same single
## emission per tick -- one global broadcast, not per-consumer timers
## (AC-5, GDD AC22, TR-time-tick-system-007); (6) [method
## TimeTickSystem.set_warp] never modifies the banked accumulator value --
## the joint assertion story tick-003 deferred until this field existed
## (TR-time-tick-system-046).
##
## Also covers two structural properties implied by the GDD Formulas'
## `while` (not `if`) loop: the accumulator can fire more than one tick from
## a single physics frame when enough banked time is due, and the boundary
## condition (`accumulator == tick_interval` exactly) is inclusive.
##
## Per the tick-001/002/003 precedent (`autoload_config_boot_test.gd`,
## `game_delta_computation_test.gd`, `pause_warp_state_test.gd`):
## `time_tick_system.gd` deliberately carries no `class_name` (it would hide
## the "TimeTickSystem" Autoload singleton -- a Godot 4.7 parse error), so
## isolated instances are constructed via a preloaded [GDScript] and
## duck-typed at each access site.
##
## Signal-count assertions use a direct `.connect()` listener that APPENDS
## to a captured `Array`, never a reassigned captured scalar -- confirmed
## the hard way in this file's own first draft: a GDScript lambda closure
## over a reassigned captured `int` local does NOT write back to the outer
## scope (each call increments its own closed-over copy), so an outer
## `var tick_count: int = 0` incremented only from inside the lambda body
## never changes as observed from the test function itself. Only mutating a
## captured `Array`'s CONTENTS (`.append()`) is visible outer-scope, per
## `pause_warp_state_test.gd`'s documented finding, which this file
## originally mis-cited before hitting the bug directly. Every tick counter
## below is therefore `var some_name: Array = []` + `.append(true)` inside
## the lambda, read via `.size()`.
##
## Every input below is a fixed literal chosen so no floating-point rounding
## can flip an assertion near a tick boundary (powers-of-two fractions where
## exactness matters; a genuinely irrational-relative-to-0.25 fixed literal
## where the drift bound itself is the thing under test) -- deterministic,
## no random seeds, no time-dependent assertions, no scene tree, no Autoload
## registration.
class_name TickAccumulatorTest
extends GdUnitTestSuite

const TimeTickSystemScript: GDScript = preload("res://src/time_tick_system/time_tick_system.gd")

## Floating-point tolerance shared by the approx assertions below.
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
# AC-1 — subtract, not reset; the GDD Formulas worked example, bit-for-bit
# ---------------------------------------------------------------------------

func test_tick_accumulator_worked_example_fires_once_and_residue_carries_forward() -> void:
	# Arrange — GDD Formulas worked example: banking to 0.2200 first (no
	# tick due -- below the default tick_interval=0.25), matching the
	# example's starting accumulator value exactly.
	var system: Object = auto_free(_new_system())
	var ticks_fired: Array = []
	@warning_ignore("unsafe_property_access")
	system.tick.connect(func() -> void: ticks_fired.append(true))

	# Act 1 — bank 0.22 game-seconds at warp=1 (default boot warp), split
	# across three sub-`max_raw_delta` (0.1) steps -- a single raw_delta of
	# 0.22 in ONE call would itself get clamped to `max_raw_delta` (0.1s
	# default, TR-time-tick-system-031) before ever reaching the
	# accumulator, which is not what this test means to exercise. No tick
	# is due yet either way (0.22 < tick_interval=0.25).
	@warning_ignore("unsafe_method_access")
	system._physics_process(0.1)
	@warning_ignore("unsafe_method_access")
	system._physics_process(0.1)
	@warning_ignore("unsafe_method_access")
	system._physics_process(0.02)

	# Assert — still below tick_interval, no tick fired, residue == 0.22.
	assert_int(ticks_fired.size()).is_equal(0)
	@warning_ignore("unsafe_method_access")
	assert_float(system.get_tick_accumulator()).is_equal_approx(0.22, TOLERANCE)

	# Act 2 — GDD worked example: time_warp=2, raw_delta=0.0167 -> game_delta
	# +0.0334 -> accumulator 0.2534 -> crosses 0.25 -> fires once -> residue
	# 0.0034 carries forward (subtraction, not a reset to 0.0).
	@warning_ignore("unsafe_method_access")
	system.set_warp(2)
	@warning_ignore("unsafe_method_access")
	system._physics_process(0.0167)

	# Assert
	assert_int(ticks_fired.size()).is_equal(1)
	@warning_ignore("unsafe_method_access")
	assert_float(system.get_tick_accumulator()).is_equal_approx(0.0034, 0.0001)


func test_tick_accumulator_exact_boundary_fires_tick_with_zero_residue() -> void:
	# Arrange — accumulator lands EXACTLY on tick_interval (inclusive `>=`
	# boundary, GDD Formulas). Uses power-of-two-exact literals (0.0625,
	# 0.25) so the float arithmetic involved is exact -- no rounding risk
	# at the boundary itself.
	var system: Object = auto_free(_new_system())
	var ticks_fired: Array = []
	@warning_ignore("unsafe_property_access")
	system.tick.connect(func() -> void: ticks_fired.append(true))

	# Act — four steps of 0.0625 at warp=1 sum to exactly 0.25 == tick_interval.
	for i: int in range(4):
		@warning_ignore("unsafe_method_access")
		system._physics_process(0.0625)

	# Assert — exactly one tick fired, residue is exactly zero (not
	# negative, not a leftover fraction).
	assert_int(ticks_fired.size()).is_equal(1)
	@warning_ignore("unsafe_method_access")
	assert_float(system.get_tick_accumulator()).is_equal(0.0)


func test_tick_accumulator_single_frame_can_fire_multiple_ticks_via_while_loop() -> void:
	# Arrange — pre-bank 0.2 across two sub-`max_raw_delta` (0.1) steps (no
	# tick due -- a single raw_delta of 0.2 in ONE call would itself get
	# clamped to `max_raw_delta`, TR-time-tick-system-031, before reaching
	# the accumulator). Then a single physics frame at warp=3 with
	# raw_delta=0.1 (== max_raw_delta, so unclamped -- the clamp is
	# inclusive) banks another 0.3, landing the accumulator at 0.5 -- TWO
	# tick_interval (0.25) crossings in that ONE `_physics_process` call.
	# This is what the `while` (not `if`) in the GDD Formulas exists for.
	var system: Object = auto_free(_new_system())
	var ticks_fired: Array = []
	@warning_ignore("unsafe_property_access")
	system.tick.connect(func() -> void: ticks_fired.append(true))
	@warning_ignore("unsafe_method_access")
	system._physics_process(0.1)
	@warning_ignore("unsafe_method_access")
	system._physics_process(0.1)
	assert_int(ticks_fired.size()).is_equal(0)

	# Act
	@warning_ignore("unsafe_method_access")
	system.set_warp(3)
	@warning_ignore("unsafe_method_access")
	system._physics_process(0.1)

	# Assert — both due ticks fired in this one call; residue is 0.0
	# (0.2 + 0.3 = 0.5 = 2 * 0.25 exactly).
	assert_int(ticks_fired.size()).is_equal(2)
	@warning_ignore("unsafe_method_access")
	assert_float(system.get_tick_accumulator()).is_equal_approx(0.0, TOLERANCE)


# ---------------------------------------------------------------------------
# AC-2 — 10,000-tick drift bound at a fixed, deliberately-odd raw_delta
# (GDD AC23)
# ---------------------------------------------------------------------------

func test_tick_accumulator_10000_ticks_fixed_odd_delta_drift_under_one_interval() -> void:
	# Arrange — a fixed odd raw_delta that does NOT evenly divide the
	# default tick_interval (0.25), so tick boundaries never align neatly
	# with a physics step -- the drift-corpus pattern the GDD's "under one
	# tick_interval after 10,000 ticks" guarantee is meant to survive.
	var system: Object = auto_free(_new_system())
	var ticks_fired: Array = []
	@warning_ignore("unsafe_property_access")
	system.tick.connect(func() -> void: ticks_fired.append(true))
	@warning_ignore("unsafe_method_access")
	var tick_interval: float = system.get_tick_interval()
	const RAW_DELTA: float = 0.037
	var total_simulated_time: float = 0.0

	# Act — drive fixed-delta physics steps (warp=1, unclamped: 0.037 <
	# max_raw_delta) until at least 10,000 ticks have fired.
	while ticks_fired.size() < 10000:
		@warning_ignore("unsafe_method_access")
		system._physics_process(RAW_DELTA)
		total_simulated_time += RAW_DELTA

	# Assert — the subtract-not-reset accumulator never drifts the fired
	# tick count more than one tick_interval away from the true elapsed
	# simulated time (GDD AC23), and the residual accumulator itself always
	# stays within [0, tick_interval) by construction of the drain loop.
	var tick_count: int = ticks_fired.size()
	var drift: float = absf(total_simulated_time - (float(tick_count) * tick_interval))
	assert_int(tick_count).is_greater_equal(10000)
	assert_float(drift).is_less(tick_interval)
	@warning_ignore("unsafe_method_access")
	var residue: float = system.get_tick_accumulator()
	assert_float(residue).is_greater_equal(0.0)
	assert_float(residue).is_less(tick_interval)


# ---------------------------------------------------------------------------
# AC-3 — time_warp scales the fired tick rate linearly (GDD AC10)
# ---------------------------------------------------------------------------

func test_tick_accumulator_time_warp_scales_tick_rate_linearly() -> void:
	# Arrange — power-of-two-exact literals throughout (0.0625 raw_delta,
	# warp=2 -> 0.125 game_delta per step, tick_interval=0.25) so this test
	# has zero floating-point rounding risk at the tick-boundary comparisons.
	var system: Object = auto_free(_new_system())
	var ticks_fired: Array = []
	@warning_ignore("unsafe_property_access")
	system.tick.connect(func() -> void: ticks_fired.append(true))
	@warning_ignore("unsafe_method_access")
	system.set_warp(2)

	# Act — 16 steps of 0.0625 sum to exactly 1.0 simulated second; at
	# warp=2 that banks exactly 2.0 game-seconds.
	for i: int in range(16):
		@warning_ignore("unsafe_method_access")
		system._physics_process(0.0625)

	# Assert — ticks_per_second (4.0 default) x time_warp (2) = 8 ticks
	# fired over that one simulated second (GDD AC10 / Formulas worked
	# example rate).
	@warning_ignore("unsafe_property_access")
	var expected_ticks: int = int(system.config.ticks_per_second * 2.0)
	assert_int(expected_ticks).is_equal(8)
	assert_int(ticks_fired.size()).is_equal(expected_ticks)


# ---------------------------------------------------------------------------
# AC-4 — zero ticks fire while paused (GDD AC13)
# ---------------------------------------------------------------------------

func test_tick_accumulator_no_ticks_fire_while_paused() -> void:
	# Arrange
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_method_access")
	system.pause()
	var ticks_fired: Array = []
	@warning_ignore("unsafe_property_access")
	system.tick.connect(func() -> void: ticks_fired.append(true))

	# Act — many physics frames while paused; game_delta is 0.0 each frame
	# (TR-time-tick-system-021/029), so the accumulator never moves at all.
	for i: int in range(100):
		@warning_ignore("unsafe_method_access")
		system._physics_process(1.0 / 60.0)

	# Assert
	assert_int(ticks_fired.size()).is_equal(0)
	@warning_ignore("unsafe_method_access")
	assert_float(system.get_tick_accumulator()).is_zero()


# ---------------------------------------------------------------------------
# AC-5 — exactly ONE global broadcast per tick, shared by every subscriber
# (GDD AC22, TR-time-tick-system-007)
# ---------------------------------------------------------------------------

func test_tick_signal_fires_exactly_once_per_tick_for_all_subscribers() -> void:
	# Arrange — M=3 independent subscribers (spy listeners), simulating
	# multiple downstream systems sharing the one global broadcast -- no
	# per-consumer timers anywhere (TR-time-tick-system-007).
	var system: Object = auto_free(_new_system())
	var subscriber_a_receipts: Array = []
	var subscriber_b_receipts: Array = []
	var subscriber_c_receipts: Array = []
	@warning_ignore("unsafe_property_access")
	system.tick.connect(func() -> void: subscriber_a_receipts.append(true))
	@warning_ignore("unsafe_property_access")
	system.tick.connect(func() -> void: subscriber_b_receipts.append(true))
	@warning_ignore("unsafe_property_access")
	system.tick.connect(func() -> void: subscriber_c_receipts.append(true))

	# Act — four steps of 0.0625 at warp=1 (default) sum to exactly one
	# tick_interval (0.25) -- exactly one tick due.
	for i: int in range(4):
		@warning_ignore("unsafe_method_access")
		system._physics_process(0.0625)

	# Assert — exactly one tick fired, and every subscriber observed exactly
	# that one emission -- the same shared broadcast, not independent
	# per-listener timers.
	assert_int(subscriber_a_receipts.size()).is_equal(1)
	assert_int(subscriber_b_receipts.size()).is_equal(1)
	assert_int(subscriber_c_receipts.size()).is_equal(1)


# ---------------------------------------------------------------------------
# TR-time-tick-system-046 — a time_warp change never touches the banked
# accumulator (joint assertion deferred from story tick-003's test, per
# `pause_warp_state_test.gd`'s doc comment -- now assertable since the
# accumulator field exists)
# ---------------------------------------------------------------------------

func test_set_warp_never_touches_banked_tick_accumulator() -> void:
	# Arrange — bank some sub-tick residue at the default warp (1) first.
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_method_access")
	system._physics_process(0.05)
	@warning_ignore("unsafe_method_access")
	var accumulator_before: float = system.get_tick_accumulator()
	assert_float(accumulator_before).is_equal_approx(0.05, TOLERANCE)

	# Act — a time_warp change, on its own, with no physics frame in between.
	@warning_ignore("unsafe_method_access")
	system.set_warp(3)

	# Assert — the banked residue is byte-for-byte untouched by the warp
	# change itself; only a subsequent `_physics_process` call would move it.
	@warning_ignore("unsafe_method_access")
	assert_float(system.get_tick_accumulator()).is_equal_approx(accumulator_before, TOLERANCE)
