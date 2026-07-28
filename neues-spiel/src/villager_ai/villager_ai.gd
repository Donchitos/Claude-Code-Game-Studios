## Villager AI injected-tier module scaffold (Story villager-ai-001, ADR-0001
## primary, ADR-0008 secondary for the FSM state set).
##
## Owns exactly two things at this story's scope: the [enum State] six-state
## agent machine (Deciding/Traveling/Working/Sleeping/Breather/Wandering,
## ADR-0008 Decision §1) and the tick-driven `match` dispatch skeleton that
## will carry each state's real behaviour in later stories -- every branch
## body is an empty stub here (`_tick_deciding`/`_tick_traveling`/
## `_tick_working`/`_tick_sleeping`/`_tick_breather`/`_tick_wandering`), per
## this story's explicit Out of Scope: walkability (story 002), the Deciding
## scheduler queue/budget (story 005), and the priority decision logic
## (story 006) are NOT implemented here.
##
## Injected-tier module (ADR-0001): [member config] and [member voxel_world]
## are wired via a scene file's Inspector in production, or assigned
## directly in a headless test; all wiring/validation lives in [method setup],
## never `_ready()`. [member time_tick_system] is the one deliberate
## exception to "typed `@export`" -- see that field's own doc comment for why
## it mirrors [GameWorld]'s existing `resource_item_database` duck-typed
## pattern instead.
##
## Dispatch is driven EXCLUSIVELY by [member time_tick_system]'s `tick`
## signal (ADR-0008 Decision §2, Control Manifest Feature Layer: "tick-driven
## via Time & Tick's signal, never raw delta") -- FSM state mutation itself
## never happens from any raw-delta engine callback (the same
## structural-guarantee style `CameraInput`'s raw-delta contract already
## established for this codebase). **Amended by story villager-ai-004**: this
## class now defines exactly ONE narrow, deliberate exception -- [method
## _process] -- added for ADR-0009's cosmetic-only visual-position recompute;
## it never reads its own raw `_delta` parameter (named with the conventional
## unused-parameter underscore prefix) and never touches [member current_cell]
## or any FSM state, so the tick-signal-only dispatch guarantee above is
## completely unaffected. This class still defines no `_physics_process`
## override anywhere.
##
## Story villager-ai-002 (previous revision) adds the two shared walkability
## predicates ADR-0007 Decision §1 assigns to Villager AI as its public API:
## [method is_standable] and [method is_step_legal]. Both are pure queries
## against [member voxel_world]'s cell data plus two registered design
## constants ([constant VILLAGER_CLEARANCE], [constant MAX_STEP_HEIGHT]) --
## no mutation, no cached state, no duplicated copy anywhere else (Control
## Manifest Feature Layer Forbidden: "never duplicate walkability rules or
## constants"). Every future consumer -- this class's own AStar3D pathfinder
## (story 007), Build Validation's independent BFS, and the Unstuck
## Watchdog's rescue-target search (story 014) -- calls these same two
## functions; none of them may re-derive an equivalent rule locally.
##
## Story villager-ai-003 (this revision) names the **body-column** concept
## explicitly (GDD Rule 8a/[TR-villager-ai-behavior-098], ADR-0009 slice
## propagation, Control Manifest Core Layer: "Occupancy is a body-column, not
## a single cell") and adds it as a second pure-function public API:
## [method body_column] derives the villager's own 3-cell vertical space
## (2-cell body + 1 buffer headroom cell) from a single discrete
## `current_cell`, and [method is_cell_in_body_column] is the occupancy
## predicate against it. Both reuse [constant VILLAGER_CLEARANCE] unchanged
## -- no second constant, per this story's explicit scope -- and are
## interpolation-free by construction (they take a `Vector3i`, never a
## villager instance or its `_visual_position`). Future consumers -- the
## Unstuck Watchdog's rescue/trigger checks (stories 014/015) and
## seal-prevention/walled-in detection (story 016) -- derive/query the
## column through these two functions rather than re-deriving an equivalent
## span locally.
##
## Story villager-ai-004 (this revision) implements ADR-0009's two-layer
## deterministic position model: the discrete, tick-boundary-quantized
## [member current_cell] -- the sole authoritative occupancy value, exposed
## via [method get_current_cell] -- versus the continuous, cosmetic-only
## [member _visual_position] (recomputed every [method _process] frame,
## never read by any logic query anywhere). [method advance_travel_progress]
## is the pure, directly-testable movement-update function (this story's
## AC20/[TR-villager-ai-behavior-093]) that advances
## [member _intra_tick_progress]; [method _on_tick] performs the ONE
## sanctioned tick-boundary mutation of [member current_cell] this story
## owns (the OTHER sanctioned mutation -- a watchdog rescue -- is story
## 015's, out of scope here). Driving [member _from_cell]/[member _to_cell]
## to new values as a villager actually paths somewhere -- path selection,
## re-pathing, and calling [method advance_travel_progress] every frame with
## a live `game_delta` -- is story 009's Traveling-state-machine scope,
## explicitly NOT implemented here.
##
## Story villager-ai-005 (this revision) lands ADR-0008's Deciding-pass
## staggering: a per-tick budget (`max_deciding_per_tick`) plus a
## stable-order FIFO queue, so a mass-Deciding event cannot let every
## eligible villager run an expensive F2 selection pass in the same tick.
## Because stories 001-004 already fixed this codebase's shape as ONE
## [VillagerAi] instance PER villager (no manager coordinating them --
## [method get_current_cell]'s own doc comment), the cross-villager
## queue+budget bookkeeping ADR-0008 describes is factored into a separate,
## dependency-free collaborator, [VillagerDecidingScheduler] (see its own
## class doc comment for the full architecture rationale), rather than being
## duplicated onto every instance's own tick handler -- which would have let
## an N-villager population drain up to N queue entries per GLOBAL tick
## instead of `max_deciding_per_tick`. [member scheduler] is an
## explicitly-injected shared dependency (like [member voxel_world]/
## [member time_tick_system], NOT a static/class-level singleton -- that
## would be hidden shared state surviving across independent test runs).
## [method request_deciding_pass] is the ONE generic eligibility-enqueue
## entry point every trigger source calls (this story wires the initial
## Deciding-eligible-at-boot case and the periodic `decision_interval`
## re-check via [method _check_decision_interval_trigger]; future stories --
## need-urgent, job-complete -- call the SAME method from their own trigger
## points, no second enqueue path is ever introduced). [method _tick_state]'s
## `State.DECIDING` branch now gates the (still-stub) [method _tick_deciding]
## call behind [method VillagerDecidingScheduler.is_runnable_this_tick] --
## the actual priority-list logic inside a Deciding pass remains story 006's
## scope, untouched here.
##
## Story villager-ai-006 (this revision) implements that priority-list logic
## (GDD Rule 2, ADR-0008 Decision §1's "strict, discrete priority order
## (Urgent need > Work > Idle/Wander)"): [method _tick_deciding] is no longer
## a stub. Two duck-typed, nil-safe, mocked-boundary dependencies --
## [member needs_provider] (tier 1) and [member job_queue] (tier 2) -- mirror
## [member time_tick_system]'s pattern exactly, since neither the Needs &
## Mood System nor the Building System's real job queue exist anywhere in
## this codebase yet (both are named MOCKED boundaries in this story's own
## Engine Notes/Implementation Notes). [enum PursuedActivity] and
## [member _pursued_activity] track WHICH tier a villager is currently
## committed to, independent of [member _state] -- the thing claim-stickiness
## (AC41/[TR-villager-ai-behavior-052]) and Edge Case 3b's same-need no-op
## actually key off, since [member _state] alone changes again once Stories
## 009/012/018 add real Traveling->Working/Sleeping sub-transitions while
## still pursuing the SAME committed tier. [method _on_tick]'s new
## `was_deciding` guard is what lets a villager already mid-activity
## (Working, Wandering, ...) get preempted by this same priority check on a
## periodic `decision_interval` re-check WITHOUT double-invoking
## [method _tick_deciding] for a villager that started the tick already in
## `State.DECIDING` ([method _tick_state]'s own pre-existing gate, story 005,
## already handles that case) -- see that method's own doc comment for the
## full ordering rationale (GDD Rule 3's graceful preemption: the CURRENT
## tick's activity body always runs first, only then does a runnable
## Deciding pass reassign [member _state]).
##
## Story villager-ai-007 (this revision) does NOT add an AStar3D member to
## this class, despite ADR-0007's Key Interfaces snippet showing an
## `_astar: AStar3D` field inline in its pseudocode. That ADR's own
## Performance Implications section is explicit that memory holds "ONE
## AStar3D instance" for the whole settlement-core region -- one per
## [VillagerAi] instance (this codebase's established one-instance-per-
## villager shape, see [method get_current_cell]'s own doc comment) would
## duplicate tens of thousands of points N times over, for a population of up
## to 30. This story instead adds [VillagerNavGraph] as a separate shared
## collaborator class -- the SAME "separate shared object, not a per-instance
## member" architecture [VillagerDecidingScheduler] already established for
## the identical reason (see that class's own doc comment). [VillagerNavGraph]
## reuses this class's own [method is_standable]/[method is_step_legal] as
## its predicate source (ADR-0007 Decision Section 1's "every consumer calls
## these same two functions"); this story's only other change here is
## extracting [method classify_step_length_cells] as a reusable static twin
## of [method _current_step_length_cells] (see that method's own doc
## comment). Wiring a shared [VillagerNavGraph] instance into this class's
## own Traveling state is story 009's scope, untouched here.
##
## Story villager-ai-008 (this revision) implements GDD Rule 10b's re-path
## FILTER ([TR-villager-ai-behavior-012]/036): [method setup] connects this
## villager directly to [member voxel_world]'s [signal
## VoxelWorldGrid.cell_changed]/[signal VoxelWorldGrid.cells_changed_batch]
## (Godot's default, synchronous, NEVER `CONNECT_DEFERRED` flags -- the same
## race-closure reliance [VillagerNavGraph]'s own story-008 subscription
## documents). [method evaluate_repath_trigger] is the filter itself,
## delegating the actual clearance-envelope-intersection decision to the
## stateless [VillagerRepathFilter] library; [method
## get_remaining_movement_cells] supplies "the remaining movement's cells"
## for THIS story's scope as exactly the current single travel step
## ([member _from_cell], [member _to_cell]) -- the only movement this class
## tracks today (a full multi-cell remaining-PATH is story 009's Traveling
## state-machine addition; this story's filter is written generically enough
## that a future richer path representation only needs to widen [method
## get_remaining_movement_cells]'s return, not [VillagerRepathFilter] itself
## or [method evaluate_repath_trigger]'s call site). [method is_moving]
## reports "moving" purely from the discrete `_from_cell != _to_cell`
## comparison -- deliberately NOT keyed to [member _state] naming Traveling/
## Wandering/Breather explicitly, so the SAME check already covers every one
## of the GDD's 4 named moving cases (Traveling, a Wandering step, a
## Breather step-away, or a future F4 vacate step) without this class ever
## needing to enumerate them. A stationary villager (Deciding/Working/
## Sleeping, or a Breather not yet stepping -- `_from_cell == _to_cell`,
## true from construction and after every arrival-crediting [method
## _on_tick] assignment) always reports not-moving, so [signal
## repath_evaluation_requested] can never fire for it -- matching the rule's
## own "for any MOVING villager" scope. This story implements the FILTER
## decision only -- the actual re-path/redirect story 009 wires to this
## signal is explicitly out of this story's scope.
##
## Story villager-ai-009 (this revision) implements the Traveling state
## machine itself (GDD "States and Transitions": "Follows the computed path
## cell-by-cell; re-paths if a Voxel World write blocks the path"). [method
## start_traveling] is the generic entry point a future story's own
## target-selection logic calls (Story 010's F2 job site, Story 018's bed
## cell) -- it acquires a path from [member nav_graph] (a new shared
## [VillagerNavGraph] dependency, mirroring [member scheduler]'s own
## "population-wide, non-`@export`, not setup()-asserted" precedent exactly
## -- earlier stories' tests never wire it and this story does not widen
## [method setup]'s boot-gate assertion retroactively) from
## [member current_cell] toward a caller-supplied `target_cell`, storing the
## FULL REMAINING path ([member _travel_remaining_path]), not merely the
## current single step -- exactly the widening this story's own predecessor
## doc comment (above) already reserved: [method get_remaining_movement_cells]
## now returns the whole upcoming route, so [VillagerRepathFilter]'s
## clearance envelope (unchanged, zero lines touched) now also covers writes
## further down the path, not only the in-flight step.
##
## [method _tick_traveling] performs the tick-boundary-only step advance
## ("request next step at tick boundaries") -- called from [method
## _tick_state] AFTER [method _on_tick]'s own arrival-crediting assignment
## already ran this tick, so [member current_cell] already reflects a
## just-completed step by the time it runs: it pops the just-arrived cell
## off [member _travel_remaining_path] and either begins the next step or
## completes arrival ([method _complete_travel_arrival], transitioning to
## the caller-supplied `arrival_state` -- Working/Sleeping/etc, real
## per-state behaviour still owned by stories 012/018).
##
## [signal repath_evaluation_requested] (story 008's own FILTER signal) is
## now consumed INTERNALLY, connected in [method setup] with default
## synchronous flags: [method _on_repath_evaluation_requested] recomputes a
## path from [member current_cell] toward the SAME [member
## _travel_target_cell] -- the actual REDIRECT this story's race-closure AC
## requires, landing in the SAME synchronous call stack as the write that
## triggered it, before the next [method _process] frame could ever advance
## [member _visual_position] further toward now-solid geometry. An empty
## recompute result (no viable detour) fires [method _abandon_travel] (this
## story's AC19 -- "exits to Deciding and re-selects... never keeps
## traveling toward a dead target"), dispatched by [member _pursued_activity]
## per GDD Edge Case 1's per-target fallback: `WORK` releases the held claim
## via the already-existing [method _release_job_claim]; `NEED`'s
## ground-sleep fallback and `NONE`'s wander-reselection are Story 018/019's
## own scope (neither system exists in this codebase yet) -- this story's
## safe default for both is simply "abandon and re-decide."
##
## **Wiring-order requirement** (load-bearing, not incidental): whoever
## assembles a population must call [method
## VillagerNavGraph.subscribe_to_voxel_world] BEFORE this villager's own
## [method setup] -- Godot fires synchronous signal connections in
## CONNECTION order (Control Manifest Global Rules), so the shared graph
## must patch a blocking write before this villager's own repath recompute
## reads it, or the recompute would run against a stale graph that still
## thinks the just-blocked cell is standable.
##
## [method _process] now ALSO drives [member _intra_tick_progress] forward
## every frame -- story villager-ai-004's own explicitly-deferred wiring
## ("calling advance_travel_progress every frame with a live game_delta is
## story 009's... responsibility") -- by querying [member time_tick_system]'s
## OWN `get_game_delta()` (a value that system already computed this frame;
## never this function's own raw `_delta` parameter, still unread) whenever
## [method is_moving] is true. Guarded by `time_tick_system != null` so
## every earlier story's own position-model unit tests (which call [method
## _process] directly without ever wiring [member time_tick_system]) keep
## passing unchanged.
##
## Story villager-ai-012 (this revision) implements [method _tick_working]
## itself -- the CLOSED job loop (GDD Rule 5/[TR-villager-ai-behavior-054],
## Edge Case 4/[TR-villager-ai-behavior-083]): "work progress accrues only
## while on site," and "a job revoked mid-work stops at the tick boundary,
## no failure reaction, re-enters Deciding." This class owns NO
## progress-crediting mechanism of its own -- that stays [ConstructionTickLoop]'s
## job, per its own doc comment -- the on-site GATE on that crediting is
## wired for real, against actual villager positions, by the new
## [VillagerOnSiteGate] collaborator (composing Rule 5's on-site predicate
## with Building System Edge Case 6/AC40b's occupied-cell defer behind the
## SAME `set_occupancy_predicate` seam both landed classes already reserved
## for this exact story). [method _tick_working] itself is purely
## OBSERVATIONAL: it reads [member _claimed_blueprint_cell]'s CURRENT
## [member BlueprintCell.state] -- the SAME shared reference
## [ConstructionTickLoop] mutates directly -- to detect completion (BUILT,
## AC40) or revocation (anything but UNDER_CONSTRUCTION/BUILT, AC33) without
## a second query back into [member job_queue]. [member
## _claimed_blueprint_cell] is set the moment a claim succeeds ([method
## _attempt_claim_and_travel_to_job], BEFORE travel even starts -- the
## on-site gate must already exist for the full travel period too, since
## [method ConstructionTickLoop.claim_job] flips a cell to
## UNDER_CONSTRUCTION immediately at claim time) and cleared by [method
## _release_job_claim] (the ONE existing helper every claim-relinquishing
## path -- need-preemption, pathing failure, and this story's own
## completion/revocation handling -- already funnels through, so it never
## goes stale).
##
## Story villager-ai-015 (this revision) implements the Unstuck Watchdog's
## TRIGGER, rescue teleport, and F3 telemetry (GDD Rule 15/15b/F5,
## [TR-villager-ai-behavior-099]/[TR-villager-ai-behavior-104]/
## [TR-villager-ai-behavior-080], ADR-0009 slice propagation's "second
## sanctioned discrete `current_cell` mutation"). [method
## _update_unstuck_watchdog] runs every tick (called from [method _on_tick]
## right after arrival-crediting, before [method _tick_state] dispatches) and
## implements GDD F5's `stuck_tick_count` formula via [method
## _is_stuck_at_current_cell] -- itself delegating to the ALREADY-shared
## [method is_standable]/[method is_step_legal] predicates plus
## [VillagerNavGraph]'s own established [constant
## VillagerNavGraph.HORIZONTAL_FULL_OFFSETS]/[constant
## VillagerNavGraph.VERTICAL_STEP_OFFSETS] neighbor-candidate constants
## (Story villager-ai-008's patch-pass reuses the identical pair -- this
## story does not invent a second, locally-derived neighbor set). Scoped
## STRICTLY to `State.TRAVELING`/`State.WORKING` -- every other state
## ([member _distressed] is still updated for observability, this story's
## AC32/Edge Case 2 complement) never accumulates [member stuck_tick_count]
## and is never rescued.
##
## On reaching [member VillagerAIConfig.unstuck_watchdog_threshold_ticks],
## [method _attempt_watchdog_rescue] calls the F5 BFS
## ([VillagerRescueTargetSearch.find_rescue_target], Story villager-ai-014) --
## a miss (search exhausted at `unstuck_rescue_max_radius`) reports through
## [member _search_failure_gate] (a per-villager [RescueSearchFailureGate]
## instance, Story villager-ai-014's own once-per-episode gate primitive;
## THIS story owns calling it and firing the actual [signal
## unstuck_search_failed]) and defers to the next tick, retrying every tick
## thereafter (GDD Edge Case 14) since [member stuck_tick_count] keeps
## incrementing past the threshold with nothing to reset it. A hit performs
## the rescue itself ([method _perform_watchdog_rescue]): releases any held
## job claim via the SAME [method _release_job_claim] helper every other
## claim-relinquishing path already funnels through (AC52 -- "no
## double-release, no orphaned claim"; a `NEED`-pursuing villager, e.g.
## traveling to a bed, holds no claim, so this is a no-op with zero bed-
## ownership side effect, exactly AC52's second half), sets [member
## current_cell] atomically AND snaps [member _visual_position] to match (NO
## lerp -- ADR-0009's "the watchdog is the one deliberate exception" to
## "never snap/teleport"), resets [member stuck_tick_count] to `0` and
## [member _search_failure_gate] for a fresh future episode, increments both
## [member _unstuck_count] (this villager's own F3 counter) and the shared
## [member unstuck_telemetry]'s world total (Story villager-ai-015's own new
## shared, population-wide, non-`@export`, nil-safe collaborator --
## [VillagerUnstuckTelemetry] -- mirrors [member scheduler]/[member
## nav_graph]'s own "one shared instance, not a duplicated-per-villager
## copy" precedent), emits [signal unstuck_rescued], transitions to
## `State.DECIDING`, and re-enters the Deciding queue via the SAME [method
## request_deciding_pass] -> [VillagerDecidingScheduler.enqueue] path every
## OTHER Deciding-eligibility trigger uses -- deliberately NOT a bonus
## immediate decide bypassing [member scheduler]'s budget (this story's own
## QA-defined "no double-decide" assertion): because [member scheduler]'s own
## per-tick budget drain ([method VillagerDecidingScheduler.advance_tick],
## wired via [method connect_to_tick_source] during [method setup]) always
## fires BEFORE any villager's own [signal TimeTickSystem.tick] handler in
## the SAME global tick (connection order, story villager-ai-005's own
## established ordering), a rescue's own [method request_deciding_pass] call
## can only ever land a villager in the FIFO queue for a tick whose budget
## was already computed -- it is never granted an extra, unbudgeted slot the
## same tick it fires, and [method VillagerDecidingScheduler.enqueue]'s own
## idempotency guard means a villager already queued at rescue time (e.g.
## from an earlier `decision_interval` trigger) is never double-enqueued.
##
## [member population] is a new duck-typed, nil-safe, mocked-boundary
## dependency (mirrors [member needs_provider]/[member job_queue]'s own
## established precedent exactly -- a real population registry is a future
## spawner story's job, same as those two systems) exposing exactly one
## member, `func get_other_villager_cells(villager_id: int) ->
## Array[Vector3i]`, supplying [VillagerRescueTargetSearch.find_rescue_target]'s
## own `other_villager_cells` parameter (that function's own doc comment:
## "the watchdog's responsibility to assemble... never queries a
## population/registry itself").
##
## Story villager-ai-019 (this revision) implements [method _tick_wandering]
## itself -- GDD F3 (wander-target selection) / Rule 7c (idle micro-behaviors)
## -- no longer a stub. The actual flood-fill/micro-behavior algorithms live
## on the new stateless [VillagerWanderSelector] library (see its own doc
## comment for the full reachability/determinism rationale); this class owns
## only the CADENCE ([member _ticks_since_last_wander_pick], counting up to
## [member VillagerAIConfig.wander_interval] independently of [member
## _ticks_since_last_decision] -- mirrors [VillagerAi]'s own Breather-beat
## doc note that a life-texture beat "runs on a dedicated ticks-since-entry
## counter, independent of `decision_interval`") and WIRES the result: a
## `WALK`/`BED_DRIFT` pick calls the SAME [method start_traveling] every
## other target-selection story already uses (arrival state `WANDERING`),
## reusing its whole existing abandon/redirect machinery for free -- a
## voxel-world write that strands a wander walk mid-route falls through
## [method _abandon_travel]'s pre-existing `PursuedActivity.NONE` branch
## ("abandon and re-decide," unchanged since story villager-ai-009), which
## already satisfies GDD Edge Case 1's own "for a wander target — pick a new
## one" wording with zero new code. A `PAUSE_LOOK`/`SIT` pick, or a `WALK`/
## `BED_DRIFT` pick whose own target resolves to [member current_cell]
## itself (this story's AC31/Edge Case 8 -- a flood-fill returning only the
## current cell), is a deliberate no-op: the villager stays in `State.
## WANDERING`, [member _tick_wandering] simply re-fires the next time its own
## counter reaches `wander_interval` -- never an error, never a forced state
## change.
##
## **Determinism, no live RNG, no wall-clock** (this sprint's own QA-plan
## grep guard for this story: "no wall-clock dependency
## (`OS.get_ticks_msec`/`Time.get_ticks_msec` absent from any decision
## path)"): [member wander_rng] is a per-villager [RandomNumberGenerator],
## mirroring [member nav_graph]'s own "DI'd, nil-safe, assigned externally
## before first use, never `setup()`-asserted" precedent -- but unlike a
## mocked-boundary mocked default, an unwired villager's [method
## _get_wander_rng] lazily self-constructs one seeded from [member
## villager_id] itself, NEVER `randomize()` (which pulls OS-clock entropy)
## and never any other wall-clock-derived value. This is a deliberate
## narrowing of the GDD/ADR-0008's own "production uses the live RNG" wording
## (this story's own interpretation): every draw this class ever makes is a
## pure function of already-deterministic state (`villager_id`, the fixed
## sequence of prior draws), so an identical world replayed identically
## always reproduces an identical wander history end to end -- satisfying
## this story's AC30 ("wandering runs twice from the same state produce
## identical paths") for BOTH a test's own explicitly-injected generator
## (assigned to [member wander_rng] before first use, exactly like [member
## nav_graph]'s own wiring-order convention) and an untouched production
## villager alike, with no separate code path between the two. Different
## villagers still draw independently-varied sequences (different
## `villager_id` seeds), so the population does not read as one synchronized
## clock.
##
## Story villager-ai-013 (this revision) implements F4's nudge-aside target
## selection and the actual vacate REQUEST/step [VillagerOnSiteGate]'s own
## doc comment reserved for this story (GDD Rule 7 / F4,
## [TR-villager-ai-behavior-056]/[TR-villager-ai-behavior-079]/
## [TR-villager-ai-behavior-034]): [method request_vacate] is the entry point
## [VillagerOnSiteGate]'s own occupancy predicate now calls whenever it finds
## an occupied builder target cell (see that class's own doc comment update),
## delegating the actual target algorithm to the new stateless
## [VillagerNudgeAsideSelector] (mirrors [VillagerWanderSelector]'s own
## "separate stateless algorithm library" precedent exactly). Eligible ONLY
## while `State.WANDERING` -- this FSM has no separate "Idle" state (the
## GDD's own States table names Wandering's Entry as "Decided Idle"), so "an
## idle or wandering occupant" (Rule 7) maps 1:1 onto that one state; every
## other state (`WORKING`/`SLEEPING` -- Rule 7's own explicit "mid-activity...
## NOT interrupted"; `BREATHER` -- a deliberate, settled rest beat, not "idle
## standing"; `TRAVELING` -- already mid-step toward its own destination; and
## `DECIDING` -- instantaneous, same-tick) is a no-op, deferring exactly as
## [VillagerOnSiteGate]'s own occupancy predicate already does independently
## (this story's own interpretation, the narrowest reading that satisfies
## AC34/AC42's explicit Idle-vacates-vs-Working/Sleeping-deferred contrast).
## Reuses [method start_traveling] wholesale (arrival state `WANDERING`, the
## SAME "resume Wandering after this walk" pattern [method
## _perform_wander_pick]'s own WALK/BED_DRIFT picks already establish) -- a
## repeated request while already mid-vacate-step finds `_state != WANDERING`
## and is a harmless no-op, no re-selection, no redundant travel restart.
class_name VillagerAi
extends Node

