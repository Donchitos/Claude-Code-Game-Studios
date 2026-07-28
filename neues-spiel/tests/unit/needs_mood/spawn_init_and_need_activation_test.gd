## Unit test — Needs & Mood System story needs-mood-006 (F4 spawn
## initialization + new-need activation; ADR-0002 primary [config-derived
## spawn values], ADR-0005 secondary [boot-path initialization order]).
##
## Proves, against [NeedsMood] directly (mocked [TimeTickSystem] boundary,
## same `MockTimeTickSystem` double every sibling needs_mood test file
## already establishes):
## 1. **AC17**: a fresh villager's active need(s) initialize at 100 and mood
##    equals `mean_active` (the single-need MVP case: 100) — never 0, and no
##    transient Low band is ever observable.
## 2. **AC26**: an existing villager's schema activating a new need seeds
##    that need at 100, leaves the already-tracked need untouched, and the
##    mood computed from `mean_active` reflects the new term — proven via
##    [method NeedsMood.initialize_villager]'s own `active_needs` override
##    (this story's sanctioned way to mock a schema change without mutating
##    the real [constant NeedsMood.ACTIVE_NEEDS] constant, which is read-only
##    at runtime).
## 3. **Idempotence**: calling [method NeedsMood.initialize_villager] twice
##    for the same villager never resets an already-tracked need OR an
##    already-established mood value (the Control Manifest's own named
##    Forbidden pattern: "re-running F4 on an existing villager").
## 4. **No spawn events**: zero [signal NeedsMood.need_urgent]/[signal
##    NeedsMood.need_satisfied]/[signal NeedsMood.mood_band_changed]
##    emissions across initialization plus one subsequent tick.
## 5. **Edge cases**: two villagers initialized in the same tick stay
##    independent; a degenerate empty active-need set yields a
##    non-crashing, documented mood (no divide-by-zero).
##
## Every input is a fixed literal — deterministic, no random seeds, no
## wall-clock assertions, no scene tree, no Autoload registration.
class_name NeedsMoodSpawnInitAndNeedActivationTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

## Returns a fresh, headless [NeedsMood] instance already through
## [method NeedsMood.setup] with a GDD-default [NeedsMoodConfig], wired to
## the caller-owned [param mock_tick] double — zero scene tree, zero
## Autoload (same precedent as every sibling needs_mood test file's own
## `_make_needs_mood`).
func _make_needs_mood(mock_tick: MockTimeTickSystem) -> NeedsMood:
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	needs_mood.config = NeedsMoodConfig.new()
	needs_mood.time_tick_system = mock_tick
	needs_mood.setup()
	return needs_mood


## Connects direct listeners to all three of [NeedsMood]'s edge-triggered
## signals, appending one entry per emission to a shared counter `Array` per
## signal (the append-not-reassign pattern this codebase's tests rely on for
## signal-count assertions — a lambda closure over a reassigned captured
## scalar does not write back to the outer scope).
func _capture_all_signals(needs_mood: NeedsMood) -> Dictionary:
	var urgent_emissions: Array = []
	var satisfied_emissions: Array = []
	var band_emissions: Array = []
	needs_mood.need_urgent.connect(
		func(villager_id: int, need: StringName) -> void: urgent_emissions.append([villager_id, need])
	)
	needs_mood.need_satisfied.connect(
		func(villager_id: int, need: StringName) -> void: satisfied_emissions.append([villager_id, need])
	)
	needs_mood.mood_band_changed.connect(
		func(villager_id: int, band: NeedsMood.MoodBand) -> void: band_emissions.append([villager_id, band])
	)
	return {
		"urgent": urgent_emissions,
		"satisfied": satisfied_emissions,
		"band": band_emissions,
	}


# ---------------------------------------------------------------------------
# AC17 — fresh spawn, every active need = 100, mood = mean_active, never 0
# ---------------------------------------------------------------------------

func test_ac17_fresh_villager_initializes_sleep_at_100_mood_at_100_band_happy() -> void:
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)

	needs_mood.initialize_villager(1)

	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(100.0)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.SATISFIED)
	assert_float(needs_mood.get_mood(1)).is_equal(100.0)
	assert_int(needs_mood.get_mood_band(1)).is_equal(NeedsMood.MoodBand.HAPPY)


func test_ac17_negative_mood_is_never_zero_at_any_observable_point() -> void:
	# Even querying mood for a villager BEFORE initialize_villager runs at all
	# must never read 0 (get_mood's own "unknown answers as if fine" default).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)

	assert_float(needs_mood.get_mood(1)).is_not_equal(0.0)

	needs_mood.initialize_villager(1)
	assert_float(needs_mood.get_mood(1)).is_not_equal(0.0)
	assert_float(needs_mood.get_mood(1)).is_equal(100.0)


# ---------------------------------------------------------------------------
# AC26 — new-need activation on an existing villager (mocked schema change)
# ---------------------------------------------------------------------------

