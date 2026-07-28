## Integration test -- Story villager-ai-024 ("A villager cannot finish a
## wall"), the story's own Anti-Vacuity Lever, verbatim: "draw a room through
## the hosted WallTool, run the real tick loop with one real villager, and
## assert EVERY blueprint cell reaches BUILT within a stated tick budget."
##
## Real chain throughout, no mocks except the tick source's own driver (the
## REAL global `TimeTickSystem` Autoload, emitted on directly -- mirrors
## `build_tool_hosting_boot_test.gd`'s own established real-boot precedent
## and `production/qa/evidence/scene-009-reproduction-not-a-live-test.gd.txt`'s
## `_tick_until_built` helper, reused in shape here): real booted
## [GameWorld]/[Valley], real [WallTool] -> real [CommitPipeline] -> real
## [BuildProjectRegistry] -> real [ConstructionJobQueue] ->
## [ConstructionTickLoop] -> the real hosted roster villager's own
## Deciding/claim/travel/on-site/seal-prevention pass, every tick.
##
## Before this story's fix, this exact scenario plateaued at the topmost wall
## layer in every configuration tried (see `wall_column_reachability_test.gd`'s
## own class doc comment for the confirmed root cause, and this story's
## commit body for the verbatim pre-change plateau recorded against this very
## test before the fix landed).
class_name WallRoomNoPlateauTest
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")

## Generous -- a small 4-segment room (10 perimeter cells x wall_height, up to
## 30 cells at the shipped default) for one villager, well inside this cap
## even accounting for Deciding-scheduler/travel overhead per cell.
const TICK_CAP: int = 4000


func _boot_real_game_world() -> GameWorld:
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	return world


func _fill_flat_plane(voxel_world: VoxelWorldGrid, center: Vector3i, half_extent: int) -> void:
	for dx in range(-half_extent, half_extent + 1):
		for dz in range(-half_extent, half_extent + 1):
			voxel_world.set_cell(Vector3i(center.x + dx, center.y - 1, center.z + dz), CellContents.new(1, 0))


## Every wall-tool drag segment (press, release) needed to enclose a 3(X) x
## 4(Z) outer footprint's perimeter with zero cell overlap between segments
## -- mirrors `tools/payoff_loop_demo.gd`'s own `_wall_segments` geometry
## exactly (the same shape this story's own finding was reproduced against).
func _wall_segments(anchor: Vector3i) -> Array:
	var ax: int = anchor.x
	var ay: int = anchor.y
	var az: int = anchor.z
	return [
		[Vector3i(ax, ay, az), Vector3i(ax + 2, ay, az)],
		[Vector3i(ax, ay, az + 3), Vector3i(ax + 2, ay, az + 3)],
		[Vector3i(ax, ay, az + 1), Vector3i(ax, ay, az + 2)],
		[Vector3i(ax + 2, ay, az + 1), Vector3i(ax + 2, ay, az + 2)],
	]


func _count_built(cells: Array[BlueprintCell]) -> int:
	var count: int = 0
	for cell: BlueprintCell in cells:
		if cell.state == BlueprintCell.MicroState.BUILT:
			count += 1
	return count


## Resolves every distinct [BuildProject] touching [param blueprint_cells] and
## releases each one exactly once -- mirrors `tools/payoff_loop_demo.gd`'s own
## `_release_projects_for` / the scene-009 reproduction's `_draft_and_release`.
func _release_projects_for(blueprint_cells: Array[BlueprintCell], registry: BuildProjectRegistry) -> void:
	var touched_ids: Dictionary[int, bool] = {}
	for cell: BlueprintCell in blueprint_cells:
		var project_id: int = registry.project_at_cell(cell.cell)
		if project_id != -1:
			touched_ids[project_id] = true
	for project_id: int in touched_ids.keys():
		registry.release_project(project_id)


