# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: full build->furnish->live loop, unguided <=5 min, cozy at scale
# Date: 2026-07-12
# Villager AI per design/gdd/villager-ai-behavior.md + CONTRACTS.md, slice-reduced
# to 1 villager (structure kept N-capable): plain explicit FSM (ADR-0008), AStar3D
# graph over the playable region, incrementally patched on cell_changed (ADR-0007),
# current_cell is the atomic tick-boundary occupancy cell — visual position is
# cosmetic lerp only, never consulted by logic (ADR-0009). Tick-driven except the
# _process visual lerp (game_delta-scaled, per the clock rule).
#
# CONTRACT ADDITIONS beyond CONTRACTS.md's VillagerAI section (see task summary
# for the full list the integrator must wire): set_shelter_provider(Callable),
# get_bed_context(int) -> Dictionary.
#
# Deliberately NOT implemented (out of this slice's CONTRACTS.md scope): F4
# nudge-aside — BuildingSystem's contract here only exposes set_occupancy_provider
# for deferral, no vacate-request signal/method exists to respond to.
extends Node3D

signal state_changed(villager_id: int, state: int)       # 0 Deciding,1 Traveling,2 Working,3 Sleeping,4 Breather,5 Wandering
signal distress_changed(villager_id: int, kind: String)   # "trapped"|"ground_sleeping"|""
# ANTI-STUCK WATCHDOG (2026-07-23): fires whenever a permanently-stuck
# villager is teleport-rescued (see _update_watchdog/_rescue_villager).
signal villager_unstuck(id: int, from_cell: Vector3i, to_cell: Vector3i)

# --- World/registry constants (duplicated per CONTRACTS.md; keep values identical) ---
const WORLD_SIZE := 2000
const MAX_Y := 32

# --- Walkability (GDD Rules 8-9) ---
const CLEARANCE := 3   # cell + 2 above must be empty

# --- Movement (F1) ---
const MOVE_SPEED := 3.0                       # cells/game-second
const TICKS_PER_SECOND := 4.0                 # must match TimeTickSystem.TICKS_PER_SECOND
const MOVE_BUDGET_PER_TICK := MOVE_SPEED / TICKS_PER_SECOND   # 0.75 cells/tick

# --- Wander (F3) — slice tuning per task spec (GDD defaults: radius 8, interval 6) ---
const WANDER_RADIUS := 12
const WANDER_REPICK_TICKS := 16

# --- Jobs / life texture ---
const JOB_RETRY_TICKS := 20
const MAX_JOB_CLAIM_TRIES_PER_PASS := 3
const JOBS_BEFORE_BREAK := 8    # user 2026-07-20: 'they should work more'
const BREATHER_DURATION_TICKS := 40
const TRAPPED_RETRY_TICKS := 8

# --- Anti-stuck watchdog (2026-07-23) ---
# ~3s at TICKS_PER_SECOND=4.0. See _update_watchdog for the two trigger
# conditions (buried/floating vs. destination-with-zero-legal-steps).
const STUCK_THRESHOLD_TICKS := 12
const UNSTUCK_SEARCH_RADIUS := 12
# dy scan order for the rescue-cell ring search: same-y first, then nearest
# other levels outward (a rescued villager should land as close to its own
# floor as possible before trying a different one).
const _RESCUE_DY_ORDER: Array[int] = [0, 1, -1, 2, -2, 3, -3, 4, -4]

const SPAWN_NAMES: Array[String] = ["Hilda", "Bruno", "Mira"]  # user: more workers
const RNG_SEED := 1337   # shared project SEED constant (CONTRACTS.md)

# --- AStar3D point-id packing: x | y<<21 | z<<42, masked (ADR-0007) ---
const ID_MASK := (1 << 21) - 1
const ID_SHIFT_Y := 21
const ID_SHIFT_Z := 42

enum State { DECIDING, TRAVELING, WORKING, SLEEPING, BREATHER, WANDERING }
enum TravelPurpose { NONE, JOB, BED, WANDER, BREATHER_SPOT }

const STATE_LABELS := {
	State.DECIDING: "Thinking",
	State.TRAVELING: "On the way",
	State.WORKING: "Working",
	State.SLEEPING: "Sleeping",
	State.BREATHER: "Taking a break",
	State.WANDERING: "Strolling",
}

# 8 horizontal neighbor directions (N,E,S,W + diagonals); dy in {-1,0,1} is
# applied separately wherever these are used (24 combos total per cell).
const _NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1),
	Vector2i(0, -1), Vector2i(0, 1),
	Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
]

# On-site candidate cells for a job/bed target: the cell itself, then its
# 6 orthogonal neighbors (incl. directly above/below), in a fixed scan order
# (GDD Rule 5 / F4-style determinism).
# On-site stand candidates relative to the job cell. NEVER the job cell itself
# (standing in your own construction cell deadlocks the occupancy deferral).
# Order: same-level orthogonals, diagonals, then below levels down to -3
# (overhead reach for roofs — see _is_onsite slice relaxation).
const _ONSITE_OFFSETS: Array[Vector3i] = [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1),
	Vector3i(1, 0, 1), Vector3i(1, 0, -1), Vector3i(-1, 0, 1), Vector3i(-1, 0, -1),
	Vector3i(0, 1, 0), Vector3i(1, 1, 0), Vector3i(-1, 1, 0), Vector3i(0, 1, 1), Vector3i(0, 1, -1),
	Vector3i(0, -1, 0), Vector3i(1, -1, 0), Vector3i(-1, -1, 0), Vector3i(0, -1, 1), Vector3i(0, -1, -1),
	Vector3i(0, -2, 0), Vector3i(1, -2, 0), Vector3i(-1, -2, 0), Vector3i(0, -2, 1), Vector3i(0, -2, -1),
	Vector3i(0, -3, 0), Vector3i(1, -3, 0), Vector3i(-1, -3, 0), Vector3i(0, -3, 1), Vector3i(0, -3, -1),
	Vector3i(1, -3, 1), Vector3i(1, -3, -1), Vector3i(-1, -3, 1), Vector3i(-1, -3, -1),
]


