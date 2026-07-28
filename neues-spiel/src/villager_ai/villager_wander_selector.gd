## F3/Rule 7c wander-target + idle-micro-behavior selection algorithm (Story
## villager-ai-019, GDD F3 "Wander target selection" / Rule 7c "Idle
## micro-behaviors", ADR-0008 Decision §1 (Wandering state) / ADR-0007
## Decision §1 (shared walkability predicates)).
##
## A pure, stateless algorithm library -- no instance, no cached state --
## mirroring [VillagerJobSelector]/[VillagerBedSelector]/
## [VillagerRescueTargetSearch]'s own established "separate stateless
## predicate/algorithm library, distinct from [VillagerAi] itself" precedent
## (see any of those classes' own doc comment for the full architectural
## rationale this one repeats). [VillagerAi]'s own [method
## VillagerAi._tick_wandering] owns WHEN a pick happens (the `wander_interval`
## cadence) and WHAT state transition follows (`start_traveling` for a WALK/
## BED_DRIFT pick, a no-op for PAUSE_LOOK/SIT) -- this class owns ONLY the
## selection algorithms themselves.
##
## **F3 flood-fill** ([method flood_fill]): a bounded breadth-first search
## outward from the villager's own `current_cell`, walking ONLY edges [method
## VillagerAi.is_step_legal] itself certifies legal between two [method
## VillagerAi.is_standable] cells -- exactly [VillagerNavGraph.build]'s own
## two-predicate discipline, reused here rather than re-derived (ADR-0007:
## "every consumer calls these same two functions"). This is what makes F3's
## own "reachability guaranteed by construction (no island targets, no
## post-hoc path validation)" wording literally true: a cell can only ever
## enter the result set by being walked to from an already-included,
## already-reachable neighbor -- there is no "scan every cell within a
## bounding box, then reachability-check it" fallback that could admit an
## unreachable-but-nearby island.
##
## Deliberately NOT built on the shared, population-wide [VillagerNavGraph]
## (unlike [VillagerJobSelector]/[VillagerBedSelector], which both consume it
## directly): that graph is bounded to a FIXED settlement-core region
## (`nav_region_size`, centered on a fixed `region_center`, [VillagerNavGraph.
## build]'s own doc comment) -- a villager wandering near or beyond that
## region's own edge would see [method VillagerNavGraph.has_point] report
## `false` for perfectly standable cells the flood-fill itself must still be
## able to reach, silently starving Wandering the moment a settlement grows
## past the nav graph's own bounded footprint. `wander_radius`'s own safe
## range (3-16, [VillagerAIConfig.WANDER_RADIUS_MAX]) is also always far
## smaller than any sane `nav_region_size`, so re-deriving a small, local BFS
## directly against the shared predicates (rather than borrowing the larger
## graph's own connectivity) costs nothing extra at this system's scale
## while removing that region-boundary hazard entirely.
##
## **Determinism** ([TR-villager-ai-behavior-016], this story's AC30 --
## "wandering runs twice from the same state produce identical paths"): every
## function here is either a pure function of its own inputs (no engine-global
## state, no wall-clock, GDScript's `OS`/`Time` singletons never referenced
## anywhere in this file) or draws from a CALLER-SUPPLIED
## [RandomNumberGenerator] instance ([method select_micro_behavior]/[method
## select_wander_target]) -- this class never constructs, seeds, or
## `randomize()`s one of its own. [method VillagerAi._get_wander_rng] is the
## one place a [RandomNumberGenerator] is ever constructed, and it seeds
## deterministically from `villager_id` -- never from OS entropy or
## wall-clock -- see that method's own doc comment for the full rationale
## (this story's own interpretation, adopted so the ENTIRE decision path stays
## free of any wall-clock dependency end to end, matching this sprint's own
## QA-plan grep guard for this story: "no wall-clock dependency
## (`OS.get_ticks_msec`/`Time.get_ticks_msec` absent from any decision path)").
## The BFS itself never consults the injected generator at all -- its own
## traversal order is already fully deterministic (a `Dictionary`-as-visited-
## set preserves insertion order in Godot, and the neighbor-candidate scan
## order is a fixed constant array, [constant VillagerNavGraph.
## HORIZONTAL_FULL_OFFSETS] x [constant VillagerNavGraph.VERTICAL_STEP_OFFSETS])
## -- randomness only enters at the two explicit "pick one of these" steps
## below.
class_name VillagerWanderSelector
extends RefCounted

