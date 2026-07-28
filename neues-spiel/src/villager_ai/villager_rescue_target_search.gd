## F5 rescue-target search algorithm (Story villager-ai-014, GDD F5 / Rule 15b
## / [TR-villager-ai-behavior-100]/[TR-villager-ai-behavior-105], ADR-0007
## Decision Section 1, Control Manifest Feature Layer Required Pattern:
## "Unstuck watchdog: ... target via expanding-ring BFS
## (`unstuck_rescue_search_radius`/`_max_radius`) with the F2 lexicographic
## tie-break").
##
## `rescue_target = nearest(cell)` such that `cell` is standable (GDD Rule 8,
## [method VillagerAi.is_standable]) and unoccupied (no other villager's
## body-column, GDD Rule 8a's "checking only the feet cell would let a rescue
## ... check pass while the model still clips" -- Story villager-ai-003's
## [method VillagerAi.is_cell_in_body_column], NOT a feet-only `==`
## comparison), found by an expanding-ring BFS out from the stuck cell,
## tie-broken by the SAME lexicographic `(y, x, z)` convention F2 uses
## ([method VillagerJobSelector.lexicographic_cell_less_than], reused
## directly -- never a second, re-derived comparator).
##
## A pure, stateless algorithm library -- no instance, no cached state --
## mirroring [VillagerJobSelector]/[VillagerRepathFilter]'s own established
## "separate stateless predicate/algorithm library, distinct from [VillagerAi]
## itself" precedent (see either class's own doc comment for the full
## architectural rationale this one repeats): this class owns ONLY the search
## algorithm itself -- "given a stuck cell, a set of other villagers'
## occupied cells, and the two radius knobs, which cell wins, and did the
## search fail." Story villager-ai-015's Unstuck Watchdog owns WHEN this
## search runs (the stuck-tick-count trigger), the actual teleport +
## `current_cell` mutation, the claim-release side effect, and the
## `villager_unstuck` SUCCESS telemetry -- all explicitly Out of Scope here
## (this story's own Out of Scope section: "Story 015: the watchdog trigger,
## teleport, claim-release, and success telemetry"). The companion
## once-per-episode `villager_unstuck_search_failed` flag this story's own
## AC53 requires is [RescueSearchFailureGate], a separate small stateful
## class (see its own doc comment for why the gate itself cannot be a pure
## function) -- this class exposes no signal of its own.
##
## **Algorithm** (GDD F5, this story's own interpretation where the GDD is
## silent on ring-0 candidacy -- see [method find_rescue_target]'s own doc
## comment for that specific call):
## 1. Starting at `search_radius`, walk Chebyshev-distance rings outward from
##    `stuck_cell`, nearest ring first (a genuine expanding-ring BFS, not a
##    bounding-box scan) -- [method _ring_cells] generates exactly the
##    3D-Chebyshev-distance-`d` shell (surface only, never the interior --
##    already-checked-at-a-smaller-distance cells are never re-visited).
## 2. Within one ring, sort candidates by [method
##    VillagerJobSelector.lexicographic_cell_less_than] and return the first
##    that passes BOTH [method VillagerAi.is_standable] and this class's own
##    [method _is_occupied] negative check -- the first ring (nearest
##    distance) that contains ANY eligible cell wins, deterministically.
## 3. If no ring up to the current radius bound yields a result, and that
##    bound is still below `max_radius`, DOUBLE the bound (capped at
##    `max_radius`) and continue expanding outward from where the previous
##    bound left off -- never re-scanning already-exhausted, smaller-distance
##    rings (GDD Edge Case 14: "the radius doubles... up to
##    `unstuck_rescue_max_radius`").
## 4. Exhausting `max_radius` with no eligible cell anywhere returns a
##    not-found [RescueSearchResult] (GDD Edge Case 14: "the rescue defers to
##    the next tick").
class_name VillagerRescueTargetSearch
extends RefCounted


