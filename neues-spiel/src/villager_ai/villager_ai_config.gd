## Typed tuning-config Resource for Villager AI (ADR-0002), storing every
## knob this story's AC list names from design/gdd/villager-ai-behavior.md's
## Tuning Knobs section, plus `max_deciding_per_tick` (ADR-0008's
## per-tick Deciding-pass budget -- an ADR-owned scheduling knob, not a GDD
## Tuning Knob, but authored here as another typed `@export` per the same
## ADR-0002 config-class pattern; see [member max_deciding_per_tick]'s own
## doc comment for its range's provenance).
##
## Wired into [VillagerAi] (injected-tier, ADR-0001) as another typed
## `@export` dependency; a matching `.tres` instance lives at
## `res://data/config/villager_ai_config.tres`. [method validate] applies
## [ConfigResource]'s single-field clamp+warn tier to every knob below --
## this story's ACs only require the single-field range-check/clamp
## behaviour (story villager-ai-001 scope); no GDD-declared BLOCKING
## cross-value invariant is authored here (mirrors `CameraInputConfig`'s
## clamp-only precedent -- a future story may add one, e.g.
## `unstuck_rescue_max_radius >= unstuck_rescue_search_radius`, if a GDD
## revision ever declares it BLOCKING).
##
## The population ceiling (20-30, Full Vision) is DELIBERATELY not a field
## here -- the GDD's own Tuning Knobs table marks it "design commitment, not
## a slider" and this story's AC list of 15 knobs to export does not include
## it. [TR-villager-ai-behavior-090]
class_name VillagerAIConfig
extends ConfigResource

## Safe range for [member move_speed] (GDD Tuning Knobs: 1.5-6.0
## cells/game-second, F1).
const MOVE_SPEED_MIN: float = 1.5
const MOVE_SPEED_MAX: float = 6.0

## Safe range for [member decision_interval] (GDD Tuning Knobs: 1-10 ticks).
const DECISION_INTERVAL_MIN: int = 1
const DECISION_INTERVAL_MAX: int = 10

## Safe range for [member unreachable_retry_ticks] (GDD Tuning Knobs:
## 10-120 ticks).
const UNREACHABLE_RETRY_TICKS_MIN: int = 10
const UNREACHABLE_RETRY_TICKS_MAX: int = 120

## Safe range for [member wander_radius] (GDD Tuning Knobs: 3-16 cells, F3).
const WANDER_RADIUS_MIN: int = 3
const WANDER_RADIUS_MAX: int = 16

## Safe range for [member wander_interval] (GDD Tuning Knobs: 2-20 ticks).
const WANDER_INTERVAL_MIN: int = 2
const WANDER_INTERVAL_MAX: int = 20

## Safe range for [member job_candidate_count] (GDD Tuning Knobs: 3-10, F2).
const JOB_CANDIDATE_COUNT_MIN: int = 3
const JOB_CANDIDATE_COUNT_MAX: int = 10

## Safe range for [member max_selection_candidates] (GDD Tuning Knobs:
## 5-30, F2 hard cap).
const MAX_SELECTION_CANDIDATES_MIN: int = 5
const MAX_SELECTION_CANDIDATES_MAX: int = 30

## Safe range for [member jobs_before_break] (GDD Tuning Knobs: 2-10, Rule 7b).
const JOBS_BEFORE_BREAK_MIN: int = 2
const JOBS_BEFORE_BREAK_MAX: int = 10

## Safe range for [member breather_duration_ticks] (GDD Tuning Knobs:
## 30-240 ticks).
const BREATHER_DURATION_TICKS_MIN: int = 30
const BREATHER_DURATION_TICKS_MAX: int = 240

## Safe range for [member starting_villager_count] (GDD Tuning Knobs: 1-8,
## Rule 14b).
const STARTING_VILLAGER_COUNT_MIN: int = 1
const STARTING_VILLAGER_COUNT_MAX: int = 8

