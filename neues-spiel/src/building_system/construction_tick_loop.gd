## Building System's construction tick loop (Story building-029, ADR-0016
## primary -- "when a cell's build time elapses, this system issues the
## Voxel World write and retires the blueprint cell" [TR-building-system-057];
## Time & Tick System secondary -- construction advances on game ticks only,
## never raw delta, GDD Formula F3 [TR-building-system-079]/
## [TR-building-system-080]).
##
## Owns exactly the "Planned -> UnderConstruction -> Built" per-cell
## progression [TR-building-system-068]/[TR-building-system-069] this
## story's own Control Manifest excerpt names, and nothing else:
##
## 1. **Job-claim seam** (AC43, [TR-building-system-068]): [method claim_job]
##    is the MOCKED on-site-job boundary this story's own Implementation
##    Notes name ("Test with a mocked on-site job... the villager claim/
##    path/arrival mechanic is Story 030"). A real caller (Story 030's
##    claim/report/on-site queue pipeline, [ConstructionJobQueue]) calls this
##    SAME method with a real claiming villager -- this class still treats
##    "claimed" and "on site" as the same fact for its OWN crediting loop
##    ([method _on_tick] has no villager-position concept and never will;
##    the real on-site/off-site distinction, [ConstructionJobQueue.is_on_site],
##    is wired by a future Villager AI story, not here). Story 030 (this
##    revision) DOES layer one refinement directly onto this seam without
##    changing [method claim_job]'s own shape: [method set_occupancy_predicate]
##    (see point 2b below) and [method release_job] (the symmetric un-claim
##    [method claim_job] never had a counterpart for).
## 2. **Tick-driven progress** (GDD Formula F3, [TR-building-system-079]):
##    [method _on_tick] -- this module's SOLE entry point that ever advances
##    any job -- credits every ACTIVE job exactly one tick per [signal
##    TimeTickSystem.tick] delivery. Warp-invariance and the burst rule (F3)
##    both fall out of [TimeTickSystem]'s OWN existing contract for free:
##    that Autoload's `_advance_ticks` already fires [signal
##    TimeTickSystem.tick] once per discrete drift-free tick boundary,
##    capped at `max_ticks_per_frame` (its own burst cap) and NEVER while
##    paused -- this class adds no second burst loop, no delta parameter,
##    and no warp read of any kind, so "tick count to complete is unchanged
##    by warp" and "at most `max_ticks_per_frame` ticks fire in one frame"
##    hold structurally, not via a second implementation of either rule.
## 2b. **Occupied-cell defer** (Story building-030, GDD Edge Case 6,
##    [TR-building-system-037]): [method set_occupancy_predicate] wires an
##    OPTIONAL `Callable(cell: Vector3i) -> bool` seam -- mirrors
##    [CommitPipeline]'s own established `set_furniture_support_predicate`
##    pattern exactly (an optional, default-invalid `Callable`, a future real
##    caller overrides it). Default `Callable()` (invalid) means "never
##    occupied" -- every pre-030 test/consumer's behavior is completely
##    unaffected. When wired, [method _on_tick] skips crediting any job whose
##    cell currently reads occupied THIS tick -- no `progress_ticks`
##    increment, the job stays exactly as UnderConstruction as it was, and
##    every OTHER active job in the SAME `_on_tick` dispatch still credits
##    normally (Edge Case 6: "that cell's progress is skipped... while all
##    other queued cells process normally" -- deferral is per-cell, never
##    per-command or global). The actual occupancy READ (a real character
##    standing on the target cell) is [ConstructionJobQueue]'s/Villager AI's
##    concern entirely -- this class only consults whatever boolean the
##    predicate returns, exactly as [CommitPipeline]'s furniture-support seam
##    never reasons about footprint geometry itself.
## 2c. **Seal-prevention negative-write gate** (Story villager-ai-016, GDD
##    Rule 16/F6, [TR-villager-ai-behavior-101]/102/106/107): [method
##    set_seal_prevention_predicate] wires a SECOND optional
##    `Callable(cell: Vector3i, villager_id: int, job_type: JobType) -> bool`
##    seam -- unlike [member _occupancy_predicate] (which only skips a
##    tick's progress accrual), this one is consulted exactly once, at the
##    moment a job would otherwise COMPLETE, and a `false` return means the
##    completion write never commits THIS dispatch at all (see [method
##    _on_tick]'s own doc comment). Default `Callable()` (invalid) means
##    "always allow" -- every pre-016 caller/test is unaffected.
##    [VillagerSealPreventionGate] is the real wirer, and is itself
##    responsible for releasing the claim back to [ConstructionJobQueue] on
##    refusal (this class still has zero [ConstructionJobQueue] awareness,
##    mirroring point 2b's own "this class has no concept of
##    ConstructionJobQueue" invariant exactly). [method claim_job]'s new
##    optional `job_type` parameter (default [constant JobType.BUILD]) is
##    the value the predicate receives back -- see [enum JobType]'s own doc
##    comment for why every job this codebase can currently originate is a
##    build job.
## 3. **Per-job independence, no rollover** (F3 burst rule, AC25/AC45,
##    [TR-building-system-080]): active jobs are tracked one per CELL, keyed
##    by that cell's address -- "N villagers complete at most N cells per
##    frame" and "excess ticks do NOT roll over to that villager's next
##    cell" both hold by construction: a completed job is removed from
##    [member _active_jobs] the instant it finishes, so any further tick
##    events in the SAME burst simply find nothing left to advance for that
##    cell, and a villager is never automatically re-assigned a new cell
##    within this class (claiming a new cell is Story 030's separate act).
## 4. **The Voxel World write + retirement** ([TR-building-system-057]):
##    completing a job means the cell's contents ([member
##    BlueprintCell.contents], a PLACEHOLDER pending Story 022's real
##    material-selection wiring -- see [BlueprintCell]'s own doc comment) get
##    written to Voxel World and [member BlueprintCell.state] transitions to
##    [constant BlueprintCell.MicroState.BUILT]. Story building-033 (point 5
##    below) changed HOW that write is issued -- see that paragraph for the
##    batched-write mechanics this point used to own entirely on its own.
## 5. **Batched completion write + self-write tag + Build Validation seam**
##    (Story building-033, [TR-building-system-072]/[TR-building-system-024]/
##    [TR-building-system-075]): [method _on_tick] no longer calls [method
##    VoxelWorldGrid.set_cell] once per completing job -- it collects EVERY
##    job that reaches its completion threshold in THIS SAME dispatch into
##    one `Dictionary[Vector3i, CellContents]` and issues exactly ONE
##    [method VoxelWorldGrid.bulk_write] call at the end via [method
##    _complete_jobs] (even for a single completion -- there is no "a batch
##    of one is still single-cell" special case; every completion, always,
##    goes through the SAME batched path), so [signal
##    VoxelWorldGrid.cells_changed_batch] fires AT MOST ONCE per tick
##    regardless of how many jobs completed, and [signal
##    VoxelWorldGrid.cell_changed] never fires for a completion anymore
##    (Villager AI's nav-graph patching, story villager-ai-008, already
##    subscribes to BOTH signals, so this is transparent to it). [member
##    write_tag] ([BuildingSystemWriteTag]) brackets that single [method
##    VoxelWorldGrid.bulk_write] call with `begin()`/`end()` -- Godot's
##    default synchronous signal delivery means [UndoRedoStack]'s own
##    undo-invalidation listener (a caller sharing the SAME
##    [BuildingSystemWriteTag] instance) observes `is_active() == true` for
##    the FULL duration of that call, recognizing every cell this dispatch
##    just wrote as self-originated and never invalidating an undo entry
##    over it (AC46). Every cell actually completed this dispatch (the SAME
##    set the batched write covers) is also collected into [signal
##    construction_completed] -- fired exactly once, AFTER the write, only
##    when at least one job completed (never a zero-cell emission) -- the
##    seam Build Validation (M02, not yet implemented) will consume to avoid
##    N region re-analyses for N parallel completions in one frame
##    ([TR-building-system-075]). Per-job state transition (to
##    [constant BlueprintCell.MicroState.BUILT]) and [member _active_jobs]
##    retirement still happen AFTER the batched write returns (mirroring the
##    exact ordering the single-cell path had before this story: the write's
##    own signal observes every completing cell still
##    [constant BlueprintCell.MicroState.UNDER_CONSTRUCTION], the state flips
##    only once the write has landed) -- no consumer of either signal has
##    ever been able to observe a completing cell's [BlueprintCell] already
##    flipped to BUILT mid-signal, before or after this story.
##
## **Explicitly out of scope** (this story's own Out of Scope section, and
## the neighbouring stories that own it):
## - Story 030 (this revision landed the two seams above -- point 2b's
##   occupancy predicate, [method release_job] -- but NOT the rest): the REAL
##   claim/report/on-site QUEUE itself (job aggregation across projects, the
##   Villager AI-facing `has_available_job()`/`release_claim()` contract,
##   one-job-per-villager bookkeeping, the on-site predicate definition, and
##   the unreachable-ghost signal/flag) lives in the separate
##   [ConstructionJobQueue] collaborator, not here. This class still does not
##   itself decide WHICH villager should claim WHICH cell, does not path
##   anyone anywhere, and still has no "on site" concept distinct from
##   "claimed" for its OWN crediting loop -- [ConstructionJobQueue] is the
##   seam that layers those concerns on top, calling [method claim_job]/
##   [method release_job]/[method set_occupancy_predicate] exactly as any
##   other caller would.
## - Story 009 (demolition / removal writes, LANDED this revision -- see the
##   dedicated "Story building-009" doc-comment block below): this story's
##   batching + self-write-tag mechanics (Story building-033, point 5 above)
##   turned out to be exactly generic enough to reuse verbatim for demolition
##   completions too -- the SAME [BuildingSystemWriteTag] instance and the
##   SAME batched-write discipline, never a second one.
## - Story 002/003: the persistent Build Project entity and its cell
##   registry/grouping -- this class has no concept of a project; it is
##   handed bare [BlueprintCell] references directly (mirrors
##   [CommitPipeline]'s own "Story 003 assigns project membership, not
##   here" precedent). Mutating [member BlueprintCell.state] here is
##   visible through any other holder of the SAME [RefCounted] reference
##   (e.g. [CommitPipeline]'s own tracking dictionary) by construction --
##   no second registry to keep in sync.
##
## **Story building-028 (this revision, ADR-0016 BV-1 ruling
## `production/architecture-decisions-m02-preflight-2026-07-26.md`): furniture
## never enters [VoxelWorldGrid].** Two changes, both scoped to [constant
## BlueprintCell.Category.FURNITURE] cells only -- every BLOCK-category
## behavior above is completely unchanged:
## 1. **Claim-time support gate** (Rule 8/[TR-building-system-050], AC49 --
##    "construction cannot start until the support cell is Built"): [method
##    claim_job] refuses (returns `false`, nothing mutated) a FURNITURE-category
##    claim whose cell directly below reads EMPTY in the raw grid right now.
##    This is a STRICTER check than [CommitPipeline]/[FurnitureTool]'s own
##    commit-time support predicate (which also accepts a not-yet-Built
##    blueprint floor cell, AC49's first half) -- by claim time, only an
##    actually-Built (grid-resident) support cell is good enough. No new
##    predicate seam: this class already holds [member voxel_world] and reads
##    it directly, mirroring [method _on_tick]'s own established "read the
##    grid directly, no extra collaborator" style.
## 2. **Completion routing** ([member furniture_registry], BV-1 §5): [method
##    _on_tick] excludes every FURNITURE-category completing cell from [param
##    changes] (the [method VoxelWorldGrid.bulk_write] payload) -- a
##    FURNITURE-category completion literally never reaches that call.
##    [method _complete_jobs] additionally skips the [method
##    VoxelWorldGrid.bulk_write] call ENTIRELY when [param changes] ends up
##    empty (an all-furniture completion batch), and routes each completing
##    FURNITURE cell to [member furniture_registry]'s own [method
##    FurnitureRegistry.place] instead. [signal construction_completed] still
##    names every completed cell regardless of category (BV-1: "construction_
##    completed still names the cell") -- only the GRID write is furniture-
##    exempt, not the job-completion bookkeeping/signal. [member
##    BlueprintCell.state] still flips to [constant
##    BlueprintCell.MicroState.BUILT] for a completed furniture cell exactly
##    like a block -- "Built" describes the JOB, not a grid record.
##
## **Story building-016 (this revision, GDD Core Rule 8/F5 multi-cell
## footprint, [TR-building-system-124]/[TR-building-system-127]) extends
## point 2 above**: a multi-cell furniture footprint's cells are still each
## their own independent job (claimed/credited/completed exactly like a
## block cell, Core Rule 12's per-cell parallelism unchanged), but [method
## _complete_jobs] now routes an ENTIRE footprint to [member
## furniture_registry] as exactly ONE [method FurnitureRegistry.place] call,
## consulting [member BlueprintCell.footprint_group] (`null` for a
## single-cell item -- routes immediately, pre-016 behavior unchanged) to
## discover every sibling cell and fire on whichever one completes LAST,
## regardless of claim/completion order or timing across ticks. See
## [FurnitureFootprintGroup]'s own doc comment for the full mechanism.
##
## **Story building-009 (this revision, ADR-0016 primary, GDD Rule 14j,
## [TR-building-system-114]/[TR-building-system-115]): demolition orders for
## BLOCK-category Built cells, mirroring Rule 12's construction job contract
## in reverse.** A demolition order is created ALREADY released -- no
## staging step, unlike a build project's Draft phase, since tearing
## something down needs no blueprint to reconsider ([method
## create_demolition_order] realizes this: it is both "the order exists" and
## "it is immediately job-eligible" in one call, collapsing what construction
## splits into [method BuildProject.release] + [method
## ConstructionJobQueue.claim_job]). [method claim_demolition_job] is the
## per-villager execution claim (mirrors [method claim_job]'s own shape and
## AC20's established mocked-claim test pattern, per this story's own
## Implementation Notes: "Test the tick loop with a mocked on-site claim").
## Three ways this deliberately mirrors construction's mechanics and one way
## it deliberately does NOT:
## 1. **No per-cell state transition on claim/progress.** [method
##    claim_job] flips [member BlueprintCell.state] PLANNED -> UNDER_
##    CONSTRUCTION because a not-yet-built cell needs a distinct "in
##    progress" state. A demolished cell has no such need: the GDD's own
##    "Built (terminal for the cell; not for the project)" States table row
##    says a Built cell's demolition "moves the PROJECT onward," never a
##    fifth [enum BlueprintCell.MicroState] value -- [member
##    BlueprintCell.is_demolition_queued] (a plain bookkeeping flag, mirrors
##    [member BlueprintCell.is_unreachable]'s own "annotation, not a state"
##    precedent) is the ONLY per-cell bookkeeping a demolition order adds;
##    [member BlueprintCell.state] stays [constant
##    BlueprintCell.MicroState.BUILT] for the order's entire lifetime.
## 2. **Same [_ActiveJob]/[method _on_tick] crediting loop, same batched
##    completion write, same [BuildingSystemWriteTag].** A demolition job is
##    tracked in the SAME [member _active_jobs] dictionary as a construction
##    job (keyed by cell -- never a collision, since a BUILT cell can never
##    ALSO be an active construction job, which always retires to BUILT
##    before this story's code path can ever see it) with [_ActiveJob.is_demolition]
##    `true` (set ONLY by [method claim_demolition_job], never [method
##    claim_job] -- deliberately NOT keyed off [enum JobType.DEMOLISH]/
##    [_ActiveJob.job_type], which is a SEPARATE, pre-existing seal-prevention
##    exemption tag [method claim_job] can also be passed explicitly, per
##    `villager-ai-016`'s own established test precedent -- see
##    [_ActiveJob.job_type]'s own doc comment for why conflating the two would
##    break that still-valid test). [method _on_tick] and [method
##    _complete_jobs] branch on [_ActiveJob.is_demolition] only where the two
##    mechanics genuinely differ (which per-category tick total applies; what
##    gets written; whether [member BlueprintCell.state] changes) -- occupancy
##    defer ([member _occupancy_predicate]) and seal-prevention ([member
##    _seal_prevention_predicate]) already applied uniformly to every
##    completing job regardless of kind before this story, and continue to
##    apply completely unchanged, still keyed off [_ActiveJob.job_type]
##    exactly as before (Rule 12's "same on-site rules" holds structurally,
##    not via a second implementation of either gate).
## 3. **The Voxel World clear, via the SAME batched [method
##    VoxelWorldGrid.bulk_write] call.** A completing DEMOLISH job's write
##    value is [member BlueprintCell.restore_value] if the cell carries one
##    (Rule 14l floor-excavation, Story 012's future capturing half -- this
##    story is the CONSUMING half) or [method CellContents.empty] otherwise
##    ("the Voxel World clear occurs and the cell is gone," [TR-building-system-115]).
##    Unlike a FURNITURE construction completion (which is EXCLUDED from
##    [param changes] entirely, see the "Story building-028" block above), a
##    BLOCK demolition completion is ALWAYS included -- there is no
##    "furniture never enters VoxelWorldGrid" carve-out on the demolition
##    side within this story's own scope, because this story implements
##    BLOCK-category demolition only ([method create_demolition_order]
##    refuses a [constant BlueprintCell.Category.FURNITURE] cell outright,
##    returning `false` -- Story 017 is the future caller that extends
##    demolition to furniture, reusing this SAME mechanism per that story's
##    own Implementation Notes: "furniture reuses the same execution
##    contract").
## 4. **Duplicate guard (Edge 17, [TR-building-system-114]).** [method
##    create_demolition_order] returns `false` (no-op, nothing mutated) if
##    [member BlueprintCell.is_demolition_queued] is already `true` --
##    "a second demolition request on an already-queued demolition cell is a
##    no-op... mirrors Core Rule 3's 'already holds a blueprint cell'
##    invalid-commit rule, applied to the demolition queue." [method
##    claim_demolition_job]'s OWN [member _active_jobs] double-claim guard
##    (shared with [method claim_job]) additionally prevents two villagers
##    from claiming the SAME already-queued order.
## 5. **[signal demolition_completed]** -- mirrors [signal
##    construction_completed] exactly (same batching guarantee: fired at
##    most once per [method _on_tick] dispatch, never for a zero-cell
##    dispatch, carrying every cell demolished in THIS SAME dispatch) but
##    kept as a SEPARATE, distinctly-named signal rather than folding
##    demolitions into [signal construction_completed] -- a demolished cell
##    is semantically the opposite event (a cell LEAVING a project, per
##    [method BuildProject.demolish_cell]) from a completed one, and this
##    class's own "no project concept" invariant (see the "Story 002/003"
##    Out-of-scope bullet above) means it cannot call that method itself;
##    this signal is the seam a FUTURE registry-aware caller (Story 010/015,
##    not yet wired -- mirrors every other not-yet-assembled seam in this
##    codebase) consumes to remove the cell from its owning [BuildProject]
##    and [BuildProjectRegistry]'s reverse index.
##
## **Story building-017 (this revision, ADR-0016 primary, GDD Rule 14j/16/17b,
## [TR-building-system-127]/[TR-building-system-064]): furniture demolition --
## job-gated and uniform with block demolition, reusing [method
## create_demolition_order]/[method claim_demolition_job] verbatim, atomic
## across a multi-cell footprint.** Four differences from the BLOCK path
## above, everything else identical:
## 1. **Category guard widened, not removed.** [method create_demolition_order]
##    now accepts [constant BlueprintCell.Category.FURNITURE] alongside
##    [constant BlueprintCell.Category.BLOCK] (previously refused outright --
##    see the "Story building-009" block above, point 3, which named THIS
##    story as the future caller). A [constant BlueprintCell.Category.FURNITURE]
##    cell whose [member BlueprintCell.footprint_group] is set additionally
##    sets [member BlueprintCell.is_demolition_queued] on EVERY sibling cell
##    of the group in the SAME call (Edge 17's duplicate guard is checked
##    across the WHOLE group first -- any sibling already queued refuses the
##    whole call, never queues "the other half" on top of an existing order)
##    -- "the order exists" now means "the whole entity's order exists,"
##    never a partial per-cell flag set.
## 2. **Atomic ONE job per entity, not per cell** ([TR-building-system-127]:
##    "demolishes atomically as ONE job -- never per-cell"). Unlike
##    construction (Story building-016 above), where a footprint's siblings
##    are each their OWN independent job and only the FINAL completion's
##    registry write is atomic, a furniture DEMOLITION job is tracked as
##    exactly ONE [_ActiveJob] under whichever cell [method
##    claim_demolition_job] was called with -- [member
##    FurnitureFootprintGroup.is_demolition_active] (Story 017 addition to
##    that class) is the group-level guard preventing a second, concurrent
##    claim against a DIFFERENT sibling cell of the SAME group (a per-cell
##    [member _active_jobs] key lookup alone cannot catch this, since only
##    ONE cell address is ever actually keyed for the whole entity).
## 3. **Never a [VoxelWorldGrid] write, on EITHER side of demolition.** Exactly
##    like a FURNITURE construction completion (see the "Story building-028"
##    block above), a completing FURNITURE demolition job is EXCLUDED from
##    [param changes] in [method _on_tick] -- furniture never entered the
##    grid when it was built, so there is nothing to clear when it is torn
##    down. Instead, [method _complete_jobs] routes the completion to
##    [member furniture_registry]'s own new [method FurnitureRegistry.remove]
##    call (resolved via [method FurnitureRegistry.get_occupant_at] against
##    whichever cell the job was claimed under -- every footprint cell shares
##    the SAME occupant id, so any one of them resolves the whole entity) --
##    the atomic counterpart to [method FurnitureRegistry.place]. Every cell
##    of the group (not just the claimed one) is cleared of [member
##    BlueprintCell.is_demolition_queued] and named in [signal
##    demolition_completed] -- mirroring [signal construction_completed]'s
##    own "names every cell regardless of category" precedent exactly (see
##    the "Story building-009" block above, point 5).
## 4. **Deferred revocation seam** (GDD Rule 17b, [TR-building-system-064]):
##    [member _furniture_demolished_callback] -- an OPTIONAL
##    `Callable(definition_id: StringName, cells: Array[Vector3i]) -> void`,
##    invoked exactly once per completed FURNITURE demolition, strictly AFTER
##    [method FurnitureRegistry.remove] -- mirrors [member
##    _occupancy_predicate]/[member _seal_prevention_predicate]'s own
##    "optional, default-invalid Callable seam" precedent exactly. This is
##    deliberately NOT a direct call into `FurnitureBedProvider`
##    (`src/villager_ai/`) -- this class stays Villager-AI-agnostic by
##    construction, mirroring every other seam in this file; a future caller
##    (or, today, a test standing in for one -- this codebase's established
##    "seam lands now, a later story assembles the real wiring" idiom) is
##    responsible for translating "this furniture item was demolished" into
##    `FurnitureBedProvider.furniture_revoked` if -- and only if -- it was
##    owned. The event structurally cannot fire before THIS method's own
##    completion write (GDD Rule 17b: "the event now fires on demolition-
##    order completion, not at order creation") -- there is no earlier call
##    site in this class that could invoke it.
##
## Injected-tier module (ADR-0001): [member voxel_world]/[member config] are
## wired via a scene file's Inspector in production (once a future
## scene-assembly story attaches this node), or assigned directly in a
## headless test. [member time_tick_system] is a plain, non-`@export`
## `Object` -- mirrors [VillagerAi]'s own established duck-typed
## `time_tick_system` precedent exactly (`@export`ing an Autoload is
## Forbidden, ADR-0001): production resolves it lazily against
## `/root/TimeTickSystem`; a headless test assigns a `tick`-signal-shaped
## test double directly before calling [method setup]. All
## wiring/validation lives in [method setup], never `_ready()`.
class_name ConstructionTickLoop
extends Node

