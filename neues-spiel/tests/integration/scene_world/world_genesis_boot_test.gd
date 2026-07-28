## Integration test — Scene/World Management Story scene-005 (World genesis
## in the boot sequence, ADR-0005 primary / ADR-0015 primary / ADR-0014
## secondary).
##
## Proves:
## - **AC-GENESIS-BEFORE-ACTIVE**: a real headless boot (real grid + real
##   Valley, [MockResourceItemDatabase] reporting Ready) reaches
##   [constant GameWorld.BootState.ACTIVE] with resident chunks non-empty and
##   at least one standable cell near the start focus; a Failed boot never
##   attaches a Valley at all (so genesis, which requires a non-null Valley,
##   structurally cannot have run).
## - **AC-NO-FULL-EXTENT-GEN**: grep guard -- `generate_terrain(` appears in
##   `neues-spiel/src/` ONLY at its own definition site.
## - **AC-DETERMINISTIC-BY-SEED**: two independent small grids driven through
##   the SAME residency-drive shape [method GameWorld._drive_boot_residency]
##   uses, with the same `terrain_seed`, produce an identical sampled cell set
##   over the boot window; a different seed differs.
## - **AC-GENERATED-STATE**: `get_state() == GENERATED` after a real boot.
## - **AC-BATCHED-SIGNAL-DISCIPLINE**: zero `cell_changed` (and zero
##   `cells_changed_batch`, since silent page-in/regen never touches an
##   already-written record) fire across a residency-drive pass.
## - **AC-ONE-START-FOCUS**: the real boot's camera start target, in world
##   space, equals [method VoxelWorldGrid.cell_to_world] of the SAME
##   config-derived start-focus cell [VillagerRosterSpawner.world_center_cell]
##   returns.
## - **AC-MESH-WINDOW-AFTER-GENESIS**: the real boot's initial mesh window
##   contains ACTUAL surface geometry at the start-focus chunk -- only
##   possible if that chunk's data was already resident (genesis) before
##   [method VoxelWorldMeshStreamer.build_initial_window] ran; a chunk meshed
##   before its data lands renders zero surfaces (this file's own class doc
##   comment / [VoxelWorldMesher]'s established contract).
## - **AC-ROSTER-AFTER-WORLD**: the real boot's [Valley.get_villagers] reports
##   exactly the shipped `starting_villager_count` MVP default (1) total
##   villagers -- Story villager-ai-022: the pre-existing default villager
##   (villager_id 0) now COUNTS toward that config, is placed by the SAME
##   genesis call, and no longer sits at the world corner.
## - **AC-NAV-GRAPH-BUILT**: the real boot's shared [VillagerNavGraph] reports
##   built, and a path query between two cells this test carves standable
##   (deterministic, never relying on incidental generated-terrain
##   connectivity) succeeds.
## - **AC-NO-SYNC-IO-IN-FRAME-PATH**: grep guard -- neither
##   `drain_pending_async_reads(` nor `wait_for_async_residency_idle(` appears
##   inside any `_process`/`_physics_process` function body anywhere under
##   `neues-spiel/src/`.
## - **AC1/AC6 (camera-input story cam-013)**: the boot-invariant assertion
##   block's own growth mechanism (`production/sprints/sprint-10.md`'s
##   process finding, this project's countermeasure for "ship-green-and-
##   uncalled") -- one line added per landed system. The real boot hosts
##   exactly one `Camera3D` under `Valley`, and it is `current`. The richer
##   AC2/AC3/AC4/AC5 claims (mirrors CameraInput one-way, target near the
##   settlement not the origin, no new input handler) have their own
##   dedicated file, `camera_hosting_test.gd`, per this story's own Test
##   Evidence note -- mirroring `villager_need_seeding_boot_test.gd`'s own
##   established "independent cluster large enough for its own file"
##   precedent.
class_name WorldGenesisBootTest
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")


# ---------------------------------------------------------------------------
# Test isolation — per-test temp region directories, cleaned up after each test
# ---------------------------------------------------------------------------

var _created_region_dirs: Array[String] = []


func after_test() -> void:
	for dir_path: String in _created_region_dirs:
		_remove_dir_recursive(dir_path)
	_created_region_dirs.clear()


func _make_temp_region_dir(suffix: String) -> String:
	var dir_path: String = "user://scene005_test_regions/%s_%d" % [suffix, Time.get_ticks_usec()]
	_created_region_dirs.append(dir_path)
	return dir_path