## Fires when [method evaluate_repath_trigger] determines a Voxel World
## write's changed cell(s) intersect this (currently moving) villager's
## remaining-movement clearance envelope (GDD Rule 10b, this story's AC18).
## Carries no arguments -- WHICH write and WHAT to do about it are story
## 009's concern; this story's own contract is purely "did the filter fire,
## and exactly how many times" (AC18/AC49's call-count assertions).
signal repath_evaluation_requested()

## Fires when the Unstuck Watchdog rescues this villager (Story
## villager-ai-015, GDD Rule 15/F5, AC51) -- carries the chosen rescue cell
## for observability/telemetry consumers (e.g. a future F3 debug overlay).
## Fired AFTER every rescue side effect below has already been applied
## ([member current_cell]/[member _visual_position] snapped, claim released,
## [member _state] transitioned to `State.DECIDING`) -- a listener never
## observes a half-applied rescue.
signal unstuck_rescued(rescue_cell: Vector3i)

## Fires when the watchdog's rescue search is exhausted at
## `unstuck_rescue_max_radius` with no eligible cell found (GDD Edge Case 14,
## AC53) -- gated by [member _search_failure_gate] to fire exactly once per
## stuck episode, never once per tick (the search itself keeps retrying every
## tick, per that Edge Case's own wording).
signal unstuck_search_failed()

## The six-state agent machine (GDD "States and Transitions" table; ADR-0008
## Decision §1 Architecture Diagram). Exactly these six and no others
## [TR-villager-ai-behavior-... state table]. Per-villager state is driven by
## `match` on [method _tick_state], never a behavior tree or utility-scored
## alternative (ADR-0008 Alternatives B/C, rejected).
enum State {
	DECIDING,
	TRAVELING,
	WORKING,
	SLEEPING,
	BREATHER,
	WANDERING,
}

## Which GDD Rule 2 priority-list tier this villager is currently COMMITTED
## to pursuing (Story villager-ai-006) -- independent of [member _state],
## and the value [method _tick_deciding]'s claim-stickiness (AC41) and Edge
## Case 3b's same-need no-op actually key off of. [member _state] alone
## moves TRAVELING -> WORKING (Story 012) or TRAVELING -> SLEEPING (Story
## 018) while still pursuing the SAME tier the whole time, so this value is
## what stays constant across that sub-transition.
enum PursuedActivity {
	NONE,  ## Pursuing neither a need nor a job (Wandering/idle, Rule 2 tier 3).
	NEED,  ## Committed to satisfying the current urgent need (tier 1).
	WORK,  ## Committed to (holding a claim on) a construction job (tier 2).
}

## Vertical clearance a standable cell requires -- re-exported alias (Story
## villager-ai-026, TD ruling BV-4): the literal `3` now lives EXACTLY ONCE,
## on [constant VillagerWalkabilityRules.VILLAGER_CLEARANCE]; this constant
## resolves to that value at parse time (a `const` initialised from another
## class's `const` costs nothing at runtime) so every existing call site --
## including [VillagerNavGraph]'s `VillagerAi.VILLAGER_CLEARANCE` read --
## compiles and behaves unchanged. See that constant's own doc comment for
## the full GDD/TR rationale.
const VILLAGER_CLEARANCE: int = VillagerWalkabilityRules.VILLAGER_CLEARANCE

## Maximum legal height difference between two adjacent standable cells --
## re-exported alias (Story villager-ai-026, TD ruling BV-4); the literal `1`
## now lives EXACTLY ONCE, on
## [constant VillagerWalkabilityRules.MAX_STEP_HEIGHT]. See that constant's
## own doc comment for the full GDD/TR rationale.
const MAX_STEP_HEIGHT: int = VillagerWalkabilityRules.MAX_STEP_HEIGHT

## Tuning config dependency (ADR-0002). Wired via a scene file's Inspector in
## production, or assigned directly in a headless test. Never read inside
## `_ready()` -- see [method setup]. No gameplay value is ever hardcoded in
## this module -- every tunable is read from this config once later stories
## give the state bodies real behaviour [TR-villager-ai-behavior-090].
@export var config: VillagerAIConfig

## Voxel World dependency (ADR-0001), typed `@export` since [VoxelWorldGrid]
## is itself an injected-tier module (not an Autoload) -- wired via a scene
## file's Inspector in production, or assigned directly in a headless test.
## Unused by this story's stub state bodies (walkability reads are story
## 002's scope); asserted as wired in [method setup] regardless, since every
## later story's `_tick_traveling`/`_tick_working`/etc. body will need it and
## the DI wiring point belongs on this scaffold from day one, not
## re-threaded per story.
@export var voxel_world: VoxelWorldGrid

## Time & Tick System dependency (ADR-0001 Autoload tier). Deliberately a
## plain, non-`@export` `Object` -- `@export`ing an Autoload into any module
## is Forbidden (ADR-0001) -- mirroring [GameWorld]'s existing
## `resource_item_database` duck-typed field exactly: production leaves this
## `null` and [method setup] resolves it lazily against
## `/root/TimeTickSystem` (the real Autoload, registered project-wide); a
## headless test assigns a `tick`-signal-shaped test double directly before
## calling [method setup], with zero scene tree and zero manual Autoload
## registration of its own. Duck-typed against two members this class
## depends on: `signal tick()` and, since story villager-ai-009,
## `func get_game_delta() -> float` ([method _process]'s live
## travel-progress wiring).
var time_tick_system: Object = null

## Deciding-pass scheduler dependency (Story villager-ai-005, ADR-0008
## Decision §2) -- the ONE shared, cross-villager FIFO-queue-and-budget
## collaborator every [VillagerAi] instance in the same population must
## point at the SAME object. Unlike [member config]/[member voxel_world]
## (typed `@export` Resource/Node references), [VillagerDecidingScheduler] is
## a plain [RefCounted] with no Inspector-editable representation --
## deliberately NOT `@export`ed, mirroring [member time_tick_system]'s own
## duck-typed, code-assigned precedent. Assigned directly by whichever code
## assembles the villager population (a headless test, or a future spawner
## story) BEFORE calling [method setup] -- asserted non-null there, exactly
## like [member config]/[member voxel_world]. This is NOT a manager: see
## [VillagerDecidingScheduler]'s own class doc comment for why sharing this
## one object across instances does not reintroduce a manager architecture.
var scheduler: VillagerDecidingScheduler = null

## Needs & Mood dependency (Story villager-ai-006, mocked boundary -- this
## story's own Engine Notes: "Needs & Mood values are mocked at the
## need-is-urgent boundary"). The Needs & Mood System is an MVP-sibling GDD
## not yet implemented anywhere in this codebase; its own future epic owns
## real production wiring. Duck-typed like [member time_tick_system] --
## exposes exactly one member this class depends on:
## `func has_urgent_need(villager_id: int) -> bool`. Deliberately nil-safe
## (see [method _has_urgent_need]) rather than asserted in [method setup]:
## a not-yet-wired villager always reads "no urgent need," never crashes --
## unlike [member time_tick_system], this dependency has no boot-gate this
## story enforces.
var needs_provider: Object = null

## Building System construction-job-queue dependency (Story villager-ai-006,
## mocked boundary -- Story 010 owns real F2 nearest-reachable selection,
## Story 011 owns real atomic claim/attribution; this story needs only the
## "available construction job" boolean gate the GDD Implementation Notes
## assign priority-list tier 2: "available construction job (queue
## non-empty)"). Duck-typed, nil-safe default (see [method
## _has_available_job]/[method _release_job_claim]) -- exposes exactly two
## members: `func has_available_job() -> bool` and
## `func release_claim(villager_id: int) -> void` (called only on graceful
## preemption, GDD Rule 3/[TR-villager-ai-behavior-050] -- never when
## nothing was actually claimed). This story models "holds a claim" purely
## as [member _pursued_activity] == `PursuedActivity.WORK`; Story 011
## introduces the real claim record this stands in for.
var job_queue: Object = null

## Story villager-ai-016 (this revision) adds the Seal Prevention trap
## predicate (GDD Rule 16/F6, ADR-0009 slice propagation Sec.2b): [method
## would_trap_builder] answers "would completing a write at this cell leave
## THIS villager with zero legal steps," evaluated as if the write had
## already committed, WITHOUT ever mutating [member voxel_world] (a real
## trial write would fire real signals for a change that might never
## commit). This class has no awareness of the Building System's write
## path, abandon-count bookkeeping, or the dig/demolition exemption at all --
## those live entirely in the new [VillagerSealPreventionGate] collaborator
## (mirrors [VillagerOnSiteGate]'s own "separate shared collaborator wired
## behind [ConstructionTickLoop]'s own predicate seam" architecture exactly),
## which calls this method once per registered villager per completing cell.

## Population dependency (Story villager-ai-015, mocked boundary -- see this
## class's own doc comment's villager-ai-015 paragraph). Duck-typed, nil-safe
## default (see [method _get_other_villager_cells]) -- exposes exactly one
## member: `func get_other_villager_cells(villager_id: int) ->
## Array[Vector3i]`, the caller-supplied occupancy snapshot
## [VillagerRescueTargetSearch.find_rescue_target] needs to reject an
## already-occupied rescue candidate. A villager with this left `null` (no
## population registry wired) simply searches as though no other villager
## exists -- a safe, conservative default, never a crash.
var population: Object = null

## Bed/furniture dependency (Story villager-ai-018, mocked boundary --
## Engine Notes: "Bed removal uses the Building System's furniture-revocation
## event (symmetric to job revocation)"; `building-028`/`016` land the real
## furniture registry CONCURRENTLY in a different lane, so this story
## consumes it exclusively through this duck-typed, nil-safe seam, mirroring
## [member job_queue]'s own established precedent exactly). Exposes four
## members: `func get_unowned_bed_cells() -> Array[Vector3i]` (mirrors
## [method ConstructionJobQueue.get_available_jobs]'s own "current claimable
## snapshot" contract), `func claim_bed(bed_cell: Vector3i, villager_id: int)
## -> bool` (the SAME atomic-claim PATTERN [method _claim_job] already
## established -- Story villager-ai-011's own Implementation Notes: "reuse
## the same atomic-claim primitive for bed ownership contention" -- this
## class calls it and tries the next candidate on a loss, exactly like job
## claiming; the ATOMICITY guarantee itself is the provider's own
## responsibility), `func is_bed_sheltered(bed_cell: Vector3i) -> bool` (the
## bed_sheltered/bed_unsheltered source-enum split, GDD Core Rule
## 4/[TR-villager-ai-behavior-071] -- fed by Build Validation's shelter
## classification on the real provider, story needs-mood-010's own future
## wiring concern, not this one), and `signal furniture_revoked(villager_id:
## int, furniture_cell: Vector3i)` (targeted per-owner per
## `docs/architecture/architecture.md`'s signal table -- every connected
## villager receives it and self-filters by [member villager_id], see
## [method _on_furniture_revoked]). Deliberately NOT [method setup]-asserted
## (mirrors [member nav_graph]/[member job_queue]'s own "nil-safe, not a
## boot-gate dependency" precedent) -- a villager with this left `null`
## never claims a bed and always falls back to ground sleep, never crashes.
var bed_provider: Object = null

## Needs & Mood need-id this story reports against (GDD Core Rule 2: "MVP
## fills only sleep"; `docs/architecture/architecture.md`'s
## `start_recovery(villager_id, need: StringName, ...)` boundary treats need
## ids as opaque wire-format strings, ADR-0006's "cross-system references are
## opaque ids only" precedent extended here) -- a single local constant
## rather than a second table, since this story's own scope names no other
## need.
const SLEEP_NEED_NAME: StringName = &"sleep"

## Which bed cell this villager PERMANENTLY owns (Story villager-ai-018, GDD
## Rule 11 -- "claiming a bed IS the move-in moment," ownership never
## dissolves except via a furniture-revocation event, [method
## _on_furniture_revoked]). Meaningless while [member _has_owned_bed] is
## `false` -- read via [method get_owned_bed_cell], never this field
## directly by an outside consumer (mirrors [member current_cell]'s own
## "field named like the GDD concept, still read via a getter" precedent).
var _owned_bed_cell: Vector3i = Vector3i.ZERO

## Whether [member _owned_bed_cell] holds a real, currently-owned bed cell
## (a `Vector3i` sentinel-free boolean flag, since `Vector3i.ZERO` is itself
## a legal cell address and cannot double as "no bed").
var _has_owned_bed: bool = false

## The bed cell this villager is CURRENTLY, PHYSICALLY sleeping in, or `null`
## whenever not actually asleep in a bed (ground-sleeping, or any
## non-Sleeping state) -- distinct from [member _owned_bed_cell]'s own "which
## bed do I own" bookkeeping: a ground-sleeping villager (GDD Rule 12's
## `ground_bed_unreachable` case) still OWNS a bed but is not sleeping IN it.
## Set by [method _enter_bed_sleep], cleared by [method _start_ground_sleep],
## [method _wake_from_sleep], and [method _on_furniture_revoked] -- see each
## method's own doc comment.
var _sleeping_in_bed_cell: Variant = null

## Shared unstuck-rescue telemetry dependency (Story villager-ai-015, GDD
## Rule 15/F5's "a per-villager counter and a world total counter"). Unlike
## [member needs_provider]/[member job_queue] (mocked boundaries standing in
## for a NOT-YET-BUILT external system), [VillagerUnstuckTelemetry] is a
## small, fully-owned-by-this-story concrete class (see its own doc comment)
## -- a REAL shared, population-wide, non-`@export` [RefCounted] collaborator,
## mirroring [member scheduler]/[member nav_graph]'s own "one instance shared
## across the whole population" precedent (never one telemetry object per
## villager -- the world-total half of its job requires a single shared
## accumulator). Deliberately nil-safe rather than [method setup]-asserted
## (mirrors [member nav_graph]'s own "not every earlier story's test wires
## this" precedent): a villager with this left `null` still rescues/resets/
## re-decides correctly, it simply records no telemetry anywhere -- see
## [method _perform_watchdog_rescue].
var unstuck_telemetry: VillagerUnstuckTelemetry = null

## Shared travel-pathfinding graph dependency (Story villager-ai-009,
## ADR-0007 Decision Section 2) -- the SAME single, population-wide
## [VillagerNavGraph] instance that class's own doc comment establishes (one
## instance for the whole population, never one per villager). Deliberately
## a plain, non-`@export`ed [RefCounted] reference -- mirrors [member
## scheduler]'s own precedent exactly (no Inspector-authoring need, a
## shared-not-duplicated architecture). Assigned by whichever code
## assembles the villager population BEFORE [method start_traveling] is
## ever called -- asserted THERE (and in [method
## _recompute_path_from_current_cell]), deliberately NOT inside [method
## setup] (unlike [member config]/[member voxel_world]/[member scheduler]):
## every earlier story's own test already calls [method setup] without ever
## wiring this new dependency, and this story does not widen that boot-gate
## assertion retroactively -- mirrors [member needs_provider]/
## [member job_queue]'s own "nil-safe, not setup()-asserted" precedent
## (Story villager-ai-006's doc comment) exactly.
##
## **Wiring-order requirement** (load-bearing, not incidental): see this
## class's own doc comment's "Wiring-order requirement" paragraph -- the
## population assembler must call [method
## VillagerNavGraph.subscribe_to_voxel_world] on this SAME instance BEFORE
## this villager's own [method setup] runs.
var nav_graph: VillagerNavGraph = null

## Scaffold occupancy dependency (story `building-034`, ADR-0007 §1a/§1b, TD
## ruling D1) -- a Building-System-owned [ScaffoldRegistry], the SECOND
## occupancy source the shared walkability predicates now accept alongside
## [member voxel_world]. Duck-typed `Object` (never the concrete
## [ScaffoldRegistry] type) mirroring [member job_queue]/[member
## needs_provider]'s own established "shared collaborator, code-assigned,
## test-mockable without inheriting the real class" precedent -- callers only
## ever invoke the ONE method the predicates duck-type against,
## `has_scaffold(cell: Vector3i) -> bool`. Deliberately nil-safe, NOT
## `setup()`-asserted (mirrors [member nav_graph]'s own precedent exactly): a
## villager with this left `null` observes EXACTLY pre-amendment behaviour --
## every predicate call below passes it straight through as the shared
## predicates' own defaulted `scaffold_source` parameter, and a `null` source
## is structurally equivalent to "no source supplied" there. This is the
## SOLE injection point (D1: "the injection point is VillagerAi's existing
## one-line delegations, not every call site") -- every consumer holding a
## [VillagerAi] ([VillagerNavGraph], [VillagerRescueTargetSearch], the
## re-path filter) becomes scaffold-aware consistently and for free by
## calling this instance's own [method is_standable]/[method is_step_legal].
var scaffold_registry: Object = null

## Story villager-ai-019's own per-villager random source for F3/Rule 7c
## selection ([VillagerWanderSelector.select_micro_behavior]/[method
## VillagerWanderSelector.select_wander_target]) -- see this class's own doc
## comment's villager-ai-019 paragraph for the full "no live RNG, no
## wall-clock" determinism rationale. Deliberately nil-safe and NOT
## `setup()`-asserted (mirrors [member nav_graph]'s own precedent exactly):
## a test assigns an explicitly-seeded [RandomNumberGenerator] here BEFORE
## Wandering ever runs for full control over the draw sequence; an untouched
## production villager gets one lazily self-constructed, seeded from [member
## villager_id], the first time [method _get_wander_rng] is called -- never
## `randomize()`.
var wander_rng: RandomNumberGenerator = null

## This villager's stable identity/processing-order index (GDD Edge Case 3 /
## F2 tie-break convention: "stable villager processing order (villager
## index)"). Explicitly assigned by whichever code assembles the population
## (0, 1, 2... in creation order) -- deliberately NOT a static
## auto-incrementing counter on this class (hidden shared state would
## survive across independent GdUnit4 test runs in the same process,
## violating this codebase's test-isolation discipline); the wirer already
## controls creation order and is in the best position to assign this
## explicitly and deterministically. Used as the FIFO key [member scheduler]
## orders its queue by (this story's stable-order AC) and, in a future
## story, the value a job claim's worker-attribution record carries
## (Story 011, [TR-villager-ai-behavior-097]).
@export var villager_id: int = 0

## Current agent state (GDD "States and Transitions": Deciding is every
## agent's loop-start entry). Read-only from outside this class -- see
## [method get_state].
var _state: State = State.DECIDING

## See [enum PursuedActivity] (Story villager-ai-006). Starts at `NONE` -- a
## fresh villager pursues nothing until its first Deciding pass runs.
var _pursued_activity: PursuedActivity = PursuedActivity.NONE

## True once [method setup] has completed at least once.
var _is_set_up: bool = false