## Safe range for [member max_deciding_per_tick] -- `[assumption]`, ADR-0008
## does not itself state a GDD-style min/max, only the spike-tuned initial
## value (1) and the fact that it bounds worst-case per-tick Deciding-pass
## cost. Bounded above by the GDD's own Full Vision population ceiling (30,
## Tuning Knobs table) -- budgeting more new Deciding passes per tick than
## the entire population ceiling has no meaning. Floored at 1 -- a budget of
## 0 would mean no villager could ever start a new Deciding pass, a
## structural deadlock, not a valid tuning choice.
const MAX_DECIDING_PER_TICK_MIN: int = 1
const MAX_DECIDING_PER_TICK_MAX: int = 30

## Safe range for [member unstuck_watchdog_threshold_ticks] (GDD Tuning
## Knobs: 6-30 ticks, F5).
const UNSTUCK_WATCHDOG_THRESHOLD_TICKS_MIN: int = 6
const UNSTUCK_WATCHDOG_THRESHOLD_TICKS_MAX: int = 30

## Safe range for [member unstuck_rescue_search_radius] (GDD Tuning Knobs:
## 3-12 cells `[assumption]`, F5).
const UNSTUCK_RESCUE_SEARCH_RADIUS_MIN: int = 3
const UNSTUCK_RESCUE_SEARCH_RADIUS_MAX: int = 12

## Safe range for [member unstuck_rescue_max_radius] (GDD Tuning Knobs:
## 12-48 cells `[assumption]`, Edge Case 14).
const UNSTUCK_RESCUE_MAX_RADIUS_MIN: int = 12
const UNSTUCK_RESCUE_MAX_RADIUS_MAX: int = 48

## Safe range for [member seal_prevention_abandon_limit] (GDD Tuning Knobs:
## 1-6 `[assumption range]`, F6).
const SEAL_PREVENTION_ABANDON_LIMIT_MIN: int = 1
const SEAL_PREVENTION_ABANDON_LIMIT_MAX: int = 6

## Safe range for [member nav_region_size] (Story villager-ai-007, ADR-0007:
## "the nav graph covers a bounded settlement-core region... Measured limit:
## region <= 200x200 cells... 300x300+ measured frame-breaking at p95 24-49
## ms per query"). The upper bound is the ADR's own measured PERFORMANCE
## CEILING, not merely a design preference -- exceeding it is an accepted
## frame-budget regression, not just an aesthetic tuning choice, so
## [method validate]'s clamp is load-bearing here in a way most other knobs'
## clamps are not. The lower bound is an `[assumption]` (no GDD/ADR floor
## stated) picked wide enough that even a degenerately small region still
## covers more than a handful of standable cells around the starting roster
## (Rule 14b).
const NAV_REGION_SIZE_MIN: int = 20
const NAV_REGION_SIZE_MAX: int = 200

## Travel pacing, cells per game-second (GDD default: 3.0, F1). Consumed by
## Traveling-state movement (story 002+, out of scope here).
@export var move_speed: float = 3.0

## How often, in ticks, an urgent need can preempt long activities (GDD
## default: 2 ticks, Rule 2; re-tuned to 4 ticks, Sprint 8 coordinated
## re-tune -- `design/quick-specs/tick-rate-retune-2026-07-25.md` §1/§7:
## restores the ORIGINAL 1.0s-at-1x real-time cadence the 2.0->4.0
## `ticks_per_second` slice revision silently halved to 0.5s, and directly
## reduces Rule 2's periodic-recheck queue pressure -- `villager-ai-025`'s
## stress evidence found the OLD value (2) sustained a chronic near-full
## Deciding queue at population 30 regardless of `max_deciding_per_tick`;
## at the new pairing (4, with `max_deciding_per_tick=5` below) supply
## (20/cycle) exceeds demand (~8/cycle), so the queue is expected to reach
## quiescence between recheck cycles instead (quick-spec §4 F-retune-2).
## Consumed by the Deciding periodic re-check (story 005/006, out of scope
## here).
@export var decision_interval: int = 4

