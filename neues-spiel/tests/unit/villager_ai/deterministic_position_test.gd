## Unit test — Villager AI story 004 (deterministic position model &
## movement interpolation, ADR-0009 Decision §1).
##
## Proves, against [VillagerAi.get_current_cell] / [VillagerAi.
## advance_travel_progress] / [VillagerAi._on_tick] / [VillagerAi._process]:
## 1. **get_current_cell mid-transit (story AC)**: returns `_from_cell`,
##    never `_to_cell` and never an interpolation-derived value, for any
##    progress strictly between 0 and 1, and at the exact boundaries 0.0 and
##    1.0 -- the 1.0 case specifically proving the boundary does NOT itself
##    flip `current_cell` before the tick-boundary function runs.
## 2. **Atomic tick-boundary arrival crediting (story AC)**: `current_cell`
##    updates to `_to_cell` in a single assignment inside `_on_tick()` --
##    never earlier, never derived from interpolation progress -- and stays
##    unchanged while progress is incomplete; idempotent once credited.
## 3. **AC13 (never partial credit, incl. a 1-cell adjacent step)**: reaching
##    progress 1.0 via `advance_travel_progress()` alone never flips
##    `current_cell` -- only the explicit tick-boundary function does, one
##    tick later.
## 4. **AC20 ([TR-villager-ai-behavior-093])**: a property check over >= 5
##    injected `game_delta` samples (incl. a warped-magnitude one and a
##    clamped/overshoot one) against `advance_travel_progress()` directly --
##    per-call displacement never exceeds `move_speed * game_delta`.
## 5. **AC21 (pause/warp invariance)**: `game_delta = 0.0` (pause) leaves
##    progress and `_visual_position` unchanged across repeated calls; a 2x
##    warped `game_delta` completes the same step in half the real-frame
##    calls of an unwarped run; total accumulated game-time cost to complete
##    a step is warp-invariant.
## 6. **F1 step-length classification**: orthogonal steps use `1.0`,
##    diagonal steps use `1.4`, a zero-length (`from == to`) step snaps
##    progress straight to `1.0` immediately.
class_name DeterministicPositionTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

## Pure position-model functions need only `config` wired -- no
## `voxel_world`, no `time_tick_system`, no `setup()` call, no scene tree
## (AC20: "drivable directly... no real engine frames"). Story
## villager-ai-005: `_on_tick()` now also dispatches through `_tick_state()`,
## whose `State.DECIDING` branch reads `scheduler` -- wired here (a fresh,
## unshared instance; these tests never populate its queue) so calling
## `_on_tick()` directly never crashes on a null scheduler.
func _make_villager_ai() -> VillagerAi:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.config = VillagerAIConfig.new()
	villager_ai.scheduler = VillagerDecidingScheduler.new()
	return villager_ai


func _set_travel_step(
	villager_ai: VillagerAi, from_cell: Vector3i, to_cell: Vector3i, progress: float
) -> void:
	villager_ai.current_cell = from_cell
	villager_ai._from_cell = from_cell
	villager_ai._to_cell = to_cell
	villager_ai._intra_tick_progress = progress


# ---------------------------------------------------------------------------
# get_current_cell — always the discrete from_cell, never to_cell/derived
# ---------------------------------------------------------------------------

func test_get_current_cell_mid_transit_returns_from_cell() -> void:
	var villager_ai: VillagerAi = _make_villager_ai()
	var from_cell := Vector3i(2, 0, 3)
	var to_cell := Vector3i(3, 0, 3)
	_set_travel_step(villager_ai, from_cell, to_cell, 0.5)

	assert_vector(Vector3(villager_ai.get_current_cell())).is_equal(Vector3(from_cell))


func test_get_current_cell_at_progress_zero_edge_returns_from_cell() -> void:
	var villager_ai: VillagerAi = _make_villager_ai()
	var from_cell := Vector3i(5, 0, 5)
	var to_cell := Vector3i(5, 0, 6)
	_set_travel_step(villager_ai, from_cell, to_cell, 0.0)

	assert_vector(Vector3(villager_ai.get_current_cell())).is_equal(Vector3(from_cell))


