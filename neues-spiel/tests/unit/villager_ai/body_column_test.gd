## Unit test — Villager AI story 003 (body-column occupancy model, ADR-0009
## slice propagation, GDD Rule 8a/[TR-villager-ai-behavior-098]).
##
## Proves, against [VillagerAi.body_column] / [VillagerAi.is_cell_in_body_column]:
## 1. **Column derivation (story AC2)**: given a discrete cell, `body_column`
##    returns the deterministic 3-cell vertical span (feet + body + buffer
##    headroom), same input always the same output.
## 2. **Same span as standability clearance (story AC1)**: the column is
##    exactly [VillagerAi.VILLAGER_CLEARANCE] cells tall, matching the span
##    [VillagerAi.is_standable] already checks — no second constant.
## 3. **Feet-only insufficiency (story AC3 / QA plan)**: a feet-only
##    comparison (`query_cell == occupant_cell`) misses the body cell and the
##    buffer headroom cell — `is_cell_in_body_column` catches both, proving
##    the column is required and a feet-only check is a defect.
## 4. **Interpolation-free / purity**: both functions take plain `Vector3i`
##    values only — no villager instance, no `_visual_position` — and are
##    side-effect-free/deterministic across repeated calls.
class_name BodyColumnTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

func _make_villager_ai() -> VillagerAi:
	# body_column()/is_cell_in_body_column() are pure Vector3i functions —
	# no voxel_world dependency, no setup() call needed for this story's API.
	return auto_free(VillagerAi.new())


# ---------------------------------------------------------------------------
# AC (column derivation) — deterministic 3-cell vertical span
# ---------------------------------------------------------------------------

func test_body_column_returns_feet_body_and_buffer_cells() -> void:
	# Arrange
	var villager_ai: VillagerAi = _make_villager_ai()
	var feet: Vector3i = Vector3i(2, 5, 3)

	# Act
	var column: Array[Vector3i] = villager_ai.body_column(feet)

	# Assert — feet + body (one above) + buffer headroom (two above).
	assert_array(column).contains_exactly([
		Vector3i(2, 5, 3),
		Vector3i(2, 6, 3),
		Vector3i(2, 7, 3),
	])


func test_body_column_length_matches_villager_clearance() -> void:
	# Arrange — story AC1: the body-column is the SAME 3-cell span as
	# standability clearance (2-cell body + 1 buffer cell), no new constant.
	var villager_ai: VillagerAi = _make_villager_ai()

	# Act
	var column: Array[Vector3i] = villager_ai.body_column(Vector3i(0, 0, 0))

	# Assert
	assert_int(column.size()).is_equal(VillagerAi.VILLAGER_CLEARANCE)


func test_body_column_same_input_always_same_output() -> void:
	# Arrange — determinism (story AC2 edge case).
	var villager_ai: VillagerAi = _make_villager_ai()
	var cell: Vector3i = Vector3i(-4, 1, 8)

	# Act
	var first: Array[Vector3i] = villager_ai.body_column(cell)
	var second: Array[Vector3i] = villager_ai.body_column(cell)

	# Assert
	assert_array(first).contains_exactly(second)


# ---------------------------------------------------------------------------
# AC (feet-only insufficiency) — a feet-only check misses body/buffer cells
# ---------------------------------------------------------------------------

func test_is_cell_in_body_column_body_cell_is_occupied() -> void:
	# Arrange — a villager standing (feet) at (0,1,0); the body cell directly
	# above the feet is (0,2,0). A naive feet-only comparison
	# (query_cell == occupant_cell) would report this as NOT occupied — the
	# exact defect this story's column check must prevent.
	var villager_ai: VillagerAi = _make_villager_ai()
	var occupant_cell: Vector3i = Vector3i(0, 1, 0)
	var body_cell: Vector3i = Vector3i(0, 2, 0)

	# Act
	var feet_only_check: bool = body_cell == occupant_cell
	var column_check: bool = villager_ai.is_cell_in_body_column(occupant_cell, body_cell)

	# Assert — feet-only check incorrectly says "not occupied"; the
	# body-column check correctly reports it as occupied.
	assert_bool(feet_only_check).is_false()
	assert_bool(column_check).is_true()


