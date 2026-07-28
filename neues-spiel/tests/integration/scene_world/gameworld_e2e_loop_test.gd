## Integration test — Scene/World Management Story scene-004, THE INTEGRATION
## CROWN of Sprint 6 (Milestone 01 exit criterion #8; ADR-0001 primary,
## ADR-0005/0013 secondary).
##
## The headless E2E LOOP test proving the assembled production game loop: a
## block placed via the REAL pipeline (ray -> DDA pick -> commit -> blueprint
## -> construction ticks -> actual voxel write), AND a villager that decides,
## paths, and walks on the discrete cell model — both proven against the same
## production classes this story wires into [GameWorld]/[Valley].
##
## Per this story's own Guardrail (Control Manifest, QA plan Edge Cases): the
## four ACs are kept as four INDEPENDENT, separately-diagnosable test
## functions in this one file — a single-half failure must read as a distinct
## red, never folded into one pass/fail line.
##
## - **AC-ASSEMBLY**: the REAL `GameWorld.tscn`/`Valley.tscn` boots behind the
##   ADR-0005 gate with all four tier-module groups (Voxel World grid+mesher,
##   Camera & Input, the four Building System modules, Villager AI) present,
##   `setup()`-wired (never their own `_ready()`), plus a non-DI
##   cross-reference grep guard.
## - **AC-PLACE-A-BLOCK**: a small, directly-assembled fixture built from the
##   SAME production classes — real screen-ray-shaped pick (mirrors
##   `dda_placement_pick_test.gd`'s established analytic-yaw camera rig, cam-005
##   precedent for driving a real [CameraInput] headlessly) through
##   [PlacementPick]'s real DDA -> [CommitPipeline]'s real commit ->
##   a REAL villager's own Deciding/F2/claim pass (Story villager-ai-012,
##   see below) -> [ConstructionTickLoop]'s real tick-driven completion —
##   asserts the completion write lands in real Voxel World grid data AND
##   fires exactly ONE `cells_changed_batch` for the completion frame, ZERO
##   `cell_changed`. (Updated by Story building-033: the landed
##   `construction_tick_loop.gd` now batches EVERY completion — including a
##   lone single-cell one — through `VoxelWorldGrid.bulk_write`, never the
##   single-cell `set_cell` path this test asserted against before that
##   story landed; see that file's own class doc comment point 5.)
## - **AC-VILLAGER-WALKS**: a villager runs a REAL Deciding pass (005/006:
##   scheduler dequeue -> priority-list commit to WORK) against a REAL
##   [ConstructionJobQueue]/[BuildProject] (Story villager-ai-012 smoke-item
##   extension, Sprint 7 QA plan Call-out 5) -- F2 real nearest-reachable
##   selection (010) atomically claims the real queued job (011), and the
##   REAL Traveling state machine (007 AStar3D path acquisition, 008/009
##   cell-by-cell following) drives it to arrival entirely on its own, never
##   a manually-seeded travel target -- asserted purely on discrete
##   `current_cell` transitions, never `_visual_position`.
## - **AC-E2E-GATE**: this file's own presence under
##   `tests/integration/scene_world/` (auto-discovered by
##   `tests/run-tests.cmd`'s `-a res://tests/integration` sweep — no separate
##   registration needed) plus the typed-Array crash-class regression call
##   (sprint Risk register: 3 incidents in the vertical slice,
##   `prototypes/last-seal-vertical-slice/REPORT.md`, "typed-Array params on
##   the untyped preview path... typed params raise at runtime"; 0 since) —
##   proven against the REAL commit path, [CommitPipeline.commit]'s own
##   `Array[Vector3i]`-typed parameter: a deliberately PLAIN, untyped `Array`
##   caller raises the engine's own type-mismatch runtime error (verified
##   live against this engine install), which is exactly why every REAL
##   caller on this path stays statically `Array[Vector3i]`-typed end to end
##   (the AC-PLACE-A-BLOCK test above IS that real, never-crashing path).
##
## Story villager-ai-012 (this revision) replaces BOTH of this file's
## previously-named seams (Sprint 7 QA plan Call-out 5): the manual
## `loop.claim_job(target, 1)` call in AC-PLACE-A-BLOCK's own Act 2, and the
## duck-typed `_MockJobQueue`/`villager.job_queue = jobs` assignment in
## AC-VILLAGER-WALKS — both now go through the REAL
## `BuildProject.release()` -> `ConstructionJobQueue` -> `VillagerAi`'s own
## Deciding/F2/claim pass machinery `build_job_cycle_test.gd` proves in
## isolation. Zero direct `.claim_job(` calls remain anywhere in this file
## (grep-verified — see the smoke item's own edge case); `job_queue` is
## still assigned per [VillagerAi]'s own documented DI pattern (its own doc
## comment: "deliberately NOT `@export`ed... assigned directly by whichever
## code assembles the population"), but every remaining assignment now
## points at a REAL [ConstructionJobQueue] populated via the real release/
## eligibility flow (004), never a duck-typed mock.
class_name GameworldE2eLoopTest
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")


