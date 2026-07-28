## Scaffold OCCUPANCY-tier hosting proof (story `building-034`, the piece that
## landed first).
##
## Deliberately small and deliberately AI-free. An earlier version of this file
## drove villager claims and positions directly to prove the whole erection
## path in one test; it was unstable, because a queue-level `release_claim`
## does not reset [VillagerAi]'s own pursuit state, so the villager re-fired its
## detection mid-run and shifted the geometry the assertions assumed. This file
## asserts only what THIS piece actually wires, and asserts it against a real
## booted [GameWorld] rather than a fixture.
##
## Non-vacuous by construction: before this piece, `Valley` hosted no
## [ScaffoldRegistry] at all, no villager carried one, and the nav graph had
## nothing to subscribe to — every assertion below reads null or fails to
## resolve on the previous build.
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")


func _boot_world() -> Node:
	var world: Node = auto_free(GameWorldScene.instantiate())
	add_child(world)
	return world


func test_valley_hosts_exactly_one_scaffold_registry_and_shares_it() -> void:
	var world: Node = _boot_world()
	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()

	var registry: ScaffoldRegistry = valley.get_scaffold_registry()
	assert_object(registry).is_not_null()

	# The presentation tier must point at the SAME instance, never a second one
	# — Sprint 12's standing rule: no collaborator may be both optional and
	# consequential.
	assert_object(valley.get_scaffold_presentation().scaffold_registry).is_same(registry)
	# And so must the tick loop, which is what routes a completed SCAFFOLD cell
	# into membership.
	assert_object(valley.get_construction_tick_loop().scaffold_registry).is_same(registry)


func test_every_hosted_villager_carries_the_same_scaffold_registry() -> void:
	var world: Node = _boot_world()
	var valley: Valley = world.get_valley() as Valley
	var registry: ScaffoldRegistry = valley.get_scaffold_registry()

	var villagers: Array[VillagerAi] = valley.get_villagers()
	assert_int(villagers.size()).is_greater(0)
	for villager: VillagerAi in villagers:
		# Not "is not null" — the SAME instance. Two registries would mean a
		# villager walking on scaffolding the rest of the game cannot see.
		assert_object(villager.scaffold_registry).is_same(registry)


func test_walkability_stays_scaffold_blind_for_callers_that_pass_nothing() -> void:
	# ADR-0007 section 1b's binding promise, asserted rather than trusted: Build
	# Validation passes no scaffold source anywhere, so it must observe exactly
	# pre-amendment behaviour. This is the invariant whose first implementation
	# broke it, turning the whole suite red.
	var world: Node = _boot_world()
	var valley: Valley = world.get_valley() as Valley
	var grid: VoxelWorldGrid = valley.get_voxel_world()
	var registry: ScaffoldRegistry = valley.get_scaffold_registry()

	# Pick a cell in genuine open air ABOVE the villager but INSIDE the world
	# bounds. The first draft used y=40, outside max_y — and every out-of-bounds
	# read is treated as blocking, so the cell was unstandable for a reason that
	# had nothing to do with scaffolding. The predicate was right; the fixture
	# was wrong.
	var floating: Vector3i = valley.get_villagers()[0].get_current_cell() + Vector3i(0, 4, 0)
	assert_bool(VillagerWalkabilityRules.is_standable(grid, floating)).is_false()
	registry.add(floating)
	# With the source supplied, scaffolding supports itself (section 1a).
	assert_bool(VillagerWalkabilityRules.is_standable(grid, floating, registry)).is_true()
	# Without it, nothing changed — the same cell, the same answer as before.
	assert_bool(VillagerWalkabilityRules.is_standable(grid, floating)).is_false()