# N-capable per-villager runtime record.
class Villager:
	var id: int = -1
	var display_name: String = ""
	var current_cell: Vector3i
	var path: Array[Vector3i] = []
	var move_progress: float = 0.0
	var state: int = State.DECIDING
	var travel_purpose: int = TravelPurpose.NONE
	var travel_target_cell: Vector3i

	var distress: String = ""
	var distress_trapped_cached: bool = false
	var trapped_retry_ticks_left: int = 0

	var has_owned_bed: bool = false
	var owned_bed_cell: Vector3i
	var has_claimed_job: bool = false
	var claimed_job_cell: Vector3i

	var job_retry_ticks_left: int = 0
	var wander_repick_ticks_left: int = 0
	var jobs_completed_streak: int = 0
	var breather_ticks_left: int = 0
	var sleeping_source: String = ""

	var visual_position: Vector3
	var visual_root: Node3D = null

	# Anti-stuck watchdog (2026-07-23).
	var stuck_ticks: int = 0
	var watchdog_prev_cell: Vector3i = Vector3i(999999999, 999999999, 999999999)  # sentinel: forces "changed" on tick 1
	var unstuck_count: int = 0


var _voxel_world: Node = null
var _building_system: Node = null
var _needs_mood: Node = null

var _astar := AStar3D.new()
var _villagers: Dictionary = {}     # int -> Villager
var _owned_beds: Dictionary = {}    # Vector3i -> int (owning villager id)
var _next_id: int = 1
var _rng := RandomNumberGenerator.new()

# Anti-stuck watchdog telemetry (2026-07-23): total teleport-rescues across
# every villager. Per-villager counts live on the Villager record (unstuck_count).
var _unstuck_count: int = 0

# CONTRACT ADDITION: optional shelter classification callback, wired by
# GameWorld from build_validation.is_cell_sheltered. Falls back to
# "unsheltered" when unset (task spec).
var _shelter_provider: Callable

# SLICE VIEW (2026-07-22, BUILD UX PACKAGE feature 2): mirrors
# voxel_world's slice_level_changed signal (subscribed in setup()) so a
# villager's visual root hides once its body cell is above the cut. MAX_Y
# ("off") means every villager stays visible — matches voxel_world's default.
var _slice_level: int = MAX_Y


# voxel_world/building_system/needs_mood are intentionally untyped, matching
# CONTRACTS.md's literal signature (mirrors the is_standable/is_step_legal
# mock-testability rationale above).
func setup(voxel_world, building_system, needs_mood) -> void:
	_voxel_world = voxel_world
	_building_system = building_system
	_needs_mood = needs_mood
	_rng.seed = RNG_SEED

	# SLICE VIEW: voxel_world is the single source of truth for the cut level;
	# subscribing here means ANY caller of voxel_world.set_slice_level() (HUD
	# buttons, PageUp/Down keys via GameWorld) keeps villager visibility in
	# sync with zero extra wiring at the call site.
	if _voxel_world.has_signal("slice_level_changed"):
		_voxel_world.slice_level_changed.connect(_on_slice_level_changed)

	_build_graph()

	var spawn_cell := _find_spawn_cell()
	for name in SPAWN_NAMES:
		var v := Villager.new()
		v.id = _next_id
		_next_id += 1
		v.display_name = name
		v.current_cell = _nearby_standable(spawn_cell, _next_id)
		v.visual_position = _cell_center(v.current_cell)
		v.state = State.DECIDING
		_villagers[v.id] = v
		_build_visual(v)
		_needs_mood.register_villager(v.id)
	_needs_mood.need_satisfied.connect(_on_need_satisfied)

	_building_system.set_occupancy_provider(Callable(self, "_is_cell_occupied"))
	_building_system.furniture_removed.connect(_on_furniture_removed)

	_voxel_world.cell_changed.connect(_on_cell_changed)
	TimeTickSystem.tick.connect(_on_tick)


func get_villager_ids() -> Array[int]:
	var ids: Array[int] = []
	for id in _villagers.keys():
		ids.append(id)
	return ids


func get_info(villager_id: int) -> Dictionary:
	var v: Villager = _villagers.get(villager_id)
	if v == null:
		return {}
	return {
		"name": v.display_name,
		"state": v.state,
		"state_label": STATE_LABELS.get(v.state, ""),
		"cell": v.current_cell,
		"visual_pos": v.visual_position,
		"distress": v.distress,
		"has_bed": v.has_owned_bed,
		"unstuck_count": v.unstuck_count,
	}


## Anti-stuck watchdog telemetry (2026-07-23): total teleport-rescues across
## every villager (see get_info()'s "unstuck_count" for the per-villager tally).
func get_unstuck_count() -> int:
	return _unstuck_count


## CONTRACT ADDITION (FEATURE 2, anti-stuck, 2026-07-23): wired by GameWorld
## into BuildingSystem.set_position_provider so the seal-prevention check can
## look up a claiming villager's current cell without BuildingSystem needing
## to track villager positions itself. Returns null for an unknown id.
func get_villager_cell(villager_id: int) -> Variant:
	var v: Villager = _villagers.get(villager_id)
	if v == null:
		return null
	return v.current_cell


# CONTRACT ADDITION: feeds needs_mood.set_context_provider (why-string
# disambiguation between "no bed" and "bed unreachable").
func get_bed_context(villager_id: int) -> Dictionary:
	var v: Villager = _villagers.get(villager_id)
	if v == null or not v.has_owned_bed:
		return {"has_bed": false, "bed_reachable": false}
	var reachable: bool = _find_onsite_path(v.current_cell, v.owned_bed_cell) != null
	return {"has_bed": true, "bed_reachable": reachable}


