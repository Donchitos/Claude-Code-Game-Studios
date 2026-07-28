## Story vox-016 headless residency tuning measurement (ADR-0015 carried
## tuning item C1; TR-voxel-world-053/-023, QA plan Config/Data smoke check).
## Measures, against the REAL production [VoxelWorldGrid]/[VoxelWorldConfig]/
## [method VoxelWorldGrid.update_residency] (never a reimplementation, never
## the throwaway `prototypes/storage-residency-spike/` code):
##
##  0. PER-CHUNK GENERATION COST, COMPUTE-ONLY -- calls the exact same
##     `static` pure functions [method VoxelWorldGrid._bg_regenerate_from_seed]
##     itself calls ([method VoxelWorldGrid._pure_terrain_noise], [method
##     VoxelWorldGrid._pure_terrain_height]) directly, replicating that
##     method's own loop body verbatim, timed with [method
##     Time.get_ticks_usec] -- the TRUE per-chunk compute cost, isolated from
##     [WorkerThreadPool] dispatch/thread-scheduling overhead and from Phase
##     1's own polling-loop floor (see Phase 1's doc comment). This is what
##     [member VoxelWorldConfig.max_chunk_generation_cost_ms]'s recorded bound
##     is actually measuring against -- the formula's own cost, since a
##     future change that adds noise octaves or tree stamping would move
##     THIS number, not Phase 1's floor-dominated one.
##  1. PER-CHUNK GENERATION COST, DISPATCH+POLL WALL TIME -- [constant
##     GEN_COST_SAMPLE_COUNT] distinct, never-before-touched chunks (a fresh,
##     empty region directory, so every sample takes the [method
##     VoxelWorldGrid._bg_regenerate_from_seed] regen branch, never a disk
##     read) are individually paged in via the real [method
##     VoxelWorldGrid.update_residency] dispatch + [method
##     VoxelWorldGrid.wait_for_async_residency_idle] completion cycle, each
##     timed dispatch-call-start to confirmed-resident
##     ([method Time.get_ticks_usec] wall clock spanning the real
##     [WorkerThreadPool] background task) -- a single-chunk desired window
##     (`view_radius_chunks = 0`, `settlement_radius_chunks = 0`) isolates
##     exactly one dispatch per sample. **Honest caveat**: [method
##     VoxelWorldGrid.wait_for_async_residency_idle]'s own spin-wait uses
##     `OS.delay_msec(1)` per poll -- this phase's numbers are floor-dominated
##     by that ~1-2 ms polling granularity, NOT the real regen compute cost
##     (Phase 0 measures that directly). Reported for completeness/honesty
##     (the vox-019 "VSync-floor" precedent: report the artifact, don't
##     silently omit it) but Phase 0, not this phase, backs the recorded
##     `max_chunk_generation_cost_ms` bound.
##  2. FULL-SPAN RESIDENCY WORST-FRAME -- a scripted straight-line corridor
##     traverse across a production-scale (2000x2000, the shipped
##     `world_width_cells`/`world_depth_cells` default) world extent, driving
##     [method VoxelWorldGrid.update_residency] once per simulated frame at
##     the game's REAL current max camera speed. **Honest speed derivation**:
##     [CameraInputConfig]'s own shipped `distance_max * pan_speed_factor` =
##     60.0 * 0.7 = 42.0 cells/sec (restated explicitly here per this
##     project's own "never rely on a default silently matching" convention)
##     -- NOT the ADR-0015 storage/residency spike's 144 cells/sec, which was
##     derived from an EARLIER prototype `camera_input.gd`'s now-superseded
##     constants (`PAN_SPEED_FACTOR 1.2` / `DISTANCE_MAX 120.0`), never the
##     shipped production `CameraInputConfig`. Repeated at BOTH candidate
##     `max_concurrent_async_tasks` values the ADR spike itself measured (32,
##     64), each its own fresh grid + region directory, so the two runs never
##     share dispatched-task state.
##
## Data-layer only (no mesh/streamer/rendering) -- runs HEADLESS:
##   Godot_v4.7-stable_win64_console.exe --headless --path neues-spiel
##     res://tools/vox016_residency_tuning_measurement.tscn
extends Node

## Production-scale world extent -- the shipped [VoxelWorldConfig] default
## (`world_width_cells`/`world_depth_cells` = 2000). Unlike
## `tools/vox018_60fps_culling_measurement.gd`'s own world-extent caveat
## (that tool's `generate_terrain()` eager bulk-fill hits a `Dictionary`
## resize/rehash cost cliff above ~900x900), THIS tool never calls
## [method VoxelWorldGrid.generate_terrain] at all -- residency's per-chunk
## regen-on-page-in is the ENTIRE mechanism under test, so the full 2000
## production default is usable directly with no scaling caveat.
const WORLD_EXTENT_CELLS := 2000
const WORLD_MAX_Y := 16
const CHUNK_SIZE := 16  # VoxelWorldGrid.CHUNK_SIZE, restated (see class doc convention)

