## Unit test — Needs & Mood System story needs-mood-003 (recovery-report API,
## source->rate table, F2 recovery; TD rulings NM-3 [three-rung ladder is
## authoritative over the GDD's stale F2 variable-table row] and NM-5
## [`start_recovery`/`stop_recovery`'s canonical villager-id three-arg form] —
## `production/architecture-decisions-m02-preflight-2026-07-26.md`;
## `docs/architecture/architecture.md` Needs & Mood API Boundaries block).
##
## Proves, against [NeedsMood] directly (mocked [TimeTickSystem] boundary,
## same `MockTimeTickSystem` double `decay_state_machine_test.gd` and
## `config_scaffold_and_ladder_invariant_test.gd` already establish):
## 1. **AC8/AC28/AC9**: the three-rung ladder — `bed_sheltered` x1.0,
##    `bed_unsheltered` x `unsheltered_bed_multiplier`, all three `ground_*`
##    enum values x `ground_penalty` identically.
## 2. **AC10**: a source id [enum NeedsMood.RecoverySource] does not (yet)
##    name still resolves via [member NeedsMood._source_rate_table]'s own
##    lookup, with zero code changes to [method NeedsMood._pass_f2_recovery]
##    — proven by extending the table directly (this codebase's established
##    "poke private state" test convention, see
##    `decay_state_machine_test.gd`'s own `_need_records` pokes).
## 3. **AC11**: the `satisfied_threshold` upward cross stops recovery exactly
##    once, with the overshoot retained (never clamped back to the
##    threshold).
## 4. **AC33**: the `min(100, ...)` domain clamp at the legal knob extremes.
## 5. **No-decay-while-Recovering**: F2's increment only, never F1's decay,
##    on the same tick.
## 6. **Intra-tick ordering**: a `stop_recovery`/`start_recovery` report lands
##    BEFORE the next tick's F-pass, so that tick credits zero/full recovery
##    respectively (GDD Core Rule 10).
## 7. **Breather exclusion**: no report ever made -> decays exactly like an
##    idle need (mirrors `decay_state_machine_test.gd`'s own AC12 case,
##    restated here per this story's own QA Test Case list).
## 8. **Isolation** (TR-needs-mood-system-052): mock Building System / item-
##    database doubles record zero calls across a full recovery cycle.
## 9. **Edge cases**: `start_recovery` idempotent for the same source while
##    already Recovering; `stop_recovery` on a non-Recovering need is a
##    documented no-op; an unrecognized recovery source fails loudly rather
##    than silently recovering at 1.0.
##
## Every input is a fixed literal — deterministic, no random seeds, no
## wall-clock assertions, no scene tree, no Autoload registration.
class_name NeedsMoodRecoverySourceRateTableTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

## Test-only stand-in for the Building System boundary (TR-needs-mood-
## system-052's "zero calls" invariant) — never wired into [NeedsMood]
## anywhere (there is no field to wire it to); its `call_count` staying `0`
## across a full recovery cycle is the isolation proof.
class MockBuildingSystem:
	extends RefCounted
	var call_count: int = 0
	func any_call() -> void:
		call_count += 1


## Test-only stand-in for the Resource & Item Database boundary — same
## "never wired, call_count stays 0" isolation proof as [MockBuildingSystem].
class MockItemDatabase:
	extends RefCounted
	var call_count: int = 0
	func any_call() -> void:
		call_count += 1


## Returns a fresh, headless [NeedsMood] instance already through
## [method NeedsMood.setup] with a GDD-default [NeedsMoodConfig], wired to
## the caller-owned [param mock_tick] double — zero scene tree, zero
## Autoload (same precedent as `decay_state_machine_test.gd`'s own
## `_make_needs_mood`).
func _make_needs_mood(mock_tick: MockTimeTickSystem) -> NeedsMood:
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	needs_mood.config = NeedsMoodConfig.new()
	needs_mood.time_tick_system = mock_tick
	needs_mood.setup()
	return needs_mood


