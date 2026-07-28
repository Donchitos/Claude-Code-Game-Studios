# Residency manager — throwaway prototype code (ADR-0015 storage/residency
# spike).
#
# Implements ADR-0015 Decision:
#   §1 resident set = camera-near window (square, ADR-0014 view radius) UNION
#      active-settlement (always-resident anchor, ADR-0007 nav-region scale)
#   §2 region files (fixed chunk-group binary files) — see region_file.gd
#   §3 load-before-write for far-world mutations (set_cell)
#   §4 save = flush of dirty region files (flush_all)
#   §5 pristine (unmutated) chunks regenerate from seed, never read from disk
#
# Eviction policy: distance/membership based, not true LRU (see round 1
# notes in README). A chunk is queued for eviction the instant it leaves
# BOTH the camera window and the settlement set; dropped from the queue if
# it re-enters need before its turn comes up.
#
# ROUND 3 REVISION (user decision: tune until clean, 5/5 required):
#   Lever 1: NO synchronous main-thread regen/read fallback in the per-frame
#            streaming path AT ALL anymore. A chunk whose async task hasn't
#            finished (or couldn't even be dispatched — pool at capacity)
#            simply stays queued for a later frame. "Deferred" is fine;
#            "15-17ms on the main thread" was the actual C1 killer.
#   Lever 2: eviction flushes (disk WRITES) now ALSO go through the same
#            capped background-task pool as page-in reads — never on the
#            main thread. A dirty chunk that can't get a write slot this
#            frame stays resident (safe) and retries next frame.
#   Lever 3: the drain loops re-check the time budget after EVERY item
#            (dispatch attempt or integration), so a burst of many
#            ready-to-integrate items in one frame still can't blow the
#            per-frame budget — excess integration is deferred, not done.
#   Lever 4: NOT implemented unless levers 1-3 leave a criterion still
#            failing (see README "Round 3" for the measured outcome).
class_name ResidencyManager
extends RefCounted

const RegionFileScript := preload("res://region_file.gd")
const TerrainGenScript := preload("res://terrain_gen.gd")

const CHUNK := 16
const CHUNKS_PER_AXIS := 1000   # 16000 / 16
const REGION_SIZE_CHUNKS := 32
const CHUNK_BYTES := 16 * 16 * 32

var view_radius_chunks: int
var settlement_radius_chunks: int
var settlement_anchor: Vector2i
var page_budget_ms: float
var evict_budget_ms: float
var region_dir: String
var use_async_io := true
var max_concurrent_async_tasks := 32   # ROUND 3: tunable — measured at 32 and 64, see README

var terrain := TerrainGenScript.new()

var _resident: Dictionary = {}          # Vector2i chunk -> PackedByteArray
var _dirty: Dictionary = {}             # Vector2i chunk -> true
var _regions: Dictionary = {}           # Vector2i region -> SpikeRegionFile
var _settlement_set: Dictionary = {}    # Vector2i chunk -> true (always resident)
var _camera_window_set: Dictionary = {} # Vector2i chunk -> true (current camera window)
var _page_in_queue: Array[Vector2i] = []
var _page_in_queued: Dictionary = {}
var _evict_queue: Array[Vector2i] = []
var _evict_queued: Dictionary = {}
var _last_camera_chunk := Vector2i(-999999, -999999)

# ROUND 3 async plumbing. Reads and writes share ONE concurrency budget
# (max_concurrent_async_tasks) — lever 2's "same capped pool."
var _read_tasks: Dictionary = {}           # Vector2i -> WorkerThreadPool task id (in-flight page-in)
var _read_results: Dictionary = {}         # Vector2i -> {data, was_load} — mutex-guarded, completed but not yet integrated
var _write_tasks: Dictionary = {}          # Vector2i -> WorkerThreadPool task id (in-flight eviction flush)
var _write_in_flight_data: Dictionary = {} # Vector2i -> PackedByteArray — authoritative bytes while a write is in flight;
                                            # doubles as a read-through cache so a chunk needed again before its own
                                            # flush finishes is served from memory, never from a possibly-still-being-written file.
var _task_mutex := Mutex.new()