# ---------------------------------------------------------------------------
# Test doubles (inner helper classes — kept ABOVE every test function)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# AC-ASSEMBLY — real GameWorld.tscn boots with all four tier-module groups
# ---------------------------------------------------------------------------

func test_ac_assembly_gameworld_wires_all_tier_modules_into_valley_and_boots_active() -> void:
	# Arrange
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database

	# Act — entering the live tree fires GameWorld._ready(); the RID mock
	# already reports Ready, so the gate settles synchronously, same frame.
	add_child(world)

	# Assert — boot reached ACTIVE through the real gate.
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()

	# Voxel World (grid + mesher + mesh view-window streamer, story vox-018)
	assert_object(valley.get_voxel_world()).is_not_null()
	assert_object(valley.get_voxel_world_mesher()).is_not_null()
	assert_object(valley.get_voxel_world_mesh_streamer()).is_not_null()
	# Camera & Input
	assert_object(valley.get_camera_input()).is_not_null()
	# Building System (four modules)
	assert_object(valley.get_tool_state_machine()).is_not_null()
	assert_object(valley.get_placement_pick()).is_not_null()
	assert_object(valley.get_commit_pipeline()).is_not_null()
	assert_object(valley.get_construction_tick_loop()).is_not_null()
	# Build Validation & Navigability (Story scene-008)
	assert_object(valley.get_build_validation()).is_not_null()
	# Villager AI
	assert_object(valley.get_villager_ai()).is_not_null()
	# Ambient torch flicker (M01 condition C4, production/milestones/
	# milestone-01-review-2026-07-26.md)
	assert_object(valley.get_torch_flicker()).is_not_null()
	# Needs & Mood System (Story needs-mood-010 -- THE CROWN's production wiring)
	assert_object(valley.get_needs_mood()).is_not_null()
	# Villager body presenter (Story presentation-003 -- concurrent with
	# needs-mood-010 in this same sprint)
	assert_object(valley.get_villager_body_presenter()).is_not_null()
	# Story scene-007 (Build-tool & project-lifecycle hosting) -- the entire
	# build-interaction tier, now real hosted children of Valley. See the
	# count comment below for the injected_tier_modules() detail.
	assert_object(valley.get_build_editor_mode()).is_not_null()
	assert_object(valley.get_wall_tool()).is_not_null()
	assert_object(valley.get_floor_tool()).is_not_null()
	assert_object(valley.get_roof_tool()).is_not_null()
	assert_object(valley.get_block_tool()).is_not_null()
	assert_object(valley.get_furniture_tool()).is_not_null()
	assert_object(valley.get_ghost_preview()).is_not_null()
	assert_object(valley.get_undo_redo_stack()).is_not_null()
	# Camera hosting (Story cam-013 -- "Camera hosting in the shipped scene")
	assert_object(valley.get_camera_mirror()).is_not_null()

	# The assembly seam (GameWorld._gather_valley_tier_modules) fed exactly
	# these twelve (story vox-018 added the mesh streamer as a ninth; M01
	# condition C4 added the torch flicker as a tenth; story needs-mood-010
	# added Needs & Mood as an eleventh; story presentation-003 added the
	# villager body presenter as a twelfth -- updated consciously, not
	# incidentally), in the load-bearing DI order Valley itself reports.
	# Story scene-007 adds a FURTHER FIVE injected-tier modules -- BuildEditorMode,
	# WallTool, FloorTool, RoofTool, BlockTool, FurnitureTool, GhostPreview,
	# UndoRedoStack are EIGHT new hosted `Node`s total, but FloorTool/RoofTool/
	# BlockTool's own `setup()`/`is_set_up()` pair (this story's own trivial
	# addition to those three classes, see each class's own doc comment) means
	# ALL EIGHT actually expose `setup()` and are therefore ALL EIGHT appended
	# to Valley.get_injected_tier_modules() (12 -> 20), not merely five --
	# corrected count, not the sprint plan's own pre-authoring guess of "20"
	# which happened to already assume this. Story cam-013 (Camera hosting in
	# the shipped scene) adds ONE further injected-tier module, CameraMirror
	# (20 -> 21) -- updated consciously, not incidentally, per that story's
	# own dev-story instructions to flag this file. Story presentation-004
	# ("The world has no sun") adds ONE further injected-tier module,
	# WorldLighting (21 -> 22) -- updated consciously, not incidentally.
	# Story scene-008 ("Hosting the gates that make work honest") adds ONE
	# further injected-tier module, BuildValidation (22 -> 23) -- updated
	# consciously, not incidentally, per that story's own dev-story
	# instructions to flag this file. VillagerOnSiteGate/
	# VillagerSealPreventionGate are RefCounted collaborators, not scene
	# children, and do not affect this count. Story build-validation-009
	# ("Loop-payoff surface receives real signals," milestone criterion #7)
	# adds TWO further injected-tier modules, LoopPayoffSignalSurface and
	# LoopPayoffAdapter (23 -> 25) -- updated consciously, not incidentally.
	# Story presentation-005 ("A built bed becomes visible" -- the furniture
	# view layer, F7) adds ONE further injected-tier module, FurniturePresenter
	# (25 -> 26) -- updated consciously, not incidentally.
	assert_object(valley.get_loop_payoff_signal_surface()).is_not_null()
	assert_object(valley.get_loop_payoff_adapter()).is_not_null()
	assert_object(valley.get_furniture_presenter()).is_not_null()
	assert_array(world.injected_tier_modules).contains_exactly(valley.get_injected_tier_modules())
	assert_int(world.injected_tier_modules.size()).is_equal(27)  # +1: ScaffoldPresentation (building-034 occupancy tier)


