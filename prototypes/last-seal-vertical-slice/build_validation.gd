# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: full build->furnish->live loop, unguided <=5 min, cozy at scale
# Date: 2026-07-12
# Build Validation & Navigability per design/gdd/build-validation-navigability.md,
# slice-reduced: event-driven region BFS (candidate cell = standable + roofed,
# both consumed/derived per Rule 1) scoped to a bounding box around player-built
# cells (tracked incrementally from Building System signals, expanded by 2 +
# furniture footprint) instead of an unbounded world scan. The outside-connection
# test walks Villager AI's own movement-graph predicates (is_standable /
# is_step_legal, consumed verbatim, called statically on the injected script
# resource) -- never redefines walkability. Pure analysis layer: reads Voxel
# World + Building System state, calls no mutating APIs, never touches villagers.
extends Node

signal room_recognized(cells: Array, celebrate: bool)
signal sealed_space_warning(cells: Array, item_ids: Array, why: String)
signal unsheltered_furniture_info(cell: Vector3i, why: String)
signal shelter_status_changed(cell: Vector3i, sheltered: bool)

const AIR_VALUE := 0
const LEAVES_VALUE := 31  # tree canopy — transparent to roof analysis
const BED_ITEM_ID := "bed"

# Slice tuning (deviates from GDD default min_room_cells=2 per explicit task
# direction; max_room_height matches GDD default and the wall_height lockstep
# invariant, both = 8).
const MIN_ROOM_CELLS := 2  # GDD default -- the first tiny hut must count
const MAX_ROOM_HEIGHT := 8
const MAX_Y := 32

const BBOX_MARGIN := 2          # cells of buffer around the built-cell footprint
const MAX_BFS_VISITED := 4000   # bounded outside-connection walk; exhaustion = sealed

const _ORTHO_6 := [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0), Vector3i(0, -1, 0),
	Vector3i(0, 0, 1), Vector3i(0, 0, -1),
]

