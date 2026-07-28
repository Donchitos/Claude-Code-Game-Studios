## Integration test -- Story villager-ai-024 ("A villager cannot finish a
## wall"). Regression test for the exact defect this story fixes: a single
## villager, building an isolated wall column of `WallToolConfig.wall_height`
## (3, read live from the shipped config, never a literal) cells, used to
## plateau forever at the TOPMOST layer -- every layer above the second was
## structurally unreachable by [VillagerJobSelector.select_job] (see AC2's
## root-cause write-up in the story file and this file's own class doc
## comment below for the confirmed mechanism).
##
## **Anti-vacuity**: this exact scenario was run against the UNCHANGED build
## before the fix landed and reproduced the plateau byte-for-byte (recorded
## verbatim in this story's own commit body): cell (2,1,3) BUILT,
## claimed_by=1; cell (2,2,3) BUILT, claimed_by=1; cell (2,3,3) PLANNED,
## claimed_by=-1, abandon_count=0 -- NEVER claimed, not claimed-and-refused,
## even after 600 ticks. This test asserts the post-fix outcome: all three
## cells reach BUILT well inside a generous tick budget.
##
## **The confirmed root cause (AC2)**: [VillagerNavGraph] only ever connects
## two cells whose HORIZONTAL offset is non-zero ([constant
## VillagerNavGraph.HORIZONTAL_HALF_OFFSETS]/[constant
## VillagerNavGraph.HORIZONTAL_FULL_OFFSETS] never include `(0, 0)`) -- a
## "step" is inherently a horizontal move. Because [method
## VillagerWalkabilityRules.is_standable] requires a cell's OWN "below" cell
## to be solid, two cells stacked directly above each other in the SAME
## column can never BOTH be standable graph points at once, so a genuinely
## vertical same-column edge could never exist anyway. A wall column can
## therefore only be entered from an ADJACENT, already-standable cell one
## step away both horizontally and vertically (`|dy| <= 1`) -- this is why
## layer 2 (one step above the always-standable ground) reliably completed:
## reachable directly from the floor. Layer 3 needs a SECOND such extension,
## but its only same-column neighbor at the needed height (layer 2's own
## cell) becomes solid -- and therefore stops being a graph point at all --
## the INSTANT it completes, in the SAME [method
## VillagerNavGraph.patch_cells] call that adds layer 3 as a point. Layer 3
## patches in as a genuinely ISOLATED point with zero edges to anywhere a
## villager could actually stand, so [method VillagerNavGraph.find_path]
## never succeeds TO it from anywhere -- confirmed directly against this
## exact scenario (`has_point` true, `find_path` from every reachable cell
## empty) before the fix. The pre-existing Unstuck Watchdog rescue does
## consider the cell directly above a self-sealed villager as a candidate,
## but its own lexicographic `(y, x, z)` tie-break always prefers a
## lower/same-height standable neighbor (e.g. the adjacent floor) when one
## exists -- which it always does near a real wall -- so the watchdog never
## once placed the villager back on the isolated node either. This is why
## job selection excludes layer 3 forever, silently, before any claim is
## ever attempted: `state == PLANNED`, `claimed_by_villager_id == -1`,
## `abandon_count == 0` -- exactly the story's own recorded evidence, never a
## refused write (which would require an existing claim).
##
## **The fix**: [method VillagerAi.climb_onto_self_sealed_cell], called by
## [VillagerSealPreventionGate] at the exact moment its own self-seal
## exemption fires. See that method's own doc comment for the full
## rationale -- summarized, a villager that just sealed itself into the cell
## it was standing in is atomically moved to stand exactly on top of it
## (the cell it just made solid + one), which is always the wall's NEXT
## layer -- reachable at Chebyshev distance 0 by the very next Deciding pass,
## chaining to any `wall_height`, with no nav-graph edge required and no
## dependence on the Watchdog's tick-threshold cadence. Seal prevention's
## OWN general trap check/`abandon_count`/livelock-escape logic is completely
## untouched (see `seal_prevention_test.gd`/`unstuck_watchdog_test.gd`, both
## still green) -- only what happens to the villager's position as a RESULT
## of an already-unconditional exemption firing is new.
class_name WallColumnReachabilityTest
extends GdUnitTestSuite


func _new_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


func _fill_flat_platform(grid: VoxelWorldGrid, size: int) -> void:
	for x in range(size):
		for z in range(size):
			grid.set_cell(Vector3i(x, 0, z), CellContents.new(1, 0))


func _planned_cell(cell: Vector3i) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.PLANNED)


func _released_project(id: int, cells: Array[Vector3i]) -> BuildProject:
	var project := BuildProject.new(id)
	for cell: Vector3i in cells:
		project.add_cell(_planned_cell(cell))
	project.release()
	return project


func _count_built(project: BuildProject, cells: Array[Vector3i]) -> int:
	var count: int = 0
	for cell: Vector3i in cells:
		if project.cells[cell].state == BlueprintCell.MicroState.BUILT:
			count += 1
	return count


