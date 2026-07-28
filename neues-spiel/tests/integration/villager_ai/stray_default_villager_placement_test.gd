## Integration test — Villager AI story villager-ai-022 ("the stray villager
## at the world corner", `production/epics/villager-ai-behavior/
## story-022-stray-default-villager-at-world-origin.md`).
##
## Found by booting the real game and printing where everybody stands:
## `Valley.get_villagers()` returned `_villager_ai` (villager_id 0, the
## scene-hosted default) UNTOUCHED by [method Valley.spawn_starting_roster] --
## it kept its `Vector3i.ZERO` construction default forever, the far corner
## of a 2000x2000 world, ~1400 cells from the real settlement.
##
## Proves:
## - **AC1 (Anti-Vacuity Lever)**: a REAL, production-shaped `game_world.tscn`
##   boot (never a hand-built villager) reaches [constant
##   GameWorld.BootState.ACTIVE] with every [Valley.get_villagers] entry
##   standing on a cell the real voxel world reports standable -- none at
##   cell (0, 0, 0), which is not the real world's center.
## - **AC2**: villager 0 is placed through the SAME
##   [VillagerRosterSpawner.select_starting_cells]/[method
##   VillagerRosterSpawner.place_villager_at_cell] path every other roster
##   member goes through -- one placement rule, not two -- and every placed
##   villager lies within [constant VillagerRosterSpawner.MAX_SEARCH_RADIUS]
##   (Chebyshev distance) of the world center.
## - **AC3**: when the search finds zero standable cells at all, that is a
##   deterministic, `push_warning`-logged outcome -- villager 0 is left where
##   it was (never crashes, never silently swallowed), and a later call (once
##   real terrain exists) still gets a chance.
## - **AC4**: villager 0 COUNTS toward `starting_villager_count` -- stated
##   explicitly, not left implicit: `Valley.get_villagers().size()` equals
##   the configured count (never "count + 1").
## - **AC5**: [method Valley._assert_villager_placement_invariant] fails
##   loudly (an `assert()`, ADR-0005's "fail loudly, not silently"
##   convention) if a hosted villager is ever found standing on a
##   non-standable cell after [method Valley.spawn_starting_roster] runs.
class_name StrayDefaultVillagerPlacementTest
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")
const ValleyScene: PackedScene = preload("res://src/scene_world_management/Valley.tscn")


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

func _solid() -> CellContents:
	return CellContents.new(1, 0)


## Fills a flat, fully-standable plane around [param center] -- byte-for-byte
## `starting_roster_test.gd`/`villager_need_seeding_boot_test.gd`'s own
## established `_fill_flat_plane` fixture.
func _fill_flat_plane(voxel_world: VoxelWorldGrid, center: Vector3i, half_extent: int) -> void:
	for dx in range(-half_extent, half_extent + 1):
		for dz in range(-half_extent, half_extent + 1):
			voxel_world.set_cell(Vector3i(center.x + dx, center.y - 1, center.z + dz), _solid())


## Instantiates the REAL `Valley.tscn` directly (never through `GameWorld`),
## with a small, test-shaped [VoxelWorldConfig] swapped in BEFORE the node
## ever enters the tree -- byte-for-byte
## `villager_need_seeding_boot_test.gd`'s own established
## `_instantiate_bare_valley` precedent (duplicated here per this codebase's
## convention of small per-file fixture helpers, e.g. `_fill_flat_plane`
## above). Calls every hosted module's `setup()` EXCEPT [NeedsMood] and
## [Valley] itself -- callers finish wiring [NeedsMood] and call
## [method Valley.seed_default_villager_needs] themselves, mirroring
## [method Valley.spawn_starting_roster]'s own real ordering guard.
func _instantiate_bare_valley(villager_config: VillagerAIConfig) -> Valley:
	var valley: Valley = ValleyScene.instantiate()
	var voxel_world: VoxelWorldGrid = valley.get_node(^"VoxelWorldGrid") as VoxelWorldGrid
	var world_config := VoxelWorldConfig.new()
	world_config.world_width_cells = 64
	world_config.world_depth_cells = 64
	voxel_world.config = world_config
	valley.villager_ai_config = villager_config
	add_child(valley)
	auto_free(valley)
	var needs_mood: NeedsMood = valley.get_needs_mood()
	for module: Node in valley.get_injected_tier_modules():
		if module == needs_mood:
			continue
		if module.has_method(&"setup"):
			module.setup()
	needs_mood.setup()
	valley.seed_default_villager_needs()
	return valley