## Ticks elapsed since this villager's last Deciding-pass ELIGIBILITY
## trigger fired (not since a pass actually RAN -- those can differ once
## [member scheduler]'s budget queues a villager for a later tick). Drives
## the GDD Rule 2 periodic re-check ("`decision_interval` ticks so an urgent
## need can preempt long work"): this story implements the trigger itself
## ([method _check_decision_interval_trigger] calling [method
## request_deciding_pass] on cadence) -- the actual preemption/priority-list
## BEHAVIOUR once a pass runs is story 006's scope, untouched here.
var _ticks_since_last_decision: int = 0

## Ticks elapsed since this villager's last F3/Rule 7c wander pick (Story
## villager-ai-019) -- a SEPARATE, independently-counting cadence from
## [member _ticks_since_last_decision] (mirrors GDD 7b's own Breather beat,
## which "runs on a dedicated ticks-since-entry counter, independent of
## `decision_interval`"). Only ever advances while [method _tick_wandering]
## itself runs, i.e. while [member _state] is `State.WANDERING` -- a villager
## mid-walk toward a chosen wander/bed-drift target is `State.TRAVELING`
## instead (see [method _perform_wander_pick]'s own doc comment), so this
## counter naturally pauses for the walk's duration and resumes counting
## once travel completes and [member _state] returns to `State.WANDERING`.
var _ticks_since_last_wander_pick: int = 0

## The most recent [enum VillagerWanderSelector.MicroBehavior] this villager
## drew (Story villager-ai-019) -- `null` until [method _perform_wander_pick]
## has run at least once (mirrors [method get_owned_bed_cell]'s own
## "`Variant`, `null` until a real value exists" convention). Read-only
## observability/test seam, see [method get_last_micro_behavior].
var _last_micro_behavior: Variant = null

## DISCRETE, tick-boundary-quantized occupancy value -- the SOLE
## authoritative value for every logic/occupancy query (ADR-0009 Decision
## §1, Control Manifest Core Layer: "Occupancy authoritative value = discrete
## `current_cell`"). Mutated at EXACTLY two sanctioned points, both
## tick-boundary discrete: (a) [method _on_tick]'s arrival crediting below
## (this story), and (b) a future watchdog rescue (story 015) -- never
## anywhere else, never derived from [member _visual_position] or
## [member _intra_tick_progress]. While Traveling, this stays equal to
## [member _from_cell] for the step's ENTIRE duration (ADR-0009 Decision
## §1). Read via [method get_current_cell] -- never read directly by an
## outside consumer.
var current_cell: Vector3i = Vector3i.ZERO

## The current travel step's origin cell (Story villager-ai-004, ADR-0009
## Decision §1 Key Interfaces). [member current_cell] equals this for the
## step's entire duration -- driving it to a NEW value for the next step
## (path selection, re-pathing) is story 009's Traveling-state-machine
## concern, out of this story's scope.
var _from_cell: Vector3i = Vector3i.ZERO

## The current travel step's destination cell (Story villager-ai-004).
## [member current_cell] becomes this value ONLY via [method _on_tick]'s
## atomic arrival-crediting assignment, at the tick boundary where
## [member _intra_tick_progress] has reached `1.0`.
var _to_cell: Vector3i = Vector3i.ZERO

## CONTINUOUS, cosmetic-ONLY interpolated world position (ADR-0009 Decision
## §1) -- a rendering input, NEVER read by any occupancy/logic query
## anywhere (Control Manifest Core/Feature Layer Forbidden: "`_visual_
## position` is never read outside the movement/rendering path").
## Recomputed every [method _process] frame from [member _from_cell]/
## [member _to_cell]/[member _intra_tick_progress] ONLY -- [method _process]
## never touches [member current_cell] and never integrates the engine's
## own raw per-frame delta.
var _visual_position: Vector3 = Vector3.ZERO

## Tick-owned progress through the CURRENT travel step, `[0.0, 1.0]`
## (ADR-0009 Decision §1 Key Interfaces naming -- despite the name, this is
## progress through the STEP, not a tick period; a step may take zero, one,
## or several ticks to complete, GDD F1). Advanced EXCLUSIVELY via
## [method advance_travel_progress], using [TimeTickSystem]'s `game_delta`
## -- never the engine's raw per-frame delta (Control Manifest Core Layer:
## "`_intra_tick_progress` advances via `game_delta` ticks only -- frozen
## during pause, no glide"). Calling [method advance_travel_progress] every
## frame with a live `game_delta` is story 009's Traveling-state-machine
## wiring responsibility (Out of Scope here) -- this story supplies only
## the pure, directly-testable advance function itself (this story's
## AC20/[TR-villager-ai-behavior-093]: "drivable directly with injected
## `game_delta` values, no real engine frames").
var _intra_tick_progress: float = 0.0

## The villager's ultimate Traveling destination (Story villager-ai-009) --
## distinct from [member _to_cell] (the CURRENT single step's destination
## only). A mid-travel recompute ([method _recompute_path_from_current_cell])
## always paths TOWARD this same value; it never changes mid-travel itself
## (a target change mid-travel would be a preemption/abandon, not a
## redirect -- out of this story's scope). Meaningless while not actually
## traveling -- no sentinel is defined for "no target," since [member
## _travel_remaining_path] being empty is the authoritative "not traveling"
## signal this class already checks everywhere.
var _travel_target_cell: Vector3i = Vector3i.ZERO

## Which [enum State] this villager transitions into on arrival at
## [member _travel_target_cell] (Story villager-ai-009's AC: "arrival on
## site transitions to the next state (Working/Sleeping/etc.)") -- supplied
## by [method start_traveling]'s caller (future stories 010's job-site
## target / 018's bed target), never decided by this class itself.
var _travel_arrival_state: State = State.DECIDING

## The full remaining AStar3D path (Story villager-ai-009), EXCLUDING the
## cell the villager currently occupies -- `_travel_remaining_path[0]` is
## always kept equal to [member _to_cell] (the in-flight step's
## destination); later entries are cells not yet stepped onto. Empty
## whenever not traveling (mirrors [member _from_cell] == [member _to_cell]
## as the "stationary" signal). Widens [method get_remaining_movement_cells]
## per story villager-ai-008's own doc comment reservation -- neither
## [VillagerRepathFilter] nor [method evaluate_repath_trigger]'s call site
## needed a single line changed by this story.
var _travel_remaining_path: Array[Vector3i] = []

## Monotonic per-villager tick counter (Story villager-ai-011) -- incremented
## once per [method _on_tick] call, never reset (unlike [member
## _ticks_since_last_decision]). The sole clock [member
## _unreachable_retry_after_tick]'s cooldown windows are measured against --
## this villager's own local notion of "how many ticks have I processed,"
## independent of [TimeTickSystem]'s own global tick count (this class only
## ever observes that indirectly, via the `tick` signal itself).
var _tick_count: int = 0

## This villager's OWN per-cell retry-cooldown memory (Story villager-ai-011,
## GDD Rule 6/AC10, [TR-villager-ai-behavior-055]): cell -> the
## [member _tick_count] value at or after which this villager may
## true-path-check that cell again via F2 selection. Populated by [method
## _abandon_travel]'s WORK branch whenever [method start_traveling] (or a
## mid-travel redirect) fails to find a path to a job this villager had just
## claimed (Rule 6's "pathing to a job fails" case) -- NOT populated by F2's
## own internal pre-claim reachability filter ([VillagerJobSelector.
## select_job] already silently skips an unreachable candidate without ever
## claiming or reporting it, so there is nothing to throttle there). A
## per-villager Dictionary, deliberately NOT shared/global -- Rule 6's
## "reports... to the Building System" already shares the ghost-tint fact
## globally via [signal ConstructionJobQueue.job_reported_unreachable]; this
## Dictionary is purely this villager's own retry-pacing memory, distinct
## from that shared visual state. [method _attempt_claim_and_travel_to_job]
## consults it via [method _is_job_cooling_down] to exclude a still-cooling
## cell from this pass's candidate set (AC10's suppress-before-the-window
## guarantee); once [member _tick_count] reaches the stored value, the SAME
## cell is eligible again on the very next Deciding pass (AC10's "a retry
## attempt occurs").
var _unreachable_retry_after_tick: Dictionary[Vector3i, int] = {}

## Report-throttle window for D5's PRE-CLAIM probe misses (story
## `building-034`). Deliberately a SECOND map rather than a reuse of
## [member _unreachable_retry_after_tick]: that one is consulted by the
## candidate filter, so reusing it would suppress re-probing and change build
## order destructively (measured: a whole corner column left unbuilt). This
## map is read by NOTHING except [method _is_unreachable_report_throttled].
var _unreachable_report_after_tick: Dictionary[Vector3i, int] = {}

## The [BlueprintCell] this villager currently holds a claim on while
## [member _pursued_activity] == [constant PursuedActivity.WORK] (Story
## villager-ai-012) -- the SAME shared reference [ConstructionTickLoop]
## itself mutates directly (that class's own doc comment: "visible through
## any other holder of the SAME RefCounted reference"), so [method
## _tick_working] can read the REAL, live construction-progress state
## without a second query back into [member job_queue]. `null` whenever no
## claim is held (every state but Working, and Working itself immediately
## after completion/abandonment clears it back to `null`). See this class's
## own doc comment's villager-ai-012 paragraph for the full set/clear
## lifecycle.
var _claimed_blueprint_cell: BlueprintCell = null

## GDD F5's own named variable (Story villager-ai-015) -- consecutive ticks
## [member _state] has been `TRAVELING`/`WORKING` with [method
## _is_stuck_at_current_cell] true. Public (not `_`-prefixed), matching
## [member current_cell]'s own "field named exactly like the GDD variable,
## still read via a getter by outside consumers" precedent -- see [method
## get_stuck_tick_count]. Reset to `0` the instant relief is available (a
## legal step or standable [member current_cell] becomes available again),
## on leaving `TRAVELING`/`WORKING` entirely, AND after a successful rescue
## (this story's own interpretation of "the instant relief is available":
## exiting the two rescuable states is itself relief, since the counter is
## meaningless outside them) -- see [method _update_unstuck_watchdog].
var stuck_tick_count: int = 0

## Edge Case 2's distress cue flag (Story villager-ai-015, AC32 -- the scope
## boundary complement this story also implements): `true` whenever [method
## _is_stuck_at_current_cell] is true, for EVERY state, not only
## `TRAVELING`/`WORKING` -- an Idle/Wandering/Sleeping/Breather villager with
## no legal step sets this and stays put, never rescued (only
## `TRAVELING`/`WORKING` ever drive [member stuck_tick_count] toward a
## rescue). The exact visual treatment is explicitly deferred to the art
## bible (GDD Open Question 6) -- this field is the data seam a future
## presentation-layer story reads, not a rendering call of its own.
var _distressed: bool = false

## This villager's own F5 rescue counter (Story villager-ai-015, GDD Rule 15:
## "incrementing a per-villager counter"). Read via [method
## get_unstuck_count] -- see [member unstuck_telemetry] for the companion
## world-total counter this class does not itself hold (a single villager
## has no way to sum every OTHER villager's own rescue count).
var _unstuck_count: int = 0

## This villager's own per-stuck-episode instance of Story villager-ai-014's
## [RescueSearchFailureGate] (that class's own doc comment: "one instance per
## villager... each villager's stuck episode is its own independent
## history" -- deliberately NOT shared population-wide, unlike [member
## scheduler]/[member nav_graph]/[member unstuck_telemetry]). Constructed
## once, up front, exactly like [member _travel_remaining_path]'s own
## literal-default precedent -- no injection, no [method setup] wiring, since
## it depends on nothing but itself.
var _search_failure_gate: RescueSearchFailureGate = RescueSearchFailureGate.new()


## Explicitly callable wiring/validation entry point (ADR-0001). Asserts
## [member config], [member voxel_world], and a
## [member time_tick_system]-shaped dependency are all wired, applies
## ADR-0002's clamp+warn `validate()` policy, then connects this module's
## tick dispatch to the SOLE global tick broadcast (`TimeTickSystem.tick`,
## per that Autoload's own doc comment) -- never a per-villager `Timer` or
## raw-delta poll. Also explicitly sets `physics_interpolation_mode = OFF`
## on this node (Story villager-ai-004, ADR-0009 Engine Notes/Risks:
## defends against a project-wide physics-interpolation setting ever being
## flipped elsewhere and stacking with this class's own hand-rolled
## [member _visual_position] lerp, double-interpolation jitter) -- applied
## here since this class IS the villager's own node; a later
## presentation-layer story's dedicated visual child, if one is ever added,
## must carry this forward too. Story villager-ai-005 additionally asserts
## [member scheduler] is wired, connects it to [member time_tick_system]'s
## own tick broadcast via [method VillagerDecidingScheduler.
## connect_to_tick_source] (idempotent -- safe even if every villager in a
## shared population calls this during their own `setup()`), and marks this
## villager Deciding-eligible for its very first pass via [method
## request_deciding_pass] (the default [member _state] is `DECIDING` from
## construction -- without this call a freshly-created villager would never
## enter [member scheduler]'s queue at all).
func setup() -> void:
	assert(config != null, "VillagerAi.config not wired")
	assert(voxel_world != null, "VillagerAi.voxel_world not wired")
	assert(scheduler != null, "VillagerAi.scheduler not wired")
	if time_tick_system == null:
		time_tick_system = get_node_or_null(^"/root/TimeTickSystem")
	assert(
		time_tick_system != null,
		"VillagerAi requires a TimeTickSystem-shaped dependency (assign a mock in"
		+ " tests; the real Autoload is registered project-wide) before setup() can"
		+ " connect tick dispatch"
	)
	for issue: String in config.validate():
		if not issue.begins_with(ConfigResource.BLOCKING_PREFIX):
			push_warning(issue)
	scheduler.connect_to_tick_source(time_tick_system, config)
	@warning_ignore("unsafe_property_access")
	time_tick_system.tick.connect(_on_tick)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	# Story villager-ai-008 (GDD Rule 10b, re-path filter): default,
	# synchronous connection flags -- NEVER CONNECT_DEFERRED. The whole
	# race-closure argument (ADR-0009) depends on this filter evaluation
	# landing in the SAME call stack as the write.
	voxel_world.cell_changed.connect(_on_voxel_world_cell_changed)
	voxel_world.cells_changed_batch.connect(_on_voxel_world_cells_changed_batch)
	# Story villager-ai-009: consumes story 008's own FILTER signal
	# internally -- default, synchronous connection flags (never
	# CONNECT_DEFERRED), same race-closure reliance as the two connections
	# directly above.
	repath_evaluation_requested.connect(_on_repath_evaluation_requested)
	# Story villager-ai-018: [member bed_provider] is nil-safe/optional (not
	# asserted above, mirrors [member job_queue]'s own precedent) -- the
	# furniture-revocation subscription is therefore conditional, the ONE
	# optional-dependency SIGNAL connection this class wires (every other
	# optional collaborator is a plain method-call seam with no signal at
	# all). Default, synchronous connection flags -- never CONNECT_DEFERRED,
	# consistent with every other signal wiring in this method.
	if bed_provider != null:
		@warning_ignore("unsafe_property_access")
		bed_provider.furniture_revoked.connect(_on_furniture_revoked)
	request_deciding_pass()
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Returns the current agent state (read-only observability/test seam).
func get_state() -> State:
	return _state


## Returns which GDD Rule 2 priority-list tier this villager is currently
## committed to (read-only observability/test seam, mirrors [method
## get_state]; Story villager-ai-006) -- Story villager-ai-009's Traveling
## state needs this to know WHY it is traveling (bed vs. job site) once it
## lands.
func get_pursued_activity() -> PursuedActivity:
	return _pursued_activity


## Read-only observability seam (Story villager-ai-012) -- the cell address
## of [member _claimed_blueprint_cell], or `null` if this villager holds no
## claim right now. [VillagerOnSiteGate] is the real consumer: it has no
## other way to learn WHICH registered villager is the assigned worker for
## an arbitrary cell it is asked to gate.
func get_claimed_job_cell() -> Variant:
	return null if _claimed_blueprint_cell == null else _claimed_blueprint_cell.cell


## Read-only observability seam (Story villager-ai-018) -- the owned bed
## cell's address, or `null` if this villager owns no bed (mirrors [method
## get_claimed_job_cell]'s own "Variant, null-checked by the caller"
## convention).
func get_owned_bed_cell() -> Variant:
	return _owned_bed_cell if _has_owned_bed else null


## Read-only observability seam (Story villager-ai-018) -- see [member
## _has_owned_bed]'s own doc comment.
func has_owned_bed() -> bool:
	return _has_owned_bed


## Read-only observability seam (Story villager-ai-019) -- the most recent
## [enum VillagerWanderSelector.MicroBehavior] this villager drew, or `null`
## if [method _perform_wander_pick] has never run yet (see [member
## _last_micro_behavior]'s own doc comment).
func get_last_micro_behavior() -> Variant:
	return _last_micro_behavior


## Returns this villager's stable identity/processing-order index (see
## [member villager_id]'s own doc comment).
func get_villager_id() -> int:
	return villager_id


## Read-only observability seam (Story villager-ai-015) -- see [member
## stuck_tick_count]'s own doc comment.
func get_stuck_tick_count() -> int:
	return stuck_tick_count


## Read-only observability seam (Story villager-ai-015, AC32) -- see [member
## _distressed]'s own doc comment.
func is_distressed() -> bool:
	return _distressed


## Read-only observability seam (Story villager-ai-015) -- this villager's
## own F5 rescue count, see [member _unstuck_count]'s own doc comment.
func get_unstuck_count() -> int:
	return _unstuck_count


## Marks this villager Deciding-eligible (ADR-0008 Decision §2 -- "a villager
## becomes eligible for a Deciding pass... enters a pending queue"). This is
## the generic entry point every eligibility trigger calls: this story wires
## it to [method setup]'s initial-eligible-at-boot call and [method
## _check_decision_interval_trigger]'s periodic re-check; future stories
## (006's state-transition-into-Deciding, 011/018's job-complete, Needs &
## Mood's need-urgent) call this SAME method from their own trigger points --
## no second enqueue path is ever introduced. Delegates entirely to [method
## VillagerDecidingScheduler.enqueue], which is itself idempotent -- calling
## this repeatedly while already queued never bumps this villager to the
## back of the stable FIFO order.
func request_deciding_pass() -> void:
	assert(scheduler != null, "VillagerAi.scheduler not wired")
	scheduler.enqueue(villager_id)


## Public occupancy query (ADR-0009 Decision §1 Key Interfaces
## `get_current_cell(villager_id)` -- this codebase's actual architecture is
## one [VillagerAi] instance PER villager, established stories 001-003 and
## mirrored by [method get_state]'s own no-id signature, so no `villager_id`
## parameter exists here; a hypothetical multi-villager manager class is not
## this project's shape). ALWAYS returns the discrete [member current_cell]
## -- never [member _to_cell], never a value derived from
## [member _visual_position] or [member _intra_tick_progress] (this story's
## AC: "returns from_cell for a mid-transit villager... never an
## interpolation-derived value"). Because [member current_cell] only ever
## changes via [method _on_tick]'s atomic arrival-crediting assignment, a
## mid-transit call (any [member _intra_tick_progress] strictly between
## `0.0` and `1.0`, and even exactly `1.0` before the next tick boundary
## runs) always still returns [member _from_cell]'s value here, by
## construction -- no branching logic needed in this function itself.
func get_current_cell() -> Vector3i:
	return current_cell


## PRESENTATION ONLY. Read-only accessor over [member _visual_position]
## (Presentation Experience story presentation-003, VB-1 §2) -- returns
## whatever [method _process] most recently computed, unmodified. Never read
## this from any logic path -- occupancy, targeting, walled-in and
## seal-prevention checks all read [method get_current_cell] instead
## (ADR-0009 §2). The interpolation itself stays exactly where ADR-0009 put
## it ([method _process]); this accessor adds no computation, caches
## nothing, and is the ONE sanctioned call-site the presentation tier's
## [VillagerBodyView] pulls from every frame (pull-only, re-read every
## frame, never cached -- "one writer, N readers, zero copies"). This is
## purely additive: [member _visual_position] itself, [method _process],
## and every existing consumer of [member current_cell]/[method
## get_current_cell] are completely unchanged by this method's existence.
func get_visual_position() -> Vector3:
	return _visual_position


## Cosmetic-only visual-position recompute (ADR-0009 Decision §1 Key
## Interfaces, Control Manifest Core Layer Required Pattern: "Visual lerp...
## each frame"). This is [VillagerAi]'s ONE deliberate, narrowly-scoped
## exception to story villager-ai-001's "no raw-delta hook" structural
## guarantee -- [param _delta] (the engine's own per-frame value) is named
## with its conventional unused-parameter underscore prefix and is NEVER
## read: this function recomputes [member _visual_position] from
## [member _from_cell]/[member _to_cell]/[member _intra_tick_progress] ONLY,
## using [method VoxelWorldGrid.cell_to_world] for the single source of
## truth on cell<->world conversion (never a second, locally-duplicated
## formula). It never touches [member current_cell], never advances
## [member _intra_tick_progress] itself (that is [method
## advance_travel_progress]'s job, called elsewhere with [TimeTickSystem]'s
## `game_delta` -- story 009's wiring), and never mutates FSM state --
## [method _tick_state]'s tick-signal-only dispatch is completely unaffected
## by this function's existence. When paused, [member _intra_tick_progress]
## simply never changes between calls (nothing advances it), so this
## recompute keeps yielding the identical [member _visual_position] every
## frame -- villagers do NOT glide while paused (this story's AC21), with no
## pause-aware branch needed here.
##
## Story villager-ai-009 (this revision) additionally drives
## [member _intra_tick_progress] forward every frame -- the "wire live
## game_delta into travel" wiring story villager-ai-004 explicitly deferred
## to this story (that story's own doc comment above: "calling
## advance_travel_progress every frame with a live game_delta is story 009's
## Traveling state-machine wiring responsibility"), matching GDD Core Rule
## 1's "visible movement interpolates continuously using game delta".
## Queries [member time_tick_system]'s OWN `get_game_delta()` -- a value
## that system already computed this frame from ITS OWN raw-delta clamp/
## warp/pause formula -- never this function's own [param _delta] parameter
## (still unread, still named with its conventional unused-parameter
## underscore prefix). Guarded by `time_tick_system != null` AND
## [method is_moving] so this call is a harmless no-op whenever either is
## false -- every earlier story's own position-model unit tests call
## [method _process] directly without ever wiring [member time_tick_system],
## and this guard keeps every one of them passing unchanged.
func _process(_delta: float) -> void:
	if is_moving() and time_tick_system != null:
		@warning_ignore("unsafe_method_access")
		advance_travel_progress(time_tick_system.get_game_delta())
	_visual_position = VoxelWorldGrid.cell_to_world(_from_cell).lerp(
		VoxelWorldGrid.cell_to_world(_to_cell), _intra_tick_progress
	)