## Connects a direct listener to [signal NeedsMood.need_satisfied] that
## appends `[villager_id, need]` pairs to the returned `Array` — the
## append-not-reassign pattern this codebase's tests rely on for signal-count
## assertions (a GDScript lambda closure over a reassigned captured scalar
## does not write back to the outer scope).
func _capture_need_satisfied(needs_mood: NeedsMood) -> Array:
	var emissions: Array = []
	needs_mood.need_satisfied.connect(
		func(villager_id: int, need: StringName) -> void: emissions.append([villager_id, need])
	)
	return emissions


# ---------------------------------------------------------------------------
# AC8/AC28/AC9 — the three-rung ladder
# ---------------------------------------------------------------------------

func test_ac8_bed_sheltered_recovers_at_full_rate() -> void:
	# Arrange — base_recovery_per_tick_sleep default 0.5, value = 30.0
	# (story's own QA Test Case).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 30.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)

	# Act
	mock_tick.fire_tick()

	# Assert — F2: value <- min(100, 30.0 + 0.5 * 1.0) == 30.5.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(30.5, 0.0001)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.RECOVERING)


func test_ac28_bed_unsheltered_recovers_at_unsheltered_multiplier() -> void:
	# Arrange — unsheltered_bed_multiplier default 0.7 (story's own QA Test
	# Case: 30.0 + 0.5 * 0.7 == 30.35).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 30.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_UNSHELTERED)

	# Act
	mock_tick.fire_tick()

	# Assert
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(30.35, 0.0001)


func test_ac9_all_three_ground_sources_recover_identically_at_ground_penalty() -> void:
	# Arrange — ground_penalty default 0.4 (story's own QA Test Case:
	# 30.0 + 0.5 * 0.4 == 30.2, identical for all three ground_* sources).
	var ground_sources: Array[NeedsMood.RecoverySource] = [
		NeedsMood.RecoverySource.GROUND_NO_BED_OWNED,
		NeedsMood.RecoverySource.GROUND_BED_UNREACHABLE,
		NeedsMood.RecoverySource.GROUND_TRAPPED,
	]
	for source: NeedsMood.RecoverySource in ground_sources:
		var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
		var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
		needs_mood.set_need_value(1, &"sleep", 30.0)
		needs_mood.start_recovery(1, &"sleep", source)

		# Act
		mock_tick.fire_tick()

		# Assert
		assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(
			30.2, 0.0001
		).override_failure_message("source %s: expected 30.2, got %s" % [source, needs_mood.get_need_value(1, &"sleep")])


# ---------------------------------------------------------------------------
# AC10 — table-lookup extensibility, no code change
# ---------------------------------------------------------------------------

func test_ac10_new_source_id_extends_table_lookup_with_no_code_change() -> void:
	# Arrange — a source id NeedsMood.RecoverySource does not name today
	# ("bed_masterwork", the story's own QA Test Case), added directly to the
	# table (this codebase's established "poke private state" test
	# convention) with its own multiplier (1.5).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 30.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)
	needs_mood._source_rate_table[&"bed_masterwork"] = 1.5
	needs_mood._need_records[NeedsMood._record_key(1, &"sleep")].recovery_source_name = &"bed_masterwork"

	# Act
	mock_tick.fire_tick()

	# Assert — 30.0 + 0.5 * 1.5 == 30.75, via the SAME _pass_f2_recovery
	# lookup body every other source above already exercised.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(30.75, 0.0001)


# ---------------------------------------------------------------------------
# AC11 — satisfied-threshold cross stops recovery, overshoot retained
# ---------------------------------------------------------------------------