## Rule 7c's four named idle micro-behaviors. `BED_DRIFT` is only ever an
## eligible OUTCOME of [method select_micro_behavior] when the caller passes
## `bed_drift_eligible = true` (i.e. [method VillagerAi.has_owned_bed] is
## `true`) -- a villager with no owned bed never draws it, matching Rule 7c's
## own "drifting toward its owned bed's area when one exists" wording.
enum MicroBehavior {
	WALK,
	PAUSE_LOOK,
	SIT,
	BED_DRIFT,
}


## F3's bounded flood-fill (see class doc comment for the full algorithm/
## reachability rationale). Always includes [param from_cell] itself,
## regardless of whether [param predicate_source] currently reports it
## standable -- this story's AC31/Edge Case 8 ("flood-fill returns only the
## current cell... stays in place, no error") needs a non-empty result even
## for a self-sealed or otherwise degenerate starting cell, and a villager
## already occupying a cell trivially "reaches" it with zero steps. Every
## OTHER cell must pass BOTH [method VillagerAi.is_standable] and [method
## VillagerAi.is_step_legal] from an already-visited neighbor to be included.
##
## Bounded to [param wander_radius] Chebyshev distance from [param from_cell]
## (this codebase's own established radius metric -- [method
## VillagerJobSelector.chebyshev_distance]/[VillagerRescueTargetSearch]'s own
## ring-BFS both use it) -- this story's AC29/AC45: a cell EXACTLY at
## `wander_radius` is included; one cell beyond is excluded. The bound is
## checked per-CANDIDATE-neighbor (never merely per-cell-popped-from-the-
## queue), so a boundary cell is correctly included while nothing beyond it
## is ever even considered for inclusion -- an inclusive, deterministic edge.
##
## Traverses [constant VillagerNavGraph.HORIZONTAL_FULL_OFFSETS] x [constant
## VillagerNavGraph.VERTICAL_STEP_OFFSETS] (this codebase's one established
## step-neighbor-candidate set -- [VillagerNavGraph]'s own patch pass and
## [VillagerAi]'s own Unstuck Watchdog reuse the identical pair, never a
## second, locally-derived neighbor set) via a plain index-walked queue (not
## `pop_front()`, which is O(n) per call at this codebase's other array
## sizes) -- an insertion-ordered `Dictionary` doubles as the visited set,
## which is what makes the returned array's OWN order deterministic (Godot
## `Dictionary` preserves insertion order): the same world always visits, and
## therefore returns, cells in the identical sequence.
static func flood_fill(
	predicate_source: VillagerAi, from_cell: Vector3i, wander_radius: int
) -> Array[Vector3i]:
	assert(predicate_source != null, "VillagerWanderSelector.flood_fill requires predicate_source")
	assert(wander_radius > 0, "VillagerWanderSelector.flood_fill requires wander_radius > 0")
	var visited: Dictionary[Vector3i, bool] = {}
	visited[from_cell] = true
	var queue: Array[Vector3i] = [from_cell]
	var head: int = 0
	while head < queue.size():
		var cell: Vector3i = queue[head]
		head += 1
		for offset: Vector2i in VillagerNavGraph.HORIZONTAL_FULL_OFFSETS:
			for dy: int in VillagerNavGraph.VERTICAL_STEP_OFFSETS:
				var neighbor: Vector3i = cell + Vector3i(offset.x, dy, offset.y)
				if visited.has(neighbor):
					continue
				if VillagerJobSelector.chebyshev_distance(from_cell, neighbor) > wander_radius:
					continue
				if not predicate_source.is_standable(neighbor):
					continue
				if not predicate_source.is_step_legal(cell, neighbor):
					continue
				visited[neighbor] = true
				queue.append(neighbor)
	return visited.keys()


