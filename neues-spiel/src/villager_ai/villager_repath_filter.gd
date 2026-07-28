## Re-path FILTER (Story villager-ai-008, GDD Rule 10b /
## [TR-villager-ai-behavior-012]): "a Voxel World write triggers a re-path/
## re-validation evaluation for any moving villager -- Traveling, a
## Wandering step, a Breather step-away, or an F4 vacate step -- ONLY if the
## changed cell(s) intersect the remaining movement's cells or their
## clearance envelope, defined explicitly as: each movement cell plus the
## two cells directly above it (the `villager_clearance` column, GDD Rule 8)
## plus, for diagonal steps, both flanking orthogonal cells (GDD Rule 9).
## Writes elsewhere are ignored by design."
##
## A pure, stateless predicate library -- no instance, no cached state --
## deliberately SEPARATE from [VillagerNavGraph] (which owns the AStar3D
## graph's own incremental patching, a different concern: the graph answers
## "is this cell still standable/connected," this filter answers "should a
## MOVING villager re-evaluate its path because of this write") and from
## [VillagerAi] (which owns WHEN this filter is consulted -- via its own
## `_from_cell`/`_to_cell` step and [signal VillagerAi.repath_evaluation_requested],
## fired from [method VillagerAi.evaluate_repath_trigger]). Story
## villager-ai-009 owns the actual re-path/redirect a positive result from
## this filter is meant to trigger (Out of Scope here, per this story's own
## boundary) -- this story owns ONLY the filter decision itself, independent
## of any throttling the Deciding-pass scheduler adds on top (ADR-0008),
## per the GDD's own "independent of whatever throttling strategy" wording.
class_name VillagerRepathFilter
extends RefCounted


## The clearance envelope for a single ORDERED `movement_cells` path (GDD
## Rule 10b's exact definition): each movement cell, PLUS the
## [constant VillagerAi.VILLAGER_CLEARANCE] cells forming its own clearance
## column (the SAME column [method VillagerAi.is_standable] itself checks --
## reused via the shared constant, never a re-derived copy of the number 3),
## PLUS -- for a diagonal step to the NEXT movement cell in the list -- both
## flanking orthogonal cells of that step, mirroring [method
## VillagerAi.is_step_legal]'s own flanker derivation exactly (`(next.x,
## cell.y, cell.z)` and `(cell.x, cell.y, next.z)`) so the envelope and the
## legality check that produced the underlying path agree on what
## "diagonal" means. Returns a deduplicated `Array[Vector3i]` (a plain
## `Dictionary` used as a set, `.keys()` at the end) -- consecutive PAIRS in
## [param movement_cells] determine which steps count as "diagonal" for the
## flanker addition; a [param movement_cells] of fewer than 2 entries simply
## contributes no flanker cells (there is no step to flank), only its own
## clearance column(s).
static func clearance_envelope(movement_cells: Array[Vector3i]) -> Array[Vector3i]:
	var envelope: Dictionary[Vector3i, bool] = {}
	for i in range(movement_cells.size()):
		var cell: Vector3i = movement_cells[i]
		for offset in range(VillagerAi.VILLAGER_CLEARANCE):
			envelope[cell + Vector3i(0, offset, 0)] = true
		if i + 1 < movement_cells.size():
			var next_cell: Vector3i = movement_cells[i + 1]
			var dx: int = next_cell.x - cell.x
			var dz: int = next_cell.z - cell.z
			if dx != 0 and dz != 0:
				envelope[Vector3i(next_cell.x, cell.y, cell.z)] = true
				envelope[Vector3i(cell.x, cell.y, next_cell.z)] = true
	return envelope.keys()


## Whether ANY of [param changed_cells] falls within [param movement_cells]'s
## own [method clearance_envelope] -- the actual gate GDD Rule 10b describes
## ("triggers... ONLY IF the changed cells intersect the remaining
## movement's cells or their clearance envelope. Writes elsewhere are
## ignored by design."). An empty [param movement_cells] (a stationary
## villager -- Deciding/Working/Sleeping, or a Breather not yet stepping)
## always returns `false` with no envelope computed at all: there is no
## movement to intersect, matching the rule's own scope ("any MOVING
## villager"). This is the AC18 (positive)/AC49 (negative, "call-count ==
## 0") gate itself -- [method VillagerAi.evaluate_repath_trigger] is the
## consumer that turns a `true` result into exactly one
## [signal VillagerAi.repath_evaluation_requested] emission.
static func changed_cells_intersect_envelope(
	changed_cells: Array[Vector3i], movement_cells: Array[Vector3i]
) -> bool:
	if movement_cells.is_empty():
		return false
	var envelope: Array[Vector3i] = clearance_envelope(movement_cells)
	for cell: Vector3i in changed_cells:
		if envelope.has(cell):
			return true
	return false