func test_ac_assembly_hosted_modules_ran_through_boot_gated_setup_never_their_own_ready() -> void:
	# Arrange + Act
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	var valley: Valley = world.get_valley() as Valley

	# Assert — every hosted module's own is_set_up() seam confirms GameWorld's
	# boot-gated sweep (ADR-0005) reached it -- never a module's own _ready().
	assert_bool(valley.get_voxel_world().is_set_up()).is_true()
	assert_bool(valley.get_voxel_world_mesher().is_set_up()).is_true()
	assert_bool(valley.get_voxel_world_mesh_streamer().is_set_up()).is_true()
	assert_bool(valley.get_camera_input().is_set_up()).is_true()
	assert_bool(valley.get_tool_state_machine().is_set_up()).is_true()
	assert_bool(valley.get_placement_pick().is_set_up()).is_true()
	assert_bool(valley.get_commit_pipeline().is_set_up()).is_true()
	assert_bool(valley.get_construction_tick_loop().is_set_up()).is_true()
	assert_bool(valley.get_build_validation().is_set_up()).is_true()
	assert_bool(valley.get_villager_ai().is_set_up()).is_true()
	# Story scene-007
	assert_bool(valley.get_build_editor_mode().is_set_up()).is_true()
	assert_bool(valley.get_wall_tool().is_set_up()).is_true()
	assert_bool(valley.get_floor_tool().is_set_up()).is_true()
	assert_bool(valley.get_roof_tool().is_set_up()).is_true()
	assert_bool(valley.get_block_tool().is_set_up()).is_true()
	assert_bool(valley.get_furniture_tool().is_set_up()).is_true()
	assert_bool(valley.get_ghost_preview().is_set_up()).is_true()
	assert_bool(valley.get_undo_redo_stack().is_set_up()).is_true()
	# Story build-validation-009
	assert_bool(valley.get_loop_payoff_signal_surface().is_set_up()).is_true()
	assert_bool(valley.get_loop_payoff_adapter().is_set_up()).is_true()