## Standability predicate (ADR-0007 Decision §1, GDD Rule 8/[TR-villager-ai-
## behavior-009]) -- one-line delegation (Story villager-ai-026, TD ruling
## BV-4): the real body, doc comment and all, now lives on
## [method VillagerWalkabilityRules.is_standable] (a pure static query over
## [param cell] and a [VoxelWorldGrid] reference, reading no per-villager
## state). This method's signature is unchanged so every existing caller
## keeps working untouched; see the static twin's doc comment for the full
## GDD/ADR rationale, including the load-bearing Planned-blueprint-cells
## clause.
func is_standable(cell: Vector3i) -> bool:
	assert(voxel_world != null, "VillagerAi.voxel_world not wired")
	return VillagerWalkabilityRules.is_standable(voxel_world, cell, scaffold_registry)


## Step-legality predicate (ADR-0007 Decision §1, GDD Rule 9/[TR-villager-ai-
## behavior-010]) -- one-line delegation (Story villager-ai-026, TD ruling
## BV-4): the real body, doc comment and all, now lives on
## [method VillagerWalkabilityRules.is_step_legal]. This method's signature
## is unchanged so every existing caller keeps working untouched.
##
## Story `building-034` (ADR-0007 §1a/§1b, D1): forwards [member
## scaffold_registry] as the shared predicates' `scaffold_source` -- this is
## the SOLE injection point (D1) that makes [VillagerNavGraph] (and every
## other consumer holding a [VillagerAi]) scaffold-aware for free.
func is_step_legal(from_cell: Vector3i, to_cell: Vector3i) -> bool:
	return VillagerWalkabilityRules.is_step_legal(voxel_world, from_cell, to_cell, scaffold_registry)


## Body-column derivation (Story villager-ai-003, ADR-0009 slice-propagation
## Decision §2/Key Interfaces, GDD Rule 8a/[TR-villager-ai-behavior-098]) --
## one-line delegation (Story villager-ai-026, TD ruling BV-4): the real
## body, doc comment and all, now lives on
## [method VillagerWalkabilityRules.body_column] (a pure static derivation
## with no per-villager state). This method's signature is unchanged so
## every existing caller keeps working untouched.
func body_column(cell: Vector3i) -> Array[Vector3i]:
	return VillagerWalkabilityRules.body_column(cell)


## Occupancy predicate against a villager's body-column (ADR-0009
## slice-propagation Decision §2/§2b) -- one-line delegation (Story
## villager-ai-026, TD ruling BV-4): the real body, doc comment and all, now
## lives on [method VillagerWalkabilityRules.is_cell_in_body_column]. This
## method's signature is unchanged so every existing caller keeps working
## untouched.
func is_cell_in_body_column(occupant_cell: Vector3i, query_cell: Vector3i) -> bool:
	return VillagerWalkabilityRules.is_cell_in_body_column(occupant_cell, query_cell)


## Pure movement-update function (Story villager-ai-004 AC20,
## [TR-villager-ai-behavior-093]): advances [member _intra_tick_progress] by
## `(config.move_speed * game_delta) / step_length_cells`, clamped to
## `[0.0, 1.0]` -- never overshoots past arrival even if [param game_delta]
## is unusually large (a stall, or several skipped frames). [param
## game_delta] is injected directly by the caller ([TimeTickSystem]'s own
## `get_game_delta()` in production, story 009's wiring) -- this function
## itself has ZERO dependency on [TimeTickSystem] or any engine callback,
## which is exactly what lets a test drive it with hand-picked
## [param game_delta] samples, "no real engine frames" (this story's AC20
## wording). Touches [member _intra_tick_progress] ONLY -- never
## [member current_cell] (the tick-boundary-only mutation discipline this
## story's AC13 depends on: reaching `1.0` progress here does NOT itself
## credit arrival; only [method _on_tick] does that, separately).
##
## Step length follows GDD F1's classification -- orthogonal = `1.0`,
## diagonal = `1.4` -- derived from [member _from_cell]/[member _to_cell]
## via [method _current_step_length_cells]; a zero-length step (the
## `from == to` case F1 documents as "target is the current/adjacent cell...
## immediate arrival") snaps progress straight to `1.0` with no division.
func advance_travel_progress(game_delta: float) -> void:
	assert(config != null, "VillagerAi.config not wired")
	var step_length: float = _current_step_length_cells()
	if step_length <= 0.0:
		_intra_tick_progress = 1.0
		return
	var progress_delta: float = (config.move_speed * game_delta) / step_length
	_intra_tick_progress = clampf(_intra_tick_progress + progress_delta, 0.0, 1.0)


## GDD F1's step-length classification for the CURRENT travel step
## ([member _from_cell] -> [member _to_cell]) -- delegates entirely to
## [method classify_step_length_cells] (Story villager-ai-007 extraction: the
## exact math this method always computed inline before that story;
## behavior-preserving refactor, not a semantic change -- the same
## "extract a pure static twin" pattern [VoxelWorldGrid._pure_terrain_height]
## already established in this codebase).
func _current_step_length_cells() -> float:
	return VillagerAi.classify_step_length_cells(_from_cell, _to_cell)


## Pure, static GDD F1 step-length classifier (Story villager-ai-007
## extraction, [TR-villager-ai-behavior-072]): orthogonal steps (differing on
## at most one horizontal axis) are `1.0`; a true diagonal (differing on BOTH
## the X and Z axes -- the same diagonal test [method is_step_legal] already
## uses) is `1.4`. Height difference (Y) never affects step length, per F1.
## Returns `0.0` when [param from_cell] equals [param to_cell] -- F1's
## documented zero-length/immediate-arrival case. Reused by [method
## _current_step_length_cells] (this class's own Traveling-step math,
## story 004) AND by [VillagerNavGraph.path_length_cells] (story 007's
## AStar3D path-length summation) -- ONE classification, never two
## independently-written copies of the same F1 formula.
static func classify_step_length_cells(from_cell: Vector3i, to_cell: Vector3i) -> float:
	if from_cell == to_cell:
		return 0.0
	var dx: int = to_cell.x - from_cell.x
	var dz: int = to_cell.z - from_cell.z
	return 1.4 if (dx != 0 and dz != 0) else 1.0


## Tick-boundary arrival predicate (ADR-0009 Decision §1 Key Interfaces
## `_travel_complete()`): true once [member _intra_tick_progress] has
## reached `1.0` -- the CURRENT travel step's target has been reached.
## Reports only on the current step; it says nothing about whether the
## villager has reached its ultimate destination, should transition out of
## Traveling, or should release a job claim -- those remain story 009/other
## stories' concerns entirely.
func _travel_complete() -> bool:
	return _intra_tick_progress >= 1.0


## Solidity read for [method is_standable]'s "solid below" check -- one-line
## delegation (Story villager-ai-026, TD ruling BV-4): the real body now
## lives on [method VillagerWalkabilityRules._is_solid]. Kept as a private
## instance method (unchanged signature) solely because the `*_after_write`
## twins ([method _is_solid_after_write], out of this story's scope) still
## call it directly -- this story edits no caller, including that one.
func _is_solid(cell: Vector3i) -> bool:
	return VillagerWalkabilityRules._is_solid(voxel_world, cell)


## Passability read for [method is_standable]'s clearance-column check --
## one-line delegation (Story villager-ai-026, TD ruling BV-4): the real body
## now lives on [method VillagerWalkabilityRules._is_passable]. Kept as a
## private instance method (unchanged signature) solely because the
## `*_after_write` twins ([method _is_passable_after_write], out of this
## story's scope) still call it directly.
func _is_passable(cell: Vector3i) -> bool:
	return VillagerWalkabilityRules._is_passable(voxel_world, cell)


## [signal TimeTickSystem.tick] handler -- the sole entry point that ever
## advances this agent's state machine (ADR-0008 Decision §2). Also performs
## tick-boundary travel-arrival crediting (ADR-0009 Decision §1 Key
## Interfaces `_on_tick()`; GDD F1 [TR-villager-ai-behavior-029]'s
## tick-boundary-only crediting, extended to occupancy by that ADR): the
## atomic `current_cell = _to_cell` assignment is one of the exactly two
## sanctioned points [member current_cell] is ever mutated (the other is a
## future watchdog rescue, story 015). Idempotent once credited --
## [member current_cell] already equals [member _to_cell], a harmless no-op
## -- until a NEW travel step's [member _from_cell]/[member _to_cell] begin
## (story 009). Delegates the FSM dispatch itself to [method _tick_state];
## kept as a separate method (rather than connecting [method _tick_state]
## directly) so a later story's Deciding-pass staggering budget (ADR-0008's
## `max_deciding_per_tick` FIFO queue, story 005) has an obvious, single seam
## to insert into without touching the signal-wiring line in [method setup].
## Story villager-ai-005 uses that seam: [method
## _check_decision_interval_trigger] runs before dispatch, marking this
## villager Deciding-eligible on the GDD Rule 2 periodic cadence regardless
## of its current state (so an urgent need can later preempt long work, per
## that rule) -- [method _tick_state]'s own `State.DECIDING` branch is what
## actually gates the (still-stub) Deciding pass body behind [member
## scheduler]'s budget.
##
## Story villager-ai-006 completes this seam. [method _tick_state]'s own
## `State.DECIDING` branch (unchanged since story 005) already re-evaluates
## the priority list for a villager that STARTS this tick already Deciding.
## For every OTHER state (Traveling/Working/Sleeping/Breather/Wandering),
## THIS method checks [member scheduler]'s budget itself, AFTER [method
## _tick_state] has already run that state's own body -- so the CURRENT
## tick's in-progress activity (e.g. a claimed job's work-progress credit,
## Story 012) always completes first, and only THEN, if runnable, does
## [method _tick_deciding] run and possibly reassign [member _state] --
## exactly GDD Rule 3's graceful-preemption ordering
## ([TR-villager-ai-behavior-050]: "finishes the current cell's in-progress
## tick, then releases its job claim... and pursues the need"). The
## `was_deciding` guard captures [member _state] BEFORE [method _tick_state]
## runs so a villager that started the tick already `DECIDING` -- whose
## Deciding pass [method _tick_state]'s own branch already ran -- is never
## double-invoked here; each villager's Deciding pass still runs at most
## once per tick (AC5).
func _on_tick() -> void:
	_tick_count += 1
	if _travel_complete():
		current_cell = _to_cell
	# Story villager-ai-015: the Unstuck Watchdog's own per-tick check runs
	# HERE -- after arrival-crediting (so `current_cell` already reflects any
	# just-completed step) but BEFORE `was_deciding` is captured below, so a
	# rescue firing THIS tick (which transitions `_state` to `State.DECIDING`)
	# is correctly seen by that capture -- see this method's own class-doc
	# "no double-decide" paragraph for the full ordering rationale.
	_update_unstuck_watchdog()
	_check_decision_interval_trigger()
	var was_deciding: bool = _state == State.DECIDING
	_tick_state()
	if not was_deciding and scheduler.is_runnable_this_tick(villager_id):
		_tick_deciding()


## GDD Rule 2's periodic re-check trigger ("re-evaluated... periodically
## every `decision_interval` ticks so an urgent need can preempt long
## work") -- this story's own concrete, independently-testable eligibility
## enqueue trigger (its Implementation Notes explicitly name
## `decision_interval` elapsed as one of the triggers this story owns,
## alongside need-urgent/job-complete, which remain future stories' scope
## since neither Needs & Mood nor the Building System's job queue exist in
## this codebase yet). Runs every tick regardless of [member _state] -- the
## cadence itself is what lets a Working villager's need be periodically
## reconsidered; deciding what to actually DO once reconsidered is story
## 006's priority-list logic.
func _check_decision_interval_trigger() -> void:
	_ticks_since_last_decision += 1
	if _ticks_since_last_decision >= config.decision_interval:
		_ticks_since_last_decision = 0
		request_deciding_pass()


## FSM dispatch (ADR-0008 Key Interfaces): one `match` branch per
## [enum State], one function per state. Every branch below is an
## intentionally empty stub for this story -- real per-state behaviour
## (movement, work progress, sleep recovery, breather pacing, wander
## micro-behaviours, the Deciding priority list) lands in stories 002/004/
## 005/006/etc., never here. Story villager-ai-005's own contribution lives
## entirely in the `State.DECIDING` branch: it gates the (still-stub) [method
## _tick_deciding] call behind [method VillagerDecidingScheduler.
## is_runnable_this_tick] -- a villager sitting in `DECIDING` but not yet
## dequeued by [member scheduler]'s budget simply does nothing this tick,
## remaining queued for a later one (ADR-0008 Decision §2). No other branch
## is touched by this story.
func _tick_state() -> void:
	match _state:
		State.DECIDING:
			if scheduler.is_runnable_this_tick(villager_id):
				_tick_deciding()
		State.TRAVELING:
			_tick_traveling()
		State.WORKING:
			_tick_working()
		State.SLEEPING:
			_tick_sleeping()
		State.BREATHER:
			_tick_breather()
		State.WANDERING:
			_tick_wandering()


## The Deciding-pass priority-list evaluation (Story villager-ai-006; GDD
## Rule 2, ADR-0008 Decision §1: "strict, discrete priority order (Urgent
## need > Work > Idle/Wander)" -- plain early-return `if` checks in exactly
## that order, never scored). Called only when [member scheduler] has
## already marked this villager runnable this tick -- either by [method
## _tick_state]'s own `State.DECIDING` branch (a villager that started this
## tick already Deciding, story 005) or by [method _on_tick]'s
## `was_deciding`-guarded post-check (a villager preempted mid-activity,
## this story) -- so this function itself never re-checks that gate.
##
## Tier 1 -- urgent need ([member needs_provider], mocked boundary). Edge
## Case 3b: already committed to pursuing a need
## ([member _pursued_activity] == `NEED`) is a documented no-op -- the
## villager continues, nothing reassigned, no claim ever released (there is
## none to release while already pursuing a need). Otherwise, a held job
## claim ([member _pursued_activity] == `WORK`) is released first ([method
## _release_job_claim], GDD Rule 3's graceful abandon) before committing to
## the need (target selection is Story 018's).
##
## Tier 2 -- an available construction job ([member job_queue], mocked
## boundary). Claim stickiness (AC41/[TR-villager-ai-behavior-052]):
## already committed to work ([member _pursued_activity] == `WORK`) is ALSO
## a no-op -- the periodic `decision_interval` re-check must never re-run
## job selection against a held claim, so [member job_queue] is not even
## consulted in this branch. Otherwise, an available job commits the
## villager to work (target selection is Story 010's F2).
##
## Tier 3 -- idle/wander, the floor (GDD Edge Case 12's MVP degenerate
## case): reached only when neither tier above committed -- no urgent need,
## and either no available job or already sticky-committed to one (handled
## by tier 2's own early return above, so this line only ever sees "no job"
## in this story's own scope).
func _tick_deciding() -> void:
	# Story villager-ai-018: this sticky check now runs FIRST, unconditional
	# on [method _has_urgent_need]'s current value -- a real Needs & Mood
	# provider reads `has_urgent_need == false` for the ENTIRE Recovering
	# span (its own [enum NeedsMood.NeedState] is SATISFIED/URGENT/RECOVERING,
	# and "urgent" is deliberately narrower than "still being pursued," see
	# `docs/architecture/architecture.md`'s Core Rule 3 -- has_urgent_need is
	# the URGENT-state gate, not a "still recovering" query). The former
	# nested "if _has_urgent_need(): if pursued == NEED: return" shape
	# (story 006) silently assumed a mocked provider that never distinguished
	# Recovering from Urgent -- with a REAL provider wired, that nested guard
	# would never even fire once sleep begins, letting a periodic
	# `decision_interval` re-check fall through to tier 2 and steal a
	# sleeping villager into a construction job. Mirrors tier 2's own
	# pre-existing WORK-stickiness shape (`if _pursued_activity == WORK:
	# return`, checked BEFORE `_has_available_job` is ever consulted) --
	# Edge Case 3b's "already pursuing a need is a documented no-op" is now
	# unconditional, exactly like Rule 4's claim-stickiness already was.
	if _pursued_activity == PursuedActivity.NEED:
		return
	if _has_urgent_need():
		if _pursued_activity == PursuedActivity.WORK:
			_release_job_claim()
		_pursued_activity = PursuedActivity.NEED
		_commit_to_sleep()
		return
	if _pursued_activity == PursuedActivity.WORK:
		return
	if _has_available_job() and _attempt_claim_and_travel_to_job():
		return
	_pursued_activity = PursuedActivity.NONE
	_state = State.WANDERING


## Tier-1 gate read ([member needs_provider], mocked boundary). Nil-safe: a
## not-yet-wired villager (or any test that never assigns this) always reads
## "no urgent need" -- never crashes, no hard [method setup] assertion, since
## Needs & Mood has no boot-gate dependency this story enforces.
func _has_urgent_need() -> bool:
	if needs_provider == null:
		return false
	@warning_ignore("unsafe_method_access")
	return needs_provider.has_urgent_need(villager_id)


## Tier-2 gate read ([member job_queue], mocked boundary). Nil-safe, same
## rationale as [method _has_urgent_need].
func _has_available_job() -> bool:
	if job_queue == null:
		return false
	@warning_ignore("unsafe_method_access")
	return job_queue.has_available_job()


## Graceful-preemption claim release (GDD Rule 3/[TR-villager-ai-behavior-050]
## "releases its job claim back to the queue"). Called from [method
## _tick_deciding]'s tier-1 branch when [member _pursued_activity] was
## `WORK`, from [method _abandon_travel]'s WORK branch (pathing failure to a
## claimed job), and from this story's own [method _complete_claimed_job]/
## [method _abandon_claimed_job] (job completion/revocation, story
## villager-ai-012) -- i.e. only when a claim could plausibly be held.
## Story villager-ai-012 (this revision): ALSO clears [member
## _claimed_blueprint_cell] back to `null` unconditionally, regardless of
## whether [member job_queue] is wired -- every one of this method's callers
## is relinquishing a claim, so this field must never outlive the claim it
## refers to. A no-op on the [member job_queue] side when it was never
## wired (mocked-boundary nil-safety, same as [method _has_urgent_need]/
## [method _has_available_job]).
func _release_job_claim() -> void:
	_claimed_blueprint_cell = null
	if job_queue == null:
		return
	@warning_ignore("unsafe_method_access")
	job_queue.release_claim(villager_id)


## Tier-2 candidate-list read ([member job_queue], mocked boundary; Story
## villager-ai-011). Nil-safe, same rationale as [method _has_available_job]
## -- though by construction this is only ever called from [method
## _attempt_claim_and_travel_to_job], itself only reached after [method
## _has_available_job] already confirmed [member job_queue] is wired.
## [member ConstructionJobQueue.get_available_jobs]'s exact duck-typed
## signature/contract: every currently BUILDING-eligible [BlueprintCell]
## across every tracked project, commit-time ordered.
func _get_available_jobs() -> Array[BlueprintCell]:
	if job_queue == null:
		return []
	@warning_ignore("unsafe_method_access")
	return job_queue.get_available_jobs()


## Tier-2 atomic-claim attempt ([member job_queue], mocked boundary; Story
## villager-ai-011, GDD Rule 4/AC8/Edge Case 3, [TR-villager-ai-behavior-051]/
## [TR-villager-ai-behavior-081]). Nil-safe, same rationale as [method
## _has_available_job]. Delegates entirely to [member
## ConstructionJobQueue.claim_job]'s exact duck-typed signature/contract --
## this class performs no claim bookkeeping of its own; a `true` return means
## [param cell] is now locked to this villager (one job per villager, no
## other villager may claim it until released), a `false` return means
## either this villager already holds a different claim, or [param cell] lost
## its claim race to another villager's same-pass call (or is no longer
## eligible for any other Building-System-owned reason) -- this method
## cannot distinguish those cases, by design; the caller ([method
## _attempt_claim_and_travel_to_job]) simply tries the next candidate either
## way.
func _claim_job(cell: Vector3i) -> bool:
	if job_queue == null:
		return false
	@warning_ignore("unsafe_method_access")
	return job_queue.claim_job(cell, villager_id)


## Unreachable-job report ([member job_queue], mocked boundary; Story
## villager-ai-011, GDD Rule 6/AC9, [TR-villager-ai-behavior-055]). Nil-safe,
## same rationale as [method _has_available_job]. Delegates entirely to
## [member ConstructionJobQueue.report_unreachable] -- this class owns no
## ghost-tint/visual state of its own.
##
## **AMENDED 2026-07-27 (story `building-034`, TD ruling D5).** Previously
## only [method _abandon_travel]'s WORK branch ever called this (a job THIS
## villager had just claimed and then failed to path to) -- F2's own silent
## pre-claim reachability skip never called or reported anything. That is no
## longer true: [method _attempt_claim_and_travel_to_job] now ALSO calls this
## for every candidate [VillagerJobSelector.select_job] itself found
## unreachable this pass (throttled by the same per-cell cooldown), so the
## Building System can detect an unreachable cell and erect scaffolding for
## it BEFORE it is ever claimed. A doc comment that contradicts the code is
## how `villager-ai-024` lost a day -- this comment is rewritten precisely so
## it does not repeat that.
func _report_job_unreachable(cell: Vector3i) -> void:
	if job_queue == null:
		return
	@warning_ignore("unsafe_method_access")
	job_queue.report_unreachable(cell)


## AC10's per-cell retry throttle read (see [member
## _unreachable_retry_after_tick]'s own doc comment for the full rationale) --
## `true` iff [param cell] was reported unreachable by THIS villager recently
## enough that [member config]'s `unreachable_retry_ticks` have not yet
## elapsed since. A cell never reported unreachable by this villager (absent
## from the map) is never cooling down.
func _is_job_cooling_down(cell: Vector3i) -> bool:
	return _unreachable_retry_after_tick.has(cell) and _tick_count < _unreachable_retry_after_tick[cell]


## Report-throttle read for D5's pre-claim probe misses -- the report-only
## twin of [method _is_job_cooling_down]. Never consulted by candidate
## selection; see [member _unreachable_report_after_tick].
func _is_unreachable_report_throttled(cell: Vector3i) -> bool:
	return (
		_unreachable_report_after_tick.has(cell)
		and _tick_count < _unreachable_report_after_tick[cell]
	)


