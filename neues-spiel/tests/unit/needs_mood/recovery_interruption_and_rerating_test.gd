## Unit test — Needs & Mood System story needs-mood-004 (recovery
## interruption, mid-recovery re-rating & bed revocation; ADR-0008 primary,
## ADR-0002 secondary; `docs/architecture/architecture.md` Needs & Mood API
## Boundaries block).
##
## Per this story's own Implementation Notes ("Re-rating is a consequence of
## story 003's design, not a new mechanism ... This story adds the mutation
## path (`report_source_changed` / the source parameter being updated) and
## the tests that pin the semantics") and its own Out of Scope line ("Build
## Validation: emitting `shelter_status_changed` (mocked here as a
## source-enum change)"): this suite adds **zero** production code. The
## mutation path IS [method NeedsMood.start_recovery] called again while a
## record is already [constant NeedsMood.NeedState.RECOVERING] — story 003's
## own implementation already stores/re-reads the source fresh every F2 tick
## and never touches `value` on a repeat call (see
## `recovery_source_rate_table_test.gd`'s own
## `test_edge_start_recovery_idempotent_for_already_recovering_same_source`,
## the SAME-source case; this file pins the DIFFERENT-source case, AC30). A
## real `shelter_status_changed` subscription/cell->villager_id correlation is
## explicitly mocked-out here as "the reported source enum changes" — that
## real wiring is a later integration concern, never this Logic-type story's.
##
## Proves, against [NeedsMood] directly (mocked [TimeTickSystem] boundary,
## same `MockTimeTickSystem` double every needs_mood test file already
## establishes):
## 1. **AC30 (upgrade + downgrade)**: a source change mid-Recovering (a
##    second [method NeedsMood.start_recovery] call with a different
##    `source_enum`) applies the new rate from the NEXT tick only — no
##    restart, no signal, all prior progress retained (Edge Case 11).
## 2. **AC13**: an interruption landing ABOVE `urgency_threshold` re-enters
##    Satisfied with NO event, decay resumes normally, and Urgent re-triggers
##    exactly once at the next downward 25-cross (Edge Case 1, above-threshold
##    branch).
## 3. **AC31**: an interruption landing AT/BELOW `urgency_threshold` re-enters
##    Urgent with NO new event, decay resumes, state reads Urgent throughout
##    (Edge Case 1, below-threshold branch).
## 4. **Edge Case 3 (revocation)**: `stop_recovery` lands before the tick's
##    F-pass — that tick credits ZERO recovery (F1 decay only), and the exit
##    state is decided purely by the current value (Urgent branch, reason
##    `&"revoked"`, distinct from `recovery_source_rate_table_test.gd`'s own
##    Satisfied-branch intra-tick-ordering test).
## 5. **Reason-independence**: `&"woke"`/`&"revoked"`/`&"preempted"` produce
##    byte-identical value/state outcomes — `reason` is diagnostic only.
## 6. **Edge cases**: a source changed twice within one tick — the last write
##    before the F-pass wins; a source change landing the same tick as the
##    satisfied cross — the cross still fires exactly once; `stop_recovery` on
##    the EXACT threshold value (25.0) resolves to Urgent (`<=` rule, never
##    `<`) with no emission.
##
## Per this codebase's own established convention (`decay_state_machine_test.
## gd`, `recovery_source_rate_table_test.gd`): signal-count assertions use a
## direct `.connect()` listener that APPENDS to a captured `Array`, never a
## reassigned captured scalar. Every input is a fixed literal — deterministic,
## no random seeds, no wall-clock assertions, no scene tree, no Autoload
## registration.
class_name NeedsMoodRecoveryInterruptionAndReratingTest
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


# ---------------------------------------------------------------------------
# AC30 — mid-recovery re-rating (upgrade + downgrade), no restart, no signal
# ---------------------------------------------------------------------------

func test_ac30_upgrade_mid_recovery_applies_full_rate_next_tick_no_restart_no_signal() -> void:
	# Arrange — Recovering at bed_unsheltered (x0.7), value = 40.0 (story's
	# own QA Test Case).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var urgent_emissions: Array = _capture_need_urgent(needs_mood)
	var satisfied_emissions: Array = _capture_need_satisfied(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 40.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_UNSHELTERED)

	# Act — one tick at the OLD (unsheltered) rate: prior progress the
	# upgrade must retain.
	mock_tick.fire_tick()
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(40.35, 0.0001)

	# Act — the upgrade: shelter_status_changed is mocked here as a second
	# start_recovery call with the new source_enum (this story's own
	# Implementation Notes) — the mutation path, no restart.
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)

	# Act — the very next tick: the FULL rate applies immediately.
	mock_tick.fire_tick()

	# Assert — 40.35 + 0.5 * 1.0 == 40.85: prior progress retained, full rate
	# from the next tick, still Recovering, no signal of either kind ever.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(40.85, 0.0001)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.RECOVERING)
	assert_int(urgent_emissions.size()).is_equal(0)
	assert_int(satisfied_emissions.size()).is_equal(0)


