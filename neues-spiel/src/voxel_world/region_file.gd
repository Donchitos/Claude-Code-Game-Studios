## On-disk region file (Story vox-010, ADR-0015 Decision §2/§6) -- one file
## per fixed [member VoxelWorldConfig.region_size_chunks] x
## [member VoxelWorldConfig.region_size_chunks] block of chunk columns.
##
## Format: a fixed header of `slots_per_region` int64 byte offsets (`0` ==
## chunk absent -- pristine/regenerable, ADR-0015 Decision §5 -- never
## written), followed by fixed-size `chunk_payload_bytes` chunk payloads,
## appended in first-write order and overwritten IN PLACE on a later mutation
## of the same chunk (every payload is the same fixed size, so no reflow is
## ever needed). A region that never has a dirty chunk never gets a file on
## disk at all (Decision §5) -- [method _ensure_header] never creates the
## file itself; only [method reserve_offset_for_write] does, on its own first
## call for that region.
##
## Per-region header I/O ([method _ensure_header]) is the ONE sanctioned
## synchronous disk operation in Voxel World's residency tier (ADR-0015
## Decision §6) -- it runs exactly once per instance (guarded by [member
## _header_loaded]), never per-tick; [member header_load_count] exists purely
## so a test can observe that guarantee directly (TR-voxel-world-053, story
## vox-010 QA plan AC-3).
##
## Story vox-011 (this revision, ADR-0015 Decision §6) splits every remaining
## PAYLOAD I/O operation off the main thread: this class now only performs
## main-thread BOOKKEEPING -- [method has_chunk] / [method offset_of] (pure
## in-memory lookups past the one-time header load) and [method
## reserve_offset_for_write] (allocates a slot's byte offset and creates the
## region's blank header file on first touch, still a one-time-per-region
## synchronous cost, never a per-chunk one). The actual chunk-payload bytes
## are read/written by the `static` [method read_payload_at] / [method
## write_payload_at] -- pure functions that open their OWN [FileAccess]
## handle and touch no instance state, so they are safe to call from a
## background [WorkerThreadPool] task ([VoxelWorldGrid]'s `_bg_*` methods).
## Splitting "reserve the offset" (must never race -- two concurrent
## dispatches must never allocate the same append offset) from "write the
## bytes" (safe to do concurrently once each writer has its own offset) is
## what lets the slow part run off-thread without a race. There is
## deliberately no instance-level synchronous full read/write method left in
## this class anymore -- that was the exact temptation-to-a-sync-fallback
## ADR-0015 Decision §6 calls "the failure mode."
##
## `RefCounted`, not `Resource` -- an internal storage-tier handle, never
## authored/serialized/shared as project data. Unlike this directory's other
## `RefCounted` value objects ([CellContents], [CellChangeRecord], etc.) this
## one is intentionally stateful/mutable and long-lived: [VoxelWorldGrid]
## caches exactly one instance per region for its own lifetime so the header
## is never re-read.
##
## Reference-only note: `prototypes/storage-residency-spike/region_file.gd`
## validated this exact format (header + fixed-size appended payloads, via
## `store_buffer`/`get_buffer`) at 5/5 spike criteria, including this same
## main-thread-reserve / background-write split (its own `reserve_offset_for_write`
## doc comment); this file is written fresh against that measured design, not
## copied from it (per this story's Engine Notes).
class_name VoxelWorldRegionFile
extends RefCounted

## Byte width of one header offset entry (`FileAccess.store_64`/`get_64`).
const HEADER_ENTRY_BYTES: int = 8

## This region's on-disk (or not-yet-created) file path.
var path: String

## Number of chunk slots in this region (`region_size_chunks^2`) -- the
## caller computes and passes this in; this class has no knowledge of chunk-
## coordinate geometry itself.
var slots_per_region: int

## Fixed serialized byte length of one chunk's payload -- constant for a
## given [VoxelWorldConfig] (depends only on that config's chunk cell count),
## passed in by the caller ([method VoxelWorldGrid._chunk_payload_bytes]).
var chunk_payload_bytes: int

## Incremented exactly once per [method _ensure_header] call that actually
## runs past its cache guard (never on a repeat call) -- the test-observable
## proof that header I/O happens exactly once per region (TR-voxel-world-053,
## story QA plan AC-3).
var header_load_count: int = 0

## Per-slot byte offset into this region's file body; `0` means "absent"
## (pristine/regenerable). Populated by [method _ensure_header].
var _offsets: PackedInt64Array = PackedInt64Array()

## True once [method _ensure_header] has run for this instance.
var _header_loaded: bool = false

## Next unused append offset in this region's file body -- starts right after
## the header, advances by [member chunk_payload_bytes] each time a
## previously-absent slot is reserved for the first time.
var _next_append_offset: int = 0


func _init(p_path: String, p_slots_per_region: int, p_chunk_payload_bytes: int) -> void:
	path = p_path
	slots_per_region = p_slots_per_region
	chunk_payload_bytes = p_chunk_payload_bytes


## True if [param slot] holds a persisted chunk payload (a non-zero header
## offset) -- false for a pristine/never-mutated slot. Triggers [method
## _ensure_header] (a no-op past the first call). Main-thread only (pure
## in-memory lookup past the one-time header load).
func has_chunk(slot: int) -> bool:
	_ensure_header()
	return _offsets[slot] != 0