## Rule 4/F2 claim-and-travel commit loop (Story villager-ai-011; GDD Rule 4
## "claiming locks the job"; [VillagerJobSelector]'s own doc comment
## explicitly deferred "WHICH job ends up actually claimed/traveled-to" to
## this story). Called ONLY from [method _tick_deciding]'s tier-2 branch,
## after [method _has_available_job] has already confirmed [member job_queue]
## is non-null and the queue is non-empty (Rule 2's cheap existence gate) --
## this method performs the more expensive part: select a candidate (F2 via
## [VillagerJobSelector.select_job]), attempt to atomically claim it, and if
## the claim is LOST to another villager's same-pass claim (AC8/Edge Case 3),
## try the NEXT F2 candidate within this SAME Deciding pass -- "the loser
## selects its next candidate," never a second, deferred Deciding pass for a
## lost claim RACE specifically (unlike Rule 6's post-claim PATHING failure,
## which DOES defer to a future pass via [method _abandon_travel]'s existing
## [method request_deciding_pass] re-queue, unchanged by this story).
## [member nav_graph] absent (null) short-circuits to `false` immediately --
## mirrors [member needs_provider]/[member job_queue]'s own nil-safe
## precedent; a villager with no shared graph wired yet simply has no work
## available this pass, exactly as if the queue were empty.
##
## Each iteration re-reads [method _get_available_jobs] fresh (the queue is
## the sole source of truth on which cells are still claimable -- a real
## [ConstructionJobQueue] naturally excludes an already-claimed cell from its
## own next [method ConstructionJobQueue.get_available_jobs] call), filtered
## by two local exclusions: `attempted_cells` (cells THIS pass already tried
## and lost the claim race for -- guarantees loop termination even against a
## queue double that never shrinks its own list: `attempted_cells` strictly
## grows by exactly one distinct cell per failed-claim iteration, bounded by
## the pass's own original candidate count) and [method _is_job_cooling_down]
## (AC10's per-cell throttle).
##
## Returns `false` when no candidate could be claimed at all this pass --
## every remaining candidate was cooling down, F2's own true-path cap found
## nothing reachable ([JobSelectionResult.has_selection] `false`), or every
## reachable candidate lost its claim race -- [method _tick_deciding]'s own
## caller then falls through to its existing tier-3 Wandering floor (AC11:
## "never stuck in Deciding").
##
## Returns `true` once a claim succeeds and [method start_traveling] has been
## invoked -- regardless of whether that travel call itself immediately
## succeeds: an immediate pathing failure is Rule 6/AC9's own post-claim
## flow, handled entirely by [method start_traveling]'s existing call into
## [method _abandon_travel] (this story only adds the unreachable-report +
## retry-cooldown side effects there, see that method's own doc comment) --
## this loop itself never retries after a successful claim.
func _attempt_claim_and_travel_to_job() -> bool:
	if nav_graph == null:
		return false
	var attempted_cells: Array[Vector3i] = []
	while true:
		var candidates: Array[BlueprintCell] = []
		for candidate: BlueprintCell in _get_available_jobs():
			if attempted_cells.has(candidate.cell):
				continue
			if _is_job_cooling_down(candidate.cell):
				continue
			candidates.append(candidate)
		if candidates.is_empty():
			return false
		var result: JobSelectionResult = VillagerJobSelector.select_job(
			candidates, current_cell, nav_graph, config.job_candidate_count, config.max_selection_candidates
		)
		# Story `building-034` (TD ruling D5) -- F2's own silent pre-claim
		# reachability skip becomes a REPORTING skip: every cell this pass
		# probed and found unreachable is forwarded to [member job_queue]'s
		# `report_unreachable` seam, throttled by the SAME already-landed
		# per-cell cooldown ([member _unreachable_retry_after_tick] /
		# [method _is_job_cooling_down]) a post-claim pathing failure already
		# uses -- a report can never storm per tick. This rewrites the
		# "never for F2's own silent pre-claim reachability skip" sentence
		# [method _report_job_unreachable]'s own doc comment used to state
		# (correctly, before this story).
		# THROTTLE THE REPORT, NEVER THE SELECTION — and the distinction is
		# load-bearing. The TD ruling asked for the landed 20-tick cooldown so
		# a pre-claim probe miss cannot storm the queue, and that is right. But
		# `_unreachable_retry_after_tick` is ALSO read by the candidate filter,
		# so writing probe misses into it stops the villager re-probing those
		# cells for 20 ticks. Measured consequence: it builds other cells
		# first, seals a corner off, and villager-ai-024's regression test
		# falls 30/30 -> 27/30 with a whole corner column left PLANNED. A
		# pre-claim probe is cheap and MUST be repeated every pass, because a
		# cell that is unreachable now routinely becomes reachable as the build
		# progresses. So the throttle gets its own map and the selection filter
		# is left alone.
		for unreachable_cell: Vector3i in result.unreachable_cells:
			if _is_unreachable_report_throttled(unreachable_cell):
				continue
			_report_job_unreachable(unreachable_cell)
			_unreachable_report_after_tick[unreachable_cell] = (
				_tick_count + config.unreachable_retry_ticks
			)
		if not result.has_selection():
			return false
		if _claim_job(result.chosen.cell):
			# Story villager-ai-012: recorded BEFORE travel starts -- Rule 5's
			# on-site gate must already exist for the FULL travel period, not
			# only once Working begins, since ConstructionTickLoop.claim_job
			# already flipped this cell to UNDER_CONSTRUCTION.
			_claimed_blueprint_cell = result.chosen
			_pursued_activity = PursuedActivity.WORK
			start_traveling(result.chosen.cell, State.WORKING)
			return true
		attempted_cells.append(result.chosen.cell)
	# Unreachable -- `while true` only exits via an explicit `return` above;
	# this satisfies GDScript's static "not all code paths return a value"
	# analyzer, which does not treat an unconditional `while true:` as
	# provably infinite/always-returning on its own.
	return false


# =============================================================================
# Story villager-ai-018 -- Sleep & home, bed claim (GDD Rule 11/12/13,
# Edge Case 1/5/6, [TR-villager-ai-behavior-061]/062/063/084/085)
# =============================================================================

## Tier-1 NEED commitment's own target-selection entry point (this story
## fills in what story 006 left as a bare `_state = State.TRAVELING`
## placeholder, its own doc comment naming "target selection is Story 018's").
## GDD Rule 12's owned-bed preference (AC23/AC44 -- "an owned bed is ALWAYS
## preferred, even over a closer unowned one") falls out of this method's own
## branch ORDER: an owned bed is checked FIRST and, if present, this method
## never even looks at [member bed_provider]'s unowned candidates at all --
## there is no ranking step that could ever prefer a closer unowned bed over
## an owned one, because the unowned branch is structurally unreachable
## whenever [member _has_owned_bed] is `true`.
func _commit_to_sleep() -> void:
	if _has_owned_bed:
		if nav_graph == null:
			# Nil-safe fallback (mirrors [method _attempt_claim_and_travel_to_job]'s
			# own `nav_graph == null` short-circuit): with no shared graph to
			# even ASK whether the owned bed is reachable, the safe, honest
			# answer is "cannot reach it" -- ground sleep, never a crash.
			_start_ground_sleep(NeedsMood.RecoverySource.GROUND_BED_UNREACHABLE)
			return
		# AC23: sleeps in its own bed when reachable. AC24 (second half): if
		# [method start_traveling] finds no path, it calls [method
		# _abandon_travel] internally -- whose `NEED` branch (below) performs
		# the `ground_bed_unreachable` fallback this exact case needs, so no
		# separate reachability pre-check is required here.
		start_traveling(_owned_bed_cell, State.SLEEPING)
		return
	# AC22: claims the nearest unowned reachable bed, permanently.
	if _attempt_claim_and_travel_to_bed():
		return
	# AC24 (first half): no bed owned, and no unowned reachable bed exists
	# ([member bed_provider] unwired, or every candidate unreachable/lost its
	# claim race) -- ground sleep at the current cell.
	_start_ground_sleep(NeedsMood.RecoverySource.GROUND_NO_BED_OWNED)


## Rule 4's atomic-claim-and-travel loop (Story villager-ai-011), applied
## unchanged to bed ownership (this story's own Implementation Notes: "Bed
## claiming reuses the atomic-claim primitive (Story 011)... AC43 lives in
## Story 011" -- [method _attempt_claim_and_travel_to_job]'s own doc comment
## explains the identical shape this mirrors line-for-line: select a
## candidate ([VillagerBedSelector.select_nearest_reachable_bed], this
## story's bed-scoped twin of [VillagerJobSelector.select_job]), attempt an
## atomic claim ([method _claim_bed]), and on a lost race try the NEXT
## candidate within this SAME Deciding pass -- never a second, deferred pass
## for a lost claim race specifically. [member bed_provider]/[member
## nav_graph] absent (either `null`) short-circuits to `false` immediately,
## mirroring [method _attempt_claim_and_travel_to_job]'s own nil-safe
## precedent -- a villager with either left unwired simply has no bed
## available this pass, exactly as if [member bed_provider]'s candidate list
## were empty.
##
## Each iteration re-reads [method _get_unowned_bed_cells] fresh (the
## provider is the sole source of truth on which beds are still unowned --
## mirrors [method _attempt_claim_and_travel_to_job]'s own "the queue
## naturally excludes an already-claimed cell" precedent), filtered by
## `attempted_cells` (cells THIS pass already tried and lost the claim race
## for -- strictly grows by one distinct cell per failed iteration, bounding
## the loop exactly like the job-claim twin).
##
## Returns `true` once a claim succeeds and [member _owned_bed_cell]/[member
## _has_owned_bed] are set and [method start_traveling] has been invoked --
## regardless of whether that travel call itself immediately succeeds (an
## immediate pathing failure is [method _abandon_travel]'s own NEED-branch
## ground-sleep fallback, unchanged by this loop). Returns `false` when no
## bed could be claimed at all this pass -- [method _commit_to_sleep]'s own
## caller then falls through to its `ground_no_bed_owned` fallback.
func _attempt_claim_and_travel_to_bed() -> bool:
	if nav_graph == null or bed_provider == null:
		return false
	var attempted_cells: Array[Vector3i] = []
	while true:
		var candidates: Array[Vector3i] = []
		for cell: Vector3i in _get_unowned_bed_cells():
			if attempted_cells.has(cell):
				continue
			candidates.append(cell)
		if candidates.is_empty():
			return false
		var chosen: Variant = VillagerBedSelector.select_nearest_reachable_bed(
			candidates, current_cell, nav_graph
		)
		if chosen == null:
			return false
		if _claim_bed(chosen):
			_owned_bed_cell = chosen
			_has_owned_bed = true
			start_traveling(chosen, State.SLEEPING)
			return true
		attempted_cells.append(chosen)
	# Unreachable -- see [method _attempt_claim_and_travel_to_job]'s own
	# identical trailing-return comment for why this line exists.
	return false


## [member bed_provider]'s candidate-list read (mocked boundary). Nil-safe,
## same rationale as [method _has_available_job].
func _get_unowned_bed_cells() -> Array[Vector3i]:
	if bed_provider == null:
		return []
	@warning_ignore("unsafe_method_access")
	return bed_provider.get_unowned_bed_cells()


## [member bed_provider]'s atomic-claim attempt (mocked boundary, GDD Rule
## 11/AC22, story 011's shared primitive PATTERN). Nil-safe, same rationale
## as [method _has_available_job]. A `true` return means [param cell] is now
## locked to this villager permanently (one bed = one owner, Rule 11); a
## `false` return means either another villager's same-pass call already won
## the race, or [param cell] is no longer eligible for any other
## provider-owned reason -- this method cannot distinguish those cases, by
## design, exactly like [method _claim_job].
func _claim_bed(cell: Vector3i) -> bool:
	if bed_provider == null:
		return false
	@warning_ignore("unsafe_method_access")
	return bed_provider.claim_bed(cell, villager_id)


## [member bed_provider]'s shelter-classification read (GDD Core Rule 4 --
## the `bed_sheltered`/`bed_unsheltered` source-enum split, fed by Build
## Validation's own shelter classification on the real provider). Nil-safe:
## an unwired provider answers the conservative, never-inflated default
## (`false`, unsheltered) -- recovery is never accidentally reported at the
## FULL ×1.0 rate for a bed this villager cannot actually confirm is
## sheltered.
func _is_bed_sheltered(bed_cell: Vector3i) -> bool:
	if bed_provider == null:
		return false
	@warning_ignore("unsafe_method_access")
	return bed_provider.is_bed_sheltered(bed_cell)


## Sleep-recovery entry report (GDD Core Rule 10: "discrete `start_recovery`
## call... never a per-tick push"). Nil-safe, same rationale as [method
## _has_urgent_need] -- an unwired [member needs_provider] simply never
## reports (this villager still sleeps and still wakes on its own, via
## [method _tick_sleeping]'s own nil-safe [method _is_need_recovering]
## default; see that method's own doc comment for why that default is safe).
func _start_sleep_recovery(source_enum: NeedsMood.RecoverySource) -> void:
	if needs_provider == null:
		return
	@warning_ignore("unsafe_method_access")
	needs_provider.start_recovery(villager_id, SLEEP_NEED_NAME, source_enum)


## Sleep-recovery INTERRUPTION report (GDD Edge Case 5, Core Rule 10's
## "credits zero recovery for the removal tick") -- called ONLY from [method
## _on_furniture_revoked] when this villager was actually sleeping in the
## just-revoked bed; natural wake ([method _wake_from_sleep]) never calls
## this (see that method's own doc comment for why: [method
## NeedsMood._pass_f2_recovery] already transitions Recovering -> Satisfied
## on its own once the wake threshold is crossed, with no external
## `stop_recovery` call required -- that call is reserved for genuine
## interruption/revocation, per [method NeedsMood.stop_recovery]'s own doc
## comment). Nil-safe, same rationale as [method _start_sleep_recovery].
func _stop_sleep_recovery(reason: StringName) -> void:
	if needs_provider == null:
		return
	@warning_ignore("unsafe_method_access")
	needs_provider.stop_recovery(villager_id, SLEEP_NEED_NAME, reason)


## The "still asleep, has the need recovered enough to wake" poll (GDD Rule
## 13/AC25: "sleeping ends when the need is restored above its wake
## threshold... re-enters the decision loop" -- Core Rule 3's own "state is
## truth, the event is a latency hint" discipline: this is a POLL, never a
## `need_satisfied` signal listener, so the crown story's own poll-not-event
## variant (needs-mood-010) needs no special casing here at all). Delegates
## to [member needs_provider]'s own `get_need_state` -- the EXACT, already
## real, already-implemented `func get_need_state(villager_id: int, need:
## StringName) -> NeedsMood.NeedState` method every real [NeedsMood] instance
## exposes (not yet promoted to `architecture.md`'s curated API Boundaries
## block per that method's own doc comment, but genuinely callable today) --
## so a REAL [NeedsMood] instance assigned as [member needs_provider] in a
## future production-wiring story works against this call with ZERO changes
## needed on the Needs & Mood side. Nil-safe default `true` (still
## recovering, i.e. "stay asleep"): by construction this is only ever
## consulted while [member _pursued_activity] == `NEED` and [member _state]
## == `SLEEPING`, which itself only happens after [method _has_urgent_need]
## answered `true` at commit time -- meaning [member needs_provider] was
## non-null then, so a `null` reading here would only ever occur if the
## dependency were unwired MID-sleep, or for a hand-constructed test fixture
## that pokes `State.SLEEPING` directly with no provider at all (e.g. the
## Unstuck Watchdog's own AC32 fixtures, which drive many ticks with a
## villager parked in `SLEEPING` and require it to stay there). With no
## information available, this defaults conservatively to "no change" rather
## than inventing an unearned wake -- mirrors this class's other "unknown
## defaults never assume progress happened" nil-safety bias (e.g. [method
## _has_urgent_need]'s own `false` default never assumes an urgent need
## either).
func _is_need_recovering() -> bool:
	if needs_provider == null:
		return true
	@warning_ignore("unsafe_method_access")
	return needs_provider.get_need_state(villager_id, SLEEP_NEED_NAME) == NeedsMood.NeedState.RECOVERING


## Bed-sleep entry (Story villager-ai-018, AC22/AC23): called ONLY from
## [method _complete_travel_arrival] when [param arrival_state] was
## `SLEEPING` -- i.e. travel just arrived at a bed cell (owned-existing or
## just-claimed, both funnel through [method start_traveling] before this
## ever runs). Samples [member bed_provider]'s CURRENT shelter classification
## at THIS moment (arrival), never a value captured earlier at commit/claim
## time -- travel can span multiple ticks, and this is this story's own
## scope's single [method _start_sleep_recovery] report; a LATER shelter
## change while already Recovering is [NeedsMood]'s own subscription to
## Build Validation's `shelter_status_changed` (story needs-mood-004's
## scope, not this one -- Villager AI is never involved in that re-rating).
func _enter_bed_sleep(bed_cell: Vector3i) -> void:
	_state = State.SLEEPING
	_sleeping_in_bed_cell = bed_cell
	var source: NeedsMood.RecoverySource = (
		NeedsMood.RecoverySource.BED_SHELTERED
		if _is_bed_sheltered(bed_cell)
		else NeedsMood.RecoverySource.BED_UNSHELTERED
	)
	_start_sleep_recovery(source)


## Ground-sleep entry (Story villager-ai-018, AC24, GDD Rule 12/Edge Case 1's
## "for a bed — fall back to ground sleep"): sleeps immediately at [member
## current_cell], no travel involved -- called from [method _commit_to_sleep]
## (no bed owned and none claimable, or an unwired [member nav_graph]) and
## from [method _abandon_travel]'s `NEED` branch (an owned bed became
## unreachable, either at initial [method start_traveling] or via a
## mid-travel re-path failure, Edge Case 1). [param source_enum] carries the
## caller's already-determined widened enum -- this method makes no
## ground/bed-reachability DECISION of its own, it only enters the state and
## reports it.
func _start_ground_sleep(source_enum: NeedsMood.RecoverySource) -> void:
	_state = State.SLEEPING
	_sleeping_in_bed_cell = null
	_start_sleep_recovery(source_enum)


## Natural wake (Story villager-ai-018, AC25, GDD Rule 13): re-enters
## Deciding via the SAME [method request_deciding_pass] every other
## eligibility trigger uses -- no bonus, unbudgeted immediate decide (mirrors
## [method _perform_watchdog_rescue]'s own identical reasoning). Deliberately
## does NOT call [method _stop_sleep_recovery] -- see that method's own doc
## comment for why natural completion needs no interruption report.
func _wake_from_sleep() -> void:
	_sleeping_in_bed_cell = null
	_pursued_activity = PursuedActivity.NONE
	_clear_travel_state()
	_state = State.DECIDING
	request_deciding_pass()


## Sleeping-state tick body (Story villager-ai-018; previously a stub --
## "later needs/sleep story"). A single poll per tick: once the need is no
## longer [constant NeedsMood.NeedState.RECOVERING] (restored above the wake
## threshold, [method _is_need_recovering] answers `false`), wake. Runs
## unconditionally every tick this villager is Sleeping -- never gated by
## [member scheduler]'s Deciding-pass budget (that budget caps expensive F2
## pathfind-bearing Deciding passes, GDD Rule 2; this is a cheap O(1) state
## poll, not a Deciding pass).
func _tick_sleeping() -> void:
	if not _is_need_recovering():
		_wake_from_sleep()


## [signal furniture_revoked]-shaped handler (Story villager-ai-018, GDD Edge
## Case 5/6, [TR-villager-ai-behavior-084]/085) -- connected in [method setup]
## only when [member bed_provider] is wired (see that method's own doc
## comment). Every connected villager receives every emission and
## self-filters by [param revoked_villager_id] (`docs/architecture/
## architecture.md`'s signal table: "targeted, per-owner" over a shared
## broadcast signal). A cell that is not this villager's OWNED bed is a
## no-op -- this handler never reacts to another villager's furniture.
##
## AC27 (Edge Case 6, "owned but unoccupied"): ownership dissolves silently
## -- no wake reaction, no [method _stop_sleep_recovery] call (nothing was
## being recovered against this bed), matching the GDD's own wording exactly.
## The villager claims a new bed at its own next urgent-sleep Deciding pass,
## which needs no special handling here: [member _has_owned_bed] is simply
## `false` again by the time that pass runs.
##
## AC26 (Edge Case 5, "removed while the villager sleeps in it"): detected by
## [member _sleeping_in_bed_cell] equalling [param furniture_cell] -- NOT by
## [member _state] alone, since a ground-sleeping villager (owning this SAME
## bed cell but not physically in it, GDD Rule 12's `ground_bed_unreachable`
## case) must NOT wake/react here (that would wrongly fire AC26's reaction
## for AC27's own silent-dissolve case). Wakes immediately, calls [method
## _stop_sleep_recovery] (credits zero recovery for the removal tick, Core
## Rule 10), and re-enters Deciding -- the NEXT Deciding pass naturally
## re-attempts a bed claim or falls back to ground sleep (GDD Edge Case 5's
## own "typically resuming... or claiming another free bed"), needing no
## special-cased target-selection here.
func _on_furniture_revoked(revoked_villager_id: int, furniture_cell: Vector3i) -> void:
	if revoked_villager_id != villager_id:
		return
	if not _has_owned_bed or furniture_cell != _owned_bed_cell:
		return
	var was_sleeping_in_this_bed: bool = (
		_sleeping_in_bed_cell != null and _sleeping_in_bed_cell == furniture_cell
	)
	_has_owned_bed = false
	_owned_bed_cell = Vector3i.ZERO
	if not was_sleeping_in_this_bed:
		return
	_sleeping_in_bed_cell = null
	_stop_sleep_recovery(&"bed_revoked")
	_pursued_activity = PursuedActivity.NONE
	_clear_travel_state()
	_state = State.DECIDING
	request_deciding_pass()


