## Candidate region formation & affected-region scoping (Story
## build-validation-003, ADR-0007 primary; GDD `design/gdd/build-validation-
## navigability.md` Rule 1's region definition + Implementation Notes'
## affected-region scoping, [TR-build-validation-navigability-024]/[-020]/
## [-023]/[-059]).
##
## **Membership vs. traversal -- the load-bearing distinction this whole class
## exists to get right** (Implementation Notes: "Getting this backwards is
## exactly what makes AC37's corner-touching case wrong"): a region's
## MEMBERSHIP is plain 6-neighbour-in-3D orthogonal adjacency over cells that
## pass [method CandidateCellRules.is_candidate_interior_cell] -- it is
## deliberately NOT the villager movement graph. [method
## VillagerWalkabilityRules.is_step_legal]'s flanked-diagonal rule belongs
## exclusively to story 004's outside-connection TRACE; this class never
## calls [VillagerWalkabilityRules] at all, only [CandidateCellRules] (which
## itself delegates standability to [VillagerWalkabilityRules] -- this class
## has no need to touch it a second time). Two regions touching only
## corner-to-corner are therefore always TWO regions here, regardless of
## whether a legal flanked diagonal could later connect them for
## reachability purposes (story 004, AC37).
##
## This is NOT the "plain 4/8-neighbor flood-fill used as the movement graph"
## the Control Manifest forbids (Feature Layer: "no plain 4/8-neighbor
## flood-fill in Build Validation") -- that prohibition targets substituting
## a raw neighbor-walk for REACHABILITY (story 004's job, which must use
## [VillagerWalkabilityRules] exactly). Region MEMBERSHIP is a different,
## orthogonal (pun intended) question by design -- the story's own Control
## Manifest note: "region membership is orthogonal by design -- the
## distinction is load-bearing."
##
## **Affected-region scoping** (Implementation Notes): [method
## form_affected_regions] never scans the whole world (that is the load
## pass's job, story 005) -- it seeds from the pass's own changed cells plus
## their immediate candidate neighbourhood, then expands each seed by
## connectivity via [method form_region]. Region detection is fully
## recomputed for the touched region(s) per event, with no caching and no
## incremental delta in MVP ([TR-build-validation-navigability-020]) --
## deliberately unbounded by any knob (Control Manifest Feature Layer
## Guardrail: "Build Validation BFS exceeds one frame above ~12k connected
## cells" is a documented, accepted-risk boundary, not a reason to add a
## bounding knob here).
##
## **World-edge cells** ([TR-build-validation-navigability-059], AC11)
## contribute neither wall nor opening: a boundary cell simply fails [method
## CandidateCellRules.is_candidate_interior_cell] (which fails standability,
## which reads [method VoxelWorldGrid.get_cell] returning `null` out of
## bounds) and is therefore never added to the frontier -- no explicit
## in-bounds check exists anywhere in this file; the property holds by
## construction through the shared predicate, exactly like
## [CandidateCellRules]'s own boundary behavior.
##
## **Character transparency** ([TR-build-validation-navigability-023], AC38)
## is the identical mechanism one level up: this class's only external read is
## [CandidateCellRules]/[VoxelWorldGrid] block data via [method form_region]'s
## BFS -- there is no character/villager-position parameter anywhere in this
## file's signatures, so a mocked character occupying an otherwise-candidate
## cell can never change region membership. The property is structural, not a
## branch this class contains.
##
## A pure, stateless algorithm library -- no instance, no cached state --
## mirroring [CandidateCellRules]/[VillagerRepathFilter]/
## [VillagerRescueTargetSearch]'s own established "separate stateless
## algorithm library" precedent.
class_name BuildValidationRegionFormation
extends RefCounted


