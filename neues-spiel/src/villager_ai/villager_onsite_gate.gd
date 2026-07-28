## On-site occupancy gate (Story villager-ai-012, GDD Rule 5/
## [TR-villager-ai-behavior-054]) -- wires [ConstructionJobQueue]/
## [ConstructionTickLoop]'s own occupied-cell-defer seam ([method
## ConstructionJobQueue.set_occupancy_predicate], forwarding to [method
## ConstructionTickLoop.set_occupancy_predicate]) for REAL, against actual
## villager positions, for the first time. Both [ConstructionJobQueue]'s and
## [ConstructionTickLoop]'s own class doc comments explicitly reserve this
## exact seam for "a future Villager AI on-site-work story" (PROVISIONAL
## AC21/AC36b, building-030) -- this class is that story's wiring.
##
## `RefCounted`, population-wide shared collaborator -- mirrors
## [VillagerDecidingScheduler]/[VillagerNavGraph]'s own established
## "separate, code-assigned, no Inspector representation" precedent, not a
## per-[VillagerAi] member.
##
## Composes TWO distinct gates behind the SAME occupancy-predicate seam --
## both read, from [ConstructionTickLoop]'s point of view, as simply
## "construction cannot proceed on this cell THIS tick" (that class has no
## villager-position concept at all, see its own doc comment):
## 1. **On-site** (Rule 5/AC12/AC13): the villager who actually holds the
##    claim on a cell must be on-site ([method
##    ConstructionJobQueue.is_on_site]) for that cell's progress to accrue
##    at all -- gates the FULL travel period too, since [method
##    ConstructionTickLoop.claim_job] flips a cell to UNDER_CONSTRUCTION at
##    CLAIM time, before travel even begins.
## 2. **Occupied-cell defer** (Building System Edge Case 6/AC36, this
##    story's own AC40b): if any OTHER registered villager currently stands
##    exactly on the target cell, the assigned worker's own progress is
##    deferred until that occupant vacates. **Story villager-ai-013 (this
##    revision)**: the actual vacate REQUEST is now wired here too -- [method
##    _is_blocked] calls [method VillagerAi.request_vacate] on the occupant
##    ("the builder requests a vacate," GDD Rule 7's own wording) as a
##    side effect of detecting the occupied cell, passing the assigned
##    worker's own on-site position as the F4 "requester" [VillagerAi.
##    request_vacate] steps the occupant away from. That method is itself a
##    no-op unless the occupant is `State.WANDERING` (Rule 7's "idle or
##    wandering... mid-activity NOT interrupted" contrast) -- a `WORKING`/
##    `SLEEPING` occupant is therefore left entirely untouched, exactly this
##    method's own return value already implied on its own (`true`, deferred)
##    before this revision. The request is safely re-issued every tick the
##    cell stays occupied: [method VillagerAi.request_vacate] itself is
##    idempotent once a vacate step is under way (see that method's own doc
##    comment), so this call site needs no once-only guard of its own.
##
## Connection ordering is NOT this class's concern (see [VillagerAi]'s own
## `_tick_working` doc comment, and [ConstructionTickLoop]'s class doc
## comment point 2, for why [ConstructionTickLoop] must connect to the
## shared tick source BEFORE any [VillagerAi] does, for AC13's
## never-partial-credit guarantee) -- this class only supplies the
## predicate [ConstructionTickLoop] consults each tick; it does not itself
## listen to any tick signal.
class_name VillagerOnSiteGate
extends RefCounted

## The queue this gate wires its composed predicate into (see class doc
## comment). Stored for clarity/observability only -- every actual query
## this class makes goes through [member _villagers] plus the static
## [method ConstructionJobQueue.is_on_site], never back into [param
## job_queue] itself after [method _init].
var _job_queue: ConstructionJobQueue

## Every currently-registered [VillagerAi] this gate considers when
## resolving a cell's assigned worker (point 1) and any other occupant
## (point 2) -- keyed by [method VillagerAi.get_villager_id] (mirrors
## [ConstructionJobQueue]'s own `_claims_by_villager` keying precedent).
var _villagers: Dictionary[int, VillagerAi] = {}


## Wires this gate's composed predicate into [param job_queue] immediately
## (see class doc comment) -- mirrors [ConstructionJobQueue]'s own "identity
## supplied at construction" precedent.
func _init(job_queue: ConstructionJobQueue) -> void:
	assert(job_queue != null, "VillagerOnSiteGate requires a ConstructionJobQueue")
	_job_queue = job_queue
	_job_queue.set_occupancy_predicate(_is_blocked)


## Registers [param villager] with this gate -- a future population-assembly
## story's own per-villager wiring step (mirrors [method
## VillagerDecidingScheduler.enqueue]'s "whichever code assembles the
## population" precedent). Idempotent-in-effect: re-registering the SAME
## villager id simply overwrites its own dictionary entry with itself.
func register_villager(villager: VillagerAi) -> void:
	_villagers[villager.get_villager_id()] = villager


## Removes [param villager] from this gate's tracked population (e.g. a
## villager despawning) -- a no-op if it was never registered.
func unregister_villager(villager: VillagerAi) -> void:
	_villagers.erase(villager.get_villager_id())


## The composed occupancy predicate (see class doc comment points 1/2) --
## `Callable(cell: Vector3i) -> bool` per [method
## ConstructionTickLoop.set_occupancy_predicate]'s own contract, `true`
## meaning "defer -- do not credit this cell this tick." Returns `false`
## (never blocks) if no REGISTERED villager currently holds the claim this
## cell -- fails open rather than silently stalling a job whose assigned
## worker this gate simply has not been told about yet (a wiring-order gap
## a future population-assembly story would need to fix, not a defect this
## class should mask by blocking indefinitely).
func _is_blocked(cell: Vector3i) -> bool:
	var worker: VillagerAi = _find_assigned_worker(cell)
	if worker == null:
		return false
	if not ConstructionJobQueue.is_on_site(cell, worker.get_current_cell()):
		return true
	for id: int in _villagers:
		if id == worker.get_villager_id():
			continue
		var occupant: VillagerAi = _villagers[id]
		if occupant.get_current_cell() == cell:
			occupant.request_vacate(worker.get_current_cell())
			return true
	return false


## Finds the registered [VillagerAi] whose OWN currently-claimed job cell
## (see [method VillagerAi.get_claimed_job_cell]) equals [param cell] -- the
## reverse of [ConstructionJobQueue]'s own forward `villager_id -> cell`
## claim map, resolved here without needing a second accessor on that class
## (this gate already holds the population it needs). Returns `null` if no
## registered villager currently claims [param cell].
func _find_assigned_worker(cell: Vector3i) -> VillagerAi:
	for id: int in _villagers:
		var villager: VillagerAi = _villagers[id]
		if villager.get_claimed_job_cell() == cell:
			return villager
	return null