## Shipped production defaults, restated explicitly (never silently relying
## on the class default) -- see `data/config/voxel_world_config.tres`.
const REGION_SIZE_CHUNKS := 32
const VIEW_RADIUS_CHUNKS := 24
const SETTLEMENT_RADIUS_CHUNKS := 8
const PAGE_BUDGET_MS := 4.0
const EVICT_BUDGET_MS := 4.0

## Candidate async concurrency caps under test (ADR-0015 spike's own two
## measured values) -- this story re-measures both against production code.
const ASYNC_CAPS_TO_TEST: Array[int] = [32, 64]

## The game's REAL current max camera speed, derived from the shipped
## [CameraInputConfig] defaults (`distance_max = 60.0`,
## `pan_speed_factor = 0.7`) via [method CameraInput.derive_pan_delta]'s own
## formula (`input_dir.normalized() * delta * distance * pan_speed_factor` --
## steady-state cells/sec = `distance * pan_speed_factor` at max zoom-out).
## See this file's own class doc comment for why this is NOT the ADR-0015
## spike's stale 144 cells/sec.
const REAL_MAX_CAMERA_SPEED_CELLS_PER_SEC := 42.0
const ASSUMED_FRAME_HZ := 60.0

## Full-span corridor endpoints with margin against world-edge chunk
## clipping -- crosses effectively the entire 2000-cell world width.
const CORRIDOR_X_MIN := 20
const CORRIDOR_X_MAX := WORLD_EXTENT_CELLS - 21
const CORRIDOR_Z := WORLD_EXTENT_CELLS / 2

## 3 one-way legs (1.5 full round trips) -- comfortably a "repeated
## full-span traverse" without an excessive headless run time (regen cost
## per chunk is measured separately and directly in Phase 1; this phase's
## own job is the worst-FRAME number, which converges quickly).
const NUM_PASSES := 3

## Phase 0/1 (per-chunk generation cost) sample count.
const GEN_COST_SAMPLE_COUNT := 40

## Deterministic seed for Phase 0's direct compute-only calls -- any [int] is
## valid (see [member VoxelWorldConfig.terrain_seed]'s own doc comment);
## restated explicitly rather than reading a config default, since Phase 0
## builds no [VoxelWorldConfig] at all.
const TERRAIN_SEED := 12345

## Frame-budget gate (QA plan / technical-preferences.md).
const FRAME_BUDGET_USEC := 16600

var _results: Dictionary = {}  # printed at the end, also written to a CSV-ish log


func _ready() -> void:
	print("vox016: ==== PHASE 0: per-chunk generation cost, COMPUTE-ONLY ====")
	var compute_only_stats: Dictionary = _measure_gen_cost_compute_only()
	_print_stats("gen_cost_compute_only_usec", compute_only_stats)

	print("vox016: ==== PHASE 1: per-chunk generation cost, dispatch+poll wall time ====")
	var gen_cost_stats: Dictionary = _measure_gen_cost()
	_print_stats("gen_cost_dispatch_poll_usec", gen_cost_stats)

	print("vox016: ==== PHASE 2: full-span traverse worst-frame, per async cap ====")
	for cap: int in ASYNC_CAPS_TO_TEST:
		print("vox016: ---- cap=%d ----" % cap)
		var traverse_stats: Dictionary = await _measure_traverse(cap)
		_print_stats("traverse_cap%d_frame_usec" % cap, traverse_stats)
		_results["cap%d" % cap] = traverse_stats

	print("vox016: ==== SUMMARY ====")
	print("vox016: gen_cost_compute_only p95=%.4f ms avg=%.4f ms worst=%.4f ms (n=%d)" % [
		compute_only_stats["p95"] / 1000.0, compute_only_stats["avg"] / 1000.0,
		compute_only_stats["worst"] / 1000.0, compute_only_stats["n"],
	])
	print("vox016: gen_cost_dispatch_poll (floor-caveated, see class doc) p95=%.4f ms avg=%.4f ms worst=%.4f ms (n=%d)" % [
		gen_cost_stats["p95"] / 1000.0, gen_cost_stats["avg"] / 1000.0,
		gen_cost_stats["worst"] / 1000.0, gen_cost_stats["n"],
	])
	for cap: int in ASYNC_CAPS_TO_TEST:
		var stats: Dictionary = _results["cap%d" % cap]
		var worst_ms: float = stats["worst"] / 1000.0
		var pass_str: String = "PASS" if stats["worst"] <= FRAME_BUDGET_USEC else "MISS"
		print("vox016: cap=%d worst_frame=%.4f ms avg=%.4f ms p95=%.4f ms budget=16.6ms %s" % [
			cap, worst_ms, stats["avg"] / 1000.0, stats["p95"] / 1000.0, pass_str,
		])

	get_tree().quit(0)


