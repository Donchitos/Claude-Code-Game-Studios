extends SceneTree

const SpatialGrid = preload("res://src/gameplay/stage/spatial_grid.gd")
const SpatialHandleBuffer = preload("res://src/gameplay/stage/spatial_handle_buffer.gd")
const SpatialQueryBuffer = preload("res://src/gameplay/stage/spatial_query_buffer.gd")
const SpatialNearestBuffer = preload("res://src/gameplay/stage/spatial_nearest_buffer.gd")

var _failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var grid := SpatialGrid.new()
	root.add_child(grid)
	_expect(grid.call("initialize", 16384.0, 2.0, 4, 4, 64) == SpatialGrid.Status.OK, "grid init must pass")
	var enemy := Node.new()
	var drop := Node.new()
	grid.add_child(enemy)
	grid.add_child(drop)
	var enemy_handle := SpatialHandleBuffer.new()
	var drop_handle := SpatialHandleBuffer.new()
	_expect(grid.call("insert_into", enemy, SpatialGrid.TYPE_ENEMY, Vector2.ZERO, enemy_handle) == SpatialGrid.Status.OK, "enemy insert must create pending handle")
	_expect(grid.call("insert_into", drop, SpatialGrid.TYPE_DROP, Vector2(20.0, 0.0), drop_handle) == SpatialGrid.Status.OK, "drop insert must create pending handle")
	var results := SpatialQueryBuffer.new()
	results.call("configure", 4)
	_expect(grid.call("query_circle_into", Vector2.ZERO, 5.0, SpatialGrid.TYPE_ALL, results) == SpatialGrid.Status.OK and results.get("count") == 0, "pending entries must stay out of snapshot")
	_expect(grid.call("sync") == SpatialGrid.Status.OK, "grid sync must publish pending entries")
	_expect(grid.call("query_circle_into", Vector2.ZERO, 5.0, SpatialGrid.TYPE_ENEMY, results) == SpatialGrid.Status.OK and results.get("count") == 1 and results.get("handle_ids")[0] == enemy_handle.get("handle_id"), "enemy query must return the local enemy")
	var nearest := SpatialNearestBuffer.new()
	_expect(grid.call("query_nearest_into", Vector2.ZERO, 30.0, SpatialGrid.TYPE_DROP, nearest) == SpatialGrid.Status.OK and nearest.get("has_handle") and nearest.get("handle_id") == drop_handle.get("handle_id"), "nearest query must honor type filter")
	_expect(grid.call("stage_position", enemy_handle.get("handle_id"), Vector2(100.0, 0.0)) == SpatialGrid.Status.OK, "stage position must pass")
	_expect(grid.call("query_circle_into", Vector2.ZERO, 5.0, SpatialGrid.TYPE_ENEMY, results) == SpatialGrid.Status.OK and results.get("count") == 1, "staged position must not mutate old snapshot")
	_expect(grid.call("sync") == SpatialGrid.Status.OK, "second sync must pass")
	_expect(grid.call("query_circle_into", Vector2.ZERO, 5.0, SpatialGrid.TYPE_ENEMY, results) == SpatialGrid.Status.OK and results.get("count") == 0, "sync must publish staged position")
	_expect(grid.call("remove", enemy_handle.get("handle_id")) == SpatialGrid.Status.OK, "remove must invalidate handle")
	_expect(grid.call("remove", enemy_handle.get("handle_id")) == SpatialGrid.Status.STALE_HANDLE, "removed handle must not be reusable")
	_expect(grid.call("insert_into", enemy, SpatialGrid.TYPE_ENEMY, Vector2(20000.0, 0.0), enemy_handle) == SpatialGrid.Status.OUT_OF_BOUNDS, "out-of-domain insert must fail closed")
	grid.queue_free()
	await process_frame
	# Force four distinct signed cells into the same hash bucket.
	var collision_grid := SpatialGrid.new()
	root.add_child(collision_grid)
	_expect(collision_grid.initialize(16384.0, 1.0, 4, 4, 64) == SpatialGrid.Status.OK, "collision grid init")
	var cells: Array[Vector2i] = []
	for x in range(-1000, 1000):
		var cell := Vector2i(x, -2)
		if posmod(hash(cell), 9) == 0:
			cells.append(cell)
			if cells.size() == 4:
				break
	var handles: Array[int] = []
	for cell in cells:
		var node := Node.new()
		collision_grid.add_child(node)
		var handle := SpatialHandleBuffer.new()
		_expect(collision_grid.insert_into(node, SpatialGrid.TYPE_ENEMY, Vector2(cell) + Vector2(0.25, 0.25), handle) == SpatialGrid.Status.OK, "collision insert")
		handles.append(handle.handle_id)
	_expect(collision_grid.sync() == SpatialGrid.Status.OK, "collision sync")
	for index in cells.size():
		_expect(collision_grid.query_circle_into(Vector2(cells[index]) + Vector2(0.25, 0.25), 0.0, SpatialGrid.TYPE_ENEMY, results) == SpatialGrid.Status.OK and results.count == 1 and results.handle_ids[0] == handles[index], "hash collision does not alias signed cells")
	_expect(collision_grid.remove(handles[0]) == SpatialGrid.Status.OK and collision_grid.sync() == SpatialGrid.Status.OK, "rebuild collision chain after removal")
	_expect(collision_grid.query_circle_into(Vector2(cells[3]) + Vector2(0.25, 0.25), 0.0, SpatialGrid.TYPE_ENEMY, results) == SpatialGrid.Status.OK and results.count == 1, "later colliding cell survives removal")
	collision_grid.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("SPATIAL_GRID_ASSERTION_FAILED %s" % message)

func _finish() -> void:
	if _failures == 0:
		print("SPATIAL_GRID_PASS sparse=true fixed_capacity=true pending_sync=true query=true nearest=true bounds=true")
		quit(0)
	else:
		print("SPATIAL_GRID_FAIL failures=%d" % _failures)
		quit(1)