## Begins Traveling toward [param target_cell], entering `State.TRAVELING`
## and transitioning to [param arrival_state] once [param target_cell] is
## reached (Story villager-ai-009; GDD "Traveling" state-table entry:
## "Activity chosen with a distant target"). The caller -- a future story's
## own target-selection logic (010's F2 job site, 018's bed cell) -- decides
## BOTH the target and what state arrival transitions into; this method
## itself never reasons about job/bed/wander semantics -- only [member
## _pursued_activity] (already set by whichever Deciding-pass tier committed
## to this activity, story 006) does, later, if travel must abandon (see
## [method _abandon_travel]).
##
## Acquires the path via [member nav_graph]'s shared [method
## VillagerNavGraph.find_path] from [member current_cell] -- NEVER from
## [member _visual_position]/[member _intra_tick_progress] (Control
## Manifest: occupancy/logic queries always read the discrete cell). Three
## outcomes, per [method VillagerNavGraph.find_path]'s own documented return
## shape:
## - Empty path (unreachable, or [member current_cell] itself isn't
##   currently a graph point) -- [method _abandon_travel] fires immediately;
##   this villager never enters `State.TRAVELING` at all. Returns `false`.
## - A single-cell path ([param target_cell] == [member current_cell]
##   already, GDD F1's "0 is valid... immediate arrival") --
##   [method _complete_travel_arrival] fires immediately, same call, no tick
##   needed. Returns `true`.
## - A multi-cell path -- stores the path (minus the already-occupied first
##   cell) as [member _travel_remaining_path], begins the first step
##   ([member _from_cell]/[member _to_cell]), resets
##   [member _intra_tick_progress], and enters `State.TRAVELING`. Returns
##   `true`.
func start_traveling(target_cell: Vector3i, arrival_state: State) -> bool:
	assert(nav_graph != null, "VillagerAi.nav_graph not wired -- required before start_traveling()")
	var path: Array[Vector3i] = nav_graph.find_path(current_cell, target_cell)
	if path.is_empty():
		# Story villager-ai-011: [member _travel_target_cell] must be set
		# BEFORE [method _abandon_travel] fires here -- that method's WORK
		# branch reports/cooldowns against it (Rule 6/AC9/AC10), and this is
		# the one call site where it would otherwise still hold a stale
		# leftover value (the normal multi-cell assignment below never runs
		# on this early-return path).
		_travel_target_cell = target_cell
		_abandon_travel()
		return false
	if path.size() == 1:
		# Story villager-ai-018: [member _travel_target_cell] must be set
		# BEFORE [method _complete_travel_arrival] fires here too -- that
		# method's own `SLEEPING` branch ([method _enter_bed_sleep]) reads it
		# to learn WHICH cell was just arrived at, and this early-return path
		# (immediate arrival, `target_cell == current_cell` by construction)
		# never runs the normal multi-cell assignment below that would
		# otherwise set it. Mirrors the empty-path branch's own identical
		# "must be set before the callee reads it" precedent above.
		_travel_target_cell = target_cell
		_complete_travel_arrival(arrival_state)
		return true
	_travel_target_cell = target_cell
	_travel_arrival_state = arrival_state
	var remaining: Array[Vector3i] = path.slice(1)
	_travel_remaining_path = remaining
	_from_cell = current_cell
	_to_cell = _travel_remaining_path[0]
	_intra_tick_progress = 0.0
	_state = State.TRAVELING
	return true


## Traveling-state tick body (Story villager-ai-009; GDD "request next step
## at tick boundaries"). Called from [method _tick_state], which itself
## runs AFTER [method _on_tick]'s own arrival-crediting assignment
## (`current_cell = _to_cell` when [method _travel_complete] was true) THIS
## SAME tick -- so by the time this runs, [member current_cell] already
## reflects a just-completed step, if one completed this tick.
##
## A no-op while still mid-step ([member current_cell] still equals
## [member _from_cell], not yet [member _to_cell]) -- nothing to advance
## yet; [method _process]/[method advance_travel_progress] handle continuous
## progress every frame, independently of this tick-boundary function.
##
## On arrival at the current step's destination: pops the just-arrived cell
## off [member _travel_remaining_path] (its front always equals
## [member _to_cell] by construction, see that field's own doc comment). An
## empty remainder means the FINAL destination was just reached -- [method
## _complete_travel_arrival] fires. Otherwise begins the next step from the
## newly-arrived [member current_cell] toward the new front of
## [member _travel_remaining_path], resetting [member _intra_tick_progress]
## to `0.0`.
##
## Defensive branch: reachable only if `State.TRAVELING` was entered without
## going through [method start_traveling] (e.g. a hand-constructed test
## fixture, or a freshly-constructed villager whose [member current_cell]/
## [member _to_cell] both default to `Vector3i.ZERO` and therefore compare
## equal trivially -- `config_and_scaffold_test.gd`'s own dispatch-structure
## test does exactly this) -- [member _travel_remaining_path] already empty
## at entry means there was never a real step to credit arrival for, so this
## is a harmless, state-PRESERVING no-op, never a `pop_front()` against an
## empty array and never a call into [method _complete_travel_arrival] (a
## genuine arrival is ONLY ever detected after popping the just-arrived cell
## below, never before).
func _tick_traveling() -> void:
	if current_cell != _to_cell:
		return
	if _travel_remaining_path.is_empty():
		return
	_travel_remaining_path.pop_front()
	if _travel_remaining_path.is_empty():
		_complete_travel_arrival(_travel_arrival_state)
		return
	_from_cell = current_cell
	_to_cell = _travel_remaining_path[0]
	_intra_tick_progress = 0.0


## Successful-arrival completion (Story villager-ai-009; GDD "arrival on
## site transitions to the next state (Working/Sleeping/etc.)"): clears all
## travel bookkeeping ([method _clear_travel_state]) and transitions
## [member _state] to [param arrival_state] -- the actual per-state
## behaviour (work-progress accrual, sleep recovery) lived as stories
## 012/018's own stub bodies. Story villager-ai-018 (this revision) adds the
## ONE branch: arriving into `State.SLEEPING` means arriving at a BED
## specifically (the only [method start_traveling] caller that ever passes
## `SLEEPING` is this story's own [method _commit_to_sleep]/[method
## _abandon_travel] machinery) -- [method _enter_bed_sleep] needs to know
## WHICH bed cell was just reached, so this method captures [member
## _travel_target_cell] BEFORE [method _clear_travel_state] runs (that
## method does not itself touch [member _travel_target_cell], but capturing
## it first keeps this method's own control flow independent of that detail).
## Every OTHER [param arrival_state] (Working, Wandering, ...) is completely
## unaffected -- one added branch, zero changed lines below it.
func _complete_travel_arrival(arrival_state: State) -> void:
	var arrived_cell: Vector3i = _travel_target_cell
	_clear_travel_state()
	if arrival_state == State.SLEEPING:
		_enter_bed_sleep(arrived_cell)
		return
	_state = arrival_state


## Graceful travel abandonment (Story villager-ai-009, this story's AC19 --
## "exits to Deciding and re-selects... never keeps traveling toward a dead
## target"). Dispatches GDD Edge Case 1's per-target fallback by [member
## _pursued_activity]:
## - `WORK`: releases the held claim via the already-existing [method
##   _release_job_claim], GDD Rule 6's "releases the claim, and tries the
##   next-nearest job" -- unchanged since story villager-ai-011.
## - `NEED` (Story villager-ai-018, this revision): GDD Edge Case 1's own
##   "for a bed — fall back to ground sleep (Rule 12)". By construction this
##   branch is reached ONLY while traveling toward a bed ([method
##   _commit_to_sleep] never calls [method start_traveling] under `NEED` for
##   any other target), and bed CLAIMING always happens before travel starts
##   (mirrors job-claim-before-travel) -- so [member _has_owned_bed] is
##   ALWAYS `true` here, meaning the correct widened source enum is always
##   `ground_bed_unreachable` (AC24's second half), never
##   `ground_no_bed_owned` (that case is [method _commit_to_sleep]'s own
##   direct fallback, never routed through this method). Deliberately does
##   NOT reset [member _pursued_activity] to `NONE` and does NOT re-enter
##   Deciding -- the villager is still pursuing the SAME need, now via ground
##   sleep instead of bed travel; forcing a Deciding re-entry here would just
##   immediately re-commit to the identical ground-sleep outcome one tick
##   later, a pointless round trip.
## - `NONE` (wander-reselection, Story villager-ai-019's own future scope):
##   this story's minimal, safe default remains "abandon and re-decide,"
##   unchanged.
func _abandon_travel() -> void:
	if _pursued_activity == PursuedActivity.WORK:
		# Story villager-ai-011 (Rule 6/AC9): release BEFORE report -- a real
		# [ConstructionJobQueue.report_unreachable] only finds [param cell]
		# via its own eligibility scan, which requires PLANNED state;
		# releasing first (UNDER_CONSTRUCTION -> PLANNED) is what makes the
		# SAME cell eligible again for that scan to find and flag. Reversing
		# this order would make [method _report_job_unreachable] a silent
		# no-op against the real queue. AC10's per-cell retry cooldown is
		# recorded here too -- this is the ONE place a WORK-pursuing
		# villager's own pathing failure to a claimed job is detected.
		_release_job_claim()
		_report_job_unreachable(_travel_target_cell)
		_unreachable_retry_after_tick[_travel_target_cell] = _tick_count + config.unreachable_retry_ticks
		_pursued_activity = PursuedActivity.NONE
		_clear_travel_state()
		_state = State.DECIDING
		request_deciding_pass()
		return
	if _pursued_activity == PursuedActivity.NEED:
		_clear_travel_state()
		_start_ground_sleep(NeedsMood.RecoverySource.GROUND_BED_UNREACHABLE)
		return
	_pursued_activity = PursuedActivity.NONE
	_clear_travel_state()
	_state = State.DECIDING
	request_deciding_pass()


## Shared travel-bookkeeping reset (Story villager-ai-009) -- used by both
## [method _complete_travel_arrival] (successful arrival) and [method
## _abandon_travel] (graceful abandonment). Empties [member
## _travel_remaining_path] and collapses [member _from_cell]/
## [member _to_cell] back to [member current_cell] (so [method is_moving]
## reports `false`, matching every other stationary state's own invariant),
## resetting [member _intra_tick_progress] to `0.0`.
func _clear_travel_state() -> void:
	_travel_remaining_path = []
	_from_cell = current_cell
	_to_cell = current_cell
	_intra_tick_progress = 0.0


## Working-state tick body (Story villager-ai-012; GDD Rule 5/[TR-villager-
## ai-behavior-054], Edge Case 4/[TR-villager-ai-behavior-083]). This class
## owns NO progress-crediting logic of its own -- [ConstructionTickLoop]'s
## own [signal TimeTickSystem.tick] handler (gated on this villager's REAL
## on-site position via [VillagerOnSiteGate]'s composed occupancy predicate,
## see that class's own doc comment) is the SOLE place a tick actually gets
## credited (AC12/AC13). This method's own job is purely OBSERVATIONAL: read
## [member _claimed_blueprint_cell]'s CURRENT [member BlueprintCell.state] --
## the SAME shared reference [ConstructionTickLoop] mutates directly -- and
## react to whichever of the three outcomes it now holds:
## - [constant BlueprintCell.MicroState.BUILT]: the job completed -- [method
##   _complete_claimed_job] (AC40: "the job is removed from the real
##   queue... villager re-enters Deciding").
## - [constant BlueprintCell.MicroState.UNDER_CONSTRUCTION]: still in
##   progress -- a no-op; nothing for this method to do while
##   [ConstructionTickLoop] keeps crediting (or deferring, per Rule 5/
##   Building Edge Case 6/this story's AC40b) on its own schedule.
## - Anything else ([constant BlueprintCell.MicroState.PLANNED] -- released
##   back by an external revocation, or [constant
##   BlueprintCell.MicroState.CANCELED] -- a project-level cancel mid-work):
##   the job was revoked out from under this villager (AC33/Edge Case 4) --
##   [method _abandon_claimed_job] (no failure reaction, clean re-decide;
##   bookkeeping was already cleared by the revocation itself, per this
##   story's own Implementation Notes, so this branch never calls [method
##   _release_job_claim]/[method _report_job_unreachable] again).
## A `null` [member _claimed_blueprint_cell] (defensive -- should not occur
## by construction, since [member _state] only ever reaches `WORKING` via a
## successful claim that sets this field first) is treated identically to
## the revoked case -- never a crash.
func _tick_working() -> void:
	if _claimed_blueprint_cell == null:
		_abandon_claimed_job()
		return
	match _claimed_blueprint_cell.state:
		BlueprintCell.MicroState.BUILT:
			_complete_claimed_job()
		BlueprintCell.MicroState.UNDER_CONSTRUCTION:
			pass
		_:
			_abandon_claimed_job()


## Successful job completion (Story villager-ai-012, AC40's final stage):
## clears this villager's own claim bookkeeping via [method
## _release_job_claim] -- [ConstructionTickLoop]'s own completion write does
## NOT clean up [ConstructionJobQueue]'s `_claims_by_villager` entry (that
## class has no concept of [ConstructionJobQueue] at all, see its own doc
## comment), so this villager must release its OWN claim explicitly here, or
## a future claim attempt would wrongly find this villager still "holding a
## claim" -- before re-entering Deciding.
##
## Story villager-ai-024 addition: [method _relocate_if_marooned] runs BEFORE
## [method request_deciding_pass] -- if this completion left the villager
## standing somewhere the nav graph cannot reach FROM anywhere else (a wall
## column's topmost layer, once finished, is exactly this), it is relocated
## to the nearest reachable standable cell right here, so the very next
## Deciding pass never has to reason about an unreachable starting position.
func _complete_claimed_job() -> void:
	_release_job_claim()
	_pursued_activity = PursuedActivity.NONE
	_state = State.DECIDING
	_relocate_if_marooned()
	request_deciding_pass()


## Revoked-mid-work handling (Story villager-ai-012, AC33/Edge Case 4): no
## failure reaction, clean re-decide. Deliberately does NOT call [method
## _release_job_claim]/[method _report_job_unreachable] -- the revocation
## itself already cleared this villager's claim bookkeeping (this story's
## own Implementation Notes: "Job revocation clears claim bookkeeping via
## the revocation itself"); calling either again here would be, at best,
## redundant, and at worst would wrongly report a legitimate revocation as
## an unreachable-job PATHING failure (Rule 6), which it is not.
##
## Story villager-ai-024 addition: [method _relocate_if_marooned] runs here
## too, for the SAME reason as [method _complete_claimed_job]'s own identical
## addition -- a revocation can leave this villager marooned exactly as a
## completion can.
func _abandon_claimed_job() -> void:
	_claimed_blueprint_cell = null
	_pursued_activity = PursuedActivity.NONE
	_state = State.DECIDING
	_relocate_if_marooned()
	request_deciding_pass()


## Breather-state tick body -- stub (later life-texture story).
func _tick_breather() -> void:
	pass


## Wandering-state tick body (Story villager-ai-019; GDD F3/Rule 7c). Counts
## up toward [member VillagerAIConfig.wander_interval] independently of
## [member _ticks_since_last_decision] (see [member
## _ticks_since_last_wander_pick]'s own doc comment) and, once the interval
## elapses, resets the counter and runs [method _perform_wander_pick] --
## exactly [method _check_decision_interval_trigger]'s own "count up, fire
## on reaching the knob, reset" shape, applied to a different cadence and a
## different action. A freshly-`State.WANDERING` villager (tier 3's own
## `_state = State.WANDERING` assignment, [method _tick_deciding], never
## edited by this story) starts this counter at its literal field default
## (`0`), so the FIRST pick fires `wander_interval` ticks after entering
## Wandering, not immediately -- this story's own minimal, GDD-silent-on-entry
## interpretation (mirrors every other periodic-cadence counter in this
## class, none of which force an immediate first fire on state entry either).
func _tick_wandering() -> void:
	_ticks_since_last_wander_pick += 1
	if _ticks_since_last_wander_pick < config.wander_interval:
		return
	_ticks_since_last_wander_pick = 0
	_perform_wander_pick()


## The F3/Rule 7c pick itself (Story villager-ai-019), called once every
## `wander_interval` ticks by [method _tick_wandering]. Recomputes the F3
## flood-fill FRESH from [member current_cell] every pick ([VillagerWanderSelector.
## flood_fill] -- never a cached set from a prior pick, since the world may
## have changed and the villager has certainly moved since the last one),
## then draws a micro-behavior via [method _get_wander_rng] ([VillagerWanderSelector.
## select_micro_behavior], bed-drift eligible iff [member _has_owned_bed]) and
## resolves it to a target cell:
## - `BED_DRIFT`: [VillagerWanderSelector.select_bed_drift_target] against
##   [member _owned_bed_cell] (only ever drawable when a bed IS owned, see
##   that selector's own eligibility gate).
## - `WALK`: [VillagerWanderSelector.select_wander_target] -- a further
##   uniform draw from the SAME flood-filled set, same `rng` stream.
## - `PAUSE_LOOK`/`SIT`: no target selection at all -- these are stationary
##   by definition; `target` is left at [member current_cell].
##
## A resolved `target` equal to [member current_cell] (a stationary pick, OR
## a `WALK`/`BED_DRIFT` pick that degenerated to the current cell -- this
## story's AC31/Edge Case 8: the flood-fill returned only the current cell)
## is a pure no-op: [member _state] stays `State.WANDERING`, nothing paths
## anywhere, [method _tick_wandering]'s own counter simply re-fires next
## interval. Otherwise, [method start_traveling] is called with arrival state
## `State.WANDERING` -- the SAME travel/abandon/redirect machinery every
## other target-selection story already wired (see this class's own doc
## comment's villager-ai-019 paragraph for why this needs zero new
## abandon-handling code).
func _perform_wander_pick() -> void:
	var flood_cells: Array[Vector3i] = VillagerWanderSelector.flood_fill(
		self, current_cell, config.wander_radius
	)
	var rng: RandomNumberGenerator = _get_wander_rng()
	var behavior: VillagerWanderSelector.MicroBehavior = VillagerWanderSelector.select_micro_behavior(
		rng, _has_owned_bed
	)
	_last_micro_behavior = behavior
	var target: Vector3i = current_cell
	match behavior:
		VillagerWanderSelector.MicroBehavior.BED_DRIFT:
			target = VillagerWanderSelector.select_bed_drift_target(flood_cells, _owned_bed_cell)
		VillagerWanderSelector.MicroBehavior.WALK:
			target = VillagerWanderSelector.select_wander_target(flood_cells, rng)
		_:
			pass
	if target == current_cell:
		return
	start_traveling(target, State.WANDERING)


## Lazily-defaulted accessor for [member wander_rng] (Story villager-ai-019)
## -- see that field's own doc comment for the full DI/determinism contract.
## Constructs and seeds one, deterministically from [member villager_id],
## the first time this is ever called for a villager nobody wired a
## generator onto directly; a test (or a future population assembler) that
## assigns [member wander_rng] BEFORE this is ever called always wins --
## this branch never overwrites an already-present generator.
func _get_wander_rng() -> RandomNumberGenerator:
	if wander_rng == null:
		wander_rng = RandomNumberGenerator.new()
		wander_rng.seed = villager_id
	return wander_rng


# =============================================================================
# Story villager-ai-013 -- Nudge-aside vacate (F4 target selection)
# =============================================================================

## Nudge-aside vacate request entry point (Story villager-ai-013, GDD Rule 7
## / F4, [TR-villager-ai-behavior-056]/[TR-villager-ai-behavior-079]/
## [TR-villager-ai-behavior-034]). Called by [VillagerOnSiteGate] (Story
## villager-ai-012's own reserved seam, see that class's own doc comment)
## whenever a builder's on-site target cell is currently occupied by THIS
## villager -- "the builder requests a vacate," GDD Rule 7's own wording.
## [param requester_cell] is the requesting builder's own discrete
## [method get_current_cell] -- the point
## [VillagerNudgeAsideSelector.select_vacate_target] steps this villager AWAY
## from (F4: "the occupant steps AWAY from the requesting builder — never
## toward it").
##
## Eligible ONLY while `State.WANDERING` -- see this class's own doc
## comment's villager-ai-013 paragraph for the full "idle or wandering maps
## 1:1 onto this one state" rationale. Every OTHER state returns `false`
## immediately with ZERO side effects (no state read/write beyond the single
## comparison below) -- a `WORKING`/`SLEEPING` occupant's held claim is never
## touched (AC42: "the occupant's claim is never revoked"), and the builder's
## cell simply stays deferred exactly as [VillagerOnSiteGate]'s own
## occupancy predicate already enforces independently of this method's
## return value.
##
## Idempotent against repeated calls while already mid-vacate-step: the
## FIRST eligible call flips [member _state] to `State.TRAVELING` (via
## [method start_traveling] below) the SAME tick it fires (this story's own
## QA wording: "steps to the F4 target within one tick"); every SUBSEQUENT
## call during the same stuck episode (e.g. [VillagerOnSiteGate]'s predicate
## re-evaluating every tick while the cell stays occupied) finds
## `_state != WANDERING` and is a harmless no-op -- no re-selection, no
## redundant travel restart.
##
## Reuses [method start_traveling] wholesale (arrival state `WANDERING`, the
## SAME "resume Wandering after this walk" pattern [method
## _perform_wander_pick]'s own WALK/BED_DRIFT picks already establish) --
## every existing abandon/redirect/re-path mechanism (GDD Rule 10b, this
## class's own [method _abandon_travel] `NONE` branch) already covers a
## vacate step for free, with zero new travel machinery. [method
## start_traveling]'s own F1 step-interpolation ("a normal walking step at
## `move_speed`," never a teleport) is exactly the step semantics F4's own
## "no timing promise tied to tick length" wording requires
## ([TR-villager-ai-behavior-034]).
##
## Returns `true` iff a vacate step was actually initiated (eligible state
## AND [VillagerNudgeAsideSelector.select_vacate_target] found a candidate
## AND [method start_traveling] itself succeeded); `false` otherwise
## (ineligible state, or no adjacent standable cell -- GDD Rule 7's own "if
## no adjacent standable cell exists, the vacate request fails and the
## builder's cell stays deferred," which [VillagerOnSiteGate]'s own
## already-live occupancy predicate enforces on its own regardless of this
## return value; it exists for direct-call test assertions and future
## callers).
func request_vacate(requester_cell: Vector3i) -> bool:
	if _state != State.WANDERING:
		return false
	var target: Variant = VillagerNudgeAsideSelector.select_vacate_target(
		self, current_cell, requester_cell
	)
	if target == null:
		return false
	return start_traveling(target, State.WANDERING)


# =============================================================================
# Story villager-ai-015 -- Unstuck Watchdog (GDD Rule 15/15b/F5)
# =============================================================================

## Rule 15/F5's own "zero legal step from `current_cell`" predicate half.
## Reuses the SAME horizontal x vertical neighbor-candidate set
## [VillagerNavGraph.HORIZONTAL_FULL_OFFSETS]/[VillagerNavGraph.
## VERTICAL_STEP_OFFSETS] already establishes as this codebase's one
## neighbor-candidate convention (Story villager-ai-008's own patch-pass
## reuses the identical pair) -- never a second, locally re-derived neighbor
## set (Control Manifest: "never duplicate walkability rules or constants",
## extended here to the neighbor-candidate set every consumer of [method
## is_standable]/[method is_step_legal] walks). `true` iff ANY candidate
## neighbor is both standable and a legal step FROM [member current_cell] --
## population/occupancy is deliberately NOT considered here (GDD F5's own
## trigger formula names only standability/step-legality; occupancy against
## other villagers is exclusively [VillagerRescueTargetSearch]'s own
## RESCUE-TARGET eligibility filter, a distinct concern from "is this
## villager stuck").
func _has_any_legal_step_from_current_cell() -> bool:
	return _has_any_legal_step_from(current_cell)


