## F2 job-selection algorithm (Story villager-ai-010, GDD F2 / ADR-0007
## Decision Section 2 [TR-villager-ai-behavior-076]/[TR-villager-ai-behavior-077]/
## [TR-villager-ai-behavior-053]): `chosen_job = argmin(path_length_cells)`
## over available reachable jobs, approximated via a bounded, round-based
## Chebyshev pre-filter -- never a full-queue pathfind.
##
## A pure, stateless algorithm library -- no instance, no cached state --
## mirroring [VillagerRepathFilter]'s own established "separate stateless
## predicate/algorithm library, distinct from [VillagerAi] itself" precedent
## (see that class's own doc comment for the full architectural rationale
## this one repeats): [VillagerAi] owns WHEN a Deciding pass commits to
## pursuing a job (Story villager-ai-006's tier-2 branch) and WHICH job ends
## up actually claimed/traveled-to (Story villager-ai-011's own atomic claim
## handshake, explicitly out of THIS story's own Out of Scope section) --
## this class owns ONLY the selection algorithm itself: "given a set of
## candidate jobs and a starting cell, which one wins, and how many
## true-path checks did it cost."
##
## **Algorithm** (ADR-0007 Implementation Notes, GDD F2's own "Approximation
## contract"):
## 1. Rank EVERY supplied candidate by straight-line (Chebyshev) distance
##    from `from_cell` to its own [member BlueprintCell.cell] -- ties broken
##    by original queue position (see "Commit-order tie-break" below), which
##    is a fully deterministic total order (no two candidates ever share a
##    queue position), so the Chebyshev pre-filter ranking never needs the
##    lexicographic secondary key GDD F2 reserves for the FINAL argmin's own
##    ties (Step 3) -- the GDD is silent on how to break a Chebyshev-distance
##    TIE during pre-filtering specifically; this is this story's own
##    interpretation, reusing the same queue-order convention already
##    established for the final tie-break, for full determinism end to end.
## 2. Evaluate candidates in ROUNDS of `job_candidate_count`, nearest round
##    first: true-path check ([method VillagerNavGraph.find_path]) every
##    candidate in the round -- this is what [member
##    JobSelectionResult.pathfind_attempt_count] counts, one per check,
##    reachable or not ([TR-villager-ai-behavior-053]: "reachability is
##    discovered lazily at selection time, never a gate on the ranking
##    itself" -- every candidate the pre-filter ranked is genuinely
##    attempted, in rank order, with zero pre-filtering by reachability).
## 3. If ANY candidate in the current round is reachable (a non-empty
##    [method VillagerNavGraph.find_path] result), the round STOPS the whole
##    selection: pick `argmin(path_length_cells)` among ONLY this round's
##    reachable candidates -- ties broken by commit order, then
##    lexicographic `(y, x, z)` (GDD F2's own wording, this story's AC6).
##    This is the approximation contract's own explicit trade-off: a nearer
##    job that only appears in a LATER round is never considered once an
##    earlier round already produced a winner -- bounded cost over true
##    global optimality.
## 4. If NO candidate in the round is reachable, advance to the next round
##    (the next `job_candidate_count` candidates by rank) -- continues until
##    either a round produces a winner, the candidate list is exhausted, or
##    `max_selection_candidates` true-path checks have been spent (AC7's
##    hard cap; the story's own worked default, 5-per-round x 3 rounds = 15,
##    divides evenly, but this loop also correctly truncates a final PARTIAL
##    round when the two knobs don't divide evenly, never exceeding the cap
##    by even one check).
## 5. Exhausting the cap (or the candidate list) with no reachable candidate
##    found anywhere returns a `null`-chosen [JobSelectionResult] (GDD F2:
##    "the villager falls through the priority list for this pass" -- Story
##    Acceptance Criteria #3, delegated to Stories 006/011's own handling,
##    NOT implemented here).
##
## **Commit-order tie-break** ("older commit first," GDD F2 / ADR-0007
## Implementation Notes): this codebase's [method
## ConstructionJobQueue.get_available_jobs] already documents its OWN return
## array as "IN REGISTRATION ORDER, preserving each project's own
## already-commit-time-ordered internal result" -- i.e. `candidates`' own
## array POSITION, as supplied by the real caller, already stands in for
## "which commit came first," with no separate commit-timestamp field
## required anywhere ([member BuildProject.cells]'s own doc comment:
## "Dictionary preserves insertion order... no separate ordering/timestamp
## field needed"). This selector therefore uses each candidate's ORIGINAL
## INDEX within `candidates` as the "older commit" tie-break key -- never a
## re-derived or duplicated timestamp concept. Because that index is a
## strict, collision-free total order over any real `candidates` array (two
## distinct array entries can never share one index), GDD F2's own
## "same-command ties break by lexicographic (y, x, z)" branch is
## structurally UNREACHABLE via today's real [ConstructionJobQueue] callers
## (there is no `command`/`commit-batch` grouping field anywhere in
## [BlueprintCell]/[BuildProject] for two DIFFERENT candidates to collide
## on) -- this selector still implements that branch faithfully (via
## [method _less_than_by_selection_key]'s own three-level comparison),
## directly exercised by this story's own test via the public [method
## lexicographic_cell_less_than] comparator in isolation, so the rule is
## proven correct and ready the day a future story adds real per-command
## grouping.
class_name VillagerJobSelector
extends RefCounted

