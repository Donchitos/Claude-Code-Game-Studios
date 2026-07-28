## Story `building-034` -- ADR-0007 §1a/§1b/§2a Validation Criteria, unit tier
## (guard assertions, not the lever -- see `scaffolding_reachability_levers_test.gd`
## for the real-production-code lever tests).
class_name WalkabilityScaffoldAmendmentTest
extends GdUnitTestSuite


func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


# ---------------------------------------------------------------------------
# §1a -- a scaffold cell is standable with air beneath it; two stacked
# non-scaffold cells are still never both standable
# ---------------------------------------------------------------------------

func test_scaffold_cell_standable_with_air_beneath() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var scaffold := ScaffoldRegistry.new()
	var cell := Vector3i(5, 5, 5)
	scaffold.add(cell)
	assert_bool(VillagerWalkabilityRules.is_standable(grid, cell, scaffold)).override_failure_message(
		"a scaffold cell must be standable with AIR beneath it -- §1a's own defining property"
	).is_true()


func test_two_stacked_non_scaffold_cells_never_both_standable() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	# Neither cell nor the one below it is solid, and neither is scaffold --
	# today's first line of is_standable ("if not solid-below: return false")
	# must still hold: the amendment must not widen beyond scaffolding.
	var lower := Vector3i(5, 5, 5)
	var upper := Vector3i(5, 6, 5)
	assert_bool(VillagerWalkabilityRules.is_standable(grid, lower)).is_false()
	assert_bool(VillagerWalkabilityRules.is_standable(grid, upper)).is_false()


# ---------------------------------------------------------------------------
# §2a -- vertical step legal ONLY when both endpoints are scaffold
# ---------------------------------------------------------------------------

func test_vertical_step_legal_only_when_both_endpoints_scaffold() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var scaffold := ScaffoldRegistry.new()
	var lower := Vector3i(5, 5, 5)
	var upper := Vector3i(5, 6, 5)
	scaffold.add(lower)
	scaffold.add(upper)
	assert_bool(VillagerWalkabilityRules.is_step_legal(grid, lower, upper, scaffold)).is_true()
	assert_bool(VillagerWalkabilityRules.is_step_legal(grid, upper, lower, scaffold)).is_true()


func test_vertical_step_refused_with_only_one_scaffold_endpoint_both_directions() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var scaffold := ScaffoldRegistry.new()
	var lower := Vector3i(5, 5, 5)
	var upper := Vector3i(5, 6, 5)
	scaffold.add(lower)
	# upper is NOT scaffold -- exactly §2a clause 2's own named reachable
	# configuration: an ordinary standable cell directly beneath a scaffold
	# cell must never connect.
	assert_bool(VillagerWalkabilityRules.is_step_legal(grid, lower, upper, scaffold)).is_false()
	assert_bool(VillagerWalkabilityRules.is_step_legal(grid, upper, lower, scaffold)).is_false()

	var scaffold2 := ScaffoldRegistry.new()
	scaffold2.add(upper)
	assert_bool(VillagerWalkabilityRules.is_step_legal(grid, lower, upper, scaffold2)).is_false()
	assert_bool(VillagerWalkabilityRules.is_step_legal(grid, upper, lower, scaffold2)).is_false()


func test_vertical_step_with_no_scaffold_source_keeps_pre_amendment_behaviour() -> void:
	# CORRECTED FROM ITS ORIGINAL FORM. It used to assert that a same-column
	# step is refused whenever no scaffold source is supplied. That contradicts
	# ADR-0007 section 1b's own binding promise -- a caller passing nothing must
	# observe EXACTLY pre-amendment behaviour -- and the pre-amendment predicate
	# returned TRUE here, falling through to the |dy| <= MAX_STEP_HEIGHT check.
	# The blanket refusal broke the pre-existing walkability_predicates_test and
	# villager-ai-024's wall fix along with it.
	#
	# General climbing is closed by the EXACTLY-ONE-endpoint-scaffold case, not
	# by refusing everything: two ordinary stacked cells still cannot both be
	# standable, because section 1a relaxes solid-below only FOR scaffold cells.
	var grid: VoxelWorldGrid = _make_grid()
	assert_bool(
		VillagerWalkabilityRules.is_step_legal(grid, Vector3i(2, 1, 2), Vector3i(2, 2, 2))
	).is_true()
	assert_bool(
		VillagerWalkabilityRules.is_step_legal(grid, Vector3i(2, 1, 2), Vector3i(2, 2, 2), null)
	).is_true()

func test_candidate_cell_rules_is_roofed_false_for_scaffold_only_roof() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var scaffold := ScaffoldRegistry.new()
	var query_cell := Vector3i(5, 5, 5)
	# Scaffold sitting directly above the query cell -- never a roof.
	scaffold.add(query_cell + Vector3i(0, 1, 0))
	assert_bool(CandidateCellRules.is_roofed(grid, query_cell, 5)).override_failure_message(
		"scaffolding must NEVER read as a roof -- CandidateCellRules never even" +
		" receives a scaffold_source parameter, so this holds structurally"
	).is_false()


func test_is_standable_defaults_to_scaffold_blind_when_source_omitted() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var cell := Vector3i(5, 5, 5)
	# Build Validation's own call shape -- no third argument at all.
	assert_bool(VillagerWalkabilityRules.is_standable(grid, cell)).is_false()


# ---------------------------------------------------------------------------
# §1b -- the after_write twins MUST receive the scaffold source (D1's own
# "correction the story missed")
# ---------------------------------------------------------------------------

func test_would_trap_builder_false_for_villager_standing_on_scaffold() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var scaffold := ScaffoldRegistry.new()
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.voxel_world = grid
	villager.scaffold_registry = scaffold
	villager.villager_id = 1

	var standing_cell := Vector3i(5, 5, 5)
	scaffold.add(standing_cell)
	# A REAL escape route, which the original fixture omitted: a scaffold cell
	# directly below, so the section-2a scaffold-to-scaffold vertical edge has
	# somewhere to go. Without it the villager genuinely has no legal step
	# anywhere and `would_trap_builder` is RIGHT to say true — the test would
	# have been asserting that the predicate lie about a real dead end.
	scaffold.add(standing_cell + Vector3i(0, -1, 0))
	villager.current_cell = standing_cell

	# A write that does NOT touch the villager's own body-column -- far away.
	var written_cell := Vector3i(50, 50, 50)
	assert_bool(villager.would_trap_builder(written_cell)).override_failure_message(
		"a villager standing on a scaffold cell has air beneath it -- a scaffold-blind" +
		" after_write twin would report it 'trapped' by nearly every write; this must be false"
	).is_false()
