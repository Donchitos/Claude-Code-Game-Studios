## Integration test — Needs & Mood System story needs-mood-001 (config
## resource, DI scaffold, fixed need schema, BLOCKING ladder invariant;
## ADR-0002 primary, ADR-0001/0005 secondary; TD ruling NM-3 —
## `production/architecture-decisions-m02-preflight-2026-07-26.md`; CD
## Ruling 1 — `production/creative-decisions-m02-preflight-2026-07-26.md`).
##
## Proves:
## 1. [NeedsMoodConfig] exports exactly the 10 Tuning Knobs this story's AC
##    list names, each at its GDD default, stored as a `.tres`.
## 2. `validate()` range-checks every single-value knob against its GDD safe
##    range — an out-of-range value warns + clamps + proceeds, never halts;
##    both boundaries are inclusive.
## 3. AC29 (BLOCKING): `ground_penalty >= unsheltered_bed_multiplier` OR
##    `unsheltered_bed_multiplier >= 1.0` fails loudly, naming the invariant;
##    the GDD defaults produce no BLOCKING issue; a BLOCKING issue mixed with
##    ordinary clamp warnings still dominates.
## 4. The need schema is fixed: [NeedsMood.Need] contains exactly SLEEP/
##    FOOD/COMPANY; [NeedsMood.ACTIVE_NEEDS] contains only SLEEP.
## 5. [NeedsMood] is instantiable headless via `Node.new()` with mocks
##    assigned directly (no scene tree, no Autoload registration); `setup()`
##    asserts `config`/a TimeTickSystem-shaped dependency are wired; a
##    BLOCKING config still completes `setup()` without throwing, recording
##    the issue for `GameWorld`'s boot gate instead (never a second halt
##    mechanism).
## 6. Tick subscription: a mocked tick source dispatched once runs the
##    F-pass entry point exactly once, in strict F1 -> F2 -> F3 order.
## 7. This plan's shipped-value literal regression assertion
##    (`production/qa/qa-plan-sprint-9-2026-07-26.md` Content Requirement 4):
##    the shipped `.tres` default ships `decay_per_tick_sleep`/
##    `base_recovery_per_tick_sleep`/`mood_smoothing_ticks` at EXACTLY
##    0.07 / 0.5 / 40.0 — a silent in-range retune must fail this assertion,
##    distinct from the ordinary range checks and from AC29's ladder check.
class_name NeedsMoodConfigAndScaffoldTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Config defaults, .tres backing
# ---------------------------------------------------------------------------

func test_config_defaults_match_gdd_tuning_knobs() -> void:
	# Arrange + Act
	var config := NeedsMoodConfig.new()

	# Assert — design/gdd/needs-mood-system.md Tuning Knobs.
	assert_float(config.decay_per_tick_sleep).is_equal_approx(0.07, 0.0001)
	assert_float(config.base_recovery_per_tick_sleep).is_equal_approx(0.5, 0.0001)
	assert_float(config.ground_penalty).is_equal_approx(0.4, 0.0001)
	assert_float(config.unsheltered_bed_multiplier).is_equal_approx(0.7, 0.0001)
	assert_float(config.urgency_threshold).is_equal_approx(25.0, 0.0001)
	assert_float(config.satisfied_threshold).is_equal_approx(95.0, 0.0001)
	assert_float(config.mood_smoothing_ticks).is_equal_approx(40.0, 0.0001)
	assert_float(config.mood_band_happy).is_equal_approx(70.0, 0.0001)
	assert_float(config.mood_band_content).is_equal_approx(40.0, 0.0001)
	assert_float(config.band_display_hysteresis).is_equal_approx(0.0, 0.0001)

	# Every knob at its GDD default produces zero issues (edge case named in
	# the story's own QA Test Cases).
	assert_array(config.validate()).is_empty()


