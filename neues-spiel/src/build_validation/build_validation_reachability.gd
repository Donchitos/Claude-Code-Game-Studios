## Outside-connection trace & Room/Sealed verdict (Story build-validation-004,
## ADR-0007 primary; GDD `design/gdd/build-validation-navigability.md` Rules
## 2/3, [TR-build-validation-navigability-008]/[-009]/[-025]/[-026]/[-027]/
## [-037]).
##
## **The reach graph is the villager movement graph, consumed VERBATIM** via
## [VillagerWalkabilityRules] (never re-derived here -- TD ruling BV-4,
## `production/architecture-decisions-m02-preflight-2026-07-26.md`):
## standability with `villager_clearance` = 3, orthogonal steps with
## `max_step_height` = 1, and diagonal steps ONLY when both flanking
## orthogonal cells are passable (no corner-cutting) -- exactly [method
## VillagerWalkabilityRules.is_standable] / [method
## VillagerWalkabilityRules.is_step_legal], called directly, never a plain
## 4/8-neighbor flood-fill (Control Manifest Feature Layer Forbidden).
##
## **"Open sky"** ([method is_open_sky]) reuses [method
## CandidateCellRules.is_roofed]'s exact scan with the result inverted --
## standable AND NOT roofed -- rather than writing a second scan
## (Implementation Notes: "Open sky reuses story 002's roof scan with the
## result inverted. Do not write a second scan.").
##
## **The trace** ([method is_outside_connected]) is the ADR's
## `_trace_reachability` shape (visited `Dictionary[Vector3i, bool]`, frontier
## `Array[Vector3i]`, early-return `true` on the first open-sky standable cell
## reached, `false` on frontier exhaustion), seeded from EVERY interior cell of
## the region -- a region carries many interior cells, and an escape may be
## rooted at any one of them, not necessarily an arbitrarily-chosen single
## seed. It deliberately walks through ANY standable cell reached, including
## another region's own interior ([TR-build-validation-navigability-026], Edge
## Case 14) -- region MEMBERSHIP (story 003, strictly orthogonal) and
## reachability TRAVERSAL (here, the full movement graph) are separate by
## design; a region touching another only corner-to-corner may still reach
## open sky through the other's interior and door via a legal flanked
## diagonal.
##
## **[method classify_region]** is Rules 2/3's full verdict: below
## `min_room_cells` -> [constant Verdict.OPEN] (never even reachability-
## checked -- Rule 2 requires BOTH conditions, and size is the strictly
## cheaper one to evaluate first); at or above it, [constant Verdict.ROOM] iff
## [method is_outside_connected], otherwise [constant Verdict.SEALED] -- a
## candidate region with NO walkable connection to the outside is a sealed
## space, never a room ([TR-build-validation-navigability-027]).
##
## **Never blocks, reverts, or calls any Building System API** ([TR-build-
## validation-navigability-037]): this file references no Building System
## type anywhere, by construction -- it is a pure query over [VoxelWorldGrid]
## data via the shared predicates, exactly like [CandidateCellRules] /
## [BuildValidationRegionFormation]. A `RefCounted`, static-functions-only
## twin, never instantiated -- mirrors [VillagerWalkabilityRules]'s /
## [CandidateCellRules]'s own established shape.
##
## Out of scope here (stories 005/006/008): the pass lifecycle/snapshot/edge-
## detection, shelter classification of furniture, and the warning/info
## signal tiers -- this class supplies only the per-region trace + verdict
## those stories consume.
##
## Story build-validation-010 (this revision) adds [method is_reachable]: the
## SAME BFS trace shape as [method is_outside_connected] -- identical [method
## _standable_neighbors] neighbor generation over the identical shared
## predicates -- generalized from "seeded from a region's interior cells,
## stops at ANY open-sky cell" to "seeded from ONE start cell, stops at ONE
## specific target cell." This is the "Build Validation reachability verdict"
## half of AC36's property corpus
## (`tests/integration/build_validation/reachability_property_corpus_test.gd`),
## cross-checked per (start, target) pair against Villager AI's independent
## `AStar3D` shortest-path query ([method VillagerNavGraph.find_path]) -- the
## ADR-0007 guard against the two traversal implementations silently
## diverging ("Reachable" is the agreement axis; path COST is never compared,
## per the story's own Implementation Notes). Not a second, duplicated
## traversal algorithm: both [method is_outside_connected] and [method
## is_reachable] delegate every neighbor-candidate decision to the identical
## private [method _standable_neighbors] helper below -- only the seed set
## and the stop condition differ.
class_name BuildValidationReachability
extends RefCounted


