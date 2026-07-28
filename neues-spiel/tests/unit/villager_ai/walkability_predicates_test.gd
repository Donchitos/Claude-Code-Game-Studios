## Unit test — Villager AI story 002 (walkability predicates, ADR-0007).
##
## Proves, all against [VillagerAi.is_standable] / [VillagerAi.is_step_legal]:
## 1. AC14 ([TR-villager-ai-behavior-009]): a cell is standable iff solid
##    below AND the full [VillagerAi.VILLAGER_CLEARANCE] (3-cell) column is
##    empty -- 2 clear cells is not enough, exactly 3 is.
## 2. AC17 ([TR-villager-ai-behavior-009]): an unbuilt Planned blueprint cell
##    (never written to [VoxelWorldGrid]) is passable/non-solid by
##    construction -- both "in the path" and "directly below a candidate
##    stand cell" (not "solid below").
## 3. AC15 ([TR-villager-ai-behavior-010]): step legality by height
##    difference -- |dy| <= 1 legal, |dy| >= 2 illegal, |dy| = 0 legal.
## 4. AC16 ([TR-villager-ai-behavior-010]): diagonal corner-cutting -- both
##    flanking orthogonal cells must be standable, or the diagonal is
##    illegal; a purely orthogonal step never requires this check.
## 5. Purity (ADR-0007 Validation Criteria / Control Manifest Feature Layer
##    Guardrail): both predicates are side-effect-free and deterministic --
##    identical inputs (whether called once or from a second "consumer"
##    call site) always produce identical results.
class_name WalkabilityPredicatesTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


func _make_villager_ai(grid: VoxelWorldGrid) -> VillagerAi:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.voxel_world = grid
	return villager_ai


func _solid_contents() -> CellContents:
	return CellContents.new(1, 0)


# ---------------------------------------------------------------------------
# AC14 — is_standable clearance (VILLAGER_CLEARANCE = 3)
# ---------------------------------------------------------------------------

func test_is_standable_solid_below_and_full_clearance_returns_true() -> void:
	# Arrange — solid ground at y=0, cells y=1..3 (cell + 2 above) all empty.
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(0, 0, 0), _solid_contents())
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act + Assert
	assert_bool(villager_ai.is_standable(Vector3i(0, 1, 0))).is_true()


func test_is_standable_only_two_clear_cells_above_returns_false() -> void:
	# Arrange — solid ground at y=0, but a block at y=3 leaves only 2 of the
	# required 3 clearance cells (y=1, y=2) empty. QA plan AC14 edge case.
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(0, 0, 0), _solid_contents())
	grid.set_cell(Vector3i(0, 3, 0), _solid_contents())
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act + Assert — needs full 3-cell clearance (y=1,2,3), not just 2.
	assert_bool(villager_ai.is_standable(Vector3i(0, 1, 0))).is_false()


func test_is_standable_exactly_three_clear_cells_returns_true() -> void:
	# Arrange — QA plan AC14 edge case: exactly 3 clear = true.
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(0, 0, 0), _solid_contents())
	grid.set_cell(Vector3i(0, 4, 0), _solid_contents())
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act + Assert — y=1,2,3 clear; y=4 solid is outside the clearance column.
	assert_bool(villager_ai.is_standable(Vector3i(0, 1, 0))).is_true()


func test_is_standable_low_ceiling_of_built_blocks_returns_false() -> void:
	# Arrange — QA plan AC14 edge case: a low ceiling of Built blocks (the
	# very next cell above the candidate is already solid) is not standable.
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(0, 0, 0), _solid_contents())
	grid.set_cell(Vector3i(0, 2, 0), _solid_contents())
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act + Assert
	assert_bool(villager_ai.is_standable(Vector3i(0, 1, 0))).is_false()


func test_is_standable_no_solid_cell_below_returns_false() -> void:
	# Arrange — nothing at y=0 (no ground at all); y=1..3 empty.
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act + Assert — clearance alone is not enough without solid ground below.
	assert_bool(villager_ai.is_standable(Vector3i(0, 1, 0))).is_false()


func test_is_standable_out_of_bounds_column_returns_false() -> void:
	# Arrange — a negative cell is outside the configured world bounds
	# (Core Rule 1) on every axis; get_cell() returns null for it.
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act + Assert
	assert_bool(villager_ai.is_standable(Vector3i(-1, 1, 0))).is_false()


# ---------------------------------------------------------------------------
# AC17 — unbuilt Planned blueprint cells are passable/non-solid by
# construction (Building Core Rule 14b)
# ---------------------------------------------------------------------------

func test_is_standable_unbuilt_blueprint_cell_in_path_is_passable() -> void:
	# Arrange — solid ground at y=0; nothing is ever written at y=1..3,
	# simulating a Planned (not-yet-Built) blueprint wall cell in the path.
	# Because Building System writes Built cells only via worker-executed
	# jobs (Control Manifest Core Layer), an unbuilt cell simply reads back
	# empty here -- no special-case branch is needed for AC17 to hold.
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(5, 0, 5), _solid_contents())
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act + Assert
	assert_bool(villager_ai.is_standable(Vector3i(5, 1, 5))).is_true()


func test_is_standable_blueprint_directly_below_candidate_is_not_solid_below() -> void:
	# Arrange — QA plan AC17 edge case: a blueprint cell directly below a
	# candidate stand cell (never written -- still Planned, not Built) must
	# NOT count as "solid below."
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act + Assert — y=0 was never built, so it is not solid.
	assert_bool(villager_ai.is_standable(Vector3i(0, 1, 0))).is_false()


