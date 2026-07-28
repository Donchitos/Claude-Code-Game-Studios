## Unit test — Needs & Mood System story needs-mood-008 (burst ordering,
## pause & warp determinism; ADR-0008 primary [tick-driven execution, never
## raw delta], ADR-0002 secondary [`TimeTickConfig.max_ticks_per_frame` /
## `NeedsMoodConfig` are read, never redefined]).
##
## This story is mostly PROOF, not new mechanism (Implementation Notes):
## stories 002/003/005 already implement the per-tick F1/F2/F3 work this
## suite exercises. What this file adds is the burst/pause/warp harness, the
## ordering guarantees, and the two anchor tick counts (1072/1212) that make
## the whole system falsifiable.
##
## Engine Notes: the tick burst cap is [member TimeTickConfig.max_ticks_per_frame]
## (landed default 12, Sprint 8 re-tune — the GDD's own prose still says 10);
## every assertion below reads that CONFIG VALUE, never the literal. Ticks
## are delivered as N discrete synchronous `tick()` signal emissions per
## frame (never a single "apply N ticks" batch call), so dispatching a tight
## `for`/`while` loop of [method MockTimeTickSystem.fire_tick] calls is the
## natural, and only, way to model a burst here.
##
## Proves, against [NeedsMood] directly (mocked [TimeTickSystem] boundary,
## same `MockTimeTickSystem` double every sibling needs_mood test file
## already establishes):
## 1. **AC21**: a burst of `TimeTickConfig.max_ticks_per_frame` ticks runs
##    F1 -> F2 -> F3 once per dispatched tick (never coalesced), a need
##    crossing `urgency_threshold` mid-burst emits exactly once at the
##    correct within-burst position, and a mocked FAST need crossing BOTH
##    thresholds inside one burst delivers `need_urgent`-then-`need_satisfied`
##    in order, both present (Edge Case 6) — proven by having the
##    `need_urgent` listener call [method NeedsMood.start_recovery]
##    synchronously off the hint, exactly the intra-tick ordering GDD Core
##    Rule 10 already documents for story 003's own recovery-report API.
## 2. **AC21 burst-mechanics edge cases**: a burst that STARTS while a need is
##    already Recovering credits exactly one increment per tick in the burst
##    (no skip, no double-credit); a `stop_recovery` landing between two
##    ticks of the same burst credits zero recovery from that point on.
## 3. **AC22**: identical tick counts dispatched in two different SHAPES
##    (individually vs. grouped) produce bit-identical F1/F2/F3 results —
##    rates are a function of tick COUNT, never of how those ticks were
##    bunched into frames by warp.
## 4. **AC23**: zero ticks dispatched (pause) leaves every queried value,
##    state, and mood untouched, and fires no signal, no matter how many
##    pure queries are made in between (there is nothing else in this module
##    for "real time passing" to move).
## 5. **AC27**: the full default sleep cycle (100 -> urgent -> sheltered-bed
##    recovery -> satisfied) fires `need_urgent` and `need_satisfied` at
##    EXACT tick counts derived from config (never a bare literal) — with
##    boundary checks one tick on either side of each anchor — and asserts
##    those derived counts equal 1072/1212 so a future retune fails loudly
##    rather than silently drifting.
## 6. **Grep**: the module source contains zero `_process`/`_physics_process`
##    simulation math, zero `Timer`, zero `SceneTree.paused`, zero
##    `Engine.time_scale` [TR-needs-mood-system-051].
##
## Per this codebase's own established convention (`decay_state_machine_test.
## gd`, `recovery_source_rate_table_test.gd`): signal-count assertions use a
## direct `.connect()` listener that APPENDS to a captured `Array`, never a
## reassigned captured scalar. Every input is a fixed literal or a value
## derived from config at test time — deterministic, no random seeds, no
## wall-clock assertions (ticks are pumped manually throughout), no scene
## tree, no Autoload registration.
class_name NeedsMoodBurstPauseWarpDeterminismTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