## Story villager-ai-016 (GDD F6: `job_type` variable, `{build, dig,
## demolish}`) -- which seal-prevention exemption bucket a claimed job falls
## into. Defaults to [constant JobType.BUILD] everywhere [method claim_job]
## is called without an explicit value, so this default changes NO existing
## caller's behavior. [constant JobType.DEMOLISH] is now [method
## claim_demolition_job]'s own OWN job kind (Story building-009, landed this
## revision -- see that story's dedicated doc-comment block above) -- both
## [method VillagerSealPreventionGate]'s exemption check (`job_type != build`,
## Rule 16) and this class's own `_on_tick`/`_complete_jobs` branch on it now
## have a real caller passing it. [constant JobType.DIG] remains reserved for
## a future terrain dig-order queue (Story building-013/014, not yet landed)
## -- this class itself still assigns no special MEANING to any value beyond
## those two consumers' own comparisons.
enum JobType {
	BUILD,
	DIG,
	DEMOLISH,
}

## Injected-tier dependency (ADR-0001) -- the sole mutation path this class
## ever calls: [method VoxelWorldGrid.bulk_write], on job completion only
## (Story building-033 -- see class doc comment point 5).
@export var voxel_world: VoxelWorldGrid

## Tuning config dependency (ADR-0002) -- GDD Formula F3's
## `base_build_ticks[category]` knobs. Wired via a scene file's Inspector in
## production, or assigned directly in a headless test. Never read inside
## `_ready()` -- see [method setup].
@export var config: ConstructionTickLoopConfig

