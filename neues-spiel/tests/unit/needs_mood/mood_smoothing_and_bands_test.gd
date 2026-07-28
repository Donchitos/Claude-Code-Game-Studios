## Unit test — Needs & Mood System story needs-mood-005 (F3 mood smoothing,
## snap rule, `mean_active`, mood bands, band-change events;
## `docs/architecture/architecture.md` Needs & Mood API Boundaries block).
##
## Proves, against [NeedsMood] directly (mocked [TimeTickSystem] boundary,
## same `MockTimeTickSystem` double `decay_state_machine_test.gd` and
## `recovery_source_rate_table_test.gd` already establish):
## 1. **AC14**: outside the 0.05 snap zone, mood moves by exactly
##    `(mean_active - mood) / mood_smoothing_ticks` in float math.
## 2. **AC15/AC16**: inside the snap zone, mood snaps exactly to
##    `mean_active` — including the anti-asymptote case where enough ticks
##    at a stable target land mood exactly on 70.0 with Happy activating.
## 3. **AC18**: exactly one `mood_band_changed` on a boundary cross; no
##    further events while parked in the new band.
## 4. **AC19**: default `band_display_hysteresis = 0` — landing exactly on
##    70.00 or 40.00 activates the higher band with the event firing on the
##    landing tick itself (no implicit dead zone).
## 5. **AC20**: `mean_active` is the mean over ACTIVE needs only (MVP:
##    sleep) — food/company values never skew it, proven by feeding the real
##    EMA pipeline distinguishable food/company values and checking the
##    resulting one-tick step matches a sleep-only mean.
## 6. **Pass ordering**: a need recovering this tick feeds its POST-recovery
##    value into F3, never the pre-tick one.
## 7. **Bands**: pure derivation from the smoothed value only (no ticks
##    fired), at and around both boundaries.
## 8. **Display-only (advisory)**: `src/villager_ai`'s source contains no
##    `get_mood`/`get_mood_band`/`MoodBand`/`mood_band_changed` reference
##    (Core Rule 8, TR-needs-mood-system-040) — the grep/contract check the
##    Implementation Notes ask this story to add.
## 9. **Edge cases**: a delta of exactly 0.05 takes the EMA branch, never the
##    snap; `mood_smoothing_ticks` at both safe-range extremes (10, 120)
##    produces a finite, non-zero step.
##
## Per this codebase's own established convention (`decay_state_machine_test
## .gd`, `recovery_source_rate_table_test.gd`): signal-count assertions use a
## direct `.connect()` listener that APPENDS to a captured `Array`, never a
## reassigned captured scalar. Every input is a fixed literal — deterministic,
## no random seeds, no wall-clock assertions, no scene tree, no Autoload
## registration. Two-consecutive-crossings-in-one-burst (the story's own QA
## Test Case list) is explicitly deferred to story needs-mood-008's burst
## harness — not tested here.
class_name NeedsMoodMoodSmoothingBandsTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

## Returns a fresh, headless [NeedsMood] instance already through
## [method NeedsMood.setup] with a GDD-default [NeedsMoodConfig], wired to
## the caller-owned [param mock_tick] double — zero scene tree, zero
## Autoload (same precedent as the sibling needs_mood test files).
func _make_needs_mood(mock_tick: MockTimeTickSystem) -> NeedsMood:
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	needs_mood.config = NeedsMoodConfig.new()
	needs_mood.time_tick_system = mock_tick
	needs_mood.setup()
	return needs_mood


## Connects a direct listener to [signal NeedsMood.mood_band_changed] that
## appends `[villager_id, band]` pairs to the returned `Array` — the
## append-not-reassign pattern this codebase's tests rely on for
## signal-count assertions.
func _capture_mood_band_changed(needs_mood: NeedsMood) -> Array:
	var emissions: Array = []
	needs_mood.mood_band_changed.connect(
		func(villager_id: int, band: NeedsMood.MoodBand) -> void: emissions.append([villager_id, band])
	)
	return emissions