func test_needs_mood_config_tres_loads_and_matches_script_defaults() -> void:
	# Arrange + Act — proves the "stored as a .tres" requirement against the
	# actual authored resource file, not just the script's own initializers.
	var config: NeedsMoodConfig = load("res://data/config/needs_mood_config.tres")

	# Assert
	assert_object(config).is_not_null()
	assert_float(config.decay_per_tick_sleep).is_equal_approx(0.07, 0.0001)
	assert_float(config.base_recovery_per_tick_sleep).is_equal_approx(0.5, 0.0001)
	assert_float(config.mood_smoothing_ticks).is_equal_approx(40.0, 0.0001)


## Content Requirement 4 (QA plan) — distinct from the defaults test above:
## a literal equality check against a silent in-range retune, not a range
## check and not the AC29 ladder check. If Ruling 1 is ever ratified-
## reversed, this assertion is updated in the SAME commit that changes the
## `.tres` defaults.
func test_shipped_tres_ships_cd_ruling_1_pacing_values_literally() -> void:
	# Arrange + Act
	var config: NeedsMoodConfig = load("res://data/config/needs_mood_config.tres")

	# Assert — exact literal values, not "somewhere in the safe range".
	assert_float(config.decay_per_tick_sleep).is_equal_approx(0.07, 0.0001)
	assert_float(config.base_recovery_per_tick_sleep).is_equal_approx(0.5, 0.0001)
	assert_float(config.mood_smoothing_ticks).is_equal_approx(40.0, 0.0001)


# ---------------------------------------------------------------------------
# AC29 — the BLOCKING ladder invariant
# ---------------------------------------------------------------------------

