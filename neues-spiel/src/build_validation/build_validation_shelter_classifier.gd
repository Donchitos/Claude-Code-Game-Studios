## Shelter classification predicate (Story build-validation-006, ADR-0007
## primary; GDD `design/gdd/build-validation-navigability.md` Rule 5, Rule 3,
## Edge Case 8, [TR-build-validation-navigability-029]).
##
## **A LIVE lookup, never a cached-snapshot read** (Implementation Notes:
## "Classification is a pure lookup: the item's cell -> its region (story
## 003) -> that region's verdict (story 004). No separate geometry."): for
## each of [param cells] this forms a fresh [BuildValidationRegion] via
## [method BuildValidationRegionFormation.form_region] and classifies it via
## [method BuildValidationReachability.classify_region] -- the exact same two
## calls [method BuildValidation.run_load_pass] already makes for its
## full-world rebuild, just scoped to one item's occupied cell(s) on demand.
##
## This is deliberate, not an optimization gap: [member
## BuildValidation._region_snapshot] is Rule 11's REGION edge-detection
## memory, patched only for cells that remain candidate members of some
## AFFECTED region ([method BuildValidationRegionFormation.form_affected_regions]
## never returns a region for a seed cell that has dropped OUT of candidate
## status entirely -- e.g. Edge Case 7's roof hole, where the cell directly
## under the hole fails [method CandidateCellRules.is_candidate_interior_cell]
## the instant the roof opens, so [method
## BuildValidationRegionFormation.form_region] returns an empty region for it
## and it is filtered from the affected-regions result). Reading that stale
## snapshot entry for such a cell would return its PRIOR verdict (e.g. ROOM),
## not the correct "no longer even a candidate, therefore not in any room"
## answer. A live lookup has no such staleness window: [method
## BuildValidationRegionFormation.form_region] called on a cell that just lost
## candidate status simply returns an empty region again, which classifies as
## [constant BuildValidationReachability.Verdict.OPEN] (never ROOM) -- exactly
## the correct answer, computed fresh every time.
##
## **Multi-cell footprint** (QA Test Cases: "a multi-cell furniture item --
## classification follows its own occupied cell(s) per Rule 5, coordinate with
## `building-016`"): sheltered iff EVERY occupied cell independently
## classifies as Room. A documented interpretation -- no multi-cell furniture
## placement exists yet (`building-016`) to pin this down further -- chosen
## because Rule 5 defines shelter per-CELL ("its cell lies inside a valid
## room"), and a bed cannot be "half inside, half outside" a room and still
## earn the room's full 1.0x rate.
##
## A pure, stateless algorithm library -- no instance, no cached state --
## mirroring [CandidateCellRules]/[BuildValidationReachability]/
## [BuildValidationRegionFormation]'s own established "separate stateless
## algorithm library" precedent. Deliberately holds no [BuildValidationConfig]
## reference of its own -- callers pass [param min_room_cells]/[param
## max_room_height] directly, exactly like [method
## BuildValidationReachability.classify_region]'s own signature. Reads only
## [VoxelWorldGrid] data via the two shared region/reachability classes --
## never [CellContents] directly, never a furniture-registry reference of its
## own (furniture identity/cells are the CALLER's concern, BV-1 -- this class
## only ever sees plain [Vector3i] cells).
class_name BuildValidationShelterClassifier
extends RefCounted


## Returns whether a furniture item occupying [param cells] is sheltered
## (Rule 5). `false` for an empty [param cells] -- nothing to classify, never
## a crash. Otherwise `true` iff EVERY cell's freshly-formed region
## classifies as [constant BuildValidationReachability.Verdict.ROOM] (Rule 3:
## a sealed "room" shelters no one; a cell that is not even a candidate
## interior cell forms an empty region, which never classifies as ROOM
## either -- both paths correctly fall out of composing the two existing
## story 003/004 predicates, no separate branch needed here).
static func is_sheltered(
	voxel_world: VoxelWorldGrid,
	cells: Array[Vector3i],
	min_room_cells: int,
	max_room_height: int,
) -> bool:
	assert(voxel_world != null, "BuildValidationShelterClassifier.is_sheltered requires voxel_world")
	if cells.is_empty():
		return false
	for cell: Vector3i in cells:
		var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
			voxel_world, cell, max_room_height
		)
		var verdict: BuildValidationReachability.Verdict = BuildValidationReachability.classify_region(
			voxel_world, region, min_room_cells, max_room_height
		)
		if verdict != BuildValidationReachability.Verdict.ROOM:
			return false
	return true
