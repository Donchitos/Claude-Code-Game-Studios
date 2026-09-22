extends SceneTree

const ObjectPool = preload("res://src/gameplay/stage/object_pool.gd")
const BorrowBuffer = preload("res://src/gameplay/stage/pool_borrow_buffer.gd")

var _failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var pool := ObjectPool.new()
	root.add_child(pool)
	_expect(pool.call("initialize", 2, Callable(self, "_make_node")) == ObjectPool.Status.OK, "pool init must pass")
	var first := BorrowBuffer.new()
	var second := BorrowBuffer.new()
	_expect(pool.call("borrow", first) == ObjectPool.Status.OK, "first borrow must pass")
	_expect(pool.call("borrow", second) == ObjectPool.Status.OK, "second borrow must pass")
	_expect(pool.call("borrow", BorrowBuffer.new()) == ObjectPool.Status.POOL_EXHAUSTED, "pool must not grow")
	_expect(pool.call("bind_spatial_handle", first.get("borrow_id"), 101) == ObjectPool.Status.OK, "grid binding must pass")
	_expect(pool.call("release", first.get("borrow_id")) == ObjectPool.Status.STILL_REGISTERED, "bound borrow must not release")
	_expect(pool.call("unbind_spatial_handle", first.get("borrow_id"), 101) == ObjectPool.Status.OK, "grid unbind must pass")
	_expect(pool.call("release", first.get("borrow_id")) == ObjectPool.Status.OK, "unbound borrow must release")
	_expect(pool.call("release", first.get("borrow_id")) == ObjectPool.Status.STALE_BORROW, "released borrow must be stale")
	_expect(pool.call("borrowed_count") == 1, "slot conservation must retain second borrow")
	pool.queue_free()
	await process_frame
	_finish()

func _make_node() -> Node:
	return Node.new()

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("OBJECT_POOL_ASSERTION_FAILED %s" % message)

func _finish() -> void:
	if _failures == 0:
		print("OBJECT_POOL_PASS fixed_capacity=true borrow=true binding=true remove_before_release=true conservation=true")
		quit(0)
	else:
		print("OBJECT_POOL_FAIL failures=%d" % _failures)
		quit(1)