## Story building-033 addition (TR-building-system-024) -- the shared
## self-write exemption tag [method _complete_jobs]'s own batched completion
## write brackets with `begin()`/`end()`. Optional; default-constructed in
## [method setup] if left unwired (see [BuildingSystemWriteTag]'s own class
## doc comment for why a caller that wants [UndoRedoStack]'s
## undo-invalidation listener to recognize this class's writes as
## self-originated MUST wire the identical instance into both). Plain `var`,
## never `@export` -- `RefCounted` is not an exportable Inspector type
## (mirrors [member time_tick_system]/[VillagerAi]'s own `job_queue: Object`
## precedent: a code-assigned collaborator, not an Inspector-wired one).
var write_tag: BuildingSystemWriteTag = null

## Story building-028 addition (ADR-0016 BV-1 ruling) -- the sole destination
## a completing [constant BlueprintCell.Category.FURNITURE] job's placement
## record is routed to, INSTEAD OF [VoxelWorldGrid]. Plain `var`, never
## `@export` -- `RefCounted` is not an exportable Inspector type (mirrors
## [member write_tag]'s own precedent exactly). `null` is tolerated: a
## completing furniture job with no registry wired is silently dropped
## (never crashes, never falls back to writing the grid) -- production
## always wires a real [FurnitureRegistry] once a future scene-assembly
## story exists; no such assembly exists yet in this codebase.
var furniture_registry: FurnitureRegistry = null

