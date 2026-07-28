## Building System's construction job queue (Story building-030, ADR-0016
## primary -- "Released project cells become jobs villagers claim and
## execute (ADR-0007 job flow). The queue semantics are owned by Building
## System; claim locking, travel/arrival, and abandonment are Villager AI's."
## ADR-0007 secondary -- Villager AI job-execution flow this class feeds;
## Core Rule 12 [TR-building-system-053]/[TR-building-system-054]/
## [TR-building-system-055]/[TR-building-system-056]/[TR-building-system-037]/
## [TR-building-system-087]).
##
## `RefCounted`, not `Resource` or `Node` -- a plain, non-`@export`ed shared
## collaborator, mirroring [VillagerDecidingScheduler]/[VillagerNavGraph]'s
## own established "population-wide shared object, code-assigned, no
## Inspector-editable representation" precedent, NOT [BuildProject]'s
## "per-instance, one per project" shape: this class aggregates across
## MULTIPLE projects and is itself the one thing every villager's [member
## VillagerAi.job_queue] duck-typed dependency ultimately points at once a
## future population-assembly story wires it in (out of this story's own
## scope -- no scene assembly exists yet in this codebase).
##
## Owns exactly the "Building-owned halves" this story's own Implementation
## Notes name -- queue aggregation/ordering, claim/release bookkeeping (one
## job per villager, [TR-building-system-054]), the on-site predicate
## definition ([TR-building-system-056]), and the unreachable-ghost
## signal/flag ([TR-building-system-087]) -- and nothing else:
##
## 1. **Aggregation across projects, no registry yet** (Rule 12,
##    [TR-building-system-053]/[TR-building-system-106]): [method add_project]/
##    [method remove_project] are the seam Story building-003's future
##    26-neighborhood grouping/reverse-index registry will call once it
##    lands (not landed anywhere in this codebase yet) -- until then, a
##    caller (a headless test, or a future scene-assembly story) registers
##    each [BuildProject] directly. [method get_available_jobs] concatenates
##    [method BuildProject.get_building_eligible_cells] across every tracked
##    project IN REGISTRATION ORDER, preserving each project's own already-
##    commit-time-ordered internal result -- ordering here, exactly as Story
##    building-004 established for a single project, is for display/
##    tie-breaking only, never forced servicing order (Villager AI chooses
##    among available jobs by its own criteria, e.g. F2 proximity).
## 2. **Claim/release bookkeeping, one job per villager**
##    ([TR-building-system-054]): [method claim_job] rejects a villager that
##    already holds a claim (the caller must [method release_claim] first --
##    "a villager finishes or abandons its current job before claiming
##    another"). Delegates the actual Planned -> UnderConstruction mechanics
##    to [member tick_loop] (the SAME [ConstructionTickLoop.claim_job] seam
##    that class's own doc comment names as this story's real caller) --
##    this class adds no second state-transition mechanism, only the
##    villager-id <-> cell bookkeeping [ConstructionTickLoop] itself does not
##    track ([TR-building-system-055]'s per-cell parallelism falls out of
##    keying by villager id here and by cell address there, independently).
## 3. **Villager AI's exact duck-typed contract** ([method
##    VillagerAi._has_available_job]/[method VillagerAi._release_job_claim]):
##    [method has_available_job] and [method release_claim] are named and
##    signed IDENTICALLY to the two members [member VillagerAi.job_queue]'s
##    own doc comment already documents as the mocked-boundary contract
##    (`func has_available_job() -> bool` / `func release_claim(villager_id: int) -> void`)
##    -- this class is the REAL object that duck-typed boundary resolves to,
##    once a future population-assembly story assigns it. No renamed/second
##    surface is introduced.
## 4. **On-site predicate** (Rule 12, [TR-building-system-056]): [method
##    is_on_site] is a pure, static, Building-owned definition -- "the
##    villager occupies the target cell or an orthogonally adjacent cell
##    (including directly below/above)." This story's own test drives it
##    directly with hand-picked standing cells (the MOCKED boundary this
##    story's Implementation Notes name); the REAL wiring -- calling this
##    with an actual villager's [method VillagerAi.get_current_cell] every
##    tick -- is a future Villager AI on-site-work story's job (PROVISIONAL,
##    AC21/AC36b), not this class's own crediting loop (which has no
##    villager-position concept at all, see [ConstructionTickLoop]'s own
##    doc comment).
## 5. **Occupied-cell defer wiring** (Edge Case 6, [TR-building-system-037]):
##    [method set_occupancy_predicate] forwards directly to [member
##    tick_loop]'s OWN identically-shaped seam ([method
##    ConstructionTickLoop.set_occupancy_predicate]) -- this class performs
##    no gating of its own; [ConstructionTickLoop] is the sole per-tick
##    crediting loop and therefore the only place the gate can actually
##    take effect (see that class's own doc comment point 2b).
## 6. **Unreachable feedback** (Edge Case 5, [TR-building-system-087]):
##    [method report_unreachable] sets [member BlueprintCell.is_unreachable]
##    and emits [signal job_reported_unreachable] -- "the job stays in the
##    queue and is retried periodically; the ghost persists indefinitely"
##    holds STRUCTURALLY here: reporting unreachable never touches [member
##    BlueprintCell.state] (still `PLANNED`, still enumerable by [method
##    get_available_jobs] every single call, regardless of how many ticks
##    pass -- AC35), only the rendering-annotation flag changes. A
##    subsequent successful [method claim_job] on the SAME cell clears the
##    flag and emits [signal job_became_reachable] ("on re-claim the ghost
##    returns to normal Planned").
## 7. **Worker attribution recording** (Rule 12/14f, ADR-0016 Decision
##    Sec.4, [TR-building-system-109], AC58; Story building-005): a
##    successful [method claim_job] resolves which tracked [BuildProject]
##    owns the claimed cell ([method _find_owning_project]) and calls
##    [method BuildProject.on_job_claimed] on it -- the villager id is
##    recorded against the cell and rolled into the project's [member
##    BuildProject.worker_ids] aggregate as that SAME claim's own side
##    effect, never a separate control decision. Attribution never gates or
##    influences this class's own claim/scheduling behavior (Control
##    Manifest Forbidden rule) -- no method here ever reads [member
##    BuildProject.worker_ids].
##
## **Explicitly out of scope** (this story's own Out of Scope section, and
## the neighbouring stories/epics that own it):
## - Villager AI's F2 nearest-reachable job SELECTION (Story villager-ai-010)
##   -- [method get_available_jobs] returns every eligible cell; picking
##   WHICH one to claim is entirely that story's own criteria, never decided
##   here.
## - Villager AI's real atomic claim/attribution race resolution (Story
##   villager-ai-011) -- [method claim_job] enforces "one job per villager"
##   and "no double-claim on one cell" (via [member tick_loop]'s own guard),
##   which together already give a deterministic single winner when called
##   in stable villager order. Recording `worker_ids` attribution (ADR-0016
##   Decision Sec.4, Story building-005) IS implemented here (see class doc
##   comment point 7 below) -- as the successful claim's own side effect,
##   the SAME call site that already resolves both the villager id and the
##   claimed cell.
## - The claim/travel/arrival/abandon MECHANICS themselves (pathing,
##   redirect, watchdog rescue) -- Villager AI epic entirely; this class only
##   exposes the queue those mechanics call into.
## - Story building-003's real 26-neighborhood grouping/reverse-index
##   registry -- [method add_project]/[method remove_project] are the seam
##   it will call; no grouping/merge logic of any kind exists here.
## - Rendering the pulsing-orange ghost tint / the non-modal UI hint itself
##   -- no Building UI exists yet in this codebase; [signal
##   job_reported_unreachable]/[signal job_became_reachable] are the seam a
##   future UI story consumes.
class_name ConstructionJobQueue
extends RefCounted

