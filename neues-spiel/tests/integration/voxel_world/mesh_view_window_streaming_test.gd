## Integration test -- Voxel World story vox-015 (mesh view-window streaming
## with per-frame build + unload budgets, ADR-0014 Decision Section 3 primary
## / ADR-0015 Decision Section 1 secondary; TR-voxel-world-025/026).
##
## Proves, all against [VoxelWorldMeshStreamer]:
## 1. AC-1 (view-window bound draw calls, TR-voxel-world-025): meshed-chunk
##    count tracks the view window, not world size; entering chunks are
##    built, distant chunks are unloaded; the window is bounds-filtered at
##    the world edge (never a negative/out-of-world chunk key).
## 2. AC-2 (staggered unload, no hitch, TR-voxel-world-025): per-frame TIME
##    budgets (not a fixed item count) bound BOTH mesh builds AND unloads,
##    re-checked after every single item (progress guaranteed for the first
##    item even if it alone exceeds budget); an unload burst is staggered
##    across calls, never applied all at once, and fully converges.
## 3. AC-3 (initial window build behind the transition overlay,
##    TR-voxel-world-026): [method VoxelWorldMeshStreamer.build_initial_window]
##    ignores the budget knobs entirely and builds the whole window in ONE
##    call, unlike the budgeted per-frame [method
##    VoxelWorldMeshStreamer.update_view_window].
## 4. Control Manifest Required pattern: a built chunk's [MeshInstance3D]
##    gets [member MeshInstance3D.visibility_range_end] DERIVED from [member
##    VoxelWorldConfig.view_radius_chunks], never a hardcoded literal.
##
## Determinism (QA rule: no time-dependent assertions): every budget
## assertion here is against ITEM COUNTS resulting from a deterministic fake
## clock ([method VoxelWorldMeshStreamer.set_time_source_for_test]), never
## against measured real elapsed time or a real sleep/wait duration -- the
## same pattern `tests/integration/voxel_world/time_based_streaming_budget_test.gd`
## already established for the data-residency tier.
class_name MeshViewWindowStreamingTest
extends GdUnitTestSuite


## Test-local deterministic fake clock (not a production class) -- see
## `time_based_streaming_budget_test.gd`'s identical helper for the full
## rationale. Advances by a fixed [member step_usec] EVERY call regardless of
## real wall-clock time.
class _FakeClock:
	var value: int = 0
	var step_usec: int = 0

	func tick() -> int:
		value += step_usec
		return value


func _make_grid(world_size: int = 512) -> VoxelWorldGrid:
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


func _count_tracked(mesher: VoxelWorldMesher, keys: Array[Vector2i]) -> int:
	var count: int = 0
	for key: Vector2i in keys:
		if mesher.is_chunk_tracked(key):
			count += 1
	return count


# ---------------------------------------------------------------------------
# AC-1 (TR-voxel-world-025) -- view-window bound, decoupled from world size
# ---------------------------------------------------------------------------

func test_build_initial_window_meshes_only_the_view_window_not_the_full_world() -> void:
	# Arrange -- a world large enough that "the full world" and "the view
	# window" are wildly different chunk counts: 512 cells / 16 = 32 chunks
	# per axis = 1024 possible chunks; view_radius_chunks=1 -> 3x3=9 desired.
	var grid: VoxelWorldGrid = _make_grid(512)
	grid.config.view_radius_chunks = 1
	grid.config.boot_mesh_radius_chunks = 1  # Story vox-021: build_initial_window reads THIS, not view_radius_chunks -- match it, this test is about window-vs-world-size, not the boot/steady split
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	var streamer: VoxelWorldMeshStreamer = _make_streamer(grid, mesher)

	# Act -- centered well inside the world so the window is never clipped.
	streamer.build_initial_window(Vector3i(256, 0, 256))

	# Assert -- exactly the 3x3 window, nowhere near the 1024 possible chunks.
	assert_int(mesher.get_tracked_chunk_keys().size()).is_equal(9)