## Returns a fresh, headless [NeedsMood] instance already through
## [method NeedsMood.setup] with a GDD-default [NeedsMoodConfig], wired to
## the caller-owned [param mock_tick] double — zero scene tree, zero
## Autoload (mirrors every sibling needs_mood test file's own
## `_make_needs_mood`).
func _make_needs_mood(mock_tick: MockTimeTickSystem) -> NeedsMood:
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	needs_mood.config = NeedsMoodConfig.new()
	needs_mood.time_tick_system = mock_tick
	needs_mood.setup()
	return needs_mood


## Connects a direct listener to [signal NeedsMood.need_urgent] that appends
## `[villager_id, need]` pairs to the returned `Array` (append-not-reassign —
## a lambda closure over a reassigned captured scalar does not write back).
func _capture_need_urgent(needs_mood: NeedsMood) -> Array:
	var emissions: Array = []
	needs_mood.need_urgent.connect(
		func(villager_id: int, need: StringName) -> void: emissions.append([villager_id, need])
	)
	return emissions


## Connects a direct listener to [signal NeedsMood.need_satisfied], same
## append-not-reassign pattern as [method _capture_need_urgent].
func _capture_need_satisfied(needs_mood: NeedsMood) -> Array:
	var emissions: Array = []
	needs_mood.need_satisfied.connect(
		func(villager_id: int, need: StringName) -> void: emissions.append([villager_id, need])
	)
	return emissions


## Reads a single `.gd` source file, stripping full-line `#`/`##` doc-comment
## lines first -- mirrors this codebase's established
## `_read_gd_source_without_comments` precedent (`wall_tool_test.gd`,
## `floor_tool_test.gd`, `block_tool_test.gd`) so a file's own doc comments
## (which may legitimately NAME a banned API to document its absence) are
## never mistaken for a violation.
func _read_gd_source_without_comments(file_path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(file_path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined


# ---------------------------------------------------------------------------
# AC21 — burst ordering: per-tick F1->F2->F3, never coalesced
# ---------------------------------------------------------------------------

func test_ac21_burst_of_max_ticks_per_frame_runs_f_pass_once_per_tick_with_correct_value() -> void:
	# Arrange
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 100.0)
	var burst_size: int = TimeTickConfig.new().max_ticks_per_frame

	# Act — dispatch the whole burst as N discrete synchronous emissions,
	# never a single "apply N ticks" shortcut.
	for i: int in range(burst_size):
		mock_tick.fire_tick()

	# Assert — the entry point ran exactly once per dispatched tick, in the
	# fixed F1 -> F2 -> F3 order, every tick (never coalesced/batched).
	assert_int(needs_mood.get_tick_pass_count()).is_equal(burst_size)
	assert_array(needs_mood.get_last_tick_pass_order()).contains_exactly(
		[&"f1_decay", &"f2_recovery", &"f3_mood"]
	)
	var expected_value: float = 100.0 - float(burst_size) * needs_mood.config.decay_per_tick_sleep
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(expected_value, 0.0001)


func test_ac21_burst_emits_urgent_exactly_once_at_correct_within_burst_position() -> void:
	# Arrange — a decay rate fast enough to cross urgency_threshold partway
	# through the burst (test-only direct config mutation AFTER setup()'s
	# one-time validate() already ran — this codebase's established
	# precedent, see decay_state_machine_test.gd's test_ac4).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.config.decay_per_tick_sleep = 10.0
	var emissions: Array = _capture_need_urgent(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 100.0)

	var burst_size: int = TimeTickConfig.new().max_ticks_per_frame
	var expected_cross_tick: int = ceili(
		(100.0 - needs_mood.config.urgency_threshold) / needs_mood.config.decay_per_tick_sleep
	)
	assert_bool(expected_cross_tick < burst_size).is_true()

	# Act — dispatch the burst tick-by-tick, checking the emission position
	# as it happens.
	for i: int in range(burst_size):
		mock_tick.fire_tick()
		var tick_number: int = i + 1
		if tick_number < expected_cross_tick:
			assert_int(emissions.size()).is_equal(0)
		else:
			assert_int(emissions.size()).is_equal(1)

	# Assert — exactly one emission for the whole burst, at the derived
	# within-burst position, never a repeat for the rest of the burst.
	assert_int(emissions.size()).is_equal(1)
	assert_array(emissions[0]).is_equal([1, &"sleep"])


func test_ac21_edge_fast_need_crosses_both_thresholds_within_one_burst_urgent_then_satisfied_in_order() -> void:
	# Arrange — a mocked "fast need": a decay rate large enough to cross
	# urgency_threshold in the burst's first tick, and (once the
	# `need_urgent` hint is acted on synchronously — Core Rule 10's own
	# intra-tick ordering) a recovery rate large enough to cross
	# satisfied_threshold the very same tick. Direct post-setup() config
	# mutation, same established precedent as the test above.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.config.decay_per_tick_sleep = 50.0
	needs_mood.config.base_recovery_per_tick_sleep = 1000.0
	var tagged_emissions: Array = []
	needs_mood.need_urgent.connect(
		func(villager_id: int, need: StringName) -> void:
			tagged_emissions.append(["urgent", villager_id, need])
			# Models Villager AI reacting to the hint synchronously, same
			# tick (GDD Core Rule 10's intra-tick ordering).
			needs_mood.start_recovery(villager_id, need, NeedsMood.RecoverySource.BED_SHELTERED)
	)
	needs_mood.need_satisfied.connect(
		func(villager_id: int, need: StringName) -> void: tagged_emissions.append(["satisfied", villager_id, need])
	)
	needs_mood.set_need_value(1, &"sleep", 100.0)
	var burst_size: int = TimeTickConfig.new().max_ticks_per_frame

	# Act — dispatch the whole burst, no batching.
	for i: int in range(burst_size):
		mock_tick.fire_tick()

	# Assert — urgent-then-satisfied, in that order, both present, never a
	# deduplicated nothing (Edge Case 6).
	assert_int(tagged_emissions.size()).is_greater_equal(2)
	assert_array(tagged_emissions[0]).is_equal(["urgent", 1, &"sleep"])
	assert_array(tagged_emissions[1]).is_equal(["satisfied", 1, &"sleep"])


# ---------------------------------------------------------------------------
# AC21 — burst-mechanics edge cases (already-Recovering start; mid-burst stop)
# ---------------------------------------------------------------------------

func test_edge_burst_starting_already_recovering_credits_one_increment_per_tick_in_burst() -> void:
	# Arrange — Recovering BEFORE the burst begins.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 50.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)
	var burst_size: int = TimeTickConfig.new().max_ticks_per_frame

	# Act — dispatch the whole burst as one tight sequence.
	for i: int in range(burst_size):
		mock_tick.fire_tick()

	# Assert — exactly one recovery increment credited per tick, no skips,
	# no double-credit from any batching.
	var expected_value: float = 50.0 + float(burst_size) * needs_mood.config.base_recovery_per_tick_sleep
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(expected_value, 0.0001)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.RECOVERING)