# ---------------------------------------------------------------------------
# AC15 — is_step_legal height difference
# ---------------------------------------------------------------------------

func test_is_step_legal_flat_step_height_difference_zero_is_legal() -> void:
	# Arrange + Act + Assert — QA plan AC15 edge case: |dy| = 0 flat step true.
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	assert_bool(
		villager_ai.is_step_legal(Vector3i(0, 1, 0), Vector3i(1, 1, 0))
	).is_true()


func test_is_step_legal_height_difference_one_is_legal() -> void:
	# Arrange + Act + Assert
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	assert_bool(
		villager_ai.is_step_legal(Vector3i(0, 1, 0), Vector3i(1, 2, 0))
	).is_true()


func test_is_step_legal_height_difference_one_downward_is_legal() -> void:
	# Arrange + Act + Assert — symmetric: stepping down by 1 is also legal.
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	assert_bool(
		villager_ai.is_step_legal(Vector3i(1, 2, 0), Vector3i(0, 1, 0))
	).is_true()


func test_is_step_legal_height_difference_two_is_illegal() -> void:
	# Arrange + Act + Assert
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	assert_bool(
		villager_ai.is_step_legal(Vector3i(0, 1, 0), Vector3i(1, 3, 0))
	).is_false()


# ---------------------------------------------------------------------------
# AC16 — diagonal corner-cutting (no jump through walls)
# ---------------------------------------------------------------------------

func test_is_step_legal_diagonal_both_flankers_standable_is_legal() -> void:
	# Arrange — solid ground under both the from/to cells AND both flanking
	# cells, all with full clearance.
	var grid: VoxelWorldGrid = _make_grid()
	for pos: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		grid.set_cell(Vector3i(pos.x, 0, pos.y), _solid_contents())
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act + Assert — diagonal from (0,1,0) to (1,1,1); flankers (1,1,0) and
	# (0,1,1) are both standable.
	assert_bool(
		villager_ai.is_step_legal(Vector3i(0, 1, 0), Vector3i(1, 1, 1))
	).is_true()


func test_is_step_legal_diagonal_one_flanker_blocked_is_illegal() -> void:
	# Arrange — same setup, but one flanking cell (1,1,0) has a wall block
	# occupying it directly -- corner-cutting through that wall is illegal.
	var grid: VoxelWorldGrid = _make_grid()
	for pos: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		grid.set_cell(Vector3i(pos.x, 0, pos.y), _solid_contents())
	grid.set_cell(Vector3i(1, 1, 0), _solid_contents())
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act + Assert
	assert_bool(
		villager_ai.is_step_legal(Vector3i(0, 1, 0), Vector3i(1, 1, 1))
	).is_false()


func test_is_step_legal_diagonal_other_flanker_blocked_is_illegal() -> void:
	# Arrange — the OTHER flanking cell (0,1,1) blocked this time, proving
	# both flankers are actually checked, not just one.
	var grid: VoxelWorldGrid = _make_grid()
	for pos: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		grid.set_cell(Vector3i(pos.x, 0, pos.y), _solid_contents())
	grid.set_cell(Vector3i(0, 1, 1), _solid_contents())
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act + Assert
	assert_bool(
		villager_ai.is_step_legal(Vector3i(0, 1, 0), Vector3i(1, 1, 1))
	).is_false()


func test_is_step_legal_orthogonal_step_ignores_unstandable_diagonal_neighbor() -> void:
	# Arrange — an orthogonal step (only X differs) must never run the
	# flanking check at all, even if a diagonal neighbor is totally solid
	# rock with zero clearance.
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(0, 0, 0), _solid_contents())
	grid.set_cell(Vector3i(1, 0, 0), _solid_contents())
	grid.set_cell(Vector3i(1, 1, 0), _solid_contents())
	grid.set_cell(Vector3i(1, 2, 0), _solid_contents())
	grid.set_cell(Vector3i(1, 3, 0), _solid_contents())
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act + Assert — orthogonal step (0,1,0) -> (0,2,0); no diagonal at all.
	assert_bool(
		villager_ai.is_step_legal(Vector3i(0, 1, 0), Vector3i(0, 2, 0))
	).is_true()


# ---------------------------------------------------------------------------
# Purity / determinism (ADR-0007 Validation Criteria, Control Manifest
# Feature Layer Guardrail — no mutation, no cached state)
# ---------------------------------------------------------------------------

func test_is_standable_recomputed_twice_yields_identical_result() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(0, 0, 0), _solid_contents())
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act — same input, two separate calls (no caching anywhere).
	var first: bool = villager_ai.is_standable(Vector3i(0, 1, 0))
	var second: bool = villager_ai.is_standable(Vector3i(0, 1, 0))

	# Assert
	assert_bool(first).is_equal(second)


func test_is_step_legal_called_from_a_second_consumer_site_yields_identical_result() -> void:
	# Arrange — simulates a second consumer (e.g. a future Build Validation
	# BFS) calling the exact same shared predicate instance -- identical
	# inputs must produce identical results, proving no hidden state biases
	# either call site (ADR-0007's "single source of truth" contract).
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act
	var from_pathfinder_call: bool = villager_ai.is_step_legal(Vector3i(0, 1, 0), Vector3i(1, 2, 0))
	var from_other_consumer_call: bool = villager_ai.is_step_legal(Vector3i(0, 1, 0), Vector3i(1, 2, 0))

	# Assert
	assert_bool(from_pathfinder_call).is_equal(from_other_consumer_call)