## Fires when [method report_unreachable] successfully flags a still-tracked
## eligible cell (Edge Case 5, [TR-building-system-087]) -- the ghost-tint /
## non-modal-hint trigger a future UI story consumes. Never fires for a cell
## this queue cannot currently find among its tracked projects' eligible
## cells.
signal job_reported_unreachable(cell: Vector3i)

## Fires when a successful [method claim_job] clears a previously-set
## [member BlueprintCell.is_unreachable] flag on the SAME cell ("on re-claim
## the ghost returns to normal Planned," Edge Case 5). Never fires for a
## claim on a cell that was never flagged unreachable.
signal job_became_reachable(cell: Vector3i)

## Injected collaborator (ADR-0001 shared-object style, mirrors [member
## VillagerAi.nav_graph]'s own "assigned directly by whichever code
## constructs this, asserted at first real use" precedent) -- the SAME
## [ConstructionTickLoop] instance this queue's [method claim_job]/[method
## release_job]/[method set_occupancy_predicate] all delegate the actual
## per-cell tick-crediting mechanics to. Assigned via [method _init].
var tick_loop: ConstructionTickLoop

## Every [BuildProject] this queue currently aggregates jobs from (see class
## doc comment point 1) -- in registration order, which [method
## get_available_jobs] preserves.
var _projects: Array[BuildProject] = []