func pick_villager(origin: Vector3, dir: Vector3, max_t: float) -> Variant:
	var best_id: Variant = null
	var best_t := max_t + 1.0
	for v: Villager in _villagers.values():
		var center: Vector3 = v.visual_position + Vector3(0.0, 0.45, 0.0)
		var radius := 0.5
		var oc: Vector3 = origin - center
		var a := dir.dot(dir)
		if a <= 0.0:
			continue
		var b := 2.0 * oc.dot(dir)
		var c := oc.dot(oc) - radius * radius
		var disc := b * b - 4.0 * a * c
		if disc < 0.0:
			continue
		var sqrt_disc := sqrt(disc)
		var t0 := (-b - sqrt_disc) / (2.0 * a)
		var t1 := (-b + sqrt_disc) / (2.0 * a)
		var t: float = t0 if t0 >= 0.0 else t1
		if t < 0.0 or t > max_t or t > best_t:
			continue
		best_t = t
		best_id = v.id
	return best_id


func set_shelter_provider(cb: Callable) -> void:
	_shelter_provider = cb


# world is intentionally untyped (matches CONTRACTS.md's literal signature) —
# this keeps is_standable/is_step_legal testable against a non-Node mock world
# double in isolated unit tests, without requiring a full VoxelWorld instance.
const WATER_VALUE := 40  # biome water — never a walking surface

static func is_standable(world, cell: Vector3i) -> bool:
	var below := Vector3i(cell.x, cell.y - 1, cell.z)
	var below_value: int = world.get_cell(below)
	if below_value <= 0 or below_value == WATER_VALUE:
		return false
	for i in range(CLEARANCE):
		var c := Vector3i(cell.x, cell.y + i, cell.z)
		if world.get_cell(c) != 0:
			return false
	return true


static func is_step_legal(world, from: Vector3i, to: Vector3i) -> bool:
	if not is_standable(world, from) or not is_standable(world, to):
		return false
	var dy := to.y - from.y
	if absi(dy) > 1:
		return false
	var dx := to.x - from.x
	var dz := to.z - from.z
	if absi(dx) > 1 or absi(dz) > 1:
		return false
	if dx == 0 and dz == 0:
		return false   # not a step
	if dx != 0 and dz != 0:
		# Diagonal: same-level only. Flank checks at from.y are ASYMMETRIC for
		# climbing diagonals (edge legal downhill, illegal uphill -> graph/
		# predicate divergence, found by loop_test day 1). Climb orthogonally.
		if dy != 0:
			return false
		# Both flanking orthogonal cells passable (no corner-cutting) — Rule 9.
		var flank_a := Vector3i(to.x, from.y, from.z)
		var flank_b := Vector3i(from.x, from.y, to.z)
		if not is_standable(world, flank_a) or not is_standable(world, flank_b):
			return false
	return true


# --- FEATURE 2 (anti-stuck, 2026-07-23): seal-prevention primitive ----------
# Lightweight duck-typed world proxy: forwards get_cell to the real world for
# every cell except ONE override (the cell about to be written), so a single
# pending write can be simulated without touching real voxel data.
class _SealCheckWorld:
	var _real
	var _override_cell: Vector3i
	var _override_value: int
	func _init(real, override_cell: Vector3i, override_value: int) -> void:
		_real = real
		_override_cell = override_cell
		_override_value = override_value
	func get_cell(cell: Vector3i) -> int:
		if cell == _override_cell:
			return _override_value
		return _real.get_cell(cell)


## True if `builder_cell` would still have >= 1 legal step (is_step_legal) even
## after `write_cell` becomes solid (value `write_value`). Called by
## BuildingSystem.report_on_site right before a non-dig job completes
## ("don't seal your last exit") -- cheap: only builder_cell's 24 (8
## horizontal x 3 vertical) neighbor steps are re-evaluated against a
## single-cell world override, no global connectivity analysis.
static func has_escape_after_write(world, builder_cell: Vector3i, write_cell: Vector3i, write_value: int) -> bool:
	var proxy := _SealCheckWorld.new(world, write_cell, write_value)
	for offset in _NEIGHBOR_OFFSETS:
		for dy in range(-1, 2):
			var n := Vector3i(builder_cell.x + offset.x, builder_cell.y + dy, builder_cell.z + offset.y)
			if is_step_legal(proxy, builder_cell, n):
				return true
	return false


func _process(_delta: float) -> void:
	for v: Villager in _villagers.values():
		_update_visual(v)


# ---------------------------------------------------------------------------
# AStar3D graph construction & incremental patching (ADR-0007)
# ---------------------------------------------------------------------------

func _build_graph() -> void:
	_astar.clear()
	var aabb: AABB = _voxel_world.get_region_aabb()
	var min_x := int(floor(aabb.position.x))
	var min_z := int(floor(aabb.position.z))
	var max_x := int(floor(aabb.position.x + aabb.size.x))
	var max_z := int(floor(aabb.position.z + aabb.size.z))

	# O(region_area * MAX_Y) one-time boot scan — acceptable for a single-
	# villager slice; a terrain-height-banded scan is the obvious follow-up
	# optimization if boot time becomes a problem at higher villager counts.
	var standable_cells: Array[Vector3i] = []
	for x in range(min_x, max_x):
		for z in range(min_z, max_z):
			for y in range(0, MAX_Y):
				var cell := Vector3i(x, y, z)
				if not _voxel_world.is_in_region(cell):
					continue
				if is_standable(_voxel_world, cell):
					_astar.add_point(_cell_to_id(cell), Vector3(cell))
					standable_cells.append(cell)

	for cell: Vector3i in standable_cells:
		_connect_neighbors(cell)


func _connect_neighbors(cell: Vector3i) -> void:
	var id := _cell_to_id(cell)
	for offset in _NEIGHBOR_OFFSETS:
		for dy in range(-1, 2):
			var neighbor := Vector3i(cell.x + offset.x, cell.y + dy, cell.z + offset.y)
			var nid := _cell_to_id(neighbor)
			if id >= nid:
				continue   # each pair processed once, in canonical (lower id first) direction
			if not _astar.has_point(nid):
				continue
			if is_step_legal(_voxel_world, cell, neighbor):
				_astar.connect_points(id, nid, true)