## Rule 7c's micro-behavior pick: uniform draw over `[WALK, PAUSE_LOOK, SIT]`,
## plus `BED_DRIFT` when [param bed_drift_eligible] is `true` -- exactly "the
## same injected RNG as F3" the GDD names ([TR-villager-ai-behavior-016]),
## never a second, independently-seeded source. `rng` is caller-supplied
## (this class holds no generator of its own, see class doc comment) --
## [method RandomNumberGenerator.randi_range] draws the index, so the SAME
## generator STATE always yields the SAME pick.
static func select_micro_behavior(rng: RandomNumberGenerator, bed_drift_eligible: bool) -> MicroBehavior:
	assert(rng != null, "VillagerWanderSelector.select_micro_behavior requires rng")
	var options: Array[MicroBehavior] = [MicroBehavior.WALK, MicroBehavior.PAUSE_LOOK, MicroBehavior.SIT]
	if bed_drift_eligible:
		options.append(MicroBehavior.BED_DRIFT)
	var index: int = rng.randi_range(0, options.size() - 1)
	return options[index]


## F3's own "uniformly chosen cell" pick ([TR-villager-ai-behavior-078]) over
## [param flood_cells] (normally [method flood_fill]'s own return value --
## never empty by that method's own "always includes `from_cell`" guarantee,
## so this never draws against an empty range). Same `rng` instance as
## [method select_micro_behavior] -- this story's own AC30 determinism
## contract holds precisely because both draws come from one ordered stream,
## never two independently-seeded ones that could drift out of sync relative
## to each other across a refactor.
static func select_wander_target(flood_cells: Array[Vector3i], rng: RandomNumberGenerator) -> Vector3i:
	assert(not flood_cells.is_empty(), "VillagerWanderSelector.select_wander_target requires a non-empty flood_cells")
	assert(rng != null, "VillagerWanderSelector.select_wander_target requires rng")
	var index: int = rng.randi_range(0, flood_cells.size() - 1)
	return flood_cells[index]


## Rule 7c/[TR-villager-ai-behavior-060]'s bed-drift target: `argmin`
## (Chebyshev distance to [param bed_cell]) over [param flood_cells] -- ties
## broken by [method VillagerJobSelector.lexicographic_cell_less_than] (the
## SAME F2/F5 tie-break convention every other selection in this codebase
## reuses, never a second, locally-derived comparator). Deliberately NOT
## random -- Rule 7c names bed-drift as "drifting toward its owned bed's
## area," a directed pull, not a flavor coin-flip; only WHETHER bed-drift is
## the chosen micro-behavior this pick cycle is randomized (via [method
## select_micro_behavior]), never WHERE it drifts to.
##
## Because [param flood_cells] is already bounded to `wander_radius` of the
## villager's own current cell (by construction, [method flood_fill]), the
## argmin over that bounded set IS "the flood-fill cell nearest the bed
## WITHIN `wander_radius`" -- when the bed itself lies beyond the radius, the
## winning cell is simply whichever bounded cell minimizes remaining distance,
## i.e. the radius edge closest to the bed's own direction; no separate
## "clamp to the radius edge" geometry is needed, this IS that clamp
## ([TR-villager-ai-behavior-060]: "if the bed lies beyond the radius, the
## villager drifts to the radius edge, never pathing outside F3's bounded
## set").
static func select_bed_drift_target(flood_cells: Array[Vector3i], bed_cell: Vector3i) -> Vector3i:
	assert(not flood_cells.is_empty(), "VillagerWanderSelector.select_bed_drift_target requires a non-empty flood_cells")
	var best_cell: Vector3i = flood_cells[0]
	var best_distance: int = VillagerJobSelector.chebyshev_distance(flood_cells[0], bed_cell)
	for i in range(1, flood_cells.size()):
		var candidate: Vector3i = flood_cells[i]
		var distance: int = VillagerJobSelector.chebyshev_distance(candidate, bed_cell)
		if (
			distance < best_distance
			or (distance == best_distance and VillagerJobSelector.lexicographic_cell_less_than(candidate, best_cell))
		):
			best_cell = candidate
			best_distance = distance
	return best_cell