func test_edge_stop_recovery_mid_burst_credits_zero_recovery_from_that_point_on() -> void:
	# Arrange
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 50.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)
	var burst_size: int = TimeTickConfig.new().max_ticks_per_frame
	var ticks_before_stop: int = 3
	assert_bool(ticks_before_stop < burst_size).is_true()

	# Act — a few ticks of recovery credit, then an interruption landing
	# before the rest of the SAME burst's remaining ticks (Core Rule 10: the
	# stop lands before the next tick's F-pass).
	for i: int in range(ticks_before_stop):
		mock_tick.fire_tick()
	var value_at_stop: float = needs_mood.get_need_value(1, &"sleep")
	needs_mood.stop_recovery(1, &"sleep", &"test_interrupt")
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_not_equal(NeedsMood.NeedState.RECOVERING)

	var remaining_ticks: int = burst_size - ticks_before_stop
	for i: int in range(remaining_ticks):
		mock_tick.fire_tick()

	# Assert — zero further recovery credit; only decay applies for the rest
	# of the burst (value_at_stop is above urgency_threshold, so the need is
	# Satisfied, not Urgent, but either way F2 never touches it again).
	var expected_value: float = value_at_stop - float(remaining_ticks) * needs_mood.config.decay_per_tick_sleep
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(expected_value, 0.0001)


# ---------------------------------------------------------------------------
# AC22 — warp invariance: identical tick counts, identical values
# ---------------------------------------------------------------------------

