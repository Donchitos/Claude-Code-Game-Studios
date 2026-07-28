## Scaffold erection planner (story `building-034`, TD ruling D8 -- "fully
## specified, deterministically"). A pure, static planning library -- no
## instance, no cached state, mirrors [VillagerJobSelector]'s own established
## "stateless algorithm library" precedent. **This is the ONLY place a
## support/cantilever/connectivity search may run** (ADR-0007 §1a binding
## clause forbids it inside any predicate) -- this class is erection-time
## planning, never a hot-path predicate.
##
## D8.1: the plan targets a STAGING cell `A`, orthogonally adjacent to the
## unreachable blueprint cell `C` in X/Z with `|dy| <= 1` -- never `C`'s own
## address (D9 forbids a scaffold cell ever sharing an address with a
## blueprint cell). D8.2: prefer the column directly below `A`; fall back to
## the nearest supported column by horizontal Chebyshev, connected via a
## same-Y cantilever run. D8.3: among multiple valid plans, prefer fewest
## cells, then smallest cantilever distance, then
## [method VillagerJobSelector.lexicographic_cell_less_than] on `A` -- the
## codebase's one established tie-break, reused. D8.4: erection order is
## strictly ascending Y within the support column, then the cantilever run.
## D8.5: this plan is a PURE function of (world state, target cell) -- never
## the requesting villager; two villagers asking about the same cell get the
## same plan. Forbids (D8): RNG, wall-clock, frame counters, `Dictionary`
## iteration-order dependence, per-villager state, a diagonal staging cell, a
## second tie-break convention.
##
## D9 (forbid overlap): every cell this planner would create is validated via
## [method _is_valid_scaffold_address] -- empty in [VoxelWorldGrid], no
## blueprint cell in any non-`SCAFFOLD` project, no furniture occupant.
class_name ScaffoldErectionPlanner
extends RefCounted

## D8.1's 4 orthogonal X/Z directions a staging cell may sit in, and the 3
## `|dy| <= 1` heights it may sit at -- 12 total candidates, deterministic
## generation order (the FINAL selection is sorted, D8.3, so this generation
## order is never itself load-bearing).
const STAGING_XZ_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
]
const STAGING_DY_OFFSETS: Array[int] = [0, -1, 1]

## Bounded downward search depth for direct-support discovery -- generous
## relative to any plausible world height, while still a hard, deterministic
## ceiling (never an unbounded scan).
const MAX_SUPPORT_SEARCH_DEPTH: int = 256

## Sentinel meaning "no direct ground support found within
## [constant MAX_SUPPORT_SEARCH_DEPTH]."
const NO_SUPPORT: int = -2147483648


## The main entry point (D8). Returns [method ScaffoldPlan.no_plan] if no
## staging cell within reach has a valid erection plan (D5's bound-the-
## response requirement: "never erect a structure that does not make the
## target reachable; never loop").
static func plan_for_target(
	voxel_world: VoxelWorldGrid,
	scaffold_registry: Object,
	build_project_registry: BuildProjectRegistry,
	furniture_registry: Object,
	target_cell: Vector3i,
	cantilever_limit: int,
) -> ScaffoldPlan:
	var candidate_plans: Array[ScaffoldPlan] = []
	for staging_cell: Vector3i in _staging_candidates(target_cell):
		if not _is_valid_scaffold_address(voxel_world, build_project_registry, furniture_registry, staging_cell):
			continue
		if scaffold_registry != null and bool(scaffold_registry.has_scaffold(staging_cell)):
			continue
		var plan: ScaffoldPlan = _plan_for_staging_cell(
			voxel_world, build_project_registry, furniture_registry, staging_cell, cantilever_limit
		)
		if plan.has_plan():
			candidate_plans.append(plan)
	if candidate_plans.is_empty():
		return ScaffoldPlan.no_plan()
	candidate_plans.sort_custom(_less_than_by_selection_key)
	return candidate_plans[0]


