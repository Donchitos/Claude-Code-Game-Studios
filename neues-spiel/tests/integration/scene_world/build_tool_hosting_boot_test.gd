## Integration test — Scene/World Management Story scene-007 (Build-tool &
## project-lifecycle hosting; ADR-0005 + ADR-0001 primary, ADR-0016 primary
## for Sub-scope B's own semantics, ADR-0010 secondary).
##
## A NEW file (scene-006's own precedent: `villager_need_seeding_boot_test.gd`
## was created new rather than extending `world_genesis_boot_test.gd`, because
## that file already bundles one expensive real production boot into a single
## test; this story's own AC cluster — tool routing, the registry/job-queue
## chain, the ghost preview, the undo stack, plus two grep guards — is at
## least as independent, so it gets its own file here too).
##
## Closes the FOURTH ship-green-and-uncalled occurrence this project has hit
## (`scene-006` recorded the first three): the entire build-interaction tier
## — [BuildEditorMode], the five placement tools, [GhostPreview],
## [UndoRedoStack], [BuildProjectRegistry], [ConstructionJobQueue],
## [PlanOnlyUndoGate], [RemovalTool], [FurnitureRegistry] — was, before this
## story, either in no scene at all or constructed nowhere in `src/`.
##
## **AC-PROBE-IS-NON-VACUOUS, the `scene-006` discipline restated**: the two
## tests proving AC-TOOL-RESOLVER-IS-LIVE and AC-COMMIT-REACHES-THE-REGISTRY
## were each demonstrated to FAIL when their own wiring line was removed —
## once, by hand, during development — then the removal was reverted verbatim
## and the suite re-run green. The exact removed line, the observed failure,
## and the restore confirmation are recorded in this story's own commit body
## (not duplicated here as a permanent artifact, per this project's own
## `scene-006` precedent: the negative-control run is a development-time
## demonstration, not a checked-in second test mode).
##
## **Camera/pick technique**: every test that needs a real commit reparents
## the HOSTED (real, booted) [CameraInput] into a dedicated, deterministically
## -sized [SubViewport] (mirrors `gameworld_e2e_loop_test.gd`'s own established
## analytic-yaw rig) and rotates it to face exactly `yaw = PI` — the SAME
## trick that test uses, generalized so it works regardless of the shipped
## `camera_input_config.tres`'s own `start_yaw` value. A headless
## [SubViewport]'s default mouse position is the deterministic `(0, 0)` corner
## that same established rig also relies on. Reparenting (`Node.reparent`,
## Godot 4.3+) only changes which [Viewport] [CameraInput].get_world_ray()`
## resolves against — every other reference this class doc comment holds
## remains valid and functional (Valley._process() still calls
## [method CameraInput.get_target] on the SAME instance).
##
## A big, generously-sized flat terrain plane is filled directly around the
## production world-genesis focus cell (`VillagerRosterSpawner.world_center_cell`,
## the SAME cell [method GameWorld._run_world_genesis] already anchors the
## camera's own start target on) via [method VoxelWorldGrid.set_cell] — a
## direct grid write, this project's own established test convention (mirrors
## `villager_need_seeding_boot_test.gd`'s `_fill_flat_plane`). No explicit
## [method CameraInput.set_target] call is needed: the real production boot
## already points the camera at this exact cell.
class_name BuildToolHostingBootTest
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")


# ---------------------------------------------------------------------------
# Shared fixture helpers
# ---------------------------------------------------------------------------

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


## Reparents the hosted [CameraInput] into a fresh, deterministically-sized
## [SubViewport] and rotates it to face `yaw = PI` — see class doc comment.
func _reparent_hosted_camera_and_rotate(valley: Valley) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1000, 1000)
	add_child(viewport)
	auto_free(viewport)
	var camera_input: CameraInput = valley.get_camera_input()
	camera_input.reparent(viewport)
	var camera_config: CameraInputConfig = camera_input.config
	var yaw_delta: float = PI - camera_config.start_yaw
	var rotate_event := InputEventMouseMotion.new()
	rotate_event.relative = Vector2(yaw_delta / camera_config.mouse_drag_sensitivity, 0.0)
	rotate_event.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	camera_input._unhandled_input(rotate_event)