func _remove_dir_recursive(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path: String = dir_path.path_join(entry)
			if dir.current_is_dir():
				_remove_dir_recursive(full_path)
			else:
				DirAccess.remove_absolute(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(dir_path)


# ---------------------------------------------------------------------------
# Shared helper — mirrors GameWorld._drive_boot_residency's own bounded shape
# (never a re-derivation of update_residency/drain_pending_async_reads
# themselves; this loop only drives the SAME two public surfaces genesis
# uses, at small test scale).
# ---------------------------------------------------------------------------

func _drive_residency_until_settled(grid: VoxelWorldGrid, focus: Vector3i, ceiling_ms: float) -> void:
	# Mirrors GameWorld._drive_boot_residency's own two-part fixed-point
	# termination (see that method's doc comment): max_concurrent_async_tasks
	# caps how many NEW chunks a single update_residency() call dispatches, so
	# a bare "zero in flight" check can return after only the FIRST capped
	# batch, silently leaving later chunks never even requested. Termination
	# requires BOTH zero in flight AND no resident-count growth since the
	# previous round.
	var start_usec: int = Time.get_ticks_usec()
	var ceiling_usec: int = int(ceiling_ms * 1000.0)
	var previous_resident_count: int = -1
	while true:
		grid.update_residency(focus, focus)
		var elapsed_usec: int = Time.get_ticks_usec() - start_usec
		if elapsed_usec >= ceiling_usec:
			return
		grid.drain_pending_async_reads(maxi(1, int(float(ceiling_usec - elapsed_usec) / 1000.0)))
		var in_flight_count: int = grid.get_in_flight_async_task_count()
		var resident_count: int = grid.get_resident_chunk_keys().size()
		if in_flight_count == 0 and resident_count == previous_resident_count:
			return
		previous_resident_count = resident_count
		if (Time.get_ticks_usec() - start_usec) >= ceiling_usec:
			return


## Recursive Camera3D count, mirroring `tools/settlement_overview_capture.gd`'s
## own `_count_cameras` helper -- used by the AC1/AC6 (story cam-013)
## boot-invariant assertion below.
func _count_camera3d_nodes(node: Node) -> int:
	var count: int = 1 if node is Camera3D else 0
	for child: Node in node.get_children():
		count += _count_camera3d_nodes(child)
	return count


func _small_config(seed_value: int, suffix: String) -> VoxelWorldConfig:
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 64
	config.world_depth_cells = 64
	config.max_y = 8
	config.view_radius_chunks = 2
	config.settlement_radius_chunks = 2
	config.boot_mesh_radius_chunks = 2
	config.terrain_seed = seed_value
	config.region_directory = _make_temp_region_dir(suffix)
	return config


# ---------------------------------------------------------------------------
# AC-GENESIS-BEFORE-ACTIVE / AC-GENERATED-STATE / AC-ONE-START-FOCUS /
# AC-MESH-WINDOW-AFTER-GENESIS / AC-ROSTER-AFTER-WORLD / AC-NAV-GRAPH-BUILT
# — one real boot, bundled assertions (each real boot pays the production
# 2000x2000 config's full genesis + mesh cost, so this file deliberately
# bundles everything a single real boot can prove into ONE test rather than
# re-paying that cost per assertion).
# ---------------------------------------------------------------------------

func test_real_boot_genesis_produces_a_populated_active_world() -> void:
	# Arrange + Act
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)

	# Assert — boot reached ACTIVE through the real gate, genesis included.
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()
	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()

	# AC-GENESIS-BEFORE-ACTIVE
	assert_bool(voxel_world.get_resident_chunk_keys().size() > 0).is_true()
	var start_focus: Vector3i = VillagerRosterSpawner.world_center_cell(voxel_world.config)
	var found_standable_near_focus: bool = false
	for x in range(start_focus.x - 4, start_focus.x + 5):
		for z in range(start_focus.z - 4, start_focus.z + 5):
			for y in range(voxel_world.config.min_y, voxel_world.config.max_y + 1):
				if VillagerWalkabilityRules.is_standable(voxel_world, Vector3i(x, y, z)):
					found_standable_near_focus = true
	assert_bool(found_standable_near_focus).is_true()

	# AC-GENERATED-STATE
	assert_int(voxel_world.get_state()).is_equal(VoxelWorldGrid.GridState.GENERATED)

	# AC-ONE-START-FOCUS — camera's start target equals the SAME config-derived
	# start-focus cell everything else anchored on.
	var camera_input: CameraInput = valley.get_camera_input()
	assert_vector(camera_input.get_target()).is_equal(VoxelWorldGrid.cell_to_world(start_focus))

	# AC-MESH-WINDOW-AFTER-GENESIS — the start-focus chunk's mesh carries REAL
	# surface geometry, only possible if its data was already resident
	# (genesis) before build_initial_window ran; a chunk meshed before its
	# data lands renders zero surfaces.
	var mesher: VoxelWorldMesher = valley.get_voxel_world_mesher()
	var focus_chunk_key: Vector2i = voxel_world.chunk_key_for_cell(start_focus)
	var mesh_instance: MeshInstance3D = mesher.get_chunk_mesh_instance(focus_chunk_key)
	assert_object(mesh_instance).is_not_null()
	assert_object(mesh_instance.mesh).is_not_null()
	assert_int(mesh_instance.mesh.get_surface_count()).is_greater(0)

	# AC-ROSTER-AFTER-WORLD — shipped MVP default starting_villager_count = 1.
	# Story villager-ai-022 ("the stray villager at the world corner"):
	# villager 0 (the always-present default) is now placed THROUGH this same
	# genesis call and COUNTS toward starting_villager_count, so a config of 1
	# yields exactly ONE total settler, never "1 default + 1 genesis-spawned"
	# (the actual shipped bug this story fixed — a real boot used to report 2
	# villagers for a count of 1, one of them stranded at the world corner
	# (0, 0, 0)).
	assert_int(valley.get_villagers().size()).is_equal(1)
	assert_vector(Vector3(valley.get_villager_ai().get_current_cell())).is_not_equal(Vector3.ZERO)
	assert_bool(
		VillagerWalkabilityRules.is_standable(voxel_world, valley.get_villager_ai().get_current_cell())
	).is_true()

	# AC-NAV-GRAPH-BUILT — carve two DETERMINISTICALLY standable, adjacent,
	# connected cells (never relying on incidental generated-terrain
	# connectivity, which this test cannot control) and rebuild the graph over
	# them via the same public surface genesis itself calls.
	var pillar_a: Vector3i = start_focus
	var pillar_b: Vector3i = start_focus + Vector3i(1, 0, 0)
	for pillar: Vector3i in [pillar_a, pillar_b]:
		voxel_world.set_cell(pillar + Vector3i(0, -1, 0), CellContents.new(1, 0))
		for dy in range(0, 3):
			voxel_world.set_cell(pillar + Vector3i(0, dy, 0), CellContents.empty())
	valley.build_villager_nav_graph(start_focus)
	assert_bool(VillagerWalkabilityRules.is_standable(voxel_world, pillar_a)).is_true()
	assert_bool(VillagerWalkabilityRules.is_standable(voxel_world, pillar_b)).is_true()
	var nav_graph: VillagerNavGraph = valley.get_villager_nav_graph()
	assert_bool(nav_graph.is_built()).is_true()
	var path: Array[Vector3i] = nav_graph.find_path(pillar_a, pillar_b)
	assert_bool(path.size() > 0).is_true()

	# AC1/AC6 (camera-input story cam-013, the boot-invariant assertion block's
	# own growth mechanism -- one line added per landed system): exactly one
	# Camera3D is hosted under Valley, and it is current. Before this story
	# the shipped scene chain hosted zero Camera3D nodes at all.
	var camera_count: int = _count_camera3d_nodes(valley)
	assert_int(camera_count).is_equal(1)
	var valley_camera: Camera3D = valley.get_valley_camera()
	assert_object(valley_camera).is_not_null()
	assert_bool(valley_camera.current).is_true()


func test_real_boot_failed_rid_never_attaches_valley_so_genesis_cannot_have_run() -> void:
	# Arrange — a Failed RID outcome: GameWorld._on_database_settled's own
	# early-return means _attach_valley() (and therefore _run_world_genesis,
	# whose own first guard requires a non-null Valley) is never reached —
	# cheap, no genesis/mesh cost paid.
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	world.resource_item_database = database
	add_child(world)

	# Act
	database.settle(false, ["world genesis boot test — forced Failed"])

	# Assert
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.HALTED)
	assert_object(world.get_valley()).is_null()


