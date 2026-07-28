# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: full build->furnish->live loop, unguided <=5 min, cozy at scale
# Date: 2026-07-12
# Voxel World / Grid Data System per design/gdd/voxel-world.md + CONTRACTS.md,
# slice-reduced: packed per-chunk byte storage (ADR-0014 chunked approach),
# lazy chunk allocation, true per-cell face-culled mesher (walls/roofs are
# free-standing cells, unlike the heightfield mesher in
# prototypes/chunked-mesher/main.gd — that prototype validated STORAGE
# feasibility only; its mesher does not apply here). No physics — DDA picking.
extends Node3D

# --- Global constants (duplicated per file per CONTRACTS.md; keep values identical) ---
const CHUNK := 16
const MAX_Y := 32
const WORLD_SIZE := 2000              # cells per horizontal axis (full data world)
const REGION_RADIUS_CHUNKS := 12      # meshed/playable window radius around center
const SEED := 1337
# Cell ids (byte values in packed chunks)
const AIR := 0
const TERRAIN_BASE := 1               # 1..4 terrain height bands
const SAND := 5
const WOOD := 10
const STONE := 11
const THATCH := 12
const BED := 20
const TRUNK := 30
const LEAVES := 31
const WATER := 40

# --- Terracing + biomes (2026-07-12, Stonehearth-style) ---
const WATER_LEVEL := 6                 # lakes fill terraces below this
const TREE_CLEARING_DIST := 70.0       # no trees within this ring (matches core+buffer)
const TREE_MOISTURE_THRESHOLD := 0.15
const TREE_CANOPY_ORTHOS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

const BAND_COLORS: Array[Color] = [
	# Art bible §4.3 per-height-band mapping: warm-neutral low -> cool-pale high
	Color("9CAD6E"),  # Lowland  — grass/valley floor
	Color("A98F5E"),  # Midland  — earth/hills
	Color("7C818A"),  # Highland — stone
	Color("C9D3D8"),  # Peak     — snow, blends into fog
]

# --- Procedural texture atlas + classic voxel AO (readability pass 2026-07-12) ---
# Tiles laid out horizontally: [4 terrain bands][WOOD][STONE][THATCH][BED][unknown].
# Vertex color no longer carries block hue (the atlas does) — it's now a pure
# grayscale multiplier: per-face-direction shade * per-vertex AO brightness.
const ATLAS_TILE_PX := 16
const ATLAS_VALUES: Array[int] = [
	TERRAIN_BASE, TERRAIN_BASE + 1, TERRAIN_BASE + 2, TERRAIN_BASE + 3,
	WOOD, STONE, THATCH, BED,
	SAND, TRUNK, LEAVES, WATER,
]

enum FaceDir { TOP, BOTTOM, RIGHT, LEFT, BACK, FORWARD }
enum StreakAxis { NONE, HORIZONTAL, VERTICAL }

const FACE_NORMAL: Array[Vector3i] = [
	Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1),
]
const FACE_SHADE: Array[float] = [1.0, 1.0, 0.88, 0.88, 0.8, 0.8]  # milder now that AO carries definition
# Per face, the 4 corners (a,b,c,d matching the mesher's vertex order) each need
# two tangent "ortho" offsets (the two face-adjacent side cells used for AO).
# Entry layout per face: [a_side1, a_side2, b_side1, b_side2, c_side1, c_side2, d_side1, d_side2]
const FACE_ORTHOS: Array[Array] = [
	# TOP
	[Vector3i(-1, 0, 0), Vector3i(0, 0, -1), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(1, 0, 0), Vector3i(0, 0, 1), Vector3i(1, 0, 0), Vector3i(0, 0, -1)],
	# BOTTOM
	[Vector3i(-1, 0, 0), Vector3i(0, 0, -1), Vector3i(1, 0, 0), Vector3i(0, 0, -1), Vector3i(1, 0, 0), Vector3i(0, 0, 1), Vector3i(-1, 0, 0), Vector3i(0, 0, 1)],
	# RIGHT (+X)
	[Vector3i(0, -1, 0), Vector3i(0, 0, -1), Vector3i(0, 1, 0), Vector3i(0, 0, -1), Vector3i(0, 1, 0), Vector3i(0, 0, 1), Vector3i(0, -1, 0), Vector3i(0, 0, 1)],
	# LEFT (-X)
	[Vector3i(0, -1, 0), Vector3i(0, 0, -1), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 1, 0), Vector3i(0, 0, 1), Vector3i(0, 1, 0), Vector3i(0, 0, -1)],
	# BACK (+Z)
	[Vector3i(-1, 0, 0), Vector3i(0, -1, 0), Vector3i(1, 0, 0), Vector3i(0, -1, 0), Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0)],
	# FORWARD (-Z)
	[Vector3i(-1, 0, 0), Vector3i(0, -1, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(1, 0, 0), Vector3i(0, -1, 0)],
]
const AO_BRIGHTNESS: Array[float] = [1.0, 0.82, 0.68, 0.55]   # 0..3 occluders