## The 6 orthogonal neighbour offsets defining region MEMBERSHIP adjacency
## (GDD Implementation Notes: "6-neighbour in 3D / 4-neighbour in-plane") --
## the full 3D set, including vertical, because two candidate interior cells
## stacked directly on top of one another are legitimately one region by this
## definition even though that is never a movement-graph question (story 004
## owns traversal separately). Declared once, here, so [method form_region]
## and [method form_affected_regions] never re-derive it independently.
const _MEMBERSHIP_NEIGHBOR_OFFSETS: Array[Vector3i] = [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0), Vector3i(0, -1, 0),
	Vector3i(0, 0, 1), Vector3i(0, 0, -1),
]


## Forms the maximal orthogonally-connected candidate region containing
## [param seed_cell] via a plain BFS (ADR-0007's reference
## `Dictionary[Vector3i, bool]` visited-set + `Array[Vector3i]` frontier
## shape) over cells passing [method
## CandidateCellRules.is_candidate_interior_cell].
##
## If [param seed_cell] itself is not a candidate interior cell, returns an
## EMPTY [BuildValidationRegion] (size 0) -- there is no region rooted at a
## non-candidate cell; this is not an error case (a caller scoping an
## affected neighbourhood, [method form_affected_regions], routinely probes
## cells that turn out not to be candidates, e.g. a cell that is now solid
## wall).
static func form_region(
	voxel_world: VoxelWorldGrid, seed_cell: Vector3i, max_room_height: int
) -> BuildValidationRegion:
	assert(voxel_world != null, "BuildValidationRegionFormation.form_region requires voxel_world")
	var visited: Dictionary[Vector3i, bool] = {}
	if not CandidateCellRules.is_candidate_interior_cell(voxel_world, seed_cell, max_room_height):
		return BuildValidationRegion.new(visited)

	var frontier: Array[Vector3i] = [seed_cell]
	while not frontier.is_empty():
		var current: Vector3i = frontier.pop_back()
		if visited.has(current):
			continue
		visited[current] = true
		for offset: Vector3i in _MEMBERSHIP_NEIGHBOR_OFFSETS:
			var neighbor: Vector3i = current + offset
			if visited.has(neighbor):
				continue
			if CandidateCellRules.is_candidate_interior_cell(voxel_world, neighbor, max_room_height):
				frontier.append(neighbor)
	return BuildValidationRegion.new(visited)


## Affected-region scoping (Implementation Notes): given [param changed_cells]
## -- the triggering pass's own changed cells, never the whole world -- returns
## every DISTINCT [BuildValidationRegion] reachable from the seed pool of those
## cells plus their immediate 6-neighbourhood. Two changed cells that land in
## the same connected region contribute only ONE entry in the result (a shared
## `already_covered` set across the whole call de-duplicates re-forming the
## same region twice); a changed cell that is not itself a candidate but has a
## candidate neighbour still correctly seeds that neighbour's region (e.g. a
## wall was removed -- the removed cell itself is not an interior candidate,
## but the room it just opened into is). An empty or all-non-candidate [param
## changed_cells] set correctly returns an empty array -- there is no region
## to report.
static func form_affected_regions(
	voxel_world: VoxelWorldGrid, changed_cells: Array[Vector3i], max_room_height: int
) -> Array[BuildValidationRegion]:
	assert(
		voxel_world != null,
		"BuildValidationRegionFormation.form_affected_regions requires voxel_world"
	)
	var seed_pool: Dictionary[Vector3i, bool] = {}
	for changed_cell: Vector3i in changed_cells:
		seed_pool[changed_cell] = true
		for offset: Vector3i in _MEMBERSHIP_NEIGHBOR_OFFSETS:
			seed_pool[changed_cell + offset] = true

	var already_covered: Dictionary[Vector3i, bool] = {}
	var regions: Array[BuildValidationRegion] = []
	for seed: Vector3i in seed_pool:
		if already_covered.has(seed):
			continue
		var region: BuildValidationRegion = form_region(voxel_world, seed, max_room_height)
		if region.size() == 0:
			continue
		for member: Vector3i in region.cell_list():
			already_covered[member] = true
		regions.append(region)

	return regions