func test_get_current_cell_at_progress_one_edge_before_tick_boundary_still_returns_from_cell() -> void:
	# Edge case explicitly named by the story AC: progress reaching exactly
	# 1.0 must NOT itself flip current_cell -- only _on_tick()'s explicit
	# tick-boundary assignment does, proving get_current_cell() never
	# derives its answer from the progress value itself.
	var villager_ai: VillagerAi = _make_villager_ai()
	var from_cell := Vector3i(0, 0, 0)
	var to_cell := Vector3i(1, 0, 0)
	_set_travel_step(villager_ai, from_cell, to_cell, 1.0)

	assert_vector(Vector3(villager_ai.get_current_cell())).is_equal(Vector3(from_cell))


# ---------------------------------------------------------------------------
# Atomic tick-boundary arrival crediting (_on_tick)
# ---------------------------------------------------------------------------

func test_on_tick_credits_arrival_atomically_when_progress_complete() -> void:
	var villager_ai: VillagerAi = _make_villager_ai()
	var from_cell := Vector3i(4, 0, 4)
	var to_cell := Vector3i(5, 0, 4)
	_set_travel_step(villager_ai, from_cell, to_cell, 1.0)

	villager_ai._on_tick()

	assert_vector(Vector3(villager_ai.get_current_cell())).is_equal(Vector3(to_cell))


func test_on_tick_does_not_flip_current_cell_when_progress_incomplete() -> void:
	var villager_ai: VillagerAi = _make_villager_ai()
	var from_cell := Vector3i(0, 0, 0)
	var to_cell := Vector3i(0, 0, 1)
	_set_travel_step(villager_ai, from_cell, to_cell, 0.7)

	villager_ai._on_tick()

	assert_vector(Vector3(villager_ai.get_current_cell())).is_equal(Vector3(from_cell))


func test_on_tick_credit_is_idempotent_after_arrival() -> void:
	var villager_ai: VillagerAi = _make_villager_ai()
	var from_cell := Vector3i(0, 0, 0)
	var to_cell := Vector3i(1, 0, 0)
	_set_travel_step(villager_ai, from_cell, to_cell, 1.0)
	villager_ai._on_tick()

	# A later tick, with no new travel step begun, is a harmless no-op.
	villager_ai._on_tick()

	assert_vector(Vector3(villager_ai.get_current_cell())).is_equal(Vector3(to_cell))


# ---------------------------------------------------------------------------
# AC13 — first work-progress increment credited at the NEXT tick boundary,
# never partial, incl. a 1-cell adjacent step
# ---------------------------------------------------------------------------

func test_advance_travel_progress_reaching_completion_does_not_itself_credit_arrival() -> void:
	# A 1-cell orthogonal step (step_length 1.0) at default move_speed 3.0 --
	# a single large game_delta drives progress to completion in one call.
	var villager_ai: VillagerAi = _make_villager_ai()
	var from_cell := Vector3i(0, 0, 0)
	var to_cell := Vector3i(1, 0, 0)
	_set_travel_step(villager_ai, from_cell, to_cell, 0.0)

	villager_ai.advance_travel_progress(1.0)

	# Progress reached 1.0, but current_cell is unaffected --
	# advance_travel_progress() never touches it.
	assert_float(villager_ai._intra_tick_progress).is_equal_approx(1.0, 0.0001)
	assert_vector(Vector3(villager_ai.get_current_cell())).is_equal(Vector3(from_cell))

	# Only the explicit tick-boundary function credits arrival -- one tick
	# later, exactly once.
	villager_ai._on_tick()
	assert_vector(Vector3(villager_ai.get_current_cell())).is_equal(Vector3(to_cell))


# ---------------------------------------------------------------------------
# AC20 — per-step displacement never exceeds move_speed * game_delta
# (property check, >= 5 samples, includes a warped-magnitude and a
# clamped/overshoot sample)
# ---------------------------------------------------------------------------