## Story `building-034` addition (TD ruling D1/D3) -- the sole destination a
## completing [constant BlueprintCell.Category.SCAFFOLD] job's cell routes to,
## INSTEAD OF [VoxelWorldGrid], mirroring [member furniture_registry]'s own
## precedent exactly. `null` is tolerated identically (a completing scaffold
## job with no registry wired is silently dropped, never falls back to
## writing the grid).
var scaffold_registry: ScaffoldRegistry = null

## Story building-033 addition ([TR-building-system-075]) -- fires exactly
## once per [method _on_tick] dispatch that completes at least one job,
## carrying every cell completed in THIS SAME dispatch (never a zero-cell
## emission) -- the seam Build Validation (M02) will consume to avoid one
## region re-analysis per completing cell.
signal construction_completed(cells: Array[Vector3i])

## Story building-009 addition ([TR-building-system-115]) -- mirrors [signal
## construction_completed] exactly (fired at most once per [method _on_tick]
## dispatch, never for a zero-cell dispatch, carrying every cell demolished
## in THIS SAME dispatch) but kept distinct -- see the "Story building-009"
## class doc comment block, point 5, for why this is a separate signal
## rather than folded into [signal construction_completed].
signal demolition_completed(cells: Array[Vector3i])

## Time & Tick System dependency (ADR-0001 Autoload tier) -- see class doc
## comment. Duck-typed against the one member this class depends on:
## `signal tick()`.
var time_tick_system: Object = null

## One currently-active (claimed) job per cell -- see class doc comment
## point 3 for why per-cell keying alone gives AC25/AC45's independence and
## no-rollover guarantees for free. A cell absent from this dictionary is
## either not yet claimed (still [constant BlueprintCell.MicroState.PLANNED])
## or already retired ([constant BlueprintCell.MicroState.BUILT]) -- [method
## claim_job]/[method _complete_jobs] are the sole writer/eraser.
class _ActiveJob:
	## The claimed [BlueprintCell] itself -- this class mutates its [member
	## BlueprintCell.state] directly (a shared [RefCounted] reference, not a
	## copy) so the SAME object a caller still holds observes the
	## transition.
	var blueprint_cell: BlueprintCell

	## The claiming villager's id (Story building-005's future worker-
	## attribution rollup reads this indirectly once [method claim_job] is
	## wired to a real claim -- this story only stores it, never reports it
	## anywhere itself).
	var villager_id: int

	## Ticks credited toward [member blueprint_cell]'s
	## `required_ticks_for(...)` total so far.
	var progress_ticks: int = 0

	## See [enum JobType] (Story villager-ai-016). Defaults to
	## [constant JobType.BUILD] -- see that enum's own doc comment. **Purely
	## a seal-prevention exemption tag** (Rule 16/F6, forwarded verbatim to
	## [member _seal_prevention_predicate]) -- deliberately NOT what [method
	## _on_tick]/[method _complete_jobs] branch on to decide whether THIS job
	## is a real demolition (see [member is_demolition] below for that).
	## `villager-ai-016`'s own established test precedent claims a job
	## through [method claim_job] (the CONSTRUCTION path: PLANNED ->
	## UNDER_CONSTRUCTION -> BUILT) while passing [constant JobType.DEMOLISH]
	## purely to exercise the seal-prevention exemption bucket -- that job is
	## NOT a real demolition and must still flip to BUILT/write [member
	## BlueprintCell.contents] normally. Conflating the two (branching
	## `_on_tick`/`_complete_jobs` on [member job_type] directly) would break
	## that pre-existing, still-valid test.
	var job_type: ConstructionTickLoop.JobType = ConstructionTickLoop.JobType.BUILD

	## Story building-009 addition -- `true` ONLY for a job started via
	## [method claim_demolition_job] (never [method claim_job], regardless of
	## what [member job_type] it was passed). THIS is what [method _on_tick]/
	## [method _complete_jobs] branch on for demolition-specific mechanics
	## (required-tick knob, write value, state-flip skip, which completion
	## signal fires) -- see [member job_type]'s own doc comment for why that
	## field is the wrong thing to branch on instead.
	var is_demolition: bool = false

	func _init(
		p_blueprint_cell: BlueprintCell,
		p_villager_id: int,
		p_job_type: ConstructionTickLoop.JobType = ConstructionTickLoop.JobType.BUILD,
		p_is_demolition: bool = false
	) -> void:
		blueprint_cell = p_blueprint_cell
		villager_id = p_villager_id
		job_type = p_job_type
		is_demolition = p_is_demolition