# metrics (cumulative across this manager's lifetime)
var page_in_count := 0
var regen_count := 0
var load_count := 0
var evict_count := 0
var flush_count := 0
var header_io_usec_total := 0   # the one documented remaining sync-disk-touch exception — see region_file.gd
var deferred_pagein_events := 0 # ROUND 3 diagnostic: a wanted chunk wasn't ready this frame (no sync fallback anymore)
var deferred_evict_events := 0  # ROUND 3 diagnostic: a dirty chunk couldn't get a write slot this frame
var last_scan_usec := 0
var last_pagein_usec := 0
var last_evict_usec := 0


func setup(region_directory: String, p_view_radius_chunks: int, p_settlement_radius_chunks: int,
		p_settlement_anchor: Vector2i, p_page_budget_ms: float, p_evict_budget_ms: float,
		p_use_async_io: bool = true, p_max_concurrent_async_tasks: int = 32) -> void:
	region_dir = region_directory
	view_radius_chunks = p_view_radius_chunks
	settlement_radius_chunks = p_settlement_radius_chunks
	settlement_anchor = p_settlement_anchor
	page_budget_ms = p_page_budget_ms
	evict_budget_ms = p_evict_budget_ms
	use_async_io = p_use_async_io
	max_concurrent_async_tasks = p_max_concurrent_async_tasks
	DirAccess.make_dir_recursive_absolute(region_dir)
	for dz in range(-settlement_radius_chunks, settlement_radius_chunks + 1):
		for dx in range(-settlement_radius_chunks, settlement_radius_chunks + 1):
			var cc := settlement_anchor + Vector2i(dx, dz)
			if _in_world(cc):
				_settlement_set[cc] = true
	# The bounded settlement-core is a standing BOOT-TIME cost, not a
	# streaming one (ADR-0007's nav region is always live) — loaded here,
	# synchronously, once. This is the one remaining synchronous
	# _ensure_resident_sync() caller outside the C3/C5 test harness; it
	# never recurs per-frame, so it's outside what C1 measures.
	for cc: Vector2i in _settlement_set:
		_ensure_resident_sync(cc)


func _in_world(cc: Vector2i) -> bool:
	return cc.x >= 0 and cc.y >= 0 and cc.x < CHUNKS_PER_AXIS and cc.y < CHUNKS_PER_AXIS


func _region_of(cc: Vector2i) -> Vector2i:
	return Vector2i(cc.x / REGION_SIZE_CHUNKS, cc.y / REGION_SIZE_CHUNKS)


func _slot_of(cc: Vector2i, region: Vector2i) -> int:
	var local := cc - region * REGION_SIZE_CHUNKS
	return local.y * REGION_SIZE_CHUNKS + local.x


func _region_file(region: Vector2i) -> SpikeRegionFile:
	if _regions.has(region):
		return _regions[region]
	var path := "%s/r_%d_%d.bin" % [region_dir, region.x, region.y]
	var rf := RegionFileScript.new(path)
	_regions[region] = rf
	return rf


# ============================================================================
# SYNCHRONOUS path — boot-time settlement load + C3/C5 test-harness ONLY.
# NEVER called from update()'s per-frame streaming path (levers 1/2).
# ============================================================================

func _ensure_resident_sync(cc: Vector2i) -> void:
	if _resident.has(cc):
		return
	page_in_count += 1
	if _write_in_flight_data.has(cc):
		_resident[cc] = _write_in_flight_data[cc]
		return
	var region := _region_of(cc)
	var rf := _region_file(region)
	var slot := _slot_of(cc, region)
	if rf.has_chunk(slot):
		_resident[cc] = rf.read_chunk(slot)
		load_count += 1
	else:
		_resident[cc] = terrain.fill_chunk(cc)
		regen_count += 1


func _evict_sync(cc: Vector2i) -> void:
	if not _resident.has(cc):
		return
	if _dirty.has(cc):
		var region := _region_of(cc)
		var rf := _region_file(region)
		var slot := _slot_of(cc, region)
		rf.write_chunk(slot, _resident[cc])
		_dirty.erase(cc)
		flush_count += 1
	_resident.erase(cc)
	evict_count += 1