## Boots the real production world, fills a generous flat plane around the
## real world-genesis focus cell, and re-aims the hosted camera at it. Returns
## the booted [Valley].
func _setup_click_fixture() -> Valley:
	var world: GameWorld = _boot_real_game_world()
	var valley: Valley = world.get_valley() as Valley
	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	var center: Vector3i = VillagerRosterSpawner.world_center_cell(voxel_world.config)
	_fill_flat_plane(voxel_world, center, 40)
	_reparent_hosted_camera_and_rotate(valley)
	# A REAL RID-registered id: this test boots the REAL production
	# ResourceItemDatabase Autoload (rid-009's shipped tier-0 content), which
	# CommitPipeline.setup() resolves independently of GameWorld's own mock
	# boot-gate database — an invented placeholder id would be correctly
	# rejected by Core Rule 9's real availability gate.
	valley.get_commit_pipeline().set_selected_item(&"wood_block")
	return valley


## Fires one real click (zero cursor travel — the F4 click path, never a
## drag) through [param pick]'s own real `_unhandled_input`/`_input` handlers.
func _fire_click(pick: PlacementPick) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	pick._unhandled_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	pick._input(release)


# ---------------------------------------------------------------------------
# AC-HOSTED-BEFORE-ACTIVE
# ---------------------------------------------------------------------------

func test_ac_hosted_before_active_every_new_module_is_wired_and_set_up() -> void:
	var world: GameWorld = _boot_real_game_world()
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()

	# Documented non-proof (scene-006's own discipline, restated in this
	# story's own text): presence alone is exactly the vacuous shape
	# AC-PROBE-IS-NON-VACUOUS bans as the ONLY evidence — kept here purely as
	# the baseline structural check this AC's own wording says "is close to
	# vacuous and is not allowed to stand alone." The REAL proof is every
	# other test below.
	assert_object(valley.get_build_editor_mode()).is_not_null()
	assert_object(valley.get_wall_tool()).is_not_null()
	assert_object(valley.get_floor_tool()).is_not_null()
	assert_object(valley.get_roof_tool()).is_not_null()
	assert_object(valley.get_block_tool()).is_not_null()
	assert_object(valley.get_furniture_tool()).is_not_null()
	assert_object(valley.get_ghost_preview()).is_not_null()
	assert_object(valley.get_undo_redo_stack()).is_not_null()
	assert_object(valley.get_build_project_registry()).is_not_null()
	assert_object(valley.get_construction_job_queue()).is_not_null()
	assert_object(valley.get_removal_tool()).is_not_null()
	assert_object(valley.get_plan_only_undo_gate()).is_not_null()
	assert_object(valley.get_furniture_registry()).is_not_null()
	assert_object(valley.get_furniture_bed_provider()).is_not_null()

	assert_bool(valley.get_build_editor_mode().is_set_up()).is_true()
	assert_bool(valley.get_wall_tool().is_set_up()).is_true()
	assert_bool(valley.get_floor_tool().is_set_up()).is_true()
	assert_bool(valley.get_roof_tool().is_set_up()).is_true()
	assert_bool(valley.get_block_tool().is_set_up()).is_true()
	assert_bool(valley.get_furniture_tool().is_set_up()).is_true()
	assert_bool(valley.get_ghost_preview().is_set_up()).is_true()
	assert_bool(valley.get_undo_redo_stack().is_set_up()).is_true()

	# Cross-instance wiring — NOT vacuous: the SAME instances feed each other.
	assert_object(valley.get_villager_ai().job_queue).is_same(valley.get_construction_job_queue())
	assert_object(valley.get_villager_ai().bed_provider).is_same(valley.get_furniture_bed_provider())
	assert_object(valley.get_construction_tick_loop().furniture_registry).is_same(valley.get_furniture_registry())
	assert_object(valley.get_undo_redo_stack().write_tag).is_same(valley.get_construction_tick_loop().write_tag)
	assert_object(valley.get_build_editor_mode().tool_state_machine).is_same(valley.get_tool_state_machine())


