## Story vox-017 headless completion-driven residency drain measurement
## (ADR-0015 carried tuning item C4; TR-voxel-world-053, QA plan AC-2's own
## quantitative "cost scales with completions, not queue size" claim). Mirrors
## `tools/vox016_residency_tuning_measurement.gd`'s own precedent: measures
## against the REAL production [VoxelWorldGrid] (never a reimplementation) --
## specifically [method VoxelWorldGrid.update_residency]'s two completion-
## driven reap phases this story added/rewrote ([method
## VoxelWorldGrid._reap_finished_async_reads] / [method
## VoxelWorldGrid._reap_finished_async_writes]).
##
## Per this project's own QA determinism rule ("no timing assertions in
## tests -- measurement variance belongs in evidence"), the GdUnit automated
## test (`tests/integration/voxel_world/completion_driven_drain_test.gd`)
## proves AC-1's structural claim (grep: the reap loops never call
## [method WorkerThreadPool.is_task_completed]) and functional correctness
## (nothing lost/corrupted across a full settle) -- deterministic, no
## wall-clock dependence. THIS tool supplies the quantitative AC-2 evidence
## the test deliberately does not assert on: real background-task completion
## timing is inherently non-deterministic (depends on OS thread scheduling),
## so "does reap cost track completions rather than queue size" can only be
## HONESTLY measured, not asserted as a pass/fail unit test.
##
## Methodology -- for BOTH the write-reap and read-reap phase, at TWO very
## different initial in-flight queue sizes (20 and 200, a 10x range):
##  1. Dispatch the full queue in ONE `update_residency` call (cap == queue
##     size, so every item dispatches this same call -- never cap-limited).
##  2. Repeatedly call `update_residency` again with the SAME focus (nothing
##     NEW to dispatch -- desired window/eviction target unchanged), timing
##     each call and recording how many in-flight tasks that call's
##     completion-driven reap actually integrated (the delta in
##     `get_in_flight_async_task_count()`), until the queue fully drains.
##  3. Compare: if reap cost genuinely tracks COMPLETIONS (this story's own
##     claim) rather than QUEUE SIZE (the anti-pattern removed), the
##     per-call wall time distribution for queue size 200 must be
##     comparable to queue size 20's, despite the 10x difference in how much
##     backlog remains at any given call -- a poll-every-queued-item
##     implementation would instead show cost scaling with remaining queue
##     size (larger initial queue -> larger EARLY-call cost).
##
## Data-layer only (no mesh/streamer/rendering) -- runs HEADLESS:
##   Godot_v4.7-stable_win64_console.exe --headless --path neues-spiel
##   res://tools/vox017_completion_driven_drain_measurement.tscn
extends Node

## The two initial in-flight queue sizes compared -- a 10x range, chosen to
## make a queue-size-dependent cost (the anti-pattern this story removes)
## unmistakable if it were still present, while both stay small enough that a
## single dispatch call comfortably finishes inside a generous setup budget
## (see [member SETUP_BUDGET_MS]).
const QUEUE_SIZES_TO_TEST: Array[int] = [20, 200]

## Shipped-shape config, restated explicitly (never silently relying on a
## default) -- small world extent is fine here since this tool never engages
## `world_width_cells`/`world_depth_cells` at production scale (unlike
## vox016's own residency-worst-frame measurement); only the queue-size/
## completion-count relationship is under test, not absolute per-chunk cost.
const WORLD_EXTENT_CELLS := 512
const WORLD_MAX_Y := 16
const REGION_SIZE_CHUNKS := 8

## Generous ms budget used ONLY for the one-shot setup dispatch call (so every
## item in the queue actually dispatches this same call, never cap- or
## budget-limited) -- NOT the value under test; the reap-timing loop below
## reverts to the shipped-shape default (4.0 ms, restated in [member
## REAP_BUDGET_MS]) for the calls actually being measured.
const SETUP_BUDGET_MS := 200.0

## Shipped production default (`data/config/voxel_world_config.tres`),
## restated explicitly -- the budget in effect during every TIMED reap call
## below, so the measured numbers reflect real production behavior.
const REAP_BUDGET_MS := 4.0

## Bounded iteration cap for the reap-timing drain loop (mirrors [method
## VoxelWorldGrid.wait_for_async_residency_idle]'s own bounded-not-unbounded
## discipline) -- generous enough that every queue size tested fully drains
## in practice, but never an infinite spin if something regresses.
const MAX_REAP_CALLS := 2000

## Frame-budget gate (QA plan / technical-preferences.md) -- reported for
## honesty (this tool's own per-call reap times are expected far under this,
## unlike vox016's own full residency worst-frame, which this tool does not
## re-measure).
const FRAME_BUDGET_USEC := 16600