## Load-before-write (ADR-0015 §3). In the travel loop this always targets
## the camera's OWN current chunk (already resident by construction), so it
## never actually triggers a fallback regen/read; kept synchronous because
## it's also the direct-call path C3/C5 use as their test harness.
func set_cell(cell: Vector3i, value: int) -> void:
	var cc := Vector2i(cell.x / CHUNK, cell.z / CHUNK)
	_ensure_resident_sync(cc)
	var lx := cell.x - cc.x * CHUNK
	var lz := cell.z - cc.y * CHUNK
	var arr: PackedByteArray = _resident[cc]
	arr[(cell.y * CHUNK + lz) * CHUNK + lx] = value
	_dirty[cc] = true


func get_cell(cell: Vector3i) -> int:
	var cc := Vector2i(cell.x / CHUNK, cell.z / CHUNK)
	if not _resident.has(cc):
		return -1
	var lx := cell.x - cc.x * CHUNK
	var lz := cell.z - cc.y * CHUNK
	var arr: PackedByteArray = _resident[cc]
	return arr[(cell.y * CHUNK + lz) * CHUNK + lx]


func debug_read_chunk(cc: Vector2i) -> PackedByteArray:
	_ensure_resident_sync(cc)
	return _resident[cc]


func debug_evict_chunk(cc: Vector2i) -> void:
	_evict_sync(cc)


func is_resident(cc: Vector2i) -> bool:
	return _resident.has(cc)


func resident_count() -> int:
	return _resident.size()


# ============================================================================
# ASYNC plumbing (lever 1 + lever 2) — the ONLY path update() uses.
# ============================================================================

func _in_flight_count() -> int:
	return _read_tasks.size() + _write_tasks.size()


## Best-effort: dispatches a background page-in task if capacity allows.
## Returns true if the chunk is now either already resident, already has a
## task in flight, or was just dispatched — false only if the pool is full
## (caller must simply wait and retry later, never fall back to sync).
func _try_dispatch_read(cc: Vector2i) -> bool:
	if _resident.has(cc) or _read_tasks.has(cc) or _write_in_flight_data.has(cc):
		return true
	if _in_flight_count() >= max_concurrent_async_tasks:
		return false
	var region := _region_of(cc)
	var rf: SpikeRegionFile = _region_file(region)
	var slot := _slot_of(cc, region)
	var t_hdr := Time.get_ticks_usec()
	var present: bool = rf.has_chunk(slot)   # _ensure_header() — one-time-per-region sync read, tracked below
	header_io_usec_total += Time.get_ticks_usec() - t_hdr
	var offset: int = rf.offset_of(slot) if present else 0
	var path := rf.path
	var task_id := WorkerThreadPool.add_task(Callable(self, "_bg_read").bind(cc, present, path, offset))
	_read_tasks[cc] = task_id
	return true


## Background thread. NOTE: WorkerThreadPool.wait_for_task_completion()
## returns an Error code, not the Callable's return value (verified
## empirically against 4.7 in round 2 — see README). The task therefore
## writes its result into a mutex-guarded dictionary itself.
func _bg_read(cc: Vector2i, present: bool, path: String, offset: int) -> void:
	var data: PackedByteArray
	var was_load: bool
	if present:
		var f := FileAccess.open(path, FileAccess.READ)
		f.seek(offset)
		data = f.get_buffer(CHUNK_BYTES)
		f.close()
		was_load = true
	else:
		var bg_terrain := TerrainGenScript.new()   # own instance — never shares state across threads
		data = bg_terrain.fill_chunk(cc)
		was_load = false
	_task_mutex.lock()
	_read_results[cc] = {"data": data, "was_load": was_load}
	_task_mutex.unlock()


## Non-blocking: true if cc is (now) resident. Never waits for a task that
## isn't finished — that's the whole point of lever 1.
func _try_integrate_read(cc: Vector2i) -> bool:
	if _resident.has(cc):
		return true
	if _write_in_flight_data.has(cc):
		_resident[cc] = _write_in_flight_data[cc]   # free integration — already have the authoritative bytes
		page_in_count += 1
		return true
	if not _read_tasks.has(cc):
		return false
	var task_id: int = _read_tasks[cc]
	if not WorkerThreadPool.is_task_completed(task_id):
		return false
	WorkerThreadPool.wait_for_task_completion(task_id)   # instant — already complete, just joins/frees it
	_read_tasks.erase(cc)
	_task_mutex.lock()
	var result: Dictionary = _read_results[cc]
	_read_results.erase(cc)
	_task_mutex.unlock()
	page_in_count += 1
	if result["was_load"]:
		load_count += 1
	else:
		regen_count += 1
	_resident[cc] = result["data"]
	return true


