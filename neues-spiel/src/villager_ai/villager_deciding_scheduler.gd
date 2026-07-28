## Deciding-pass scheduler (Story villager-ai-005, ADR-0008 Decision §2:
## "Tick-staggered Deciding-pass processing via a per-tick budget
## (`max_deciding_per_tick`) and a stable-order FIFO queue").
##
## **Architecture note** (this story's own resolution of a real tension):
## stories 001-004 established this codebase's actual shape as ONE
## [VillagerAi] instance PER villager, with NO manager class coordinating
## them (see [VillagerAi.get_current_cell]'s own doc comment). ADR-0008's Key
## Interfaces snippet, however, shows `_deciding_queue`/`_on_tick()`/
## `_run_deciding_pass(villager_id)` as though ONE object owned the whole
## population's queue and drained it each tick. Taken completely literally as
## a method duplicated onto EVERY [VillagerAi] instance's own per-instance
## tick handler, that pseudocode would let an N-villager population drain up
## to N queue entries per GLOBAL tick (once per instance's own signal
## handler) -- silently defeating the very budget it exists to enforce.
##
## This class resolves that tension: it is the ONE shared, budget-owning
## queue ADR-0008's mechanism actually requires, factored OUT of any single
## [VillagerAi] instance so "one instance per villager, no manager" remains
## true. It never holds a [VillagerAi] reference, never drives FSM state, and
## never calls into any villager's own behaviour -- each [VillagerAi]
## instance still decides everything about its own behaviour independently;
## it merely CONSULTS this shared bookkeeping object, the same relationship
## a plain shared data structure has to its callers, not a coordinating
## "manager."
##
## Deliberately a plain [RefCounted] -- not a `Resource` (no Inspector
## authoring need) and not a `Node` (no scene-tree presence needed) -- with
## ZERO dependencies beyond what [method connect_to_tick_source] is
## explicitly handed. [method enqueue] / [method advance_tick] / [method
## is_runnable_this_tick] / [method is_queued] / [method queue_length] have
## NO dependency on [TimeTickSystem], [VillagerAi], or any scene tree at all,
## so every one of them is directly unit-testable exactly as ADR-0008's own
## Validation Criteria describes: "enqueues more villagers than
## `max_deciding_per_tick` in a single tick and asserts only the budgeted
## count runs... the rest remain queued in stable order... processed on
## subsequent ticks."
##
## **Sharing across a population** (deliberately NOT a static/class-level
## singleton -- that would be hidden shared state surviving across
## independent GdUnit4 test runs in the same process, violating this
## codebase's test-isolation discipline, coding-standards.md's
## "Isolation"/"Determinism" rules): whichever code assembles a villager
## population (a headless test, or a future spawner story) constructs exactly
## ONE instance of this class and assigns it to every [VillagerAi.scheduler]
## field in that population -- explicit dependency injection (ADR-0001's
## pattern), never a hidden global.
class_name VillagerDecidingScheduler
extends RefCounted

## Pending villager ids awaiting a Deciding pass, stable FIFO order (insertion
## order = enqueue order = the stable villager-index order every caller is
## responsible for enqueuing in, GDD Edge Case 3 / F2 tie-break convention).
## Never reordered, never deduplicated by re-sorting -- [method enqueue]'s
## own idempotency guard (via [member _queued_ids]) is what keeps this a
## set-like FIFO rather than a plain list that could grow duplicate entries.
var _queue: Array[int] = []

## O(1) membership guard for [member _queue] -- prevents a villager already
## queued from being appended a second time, which would otherwise let a
## repeated eligibility trigger (e.g. [VillagerAi]'s own `decision_interval`
## re-check firing every tick while still queued) silently bump that
## villager to the BACK of the FIFO on every redundant call, corrupting the
## stable-order guarantee (GDD Edge Case 3 / [TR-villager-ai-behavior-013]).
var _queued_ids: Dictionary = {}

## The set of villager ids permitted to run a Deciding pass THIS tick --
## recomputed WHOLESALE by [method advance_tick] every time it is called
## (replacing whatever set was runnable on the previous call, never
## accumulating). A dequeued id's runnable window is exactly the one tick it
## was dequeued for (ADR-0008 Decision §2: "budget caps how many NEW passes
## START per tick") -- it is never carried over to a later tick by this
## class; a villager whose pass must run again later re-enters entirely via
## a fresh [method enqueue] call from its own next eligibility trigger.
var _runnable_this_tick: Dictionary = {}

## The tuning-config dependency [method connect_to_tick_source] stores so
## [method _on_scheduler_tick] can read a fresh `max_deciding_per_tick` every
## tick (config is read-only after boot per ADR-0002, so re-reading it here
## is always safe and never stale).
var _config: VillagerAIConfig = null

## Guards [method connect_to_tick_source] so the actual signal connection
## happens exactly ONCE regardless of how many [VillagerAi] instances in the
## population call it during their own `setup()` -- no fragile "which
## instance connects first" ordering assumption is needed anywhere else in
## this class or its callers.
var _is_connected_to_tick_source: bool = false