## Returns [param slot]'s byte offset (`0` if absent) with no file I/O beyond
## the one-time [method _ensure_header] guard -- lets the async dispatch path
## (Story 011, [VoxelWorldGrid._try_dispatch_read]) hand a background task
## the exact offset it needs, entirely from main-thread bookkeeping, before
## the actual disk read ever runs off-thread.
func offset_of(slot: int) -> int:
	_ensure_header()
	return _offsets[slot]


## MAIN-THREAD-ONLY bookkeeping (Story 011, ADR-0015 Decision §6 lever 2):
## reserves (or returns the already-assigned) byte offset for [param slot]
## WITHOUT performing the actual payload write -- that happens afterward in a
## background [WorkerThreadPool] task via the `static` [method
## write_payload_at]. Splitting "reserve the slot" from "write the bytes" is
## what lets the slow part run off-thread without a race (see class doc
## comment).
##
## If this is the FIRST write ever to this region, the (small) blank header
## file -- and its parent directory, if missing -- is created HERE,
## synchronously: centralizing region-file creation on the main thread
## prevents two background tasks for two different chunks in the same
## brand-new region from racing to create the file concurrently. This is a
## one-time-per-region cost (ADR-0015 Decision §6's one sanctioned
## synchronous exception), not a per-chunk one -- the same guarantee [method
## _ensure_header] already gives read-side callers.
func reserve_offset_for_write(slot: int) -> int:
	_ensure_header()
	if not FileAccess.file_exists(path):
		var dir_result: Error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		assert(
			dir_result == OK,
			"VoxelWorldRegionFile.reserve_offset_for_write: could not create directory for %s (error %s)" % [path, dir_result]
		)
		var create_f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		assert(
			create_f != null,
			"VoxelWorldRegionFile.reserve_offset_for_write: could not create %s (%s)" % [path, FileAccess.get_open_error()]
		)
		for i in slots_per_region:
			create_f.store_64(0)
		create_f.close()
	var offset: int = _offsets[slot]
	if offset == 0:
		offset = _next_append_offset
		_offsets[slot] = offset
		_next_append_offset += chunk_payload_bytes
	return offset


## Pure, stateless payload read (Story 011) -- safe to call from a background
## [WorkerThreadPool] task: opens its OWN [FileAccess] handle, touches no
## instance state of any [VoxelWorldRegionFile]. Caller MUST already know
## [param offset] via a main-thread [method has_chunk] / [method offset_of]
## call BEFORE dispatching the background task that calls this -- this reads
## whatever [param payload_bytes] sit at [param offset] unconditionally, with
## no further presence check.
static func read_payload_at(path: String, offset: int, payload_bytes: int) -> PackedByteArray:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("VoxelWorldRegionFile.read_payload_at: could not open %s for read (%s)" % [path, FileAccess.get_open_error()])
		return PackedByteArray()
	f.seek(offset)
	var data: PackedByteArray = f.get_buffer(payload_bytes)
	f.close()
	return data


## Pure, stateless payload write + header-slot update (Story 011) -- safe to
## call from a background [WorkerThreadPool] task: opens its OWN [FileAccess]
## handle, touches no instance state. [param offset] MUST already be reserved
## via a main-thread [method reserve_offset_for_write] call BEFORE the
## background task that calls this was dispatched -- this only performs the
## actual byte write (payload, then that slot's header entry). Returns
## `false` (and `push_error`s, never silently swallows -- Foundation Layer's
## "detect, push_error, return false" precedent, ADR-0012) on any I/O
## failure; the caller consumes this result via a mutex-guarded structure,
## never via [method WorkerThreadPool.wait_for_task_completion]'s return
## value (ADR-0015 Decision §6 engine note, TR-voxel-world-053 QA AC-3).
static func write_payload_at(path: String, slot: int, offset: int, data: PackedByteArray) -> bool:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ_WRITE)
	if f == null:
		push_error("VoxelWorldRegionFile.write_payload_at: could not open %s for read/write (%s)" % [path, FileAccess.get_open_error()])
		return false
	f.seek(offset)
	if not f.store_buffer(data):
		push_error("VoxelWorldRegionFile.write_payload_at: failed writing payload for slot %d in %s" % [slot, path])
		f.close()
		return false
	f.seek(slot * HEADER_ENTRY_BYTES)
	if not f.store_64(offset):
		push_error("VoxelWorldRegionFile.write_payload_at: failed updating header for slot %d in %s" % [slot, path])
		f.close()
		return false
	f.close()
	return true


## Reads (or, for a not-yet-existing file, initializes an all-absent) header
## exactly once per instance -- see class doc comment and [member
## header_load_count]. A missing file is NOT created here (see [method
## reserve_offset_for_write]) -- "a region that never has a dirty chunk never
## gets a file on disk at all."
func _ensure_header() -> void:
	if _header_loaded:
		return
	_offsets.resize(slots_per_region)
	var header_bytes: int = slots_per_region * HEADER_ENTRY_BYTES
	_next_append_offset = header_bytes
	if FileAccess.file_exists(path):
		var f: FileAccess = FileAccess.open(path, FileAccess.READ)
		assert(f != null, "VoxelWorldRegionFile._ensure_header: could not open %s for read (%s)" % [path, FileAccess.get_open_error()])
		for i in slots_per_region:
			_offsets[i] = f.get_64()
		_next_append_offset = maxi(header_bytes, f.get_length())
		f.close()
	header_load_count += 1
	_header_loaded = true