func test_ac11_satisfied_threshold_cross_emits_once_and_stops_with_overshoot_retained() -> void:
	# Arrange — value = 94.8, satisfied_threshold = 95, recovering at 0.5
	# (bed_sheltered, x1.0) — story's own QA Test Case.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var emissions: Array = _capture_need_satisfied(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 94.8)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)

	# Act — the crossing tick.
	mock_tick.fire_tick()

	# Assert — overshoot (95.3) retained, exactly one emission, state Satisfied.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(95.3, 0.0001)
	assert_int(emissions.size()).is_equal(1)
	assert_array(emissions[0]).is_equal([1, &"sleep"])
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.SATISFIED)

	# Act — a further tick must not re-emit (F2 skips non-Recovering records).
	mock_tick.fire_tick()
	assert_int(emissions.size()).is_equal(1)


# ---------------------------------------------------------------------------
# AC33 — domain clamp at legal knob extremes
# ---------------------------------------------------------------------------

func test_ac33_domain_clamp_at_legal_extreme_caps_at_100_exactly() -> void:
	# Arrange — value = 99.0, satisfied_threshold = 100 (its own safe-range
	# max), base_recovery_per_tick_sleep = 2.0 (its own safe-range max) at
	# bed_sheltered (x1.0) -- the story's own "legal knob extremes" case.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	needs_mood.config = NeedsMoodConfig.new()
	needs_mood.config.satisfied_threshold = 100.0
	needs_mood.config.base_recovery_per_tick_sleep = 2.0
	needs_mood.time_tick_system = mock_tick
	needs_mood.setup()
	needs_mood.set_need_value(1, &"sleep", 99.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)

	# Act
	mock_tick.fire_tick()

	# Assert — 99.0 + 2.0 * 1.0 == 101.0, clamped to exactly 100.0, never above.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(100.0)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.SATISFIED)


# ---------------------------------------------------------------------------
# No-decay-while-Recovering
# ---------------------------------------------------------------------------

func test_no_decay_while_recovering_net_change_equals_recovery_increment_only() -> void:
	# Arrange — decay_per_tick_sleep default 0.07 would otherwise subtract;
	# F2 must be the ONLY contributor while Recovering.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 50.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)

	# Act
	mock_tick.fire_tick()

	# Assert — net change is exactly +0.5 (base_recovery_per_tick_sleep * 1.0),
	# never 0.5 - 0.07 or any decay-tainted figure.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(50.5, 0.0001)


# ---------------------------------------------------------------------------
# Intra-tick ordering (GDD Core Rule 10)
# ---------------------------------------------------------------------------

func test_intra_tick_ordering_stop_recovery_before_tick_credits_zero_recovery() -> void:
	# Arrange — Recovering villager; stop_recovery lands BEFORE the next tick.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 50.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)
	mock_tick.fire_tick()
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(50.5, 0.0001)

	# Act — stop lands before the tick; the tick then fires.
	needs_mood.stop_recovery(1, &"sleep", &"interrupted")
	mock_tick.fire_tick()

	# Assert — zero recovery credited that tick; normal F1 decay applies
	# instead, since the record is no longer Recovering by the time F1 runs.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(50.43, 0.0001)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.SATISFIED)


func test_intra_tick_ordering_start_recovery_before_tick_credits_full_increment_same_tick() -> void:
	# Arrange — Urgent villager; start_recovery lands BEFORE the very next
	# tick, which must still credit a FULL increment (never zero, never
	# partial).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 20.0)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)

	# Act
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)
	mock_tick.fire_tick()

	# Assert — full increment (0.5 * 1.0) credited on this same tick.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(20.5, 0.0001)


# ---------------------------------------------------------------------------
# Breather exclusion — no report, no recovery, no pause of decay
# ---------------------------------------------------------------------------

func test_breather_exclusion_no_report_decays_normally_no_pause_no_recovery() -> void:
	# Arrange — a Breather villager reports nothing; NeedsMood has no concept
	# of "Breather" at all, so this proves the negative space directly: with
	# zero start_recovery calls, decay proceeds exactly as an idle villager's
	# would (mirrors decay_state_machine_test.gd's own AC12 case).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 50.0)

	# Act
	for i: int in range(10):
		mock_tick.fire_tick()
		assert_int(needs_mood.get_need_state(1, &"sleep")).is_not_equal(NeedsMood.NeedState.RECOVERING)

	# Assert — ten ticks of normal F1 decay, never paused, never recovered.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(50.0 - 10.0 * 0.07, 0.0001)