# ---------------------------------------------------------------------------
# AC1 — Anti-Vacuity Lever: asserted on the REAL booted scene
# ---------------------------------------------------------------------------

func test_real_boot_no_villager_stands_at_the_world_origin_and_every_villager_is_standable() -> void:
	# Arrange + Act -- the real, unmodified production boot (2000x2000
	# config, the shipped `.tres` roster config), mirrors
	# `world_genesis_boot_test.gd`'s own established real-boot fixture.
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)

	# Assert -- boot reached ACTIVE through the real gate, genesis included.
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()
	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()

	# Anti-Vacuity Lever (AC1): every real villager stands on a cell the real
	# voxel world reports standable -- none at (0, 0, 0), which is not this
	# world's real center.
	var villagers: Array[VillagerAi] = valley.get_villagers()
	assert_int(villagers.size()).is_greater(0)
	var world_center: Vector3i = VillagerRosterSpawner.world_center_cell(voxel_world.config)
	assert_vector(Vector3(world_center)).is_not_equal(Vector3.ZERO)
	for villager: VillagerAi in villagers:
		var cell: Vector3i = villager.get_current_cell()
		assert_vector(Vector3(cell)).is_not_equal(Vector3.ZERO)
		assert_bool(VillagerWalkabilityRules.is_standable(voxel_world, cell)).is_true()


# ---------------------------------------------------------------------------
# AC2 — one placement rule, every villager within the spawner's search radius
# ---------------------------------------------------------------------------

func test_villager_zero_is_within_the_spawner_search_radius_of_world_center() -> void:
	# Arrange -- a lightweight Valley, real terrain filled around center.
	var villager_config := VillagerAIConfig.new()
	villager_config.starting_villager_count = 3
	var valley: Valley = _instantiate_bare_valley(villager_config)
	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	var center: Vector3i = VillagerRosterSpawner.world_center_cell(voxel_world.config)
	_fill_flat_plane(voxel_world, center, 10)

	# Act
	valley.spawn_starting_roster()

	# Assert -- EVERY hosted villager (villager 0 included) lies within
	# MAX_SEARCH_RADIUS (Chebyshev distance) of the world center -- the same
	# bound every other roster member is already held to. Reuses
	# [VillagerJobSelector.chebyshev_distance] (ADR-0007: never a second,
	# locally-duplicated copy of a shared distance metric).
	for villager: VillagerAi in valley.get_villagers():
		var cell: Vector3i = villager.get_current_cell()
		var chebyshev_distance: int = VillagerJobSelector.chebyshev_distance(cell, center)
		assert_int(chebyshev_distance).is_less_equal(VillagerRosterSpawner.MAX_SEARCH_RADIUS)
		assert_bool(VillagerWalkabilityRules.is_standable(voxel_world, cell)).is_true()


# ---------------------------------------------------------------------------
# AC3 — zero standable cells: deterministic, logged, never silent
# ---------------------------------------------------------------------------