func test_ac22_identical_tick_counts_dispatched_in_different_shapes_produce_bit_identical_values() -> void:
	# Arrange — two independent instances, identical starting state. Warp
	# itself is Time & Tick's own concern (a game_delta multiplier that
	# changes how many ticks arrive per real-time frame); this module only
	# ever sees discrete tick() emissions, so "1x" vs "3x" is modeled here
	# purely as a different SHAPE of dispatch for the SAME total tick count
	# (Implementation Notes: "the test dispatches N ticks in both scenarios
	# and asserts identical values").
	var mock_tick_a: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood_a: NeedsMood = _make_needs_mood(mock_tick_a)
	needs_mood_a.set_need_value(1, &"sleep", 60.0)
	needs_mood_a.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_UNSHELTERED)
	needs_mood_a.set_mood_value(1, 60.0)

	var mock_tick_b: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood_b: NeedsMood = _make_needs_mood(mock_tick_b)
	needs_mood_b.set_need_value(1, &"sleep", 60.0)
	needs_mood_b.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_UNSHELTERED)
	needs_mood_b.set_mood_value(1, 60.0)

	var total_ticks: int = 500

	# Act — A: "1x", one tick dispatched per outer step.
	for i: int in range(total_ticks):
		mock_tick_a.fire_tick()

	# Act — B: "3x", ticks arrive bunched (5 per outer step) — a different
	# dispatch SHAPE for the identical total tick count.
	var group_size: int = 5
	for i: int in range(total_ticks / group_size):
		for j: int in range(group_size):
			mock_tick_b.fire_tick()

	# Assert — bit-identical F1/F2/F3 results regardless of dispatch shape.
	assert_float(needs_mood_a.get_need_value(1, &"sleep")).is_equal(needs_mood_b.get_need_value(1, &"sleep"))
	assert_int(needs_mood_a.get_need_state(1, &"sleep")).is_equal(needs_mood_b.get_need_state(1, &"sleep"))
	assert_float(needs_mood_a.get_mood(1)).is_equal(needs_mood_b.get_mood(1))
	assert_int(needs_mood_a.get_mood_band(1)).is_equal(needs_mood_b.get_mood_band(1))


# ---------------------------------------------------------------------------
# AC23 — pause: zero ticks dispatched, nothing moves
# ---------------------------------------------------------------------------

