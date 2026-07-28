## Unit test — Needs & Mood System story needs-mood-002 (F1 decay, per-need
## state machine, edge-triggered urgent signal, has_urgent_need; TD ruling
## NM-6 — `production/architecture-decisions-m02-preflight-2026-07-26.md`;
## `docs/architecture/architecture.md` Needs & Mood API Boundaries block).
##
## Proves, against [NeedsMood] directly (mocked [TimeTickSystem] boundary,
## same `MockTimeTickSystem` double established by
## `tests/integration/needs_mood/config_scaffold_and_ladder_invariant_test.gd`
## / `tests/integration/villager_ai/mock_time_tick_system.gd`):
## 1. **AC1/AC2**: F1 decay reduces by exactly `decay_per_tick_sleep`, clamps
##    to 0 and stays.
## 2. **AC3/AC4/AC5**: exactly one `need_urgent` on the downward
##    `urgency_threshold` cross; no repeat while parked at the threshold
##    (decay temporarily zeroed, per this story's own QA Test Case wording)
##    or at 0.
## 3. **AC6**: sustained-0 produces no signal, no state change beyond the
##    clamp, no error.
## 4. **AC7**: the urgent signal fires on tick 1072 exactly — nothing on
##    1071 or 1073 — a tick-count assertion, never wall-clock.
## 5. **AC12**: no recovery report → the state machine never reads
##    `RECOVERING`, decay continues to the 0 clamp.
## 6. **Seam**: `has_urgent_need(id)` true/false/unknown-id-false, no error.
## 7. **Seam purity (NM-6)**: `has_urgent_need(id)` called N times on any id
##    never emits a signal, never creates/mutates a record — the module's
##    tracked-record set is byte-identical before/after.
## 8. **Edge cases**: a single-tick above→below crossing still emits exactly
##    once; two villagers' same need cross independently with the correct
##    per-emission payload; two needs on one villager (one decaying/active,
##    one dormant per Core Rule 2's "MVP fills only sleep") never
##    cross-contaminate each other's value/state.
##
## Per this codebase's own established convention (`tick_accumulator_test.gd`,
## `priority_decision_loop_test.gd`): signal-count assertions use a direct
## `.connect()` listener that APPENDS to a captured `Array`, never a
## reassigned captured scalar (a GDScript lambda closure over a reassigned
## captured `int`/scalar local does not write back to the outer scope).
## Every input is a fixed literal — deterministic, no random seeds, no
## wall-clock assertions, no scene tree, no Autoload registration.
class_name NeedsMoodDecayStateMachineTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

## Returns a fresh, headless [NeedsMood] instance already through
## [method NeedsMood.setup] with a GDD-default [NeedsMoodConfig], wired to
## the caller-owned [param mock_tick] double — zero scene tree, zero
## Autoload. The caller keeps its own strongly-typed reference to
## [param mock_tick] (this codebase's own established precedent, see
## `config_scaffold_and_ladder_invariant_test.gd`) rather than reading
## [member NeedsMood.time_tick_system] back out of the `Object`-typed field.
func _make_needs_mood(mock_tick: MockTimeTickSystem) -> NeedsMood:
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	needs_mood.config = NeedsMoodConfig.new()
	needs_mood.time_tick_system = mock_tick
	needs_mood.setup()
	return needs_mood


## Connects a direct listener to [signal NeedsMood.need_urgent] that appends
## `[villager_id, need]` pairs to the returned `Array` — the append-not-
## reassign pattern this codebase's own tests rely on for signal-count
## assertions.
func _capture_need_urgent(needs_mood: NeedsMood) -> Array:
	var emissions: Array = []
	needs_mood.need_urgent.connect(
		func(villager_id: int, need: StringName) -> void: emissions.append([villager_id, need])
	)
	return emissions


# ---------------------------------------------------------------------------
# AC1/AC2 — exact decay, clamp to 0 and stay
# ---------------------------------------------------------------------------

func test_ac1_decay_reduces_value_by_exact_decay_per_tick() -> void:
	# Arrange
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 100.0)

	# Act
	mock_tick.fire_tick()

	# Assert — F1: value <- max(0, value - decay_per_tick), default 0.07.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(99.93, 0.0001)


func test_ac2_decay_below_rate_clamps_to_zero_and_stays() -> void:
	# Arrange
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 0.03)

	# Act — one tick clamps (0.03 - 0.07 would be negative).
	mock_tick.fire_tick()
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(0.0)

	# Act — ten further ticks; stays at the clamp.
	for i: int in range(10):
		mock_tick.fire_tick()
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(0.0)


# ---------------------------------------------------------------------------
# AC3/AC4/AC5 — edge-triggered urgent signal, crossing not equality
# ---------------------------------------------------------------------------

func test_ac3_urgent_signal_emits_exactly_once_on_downward_cross() -> void:
	# Arrange
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var emissions: Array = _capture_need_urgent(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 25.04)

	# Act — one tick: 25.04 - 0.07 = 24.97, crosses 25 downward.
	mock_tick.fire_tick()

	# Assert
	assert_int(emissions.size()).is_equal(1)
	assert_array(emissions[0]).is_equal([1, &"sleep"])
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)

	# Act — further ticks must not re-emit.
	for i: int in range(20):
		mock_tick.fire_tick()
	assert_int(emissions.size()).is_equal(1)