func test_ac30_downgrade_mid_recovery_applies_lower_rate_next_tick_no_restart_no_signal() -> void:
	# Arrange — the mirror case: Recovering at bed_sheltered (x1.0),
	# value = 40.0.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var urgent_emissions: Array = _capture_need_urgent(needs_mood)
	var satisfied_emissions: Array = _capture_need_satisfied(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 40.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)

	# Act — one tick at the OLD (sheltered) rate.
	mock_tick.fire_tick()
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(40.5, 0.0001)

	# Act — the downgrade (roof removed mid-sleep).
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_UNSHELTERED)
	mock_tick.fire_tick()

	# Assert — 40.5 + 0.5 * 0.7 == 40.85: same no-restart/no-signal guarantees
	# with the LOWER rate identically applied.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(40.85, 0.0001)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.RECOVERING)
	assert_int(urgent_emissions.size()).is_equal(0)
	assert_int(satisfied_emissions.size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC13 — interruption above threshold: Satisfied, no event, decay resumes,
# Urgent re-triggers exactly once at the next 25-cross
# ---------------------------------------------------------------------------

func test_ac13_interruption_above_threshold_reenters_satisfied_and_recrosses_urgent_once() -> void:
	# Arrange — Recovering, value = 60.0 (story's own QA Test Case).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var urgent_emissions: Array = _capture_need_urgent(needs_mood)
	var satisfied_emissions: Array = _capture_need_satisfied(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 60.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)

	# Act — the interruption itself.
	needs_mood.stop_recovery(1, &"sleep", &"preempted")

	# Assert — Satisfied by value alone, not a limbo state; zero events from
	# the interruption itself.
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.SATISFIED)
	assert_int(urgent_emissions.size()).is_equal(0)
	assert_int(satisfied_emissions.size()).is_equal(0)

	# Act — decay resumes silently (F1, not F2).
	mock_tick.fire_tick()
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(59.93, 0.0001)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.SATISFIED)
	assert_int(urgent_emissions.size()).is_equal(0)

	# Act — reposition to the edge of the next downward cross (the same
	# precise-crossing arrangement `decay_state_machine_test.gd`'s own AC3
	# test establishes) — test setup only, never a production "reset";
	# set_need_value itself never emits (its own documented guarantee).
	needs_mood.set_need_value(1, &"sleep", 25.04)
	assert_int(urgent_emissions.size()).is_equal(0)

	# Act — the next 25-cross.
	mock_tick.fire_tick()

	# Assert — exactly one need_urgent, ever; no need_satisfied anywhere;
	# state now reads Urgent.
	assert_int(urgent_emissions.size()).is_equal(1)
	assert_array(urgent_emissions[0]).is_equal([1, &"sleep"])
	assert_int(satisfied_emissions.size()).is_equal(0)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)


# ---------------------------------------------------------------------------
# AC31 — interruption at/below threshold: Urgent by value, no second event
# ---------------------------------------------------------------------------

func test_ac31_interruption_below_threshold_reenters_urgent_with_no_new_signal() -> void:
	# Arrange — value = 18.0, already at/below urgency_threshold (story's own
	# QA Test Case). Arranged directly via set_need_value (never emits, per
	# its own doc comment) — the "original edge" this Edge Case 1 branch
	# refers to is decay_state_machine_test.gd's own AC3/AC7 territory; this
	# test's sole job is the STOP path's own no-second-emission guarantee.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var urgent_emissions: Array = _capture_need_urgent(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 18.0)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)
	assert_int(urgent_emissions.size()).is_equal(0)

	# Act — the interruption while still at/below threshold.
	needs_mood.stop_recovery(1, &"sleep", &"woke")

	# Assert — Urgent by value, NO new urgent event.
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)
	assert_int(urgent_emissions.size()).is_equal(0)

	# Act — decay resumes; state reads Urgent throughout.
	mock_tick.fire_tick()
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(17.93, 0.0001)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)
	assert_int(urgent_emissions.size()).is_equal(0)


# ---------------------------------------------------------------------------
# Edge Case 3 — bed revoked mid-recovery: zero recovery credited that tick
# ---------------------------------------------------------------------------

