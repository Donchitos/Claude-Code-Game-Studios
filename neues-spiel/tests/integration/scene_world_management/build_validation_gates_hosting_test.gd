## Integration test -- Scene/World Management Story scene-008 ("Hosting the
## gates that make work honest"; ADR-0001 primary, ADR-0005/0016 secondary).
##
## Found by `tools/payoff_loop_demo.gd` -- a capture tool that drove the real
## shipped build chain end to end and photographed each stage: a 30-cell room
## was drafted, released, and a real villager built 20 cells of it while
## standing well away from the house. Grep-confirmed independently: three
## fully-built, fully-tested classes ([BuildValidation], [VillagerOnSiteGate],
## [VillagerSealPreventionGate]) the running game never constructed. Both
## gates default PERMISSIVELY when unwired, so [ConstructionTickLoop] credited
## a claimed job on a timer regardless of whether the claiming villager had
## physically arrived; [Valley]'s own `_wire_build_project_lifecycle()`
## constructed [FurnitureBedProvider] with a `null` validation dependency, so
## [method FurnitureBedProvider.is_bed_sheltered] structurally returned
## `false` for every bed in the shipped game.
##
## This story changes NO rule inside [BuildValidation] or either gate -- all
## three are already built and tested elsewhere (`build-validation` epic
## stories 001-008; `villager-ai-behavior` epic stories 012/016). This suite
## proves the running game now CONSTRUCTS and WIRES them, split exactly along
## the story's own QA Test Cases boundary:
## - AC1/AC2/AC5 ("the wiring exists"): presence/identity, against the REAL
##   booted scene.
## - AC3 (Anti-Vacuity Lever #1, "absent workers earn nothing"): behavioral,
##   against the REAL hosted [ConstructionJobQueue]/[ConstructionTickLoop]/
##   [VillagerOnSiteGate] instances Valley wires -- driven by a fully
##   isolated, deterministic fixture (own grid/nav_graph/villager/mock tick
##   source) so this test's own claim/travel arithmetic never depends on the
##   real world's procedurally-generated terrain or races the real,
##   ALREADY-hosted default villager (which reacts only to the REAL
##   `TimeTickSystem` Autoload signal -- never fired by this test).
## - AC4 (Anti-Vacuity Lever #2, "shelter reaches the game"): behavioral,
##   against the REAL booted scene, building a real enclosed room around a
##   real bed via the hosted [VoxelWorldGrid]/[FurnitureRegistry] -- exactly
##   as the story's own Anti-Vacuity Lever text requires ("boot the real
##   scene").
class_name BuildValidationGatesHostingTest
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")


# ---------------------------------------------------------------------------
# Shared fixture helper
# ---------------------------------------------------------------------------

func _boot_real_game_world() -> GameWorld:
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	return world


# ---------------------------------------------------------------------------
# AC1 / AC2 / AC5 -- the wiring exists (presence, against the real scene)
# ---------------------------------------------------------------------------

func test_ac1_ac2_ac5_all_three_constructed_exactly_once_and_bed_provider_wired() -> void:
	var world: GameWorld = _boot_real_game_world()
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()

	# AC1 -- BuildValidation is constructed, hosted, and set up.
	var build_validation: BuildValidation = valley.get_build_validation()
	assert_object(build_validation).is_not_null()
	assert_bool(build_validation.is_set_up()).is_true()

	# AC1 -- FurnitureBedProvider receives it instead of null.
	var bed_provider: FurnitureBedProvider = valley.get_furniture_bed_provider()
	assert_object(bed_provider).is_not_null()
	assert_object(bed_provider.build_validation).is_not_null()
	assert_object(bed_provider.build_validation).is_same(build_validation)

	# AC2 -- both gates are constructed and hosted.
	var onsite_gate: VillagerOnSiteGate = valley.get_villager_onsite_gate()
	var seal_gate: VillagerSealPreventionGate = valley.get_villager_seal_prevention_gate()
	assert_object(onsite_gate).is_not_null()
	assert_object(seal_gate).is_not_null()

	# AC5 -- BuildValidation appears exactly once in the injected-tier sweep
	# (constructed exactly once, per Valley's own single _ready() pass).
	var occurrences: int = 0
	for module: Node in valley.get_injected_tier_modules():
		if module == build_validation:
			occurrences += 1
	assert_int(occurrences).is_equal(1)