signal cell_changed(changes: Array)    # Array of {cell: Vector3i, before: int, after: int} — ONE emission per write call (batched)
# SLICE VIEW (2026-07-22, BUILD UX PACKAGE feature 2): fires whenever
# set_slice_level() actually changes the level — VillagerAI subscribes to hide
# villagers above the cut without GameWorld needing to broker every caller.
signal slice_level_changed(level: int)

var _chunk_data: Dictionary[Vector2i, PackedByteArray] = {}    # lazily allocated — only touched chunks
var _chunk_nodes: Dictionary[Vector2i, MeshInstance3D] = {}    # only chunks with a built mesh
var _hills_noise: FastNoiseLite = FastNoiseLite.new()      # local roughness (was `_noise`)
var _continent_noise: FastNoiseLite = FastNoiseLite.new()  # broad elevation -> terraces/mountains
var _moisture_noise: FastNoiseLite = FastNoiseLite.new()   # forest placement
# SLICE VIEW: ShaderMaterial replaces the old StandardMaterial3D — see _ready()
# and res://chunk_terrain.gdshader. One shared instance for every chunk (as
# before), so setting the y_cut uniform once updates every chunk with no remesh.
var _material: ShaderMaterial = ShaderMaterial.new()
var _slice_level: int = MAX_Y   # MAX_Y = "off" (Home/reset default per task spec)
var _center_chunk: Vector2i = Vector2i.ZERO
var _region_chunk_min: Vector2i = Vector2i.ZERO
var _region_chunk_max: Vector2i = Vector2i.ZERO   # exclusive
var _region_cell_min: Vector2i = Vector2i.ZERO
var _region_cell_max: Vector2i = Vector2i.ZERO    # exclusive
var _value_tile_index: Dictionary[int, int] = {}   # cell value -> atlas tile index
var _unknown_tile_index: int = 0
var _atlas_tile_count: int = 0


func _ready() -> void:
	_hills_noise.seed = SEED
	_hills_noise.frequency = 0.012  # slice tuning: rolling hills, not per-cell speckle (was 0.05)
	_continent_noise.seed = SEED
	_continent_noise.frequency = 0.0022  # wider landforms (user: world should read bigger)
	_moisture_noise.seed = SEED + 7
	_moisture_noise.frequency = 0.006
	# SLICE VIEW (2026-07-22): chunk_terrain.gdshader replicates the previous
	# StandardMaterial3D look exactly (vertex-color-as-AO-modulate, cull
	# disabled per the winding note below, roughness 1 / no specular) and adds
	# ONE thing: a y_cut uniform + fragment discard above it (see the shader
	# file for the full writeup, including why VERTEX.y == world Y here).
	# DIAGNOSIS CONFIRMED 2026-07-20 (user close-up of a tree canopy rendering
	# inside-out): faces are wound for the OpenGL front-face convention (CCW),
	# but Godot fronts are CLOCKWISE — cull_back hid the outside of everything.
	# Every 'missing faces' report was this. Culling disabled (baked into the
	# shader's render_mode) as the immediate fix (10x frame headroom absorbs
	# the ~2x face cost); proper winding flip is the follow-up.
	_material.shader = preload("res://chunk_terrain.gdshader")
	_material.set_shader_parameter("y_cut", float(_slice_level) + 1.0)


func setup() -> void:
	_build_atlas()
	_center_chunk = Vector2i((WORLD_SIZE / 2) / CHUNK, (WORLD_SIZE / 2) / CHUNK)
	_region_chunk_min = _center_chunk - Vector2i(REGION_RADIUS_CHUNKS, REGION_RADIUS_CHUNKS)
	_region_chunk_max = _center_chunk + Vector2i(REGION_RADIUS_CHUNKS, REGION_RADIUS_CHUNKS)
	_region_cell_min = _region_chunk_min * CHUNK
	_region_cell_max = _region_chunk_max * CHUNK
	# Pass 1: fill terrain data for every chunk in the playable window.
	for cz in range(_region_chunk_min.y, _region_chunk_max.y):
		for cx in range(_region_chunk_min.x, _region_chunk_max.x):
			_fill_chunk_terrain(Vector2i(cx, cz))
	# Pass 2: mesh every chunk (data pass must finish first so cross-chunk
	# neighbor lookups at the mesher's border faces see committed terrain).
	for cz in range(_region_chunk_min.y, _region_chunk_max.y):
		for cx in range(_region_chunk_min.x, _region_chunk_max.x):
			_rebuild_chunk_mesh(Vector2i(cx, cz))
	# Deliberately no cell_changed emission here: per voxel-world.md Edge
	# Cases, terrain generation may emit "at most one batched signal... or
	# none, if listeners attach only after the Generated state" — true here,
	# since GameWorld calls this before any other system's setup().


