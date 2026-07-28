## Seal-prevention negative-write gate (Story villager-ai-016, GDD Rule
## 16/F6, [TR-villager-ai-behavior-101]/102/106/107; ADR-0009 slice
## propagation Sec.2b) -- wires [ConstructionJobQueue]/[ConstructionTickLoop]'s
## own seal-prevention seam ([method
## ConstructionJobQueue.set_seal_prevention_predicate], forwarding to [method
## ConstructionTickLoop.set_seal_prevention_predicate]) for REAL, against
## actual villager positions, mirroring [VillagerOnSiteGate]'s own
## established "separate shared collaborator wired behind a Building System
## predicate seam" architecture exactly.
##
## `RefCounted`, population-wide shared collaborator -- same "separate,
## code-assigned, no Inspector representation" precedent as
## [VillagerDecidingScheduler]/[VillagerNavGraph]/[VillagerOnSiteGate], not a
## per-[VillagerAi] member.
##
## Implements the GDD F6 formula exactly:
## `allow_write = NOT would_trap_builder OR (abandon_count >= seal_
## prevention_abandon_limit) OR (job_type != build)`
## -- [method VillagerAi.would_trap_builder] supplies the first term (this
## class has zero walkability arithmetic of its own, Control Manifest
## Forbidden: "never duplicate walkability rules or constants"); this class
## owns exactly the OTHER two terms -- the per-(job, villager) `abandon_count`
## bookkeeping (monotonic, bounded above by `seal_prevention_abandon_limit`,
## reset when a DIFFERENT villager claims the SAME cell) and the dig/
## demolition exemption -- plus the actual REFUSAL side effect: releasing the
## claim back to [member _job_queue] via [method
## ConstructionJobQueue.release_claim] (never [ConstructionTickLoop.
## release_job] directly -- see [method ConstructionJobQueue.
## set_seal_prevention_predicate]'s own doc comment for why THIS class must
## call the QUEUE, not the tick loop, to keep both layers' bookkeeping in
## sync in the SAME call).
##
## Two deliberate always-allow exceptions sit ON TOP OF that three-term
## formula, both narrated by ADR-0009's own slice-propagation Sec.2b prose
## rather than spelled out as a fourth `OR` term in the GDD's own F6 table:
##
## 1. **Self-seal** ("a builder sealing itself with its own same-job
##    completion write proceeds unconditionally"): THIS codebase's own
##    established Traveling mechanics (stories 009/012, unrelated to this
##    one) route a claiming villager to stand EXACTLY on its own job's cell
##    for the entire construction period (confirmed by
##    `build_job_cycle_test.gd`'s own AC40 assertion) -- so [param cell]
##    equalling the SAME villager's own [method VillagerAi.get_current_cell]
##    is the ordinary, common case for a normal single-cell job, not a rare
##    edge case. Applying the general trap check there would flag every
##    single normal completion as "trapping" (standing exactly where solid
##    content is about to appear always fails standability), which is
##    plainly not what Rule 16 intends -- so this specific pairing is
##    exempted BEFORE the trap check ever runs. **Story villager-ai-024
##    fix**: this branch now ALSO calls [method
##    VillagerAi.climb_onto_self_sealed_cell] on its way out -- pre-fix, the
##    villager was simply left standing inside the now-solid content until
##    the Unstuck Watchdog's own rescue (Story villager-ai-015) eventually
##    noticed `current_cell` failed standability and teleported it away
##    (usually sideways/down, per that search's own lexicographic tie-break --
##    never back onto the column it was building), which is THE reason a
##    wall's third layer and above could never be reached by job selection at
##    all (see that method's own doc comment for the full root-cause/fix
##    rationale). The exemption's own logic is completely unchanged -- still
##    unconditional, still ahead of the trap check/`abandon_count` -- only the
##    villager's resulting POSITION is now correct instead of embedded. This
##    class still performs no rescue/trap-check of its own for this branch;
##    the Unstuck Watchdog remains the fallback for the rare case the bumped
##    cell itself is not standable.
## 2. **Livelock escape** (GDD Rule 16b, F6, AC56): once `abandon_count`
##    reaches `seal_prevention_abandon_limit` for a (job, villager) pair
##    whose builder stands SOMEWHERE ELSE (not on its own job cell -- e.g. a
##    DIFFERENT job's completion sealed the room this villager already
##    occupies while working a distinct cell), the NEXT attempt's
##    `allow_write` flips true regardless of the trap check -- again left
##    for the watchdog to rescue on its own schedule.
class_name VillagerSealPreventionGate
extends RefCounted

## The queue this gate wires its composed predicate into (see class doc
## comment). Also the real target of every refusal's claim-release call
## (never [member _job_queue]'s own `tick_loop` directly).
var _job_queue: ConstructionJobQueue

## Tuning-config dependency (ADR-0002) -- the sole source of
## `seal_prevention_abandon_limit` (Control Manifest: "no gameplay value ever
## hardcoded"). Read fresh on every evaluation, never cached, so a future
## live-tuning change takes effect on the very next completion attempt.
var _config: VillagerAIConfig

## Every currently-registered [VillagerAi] this gate considers when
## resolving which villager instance's [method VillagerAi.would_trap_builder]
## to consult -- keyed by [method VillagerAi.get_villager_id] (mirrors
## [VillagerOnSiteGate]'s own `_villagers` keying precedent exactly).
var _villagers: Dictionary[int, VillagerAi] = {}