## Reads every `.gd` file directly under [param dir_path] (non-recursive,
## comment-stripped) and returns the concatenated source — this codebase's
## own established convention for grep-style architectural contract checks
## (see `tests/integration/villager_ai/config_and_scaffold_test.gd`'s
## identically-named helper).
func _read_all_gd_source(dir_path: String) -> String:
	var combined: String = ""
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Could not open directory: %s" % dir_path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gd"):
			var text: String = FileAccess.get_file_as_string(dir_path.path_join(file_name))
			for line: String in text.split("\n"):
				if not line.strip_edges().begins_with("#"):
					combined += line
					combined += "\n"
		file_name = dir.get_next()
	dir.list_dir_end()
	return combined


# ---------------------------------------------------------------------------
# AC14 — outside the snap zone, exact EMA step
# ---------------------------------------------------------------------------

func test_ac14_mood_moves_by_exact_ema_step_outside_snap_zone() -> void:
	# Arrange — mood = 100.0, mean_active = 60.0 (story's own QA Test Case;
	# delta = 40.0, well outside the 0.05 snap zone). Decay zeroed (this
	# codebase's established precedent — see decay_state_machine_test.gd's
	# own AC4 case) so F1 cannot nudge the sleep value away from 60.0 before
	# F3 reads it this same tick.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.config.decay_per_tick_sleep = 0.0
	needs_mood.set_mood_value(1, 100.0)
	needs_mood.set_need_value(1, &"sleep", 60.0)

	# Act
	mock_tick.fire_tick()

	# Assert — F3: mood <- 100 + (60 - 100) / 40 == 99.0 exactly.
	assert_float(needs_mood.get_mood(1)).is_equal_approx(99.0, 0.0001)


# ---------------------------------------------------------------------------
# AC15/AC16 — snap rule, anti-asymptote guarantee
# ---------------------------------------------------------------------------

func test_ac15_mood_snaps_exactly_to_mean_active_inside_snap_zone() -> void:
	# Arrange — mood = 69.98, mean_active = 70.0 (story's own QA Test Case;
	# delta = 0.02, inside the 0.05 snap zone). Decay zeroed so mean_active
	# stays exactly 70.0 through this tick's F1 pass.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.config.decay_per_tick_sleep = 0.0
	needs_mood.set_mood_value(1, 69.98)
	needs_mood.set_need_value(1, &"sleep", 70.0)

	# Act
	mock_tick.fire_tick()

	# Assert — snaps to exactly 70.0, Happy activates.
	assert_float(needs_mood.get_mood(1)).is_equal(70.0)
	assert_int(needs_mood.get_mood_band(1)).is_equal(NeedsMood.MoodBand.HAPPY)


func test_ac16_mean_active_stable_at_70_converges_to_exactly_70_and_happy() -> void:
	# Arrange — mean_active held stable at 70.0 (decay zeroed, this codebase's
	# established precedent — see decay_state_machine_test.gd's own AC4 case
	# — so the sleep value driving mean_active never drifts); mood starts at
	# 60.0.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.config.decay_per_tick_sleep = 0.0
	needs_mood.set_need_value(1, &"sleep", 70.0)
	needs_mood.set_mood_value(1, 60.0)

	# Act — enough ticks that the EMA gap (10.0 * 0.975^n) falls under the
	# 0.05 snap zone (n ~ 210 at defaults); 400 gives ample margin.
	for i: int in range(400):
		mock_tick.fire_tick()

	# Assert — the anti-asymptote guarantee: mood == 70.0 exactly, Happy.
	assert_float(needs_mood.get_mood(1)).is_equal(70.0)
	assert_int(needs_mood.get_mood_band(1)).is_equal(NeedsMood.MoodBand.HAPPY)

	# Act — further ticks stay snapped (gap is now 0.0, still < 0.05).
	mock_tick.fire_tick()
	assert_float(needs_mood.get_mood(1)).is_equal(70.0)


# ---------------------------------------------------------------------------
# AC18 — exactly one band-change event on a cross, none while parked
# ---------------------------------------------------------------------------

