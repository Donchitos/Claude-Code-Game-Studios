# AStar3D nav graph per ADR-0007 rules — throwaway prototype code.
# Standability: solid below + 3-cell vertical clearance. Step: |dy| <= 1.
# Diagonal only if both flanking orthogonals passable. IDs: 21-bit packed axes.
class_name NavGraph
extends RefCounted

const B21 := 0x1FFFFF
const UP := Vector3i(0, 1, 0)
const DOWN := Vector3i(0, -1, 0)

var astar := AStar3D.new()
var occ: Dictionary  # Vector3i -> material id (shared with Main)
var max_y: int
var standable_ids: PackedInt64Array = []

var _dirs8: Array[Vector3i] = [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1),
	Vector3i(1, 0, 1), Vector3i(1, 0, -1), Vector3i(-1, 0, 1), Vector3i(-1, 0, -1),
]


static func pack(c: Vector3i) -> int:
	return (c.x & B21) | ((c.y & B21) << 21) | ((c.z & B21) << 42)


func is_passable(c: Vector3i) -> bool:
	return not occ.has(c)


func is_standable(c: Vector3i) -> bool:
	if c.y < 0 or c.y > max_y:
		return false
	return occ.has(c + DOWN) and not occ.has(c) \
		and not occ.has(c + UP) and not occ.has(c + UP + UP)


func is_step_legal(from: Vector3i, to: Vector3i) -> bool:
	if absi(to.y - from.y) > 1:
		return false
	var d := to - from
	if d.x != 0 and d.z != 0:  # diagonal: both flanking orthogonals passable
		if not is_passable(Vector3i(from.x + d.x, from.y, from.z)):
			return false
		if not is_passable(Vector3i(from.x, from.y, from.z + d.z)):
			return false
	return true


func cell_center(c: Vector3i) -> Vector3:
	return Vector3(c.x + 0.5, float(c.y), c.z + 0.5)


func build(width: int, depth: int) -> void:
	build_region(0, 0, width, depth)


func build_region(x0: int, z0: int, x1: int, z1: int) -> void:
	astar.clear()
	standable_ids.clear()
	var cells: Array[Vector3i] = []
	for x in range(x0, x1):
		for z in range(z0, z1):
			for y in max_y + 1:
				var c := Vector3i(x, y, z)
				if is_standable(c):
					var id := pack(c)
					astar.add_point(id, cell_center(c))
					cells.append(c)
					standable_ids.append(id)
	for c in cells:
		_connect_cell(c)


func _connect_cell(c: Vector3i) -> void:
	var id := pack(c)
	if not astar.has_point(id):
		return
	for d in _dirs8:
		for dy in [-1, 0, 1]:
			var n := c + d + Vector3i(0, dy, 0)
			var nid := pack(n)
			if astar.has_point(nid) and is_step_legal(c, n) \
					and not astar.are_points_connected(id, nid):
				astar.connect_points(id, nid)


# Incremental patch after occ change at `changed` — re-derive the local window.
func patch(changed: Vector3i) -> void:
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for dy in range(-3, 2):
				var c := changed + Vector3i(dx, dy, dz)
				var id := pack(c)
				var should := is_standable(c)
				var has := astar.has_point(id)
				if has and not should:
					astar.remove_point(id)
				elif should and not has:
					astar.add_point(id, cell_center(c))
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			for dy in range(-4, 3):
				var c := changed + Vector3i(dx, dy, dz)
				if astar.has_point(pack(c)):
					_connect_cell(c)


func random_standable(rng: RandomNumberGenerator) -> int:
	while true:
		var id := standable_ids[rng.randi_range(0, standable_ids.size() - 1)]
		if astar.has_point(id):
			return id
	return -1


# Bounded BFS reachability (Deciding-pass candidate check / wander scope).
func bounded_bfs_reachable(from: Vector3i, to: Vector3i, cell_limit: int) -> bool:
	if from == to:
		return true
	var frontier: Array[Vector3i] = [from]
	var seen := {from: true}
	var head := 0
	while head < frontier.size() and head < cell_limit:
		var cur: Vector3i = frontier[head]
		head += 1
		for d in _dirs8:
			for dy in [-1, 0, 1]:
				var n: Vector3i = cur + d + Vector3i(0, dy, 0)
				if seen.has(n) or not is_standable(n) or not is_step_legal(cur, n):
					continue
				if n == to:
					return true
				seen[n] = true
				frontier.append(n)
	return false