func get_cell(cell: Vector3i) -> int:
	if cell.x < 0 or cell.z < 0 or cell.x >= WORLD_SIZE or cell.z >= WORLD_SIZE or cell.y < 0 or cell.y >= MAX_Y:
		return -1
	var cc := Vector2i(cell.x / CHUNK, cell.z / CHUNK)
	if not _chunk_data.has(cc):
		return AIR
	var arr: PackedByteArray = _chunk_data[cc]
	var lx := cell.x % CHUNK
	var lz := cell.z % CHUNK
	return arr[(cell.y * CHUNK + lz) * CHUNK + lx]


func set_cells(changes: Array) -> Array:
	var results: Array = []
	var chunk_writes: Dictionary[Vector2i, PackedByteArray] = {}   # cc -> in-progress array for this batch
	var touched_chunks: Dictionary[Vector2i, bool] = {}            # cc -> needs remesh (dedup set)
	for change: Dictionary in changes:
		var cell: Vector3i = change["cell"]
		var value: int = change["value"]
		if cell.x < 0 or cell.z < 0 or cell.x >= WORLD_SIZE or cell.z >= WORLD_SIZE or cell.y < 0 or cell.y >= MAX_Y:
			results.append({"cell": cell, "before": -1, "after": -1})
			continue
		var cc := Vector2i(cell.x / CHUNK, cell.z / CHUNK)
		var lx := cell.x % CHUNK
		var lz := cell.z % CHUNK
		var arr: PackedByteArray
		if chunk_writes.has(cc):
			arr = chunk_writes[cc]
		elif _chunk_data.has(cc):
			arr = _chunk_data[cc]
		else:
			arr = PackedByteArray()
			arr.resize(CHUNK * CHUNK * MAX_Y)   # zero-filled = air; lazy alloc for a never-touched chunk
		var idx := (cell.y * CHUNK + lz) * CHUNK + lx
		var before: int = arr[idx]
		arr[idx] = value
		chunk_writes[cc] = arr
		touched_chunks[cc] = true
		if lx == 0:
			touched_chunks[Vector2i(cc.x - 1, cc.y)] = true
		elif lx == CHUNK - 1:
			touched_chunks[Vector2i(cc.x + 1, cc.y)] = true
		if lz == 0:
			touched_chunks[Vector2i(cc.x, cc.y - 1)] = true
		elif lz == CHUNK - 1:
			touched_chunks[Vector2i(cc.x, cc.y + 1)] = true
		results.append({"cell": cell, "before": before, "after": value})
	for cc: Vector2i in chunk_writes:
		_chunk_data[cc] = chunk_writes[cc]
	for cc: Vector2i in touched_chunks:
		if _chunk_data.has(cc):
			_rebuild_chunk_mesh(cc)
	if not results.is_empty():
		cell_changed.emit(results)
	return results


## FEATURE 3 (2026-07-22, ghost snapping) + BUG A fix (user report: aiming at a
## built block showed no preview -- root cause was actually that DRAFT
## blueprint cells are AIR in real voxel data, so the pick ray passed straight
## through them; built cells 10..29 already hit via the uniform solidity check
## below and needed no fix). `extra_solid`, if valid, is an additional
## predicate (Callable(cell: Vector3i) -> bool) checked alongside the real
## voxel data -- building_system threads its blueprint-cell lookup through
## this while build mode is active, so the ray also stops on ghosts (any
## state except dig-orders) as if they were solid. Water is explicitly
## EXCLUDED from solidity here (BUG A follow-up) -- it read as clickable
## solid before this fix, which is wrong for a decorative lake surface.
func raycast_cells(origin: Vector3, dir: Vector3, max_dist: float = 200.0, extra_solid: Callable = Callable()) -> Dictionary:
	var d := dir.normalized()
	if d.length_squared() == 0.0:
		return {}
	var cell := Vector3i(floori(origin.x), floori(origin.y), floori(origin.z))
	if _is_pick_solid(get_cell(cell)) or (extra_solid.is_valid() and bool(extra_solid.call(cell))):
		return {"cell": cell, "normal": Vector3i.ZERO}   # ray origin embedded in solid geometry
	var step := Vector3i(
		1 if d.x > 0.0 else (-1 if d.x < 0.0 else 0),
		1 if d.y > 0.0 else (-1 if d.y < 0.0 else 0),
		1 if d.z > 0.0 else (-1 if d.z < 0.0 else 0))
	var t_max := Vector3(INF, INF, INF)
	var t_delta := Vector3(INF, INF, INF)
	if d.x != 0.0:
		t_delta.x = 1.0 / absf(d.x)
		var boundary_x: float = float(cell.x + (1 if step.x > 0 else 0))
		t_max.x = (boundary_x - origin.x) / d.x
	if d.y != 0.0:
		t_delta.y = 1.0 / absf(d.y)
		var boundary_y: float = float(cell.y + (1 if step.y > 0 else 0))
		t_max.y = (boundary_y - origin.y) / d.y
	if d.z != 0.0:
		t_delta.z = 1.0 / absf(d.z)
		var boundary_z: float = float(cell.z + (1 if step.z > 0 else 0))
		t_max.z = (boundary_z - origin.z) / d.z
	var t := 0.0
	var last_normal := Vector3i.ZERO
	while t <= max_dist:
		if t_max.x < t_max.y and t_max.x < t_max.z:
			t = t_max.x
			t_max.x += t_delta.x
			cell.x += step.x
			last_normal = Vector3i(-step.x, 0, 0)
		elif t_max.y < t_max.z:
			t = t_max.y
			t_max.y += t_delta.y
			cell.y += step.y
			last_normal = Vector3i(0, -step.y, 0)
		else:
			t = t_max.z
			t_max.z += t_delta.z
			cell.z += step.z
			last_normal = Vector3i(0, 0, -step.z)
		if t > max_dist:
			break
		var v := get_cell(cell)
		if _is_pick_solid(v) or (extra_solid.is_valid() and bool(extra_solid.call(cell))):
			return {"cell": cell, "normal": last_normal}
	return {}