func test_ac_hosted_before_active_failed_rid_never_wires_anything() -> void:
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	world.resource_item_database = database
	add_child(world)

	database.settle(false, ["build tool hosting boot test — forced Failed"])

	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.HALTED)
	assert_object(world.get_valley()).is_null()


# ---------------------------------------------------------------------------
# AC-TOOL-RESOLVER-IS-LIVE — the primary non-vacuity lever
# ---------------------------------------------------------------------------

func test_ac_tool_resolver_is_live_wall_click_produces_wall_height_cells_from_config() -> void:
	var valley: Valley = _setup_click_fixture()
	var wall_config: WallToolConfig = valley.get_wall_tool().config
	# The AC's own void-guard: this assertion is meaningless (and the AC
	# itself void) unless the shipped config keeps wall_height > 1.
	assert_int(wall_config.wall_height).is_greater(1)

	valley.get_build_editor_mode().arm_tool(ToolStateMachine.TOOL_ID_WALL)
	_fire_click(valley.get_placement_pick())

	var cells: Array[BlueprintCell] = valley.get_commit_pipeline().get_blueprint_cells()
	# Read from config, never a literal: the shipped wall_tool_config.tres
	# carries wall_height = 3, and this assertion reads THAT value, not "3".
	assert_int(cells.size()).is_equal(wall_config.wall_height)

	# One vertical column: all cells share X/Z, Y values are consecutive.
	var xs: Dictionary = {}
	var zs: Dictionary = {}
	var ys: Array[int] = []
	for cell: BlueprintCell in cells:
		xs[cell.cell.x] = true
		zs[cell.cell.z] = true
		ys.append(cell.cell.y)
	assert_int(xs.size()).is_equal(1)
	assert_int(zs.size()).is_equal(1)
	ys.sort()
	for i in range(1, ys.size()):
		assert_int(ys[i]).is_equal(ys[i - 1] + 1)


func test_ac_tool_resolver_is_live_re_arming_to_block_tool_produces_that_tools_own_cell_set() -> void:
	var valley: Valley = _setup_click_fixture()
	var wall_height: int = valley.get_wall_tool().config.wall_height

	valley.get_build_editor_mode().arm_tool(ToolStateMachine.TOOL_ID_WALL)
	_fire_click(valley.get_placement_pick())
	assert_int(valley.get_commit_pipeline().get_blueprint_cells().size()).is_equal(wall_height)

	# Re-point the pick at a fresh, still-untracked column (a neighboring
	# cell in the SAME filled plane) — translating the camera's target by an
	# exact integer cell-size shifts the resolved hit cell by the identical
	# integer amount (floor(x + n) == floor(x) + n for any real x), so this
	# is never a boundary-precision gamble.
	var camera_input: CameraInput = valley.get_camera_input()
	camera_input.set_target(camera_input.get_target() + Vector3(6.0, 0.0, 0.0))

	valley.get_build_editor_mode().arm_tool(ToolStateMachine.TOOL_ID_BLOCK)
	_fire_click(valley.get_placement_pick())

	# Proves the router RE-POINTED on this second arm rather than latching
	# the wall tool's own resolver: exactly one NEW cell (BlockTool's own
	# single-cell formula), not another wall_height-sized column.
	assert_int(valley.get_commit_pipeline().get_blueprint_cells().size()).is_equal(wall_height + 1)


# ---------------------------------------------------------------------------
# AC-COMMIT-REACHES-THE-REGISTRY
# ---------------------------------------------------------------------------

