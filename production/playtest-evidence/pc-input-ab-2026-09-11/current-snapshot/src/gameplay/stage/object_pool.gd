class_name ProductionObjectPool
extends Node

const BorrowBuffer = preload("res://src/gameplay/stage/pool_borrow_buffer.gd")

## Fixed-capacity pool spike. Grid binding is explicit so release cannot bypass
## the remove-before-free lifecycle boundary.
enum Status {
	OK,
	INVALID_CONFIG,
	INVALID_ARGUMENT,
	POOL_EXHAUSTED,
	STALE_BORROW,
	STILL_REGISTERED,
	NOT_INITIALIZED,
}

const SLOT_FREE := 0
const SLOT_BORROWED_UNBOUND := 1
const SLOT_BORROWED_BOUND := 2

var _initialized := false
var _capacity: int = 0
var _states := PackedByteArray()
var _borrow_ids := PackedInt64Array()
var _spatial_handles := PackedInt64Array()
var _nodes: Array = []
var _next_borrow_id: int = 1

func initialize(capacity: int, factory: Callable) -> int:
	if _initialized or capacity <= 0 or not factory.is_valid():
		return Status.INVALID_CONFIG
	_capacity = capacity
	_states.resize(capacity)
	_borrow_ids.resize(capacity)
	_spatial_handles.resize(capacity)
	_nodes.resize(capacity)
	for slot in capacity:
		var node = factory.call()
		if not node is Node:
			return Status.INVALID_CONFIG
		_nodes[slot] = node
		_states[slot] = SLOT_FREE
		_borrow_ids[slot] = 0
		_spatial_handles[slot] = 0
		if node.get_parent() == null:
			add_child(node)
	_initialized = true
	return Status.OK

func borrow(out_borrow) -> int:
	if not _initialized:
		return Status.NOT_INITIALIZED
	if out_borrow == null or _next_borrow_id <= 0:
		return Status.INVALID_ARGUMENT
	for slot in _capacity:
		if _states[slot] != SLOT_FREE:
			continue
		_states[slot] = SLOT_BORROWED_UNBOUND
		_borrow_ids[slot] = _next_borrow_id
		_next_borrow_id += 1
		_spatial_handles[slot] = 0
		out_borrow.borrow_id = _borrow_ids[slot]
		out_borrow.slot_id = slot
		return Status.OK
	return Status.POOL_EXHAUSTED

func bind_spatial_handle(borrow_id: int, spatial_handle: int) -> int:
	var slot := _find_borrow(borrow_id)
	if slot < 0 or spatial_handle <= 0:
		return Status.STALE_BORROW
	if _states[slot] != SLOT_BORROWED_UNBOUND:
		return Status.STALE_BORROW
	_spatial_handles[slot] = spatial_handle
	_states[slot] = SLOT_BORROWED_BOUND
	return Status.OK

func unbind_spatial_handle(borrow_id: int, spatial_handle: int) -> int:
	var slot := _find_borrow(borrow_id)
	if slot < 0 or _states[slot] != SLOT_BORROWED_BOUND or _spatial_handles[slot] != spatial_handle:
		return Status.STALE_BORROW
	_spatial_handles[slot] = 0
	_states[slot] = SLOT_BORROWED_UNBOUND
	return Status.OK

func release(borrow_id: int) -> int:
	var slot := _find_borrow(borrow_id)
	if slot < 0:
		return Status.STALE_BORROW
	if _states[slot] == SLOT_BORROWED_BOUND or _spatial_handles[slot] != 0:
		return Status.STILL_REGISTERED
	if _states[slot] != SLOT_BORROWED_UNBOUND:
		return Status.STALE_BORROW
	_states[slot] = SLOT_FREE
	_borrow_ids[slot] = 0
	_spatial_handles[slot] = 0
	return Status.OK

func borrowed_count() -> int:
	var count := 0
	for state in _states:
		if state != SLOT_FREE:
			count += 1
	return count

func node_for(borrow_id: int):
	var slot := _find_borrow(borrow_id)
	return null if slot < 0 else _nodes[slot]

func _find_borrow(borrow_id: int) -> int:
	if borrow_id <= 0:
		return -1
	for slot in _capacity:
		if _states[slot] != SLOT_FREE and _borrow_ids[slot] == borrow_id:
			return slot
	return -1