func test_ac1_a_room_drawn_through_the_hosted_wall_tool_reaches_full_enclosure() -> void:
	var world: GameWorld = _boot_real_game_world()
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()

	var villagers: Array[VillagerAi] = valley.get_villagers()
	assert_int(villagers.size()).is_equal(1)
	var villager: VillagerAi = villagers[0]
	# This test's OWN scope is job-selection reachability (story villager-ai-024),
	# not Needs & Mood balance (a separate system/epic): the real Needs & Mood
	# System is otherwise live in this real boot and, over the thousands of
	# real ticks a full multi-segment room can take, its own GDD Rule 2 tier-1
	# priority ("Urgent need > Work") legitimately preempts construction --
	# confirmed separately (a real, ground-sleep-only villager with no bed yet
	# built can cycle need-driven Wandering/Sleeping indefinitely without ever
	# returning to tier 2). Detaching the (nil-safe, non-asserted) dependency
	# isolates THIS test's own claim -- "construction alone, undisturbed by an
	# unrelated system, no longer plateaus" -- exactly as `_has_urgent_need`'s
	# own doc comment already documents as the safe "not yet wired" default,
	# never a product code change.
	villager.needs_provider = null

	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	var wall_tool: WallTool = valley.get_wall_tool()
	var wall_height: int = wall_tool.config.wall_height
	assert_int(wall_height).is_greater(1)

	# A generous, controlled flat plane near the real villager's own spawn --
	# mirrors `build_tool_hosting_boot_test.gd`'s own `_fill_flat_plane`
	# fixture precedent, never a direct write to any cell this test then
	# claims villager AI built (only the GROUND the room sits on).
	var anchor: Vector3i = villager.get_current_cell() + Vector3i(4, 0, 4)
	_fill_flat_plane(voxel_world, anchor, 10)

	var commit_pipeline: CommitPipeline = valley.get_commit_pipeline()
	var placement_pick: PlacementPick = valley.get_placement_pick()
	var build_project_registry: BuildProjectRegistry = valley.get_build_project_registry()
	var construction_job_queue: ConstructionJobQueue = valley.get_construction_job_queue()

	valley.get_build_editor_mode().arm_tool(ToolStateMachine.TOOL_ID_WALL)
	commit_pipeline.set_selected_item(&"wood_block")
	placement_pick.resolve_pick(VoxelWorldGrid.cell_to_world(anchor) + Vector3(0.0, 60.0, 0.0), Vector3.DOWN)
	assert_bool(placement_pick.get_current_pick().hit).is_true()

	var wall_cells: Array[BlueprintCell] = []
	for segment: Array in _wall_segments(anchor):
		var candidate_cells: Array[Vector3i] = wall_tool.resolve_cell_set(true, segment[0], segment[1])
		wall_cells.append_array(commit_pipeline.commit(candidate_cells))

	assert_int(wall_cells.size()).is_equal(10 * wall_height)
	_release_projects_for(wall_cells, build_project_registry)
	assert_bool(construction_job_queue.get_available_jobs().size() > 0).is_true()

	# Drive the REAL global TimeTickSystem directly (mirrors
	# `build_tool_hosting_boot_test.gd`'s own direct-Autoload-tick precedent) --
	# the real, hosted ConstructionTickLoop/VillagerOnSiteGate/
	# VillagerSealPreventionGate/VillagerAi already bound to it at boot are
	# the only things that ever move a cell toward BUILT.
	var ticks: int = 0
	while _count_built(wall_cells) < wall_cells.size() and ticks < TICK_CAP:
		villager.advance_travel_progress(1000.0)
		TimeTickSystem.tick.emit()
		ticks += 1

	# On failure, print exactly the cell/state/claimed_by triple this story's
	# own Anti-Vacuity Lever names -- the same evidence shape the pre-fix
	# plateau was recorded in (see this file's own class doc comment).
	var built_count: int = _count_built(wall_cells)
	if built_count < wall_cells.size():
		for cell: BlueprintCell in wall_cells:
			if cell.state != BlueprintCell.MicroState.BUILT:
				print(
					"WallRoomNoPlateauTest STUCK CELL: cell=%s state=%d claimed_by=%d"
					% [cell.cell, cell.state, cell.claimed_by_villager_id]
				)
	assert_int(built_count).override_failure_message(
		"Only %d/%d wall cells reached BUILT within %d ticks -- the story-024 plateau"
		% [built_count, wall_cells.size(), TICK_CAP]
	).is_equal(wall_cells.size())