func test_ac5_grep_guard_each_class_is_constructed_exactly_once_in_src_and_only_in_valley_gd() -> void:
	# The story's own "found by grep" framing, now proving the fix the same
	# way the bug itself was found: today's shipped source reads
	# `VillagerOnSiteGate.new( in src/: 0` / `VillagerSealPreventionGate.new(
	# in src/: 0` -- after this story, each reads exactly 1 in src/, in
	# valley.gd. Both are `RefCounted` collaborators Valley constructs
	# directly, mirroring `_construction_job_queue`'s own established
	# `ConstructionJobQueue.new(...)` construction-site precedent.
	for needle: String in ["VillagerOnSiteGate.new(", "VillagerSealPreventionGate.new("]:
		var hits: Array[String] = []
		_find_call_sites("res://src", needle, hits)
		assert_int(hits.size()).is_equal(1)
		assert_str(hits[0]).contains("scene_world_management/valley.gd")

	# BuildValidation is a scene-hosted `Node` -- like every other hosted
	# injected-tier module on Valley (VoxelWorldGrid, VillagerAi, etc.), it is
	# never constructed via `BuildValidation.new(` anywhere (grep-verified:
	# zero occurrences in `src/` today, correctly, since Godot's own scene
	# instantiation constructs it from `Valley.tscn`, not GDScript). Its own
	# "constructed exactly once" proof is the `$BuildValidation` onready
	# scene-tree reference, appearing exactly once in valley.gd.
	var scene_hosting_hits: Array[String] = []
	_find_call_sites("res://src", "$BuildValidation", scene_hosting_hits)
	assert_int(scene_hosting_hits.size()).is_equal(1)
	assert_str(scene_hosting_hits[0]).contains("scene_world_management/valley.gd")


# ---------------------------------------------------------------------------
# AC3 -- Anti-Vacuity Lever #1: absent workers earn nothing, then earn again
# ---------------------------------------------------------------------------

func test_ac3_absent_worker_earns_zero_progress_then_earns_once_moved_on_site() -> void:
	var world: GameWorld = _boot_real_game_world()
	var valley: Valley = world.get_valley() as Valley

	# The REAL, hosted collaborators Valley itself wires -- this is the crux
	# of the proof: the SAME ConstructionJobQueue/ConstructionTickLoop/
	# VillagerOnSiteGate the shipped game's own default villager uses.
	# ConstructionTickLoop.setup() resolved its OWN time_tick_system against
	# the real `/root/TimeTickSystem` Autoload during boot (ADR-0001) -- a
	# fresh MockTimeTickSystem would never drive it at all, so this test's own
	# claiming villager must be wired to that SAME real Autoload, and this
	# test drives progress by firing ITS signal, never a second, disconnected
	# tick source.
	var tick_loop: ConstructionTickLoop = valley.get_construction_tick_loop()
	var queue: ConstructionJobQueue = valley.get_construction_job_queue()
	var gate: VillagerOnSiteGate = valley.get_villager_onsite_gate()
	# The real Autoload, referenced by name (mirrors
	# build_tool_hosting_boot_test.gd's own established `TimeTickSystem.tick.emit()`
	# precedent) -- never a second, disconnected mock tick source.
	var real_tick_system: Object = TimeTickSystem

	# A small, self-contained grid/nav_graph -- deliberately SEPARATE from the
	# real, procedurally-generated hosted VoxelWorldGrid (mirrors
	# gameworld_e2e_loop_test.gd's own AC-VILLAGER-WALKS fixture): this test's
	# target cell never reaches ConstructionTickLoop's own completion write
	# (the ONLY call site that reads voxel_world), so a fully controlled
	# fixture keeps this test's claim/travel arithmetic deterministic. It also
	# stays OUTSIDE the shared, hosted VillagerNavGraph's own built window (a
	# ~nav_region_size cell region around the real world center) -- this
	# test's own target_cell is therefore unreachable through the ALREADY-
	# hosted default villager's own nav_graph, so the two can never race for
	# the SAME job even though both now react to the SAME real tick signal.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	for x in range(5):
		for z in range(5):
			grid.set_cell(Vector3i(x, 0, z), CellContents.new(1, 0))

	var target_cell := Vector3i(4, 1, 0)
	var project := BuildProject.new(900081)
	project.add_cell(BlueprintCell.new(target_cell))
	project.release()
	queue.add_project(project)

	var predicate_source: VillagerAi = auto_free(VillagerAi.new())
	predicate_source.voxel_world = grid
	var nav_graph := VillagerNavGraph.new()
	nav_graph.subscribe_to_voxel_world(grid, predicate_source)
	nav_graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)

	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.config = VillagerAIConfig.new()
	villager.voxel_world = grid
	villager.scheduler = VillagerDecidingScheduler.new()
	villager.nav_graph = nav_graph
	villager.time_tick_system = real_tick_system
	villager.job_queue = queue
	villager.villager_id = 900081
	villager.current_cell = Vector3i(0, 1, 0)
	villager._from_cell = villager.current_cell
	villager._to_cell = villager.current_cell
	villager.setup()
	gate.register_villager(villager)

	# Act 1 -- one real tick: the villager's own real Deciding/F2 pass claims
	# the only available job and begins TRAVELING toward it -- but never
	# arrives, since advance_travel_progress() is never called anywhere in
	# this test (current_cell only ever changes via that explicit call).
	real_tick_system.tick.emit()

	assert_vector(Vector3(villager.get_claimed_job_cell())).is_equal(Vector3(target_cell))
	assert_vector(Vector3(villager.get_current_cell())).is_not_equal(Vector3(target_cell))
	assert_int(tick_loop.get_progress_ticks(target_cell)).is_equal(0)

	# Act 2 -- N further ticks, still away.
	for _i in range(3):
		real_tick_system.tick.emit()

	# Assert -- EXACTLY zero, not merely "not yet complete." On today's
	# unfixed build (both gates unwired, ConstructionTickLoop's own default
	# occupancy predicate is "never occupied") this accrues one tick per
	# emit() call above.
	assert_vector(Vector3(villager.get_current_cell())).is_not_equal(Vector3(target_cell))
	assert_int(tick_loop.get_progress_ticks(target_cell)).is_equal(0)

	# Act 3 -- move the villager onto the site (direct positional assignment
	# -- this codebase's own established convention for controlled arrival,
	# e.g. gameworld_e2e_loop_test.gd's own AC-PLACE-A-BLOCK fixture).
	villager.current_cell = target_cell
	villager._from_cell = target_cell
	villager._to_cell = target_cell
	real_tick_system.tick.emit()

	# Assert -- a naive "always deny" fix would fail HERE: progress must now
	# accrue once the claiming villager is actually on site.
	assert_int(tick_loop.get_progress_ticks(target_cell)).is_greater(0)