static func _cell_to_id(cell: Vector3i) -> int:
	return (cell.x & ID_MASK) | ((cell.y & ID_MASK) << ID_SHIFT_Y) | ((cell.z & ID_MASK) << ID_SHIFT_Z)


static func _id_to_cell(id: int) -> Vector3i:
	var x := id & ID_MASK
	var y := (id >> ID_SHIFT_Y) & ID_MASK
	var z := (id >> ID_SHIFT_Z) & ID_MASK
	return Vector3i(x, y, z)


func _on_cell_changed(changes: Array) -> void:
	var envelope: Dictionary = {}   # Vector3i -> true (dedup set)
	for change in changes:
		var cell: Vector3i = change.cell
		_gather_patch_envelope(cell, envelope)
	_patch_graph(envelope.keys())

	var changed_cells: Array = []
	for change in changes:
		changed_cells.append(change.cell)
	_check_repaths(changed_cells)


func _gather_patch_envelope(cell: Vector3i, out: Dictionary) -> void:
	# Slice-quality envelope: the changed column's clearance band (Rule 8)
	# plus its 8 horizontal neighbors (covers Rule 9's diagonal flank checks
	# for steps touching this column). Wider than the strict per-movement
	# clearance envelope used by _check_repaths — the GRAPH must stay
	# globally consistent, not just whichever path is currently being walked.
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for dy in range(-2, 2):
				out[Vector3i(cell.x + dx, cell.y + dy, cell.z + dz)] = true


func _patch_graph(cells: Array) -> void:
	var touched: Dictionary = {}   # int id -> true
	for cell: Vector3i in cells:
		if not _voxel_world.is_in_region(cell):
			continue
		var id := _cell_to_id(cell)
		var should_exist := is_standable(_voxel_world, cell)
		var exists := _astar.has_point(id)
		if should_exist and not exists:
			_astar.add_point(id, Vector3(cell))
			touched[id] = true
		elif not should_exist and exists:
			_astar.remove_point(id)
		elif should_exist and exists:
			touched[id] = true
	for id in touched.keys():
		_reconnect_point(id)


func _reconnect_point(id: int) -> void:
	var cell := _id_to_cell(id)
	for existing_id in _astar.get_point_connections(id):
		_astar.disconnect_points(id, existing_id)
	for offset in _NEIGHBOR_OFFSETS:
		for dy in range(-1, 2):
			var neighbor := Vector3i(cell.x + offset.x, cell.y + dy, cell.z + offset.y)
			var nid := _cell_to_id(neighbor)
			if not _astar.has_point(nid):
				continue
			if is_step_legal(_voxel_world, cell, neighbor):
				_astar.connect_points(id, nid, true)


# ---------------------------------------------------------------------------
# Re-path filtering (Rule 10b) — negative case matters as much as positive:
# a write NOT touching the envelope must cost zero re-path evaluations.
# ---------------------------------------------------------------------------

func _check_repaths(changed_cells: Array) -> void:
	for v: Villager in _villagers.values():
		if v.path.is_empty():
			continue   # not moving
		if _envelope_intersects(v, changed_cells):
			_repath_current(v)


func _envelope_intersects(v: Villager, changed_cells: Array) -> bool:
	var full_path: Array[Vector3i] = [v.current_cell]
	full_path.append_array(v.path)
	for i in range(full_path.size()):
		var cell: Vector3i = full_path[i]
		for dy in range(0, CLEARANCE):
			if changed_cells.has(Vector3i(cell.x, cell.y + dy, cell.z)):
				return true
		if i + 1 < full_path.size():
			var nxt: Vector3i = full_path[i + 1]
			var dx := nxt.x - cell.x
			var dz := nxt.z - cell.z
			if dx != 0 and dz != 0:
				var flank_a := Vector3i(nxt.x, cell.y, cell.z)
				var flank_b := Vector3i(cell.x, cell.y, nxt.z)
				if changed_cells.has(flank_a) or changed_cells.has(flank_b):
					return true
	return false


func _repath_current(v: Villager) -> void:
	var result: Variant = _compute_path(v.current_cell, v.travel_target_cell)
	if result == null:
		_handle_repath_failure(v)
		return
	v.path = result
	v.move_progress = 0.0


func _handle_repath_failure(v: Villager) -> void:
	match v.travel_purpose:
		TravelPurpose.JOB:
			if v.has_claimed_job:
				_building_system.release_job(v.claimed_job_cell)
				v.has_claimed_job = false
			v.path.clear()
			v.travel_purpose = TravelPurpose.NONE
			_set_state(v, State.DECIDING)
		TravelPurpose.BED:
			v.path.clear()
			_enter_ground_sleep(v, "ground_bed_unreachable")
		_:
			v.path.clear()
			v.travel_purpose = TravelPurpose.NONE
			_set_state(v, State.DECIDING)


# ---------------------------------------------------------------------------
# Pathfinding helpers
# ---------------------------------------------------------------------------

# Returns Array[Vector3i] (possibly empty = already there) or null (unreachable).
func _compute_path(from_cell: Vector3i, to_cell: Vector3i) -> Variant:
	var from_id := _cell_to_id(from_cell)
	var to_id := _cell_to_id(to_cell)
	if not _astar.has_point(from_id) or not _astar.has_point(to_id):
		return null
	var id_path: PackedInt64Array = _astar.get_id_path(from_id, to_id)
	if id_path.is_empty():
		return null
	var cells: Array[Vector3i] = []
	for i in range(1, id_path.size()):
		cells.append(_id_to_cell(id_path[i]))
	return cells


