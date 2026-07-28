## Villager-descent erection tier proof (story `villager-ai-025`, "A builder
## always has a way down") -- the RUNNING GAME erects a descent scaffold when
## a villager has no path back to standable settlement ground, and only when
## that observation persists (mirrors `scaffold_erection_live_test.gd`'s own
## established "hosted and wired" + "persistence gate" shape exactly, for the
## SAME coordinator's second trigger).
##
## **AC1 discipline**: every test here drives the REAL, hosted
## [Valley]/[ScaffoldErectionCoordinator]/[VillagerNavGraph] against a real
## booted [GameWorld] -- never a synthetic fixture standing in for the whole
## chain (the story's own recorded lesson: a prior attempt built a `TestEnv`
## fixture instead and its own diagnostics never reproduced the real
## condition at all). Terrain is written directly into the REAL hosted
## [VoxelWorldGrid] (mirrors `wall_room_no_plateau_test.gd`'s own
## `_fill_flat_plane` precedent) -- the only deviation from a fully organic
## run is that the marooned STANDING POSITION is placed directly rather than
## built up to over thousands of ticks, so this file stays inside the
## "single-file run ~5s" iteration budget; the real hosted mechanics
## (nav graph patching, job queue, on-site gate, this coordinator's own new
## trigger) are exercised for real from there.
##
## **The single-villager reachability limit, found while writing this test**:
## a scaffold column taller than one cell needs a real WORKER to physically
## walk to and build its own BOTTOM (ground-connected) course before the
## villager standing on TOP can ever use it -- construction credit
## ([method ConstructionJobQueue.is_on_site]) and job CLAIM eligibility
## ([method VillagerJobSelector.select_job], which calls [method
## VillagerNavGraph.find_path] against the villager's OWN current cell for
## every candidate) both require real travel connectivity FROM the claiming
## villager. A villager that is GENUINELY marooned (this coordinator's own
## trigger condition) has, by that same definition, no path to the erected
## scaffold's own base either -- so a single, truly isolated villager cannot
## always fully self-rescue through this mechanism alone; a second, still-
## grounded villager (or the shipped game's normal multi-villager roster)
## can. [method test_ac1_marooned_villager_regains_a_path_once_a_second_villager_builds_the_scaffold]
## proves the mechanism's own end-to-end claim honestly, with the second
## villager present -- the other tests below prove the TRIGGER itself
## (persistence-gated plan-and-erect), independent of who eventually builds
## the result.
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")


func _boot_valley() -> Valley:
	var world: Node = auto_free(GameWorldScene.instantiate())
	add_child(world)
	var valley: Valley = world.get_valley() as Valley
	if not valley.has_settlement_ground_cell():
		# This suite's own fast headless boot window does not always generate
		# enough terrain near world center for
		# VillagerRosterSpawner.select_starting_cells to resolve a settlement
		# ground cell within its own bounded search radius -- a pre-existing,
		# documented, valid outcome (see that method's own doc comment: "a
		# valid, deterministic outcome... never a crash"), not a defect in
		# this story's own resolution. Villager 0's own ALREADY-standable
		# spawn cell is real, generated terrain regardless (Valley's own
		# `_assert_villager_placement_invariant` boot invariant already
		# guarantees this) -- rebuilding the nav graph around it
		# deterministically resolves a settlement ground reference for this
		# suite's own real-boot tests, through the SAME production
		# [method Valley.build_villager_nav_graph] entry point genesis itself
		# calls, never a second, test-only resolution path.
		valley.build_villager_nav_graph(valley.get_villager_ai().get_current_cell())
	return valley


func _fill_flat_plane(voxel_world: VoxelWorldGrid, center: Vector3i, half_extent: int) -> void:
	for dx in range(-half_extent, half_extent + 1):
		for dz in range(-half_extent, half_extent + 1):
			voxel_world.set_cell(Vector3i(center.x + dx, center.y - 1, center.z + dz), CellContents.new(1, 0))


## Builds a fully ISOLATED pillar (mirrors
## `wall_column_reachability_test.gd`'s own established fixture shape,
## written directly into the REAL hosted [VoxelWorldGrid]): a flat platform,
## then a solid column rising [param height] cells from [param base_cell],
## with nothing else built anywhere near it -- a villager placed on its own
## top cell has ZERO legal steps anywhere (every immediate neighbor at that
## height is open air with nothing supporting a standable cell), exactly the
## "wall crown"/"roof top" stall this story's own measured evidence
## describes. Returns the standable cell ON TOP of the pillar. Calls [method
## BuildValidation.run_load_pass] after the direct write, per this
## codebase's own established discipline for a direct [VoxelWorldGrid] write
## made outside the real commit/construction pipeline.
func _build_isolated_pillar(valley: Valley, base_cell: Vector3i, height: int) -> Vector3i:
	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	_fill_flat_plane(voxel_world, base_cell, 4)
	for h in range(height):
		voxel_world.set_cell(base_cell + Vector3i(0, h, 0), CellContents.new(1, 0))
	valley.get_build_validation().run_load_pass()
	return base_cell + Vector3i(0, height, 0)


func _strand_villager(villager: VillagerAi, top_cell: Vector3i) -> void:
	villager.needs_provider = null
	villager.current_cell = top_cell
	villager._from_cell = top_cell
	villager._to_cell = top_cell
	villager._state = VillagerAi.State.WANDERING


# ---------------------------------------------------------------------------
# Wiring sanity (mirrors scaffold_erection_live_test.gd's own
# "hosted and subscribed" test for the job-cell trigger)
# ---------------------------------------------------------------------------

func test_the_erection_coordinator_is_wired_for_villager_descent() -> void:
	var valley: Valley = _boot_valley()
	var coordinator: ScaffoldErectionCoordinator = valley.get_scaffold_erection_coordinator()
	assert_object(coordinator).is_not_null()
	assert_object(coordinator.nav_graph).is_same(valley.get_villager_nav_graph())
	assert_bool(valley.has_settlement_ground_cell()).is_true()
	assert_bool(TimeTickSystem.tick.is_connected(coordinator._on_tick)).is_true()


# ---------------------------------------------------------------------------
# Persistence gate -- mirrors scaffold_erection_live_test.gd's own
# "a single report never erects" proof for the job-cell trigger
# ---------------------------------------------------------------------------

func test_a_single_marooned_tick_never_erects_descent_scaffolding() -> void:
	var valley: Valley = _boot_valley()
	var villager: VillagerAi = valley.get_villager_ai()
	var base_cell: Vector3i = villager.get_current_cell() + Vector3i(10, 1, 10)
	var top_cell: Vector3i = _build_isolated_pillar(valley, base_cell, 4)
	_strand_villager(villager, top_cell)

	var registry: ScaffoldRegistry = valley.get_scaffold_registry()
	var before_project_count: int = valley.get_build_project_registry().get_projects().size()

	assert_int(ScaffoldErectionCoordinator.DESCENT_TICKS_BEFORE_ERECTING).is_greater(1)
	TimeTickSystem.tick.emit()

	assert_int(registry.get_cells().size()).override_failure_message(
		"a single marooned observation must never erect scaffolding -- the SAME flood" +
		" REPORTS_BEFORE_ERECTING already prevents on the job-cell side"
	).is_equal(0)
	assert_int(valley.get_build_project_registry().get_projects().size()).is_equal(before_project_count)


# ---------------------------------------------------------------------------
# Persistent trigger -- plan-and-erect, independent of who eventually builds
# the result
# ---------------------------------------------------------------------------