## True once [method setup] has completed at least once.
var _is_set_up: bool = false

## See [_ActiveJob] doc comment above.
var _active_jobs: Dictionary[Vector3i, _ActiveJob] = {}

## Occupied-cell defer seam (Story building-030, class doc comment point 2b)
## -- `Callable(cell: Vector3i) -> bool`, `true` meaning "occupied this
## tick." Default `Callable()` (invalid) mirrors [CommitPipeline]'s own
## `_furniture_support_predicate` default exactly: "never occupied," a
## complete no-op for every pre-030 caller. Set via [method
## set_occupancy_predicate].
var _occupancy_predicate: Callable = Callable()

## Seal-prevention negative-write gate seam (Story villager-ai-016, GDD Rule
## 16/F6, ADR-0009 slice propagation Sec.2b) -- `Callable(cell: Vector3i,
## villager_id: int, job_type: JobType) -> bool`, `true` meaning "allow this
## completion write to commit" (the OPPOSITE polarity from [member
## _occupancy_predicate]: this seam mirrors the GDD's own `allow_write`
## naming directly, since -- unlike the occupancy seam, which only ever
## skips a tick's progress accrual -- refusing here means the completion
## itself never commits and the claim is released back to the queue, a
## materially different consequence worth a materially different polarity
## rather than reusing "true = block"). Default `Callable()` (invalid) means
## "always allow" -- every pre-016 caller/test is completely unaffected.
## [VillagerSealPreventionGate] is the real wirer (via [method
## ConstructionJobQueue.set_seal_prevention_predicate], mirroring [member
## _occupancy_predicate]'s own forwarding precedent exactly) -- when it
## refuses, IT is responsible for releasing the claim back to
## [ConstructionJobQueue] (via that class's own [method
## ConstructionJobQueue.release_claim], which this class has no visibility
## into at all, same as [member _occupancy_predicate]'s own "this class has
## no concept of ConstructionJobQueue" invariant) -- this class only skips
## finalizing the write for that job THIS dispatch; see [method _on_tick]'s
## own doc comment for why that reentrant release, mid-iteration, is safe.
var _seal_prevention_predicate: Callable = Callable()

## Story building-017 addition (GDD Rule 17b, [TR-building-system-064]) --
## optional `Callable(definition_id: StringName, cells: Array[Vector3i]) ->
## void` seam, invoked exactly once per completed FURNITURE demolition job,
## strictly AFTER [method FurnitureRegistry.remove] -- see class doc
## comment's "Story building-017" block, point 4, for why this stays
## Villager-AI-agnostic rather than calling `FurnitureBedProvider` directly.
## Default `Callable()` (invalid) is a silent no-op -- mirrors [member
## _occupancy_predicate]/[member _seal_prevention_predicate]'s own "invalid
## by default" precedent exactly.
var _furniture_demolished_callback: Callable = Callable()


## Explicitly callable wiring/validation entry point (ADR-0001). Asserts
## [member voxel_world] and a [member time_tick_system]-shaped dependency
## are wired, applies ADR-0002's clamp+warn `validate()` policy, then
## connects this module's tick dispatch to [signal TimeTickSystem.tick]
## (idempotent, mirroring [CommitPipeline]/[ToolStateMachine]'s own
## `is_connected` guard precedent).
func setup() -> void:
	assert(voxel_world != null, "ConstructionTickLoop.voxel_world not wired")
	assert(config != null, "ConstructionTickLoop.config not wired")
	for issue: String in config.validate():
		push_warning(issue)
	if time_tick_system == null:
		time_tick_system = get_node_or_null(^"/root/TimeTickSystem")
	assert(
		time_tick_system != null,
		"ConstructionTickLoop requires a TimeTickSystem-shaped dependency (assign a mock in"
		+ " tests; the real Autoload is registered project-wide) before setup() can"
		+ " connect tick dispatch"
	)
	@warning_ignore("unsafe_property_access")
	var tick_already_connected: bool = time_tick_system.tick.is_connected(_on_tick)
	if not tick_already_connected:
		@warning_ignore("unsafe_property_access")
		time_tick_system.tick.connect(_on_tick)
	if write_tag == null:
		write_tag = BuildingSystemWriteTag.new()
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## The job-claim seam (AC43, [TR-building-system-068]) -- see class doc
## comment point 1. Transitions [param blueprint_cell] from
## [constant BlueprintCell.MicroState.PLANNED] to
## [constant BlueprintCell.MicroState.UNDER_CONSTRUCTION] and begins
## crediting it ticks via [method _on_tick]. Returns `false` (no-op) if
## [param blueprint_cell] is not currently Planned, or if its cell address
## already has an active job (double-claim guard) -- either way nothing is
## mutated.
func claim_job(
	blueprint_cell: BlueprintCell,
	villager_id: int,
	job_type: JobType = JobType.BUILD
) -> bool:
	assert(is_set_up(), "ConstructionTickLoop.claim_job called before setup()")
	if blueprint_cell.state != BlueprintCell.MicroState.PLANNED:
		return false
	if _active_jobs.has(blueprint_cell.cell):
		return false
	# Story building-028 (Rule 8/TR-050, AC49) -- a FURNITURE-category cell
	# cannot begin construction until its support cell (directly below) is
	# actually Built in the raw grid right now. See class doc comment's
	# "Story building-028" point 1 for why this is a stricter, direct grid
	# read rather than a new predicate seam. An out-of-bounds support cell
	# (e.g. a furniture cell placed at the world floor, y = min_y) is never
	# solid -- [method VoxelWorldGrid.get_cell] itself returns `null` (not an
	# empty [CellContents]) for an out-of-bounds address, so bounds must be
	# checked FIRST to avoid a null-call crash.
	if blueprint_cell.category == BlueprintCell.Category.FURNITURE:
		var support_cell: Vector3i = blueprint_cell.cell + Vector3i(0, -1, 0)
		if not voxel_world.is_in_bounds(support_cell) or voxel_world.get_cell(support_cell).is_empty():
			return false
	blueprint_cell.state = BlueprintCell.MicroState.UNDER_CONSTRUCTION
	_active_jobs[blueprint_cell.cell] = _ActiveJob.new(blueprint_cell, villager_id, job_type)
	return true