## D8.1's 12 staging-cell candidates for [param target_cell] -- orthogonal
## X/Z only (never diagonal, D8 Forbids), `|dy| <= 1`.
static func _staging_candidates(target_cell: Vector3i) -> Array[Vector3i]:
	var candidates: Array[Vector3i] = []
	for offset: Vector2i in STAGING_XZ_OFFSETS:
		for dy: int in STAGING_DY_OFFSETS:
			candidates.append(target_cell + Vector3i(offset.x, dy, offset.y))
	return candidates


## D8.2 -- the plan for ONE staging cell: prefer the column directly below
## it; fall back to a cantilevered run from the nearest supported column.
static func _plan_for_staging_cell(
	voxel_world: VoxelWorldGrid,
	build_project_registry: BuildProjectRegistry,
	furniture_registry: Object,
	staging_cell: Vector3i,
	cantilever_limit: int,
) -> ScaffoldPlan:
	var direct_support_y: int = _find_direct_support_y(voxel_world, staging_cell.x, staging_cell.z, staging_cell.y)
	if direct_support_y != NO_SUPPORT:
		var cells: Array[Vector3i] = []
		for y in range(direct_support_y, staging_cell.y + 1):
			var cell := Vector3i(staging_cell.x, y, staging_cell.z)
			if not _is_valid_scaffold_address(voxel_world, build_project_registry, furniture_registry, cell):
				return ScaffoldPlan.no_plan()
			cells.append(cell)
		return ScaffoldPlan.new(cells, staging_cell, 0)

	var nearest: Vector2i = _find_nearest_ground_column(voxel_world, staging_cell, cantilever_limit)
	if nearest == Vector2i(NO_SUPPORT, NO_SUPPORT):
		return ScaffoldPlan.no_plan()
	var cantilever_distance: int = maxi(absi(nearest.x - staging_cell.x), absi(nearest.y - staging_cell.z))
	if cantilever_distance > cantilever_limit:
		return ScaffoldPlan.no_plan()

	var support_y: int = _find_direct_support_y(voxel_world, nearest.x, nearest.y, staging_cell.y)
	var cells: Array[Vector3i] = []
	for y in range(support_y, staging_cell.y + 1):
		cells.append(Vector3i(nearest.x, y, nearest.y))
	for cell: Vector3i in _bridge_run(nearest.x, nearest.y, staging_cell.x, staging_cell.z, staging_cell.y):
		cells.append(cell)
	for cell: Vector3i in cells:
		if not _is_valid_scaffold_address(voxel_world, build_project_registry, furniture_registry, cell):
			return ScaffoldPlan.no_plan()
	return ScaffoldPlan.new(cells, staging_cell, cantilever_distance)


## Scans downward from `(x, from_y, z)` for the first Y whose own
## below-neighbor reads SOLID in [param voxel_world] (D6.2: "the cell
## directly below it is solid -- terrain or a Built block -- never another
## scaffold cell's 'solidity'"). Reading solidity straight from the raw grid
## automatically excludes scaffold (scaffolding never touches
## [VoxelWorldGrid], D1) with no special-case branch needed. Returns
## [constant NO_SUPPORT] if nothing solid is found within
## [constant MAX_SUPPORT_SEARCH_DEPTH].
static func _find_direct_support_y(voxel_world: VoxelWorldGrid, x: int, z: int, from_y: int) -> int:
	for y in range(from_y, from_y - MAX_SUPPORT_SEARCH_DEPTH, -1):
		var below := Vector3i(x, y - 1, z)
		var contents: CellContents = voxel_world.get_cell(below)
		if contents != null and not contents.is_empty():
			return y
	return NO_SUPPORT


## D8.2's cantilever fallback: the nearest `(x, z)` column (horizontal
## Chebyshev, D6.1) that has direct ground support reachable up to
## [param staging_cell]'s own height, searched in expanding Chebyshev rings
## up to [param cantilever_limit], tie-broken lexicographically on `(x, z)`
## within a ring (deterministic, D8 Forbids "Dictionary iteration-order
## dependence"). Returns `Vector2i(NO_SUPPORT, NO_SUPPORT)` if none exists
## within the limit.
static func _find_nearest_ground_column(
	voxel_world: VoxelWorldGrid, staging_cell: Vector3i, cantilever_limit: int
) -> Vector2i:
	for distance in range(1, cantilever_limit + 1):
		var ring: Array[Vector2i] = _ring_xz_cells(staging_cell.x, staging_cell.z, distance)
		ring.sort_custom(_less_than_xz)
		for candidate: Vector2i in ring:
			if _find_direct_support_y(voxel_world, candidate.x, candidate.y, staging_cell.y) != NO_SUPPORT:
				return candidate
	return Vector2i(NO_SUPPORT, NO_SUPPORT)