## Phase 0 -- TRUE per-chunk generation compute cost, isolated from any
## [WorkerThreadPool]/polling overhead. Replicates [method
## VoxelWorldGrid._bg_regenerate_from_seed]'s own loop body VERBATIM, calling
## the SAME `static` pure functions it calls
## ([method VoxelWorldGrid._pure_terrain_noise], [method
## VoxelWorldGrid._pure_terrain_height]) -- never a reimplementation of the
## noise/height formula itself, only the surrounding loop is duplicated here
## (unavoidable: [method VoxelWorldGrid._bg_regenerate_from_seed] is an
## instance method with no public direct-call wrapper, and dispatching it via
## [WorkerThreadPool] is exactly the overhead Phase 0 exists to exclude).
func _measure_gen_cost_compute_only() -> Dictionary:
	var noise: FastNoiseLite = VoxelWorldGrid._pure_terrain_noise(TERRAIN_SEED)
	var chunk_height: int = WORLD_MAX_Y + 1  # max_y - min_y + 1, min_y = 0
	var samples: Array = []

	for i in GEN_COST_SAMPLE_COUNT:
		var chunk_x: int = 1 + i * 2
		var chunk_z: int = 1 + i * 2
		var t0: int = Time.get_ticks_usec()
		var cell_count: int = CHUNK_SIZE * CHUNK_SIZE * chunk_height
		var block_type_ids := PackedByteArray()
		block_type_ids.resize(cell_count)
		var material_ids := PackedByteArray()
		material_ids.resize(cell_count)
		for local_z in CHUNK_SIZE:
			var global_z: int = chunk_z * CHUNK_SIZE + local_z
			for local_x in CHUNK_SIZE:
				var global_x: int = chunk_x * CHUNK_SIZE + local_x
				var height: int = VoxelWorldGrid._pure_terrain_height(
					global_x, global_z, noise, 4, 3.0, 0.05, 0, WORLD_MAX_Y
				)
				for y in range(0, height + 1):
					var offset: int = (y * CHUNK_SIZE + local_z) * CHUNK_SIZE + local_x
					block_type_ids[offset] = 1
					material_ids[offset] = 1
		var elapsed_usec: int = Time.get_ticks_usec() - t0
		samples.append(elapsed_usec)

	return _stats(samples)


## Phase 1 -- isolated per-chunk generation cost. Each sample uses a FRESH,
## never-touched chunk key (monotonically advancing across the world so no
## key repeats and no region file for it can possibly exist), a
## single-chunk desired window (`view_radius_chunks = 0`,
## `settlement_radius_chunks = 0`, camera and settlement anchor both pointed
## at the same one chunk) so exactly one dispatch happens per sample, timed
## dispatch-call-start to confirmed-resident.
func _measure_gen_cost() -> Dictionary:
	var region_dir: String = _make_temp_region_dir("gen_cost")
	var config := VoxelWorldConfig.new()
	config.world_width_cells = WORLD_EXTENT_CELLS
	config.world_depth_cells = WORLD_EXTENT_CELLS
	config.max_y = WORLD_MAX_Y
	config.region_directory = region_dir
	config.region_size_chunks = REGION_SIZE_CHUNKS
	config.view_radius_chunks = 0
	config.settlement_radius_chunks = 0
	config.max_concurrent_async_tasks = 1
	var grid := VoxelWorldGrid.new()
	add_child(grid)
	grid.config = config

	var samples: Array = []
	# Spread samples along a diagonal (spacing 2 chunks) so every sample is a
	# distinct, never-touched chunk key -- spacing chosen to stay well
	# within the 2000/16 = 125 chunks/axis world bound (max index used here:
	# 1 + 39*2 = 79 < 125), unlike a coarser spacing which would walk
	# straight out of the world and silently produce an empty (no-op)
	# desired window.
	for i in GEN_COST_SAMPLE_COUNT:
		var chunk_x: int = 1 + i * 2
		var chunk_z: int = 1 + i * 2
		var focus_cell := Vector3i(chunk_x * CHUNK_SIZE, 0, chunk_z * CHUNK_SIZE)
		var t0: int = Time.get_ticks_usec()
		grid.update_residency(focus_cell, focus_cell)
		grid.wait_for_async_residency_idle()
		var elapsed_usec: int = Time.get_ticks_usec() - t0
		samples.append(elapsed_usec)

	grid.queue_free()
	_remove_dir_recursive(region_dir)
	return _stats(samples)