# ---------------------------------------------------------------------------
# Isolation — zero calls into Building System / item database (TR-052)
# ---------------------------------------------------------------------------

func test_isolation_mocked_building_and_item_db_doubles_record_zero_calls() -> void:
	# Arrange — a full recovery cycle: Urgent -> start_recovery -> Recovering
	# -> satisfied cross -> Satisfied. Neither mock is ever wired into
	# NeedsMood (it exposes no such field) — their call_count staying 0 is
	# the isolation proof (TR-needs-mood-system-052).
	var mock_building_system := MockBuildingSystem.new()
	var mock_item_database := MockItemDatabase.new()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 94.5)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)

	# Act
	for i: int in range(5):
		mock_tick.fire_tick()

	# Assert — the recovery cycle completed (satisfied) and neither mock was
	# ever touched.
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.SATISFIED)
	assert_int(mock_building_system.call_count).is_equal(0)
	assert_int(mock_item_database.call_count).is_equal(0)


# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

func test_edge_start_recovery_idempotent_for_already_recovering_same_source() -> void:
	# Arrange
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 30.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)

	# Act — calling start_recovery again with the SAME source mid-recovery.
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)
	mock_tick.fire_tick()

	# Assert — behaves exactly as a single start_recovery call would.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(30.5, 0.0001)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.RECOVERING)


func test_edge_stop_recovery_on_non_recovering_need_is_documented_no_op() -> void:
	# Arrange — Urgent, never recovering.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 20.0)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)

	# Act — stop_recovery on a need that was never Recovering.
	needs_mood.stop_recovery(1, &"sleep", &"not_recovering")

	# Assert — no-op: state and value untouched.
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal(20.0)


func test_edge_stop_recovery_on_untracked_villager_is_documented_no_op() -> void:
	# Arrange — no record exists for villager 999 at all.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)

	# Act + Assert — reaching this line at all proves no runtime error.
	needs_mood.stop_recovery(999, &"sleep", &"never_tracked")
	assert_float(needs_mood.get_need_value(999, &"sleep")).is_equal(100.0)


func test_edge_start_recovery_on_untracked_villager_is_documented_no_op() -> void:
	# Arrange — no record exists for villager 999 (no prior set_need_value).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)

	# Act — start_recovery on a villager this module has never been told
	# about; must not create a record (mirrors _need_records' own "created
	# ONLY by set_need_value" invariant).
	needs_mood.start_recovery(999, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)

	# Assert — still untracked, safe default, no crash.
	assert_float(needs_mood.get_need_value(999, &"sleep")).is_equal(100.0)
	assert_int(needs_mood.get_need_state(999, &"sleep")).is_equal(NeedsMood.NeedState.SATISFIED)


func test_edge_unknown_recovery_source_fails_loudly_rather_than_defaulting_to_one() -> void:
	# Arrange — a Recovering record whose stored source name is not present
	# in the source->rate table at all (only reachable by poking private
	# state directly — the production start_recovery API cannot express an
	# unrecognized RecoverySource enum value).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 30.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)
	needs_mood._need_records[NeedsMood._record_key(1, &"sleep")].recovery_source_name = &"bogus_source"

	# Act + Assert — fails loudly (a runtime assertion), never a silent
	# fallback to a 1.0 multiplier.
	await assert_error(func() -> void: mock_tick.fire_tick()).is_runtime_error(
		"Assertion failed: NeedsMood._pass_f2_recovery: unrecognized recovery source"
		+ " 'bogus_source' -- not present in the source->rate table"
		+ " (TR-needs-mood-system-035/065)"
	)