## Builds one villager, real [ConstructionJobQueue]/[ConstructionTickLoop]/
## [VillagerOnSiteGate]/[VillagerSealPreventionGate]/[VillagerNavGraph]
## environment around [param wall_cells] and drives it, real tick by real
## tick (via a [MockTimeTickSystem], this codebase's own established
## tick-driven-loop precedent -- `build_job_cycle_test.gd`'s own
## `_make_environment`/`_make_full_villager` shape, reused directly rather
## than re-derived), until every cell reaches BUILT or [param tick_cap] is
## exhausted. Returns the [BuildProject] so the caller can assert final
## per-cell state.
func _drive_wall_column_to_completion(
	wall_cells: Array[Vector3i], start_cell: Vector3i, tick_cap: int
) -> BuildProject:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var grid: VoxelWorldGrid = _new_grid()
	_fill_flat_platform(grid, 8)

	var loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	loop.voxel_world = grid
	loop.config = ConstructionTickLoopConfig.new()
	loop.time_tick_system = tick_source
	loop.setup()
	var queue := ConstructionJobQueue.new(loop)
	var onsite_gate := VillagerOnSiteGate.new(queue)
	var vai_config := VillagerAIConfig.new()
	var seal_gate := VillagerSealPreventionGate.new(queue, vai_config)

	var project: BuildProject = _released_project(1, wall_cells)
	queue.add_project(project)

	var predicate_source: VillagerAi = auto_free(VillagerAi.new())
	predicate_source.voxel_world = grid
	predicate_source.villager_id = -1
	var nav_graph := VillagerNavGraph.new()
	nav_graph.subscribe_to_voxel_world(grid, predicate_source)
	nav_graph.build(grid, predicate_source, start_cell, 20)

	var scheduler := VillagerDecidingScheduler.new()
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.config = vai_config
	villager.voxel_world = grid
	villager.scheduler = scheduler
	villager.nav_graph = nav_graph
	villager.time_tick_system = tick_source
	villager.job_queue = queue
	villager.villager_id = 1
	villager.setup()
	onsite_gate.register_villager(villager)
	seal_gate.register_villager(villager)

	villager.current_cell = start_cell
	villager._from_cell = start_cell
	villager._to_cell = start_cell

	var ticks: int = 0
	while ticks < tick_cap and _count_built(project, wall_cells) < wall_cells.size():
		villager.advance_travel_progress(1000.0)
		tick_source.fire_tick()
		ticks += 1

	return project


# ---------------------------------------------------------------------------
# AC1 / Anti-Vacuity Lever -- an isolated wall column at the shipped
# WallToolConfig.wall_height completes EVERY cell, no plateau at the top
# ---------------------------------------------------------------------------

func test_ac1_isolated_wall_column_at_shipped_wall_height_completes_every_cell() -> void:
	# Read LIVE from the shipped .tres, never a literal -- this story's own
	# finding is scoped explicitly to "wall_height ships as 3" (currently
	# true; this assertion would surface a future re-tune rather than
	# silently testing a stale number).
	var shipped_config: WallToolConfig = load("res://data/config/wall_tool_config.tres")
	var wall_height: int = shipped_config.wall_height

	var base_cell := Vector3i(2, 1, 3)
	var wall_cells: Array[Vector3i] = []
	for h in range(wall_height):
		wall_cells.append(base_cell + Vector3i(0, h, 0))

	var project: BuildProject = _drive_wall_column_to_completion(wall_cells, Vector3i(3, 1, 3), 200)

	for cell: Vector3i in wall_cells:
		assert_int(project.cells[cell].state).override_failure_message(
			"cell %s never reached BUILT (claimed_by=%d) -- the plateau this story fixes"
			% [cell, project.cells[cell].claimed_by_villager_id]
		).is_equal(BlueprintCell.MicroState.BUILT)


## Generalization check (not itself an AC, but directly informs AC2's
## confirmation that the fix is structural, not a height-3 special case --
## the story's own Out of Scope explicitly bans "a fix that only works at
## two"): a TALLER column (6, double the shipped default, still within
## [constant WallToolConfig.WALL_HEIGHT_MAX]) also completes every layer.
func test_generalizes_beyond_height_3_taller_column_completes_every_cell() -> void:
	var wall_height: int = 6
	var base_cell := Vector3i(2, 1, 3)
	var wall_cells: Array[Vector3i] = []
	for h in range(wall_height):
		wall_cells.append(base_cell + Vector3i(0, h, 0))

	var project: BuildProject = _drive_wall_column_to_completion(wall_cells, Vector3i(3, 1, 3), 300)

	for cell: Vector3i in wall_cells:
		assert_int(project.cells[cell].state).override_failure_message(
			"cell %s never reached BUILT -- fix does not generalize past height 3" % cell
		).is_equal(BlueprintCell.MicroState.BUILT)