func test_get_desired_window_keys_matches_actually_built_chunks() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_grid(512)
	grid.config.view_radius_chunks = 2  # 5x5 = 25
	grid.config.boot_mesh_radius_chunks = 2  # Story vox-021: match view_radius_chunks so build_initial_window's window equals get_desired_window_keys' steady-state window, exactly this test's own point
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	var streamer: VoxelWorldMeshStreamer = _make_streamer(grid, mesher)
	var focus := Vector3i(256, 0, 256)

	# Act
	var desired: Array[Vector2i] = streamer.get_desired_window_keys(focus)
	streamer.build_initial_window(focus)

	# Assert -- the introspection helper's set matches reality exactly.
	assert_int(desired.size()).is_equal(25)
	assert_int(mesher.get_tracked_chunk_keys().size()).is_equal(25)
	assert_int(_count_tracked(mesher, desired)).is_equal(25)


func test_moving_camera_focus_builds_entering_chunks_and_unloads_leaving_chunks() -> void:
	# Arrange -- two NON-overlapping windows far apart in a large world.
	var grid: VoxelWorldGrid = _make_grid(2048)
	grid.config.view_radius_chunks = 1  # 3x3 = 9
	grid.config.boot_mesh_radius_chunks = 1  # Story vox-021: build_initial_window reads THIS, not view_radius_chunks
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	var streamer: VoxelWorldMeshStreamer = _make_streamer(grid, mesher)
	var focus_a := Vector3i(160, 0, 160)  # chunk (10, 10)
	var focus_b := Vector3i(1600, 0, 1600)  # chunk (100, 100) -- far from A's window

	# Act -- initial window at A (unbounded, proves entering-chunk build).
	streamer.build_initial_window(focus_a)
	var window_a: Array[Vector2i] = streamer.get_desired_window_keys(focus_a)
	assert_int(_count_tracked(mesher, window_a)).is_equal(9)

	# Act -- move to B, still unbounded (isolates membership from budgeting,
	# which the dedicated budget tests below cover separately).
	streamer.build_initial_window(focus_b)
	var window_b: Array[Vector2i] = streamer.get_desired_window_keys(focus_b)

	# Assert -- B's window is now fully built, and A's window was fully
	# unloaded (unbounded unload phase, same call).
	assert_int(_count_tracked(mesher, window_b)).is_equal(9)
	assert_int(_count_tracked(mesher, window_a)).is_equal(0)


func test_view_window_near_world_edge_excludes_out_of_bounds_chunk_keys() -> void:
	# Arrange -- a small world (64 cells / 16 = 4 chunks per axis, valid chunk
	# indices 0..3) and a focus at the world's origin corner, radius 2 (naive
	# 5x5=25 candidates, most of which fall outside bounds).
	var grid: VoxelWorldGrid = _make_grid(64)
	grid.config.view_radius_chunks = 2
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	var streamer: VoxelWorldMeshStreamer = _make_streamer(grid, mesher)

	# Act
	var desired: Array[Vector2i] = streamer.get_desired_window_keys(Vector3i(0, 0, 0))

	# Assert -- only chunk.x/z in [0, 2] survive the world-0..3 intersect
	# window-(-2..2) filter -> 3x3 = 9, and never negative.
	assert_int(desired.size()).is_equal(9)
	for key: Vector2i in desired:
		assert_bool(key.x >= 0 and key.y >= 0).is_true()


# ---------------------------------------------------------------------------
# Control Manifest Required pattern -- visibility_range_end, derived not
# hardcoded
# ---------------------------------------------------------------------------

func test_compute_visibility_range_end_is_derived_from_view_radius() -> void:
	# Pure static helper -- CHUNK_SIZE=16, CELL_SIZE=1.0.
	assert_float(VoxelWorldMeshStreamer.compute_visibility_range_end(4)).is_equal_approx(64.0, 0.0001)
	assert_float(VoxelWorldMeshStreamer.compute_visibility_range_end(24)).is_equal_approx(384.0, 0.0001)


func test_built_chunk_mesh_instance_gets_visibility_range_end_set() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_grid(512)
	grid.config.view_radius_chunks = 4
	grid.config.boot_mesh_radius_chunks = 4  # Story vox-021: match view_radius_chunks (harmless either way here -- the center chunk is built under any positive boot radius -- kept for consistency)
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	var streamer: VoxelWorldMeshStreamer = _make_streamer(grid, mesher)
	var focus := Vector3i(256, 0, 256)

	# Act
	streamer.build_initial_window(focus)

	# Assert -- the focus chunk's own mesh instance carries the derived value.
	var center_key: Vector2i = grid.chunk_key_for_cell(focus)
	var mesh_instance: MeshInstance3D = mesher.get_chunk_mesh_instance(center_key)
	assert_object(mesh_instance).is_not_null()
	assert_float(mesh_instance.visibility_range_end).is_equal_approx(64.0, 0.0001)