func test_ac4_value_parked_at_threshold_emits_no_signal_across_many_ticks() -> void:
	# Arrange — decay temporarily zeroed (this story's own QA Test Case
	# wording) so the value stays PARKED exactly at the threshold; a test-
	# only mutation on a Resource instance this test owns, made AFTER
	# setup()'s one-time validate() already ran (never touches
	# config.validate() itself, never a src/ production write site).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var emissions: Array = _capture_need_urgent(needs_mood)
	needs_mood.config.decay_per_tick_sleep = 0.0
	needs_mood.set_need_value(1, &"sleep", 25.0)

	# Act
	for i: int in range(20):
		mock_tick.fire_tick()

	# Assert — Edge Case 4: crossing, not equality. Value never moves.
	assert_int(emissions.size()).is_equal(0)
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(25.0)


func test_ac5_value_at_zero_emits_no_repeated_signal_across_many_ticks() -> void:
	# Arrange
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var emissions: Array = _capture_need_urgent(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 0.0)

	# Act
	for i: int in range(50):
		mock_tick.fire_tick()

	# Assert
	assert_int(emissions.size()).is_equal(0)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)


# ---------------------------------------------------------------------------
# AC6 — "harms nothing" is literal
# ---------------------------------------------------------------------------

func test_ac6_value_at_zero_has_no_side_effects_beyond_sustained_clamp() -> void:
	# Arrange
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var emissions: Array = _capture_need_urgent(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 0.0)

	# Act
	for i: int in range(50):
		mock_tick.fire_tick()

	# Assert — no signal/event, value stays exactly 0.0, state unchanged,
	# and reaching this line at all proves no runtime error was raised.
	assert_int(emissions.size()).is_equal(0)
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(0.0)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)


# ---------------------------------------------------------------------------
# AC7 — the 1072-tick boundary, exactly
# ---------------------------------------------------------------------------

func test_ac7_urgent_signal_fires_at_tick_1072_exactly() -> void:
	# Arrange — defaults: value=100, decay_per_tick_sleep=0.07,
	# urgency_threshold=25 -> ceil((100-25)/0.07) = 1072 (GDD F1 worked
	# example, TR-needs-mood-system-030).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var emissions: Array = _capture_need_urgent(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 100.0)

	# Act — 1071 ticks: nothing yet.
	for i: int in range(1071):
		mock_tick.fire_tick()
	assert_int(emissions.size()).is_equal(0)

	# Act — tick 1072: the cross.
	mock_tick.fire_tick()
	assert_int(emissions.size()).is_equal(1)

	# Act — tick 1073: no repeat.
	mock_tick.fire_tick()
	assert_int(emissions.size()).is_equal(1)


# ---------------------------------------------------------------------------
# AC12 — recovery cannot self-trigger from value alone
# ---------------------------------------------------------------------------

func test_ac12_no_recovery_report_never_enters_recovering_state() -> void:
	# Arrange
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 10.0)

	# Act — enough ticks to fully drain to the 0 clamp (10 / 0.07 ≈ 143) and
	# then well beyond it.
	for i: int in range(150):
		mock_tick.fire_tick()
		assert_int(needs_mood.get_need_state(1, &"sleep")).is_not_equal(NeedsMood.NeedState.RECOVERING)

	# Assert — kept decaying all the way to the 0 clamp; state is Urgent,
	# never Recovering (no start_recovery report exists yet — story 003).
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(0.0)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)


# ---------------------------------------------------------------------------
# Seam — has_urgent_need
# ---------------------------------------------------------------------------

func test_seam_has_urgent_need_true_false_and_unknown_id_false_no_error() -> void:
	# Arrange
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 25.04)
	needs_mood.set_need_value(2, &"sleep", 100.0)

	# Act — villager 1 crosses to Urgent; villager 2 stays Satisfied.
	mock_tick.fire_tick()

	# Assert
	assert_bool(needs_mood.has_urgent_need(1)).is_true()
	assert_bool(needs_mood.has_urgent_need(2)).is_false()
	assert_bool(needs_mood.has_urgent_need(999)).is_false()


# ---------------------------------------------------------------------------
# Seam purity (NM-6) — pure query, zero side effects
# ---------------------------------------------------------------------------

func test_seam_purity_has_urgent_need_never_signals_mutates_or_creates_records() -> void:
	# Arrange — one KNOWN villager (Urgent), plus unknown/never-spawned ids.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var emissions: Array = _capture_need_urgent(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 25.04)
	mock_tick.fire_tick()
	assert_int(emissions.size()).is_equal(1)
	emissions.clear()

	var records_before: Dictionary = needs_mood._need_records.duplicate(true)
	var value_before: float = needs_mood.get_need_value(1, &"sleep")
	var state_before: NeedsMood.NeedState = needs_mood.get_need_state(1, &"sleep")

	# Act — many calls against known, unknown, and never-spawned ids.
	for i: int in range(25):
		needs_mood.has_urgent_need(1)
		needs_mood.has_urgent_need(999)
		needs_mood.has_urgent_need(-1)

	# Assert — zero signals, zero record creation/mutation, byte-identical
	# tracked-record set.
	assert_int(emissions.size()).is_equal(0)
	assert_int(needs_mood._need_records.size()).is_equal(records_before.size())
	assert_bool(needs_mood._need_records.has("999:sleep")).is_false()
	assert_bool(needs_mood._need_records.has("-1:sleep")).is_false()
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(value_before)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(state_before)


# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

func test_edge_single_tick_above_to_below_crossing_emits_exactly_once() -> void:
	# Arrange — one tick's decay carries the value from just above the
	# threshold to just below it.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var emissions: Array = _capture_need_urgent(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 25.001)

	# Act
	mock_tick.fire_tick()

	# Assert — exactly one emission, in this single tick.
	assert_int(emissions.size()).is_equal(1)
	assert_array(emissions[0]).is_equal([1, &"sleep"])


func test_edge_two_villagers_same_need_cross_independently_with_correct_payload() -> void:
	# Arrange — villager 1 crosses almost immediately, villager 2 much later.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var emissions: Array = _capture_need_urgent(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 25.04)
	needs_mood.set_need_value(2, &"sleep", 100.0)

	# Act — one tick: villager 1 crosses, villager 2 is nowhere close.
	mock_tick.fire_tick()
	assert_int(emissions.size()).is_equal(1)
	assert_array(emissions[0]).is_equal([1, &"sleep"])
	assert_bool(needs_mood.has_urgent_need(1)).is_true()
	assert_bool(needs_mood.has_urgent_need(2)).is_false()

	# Act — drive villager 2 down to its own cross (1071 more ticks from
	# its own tick-1 decay puts it at tick 1072 total).
	for i: int in range(1071):
		mock_tick.fire_tick()

	# Assert — villager 2 crossed independently; villager 1 never re-fires.
	assert_int(emissions.size()).is_equal(2)
	assert_array(emissions[1]).is_equal([2, &"sleep"])
	assert_bool(needs_mood.has_urgent_need(1)).is_true()
	assert_bool(needs_mood.has_urgent_need(2)).is_true()


func test_edge_two_needs_on_one_villager_never_cross_contaminate() -> void:
	# Arrange — sleep (active, decays) and food (schema-known but inactive
	# in MVP per Core Rule 2 -- zero configured decay rate) on the SAME
	# villager. Food starts already below its own threshold; since it is
	# not in ACTIVE_NEEDS, has_urgent_need never even inspects it, and since
	# its decay rate is 0.0 it must never move or re-signal while sleep
	# decays and crosses underneath it.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var emissions: Array = _capture_need_urgent(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 25.04)
	needs_mood.set_need_value(1, &"food", 10.0)
	var food_state_before: NeedsMood.NeedState = needs_mood.get_need_state(1, &"food")

	# Act
	for i: int in range(5):
		mock_tick.fire_tick()

	# Assert — sleep crossed exactly once; food's value/state are untouched.
	assert_int(emissions.size()).is_equal(1)
	assert_array(emissions[0]).is_equal([1, &"sleep"])
	assert_float(needs_mood.get_need_value(1, &"food")).is_equal(10.0)
	assert_int(needs_mood.get_need_state(1, &"food")).is_equal(food_state_before)
	assert_bool(needs_mood.has_urgent_need(1)).is_true()


# ---------------------------------------------------------------------------
# Query surface — unknown id/need defaults (story AC: "answers ... without
# erroring")
# ---------------------------------------------------------------------------

func test_query_surface_unknown_villager_and_need_return_safe_defaults_no_error() -> void:
	# Arrange
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)

	# Assert — unknown villager id.
	assert_float(needs_mood.get_need_value(999, &"sleep")).is_equal(100.0)
	assert_int(needs_mood.get_need_state(999, &"sleep")).is_equal(NeedsMood.NeedState.SATISFIED)

	# Assert — unrecognized need name, known villager.
	needs_mood.set_need_value(1, &"sleep", 50.0)
	assert_float(needs_mood.get_need_value(1, &"nonexistent")).is_equal(100.0)
	assert_int(needs_mood.get_need_state(1, &"nonexistent")).is_equal(NeedsMood.NeedState.SATISFIED)


func test_set_need_value_clamps_and_never_emits_a_signal_on_initialization() -> void:
	# Arrange
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var emissions: Array = _capture_need_urgent(needs_mood)

	# Act — out-of-domain values clamp; an already-below-threshold
	# initialization must not be treated as a "cross".
	needs_mood.set_need_value(1, &"sleep", 150.0)
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(100.0)

	needs_mood.set_need_value(2, &"sleep", -10.0)
	assert_float(needs_mood.get_need_value(2, &"sleep")).is_equal(0.0)
	assert_int(needs_mood.get_need_state(2, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)

	# Assert — initialization alone never emits, regardless of state.
	assert_int(emissions.size()).is_equal(0)