# ---------------------------------------------------------------------------
# AC4 -- Anti-Vacuity Lever #2: shelter reaches the game (real booted scene)
# ---------------------------------------------------------------------------

func test_ac4_bed_inside_a_real_built_room_reads_sheltered_bed_under_open_sky_does_not() -> void:
	var world: GameWorld = _boot_real_game_world()
	var valley: Valley = world.get_valley() as Valley
	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	var registry: FurnitureRegistry = valley.get_furniture_registry()
	var bed_provider: FurnitureBedProvider = valley.get_furniture_bed_provider()

	# Two well-separated locations near the real world-genesis focus cell
	# (the SAME real, resident window build_tool_hosting_boot_test.gd's own
	# `_fill_flat_plane` precedent already writes into synchronously) -- one
	# roofed, one left open, so both halves of the lever run against the SAME
	# real booted game.
	var center: Vector3i = VillagerRosterSpawner.world_center_cell(voxel_world.config)
	var sheltered_center: Vector3i = center + Vector3i(30, 0, 30)
	var open_center: Vector3i = center + Vector3i(30, 0, -30)
	_fill_flat_plane(voxel_world, sheltered_center, 3)
	_fill_flat_plane(voxel_world, open_center, 3)

	var sheltered_bed_a: Vector3i = Vector3i(sheltered_center.x, 1, sheltered_center.z)
	var sheltered_bed_b: Vector3i = sheltered_bed_a + Vector3i(0, 0, 1)
	# A real roof, directly above the bed's own two footprint cells -- the
	# rest of the open platform (unroofed) is the reachable "outside" every
	# Room needs to classify as Room rather than Sealed (mirrors
	# shelter_recovery_live_pair_test.gd's own `_roof_over` precedent).
	voxel_world.set_cell(sheltered_bed_a + Vector3i(0, 8, 0), CellContents.new(1, 0))
	voxel_world.set_cell(sheltered_bed_b + Vector3i(0, 8, 0), CellContents.new(1, 0))

	var open_bed_a: Vector3i = Vector3i(open_center.x, 1, open_center.z)
	var open_bed_b: Vector3i = open_bed_a + Vector3i(0, 0, 1)
	# Deliberately NO roof anywhere above open_bed_a/open_bed_b.

	# Placing through the REAL, hosted FurnitureRegistry -- BuildValidation's
	# own setup() already subscribed to its `furniture_changed` signal during
	# boot, so each place() call below synchronously triggers real
	# reclassification (Story build-validation-006's own landed mechanism) --
	# never a manually-forced run_load_pass() or synthetic trigger.
	registry.place(&"bed", [sheltered_bed_a, sheltered_bed_b])
	registry.place(&"bed", [open_bed_a, open_bed_b])

	# Assert -- today (BuildValidation hosted with a `null` validation
	# dependency, or not hosted at all) this reads false structurally, no
	# matter how perfect the room. After this story it must read true.
	assert_bool(bed_provider.is_bed_sheltered(sheltered_bed_a)).is_true()
	# The naive-fix guard: an identical bed under open sky must still read
	# false -- a "BuildValidation hosted but left unwired" fix, or one that
	# always answers true, both fail this half.
	assert_bool(bed_provider.is_bed_sheltered(open_bed_a)).is_false()