# ---------------------------------------------------------------------------
# AC-3 (TR-voxel-world-026) -- initial build ignores the budget entirely
# ---------------------------------------------------------------------------

func test_build_initial_window_ignores_budget_and_builds_entire_window_in_one_call() -> void:
	# Arrange -- a tiny configured budget and a fake clock whose simulated
	# per-item cost alone blows it many times over; the BUDGETED path would
	# only ever integrate the first item (progress guarantee) and defer the
	# rest. build_initial_window must build the WHOLE window regardless.
	var grid: VoxelWorldGrid = _make_grid(512)
	grid.config.view_radius_chunks = 1  # 3x3 = 9
	grid.config.boot_mesh_radius_chunks = 1  # Story vox-021: build_initial_window reads THIS, not view_radius_chunks
	grid.config.mesh_build_budget_ms = 4.0
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	var streamer: VoxelWorldMeshStreamer = _make_streamer(grid, mesher)
	var clock := _FakeClock.new()
	clock.step_usec = 100000  # 100 ms/item -- alone dwarfs the 4.0 ms budget
	streamer.set_time_source_for_test(Callable(clock, "tick"))

	# Act
	streamer.build_initial_window(Vector3i(256, 0, 256))

	# Assert -- all 9, not just the progress-guaranteed first one.
	assert_int(mesher.get_tracked_chunk_keys().size()).is_equal(9)


# ---------------------------------------------------------------------------
# AC-2 (TR-voxel-world-025) -- time-based, not count-based; both builds AND
# unloads
# ---------------------------------------------------------------------------

func test_update_view_window_build_dispatch_count_varies_with_simulated_per_item_cost_not_fixed() -> void:
	# Arrange -- the IDENTICAL desired window (view_radius_chunks=3 -> 7x7=49)
	# and IDENTICAL mesh_build_budget_ms (4.0 ms) for BOTH streamers below;
	# ONLY the fake clock's simulated per-item cost differs. A fixed
	# items-per-frame count could never explain two different results from
	# this identical setup.
	var focus := Vector3i(160, 0, 160)

	var grid_a: VoxelWorldGrid = _make_grid(1024)
	grid_a.config.view_radius_chunks = 3
	grid_a.config.boot_mesh_radius_chunks = 3  # Story vox-021: the "settle" build_initial_window call below now reads THIS, not view_radius_chunks -- match it so the settle target stays the same 7x7=49 window
	grid_a.config.mesh_build_budget_ms = 4.0
	var mesher_a: VoxelWorldMesher = _make_mesher(grid_a)
	var streamer_a: VoxelWorldMeshStreamer = _make_streamer(grid_a, mesher_a)
	var clock_a := _FakeClock.new()
	clock_a.step_usec = 1000  # 1 ms/item -> expect exactly 4 (4x1000=4000==budget)
	streamer_a.set_time_source_for_test(Callable(clock_a, "tick"))

	var grid_b: VoxelWorldGrid = _make_grid(1024)
	grid_b.config.view_radius_chunks = 3
	grid_b.config.boot_mesh_radius_chunks = 3  # Story vox-021: see grid_a's own matching comment above
	grid_b.config.mesh_build_budget_ms = 4.0
	var mesher_b: VoxelWorldMesher = _make_mesher(grid_b)
	var streamer_b: VoxelWorldMeshStreamer = _make_streamer(grid_b, mesher_b)
	var clock_b := _FakeClock.new()
	clock_b.step_usec = 2000  # 2 ms/item -> expect exactly 2
	streamer_b.set_time_source_for_test(Callable(clock_b, "tick"))

	# Act -- ONE update_view_window call each (the "one frame" the QA plan
	# describes).
	streamer_a.update_view_window(focus)
	streamer_b.update_view_window(focus)

	# Assert -- different processed counts from the IDENTICAL list/budget,
	# explained ONLY by the differing simulated per-item cost.
	assert_int(mesher_a.get_tracked_chunk_keys().size()).is_equal(4)
	assert_int(mesher_b.get_tracked_chunk_keys().size()).is_equal(2)

	# Settle -- proves nothing was lost, only deferred. Uses the UNBOUNDED
	# [method VoxelWorldMeshStreamer.build_initial_window] entry point rather
	# than looping budgeted [method VoxelWorldMeshStreamer.update_view_window]
	# calls an unknown number of times (real per-chunk build cost is not
	# microseconds-fast the way a single 4.0 ms budgeted call assumes --
	# looping budgeted calls would need an arbitrary retry guard; the
	# unbounded entry point settles deterministically in exactly one call).
	streamer_a.build_initial_window(focus)
	streamer_b.build_initial_window(focus)
	assert_int(mesher_a.get_tracked_chunk_keys().size()).is_equal(49)
	assert_int(mesher_b.get_tracked_chunk_keys().size()).is_equal(49)