## Retry cadence, in ticks, for unreachable jobs (GDD default: 20, Rule 6).
## Consumed by story 006's unreachable-job retry, out of scope here.
@export var unreachable_retry_ticks: int = 20

## How far idle villagers roam, in cells (GDD default: 8, F3). Consumed by
## story 004's Wandering flood-fill, out of scope here.
@export var wander_radius: int = 8

## How often a wander target is re-picked, in ticks (GDD default: 6, F3).
## Consumed by story 004, out of scope here.
@export var wander_interval: int = 6

## F2's pre-filter width -- the nearest-by-straight-line-distance candidate
## count considered before true-path checking (GDD default: 5, F2). Consumed
## by story 005/006's job selection, out of scope here.
@export var job_candidate_count: int = 5

## Hard total candidate cap per F2 selection pass across all pre-filter
## rounds (GDD default: 15, F2). Consumed by story 005/006, out of scope
## here.
@export var max_selection_candidates: int = 15

## Consecutive completed jobs before a Breather (GDD default: 4, Rule 7b).
## Consumed by a later story's Breather logic, out of scope here.
@export var jobs_before_break: int = 4

## Length of the Breather rest beat, in ticks (GDD default: 90, Rule 7b).
## Consumed by a later story's Breather logic, out of scope here.
@export var breather_duration_ticks: int = 90

## The world-generation starting roster size (GDD default: 1 at MVP scope,
## Rule 14b). Consumed by a later world-generation story, out of scope here.
@export var starting_villager_count: int = 1

## Per-tick budget on how many NEW Deciding passes may START in a single
## tick (ADR-0008 Decision §2, spike-tuned initial default: 1; re-tuned to
## 5, Story villager-ai-022 / Sprint 8 coordinated re-tune --
## `design/quick-specs/tick-rate-retune-2026-07-25.md` §1/§4/§5, ratified
## against `villager-ai-025`'s production-code stress evidence, not the
## pre-VS GDScript-stand-in spike). Cuts the worst-case Deciding-queue wait
## at population 30 from 30 ticks (7.5s @ 1x, TPS=4.0) to 6 ticks (1.5s), an
## 80% reduction (quick-spec F-retune-1), while keeping the estimated
## worst-case per-tick Deciding cost at roughly a third of the 16.6ms frame
## budget (~5.47ms estimated, re-measured by `stress_30_villager_test.gd`'s
## Sprint 8 additions). Caps worst-case per-tick Deciding-pass cost; never
## interrupts an in-progress pass. Consumed by story 005's Deciding-pass
## staggering queue, out of scope here.
@export var max_deciding_per_tick: int = 5

## Ticks of continuous stuckness (zero legal step, or a non-standable
## current cell) before the Unstuck Watchdog's rescue teleport fires (GDD
## default: 12, F5/Rule 15). Consumed by a later story's watchdog, out of
## scope here.
@export var unstuck_watchdog_threshold_ticks: int = 12

## Initial BFS ring radius searched for a rescue cell, in cells (GDD
## default: 6 `[assumption]`, F5/Rule 15b). Consumed by a later story's
## watchdog, out of scope here.
@export var unstuck_rescue_search_radius: int = 6

## Expansion ceiling, in cells, before a rescue defers to the next tick (GDD
## default: 24 `[assumption]`, Edge Case 14). Consumed by a later story's
## watchdog, out of scope here.
@export var unstuck_rescue_max_radius: int = 24

## Livelock-escape threshold: refused completions of the same (job,
## villager) pair before the write proceeds unconditionally (GDD default: 3,
## F6/Rule 16b). Consumed by a later story's seal-prevention gate, out of
## scope here.
@export var seal_prevention_abandon_limit: int = 3