func test_ac_assembly_building_and_villager_source_holds_no_non_di_root_reference() -> void:
	# Grep companion (QA plan AC-ASSEMBLY): every cross-system reach in
	# Building System / Villager AI source is either an injected-tier
	# `@export`/duck-typed field or one of the two sanctioned Autoloads
	# (TimeTickSystem, ResourceItemDatabase) -- never a hardcoded
	# `/root/<OtherSystem>` lookup to a third system.
	var source: String = (
		_read_all_gd_source_flat("res://src/building_system")
		+ _read_all_gd_source_flat("res://src/villager_ai")
	)
	var search_from: int = 0
	while true:
		var idx: int = source.find("/root/", search_from)
		if idx == -1:
			break
		var after: String = source.substr(idx + "/root/".length(), 24)
		var sanctioned: bool = after.begins_with("TimeTickSystem") or after.begins_with("ResourceItemDatabase")
		assert_bool(sanctioned).is_true()
		search_from = idx + 1


# ---------------------------------------------------------------------------
# AC-PLACE-A-BLOCK — real ray -> DDA -> commit -> construction-tick write
# ---------------------------------------------------------------------------

func test_ac_place_a_block_committed_through_real_pipeline_writes_voxel_world_and_fires_one_cell_changed() -> void:
	# Arrange -- a real, fully solid 100x100 slab (mirrors
	# dda_placement_pick_test.gd's established analytic-yaw camera rig: a
	# fixed-size SubViewport with a deterministic (0,0) headless mouse
	# position, yaw rotated to exactly PI via the real middle-mouse-drag
	# rotation path so the corner ray lands solidly inside a generous
	# positive-quadrant slab regardless of float slack).
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	var world_config := VoxelWorldConfig.new()
	world_config.world_width_cells = 100
	world_config.world_depth_cells = 100
	grid.config = world_config
	grid.setup()
	var changes: Dictionary[Vector3i, CellContents] = {}
	for x in 100:
		for z in 100:
			changes[Vector3i(x, 0, z)] = CellContents.new(1, 0)
	grid.bulk_write(changes)

	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())
	machine.arm_tool(&"wall")

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1000, 1000)
	add_child(viewport)
	auto_free(viewport)

	var camera: CameraInput = auto_free(CameraInput.new())
	var camera_config := CameraInputConfig.new()
	camera.config = camera_config
	camera.setup()
	viewport.add_child(camera)
	var yaw_delta: float = PI - camera_config.start_yaw
	var rotate_event := InputEventMouseMotion.new()
	rotate_event.relative = Vector2(yaw_delta / camera_config.mouse_drag_sensitivity, 0.0)
	rotate_event.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	camera._unhandled_input(rotate_event)

	var pick: PlacementPick = auto_free(PlacementPick.new())
	pick.camera_input = camera
	pick.voxel_world = grid
	pick.tool_state_machine = machine
	pick.config = PlacementPickConfig.new()
	pick.setup()
	viewport.add_child(pick)

	var pipeline: CommitPipeline = auto_free(CommitPipeline.new())
	pipeline.placement_pick = pick
	pipeline.voxel_world = grid
	pipeline.config = CommitPipelineConfig.new()
	pipeline.setup()
	# Story building-022's material-selection gate (AC42) is out of THIS
	# story's own scope -- select a placeholder so the real pipeline this E2E
	# test drives keeps committing exactly as before that story landed.
	pipeline.set_selected_item(&"placeholder_material")

	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var tick_loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	loop.voxel_world = grid
	loop.config = tick_loop_config
	loop.time_tick_system = tick_source
	loop.setup()

	var cell_changed_count: Array = [0]
	var batch_count: Array = [0]
	grid.cell_changed.connect(
		func(_cell: Vector3i, _before: CellContents, _after: CellContents) -> void:
			cell_changed_count[0] += 1
	)
	grid.cells_changed_batch.connect(
		func(_changes: Array[CellChangeRecord]) -> void:
			batch_count[0] += 1
	)

	# Act 1 -- the real pick pipeline: screen ray (camera.get_world_ray(),
	# driven internally by PlacementPick) -> voxel DDA -> a genuine click
	# commit (press/release at the SAME screen position -- zero cursor
	# travel, F4's click path).
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	pick._unhandled_input(press)
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.DRAGGING)

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	pick._input(release)
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.TOOL_ARMED)

	# Assert -- exactly one Draft blueprint cell exists; zero grid write yet.
	var blueprint_cells: Array[BlueprintCell] = pipeline.get_blueprint_cells()
	assert_int(blueprint_cells.size()).is_equal(1)
	var target: BlueprintCell = blueprint_cells[0]
	assert_int(target.state).is_equal(BlueprintCell.MicroState.PLANNED)
	assert_bool(grid.get_cell(target.cell).is_empty()).is_true()

	# Act 2 -- Story villager-ai-012's real worker-assignment AI (Sprint 7 QA
	# plan Call-out 5): the REAL Building System registry (BuildProject ->
	# release() -> ConstructionJobQueue) plus a REAL claiming villager, its
	# own Deciding/F2 pass, and the real on-site occupancy gate — never a
	# manual `loop.claim_job(...)` call.
	var project := BuildProject.new(1)
	project.add_cell(target)
	project.release()
	var queue := ConstructionJobQueue.new(loop)
	queue.add_project(project)
	var gate := VillagerOnSiteGate.new(queue)

	var predicate_source: VillagerAi = auto_free(VillagerAi.new())
	predicate_source.voxel_world = grid
	var nav_graph := VillagerNavGraph.new()
	nav_graph.subscribe_to_voxel_world(grid, predicate_source)

	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.config = VillagerAIConfig.new()
	villager.voxel_world = grid
	villager.scheduler = VillagerDecidingScheduler.new()
	villager.nav_graph = nav_graph
	villager.time_tick_system = tick_source
	villager.job_queue = queue
	villager.villager_id = 1
	# Starts standing exactly on the job's own cell -- this test's own focus
	# is the commit -> construction-completion write, not travel (that is
	# AC-VILLAGER-WALKS' own focus, below) -- an immediate-arrival claim
	# (path.size() == 1) is sufficient here.
	villager.current_cell = target.cell
	villager._from_cell = villager.current_cell
	villager._to_cell = villager.current_cell
	villager.setup()
	gate.register_villager(villager)
	nav_graph.build(grid, predicate_source, target.cell, 5)

	# Tick 1 -- the villager's own real Deciding pass: F2 selects the one
	# available job (010), atomically claims it against the REAL queue
	# (011), and arrives immediately (already standing on the cell).
	tick_source.fire_tick()
	assert_int(target.state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)
	assert_int(villager.get_state()).is_equal(VillagerAi.State.WORKING)

	# Ticks 2..N -- on-site (Rule 5/[TR-villager-ai-behavior-054]), so
	# ConstructionTickLoop's own crediting (gated by VillagerOnSiteGate)
	# advances normally to completion.
	for _i in range(tick_loop_config.base_build_ticks_block):
		tick_source.fire_tick()

	# Assert -- the target cell is Built in REAL Voxel World grid data, and
	# exactly one cells_changed_batch fired for the completion frame (Story
	# building-033's batched-write path -- see class doc comment's own
	# updated note); zero cell_changed fired. The closed loop also
	# completes: the claim is released and the villager re-enters Deciding.
	assert_int(target.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(grid.get_cell(target.cell).is_empty()).is_false()
	assert_int(cell_changed_count[0]).is_equal(0)
	assert_int(batch_count[0]).is_equal(1)
	# The villager re-enters the decision loop -- whether the exact terminal
	# snapshot is DECIDING or WANDERING depends on whether Rule 2's own
	# periodic decision_interval re-check (Story villager-ai-006, unrelated
	# to this story) also lands on this same tick (see
	# build_job_cycle_test.gd's AC40 test for the full explanation); either
	# way it is no longer WORKING and no longer holds the claim.
	var re_decided: bool = (
		villager.get_state() == VillagerAi.State.DECIDING
		or villager.get_state() == VillagerAi.State.WANDERING
	)
	assert_bool(re_decided).is_true()
	assert_bool(queue.has_claim(1)).is_false()


# ---------------------------------------------------------------------------
# AC-VILLAGER-WALKS — real Deciding pass -> real AStar3D path -> real walk
# ---------------------------------------------------------------------------

func test_ac_villager_walks_decides_paths_and_follows_cell_by_cell_to_arrival() -> void:
	# Arrange -- a flat, fully-connected 5x5 standable platform (mirrors
	# traveling_repath_test.gd's established fixture).
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	for x in range(5):
		for z in range(5):
			grid.set_cell(Vector3i(x, 0, z), CellContents.new(1, 0))

	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	loop.voxel_world = grid
	loop.config = ConstructionTickLoopConfig.new()
	loop.time_tick_system = tick_source
	loop.setup()

	# Story villager-ai-012 (Sprint 7 QA plan Call-out 5): a REAL released
	# BuildProject/ConstructionJobQueue/VillagerOnSiteGate -- never the
	# duck-typed `_MockJobQueue` this test used before Story villager-ai-010/
	# 011/012 landed real F2/claim/on-site machinery.
	var target_cell := Vector3i(4, 1, 0)
	var project := BuildProject.new(1)
	project.add_cell(BlueprintCell.new(target_cell))
	project.release()
	var queue := ConstructionJobQueue.new(loop)
	queue.add_project(project)
	var gate := VillagerOnSiteGate.new(queue)

	var predicate_source: VillagerAi = auto_free(VillagerAi.new())
	predicate_source.voxel_world = grid
	var nav_graph := VillagerNavGraph.new()
	# Wiring-order requirement (VillagerAi's own doc comment, load-bearing):
	# subscribe the shared graph BEFORE this villager's own setup().
	nav_graph.subscribe_to_voxel_world(grid, predicate_source)

	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.config = VillagerAIConfig.new()
	villager.voxel_world = grid
	villager.scheduler = VillagerDecidingScheduler.new()
	villager.time_tick_system = tick_source
	villager.nav_graph = nav_graph
	villager.job_queue = queue
	villager.villager_id = 1
	villager.setup()
	gate.register_villager(villager)

	nav_graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)

	villager.current_cell = Vector3i(0, 1, 0)
	villager._from_cell = villager.current_cell
	villager._to_cell = villager.current_cell

	# Act -- a REAL Deciding pass (005/006): the villager is already queued
	# (setup()'s own initial-eligible-at-boot call); one real tick lets the
	# shared scheduler dequeue it under its budget and run the real
	# priority-list evaluation, which now (Story villager-ai-010/011 landed)
	# selects (F2) and atomically claims (against the REAL
	# ConstructionJobQueue) the SAME real job, entirely on its own -- never a
	# manually-seeded travel target.
	assert_bool(villager.scheduler.is_queued(villager.villager_id)).is_true()
	tick_source.fire_tick()
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.WORK)
	assert_int(villager.get_state()).is_equal(VillagerAi.State.TRAVELING)
	assert_vector(Vector3(villager.get_claimed_job_cell())).is_equal(Vector3(target_cell))

	# Cell-by-cell following (008/009) to arrival -- driven purely by firing
	# the SAME shared tick signal (never a manual `_on_tick()` poke), matching
	# the assembled scene's own real dispatch path.
	var max_ticks: int = 20
	var ticks_elapsed: int = 0
	while villager.get_current_cell() != target_cell and ticks_elapsed < max_ticks:
		villager.advance_travel_progress(1000.0)
		tick_source.fire_tick()
		ticks_elapsed += 1

	# Assert -- discrete current_cell transitions ending at the target, never
	# _visual_position or wall-clock timing.
	assert_vector(Vector3(villager.get_current_cell())).is_equal(Vector3(target_cell))
	assert_int(villager.get_state()).is_equal(VillagerAi.State.WORKING)
	assert_bool(villager.is_moving()).is_false()