## Villager id -> currently-claimed cell address (see class doc comment
## point 2). A villager absent from this map holds no claim through this
## queue.
var _claims_by_villager: Dictionary[int, Vector3i] = {}


## Requires [param p_tick_loop] up front (mirrors [BuildProject]'s own
## "identity supplied at construction" precedent) -- this queue is
## meaningless without a tick loop to delegate the actual claim/release
## mechanics to.
func _init(p_tick_loop: ConstructionTickLoop) -> void:
	assert(p_tick_loop != null, "ConstructionJobQueue requires a ConstructionTickLoop")
	tick_loop = p_tick_loop


## Registers [param project] as a source of jobs (see class doc comment
## point 1) -- idempotent-in-effect: registering the SAME project instance
## twice is harmless (it simply appears twice in [member _projects] and
## therefore twice in [method get_available_jobs]'s naive concatenation;
## callers are expected not to double-register, matching every other
## registration-style seam in this codebase, e.g. [CommitPipeline]'s
## resolver-callable seam, which carries no such guard either).
func add_project(project: BuildProject) -> void:
	_projects.append(project)


## Removes [param project] from this queue's tracked set (see class doc
## comment point 1) -- a no-op if [param project] is not currently tracked.
func remove_project(project: BuildProject) -> void:
	_projects.erase(project)


## Every currently BUILDING-eligible [BlueprintCell] across every tracked
## project (see class doc comment point 1), in registration order. Recomputed
## fresh on every call -- this class caches no snapshot of its own, mirroring
## [method BuildProject.get_building_eligible_cells]'s own "structurally
## gated on state" freshness guarantee.
func get_available_jobs() -> Array[BlueprintCell]:
	var jobs: Array[BlueprintCell] = []
	for project: BuildProject in _projects:
		jobs.append_array(project.get_building_eligible_cells())
	return jobs


## Villager AI's exact duck-typed contract (see class doc comment point 3;
## [method VillagerAi._has_available_job]) -- `true` iff [method
## get_available_jobs] is non-empty.
func has_available_job() -> bool:
	return not get_available_jobs().is_empty()


