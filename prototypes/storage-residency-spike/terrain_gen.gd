# Deterministic synthetic terrain generator — throwaway prototype code
# (ADR-0015 storage/residency spike).
#
# Reuses the terrace/biome FORMULA FAMILY from
# prototypes/last-seal-vertical-slice/voxel_world.gd (same constants, same
# noise-based terracing + tree stamping) so per-chunk generation cost is
# realistic, not a toy stand-in. Data-only: no mesh, no atlas, no material —
# this spike is the data layer, not rendering (ADR-0014 unaffected).
#
# Determinism is load-bearing: given the fixed SEED, fill_chunk(cc) always
# produces byte-identical output. That is what lets a pristine (never
# mutated) chunk be regenerated on page-in instead of read from disk
# (ADR-0015 §5, the sparse-persistence layer this spike's region files rely
# on for their "only mutated chunks are ever written" property).
class_name SpikeTerrainGen
extends RefCounted

const CHUNK := 16
const MAX_Y := 32
const WORLD_SIZE := 16000
const SEED := 1337
const AIR := 0
const TERRAIN_BASE := 1
const SAND := 5
const TRUNK := 30
const LEAVES := 31
const WATER := 40
const WATER_LEVEL := 6
const TREE_CLEARING_DIST := 70.0
const TREE_MOISTURE_THRESHOLD := 0.15
const TREE_CANOPY_ORTHOS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _hills_noise := FastNoiseLite.new()
var _continent_noise := FastNoiseLite.new()
var _moisture_noise := FastNoiseLite.new()


func _init() -> void:
	_hills_noise.seed = SEED
	_hills_noise.frequency = 0.012
	_continent_noise.seed = SEED
	_continent_noise.frequency = 0.0022
	_moisture_noise.seed = SEED + 7
	_moisture_noise.frequency = 0.006


func _dist_from_center(x: int, z: int) -> float:
	var center := Vector2(float(WORLD_SIZE) / 2.0, float(WORLD_SIZE) / 2.0)
	return Vector2(float(x), float(z)).distance_to(center)


func terrain_height(x: int, z: int) -> int:
	# Same terrace formula as the slice: flat settlement-core plateau, blended
	# 8-cell-stepped terraces beyond it (voxel_world.gd terrain_height()).
	var dist := _dist_from_center(x, z)
	if dist < 60.0:
		return 8
	var continent := _continent_noise.get_noise_2d(float(x), float(z))
	var core_blend := smoothstep(60.0, 150.0, dist)
	var smooth_raw := lerpf(8.0, 8.0 + continent * 18.0, core_blend)
	var terraced := int(floor(smooth_raw / 8.0)) * 8
	return clampi(terraced, 2, MAX_Y - 6)


func _terrain_band_value(ly: int) -> int:
	return TERRAIN_BASE + (ly * 3) / MAX_Y


func _is_beach_column(gx: int, gz: int, h: int) -> bool:
	if h > WATER_LEVEL + 1:
		return false
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dz == 0:
				continue
			if terrain_height(gx + dx, gz + dz) < WATER_LEVEL:
				return true
	return false


func _column_hash01(gx: int, gz: int, salt: int) -> float:
	var h := absi(hash(Vector3i(gx, gz, SEED + salt)))
	return float(h % 1000000) / 1000000.0


func _is_tree_column(gx: int, gz: int) -> bool:
	if _dist_from_center(gx, gz) <= TREE_CLEARING_DIST:
		return false
	var h := terrain_height(gx, gz)
	if h < WATER_LEVEL + 1:
		return false
	if _is_beach_column(gx, gz, h):
		return false
	if _terrain_band_value(h - 1) != TERRAIN_BASE:
		return false
	var moisture := _moisture_noise.get_noise_2d(float(gx), float(gz))
	if moisture <= TREE_MOISTURE_THRESHOLD:
		return false
	var density := remap(moisture, TREE_MOISTURE_THRESHOLD, 1.0, 1.0 / 80.0, 1.0 / 40.0)
	return _column_hash01(gx, gz, 0) < density


func _tree_trunk_height(gx: int, gz: int) -> int:
	return 4 + int(_column_hash01(gx, gz, 101) * 3.0)


func _stamp_cell(arr: PackedByteArray, cc: Vector2i, gx: int, gy: int, gz: int, value: int) -> void:
	if gy < 0 or gy >= MAX_Y:
		return
	var lx := gx - cc.x * CHUNK
	var lz := gz - cc.y * CHUNK
	if lx < 0 or lx >= CHUNK or lz < 0 or lz >= CHUNK:
		return   # outside this chunk — the owning chunk stamps it itself (pure fn of gx,gz)
	var idx := (gy * CHUNK + lz) * CHUNK + lx
	if arr[idx] == AIR:
		arr[idx] = value


func _stamp_trees(cc: Vector2i, arr: PackedByteArray) -> void:
	var col_min_x := cc.x * CHUNK - 2
	var col_max_x := cc.x * CHUNK + CHUNK + 2
	var col_min_z := cc.y * CHUNK - 2
	var col_max_z := cc.y * CHUNK + CHUNK + 2
	var trees: Array[Dictionary] = []
	for gz in range(col_min_z, col_max_z):
		for gx in range(col_min_x, col_max_x):
			if not _is_tree_column(gx, gz):
				continue
			var surface_y := terrain_height(gx, gz)
			var trunk_h := _tree_trunk_height(gx, gz)
			trees.append({"gx": gx, "gz": gz, "surface_y": surface_y, "trunk_h": trunk_h, "top_y": surface_y + trunk_h - 1})
	for t in trees:
		var gx: int = t["gx"]
		var gz: int = t["gz"]
		var surface_y: int = t["surface_y"]
		var trunk_h: int = t["trunk_h"]
		for i in trunk_h:
			_stamp_cell(arr, cc, gx, surface_y + i, gz, TRUNK)
	for t in trees:
		var gx: int = t["gx"]
		var gz: int = t["gz"]
		var top_y: int = t["top_y"]
		for d in TREE_CANOPY_ORTHOS:
			_stamp_cell(arr, cc, gx + d.x, top_y, gz + d.y, LEAVES)
		for dz2 in range(-1, 2):
			for dx2 in range(-1, 2):
				_stamp_cell(arr, cc, gx + dx2, top_y + 1, gz + dz2, LEAVES)
		_stamp_cell(arr, cc, gx, top_y + 2, gz, LEAVES)
		for d in TREE_CANOPY_ORTHOS:
			_stamp_cell(arr, cc, gx + d.x, top_y + 2, gz + d.y, LEAVES)


## Pure function of (SEED, cc) — same output every call, every process. THIS
## is the "regen from seed" path (ADR-0015 §5): a chunk absent from its
## region file is reconstructed by calling this, never invented or guessed.
func fill_chunk(cc: Vector2i) -> PackedByteArray:
	var arr := PackedByteArray()
	arr.resize(CHUNK * CHUNK * MAX_Y)   # zero-filled = air
	for lz in CHUNK:
		var gz := cc.y * CHUNK + lz
		for lx in CHUNK:
			var gx := cc.x * CHUNK + lx
			var h := terrain_height(gx, gz)
			var beach := _is_beach_column(gx, gz, h)
			for ly in h:
				var value := _terrain_band_value(ly)
				if beach and ly == h - 1:
					value = SAND
				arr[(ly * CHUNK + lz) * CHUNK + lx] = value
			if h < WATER_LEVEL:
				for ly in range(h, WATER_LEVEL):
					arr[(ly * CHUNK + lz) * CHUNK + lx] = WATER
	_stamp_trees(cc, arr)
	return arr