## BUG A fix: solidity predicate for picking only -- every non-air cell value
## is solid (terrain 1..5, built blocks 10..29, trunk/leaves 30/31) EXCEPT
## water, which is a decorative surface the pick ray should pass through to
## whatever's beneath it (debatable per task discussion; this is the chosen
## behavior).
func _is_pick_solid(v: int) -> bool:
	return v > AIR and v != WATER


func is_in_region(cell: Vector3i) -> bool:
	if cell.y < 0 or cell.y >= MAX_Y:
		return false
	return cell.x >= _region_cell_min.x and cell.x < _region_cell_max.x \
		and cell.z >= _region_cell_min.y and cell.z < _region_cell_max.y


func get_region_aabb() -> AABB:
	var pos := Vector3(float(_region_cell_min.x), 0.0, float(_region_cell_min.y))
	var size := Vector3(
		float(_region_cell_max.x - _region_cell_min.x),
		float(MAX_Y),
		float(_region_cell_max.y - _region_cell_min.y))
	return AABB(pos, size)


## Added 2026-07-12 for BuildingSystem's textured ghost previews (see
## building_system.gd write-up): exposes the atlas texture + a value->UV-rect
## lookup so ghosts can render the REAL block tile, just translucent, instead
## of a flat tint. Valid only after setup() (_build_atlas already ran).
func get_atlas() -> Dictionary:
	return {
		"texture": _material.get_shader_parameter("albedo_texture"),
		"uv_rect": Callable(self, "_atlas_uv_rect_for_value"),
	}


## SLICE VIEW (2026-07-22): current cutoff cell-y (world cells with y >
## get_slice_level() are hidden). MAX_Y means "off" (nothing hidden).
func get_slice_level() -> int:
	return _slice_level


## True while a cut is actually in effect (level < MAX_Y).
func is_slice_active() -> bool:
	return _slice_level < MAX_Y


## Sets the slice cutoff (clamped 0..MAX_Y) and pushes the new y_cut to the
## ONE shared chunk material — every chunk updates instantly, no remesh.
## No-op (no signal) if the clamped value doesn't actually change.
func set_slice_level(level: int) -> void:
	var clamped: int = clampi(level, 0, MAX_Y)
	if clamped == _slice_level:
		return
	_slice_level = clamped
	_material.set_shader_parameter("y_cut", float(_slice_level) + 1.0)
	slice_level_changed.emit(_slice_level)


## Convenience for the Home-key / reset-button case (task spec: "resets to
## 'off' (MAX_Y)").
func reset_slice_level() -> void:
	set_slice_level(MAX_Y)


func _dist_from_center(x: int, z: int) -> float:
	var center := Vector2(float(WORLD_SIZE) / 2.0, float(WORLD_SIZE) / 2.0)
	return Vector2(float(x), float(z)).distance_to(center)