# ---------------------------------------------------------------------------
# AC-DETERMINISTIC-BY-SEED
# ---------------------------------------------------------------------------

func test_ac_deterministic_by_seed_same_seed_produces_identical_sampled_cells_different_seed_differs() -> void:
	# Arrange + Act — grid A and grid B, same seed, driven independently
	# through the same bounded residency-drive shape genesis uses.
	var grid_a: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid_a.config = _small_config(777, "det_a")
	grid_a.setup()
	_drive_residency_until_settled(grid_a, Vector3i(32, 4, 32), 2000.0)

	var grid_b: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid_b.config = _small_config(777, "det_b")
	grid_b.setup()
	_drive_residency_until_settled(grid_b, Vector3i(32, 4, 32), 2000.0)

	var grid_c: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid_c.config = _small_config(999, "det_c")
	grid_c.setup()
	_drive_residency_until_settled(grid_c, Vector3i(32, 4, 32), 2000.0)

	# Assert — same seed: every sampled column's fill height (captured via
	# is_empty() per cell, a complete proxy for content equality since this
	# generator fills a column uniformly up to its height and leaves the rest
	# empty) matches exactly.
	for x in range(16, 48):
		for z in range(16, 48):
			for y in range(0, 8):
				var cell := Vector3i(x, y, z)
				assert_bool(grid_a.get_cell(cell).is_empty()).is_equal(grid_b.get_cell(cell).is_empty())

	# Assert — different seed: at least one sampled cell differs.
	var differs: bool = false
	for x in range(16, 48):
		for z in range(16, 48):
			for y in range(0, 8):
				var cell := Vector3i(x, y, z)
				if grid_a.get_cell(cell).is_empty() != grid_c.get_cell(cell).is_empty():
					differs = true
	assert_bool(differs).is_true()


