## Integration test -- Voxel World story vox-021 (boot-scoped mesh radius +
## `view_radius_chunks` 24 -> 12 retune; TD ruling
## `production/architecture-decisions-m02-preflight-2026-07-26.md` Addendum D
## / D2; ADR-0014 amendment §3, ADR-0005 unchanged; ADR-0002 two-tier config;
## TR-voxel-world-023/025/026).
##
## Proves, against the REAL production [VoxelWorldConfig] / [VoxelWorldGrid] /
## [VoxelWorldMesher] / [VoxelWorldMeshStreamer] / [GameWorld] / [Valley]
## (never a reimplementation):
## 1. AC-BOOT-RADIUS-KNOB: [member VoxelWorldConfig.boot_mesh_radius_chunks]
##    validated at all four boundaries (below MIN, above MAX, above
##    [member VoxelWorldConfig.view_radius_chunks], in range).
## 2. AC-BOOT-ONLY-CONSUMER (grep guard): exactly one CODE read of
##    `boot_mesh_radius_chunks` in `neues-spiel/src/`, outside its own
##    declaration file's doc comments/self-validation, and it lives inside
##    [method VoxelWorldMeshStreamer.build_initial_window]'s own body.
## 3. AC-STEADY-STATE-UNCHANGED: the boot window's key count equals the BOOT
##    radius window (never the steady-state one); [method
##    VoxelWorldMeshStreamer.update_view_window] grows the tracked set toward
##    the steady-state ([member view_radius_chunks]) window and never
##    exceeds it; the shared [member
##    VoxelWorldConfig.mesh_build_budget_ms] progress guarantee still holds
##    exactly (one chunk per call) when growing FROM the boot window.
## 4. AC-VISIBILITY-RANGE-DERIVED: [method
##    VoxelWorldMeshStreamer.compute_visibility_range_end](12) == 192.0, and
##    no literal fade-distance value is hardcoded anywhere in `src/`.
## 5. AC-ADR-0005-ORDER-HOLDS: a real [GameWorld]/[Valley] boot's initial mesh
##    window (already complete the instant `add_child()` returns, ADR-0005)
##    matches the BOOT radius, not the steady-state radius.
## 6. AC-VIEW-RADIUS-RETUNE (regression pin): the shipped `.tres` ships
##    `view_radius_chunks == 12` / `boot_mesh_radius_chunks == 8` with no
##    unexpected `validate()` clamp.
##
## Determinism (QA rule): every budget-driven assertion uses a deterministic
## fake clock (`mesh_view_window_streaming_test.gd`'s own established
## [_FakeClock] pattern) -- never measured real elapsed time. The one
## real-clock convergence loop (`test_build_initial_window_uses_boot_radius_
## and_update_view_window_grows_to_steady_state_never_exceeding`) asserts only
## item COUNTS at each step, matching that same suite's own established
## "settle" convergence-loop precedent -- never a wall-clock duration.
class_name BootMeshRadiusTest
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")


# ---------------------------------------------------------------------------
# Inner helpers (above all test functions, per this codebase's own convention)
# ---------------------------------------------------------------------------

## Test-local deterministic fake clock (not a production class) -- matches
## `mesh_view_window_streaming_test.gd`/`mesh_invalidation_budget_test.gd`'s
## identical helper.
class _FakeClock:
	var value: int = 0
	var step_usec: int = 0

	func tick() -> int:
		value += step_usec
		return value


func _make_grid(world_size: int = 2048) -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	var config := VoxelWorldConfig.new()
	config.world_width_cells = world_size
	config.world_depth_cells = world_size
	grid.config = config
	return grid


func _make_mesher(grid: VoxelWorldGrid) -> VoxelWorldMesher:
	var mesher: VoxelWorldMesher = auto_free(VoxelWorldMesher.new())
	mesher.grid = grid
	# Story vox-023: VoxelWorldMesher.setup() now asserts appearance is wired
	# (AC-NEVER-OPTIONAL-AND-CONSEQUENTIAL) -- a fresh, valid config satisfies
	# that assert without affecting this file's own view-window assertions.
	mesher.appearance = BlockAppearanceConfig.new()
	mesher.setup()
	return mesher


func _make_streamer(grid: VoxelWorldGrid, mesher: VoxelWorldMesher) -> VoxelWorldMeshStreamer:
	var streamer: VoxelWorldMeshStreamer = auto_free(VoxelWorldMeshStreamer.new())
	streamer.grid = grid
	streamer.mesher = mesher
	streamer.setup()
	return streamer