func test_update_view_window_single_build_item_exceeding_budget_still_builds_then_stops() -> void:
	# Arrange -- progress guarantee: a single item whose own simulated cost
	# alone blows the budget is still integrated, then the loop stops.
	var grid: VoxelWorldGrid = _make_grid(512)
	grid.config.view_radius_chunks = 1  # 3x3 = 9
	grid.config.mesh_build_budget_ms = 4.0
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	var streamer: VoxelWorldMeshStreamer = _make_streamer(grid, mesher)
	var clock := _FakeClock.new()
	clock.step_usec = 10000  # 10 ms/item -- alone exceeds the 4.0 ms budget
	streamer.set_time_source_for_test(Callable(clock, "tick"))

	# Act
	streamer.update_view_window(Vector3i(256, 0, 256))

	# Assert -- exactly ONE processed, not zero, not all nine.
	assert_int(mesher.get_tracked_chunk_keys().size()).is_equal(1)


func test_update_view_window_unload_burst_bounded_per_call_and_settles_across_later_calls() -> void:
	# Arrange -- two NON-overlapping 5x5 (view_radius_chunks=2) windows far
	# apart, in a world large enough to hold both without clipping.
	var grid: VoxelWorldGrid = _make_grid(2048)
	grid.config.view_radius_chunks = 2  # 5x5 = 25
	grid.config.boot_mesh_radius_chunks = 2  # Story vox-021: the build_initial_window call below (A's setup phase) now reads THIS, not view_radius_chunks -- match it so A's window stays exactly 5x5=25
	grid.config.mesh_build_budget_ms = 1000.0  # generous -- never the limiter here
	grid.config.mesh_unload_budget_ms = 4.0  # 4000 us
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	var streamer: VoxelWorldMeshStreamer = _make_streamer(grid, mesher)
	var focus_a := Vector3i(160, 0, 160)  # chunk (10, 10)
	var focus_b := Vector3i(1600, 0, 1600)  # chunk (100, 100) -- far from A's window

	# Build A's window fully, with the real clock (setup phase, not the
	# behavior under test).
	streamer.build_initial_window(focus_a)
	var window_a: Array[Vector2i] = streamer.get_desired_window_keys(focus_a)
	assert_int(_count_tracked(mesher, window_a)).is_equal(25)  # sanity

	# Act -- frame 1: move to B under the fake clock (1 ms/item simulated).
	# Build phase processes all 25 new B chunks (budget 1000 ms, never trips).
	# Unload phase then gets its OWN fresh budget window and stops after
	# exactly 4 (4000 us / 1000 us per item) of A's 25 stale chunks.
	var clock := _FakeClock.new()
	clock.step_usec = 1000
	streamer.set_time_source_for_test(Callable(clock, "tick"))
	streamer.update_view_window(focus_b)

	# Assert -- checked immediately: B fully built, exactly 4 of A's 25
	# unloaded (21 still tracked, untouched) -- never the full 25-item burst
	# at once.
	var window_b: Array[Vector2i] = streamer.get_desired_window_keys(focus_b)
	assert_int(_count_tracked(mesher, window_b)).is_equal(25)
	assert_int(_count_tracked(mesher, window_a)).is_equal(25 - 4)

	# Act -- settle: switch back to the real clock and keep calling
	# update_view_window(focus_b) until A's window is fully drained -- proves
	# the deferred excess is fully processed across enough LATER calls, never
	# lost, and B's window is undisturbed throughout.
	streamer.set_time_source_for_test(Callable(Time, "get_ticks_usec"))
	var guard: int = 0
	while _count_tracked(mesher, window_a) > 0 and guard < 50:
		streamer.update_view_window(focus_b)
		guard += 1

	# Assert -- fully converged, nothing lost.
	assert_int(_count_tracked(mesher, window_a)).is_equal(0)
	assert_int(_count_tracked(mesher, window_b)).is_equal(25)