## Symmetric un-claim to [method claim_job] (Story building-030, GDD Rule 3 /
## [TR-building-system-054]'s "a villager finishes or abandons its current
## job before claiming another" -- the release half of that contract, which
## [ConstructionTickLoop] never had a counterpart for before this story).
## Transitions [param cell]'s active job's [member BlueprintCell.state] back
## to [constant BlueprintCell.MicroState.PLANNED] and erases it from [member
## _active_jobs] -- any [member _ActiveJob.progress_ticks] already banked is
## discarded with it (this codebase carries no partial-progress-preservation
## concept anywhere; an abandoned-then-reclaimed job restarts from zero,
## mirroring [method claim_job]'s own fresh-[_ActiveJob] construction).
## Returns `false` (no-op, nothing mutated) if [param cell] has no active
## job. [ConstructionJobQueue] is this method's real caller (graceful
## abandon / claim-released-on-abandon, GDD Rule 3/Edge Case 4) -- this class
## itself never decides WHEN to release, only performs the mechanical
## un-claim once asked.
func release_job(cell: Vector3i) -> bool:
	if not _active_jobs.has(cell):
		return false
	var job: _ActiveJob = _active_jobs[cell]
	job.blueprint_cell.state = BlueprintCell.MicroState.PLANNED
	_active_jobs.erase(cell)
	return true


## Whether [param cell] currently has an active (claimed, not yet completed)
## construction job.
func is_job_active(cell: Vector3i) -> bool:
	return _active_jobs.has(cell)


## Creates a demolition order for [param blueprint_cell] (Story building-009,
## AC65, GDD Rule 14j, [TR-building-system-114]) -- see the "Story
## building-009" class doc comment block above for the full mechanism.
## Requires [param blueprint_cell] to be currently [constant
## BlueprintCell.MicroState.BUILT] (a not-yet-Built cell is canceled via
## [BuildProject.cancel_cell]/Story 015's Draft-eraser branch, never
## demolished) and [constant BlueprintCell.Category.BLOCK] (Story 017 is the
## future caller that extends this to [constant
## BlueprintCell.Category.FURNITURE]). Returns `false` (no-op, nothing
## mutated) if either of those does not hold, or if [param blueprint_cell]
## already has a demolition order queued (Edge 17's duplicate guard --
## [member BlueprintCell.is_demolition_queued] already `true`). On success,
## sets that flag -- the order is immediately job-eligible, no separate
## release step ("already released" per AC65) -- and [param blueprint_cell]'s
## own [member BlueprintCell.state] is left completely untouched (stays
## BUILT; the cell is NOT cleared yet, per AC65's own wording).
func create_demolition_order(blueprint_cell: BlueprintCell) -> bool:
	if blueprint_cell.state != BlueprintCell.MicroState.BUILT:
		return false
	if (
		blueprint_cell.category != BlueprintCell.Category.BLOCK
		and blueprint_cell.category != BlueprintCell.Category.FURNITURE
		and blueprint_cell.category != BlueprintCell.Category.SCAFFOLD
	):
		return false
	if blueprint_cell.is_demolition_queued:
		return false
	# Story building-017 (Rule 16/[TR-building-system-127], class doc
	# comment's "Story building-017" block point 1) -- a multi-cell furniture
	# footprint's order covers the WHOLE entity atomically: Edge 17's
	# duplicate guard is checked across every sibling BEFORE any flag is set
	# (a partially-already-queued group refuses the whole call, never queues
	# "the other half" on top of an existing order), then every sibling is
	# flagged in the SAME call.
	var group: FurnitureFootprintGroup = blueprint_cell.footprint_group
	if group != null:
		for sibling: BlueprintCell in group.cells:
			if sibling.is_demolition_queued:
				return false
		for sibling: BlueprintCell in group.cells:
			sibling.is_demolition_queued = true
		return true
	blueprint_cell.is_demolition_queued = true
	return true


## The demolition job-claim seam (AC66, mirrors [method claim_job]'s own
## shape and AC20's established mocked-claim test pattern -- see the "Story
## building-009" class doc comment block above). Requires [param
## blueprint_cell] to already carry a demolition order ([member
## BlueprintCell.is_demolition_queued], via [method create_demolition_order])
## and its cell address to have no other active job (mirrors [method
## claim_job]'s own double-claim guard, reusing the SAME [member
## _active_jobs] dictionary -- a collision is structurally impossible here,
## since a BUILT cell can never simultaneously be an active CONSTRUCTION
## job). Returns `false` (no-op) otherwise. On success, begins crediting
## [param blueprint_cell] ticks via [method _on_tick] with [enum
## JobType.DEMOLISH] -- [member BlueprintCell.state] is NOT transitioned (see
## class doc comment point 1: demolition adds no per-cell state, only the
## [member BlueprintCell.is_demolition_queued] bookkeeping flag already set).
func claim_demolition_job(blueprint_cell: BlueprintCell, villager_id: int) -> bool:
	assert(is_set_up(), "ConstructionTickLoop.claim_demolition_job called before setup()")
	if not blueprint_cell.is_demolition_queued:
		return false
	if _active_jobs.has(blueprint_cell.cell):
		return false
	# Story building-017 (Rule 16/[TR-building-system-127], class doc
	# comment's "Story building-017" block point 2) -- a multi-cell
	# footprint's demolition is ONE job for the whole entity: the group-level
	# [member FurnitureFootprintGroup.is_demolition_active] flag catches a
	# second claim attempt against a DIFFERENT sibling cell of the SAME
	# group, which the per-cell [member _active_jobs] key alone cannot see
	# (only the cell passed to THIS call is ever keyed).
	var group: FurnitureFootprintGroup = blueprint_cell.footprint_group
	if group != null and blueprint_cell.category == BlueprintCell.Category.FURNITURE:
		if group.is_demolition_active:
			return false
		group.is_demolition_active = true
	_active_jobs[blueprint_cell.cell] = _ActiveJob.new(blueprint_cell, villager_id, JobType.DEMOLISH, true)
	return true


## Wires the occupied-cell defer seam (Story building-030, class doc comment
## point 2b) -- [ConstructionJobQueue]'s real caller, or a test's mocked
## occupied-state stand-in, supplies `Callable(cell: Vector3i) -> bool`.
## Passing an invalid [Callable] (the default, or an explicit `Callable()`)
## restores the pre-030 "never occupied" behavior.
func set_occupancy_predicate(predicate: Callable) -> void:
	_occupancy_predicate = predicate


## Wires the seal-prevention negative-write gate seam (Story villager-ai-016,
## class doc comment/[member _seal_prevention_predicate]'s own doc comment)
## -- [VillagerSealPreventionGate]'s real caller, or a test's mocked
## allow/refuse stand-in, supplies `Callable(cell: Vector3i, villager_id:
## int, job_type: JobType) -> bool`. Passing an invalid [Callable] (the
## default, or an explicit `Callable()`) restores the pre-016 "always allow"
## behavior.
func set_seal_prevention_predicate(predicate: Callable) -> void:
	_seal_prevention_predicate = predicate


## Wires the furniture-demolition notification seam (Story building-017,
## [member _furniture_demolished_callback]'s own doc comment) -- a future
## Villager-AI-side bridge (or a test standing in for one) supplies
## `Callable(definition_id: StringName, cells: Array[Vector3i]) -> void`.
## Passing an invalid [Callable] (the default, or an explicit `Callable()`)
## restores the "no notification" no-op behavior.
func set_furniture_demolished_callback(callback: Callable) -> void:
	_furniture_demolished_callback = callback


## Ticks credited so far toward [param cell]'s active job, or `0` if it has
## none (never claimed, or already retired) -- read-only observability
## (e.g. a future UI progress-fill consumer, TR-building-system-069).
func get_progress_ticks(cell: Vector3i) -> int:
	if not _active_jobs.has(cell):
		return 0
	return _active_jobs[cell].progress_ticks