## Bounded settlement-core region size, in cells, the AStar3D travel-
## pathfinding graph is built over (Story villager-ai-007, ADR-0007
## Constraints: "the nav graph covers a bounded settlement-core region, NOT
## the whole world"; spike-validated default 200). Consumed by
## [VillagerNavGraph.build] -- never a per-GDD-Tuning-Knob row (this is an
## ADR-owned architectural bound, same "authored here as another typed
## `@export`" precedent as [member max_deciding_per_tick]), out of scope for
## any other story.
##
## Story scene-005 re-tune (200 -> 40, TD-named lever #1, this story's own
## AC-BOOT-BUDGET): wiring [method VillagerNavGraph.build] into the real
## synchronous boot chain for the first time (villager-ai-007 landed the
## method but nothing called it from boot until this story) surfaced a real
## cost the ADR's own spike never measured against a live boot budget: at
## the shipped default, 200x200x17 = 680,000 [method
## VillagerWalkabilityRules.is_standable] evaluations measured **6697.6 ms**
## (`tools/scene005_genesis_boot_budget_measurement.gd`), alone almost 2.2x
## the technical-director's entire 3.0 s boot-to-ACTIVE ceiling (Addendum D /
## D2). Reduced to 40 (64x fewer columns, 40x40x17 = 27,200 evaluations)
## measured **~268 ms** -- see `production/qa/evidence/
## world-genesis-boot-budget-2026-07-26.md` for the full phase-split
## before/after. Still comfortably inside villager-ai-007's own ADR-0007
## measured-safe range (20-200) and its own per-query performance ceiling
## (region <= 200x200 was the UPPER bound that query-time measurement named,
## not a floor); a 40x40 settlement core is still generous at MVP/VS
## population scale (1-5 villagers). This is a `.tres` DATA change only, no
## code -- reversible the instant a future story funds a faster nav-graph
## build (e.g. an incremental/threaded construction) and wants the larger
## region back.
@export var nav_region_size: int = 40