const _HORIZONTAL_DIRS := [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

var _voxel_world: Node3D
var _building_system: Node3D
var _villager_ai_script: GDScript

var _built_cells: Dictionary = {}                  # Vector3i -> true; built non-terrain cells (walls/floor/roof/blocks)
var _region_valid_snapshot: Dictionary = {}         # Vector3i -> bool; last-known valid-room membership (edge-detection memory, Rule 11)
var _furniture_sheltered_snapshot: Dictionary = {}  # Vector3i -> bool; last-known sheltered flag per furniture cell
var _furniture_cache: Dictionary = {}               # Vector3i -> item_id; valid only within one analysis pass
var _pass_scheduled := false


func _process(_delta: float) -> void:
	if not _pass_scheduled:
		set_process(false)
		return
	_pass_scheduled = false
	set_process(false)
	_run_analysis_pass()


func setup(voxel_world: Node3D, building_system: Node3D, villager_ai_script: GDScript) -> void:
	_voxel_world = voxel_world
	_building_system = building_system
	_villager_ai_script = villager_ai_script
	_building_system.construction_completed.connect(_on_construction_completed)
	_building_system.cells_removed.connect(_on_cells_removed)
	_building_system.furniture_placed.connect(_on_furniture_placed)
	_building_system.furniture_removed.connect(_on_furniture_removed)
	set_process(false)  # event-driven only; _process stays off until a pass is scheduled


func is_cell_sheltered(cell: Vector3i) -> bool:
	return _region_valid_snapshot.get(cell, false)


func _run_analysis_pass() -> void:
	var bbox: Dictionary = _compute_bounding_box()
	if bbox.is_empty():
		return
	_furniture_cache = _building_system.get_furniture_cells()  # Vector3i -> item_id, cached for this pass only

	var candidates: Dictionary = _find_candidate_cells(bbox)
	var regions: Array = _find_regions(candidates)

	var new_valid_cells: Dictionary = {}   # Vector3i -> true; every cell of every valid room this pass
	var newly_recognized: Array = []       # Array[Array]; room cell-lists brand-new this pass (Rule 11 continuity)
	var sealed_regions: Array = []         # Array[Dictionary]; regions with no outside connection this pass

	for region in regions:
		var region_dict: Dictionary = region
		var connected: bool = _has_outside_connection(region_dict)
		if connected and region_dict.size() >= MIN_ROOM_CELLS:
			var was_new := true
			for cell in region_dict:
				new_valid_cells[cell] = true
				if _region_valid_snapshot.get(cell, false):
					was_new = false
			if was_new:
				newly_recognized.append(region_dict.keys())
		elif not connected:
			sealed_regions.append(region_dict)
		# else: Open (connected, below MIN_ROOM_CELLS) -- no room, no warning, no snapshot entry

	# Incremental snapshot patch scoped to this pass's candidates only (Rule 11).
	for cell in candidates:
		_region_valid_snapshot[cell] = new_valid_cells.has(cell)
	_purge_stale_snapshot_entries(bbox, candidates)

	for room_cells in newly_recognized:
		room_recognized.emit(room_cells, true)

	for region_dict in sealed_regions:
		var bed_ids: Array = []
		for cell in region_dict:
			if _furniture_cache.has(cell) and _furniture_cache[cell] == BED_ITEM_ID:
				bed_ids.append(BED_ITEM_ID)
		if not bed_ids.is_empty():
			sealed_space_warning.emit(region_dict.keys(), bed_ids, "the bed can't be reached — the room has no opening")

	for cell in _furniture_cache:
		var furniture_cell: Vector3i = cell
		if not _cell_in_bbox_xz(furniture_cell, bbox):
			continue  # outside this pass's scope; its structure did not change, leave its status untouched
		var item_id: String = _furniture_cache[cell]
		var sheltered: bool = new_valid_cells.has(furniture_cell)
		var prev_sheltered: bool = _furniture_sheltered_snapshot.get(furniture_cell, false)
		if sheltered != prev_sheltered:
			shelter_status_changed.emit(furniture_cell, sheltered)
		_furniture_sheltered_snapshot[furniture_cell] = sheltered

		if item_id == BED_ITEM_ID and not sheltered:
			var in_sealed := false
			for region_dict in sealed_regions:
				if region_dict.has(furniture_cell):
					in_sealed = true
					break
			if not in_sealed:
				unsheltered_furniture_info.emit(furniture_cell, "a bed under the sky — build a shelter around it")

	_furniture_cache = {}


func _compute_bounding_box() -> Dictionary:
	var min_x: int = 0
	var max_x: int = 0
	var min_z: int = 0
	var max_z: int = 0
	var has_any := false
	for cell in _built_cells:
		var c: Vector3i = cell
		if not has_any:
			min_x = c.x; max_x = c.x; min_z = c.z; max_z = c.z
			has_any = true
		else:
			min_x = mini(min_x, c.x)
			max_x = maxi(max_x, c.x)
			min_z = mini(min_z, c.z)
			max_z = maxi(max_z, c.z)
	var furniture_cells: Dictionary = _building_system.get_furniture_cells()
	for cell in furniture_cells:
		var c: Vector3i = cell
		if not has_any:
			min_x = c.x; max_x = c.x; min_z = c.z; max_z = c.z
			has_any = true
		else:
			min_x = mini(min_x, c.x)
			max_x = maxi(max_x, c.x)
			min_z = mini(min_z, c.z)
			max_z = maxi(max_z, c.z)
	if not has_any:
		return {}
	return {
		"min_x": min_x - BBOX_MARGIN,
		"max_x": max_x + BBOX_MARGIN,
		"min_z": min_z - BBOX_MARGIN,
		"max_z": max_z + BBOX_MARGIN,
	}


func _cell_in_bbox_xz(cell: Vector3i, bbox: Dictionary) -> bool:
	return cell.x >= bbox.min_x and cell.x <= bbox.max_x and cell.z >= bbox.min_z and cell.z <= bbox.max_z


func _find_candidate_cells(bbox: Dictionary) -> Dictionary:
	var candidates: Dictionary = {}
	for x in range(bbox.min_x, bbox.max_x + 1):
		for z in range(bbox.min_z, bbox.max_z + 1):
			for y in range(0, MAX_Y):
				var cell := Vector3i(x, y, z)
				if not _voxel_world.is_in_region(cell):
					continue
				if not _is_candidate_standable(cell):
					continue
				if _is_roofed(cell):
					candidates[cell] = true
	return candidates


# Rule 1 / TR-022: furniture occupancy is TRANSPARENT to the analysis — a
# furniture-occupied cell evaluates as if empty. The villager predicate treats
# furniture as solid (you can't walk through a bed), so candidacy needs its
# own standability with furniture-as-air semantics.
func _is_candidate_standable(cell: Vector3i) -> bool:
	var below := cell + Vector3i(0, -1, 0)
	if _voxel_world.get_cell(below) <= AIR_VALUE and not _furniture_cache.has(below):
		return false
	for dy in 3:
		var c := cell + Vector3i(0, dy, 0)
		var v: int = _voxel_world.get_cell(c)
		if v > AIR_VALUE and not _furniture_cache.has(c):
			return false
		if v < AIR_VALUE:
			return false
	return true


func _find_regions(candidates: Dictionary) -> Array:
	var regions: Array = []
	var visited: Dictionary = {}
	for start_cell in candidates:
		if visited.has(start_cell):
			continue
		var region: Dictionary = {}
		var queue: Array = [start_cell]
		visited[start_cell] = true
		var head := 0
		while head < queue.size():
			var cur: Vector3i = queue[head]
			head += 1
			region[cur] = true
			for offset in _ORTHO_6:
				var neighbor: Vector3i = cur + offset
				if not candidates.has(neighbor) or visited.has(neighbor):
					continue
				visited[neighbor] = true
				queue.append(neighbor)
		regions.append(region)
	return regions


func _has_outside_connection(region: Dictionary) -> bool:
	var visited: Dictionary = {}
	var queue: Array = []
	for cell in region:
		visited[cell] = true
		queue.append(cell)
	var head := 0
	while head < queue.size():
		if visited.size() > MAX_BFS_VISITED:
			break  # bounded exhaustion -> treat as sealed (never a false "reachable")
		var cur: Vector3i = queue[head]
		head += 1
		if _villager_ai_script.is_standable(_voxel_world, cur) and not _is_roofed(cur):
			return true  # open-sky standable cell reached
		for neighbor in _movement_neighbors(cur):
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			queue.append(neighbor)
	return false


func _movement_neighbors(cell: Vector3i) -> Array:
	var result: Array = []
	for dir in _HORIZONTAL_DIRS:
		for dy in [-1, 0, 1]:
			var to := Vector3i(cell.x + dir.x, cell.y + dy, cell.z + dir.y)
			if not _voxel_world.is_in_region(to):
				continue
			if not _villager_ai_script.is_standable(_voxel_world, to):
				continue
			if not _villager_ai_script.is_step_legal(_voxel_world, cell, to):
				continue
			result.append(to)
	return result


func _is_roofed(cell: Vector3i) -> bool:
	for offset in range(1, MAX_ROOM_HEIGHT + 1):
		var above_y := cell.y + offset
		if above_y >= MAX_Y:
			break
		var v: int = _voxel_world.get_cell(Vector3i(cell.x, above_y, cell.z))
		if v == LEAVES_VALUE:
			continue  # natural canopy is not shelter and never seals the sky
		if v > AIR_VALUE and not _furniture_cache.has(Vector3i(cell.x, above_y, cell.z)):
			return true
	return false


func _is_solid(cell: Vector3i) -> bool:
	if _voxel_world.get_cell(cell) == AIR_VALUE:
		return false
	if _furniture_cache.has(cell):
		return false  # furniture occupancy is transparent to this analysis (Rule 1, TR-022)
	return true


func _purge_stale_snapshot_entries(bbox: Dictionary, candidates: Dictionary) -> void:
	var stale: Array = []
	for cell in _region_valid_snapshot:
		var c: Vector3i = cell
		if _cell_in_bbox_xz(c, bbox) and not candidates.has(c):
			stale.append(c)
	for cell in stale:
		_region_valid_snapshot.erase(cell)


func _on_construction_completed(cells: Array) -> void:
	for cell in cells:
		_built_cells[cell] = true
	_schedule_pass()


func _on_cells_removed(cells: Array) -> void:
	for cell in cells:
		_built_cells.erase(cell)
	_schedule_pass()


func _on_furniture_placed(_cell: Vector3i, _item_id: String) -> void:
	_schedule_pass()


func _on_furniture_removed(cell: Vector3i, _item_id: String) -> void:
	_furniture_sheltered_snapshot.erase(cell)
	_schedule_pass()


func _schedule_pass() -> void:
	_pass_scheduled = true
	set_process(true)