func test_ac_commit_reaches_the_registry_single_commit_owns_all_its_cells_under_one_project() -> void:
	var valley: Valley = _setup_click_fixture()
	valley.get_build_editor_mode().arm_tool(ToolStateMachine.TOOL_ID_WALL)
	_fire_click(valley.get_placement_pick())

	var registry: BuildProjectRegistry = valley.get_build_project_registry()
	var cells: Array[BlueprintCell] = valley.get_commit_pipeline().get_blueprint_cells()
	assert_int(cells.size()).is_greater(0)
	var ids: Dictionary = {}
	for cell: BlueprintCell in cells:
		var project_id: int = registry.project_at_cell(cell.cell)
		assert_int(project_id).is_not_equal(-1)
		ids[project_id] = true
	assert_int(ids.size()).is_equal(1)
	assert_int(registry.get_projects().size()).is_equal(1)


func test_ac_commit_reaches_the_registry_adjacent_merges_distant_creates_second() -> void:
	var valley: Valley = _setup_click_fixture()
	var registry: BuildProjectRegistry = valley.get_build_project_registry()
	var camera_input: CameraInput = valley.get_camera_input()

	valley.get_build_editor_mode().arm_tool(ToolStateMachine.TOOL_ID_BLOCK)
	_fire_click(valley.get_placement_pick())
	assert_int(registry.get_projects().size()).is_equal(1)
	var first_cell: Vector3i = valley.get_commit_pipeline().get_blueprint_cells()[0].cell
	var first_project_id: int = registry.project_at_cell(first_cell)

	# Adjacent commit (26-neighborhood, ADR-0016 §2/F6) — exactly one cell
	# over on the SAME flat plane.
	camera_input.set_target(camera_input.get_target() + Vector3(1.0, 0.0, 0.0))
	_fire_click(valley.get_placement_pick())
	assert_int(registry.get_projects().size()).is_equal(1)
	for cell: BlueprintCell in valley.get_commit_pipeline().get_blueprint_cells():
		assert_int(registry.project_at_cell(cell.cell)).is_equal(first_project_id)

	# Distant commit — far enough (31 cells total) to never 26-adjoin either
	# prior cell.
	camera_input.set_target(camera_input.get_target() + Vector3(30.0, 0.0, 0.0))
	_fire_click(valley.get_placement_pick())
	assert_int(registry.get_projects().size()).is_equal(2)


# ---------------------------------------------------------------------------
# AC-RELEASED-PROJECT-REACHES-THE-JOB-QUEUE
# ---------------------------------------------------------------------------

func test_ac_released_project_reaches_the_job_queue_after_release_only() -> void:
	var valley: Valley = _setup_click_fixture()
	valley.get_build_editor_mode().arm_tool(ToolStateMachine.TOOL_ID_BLOCK)
	_fire_click(valley.get_placement_pick())

	var registry: BuildProjectRegistry = valley.get_build_project_registry()
	var queue: ConstructionJobQueue = valley.get_construction_job_queue()
	var committed_cell: Vector3i = valley.get_commit_pipeline().get_blueprint_cells()[0].cell
	var project_id: int = registry.project_at_cell(committed_cell)
	assert_int(project_id).is_not_equal(-1)

	# Draft is not BUILDING-eligible — drive the landed state machine, never
	# assert an invented state name.
	assert_bool(queue.has_available_job()).is_false()

	registry.release_project(project_id)

	assert_bool(queue.has_available_job()).is_true()
	var available_cells: Array[Vector3i] = []
	for job: BlueprintCell in queue.get_available_jobs():
		available_cells.append(job.cell)
	assert_array(available_cells).contains([committed_cell])

	# The hosted VillagerAi.job_queue is the SAME instance the registry
	# feeds — its own duck-typed _has_available_job() path sees it too,
	# because it reads through this identical reference.
	assert_object(valley.get_villager_ai().job_queue).is_same(queue)


# ---------------------------------------------------------------------------
# AC-GHOST-MIRRORS-THE-ARMED-TOOL
# ---------------------------------------------------------------------------