## Claims [param cell] for [param villager_id] (see class doc comment point
## 2). Fails (`false`, nothing mutated) if [param villager_id] already holds
## a claim through this queue (TR-054's "one job per villager at a time"),
## or if [param cell] is not currently a BUILDING-eligible cell of any
## tracked project (covers: cell belongs to no tracked project, its project
## is not BUILDING, or the cell itself is not [constant
## BlueprintCell.MicroState.PLANNED] -- e.g. already claimed by someone
## else), or if [member ConstructionTickLoop.claim_job] itself rejects (the
## double-claim guard that class already owns). On success, records the
## villager <-> cell claim, delegates the actual state transition to [member
## tick_loop], and -- if [param cell] was previously flagged unreachable
## ([method report_unreachable]) -- clears the flag and emits [signal
## job_became_reachable] (Edge Case 5's "on re-claim the ghost returns to
## normal Planned"). [param job_type] (Story villager-ai-016, default
## [constant ConstructionTickLoop.JobType.BUILD]) forwards unchanged to
## [member tick_loop]'s own identically-shaped parameter -- this class adds
## no job-type bookkeeping/meaning of its own, it is purely a pass-through
## so a future dig/demolition-project caller (Story building-013/014, not
## yet landed) has a real seam to pass a non-BUILD value through, exactly
## like [method set_seal_prevention_predicate] is a pure forward too.
func claim_job(
	cell: Vector3i,
	villager_id: int,
	job_type: ConstructionTickLoop.JobType = ConstructionTickLoop.JobType.BUILD
) -> bool:
	if _claims_by_villager.has(villager_id):
		return false
	var blueprint_cell: BlueprintCell = _find_eligible_cell(cell)
	if blueprint_cell == null:
		return false
	if not tick_loop.claim_job(blueprint_cell, villager_id, job_type):
		return false
	_claims_by_villager[villager_id] = cell
	if blueprint_cell.is_unreachable:
		blueprint_cell.is_unreachable = false
		job_became_reachable.emit(cell)
	# Story building-005 (ADR-0016 Decision Sec.4, AC58): record worker
	# attribution as this claim's own side effect -- see class doc comment
	# point 7 and [BuildProject.on_job_claimed]'s own doc comment for why
	# this call site, not Villager AI, is the recording contract's real
	# caller.
	var owning_project: BuildProject = _find_owning_project(cell)
	if owning_project != null:
		owning_project.on_job_claimed(cell, villager_id)
	return true


## Villager AI's exact duck-typed contract (see class doc comment point 3;
## [method VillagerAi._release_job_claim]) -- releases [param villager_id]'s
## currently-held claim (if any) back to the queue via [member
## ConstructionTickLoop.release_job], then forgets the villager <-> cell
## bookkeeping. A no-op (never errors) if [param villager_id] holds no claim
## through this queue -- mirrors [method VillagerAi._release_job_claim]'s
## own "only ever called when a claim could plausibly be held" caller
## discipline, but stays safe even if that discipline is ever violated.
func release_claim(villager_id: int) -> void:
	if not _claims_by_villager.has(villager_id):
		return
	var cell: Vector3i = _claims_by_villager[villager_id]
	tick_loop.release_job(cell)
	_claims_by_villager.erase(villager_id)


## Whether [param villager_id] currently holds a claim through this queue --
## read-only observability/test seam (mirrors [method
## ConstructionTickLoop.is_job_active]'s own "boolean query over the
## internal claim map" shape).
func has_claim(villager_id: int) -> bool:
	return _claims_by_villager.has(villager_id)


## Flags [param cell] unreachable (Edge Case 5, [TR-building-system-087]) --
## the report itself is Villager AI's pathing-failure detection (PROVISIONAL
## here, this story's own mocked boundary); this method only registers it.
## Sets [member BlueprintCell.is_unreachable] and emits [signal
## job_reported_unreachable]; never touches [member BlueprintCell.state] --
## the cell stays exactly as `PLANNED`/BUILDING-eligible as it already was
## (AC35: "the job remains queued... never auto-canceled"). Returns `false`
## (no-op) if [param cell] is not currently a BUILDING-eligible cell of any
## tracked project.
func report_unreachable(cell: Vector3i) -> bool:
	var blueprint_cell: BlueprintCell = _find_eligible_cell(cell)
	if blueprint_cell == null:
		return false
	blueprint_cell.is_unreachable = true
	job_reported_unreachable.emit(cell)
	return true