func test_validate_ac29_ground_penalty_equal_unsheltered_bed_multiplier_is_blocking() -> void:
	# Arrange — both values are individually within their own safe ranges,
	# isolating the ladder-ordering failure from any single-field clamp.
	var config := NeedsMoodConfig.new()
	config.ground_penalty = 0.7
	config.unsheltered_bed_multiplier = 0.7

	# Act
	var issues: Array[String] = config.validate()

	# Assert — exactly one BLOCKING issue, naming the invariant.
	assert_int(issues.size()).is_equal(1)
	assert_bool(issues[0].begins_with(ConfigResource.BLOCKING_PREFIX)).is_true()
	assert_bool(issues[0].contains("ground_penalty")).is_true()
	assert_bool(issues[0].contains("unsheltered_bed_multiplier")).is_true()
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_validate_ac29_unsheltered_bed_multiplier_equal_one_is_blocking() -> void:
	# Arrange
	var config := NeedsMoodConfig.new()
	config.unsheltered_bed_multiplier = 1.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert — the same BLOCKING outcome (AC29's own second QA Test Case).
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_validate_ac29_gdd_defaults_produce_no_blocking_issue() -> void:
	# Arrange — ground_penalty = 0.4, unsheltered_bed_multiplier = 0.7 (GDD
	# defaults, AC29's own third QA Test Case).
	var config := NeedsMoodConfig.new()

	# Act + Assert
	assert_bool(ConfigResource.has_blocking_issue(config.validate())).is_false()


func test_validate_ac29_blocking_mixed_with_clamp_warnings_still_dominates() -> void:
	# Arrange — a BLOCKING invariant failure alongside an unrelated
	# single-field clamp warning; has_blocking_issue() must still read true.
	var config := NeedsMoodConfig.new()
	config.ground_penalty = 0.7
	config.unsheltered_bed_multiplier = 0.7
	config.decay_per_tick_sleep = 0.5

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(2)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_needs_mood_setup_records_blocking_issue_for_boot_gate_without_asserting() -> void:
	# Arrange — a BLOCKING config invariant must be RECORDED for GameWorld's
	# boot gate (ADR-0005), not thrown as an assertion inside setup() itself
	# (AC29 edge case: "setup() on a blocking config does not proceed to
	# normal operation" is enforced by GameWorld's boot gate, not by a second
	# halt mechanism here).
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	var config := NeedsMoodConfig.new()
	config.ground_penalty = 0.7
	config.unsheltered_bed_multiplier = 0.7
	needs_mood.config = config
	needs_mood.time_tick_system = auto_free(MockTimeTickSystem.new())

	# Act
	needs_mood.setup()

	# Assert — setup() itself completed (no thrown assertion); the BLOCKING
	# issue is queryable via get_boot_blocking_issues().
	assert_bool(needs_mood.is_set_up()).is_true()
	var blocking: Array[String] = needs_mood.get_boot_blocking_issues()
	assert_int(blocking.size()).is_equal(1)
	assert_bool(blocking[0].begins_with(ConfigResource.BLOCKING_PREFIX)).is_true()


# ---------------------------------------------------------------------------
# Single-field range checks — the six knobs independent of the AC29 ladder
# ---------------------------------------------------------------------------

## One row per independent single-field knob: [field name, min, max, below, above].
const KNOB_CASES: Array[Array] = [
	["decay_per_tick_sleep", NeedsMoodConfig.DECAY_PER_TICK_SLEEP_MIN, NeedsMoodConfig.DECAY_PER_TICK_SLEEP_MAX, 0.01, 0.3],
	["base_recovery_per_tick_sleep", NeedsMoodConfig.BASE_RECOVERY_PER_TICK_SLEEP_MIN, NeedsMoodConfig.BASE_RECOVERY_PER_TICK_SLEEP_MAX, 0.05, 3.0],
	["urgency_threshold", NeedsMoodConfig.URGENCY_THRESHOLD_MIN, NeedsMoodConfig.URGENCY_THRESHOLD_MAX, 5.0, 50.0],
	["satisfied_threshold", NeedsMoodConfig.SATISFIED_THRESHOLD_MIN, NeedsMoodConfig.SATISFIED_THRESHOLD_MAX, 70.0, 110.0],
	["mood_smoothing_ticks", NeedsMoodConfig.MOOD_SMOOTHING_TICKS_MIN, NeedsMoodConfig.MOOD_SMOOTHING_TICKS_MAX, 5.0, 150.0],
	["band_display_hysteresis", NeedsMoodConfig.BAND_DISPLAY_HYSTERESIS_MIN, NeedsMoodConfig.BAND_DISPLAY_HYSTERESIS_MAX, -1.0, 5.0],
]


func test_validate_every_independent_knob_below_min_clamps_and_warns() -> void:
	for case: Array in KNOB_CASES:
		var field: String = case[0]
		var min_value: float = case[1]
		var below_value: float = case[3]

		var config := NeedsMoodConfig.new()
		config.set(field, below_value)

		var issues: Array[String] = config.validate()

		assert_int(issues.size()).is_equal(1).override_failure_message(
			"field '%s': expected exactly 1 issue, got %s" % [field, issues]
		)
		assert_float(config.get(field)).is_equal_approx(min_value, 0.0001).override_failure_message(
			"field '%s': expected clamp to %s, got %s" % [field, min_value, config.get(field)]
		)


func test_validate_every_independent_knob_above_max_clamps_and_warns() -> void:
	for case: Array in KNOB_CASES:
		var field: String = case[0]
		var max_value: float = case[2]
		var above_value: float = case[4]

		var config := NeedsMoodConfig.new()
		config.set(field, above_value)

		var issues: Array[String] = config.validate()

		assert_int(issues.size()).is_equal(1).override_failure_message(
			"field '%s': expected exactly 1 issue, got %s" % [field, issues]
		)
		assert_float(config.get(field)).is_equal_approx(max_value, 0.0001).override_failure_message(
			"field '%s': expected clamp to %s, got %s" % [field, max_value, config.get(field)]
		)


func test_validate_every_independent_knob_at_min_boundary_is_inclusive_no_warning() -> void:
	for case: Array in KNOB_CASES:
		var field: String = case[0]
		var min_value: float = case[1]

		var config := NeedsMoodConfig.new()
		config.set(field, min_value)

		var issues: Array[String] = config.validate()

		assert_array(issues).is_empty().override_failure_message(
			"field '%s' at min boundary %s produced issues: %s" % [field, min_value, issues]
		)


func test_validate_every_independent_knob_at_max_boundary_is_inclusive_no_warning() -> void:
	for case: Array in KNOB_CASES:
		var field: String = case[0]
		var max_value: float = case[2]

		var config := NeedsMoodConfig.new()
		config.set(field, max_value)

		var issues: Array[String] = config.validate()

		assert_array(issues).is_empty().override_failure_message(
			"field '%s' at max boundary %s produced issues: %s" % [field, max_value, issues]
		)


# ---------------------------------------------------------------------------
# ground_penalty / unsheltered_bed_multiplier — single-field range, kept
# independent of the AC29 ladder by choosing values that do not also trip it
# ---------------------------------------------------------------------------

func test_validate_ground_penalty_below_min_clamps_and_no_blocking() -> void:
	# Arrange — default unsheltered_bed_multiplier (0.7) keeps the ladder
	# holding (0.05 < 0.7 < 1.0) so only the ordinary clamp warning fires.
	var config := NeedsMoodConfig.new()
	config.ground_penalty = 0.05

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_float(config.ground_penalty).is_equal_approx(NeedsMoodConfig.GROUND_PENALTY_MIN, 0.0001)


func test_validate_ground_penalty_above_max_clamps_and_no_blocking() -> void:
	# Arrange — raise unsheltered_bed_multiplier to its own max (0.9) so the
	# ladder still holds (0.85 < 0.9 < 1.0) while ground_penalty is pushed
	# above its own safe max (0.8).
	var config := NeedsMoodConfig.new()
	config.unsheltered_bed_multiplier = 0.9
	config.ground_penalty = 0.85

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_float(config.ground_penalty).is_equal_approx(NeedsMoodConfig.GROUND_PENALTY_MAX, 0.0001)


func test_validate_ground_penalty_at_min_boundary_no_issues() -> void:
	var config := NeedsMoodConfig.new()
	config.ground_penalty = NeedsMoodConfig.GROUND_PENALTY_MIN

	assert_array(config.validate()).is_empty()


func test_validate_ground_penalty_at_max_boundary_no_issues() -> void:
	# Arrange — unsheltered_bed_multiplier raised to 0.9 so the ladder holds
	# at ground_penalty's own max boundary (0.8 < 0.9 < 1.0).
	var config := NeedsMoodConfig.new()
	config.unsheltered_bed_multiplier = 0.9
	config.ground_penalty = NeedsMoodConfig.GROUND_PENALTY_MAX

	assert_array(config.validate()).is_empty()


func test_validate_unsheltered_bed_multiplier_below_min_clamps_and_no_blocking() -> void:
	# Arrange — lower ground_penalty to its own min (0.1) so the ladder
	# still holds (0.1 < 0.3 < 1.0) while unsheltered_bed_multiplier is
	# pushed below its own safe min (0.5).
	var config := NeedsMoodConfig.new()
	config.ground_penalty = 0.1
	config.unsheltered_bed_multiplier = 0.3

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_float(config.unsheltered_bed_multiplier).is_equal_approx(
		NeedsMoodConfig.UNSHELTERED_BED_MULTIPLIER_MIN, 0.0001
	)


func test_validate_unsheltered_bed_multiplier_above_max_clamps_and_no_blocking() -> void:
	# Arrange — default ground_penalty (0.4) keeps the ladder holding
	# (0.4 < 0.95 < 1.0) while unsheltered_bed_multiplier is pushed above its
	# own safe max (0.9).
	var config := NeedsMoodConfig.new()
	config.unsheltered_bed_multiplier = 0.95

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_float(config.unsheltered_bed_multiplier).is_equal_approx(
		NeedsMoodConfig.UNSHELTERED_BED_MULTIPLIER_MAX, 0.0001
	)


func test_validate_unsheltered_bed_multiplier_at_min_boundary_no_issues() -> void:
	# Arrange — ground_penalty lowered to its own min (0.1) so the ladder
	# holds at unsheltered_bed_multiplier's own min boundary (0.1 < 0.5).
	var config := NeedsMoodConfig.new()
	config.ground_penalty = NeedsMoodConfig.GROUND_PENALTY_MIN
	config.unsheltered_bed_multiplier = NeedsMoodConfig.UNSHELTERED_BED_MULTIPLIER_MIN

	assert_array(config.validate()).is_empty()


func test_validate_unsheltered_bed_multiplier_at_max_boundary_no_issues() -> void:
	var config := NeedsMoodConfig.new()
	config.unsheltered_bed_multiplier = NeedsMoodConfig.UNSHELTERED_BED_MULTIPLIER_MAX

	assert_array(config.validate()).is_empty()


# ---------------------------------------------------------------------------
# Need schema — fixed enum + explicit active set
# ---------------------------------------------------------------------------

func test_need_enum_contains_exactly_sleep_food_company() -> void:
	# Assert — exactly three values, in schema order.
	assert_int(NeedsMood.Need.SLEEP).is_equal(0)
	assert_int(NeedsMood.Need.FOOD).is_equal(1)
	assert_int(NeedsMood.Need.COMPANY).is_equal(2)
	assert_int(NeedsMood.Need.size()).is_equal(3)


func test_active_needs_contains_only_sleep() -> void:
	assert_array(NeedsMood.ACTIVE_NEEDS).contains_exactly([NeedsMood.Need.SLEEP])


# ---------------------------------------------------------------------------
# Headless DI (Node.new() + mocks, zero scene tree, zero Autoload)
# ---------------------------------------------------------------------------

func test_needs_mood_setup_headless_with_mocks_succeeds_no_scene_tree() -> void:
	# Arrange
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	needs_mood.config = NeedsMoodConfig.new()
	needs_mood.time_tick_system = auto_free(MockTimeTickSystem.new())
	assert_bool(needs_mood.is_set_up()).is_false()

	# Act
	needs_mood.setup()

	# Assert
	assert_bool(needs_mood.is_set_up()).is_true()
	assert_array(needs_mood.get_boot_blocking_issues()).is_empty()


func test_needs_mood_setup_missing_config_raises_assertion() -> void:
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	needs_mood.time_tick_system = auto_free(MockTimeTickSystem.new())

	await assert_error(func() -> void: needs_mood.setup()).is_runtime_error(
		"Assertion failed: NeedsMood.config not wired"
	)


func test_needs_mood_setup_missing_time_tick_system_raises_assertion() -> void:
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	needs_mood.config = NeedsMoodConfig.new()

	await assert_error(func() -> void: needs_mood.setup()).is_runtime_error(
		"Assertion failed: NeedsMood requires a TimeTickSystem-shaped dependency"
		+ " (assign a mock in tests; the real Autoload is registered project-wide)"
		+ " before setup() can connect tick dispatch"
	)


# ---------------------------------------------------------------------------
# Tick subscription — F1 -> F2 -> F3, exactly once per dispatched tick
# ---------------------------------------------------------------------------

func test_tick_dispatch_runs_f_pass_exactly_once_in_strict_order() -> void:
	# Arrange
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	needs_mood.config = NeedsMoodConfig.new()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	needs_mood.time_tick_system = mock_tick
	needs_mood.setup()

	# Act
	mock_tick.fire_tick()

	# Assert
	assert_int(needs_mood.get_tick_pass_count()).is_equal(1)
	assert_array(needs_mood.get_last_tick_pass_order()).contains_exactly(
		[&"f1_decay", &"f2_recovery", &"f3_mood"]
	)


func test_tick_dispatch_twice_runs_f_pass_exactly_twice() -> void:
	# Arrange
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	needs_mood.config = NeedsMoodConfig.new()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	needs_mood.time_tick_system = mock_tick
	needs_mood.setup()

	# Act
	mock_tick.fire_tick()
	mock_tick.fire_tick()

	# Assert — the entry point fires once PER dispatched tick, never coalesced.
	assert_int(needs_mood.get_tick_pass_count()).is_equal(2)
	assert_array(needs_mood.get_last_tick_pass_order()).contains_exactly(
		[&"f1_decay", &"f2_recovery", &"f3_mood"]
	)