func test_ac_ghost_mirrors_the_armed_tool_wall_height_cells_shown_and_escape_hides() -> void:
	var valley: Valley = _setup_click_fixture()
	var ghost: GhostPreview = valley.get_ghost_preview()
	var wall_height: int = valley.get_wall_tool().config.wall_height

	valley.get_build_editor_mode().arm_tool(ToolStateMachine.TOOL_ID_WALL)
	# A hover pick (no click) — drives PlacementPick's own real per-frame
	# hover path directly, mirroring its own _process() driver.
	valley.get_placement_pick().update_pick()

	assert_bool(ghost.is_live_preview_visible()).is_true()
	assert_int(ghost.get_live_preview_cells().size()).is_equal(wall_height)

	valley.get_build_editor_mode().handle_escape()
	assert_bool(ghost.is_live_preview_visible()).is_false()


# ---------------------------------------------------------------------------
# AC-BUILD-MODE-IS-THE-ONLY-ARMING-PATH
# ---------------------------------------------------------------------------

func test_ac_build_mode_is_the_only_arming_path_grep_guard_zero_arm_tool_outside_build_editor_mode() -> void:
	var offenders: Array[String] = []
	_find_offending_arm_tool_calls("res://src", offenders)
	assert_array(offenders).is_empty()


func test_ac_build_mode_is_the_only_arming_path_fresh_boot_off_then_arm_then_click_commits() -> void:
	var valley: Valley = _setup_click_fixture()
	assert_int(valley.get_build_editor_mode().get_mode()).is_equal(BuildEditorMode.Mode.OFF)
	assert_int(valley.get_tool_state_machine().get_state()).is_equal(ToolStateMachine.State.IDLE)

	# A click while Off commits nothing (Rule 8a/8d — Off is fully inert).
	_fire_click(valley.get_placement_pick())
	assert_int(valley.get_commit_pipeline().get_blueprint_cells().size()).is_equal(0)

	# The identical click, after arming, commits.
	valley.get_build_editor_mode().arm_tool(ToolStateMachine.TOOL_ID_BLOCK)
	_fire_click(valley.get_placement_pick())
	assert_int(valley.get_commit_pipeline().get_blueprint_cells().size()).is_equal(1)


# ---------------------------------------------------------------------------
# AC-UNDO-IS-PLAN-ONLY-THROUGH-THE-HOSTED-STACK (Sub-scope C)
# ---------------------------------------------------------------------------