## Forwards to [member ConstructionTickLoop.set_occupancy_predicate] (see
## class doc comment point 5) -- this class performs no gating of its own;
## [member tick_loop] is the sole per-tick crediting loop the predicate can
## actually take effect against.
func set_occupancy_predicate(predicate: Callable) -> void:
	tick_loop.set_occupancy_predicate(predicate)


## Forwards to [member ConstructionTickLoop.set_seal_prevention_predicate]
## (Story villager-ai-016, GDD Rule 16/F6) -- this class performs no
## trap-checking/abandon-count bookkeeping of its own; [member tick_loop] is
## the sole per-tick completion-write dispatcher the predicate can actually
## take effect against. [VillagerSealPreventionGate] is the real wirer (its
## own `_init` calls this exactly once, mirroring [VillagerOnSiteGate]'s own
## `_init` -> [method set_occupancy_predicate] precedent) -- and, on refusal,
## calls THIS class's own [method release_claim] directly (never [member
## tick_loop]'s [method ConstructionTickLoop.release_job] directly), so both
## this queue's `_claims_by_villager` bookkeeping AND the tick loop's active-
## job state stay in sync in the SAME call, exactly as every other
## claim-relinquishing path in this codebase already does.
func set_seal_prevention_predicate(predicate: Callable) -> void:
	tick_loop.set_seal_prevention_predicate(predicate)


## On-site predicate (Rule 12, [TR-building-system-056]; see class doc
## comment point 4) -- `true` iff [param standing_cell] equals [param
## target_cell] itself, or differs from it along EXACTLY one axis by EXACTLY
## one cell (an orthogonal neighbour, including directly below/above: a
## Y-axis-only difference of 1 counts identically to an X- or Z-axis-only
## difference of 1). A diagonal difference (more than one axis differing) or
## any distance greater than one cell along its differing axis is never
## on-site. Pure, static, stateless -- no villager instance, no [Vector3i]
## interpolation of any kind, mirrors [method VillagerAi.is_step_legal]'s
## own axis-counting style.
static func is_on_site(target_cell: Vector3i, standing_cell: Vector3i) -> bool:
	if standing_cell == target_cell:
		return true
	var offset: Vector3i = standing_cell - target_cell
	var differing_axes: int = 0
	if offset.x != 0:
		differing_axes += 1
	if offset.y != 0:
		differing_axes += 1
	if offset.z != 0:
		differing_axes += 1
	if differing_axes != 1:
		return false
	return absi(offset.x) <= 1 and absi(offset.y) <= 1 and absi(offset.z) <= 1


## Shared lookup for [method claim_job]/[method report_unreachable] -- scans
## every tracked project's CURRENT [method BuildProject.get_building_eligible_cells]
## result (never a project's raw [member BuildProject.cells] dictionary) so
## both callers automatically inherit that method's own BUILDING-state/
## PLANNED-only gating for free, with no duplicated eligibility logic here.
## Returns `null` if [param cell] is not currently eligible in any tracked
## project.
func _find_eligible_cell(cell: Vector3i) -> BlueprintCell:
	for project: BuildProject in _projects:
		for blueprint_cell: BlueprintCell in project.get_building_eligible_cells():
			if blueprint_cell.cell == cell:
				return blueprint_cell
	return null


## Shared lookup for [method claim_job]'s attribution wiring (class doc
## comment point 7, Story building-005) -- the tracked [BuildProject] that
## currently has [param cell] among its own [member BuildProject.cells].
## Only ever called AFTER [method _find_eligible_cell] has already confirmed
## [param cell] is a real, currently-eligible cell of exactly one tracked
## project (Story building-003's future reverse index is the whole-world
## uniqueness guarantee this method itself does not enforce). Returns `null`
## if no tracked project currently tracks [param cell] -- defensive only,
## never hit from [method claim_job]'s own call site.
func _find_owning_project(cell: Vector3i) -> BuildProject:
	for project: BuildProject in _projects:
		if project.has_cell(cell):
			return project
	return null