func test_spawn_starting_roster_logs_and_leaves_villager_zero_when_no_standable_cell_exists() -> void:
	# Arrange -- a genuinely empty grid (mirrors `starting_roster_test.gd`'s
	# own "world has zero standable cells" fixture) -- no terrain filled at
	# all, so the search exhausts MAX_SEARCH_RADIUS and finds nothing.
	var villager_config := VillagerAIConfig.new()
	villager_config.starting_villager_count = 1
	var valley: Valley = _instantiate_bare_valley(villager_config)
	var default_villager: VillagerAi = valley.get_villager_ai()
	var cell_before: Vector3i = default_villager.get_current_cell()
	var center: Vector3i = VillagerRosterSpawner.world_center_cell(valley.get_voxel_world().config)
	var expected_message: String = (
		"Valley.spawn_starting_roster: no standable cell found near world center %s" +
		" for villager 0 within VillagerRosterSpawner.MAX_SEARCH_RADIUS -- it remains" +
		" at %s (logged, not silently left there)"
	) % [center, cell_before]

	# Act + Assert -- AC3: deterministic, logged (never silent) outcome.
	await assert_error(func() -> void: valley.spawn_starting_roster()).is_push_warning(expected_message)

	# Assert -- villager 0 was never crashed, never duplicated, never moved.
	assert_int(valley.get_villagers().size()).is_equal(1)
	assert_object(valley.get_villager_ai()).is_same(default_villager)
	assert_vector(Vector3(default_villager.get_current_cell())).is_equal(Vector3(cell_before))

	# Assert -- a LATER call, once real terrain exists, still gets a chance
	# (the warning-logged outcome above is not a permanent "give up").
	_fill_flat_plane(valley.get_voxel_world(), center, 10)
	valley.spawn_starting_roster()
	assert_bool(
		VillagerWalkabilityRules.is_standable(valley.get_voxel_world(), valley.get_villager_ai().get_current_cell())
	).is_true()


# ---------------------------------------------------------------------------
# AC4 — the roster count is honest: villager 0 counts toward it
# ---------------------------------------------------------------------------

func test_get_villagers_count_equals_starting_villager_count_when_enough_standable_cells_exist() -> void:
	# Arrange -- three independent lightweight Valleys, one per config value,
	# so each proves the SAME convention in isolation (never accumulated
	# state from a shared fixture).
	for count in [1, 3, 5]:
		var villager_config := VillagerAIConfig.new()
		villager_config.starting_villager_count = count
		var valley: Valley = _instantiate_bare_valley(villager_config)
		var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
		var center: Vector3i = VillagerRosterSpawner.world_center_cell(voxel_world.config)
		_fill_flat_plane(voxel_world, center, 10)

		# Act
		valley.spawn_starting_roster()

		# Assert -- AC4: get_villagers().size() equals the configured count
		# exactly -- villager 0 counts toward it, never "count + 1".
		assert_int(valley.get_villagers().size()).is_equal(count)


# ---------------------------------------------------------------------------
# AC5 — the boot invariant fails loudly on a corrupted placement
# ---------------------------------------------------------------------------

func test_villager_placement_invariant_fails_loudly_on_a_non_standable_villager() -> void:
	# Arrange -- a lightweight Valley, real terrain, one successful roster
	# spawn so a second, newly-constructed villager exists.
	var villager_config := VillagerAIConfig.new()
	villager_config.starting_villager_count = 2
	var valley: Valley = _instantiate_bare_valley(villager_config)
	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	var center: Vector3i = VillagerRosterSpawner.world_center_cell(voxel_world.config)
	_fill_flat_plane(voxel_world, center, 10)
	valley.spawn_starting_roster()
	var roster: Array[VillagerAi] = valley.get_villagers()
	assert_int(roster.size()).is_equal(2)

	# Act -- deliberately corrupt the second villager's placement to a
	# non-standable cell (never reachable through this story's own logic,
	# which only ever places villagers on [VillagerWalkabilityRules
	# .is_standable]-confirmed cells) -- proves the assert exists and fires,
	# a fixture-only scenario, not a production reachable one.
	var corrupted: VillagerAi = roster[1]
	var non_standable_cell: Vector3i = center + Vector3i(1000, 0, 1000)
	corrupted.current_cell = non_standable_cell
	var expected_message: String = (
		"Assertion failed: Valley: villager_id %d stands on a non-standable cell %s after spawn_starting_roster"
	) % [corrupted.get_villager_id(), non_standable_cell]

	# Assert -- a further spawn_starting_roster() call re-runs the boot
	# invariant sweep over every hosted villager, including the corrupted one.
	await assert_error(func() -> void: valley.spawn_starting_roster()).is_runtime_error(expected_message)
