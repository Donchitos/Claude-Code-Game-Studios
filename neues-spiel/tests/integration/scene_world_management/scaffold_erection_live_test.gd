## Erection-tier proof (story `building-034`): the RUNNING GAME erects
## scaffolding, and only when it is actually needed.
##
## Deliberately AI-free, like its occupancy-tier sibling. It drives the real
## hosted `ConstructionJobQueue.report_unreachable` seam directly rather than
## trying to make a villager report naturally — an earlier attempt did the
## latter and was unstable, because a queue-level `release_claim` does not
## reset [VillagerAi]'s own pursuit state.
##
## The second test here is the one that matters most. Erection used to fire on
## the FIRST report, and a pre-claim probe calls a cell unreachable whenever it
## is unreachable AT THAT INSTANT — which, with one villager walking a site, is
## most cells most of the time. Measured on a real hosted build of a 30-cell
## room: 20+ reports, every one planning successfully, flooding the queue with
## scaffold jobs. Since a villager holds only ONE claim, the real wall cells
## starved and villager-ai-024's regression test fell 30/30 -> 27/30. The
## persistence gate is what restores the user's own stated rule: scaffolding is
## built only when it is NEEDED.
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")


func _boot_valley() -> Valley:
	var world: Node = auto_free(GameWorldScene.instantiate())
	add_child(world)
	return world.get_valley() as Valley


func test_a_single_report_never_erects_scaffolding() -> void:
	var valley: Valley = _boot_valley()
	var registry: ScaffoldRegistry = valley.get_scaffold_registry()
	var before: int = valley.get_build_project_registry().get_projects().size()

	# One report is "not right now", never "needs scaffolding".
	valley.get_construction_job_queue().report_unreachable(Vector3i(1002, 8, 1006))

	assert_int(registry.get_cells().size()).is_equal(0)
	assert_int(valley.get_build_project_registry().get_projects().size()).is_equal(before)


func test_the_erection_coordinator_is_hosted_and_subscribed() -> void:
	var valley: Valley = _boot_valley()
	var coordinator: ScaffoldErectionCoordinator = valley.get_scaffold_erection_coordinator()
	assert_object(coordinator).is_not_null()
	# Subscribed to the real seam, not merely constructed — the difference
	# between hosted and actually wired is this project's most-repeated defect.
	assert_bool(
		valley.get_construction_job_queue().job_reported_unreachable.is_connected(
			coordinator._on_job_reported_unreachable
		)
	).is_true()
