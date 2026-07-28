## F2 job-selection outcome (Story villager-ai-010, GDD F2 / ADR-0007 Decision
## Section 2, [TR-villager-ai-behavior-076]/[TR-villager-ai-behavior-077]).
##
## `RefCounted`, not `Resource` -- a transient per-call value object, mirroring
## [RaycastHitResult]/[CellQueryResult]'s shared "fresh lightweight wrapper per
## call, explicit hit-or-miss rather than a bare nullable return" precedent.
## The explicit [member pathfind_attempt_count] field exists because this
## story's own AC7 needs a SECOND observable value alongside the chosen job
## itself ("assert pathfind attempts <= max_selection_candidates, not just
## 'eventually returns'") -- a bare `BlueprintCell` (or `null`) return could
## never expose that count to a caller/test.
class_name JobSelectionResult
extends RefCounted

## The chosen [BlueprintCell], or `null` if every candidate within the
## `max_selection_candidates` cap failed the true-path check this pass (GDD
## F2: "the villager falls through the priority list for this pass" --
## Story Acceptance Criteria #3, delegated to Stories 006/011's own
## handling, NOT implemented here). Callers MUST check [method has_selection]
## (or compare against `null` directly) before treating this as a valid
## target -- mirrors [RaycastHitResult.hit]'s own "check before trusting the
## payload" convention.
var chosen: BlueprintCell = null

## How many true-path ([method VillagerNavGraph.find_path]) checks this
## selection pass actually performed -- this story's AC7 observability
## contract. Bounded at `max_selection_candidates` by [method
## VillagerJobSelector.select_job]'s own budget guard, regardless of how many
## total candidates were supplied to it.
var pathfind_attempt_count: int = 0

## Story `building-034` addition (TD ruling D5): the deterministic list of
## every candidate cell THIS pass probed via [method VillagerNavGraph.find_path]
## and found unreachable (`path.is_empty()`) -- [method
## VillagerJobSelector.select_job] already computed exactly this set inside
## its own round loop and previously threw it away. `select_job` stays a
## PURE static function (D5: "reports nothing itself, gains no dependency")
## -- the caller ([VillagerAi]) forwards this list to
## [method ConstructionJobQueue.report_unreachable], throttled by the
## already-landed retry cooldown.
var unreachable_cells: Array[Vector3i] = []


func _init(
	p_chosen: BlueprintCell = null, p_pathfind_attempt_count: int = 0, p_unreachable_cells: Array[Vector3i] = []
) -> void:
	chosen = p_chosen
	pathfind_attempt_count = p_pathfind_attempt_count
	unreachable_cells = p_unreachable_cells


## Whether this pass found a reachable job -- the explicit "hit or miss"
## check (see class doc comment); `false` means every candidate within the
## cap failed reachability (GDD F2's fall-through case).
func has_selection() -> bool:
	return chosen != null
