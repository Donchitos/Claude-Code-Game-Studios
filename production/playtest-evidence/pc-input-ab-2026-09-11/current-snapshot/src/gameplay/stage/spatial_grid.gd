class_name ProductionSpatialGrid
extends Node

const SpatialHandleBuffer = preload("res://src/gameplay/stage/spatial_handle_buffer.gd")
const SpatialQueryBuffer = preload("res://src/gameplay/stage/spatial_query_buffer.gd")
const SpatialNearestBuffer = preload("res://src/gameplay/stage/spatial_nearest_buffer.gd")

## Fixed-capacity sparse grid core used by StageRuntime. Full GameRoot phase
## leases and pause/resume snapshot transactions remain a later integration.
enum Status {
	OK,
	INVALID_CONFIG,
	INVALID_ARGUMENT,
	OUT_OF_BOUNDS,
	CAPACITY_EXCEEDED,
	BUFFER_TOO_SMALL,
	NOT_INITIALIZED,
	STALE_HANDLE,
}

const TYPE_ENEMY := 1
const TYPE_PROJECTILE := 2
const TYPE_DROP := 4
const TYPE_ALL := 7
const ENTRY_FREE := 0
const ENTRY_PENDING := 1
const ENTRY_ACTIVE := 2

var _initialized := false
var _world_half_extent: float = 0.0
var _cell_size: float = 0.0
var _max_entries: int = 0
var _max_cells: int = 0
var _max_query_cells: int = 0
var _next_handle: int = 1

var _states := PackedByteArray()
var _handles := PackedInt64Array()
var _positions := PackedVector2Array()
var _staged_positions := PackedVector2Array()
var _has_staged_position := PackedByteArray()
var _types := PackedInt32Array()
var _entry_cells := PackedInt32Array()
var _entry_next := PackedInt32Array()
var _objects: Array = []

var _cell_used := PackedByteArray()
var _cell_x := PackedInt64Array()
var _cell_y := PackedInt64Array()
var _cell_heads := PackedInt32Array()
var _cell_lookup := PackedInt32Array()

var last_query_cells_visited: int = 0
var last_query_candidates_examined: int = 0
var last_query_results_count: int = 0

func initialize(world_half_extent: float, cell_size: float, max_entries: int = 1000, max_cells: int = 1000, max_query_cells: int = 262144) -> int:
	if _initialized or not is_finite(world_half_extent) or world_half_extent <= 0.0 \
			or not is_finite(cell_size) or cell_size <= 0.0 \
			or max_entries <= 0 or max_cells <= 0 or max_query_cells <= 0:
		return Status.INVALID_CONFIG
	_world_half_extent = world_half_extent
	_cell_size = cell_size
	_max_entries = max_entries
	_max_cells = max_cells
	_max_query_cells = max_query_cells
	_states.resize(max_entries)
	_handles.resize(max_entries)
	_positions.resize(max_entries)
	_staged_positions.resize(max_entries)
	_has_staged_position.resize(max_entries)
	_types.resize(max_entries)
	_entry_cells.resize(max_entries)
	_entry_next.resize(max_entries)
	_objects.resize(max_entries)
	_cell_used.resize(max_cells)
	_cell_x.resize(max_cells)
	_cell_y.resize(max_cells)
	_cell_heads.resize(max_cells)
	_cell_lookup.resize(max_cells * 2 + 1)
	_reset_storage()
	_initialized = true
	return Status.OK

func insert_into(object: Node, type_mask: int, position: Vector2, out_handle) -> int:
	if not _initialized:
		return Status.NOT_INITIALIZED
	if object == null or out_handle == null or not _valid_type(type_mask):
		return Status.INVALID_ARGUMENT
	if not _valid_position(position):
		return Status.OUT_OF_BOUNDS
	var slot := _find_free_entry()
	if slot < 0:
		return Status.CAPACITY_EXCEEDED
	if _next_handle <= 0:
		return Status.CAPACITY_EXCEEDED
	_states[slot] = ENTRY_PENDING
	_handles[slot] = _next_handle
	_next_handle += 1
	_positions[slot] = position
	_types[slot] = type_mask
	_objects[slot] = object
	out_handle.handle_id = _handles[slot]
	return Status.OK

