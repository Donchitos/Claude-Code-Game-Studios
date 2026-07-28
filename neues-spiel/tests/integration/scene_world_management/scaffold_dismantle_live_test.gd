## Dismantle-tier proof (story `building-034`): scaffolding is taken down again
## once the project it served is finished, and taken down TOP-DOWN so the
## worker rides it back to the ground instead of being stranded on it.
##
## AI-FREE BY DESIGN, and that is the whole point of this file. Two earlier
## attempts at proving the dismantle half drove real villagers and were
## unstable — a queue-level `release_claim` does not reset [VillagerAi]'s own
## pursuit state, so the villager re-fired its detection mid-run and moved the
## geometry the assertions assumed. Here the BUILD and SCAFFOLD projects are
## constructed directly, so what is under test is the ORDERING and the
## TRIGGER, never the pathfinder.
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")


func _boot_valley() -> Valley:
	var world: Node = auto_free(GameWorldScene.instantiate())
	add_child(world)
	return world.get_valley() as Valley


func test_the_dismantle_coordinator_is_hosted_and_subscribed_to_both_triggers() -> void:
	var valley: Valley = _boot_valley()
	var coordinator: ScaffoldDismantleCoordinator = valley.get_scaffold_dismantle_coordinator()
	assert_object(coordinator).is_not_null()

	# Trigger 1 — the owning project finishing. Constructed-but-unsubscribed is
	# this project's single most repeated defect, so identity of the connection
	# is asserted, not merely the existence of the object.
	assert_bool(
		valley.get_construction_tick_loop().construction_completed.is_connected(
			coordinator._on_construction_completed
		)
	).is_true()
	# Trigger 2 — the player cancelling the project mid-build (D4).
	assert_bool(
		valley.get_removal_tool().project_canceled.is_connected(coordinator.on_project_canceled)
	).is_true()


func test_dismantle_order_is_strictly_top_down() -> void:
	# The ordering rule is what keeps a worker from stranding itself: it always
	# removes the cell ABOVE the one it stands on, so it descends as it works.
	# Asserted on the planner directly — no world, no villager, no clock.
	var column: Array[Vector3i] = [
		Vector3i(10, 4, 10),
		Vector3i(10, 6, 10),
		Vector3i(10, 5, 10),
	]
	var nobody: Array = []

	# Deliberately shuffled input: the planner must impose the order, never
	# inherit it. Taken one at a time, exactly as the tick loop consumes it.
	var first: Vector3i = ScaffoldDismantlePlanner.next_top_down_demolition_cell(column, nobody)
	assert_int(first.y).is_equal(6)
	column.erase(first)
	var second: Vector3i = ScaffoldDismantlePlanner.next_top_down_demolition_cell(column, nobody)
	assert_int(second.y).is_equal(5)
	column.erase(second)
	var third: Vector3i = ScaffoldDismantlePlanner.next_top_down_demolition_cell(column, nobody)
	assert_int(third.y).is_equal(4)


func test_a_cell_a_worker_stands_in_is_never_the_next_to_go() -> void:
	# SC-INV-1: no scaffold cell is removed while a villager's body column
	# occupies it. Without this the "top-down" rule would happily delete the
	# floor under the worker that is riding the structure down.
	var column: Array[Vector3i] = [
		Vector3i(10, 4, 10),
		Vector3i(10, 5, 10),
		Vector3i(10, 6, 10),
	]
	# The inner array MUST be typed. The planner assigns each entry to an
	# Array[Vector3i], and an untyped literal crashes on assignment — the
	# typed-Array trap this codebase has been bitten by repeatedly.
	var body_column: Array[Vector3i] = [Vector3i(10, 6, 10)]
	var worker_on_top: Array = [body_column]

	var next: Vector3i = ScaffoldDismantlePlanner.next_top_down_demolition_cell(
		column, worker_on_top
	)
	assert_int(next.y).is_equal(5)  # skipped the occupied top, took the one below


func test_dismantle_defers_while_a_builder_is_still_up_on_the_structure() -> void:
	# SC-INV-2, the escape-route rule. SC-INV-1 protects the cell a villager
	# stands IN; this protects the way DOWN. Measured on the first real run with
	# scaffolding wired: 30/30 walls built (a first), then the roof stalled at
	# 10/12 and the villager slept five times at y=10 — above the walls and
	# above the roof plane. The wall project reaches DONE while the ROOF is
	# still a separate unfinished project, so dismantle fired with the builder
	# still up top and took away its descent.
	var valley: Valley = _boot_valley()
	var coordinator: ScaffoldDismantleCoordinator = valley.get_scaffold_dismantle_coordinator()
	var villager: VillagerAi = valley.get_villagers()[0]

	# A scaffold structure directly under the villager's own column.
	var ground: Vector3i = villager.get_current_cell()
	var registry: ScaffoldRegistry = valley.get_scaffold_registry()
	registry.add(ground)

	var project := BuildProject.new(
		valley.get_build_project_registry().allocate_project_id(),
		BuildProject.Kind.SCAFFOLD,
		1,
	)
	project.add_cell(
		BlueprintCell.new(ground, BlueprintCell.MicroState.PLANNED, BlueprintCell.Category.SCAFFOLD)
	)
	valley.get_build_project_registry().register_project(project)

	# The served project reports DONE while the villager stands on the
	# structure: dismantling must NOT latch.
	coordinator._start_top_down_dismantle(1)
	assert_bool(coordinator.is_dismantling(1)).override_failure_message(
		"dismantle must defer while a builder is still standing on or above the scaffolding"
	).is_false()