## A candidate region's classification (GDD States and Transitions table):
## [constant OPEN] -- below `min_room_cells`, never reachability-checked;
## [constant ROOM] -- meets the size threshold AND has a walkable outside
## connection; [constant SEALED] -- meets the size threshold but has NONE
## ([TR-build-validation-navigability-027], Rule 3 -- "never a room").
enum Verdict { OPEN, ROOM, SEALED }


## The 8 in-plane (dx, dz) neighbor directions, paired with [constant
## _VERTICAL_OFFSETS] below, forming the movement graph's candidate-neighbor
## set (Implementation Notes: "the 8 in-plane offsets at Δy ∈ {-1, 0, +1}") --
## the same 8-direction set as [VillagerNavGraph]'s own `HORIZONTAL_FULL_OFFSETS`
## (declared independently here rather than as a cross-module constant
## reference, since a BFS trace -- unlike [VillagerNavGraph]'s one-time graph
## construction -- walks all 8 directions from every visited cell; there is no
## "half the pairs, visited once" optimization available to a single-
## direction reachability walk).
const _HORIZONTAL_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
]

## The 3 vertical offsets a legal step may span (GDD Rule 9: `|height
## difference| <= 1`), checked against every horizontal direction above.
const _VERTICAL_OFFSETS: Array[int] = [-1, 0, 1]


## "Outside world" predicate (Rule 2, [TR-build-validation-navigability-009]):
## [param cell] is open sky iff it is standable ([method
## VillagerWalkabilityRules.is_standable]) AND NOT roofed ([method
## CandidateCellRules.is_roofed] over [param max_room_height]) -- the exact
## inverse of Rule 1's roof scan, reusing that one shared implementation
## rather than a second copy.
static func is_open_sky(voxel_world: VoxelWorldGrid, cell: Vector3i, max_room_height: int) -> bool:
	if not VillagerWalkabilityRules.is_standable(voxel_world, cell):
		return false
	return not CandidateCellRules.is_roofed(voxel_world, cell, max_room_height)


## The outside-connection trace (Rule 2, [TR-build-validation-navigability-
## 008]/[-009]/[-026]): a BFS over the villager movement graph, seeded from
## EVERY interior cell of [param region], that returns `true` on the FIRST
## open-sky standable cell reached, or `false` once the frontier is exhausted
## (the ADR's `_trace_reachability` shape, multi-seeded). Walks through ANY
## standable cell along the way, including another region's own interior --
## reachability makes no distinction ([TR-build-validation-navigability-026],
## Edge Case 14); this function holds no [BuildValidationRegion] boundary
## awareness once the walk begins -- only the SEED set comes from [param
## region].
##
## An empty [param region] (size 0) trivially returns `false` -- there is no
## interior cell to seed a frontier from.
static func is_outside_connected(
	voxel_world: VoxelWorldGrid, region: BuildValidationRegion, max_room_height: int
) -> bool:
	assert(
		voxel_world != null, "BuildValidationReachability.is_outside_connected requires voxel_world"
	)
	assert(region != null, "BuildValidationReachability.is_outside_connected requires region")
	var visited: Dictionary[Vector3i, bool] = {}
	var frontier: Array[Vector3i] = region.cell_list()
	while not frontier.is_empty():
		var current: Vector3i = frontier.pop_back()
		if visited.has(current):
			continue
		visited[current] = true
		if is_open_sky(voxel_world, current, max_room_height):
			return true
		for neighbor: Vector3i in _standable_neighbors(voxel_world, current):
			if not visited.has(neighbor):
				frontier.append(neighbor)
	return false