## See [ConfigResource.validate]. Clamps every knob to its GDD-documented (or
## explicitly `[assumption]`-labeled) safe bound in place (the sole
## sanctioned runtime write to this config) and appends a warning string per
## clamped field. No BLOCKING cross-value invariant exists for this config
## (ADR-0002 two-tier policy, this story's scope) -- an out-of-range single
## field always clamps and proceeds, never halts boot.
func validate() -> Array[String]:
	var issues: Array[String] = []
	if move_speed < MOVE_SPEED_MIN or move_speed > MOVE_SPEED_MAX:
		issues.append(
			"move_speed out of range [%s, %s], got %s -- clamped" %
			[MOVE_SPEED_MIN, MOVE_SPEED_MAX, move_speed]
		)
		move_speed = clampf(move_speed, MOVE_SPEED_MIN, MOVE_SPEED_MAX)
	if decision_interval < DECISION_INTERVAL_MIN or decision_interval > DECISION_INTERVAL_MAX:
		issues.append(
			"decision_interval out of range [%s, %s], got %s -- clamped" %
			[DECISION_INTERVAL_MIN, DECISION_INTERVAL_MAX, decision_interval]
		)
		decision_interval = clampi(decision_interval, DECISION_INTERVAL_MIN, DECISION_INTERVAL_MAX)
	if unreachable_retry_ticks < UNREACHABLE_RETRY_TICKS_MIN or unreachable_retry_ticks > UNREACHABLE_RETRY_TICKS_MAX:
		issues.append(
			"unreachable_retry_ticks out of range [%s, %s], got %s -- clamped" %
			[UNREACHABLE_RETRY_TICKS_MIN, UNREACHABLE_RETRY_TICKS_MAX, unreachable_retry_ticks]
		)
		unreachable_retry_ticks = clampi(
			unreachable_retry_ticks, UNREACHABLE_RETRY_TICKS_MIN, UNREACHABLE_RETRY_TICKS_MAX
		)
	if wander_radius < WANDER_RADIUS_MIN or wander_radius > WANDER_RADIUS_MAX:
		issues.append(
			"wander_radius out of range [%s, %s], got %s -- clamped" %
			[WANDER_RADIUS_MIN, WANDER_RADIUS_MAX, wander_radius]
		)
		wander_radius = clampi(wander_radius, WANDER_RADIUS_MIN, WANDER_RADIUS_MAX)
	if wander_interval < WANDER_INTERVAL_MIN or wander_interval > WANDER_INTERVAL_MAX:
		issues.append(
			"wander_interval out of range [%s, %s], got %s -- clamped" %
			[WANDER_INTERVAL_MIN, WANDER_INTERVAL_MAX, wander_interval]
		)
		wander_interval = clampi(wander_interval, WANDER_INTERVAL_MIN, WANDER_INTERVAL_MAX)
	if job_candidate_count < JOB_CANDIDATE_COUNT_MIN or job_candidate_count > JOB_CANDIDATE_COUNT_MAX:
		issues.append(
			"job_candidate_count out of range [%s, %s], got %s -- clamped" %
			[JOB_CANDIDATE_COUNT_MIN, JOB_CANDIDATE_COUNT_MAX, job_candidate_count]
		)
		job_candidate_count = clampi(job_candidate_count, JOB_CANDIDATE_COUNT_MIN, JOB_CANDIDATE_COUNT_MAX)
	if max_selection_candidates < MAX_SELECTION_CANDIDATES_MIN or max_selection_candidates > MAX_SELECTION_CANDIDATES_MAX:
		issues.append(
			"max_selection_candidates out of range [%s, %s], got %s -- clamped" %
			[MAX_SELECTION_CANDIDATES_MIN, MAX_SELECTION_CANDIDATES_MAX, max_selection_candidates]
		)
		max_selection_candidates = clampi(
			max_selection_candidates, MAX_SELECTION_CANDIDATES_MIN, MAX_SELECTION_CANDIDATES_MAX
		)
	if jobs_before_break < JOBS_BEFORE_BREAK_MIN or jobs_before_break > JOBS_BEFORE_BREAK_MAX:
		issues.append(
			"jobs_before_break out of range [%s, %s], got %s -- clamped" %
			[JOBS_BEFORE_BREAK_MIN, JOBS_BEFORE_BREAK_MAX, jobs_before_break]
		)
		jobs_before_break = clampi(jobs_before_break, JOBS_BEFORE_BREAK_MIN, JOBS_BEFORE_BREAK_MAX)
	if breather_duration_ticks < BREATHER_DURATION_TICKS_MIN or breather_duration_ticks > BREATHER_DURATION_TICKS_MAX:
		issues.append(
			"breather_duration_ticks out of range [%s, %s], got %s -- clamped" %
			[BREATHER_DURATION_TICKS_MIN, BREATHER_DURATION_TICKS_MAX, breather_duration_ticks]
		)
		breather_duration_ticks = clampi(
			breather_duration_ticks, BREATHER_DURATION_TICKS_MIN, BREATHER_DURATION_TICKS_MAX
		)
	if starting_villager_count < STARTING_VILLAGER_COUNT_MIN or starting_villager_count > STARTING_VILLAGER_COUNT_MAX:
		issues.append(
			"starting_villager_count out of range [%s, %s], got %s -- clamped" %
			[STARTING_VILLAGER_COUNT_MIN, STARTING_VILLAGER_COUNT_MAX, starting_villager_count]
		)
		starting_villager_count = clampi(
			starting_villager_count, STARTING_VILLAGER_COUNT_MIN, STARTING_VILLAGER_COUNT_MAX
		)
	if max_deciding_per_tick < MAX_DECIDING_PER_TICK_MIN or max_deciding_per_tick > MAX_DECIDING_PER_TICK_MAX:
		issues.append(
			"max_deciding_per_tick out of range [%s, %s], got %s -- clamped" %
			[MAX_DECIDING_PER_TICK_MIN, MAX_DECIDING_PER_TICK_MAX, max_deciding_per_tick]
		)
		max_deciding_per_tick = clampi(
			max_deciding_per_tick, MAX_DECIDING_PER_TICK_MIN, MAX_DECIDING_PER_TICK_MAX
		)
	if (
		unstuck_watchdog_threshold_ticks < UNSTUCK_WATCHDOG_THRESHOLD_TICKS_MIN
		or unstuck_watchdog_threshold_ticks > UNSTUCK_WATCHDOG_THRESHOLD_TICKS_MAX
	):
		issues.append(
			"unstuck_watchdog_threshold_ticks out of range [%s, %s], got %s -- clamped" %
			[UNSTUCK_WATCHDOG_THRESHOLD_TICKS_MIN, UNSTUCK_WATCHDOG_THRESHOLD_TICKS_MAX, unstuck_watchdog_threshold_ticks]
		)
		unstuck_watchdog_threshold_ticks = clampi(
			unstuck_watchdog_threshold_ticks,
			UNSTUCK_WATCHDOG_THRESHOLD_TICKS_MIN,
			UNSTUCK_WATCHDOG_THRESHOLD_TICKS_MAX
		)
	if (
		unstuck_rescue_search_radius < UNSTUCK_RESCUE_SEARCH_RADIUS_MIN
		or unstuck_rescue_search_radius > UNSTUCK_RESCUE_SEARCH_RADIUS_MAX
	):
		issues.append(
			"unstuck_rescue_search_radius out of range [%s, %s], got %s -- clamped" %
			[UNSTUCK_RESCUE_SEARCH_RADIUS_MIN, UNSTUCK_RESCUE_SEARCH_RADIUS_MAX, unstuck_rescue_search_radius]
		)
		unstuck_rescue_search_radius = clampi(
			unstuck_rescue_search_radius, UNSTUCK_RESCUE_SEARCH_RADIUS_MIN, UNSTUCK_RESCUE_SEARCH_RADIUS_MAX
		)
	if (
		unstuck_rescue_max_radius < UNSTUCK_RESCUE_MAX_RADIUS_MIN
		or unstuck_rescue_max_radius > UNSTUCK_RESCUE_MAX_RADIUS_MAX
	):
		issues.append(
			"unstuck_rescue_max_radius out of range [%s, %s], got %s -- clamped" %
			[UNSTUCK_RESCUE_MAX_RADIUS_MIN, UNSTUCK_RESCUE_MAX_RADIUS_MAX, unstuck_rescue_max_radius]
		)
		unstuck_rescue_max_radius = clampi(
			unstuck_rescue_max_radius, UNSTUCK_RESCUE_MAX_RADIUS_MIN, UNSTUCK_RESCUE_MAX_RADIUS_MAX
		)
	if (
		seal_prevention_abandon_limit < SEAL_PREVENTION_ABANDON_LIMIT_MIN
		or seal_prevention_abandon_limit > SEAL_PREVENTION_ABANDON_LIMIT_MAX
	):
		issues.append(
			"seal_prevention_abandon_limit out of range [%s, %s], got %s -- clamped" %
			[SEAL_PREVENTION_ABANDON_LIMIT_MIN, SEAL_PREVENTION_ABANDON_LIMIT_MAX, seal_prevention_abandon_limit]
		)
		seal_prevention_abandon_limit = clampi(
			seal_prevention_abandon_limit, SEAL_PREVENTION_ABANDON_LIMIT_MIN, SEAL_PREVENTION_ABANDON_LIMIT_MAX
		)
	if nav_region_size < NAV_REGION_SIZE_MIN or nav_region_size > NAV_REGION_SIZE_MAX:
		issues.append(
			"nav_region_size out of range [%s, %s], got %s -- clamped" %
			[NAV_REGION_SIZE_MIN, NAV_REGION_SIZE_MAX, nav_region_size]
		)
		nav_region_size = clampi(nav_region_size, NAV_REGION_SIZE_MIN, NAV_REGION_SIZE_MAX)
	return issues