## Recursively lists every `.gd` file under [param dir_path] (a `res://`
## path) -- used by the grep-guard tests below.
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


## Strips full-line comments (any line whose stripped form begins with `#`) --
## mirrors `live_view_window_wiring_test.gd`'s own established
## `test_valley_source_never_calls_setup_on_the_hosted_mesh_streamer` grep
## precedent exactly, so doc-comment mentions of an identifier are never
## mistaken for a code read.
func _strip_full_line_comments(text: String) -> String:
	var code_only: String = ""
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			code_only += line
			code_only += "\n"
	return code_only


func _count_occurrences(text: String, needle: String) -> int:
	var count: int = 0
	var idx: int = 0
	while true:
		idx = text.find(needle, idx)
		if idx == -1:
			break
		count += 1
		idx += needle.length()
	return count


## Returns the top-level function body (from a line beginning with [param
## func_prefix] up to, but not including, the NEXT top-level `func ` line) --
## "top-level" meaning column 0, no leading whitespace, matching GDScript's
## own function-declaration shape.
func _extract_function_body(code_only: String, func_prefix: String) -> String:
	var start: int = code_only.find(func_prefix)
	if start == -1:
		return ""
	var rest: String = code_only.substr(start)
	var next_func: int = rest.find("\nfunc ", 1)
	if next_func == -1:
		return rest
	return rest.substr(0, next_func)


# ---------------------------------------------------------------------------
# AC-BOOT-RADIUS-KNOB -- all four boundaries, each isolated from the other
# clamp tier so a single test proves exactly one thing.
# ---------------------------------------------------------------------------

func test_boot_mesh_radius_below_min_clamps_to_min_with_warning() -> void:
	var config := VoxelWorldConfig.new()
	config.boot_mesh_radius_chunks = 1
	var issues: Array[String] = config.validate()
	assert_int(config.boot_mesh_radius_chunks).is_equal(VoxelWorldConfig.BOOT_MESH_RADIUS_CHUNKS_MIN)
	var found: bool = false
	for issue: String in issues:
		if issue.contains("boot_mesh_radius_chunks"):
			found = true
	assert_bool(found).is_true()


func test_boot_mesh_radius_above_max_clamps_to_view_radius_chunks_max_with_warning() -> void:
	# Isolated from the separate `> view_radius_chunks` clamp tier by setting
	# view_radius_chunks to the SAME ceiling first.
	var config := VoxelWorldConfig.new()
	config.view_radius_chunks = VoxelWorldConfig.VIEW_RADIUS_CHUNKS_MAX
	config.boot_mesh_radius_chunks = 999
	var issues: Array[String] = config.validate()
	assert_int(config.boot_mesh_radius_chunks).is_equal(VoxelWorldConfig.VIEW_RADIUS_CHUNKS_MAX)
	var found: bool = false
	for issue: String in issues:
		if issue.contains("boot_mesh_radius_chunks"):
			found = true
	assert_bool(found).is_true()


func test_boot_mesh_radius_exceeding_view_radius_chunks_clamps_non_blocking_and_boot_proceeds() -> void:
	var config := VoxelWorldConfig.new()
	config.view_radius_chunks = 12
	config.boot_mesh_radius_chunks = 20
	var issues: Array[String] = config.validate()
	assert_int(config.boot_mesh_radius_chunks).is_equal(12)
	var has_blocking: bool = false
	var found_warning: bool = false
	for issue: String in issues:
		if issue.begins_with(ConfigResource.BLOCKING_PREFIX):
			has_blocking = true
		if issue.contains("boot_mesh_radius_chunks"):
			found_warning = true
	assert_bool(has_blocking).is_false()  # non-BLOCKING -- boot proceeds
	assert_bool(found_warning).is_true()


func test_boot_mesh_radius_in_range_untouched_no_warning() -> void:
	var config := VoxelWorldConfig.new()
	config.view_radius_chunks = 12
	config.boot_mesh_radius_chunks = 8
	var issues: Array[String] = config.validate()
	assert_int(config.boot_mesh_radius_chunks).is_equal(8)
	for issue: String in issues:
		assert_bool(issue.contains("boot_mesh_radius_chunks")).is_false()


# ---------------------------------------------------------------------------
# AC-BOOT-ONLY-CONSUMER (grep guard)
# ---------------------------------------------------------------------------