## The F5 search entry point. `stuck_cell` is the villager's own discrete
## [method VillagerAi.get_current_cell] (never an interpolated/visual
## position -- Control Manifest Core Layer: "`_visual_position` is never read
## outside the movement/rendering path"; this module never references that
## field at all). `predicate_source` supplies [method VillagerAi.is_standable]
## and the body-column occupancy predicates ([method VillagerAi.body_column]/
## [method VillagerAi.is_cell_in_body_column]) -- any [VillagerAi] instance
## works, mirroring [method VillagerNavGraph.build]'s own "generic predicate
## source, not necessarily `self`" parameter shape. `other_villager_cells` is
## the caller's own current snapshot of every OTHER villager's discrete
## `current_cell` (the watchdog's responsibility to assemble, mirroring
## [VillagerJobSelector.select_job]'s own "caller supplies every input, this
## library holds no live registry of its own" shape) -- this function never
## queries a population/registry itself. `search_radius`/`max_radius` are
## [VillagerAIConfig]'s own `unstuck_rescue_search_radius`/
## `unstuck_rescue_max_radius` knobs, read fresh by the caller and passed in.
##
## **Ring-0 (the stuck cell itself) is deliberately EXCLUDED from candidacy**
## -- the GDD is silent on this specific point, and this is this story's own
## interpretation (mirroring [VillagerJobSelector]'s own documented
## "the GDD is silent on X; this is this story's own interpretation"
## precedent): the watchdog's OWN trigger condition (GDD Rule 15/F5) fires
## when a Traveling/Working villager has "zero legal step from its current
## cell" for `unstuck_watchdog_threshold_ticks` -- which can be true even
## while the current cell itself is still standable (a villager walled in on
## an otherwise-fine cell). If ring 0 were eligible, the search would trivially
## return the villager's OWN current cell as its "nearest" rescue target -- a
## teleport-to-self that resets `stuck_tick_count` (GDD F5: "resets to 0 the
## instant a legal step or standable cell becomes available again" -- a
## same-cell "rescue" satisfies neither condition) without actually freeing a
## walled-in villager, who would then simply re-trigger the watchdog every
## `unstuck_watchdog_threshold_ticks` indefinitely. Starting the ring walk at
## distance 1 guarantees every returned rescue target is a cell the villager
## does not already occupy.
static func find_rescue_target(
	stuck_cell: Vector3i,
	predicate_source: VillagerAi,
	other_villager_cells: Array[Vector3i],
	search_radius: int,
	max_radius: int,
) -> RescueSearchResult:
	assert(predicate_source != null, "VillagerRescueTargetSearch.find_rescue_target requires predicate_source")
	assert(search_radius > 0, "VillagerRescueTargetSearch.find_rescue_target requires search_radius > 0")
	assert(max_radius > 0, "VillagerRescueTargetSearch.find_rescue_target requires max_radius > 0")

	var radius: int = mini(search_radius, max_radius)
	var checked_up_to_distance: int = 0
	while true:
		for distance in range(checked_up_to_distance + 1, radius + 1):
			var ring: Array[Vector3i] = _ring_cells(stuck_cell, distance)
			ring.sort_custom(VillagerJobSelector.lexicographic_cell_less_than)
			for candidate: Vector3i in ring:
				if (
					predicate_source.is_standable(candidate)
					and not _is_occupied(predicate_source, candidate, other_villager_cells)
				):
					return RescueSearchResult.new(true, candidate)
		checked_up_to_distance = radius
		if radius >= max_radius:
			break
		radius = mini(radius * 2, max_radius)

	return RescueSearchResult.new(false, Vector3i.ZERO)


## Whether ANY registered other villager's body-column ([method
## VillagerAi.body_column]) overlaps [param candidate_cell]'s own body-column
## -- the "unoccupied" half of F5's eligibility test, GDD Rule 8a's explicit
## body-column-not-feet-only occupancy discipline (this story's Implementation
## Notes: "the body-column occupancy (Story 003) to reject cells whose column
## collides with another villager"). Deliberately NOT a bare
## `candidate_cell == other_cell` comparison -- that would miss the case
## where a rescued villager's BODY (not feet) would clip into a neighboring
## occupant's own space, the identical defect [method
## VillagerAi.is_cell_in_body_column]'s own doc comment names for
## seal-prevention. Reuses [method VillagerAi.is_cell_in_body_column]
## directly (no re-derived overlap rule of its own, ADR-0007: "never
## duplicate walkability rules or constants" -- extended here to the shared
## occupancy predicate).
static func _is_occupied(
	predicate_source: VillagerAi, candidate_cell: Vector3i, other_villager_cells: Array[Vector3i]
) -> bool:
	for other_cell: Vector3i in other_villager_cells:
		for query_cell: Vector3i in predicate_source.body_column(candidate_cell):
			if predicate_source.is_cell_in_body_column(other_cell, query_cell):
				return true
	return false


## Every cell at EXACTLY Chebyshev distance `distance` from `center` in 3D
## (the surface of a `(2*distance+1)`-side cube, never its interior) -- the
## same 3D Chebyshev metric [method VillagerJobSelector.chebyshev_distance]
## defines (`max(|dx|, |dy|, |dz|)`), generated directly rather than filtered
## from a full cuboid scan (an expanding-ring BFS visits each ring's surface
## once, not the whole bounding cuboid every time). `distance == 0` returns
## just `[center]` (never reached by [method find_rescue_target]'s own ring
## walk, which always starts at distance 1 -- see that method's own doc
## comment -- but kept correct here as a self-contained utility). For
## `distance > 0`, partitions the cube's 6 faces into 3 non-overlapping
## groups (X-extreme faces first with a FULL y/z range, then Y-extreme faces
## restricted to a horizontally-interior x range, then Z-extreme faces
## restricted to a horizontally-interior x AND y range) so no cell is ever
## generated twice -- no de-duplication pass needed.
static func _ring_cells(center: Vector3i, distance: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	if distance == 0:
		cells.append(center)
		return cells

	for x_sign in [-1, 1]:
		var x: int = center.x + x_sign * distance
		for dy in range(-distance, distance + 1):
			for dz in range(-distance, distance + 1):
				cells.append(Vector3i(x, center.y + dy, center.z + dz))

	for y_sign in [-1, 1]:
		var y: int = center.y + y_sign * distance
		for dx in range(-distance + 1, distance):
			for dz in range(-distance, distance + 1):
				cells.append(Vector3i(center.x + dx, y, center.z + dz))

	for z_sign in [-1, 1]:
		var z: int = center.z + z_sign * distance
		for dx in range(-distance + 1, distance):
			for dy in range(-distance + 1, distance):
				cells.append(Vector3i(center.x + dx, center.y + dy, z))

	return cells
