## Unit test — Story villager-ai-026 (walkability static extraction,
## behavior-preserving; TD ruling BV-4,
## `production/architecture-decisions-m02-preflight-2026-07-26.md`).
##
## This is the story's correctness proof, additive-only (no pre-existing test
## file is touched anywhere in this change — see the story's own zero-test-
## edit AC). Proves exactly the two structural claims the story's AC and QA
## Test Cases name:
##
## 1. **Equivalence**: [VillagerAi.is_standable] / [VillagerAi.is_step_legal] /
##    [VillagerAi.body_column] return IDENTICAL answers to their static twins
##    on [VillagerWalkabilityRules], over a shared fixture set that includes
##    the out-of-bounds/world-boundary cells where
##    [method VoxelWorldGrid.get_cell] returns `null` (QA plan Gate 1 item 4).
## 2. **Alias identity**: [constant VillagerAi.VILLAGER_CLEARANCE] `==`
##    [constant VillagerWalkabilityRules.VILLAGER_CLEARANCE] (likewise
##    `MAX_STEP_HEIGHT`) — an alias of the SAME declaration, not two values
##    that happen to match today.
class_name WalkabilityRulesStaticTest
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


## Shared `is_standable`/`body_column` fixture cells -- deliberately includes
## a world-boundary/out-of-bounds cell (negative X, same as
## `walkability_predicates_test.gd`'s own out-of-bounds case) alongside
## ordinary standable/non-standable cells, per QA plan Gate 1 item 4.
func _standability_fixture_cells() -> Array[Vector3i]:
	return [
		Vector3i(0, 1, 0),  # standable: solid below, clear column.
		Vector3i(0, 4, 0),  # not standable: nothing solid below at y=3.
		Vector3i(5, 1, 5),  # not standable: low ceiling one cell above.
		Vector3i(-1, 1, 0),  # out-of-bounds: get_cell() returns null.
	]


## Shared `is_step_legal` fixture pairs -- flat, up-one, illegal-height, and a
## diagonal pair whose flanker sits at a world-boundary (out-of-bounds) cell.
func _step_legal_fixture_pairs() -> Array[Array]:
	return [
		[Vector3i(0, 1, 0), Vector3i(1, 1, 0)],  # flat orthogonal step.
		[Vector3i(0, 1, 0), Vector3i(1, 2, 0)],  # +1 height, legal.
		[Vector3i(0, 1, 0), Vector3i(1, 3, 0)],  # +2 height, illegal.
		[Vector3i(0, 1, 0), Vector3i(1, 1, 1)],  # diagonal, flankers standable.
		[Vector3i(0, 1, -1), Vector3i(1, 1, 0)],  # diagonal, flanker OOB (x=-1 side unaffected; z=-1 flanker path exercises get_cell()==null on the flanker read).
	]


# ---------------------------------------------------------------------------
# Equivalence — is_standable
# ---------------------------------------------------------------------------

func test_is_standable_equivalence_across_fixture_set_including_out_of_bounds() -> void:
	# Arrange — a world with a mix of solid/empty cells so the fixture set's
	# standable/non-standable/out-of-bounds cells all exercise real branches.
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(0, 0, 0), _solid_contents())
	grid.set_cell(Vector3i(5, 0, 5), _solid_contents())
	grid.set_cell(Vector3i(5, 2, 5), _solid_contents())  # low ceiling.
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act + Assert — every fixture cell: instance and static answers match.
	for cell: Vector3i in _standability_fixture_cells():
		var from_instance: bool = villager_ai.is_standable(cell)
		var from_static: bool = VillagerWalkabilityRules.is_standable(grid, cell)
		assert_bool(from_static).override_failure_message(
			"is_standable(%s) diverged: instance=%s static=%s" % [cell, from_instance, from_static]
		).is_equal(from_instance)


# ---------------------------------------------------------------------------
# Equivalence — is_step_legal
# ---------------------------------------------------------------------------

func test_is_step_legal_equivalence_across_fixture_set_including_out_of_bounds() -> void:
	# Arrange — solid ground under every ordinary (non-OOB) fixture cell used
	# above so the diagonal flanker checks have real standability answers to
	# diverge on if the extraction changed anything.
	var grid: VoxelWorldGrid = _make_grid()
	for pos: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		grid.set_cell(Vector3i(pos.x, 0, pos.y), _solid_contents())
	var villager_ai: VillagerAi = _make_villager_ai(grid)

	# Act + Assert
	for pair: Array in _step_legal_fixture_pairs():
		var from_cell: Vector3i = pair[0]
		var to_cell: Vector3i = pair[1]
		var from_instance: bool = villager_ai.is_step_legal(from_cell, to_cell)
		var from_static: bool = VillagerWalkabilityRules.is_step_legal(grid, from_cell, to_cell)
		assert_bool(from_static).override_failure_message(
			(
				"is_step_legal(%s, %s) diverged: instance=%s static=%s"
				% [from_cell, to_cell, from_instance, from_static]
			)
		).is_equal(from_instance)


# ---------------------------------------------------------------------------
# Equivalence — body_column (pure Vector3i derivation, no voxel_world needed)
# ---------------------------------------------------------------------------

func test_body_column_equivalence_across_fixture_set() -> void:
	# Arrange — body_column() takes no voxel_world, so a bare VillagerAi
	# (no setup() call) is sufficient, matching body_column_test.gd's own
	# established fixture pattern.
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())

	# Act + Assert — including a negative/world-boundary cell: body_column is
	# a pure Vector3i derivation with no bounds check of its own, so it must
	# agree there too.
	for cell: Vector3i in _standability_fixture_cells():
		var from_instance: Array[Vector3i] = villager_ai.body_column(cell)
		var from_static: Array[Vector3i] = VillagerWalkabilityRules.body_column(cell)
		assert_array(from_instance).contains_exactly(from_static)


# ---------------------------------------------------------------------------
# Alias identity — VILLAGER_CLEARANCE / MAX_STEP_HEIGHT
# ---------------------------------------------------------------------------

func test_villager_clearance_is_an_alias_of_the_static_rules_constant() -> void:
	# Assert — same value; VillagerAi's own const is initialised FROM this
	# one (parse-time resolution), not a second independent literal.
	assert_int(VillagerAi.VILLAGER_CLEARANCE).is_equal(VillagerWalkabilityRules.VILLAGER_CLEARANCE)


func test_max_step_height_is_an_alias_of_the_static_rules_constant() -> void:
	# Assert
	assert_int(VillagerAi.MAX_STEP_HEIGHT).is_equal(VillagerWalkabilityRules.MAX_STEP_HEIGHT)