func remove(handle_id: int) -> int:
	var slot := _find_entry(handle_id)
	if slot < 0:
		return Status.STALE_HANDLE
	_states[slot] = ENTRY_FREE
	_handles[slot] = 0
	_objects[slot] = null
	_has_staged_position[slot] = 0
	return Status.OK

func stage_position(handle_id: int, position: Vector2) -> int:
	var slot := _find_entry(handle_id)
	if slot < 0:
		return Status.STALE_HANDLE
	if not _valid_position(position):
		return Status.OUT_OF_BOUNDS
	if _states[slot] == ENTRY_PENDING:
		_positions[slot] = position
		return Status.OK
	if _states[slot] != ENTRY_ACTIVE:
		return Status.STALE_HANDLE
	_staged_positions[slot] = position
	_has_staged_position[slot] = 1
	return Status.OK

func sync() -> int:
	if not _initialized:
		return Status.NOT_INITIALIZED
	_clear_cells()
	for slot in _max_entries:
		if _states[slot] == ENTRY_PENDING:
			_states[slot] = ENTRY_ACTIVE
		if _states[slot] != ENTRY_ACTIVE:
			continue
		if _has_staged_position[slot] != 0:
			_positions[slot] = _staged_positions[slot]
			_has_staged_position[slot] = 0
		var cell := _find_or_create_cell(_cell_for_position(_positions[slot]))
		if cell < 0:
			return Status.CAPACITY_EXCEEDED
		_entry_cells[slot] = cell
		_entry_next[slot] = _cell_heads[cell]
		_cell_heads[cell] = slot
	return Status.OK

func query_circle_into(center: Vector2, radius: float, type_filter: int, out_results) -> int:
	if not _initialized:
		return Status.NOT_INITIALIZED
	if out_results == null or not _valid_position(center) or not is_finite(radius) or radius < 0.0:
		return Status.INVALID_ARGUMENT
	_reset_query_diagnostics()
	type_filter &= TYPE_ALL
	out_results.clear()
	if type_filter == 0:
		return Status.OK
	var radius_squared := radius * radius
	var min_cell := _cell_for_position(center - Vector2.ONE * radius)
	var max_cell := _cell_for_position(center + Vector2.ONE * radius)
	var cell_width := maxi(0, int(max_cell.x - min_cell.x + 1))
	var cell_height := maxi(0, int(max_cell.y - min_cell.y + 1))
	var use_fallback := cell_width > 0 and cell_height > 0 and cell_width > _max_query_cells / cell_height
	if use_fallback:
		return _scan_entries_circle(center, radius_squared, type_filter, out_results)
	var cell_y_value := int(min_cell.y)
	while cell_y_value <= int(max_cell.y):
		var cell_x_value := int(min_cell.x)
		while cell_x_value <= int(max_cell.x):
			last_query_cells_visited += 1
			var cell := _find_cell(Vector2i(cell_x_value, cell_y_value))
			if cell >= 0:
				var slot := _cell_heads[cell]
				while slot >= 0:
					if _matches(slot, center, radius_squared, type_filter):
						if not _write_result(slot, out_results):
							return Status.BUFFER_TOO_SMALL
					slot = _entry_next[slot]
			cell_x_value += 1
		cell_y_value += 1
	last_query_results_count = out_results.count
	return Status.OK