func terrain_height(x: int, z: int) -> int:
	# Stonehearth-style TERRACING (2026-07-12, supersedes the smooth-hill
	# tuning): continent noise (broad elevation -> which terrace/mountains)
	# blended with hills noise (local roughness within a terrace), quantized
	# to 4-cell steps. The settlement core stays a single clean plateau at
	# h=8 (dist<40); the 40..110 ring blends the RAW (pre-quantize) height
	# from the core's flat value up to full terrain so the first real
	# terrace edge lands outside the core instead of clipping it.
	var dist := _dist_from_center(x, z)
	if dist < 60.0:
		return 8
	var continent := _continent_noise.get_noise_2d(float(x), float(z))
	# TERRACE ALIASING FIX (2026-07-20): quantize ONLY the smooth continent
	# field. Feeding the hills noise into the quantizer made single columns
	# flip between adjacent 4-cell steps along terrace boundaries -> isolated
	# 4-tall needle pillars that read as detached floating faces (user
	# screenshots). Hills detail is added AFTER quantization, capped to +-1
	# cell, so it can never create a step jump.
	var core_blend := smoothstep(60.0, 150.0, dist)  # 0 just outside core -> 1 at dist>=150
	# 8-CELL STEPS (2026-07-20): 4-cell terraces were visually IMPERCEPTIBLE
	# from the colony camera (same grass above/below, aligned tile grids, no
	# depth cues) — the lips read as floating planks, the final root of every
	# 'missing faces' report. A step must be tall enough to exist perceptually.
	var smooth_raw := lerpf(8.0, 8.0 + continent * 18.0, core_blend)
	var terraced := int(floor(smooth_raw / 8.0)) * 8   # steps at y=..,0,8,16,24
	# NO per-column detail on terraces: even +-1-cell noise creates isolated
	# single-column bumps whose side faces read as floating shards from
	# grazing angles (their grass tops blend invisibly from above) — the
	# final form of the user's 'missing faces' reports. True Stonehearth
	# terraces are FLAT; variation comes from the terrace shapes themselves.
	return clampi(terraced, 2, MAX_Y - 6)


func _terrain_band_value(ly: int) -> int:
	return TERRAIN_BASE + (ly * 3) / MAX_Y


func _is_beach_column(gx: int, gz: int, h: int) -> bool:
	# Cheap approximation (coordinator-approved): Chebyshev-1 (8 neighbors)
	# instead of a full Chebyshev-3 search — a low (underwater) neighbor
	# within the immediate ring is enough to call this column a shoreline.
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
		return false   # settlement core + clearing ring: no trees
	var h := terrain_height(gx, gz)
	if h < WATER_LEVEL + 1:
		return false   # underwater
	if _is_beach_column(gx, gz, h):
		return false   # no trees standing in the sand
	if _terrain_band_value(h - 1) != TERRAIN_BASE:
		return false   # only the grass band (lowest terraces) grows forest
	var moisture := _moisture_noise.get_noise_2d(float(gx), float(gz))
	if moisture <= TREE_MOISTURE_THRESHOLD:
		return false   # sparse/zero outside forest-moisture pockets
	var density := remap(moisture, TREE_MOISTURE_THRESHOLD, 1.0, 1.0 / 80.0, 1.0 / 40.0)
	return _column_hash01(gx, gz, 0) < density


func _tree_trunk_height(gx: int, gz: int) -> int:
	return 4 + int(_column_hash01(gx, gz, 101) * 3.0)   # deterministic 4..6 (2-block-tall characters)


func _stamp_cell(cc: Vector2i, arr: PackedByteArray, gx: int, gy: int, gz: int, value: int) -> void:
	if gy < 0 or gy >= MAX_Y:
		return
	var lx := gx - cc.x * CHUNK
	var lz := gz - cc.y * CHUNK
	if lx < 0 or lx >= CHUNK or lz < 0 or lz >= CHUNK:
		return   # outside this chunk — the OWNING chunk stamps it itself
	var idx := (gy * CHUNK + lz) * CHUNK + lx
	if arr[idx] == AIR:
		arr[idx] = value   # never clobber terrain/water — a cliff clips the canopy


