## Candidate interior cell predicate (Story build-validation-002, ADR-0007
## primary; GDD `design/gdd/build-validation-navigability.md` Rule 1,
## [TR-build-validation-navigability-021]/[-022]/[-023]/[-031]/[-010]).
##
## A **candidate interior cell** is standable per Villager AI's Rule 8,
## consumed VERBATIM via [VillagerWalkabilityRules] (never re-derived here --
## TD ruling BV-4, `production/architecture-decisions-m02-preflight-
## 2026-07-26.md`), AND **roofed**: scanning straight up from the cell, the
## NEAREST solid cell sits at most `max_room_height` cells above it. Both
## halves are pure boolean predicates over [VoxelWorldGrid] data only -- this
## class holds no state, injects nothing, and is never instantiated (a
## `RefCounted`, static-functions-only twin, matching
## [VillagerWalkabilityRules]'s own established shape).
##
## **Furniture transparency (Rule 1, [TR-build-validation-navigability-022])
## needs no branch here at all.** Per TD ruling BV-1, furniture is never
## voxel data -- it never reaches [VoxelWorldGrid] (a Building-System-owned
## furniture registry holds item identity + cells instead,`building-028`) --
## so a furniture-occupied cell reads back EMPTY from [method
## VoxelWorldGrid.get_cell] by construction, identically to an unbuilt
## Planned blueprint cell ([TR-build-validation-navigability-031], Rule 7
## built-only). This class therefore has no furniture-registry parameter of
## any kind; the transparency property holds because there is nothing for it
## to read.
##
## **Character transparency** ([TR-build-validation-navigability-023]) is the
## identical mechanism: [VoxelWorldGrid] stores blocks, never villager
## positions, so a villager standing in an otherwise-candidate cell can never
## change what this predicate reads.
##
## Region formation (a maximal orthogonally-connected set of candidate
## cells), the outside-connection trace, and the Room/Sealed verdict are
## explicitly OUT OF SCOPE here -- stories 003/004.
class_name CandidateCellRules
extends RefCounted


## Candidate-interior-cell predicate (Rule 1, [TR-build-validation-
## navigability-021]): [param cell] is a candidate interior cell iff it is
## standable ([method VillagerWalkabilityRules.is_standable], consumed
## verbatim -- no local copy of `VILLAGER_CLEARANCE` or any other walkability
## constant exists anywhere in this file, [TR-build-validation-navigability-
## 010]) AND [method is_roofed] over [param max_room_height].
##
## Standability already guarantees the roof-scan starting point is at least
## `VILLAGER_CLEARANCE` cells above the floor -- a crawlspace whose roof sits
## 1-2 cells above the floor therefore fails standability BEFORE the roof
## scan ever runs (Edge Case 13): this predicate never needs a separate
## crawlspace branch, it falls straight out of composing the two checks.
##
## Pure query: reads only [param voxel_world]'s cell data, mutates nothing,
## caches nothing (Control Manifest Feature Layer Guardrail, same purity
## contract as [VillagerWalkabilityRules]'s own predicates).
static func is_candidate_interior_cell(
	voxel_world: VoxelWorldGrid, cell: Vector3i, max_room_height: int
) -> bool:
	if not VillagerWalkabilityRules.is_standable(voxel_world, cell):
		return false
	return is_roofed(voxel_world, cell, max_room_height)


## Roofed predicate (Rule 1's roof-scan half, [TR-build-validation-
## navigability-021], AC6): [param cell] is roofed iff the NEAREST solid cell
## scanning straight up from it -- offsets `1` through [param
## max_room_height] inclusive -- exists. Scanning in increasing order and
## returning on the first solid hit is exactly "the nearest solid cell sits
## at most `max_room_height` above it": a solid cell one step beyond
## `max_room_height` (or no solid cell at all within range -- open sky) is
## never observed by this loop and correctly reads as NOT roofed (AC6's
## boundary in both directions).
##
## Exposed publicly (not folded privately into [method
## is_candidate_interior_cell]) because Rule 2's "outside world" definition
## (story 004) is exactly the negation of this same scan ("open sky" = NOT
## roofed) -- a second, independent implementation of this scan would be
## exactly the kind of duplicated rule the Control Manifest forbids for
## walkability; this is the one shared home for it.
##
## Pure query, same guarantees as [method is_candidate_interior_cell].
static func is_roofed(voxel_world: VoxelWorldGrid, cell: Vector3i, max_room_height: int) -> bool:
	assert(voxel_world != null, "CandidateCellRules.is_roofed requires voxel_world")
	for offset in range(1, max_room_height + 1):
		if _is_solid(voxel_world, cell + Vector3i(0, offset, 0)):
			return true
	return false


## Solidity read for [method is_roofed]'s upward scan -- "solid" means
## Voxel World block occupancy only ([TR-build-validation-navigability-023]):
## an out-of-bounds cell ([method VoxelWorldGrid.get_cell] returning `null`)
## is never solid, matching [VillagerWalkabilityRules]'s own `_is_solid`
## convention (the world simply does not extend there).
static func _is_solid(voxel_world: VoxelWorldGrid, cell: Vector3i) -> bool:
	var contents: CellContents = voxel_world.get_cell(cell)
	return contents != null and not contents.is_empty()