## Phase 2 -- full-span corridor traverse at [constant
## REAL_MAX_CAMERA_SPEED_CELLS_PER_SEC], one [method
## VoxelWorldGrid.update_residency] call per simulated frame, worst/avg/p95
## call cost recorded ([method Time.get_ticks_usec] wall clock -- the real
## dispatch + budgeted-drain cost of that one call, exactly the production
## per-frame cost this call would have if wired into a live scene).
func _measure_traverse(async_cap: int) -> Dictionary:
	var region_dir: String = _make_temp_region_dir("traverse_cap%d" % async_cap)
	var config := VoxelWorldConfig.new()
	config.world_width_cells = WORLD_EXTENT_CELLS
	config.world_depth_cells = WORLD_EXTENT_CELLS
	config.max_y = WORLD_MAX_Y
	config.region_directory = region_dir
	config.region_size_chunks = REGION_SIZE_CHUNKS
	config.view_radius_chunks = VIEW_RADIUS_CHUNKS
	config.settlement_radius_chunks = SETTLEMENT_RADIUS_CHUNKS
	config.page_budget_ms = PAGE_BUDGET_MS
	config.evict_budget_ms = EVICT_BUDGET_MS
	config.max_concurrent_async_tasks = async_cap
	var grid := VoxelWorldGrid.new()
	add_child(grid)
	grid.config = config

	var settlement_anchor := Vector3i(WORLD_EXTENT_CELLS / 2, 0, WORLD_EXTENT_CELLS / 2)
	var cells_per_tick: float = REAL_MAX_CAMERA_SPEED_CELLS_PER_SEC / ASSUMED_FRAME_HZ
	var camera_x: float = float(CORRIDOR_X_MIN)
	var direction: float = 1.0
	var passes_done: int = 0
	var tick_index: int = 0
	var samples: Array = []

	while passes_done < NUM_PASSES:
		camera_x += direction * cells_per_tick
		if camera_x >= float(CORRIDOR_X_MAX):
			camera_x = float(CORRIDOR_X_MAX)
			direction = -1.0
			passes_done += 1
		elif camera_x <= float(CORRIDOR_X_MIN):
			camera_x = float(CORRIDOR_X_MIN)
			direction = 1.0
			passes_done += 1

		var camera_focus_cell := Vector3i(int(camera_x), 0, CORRIDOR_Z)
		var t0: int = Time.get_ticks_usec()
		grid.update_residency(camera_focus_cell, settlement_anchor)
		var elapsed_usec: int = Time.get_ticks_usec() - t0
		samples.append(elapsed_usec)
		tick_index += 1

		if tick_index % 5000 == 0:
			print("vox016: PROGRESS cap=%d tick=%d pass=%d/%d camera_x=%.0f resident=%d in_flight=%d" % [
				async_cap, tick_index, passes_done, NUM_PASSES, camera_x,
				grid.get_resident_chunk_keys().size(), grid.get_in_flight_async_task_count(),
			])

		await get_tree().process_frame

	grid.wait_for_async_residency_idle()
	grid.queue_free()
	_remove_dir_recursive(region_dir)
	return _stats(samples)


func _print_stats(label: String, stats: Dictionary) -> void:
	print("vox016: %s avg=%.1f p95=%.1f worst=%.1f (n=%d) [usec]" % [
		label, stats["avg"], stats["p95"], stats["worst"], stats["n"],
	])


## Sorted-array avg/p95/worst helper, mirroring
## `prototypes/storage-residency-spike/metrics.gd`'s own `stats` shape.
func _stats(samples: Array) -> Dictionary:
	if samples.is_empty():
		return {"avg": 0.0, "p95": 0.0, "worst": 0.0, "n": 0}
	var sorted_samples: Array = samples.duplicate()
	sorted_samples.sort()
	var total: float = 0.0
	for value in sorted_samples:
		total += float(value)
	var avg: float = total / sorted_samples.size()
	var p95_index: int = mini(int(sorted_samples.size() * 0.95), sorted_samples.size() - 1)
	return {
		"avg": avg,
		"p95": float(sorted_samples[p95_index]),
		"worst": float(sorted_samples[-1]),
		"n": sorted_samples.size(),
	}


## Isolated per-run region directory under `user://` -- never `res://`,
## never shared across runs/samples, removed immediately after use (same
## isolation discipline `tests/integration/voxel_world/async_region_io_test.gd`
## already established for GdUnit tests).
func _make_temp_region_dir(suffix: String) -> String:
	var dir_path: String = "user://vox016_measurement_regions/%s_%d" % [suffix, Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
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