func test_ac23_pause_zero_ticks_dispatched_leaves_all_state_unchanged() -> void:
	# Arrange — a villager mid-Recovering, so there is live state that COULD
	# move if any code path bypassed the tick signal.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var urgent_emissions: Array = _capture_need_urgent(needs_mood)
	var satisfied_emissions: Array = _capture_need_satisfied(needs_mood)
	var band_emissions: Array = []
	needs_mood.mood_band_changed.connect(
		func(villager_id: int, band: NeedsMood.MoodBand) -> void: band_emissions.append([villager_id, band])
	)
	needs_mood.set_need_value(1, &"sleep", 60.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)
	needs_mood.set_mood_value(1, 60.0)

	var value_before: float = needs_mood.get_need_value(1, &"sleep")
	var state_before: NeedsMood.NeedState = needs_mood.get_need_state(1, &"sleep")
	var mood_before: float = needs_mood.get_mood(1)
	var band_before: NeedsMood.MoodBand = needs_mood.get_mood_band(1)
	var tick_pass_count_before: int = needs_mood.get_tick_pass_count()

	# Act — "real time passes" (many pure queries standing in for however
	# much wall-clock elapses) with ZERO ticks dispatched. Pause per Time &
	# Tick's own semantics is exactly the absence of the tick signal, nothing
	# else — there is no other code path in this module that touches state.
	for i: int in range(50):
		needs_mood.get_need_value(1, &"sleep")
		needs_mood.has_urgent_need(1)
		needs_mood.get_why_string(1)
		needs_mood.get_mood(1)
		needs_mood.get_mood_band(1)

	# Assert — nothing moved, nothing fired.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(value_before)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(state_before)
	assert_float(needs_mood.get_mood(1)).is_equal(mood_before)
	assert_int(needs_mood.get_mood_band(1)).is_equal(band_before)
	assert_int(needs_mood.get_tick_pass_count()).is_equal(tick_pass_count_before)
	assert_int(urgent_emissions.size()).is_equal(0)
	assert_int(satisfied_emissions.size()).is_equal(0)
	assert_int(band_emissions.size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC27 — the full default sleep cycle, exact tick anchors
# ---------------------------------------------------------------------------

func test_ac27_full_sleep_cycle_urgent_and_satisfied_at_derived_exact_ticks() -> void:
	# Arrange — GDD-default config; the anchor ticks are DERIVED from config
	# below, never a bare literal (Implementation Notes: "if a future retune
	# changes the config, the test must fail loudly rather than silently
	# follow").
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var urgent_emissions: Array = []
	var satisfied_emissions: Array = []
	needs_mood.need_urgent.connect(
		func(villager_id: int, need: StringName) -> void:
			urgent_emissions.append([villager_id, need])
			# Villager AI reacting to the hint synchronously, same tick
			# (GDD Core Rule 10's intra-tick ordering) — this is what makes
			# the very first recovery increment land on tick 1072 itself.
			needs_mood.start_recovery(villager_id, need, NeedsMood.RecoverySource.BED_SHELTERED)
	)
	needs_mood.need_satisfied.connect(
		func(villager_id: int, need: StringName) -> void: satisfied_emissions.append([villager_id, need])
	)
	needs_mood.set_need_value(1, &"sleep", 100.0)

	var config: NeedsMoodConfig = needs_mood.config
	var expected_urgent_tick: int = ceili((100.0 - config.urgency_threshold) / config.decay_per_tick_sleep)
	assert_int(expected_urgent_tick).is_equal(1072)

	var value_at_urgent_tick: float = 100.0 - config.decay_per_tick_sleep * float(expected_urgent_tick)
	var recovery_ticks_needed: int = ceili(
		(config.satisfied_threshold - value_at_urgent_tick) / config.base_recovery_per_tick_sleep
	)
	var expected_satisfied_tick: int = expected_urgent_tick + recovery_ticks_needed - 1
	assert_int(expected_satisfied_tick).is_equal(1212)

	# Act/Assert — dispatch tick-by-tick, checking boundaries one tick on
	# either side of the urgent anchor.
	var current_tick: int = 0
	while current_tick < expected_urgent_tick + 1:
		current_tick += 1
		mock_tick.fire_tick()
		if current_tick == expected_urgent_tick - 1:
			assert_int(urgent_emissions.size()).is_equal(0)
		elif current_tick == expected_urgent_tick:
			assert_int(urgent_emissions.size()).is_equal(1)
		elif current_tick == expected_urgent_tick + 1:
			assert_int(urgent_emissions.size()).is_equal(1)

	# Act/Assert — continue to the satisfied anchor, same boundary discipline.
	while current_tick < expected_satisfied_tick + 1:
		current_tick += 1
		mock_tick.fire_tick()
		if current_tick == expected_satisfied_tick - 1:
			assert_int(satisfied_emissions.size()).is_equal(0)
		elif current_tick == expected_satisfied_tick:
			assert_int(satisfied_emissions.size()).is_equal(1)
		elif current_tick == expected_satisfied_tick + 1:
			assert_int(satisfied_emissions.size()).is_equal(1)

	# Assert — exactly one of each across the whole cycle, never wall-clock.
	assert_int(urgent_emissions.size()).is_equal(1)
	assert_int(satisfied_emissions.size()).is_equal(1)


# ---------------------------------------------------------------------------
# Grep — zero forbidden tick/pause/warp patterns anywhere in this module
# ---------------------------------------------------------------------------

func test_grep_module_source_contains_no_forbidden_tick_patterns() -> void:
	# Arrange
	var source: String = _read_gd_source_without_comments("res://src/needs_mood/needs_mood.gd")
	assert_str(source).is_not_empty()

	# Assert — all decay/recovery/mood math is reached only through Time &
	# Tick's `tick` signal (TR-needs-mood-system-051): zero `_process`/
	# `_physics_process` simulation math, zero `Timer`, zero
	# `SceneTree.paused`/`Engine.time_scale` (project-wide forbidden patterns).
	assert_bool(source.find("_process(") == -1).is_true()
	assert_bool(source.find("Timer") == -1).is_true()
	assert_bool(source.find("SceneTree.paused") == -1).is_true()
	assert_bool(source.find("Engine.time_scale") == -1).is_true()
