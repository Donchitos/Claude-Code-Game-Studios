## Bed-selection algorithm (Story villager-ai-018, GDD Rule 11/AC22/AC44,
## ADR-0007 Decision Section 1's shared-predicate/shared-graph discipline).
##
## Picks the nearest REACHABLE bed cell among `candidates` by true path
## length ([method VillagerNavGraph.find_path] / [method
## VillagerNavGraph.path_length_cells]) -- an unreachable candidate is
## silently skipped, never claimed or reported, mirroring
## [VillagerJobSelector.select_job]'s own "reachability discovered lazily,
## no side effect for a candidate that fails it" precedent for jobs.
##
## Unlike [VillagerJobSelector], this class runs NO round-based Chebyshev
## pre-filter/budget: the GDD names no F2-style approximation contract for
## bed selection anywhere (Rule 11 says only "an unowned, reachable bed", no
## ranking formula, and no Tuning Knob analogous to `job_candidate_count`
## exists for beds) -- a full linear true-path scan of every supplied
## candidate is the honest, unapproximated implementation of "nearest
## reachable," acceptable at this system's bed-count scale (a settlement's
## bed count sits far below its blueprint-cell/job count). Ties are broken
## by [method VillagerJobSelector.lexicographic_cell_less_than] -- the SAME
## F2/F5 tie-break convention every other selection in this codebase reuses,
## never a second, locally-derived comparator.
##
## A pure, stateless algorithm library -- no instance, no cached state --
## mirroring [VillagerJobSelector]/[VillagerRescueTargetSearch]'s own
## established "separate stateless predicate/algorithm library, distinct
## from [VillagerAi] itself" precedent.
class_name VillagerBedSelector
extends RefCounted


## Returns the nearest reachable cell among `candidates`, or `null` if none
## is reachable (GDD Rule 12's own "if no reachable bed exists" case --
## delegated entirely to the caller, [VillagerAi._attempt_claim_and_travel_to_bed],
## never decided here). `from_cell` is the villager's own discrete
## [method VillagerAi.get_current_cell] -- never an interpolated/visual
## position (Control Manifest Core Layer occupancy discipline). `nav_graph`
## supplies every true-path check -- this selector calls it directly, never
## a second, re-derived pathfinding routine (ADR-0007: "one shared graph,
## one consumer path").
static func select_nearest_reachable_bed(
	candidates: Array[Vector3i], from_cell: Vector3i, nav_graph: VillagerNavGraph
) -> Variant:
	var best_cell: Variant = null
	var best_length: float = 0.0
	for candidate: Vector3i in candidates:
		var path: Array[Vector3i] = nav_graph.find_path(from_cell, candidate)
		if path.is_empty():
			continue
		var length: float = VillagerNavGraph.path_length_cells(path)
		if (
			best_cell == null
			or length < best_length
			or (length == best_length and VillagerJobSelector.lexicographic_cell_less_than(candidate, best_cell))
		):
			best_cell = candidate
			best_length = length
	return best_cell
