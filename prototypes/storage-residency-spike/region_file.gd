# On-disk region file — throwaway prototype code (ADR-0015 storage/residency
# spike).
#
# One file per region_size_chunks x region_size_chunks block of chunk
# columns (Decision §2). Format:
#   header: SLOTS_PER_REGION x int64 byte-offset (0 == chunk absent, i.e.
#           pristine/regenerable — ADR-0015 §5; never written at all)
#   body:   CHUNK_BYTES-sized raw chunk payloads, appended in first-write
#           order (fixed size => safe to overwrite in place on a later
#           mutation of the same chunk, no reflow needed)
#
# A region that has never had a dirty chunk never has a file on disk at
# all — this is what keeps the persisted footprint sparse (Decision §5:
# "store only mutated far chunks"), not the naive "one file per region,
# always full" layout.
class_name SpikeRegionFile
extends RefCounted

const REGION_SIZE_CHUNKS := 32
const SLOTS_PER_REGION := REGION_SIZE_CHUNKS * REGION_SIZE_CHUNKS   # 1024
const HEADER_BYTES := SLOTS_PER_REGION * 8                          # 8192
const CHUNK_BYTES := 16 * 16 * 32                                   # 8192

var path: String
var _offsets: PackedInt64Array = PackedInt64Array()
var _header_loaded := false
var _next_append_offset: int = HEADER_BYTES


func _init(region_path: String) -> void:
	path = region_path


func _ensure_header() -> void:
	if _header_loaded:
		return
	_offsets.resize(SLOTS_PER_REGION)
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		for i in SLOTS_PER_REGION:
			_offsets[i] = f.get_64()
		_next_append_offset = maxi(HEADER_BYTES, f.get_length())
		f.close()
	else:
		_next_append_offset = HEADER_BYTES
	_header_loaded = true


func has_chunk(slot: int) -> bool:
	_ensure_header()
	return _offsets[slot] != 0


func offset_of(slot: int) -> int:
	_ensure_header()
	return _offsets[slot]


## ROUND 3 (lever 2 — disk I/O off the main thread): MAIN-THREAD-ONLY
## bookkeeping that reserves (or returns the existing) byte offset for a
## slot WITHOUT performing the actual payload write — that happens in a
## background task afterward (residency_manager.gd's _bg_write). Splitting
## "reserve the slot" (must be synchronized — two concurrent writers must
## never allocate the same append offset) from "write the bytes" (safe to
## do concurrently once each writer has its own offset) is what lets the
## slow part run off-thread without a race.
##
## Exception, documented: if this is the FIRST write ever to this region,
## the (small, 8192 B) blank header file is created HERE, synchronously —
## centralizing region-file creation on the main thread is what prevents
## two background tasks for two different chunks in the same brand-new
## region from both trying to create the file concurrently (a real
## corruption risk if left to the background tasks themselves). This is a
## one-time-per-region cost (at most ~50-100 occurrences across a full
## spike run), not a per-chunk one, and measured separately — see
## header_io_usec in residency_manager.gd.
func reserve_offset_for_write(slot: int) -> int:
	_ensure_header()
	if not FileAccess.file_exists(path):
		var create_f := FileAccess.open(path, FileAccess.WRITE)
		for i in SLOTS_PER_REGION:
			create_f.store_64(0)
		create_f.close()
	var offset: int = _offsets[slot]
	if offset == 0:
		offset = _next_append_offset
		_offsets[slot] = offset
		_next_append_offset += CHUNK_BYTES
	return offset


func read_chunk(slot: int) -> PackedByteArray:
	_ensure_header()
	var f := FileAccess.open(path, FileAccess.READ)
	f.seek(_offsets[slot])
	var data := f.get_buffer(CHUNK_BYTES)
	f.close()
	return data


## Writes (or overwrites in place — every payload is fixed CHUNK_BYTES size)
## one chunk's bytes and updates that slot's header entry. Creates the file
## (header-only, all-zero offsets) on first write to this region.
func write_chunk(slot: int, data: PackedByteArray) -> void:
	_ensure_header()
	if not FileAccess.file_exists(path):
		var create_f := FileAccess.open(path, FileAccess.WRITE)
		for i in SLOTS_PER_REGION:
			create_f.store_64(0)
		create_f.close()
	var f := FileAccess.open(path, FileAccess.READ_WRITE)
	var offset: int = _offsets[slot]
	if offset == 0:
		offset = _next_append_offset
		_offsets[slot] = offset
		_next_append_offset += CHUNK_BYTES
	f.seek(offset)
	f.store_buffer(data)
	f.seek(slot * 8)
	f.store_64(offset)
	f.close()


func file_size_on_disk() -> int:
	if not FileAccess.file_exists(path):
		return 0
	var f := FileAccess.open(path, FileAccess.READ)
	var size := f.get_length()
	f.close()
	return size