func test_ac18_band_change_emits_once_on_cross_then_nothing_while_parked() -> void:
	# Arrange — mood starts Happy (75.0); mean_active fixed at 50.0 (decay
	# zeroed) so mood descends toward 50.0, crossing 70 into Content, then
	# asymptotically approaches 50.0 — never reaching 40 (Low), so "no
	# further cross" is guaranteed by the fixed target, not a lucky tick
	# count.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.config.decay_per_tick_sleep = 0.0
	needs_mood.set_need_value(1, &"sleep", 50.0)
	needs_mood.set_mood_value(1, 75.0)
	var emissions: Array = _capture_mood_band_changed(needs_mood)

	# Act — fire ticks until the Content cross (safety-capped).
	var iterations: int = 0
	while needs_mood.get_mood_band(1) == NeedsMood.MoodBand.HAPPY and iterations < 100:
		mock_tick.fire_tick()
		iterations += 1

	# Assert — exactly one emission, band Content.
	assert_int(emissions.size()).is_equal(1)
	assert_array(emissions[0]).is_equal([1, NeedsMood.MoodBand.CONTENT])

	# Act — further ticks trend toward 50.0, staying in Content; no new cross.
	for i: int in range(20):
		mock_tick.fire_tick()

	# Assert — no repeat, no further event.
	assert_int(emissions.size()).is_equal(1)
	assert_int(needs_mood.get_mood_band(1)).is_equal(NeedsMood.MoodBand.CONTENT)


# ---------------------------------------------------------------------------
# AC19 — no implicit dead zone at default hysteresis 0
# ---------------------------------------------------------------------------

func test_ac19_landing_exactly_on_70_activates_happy_with_event_on_landing_tick() -> void:
	# Arrange — the snap rule lands mood exactly on 70.00 (mirrors AC15's own
	# math): previous mood 69.98 (Content), mean_active 70.0. Decay zeroed so
	# mean_active stays exactly 70.0 through this tick's F1 pass.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.config.decay_per_tick_sleep = 0.0
	needs_mood.set_mood_value(1, 69.98)
	needs_mood.set_need_value(1, &"sleep", 70.0)
	var emissions: Array = _capture_mood_band_changed(needs_mood)

	# Act — the landing tick.
	mock_tick.fire_tick()

	# Assert — lands exactly on 70.00, Happy activates, event fires THIS tick.
	assert_float(needs_mood.get_mood(1)).is_equal(70.0)
	assert_int(needs_mood.get_mood_band(1)).is_equal(NeedsMood.MoodBand.HAPPY)
	assert_int(emissions.size()).is_equal(1)
	assert_array(emissions[0]).is_equal([1, NeedsMood.MoodBand.HAPPY])


func test_ac19_landing_exactly_on_40_activates_content_with_event_on_landing_tick() -> void:
	# Arrange — snap lands mood exactly on 40.00: previous mood 39.98 (Low),
	# mean_active 40.0. Decay zeroed so mean_active stays exactly 40.0
	# through this tick's F1 pass.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.config.decay_per_tick_sleep = 0.0
	needs_mood.set_mood_value(1, 39.98)
	needs_mood.set_need_value(1, &"sleep", 40.0)
	var emissions: Array = _capture_mood_band_changed(needs_mood)

	# Act — the landing tick.
	mock_tick.fire_tick()

	# Assert — lands exactly on 40.00, Content activates, event fires THIS tick.
	assert_float(needs_mood.get_mood(1)).is_equal(40.0)
	assert_int(needs_mood.get_mood_band(1)).is_equal(NeedsMood.MoodBand.CONTENT)
	assert_int(emissions.size()).is_equal(1)
	assert_array(emissions[0]).is_equal([1, NeedsMood.MoodBand.CONTENT])


# ---------------------------------------------------------------------------
# AC20 — mean_active excludes inactive needs, never defaults them
# ---------------------------------------------------------------------------

func test_ac20_mean_active_uses_only_active_needs_never_food_or_company() -> void:
	# Arrange — sleep = 60.0 (active); food = 100.0, company = 0.0 (inactive
	# in MVP — if either wrongly entered the mean it would skew the result
	# to 86.7 or 20.0 respectively, per the story's own QA Test Case). Mood
	# starts at 0.0 so the resulting one-tick EMA step direction/magnitude
	# reveals which mean was actually used.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.config.decay_per_tick_sleep = 0.0
	needs_mood.set_need_value(1, &"sleep", 60.0)
	needs_mood.set_need_value(1, &"food", 100.0)
	needs_mood.set_need_value(1, &"company", 0.0)
	needs_mood.set_mood_value(1, 0.0)

	# Act
	mock_tick.fire_tick()

	# Assert — mood <- 0 + (60.0 - 0) / 40 == 1.5. A mean of 86.7 would give
	# 2.1675; a mean of 20.0 (food/company only) would give 0.5.
	assert_float(needs_mood.get_mood(1)).is_equal_approx(1.5, 0.0001)