func test_boot_mesh_radius_chunks_has_exactly_one_code_read_and_it_is_inside_build_initial_window() -> void:
	var files: Array[String] = _list_gd_files_recursive("res://src")
	var total_reads: int = 0
	var found_in_build_initial_window: bool = false
	for path: String in files:
		if path == "res://src/voxel_world/voxel_world_config.gd":
			# Its own declaration + self-validation (`validate()`'s clamp
			# logic) -- excluded per this AC's own "outside its own
			# declaration/doc comment" wording; this is the field's home file,
			# not a second consumer.
			continue
		var code_only: String = _strip_full_line_comments(FileAccess.get_file_as_string(path))
		var count: int = _count_occurrences(code_only, "boot_mesh_radius_chunks")
		if count > 0:
			total_reads += count
			if path == "res://src/voxel_world/voxel_world_mesh_streamer.gd":
				var func_body: String = _extract_function_body(code_only, "func build_initial_window")
				if func_body.contains("boot_mesh_radius_chunks"):
					found_in_build_initial_window = true
	assert_int(total_reads).is_equal(1)
	assert_bool(found_in_build_initial_window).is_true()


# ---------------------------------------------------------------------------
# AC-STEADY-STATE-UNCHANGED
# ---------------------------------------------------------------------------

func test_build_initial_window_uses_boot_radius_and_update_view_window_grows_to_steady_state_never_exceeding() -> void:
	# Arrange -- a focus well inside a large world (2048/16 = 128 chunks/axis)
	# so neither radius clips against a world edge.
	var grid: VoxelWorldGrid = _make_grid(2048)
	grid.config.view_radius_chunks = 12
	grid.config.boot_mesh_radius_chunks = 8
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	var streamer: VoxelWorldMeshStreamer = _make_streamer(grid, mesher)
	var focus := Vector3i(1600, 0, 1600)  # chunk (100, 100)

	# Act -- boot.
	streamer.build_initial_window(focus)

	# Assert -- the boot window is the BOOT radius (17x17 = 289), NOT the
	# steady-state (25x25 = 625) window get_desired_window_keys reports --
	# get_desired_window_keys stays deliberately steady-state-only.
	var boot_expected: int = (2 * 8 + 1) * (2 * 8 + 1)
	var steady_expected: int = (2 * 12 + 1) * (2 * 12 + 1)
	assert_int(mesher.get_tracked_chunk_keys().size()).is_equal(boot_expected)
	assert_int(streamer.get_desired_window_keys(focus).size()).is_equal(steady_expected)

	# Act/Assert -- update_view_window grows the tracked set toward the
	# steady-state window (real clock -- a non-resident/un-generated chunk
	# builds cheaply in this headless suite) and NEVER exceeds it at any step.
	var guard: int = 0
	while mesher.get_tracked_chunk_keys().size() < steady_expected and guard < 500:
		streamer.update_view_window(focus)
		assert_int(mesher.get_tracked_chunk_keys().size()).is_less_equal(steady_expected)
		guard += 1

	assert_int(mesher.get_tracked_chunk_keys().size()).is_equal(steady_expected)


func test_update_view_window_from_boot_window_respects_shared_budget_progress_guarantee() -> void:
	# Arrange -- same shared-budget progress guarantee vox-020 established
	# (one chunk per call when per-item cost alone exceeds the budget),
	# re-pinned here specifically starting FROM the boot window -- proving
	# the radius-threading change did not alter _sync_window's own budget
	# mechanics.
	var grid: VoxelWorldGrid = _make_grid(2048)
	grid.config.view_radius_chunks = 12
	grid.config.boot_mesh_radius_chunks = 8
	grid.config.mesh_build_budget_ms = 4.0
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	var streamer: VoxelWorldMeshStreamer = _make_streamer(grid, mesher)
	var focus := Vector3i(1600, 0, 1600)
	streamer.build_initial_window(focus)
	var boot_count: int = mesher.get_tracked_chunk_keys().size()

	var clock := _FakeClock.new()
	clock.step_usec = 5000  # 5 ms/item -- alone exceeds the 4.0 ms budget,
	# mirroring the measured ~7.7 ms/chunk-vs-4.0 ms-budget shape vox-019 found.
	streamer.set_time_source_for_test(Callable(clock, "tick"))

	# Act -- ONE budgeted call.
	streamer.update_view_window(focus)

	# Assert -- exactly one new chunk integrated, never zero, never more.
	assert_int(mesher.get_tracked_chunk_keys().size()).is_equal(boot_count + 1)


