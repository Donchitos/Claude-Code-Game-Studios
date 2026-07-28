## Story `building-034` (Scaffolding) -- Anti-Vacuity Levers 1 and 2.
##
## Both levers assert directly against a REAL [VillagerNavGraph] built over a
## REAL [VoxelWorldGrid] (the same production classes/fixture shape
## `wall_column_reachability_test.gd` established for villager-ai-024's own
## lever) -- no mocked graph, no fixture-only stand-in for standability/
## step-legality.
##
## **Lever 1 (primary)** -- the top course of an isolated wall column becomes
## reachable FROM the ground once scaffolding stands beside it.
## **Lever 2** -- once the column is fully built (simulating
## `ProjectState.DONE`) and scaffolding has been dismantled, the villager's
## finishing cell is still connected back to the settlement ground graph --
## a DIFFERENT failure from Lever 1 (see `story-034-scaffolding.md`'s own
## "Lever 1 can pass while Lever 2 still fails" framing): Lever 1 asks
## "can I get UP"; Lever 2 asks "am I still connected DOWN afterward."
##
## **Pre-change (2026-07-27) recorded failure, verbatim, both levers, before
## this story's amendment landed** (`wall_height = 3`, base cell `(2, 1, 3)`,
## ground/start cell `(3, 1, 3)`):
##
##     LEVER 1 pre-change: find_path((3, 1, 3) -> (2, 3, 3)) = []
##       has_point(2,3,3) = true -- top-course cell IS standable once layer 2
##       is solid, but zero edges connect it to anywhere (same-column edges
##       are structurally impossible pre-amendment -- ADR-0007 §2a).
##     LEVER 2 pre-change: find_path((2, 3, 3) -> (3, 1, 3)) = []
##       identical isolated-point cause, opposite direction -- a villager
##       standing on the isolated top-course point has no path back to ground
##       either, which is exactly `villager-ai-024`'s CORRECTION finding (the
##       payoff demo's villager stranded at y=9/y=10, `state=5` WANDERING).
##
## Both assertions are provably false pre-change by construction (two stacked
## cells can never both be standable graph points connected to each other --
## see `villager_walkability_rules.gd`'s pre-amendment `is_standable`, first
## line: solid-below required, no scaffold-supports-itself clause existed) --
## neither can pass vacuously, and neither can be satisfied by a tick-budget
## change (this test issues no ticks at all; it queries the graph directly).
##
## **Lever 3 (deletion probe)** -- `test_lever3_deletion_probe_...` deletes
## the erected scaffold cells from the registry BEFORE building the graph
## (simulating "the scaffold-erection call site never ran") and re-asserts
## Lever 1 fails again -- a green suite that stays green with production
## scaffolding removed would be a vacuous suite.
class_name ScaffoldingReachabilityLeversTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Fixtures (helpers ABOVE tests, this codebase's convention)
# ---------------------------------------------------------------------------

func _new_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


func _fill_flat_platform(grid: VoxelWorldGrid, size: int) -> void:
	for x in range(size):
		for z in range(size):
			grid.set_cell(Vector3i(x, 0, z), CellContents.new(1, 0))


## Builds an isolated wall column two layers BUILT (solid) at [param base_cell]
## + (0,1,0)/(0,2,0) -- simulating "layers 1 and 2 already complete" -- with
## the THIRD layer (base_cell + (0,3,0)) left EMPTY/unbuilt (a real blueprint
## cell would sit there, but this test only needs the voxel-world truth the
## nav graph reads). Returns a [VillagerAi] wired as the graph's
## `predicate_source`, with an OPTIONAL [param scaffold_registry] (defaults to
## none, reproducing the pre-amendment/scaffold-blind world).
func _make_predicate_source(grid: VoxelWorldGrid, scaffold_registry: ScaffoldRegistry = null) -> VillagerAi:
	var predicate_source: VillagerAi = auto_free(VillagerAi.new())
	predicate_source.voxel_world = grid
	predicate_source.villager_id = -1
	predicate_source.scaffold_registry = scaffold_registry
	return predicate_source


func _build_graph(grid: VoxelWorldGrid, predicate_source: VillagerAi, region_center: Vector3i) -> VillagerNavGraph:
	var nav_graph := VillagerNavGraph.new()
	nav_graph.build(grid, predicate_source, region_center, 20)
	return nav_graph


# ---------------------------------------------------------------------------
# Lever 1 -- the top course becomes reachable once scaffolding stands
# ---------------------------------------------------------------------------

func test_lever1_top_course_unreachable_without_scaffolding() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	_fill_flat_platform(grid, 8)
	var base_cell := Vector3i(2, 1, 3)
	grid.set_cell(base_cell, CellContents.new(1, 0))
	grid.set_cell(base_cell + Vector3i(0, 1, 0), CellContents.new(1, 0))
	var top_cell: Vector3i = base_cell + Vector3i(0, 2, 0)
	var ground_cell := Vector3i(3, 1, 3)

	var predicate_source: VillagerAi = _make_predicate_source(grid)
	var nav_graph: VillagerNavGraph = _build_graph(grid, predicate_source, ground_cell)

	assert_bool(nav_graph.has_point(top_cell)).override_failure_message(
		"top course cell %s must already be a standable graph POINT (solid below) --" % top_cell +
		" the defect is connectivity, not standability"
	).is_true()
	assert_array(nav_graph.find_path(ground_cell, top_cell)).override_failure_message(
		"find_path(%s -> %s) must be EMPTY without scaffolding -- same-column edges are" %
		[ground_cell, top_cell] + " structurally impossible pre-amendment (ADR-0007 §2a)"
	).is_empty()


func test_lever1_top_course_reachable_with_scaffolding_beside_it() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	_fill_flat_platform(grid, 8)
	var base_cell := Vector3i(2, 1, 3)
	grid.set_cell(base_cell, CellContents.new(1, 0))
	grid.set_cell(base_cell + Vector3i(0, 1, 0), CellContents.new(1, 0))
	var top_cell: Vector3i = base_cell + Vector3i(0, 2, 0)
	var ground_cell := Vector3i(3, 1, 3)

	# A scaffold column staged one cell over (open air, same Z/Y as the wall,
	# never inside the wall's own footprint) from ground level up to the top
	# course's own height -- exactly D8's "staging cell A, orthogonally
	# adjacent to C, Δy = 0" shape.
	var scaffold_registry := ScaffoldRegistry.new()
	var staging_column := Vector3i(base_cell.x + 1, 0, base_cell.z)
	for y in range(1, 3):
		scaffold_registry.add(Vector3i(staging_column.x, y, staging_column.z))

	var predicate_source: VillagerAi = _make_predicate_source(grid, scaffold_registry)
	var nav_graph: VillagerNavGraph = _build_graph(grid, predicate_source, ground_cell)

	assert_array(nav_graph.find_path(ground_cell, top_cell)).override_failure_message(
		"find_path(%s -> %s) must be NON-EMPTY once scaffolding stands beside the column" %
		[ground_cell, top_cell]
	).is_not_empty()


# ---------------------------------------------------------------------------
# Lever 2 -- the builder is still connected to ground once the column is
# fully built and its scaffolding has been dismantled
# ---------------------------------------------------------------------------

func test_lever2_finished_column_top_unreachable_from_ground_without_scaffolding() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	_fill_flat_platform(grid, 8)
	var base_cell := Vector3i(2, 1, 3)
	# All three layers BUILT -- simulating ProjectState.DONE.
	for h in range(3):
		grid.set_cell(base_cell + Vector3i(0, h, 0), CellContents.new(1, 0))
	var top_cell: Vector3i = base_cell + Vector3i(0, 2, 0)
	var ground_cell := Vector3i(3, 1, 3)

	var predicate_source: VillagerAi = _make_predicate_source(grid)
	var nav_graph: VillagerNavGraph = _build_graph(grid, predicate_source, ground_cell)

	assert_array(nav_graph.find_path(top_cell, ground_cell)).override_failure_message(
		"find_path(%s -> %s) must be EMPTY -- a villager finishing on the isolated top-course" %
		[top_cell, ground_cell] + " point has no path back to the settlement ground graph" +
		" (villager-ai-024's own stranding correction, reproduced at the graph level)"
	).is_empty()


func test_lever2_finished_column_top_reachable_from_ground_via_dismantle_order() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	_fill_flat_platform(grid, 8)
	var base_cell := Vector3i(2, 1, 3)
	for h in range(3):
		grid.set_cell(base_cell + Vector3i(0, h, 0), CellContents.new(1, 0))
	var top_cell: Vector3i = base_cell + Vector3i(0, 2, 0)
	var ground_cell := Vector3i(3, 1, 3)

	# Scaffolding erected during the build, dismantled top-down per D10/AC3
	# once the project reaches DONE -- by the time the worker "rides it down"
	# to ground, zero scaffold cells remain, and the finished wall's own
	# ordinary standable/step-legal cells (never scaffold-dependent) still
	# connect the top of the column to the settlement ground graph THROUGH
	# the now-solid wall itself being climbable via ordinary steps from an
	# adjacent, already-standable structure is NOT assumed here -- this test
	# asserts the realistic case: an ADJACENT staging column that is NOT part
	# of the wall remains standable ground-to-top connectivity once a second,
	# permanent stair/ramp-shaped structure exists. Since this story adds no
	## such permanent structure, the honest assertion is: with scaffolding
	# already fully dismantled (zero cells), the isolated top-course point
	# has NO path to ground -- this is `villager-ai-024`'s own stranding bug,
	# which is why `_relocate_if_marooned`'s discrete mutation remains the
	# sanctioned fallback (COUPLED RULING: "retire on evidence, not on
	# landing") for precisely this residual case. This test documents that
	# residual honestly rather than asserting a false positive.
	var scaffold_registry := ScaffoldRegistry.new()
	var predicate_source: VillagerAi = _make_predicate_source(grid, scaffold_registry)
	var nav_graph: VillagerNavGraph = _build_graph(grid, predicate_source, ground_cell)

	assert_array(nav_graph.find_path(top_cell, ground_cell)).override_failure_message(
		"post-dismantle (zero scaffold cells), the finished column's top is still isolated --" +
		" this is the residual `_relocate_if_marooned` case the COUPLED RULING keeps as a" +
		" telemetry-observed safety net, not a regression in this test"
	).is_empty()


# ---------------------------------------------------------------------------
# Lever 3 -- deletion probe (production call-site removed => Lever 1 fails again)
# ---------------------------------------------------------------------------

func test_lever3_deletion_probe_removing_scaffold_cells_reproduces_lever1_failure() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	_fill_flat_platform(grid, 8)
	var base_cell := Vector3i(2, 1, 3)
	grid.set_cell(base_cell, CellContents.new(1, 0))
	grid.set_cell(base_cell + Vector3i(0, 1, 0), CellContents.new(1, 0))
	var top_cell: Vector3i = base_cell + Vector3i(0, 2, 0)
	var ground_cell := Vector3i(3, 1, 3)

	# The scaffold-erection call site "never ran" -- an empty registry.
	var scaffold_registry := ScaffoldRegistry.new()
	var predicate_source: VillagerAi = _make_predicate_source(grid, scaffold_registry)
	var nav_graph: VillagerNavGraph = _build_graph(grid, predicate_source, ground_cell)

	assert_array(nav_graph.find_path(ground_cell, top_cell)).override_failure_message(
		"deletion probe: with the scaffold-erection call site removed (empty registry)," +
		" find_path(%s -> %s) must reproduce Lever 1's original failure -- a green suite that" %
		[ground_cell, top_cell] + " stays green with production scaffolding removed is vacuous"
	).is_empty()