## One [BlueprintCell] candidate ranked by Chebyshev distance for the
## pre-filter pass (Step 1) -- pairs the cell with its ORIGINAL `candidates`
## array position (the commit-order tie-break key, see class doc comment) so
## later steps never need to re-derive it. Declared above every function
## that uses it, per this codebase's own inner-helper-class convention.
class _RankedCandidate:
	var blueprint_cell: BlueprintCell
	var queue_index: int
	var chebyshev_distance: int

	func _init(p_blueprint_cell: BlueprintCell, p_queue_index: int, p_chebyshev_distance: int) -> void:
		blueprint_cell = p_blueprint_cell
		queue_index = p_queue_index
		chebyshev_distance = p_chebyshev_distance


## One candidate that survived a round's true-path check (Step 3) -- carries
## its own [method VillagerNavGraph.path_length_cells] result alongside the
## SAME `queue_index` the pre-filter already computed, so the final argmin's
## own tie-break needs no second lookup.
class _ReachableCandidate:
	var blueprint_cell: BlueprintCell
	var queue_index: int
	var path_length_cells: float

	func _init(p_blueprint_cell: BlueprintCell, p_queue_index: int, p_path_length_cells: float) -> void:
		blueprint_cell = p_blueprint_cell
		queue_index = p_queue_index
		path_length_cells = p_path_length_cells


## The F2 selection entry point (see class doc comment for the full
## algorithm). `candidates` is the caller's current available-jobs snapshot
## (production: [method ConstructionJobQueue.get_available_jobs]'s own
## return value, already commit-time ordered -- see class doc comment); an
## empty array short-circuits to a `null`-chosen result with zero pathfind
## attempts, no round logic entered at all. `from_cell` is the villager's
## own discrete [method VillagerAi.get_current_cell] (never an interpolated
## position, per this codebase's occupancy discipline). `nav_graph` supplies
## the true-path checks ([method VillagerNavGraph.find_path]) -- this
## selector calls it directly, never a second, re-derived pathfinding
## routine (ADR-0007: one shared graph, one consumer path).
## `job_candidate_count`/`max_selection_candidates` are [VillagerAIConfig]'s
## own F2 knobs, read fresh by the caller and passed in -- this selector
## holds no config reference of its own (mirrors [method
## VillagerRepathFilter.clearance_envelope]'s own "pure function, caller
## supplies every input" shape).
static func select_job(
	candidates: Array[BlueprintCell],
	from_cell: Vector3i,
	nav_graph: VillagerNavGraph,
	job_candidate_count: int,
	max_selection_candidates: int,
) -> JobSelectionResult:
	assert(job_candidate_count > 0, "VillagerJobSelector.select_job requires job_candidate_count > 0")
	if candidates.is_empty():
		return JobSelectionResult.new(null, 0)

	var ranked: Array[_RankedCandidate] = []
	for i in range(candidates.size()):
		var blueprint_cell: BlueprintCell = candidates[i]
		ranked.append(_RankedCandidate.new(
			blueprint_cell, i, chebyshev_distance(from_cell, blueprint_cell.cell)
		))
	ranked.sort_custom(_less_than_by_chebyshev)

	# Story `building-034` (TD ruling D5) -- every candidate this pass probes
	# and finds unreachable is recorded here, deterministically, for the
	# caller to forward to [method ConstructionJobQueue.report_unreachable].
	# This function stays PURE: it reports nothing itself, gains no
	# job-queue dependency.
	var unreachable_cells: Array[Vector3i] = []
	var attempts: int = 0
	var round_start: int = 0
	while round_start < ranked.size() and attempts < max_selection_candidates:
		var round_end: int = mini(round_start + job_candidate_count, ranked.size())
		var reachable_this_round: Array[_ReachableCandidate] = []
		for i in range(round_start, round_end):
			if attempts >= max_selection_candidates:
				break
			var candidate: _RankedCandidate = ranked[i]
			var path: Array[Vector3i] = nav_graph.find_path(from_cell, candidate.blueprint_cell.cell)
			attempts += 1
			if not path.is_empty():
				reachable_this_round.append(_ReachableCandidate.new(
					candidate.blueprint_cell, candidate.queue_index, VillagerNavGraph.path_length_cells(path)
				))
			else:
				unreachable_cells.append(candidate.blueprint_cell.cell)
		if not reachable_this_round.is_empty():
			reachable_this_round.sort_custom(_less_than_by_selection_key)
			return JobSelectionResult.new(reachable_this_round[0].blueprint_cell, attempts, unreachable_cells)
		round_start = round_end

	return JobSelectionResult.new(null, attempts, unreachable_cells)