func test_advance_travel_progress_displacement_never_exceeds_move_speed_times_game_delta() -> void:
	var move_speed: float = 3.0
	var step_length: float = 1.0
	# 6 samples (>= 5 required): small, mid, and large/warp-magnitude
	# deltas, plus one deliberately large enough to force the [0,1] clamp --
	# clamping can only REDUCE displacement below the bound, never exceed it.
	var samples: Array[float] = [0.01, 0.033, 0.07, 0.1, 0.2, 1.0]

	for game_delta: float in samples:
		var villager_ai: VillagerAi = _make_villager_ai()
		villager_ai.config.move_speed = move_speed
		_set_travel_step(villager_ai, Vector3i(0, 0, 0), Vector3i(1, 0, 0), 0.0)

		var progress_before: float = villager_ai._intra_tick_progress
		villager_ai.advance_travel_progress(game_delta)
		var progress_after: float = villager_ai._intra_tick_progress

		var displacement_cells: float = (progress_after - progress_before) * step_length
		var bound: float = move_speed * game_delta

		assert_bool(displacement_cells <= bound + 0.0001).is_true().override_failure_message(
			"game_delta=%s: displacement %s exceeded bound %s" % [game_delta, displacement_cells, bound]
		)


# ---------------------------------------------------------------------------
# AC21 — pause freezes position; 2x warp halves wall-clock for the same
# game-time cost
# ---------------------------------------------------------------------------

func test_advance_travel_progress_pause_zero_delta_leaves_progress_unchanged() -> void:
	var villager_ai: VillagerAi = _make_villager_ai()
	_set_travel_step(villager_ai, Vector3i(0, 0, 0), Vector3i(1, 0, 0), 0.3)

	villager_ai.advance_travel_progress(0.0)
	villager_ai.advance_travel_progress(0.0)
	villager_ai.advance_travel_progress(0.0)

	assert_float(villager_ai._intra_tick_progress).is_equal_approx(0.3, 0.0001)


func test_process_visual_position_frozen_during_pause_across_repeated_frames() -> void:
	var villager_ai: VillagerAi = _make_villager_ai()
	_set_travel_step(villager_ai, Vector3i(0, 0, 0), Vector3i(1, 0, 0), 0.4)

	villager_ai._process(0.016)
	var first_position: Vector3 = villager_ai._visual_position

	# Simulate paused frames: game_delta stays 0, so progress never advances.
	villager_ai.advance_travel_progress(0.0)
	villager_ai._process(0.016)
	var second_position: Vector3 = villager_ai._visual_position

	# Even an unusually large raw _delta must not matter -- _process() never
	# reads its own parameter.
	villager_ai.advance_travel_progress(0.0)
	villager_ai._process(0.5)
	var third_position: Vector3 = villager_ai._visual_position

	var epsilon := Vector3(0.0001, 0.0001, 0.0001)
	assert_vector(second_position).is_equal_approx(first_position, epsilon)
	assert_vector(third_position).is_equal_approx(first_position, epsilon)


func test_advance_travel_progress_2x_warp_completes_step_in_half_the_frames() -> void:
	# step_length 1.0, move_speed 3.0 -> total game-time cost to complete =
	# 1.0/3.0 game-seconds. At a fixed real frame rate (1/60s raw), 1x warp
	# needs 20 frames (20 * 1/60 = 0.3333); 2x warp needs only 10
	# (10 * 2/60 = 0.3333) -- the SAME game-time cost, half the wall-clock
	# frame count.
	var unwarped: VillagerAi = _make_villager_ai()
	_set_travel_step(unwarped, Vector3i(0, 0, 0), Vector3i(1, 0, 0), 0.0)
	for _i in range(10):
		unwarped.advance_travel_progress(1.0 / 60.0)
	# Only half the real-time frames a 1x run needs -- still incomplete.
	assert_float(unwarped._intra_tick_progress).is_equal_approx(0.5, 0.01)

	var warped: VillagerAi = _make_villager_ai()
	_set_travel_step(warped, Vector3i(0, 0, 0), Vector3i(1, 0, 0), 0.0)
	for _i in range(10):
		warped.advance_travel_progress(2.0 / 60.0)
	# Same 10 real-time frames, but 2x warp completes the step -- proving
	# wall-clock travel halved for the identical game-time cost.
	assert_float(warped._intra_tick_progress).is_equal_approx(1.0, 0.01)