func _ready() -> void:
	print("vox017: ==== PHASE 1: WRITE-reap (eviction-flush) cost vs. queue size ====")
	var write_results: Dictionary = {}
	for queue_size: int in QUEUE_SIZES_TO_TEST:
		print("vox017: ---- write queue_size=%d ----" % queue_size)
		var stats: Dictionary = _measure_write_reap_scaling(queue_size)
		write_results[queue_size] = stats
		_print_reap_stats("write", queue_size, stats)

	print("vox017: ==== PHASE 2: READ-reap (page-in) cost vs. queue size ====")
	var read_results: Dictionary = {}
	for queue_size: int in QUEUE_SIZES_TO_TEST:
		print("vox017: ---- read queue_size=%d ----" % queue_size)
		var stats: Dictionary = _measure_read_reap_scaling(queue_size)
		read_results[queue_size] = stats
		_print_reap_stats("read", queue_size, stats)

	print("vox017: ==== SUMMARY (does reap-call cost track queue size, or completions?) ====")
	_print_scaling_summary("write", write_results)
	_print_scaling_summary("read", read_results)

	get_tree().quit(0)


## Phase 1 -- dispatches [param queue_size] eviction-flush tasks in ONE call
## (cap == queue_size, generous setup budget), then repeatedly calls [method
## VoxelWorldGrid.update_residency] with the SAME far/empty desired window
## (nothing new to evict -- every call after the first exercises ONLY the
## completion-driven [method VoxelWorldGrid._reap_finished_async_writes]
## phase), timing each call and recording how many in-flight tasks it
## actually reaped, until the queue fully drains or [constant MAX_REAP_CALLS]
## is reached.
func _measure_write_reap_scaling(queue_size: int) -> Dictionary:
	var region_dir: String = _make_temp_region_dir("write_q%d" % queue_size)
	var config := VoxelWorldConfig.new()
	config.world_width_cells = WORLD_EXTENT_CELLS
	config.world_depth_cells = WORLD_EXTENT_CELLS
	config.max_y = WORLD_MAX_Y
	config.region_directory = region_dir
	config.region_size_chunks = REGION_SIZE_CHUNKS
	config.view_radius_chunks = 0
	config.settlement_radius_chunks = 0
	config.max_concurrent_async_tasks = queue_size
	config.evict_budget_ms = SETUP_BUDGET_MS
	var grid := VoxelWorldGrid.new()
	add_child(grid)
	grid.config = config

	# Dirty `queue_size` distinct chunks along a diagonal (spacing 1 chunk --
	# queue_size stays well under 512/16 = 32 chunks/axis only for the small
	# queue; the 200-chunk case needs a wider spread, see below).
	var side: int = ceili(sqrt(float(queue_size)))
	var written: int = 0
	for gz in range(side):
		for gx in range(side):
			if written >= queue_size:
				break
			var cell := Vector3i(gx * VoxelWorldGrid.CHUNK_SIZE, 0, gz * VoxelWorldGrid.CHUNK_SIZE)
			grid.set_cell(cell, CellContents.new(3, 1))
			written += 1
		if written >= queue_size:
			break

	# One-shot setup dispatch: move residency far away so every dirtied chunk
	# becomes stale (outside the new desired window) AND dirty in this SAME
	# call -- an eviction burst, generous budget guarantees full dispatch.
	var far_focus := Vector3i(WORLD_EXTENT_CELLS - 1, 0, WORLD_EXTENT_CELLS - 1)
	grid.update_residency(far_focus, far_focus)
	var dispatched: int = grid.get_in_flight_async_task_count()

	# Revert to the shipped-shape budget for every TIMED call below.
	config.evict_budget_ms = REAP_BUDGET_MS

	var samples: Array = []
	var remaining_before_samples: Array = []
	var completions_samples: Array = []
	var call_count: int = 0
	while grid.get_in_flight_async_task_count() > 0 and call_count < MAX_REAP_CALLS:
		var remaining_before: int = grid.get_in_flight_async_task_count()
		var t0: int = Time.get_ticks_usec()
		grid.update_residency(far_focus, far_focus)
		var elapsed_usec: int = Time.get_ticks_usec() - t0
		var remaining_after: int = grid.get_in_flight_async_task_count()
		samples.append(elapsed_usec)
		remaining_before_samples.append(remaining_before)
		completions_samples.append(remaining_before - remaining_after)
		call_count += 1
		OS.delay_msec(1)

	grid.wait_for_async_residency_idle()
	grid.queue_free()
	_remove_dir_recursive(region_dir)

	var stats: Dictionary = _stats(samples)
	stats["dispatched"] = dispatched
	stats["calls"] = call_count
	stats["avg_completions_per_call"] = _avg(completions_samples)
	stats["max_remaining_seen"] = _max_int(remaining_before_samples)
	return stats