## Straight-line (Chebyshev / chessboard) distance between two cells --
## `max(|dx|, |dy|, |dz|)` -- GDD F2's own pre-filter metric ("straight-line
## (Chebyshev) distance"). Pure, static, no dependency on any world/graph
## state.
static func chebyshev_distance(a: Vector3i, b: Vector3i) -> int:
	return maxi(absi(a.x - b.x), maxi(absi(a.y - b.y), absi(a.z - b.z)))


## The F2/F5 shared lexicographic tie-break convention (GDD F2's own
## wording: "lexicographic cell coordinates (y, then x, then z)" -- also
## named by the Control Manifest as F5's unstuck-watchdog rescue-target
## convention, "tie-break lexicographic y, x, z, the F2 convention, for
## determinism"). Public (not a private `_`-prefixed helper) so a future
## watchdog story (F5, villager-ai-014/015) can reuse this SAME comparison
## rather than re-deriving an equivalent one locally, mirroring [method
## VillagerAi.classify_step_length_cells]'s own "extract a reusable static
## twin, cited for reuse by name" precedent. Returns `true` iff `a` sorts
## strictly before `b`.
static func lexicographic_cell_less_than(a: Vector3i, b: Vector3i) -> bool:
	if a.y != b.y:
		return a.y < b.y
	if a.x != b.x:
		return a.x < b.x
	return a.z < b.z


## Pre-filter ranking comparator (Step 1): ascending Chebyshev distance, ties
## broken by ascending original queue position (the commit-order proxy, see
## class doc comment) -- always a strict total order over a real
## `candidates` array (see class doc comment for why the lexicographic key
## is never needed at this stage).
static func _less_than_by_chebyshev(a: _RankedCandidate, b: _RankedCandidate) -> bool:
	if a.chebyshev_distance != b.chebyshev_distance:
		return a.chebyshev_distance < b.chebyshev_distance
	return a.queue_index < b.queue_index


## Final argmin comparator (Step 3, this story's AC6): ascending
## `path_length_cells`, ties broken by ascending queue position ("older
## commit first"), remaining ties (only reachable via a synthetic
## same-queue-index candidate list -- see class doc comment) broken by
## [method lexicographic_cell_less_than] -- GDD F2's full three-level
## tie-break, implemented exactly as specified even though today's real
## [ConstructionJobQueue] can never produce the third level's input.
static func _less_than_by_selection_key(a: _ReachableCandidate, b: _ReachableCandidate) -> bool:
	if a.path_length_cells != b.path_length_cells:
		return a.path_length_cells < b.path_length_cells
	if a.queue_index != b.queue_index:
		return a.queue_index < b.queue_index
	return lexicographic_cell_less_than(a.blueprint_cell.cell, b.blueprint_cell.cell)