## The Room/Sealed(/Open) verdict (Rules 2/3, [TR-build-validation-
## navigability-025]/[-027]): [param region] is [constant Verdict.OPEN] if it
## has fewer than [param min_room_cells] interior cells (never reachability-
## checked -- Rule 2 requires size AND reachability, and the size half is
## strictly cheaper); otherwise [constant Verdict.ROOM] iff [method
## is_outside_connected], else [constant Verdict.SEALED] -- a candidate region
## with NO walkable outside connection is a sealed space, never a room.
static func classify_region(
	voxel_world: VoxelWorldGrid,
	region: BuildValidationRegion,
	min_room_cells: int,
	max_room_height: int,
) -> Verdict:
	if region.size() < min_room_cells:
		return Verdict.OPEN
	if is_outside_connected(voxel_world, region, max_room_height):
		return Verdict.ROOM
	return Verdict.SEALED


## Point-to-point reachability query (Story build-validation-010's AC36
## property corpus) -- see this class's own doc comment for why this is a
## generalization of [method is_outside_connected]'s trace, not a second
## traversal implementation. `[param from_cell] == [param to_cell]` returns
## `true` immediately without running a BFS at all -- a villager already
## standing on its own target cell is trivially "there," matching [method
## VillagerNavGraph.find_path]'s own same-cell single-element-path contract
## (AStar3D's `get_id_path(id, id)` returns `[id]`, not empty), so the two
## sides' zero-length-path convention agrees by construction rather than by
## coincidence.
##
## Neither endpoint's own standability is re-verified here -- same contract
## as [method is_outside_connected]'s region-cell seeding: the caller is
## responsible for supplying already-standable cells (AC36's own corpus
## samples pairs "drawn from that world's standable cells"). Reads only
## [param voxel_world] via the shared predicates; no mutation, no cached
## state (same purity guarantee as every other method in this class).
static func is_reachable(voxel_world: VoxelWorldGrid, from_cell: Vector3i, to_cell: Vector3i) -> bool:
	assert(voxel_world != null, "BuildValidationReachability.is_reachable requires voxel_world")
	if from_cell == to_cell:
		return true
	var visited: Dictionary[Vector3i, bool] = {}
	var frontier: Array[Vector3i] = [from_cell]
	while not frontier.is_empty():
		var current: Vector3i = frontier.pop_back()
		if visited.has(current):
			continue
		visited[current] = true
		if current == to_cell:
			return true
		for neighbor: Vector3i in _standable_neighbors(voxel_world, current):
			if not visited.has(neighbor):
				frontier.append(neighbor)
	return false


## Movement-graph neighbor candidates for [param current] (Implementation
## Notes): the 8 in-plane offsets x Δy ∈ {-1, 0, +1} (24 raw candidates),
## filtered by [method VillagerWalkabilityRules.is_standable] THEN [method
## VillagerWalkabilityRules.is_step_legal] -- both shared predicates, called
## directly, exactly as Rule 2 requires ("consumed verbatim"). Standability is
## checked FIRST since [method VillagerWalkabilityRules.is_step_legal] assumes
## both endpoints are already standable (its own documented contract) --
## checking order here honours that contract rather than relying on it
## accidentally holding.
static func _standable_neighbors(voxel_world: VoxelWorldGrid, current: Vector3i) -> Array[Vector3i]:
	var neighbors: Array[Vector3i] = []
	for offset: Vector2i in _HORIZONTAL_OFFSETS:
		for dy: int in _VERTICAL_OFFSETS:
			var neighbor: Vector3i = current + Vector3i(offset.x, dy, offset.y)
			if not VillagerWalkabilityRules.is_standable(voxel_world, neighbor):
				continue
			if not VillagerWalkabilityRules.is_step_legal(voxel_world, current, neighbor):
				continue
			neighbors.append(neighbor)
	return neighbors