## Marks [param villager_id] Deciding-eligible (ADR-0008 Decision §2: "When a
## villager becomes eligible for a Deciding pass... it enters a pending queue
## rather than running F2 selection immediately"). Idempotent: a villager
## already queued (waiting from an earlier tick, not yet dequeued) is left
## exactly where it is -- appending again would violate the stable FIFO order
## this story's AC (villager order within the stagger follows stable
## processing order) requires. Safe to call multiple times per tick, from
## multiple independent trigger sources (need-urgent, job-complete,
## `decision_interval` elapsed, per this story's Implementation Notes) --
## every one of them funnels through this single method.
func enqueue(villager_id: int) -> void:
	if _queued_ids.has(villager_id):
		return
	_queue.append(villager_id)
	_queued_ids[villager_id] = true


## Drains up to [param budget] villager ids from the FRONT of [member _queue]
## (FIFO -- oldest-enqueued first, ADR-0008 Decision §2's "processed FIFO
## within the stable order") and marks EXACTLY those ids runnable for this
## tick via [member _runnable_this_tick] -- clearing whatever set of ids was
## runnable on the previous call first, so a villager's "may run" window
## never silently persists across ticks (this story's AC: "the budget caps
## new passes STARTED per tick, never interrupts an in-progress pass" --
## and, symmetrically, never resurrects a PAST tick's dequeue either). An id
## popped here is removed from [member _queue]/[member _queued_ids]
## immediately -- it is never re-added to the queue by this method; a
## villager whose Deciding pass needs to run again later re-enters only via
## a fresh [method enqueue] call.
##
## Never touches, removes, or otherwise "interrupts" an id that is NOT
## currently sitting in [member _queue] -- structurally, an id already
## dequeued and mid-execution (a real [VillagerAi]'s synchronous
## `_tick_deciding()` call, which always runs to completion before this
## method could next be invoked, GDScript being single-threaded) was already
## removed from the queue by ITS OWN dequeue, so there is nothing left in
## this queue for a later call to disturb (this story's "no mid-pass
## interruption" AC).
func advance_tick(budget: int) -> void:
	_runnable_this_tick.clear()
	var remaining: int = budget
	while remaining > 0 and not _queue.is_empty():
		var villager_id: int = _queue.pop_front()
		_queued_ids.erase(villager_id)
		_runnable_this_tick[villager_id] = true
		remaining -= 1


## Whether [param villager_id] was dequeued by the MOST RECENT [method
## advance_tick] call -- the single per-tick permission gate every
## [VillagerAi] instance consults before actually running its own Deciding
## pass body ([VillagerAi._tick_deciding], story 006's real priority-list
## logic).
func is_runnable_this_tick(villager_id: int) -> bool:
	return _runnable_this_tick.has(villager_id)


## Whether [param villager_id] currently sits in the pending FIFO queue,
## awaiting a future [method advance_tick] dequeue -- observability for
## tests and any future debug tooling (a Deciding-pass inspector, per this
## agent's own "AI Debugging Tools" responsibility).
func is_queued(villager_id: int) -> bool:
	return _queued_ids.has(villager_id)


## Current pending-queue length -- observability for tests (e.g. asserting
## "N minus budget villagers remain queued after one tick's dequeue").
func queue_length() -> int:
	return _queue.size()


## Connects this scheduler's own per-tick budget drain to [param tick_source]
## (a [TimeTickSystem]-shaped object exposing `signal tick()`, exactly the
## same duck-typed shape [VillagerAi.time_tick_system] depends on) and stores
## [param config] so [method _on_scheduler_tick] can read
## `max_deciding_per_tick` fresh every tick. Idempotent -- calling this
## repeatedly (once per [VillagerAi] instance's own `setup()` in a
## population sharing this same scheduler instance) connects the underlying
## signal exactly ONCE; every call after the first only refreshes
## [member _config] (harmless: ADR-0002's one-`.tres`-per-module convention
## means every villager in a population is wired to the SAME shared config
## object anyway).
func connect_to_tick_source(tick_source: Object, config: VillagerAIConfig) -> void:
	_config = config
	if _is_connected_to_tick_source:
		return
	@warning_ignore("unsafe_property_access")
	tick_source.tick.connect(_on_scheduler_tick)
	_is_connected_to_tick_source = true


## [signal TimeTickSystem.tick] handler -- the ONE place this scheduler's own
## budget drain fires from, once per global tick, regardless of how many
## villagers share this instance (this is what makes [method advance_tick]
## bounded to `max_deciding_per_tick` PER GLOBAL TICK, not per villager
## instance -- the exact defect this class's own header doc names as the
## reason it exists at all).
func _on_scheduler_tick() -> void:
	assert(_config != null, "VillagerDecidingScheduler.connect_to_tick_source was never called")
	advance_tick(_config.max_deciding_per_tick)