func _stamp_trees_for_chunk(cc: Vector2i, arr: PackedByteArray) -> void:
	# Iterate tree-candidate COLUMNS in this chunk's rect expanded by 2 (max
	# canopy reach is 1 cell out from its base column) so a tree rooted in a
	# neighboring chunk stamps its overhanging canopy cells into this chunk
	# identically, without needing that neighbor chunk's data at all — every
	# input here (terrain_height/_is_beach_column/moisture/hash) is a pure
	# function of (gx,gz), so both chunks compute the exact same tree.
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
	# PASS 1 (all trunks first): fixes the 2026-07-12 "hollow trunk" /
	# "orphan canopy" defect — two trees close enough for canopies to reach
	# each other always share the same surface_y=8 (only grass terrace that
	# grows forest), so their top_y values collide often (trunk_h is only
	# 3 or 4). The OLD single-pass-per-tree order let whichever tree's canopy
	# was stamped first (by scan order) steal a NEIGHBORING tree's own
	# top-trunk cell out from under it (air-only guard let LEAVES win the
	# race). Placing every candidate's full trunk before ANY canopy makes
	# trunk cells always win that collision, independent of scan order.
	for t in trees:
		var gx: int = t["gx"]
		var gz: int = t["gz"]
		var surface_y: int = t["surface_y"]
		var trunk_h: int = t["trunk_h"]
		for i in trunk_h:
			_stamp_cell(cc, arr, gx, surface_y + i, gz, TRUNK)
	# PASS 2: canopies, only landing on cells still air after ALL trunks are placed.
	for t in trees:
		var gx: int = t["gx"]
		var gz: int = t["gz"]
		var top_y: int = t["top_y"]
		# canopy layer 0 (trunk-top level): the 4 orthogonal neighbors only
		# (center is already TRUNK) -- corners skipped for a rounded read.
		for d in TREE_CANOPY_ORTHOS:
			_stamp_cell(cc, arr, gx + d.x, top_y, gz + d.y, LEAVES)
		# canopy layer 1 (top_y+1): full 3x3, the widest/densest layer.
		for dz2 in range(-1, 2):
			for dx2 in range(-1, 2):
				_stamp_cell(cc, arr, gx + dx2, top_y + 1, gz + dz2, LEAVES)
		# canopy layer 2 (top_y+2): plus-shape cap.
		_stamp_cell(cc, arr, gx, top_y + 2, gz, LEAVES)
		for d in TREE_CANOPY_ORTHOS:
			_stamp_cell(cc, arr, gx + d.x, top_y + 2, gz + d.y, LEAVES)


func _fill_chunk_terrain(cc: Vector2i) -> void:
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
					value = SAND   # surface cell only
				arr[(ly * CHUNK + lz) * CHUNK + lx] = value
			if h < WATER_LEVEL:
				for ly in range(h, WATER_LEVEL):
					arr[(ly * CHUNK + lz) * CHUNK + lx] = WATER
	_stamp_trees_for_chunk(cc, arr)
	_chunk_data[cc] = arr


func _rebuild_chunk_mesh(cc: Vector2i) -> void:
	if not _chunk_data.has(cc):
		return
	var arr: PackedByteArray = _chunk_data[cc]
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for ly in MAX_Y:
		var fy := float(ly)
		var fy1 := fy + 1.0
		for lz in CHUNK:
			var gz := cc.y * CHUNK + lz
			var fz := float(gz)
			for lx in CHUNK:
				var v: int = arr[(ly * CHUNK + lz) * CHUNK + lx]
				if v == AIR:
					continue
				var gx := cc.x * CHUNK + lx
				var fx := float(gx)
				var tile_index := _tile_index_for_value(v)
				# Minecraft's iconic readability trick: grass shows only on
				# TOP faces — every grass-band SIDE face renders as earth.
				# Without this, a 4-cell terrace cliff whose upper lip is
				# grass-sided visually merges with the grass below and its
				# sawtooth edge reads as floating shards (user reports).
				var side_tile := tile_index
				if v == TERRAIN_BASE:
					side_tile = _tile_index_for_value(TERRAIN_BASE + 1)
				if _neighbor_value(cc, arr, lx, ly + 1, lz) <= AIR:
					_append_face(verts, normals, colors, uvs, indices,
						Vector3(fx, fy1, fz), Vector3(fx, fy1, fz + 1), Vector3(fx + 1, fy1, fz + 1), Vector3(fx + 1, fy1, fz),
						FaceDir.TOP, tile_index, cc, arr, lx, ly, lz)
				if _neighbor_value(cc, arr, lx, ly - 1, lz) <= AIR:
					_append_face(verts, normals, colors, uvs, indices,
						Vector3(fx, fy, fz), Vector3(fx + 1, fy, fz), Vector3(fx + 1, fy, fz + 1), Vector3(fx, fy, fz + 1),
						FaceDir.BOTTOM, tile_index, cc, arr, lx, ly, lz)
				if _neighbor_value(cc, arr, lx + 1, ly, lz) <= AIR:
					_append_face(verts, normals, colors, uvs, indices,
						Vector3(fx + 1, fy, fz), Vector3(fx + 1, fy1, fz), Vector3(fx + 1, fy1, fz + 1), Vector3(fx + 1, fy, fz + 1),
						FaceDir.RIGHT, side_tile, cc, arr, lx, ly, lz)
				if _neighbor_value(cc, arr, lx - 1, ly, lz) <= AIR:
					_append_face(verts, normals, colors, uvs, indices,
						Vector3(fx, fy, fz), Vector3(fx, fy, fz + 1), Vector3(fx, fy1, fz + 1), Vector3(fx, fy1, fz),
						FaceDir.LEFT, side_tile, cc, arr, lx, ly, lz)
				if _neighbor_value(cc, arr, lx, ly, lz + 1) <= AIR:
					_append_face(verts, normals, colors, uvs, indices,
						Vector3(fx, fy, fz + 1), Vector3(fx + 1, fy, fz + 1), Vector3(fx + 1, fy1, fz + 1), Vector3(fx, fy1, fz + 1),
						FaceDir.BACK, side_tile, cc, arr, lx, ly, lz)
				if _neighbor_value(cc, arr, lx, ly, lz - 1) <= AIR:
					_append_face(verts, normals, colors, uvs, indices,
						Vector3(fx, fy, fz), Vector3(fx, fy1, fz), Vector3(fx + 1, fy1, fz), Vector3(fx + 1, fy, fz),
						FaceDir.FORWARD, side_tile, cc, arr, lx, ly, lz)
	if verts.is_empty():
		if _chunk_nodes.has(cc):
			(_chunk_nodes[cc] as MeshInstance3D).mesh = null
		return
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _material)
	if _chunk_nodes.has(cc):
		(_chunk_nodes[cc] as MeshInstance3D).mesh = mesh
	else:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		add_child(mi)
		_chunk_nodes[cc] = mi