# ---------------------------------------------------------------------------
# AC-VISIBILITY-RANGE-DERIVED
# ---------------------------------------------------------------------------

func test_compute_visibility_range_end_at_new_default_radius_12() -> void:
	assert_float(VoxelWorldMeshStreamer.compute_visibility_range_end(12)).is_equal_approx(192.0, 0.0001)


func test_no_literal_fade_distance_hardcoded_anywhere_in_src() -> void:
	# Grep guard -- 192.0 (12*16*1.0, the NEW default) and 384.0 (the OLD
	# default) must never appear as a hardcoded visibility_range_end
	# assignment anywhere in src/ -- only compute_visibility_range_end()
	# (a pure function of the radius) may ever produce either value.
	var files: Array[String] = _list_gd_files_recursive("res://src")
	for path: String in files:
		var code_only: String = _strip_full_line_comments(FileAccess.get_file_as_string(path))
		assert_bool(code_only.contains("visibility_range_end = 192")).is_false()
		assert_bool(code_only.contains("visibility_range_end = 384")).is_false()


# ---------------------------------------------------------------------------
# AC-ADR-0005-ORDER-HOLDS
# ---------------------------------------------------------------------------

func test_gameworld_boot_initial_mesh_window_uses_boot_radius_not_steady_state_radius() -> void:
	# Act -- a real GameWorld/Valley boot through the ADR-0005 gate (a
	# Ready-immediately mock database), mirroring
	# `live_view_window_wiring_test.gd`'s own established `_boot_valley`
	# precedent.
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)

	# Assert -- boot already reached ACTIVE synchronously (ADR-0005 --
	# build_initial_window ran inside WIRING, strictly before ACTIVE, the
	# instant add_child() returned; no `await get_tree().process_frame`
	# anywhere above this line).
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()

	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	var mesher: VoxelWorldMesher = valley.get_voxel_world_mesher()
	var streamer: VoxelWorldMeshStreamer = valley.get_voxel_world_mesh_streamer()
	var boot_radius: int = voxel_world.config.boot_mesh_radius_chunks
	var steady_radius: int = voxel_world.config.view_radius_chunks
	assert_int(boot_radius).is_less(steady_radius)  # sanity -- the shipped config actually narrows at boot

	# Assert -- the initial window's key count equals the BOOT radius window.
	# Story scene-005 (World genesis in the boot sequence, AC-ONE-START-FOCUS)
	# changed the PRECONDITION this assertion was written against: world
	# genesis now calls CameraInput.set_target() with the config-derived
	# world-CENTER cell (VillagerRosterSpawner.world_center_cell) BEFORE this
	# initial mesh window ever builds -- the camera's default Vector3.ZERO
	# "world corner" starting orbit target (this test's own former precondition,
	# the exact bug AC-ONE-START-FOCUS names and fixes) no longer holds by the
	# time build_initial_window runs. The window is therefore now centered on
	# that interior cell, comfortably clear of every world edge at this
	# radius, and survives with NO lower-bound clipping at all -- a full
	# (2*radius+1)^2 square, not the former clipped-corner (radius+1)^2.
	# Updated consciously, not incidentally, per scene-005's own dev-story
	# instructions to flag this file.
	var focus_cell: Vector3i = VillagerRosterSpawner.world_center_cell(voxel_world.config)
	var expected_boot_count: int = (2 * boot_radius + 1) * (2 * boot_radius + 1)
	assert_int(mesher.get_tracked_chunk_keys().size()).is_equal(expected_boot_count)
	var steady_window: Array[Vector2i] = streamer.get_desired_window_keys(focus_cell)
	assert_int(steady_window.size()).is_greater(expected_boot_count)


# ---------------------------------------------------------------------------
# AC-VIEW-RADIUS-RETUNE (Config/Data regression pin)
# ---------------------------------------------------------------------------

func test_shipped_tres_ships_retuned_radii_with_no_unexpected_clamp() -> void:
	var config: VoxelWorldConfig = load("res://data/config/voxel_world_config.tres")
	assert_int(config.view_radius_chunks).is_equal(12)
	assert_int(config.boot_mesh_radius_chunks).is_equal(8)
	var issues: Array[String] = config.validate()
	assert_array(issues).is_empty()