## GDD Formula F3's `cell_build_ticks = base_build_ticks[category]` -- pure
## and stateless, exercisable directly with an arbitrary [param
## ticks_config], mirroring this codebase's established testable-pure-
## function precedent ([method PlacementPick.is_drag], [method
## PlacementPick.derive_attach_cell]).
static func required_ticks_for(category: BlueprintCell.Category, ticks_config: ConstructionTickLoopConfig) -> int:
	match category:
		BlueprintCell.Category.FURNITURE:
			return ticks_config.base_build_ticks_furniture
		BlueprintCell.Category.SCAFFOLD:
			return ticks_config.base_build_ticks_scaffold
		_:
			return ticks_config.base_build_ticks_block


## GDD Formula F3 addendum's `cell_demolition_ticks = base_demolition_ticks
## [category]` (Story building-009, [TR-building-system-114]/115) -- mirrors
## [method required_ticks_for]'s own pure/static/testable shape exactly.
static func required_demolition_ticks_for(
	category: BlueprintCell.Category, ticks_config: ConstructionTickLoopConfig
) -> int:
	match category:
		BlueprintCell.Category.FURNITURE:
			return ticks_config.base_demolition_ticks_furniture
		BlueprintCell.Category.SCAFFOLD:
			return ticks_config.base_demolition_ticks_scaffold
		_:
			return ticks_config.base_demolition_ticks_block


## [signal TimeTickSystem.tick] handler -- see class doc comment point 2 for
## why no burst loop/delta/warp handling belongs here. Credits every
## currently-active job exactly one tick. Iterates a SNAPSHOT of [member
## _active_jobs]'s keys (never the live [Dictionary] itself) since a
## completing job is retired from it only AFTER [method _complete_jobs]'s own
## batched write below (Story building-033, class doc comment point 5).
## Story building-030 (class doc comment point 2b): a job whose cell is
## currently occupied per [member _occupancy_predicate] is skipped entirely
## THIS dispatch -- no progress increment, no completion check -- while every
## other active job in the SAME snapshot still credits normally. Every job
## that reaches its `required_ticks_for(...)` total THIS dispatch consults
## [member _seal_prevention_predicate] (Story villager-ai-016) EXACTLY once,
## at the moment it would otherwise complete: a `false` return (refused)
## skips this job for THIS dispatch entirely -- no entry in [param changes]/
## [param completed_jobs], so [method _complete_jobs] never writes it and
## [signal construction_completed] never names it. The predicate itself is
## responsible for releasing the claim back to [ConstructionJobQueue] when it
## refuses (see [member _seal_prevention_predicate]'s own doc comment) -- that
## release synchronously erases this SAME cell's entry from [member
## _active_jobs] via [method release_job], which is safe here because this
## loop iterates a SNAPSHOT of [member _active_jobs]'s keys (see this
## method's own doc comment above), never the live [Dictionary] itself; the
## local `job` reference already held below stays valid regardless. Every
## job that reaches threshold and is NOT refused is collected (never written
## individually) and handed to [method _complete_jobs] once the credit pass
## is done.
##
## Story building-009 addition -- a job with [member _ActiveJob.is_demolition]
## `true` (started via [method claim_demolition_job] -- see that member's own
## doc comment for why this is NOT the same thing as [member
## _ActiveJob.job_type] `== ` [constant JobType.DEMOLISH]) is credited
## against [method required_demolition_ticks_for] instead of [method
## required_ticks_for]; the occupancy/seal-prevention predicates above are
## consulted identically regardless (Rule 12's "same on-site rules," no
## second implementation) -- [member _ActiveJob.job_type] is still forwarded
## to [member _seal_prevention_predicate] completely unchanged. On threshold,
## a completing real-demolition job's write value is [member
## BlueprintCell.restore_value] if set (Rule 14l floor-excavation) or
## [method CellContents.empty] otherwise ("the Voxel World clear occurs and
## the cell is gone") -- ALWAYS included in [param changes] (unlike a
## FURNITURE construction completion's grid-write exclusion just below; this
## story implements BLOCK-category demolition only, so this branch never
## sees a FURNITURE cell -- see [method create_demolition_order]'s own
## category guard).
func _on_tick() -> void:
	var changes: Dictionary[Vector3i, CellContents] = {}
	var completed_jobs: Array[_ActiveJob] = []
	for cell: Vector3i in _active_jobs.keys():
		if _occupancy_predicate.is_valid() and bool(_occupancy_predicate.call(cell)):
			continue
		var job: _ActiveJob = _active_jobs[cell]
		job.progress_ticks += 1
		var required_ticks: int
		if job.is_demolition:
			required_ticks = ConstructionTickLoop.required_demolition_ticks_for(job.blueprint_cell.category, config)
		else:
			required_ticks = ConstructionTickLoop.required_ticks_for(job.blueprint_cell.category, config)
		if job.progress_ticks >= required_ticks:
			if _seal_prevention_predicate.is_valid():
				var allow_write: bool = bool(
					_seal_prevention_predicate.call(cell, job.villager_id, job.job_type)
				)
				if not allow_write:
					continue
			if job.is_demolition:
				# Story building-017 (BV-1 ruling extended to removal, class
				# doc comment's "Story building-017" block point 3) -- a
				# FURNITURE-category demolition NEVER touches VoxelWorldGrid,
				# exactly like a furniture construction completion: furniture
				# was never written into the grid in the first place, so
				# there is nothing to clear. Routed to [member
				# furniture_registry] instead, in [method _complete_jobs].
				if (
					job.blueprint_cell.category != BlueprintCell.Category.FURNITURE
					and job.blueprint_cell.category != BlueprintCell.Category.SCAFFOLD
				):
					# Story building-009 (Rule 14j/14l, TR-115) -- always
					# included for a BLOCK cell: the restore_value snapshot
					# if this was a floor-excavation entry, otherwise an
					# explicit empty cell ("the clear occurs"). Story
					# building-034: SCAFFOLD is excluded identically to
					# FURNITURE -- never touched the grid, nothing to clear
					# (routed to [member scaffold_registry] instead).
					changes[cell] = (
						job.blueprint_cell.restore_value
						if job.blueprint_cell.restore_value != null
						else CellContents.empty()
					)
			# Story building-028 (ADR-0016 BV-1 ruling) -- a FURNITURE-category
			# construction completion is EXCLUDED from the bulk_write payload
			# entirely; it is routed to [member furniture_registry] instead, in
			# [method _complete_jobs]. Story building-034: SCAFFOLD is excluded
			# identically (D1: never voxel data). Every other category is
			# unaffected.
			elif (
				job.blueprint_cell.category != BlueprintCell.Category.FURNITURE
				and job.blueprint_cell.category != BlueprintCell.Category.SCAFFOLD
			):
				changes[cell] = job.blueprint_cell.contents
			completed_jobs.append(job)
	_complete_jobs(changes, completed_jobs)