## Best-effort dispatch of an eviction flush. Returns true if dispatched
## (caller may then safely free the resident slot — the data lives on in
## _write_in_flight_data until the background write finishes), false if
## the pool is full (caller must keep the chunk resident and retry later).
func _try_dispatch_write(cc: Vector2i, data: PackedByteArray) -> bool:
	if _write_tasks.has(cc):
		return true
	if _in_flight_count() >= max_concurrent_async_tasks:
		return false
	var region := _region_of(cc)
	var rf: SpikeRegionFile = _region_file(region)
	var slot := _slot_of(cc, region)
	var t_hdr := Time.get_ticks_usec()
	var offset := rf.reserve_offset_for_write(slot)   # main-thread bookkeeping (+ one-time region creation) — tracked below
	header_io_usec_total += Time.get_ticks_usec() - t_hdr
	var path := rf.path
	_write_in_flight_data[cc] = data
	var task_id := WorkerThreadPool.add_task(Callable(self, "_bg_write").bind(path, slot, offset, data))
	_write_tasks[cc] = task_id
	return true


## Background thread: pure disk I/O against a pre-reserved offset — no
## shared mutable state touched (the offset table update already happened
## on the main thread in reserve_offset_for_write()).
func _bg_write(path: String, slot: int, offset: int, data: PackedByteArray) -> void:
	var f := FileAccess.open(path, FileAccess.READ_WRITE)
	f.seek(offset)
	f.store_buffer(data)
	f.seek(slot * 8)
	f.store_64(offset)
	f.close()


## Non-blocking cleanup: joins any finished write tasks (frees the pool
## slot, drops the read-through cache — the data is now durably on disk).
func _reap_finished_writes() -> void:
	if _write_tasks.is_empty():
		return
	var done: Array[Vector2i] = []
	for cc: Vector2i in _write_tasks:
		if WorkerThreadPool.is_task_completed(_write_tasks[cc]):
			done.append(cc)
	for cc: Vector2i in done:
		WorkerThreadPool.wait_for_task_completion(_write_tasks[cc])
		_write_tasks.erase(cc)
		_write_in_flight_data.erase(cc)
		flush_count += 1


# ============================================================================
# Per-frame streaming path — the ONLY thing update() drives.
# ============================================================================