func query_nearest_into(center: Vector2, max_radius: float, type_filter: int, out_result) -> int:
	if not _initialized:
		return Status.NOT_INITIALIZED
	if out_result == null or not _valid_position(center) or not is_finite(max_radius) or max_radius < 0.0:
		return Status.INVALID_ARGUMENT
	_reset_query_diagnostics()
	type_filter &= TYPE_ALL
	out_result.clear()
	if type_filter == 0:
		return Status.OK
	var radius_squared := max_radius * max_radius
	var best_distance := INF
	for slot in _max_entries:
		if _states[slot] != ENTRY_ACTIVE or (_types[slot] & type_filter) == 0:
			continue
		last_query_candidates_examined += 1
		var distance := _positions[slot].distance_squared_to(center)
		if distance > radius_squared:
			continue
		var handle := _handles[slot]
		if distance < best_distance or (is_equal_approx(distance, best_distance) and handle < out_result.handle_id):
			best_distance = distance
			out_result.has_handle = true
			out_result.handle_id = handle
	last_query_results_count = 1 if out_result.has_handle else 0
	return Status.OK

func active_count() -> int:
	var count := 0
	for state in _states:
		if state == ENTRY_ACTIVE:
			count += 1
	return count

func _scan_entries_circle(center: Vector2, radius_squared: float, type_filter: int, out_results) -> int:
	for slot in _max_entries:
		if _matches(slot, center, radius_squared, type_filter):
			if not _write_result(slot, out_results):
				return Status.BUFFER_TOO_SMALL
	last_query_results_count = out_results.count
	return Status.OK

func _write_result(slot: int, out_results) -> bool:
	last_query_candidates_examined += 1
	if out_results.count >= out_results.handle_ids.size():
		out_results.required_capacity = out_results.count + 1
		out_results.count = 0
		return false
	out_results.handle_ids[out_results.count] = _handles[slot]
	out_results.count += 1
	return true

func _matches(slot: int, center: Vector2, radius_squared: float, type_filter: int) -> bool:
	if _states[slot] != ENTRY_ACTIVE or (_types[slot] & type_filter) == 0:
		return false
	return _positions[slot].distance_squared_to(center) <= radius_squared

func _valid_type(type_mask: int) -> bool:
	return type_mask == TYPE_ENEMY or type_mask == TYPE_PROJECTILE or type_mask == TYPE_DROP

func _valid_position(position: Vector2) -> bool:
	return position.is_finite() and absf(position.x) <= _world_half_extent and absf(position.y) <= _world_half_extent

func _cell_for_position(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / _cell_size), floori(position.y / _cell_size))

func _find_or_create_cell(cell: Vector2i) -> int:
	var existing := _find_cell(cell)
	if existing >= 0:
		return existing
	for index in _max_cells:
		if _cell_used[index] == 0:
			_cell_used[index] = 1
			_cell_x[index] = cell.x
			_cell_y[index] = cell.y
			_cell_heads[index] = -1
			var bucket := posmod(hash(cell), _cell_lookup.size())
			while _cell_lookup[bucket] >= 0:
				bucket = (bucket + 1) % _cell_lookup.size()
			_cell_lookup[bucket] = index
			return index
	return -1

func _find_cell(cell: Vector2i) -> int:
	var bucket := posmod(hash(cell), _cell_lookup.size())
	for probe in _cell_lookup.size():
		var index := _cell_lookup[bucket]
		if index < 0:
			return -1
		if _cell_x[index] == cell.x and _cell_y[index] == cell.y:
			return index
		bucket = (bucket + 1) % _cell_lookup.size()
	return -1

func _find_free_entry() -> int:
	for index in _max_entries:
		if _states[index] == ENTRY_FREE:
			return index
	return -1

func _find_entry(handle_id: int) -> int:
	if handle_id <= 0:
		return -1
	for index in _max_entries:
		if _states[index] != ENTRY_FREE and _handles[index] == handle_id:
			return index
	return -1

func _clear_cells() -> void:
	_cell_lookup.fill(-1)
	for index in _max_cells:
		_cell_used[index] = 0
		_cell_heads[index] = -1

func _reset_storage() -> void:
	for index in _max_entries:
		_states[index] = ENTRY_FREE
		_handles[index] = 0
		_has_staged_position[index] = 0
		_entry_cells[index] = -1
		_entry_next[index] = -1
		_objects[index] = null
	_clear_cells()

func _reset_query_diagnostics() -> void:
	last_query_cells_visited = 0
	last_query_candidates_examined = 0
	last_query_results_count = 0