## Every `(x, z)` pair at EXACTLY horizontal Chebyshev distance
## [param distance] from `(center_x, center_z)` -- the square ring's
## perimeter only, never its interior (mirrors
## [VillagerRescueTargetSearch._ring_cells]'s own 3D precedent, restricted to
## 2 horizontal axes per D6.1's "Y excluded" metric).
static func _ring_xz_cells(center_x: int, center_z: int, distance: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dx in range(-distance, distance + 1):
		cells.append(Vector2i(center_x + dx, center_z - distance))
		cells.append(Vector2i(center_x + dx, center_z + distance))
	for dz in range(-distance + 1, distance):
		cells.append(Vector2i(center_x - distance, center_z + dz))
		cells.append(Vector2i(center_x + distance, center_z + dz))
	return cells


## Deterministic lexicographic `(x, z)` tie-break for [method
## _find_nearest_ground_column]'s own ring walk.
static func _less_than_xz(a: Vector2i, b: Vector2i) -> bool:
	if a.x != b.x:
		return a.x < b.x
	return a.y < b.y


## D8.2's "connect with a same-Y cantilever run" -- a Chebyshev-shortest
## (diagonal-then-straight) walk from `(from_x, from_z)` to `(to_x, to_z)` at
## height [param y], EXCLUDING the start cell (already covered by the
## approach column's own topmost cell) and INCLUDING the end cell (the
## staging cell itself).
static func _bridge_run(from_x: int, from_z: int, to_x: int, to_z: int, y: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var x: int = from_x
	var z: int = from_z
	while x != to_x or z != to_z:
		if x < to_x:
			x += 1
		elif x > to_x:
			x -= 1
		if z < to_z:
			z += 1
		elif z > to_z:
			z -= 1
		cells.append(Vector3i(x, y, z))
	return cells


## D9 (RULED: Option (a), forbid overlap) -- a scaffold cell may only be
## created at an address that (i) reads EMPTY in [param voxel_world], (ii)
## has no blueprint cell in any non-`SCAFFOLD` project, and (iii) holds no
## furniture. Checked in this ONE place, at plan time.
static func _is_valid_scaffold_address(
	voxel_world: VoxelWorldGrid,
	build_project_registry: BuildProjectRegistry,
	furniture_registry: Object,
	cell: Vector3i,
) -> bool:
	if not voxel_world.is_in_bounds(cell):
		return false
	var contents: CellContents = voxel_world.get_cell(cell)
	if contents == null or not contents.is_empty():
		return false
	if build_project_registry != null:
		var owning_id: int = build_project_registry.project_at_cell(cell)
		if owning_id != -1:
			var owning_project: BuildProject = build_project_registry.get_project(owning_id)
			if owning_project != null and owning_project.kind != BuildProject.Kind.SCAFFOLD:
				return false
	if furniture_registry != null and bool(furniture_registry.has_occupant(cell)):
		return false
	return true


## D8.3's selection order among multiple valid plans: fewest cells, then
## smallest cantilever distance, then [method
## VillagerJobSelector.lexicographic_cell_less_than] on the staging cell --
## the codebase's one established tie-break, reused, never a second one.
static func _less_than_by_selection_key(a: ScaffoldPlan, b: ScaffoldPlan) -> bool:
	if a.cells.size() != b.cells.size():
		return a.cells.size() < b.cells.size()
	if a.cantilever_distance != b.cantilever_distance:
		return a.cantilever_distance < b.cantilever_distance
	return VillagerJobSelector.lexicographic_cell_less_than(a.staging_cell, b.staging_cell)