# ---------------------------------------------------------------------------
# Pass ordering — F3 reads the POST-recovery value, never the pre-tick one
# ---------------------------------------------------------------------------

func test_pass_ordering_f3_reads_post_recovery_value_same_tick() -> void:
	# Arrange — sleep Recovering at bed_sheltered (x1.0); mood starts equal
	# to the PRE-tick need value (50.0), so the resulting step reveals
	# whether F3 used the pre- or post-recovery value.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 50.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)
	needs_mood.set_mood_value(1, 50.0)

	# Act
	mock_tick.fire_tick()

	# Assert — F2 raises sleep to 50.5 THIS tick; F3's mean_active must be
	# 50.5, giving mood <- 50.0 + (50.5 - 50.0) / 40 == 50.0125. Using the
	# stale pre-tick value (50.0) would instead leave mood at exactly 50.0.
	assert_float(needs_mood.get_mood(1)).is_equal_approx(50.0125, 0.0001)
	assert_float(needs_mood.get_mood(1)).is_not_equal(50.0)


# ---------------------------------------------------------------------------
# Bands — pure derivation from the smoothed value only
# ---------------------------------------------------------------------------

func test_bands_derive_purely_from_smoothed_value_at_and_around_boundaries() -> void:
	# Arrange + Act + Assert — no ticks fired; a pure query of directly-set
	# mood values proves the band comparison is `>=` both ways.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)

	needs_mood.set_mood_value(1, 70.0)
	assert_int(needs_mood.get_mood_band(1)).is_equal(NeedsMood.MoodBand.HAPPY)

	needs_mood.set_mood_value(2, 69.99)
	assert_int(needs_mood.get_mood_band(2)).is_equal(NeedsMood.MoodBand.CONTENT)

	needs_mood.set_mood_value(3, 40.0)
	assert_int(needs_mood.get_mood_band(3)).is_equal(NeedsMood.MoodBand.CONTENT)

	needs_mood.set_mood_value(4, 39.99)
	assert_int(needs_mood.get_mood_band(4)).is_equal(NeedsMood.MoodBand.LOW)


func test_query_surface_unknown_villager_returns_safe_defaults_no_error() -> void:
	# Arrange
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)

	# Assert — reaching this line at all proves no runtime error.
	assert_float(needs_mood.get_mood(999)).is_equal(100.0)
	assert_int(needs_mood.get_mood_band(999)).is_equal(NeedsMood.MoodBand.HAPPY)


func test_set_mood_value_clamps_and_never_emits_on_initialization() -> void:
	# Arrange
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var emissions: Array = _capture_mood_band_changed(needs_mood)

	# Act — out-of-domain values clamp; landing in Low or Happy at
	# initialization must not be treated as a "cross".
	needs_mood.set_mood_value(1, 150.0)
	assert_float(needs_mood.get_mood(1)).is_equal(100.0)

	needs_mood.set_mood_value(2, -10.0)
	assert_float(needs_mood.get_mood(2)).is_equal(0.0)
	assert_int(needs_mood.get_mood_band(2)).is_equal(NeedsMood.MoodBand.LOW)

	# Assert — initialization alone never emits.
	assert_int(emissions.size()).is_equal(0)


# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

func test_edge_delta_exactly_0_05_takes_ema_branch_not_snap() -> void:
	# Arrange — mood = 0.0, mean_active = 0.05 (subtraction from zero is
	# exact in IEEE754, so abs(mean_active - mood) is bit-identical to the
	# literal 0.05 the production comparison also parses). Decay zeroed so
	# F1 cannot touch the tiny sleep value before F3 reads it.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.config.decay_per_tick_sleep = 0.0
	needs_mood.set_need_value(1, &"sleep", 0.05)
	needs_mood.set_mood_value(1, 0.0)

	# Act
	mock_tick.fire_tick()

	# Assert — EMA branch (0.0 + 0.05/40 == 0.00125), NOT the snap (0.05,
	# which would result if `< 0.05` were instead `<= 0.05`).
	assert_float(needs_mood.get_mood(1)).is_equal_approx(0.00125, 0.000001)