## Per-(job, villager) refusal counter (GDD F6 `abandon_count`), keyed by
## cell address ("job" == the [BlueprintCell] at this cell, this codebase's
## own established one-job-per-cell-address convention -- see
## [ConstructionJobQueue]'s own `_claims_by_villager` doc comment). Absent
## from this [Dictionary] means `0` (never refused yet for the CURRENT
## claimant -- see [member _claimant_by_cell]'s own doc comment for the
## reset rule).
var _abandon_counts: Dictionary[Vector3i, int] = {}

## Which villager id [member _abandon_counts]' entry for this cell currently
## belongs to. Compared against the claimant on every evaluation
## ([method _evaluate]) -- a mismatch means a DIFFERENT villager now holds
## this cell's claim (only possible after a release + re-claim), so
## `abandon_count` resets to `0` for the new claimant BEFORE this attempt is
## evaluated (GDD F6: "`abandon_count`... resets when the job is claimed by
## a different villager").
var _claimant_by_cell: Dictionary[Vector3i, int] = {}


## Wires this gate's composed predicate into [param job_queue] immediately
## (see class doc comment) -- mirrors [VillagerOnSiteGate]'s own `_init`
## precedent exactly.
func _init(job_queue: ConstructionJobQueue, config: VillagerAIConfig) -> void:
	assert(job_queue != null, "VillagerSealPreventionGate requires a ConstructionJobQueue")
	assert(config != null, "VillagerSealPreventionGate requires a VillagerAIConfig")
	_job_queue = job_queue
	_config = config
	_job_queue.set_seal_prevention_predicate(_evaluate)


## Registers [param villager] with this gate -- mirrors [method
## VillagerOnSiteGate.register_villager] exactly (idempotent-in-effect: a
## re-registration simply overwrites its own dictionary entry).
func register_villager(villager: VillagerAi) -> void:
	_villagers[villager.get_villager_id()] = villager


## Removes [param villager] from this gate's tracked population -- mirrors
## [method VillagerOnSiteGate.unregister_villager] exactly.
func unregister_villager(villager: VillagerAi) -> void:
	_villagers.erase(villager.get_villager_id())


## Read-only observability/test seam -- this (job, villager) pair's current
## `abandon_count` (GDD F6), or `0` if never refused. Never negative, never
## above [member VillagerAIConfig.seal_prevention_abandon_limit] (see
## [method _evaluate]'s own "count checked before increment" ordering).
func get_abandon_count(cell: Vector3i) -> int:
	return _abandon_counts.get(cell, 0)


## The composed seal-prevention predicate (see class doc comment) --
## `Callable(cell: Vector3i, villager_id: int, job_type:
## ConstructionTickLoop.JobType) -> bool` per [method
## ConstructionTickLoop.set_seal_prevention_predicate]'s own contract, `true`
## meaning "allow this completion write to commit." Order of checks
## (cheapest/most-certain-to-allow first, short-circuiting on the first
## `true`):
## 1. A different claimant since last evaluated resets `abandon_count` to
##    `0` before anything else runs (GDD F6's own reset rule).
## 2. A non-BUILD [param job_type] always allows (Rule 16 exemption, AC55).
## 3. An unregistered villager (this gate was never told about it) fails
##    OPEN -- allows, exactly [VillagerOnSiteGate]'s own "never blocks if
##    worker unknown" precedent, never a silent indefinite stall over a
##    wiring gap this class did not cause.
## 4. Self-seal (class doc comment point 1): [param cell] equals the SAME
##    villager's own [method VillagerAi.get_current_cell] -- always allows,
##    unconditionally, before the trap check or `abandon_count` are ever
##    consulted.
## 5. Livelock escape (class doc comment point 2, AC56): an already-at-limit
##    `abandon_count` always allows.
## 6. Otherwise [method VillagerAi.would_trap_builder] is the real trap
##    check (AC54) -- a refusal increments `abandon_count` and releases the
##    claim back to [member _job_queue] BEFORE returning `false`.
func _evaluate(
	cell: Vector3i, villager_id: int, job_type: ConstructionTickLoop.JobType
) -> bool:
	if not _claimant_by_cell.has(cell) or _claimant_by_cell[cell] != villager_id:
		_abandon_counts.erase(cell)
		_claimant_by_cell[cell] = villager_id
	if job_type != ConstructionTickLoop.JobType.BUILD:
		return true
	var worker: VillagerAi = _villagers.get(villager_id)
	if worker == null:
		return true
	if worker.get_current_cell() == cell:
		# Story villager-ai-024 fix (the wall-plateau defect): a self-seal no
		# longer just entombs the builder for the Watchdog to clean up later
		# -- it steps the villager UP onto the surface it is about to create,
		# via the SAME synchronous call, so the very next Deciding pass finds
		# it standing exactly on this column's next blueprint cell (see
		# [method VillagerAi.climb_onto_self_sealed_cell]'s own doc comment
		# for the full root-cause/fix rationale). The exemption itself is
		# UNCHANGED -- still unconditional, still checked before
		# `abandon_count`/[method VillagerAi.would_trap_builder] are ever
		# consulted -- only what happens to the villager's OWN position as a
		# result is new.
		worker.climb_onto_self_sealed_cell(cell)
		return true
	var count: int = _abandon_counts.get(cell, 0)
	if count >= _config.seal_prevention_abandon_limit:
		return true
	if not worker.would_trap_builder(cell):
		return true
	_abandon_counts[cell] = count + 1
	_job_queue.release_claim(villager_id)
	return false