func test_is_cell_in_body_column_buffer_headroom_cell_is_occupied() -> void:
	# Arrange — the topmost buffer headroom cell (two above feet) is also
	# part of the villager's space and must be caught.
	var villager_ai: VillagerAi = _make_villager_ai()
	var occupant_cell: Vector3i = Vector3i(0, 1, 0)
	var buffer_cell: Vector3i = Vector3i(0, 3, 0)

	# Act + Assert
	assert_bool(villager_ai.is_cell_in_body_column(occupant_cell, buffer_cell)).is_true()


func test_is_cell_in_body_column_feet_cell_itself_is_occupied() -> void:
	# Arrange + Act + Assert — the feet cell itself is trivially in its own
	# column (occupant_cell == query_cell case still holds).
	var villager_ai: VillagerAi = _make_villager_ai()
	var occupant_cell: Vector3i = Vector3i(4, 2, 1)

	assert_bool(villager_ai.is_cell_in_body_column(occupant_cell, occupant_cell)).is_true()


func test_is_cell_in_body_column_cell_outside_column_returns_false() -> void:
	# Arrange — a cell one above the buffer headroom cell (outside the
	# 3-cell span) must NOT be reported as occupied.
	var villager_ai: VillagerAi = _make_villager_ai()
	var occupant_cell: Vector3i = Vector3i(0, 1, 0)
	var above_buffer_cell: Vector3i = Vector3i(0, 4, 0)

	# Act + Assert
	assert_bool(villager_ai.is_cell_in_body_column(occupant_cell, above_buffer_cell)).is_false()


func test_is_cell_in_body_column_cell_below_feet_returns_false() -> void:
	# Arrange — the ground cell below the feet is not part of the villager's
	# own body-column (it's what the villager stands ON, per is_standable).
	var villager_ai: VillagerAi = _make_villager_ai()
	var occupant_cell: Vector3i = Vector3i(0, 1, 0)
	var ground_cell: Vector3i = Vector3i(0, 0, 0)

	# Act + Assert
	assert_bool(villager_ai.is_cell_in_body_column(occupant_cell, ground_cell)).is_false()


func test_is_cell_in_body_column_different_horizontal_cell_returns_false() -> void:
	# Arrange — a cell at the same height but a different (x, z) column
	# entirely is never part of this villager's body-column.
	var villager_ai: VillagerAi = _make_villager_ai()
	var occupant_cell: Vector3i = Vector3i(0, 1, 0)
	var neighbor_cell: Vector3i = Vector3i(1, 1, 0)

	# Act + Assert
	assert_bool(villager_ai.is_cell_in_body_column(occupant_cell, neighbor_cell)).is_false()


# ---------------------------------------------------------------------------
# Purity / determinism (Control Manifest Feature Layer Guardrail — no
# mutation, no cached state; ADR-0009: interpolation-free, no villager
# instance or `_visual_position` involved anywhere in these signatures)
# ---------------------------------------------------------------------------

func test_is_cell_in_body_column_recomputed_twice_yields_identical_result() -> void:
	# Arrange
	var villager_ai: VillagerAi = _make_villager_ai()
	var occupant_cell: Vector3i = Vector3i(0, 1, 0)
	var query_cell: Vector3i = Vector3i(0, 2, 0)

	# Act — same inputs, two separate calls (no caching anywhere).
	var first: bool = villager_ai.is_cell_in_body_column(occupant_cell, query_cell)
	var second: bool = villager_ai.is_cell_in_body_column(occupant_cell, query_cell)

	# Assert
	assert_bool(first).is_equal(second)


func test_body_column_called_from_a_second_consumer_site_yields_identical_result() -> void:
	# Arrange — simulates a second consumer (e.g. a future seal-prevention
	# check, story 016) calling the exact same shared predicate instance --
	# identical inputs must produce identical results (ADR-0007's
	# "single source of truth" contract, extended to this story's API).
	var villager_ai: VillagerAi = _make_villager_ai()
	var cell: Vector3i = Vector3i(7, 3, -2)

	# Act
	var from_watchdog_call: Array[Vector3i] = villager_ai.body_column(cell)
	var from_seal_prevention_call: Array[Vector3i] = villager_ai.body_column(cell)

	# Assert
	assert_array(from_watchdog_call).contains_exactly(from_seal_prevention_call)