# Tries target_cell itself, then its 6 orthogonal neighbors, fixed order.
func _find_onsite_path(from_cell: Vector3i, target_cell: Vector3i) -> Variant:
	var blueprint: Dictionary = _building_system.get_blueprint_cells()
	# FEATURE 2 safety (2026-07-22, found by loop_test): a dig job must never
	# let the villager stand directly ON TOP of the cell it's digging -- once
	# it completes, that's the villager's own footing gone, is_standable(own
	# current_cell) goes false, and _has_any_legal_step(from) then fails for
	# EVERY candidate step (is_standable(from) is checked first) -> permanent
	# "trapped" distress with no way out. Standing beside/diagonal-above (a
	# DIFFERENT column) or reaching up from below are all still fine -- only
	# the exact "directly above the target" offset is excluded, and only for
	# digs (a roof build legitimately stands on top of its own target).
	var is_dig: bool = bool(blueprint.get(target_cell, {}).get("dig", false))
	for offset in _ONSITE_OFFSETS:
		if is_dig and offset == Vector3i(0, 1, 0):
			continue
		var candidate := target_cell + offset
		if not _astar.has_point(_cell_to_id(candidate)):
			continue
		# Never stand inside a pending construction cell (own or another's) —
		# the stand spot itself, or any body-column cell, would deadlock/entomb.
		if blueprint.has(candidate) or blueprint.has(candidate + Vector3i(0, 1, 0)) 				or blueprint.has(candidate + Vector3i(0, 2, 0)):
			continue
		var result: Variant = _compute_path(from_cell, candidate)
		if result != null:
			return result
	return null


func _path_to_onsite(v: Villager, target_cell: Vector3i) -> bool:
	var result: Variant = _find_onsite_path(v.current_cell, target_cell)
	if result == null:
		return false
	v.path = result
	v.move_progress = 0.0
	v.travel_target_cell = target_cell
	return true


func _is_onsite(cell: Vector3i, target: Vector3i) -> bool:
	# SLICE RELAXATION: overhead reach up to 3 cells (roofs are otherwise
	# unbuildable without scaffolding/ladders — REAL production design gap,
	# flagged in REPORT.md; GDD rule is Manhattan distance <= 1).
	var d := cell - target
	if absi(d.x) + absi(d.y) + absi(d.z) <= 1:
		return true
	return absi(d.x) <= 1 and absi(d.z) <= 1 and d.y >= -3 and d.y <= 1


# ---------------------------------------------------------------------------
# Spawn placement
# ---------------------------------------------------------------------------

func _nearby_standable(origin: Vector3i, salt: int) -> Vector3i:
	# Spread multiple spawns over distinct standable cells near the origin.
	var offsets: Array[Vector2i] = [Vector2i(0, 0), Vector2i(2, 1), Vector2i(-2, 2), Vector2i(1, -2), Vector2i(3, 3)]
	var d: Vector2i = offsets[salt % offsets.size()]
	var c := Vector3i(origin.x + d.x, origin.y, origin.z + d.y)
	if is_standable(_voxel_world, c):
		return c
	return origin


func _find_spawn_cell() -> Vector3i:
	var center := Vector3i(WORLD_SIZE / 2, 0, WORLD_SIZE / 2)
	for radius in range(0, 32):
		for dx in range(-radius, radius + 1):
			for dz in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dz)) != radius:
					continue   # scan only the current ring
				var x := center.x + dx
				var z := center.z + dz
				var hint: int = _voxel_world.terrain_height(x, z)
				var y_start := maxi(0, hint - 2)
				for y in range(y_start, MAX_Y - CLEARANCE):
					var cell := Vector3i(x, y, z)
					if not _voxel_world.is_in_region(cell):
						continue
					if is_standable(_voxel_world, cell):
						return cell
	push_warning("villager_ai: no standable spawn cell found near region center — falling back to raw center")
	return center


# ---------------------------------------------------------------------------
# Visuals (capsule + box, no physics body; visual-only, never read by logic)
# ---------------------------------------------------------------------------

static func _cell_center(cell: Vector3i) -> Vector3:
	return Vector3(cell.x + 0.5, cell.y, cell.z + 0.5)


static func _step_cost(from_cell: Vector3i, to_cell: Vector3i) -> float:
	if from_cell == to_cell:
		return 0.0
	var dx := to_cell.x - from_cell.x
	var dz := to_cell.z - from_cell.z
	return 1.4 if (dx != 0 and dz != 0) else 1.0


func _build_visual(v: Villager) -> void:
	var root := Node3D.new()
	root.name = "Villager_%d" % v.id
	root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(root)

	var warm_cream := Color(0.93, 0.85, 0.72)

	var body := MeshInstance3D.new()
	# 2 blocks tall (user 2026-07-20: Minecraft proportions — blocks read
	# smaller, world reads bigger; walk clearance stays 3, logic unchanged).
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.4
	body.mesh = capsule
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = warm_cream
	body.material_override = body_mat
	body.position = Vector3(0.0, 0.1 + capsule.height * 0.5, 0.0)
	root.add_child(body)

	var head := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.26, 0.26, 0.26)
	head.mesh = box
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = warm_cream
	head.material_override = head_mat
	head.position = Vector3(0.0, 0.1 + capsule.height + box.size.y * 0.5, 0.0)
	root.add_child(head)

	v.visual_root = root
	root.position = v.visual_position


func _update_visual(v: Villager) -> void:
	var from_pos := _cell_center(v.current_cell)
	var to_cell: Vector3i = v.path[0] if not v.path.is_empty() else v.current_cell
	var to_pos := _cell_center(to_cell)
	var cost := _step_cost(v.current_cell, to_cell)
	var t := 0.0 if cost <= 0.0 else clampf(v.move_progress / cost, 0.0, 1.0)
	v.visual_position = from_pos.lerp(to_pos, t)

	if v.visual_root == null:
		return
	if v.state == State.SLEEPING:
		v.visual_root.position = v.visual_position - Vector3(0.0, 0.35, 0.0)
		v.visual_root.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	else:
		v.visual_root.position = v.visual_position
		v.visual_root.rotation_degrees = Vector3.ZERO
	# SLICE VIEW: hide the whole villager once their body cell is above the cut.
	v.visual_root.visible = v.current_cell.y <= _slice_level


func _on_slice_level_changed(level: int) -> void:
	_slice_level = level


# ---------------------------------------------------------------------------
# Movement (F1) — tick-driven progress, atomic cell arrival at tick boundary
# ---------------------------------------------------------------------------