func test_advance_travel_progress_total_game_time_to_complete_is_warp_invariant() -> void:
	# The SAME total game-time cost (step_length / move_speed) completes the
	# step whether delivered as many small unwarped deltas or as one lump
	# delta of that same total -- proving warp accelerates wall-clock only,
	# never the underlying game-time cost (F1 game-time invariance,
	# [TR-villager-ai-behavior-073]).
	var step_length: float = 1.0
	var move_speed: float = 3.0
	var total_game_seconds: float = step_length / move_speed

	var from_many_small_deltas: VillagerAi = _make_villager_ai()
	_set_travel_step(from_many_small_deltas, Vector3i(0, 0, 0), Vector3i(1, 0, 0), 0.0)
	var per_frame_delta: float = total_game_seconds / 20.0
	for _i in range(20):
		from_many_small_deltas.advance_travel_progress(per_frame_delta)

	var from_one_lump_delta: VillagerAi = _make_villager_ai()
	_set_travel_step(from_one_lump_delta, Vector3i(0, 0, 0), Vector3i(1, 0, 0), 0.0)
	from_one_lump_delta.advance_travel_progress(total_game_seconds)

	assert_float(from_many_small_deltas._intra_tick_progress).is_equal_approx(1.0, 0.001)
	assert_float(from_one_lump_delta._intra_tick_progress).is_equal_approx(1.0, 0.001)


# ---------------------------------------------------------------------------
# F1 step-length classification — orthogonal 1.0, diagonal 1.4, zero-length
# snaps to progress 1.0 immediately
# ---------------------------------------------------------------------------

func test_advance_travel_progress_orthogonal_step_uses_unit_length() -> void:
	var villager_ai: VillagerAi = _make_villager_ai()
	_set_travel_step(villager_ai, Vector3i(0, 0, 0), Vector3i(1, 0, 0), 0.0)

	villager_ai.advance_travel_progress(1.0 / 3.0)

	assert_float(villager_ai._intra_tick_progress).is_equal_approx(1.0, 0.001)


func test_advance_travel_progress_diagonal_step_uses_1_4_length() -> void:
	var villager_ai: VillagerAi = _make_villager_ai()
	_set_travel_step(villager_ai, Vector3i(0, 0, 0), Vector3i(1, 0, 1), 0.0)

	# A full diagonal step (1.4 cells at move_speed 3.0) takes 1.4/3.0
	# game-seconds -- feeding exactly that much completes it.
	villager_ai.advance_travel_progress(1.4 / 3.0)

	assert_float(villager_ai._intra_tick_progress).is_equal_approx(1.0, 0.001)


func test_advance_travel_progress_diagonal_step_incomplete_at_orthogonal_duration() -> void:
	# Proves 1.4 is actually used (not silently 1.0): the same game-time that
	# fully completes an orthogonal step leaves a diagonal step short.
	var villager_ai: VillagerAi = _make_villager_ai()
	_set_travel_step(villager_ai, Vector3i(0, 0, 0), Vector3i(1, 0, 1), 0.0)

	villager_ai.advance_travel_progress(1.0 / 3.0)

	assert_float(villager_ai._intra_tick_progress).is_less(1.0)


func test_advance_travel_progress_zero_length_step_snaps_to_complete() -> void:
	# F1: "0 is valid (target is the current/adjacent cell)... immediate
	# arrival" -- the from == to case.
	var villager_ai: VillagerAi = _make_villager_ai()
	_set_travel_step(villager_ai, Vector3i(2, 0, 2), Vector3i(2, 0, 2), 0.0)

	villager_ai.advance_travel_progress(0.001)

	assert_float(villager_ai._intra_tick_progress).is_equal(1.0)


# ---------------------------------------------------------------------------
# physics_interpolation_mode = OFF (ADR-0009 Engine Notes/Risks -- defensive
# double-interpolation guard)
# ---------------------------------------------------------------------------

func test_setup_sets_physics_interpolation_mode_off() -> void:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.config = VillagerAIConfig.new()
	villager_ai.voxel_world = auto_free(VoxelWorldGrid.new())
	villager_ai.scheduler = VillagerDecidingScheduler.new()
	villager_ai.time_tick_system = auto_free(MockTimeTickSystem.new())

	villager_ai.setup()

	assert_int(villager_ai.physics_interpolation_mode).is_equal(
		Node.PHYSICS_INTERPOLATION_MODE_OFF
	)