## General twin of [method _has_any_legal_step_from_current_cell] -- the SAME
## check against an ARBITRARY [param from_cell], not only [member
## current_cell] (Story villager-ai-024 addition: [method
## _relocate_if_marooned]'s own candidate-usefulness filter needs to ask this
## about a rescue-search CANDIDATE cell, never the villager's own current
## position). Extracted rather than duplicated -- [method
## _has_any_legal_step_from_current_cell] is now a one-line delegation to
## this, byte-for-byte the same check it always was.
func _has_any_legal_step_from(from_cell: Vector3i) -> bool:
	for offset: Vector2i in VillagerNavGraph.HORIZONTAL_FULL_OFFSETS:
		for dy: int in VillagerNavGraph.VERTICAL_STEP_OFFSETS:
			var neighbor: Vector3i = from_cell + Vector3i(offset.x, dy, offset.y)
			if is_standable(neighbor) and is_step_legal(from_cell, neighbor):
				return true
	return false


## Rule 15/F5's OWN cell-standability half of the "stuck" predicate, split
## out as its own named query (fix for the M01 closure observation run's
## Scenario 1 finding, `production/qa/evidence/m01-closure-evidence-
## 20260726.md`): `true` iff [member current_cell] itself has become
## non-standable -- the exact signature of a self-seal completion (Rule
## 16/F6, [VillagerSealPreventionGate]'s own class doc comment point 1:
## "the villager ending up standing inside now-solid content"). Distinct
## from "walled in but my own cell is fine" (the OTHER half of [method
## _is_stuck_at_current_cell], see below) -- [method
## _update_unstuck_watchdog] treats the two halves differently: this one is
## rescue-eligible in EVERY state (see that method's own doc comment for
## why); the other stays strictly `TRAVELING`/`WORKING`-scoped, unchanged,
## per Rule 15/Edge Case 2/AC32.
func _is_self_sealed_at_current_cell() -> bool:
	return not is_standable(current_cell)


## Rule 15/F5's full "stuck" predicate: [member current_cell] fails
## standability, OR has zero legal step to any neighbor (GDD F5 Formulas:
## "`stuck_tick_count` increments... a Traveling/Working villager has zero
## legal step from `current_cell` OR `current_cell` fails the standability
## check"). Used both by [method _update_unstuck_watchdog]'s
## `TRAVELING`/`WORKING` counter and by [member _distressed]'s own
## all-states read (AC32) -- ONE predicate, not two independently-maintained
## copies. Delegates its own-cell half to [method
## _is_self_sealed_at_current_cell] rather than re-checking [method
## is_standable] inline a second time (this is a pure refactor of this
## method's OWN body -- its return value is byte-for-byte unchanged from
## before the M01 closure fix).
##
## **Story villager-ai-024 fix, second half.** [method
## climb_onto_self_sealed_cell] means a WORKING villager now routinely stands
## on a wall column's 3rd-and-higher layer -- a cell [VillagerNavGraph]
## structurally never connects to anything (see that method's own doc
## comment) -- for the ENTIRE duration it takes to build that layer, not just
## the instant of completion. Read literally, the "zero legal step" half of
## this predicate would count every one of those ticks as "stuck" too,
## accumulating toward an [member VillagerAIConfig.unstuck_watchdog_threshold_ticks]
## rescue that ABANDONS a job that is not stuck at all -- it is progressing
## completely normally, exactly like every job below layer 3 always has.
## [method _is_actively_building_on_own_claimed_site] exempts EXACTLY that
## one case (mirrors [VillagerSealPreventionGate]'s own self-seal
## exemption's reasoning: "the ordinary, common case... not a rare edge
## case," applied here to the no-legal-step half instead of the
## self-sealed half) -- a villager genuinely mid-progress on its OWN,
## currently-`UNDER_CONSTRUCTION` claimed cell has nowhere it NEEDS to step
## to; it is stationary and productive by design, not stranded. This
## exemption can only ever suppress the no-legal-step half, only while
## `State.WORKING`, only for a cell that is this SAME villager's own live
## claim -- self-seal detection above is completely unaffected (still
## unconditional, still fires in every state), `TRAVELING`'s no-legal-step
## check is completely unaffected (a genuinely stranded mid-route villager is
## exactly as stuck as before), and the instant the job completes or is
## revoked this exemption stops applying on its own (the claim is gone, or
## the cell is no longer `UNDER_CONSTRUCTION`) -- no separate reset needed.
func _is_stuck_at_current_cell() -> bool:
	if _is_self_sealed_at_current_cell():
		return true
	if _has_any_legal_step_from_current_cell():
		return false
	return not _is_actively_building_on_own_claimed_site()


## See [method _is_stuck_at_current_cell]'s own "Story villager-ai-024 fix,
## second half" doc comment paragraph. `true` iff this villager is `State.
## WORKING` on a [BlueprintCell] it currently holds the claim on
## ([member _claimed_blueprint_cell]), that cell's own address equals [member
## current_cell] (the ordinary on-site case every claimed job already
## requires, Rule 5), AND that cell's [member BlueprintCell.state] still
## reads [constant BlueprintCell.MicroState.UNDER_CONSTRUCTION] (genuinely
## still in progress -- a `BUILT` cell means this villager is now self-sealed
## instead, already covered by the FIRST half of [method
## _is_stuck_at_current_cell] above; a revoked/canceled cell means [method
## _tick_working] is about to abandon it next, at which point this exemption
## correctly stops applying).
func _is_actively_building_on_own_claimed_site() -> bool:
	return (
		_state == State.WORKING
		and _claimed_blueprint_cell != null
		and _claimed_blueprint_cell.cell == current_cell
		and _claimed_blueprint_cell.state == BlueprintCell.MicroState.UNDER_CONSTRUCTION
	)


## The Unstuck Watchdog's own per-tick entry point (Story villager-ai-015;
## GDD Rule 15/F5; ADR-0008/Control Manifest Feature Layer's "cheap
## O(villagers) per-tick check"), called from [method _on_tick] every tick
## for every villager -- see that method's own doc comment for exactly WHERE
## in tick ordering this runs and why.
##
## Every state updates [member _distressed] (AC32, Edge Case 2's complement:
## an Idle/Wandering/Sleeping/Breather villager with no legal step shows the
## distress cue and stays put, never rescued) -- and, as before, only
## `State.TRAVELING`/`State.WORKING` ever count a "walled in but my own cell
## is still standable" episode toward [member stuck_tick_count] (Rule 15's
## own explicit scope boundary, Edge Case 2/AC32's negative test, both
## UNCHANGED by this fix).
##
## **M01 closure fix** (`production/qa/evidence/m01-closure-evidence-
## 20260726.md` Scenario 1): a villager whose OWN [member current_cell] has
## become non-standable -- [method _is_self_sealed_at_current_cell] --
## remains rescue-eligible REGARDLESS of [member _state]. This is a
## narrowly-scoped exception to "only `TRAVELING`/`WORKING` count", not a
## general widening of Rule 15's rescue scope to Idle/Wandering/Sleeping/
## Breather (Edge Case 2's own "never teleported, stays put" guarantee for
## a merely WALLED-IN-but-standable villager in those states is completely
## untouched -- see [method _is_self_sealed_at_current_cell]'s own doc
## comment for the exact line this fix draws). It exists because Rule
## 16b/[VillagerSealPreventionGate]'s own class doc comment ALREADY promises
## this exact outcome ("the builder becomes sealed in by its own completed
## work, and the Unstuck Watchdog... rescues it on its normal schedule") --
## but [method _tick_working]'s own completion handling
## ([method _complete_claimed_job]) transitions `WORKING -> DECIDING` the
## SAME tick the self-seal first becomes true (GDD's own state table: "Cell
## Built" is an unconditional Working-exit trigger), and Rule 2's periodic
## `decision_interval` re-check (unrelated to this fix) can carry the
## villager on into `WANDERING` shortly after when no other job is
## reachable -- so a strictly `TRAVELING`/`WORKING`-scoped counter, as
## written before this fix, could accumulate at most ONE stuck tick before
## the villager left the counted states for good, structurally short of
## `unstuck_watchdog_threshold_ticks` (12 at production defaults) forever.
## Scoping the exception to "self-sealed" specifically (not "any villager
## with zero legal steps") is deliberate: a self-sealed cell is a
## comparatively rare, severe physical condition (the villager's own body
## literally overlaps solid content) that ONLY Rule 16's self-seal write
## can produce against a previously-standable cell; it is a strict subset
## of "stuck", never triggered by the ordinary "walled into a room by
## someone else's write while idling" case Edge Case 2 is about (that case
## always leaves [member current_cell] itself standable -- only the
## LEGAL-STEP half of [method _is_stuck_at_current_cell] fails there).
func _update_unstuck_watchdog() -> void:
	# Nil-safe against a villager fixture that has no [member voxel_world]
	# wired at all, or one wired but not yet given its own
	# [member VoxelWorldGrid.config] (several earlier stories' own tests
	# drive [method _on_tick] directly without either, since walkability
	# queries were never on THEIR call path before this story) -- mirrors
	# [member nav_graph]'s own "not every earlier story's test wires this"
	# nil-safe precedent, extended here to "not yet fully wired for
	# walkability queries": nothing to check yet is a harmless no-op, never
	# a crash. Every REAL production villager has both wired via [method
	# setup]'s own assert + the boot sequence's config wiring, so this guard
	# never masks anything in production.
	if voxel_world == null or voxel_world.config == null:
		return
	var stuck: bool = _is_stuck_at_current_cell()
	_distressed = stuck
	var rescue_eligible_now: bool = (
		_state == State.TRAVELING
		or _state == State.WORKING
		or _is_self_sealed_at_current_cell()
	)
	if not rescue_eligible_now:
		_reset_stuck_episode()
		return
	if not stuck:
		_reset_stuck_episode()
		return
	stuck_tick_count += 1
	if stuck_tick_count >= config.unstuck_watchdog_threshold_ticks:
		_attempt_watchdog_rescue()


## Shared "relief" reset (Story villager-ai-015) -- used by [method
## _update_unstuck_watchdog]'s own two relief paths (no longer
## Traveling/Working; still Traveling/Working but no longer stuck) AND by
## [method _perform_watchdog_rescue] (a successful rescue is relief too). A
## harmless no-op when [member stuck_tick_count] is already `0` and [member
## _search_failure_gate] already fresh -- [method
## RescueSearchFailureGate.reset_episode]'s own doc comment: "idempotent".
func _reset_stuck_episode() -> void:
	stuck_tick_count = 0
	_search_failure_gate.reset_episode()


## Rule 15's rescue attempt (Story villager-ai-015, AC51) -- called once
## [member stuck_tick_count] has reached [member VillagerAIConfig.
## unstuck_watchdog_threshold_ticks]. Delegates target selection entirely to
## the F5 BFS ([VillagerRescueTargetSearch.find_rescue_target], Story
## villager-ai-014) -- this method never re-derives an equivalent search of
## its own. A miss (search exhausted at `unstuck_rescue_max_radius`, GDD Edge
## Case 14) reports through [member _search_failure_gate]'s own
## once-per-episode gate and defers -- [member stuck_tick_count] is
## deliberately NOT reset here, so [method _update_unstuck_watchdog] keeps
## incrementing it and re-attempts this SAME search on every subsequent tick
## (Edge Case 14: "the search retries every tick until a cell is found"),
## with [member _search_failure_gate] guaranteeing [signal
## unstuck_search_failed] still fires only once across that whole retry
## run. A hit performs the actual rescue via [method
## _perform_watchdog_rescue].
func _attempt_watchdog_rescue() -> void:
	var other_cells: Array[Vector3i] = _get_other_villager_cells()
	var result: RescueSearchResult = VillagerRescueTargetSearch.find_rescue_target(
		current_cell,
		self,
		other_cells,
		config.unstuck_rescue_search_radius,
		config.unstuck_rescue_max_radius,
	)
	if not result.has_target():
		if _search_failure_gate.should_report_failure():
			unstuck_search_failed.emit()
		return
	_perform_watchdog_rescue(result.cell)


## The rescue itself (Story villager-ai-015, AC51/AC52; ADR-0009 slice
## propagation's second sanctioned discrete `current_cell` mutation). Order
## of operations, all within this single synchronous call (no tick spans
## mid-rescue):
## 1. Release any held job claim via the SAME [method _release_job_claim]
##    helper every OTHER claim-relinquishing path already funnels through
##    (AC52: "releases back to the queue exactly as Rule 6's unreachable-job
##    flow -- no double-release, no orphaned claim") -- ONLY when [member
##    _pursued_activity] is `WORK`; a `NEED`-pursuing villager (e.g. mid-travel
##    to a bed) holds no claim, so this is skipped entirely, exactly AC52's
##    "no claim-release side effect... bed ownership unaffected" half.
##    Deliberately does NOT also call [method _report_job_unreachable]/record
##    an unreachable-retry cooldown -- unlike Rule 6's own pathing-failure
##    flow, the claimed CELL itself was never unreachable here; this
##    villager was stuck, a distinct fact Rule 6's job-unreachable reporting
##    would mislabel (this story's own interpretation of AC52's "exactly as
##    Rule 6's unreachable-job flow" -- read as "reuses the same release
##    HELPER/no-double-release guarantee", not "replays every one of Rule
##    6's side effects").
## 2. Clears travel bookkeeping and sets [member current_cell] atomically to
##    [param rescue_cell], snapping [member _visual_position] to match via
##    the SAME [method VoxelWorldGrid.cell_to_world] conversion [method
##    _process] already uses -- NO lerp (ADR-0009: "the watchdog is the one
##    deliberate exception" to "never snap/teleport").
## 3. Resets the stuck episode ([method _reset_stuck_episode]) and [member
##    _distressed] -- relief.
## 4. Records telemetry: this villager's own [member _unstuck_count], plus
##    [member unstuck_telemetry]'s shared world total when wired (nil-safe,
##    see that field's own doc comment).
## 5. Emits [signal unstuck_rescued], transitions to `State.DECIDING`, and
##    re-enters the Deciding queue via the SAME [method request_deciding_pass]
##    every OTHER eligibility trigger uses -- see this class's own
##    villager-ai-015 doc-comment paragraph for why this is never a bonus,
##    unbudgeted immediate decide.
func _perform_watchdog_rescue(rescue_cell: Vector3i) -> void:
	if _pursued_activity == PursuedActivity.WORK:
		_release_job_claim()
	_pursued_activity = PursuedActivity.NONE
	_travel_remaining_path = []
	current_cell = rescue_cell
	_from_cell = rescue_cell
	_to_cell = rescue_cell
	_intra_tick_progress = 0.0
	_visual_position = VoxelWorldGrid.cell_to_world(rescue_cell)
	_reset_stuck_episode()
	_distressed = false
	_unstuck_count += 1
	if unstuck_telemetry != null:
		unstuck_telemetry.record_rescue(villager_id)
	_state = State.DECIDING
	unstuck_rescued.emit(rescue_cell)
	request_deciding_pass()


## [member population]'s nil-safe read (Story villager-ai-015). Nil-safe,
## same rationale as [method _has_urgent_need]/[method _has_available_job] --
## a villager with no population registry wired searches as though no other
## villager exists.
func _get_other_villager_cells() -> Array[Vector3i]:
	if population == null:
		return []
	@warning_ignore("unsafe_method_access")
	return population.get_other_villager_cells(villager_id)


# =============================================================================
# Story villager-ai-016 -- Seal Prevention (GDD Rule 16/F6, ADR-0009 slice
# propagation Sec.2b, [TR-villager-ai-behavior-101]/102/106/107)
# =============================================================================

## Seal-prevention trap predicate (GDD F6: `would_trap_builder`) -- true iff
## a write that makes [param written_cell] solid would leave THIS villager
## (at its own [member current_cell]) with zero legal steps to any standable
## neighbor, evaluated AS IF the write had already committed
## (Implementation Notes) without ever mutating the real [member voxel_world]
## (a genuine trial write would fire real signals -- nav-graph patching,
## repath filters -- for a change that might never actually commit, exactly
## the side-effect risk this predicate is designed to avoid). Reuses the
## SAME neighbor-candidate set [method _has_any_legal_step_from_current_cell]
## already establishes ([VillagerNavGraph.HORIZONTAL_FULL_OFFSETS]/[VillagerNavGraph.
## VERTICAL_STEP_OFFSETS]) and the SAME Rule 8/9 arithmetic [method
## is_standable]/[method is_step_legal] already define -- never a second,
## locally-derived neighbor set or a duplicated walkability formula (Control
## Manifest Feature Layer Forbidden). The private `_after_write` twins below
## are the ONLY new arithmetic this story adds: each mirrors its non-`_after_
## write` counterpart line-for-line, substituting exactly one thing --
## treating [param written_cell] as solid/occupied regardless of what
## [member voxel_world] currently reports there -- mirroring this codebase's
## own established "extract a parameterized twin rather than duplicate"
## precedent ([method classify_step_length_cells]'s own extraction, story
## villager-ai-007).
##
## Checked against [member current_cell] itself first (mirrors [method
## _is_stuck_at_current_cell]'s own "not standable OR no legal step"
## structure exactly) -- a write that removes the builder's OWN standing
## clearance (e.g. directly overhead) counts as trapping just as surely as
## sealing every exit does.
##
## [VillagerSealPreventionGate] is this predicate's real caller (wired into
## [ConstructionTickLoop]'s completion write path via [ConstructionJobQueue]
## behind [method ConstructionTickLoop.set_seal_prevention_predicate]) --
## this method itself has no Building System awareness whatsoever, exactly
## like [method is_standable]/[method is_step_legal].
##
## Story `building-034` (ADR-0007 §1b, TD ruling D1 -- "the correction the
## story missed"): the escape-route search now ALSO tries the same-column
## neighbors directly above/below [member current_cell] -- a scaffold-to-
## scaffold vertical step is a legal escape route since §2a, and a villager
## standing ON a scaffold cell has air beneath it, so leaving this search
## purely horizontal would silently under-count real escape routes once
## scaffolding lands. [constant VillagerNavGraph.VERTICAL_SAME_COLUMN_OFFSETS]
## is the same constant [VillagerNavGraph]'s own patch pass reuses -- never a
## second, independently-declared offset pair.
func would_trap_builder(written_cell: Vector3i) -> bool:
	if not _is_standable_after_write(current_cell, written_cell):
		return true
	for offset: Vector2i in VillagerNavGraph.HORIZONTAL_FULL_OFFSETS:
		for dy: int in VillagerNavGraph.VERTICAL_STEP_OFFSETS:
			var neighbor: Vector3i = current_cell + Vector3i(offset.x, dy, offset.y)
			if (
				_is_standable_after_write(neighbor, written_cell)
				and _is_step_legal_after_write(current_cell, neighbor, written_cell)
			):
				return false
	# SCAFFOLD-ONLY, and the guard is load-bearing. A same-column escape exists
	# solely as the §2a scaffold-to-scaffold edge. Without this check the loop
	# also accepts a vertical move where NEITHER cell is scaffold — because the
	# step predicate deliberately falls through to pre-amendment behaviour
	# there — and that reports an escape route the villager does not actually
	# have. The observable cost was concrete: seal prevention started allowing
	# writes it used to refuse, and one of them sealed off a corner column, so
	# villager-ai-024's regression test fell from 30/30 to 27/30 with all three
	# cells of that column left PLANNED and unclaimed.
	if _has_scaffold(current_cell):
		for dy: int in VillagerNavGraph.VERTICAL_SAME_COLUMN_OFFSETS:
			var neighbor: Vector3i = current_cell + Vector3i(0, dy, 0)
			if not _has_scaffold(neighbor):
				continue
			if (
				_is_standable_after_write(neighbor, written_cell)
				and _is_step_legal_after_write(current_cell, neighbor, written_cell)
			):
				return false
	return true


## [method is_standable]'s "as if written" twin -- see [method
## would_trap_builder]'s own doc comment. Identical control flow to [method
## is_standable]; only the solid-below/clearance-column reads are routed
## through the override-aware [method _is_solid_after_write]/[method
## _is_passable_after_write] below instead of [method _is_solid]/[method
## _is_passable] directly.
##
## **Story `building-034` (ADR-0007 §1b, MUST receive the scaffold source):**
## a villager standing on a scaffold cell has air beneath it -- a
## scaffold-blind version of this twin would report it unstandable and
## [method would_trap_builder] would return `true` for essentially every
## write that villager evaluates, firing the self-seal exemption
## continuously. [member scaffold_registry] is consulted via [method
## _has_scaffold] exactly like the non-`_after_write` [method
## VillagerWalkabilityRules.is_standable] -- the hypothetical write never
## changes real scaffold occupancy, so this read is never routed through an
## "as if written" scaffold twin of its own; only solidity/passability are
## hypothetical here.
func _is_standable_after_write(cell: Vector3i, written_cell: Vector3i) -> bool:
	var solid_below: bool = _is_solid_after_write(cell + Vector3i(0, -1, 0), written_cell)
	if not solid_below and not _has_scaffold(cell):
		return false
	for offset in range(VILLAGER_CLEARANCE):
		if not _is_passable_after_write(cell + Vector3i(0, offset, 0), written_cell):
			return false
	return true


## [method is_step_legal]'s "as if written" twin -- see [method
## would_trap_builder]'s own doc comment. Identical control flow to [method
## is_step_legal]; only the diagonal flanker standability reads are routed
## through [method _is_standable_after_write] instead of [method
## is_standable] directly.
##
## Story `building-034` (ADR-0007 §2a clause 2, mirrored here for the
## `_after_write` shape): a same-column pair is legal only if BOTH endpoints
## are (really -- never hypothetically) scaffold cells.
func _is_step_legal_after_write(from_cell: Vector3i, to_cell: Vector3i, written_cell: Vector3i) -> bool:
	if absi(to_cell.y - from_cell.y) > MAX_STEP_HEIGHT:
		return false
	var dx: int = to_cell.x - from_cell.x
	var dz: int = to_cell.z - from_cell.z
	if dx == 0 and dz == 0:
		var from_is_scaffold: bool = _has_scaffold(from_cell)
		var to_is_scaffold: bool = _has_scaffold(to_cell)
		if from_is_scaffold and to_is_scaffold:
			return true  # §2a: the one new edge class.
		if from_is_scaffold or to_is_scaffold:
			return false  # Never climb between ordinary ground and scaffolding.
		# NEITHER endpoint is scaffold: fall through to the pre-amendment rules.
		# Same correction as VillagerWalkabilityRules.is_step_legal — the gate
		# was copied here verbatim, so it carried the same defect: it flipped
		# this predicate from true to false for every ordinary same-column
		# pair, and these _after_write twins feed would_trap_builder. Refusing
		# them made the builder believe far more writes would trap it than
		# actually do.
	if dx != 0 and dz != 0:
		var flanker_a := Vector3i(to_cell.x, from_cell.y, from_cell.z)
		var flanker_b := Vector3i(from_cell.x, from_cell.y, to_cell.z)
		if (
			not _is_standable_after_write(flanker_a, written_cell)
			or not _is_standable_after_write(flanker_b, written_cell)
		):
			return false
	return true