func _advance_movement(v: Villager) -> void:
	if v.path.is_empty():
		v.move_progress = 0.0
		return
	v.move_progress += MOVE_BUDGET_PER_TICK
	while not v.path.is_empty():
		var next_cell: Vector3i = v.path[0]
		if next_cell == v.current_cell:
			v.path.pop_front()  # AStar paths include the start point — free
			continue
		var cost := _step_cost(v.current_cell, next_cell)
		if v.move_progress < cost:
			break
		# ADR-0009 race closure, second half: the re-path filter replaces
		# v.path, but an IN-FLIGHT step must also be re-validated at the
		# arrival boundary — the target cell may have solidified this tick
		# (found by loop_test day 1: villager entombed itself in a wall).
		if not is_step_legal(_voxel_world, v.current_cell, next_cell):
			v.move_progress = 0.0
			_handle_repath_failure(v)
			return
		v.move_progress -= cost
		v.current_cell = next_cell
		v.path.pop_front()


# ---------------------------------------------------------------------------
# FSM
# ---------------------------------------------------------------------------

func _on_tick() -> void:
	for v: Villager in _villagers.values():
		_advance_movement(v)
		match v.state:
			State.DECIDING:
				_decide(v)
			State.TRAVELING:
				_tick_traveling(v)
			State.WORKING:
				_tick_working(v)
			State.SLEEPING:
				_tick_sleeping(v)
			State.BREATHER:
				_tick_breather(v)
			State.WANDERING:
				_tick_wandering(v)
		_maybe_preempt_for_sleep(v)
		_update_distress(v)
		_update_watchdog(v)


func _set_state(v: Villager, new_state: int) -> void:
	if v.state == new_state:
		return
	v.state = new_state
	state_changed.emit(v.id, new_state)


func _decide(v: Villager) -> void:
	# Priority: urgent sleep > work > wander (Rule 2).
	if _needs_mood.is_urgent(v.id, "sleep"):
		_decide_sleep(v)
		return
	if _try_claim_and_path_job(v):
		return
	_enter_wandering(v)


func _maybe_preempt_for_sleep(v: Villager) -> void:
	if not _needs_mood.is_urgent(v.id, "sleep"):
		return
	match v.state:
		State.WORKING:
			# Graceful: this tick's report_on_site already ran (above, in
			# _tick_working) before this preemption check runs.
			if v.has_claimed_job:
				_building_system.release_job(v.claimed_job_cell)
				v.has_claimed_job = false
			v.travel_purpose = TravelPurpose.NONE
			_set_state(v, State.DECIDING)
		State.WANDERING, State.BREATHER:
			v.path.clear()
			v.travel_purpose = TravelPurpose.NONE
			_set_state(v, State.DECIDING)
		State.TRAVELING:
			if v.travel_purpose != TravelPurpose.BED:
				if v.travel_purpose == TravelPurpose.JOB and v.has_claimed_job:
					_building_system.release_job(v.claimed_job_cell)
					v.has_claimed_job = false
				v.path.clear()
				v.travel_purpose = TravelPurpose.NONE
				_set_state(v, State.DECIDING)
			# else: already heading to bed — no-op (Edge Case 3b).
		_:
			pass   # DECIDING (about to pick sleep) / SLEEPING (already correct)


# --- Sleep / bed ---

func _decide_sleep(v: Villager) -> void:
	var bed_cell: Vector3i
	var have_bed := false
	if v.has_owned_bed:
		bed_cell = v.owned_bed_cell
		have_bed = true
	else:
		var claimed: Variant = _claim_nearest_reachable_bed(v)
		if claimed != null:
			bed_cell = claimed
			have_bed = true
	if not have_bed:
		_enter_ground_sleep(v, "ground_no_bed_owned")
		return
	if _path_to_onsite(v, bed_cell):
		v.travel_purpose = TravelPurpose.BED
		if v.path.is_empty():
			_arrive_at_bed(v)
		else:
			_set_state(v, State.TRAVELING)
	else:
		_enter_ground_sleep(v, "ground_bed_unreachable")


func _claim_nearest_reachable_bed(v: Villager) -> Variant:
	var best_cell: Variant = null
	var best_len := -1
	var furniture: Dictionary = _building_system.get_furniture_cells()
	for cell: Vector3i in furniture.keys():
		if furniture[cell] != "bed":
			continue
		if _owned_beds.has(cell):
			continue
		var path: Variant = _find_onsite_path(v.current_cell, cell)
		if path == null:
			continue
		var length: int = (path as Array).size()
		if best_len == -1 or length < best_len:
			best_len = length
			best_cell = cell
	if best_cell != null:
		_owned_beds[best_cell] = v.id
		v.has_owned_bed = true
		v.owned_bed_cell = best_cell
	return best_cell


func _arrive_at_bed(v: Villager) -> void:
	var sheltered := false
	if _shelter_provider.is_valid():
		sheltered = _shelter_provider.call(v.owned_bed_cell)
	var source := "bed_sheltered" if sheltered else "bed_unsheltered"
	v.sleeping_source = source
	_needs_mood.start_recovery(v.id, "sleep", source)
	_set_state(v, State.SLEEPING)


func _enter_ground_sleep(v: Villager, source: String) -> void:
	v.path.clear()
	v.travel_purpose = TravelPurpose.NONE
	v.sleeping_source = source
	_needs_mood.start_recovery(v.id, "sleep", source)
	_set_state(v, State.SLEEPING)


func _tick_sleeping(v: Villager) -> void:
	# Edge Case 11: re-check shelter each tick while asleep in a bed; re-rate
	# (idempotent, no restart) if the roof completed/was removed mid-sleep.
	if not v.sleeping_source.begins_with("bed") or not _shelter_provider.is_valid():
		return
	var sheltered: bool = _shelter_provider.call(v.owned_bed_cell)
	var source := "bed_sheltered" if sheltered else "bed_unsheltered"
	if source != v.sleeping_source:
		v.sleeping_source = source
		_needs_mood.start_recovery(v.id, "sleep", source)