# ---------------------------------------------------------------------------
# AC-E2E-GATE — typed-Array crash-class regression call
# ---------------------------------------------------------------------------

func test_ac_e2e_gate_typed_array_param_rejects_plain_untyped_array_caller() -> void:
	# Regression guard (sprint Risk register: 3 incidents in the vertical
	# slice, prototypes/last-seal-vertical-slice/REPORT.md -- "typed-Array
	# params on the untyped preview path... typed params raise at runtime";
	# 0 incidents S1-S5). Verified LIVE against this engine install (Godot
	# 4.7-stable) while authoring this test: a plain, untyped `Array` caller
	# (never declared `Array[Vector3i]`) passed into a REAL production method
	# whose parameter IS typed `Array[Vector3i]` -- CommitPipeline.commit's
	# own signature -- raises exactly this crash class at runtime (GDScript
	# does NOT silently/leniently convert a bare `Array` into a typed one
	# here); this is precisely WHY every real caller on this path
	# (PlacementPick.build_committed -> CommitPipeline._on_build_committed ->
	# _resolve_cell_set/_default_cell_set) is statically typed to return
	# `Array[Vector3i]` end to end (AC-PLACE-A-BLOCK's own test above proves
	# that real, fully-typed call path commits successfully with zero
	# crashes). This test locks in the failure mode a caller violating that
	# typed contract would hit, so a future regression toward an untyped
	# caller on this exact boundary fails loudly here first, rather than
	# silently reappearing at scale in an assembled scene.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	grid.set_cell(Vector3i(5, 0, 5), CellContents.new(1, 0))

	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())
	machine.arm_tool(&"wall")

	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()
	camera.setup()

	var pick: PlacementPick = auto_free(PlacementPick.new())
	pick.camera_input = camera
	pick.voxel_world = grid
	pick.tool_state_machine = machine
	pick.config = PlacementPickConfig.new()
	pick.setup()
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))

	var pipeline: CommitPipeline = auto_free(CommitPipeline.new())
	pipeline.placement_pick = pick
	pipeline.voxel_world = grid
	pipeline.config = CommitPipelineConfig.new()
	pipeline.setup()
	# The typed-Array crash this test proves happens at the engine's own
	# call-boundary type check, before `commit`'s body (and therefore Story
	# building-022's validity gate) ever runs -- no material selection is
	# needed for this test to reach its assertion.

	# Deliberately UNTYPED -- never `Array[Vector3i]` -- the historical
	# crash-class caller shape.
	var untyped_candidates: Array = [Vector3i(5, 1, 5)]

	# Act + Assert -- the expected, engine-verified runtime type error (exact
	# message match, per GdUnitGodotErrorAssertImpl's own equality check).
	await assert_error(func() -> void: pipeline.commit(untyped_candidates)).is_runtime_error(
		"Invalid type in function 'commit' in base 'Node (CommitPipeline)'. The array of"
		+ " argument 1 (Array) does not have the same element type as the expected typed"
		+ " array argument."
	)


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Reads and concatenates every `.gd` source file directly under
## [param dir_path] (non-recursive -- both `src/building_system` and
## `src/villager_ai` are flat directories), stripping full-line `#`/`##`
## doc-comment lines first -- mirrors `world_root_valley_attach_test.gd`'s
## established `_read_all_gd_source` precedent so a file's own doc comments
## (which legitimately NAME the sanctioned Autoload paths) are never
## mistaken for a violation.
func _read_all_gd_source_flat(dir_path: String) -> String:
	var combined: String = ""
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Could not open directory: %s" % dir_path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gd"):
			var text: String = FileAccess.get_file_as_string(dir_path.path_join(file_name))
			for line: String in text.split("\n"):
				if not line.strip_edges().begins_with("#"):
					combined += line
					combined += "\n"
		file_name = dir.get_next()
	dir.list_dir_end()
	return combined