func _neighbor_value(cc: Vector2i, arr: PackedByteArray, lx: int, ly: int, lz: int) -> int:
	if ly < 0 or ly >= MAX_Y:
		return -1   # world edge (no vertical chunking — MAX_Y is the full column height)
	if lx >= 0 and lx < CHUNK and lz >= 0 and lz < CHUNK:
		return arr[(ly * CHUNK + lz) * CHUNK + lx]
	var gx := cc.x * CHUNK + lx
	var gz := cc.y * CHUNK + lz
	return get_cell(Vector3i(gx, ly, gz))


func _build_atlas() -> void:
	_value_tile_index.clear()
	for i in ATLAS_VALUES.size():
		_value_tile_index[ATLAS_VALUES[i]] = i
	_unknown_tile_index = ATLAS_VALUES.size()
	_atlas_tile_count = ATLAS_VALUES.size() + 1
	var atlas_w := _atlas_tile_count * ATLAS_TILE_PX
	var img := Image.create(atlas_w, ATLAS_TILE_PX, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for tile_i in _atlas_tile_count:
		var value := ATLAS_VALUES[tile_i] if tile_i < ATLAS_VALUES.size() else -1
		var base_color := _base_color_for_tile(value)
		var noise_amp := _tile_noise_amplitude(value)
		var streak_axis := _tile_streak_axis(value)
		var col_streak := PackedFloat32Array()
		col_streak.resize(ATLAS_TILE_PX)
		for px in ATLAS_TILE_PX:
			col_streak[px] = (1.0 + (rng.randf() - 0.5) * 0.14) if streak_axis == StreakAxis.VERTICAL else 1.0
		for py in ATLAS_TILE_PX:
			var row_mult := (1.0 + (rng.randf() - 0.5) * 0.14) if streak_axis == StreakAxis.HORIZONTAL else 1.0   # horizontal plank/straw streaks
			for px in ATLAS_TILE_PX:
				var pixel_noise := 1.0 + (rng.randf() - 0.5) * noise_amp   # per-pixel variation, tile-specific amplitude
				var mult := pixel_noise * row_mult * col_streak[px]   # col_streak carries vertical bark-grain streaks
				if px == 0 or px == ATLAS_TILE_PX - 1 or py == 0 or py == ATLAS_TILE_PX - 1:
					mult *= 0.85   # 1px tile border so block boundaries read at a distance
				img.set_pixel(tile_i * ATLAS_TILE_PX + px, py, Color(
					clampf(base_color.r * mult, 0.0, 1.0),
					clampf(base_color.g * mult, 0.0, 1.0),
					clampf(base_color.b * mult, 0.0, 1.0)))
	var tex := ImageTexture.create_from_image(img)
	_material.set_shader_parameter("albedo_texture", tex)   # sampler filter (nearest) is baked into the shader hint


func _base_color_for_tile(value: int) -> Color:
	if value < 0:
		return Color.MAGENTA   # reserved "unknown value" tile
	if value >= TERRAIN_BASE and value < TERRAIN_BASE + BAND_COLORS.size():
		return BAND_COLORS[value - TERRAIN_BASE]
	match value:
		SAND:
			return Color("D8C9A0")
		WATER:
			return Color("5E93AD")  # brighter calm blue (horizon-band fix)
		TRUNK:
			return Color("5C4630")
		LEAVES:
			return Color("5E7D46")
	var def: ResourceItemDatabase.ItemDef = ResourceItemDatabase.get_by_cell_value(value)
	if def == null:
		return Color.MAGENTA   # visibly wrong instead of a silent crash — unknown built cell value
	return def.color


func _tile_noise_amplitude(value: int) -> float:
	match value:
		WATER:
			return 0.06   # calm, subtle ripple
		LEAVES:
			return 0.24   # high-noise mottle
	return 0.16   # default per-pixel variation (~+-8%)


func _tile_streak_axis(value: int) -> StreakAxis:
	match value:
		WOOD, THATCH:
			return StreakAxis.HORIZONTAL
		TRUNK:
			return StreakAxis.VERTICAL   # bark grain
	return StreakAxis.NONE


func _tile_index_for_value(v: int) -> int:
	return _value_tile_index.get(v, _unknown_tile_index)


func _atlas_uv_rect_for_value(cell_value: int) -> Rect2:
	var tile_index := _tile_index_for_value(cell_value)
	var u0 := float(tile_index) / float(_atlas_tile_count)
	var u1 := float(tile_index + 1) / float(_atlas_tile_count)
	return Rect2(u0, 0.0, u1 - u0, 1.0)


func _vertex_ao(cc: Vector2i, arr: PackedByteArray, lx: int, ly: int, lz: int, face_dir: Vector3i, o1: Vector3i, o2: Vector3i) -> int:
	# Classic voxel AO (0fps-style): both side-adjacent cells solid always
	# forces max occlusion regardless of the corner cell (avoids a bright
	# seam where the corner is empty but both sides already block light).
	var side1 := _neighbor_value(cc, arr, lx + face_dir.x + o1.x, ly + face_dir.y + o1.y, lz + face_dir.z + o1.z) > AIR
	var side2 := _neighbor_value(cc, arr, lx + face_dir.x + o2.x, ly + face_dir.y + o2.y, lz + face_dir.z + o2.z) > AIR
	if side1 and side2:
		return 3
	var corner := _neighbor_value(cc, arr,
		lx + face_dir.x + o1.x + o2.x, ly + face_dir.y + o1.y + o2.y, lz + face_dir.z + o1.z + o2.z) > AIR
	var count := 0
	if side1:
		count += 1
	if side2:
		count += 1
	if corner:
		count += 1
	return count


func _append_face(verts: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, uvs: PackedVector2Array, indices: PackedInt32Array,
		a: Vector3, b: Vector3, c: Vector3, d: Vector3, face: int, tile_index: int,
		cc: Vector2i, arr: PackedByteArray, lx: int, ly: int, lz: int) -> void:
	var face_dir: Vector3i = FACE_NORMAL[face]
	var shade: float = FACE_SHADE[face]
	var orthos: Array = FACE_ORTHOS[face]
	var ao_a := _vertex_ao(cc, arr, lx, ly, lz, face_dir, orthos[0], orthos[1])
	var ao_b := _vertex_ao(cc, arr, lx, ly, lz, face_dir, orthos[2], orthos[3])
	var ao_c := _vertex_ao(cc, arr, lx, ly, lz, face_dir, orthos[4], orthos[5])
	var ao_d := _vertex_ao(cc, arr, lx, ly, lz, face_dir, orthos[6], orthos[7])
	var m_a := shade * AO_BRIGHTNESS[ao_a]
	var m_b := shade * AO_BRIGHTNESS[ao_b]
	var m_c := shade * AO_BRIGHTNESS[ao_c]
	var m_d := shade * AO_BRIGHTNESS[ao_d]
	var own_value: int = arr[(ly * CHUNK + lz) * CHUNK + lx]
	if own_value == WATER:
		# Lakes sit in pits — full basin-wall AO paints the whole surface
		# near-black at distance. Water stays calm and bright.
		m_a = maxf(m_a, shade * 0.9)
		m_b = maxf(m_b, shade * 0.9)
		m_c = maxf(m_c, shade * 0.9)
		m_d = maxf(m_d, shade * 0.9)
	elif own_value == TRUNK:
		# The canopy above max-occludes every trunk side face (both AO side
		# samples hit LEAVES) — near-black bark reads as a MISSING face.
		m_a = maxf(m_a, shade * 0.78)
		m_b = maxf(m_b, shade * 0.78)
		m_c = maxf(m_c, shade * 0.78)
		m_d = maxf(m_d, shade * 0.78)
	var base := verts.size()
	verts.append_array([a, b, c, d])
	var n := Vector3(face_dir)
	normals.append_array([n, n, n, n])
	colors.append_array([Color(m_a, m_a, m_a), Color(m_b, m_b, m_b), Color(m_c, m_c, m_c), Color(m_d, m_d, m_d)])
	var u0 := float(tile_index) / float(_atlas_tile_count)
	var u1 := float(tile_index + 1) / float(_atlas_tile_count)
	uvs.append_array([Vector2(u0, 0.0), Vector2(u1, 0.0), Vector2(u1, 1.0), Vector2(u0, 1.0)])
	# Standard AO seam fix: flip the triangulation diagonal when the "a-c"
	# diagonal is more occluded than "b-d", to avoid the classic X-shaped
	# AO artifact on partially-occluded quads.
	if ao_a + ao_c > ao_b + ao_d:
		indices.append_array([base + 1, base + 2, base + 3, base + 1, base + 3, base + 0])
	else:
		indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