## Completes every job in [param completed_jobs] (Story building-033, class
## doc comment point 5) -- issues [param changes] as exactly ONE [method
## VoxelWorldGrid.bulk_write] call (never one [method VoxelWorldGrid.set_cell]
## per job, and never conditionally -- a single completion goes through this
## SAME path), bracketed by [member write_tag]'s self-write exemption tag,
## then transitions every completed [BlueprintCell] to [constant
## BlueprintCell.MicroState.BUILT] and retires it from [member _active_jobs]
## -- AFTER the write, matching this class's pre-033 ordering (the write's
## own signal always observed a completing cell still UnderConstruction).
## Fires [signal construction_completed] with every completed CONSTRUCTION
## cell and [signal demolition_completed] with every completed DEMOLITION
## cell (Story building-009), each only when its own set is non-empty -- a
## dispatch with nothing to complete of a given kind emits neither signal,
## matching [method VoxelWorldGrid.bulk_write]'s own "nothing changed,
## nothing emitted" contract.
func _complete_jobs(changes: Dictionary[Vector3i, CellContents], completed_jobs: Array[_ActiveJob]) -> void:
	if completed_jobs.is_empty():
		return
	# Story building-028: an all-furniture completion batch resolves
	# [param changes] to empty -- [method VoxelWorldGrid.bulk_write] is not
	# even CALLED in that case (not just "called with nothing to write"),
	# matching BV-1's "never bulk_writes to the grid" literally rather than
	# only in effect.
	if not changes.is_empty():
		write_tag.begin()
		voxel_world.bulk_write(changes)
		write_tag.end()
	# First pass: retire every completing job from [member _active_jobs].
	# A CONSTRUCTION job additionally flips to BUILT before any furniture-
	# footprint completeness check runs below (Story building-016) -- a
	# multi-cell footprint's siblings can complete in the SAME dispatch, so
	# checking group completeness must see every sibling's freshly-flipped
	# state, never a stale UNDER_CONSTRUCTION read that would depend on
	# [param completed_jobs]' iteration order. A DEMOLISH job (Story
	# building-009) does NOT flip state (see class doc comment point 1 --
	# it stays BUILT for its entire lifetime) and instead clears [member
	# BlueprintCell.is_demolition_queued], the order's own fulfillment.
	var completed_construction_cells: Array[Vector3i] = []
	var completed_demolition_cells: Array[Vector3i] = []
	for job: _ActiveJob in completed_jobs:
		_active_jobs.erase(job.blueprint_cell.cell)
		if job.is_demolition:
			# Story building-017 (Rule 16/[TR-building-system-127]) -- a
			# multi-cell furniture footprint clears EVERY sibling together,
			# atomically, never just the one cell the job happened to be
			# keyed under (class doc comment's "Story building-017" block,
			# point 2/3).
			var group: FurnitureFootprintGroup = job.blueprint_cell.footprint_group
			if group != null and job.blueprint_cell.category == BlueprintCell.Category.FURNITURE:
				group.is_demolition_active = false
				for sibling: BlueprintCell in group.cells:
					sibling.is_demolition_queued = false
					completed_demolition_cells.append(sibling.cell)
			else:
				job.blueprint_cell.is_demolition_queued = false
				completed_demolition_cells.append(job.blueprint_cell.cell)
		else:
			job.blueprint_cell.state = BlueprintCell.MicroState.BUILT
			completed_construction_cells.append(job.blueprint_cell.cell)
	# Second pass: route furniture completions. A single-cell item
	# ([member BlueprintCell.footprint_group] `null`) routes immediately --
	# Story building-028's exact pre-016 behavior, unchanged. A multi-cell
	# footprint (Story building-016) routes exactly ONCE, on whichever
	# sibling happens to be the LAST to reach BUILT (order-independent by
	# construction -- see [FurnitureFootprintGroup]'s own doc comment);
	# [member FurnitureFootprintGroup.is_registered] guards against a double
	# [method FurnitureRegistry.place] call when two or more siblings
	# complete in this SAME dispatch. A DEMOLISH job is never routed here --
	# this story implements BLOCK-category demolition only (Story 017 is
	# furniture demolition's own future extension).
	for job: _ActiveJob in completed_jobs:
		if (
			job.is_demolition
			or job.blueprint_cell.category != BlueprintCell.Category.FURNITURE
			or furniture_registry == null
		):
			continue
		# Story building-028 (ADR-0016 BV-1 ruling) -- route a completing
		# FURNITURE cell to the furniture registry INSTEAD OF the grid (see
		# class doc comment's "Story building-028" point 2). A `null`
		# registry is skipped above -- it never falls back to writing the
		# grid.
		var group: FurnitureFootprintGroup = job.blueprint_cell.footprint_group
		if group == null:
			furniture_registry.place(job.blueprint_cell.furniture_definition_id, [job.blueprint_cell.cell])
			continue
		if group.is_registered:
			continue
		var all_siblings_built: bool = true
		for sibling: BlueprintCell in group.cells:
			if sibling.state != BlueprintCell.MicroState.BUILT:
				all_siblings_built = false
				break
		if not all_siblings_built:
			continue
		group.is_registered = true
		var footprint_cells: Array[Vector3i] = []
		for sibling: BlueprintCell in group.cells:
			footprint_cells.append(sibling.cell)
		furniture_registry.place(job.blueprint_cell.furniture_definition_id, footprint_cells)
	# Third pass (Story building-017): route furniture DEMOLITION
	# completions to [member furniture_registry]'s own [method
	# FurnitureRegistry.remove] -- the atomic counterpart to [method
	# FurnitureRegistry.place] above. A multi-cell footprint's demolition is
	# already ONE job (see class doc comment's "Story building-017" block,
	# point 2), so this never needs an [member
	# FurnitureFootprintGroup.is_registered]-style dedup guard the way
	# construction's per-cell-independent jobs do -- [param completed_jobs]
	# contains at most one entry for the whole entity.
	for job: _ActiveJob in completed_jobs:
		if not job.is_demolition or job.blueprint_cell.category != BlueprintCell.Category.FURNITURE:
			continue
		if furniture_registry == null:
			continue
		var definition_id: StringName = job.blueprint_cell.furniture_definition_id
		var footprint_cells: Array[Vector3i] = []
		var group: FurnitureFootprintGroup = job.blueprint_cell.footprint_group
		if group != null:
			for sibling: BlueprintCell in group.cells:
				footprint_cells.append(sibling.cell)
		else:
			footprint_cells.append(job.blueprint_cell.cell)
		var item_id: String = furniture_registry.get_occupant_at(job.blueprint_cell.cell)
		if item_id != "":
			furniture_registry.remove(item_id)
		# Story building-017 (GDD Rule 17b, [TR-building-system-064]) -- the
		# deferred revocation seam fires HERE, strictly after the registry
		# removal above, never earlier (see class doc comment's "Story
		# building-017" block, point 4).
		if _furniture_demolished_callback.is_valid():
			_furniture_demolished_callback.call(definition_id, footprint_cells)
	# Story `building-034` (TD ruling D1/D3) -- route SCAFFOLD construction
	# completions to [member scaffold_registry] INSTEAD OF the grid.
	for job: _ActiveJob in completed_jobs:
		if (
			job.is_demolition
			or job.blueprint_cell.category != BlueprintCell.Category.SCAFFOLD
			or scaffold_registry == null
		):
			continue
		scaffold_registry.add(job.blueprint_cell.cell)
	# Story `building-034` -- route SCAFFOLD demolition completions to
	# [member scaffold_registry]'s own [method ScaffoldRegistry.remove].
	# SC-INV-1 (ADR-0007 §1b) is enforced by [ScaffoldDismantlePlanner] at
	# ORDER-of-demolition time, before this class ever completes the job.
	for job: _ActiveJob in completed_jobs:
		if not job.is_demolition or job.blueprint_cell.category != BlueprintCell.Category.SCAFFOLD:
			continue
		if scaffold_registry == null:
			continue
		scaffold_registry.remove(job.blueprint_cell.cell)
	if not completed_construction_cells.is_empty():
		construction_completed.emit(completed_construction_cells)
	if not completed_demolition_cells.is_empty():
		demolition_completed.emit(completed_demolition_cells)