func _on_need_satisfied(villager_id: int, need: String) -> void:
	if need != "sleep":
		return
	var v: Villager = _villagers.get(villager_id)
	if v == null or v.state != State.SLEEPING:
		return
	_needs_mood.stop_recovery(villager_id, "sleep", "satisfied")
	v.sleeping_source = ""
	_set_state(v, State.DECIDING)


func _on_furniture_removed(cell: Vector3i, item_id: String) -> void:
	if item_id != "bed" or not _owned_beds.has(cell):
		return
	var owner_id: int = _owned_beds[cell]
	_owned_beds.erase(cell)
	var v: Villager = _villagers.get(owner_id)
	if v == null:
		return
	v.has_owned_bed = false
	if v.state == State.SLEEPING and v.owned_bed_cell == cell:
		_needs_mood.stop_recovery(v.id, "sleep", "bed_removed")
		v.sleeping_source = ""
		_set_state(v, State.DECIDING)


# --- Work ---

func _try_claim_and_path_job(v: Villager) -> bool:
	var tries := 0
	while tries < MAX_JOB_CLAIM_TRIES_PER_PASS:
		tries += 1
		var claimed: Variant = _building_system.claim_job(v.id)
		if claimed == null:
			return false
		var job_cell: Vector3i = claimed
		if _path_to_onsite(v, job_cell):
			v.has_claimed_job = true
			v.claimed_job_cell = job_cell
			v.travel_purpose = TravelPurpose.JOB
			if v.path.is_empty():
				_set_state(v, State.WORKING)
			else:
				_set_state(v, State.TRAVELING)
			return true
		_building_system.release_job(job_cell)
	return false


func _tick_working(v: Villager) -> void:
	if not _building_system.get_blueprint_cells().has(v.claimed_job_cell):
		_building_system.release_job(v.claimed_job_cell)
		v.has_claimed_job = false
		v.travel_purpose = TravelPurpose.NONE
		v.jobs_completed_streak += 1
		if v.jobs_completed_streak >= JOBS_BEFORE_BREAK:
			v.jobs_completed_streak = 0
			_enter_breather(v)
		else:
			_set_state(v, State.DECIDING)
		return
	if _is_onsite(v.current_cell, v.claimed_job_cell):
		_building_system.report_on_site(v.claimed_job_cell)
		# FEATURE 2 (anti-stuck, "don't seal your last exit"): report_on_site
		# may have silently released our claim this tick (seal-prevention
		# refused to let this completion wall off our own last exit) --
		# is_job_claimed_by lets us notice instead of hammering the same
		# doomed cell every tick; go find different work.
		if v.has_claimed_job and not _building_system.is_job_claimed_by(v.claimed_job_cell, v.id):
			v.has_claimed_job = false
			v.travel_purpose = TravelPurpose.NONE
			_set_state(v, State.DECIDING)
		return
	# Knocked off site (world changed under it) — try to get back on site.
	if _path_to_onsite(v, v.claimed_job_cell):
		v.travel_purpose = TravelPurpose.JOB
		_set_state(v, State.TRAVELING)
	else:
		_building_system.release_job(v.claimed_job_cell)
		v.has_claimed_job = false
		v.travel_purpose = TravelPurpose.NONE
		_set_state(v, State.DECIDING)


func _enter_breather(v: Villager) -> void:
	var target := _pick_wander_cell(v.current_cell)
	if target == v.current_cell or not _path_to_onsite(v, target):
		v.breather_ticks_left = BREATHER_DURATION_TICKS
		_set_state(v, State.BREATHER)
		return
	v.travel_purpose = TravelPurpose.BREATHER_SPOT
	_set_state(v, State.TRAVELING)


func _tick_breather(v: Villager) -> void:
	v.breather_ticks_left -= 1
	if v.breather_ticks_left <= 0:
		_set_state(v, State.DECIDING)


# --- Traveling dispatch (arrival handling for JOB/BED/WANDER/BREATHER_SPOT) ---

func _tick_traveling(v: Villager) -> void:
	if v.travel_purpose == TravelPurpose.JOB and v.has_claimed_job:
		if not _building_system.get_blueprint_cells().has(v.claimed_job_cell):
			# Edge Case 4: job revoked mid-travel.
			_building_system.release_job(v.claimed_job_cell)
			v.has_claimed_job = false
			v.travel_purpose = TravelPurpose.NONE
			_set_state(v, State.DECIDING)
			return
	if not v.path.is_empty():
		return   # still moving
	match v.travel_purpose:
		TravelPurpose.JOB:
			_set_state(v, State.WORKING)
		TravelPurpose.BED:
			_arrive_at_bed(v)
		TravelPurpose.BREATHER_SPOT:
			v.breather_ticks_left = BREATHER_DURATION_TICKS
			_set_state(v, State.BREATHER)
		TravelPurpose.WANDER:
			_set_state(v, State.WANDERING)
		_:
			_set_state(v, State.DECIDING)


# --- Wander (F3) ---

func _enter_wandering(v: Villager) -> void:
	v.travel_purpose = TravelPurpose.NONE
	v.job_retry_ticks_left = JOB_RETRY_TICKS
	_pick_new_wander_target(v)


func _pick_new_wander_target(v: Villager) -> void:
	v.wander_repick_ticks_left = WANDER_REPICK_TICKS
	var target := _pick_wander_cell(v.current_cell)
	if target == v.current_cell:
		_set_state(v, State.WANDERING)   # Edge Case 8: no other reachable cell
		return
	var result: Variant = _compute_path(v.current_cell, target)
	if result == null:
		_set_state(v, State.WANDERING)   # defensive; flood-fill guarantees reachability
		return
	v.path = result
	v.move_progress = 0.0
	v.travel_target_cell = target
	v.travel_purpose = TravelPurpose.WANDER
	_set_state(v, State.TRAVELING)