func test_edge_mood_smoothing_ticks_at_min_extreme_10_produces_finite_nonzero_step() -> void:
	# Arrange — mood_smoothing_ticks at its safe-range minimum (10.0, its own
	# GDD-declared bound), a large delta well outside the snap zone.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	needs_mood.config = NeedsMoodConfig.new()
	needs_mood.config.mood_smoothing_ticks = 10.0
	needs_mood.time_tick_system = mock_tick
	needs_mood.setup()
	# Zeroed AFTER setup()'s one-time validate() already ran (that call would
	# otherwise clamp 0.0 back into the [0.03, 0.2] safe range) — this
	# codebase's established precedent, see decay_state_machine_test.gd's own
	# AC4 case.
	needs_mood.config.decay_per_tick_sleep = 0.0
	needs_mood.set_need_value(1, &"sleep", 100.0)
	needs_mood.set_mood_value(1, 0.0)

	# Act
	mock_tick.fire_tick()

	# Assert — 0 + (100 - 0) / 10 == 10.0: finite, non-zero.
	var mood_after: float = needs_mood.get_mood(1)
	assert_bool(is_finite(mood_after)).is_true()
	assert_float(mood_after).is_not_equal(0.0)
	assert_float(mood_after).is_equal_approx(10.0, 0.0001)


func test_edge_mood_smoothing_ticks_at_max_extreme_120_produces_finite_nonzero_step() -> void:
	# Arrange — mood_smoothing_ticks at its safe-range maximum (120.0, its
	# own GDD-declared bound).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	needs_mood.config = NeedsMoodConfig.new()
	needs_mood.config.mood_smoothing_ticks = 120.0
	needs_mood.time_tick_system = mock_tick
	needs_mood.setup()
	# Zeroed AFTER setup() — see the min-extreme test's own comment above.
	needs_mood.config.decay_per_tick_sleep = 0.0
	needs_mood.set_need_value(1, &"sleep", 100.0)
	needs_mood.set_mood_value(1, 0.0)

	# Act
	mock_tick.fire_tick()

	# Assert — 0 + (100 - 0) / 120 == 0.8333...: finite, non-zero.
	var mood_after: float = needs_mood.get_mood(1)
	assert_bool(is_finite(mood_after)).is_true()
	assert_float(mood_after).is_not_equal(0.0)
	assert_float(mood_after).is_equal_approx(100.0 / 120.0, 0.0001)


func test_edge_villager_with_need_data_but_no_mood_record_is_skipped_no_crash() -> void:
	# Arrange — need data exists, but set_mood_value was never called (no
	# lazy init, mirrors _need_records' own "created ONLY by set_need_value"
	# precedent).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 60.0)

	# Act + Assert — reaching this line at all proves no runtime error
	# (division-by-zero or otherwise); mood stays at the safe default.
	mock_tick.fire_tick()
	assert_float(needs_mood.get_mood(1)).is_equal(100.0)


# ---------------------------------------------------------------------------
# Display-only (advisory) — Core Rule 8, TR-needs-mood-system-040
# ---------------------------------------------------------------------------

func test_advisory_mood_has_zero_consuming_references_in_villager_ai_source() -> void:
	# Grep-verifiable AC (Implementation Notes: "Add the grep/contract check
	# with the story so it can never regress silently."): no work/scheduling
	# code may read mood. Villager AI is the sole implemented work/scheduling
	# system today — its decision loop/priority code must never reference
	# any of this module's mood-consuming surface.
	var source: String = _read_all_gd_source("res://src/villager_ai")

	var banned_substrings: Array[String] = [
		"get_mood(",
		"get_mood_band(",
		"MoodBand",
		"mood_band_changed",
	]
	for banned: String in banned_substrings:
		assert_bool(source.contains(banned)).is_false()