## Recomputes the desired camera window ONLY when the camera crosses a
## chunk boundary, then drains the page-in and eviction queues, each under
## its OWN time budget (lever 3: the budget check happens after every
## single item, so a burst of ready work in one frame still can't exceed
## it — the remainder is simply deferred to next frame, never processed by
## blowing the budget).
func update(camera_chunk: Vector2i) -> Dictionary:
	var t_scan := Time.get_ticks_usec()
	if camera_chunk != _last_camera_chunk:
		_rescan_window(camera_chunk)
		_last_camera_chunk = camera_chunk
	last_scan_usec = Time.get_ticks_usec() - t_scan

	_reap_finished_writes()   # cheap, non-blocking bookkeeping — never touches disk itself

	var t_page := Time.get_ticks_usec()
	var page_deadline := t_page + int(page_budget_ms * 1000.0)
	var page_remaining: Array[Vector2i] = []
	var i := 0
	while i < _page_in_queue.size():
		if Time.get_ticks_usec() >= page_deadline:
			for j in range(i, _page_in_queue.size()):
				page_remaining.append(_page_in_queue[j])
			break
		var cc: Vector2i = _page_in_queue[i]
		i += 1
		if not (_camera_window_set.has(cc) or _settlement_set.has(cc)):
			_page_in_queued.erase(cc)   # stale — no longer wanted; any in-flight task is left to finish and its
			continue                     # result is simply never collected (small, bounded, accepted leak — see README)
		if _try_integrate_read(cc):
			_page_in_queued.erase(cc)
			continue
		_try_dispatch_read(cc)   # best-effort — may still fail if the pool filled up since enqueue; harmless either way
		deferred_pagein_events += 1
		page_remaining.append(cc)
	_page_in_queue = page_remaining
	last_pagein_usec = Time.get_ticks_usec() - t_page

	var t_evict := Time.get_ticks_usec()
	var evict_deadline := t_evict + int(evict_budget_ms * 1000.0)
	var evict_remaining: Array[Vector2i] = []
	var k := 0
	while k < _evict_queue.size():
		if Time.get_ticks_usec() >= evict_deadline:
			for j in range(k, _evict_queue.size()):
				evict_remaining.append(_evict_queue[j])
			break
		var cc: Vector2i = _evict_queue[k]
		k += 1
		if _camera_window_set.has(cc) or _settlement_set.has(cc):
			_evict_queued.erase(cc)   # re-needed before its turn came up — drop from the evict queue
			continue
		if not _resident.has(cc):
			_evict_queued.erase(cc)
			continue
		if not _dirty.has(cc):
			_resident.erase(cc)   # clean — free to drop, no I/O needed at all
			evict_count += 1
			_evict_queued.erase(cc)
			continue
		if _try_dispatch_write(cc, _resident[cc]):
			_resident.erase(cc)   # safe — _write_in_flight_data holds the authoritative bytes until the flush lands
			_dirty.erase(cc)
			evict_count += 1
			_evict_queued.erase(cc)
		else:
			deferred_evict_events += 1
			evict_remaining.append(cc)   # pool full — stays resident (safe), retried next frame
	_evict_queue = evict_remaining
	last_evict_usec = Time.get_ticks_usec() - t_evict

	return {
		"scan_usec": last_scan_usec,
		"pagein_usec": last_pagein_usec,
		"evict_usec": last_evict_usec,
		"io_usec": 0,     # ROUND 3: by construction, always 0 on the main thread now — see header_io_usec_total for the one accepted exception
		"regen_usec": 0,  # ROUND 3: same — all regen now happens in _bg_read on a background thread
	}


func _rescan_window(camera_chunk: Vector2i) -> void:
	var new_window: Dictionary = {}
	for dz in range(-view_radius_chunks, view_radius_chunks + 1):
		for dx in range(-view_radius_chunks, view_radius_chunks + 1):
			var cc := camera_chunk + Vector2i(dx, dz)
			if _in_world(cc):
				new_window[cc] = true
	for cc: Vector2i in new_window:
		if not _camera_window_set.has(cc) and not _resident.has(cc) and not _page_in_queued.has(cc):
			_page_in_queue.append(cc)
			_page_in_queued[cc] = true
			if use_async_io:
				_try_dispatch_read(cc)   # best-effort prefetch at first sight — update()'s drain loop retries if this fails (pool full)
	for cc: Vector2i in _camera_window_set:
		if not new_window.has(cc) and not _settlement_set.has(cc) and not _evict_queued.has(cc):
			_evict_queue.append(cc)
			_evict_queued[cc] = true
	_camera_window_set = new_window


## Flushes every currently-dirty resident chunk to its region file
## SYNCHRONOUSLY and WAITS for durability before returning — this is an
## explicit, infrequent "save" action (not a per-frame path), so blocking
## here is correct and necessary: C5's "restart and reload" simulation must
## never race an in-flight async write.
func flush_all() -> void:
	for cc: Vector2i in _dirty.keys():
		var region := _region_of(cc)
		var rf := _region_file(region)
		var slot := _slot_of(cc, region)
		rf.write_chunk(slot, _resident[cc])
		flush_count += 1
	_dirty.clear()
	# Also wait out any in-flight ASYNC writes from prior eviction activity —
	# a save must be durable against those too before a "restart" is valid.
	var pending_ccs: Array[Vector2i] = []
	for cc: Vector2i in _write_tasks:
		pending_ccs.append(cc)
	for cc: Vector2i in pending_ccs:
		WorkerThreadPool.wait_for_task_completion(_write_tasks[cc])
		_write_tasks.erase(cc)
		_write_in_flight_data.erase(cc)
		flush_count += 1