func _tick_wandering(v: Villager) -> void:
	v.job_retry_ticks_left -= 1
	if v.job_retry_ticks_left <= 0:
		v.job_retry_ticks_left = JOB_RETRY_TICKS
		if _try_claim_and_path_job(v):
			return
	if v.path.is_empty() and v.state == State.WANDERING:
		v.wander_repick_ticks_left -= 1
		if v.wander_repick_ticks_left <= 0:
			_pick_new_wander_target(v)


# Bounded flood-fill (F3): uniformly chosen standable+reachable cell within
# WANDER_RADIUS (horizontal Chebyshev distance) of origin.
func _pick_wander_cell(origin: Vector3i) -> Vector3i:
	var visited: Dictionary = {origin: true}
	var frontier: Array[Vector3i] = [origin]
	var candidates: Array[Vector3i] = [origin]
	while not frontier.is_empty():
		var next_frontier: Array[Vector3i] = []
		for cell in frontier:
			for offset in _NEIGHBOR_OFFSETS:
				for dy in range(-1, 2):
					var n := Vector3i(cell.x + offset.x, cell.y + dy, cell.z + offset.y)
					if visited.has(n):
						continue
					visited[n] = true
					if _chebyshev_xz(origin, n) > WANDER_RADIUS:
						continue
					if not _astar.has_point(_cell_to_id(n)):
						continue
					if not is_step_legal(_voxel_world, cell, n):
						continue
					candidates.append(n)
					next_frontier.append(n)
		frontier = next_frontier
	return candidates[_rng.randi_range(0, candidates.size() - 1)]


static func _chebyshev_xz(a: Vector3i, b: Vector3i) -> int:
	return maxi(absi(a.x - b.x), absi(a.z - b.z))


# --- Trapped / distress (Edge Case 2) ---

func _has_any_legal_step(cell: Vector3i) -> bool:
	for offset in _NEIGHBOR_OFFSETS:
		for dy in range(-1, 2):
			var n := Vector3i(cell.x + offset.x, cell.y + dy, cell.z + offset.y)
			if is_step_legal(_voxel_world, cell, n):
				return true
	return false


func _update_distress(v: Villager) -> void:
	v.trapped_retry_ticks_left -= 1
	if v.trapped_retry_ticks_left <= 0:
		v.trapped_retry_ticks_left = TRAPPED_RETRY_TICKS
		v.distress_trapped_cached = not _has_any_legal_step(v.current_cell)

	var kind := ""
	if v.distress_trapped_cached:
		kind = "trapped"
	elif v.state == State.SLEEPING and v.sleeping_source.begins_with("ground"):
		kind = "ground_sleeping"

	if kind != v.distress:
		v.distress = kind
		distress_changed.emit(v.id, kind)


# --- Anti-stuck watchdog (2026-07-23) ---
# Slice-scope safety net, NOT full build-order planning: catches a villager
# left permanently unable to act (buried/floating, or holding a destination/
# job with zero legal steps out of its own cell while its position hasn't
# moved) and teleport-rescues it after STUCK_THRESHOLD_TICKS. Idle villagers
# with no destination/job are deliberately excluded from the (b) branch below
# (don't teleport a wanderer just for waiting between repicks).

func _update_watchdog(v: Villager) -> void:
	var buried_or_floating := not is_standable(_voxel_world, v.current_cell)
	var has_destination := v.state == State.TRAVELING or v.state == State.WORKING
	var position_unchanged := v.current_cell == v.watchdog_prev_cell
	var stuck_now: bool = buried_or_floating \
		or (has_destination and position_unchanged and not _has_any_legal_step(v.current_cell))
	v.stuck_ticks = v.stuck_ticks + 1 if stuck_now else 0
	v.watchdog_prev_cell = v.current_cell
	if v.stuck_ticks >= STUCK_THRESHOLD_TICKS:
		_rescue_villager(v)


func _rescue_villager(v: Villager) -> void:
	var from_cell: Vector3i = v.current_cell
	var to_cell: Vector3i = _find_rescue_cell(from_cell)
	v.current_cell = to_cell
	v.visual_position = _cell_center(to_cell)
	v.path.clear()
	v.move_progress = 0.0
	v.stuck_ticks = 0
	v.watchdog_prev_cell = to_cell
	if v.has_claimed_job:
		_building_system.release_job(v.claimed_job_cell)
		v.has_claimed_job = false
	v.travel_purpose = TravelPurpose.NONE
	_set_state(v, State.DECIDING)
	v.unstuck_count += 1
	_unstuck_count += 1
	villager_unstuck.emit(v.id, from_cell, to_cell)


## Ring search outward from `origin` (radius up to UNSTUCK_SEARCH_RADIUS) for
## the nearest standable, unoccupied cell -- same-y first, then nearby y
## (_RESCUE_DY_ORDER), before falling back to the spawn area if nothing in
## range qualifies.
func _find_rescue_cell(origin: Vector3i) -> Vector3i:
	for radius in range(0, UNSTUCK_SEARCH_RADIUS + 1):
		for dy in _RESCUE_DY_ORDER:
			for dx in range(-radius, radius + 1):
				for dz in range(-radius, radius + 1):
					if maxi(absi(dx), absi(dz)) != radius:
						continue   # ring only -- interior already scanned at a smaller radius
					var candidate := Vector3i(origin.x + dx, origin.y + dy, origin.z + dz)
					if not _voxel_world.is_in_region(candidate):
						continue
					if not is_standable(_voxel_world, candidate):
						continue
					if _is_cell_occupied(candidate):
						continue
					return candidate
	return _find_spawn_cell()


# --- BuildingSystem occupancy provider ---

func _is_cell_occupied(cell: Vector3i) -> bool:
	# Occupied = anywhere in a villager's BODY COLUMN (feet + 2 clearance cells),
	# not just the feet cell — otherwise walls get built through heads and the
	# builder ends up entombed (found by loop_test day 1).
	for v: Villager in _villagers.values():
		if cell.x == v.current_cell.x and cell.z == v.current_cell.z 				and cell.y >= v.current_cell.y and cell.y <= v.current_cell.y + 2:
			return true
	return false