func test_ac_undo_is_plan_only_one_command_undo_clears_ownership_never_touches_built() -> void:
	var valley: Valley = _setup_click_fixture()
	var stack: UndoRedoStack = valley.get_undo_redo_stack()
	var registry: BuildProjectRegistry = valley.get_build_project_registry()

	# A whole wall drag/click = ONE command = ONE undo step (Core Rule 17) —
	# never wall_height separate steps.
	valley.get_build_editor_mode().arm_tool(ToolStateMachine.TOOL_ID_WALL)
	_fire_click(valley.get_placement_pick())
	var wall_height: int = valley.get_wall_tool().config.wall_height
	var wall_cells: Array[BlueprintCell] = valley.get_commit_pipeline().get_blueprint_cells()
	assert_int(wall_cells.size()).is_equal(wall_height)
	assert_int(stack.get_undo_stack_size()).is_equal(1)
	var wall_cell_addresses: Dictionary = {}
	for cell: BlueprintCell in wall_cells:
		wall_cell_addresses[cell.cell] = true

	stack.undo()
	for cell: BlueprintCell in wall_cells:
		assert_int(registry.project_at_cell(cell.cell)).is_equal(-1)

	# ADR-0016 §5: a cell driven to BUILT is NEVER mutated by undo. Drive a
	# second, fresh commit to real completion via the hosted
	# ConstructionTickLoop + the REAL global TimeTickSystem Autoload (mirrors
	# villager_need_seeding_boot_test.gd's own direct-Autoload-tick
	# precedent), then attempt to undo it.
	var camera_input: CameraInput = valley.get_camera_input()
	camera_input.set_target(camera_input.get_target() + Vector3(10.0, 0.0, 0.0))
	valley.get_build_editor_mode().arm_tool(ToolStateMachine.TOOL_ID_BLOCK)
	_fire_click(valley.get_placement_pick())
	assert_int(stack.get_undo_stack_size()).is_equal(1)
	# CommitPipeline's own tracking dictionary never drops a CANCELED entry
	# (undo() above marks the wall cells CANCELED, but they remain enumerable
	# by get_blueprint_cells() — this project's own established combined-view
	# convention) — so the fresh block commit's cell is whichever ISN'T one
	# of the wall's own addresses, never a bare index [0].
	var built_cell: Vector3i = Vector3i.ZERO
	for cell: BlueprintCell in valley.get_commit_pipeline().get_blueprint_cells():
		if not wall_cell_addresses.has(cell.cell):
			built_cell = cell.cell

	var built_project_id: int = registry.project_at_cell(built_cell)
	assert_bool(registry.release_project(built_project_id)).is_true()
	var queue: ConstructionJobQueue = valley.get_construction_job_queue()
	assert_bool(queue.claim_job(built_cell, 999)).is_true()
	var tick_loop_config: ConstructionTickLoopConfig = valley.get_construction_tick_loop().config
	for _i in range(tick_loop_config.base_build_ticks_block):
		TimeTickSystem.tick.emit()

	var built_cell_ref: BlueprintCell = valley.get_commit_pipeline().get_blueprint_cell_at(built_cell)
	assert_int(built_cell_ref.state).is_equal(BlueprintCell.MicroState.BUILT)

	stack.undo()

	assert_int(built_cell_ref.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_int(registry.project_at_cell(built_cell)).is_not_equal(-1)


## The shared BuildingSystemWriteTag proof (see class doc comment's own
## Story scene-007 paragraph): the tick loop's own batched completion write
## must register as self-originated, never invalidating the undo history it
## did not touch. Proven behaviourally: after the SAME real completion as
## above, a DIFFERENT, still-pending command's own cells must remain
## undoable (never silently marked invalidated by the tick loop's unrelated
## write to a different cell).
func test_ac_undo_shared_write_tag_tick_loop_completion_never_invalidates_an_unrelated_pending_command() -> void:
	var valley: Valley = _setup_click_fixture()
	var stack: UndoRedoStack = valley.get_undo_redo_stack()
	var registry: BuildProjectRegistry = valley.get_build_project_registry()
	var camera_input: CameraInput = valley.get_camera_input()

	# Command A: committed, released, driven to completion for real.
	valley.get_build_editor_mode().arm_tool(ToolStateMachine.TOOL_ID_BLOCK)
	_fire_click(valley.get_placement_pick())
	var cell_a: Vector3i = valley.get_commit_pipeline().get_blueprint_cells()[0].cell
	var project_a_id: int = registry.project_at_cell(cell_a)
	registry.release_project(project_a_id)
	var queue: ConstructionJobQueue = valley.get_construction_job_queue()
	queue.claim_job(cell_a, 111)
	var tick_loop_config: ConstructionTickLoopConfig = valley.get_construction_tick_loop().config
	for _i in range(tick_loop_config.base_build_ticks_block):
		TimeTickSystem.tick.emit()
	assert_int(valley.get_commit_pipeline().get_blueprint_cell_at(cell_a).state).is_equal(
		BlueprintCell.MicroState.BUILT
	)

	# Command B: a SEPARATE, still-pending (Draft) commit, far from A.
	camera_input.set_target(camera_input.get_target() + Vector3(20.0, 0.0, 0.0))
	valley.get_build_editor_mode().arm_tool(ToolStateMachine.TOOL_ID_BLOCK)
	_fire_click(valley.get_placement_pick())
	var found_cell_b: bool = false
	var cell_b: Vector3i = Vector3i.ZERO
	for cell: BlueprintCell in valley.get_commit_pipeline().get_blueprint_cells():
		if cell.cell != cell_a:
			cell_b = cell.cell
			found_cell_b = true
	assert_bool(found_cell_b).is_true()
	assert_bool(valley.get_undo_redo_stack().is_cell_invalidated(cell_b)).is_false()

	# Undoing command B must still work — its cell was never touched by A's
	# completion write, so it is never in the invalidated set. Two commands
	# are on the stack (A's own, never itself undone here, plus B's) — undo()
	# pops the MOST RECENT (B, Core Rule 17's own LIFO order).
	assert_int(stack.get_undo_stack_size()).is_equal(2)
	stack.undo()
	assert_int(registry.project_at_cell(cell_b)).is_equal(-1)
	assert_int(registry.project_at_cell(cell_a)).is_not_equal(-1)


# ---------------------------------------------------------------------------
# AC-HOSTING-IS-NOT-DI
# ---------------------------------------------------------------------------

func test_ac_hosting_is_not_di_only_two_setup_call_sites_in_src() -> void:
	var offenders: Array[String] = []
	_find_setup_call_sites("res://src", offenders)
	# Exactly two sanctioned call sites (CONTRACTS.md §1 / ADR-0005):
	# GameWorld._setup_injected_tier()'s sweep, and
	# Valley.spawn_starting_roster()'s own already-sanctioned per-villager
	# exception. No new exception is introduced by this story.
	assert_int(offenders.size()).is_equal(2)
	for offender: String in offenders:
		var is_sanctioned: bool = (
			offender.ends_with("scene_world_management/game_world.gd")
			or offender.ends_with("scene_world_management/valley.gd")
		)
		assert_bool(is_sanctioned).is_true()


# ---------------------------------------------------------------------------
# Grep-guard helpers (recursive — src/ has many subdirectories, unlike the
# flat directories world_root_valley_attach_test.gd's own non-recursive
# _read_all_gd_source helper was built for)
# ---------------------------------------------------------------------------

## Recursively scans every `.gd` file under [param dir_path] for an
## `arm_tool(` CALL SITE (`something.arm_tool(`, a receiver + dot) --
## deliberately distinct from `func arm_tool(` (a bare match on `arm_tool(`
## alone would also catch [ToolStateMachine]'s own DEFINITION of the method,
## which is not a call). Strips full-line `#`/`##` doc comments first (this
## codebase's own established false-positive guard — see
## `world_root_valley_attach_test.gd`'s identical rationale). Excludes
## `build_editor_mode.gd` itself, the one sanctioned caller.
func _find_offending_arm_tool_calls(dir_path: String, offenders: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full_path: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_find_offending_arm_tool_calls(full_path, offenders)
		elif entry.ends_with(".gd") and not full_path.ends_with("build_editor_mode.gd"):
			var text: String = FileAccess.get_file_as_string(full_path)
			var cleaned_lines: Array[String] = []
			for line: String in text.split("\n"):
				if not line.strip_edges().begins_with("#"):
					cleaned_lines.append(line)
			if "\n".join(cleaned_lines).contains(".arm_tool("):
				offenders.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()


## Recursively scans every `.gd` file under [param dir_path] for a real
## `x.setup()` CALL-SITE statement — distinguished from a `func setup()`
## DEFINITION (never matches, no leading dot) and from a doc-comment/assert-
## string MENTION (never matches a whole-line-after-strip regex) via a strict
## "the entire stripped line is exactly `something.setup()`" pattern, mirroring
## `world_root_valley_attach_test.gd`'s own regex-based non-textual-mention
## precedent (`current_scene\s*=(?!=)`).
func _find_setup_call_sites(dir_path: String, offenders: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	var setup_call_regex := RegEx.new()
	var compile_error: int = setup_call_regex.compile("^[\\w.]+\\.setup\\(\\)$")
	assert(compile_error == OK, "Failed to compile setup() call-site regex")
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full_path: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_find_setup_call_sites(full_path, offenders)
		elif entry.ends_with(".gd"):
			var text: String = FileAccess.get_file_as_string(full_path)
			for line: String in text.split("\n"):
				var stripped: String = line.strip_edges()
				if stripped.begins_with("#"):
					continue
				if setup_call_regex.search(stripped) != null:
					offenders.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