func test_ac26_new_need_activation_seeds_new_need_leaves_existing_untouched() -> void:
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)

	# Arrange — an "existing villager" whose sleep value has already drifted
	# from a fresh spawn (arranged directly, this story's own established
	# initialization/test seam).
	needs_mood.set_need_value(1, &"sleep", 40.0)

	# Act — the mocked schema change: a version now activates `food` too.
	# Passed via the sanctioned active_needs override rather than mutating
	# the real (read-only) ACTIVE_NEEDS constant.
	var mocked_active_needs: Array[NeedsMood.Need] = [NeedsMood.Need.SLEEP, NeedsMood.Need.FOOD]
	needs_mood.initialize_villager(1, mocked_active_needs)

	# Assert — food seeded at 100, sleep untouched, mood == mean_active(40, 100) == 70.0.
	assert_float(needs_mood.get_need_value(1, &"food")).is_equal(100.0)
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(40.0)
	assert_float(needs_mood.get_mood(1)).is_equal(70.0)


func test_ac26_activation_on_already_moodinitialized_villager_never_overwrites_mood() -> void:
	# Distinct from the case above: a villager whose MoodRecord ALREADY
	# exists (a real prior initialize_villager call, mood ticking since) must
	# NEVER have that mood value recomputed/overwritten by a later
	# new-need-activation call — the Control Manifest's own named Forbidden
	# pattern ("re-running F4 on an existing villager... would erase the
	# smoothing state").
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)

	needs_mood.initialize_villager(1)  # sleep=100, mood=100 (real F4 spawn).
	needs_mood.set_need_value(1, &"sleep", 40.0)  # simulate ticks having passed.
	needs_mood.set_mood_value(1, 55.3)  # simulate mood having drifted via F3.

	var mocked_active_needs: Array[NeedsMood.Need] = [NeedsMood.Need.SLEEP, NeedsMood.Need.FOOD]
	needs_mood.initialize_villager(1, mocked_active_needs)

	# food is seeded (was never tracked); sleep and mood are BOTH untouched.
	assert_float(needs_mood.get_need_value(1, &"food")).is_equal(100.0)
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(40.0)
	assert_float(needs_mood.get_mood(1)).is_equal(55.3)


# ---------------------------------------------------------------------------
# Idempotence — calling initialize_villager twice never resets live values
# ---------------------------------------------------------------------------

func test_idempotence_second_call_does_not_reset_already_initialized_need() -> void:
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)

	needs_mood.initialize_villager(1)
	needs_mood.set_need_value(1, &"sleep", 30.0)  # simulate ticks having passed.

	needs_mood.initialize_villager(1)  # called again for the SAME id.

	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(30.0)


func test_idempotence_second_call_does_not_reset_already_initialized_mood() -> void:
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)

	needs_mood.initialize_villager(1)
	needs_mood.set_mood_value(1, 62.5)  # simulate mood having drifted via F3.

	needs_mood.initialize_villager(1)  # called again for the SAME id.

	assert_float(needs_mood.get_mood(1)).is_equal(62.5)


# ---------------------------------------------------------------------------
# No spawn events — zero emissions across init + one subsequent tick
# ---------------------------------------------------------------------------

func test_no_spawn_events_zero_signals_across_init_and_one_tick() -> void:
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var emissions: Dictionary = _capture_all_signals(needs_mood)

	needs_mood.initialize_villager(1)
	mock_tick.fire_tick()

	assert_int((emissions["urgent"] as Array).size()).is_equal(0)
	assert_int((emissions["satisfied"] as Array).size()).is_equal(0)
	assert_int((emissions["band"] as Array).size()).is_equal(0)


# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

func test_edge_two_villagers_initialized_same_tick_stay_independent() -> void:
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)

	needs_mood.initialize_villager(1)
	needs_mood.initialize_villager(2)
	needs_mood.set_need_value(1, &"sleep", 40.0)
	needs_mood.set_need_value(2, &"sleep", 90.0)

	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(40.0)
	assert_float(needs_mood.get_need_value(2, &"sleep")).is_equal(90.0)
	assert_float(needs_mood.get_mood(1)).is_equal(100.0)
	assert_float(needs_mood.get_mood(2)).is_equal(100.0)


func test_edge_degenerate_empty_active_needs_yields_non_crashing_documented_mood() -> void:
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)

	var empty_active_needs: Array[NeedsMood.Need] = []
	needs_mood.initialize_villager(1, empty_active_needs)

	# No need record created, no MoodRecord created (never a divide-by-zero) —
	# both queries fall back to their own documented "unknown, fine" default.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(100.0)
	assert_float(needs_mood.get_mood(1)).is_equal(100.0)
	assert_int(needs_mood.get_mood_band(1)).is_equal(NeedsMood.MoodBand.HAPPY)