# ---------------------------------------------------------------------------
# AC-BATCHED-SIGNAL-DISCIPLINE
# ---------------------------------------------------------------------------

func test_ac_batched_signal_discipline_zero_per_cell_signals_across_a_residency_drive_pass() -> void:
	# Arrange — a listener connected BEFORE the drive begins (QA plan wording:
	# "a listener that counts signals across a full boot").
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = _small_config(555, "batch_signal")
	grid.setup()

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

	# Act
	_drive_residency_until_settled(grid, Vector3i(32, 4, 32), 2000.0)

	# Assert — silent page-in/regen (this class's own established contract):
	# zero per-cell signals of either shape.
	assert_int(cell_changed_count[0]).is_equal(0)
	assert_int(batch_count[0]).is_equal(0)


# ---------------------------------------------------------------------------
# AC-NO-FULL-EXTENT-GEN / AC-NO-SYNC-IO-IN-FRAME-PATH — grep guards
# ---------------------------------------------------------------------------

func test_ac_no_full_extent_gen_generate_terrain_call_sites_grep_guard() -> void:
	# Grep-guarded AC: the only permitted occurrence of `generate_terrain(` in
	# `neues-spiel/src/` is its own definition in voxel_world_grid.gd.
	var offenders: Array[String] = []
	for path: String in _list_gd_files_recursive("res://src"):
		var text: String = FileAccess.get_file_as_string(path)
		for line: String in text.split("\n"):
			var stripped: String = line.strip_edges()
			if stripped.begins_with("#"):
				continue
			if not stripped.contains("generate_terrain("):
				continue
			var is_own_definition: bool = (
				path.ends_with("voxel_world_grid.gd") and stripped.begins_with("func generate_terrain(")
			)
			if not is_own_definition:
				offenders.append("%s :: %s" % [path, stripped])
	assert_array(offenders).is_empty()


func test_ac_no_sync_io_in_frame_path_grep_guard() -> void:
	# Grep-guarded AC: neither drain_pending_async_reads( nor
	# wait_for_async_residency_idle( appears inside any _process/
	# _physics_process function body anywhere under neues-spiel/src/.
	var offenders: Array[String] = []
	for path: String in _list_gd_files_recursive("res://src"):
		var text: String = FileAccess.get_file_as_string(path)
		var cleaned_lines: Array[String] = []
		for line: String in text.split("\n"):
			if not line.strip_edges().begins_with("#"):
				cleaned_lines.append(line)
		var cleaned: String = "\n".join(cleaned_lines)
		for body: String in _extract_process_function_bodies(cleaned):
			if body.contains("drain_pending_async_reads(") or body.contains("wait_for_async_residency_idle("):
				offenders.append(path)
	assert_array(offenders).is_empty()


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

func _list_gd_files_recursive(dir_path: String) -> Array[String]:
	var results: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return results
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path: String = dir_path.path_join(entry)
			if dir.current_is_dir():
				results.append_array(_list_gd_files_recursive(full_path))
			elif entry.ends_with(".gd"):
				results.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	return results


## Extracts the text body of every top-level `_process`/`_physics_process`
## function found in [param source] (comment lines already stripped by the
## caller), from its own `func` line up to (not including) the next line
## whose stripped text begins with `func ` at the SAME OR SHALLOWER
## indentation -- adequate for this codebase's flat per-class function layout
## (no nested inner-class overrides of either callback exist under `src/`).
func _extract_process_function_bodies(source: String) -> Array[String]:
	var bodies: Array[String] = []
	var lines: PackedStringArray = source.split("\n")
	var i: int = 0
	while i < lines.size():
		var line: String = lines[i]
		var stripped: String = line.strip_edges()
		if stripped.begins_with("func _process(") or stripped.begins_with("func _physics_process("):
			var indent: int = line.length() - line.strip_edges(true, false).length()
			var body: String = line + "\n"
			var j: int = i + 1
			while j < lines.size():
				var next_line: String = lines[j]
				var next_stripped: String = next_line.strip_edges()
				if next_stripped.begins_with("func "):
					var next_indent: int = next_line.length() - next_line.strip_edges(true, false).length()
					if next_indent <= indent:
						break
				body += next_line + "\n"
				j += 1
			bodies.append(body)
			i = j
		else:
			i += 1
	return bodies