## The O(1) duck-typed scaffold-membership read [member scaffold_registry]
## exposes -- see that field's own doc comment. `null` is structurally
## "never scaffold," mirroring [method VillagerWalkabilityRules._has_scaffold]
## exactly (this is the instance-side twin, since [member scaffold_registry]
## is a per-villager-population-shared field, not a static parameter).
func _has_scaffold(cell: Vector3i) -> bool:
	if scaffold_registry == null:
		return false
	@warning_ignore("unsafe_method_access")
	return bool(scaffold_registry.has_scaffold(cell))


## [method _is_solid]'s override-aware twin -- [param written_cell] always
## reads solid (the hypothetical write has committed), regardless of
## [member voxel_world]'s REAL current contents there.
func _is_solid_after_write(cell: Vector3i, written_cell: Vector3i) -> bool:
	if cell == written_cell:
		return true
	return _is_solid(cell)


## [method _is_passable]'s override-aware twin -- [param written_cell] never
## reads passable (the hypothetical write has committed), regardless of
## [member voxel_world]'s REAL current contents there.
func _is_passable_after_write(cell: Vector3i, written_cell: Vector3i) -> bool:
	if cell == written_cell:
		return false
	return _is_passable(cell)


## Story villager-ai-024 fix (the wall-plateau defect) -- ONE generalized
## rule, realized as TWO directional call sites sharing ONE mutation
## primitive ([method _snap_current_cell_to] below): **when this villager's
## own construction work leaves it standing somewhere [VillagerNavGraph]
## cannot reach from anywhere else, move it to the nearest standable cell
## that IS reachable.** Together with an Unstuck Watchdog rescue (Story
## villager-ai-015) and tick-boundary travel arrival (Story villager-ai-004),
## this is ADR-0009's amended set of sanctioned discrete [member current_cell]
## mutations (see that ADR's own "Story villager-ai-024" addendum) -- never
## from anywhere else, never interpolated, always paired with a
## [member _visual_position] snap (no lerp).
##
## **Why two call sites, not one search reused twice.** The two moments this
## rule fires need OPPOSITE guarantees a single search cannot give both at
## once:
## - **Climbing UP** (this method, called by [VillagerSealPreventionGate] at
##   the exact instant its self-seal exemption fires -- `worker.
##   get_current_cell() == cell`, that class's own doc comment point 1) MUST
##   land EXACTLY on `sealed_cell + Vector3i(0, 1, 0)` -- the column's own
##   NEXT blueprint cell, if the column continues -- so the very next Deciding
##   pass finds it there at Chebyshev distance 0 and claims it immediately,
##   chaining up any `wall_height` with zero wasted ticks. A generic
##   nearest-standable-cell BFS ([VillagerRescueTargetSearch], reused
##   verbatim below for the OTHER direction) would NOT give this guarantee:
##   its own lexicographic `(y, x, z)` tie-break always prefers a
##   lower/same-height neighbor (e.g. the adjacent floor) over climbing
##   straight up -- confirmed directly, this is THE reason the Watchdog's
##   own pre-existing rescue never once climbed a column on its own, which is
##   THE reason a wall's third layer and above plateaued forever (root cause,
##   this story's own AC2 write-up): nothing ever put the villager exactly
##   there for job selection's true-path check to find. So this direction
##   stays a cheap, deterministic `+1` -- no search, no ambiguity.
## - **Climbing/stepping back DOWN** ([method _relocate_if_marooned] below,
##   called by [method _complete_claimed_job]/[method _abandon_claimed_job]
##   the instant a job finishes or is revoked) has no single correct fixed
##   offset -- the ground a column was originally approached from could be in
##   any horizontal direction, at any distance, and every cell of the column
##   itself is now solid rock underfoot, so a straight-down retrace is
##   impossible by construction. This direction genuinely needs a search --
##   reusing [VillagerRescueTargetSearch.find_rescue_target] VERBATIM (the
##   SAME BFS/tie-break the Watchdog already trusts, never a second
##   independently-written search) is exactly right here, since "prefer the
##   nearest LOWER standable neighbor" is precisely "climb back down to the
##   ground," the correct resolution for this direction.
##
## Both share [method _snap_current_cell_to] for the actual mutation --
## ONE accounting point for "this is a sanctioned discrete jump," not two
## independently-written field-assignment blocks.
func climb_onto_self_sealed_cell(sealed_cell: Vector3i) -> void:
	_snap_current_cell_to(sealed_cell + Vector3i(0, 1, 0))
	# Story `building-034` COUPLED RULING -- telemetry, not retirement (see
	# [VillagerUnstuckTelemetry]'s own doc comment). Nil-safe: mirrors this
	# class's own established "telemetry is observational, never gates
	# behaviour" precedent (see [method _perform_watchdog_rescue]).
	if unstuck_telemetry != null:
		unstuck_telemetry.record_self_seal_climb()


## See [method climb_onto_self_sealed_cell]'s own doc comment for the full
## "one generalized rule, two directions" rationale -- this is the DOWNWARD
## direction. Called only from [method _complete_claimed_job]/[method
## _abandon_claimed_job], both immediately after clearing this villager's own
## claim bookkeeping and setting [member _state] to `State.DECIDING`, BEFORE
## [method request_deciding_pass] re-enters the queue -- so a relocation here
## is always visible to the very first Deciding pass that follows, never a
## tick late.
##
## A no-op in every case where relocating would be WRONG or unnecessary,
## checked in order:
## 1. Self-sealed at [member current_cell] -- [method
##    climb_onto_self_sealed_cell] already owns this moment; this method
##    never duplicates or second-guesses that call.
## 2. **[method _has_available_job_at_current_cell] is true** -- this is the
##    load-bearing exclusion that keeps [method climb_onto_self_sealed_cell]'s
##    own chaining intact: standing at an isolated column cell with a REAL
##    next layer still queued there (mid-column, e.g. just arrived at layer 3
##    of a 6-tall wall) must NEVER be treated as "marooned" -- the very next
##    Deciding pass is SUPPOSED to claim and build exactly this cell. Skipping
##    this check would undo every climb the instant it happened, before the
##    next layer could ever be claimed.
## 3. [method _can_still_reach_available_work] is true -- deliberately NOT
##    "has any legal step to some neighbor": two adjacent finished columns'
##    own tops can be legally connected to EACH OTHER (an ordinary horizontal
##    step, same height) while that whole little island remains completely
##    cut off from every OTHER job site and the ground -- confirmed directly
##    against a real multi-segment room (a villager that finished two
##    adjacent columns wandered forever between their two tops, each always
##    reading "has a legal step," never reaching any of the other eight
##    still-queued columns). A true-path check against every CURRENTLY
##    available job (never a mere neighbor-count) is the only test that
##    actually answers "can this villager still do anything from here" --
##    see that method's own doc comment.
## Only once all three are false -- genuinely topped out or cut off, no
## reachable job anywhere, no legal walk out -- does this method search
## ([VillagerRescueTargetSearch.find_rescue_target], this villager's own
## [member config]-supplied `unstuck_rescue_search_radius`/`_max_radius`
## knobs, the SAME ones the Watchdog uses -- no new tuning knob) for a
## candidate, then VERIFIES it before committing (see [method
## _is_useful_relocation_candidate]'s own doc comment for why a raw search
## result cannot be trusted blindly): a real multi-segment room proved that
## search alone can return the top of a DIFFERENT already-finished, equally
## dead-end column (nearer, in pure Chebyshev terms, than the actual ground)
## -- a "rescue" that trades one isolated perch for another. A failing
## candidate is excluded (passed back into the NEXT search attempt's own
## occupant list, so the ring walk cannot return it again) and the search
## retries, up to [constant MAROONED_RELOCATE_MAX_ATTEMPTS] times -- bounded,
## deterministic, never an unbounded loop. Exhausting the attempts, or the
## search itself ever returning no candidate at all (an exceptionally sparse
## world), leaves the villager exactly where it is -- never relocates to
## nowhere; the pre-existing Unstuck Watchdog remains the fallback exactly as
## before this story for that residual case.
##
## **Never fires for Edge Case 2's protected scenario** (GDD Rule 15's own
## "a walled-in Idle/Wandering villager stays put, never rescued," Story
## villager-ai-019's own deliberate design -- the Unstuck Watchdog's own
## `stuck_tick_count` counter is STILL never widened to `State.WANDERING` by
## this story, exactly as directed): this method is reachable ONLY through a
## just-finished/just-revoked CONSTRUCTION claim, never through any Wandering
## re-entry into Deciding. A villager that becomes boxed in while idly
## wandering (unrelated to its own work) never passes through [method
## _complete_claimed_job]/[method _abandon_claimed_job] at all, so it is
## structurally unreachable by this method -- indistinguishable-by-flood-fill
## situations are resolved by WHICH CALL SITE reaches this method, never by
## re-inspecting `_state` after the fact.
func _relocate_if_marooned() -> void:
	if _is_self_sealed_at_current_cell():
		return
	if _has_available_job_at_current_cell():
		return
	if _can_still_reach_available_work():
		return
	var excluded_candidates: Array[Vector3i] = []
	for _attempt in range(MAROONED_RELOCATE_MAX_ATTEMPTS):
		var other_cells: Array[Vector3i] = _get_other_villager_cells() + excluded_candidates
		var result: RescueSearchResult = VillagerRescueTargetSearch.find_rescue_target(
			current_cell,
			self,
			other_cells,
			config.unstuck_rescue_search_radius,
			config.unstuck_rescue_max_radius,
		)
		if not result.has_target():
			return
		if _is_useful_relocation_candidate(result.cell):
			_snap_current_cell_to(result.cell)
			# Story `building-034` COUPLED RULING -- telemetry, not
			# retirement, recorded ONLY on an actual relocation (never on
			# one of this method's own early no-op returns above).
			if unstuck_telemetry != null:
				unstuck_telemetry.record_marooned_relocation()
			return
		excluded_candidates.append(result.cell)


## Bounded retry cap for [method _relocate_if_marooned]'s own
## search-then-verify loop -- generous relative to the handful of
## already-finished, adjacent dead-end columns a single small room can
## plausibly present as false leads, while still a hard, deterministic
## ceiling (never an unbounded search).
const MAROONED_RELOCATE_MAX_ATTEMPTS: int = 8


## [method _relocate_if_marooned]'s own candidate-usefulness filter.
## [VillagerRescueTargetSearch.find_rescue_target] answers ONLY "standable
## and unoccupied," the SAME general-purpose contract the Unstuck Watchdog
## already relies on -- it has no notion of "and can this villager actually
## DO anything from there," because for the Watchdog's own use (a genuinely
## walled-in-but-otherwise-normal villager) any standable neighbor already
## implies exactly that. This story's own new scenario breaks that implicit
## assumption TWICE over, both confirmed directly against a real
## multi-segment room:
## 1. The top of one just-finished, isolated column can be the NEAREST
##    standable-and-unoccupied cell to the top of ANOTHER just-finished,
##    isolated column -- both equally dead ends.
## 2. Two such dead-end tops are typically also a LEGAL STEP away from EACH
##    OTHER (an ordinary same-height horizontal move) -- so a naive
##    "has any legal step" check ([method _has_any_legal_step_from], correct
##    for [member current_cell] in [method _can_still_reach_available_work]'s
##    OWN "am I still stuck at all" question, which only needs a boolean, not
##    a destination) is NOT enough to VET a specific candidate destination:
##    it would accept "the other equally-isolated top" as a false pass.
## While [param candidate_cell] is standable (the search already guarantees
## that), the only way to actually tell "useful" from "another false lead" is
## the SAME true-path check F2 job selection itself uses: `true` iff [param
## candidate_cell] is EITHER itself a currently-claimable job ([method
## _get_available_jobs] -- landing exactly on the next thing to build is
## always useful) OR [VillagerNavGraph.find_path] can reach at least one
## currently-available job FROM it. When [method _get_available_jobs] is
## itself empty (nothing left to build anywhere -- the whole project just
## finished), there is no job to path-check against at all; this falls back
## to [method _has_any_legal_step_from] instead -- weaker, but harmless here,
## since [method _relocate_if_marooned]'s own bounded retry-and-exclude loop
## converges past a small handful of finished-column false leads onto real,
## ordinary ground within its attempt cap regardless of which of two
## equally-pointless dead ends is rejected first.
func _is_useful_relocation_candidate(candidate_cell: Vector3i) -> bool:
	var available_jobs: Array[BlueprintCell] = _get_available_jobs()
	if available_jobs.is_empty():
		return _has_any_legal_step_from(candidate_cell)
	for job: BlueprintCell in available_jobs:
		if job.cell == candidate_cell:
			return true
		if nav_graph != null and not nav_graph.find_path(candidate_cell, job.cell).is_empty():
			return true
	return false


## Whether [param job_queue]'s CURRENT available-jobs snapshot names [member
## current_cell] itself as a claimable [BlueprintCell] -- [method
## _relocate_if_marooned]'s own load-bearing "a real next job sits exactly
## here, do not relocate" exclusion (see that method's own doc comment, point
## 2). Reuses [method _get_available_jobs] (the SAME nil-safe read every
## other tier-2 query already goes through) rather than a second query
## shape -- a small linear scan, mirroring [method
## ConstructionJobQueue._find_eligible_cell]'s own established "scan the
## small available-jobs list directly" precedent.
func _has_available_job_at_current_cell() -> bool:
	for job: BlueprintCell in _get_available_jobs():
		if job.cell == current_cell:
			return true
	return false


## [method _relocate_if_marooned]'s own true-path reachability check (see
## that method's own doc comment, point 3, for why a mere neighbor-count is
## not enough): `true` iff [member nav_graph] can path from [member
## current_cell] to AT LEAST ONE cell [method _get_available_jobs] currently
## names -- the SAME [method VillagerNavGraph.find_path] true-path check F2
## job selection itself uses, never a second, re-derived reachability
## formula. An EMPTY available-jobs list (nothing left to build anywhere)
## returns `false` -- vacuously "cannot reach any work," matching this
## story's own "climb back down once there is nothing left to do up there"
## framing, never treated as "trivially fine, stay put." A `null` [member
## nav_graph] (a lighter test fixture that never wires one) falls back to
## [method _has_any_legal_step_from_current_cell] -- the pre-this-story
## heuristic -- rather than crashing; every REAL production villager has
## [member nav_graph] wired well before this method can ever run (a claim can
## only exist after a real F2 selection already required it).
func _can_still_reach_available_work() -> bool:
	if nav_graph == null:
		return _has_any_legal_step_from_current_cell()
	var available_jobs: Array[BlueprintCell] = _get_available_jobs()
	for job: BlueprintCell in available_jobs:
		if not nav_graph.find_path(current_cell, job.cell).is_empty():
			return true
	return false


## The ONE shared mutation primitive both directions of this story's fix
## funnel through (see [method climb_onto_self_sealed_cell]'s own doc
## comment) -- also mirrors [method _perform_watchdog_rescue]'s own
## established "atomic jump + snapped visual, no lerp, cleared travel state"
## shape exactly, applied here as a named, reusable step rather than a third
## independently-written copy of the same five field assignments.
func _snap_current_cell_to(target: Vector3i) -> void:
	current_cell = target
	_from_cell = target
	_to_cell = target
	_travel_remaining_path = []
	_intra_tick_progress = 0.0
	_visual_position = VoxelWorldGrid.cell_to_world(target)


# =============================================================================
# Story villager-ai-008 -- re-path FILTER (GDD Rule 10b, TR-012/036)
# =============================================================================

## Whether this villager is currently mid-step (GDD Rule 10b's "any moving
## villager" scope). A pure, discrete comparison -- `_from_cell != _to_cell`
## -- never a read of [member _visual_position]/[member _intra_tick_progress]
## (Control Manifest Core Layer: occupancy/movement queries never reason
## about interpolation progress). Deliberately NOT keyed to [member _state]
## naming TRAVELING/WANDERING/BREATHER explicitly: whichever state is
## driving a 1-cell step (Traveling, a Wandering step, a Breather
## step-away, or a future F4 vacate step), that step sets
## [member _from_cell]/[member _to_cell] to two DIFFERENT cells for its
## duration and back to equal at arrival ([method _on_tick]'s
## `current_cell = _to_cell` moment coincides with `_from_cell == _to_cell`
## already being true from the PRIOR step's completion, by this class's own
## existing invariant) -- so this single check already covers all 4 named
## cases without enumerating them, and naturally excludes every stationary
## state (Deciding/Working/Sleeping, and a Breather not yet stepping) since
## none of them ever drives `_from_cell`/`_to_cell` apart.
func is_moving() -> bool:
	return _from_cell != _to_cell


## "The remaining movement's cells" (GDD Rule 10b) -- widened by story
## villager-ai-009 (exactly the widening this method's own predecessor doc
## comment reserved) to cover the villager's ENTIRE remaining route once
## [method start_traveling] is driving travel, not merely its single
## in-flight step: [member _from_cell] (the current step's origin) plus
## every cell still in [member _travel_remaining_path] (which always begins
## with [member _to_cell], the in-flight step's own destination). Falls
## back to the ORIGINAL single-step pair, `[_from_cell, _to_cell]`, when
## [member _travel_remaining_path] is empty despite [method is_moving] being
## `true` -- the case a hand-constructed test fixture produces by setting
## [member _from_cell]/[member _to_cell] apart directly without ever calling
## [method start_traveling] (story 008's own `graph_patching_test.gd`
## fixtures do exactly this; this fallback keeps them passing unchanged). An
## empty array when stationary ([method is_moving] `false`), unchanged from
## story 008.
func get_remaining_movement_cells() -> Array[Vector3i]:
	if not is_moving():
		return []
	if _travel_remaining_path.is_empty():
		return [_from_cell, _to_cell]
	var cells: Array[Vector3i] = [_from_cell]
	cells.append_array(_travel_remaining_path)
	return cells


## Mid-travel re-path recompute (Story villager-ai-009, this story's AC18 --
## "the villager re-paths from its current cell"). Called ONLY from [method
## _on_repath_evaluation_requested]'s `State.TRAVELING` guard. Re-queries
## [member nav_graph] -- already patched against the SAME write, by
## construction, per [member nav_graph]'s own wiring-order doc comment --
## for a fresh path from [member current_cell] toward the SAME
## [member _travel_target_cell] (a redirect never changes the ultimate
## target itself, only the route). An empty result means no viable detour
## exists -- [method _abandon_travel] fires (this story's AC19, dispatched
## via the SAME per-target fallback [method start_traveling]'s own
## unreachable case uses). A single-cell result (rare: [member current_cell]
## itself is now the target) still completes arrival correctly via
## [method _complete_travel_arrival]. A genuine multi-cell detour replaces
## [member _travel_remaining_path] outright and resets
## [member _intra_tick_progress] -- the redirected step begins from `0.0`
## progress, never from wherever the abandoned step's progress happened to
## be (a fresh step, not a resumed one).
func _recompute_path_from_current_cell() -> void:
	assert(nav_graph != null, "VillagerAi.nav_graph not wired -- required once Traveling")
	var new_path: Array[Vector3i] = nav_graph.find_path(current_cell, _travel_target_cell)
	if new_path.is_empty():
		_abandon_travel()
		return
	if new_path.size() == 1:
		_complete_travel_arrival(_travel_arrival_state)
		return
	var remaining: Array[Vector3i] = new_path.slice(1)
	_travel_remaining_path = remaining
	_from_cell = current_cell
	_to_cell = _travel_remaining_path[0]
	_intra_tick_progress = 0.0


## [signal repath_evaluation_requested] handler (Story villager-ai-009),
## connected in [method setup] with Godot's DEFAULT synchronous flags
## (never `CONNECT_DEFERRED`) -- the actual REDIRECT this story's
## race-closure AC requires happens here, in the SAME synchronous call
## stack as the Voxel World write that triggered [signal
## repath_evaluation_requested] (story 008's own filter, unchanged), well
## before the next frame's [method _process] call could ever advance
## [member _visual_position] further toward now-solid geometry. Guarded to
## `State.TRAVELING` only: [method evaluate_repath_trigger] can fire for any
## moving villager regardless of [member _state] (nothing in that check
## depends on it, story 008), but a villager whose [member _from_cell]/
## [member _to_cell] were set apart by some OTHER means (e.g. a
## hand-constructed test fixture never touching [member _state]) has no
## [member _travel_target_cell]/[member nav_graph] to recompute against --
## a harmless no-op for every state but Traveling.
func _on_repath_evaluation_requested() -> void:
	if _state != State.TRAVELING:
		return
	_recompute_path_from_current_cell()


## The re-path FILTER itself (GDD Rule 10b, this story's AC18/AC49): given
## the cell(s) a Voxel World write just changed, fires [signal
## repath_evaluation_requested] exactly once if -- and only if -- this
## villager is currently moving ([method is_moving]) AND [param
## changed_cells] intersects [method get_remaining_movement_cells]'s own
## clearance envelope (delegated entirely to the stateless
## [VillagerRepathFilter] library, never a locally re-derived copy of the
## envelope rule). A write outside that envelope -- or any write while this
## villager is stationary -- fires nothing (AC49: "re-path evaluation
## call-count == 0").
func evaluate_repath_trigger(changed_cells: Array[Vector3i]) -> void:
	if not is_moving():
		return
	if VillagerRepathFilter.changed_cells_intersect_envelope(changed_cells, get_remaining_movement_cells()):
		repath_evaluation_requested.emit()


## [signal VoxelWorldGrid.cell_changed] handler (wired in [method setup] with
## Godot's DEFAULT, synchronous, NEVER `CONNECT_DEFERRED` connection flags --
## see this class's own doc comment for why that is load-bearing). Delegates
## to [method evaluate_repath_trigger] for the single changed cell; [param
## _before]/[param _after] are unused -- the filter only cares WHICH cell
## changed, never what it changed FROM/TO.
func _on_voxel_world_cell_changed(cell: Vector3i, _before: CellContents, _after: CellContents) -> void:
	evaluate_repath_trigger([cell])


## [signal VoxelWorldGrid.cells_changed_batch] handler -- same delegation as
## [method _on_voxel_world_cell_changed], batched: every changed cell across
## one bulk write is folded into ONE [method evaluate_repath_trigger] call
## (so at most one [signal repath_evaluation_requested] emission per batch,
## never one per record), consistent with [VillagerNavGraph]'s own
## story-008 batch handler.
func _on_voxel_world_cells_changed_batch(changes: Array[CellChangeRecord]) -> void:
	var cells: Array[Vector3i] = []
	for record: CellChangeRecord in changes:
		cells.append(record.cell)
	evaluate_repath_trigger(cells)