func test_edge_case_3_revocation_credits_zero_recovery_and_exits_by_value_urgent_branch() -> void:
	# Arrange — Recovering from bed_sheltered, one tick of real progress,
	# still below satisfied_threshold. Distinct from
	# `recovery_source_rate_table_test.gd`'s own intra-tick-ordering test
	# (which lands in the Satisfied branch) — this pins the Urgent-branch
	# revocation outcome with `reason = &"revoked"` explicitly.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 20.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)
	mock_tick.fire_tick()
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(20.5, 0.0001)

	# Act — Villager AI's chain reaction to Building System's bed-revocation
	# event lands here as a synchronous stop_recovery call, BEFORE the next
	# tick's F-pass (Core Rule 10 / this system holds no bed reference and
	# performs no wake behavior itself).
	needs_mood.stop_recovery(1, &"sleep", &"revoked")
	mock_tick.fire_tick()

	# Assert — that tick credited ZERO recovery: the value moved by F1's
	# decay only (20.5 - 0.07 == 20.43), never F2's increment. Exit state is
	# purely by current value: 20.43 <= 25 -> Urgent.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(20.43, 0.0001)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)


# ---------------------------------------------------------------------------
# Reason-independence — the `reason` argument is diagnostic only
# ---------------------------------------------------------------------------

func test_reason_argument_never_changes_arithmetic_or_exit_state() -> void:
	# Arrange + Act — identical starting conditions and timing, three
	# different `reason` values, each on its own fresh instance.
	var reasons: Array[StringName] = [&"woke", &"revoked", &"preempted"]
	var final_values: Array[float] = []
	var final_states: Array[NeedsMood.NeedState] = []
	for reason: StringName in reasons:
		var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
		var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
		needs_mood.set_need_value(1, &"sleep", 50.0)
		needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)
		mock_tick.fire_tick()
		needs_mood.stop_recovery(1, &"sleep", reason)
		mock_tick.fire_tick()
		final_values.append(needs_mood.get_need_value(1, &"sleep"))
		final_states.append(needs_mood.get_need_state(1, &"sleep"))

	# Assert — all three runs produce byte-identical value and state.
	assert_float(final_values[1]).is_equal_approx(final_values[0], 0.0001)
	assert_float(final_values[2]).is_equal_approx(final_values[0], 0.0001)
	assert_int(final_states[1]).is_equal(final_states[0])
	assert_int(final_states[2]).is_equal(final_states[0])
	# Sanity — the shared value is exactly the expected F2-then-F1 result
	# (50.0 + 0.5*1.0 = 50.5, then 50.5 - 0.07 = 50.43), not a coincidental 0.0.
	assert_float(final_values[0]).is_equal_approx(50.43, 0.0001)


# ---------------------------------------------------------------------------
# Edge cases — QA Test Case list
# ---------------------------------------------------------------------------

func test_edge_source_changed_twice_within_one_tick_last_write_wins() -> void:
	# Arrange — two source changes land before the SAME tick's F-pass; only
	# the last write before that pass may take effect.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	needs_mood.set_need_value(1, &"sleep", 30.0)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.GROUND_NO_BED_OWNED)  # x0.4
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_UNSHELTERED)      # x0.7 (overwritten)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)        # x1.0 (last write)

	# Act
	mock_tick.fire_tick()

	# Assert — 30.0 + 0.5 * 1.0 == 30.5 (the LAST write, never 0.4 or 0.7).
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(30.5, 0.0001)


func test_edge_source_changed_same_tick_as_satisfied_cross_fires_exactly_once() -> void:
	# Arrange — a source change lands before the very tick that also crosses
	# satisfied_threshold — the cross must still fire exactly once, off the
	# NEW rate.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var satisfied_emissions: Array = _capture_need_satisfied(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 94.8)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_UNSHELTERED)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)

	# Act — the crossing tick, at the NEW (sheltered) rate.
	mock_tick.fire_tick()

	# Assert — 94.8 + 0.5 * 1.0 == 95.3 (overshoot retained), exactly one
	# emission, state Satisfied.
	assert_float(needs_mood.get_need_value(1, &"sleep")).is_equal_approx(95.3, 0.0001)
	assert_int(satisfied_emissions.size()).is_equal(1)
	assert_array(satisfied_emissions[0]).is_equal([1, &"sleep"])
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.SATISFIED)

	# Act — a further tick must not re-emit.
	mock_tick.fire_tick()
	assert_int(satisfied_emissions.size()).is_equal(1)


func test_edge_stop_recovery_at_exact_threshold_value_resolves_to_urgent_with_no_emission() -> void:
	# Arrange — value == urgency_threshold exactly (25.0), the `<=` rule
	# (never `<`).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(mock_tick)
	var urgent_emissions: Array = _capture_need_urgent(needs_mood)
	var satisfied_emissions: Array = _capture_need_satisfied(needs_mood)
	needs_mood.set_need_value(1, &"sleep", 25.0)
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)
	needs_mood.start_recovery(1, &"sleep", NeedsMood.RecoverySource.BED_SHELTERED)

	# Act
	needs_mood.stop_recovery(1, &"sleep", &"woke")

	# Assert — resolves to Urgent (25.0 is not `>` 25.0), no emission at all.
	assert_int(needs_mood.get_need_state(1, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)
	assert_int(urgent_emissions.size()).is_equal(0)
	assert_int(satisfied_emissions.size()).is_equal(0)
