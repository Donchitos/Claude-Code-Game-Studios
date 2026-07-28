## F4 nudge-aside vacate-target selection algorithm (Story villager-ai-013,
## GDD F4 "Nudge-aside target selection" / Rule 7 (Building System Edge Case
## 6), [TR-villager-ai-behavior-056]/[TR-villager-ai-behavior-079]/
## [TR-villager-ai-behavior-034], ADR-0009 Decision Section 2: "F4 targeting
## reads the discrete `current_cell`... deterministic -- the same situation
## always produces the same step").
##
## A pure, stateless algorithm library -- no instance, no cached state --
## mirroring [VillagerJobSelector]/[VillagerRescueTargetSearch]/
## [VillagerWanderSelector]'s own established "separate stateless
## predicate/algorithm library, distinct from [VillagerAi] itself" precedent
## (see any of those classes' own doc comment for the full architectural
## rationale this one repeats). [VillagerAi]'s own [method
## VillagerAi.request_vacate] owns WHEN a vacate is requested (a builder's
## on-site check finding an occupied target cell, [VillagerOnSiteGate]) and
## WHAT follows (a normal [method VillagerAi.start_traveling] walking step)
## -- this class owns ONLY the target-selection ALGORITHM itself.
##
## **Algorithm** (GDD F4): `vacate_target = argmin(height_difference), then
## argMAX(Chebyshev distance to requester)` over standable cells orthogonally
## adjacent to `occupant_cell`; ties broken by a fixed scan order (N, E, S,
## W -- [constant COMPASS_OFFSETS], axis convention pinned by the GDD/
## ADR-0009 Engine Notes: N = -z, E = +x, S = +z, W = -x). A candidate must
## ALSO pass [method VillagerAi.is_step_legal] from `occupant_cell` (not
## merely [method VillagerAi.is_standable]) -- reusing that shared predicate
## here (rather than a bare `absi(dy) <= 1` check of this class's own) is
## this codebase's own "never duplicate walkability rules" discipline
## (ADR-0007), applied to F4 exactly as it already is to F3's flood-fill and
## the F5 rescue search; it also structurally guarantees `height_difference`
## never exceeds [constant VillagerWalkabilityRules.MAX_STEP_HEIGHT] and that
## a diagonal corner is never cut (moot here, since every candidate offset is
## purely orthogonal).
##
## Each of the 4 compass directions is tried at every [constant
## VillagerNavGraph.VERTICAL_STEP_OFFSETS] vertical offset (reusing that SAME
## shared neighbor-candidate constant [VillagerNavGraph]'s own patch pass and
## the Unstuck Watchdog already use, never a second, locally re-derived
## vertical-offset set) -- a raised-or-lowered adjacent standable cell (a
## natural block staircase, GDD Rule 9) is therefore still a valid vacate
## candidate, not only a flat, same-height neighbor.
##
## **Deterministic, first-strict-improvement-wins tie-break** ([method
## select_vacate_target]'s own running-best comparison): candidates are
## visited in the fixed N -> E -> S -> W compass order, and within one
## direction in [constant VillagerNavGraph.VERTICAL_STEP_OFFSETS]'s own fixed
## order (-1, 0, 1). A later candidate only ever REPLACES the current best on
## a STRICT improvement (a smaller `height_difference`, or an equal
## `height_difference` with a STRICTLY larger requester distance) -- never on
## an exact tie -- so the FIRST candidate found at any winning
## `(height_difference, distance)` key is what a tie resolves to, which is
## exactly the GDD's own "fixed scan order... tie-break" wording (this
## story's own interpretation of how a running-best scan implements a stated
## scan-order tie-break, rather than a separate post-hoc sort + comparator --
## a bounded ~12-candidate set makes an explicit sort unnecessary here, unlike
## [VillagerJobSelector]/[VillagerRescueTargetSearch]'s own larger candidate
## sets).
##
## Returns `null` (a `Variant`, mirroring [method VillagerAi.
## get_owned_bed_cell]'s own "`Variant`, `null` means none" convention) when
## NO standable, step-legal orthogonal neighbor exists at all -- GDD Rule 7's
## own "if no adjacent standable cell exists, the vacate request fails and
## the builder's cell stays deferred."
class_name VillagerNudgeAsideSelector
extends RefCounted

## The 4 orthogonal (dx, dz) compass offsets, in the FIXED N, E, S, W scan
## order the GDD's own tie-break names explicitly -- axis convention pinned
## by the GDD/ADR-0009 Engine Notes: N = -z, E = +x, S = +z, W = -x.
const COMPASS_OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1),  # N
	Vector2i(1, 0),   # E
	Vector2i(0, 1),   # S
	Vector2i(-1, 0),  # W
]


## The F4 selection entry point (see class doc comment for the full
## algorithm). `predicate_source` supplies [method VillagerAi.is_standable]/
## [method VillagerAi.is_step_legal] -- any [VillagerAi] instance works
## (mirrors [method VillagerNavGraph.build]'s own "generic predicate source,
## not necessarily `self`" parameter shape). `occupant_cell` is the villager
## being asked to vacate's own discrete [method VillagerAi.get_current_cell]
## (never an interpolated/visual position -- ADR-0009's "F4 targeting reads
## the discrete `current_cell`"). `requester_cell` is the requesting
## builder's own discrete current cell -- the point the occupant steps AWAY
## from (GDD F4: "the occupant steps AWAY from the requesting builder — never
## toward it").
static func select_vacate_target(
	predicate_source: VillagerAi, occupant_cell: Vector3i, requester_cell: Vector3i
) -> Variant:
	assert(predicate_source != null, "VillagerNudgeAsideSelector.select_vacate_target requires predicate_source")
	var best_cell: Variant = null
	var best_height_difference: int = 0
	var best_distance: int = 0
	for offset: Vector2i in COMPASS_OFFSETS:
		for dy: int in VillagerNavGraph.VERTICAL_STEP_OFFSETS:
			var candidate: Vector3i = occupant_cell + Vector3i(offset.x, dy, offset.y)
			if not predicate_source.is_standable(candidate):
				continue
			if not predicate_source.is_step_legal(occupant_cell, candidate):
				continue
			var height_difference: int = absi(dy)
			var distance: int = VillagerJobSelector.chebyshev_distance(candidate, requester_cell)
			if (
				best_cell == null
				or height_difference < best_height_difference
				or (height_difference == best_height_difference and distance > best_distance)
			):
				best_cell = candidate
				best_height_difference = height_difference
				best_distance = distance
	return best_cell