## Fills a flat floor at `y = 0` and CLEARS a generous headroom column above
## it (`y = 1` through `y = 12`) across a `(2 * half_extent + 1)` square
## centered on [param center]'s own X/Z. The clear pass is load-bearing, not
## decorative: the real, hosted [VoxelWorldGrid] pages in REAL, procedurally-
## generated terrain as chunks become resident during world genesis (the
## noise-driven `base_height`/`amplitude`/`frequency` knobs on
## `voxel_world_config.tres`; `payoff_loop_demo.gd`'s own
## `_find_build_site`/`_site_is_clear` exists for exactly this reason -- an
## arbitrary offset near world center is NOT guaranteed clear). A floor write
## alone leaves whatever pre-existing solid terrain a real chunk generated
## sitting inside the intended "open interior" column, which fails
## [VillagerWalkabilityRules.is_standable]'s own headroom check and prevents
## the room from ever forming as a valid candidate region -- the actual root
## cause the first version of this fixture hit. Explicitly clearing first
## guarantees a genuinely flat, open platform regardless of what terrain was
## there before (mirrors `build_tool_hosting_boot_test.gd`'s own
## `_fill_flat_plane`, except that one clear pass is added here since that
## file's own fixture only ever writes a floor, never tests headroom above
## it). Floor Y is a fixed, explicit `0` rather than `center.y - 1` -- this
## test's own bed/roof cells are placed at fixed Y offsets from that floor
## (standable `y = 1`, roof `y = 9`, `BuildValidationConfig`'s own shipped
## `max_room_height = 8`), so a fixed floor Y avoids depending on
## [method VillagerRosterSpawner.world_center_cell]'s own Y midpoint landing
## far enough below the world's `max_y` ceiling for a roof 8 cells above it
## to still be in-bounds.
func _fill_flat_plane(voxel_world: VoxelWorldGrid, center: Vector3i, half_extent: int) -> void:
	for dx in range(-half_extent, half_extent + 1):
		for dz in range(-half_extent, half_extent + 1):
			voxel_world.set_cell(Vector3i(center.x + dx, 0, center.z + dz), CellContents.new(1, 0))
			for y in range(1, 13):
				voxel_world.set_cell(Vector3i(center.x + dx, y, center.z + dz), CellContents.empty())


# ---------------------------------------------------------------------------
# Grep-guard helper
# ---------------------------------------------------------------------------

## Recursively scans every `.gd` file under [param dir_path] for [param
## needle] as a literal call-site substring, appending the `res://`-relative
## path once per matching FILE (never once per occurrence) to [param hits].
## Strips full-line `#`/`##` doc-comment lines first -- this codebase's own
## established false-positive guard (mirrors
## `world_root_valley_attach_test.gd`'s identical rationale): a class's own
## doc comment narrating "this class's own `_init` calls
## `VillagerOnSiteGate.new(...)`" in prose must never be mistaken for a real
## call site.
func _find_call_sites(dir_path: String, needle: String, hits: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full_path: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_find_call_sites(full_path, needle, hits)
		elif entry.ends_with(".gd"):
			var text: String = FileAccess.get_file_as_string(full_path)
			var cleaned_lines: Array[String] = []
			for line: String in text.split("\n"):
				if not line.strip_edges().begins_with("#"):
					cleaned_lines.append(line)
			if "\n".join(cleaned_lines).contains(needle):
				hits.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