## Phase 2 -- read-side counterpart of [method _measure_write_reap_scaling]:
## dispatches [param queue_size] PRISTINE (regen-branch) page-in tasks in ONE
## call, then repeatedly calls [method VoxelWorldGrid.update_residency] with
## the SAME desired window (nothing new to dispatch -- every call after the
## first exercises ONLY the completion-driven [method
## VoxelWorldGrid._reap_finished_async_reads] phase), timing each call.
func _measure_read_reap_scaling(queue_size: int) -> Dictionary:
	var region_dir: String = _make_temp_region_dir("read_q%d" % queue_size)
	var config := VoxelWorldConfig.new()
	config.world_width_cells = WORLD_EXTENT_CELLS
	config.world_depth_cells = WORLD_EXTENT_CELLS
	config.max_y = WORLD_MAX_Y
	config.region_directory = region_dir
	config.region_size_chunks = REGION_SIZE_CHUNKS
	# view_radius_chunks sized so the desired window contains AT LEAST
	# queue_size distinct pristine chunks (a square window of side
	# 2*radius+1 -- solved for the smallest radius covering queue_size).
	var radius: int = ceili((sqrt(float(queue_size)) - 1.0) / 2.0)
	config.view_radius_chunks = maxi(radius, 0)
	config.settlement_radius_chunks = 0
	config.max_concurrent_async_tasks = queue_size
	config.page_budget_ms = SETUP_BUDGET_MS
	var grid := VoxelWorldGrid.new()
	add_child(grid)
	grid.config = config

	var camera_focus := Vector3i(WORLD_EXTENT_CELLS / 2, 0, WORLD_EXTENT_CELLS / 2)
	grid.update_residency(camera_focus, camera_focus)
	var dispatched: int = grid.get_in_flight_async_task_count()

	config.page_budget_ms = REAP_BUDGET_MS

	var samples: Array = []
	var remaining_before_samples: Array = []
	var completions_samples: Array = []
	var call_count: int = 0
	while grid.get_in_flight_async_task_count() > 0 and call_count < MAX_REAP_CALLS:
		var remaining_before: int = grid.get_in_flight_async_task_count()
		var t0: int = Time.get_ticks_usec()
		grid.update_residency(camera_focus, camera_focus)
		var elapsed_usec: int = Time.get_ticks_usec() - t0
		var remaining_after: int = grid.get_in_flight_async_task_count()
		samples.append(elapsed_usec)
		remaining_before_samples.append(remaining_before)
		completions_samples.append(remaining_before - remaining_after)
		call_count += 1
		OS.delay_msec(1)

	grid.wait_for_async_residency_idle()
	grid.queue_free()
	_remove_dir_recursive(region_dir)

	var stats: Dictionary = _stats(samples)
	stats["dispatched"] = dispatched
	stats["calls"] = call_count
	stats["avg_completions_per_call"] = _avg(completions_samples)
	stats["max_remaining_seen"] = _max_int(remaining_before_samples)
	return stats


func _print_reap_stats(label: String, queue_size: int, stats: Dictionary) -> void:
	print("vox017: %s queue_size=%d dispatched=%d calls=%d avg_completions/call=%.2f avg=%.1f p95=%.1f worst=%.1f (n=%d) [usec]" % [
		label, queue_size, stats["dispatched"], stats["calls"], stats["avg_completions_per_call"],
		stats["avg"], stats["p95"], stats["worst"], stats["n"],
	])


func _print_scaling_summary(label: String, results: Dictionary) -> void:
	var small_queue: int = QUEUE_SIZES_TO_TEST[0]
	var large_queue: int = QUEUE_SIZES_TO_TEST[1]
	var small_stats: Dictionary = results[small_queue]
	var large_stats: Dictionary = results[large_queue]
	print("vox017: %s -- queue %d: avg=%.1f us worst=%.1f us | queue %d: avg=%.1f us worst=%.1f us | ratio worst(large/small)=%.2fx (queue-size ratio=%.0fx)" % [
		label, small_queue, small_stats["avg"], small_stats["worst"],
		large_queue, large_stats["avg"], large_stats["worst"],
		large_stats["worst"] / maxf(small_stats["worst"], 1.0),
		float(large_queue) / float(small_queue),
	])


func _avg(samples: Array) -> float:
	if samples.is_empty():
		return 0.0
	var total: float = 0.0
	for value in samples:
		total += float(value)
	return total / samples.size()


func _max_int(samples: Array) -> int:
	var m: int = 0
	for value: int in samples:
		m = maxi(m, value)
	return m


## Sorted-array avg/p95/worst helper, mirroring `tools/vox016_residency_tuning_measurement.gd`'s
## own `_stats` helper verbatim.
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


## Isolated per-run region directory under `user://`, mirroring
## `tools/vox016_residency_tuning_measurement.gd`'s own isolation discipline.
func _make_temp_region_dir(suffix: String) -> String:
	var dir_path: String = "user://vox017_measurement_regions/%s_%d" % [suffix, Time.get_ticks_usec()]
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
