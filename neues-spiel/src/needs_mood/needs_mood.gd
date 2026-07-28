## Needs & Mood System module scaffold (Story needs-mood-001, ADR-0002
## primary config; ADR-0001 injected-tier DI; ADR-0005 boot gate). This
## story's scope is EXACTLY the config resource + DI scaffold + the fixed
## need schema + the AC29 BLOCKING ladder invariant + the tick-subscription
## skeleton -- no F1 decay state machine, no F2 recovery-report API/source
## table, no F3 mood math (those are stories 002/003/005).
##
## Per TD ruling NM-3 (`production/architecture-decisions-m02-preflight-
## 2026-07-26.md`), Core Rule 4's THREE-rung recovery ladder is
## authoritative -- the GDD's own F2 variable-table row (a stale
## two-multiplier form) is a known doc-hygiene defect and is never
## implemented anywhere in this module or a future story.
##
## Story needs-mood-002 (this revision) fills in [method _pass_f1_decay]
## for real: F1 decay, the per-need queryable state machine (Satisfied ->
## Urgent; [enum NeedState.RECOVERING] is wired as an enum value only,
## story 003's `start_recovery` report is the sole way to ever enter it),
## the edge-triggered [signal need_urgent] notification, and the
## Villager-AI-facing query surface -- [method has_urgent_need] (TD ruling
## NM-6, a REQUIRED pure query, matched verbatim to
## `villager_ai.gd`'s `needs_provider.has_urgent_need` seam),
## [method get_need_value], and [method get_need_state]. [method
## set_need_value] is this story's own initialization/test seam (NOT the
## GDD's F4 spawn-init feature, which remains unowned -- see that method's
## own doc comment). F2 recovery ([method _pass_f2_recovery]) and F3 mood
## smoothing ([method _pass_f3_mood]) remain untouched no-op stubs --
## stories 003/005's scope.
##
## Story needs-mood-003 (this revision) fills in the recovery-report API and
## F2 recovery for real: [method start_recovery]/[method stop_recovery] (TD
## ruling NM-5 -- `production/architecture-decisions-m02-preflight-
## 2026-07-26.md` -- the three-arg villager-id form is canonical, matching
## `docs/architecture/architecture.md`'s API Boundaries block verbatim), the
## [enum RecoverySource] source schema + [constant RECOVERY_SOURCE_NAMES]
## conversion table, the per-tick [member _source_rate_table] lookup (GDD
## Core Rule 4; per TD ruling NM-3 the THREE-rung ladder is authoritative --
## the GDD's own stale two-multiplier F2 variable-table row is never
## implemented), [method _pass_f2_recovery] (GDD Formulas F2), and the
## edge-triggered [signal need_satisfied] notification. F3 mood smoothing
## ([method _pass_f3_mood]) remains story 005's untouched no-op stub.
##
## Story needs-mood-005 (this revision) fills in F3 mood smoothing for real:
## the per-villager EMA step + snap rule ([method _pass_f3_mood]), the
## `mean_active` aggregate over [constant ACTIVE_NEEDS] only ([method
## _mean_active_need_value]), the pure mood-band derivation ([enum MoodBand],
## [method _band_for_mood]) against [member NeedsMoodConfig.mood_band_happy]/
## [member NeedsMoodConfig.mood_band_content], the edge-triggered [signal
## mood_band_changed] display notification, and [method get_mood]/[method
## get_mood_band]/[method set_mood_value] (the latter this story's own
## initialization/test seam, NOT the GDD's F4 spawn-init feature -- story
## needs-mood-006's scope, see that method's own doc comment). Per Core Rule
## 7 and this story's own Control Manifest note, mood is display-only in MVP:
## no scheduling/work-speed/priority code may read [method get_mood]/[method
## get_mood_band] (TR-needs-mood-system-040), a claim this story's own test
## suite verifies directly against `src/villager_ai`'s source.
##
## Story needs-mood-006 (this revision) fills in F4 spawn initialization for
## real: [method initialize_villager] -- the sole entry point that seeds every
## [constant ACTIVE_NEEDS] member at 100 for a villager (idempotent by
## construction -- an already-tracked need is left completely untouched, no
## overwrite) and creates that villager's [MoodRecord] at `mean_active`
## (reusing [method _mean_active_need_value] verbatim, never a second copy of
## that formula, per this story's own Implementation Notes), but ONLY the
## FIRST time this is called for a given villager_id -- an already-existing
## [MoodRecord] is never rewritten. That one guard is what lets a SINGLE
## method legally serve both GDD F4 spawn-init (TR-needs-mood-system-056) and
## an existing villager's new-need schema activation (Edge Case 5,
## TR-needs-mood-system-061, AC26) without ever re-running F4's mood formula
## against a villager whose mood is already ticking -- the Control Manifest's
## own named Forbidden pattern (re-running F4 on an existing villager is what
## would erase story needs-mood-012's future load-restored smoothing state).
## The optional [param active_needs] override (default [constant
## ACTIVE_NEEDS]) exists SOLELY so this story's own test suite can exercise
## the new-need-activation path deterministically without mutating the real
## schema constant (which Godot treats as read-only at runtime) -- production
## always calls with zero arguments beyond `villager_id`. Never emits any
## signal on either branch (the same "initialization is never a cross"
## argument [method set_need_value]/[method set_mood_value]'s own doc
## comments make) -- this story's own AC requires zero events observable
## after initialization plus one subsequent tick.
##
## Story needs-mood-007 (this revision) fills in why-string selection,
## templates, and UI-slot precedence for real (GDD Core Rule 11,
## TR-needs-mood-system-045/046/047/064): [method get_why_string] -- a PURE,
## O(active needs) query with two inputs and one output ("no history, no
## caching" per this story's own Implementation Notes) -- (1) [method
## _strongest_drain_record] picks the strongest current drain (the LOWEST
## tracked need value, schema-order tie-break via [constant NEED_NAMES]'s
## own insertion order, never gated by [constant ACTIVE_NEEDS] so a test
## double can exercise a schema-inactive need directly), and (2) [method
## _why_string_for_need] reads that need's CURRENTLY reported recovery
## source against [constant WHY_STRING_TEMPLATES] (data, keyed by source
## enum -- "adding a source rung adds a row, not a branch") or falls back to
## [constant NEED_WHY_BASE]'s bare word with no source suffix. Empty EXACTLY
## when nothing is urgent AND mood is [constant MoodBand.HAPPY] -- a
## Content-mood villager with nothing urgent still yields a string (this
## story's own "do not widen the empty case" warning). [enum WhySlotFeeder]
## + [constant WHY_STRING_PRECEDENCE_RANK] publish this module's own
## UI-slot precedence rank for the single why-slot (Villager AI's
## distress/trapped cue outranks this module's why, which outranks Build
## Validation's structural string) -- this module never arbitrates the
## other two feeders itself, that is Villager Info UI's own epic.
## `ground_trapped` has no production reporter yet (`villager-ai-018`'s ACs
## name only the other two ground values) -- its template is implemented
## and tested here anyway, exercised by mock until Villager AI reports it.
##
## Tick dispatch is driven EXCLUSIVELY by [member time_tick_system]'s `tick`
## signal (GDD: "all decay/recovery/mood math runs on Time & Tick events",
## TR-needs-mood-system-051), connected with Godot's plain synchronous
## default (never `CONNECT_DEFERRED`) -- load-bearing for story 003's
## intra-tick start/stop-before-F-pass ordering rule (GDD Core Rule 10).
## [method _on_tick] is the strict F1 -> F2 -> F3 skeleton this story lands;
## each pass is a documented no-op stub until its owning story (002/003/005)
## fills in the real body -- this story's own AC requires only that the
## entry point fires exactly once per tick, in that fixed order.
class_name NeedsMood
extends Node

## Fixed need schema (GDD Core Rule 2, TR-needs-mood-system-031): known from
## day one, same pattern as the item database's category set. Adding a need
## type is a design/code change, never a data edit -- this enum is
## deliberately NOT a config `@export` field.
enum Need { SLEEP, FOOD, COMPANY }

## The active-set subset of [enum Need] that actually carries values in MVP
## (GDD Core Rule 2: "MVP fills only sleep"). `mean_active` (story 005)
## iterates exactly this set -- an inactive need (FOOD/COMPANY) is never
## defaulted into any computation.
const ACTIVE_NEEDS: Array[Need] = [Need.SLEEP]

## Per-need queryable state (GDD "States and Transitions" table,
## TR-needs-mood-system-032/048). [constant RECOVERING] is wired by story
## needs-mood-003's `start_recovery` report -- this story's own state
## machine only ever transitions Satisfied <-> Urgent; the enum value
## exists now (not added later) so story 003 introduces no enum migration,
## matching this file's own F1/F2/F3 stub-now-fill-later precedent.
enum NeedState { SATISFIED, URGENT, RECOVERING }

## The recovery-source enum Villager AI reports via [method start_recovery]
## (GDD Core Rule 4, TR-needs-mood-system-035/036) -- fixed schema, same
## precedent as [enum Need]: the three `ground_*` values are separate schema
## members (the why-string, story 007's scope, needs to tell them apart) even
## though they share one rate row in [member _source_rate_table] below.
## Matches `docs/architecture/architecture.md`'s
## `start_recovery(villager_id, need, source_enum: RecoverySource)` /
## `stop_recovery` signatures (TD ruling NM-5) and Build Validation's
## `shelter_status_changed(item_cell, source_enum: RecoverySource)` verbatim.
enum RecoverySource {
	BED_SHELTERED,
	BED_UNSHELTERED,
	GROUND_NO_BED_OWNED,
	GROUND_BED_UNREACHABLE,
	GROUND_TRAPPED,
}

## [enum RecoverySource] <-> the external `StringName` id every reporter and
## this module's own [member _source_rate_table] actually key by -- mirrors
## [constant NEED_NAMES]'s pattern exactly. This is the ONLY place the fixed
## five-member enum touches the table: F2's rate lookup ([method
## _rate_for_source]) is keyed by [member NeedRecord.recovery_source_name]
## (a `StringName`), never by this enum directly, which is what keeps
## [member _source_rate_table] a genuinely open `Dictionary[StringName,
## float]` rather than a lookup hardwired to five compile-time values --
## AC10's "a brand-new source id works via table lookup with no code change"
## is a claim about THAT table (proven directly against it in this story's
## own test, `recovery_source_rate_table_test.gd`), not a claim that this
## production enum itself is ever extended without a code change (adding a
## sixth reported source IS a schema/code change here, exactly like [enum
## Need]'s own "adding a need type is a design change, not a data edit").
const RECOVERY_SOURCE_NAMES: Dictionary[RecoverySource, StringName] = {
	RecoverySource.BED_SHELTERED: &"bed_sheltered",
	RecoverySource.BED_UNSHELTERED: &"bed_unsheltered",
	RecoverySource.GROUND_NO_BED_OWNED: &"ground_no_bed_owned",
	RecoverySource.GROUND_BED_UNREACHABLE: &"ground_bed_unreachable",
	RecoverySource.GROUND_TRAPPED: &"ground_trapped",
}

## Recovery-source -> why-string-SUFFIX template table (GDD Core Rule 11,
## TR-needs-mood-system-045/046) -- DATA, keyed by the same `StringName` id
## [constant RECOVERY_SOURCE_NAMES] resolves and [member _source_rate_table]
## already keys by: "adding a source rung adds a row, not a branch" (this
## story's own Implementation Notes), never a hardcoded branch. Every entry
## here is the FULL "tired -- ..." string for [constant Need.SLEEP] (the only
## need with an owned base word today, [constant NEED_WHY_BASE]); a future
## need with its own base word gets its own template set the same way, never
## a second copy of this dictionary's shape.
##
## [constant RecoverySource.BED_SHELTERED] is DELIBERATELY absent: a
## sheltered sleeper has no fix to offer, so it -- and "not currently
## Recovering" (no reported source at all) -- falls through to [method
## _why_string_for_need]'s bare [constant NEED_WHY_BASE] word with NO source
## suffix, never a hardcoded special case. The `ground_trapped` row is
## implemented and tested here even though `villager-ai-018`'s ACs report
## only the other two ground values in production today -- getting this row
## wrong (e.g. reusing the `ground_no_bed_owned` string) is the exact
## "sends the player to build a second bed for a trapped villager" Pillar-4
## failure this story's own Implementation Notes name.
const WHY_STRING_TEMPLATES: Dictionary[StringName, String] = {
	&"ground_no_bed_owned": "tired — no bed",
	&"ground_bed_unreachable": "tired — bed unreachable",
	&"ground_trapped": "tired — trapped!",
	&"bed_unsheltered": "sleeping rough — no shelter",
}

## Mood band schema (GDD Core Rule 7, TR-needs-mood-system-039): a pure
## function of the smoothed mood value (see [method _band_for_mood]) against
## [member NeedsMoodConfig.mood_band_happy]/[member NeedsMoodConfig.
## mood_band_content] -- never a second copy of the boundaries, this table
## IS the display contract shared verbatim with Villager Info UI (ADR-0002).
## Declared in the GDD's own listed order (Happy, Content, Low); no ordinal
## comparison between members is ever meaningful, only [method
## _band_for_mood]'s threshold comparisons are.
enum MoodBand { HAPPY, CONTENT, LOW }

## The single why-slot's UI-slot precedence order (GDD Core Rule 11,
## TR-needs-mood-system-047): ONE display slot, THREE competing feeders.
## Declared as a single ordered enum (declaration order == precedence order,
## highest first) so a UI consumer compares feeders by ordinal rather than
## hardcoding an if/else chain. This module publishes ONLY its own member
## ([constant WHY_STRING_PRECEDENCE_RANK], read via [method
## get_why_string_precedence_rank]) -- it never arbitrates the other two
## feeders' strings itself (Villager Info UI's own epic, Out of Scope here).
enum WhySlotFeeder {
	VILLAGER_AI_DISTRESS,          ## Highest precedence -- the distress/trapped cue.
	NEEDS_MOOD_WHY,                ## This module's own [method get_why_string] output.
	BUILD_VALIDATION_STRUCTURAL,   ## Lowest -- building/bed context only, never here.
}

## This module's own rank within [enum WhySlotFeeder] -- the value [method
## get_why_string_precedence_rank] returns. A UI consumer compares this
## ordinal against the other two feeders' own published ranks (not exposed by
## this module) to resolve which of the (at most) three candidate strings
## wins the single why-slot.
const WHY_STRING_PRECEDENCE_RANK: WhySlotFeeder = WhySlotFeeder.NEEDS_MOOD_WHY


## One flat record per (villager_id, need) pair actually tracked -- created
## ONLY by [method set_need_value] (never as a side effect of a query, see
## [method has_urgent_need]'s own doc comment, NM-6). Keyed by a composite
## string (see [method _record_key]) rather than a nested
## `Dictionary[int, Dictionary[Need, NeedRecord]]` -- deliberately flat to
## avoid nested typed-Dictionary/Array surface area entirely; a single
## `Dictionary[String, NeedRecord]` keeps every lookup/iteration statically
## typed with zero unsafe casts.
class NeedRecord:
	extends RefCounted

	## Denormalized alongside the composite key so [method _pass_f1_decay]'s
	## iteration (which walks every tracked record, not a per-villager
	## sub-map) can still emit [signal need_urgent] with the right
	## `villager_id`/need name without parsing the key back apart.
	var villager_id: int = 0
	var need: Need = Need.SLEEP
	## Current need value, 0-100 (GDD F1). Only ever written by [method
	## set_need_value] (initialization/test seam) and [method
	## _pass_f1_decay] (per-tick decay) in this story's own scope --
	## story 003 adds the F2 recovery writer.
	var value: float = 100.0
	## Queryable per-need state (GDD States and Transitions table). Only
	## ever SATISFIED or URGENT in this story's own scope (see [enum
	## NeedState]'s own doc comment).
	var state: NeedState = NeedState.SATISFIED
	## The reported [enum RecoverySource]'s `StringName` id (see [constant
	## RECOVERY_SOURCE_NAMES]), re-read every F2 tick (GDD Core Rule 10 --
	## "re-reads the CURRENT source enum each tick", story 004's mid-recovery
	## re-rating). Empty (`&""`) whenever [member state] is not
	## [constant NeedState.RECOVERING] -- written only by [method
	## start_recovery] (sets it) and [method stop_recovery]/[method
	## _pass_f2_recovery]'s satisfied-cross branch (both clear it).
	var recovery_source_name: StringName = &""


## Per-villager smoothed-mood state (GDD F3). Created ONLY by [method
## set_mood_value] (this story's own initialization/test seam -- see that
## method's own doc comment for why this is NOT the GDD's F4 spawn-init
## feature) -- mirrors [NeedRecord]'s own "no lazy init" precedent exactly:
## [method _pass_f3_mood] only ever updates an EXISTING record, it never
## creates one for a villager nobody has told this module to track yet.
## Keyed by a flat `Dictionary[int, MoodRecord]` ([member _mood_records])
## rather than folded into [NeedRecord] -- mood is a per-villager aggregate,
## not a per-(villager, need) value, so a separate flat table (still a
## single, non-nested typed Dictionary) keeps the same static-typing
## discipline [NeedRecord]'s own doc comment argues for.
class MoodRecord:
	extends RefCounted

	## The current smoothed mood value, 0-100 (GDD F3). Written by [method
	## set_mood_value] (initialization/test seam) and [method _pass_f3_mood]
	## (the per-tick EMA step/snap) -- no other writer.
	var value: float = 0.0


## Need-enum <-> the external `StringName` need id every public query/report
## method in `docs/architecture/architecture.md`'s API Boundaries block
## actually uses (`get_need_value(villager_id, need: StringName)`,
## `start_recovery(villager_id, need: StringName, ...)`, etc.) -- [enum Need]
## itself stays an internal implementation detail, never exposed across the
## module boundary directly.
const NEED_NAMES: Dictionary[Need, StringName] = {
	Need.SLEEP: &"sleep",
	Need.FOOD: &"food",
	Need.COMPANY: &"company",
}

## The reverse of [constant NEED_NAMES] -- resolves an external caller's
## `StringName` need id back to the internal [enum Need] value. An
## unrecognized name is handled by every caller via `.has()` (never a
## sentinel int smuggled through a typed enum-valued lookup) -- see
## [method get_need_value]/[method get_need_state]/[method set_need_value].
const NEED_NAME_TO_ENUM: Dictionary[StringName, Need] = {
	&"sleep": Need.SLEEP,
	&"food": Need.FOOD,
	&"company": Need.COMPANY,
}

## Per-need base why-string word (GDD Core Rule 11's template table), keyed
## by [enum Need] -- read by [method _why_string_for_need] whenever a need's
## record is NOT currently [constant NeedState.RECOVERING], or IS Recovering
## via [constant RecoverySource.BED_SHELTERED] (absent from [constant
## WHY_STRING_TEMPLATES] by design): both cases are "the base string with no
## source suffix" per this story's own Implementation Notes. Only [constant
## Need.SLEEP] is configured this story's own TR scope covers (Core Rule 2:
## "MVP fills only sleep"), matching every other per-need MVP lookup already
## in this file ([method _decay_rate_for_need], [method
## _base_recovery_rate_for_need]) -- FOOD/COMPANY answer "" until a future
## story gives them their own base word.
const NEED_WHY_BASE: Dictionary[Need, String] = {
	Need.SLEEP: "tired",
}

## Edge-triggered "need is urgent" notification (GDD Core Rule 3,
## TR-needs-mood-system-033) -- a LATENCY HINT layered on top of the
## queryable state [method get_need_state]/[method has_urgent_need] already
## expose; fires exactly once per downward `urgency_threshold` cross, per
## (villager_id, need) -- never on equality, never a repeat while parked at
## or below the threshold (Edge Cases 2/4). A dropped connection must be
## harmless (ADR-0008: Villager AI polls state, never trusts this alone).
signal need_urgent(villager_id: int, need: StringName)

## Edge-triggered "need satisfied" notification (GDD Core Rule 3/10,
## TR-needs-mood-system-033/053) -- a LATENCY HINT, same status as [signal
## need_urgent]. Fires exactly once per upward `satisfied_threshold` cross
## while [constant NeedState.RECOVERING], emitted by [method
## _pass_f2_recovery] in the same tick the cross occurs; never re-fires
## afterward because that record is no longer RECOVERING (F2 skips
## non-Recovering records by construction, not by a separate dedup check --
## same "no repeat is possible by construction" argument [method
## _pass_f1_decay]'s own doc comment makes for [signal need_urgent]).
signal need_satisfied(villager_id: int, need: StringName)

## Edge-triggered "mood band changed" display notification (GDD Core Rule 7,
## States and Transitions "Mood bands" row, TR-needs-mood-system-049) --
## fires exactly once per tick a villager's [enum MoodBand] (derived purely
## from [method get_mood]'s smoothed value, see [method _band_for_mood])
## differs from what it was at the START of that tick's [method
## _pass_f3_mood] step; never coalesced, never a repeat while parked on one
## side of a boundary (mirrors [signal need_urgent]/[signal need_satisfied]'s
## own "no repeat is possible by construction" argument, applied here to a
## continuous derived value instead of a per-need threshold). The sole
## refresh trigger for Villager Info UI's band display -- steady-state reads
## come from [method get_mood]/[method get_mood_band] verbatim, never from
## this signal's payload alone (same latency-hint status as the need
## signals).
signal mood_band_changed(villager_id: int, band: MoodBand)

## Tuning config (ADR-0002). Wired via a scene file's Inspector in
## production, or assigned directly in a headless test. Asserted wired by
## [method setup] -- never read inside `_ready()`.
@export var config: NeedsMoodConfig

## Time & Tick System dependency (ADR-0001). Deliberately NOT `@export`ed --
## `TimeTickSystem` is Autoload-tier and per ADR-0001 is never injected via
## the Inspector. Duck-typed against the one member [method setup] needs:
## `signal tick()`. Mirrors [VillagerAi.time_tick_system]'s and
## [ConstructionTickLoop.time_tick_system]'s established precedent exactly:
## a headless test assigns a mock double directly before calling
## [method setup]; production resolves the real Autoload lazily.
var time_tick_system: Object = null

## Per-(villager_id, need) simulation state (GDD F1 + States/Transitions
## table). See [NeedRecord]'s own doc comment for the flat composite-key
## design rationale. A record is created ONLY by [method set_need_value] --
## every query method ([method has_urgent_need], [method get_need_value],
## [method get_need_state]) reads with `.get(key, null)` and never inserts
## (NM-6's "no lazy record init" guarantee, extended here to the sibling
## queries for the same consistency reason even though NM-6 only strictly
## requires it of has_urgent_need).
var _need_records: Dictionary[String, NeedRecord] = {}

## Per-villager smoothed-mood state (GDD F3). See [MoodRecord]'s own doc
## comment for why this is a SEPARATE flat `Dictionary[int, MoodRecord]`
## rather than folded into [member _need_records] -- mood is a per-villager
## aggregate, not a per-(villager, need) value. A record is created ONLY by
## [method set_mood_value]; [method _pass_f3_mood] updates existing records
## only, it never lazily creates one (mirrors [member _need_records]'s own
## "created ONLY by set_need_value" invariant).
var _mood_records: Dictionary[int, MoodRecord] = {}

## F2's source->rate table (GDD Core Rule 4; Implementation Notes: "built
## once from config at setup() -- five enum keys today, three distinct
## values"). Built exactly once, in [method setup], from [member config]'s
## POST-validate/clamp values -- never rebuilt per tick (Control Manifest
## Guardrail: "F2 is an O(1) table lookup per recovering need per tick; the
## table is read, never rebuilt per tick"). Deliberately `Dictionary[
## StringName, float]` rather than `Dictionary[RecoverySource, float]`: this
## is what lets [method _rate_for_source] be a genuine generic lookup that a
## test can extend with a key [enum RecoverySource] does not (yet) name
## (AC10) without touching this module's code -- see [constant
## RECOVERY_SOURCE_NAMES]'s own doc comment for why the production enum
## stays closed while this table stays open.
var _source_rate_table: Dictionary[StringName, float] = {}

## True once [method setup] has completed at least once.
var _is_set_up: bool = false

## The BLOCKING-tagged subset of the most recent `config.validate()` result,
## if any. Populated by [method setup]; read by [GameWorld]'s boot gate via
## [method get_boot_blocking_issues] (ADR-0002/0005).
var _boot_blocking_issues: Array[String] = []

## Number of times [method _on_tick] has run. Test-observability only --
## proves "the F-pass entry point runs exactly once" per tick dispatch, this
## story's own AC.
var _tick_pass_count: int = 0

## The pass names [method _on_tick] ran, in the order it ran them, reset at
## the start of every call. Test-observability only -- proves the strict
## F1 -> F2 -> F3 call order this story's AC requires.
var _last_tick_pass_order: Array[StringName] = []


## Explicitly callable wiring/validation entry point (ADR-0001). Asserts
## [member config] and a [member time_tick_system]-shaped dependency are
## wired, applies ADR-0002's two-tier `validate()` policy exactly like
## [BuildValidation]/[ReferenceConfigConsumer], then connects this module's
## tick dispatch to the sole global tick broadcast (`TimeTickSystem.tick`,
## plain synchronous default connection -- never `CONNECT_DEFERRED`).
func setup() -> void:
	assert(config != null, "NeedsMood.config not wired")
	if time_tick_system == null:
		time_tick_system = get_node_or_null(^"/root/TimeTickSystem")
	assert(
		time_tick_system != null,
		"NeedsMood requires a TimeTickSystem-shaped dependency (assign a mock in"
		+ " tests; the real Autoload is registered project-wide) before setup() can"
		+ " connect tick dispatch"
	)
	var issues: Array[String] = config.validate()
	_boot_blocking_issues = issues.filter(
		func(issue: String) -> bool: return issue.begins_with(ConfigResource.BLOCKING_PREFIX)
	)
	for issue: String in issues:
		if not issue.begins_with(ConfigResource.BLOCKING_PREFIX):
			push_warning(issue)
	# F2's source->rate table (GDD Core Rule 4) -- built once, here, from
	# config's POST-validate/clamp values (deliberately after validate() so a
	# clamped ground_penalty/unsheltered_bed_multiplier is what F2 ever reads).
	# The three ground_* enum ids share one rate row by construction (a single
	# dictionary value written three times), never a hardcoded branch.
	_source_rate_table = {
		&"bed_sheltered": 1.0,
		&"bed_unsheltered": config.unsheltered_bed_multiplier,
		&"ground_no_bed_owned": config.ground_penalty,
		&"ground_bed_unreachable": config.ground_penalty,
		&"ground_trapped": config.ground_penalty,
	}
	@warning_ignore("unsafe_property_access")
	time_tick_system.tick.connect(_on_tick)
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Returns the BLOCKING-tagged issues (if any) found in the most recent
## `config.validate()` call. [GameWorld]'s boot gate duck-types this method
## on every injected-tier module after calling `setup()` (ADR-0002 Decision,
## ADR-0005 reuse) -- a non-empty result triggers the same terminal boot-halt
## path used for RID's Failed outcome, no new severity model, no new halt
## mechanism. Under a violated ladder invariant (AC29), this is the
## mechanism by which the module "does not proceed to normal operation":
## [GameWorld] halts before reaching ACTIVE, so no production tick is ever
## dispatched into this module.
func get_boot_blocking_issues() -> Array[String]:
	return _boot_blocking_issues


## Number of times [method _on_tick] has fired since [method setup]. Test
## observability only -- not part of any other module's contract.
func get_tick_pass_count() -> int:
	return _tick_pass_count


## The most recent tick's pass order (see [member _last_tick_pass_order]).
## Test observability only.
func get_last_tick_pass_order() -> Array[StringName]:
	return _last_tick_pass_order


## Story needs-mood-002, TD ruling NM-6 (`production/architecture-
## decisions-m02-preflight-2026-07-26.md`; canonized into
## `docs/architecture/architecture.md`'s Needs & Mood API Boundaries block).
## Returns whether ANY of [constant ACTIVE_NEEDS] currently reads
## [constant NeedState.URGENT] for `villager_id` -- the queryable state,
## never a cached event (Core Rule 3). This is [VillagerAi]'s tier-1
## priority gate (`villager_ai.gd`'s `needs_provider.has_urgent_need`,
## `_has_urgent_need()`), matched here verbatim in name and arity.
##
## GUARANTEE (NM-6, asserted by this story's own test suite, not merely
## documented): emits no signal, mutates no state, and never lazily
## initializes a villager's need record as a side effect of being asked. An
## unknown/despawned `villager_id` -- one with no tracked record at all --
## returns `false` WITHOUT creating one; nil-safety for an unwired provider
## belongs to the CALLER ([method VillagerAi._has_urgent_need]'s existing
## guard), never to a null-provider branch here.
func has_urgent_need(villager_id: int) -> bool:
	for need_enum: Need in ACTIVE_NEEDS:
		var need_name: StringName = NEED_NAMES.get(need_enum, &"")
		var key: String = _record_key(villager_id, need_name)
		if _need_records.has(key) and _need_records[key].state == NeedState.URGENT:
			return true
	return false


## `docs/architecture/architecture.md` API Boundaries:
## `get_need_value(villager_id: int, need: StringName) -> float`. Read-only;
## never creates a record for an untracked villager or an unrecognized need
## name -- both answer the same safe, non-urgent default (100.0, "fully
## satisfied") a fresh spawn would start at (GDD F4), consistent with
## [method has_urgent_need]'s own "unknown answers as if fine, never
## crashes" bias.
func get_need_value(villager_id: int, need: StringName) -> float:
	if not NEED_NAME_TO_ENUM.has(need):
		return 100.0
	var key: String = _record_key(villager_id, need)
	if not _need_records.has(key):
		return 100.0
	return _need_records[key].value


## The "per-need state query" this story's own AC list requires alongside
## [method get_need_value] (not yet named in `architecture.md`'s API
## Boundaries block -- the GDD's own query-API section/TR is a non-blocking
## follow-up per NM-6). Same unknown-id/unknown-need default bias as
## [method get_need_value]: [constant NeedState.SATISFIED], never an error.
func get_need_state(villager_id: int, need: StringName) -> NeedState:
	if not NEED_NAME_TO_ENUM.has(need):
		return NeedState.SATISFIED
	var key: String = _record_key(villager_id, need)
	if not _need_records.has(key):
		return NeedState.SATISFIED
	return _need_records[key].state


## `docs/architecture/architecture.md` API Boundaries:
## `get_mood(villager_id: int) -> float` (GDD F3, TR-needs-mood-system-038).
## Read-only, EMA-smoothed 0-100 value; never creates a record for an
## untracked villager -- same "unknown answers as if fine, never crashes"
## bias as [method get_need_value]/[method get_need_state] (100.0, "fully
## satisfied," matching a fresh spawn's F4 starting point once that story
## lands).
func get_mood(villager_id: int) -> float:
	if not _mood_records.has(villager_id):
		return 100.0
	return _mood_records[villager_id].value


## The mood-band query this story's own AC list requires alongside
## [method get_mood] (not yet named in `architecture.md`'s API Boundaries
## block -- same non-blocking follow-up status [method get_need_state]'s own
## doc comment notes for its sibling). Pure function of the tracked mood
## value via [method _band_for_mood]; same unknown-id default bias as
## [method get_mood] ([constant MoodBand.HAPPY], the "fine" default, never an
## error).
func get_mood_band(villager_id: int) -> MoodBand:
	if not _mood_records.has(villager_id):
		return MoodBand.HAPPY
	return _band_for_mood(_mood_records[villager_id].value)


## Returns this module's published UI-slot precedence rank (see [enum
## WhySlotFeeder]/[constant WHY_STRING_PRECEDENCE_RANK]'s own doc comments,
## TR-needs-mood-system-047). Pure, no side effects, no `villager_id` --
## the rank is fixed data, not per-villager state.
func get_why_string_precedence_rank() -> WhySlotFeeder:
	return WHY_STRING_PRECEDENCE_RANK


## `docs/architecture/architecture.md` API Boundaries: `get_why_string(
## villager_id: int) -> String` (GDD Core Rule 11, TR-needs-mood-system-
## 045/046/064). Pure query, O(active needs), no allocation-heavy formatting
## (Control Manifest Guardrail) -- two inputs, one output, NO history/caching
## (Implementation Notes): (1) [method _strongest_drain_record] picks the
## strongest current drain; (2) [method _why_string_for_need] reads that
## need's CURRENTLY reported recovery source fresh, every call.
##
## Empty EXACTLY when nothing is urgent ([method has_urgent_need]) AND mood
## is [constant MoodBand.HAPPY] ([method get_mood_band]) -- a Content-mood
## villager with nothing urgent still yields a string per the selection rule
## (this story's own "do not widen the empty case" warning). An unknown
## villager id (no tracked records at all: [method has_urgent_need] reads
## false, [method get_mood_band] defaults HAPPY) falls straight into this
## same empty branch -- the "unknown answers as if fine" bias every sibling
## query in this file shares, here landing on the empty string rather than a
## distinct default. Never errors on an unrecognized/untracked id.
func get_why_string(villager_id: int) -> String:
	if not has_urgent_need(villager_id) and get_mood_band(villager_id) == MoodBand.HAPPY:
		return ""
	var strongest: NeedRecord = _strongest_drain_record(villager_id)
	if strongest == null:
		return ""
	return _why_string_for_need(strongest.need, strongest)


## Initialization/test seam -- the ONE entry point that creates a
## (villager_id, need) record (see [member _need_records]'s own doc
## comment). Deliberately NOT this story's F4 spawn-initialization feature
## (TR-needs-mood-system-056 is out of this story's TR list) -- a future
## spawn story calls this once per active need at 100.0, exactly like this
## story's own tests do to arrange a "Given value = ..." precondition.
## Clamps to the declared 0-100 domain and derives [enum NeedState] purely
## from the clamped value against [member NeedsMoodConfig.urgency_threshold]
## (`Satisfied` if strictly above, `Urgent` otherwise, per the GDD's own
## State table) -- this is initialization, never a "cross" (Edge Case 4's
## "crossing, not equality" applies to TICKS; assigning a value out of band
## is not a tick and never emits [signal need_urgent], regardless of which
## side of the threshold the new value lands on.
func set_need_value(villager_id: int, need: StringName, value: float) -> void:
	if not NEED_NAME_TO_ENUM.has(need):
		return
	var need_enum: Need = NEED_NAME_TO_ENUM[need]
	var key: String = _record_key(villager_id, need)
	if not _need_records.has(key):
		var new_record := NeedRecord.new()
		new_record.villager_id = villager_id
		new_record.need = need_enum
		_need_records[key] = new_record
	var record: NeedRecord = _need_records[key]
	record.value = clampf(value, 0.0, 100.0)
	record.state = NeedState.SATISFIED if record.value > config.urgency_threshold else NeedState.URGENT


## `docs/architecture/architecture.md` API Boundaries (TD ruling NM-5, the
## villager-id three-arg form): the SOLE entry into [constant
## NeedState.RECOVERING] (GDD Core Rule 10, TR-needs-mood-system-042/034).
## Villager AI (the only production caller) reports via a discrete call per
## activity start -- never a per-tick push. Stores the reported
## [param source_enum] as its `StringName` id on the record (re-read fresh by
## [method _pass_f2_recovery] every tick, never captured once -- Core Rule 10
## / story 004's mid-recovery re-rating); calling this again with the SAME
## source while already Recovering is idempotent BY CONSTRUCTION (re-writing
## an identical value), no special-case branch needed.
##
## A villager_id/need with no tracked record is a documented no-op (mirrors
## [member _need_records]'s own "created ONLY by [method set_need_value]"
## invariant -- there is no sensible value to recover FROM for a need this
## module has never been told about); an unrecognized [param need] name is
## the same safe no-op [method get_need_value]/[method set_need_value] apply.
## An unrecognized [param source_enum] fails loudly (`assert`) rather than
## silently defaulting -- there is no legal [enum RecoverySource] value this
## can occur for today (every member is in [constant RECOVERY_SOURCE_NAMES]
## by construction); the guard exists for the same defensive reason
## [method setup]'s asserts do.
func start_recovery(villager_id: int, need: StringName, source_enum: RecoverySource) -> void:
	if not NEED_NAME_TO_ENUM.has(need):
		return
	assert(
		RECOVERY_SOURCE_NAMES.has(source_enum),
		"NeedsMood.start_recovery: unrecognized RecoverySource enum value %s" % source_enum
	)
	var key: String = _record_key(villager_id, need)
	if not _need_records.has(key):
		return
	var record: NeedRecord = _need_records[key]
	record.state = NeedState.RECOVERING
	record.recovery_source_name = RECOVERY_SOURCE_NAMES[source_enum]


## `docs/architecture/architecture.md` API Boundaries:
## `stop_recovery(villager_id: int, need: StringName, reason: StringName) ->
## void` (TD ruling NM-5). Revokes/interrupts a Recovering need (GDD Edge
## Case 1/3) -- a documented no-op for an untracked villager_id, an
## unrecognized need name, or a need that is not currently
## [constant NeedState.RECOVERING] (the story's own named edge case: "a
## documented no-op"). [param reason] is accepted but not yet consumed here
## (a future why-string/logging consumer, story 007) -- the signature is
## fixed now per NM-5 so no later signature migration is needed.
##
## Transition is purely by CURRENT value (Edge Case 1, no new signal either
## way): strictly above [member NeedsMoodConfig.urgency_threshold] ->
## Satisfied (decay resumes silently); at or below -> Urgent (the original
## downward-cross edge already fired earlier and is not re-emitted here).
## Per Core Rule 10's intra-tick ordering this write lands synchronously,
## before the next dispatched tick's F-pass -- so an interruption this tick
## credits ZERO recovery for that same tick (F2 simply never sees this
## record as RECOVERING again).
func stop_recovery(villager_id: int, need: StringName, reason: StringName) -> void:
	if not NEED_NAME_TO_ENUM.has(need):
		return
	var key: String = _record_key(villager_id, need)
	if not _need_records.has(key):
		return
	var record: NeedRecord = _need_records[key]
	if record.state != NeedState.RECOVERING:
		return
	record.recovery_source_name = &""
	record.state = NeedState.SATISFIED if record.value > config.urgency_threshold else NeedState.URGENT


## Initialization/test seam -- the ONE entry point that creates a
## per-villager [MoodRecord] (see [member _mood_records]'s own doc comment).
## Deliberately NOT this story's own F4 spawn-initialization feature (that
## remains story needs-mood-006's scope, `mood <- mean_active` tied
## specifically to villager spawn) -- a future spawn story calls this once
## per spawned villager with its own computed `mean_active`, exactly like
## this story's own tests do to arrange a "Given mood = ..." precondition
## (mirrors [method set_need_value]'s own doc comment precedent exactly).
## Clamps to the declared 0-100 domain; never emits [signal mood_band_changed]
## regardless of which band the assigned value lands in -- assigning a value
## out of band is initialization, never a "cross" (same argument [method
## set_need_value]'s own doc comment makes for [signal need_urgent]).
func set_mood_value(villager_id: int, value: float) -> void:
	if not _mood_records.has(villager_id):
		_mood_records[villager_id] = MoodRecord.new()
	_mood_records[villager_id].value = clampf(value, 0.0, 100.0)


## Story needs-mood-006, GDD F4 (TR-needs-mood-system-056) + Edge Case 5
## (TR-needs-mood-system-061, AC26) -- the ONE production entry point for
## spawn initialization. Called once per starting villager from the boot path
## (`docs/architecture/architecture.md`'s Initialization Order step 8, "Needs
## & Mood initializes (F4 spawn-init per starting villager)"), and again --
## the SAME method, deliberately -- whenever a schema revision activates a
## need an existing villager does not yet track (Edge Case 5: "the new need
## initializes at 100 and `mean_active` simply gains a term").
##
## Two-line body, per Implementation Notes ("F4 is two lines and one trap"):
## 1. Every [param active_needs] member with no existing record is seeded at
##    100.0 via [method set_need_value] (SATISFIED, since 100 is always above
##    [member NeedsMoodConfig.urgency_threshold]) -- an ALREADY-tracked need
##    (this villager's own prior initialization, or a value a test arranged
##    directly) is left completely untouched, never overwritten. This is what
##    makes AC26's "sleep untouched, food seeded at 100" and the story's own
##    idempotence requirement ("calling this twice for the same villager does
##    not silently reset live values") the SAME guarantee, not two separate
##    branches.
## 2. Mood initializes to `mean_active` ONLY the first time this runs for
##    `villager_id` (no [MoodRecord] yet) -- reusing [method
##    _mean_active_need_value] verbatim so the two formulas can never diverge
##    (Implementation Notes' own "the trap is the second line" warning). An
##    already-existing [MoodRecord] (a villager whose mood has been ticking)
##    is NEVER rewritten here -- re-running F4's mood formula against a
##    villager that already has one is the Control Manifest's own named
##    Forbidden pattern (would erase story needs-mood-012's future
##    load-restored smoothing state). A degenerate `active_needs` with no
##    active needs at all (or one whose members were all already tracked from
##    a fresh [MoodRecord]) yields [method _mean_active_need_value]'s own
##    `-1.0` "no active need has data" sentinel -- this method reads that as
##    "nothing to initialize mood from yet" and leaves [member _mood_records]
##    untouched rather than dividing by zero or defaulting to a literal (the
##    story's own named degenerate-config edge case: "a documented,
##    non-crashing mood").
##
## [param active_needs] defaults to [constant ACTIVE_NEEDS] -- production
## NEVER passes a second argument. The override exists solely so this story's
## own test suite can exercise the new-need-activation path (AC26's "mocked
## schema change") deterministically, without mutating the real schema
## constant (which this codebase treats as fixed, GDD Core Rule 2: "adding a
## need type is a design change, not a data edit").
##
## GUARANTEE (this story's own AC): never emits [signal need_urgent], [signal
## need_satisfied], or [signal mood_band_changed] on either branch --
## [method set_need_value]/[method set_mood_value] both already document
## "initialization is never a cross," and this method's own logic never
## drives an [enum NeedState]/[enum MoodBand] transition either (a brand-new
## record cannot "transition" from nothing).
func initialize_villager(villager_id: int, active_needs: Array[Need] = ACTIVE_NEEDS) -> void:
	for need_enum: Need in active_needs:
		var need_name: StringName = NEED_NAMES.get(need_enum, &"")
		var key: String = _record_key(villager_id, need_name)
		if not _need_records.has(key):
			set_need_value(villager_id, need_name, 100.0)
	if not _mood_records.has(villager_id):
		var mean_active: float = _mean_active_need_value(villager_id, active_needs)
		if mean_active >= 0.0:
			set_mood_value(villager_id, mean_active)


## Composite storage key for [member _need_records] (see [NeedRecord]'s own
## doc comment for why this is flat rather than nested).
static func _record_key(villager_id: int, need: StringName) -> String:
	return "%d:%s" % [villager_id, need]


## F1's per-need decay rate lookup (GDD Core Rule 1: "decay_per_tick
## [need]"). Only [constant Need.SLEEP] has a real configured rate this
## story's own TR scope covers (Core Rule 2: "MVP fills only sleep with
## values") -- FOOD/COMPANY answer 0.0 (inert, never decays) until their own
## future story adds a knob; this is honest MVP behavior, not a stub
## shortcut, since a record for either can only exist at all via [method
## set_need_value] (no production caller does that yet).
func _decay_rate_for_need(need: Need) -> float:
	match need:
		Need.SLEEP:
			return config.decay_per_tick_sleep
		_:
			return 0.0


## F2's per-need base-recovery-rate lookup (GDD F2:
## `base_recovery_per_tick[need]`) -- same "only SLEEP is configured in MVP"
## shape as [method _decay_rate_for_need], for the identical reason (Core
## Rule 2).
func _base_recovery_rate_for_need(need: Need) -> float:
	match need:
		Need.SLEEP:
			return config.base_recovery_per_tick_sleep
		_:
			return 0.0


## F2's source->rate multiplier lookup (GDD Core Rule 4) -- a pure
## `Dictionary[StringName, float]` read against [member _source_rate_table],
## never a hardcoded bed/ground branch (Control Manifest Forbidden pattern;
## AC10/AC65). Fails LOUDLY (`assert`) when [param source_name] is not a key
## in the table, rather than silently defaulting to `1.0` (the story's own
## named edge case: "an unknown source enum fails loudly rather than
## silently recovering at 1.0") -- every [enum RecoverySource] member
## [method start_recovery] can ever write resolves to one of the five keys
## [method setup] populates, so this can only trip for a source name written
## directly into a record outside the production API (a test-only scenario
## proving the guard, see `recovery_source_rate_table_test.gd`).
func _rate_for_source(source_name: StringName) -> float:
	assert(
		_source_rate_table.has(source_name),
		(
			"NeedsMood._pass_f2_recovery: unrecognized recovery source '%s' -- not"
			+ " present in the source->rate table (TR-needs-mood-system-035/065)"
		) % source_name
	)
	return _source_rate_table.get(source_name, 0.0)


## F3's `mean_active` term (GDD Formulas F3, TR-needs-mood-system-055):
## the unweighted arithmetic mean over [constant ACTIVE_NEEDS] whose record
## actually exists for `villager_id` -- an inactive schema need (FOOD/COMPANY
## pre-tier, Core Rule 2) is never in [constant ACTIVE_NEEDS] at all in MVP,
## so it can never contribute a term OR change the divisor, satisfying AC20
## by construction rather than a separate exclusion branch. Returns `-1.0`
## (an otherwise-impossible value in the declared 0-100 domain) when NO
## active need has a tracked record yet -- the sentinel [method
## _pass_f3_mood] reads to skip that villager's mood update entirely this
## tick, rather than dividing by zero or defaulting a term.
##
## [param active_needs] defaults to [constant ACTIVE_NEEDS] -- [method
## _pass_f3_mood] always calls with zero arguments beyond `villager_id`. The
## override exists solely so [method initialize_villager] (story
## needs-mood-006) can reuse this SAME formula for its own mocked-schema test
## path (see that method's own doc comment) without a second, divergent copy
## of the mean calculation.
func _mean_active_need_value(villager_id: int, active_needs: Array[Need] = ACTIVE_NEEDS) -> float:
	var sum: float = 0.0
	var count: int = 0
	for need_enum: Need in active_needs:
		var need_name: StringName = NEED_NAMES.get(need_enum, &"")
		var key: String = _record_key(villager_id, need_name)
		if _need_records.has(key):
			sum += _need_records[key].value
			count += 1
	if count == 0:
		return -1.0
	return sum / float(count)


## Pure mood-band derivation (GDD Core Rule 7, States and Transitions "Mood
## bands" row): compares the smoothed value against [member
## NeedsMoodConfig.mood_band_happy]/[member NeedsMoodConfig.mood_band_content]
## only -- `>=` both ways, never `>`, so a value landing exactly on a
## boundary resolves to the HIGHER band (AC19: exactly 70.00 is Happy,
## exactly 40.00 is Content). [member NeedsMoodConfig.band_display_hysteresis]
## is deliberately NOT read here -- Implementation Notes: "wired but inert,"
## Edge Case 10 is a reserve enabled only by a future story if playtests show
## boundary flapping, never by this one.
func _band_for_mood(mood: float) -> MoodBand:
	if mood >= config.mood_band_happy:
		return MoodBand.HAPPY
	elif mood >= config.mood_band_content:
		return MoodBand.CONTENT
	return MoodBand.LOW


## First half of [method get_why_string]'s selection rule (GDD Core Rule 11,
## Implementation Notes "two inputs, one output"): which need is the
## strongest current drain -- the LOWEST tracked value across every need
## this `villager_id` has ANY record for, tie-broken by [enum Need]'s OWN
## declared order (sleep > food > company, via [constant NEED_NAMES]'s
## insertion order) using a STRICT `<` comparison so an earlier-iterated tie
## is never displaced by a later, equal-valued need.
##
## Deliberately NOT gated by [constant ACTIVE_NEEDS] -- a schema-inactive
## need (food/company pre-tier) can still be tracked directly via [method
## set_need_value] (this story's own test double for "a mocked active
## need"), and the selection rule must honor it the same as a real MVP
## sleep record. Returns `null` (never lazily creating a record, the same
## "no lazy init" bias every sibling query in this file shares) when this
## villager has no tracked need record at all -- [method get_why_string]
## reads that as "nothing to describe."
##
## Returns the [NeedRecord] itself (not a separate `Need`/value pair) so the
## caller can read [member NeedRecord.need] straight off it -- reusing the
## record's own denormalized field rather than a second lookup.
func _strongest_drain_record(villager_id: int) -> NeedRecord:
	var strongest: NeedRecord = null
	for need_enum: Need in NEED_NAMES.keys():
		var need_name: StringName = NEED_NAMES[need_enum]
		var key: String = _record_key(villager_id, need_name)
		if _need_records.has(key):
			var record: NeedRecord = _need_records[key]
			if strongest == null or record.value < strongest.value:
				strongest = record
	return strongest


## Second half of [method get_why_string]'s selection rule: the reported
## [enum RecoverySource]'s template for `record` (GDD Core Rule 11's
## template table, [constant WHY_STRING_TEMPLATES]), or `need_enum`'s own
## base word with NO source suffix when `record` is NOT currently
## [constant NeedState.RECOVERING] -- covers BOTH "bed_sheltered" (Recovering,
## no suffix by design -- absent from [constant WHY_STRING_TEMPLATES]) and
## "not currently sleeping" (not Recovering at all) in the SAME fallback,
## per Implementation Notes ("both produce the base string with no source
## suffix"). Reads `record.recovery_source_name` fresh every call -- no
## history, no caching (Core Rule 10's "re-reads the CURRENT source enum
## each tick", applied here to a query instead of a tick pass).
func _why_string_for_need(need_enum: Need, record: NeedRecord) -> String:
	var base: String = NEED_WHY_BASE.get(need_enum, "")
	if record.state == NeedState.RECOVERING:
		return WHY_STRING_TEMPLATES.get(record.recovery_source_name, base)
	return base


## F1 -- need decay (GDD Formulas: `value <- max(0, value -
## decay_per_tick[need])`, TR-needs-mood-system-030), plus the
## edge-triggered `urgency_threshold` downward-cross detection layered on
## top (GDD Core Rule 3, TR-needs-mood-system-033). Story needs-mood-002's
## own scope -- F2 recovery ([method _pass_f2_recovery]) and F3 mood
## smoothing ([method _pass_f3_mood]) remain story 003/005 stubs, untouched
## here.
##
## Crossing compares the PRE-tick value vs the POST-tick value against
## [member NeedsMoodConfig.urgency_threshold] (`>` then `<=`, never `==`) --
## Edge Case 4's "a value parked at 25.0 emits nothing new" falls out of
## this comparison directly: once `state == URGENT`, `previous_value` can
## never again read `> threshold` without a recovery report ([constant
## NeedState.RECOVERING], story 003's scope, never entered anywhere in this
## story's own code -- AC12's own negative-space proof), so no repeat
## emission is possible by construction, not by a separate dedup check.
## Skips any record already `RECOVERING` (F1's own "except while Recovering"
## clause) -- always true today since nothing sets that state yet, but
## written now so story 003 needs no edit here.
func _pass_f1_decay() -> void:
	_last_tick_pass_order.append(&"f1_decay")
	for key: String in _need_records.keys():
		var record: NeedRecord = _need_records[key]
		if record.state == NeedState.RECOVERING:
			continue
		var previous_value: float = record.value
		var rate: float = _decay_rate_for_need(record.need)
		record.value = maxf(0.0, previous_value - rate)
		if previous_value > config.urgency_threshold and record.value <= config.urgency_threshold:
			record.state = NeedState.URGENT
			need_urgent.emit(record.villager_id, NEED_NAMES.get(record.need, &""))


## F2 -- need recovery via the source-rate table (GDD Formulas: `value <-
## min(100, value + base_recovery_per_tick[need] * source_multiplier)`,
## TR-needs-mood-system-053), plus the edge-triggered `satisfied_threshold`
## upward-cross detection (GDD Core Rule 3). Only ever touches records
## currently [constant NeedState.RECOVERING] -- F1 already skips those, so
## a need is decayed XOR recovered on any given tick, never both (the story's
## own "no-decay-while-Recovering" requirement falls out of the two passes'
## mutually exclusive record filters, not a separate guard here).
##
## Crossing compares the PRE-tick value vs the POST-tick (clamped) value
## against [member NeedsMoodConfig.satisfied_threshold] (`<` then `>=`) --
## the mirror of [method _pass_f1_decay]'s own crossing comparison, upward
## instead of downward. The domain clamp (`minf(100.0, ...)`, AC33) is
## applied BEFORE the crossing check, so an overshoot that would exceed 100
## is capped first and the satisfied cross still fires off the capped value
## (100.0 can only ever satisfy-cross a threshold <= 100.0, never miss it).
## On the cross: state -> Satisfied, [signal need_satisfied] emits exactly
## once, and [member NeedRecord.recovery_source_name] clears -- symmetric to
## [method stop_recovery]'s own clear. The value itself is left exactly
## where F2 landed it (AC11's "overshoot retained, never clamped back to the
## threshold").
func _pass_f2_recovery() -> void:
	_last_tick_pass_order.append(&"f2_recovery")
	for key: String in _need_records.keys():
		var record: NeedRecord = _need_records[key]
		if record.state != NeedState.RECOVERING:
			continue
		var rate: float = _rate_for_source(record.recovery_source_name)
		var previous_value: float = record.value
		var base_rate: float = _base_recovery_rate_for_need(record.need)
		record.value = minf(100.0, previous_value + base_rate * rate)
		if previous_value < config.satisfied_threshold and record.value >= config.satisfied_threshold:
			record.state = NeedState.SATISFIED
			record.recovery_source_name = &""
			need_satisfied.emit(record.villager_id, NEED_NAMES.get(record.need, &""))


## F3 -- mood smoothing (GDD Formulas F3, TR-needs-mood-system-038/054/055).
## Runs once per villager per tick, AFTER this same tick's F1/F2 have already
## written their values (Control Manifest Guardrail) -- [method
## _mean_active_need_value] reads [member _need_records] fresh every call, so
## a need recovering this very tick feeds its POST-recovery value into
## `mean_active`, never the pre-tick one.
##
## Only ever updates a villager that already has a [MoodRecord] (see [member
## _mood_records]'s own "created ONLY by [method set_mood_value]" doc
## comment) -- a villager with need data but no mood record yet is silently
## skipped this tick, same "no lazy init" bias [method _mean_active_need_value]
## applies via its own `-1.0` sentinel for a villager with no active need data
## at all.
##
## The snap rule (AC15/16, TR-needs-mood-system-054) is an explicit branch
## BEFORE the EMA step, not a rounding of its result: `abs(mean_active - mood)
## < 0.05` snaps directly to `mean_active` (defeating the asymptote that would
## otherwise leave mood parked just under a band boundary forever); everything
## else takes the EMA step with explicit float division
## (`/ config.mood_smoothing_ticks`, never integer division -- Engine Notes).
## A delta of EXACTLY `0.05` takes the EMA branch, never the snap (`<`, not
## `<=` -- the story's own named edge case).
##
## Band crossing (AC18/19) compares [method _band_for_mood] of the PRE-tick
## value against the POST-tick value -- the same "compare the two endpoints,
## no separate dedup flag" pattern [method _pass_f1_decay]/[method
## _pass_f2_recovery] already establish for their own threshold crosses,
## applied here to a continuous derived value instead of a raw threshold.
## [signal mood_band_changed] emits at most once per villager per tick.
func _pass_f3_mood() -> void:
	_last_tick_pass_order.append(&"f3_mood")
	for villager_id: int in _mood_records.keys():
		var mean_active: float = _mean_active_need_value(villager_id)
		if mean_active < 0.0:
			continue
		var record: MoodRecord = _mood_records[villager_id]
		var previous_mood: float = record.value
		var previous_band: MoodBand = _band_for_mood(previous_mood)
		if absf(mean_active - previous_mood) < 0.05:
			record.value = mean_active
		else:
			record.value = previous_mood + (mean_active - previous_mood) / config.mood_smoothing_ticks
		var new_band: MoodBand = _band_for_mood(record.value)
		if new_band != previous_band:
			mood_band_changed.emit(villager_id, new_band)


## The sole tick-dispatch entry point (GDD: "all decay/recovery/mood math
## runs on Time & Tick events"). Runs the strict F1 -> F2 -> F3 pass order
## exactly once per broadcast tick -- this story's scope is the skeleton
## only; see [method _pass_f1_decay]/[method _pass_f2_recovery]/
## [method _pass_f3_mood]'s own doc comments.
func _on_tick() -> void:
	_tick_pass_count += 1
	_last_tick_pass_order = []
	_pass_f1_decay()
	_pass_f2_recovery()
	_pass_f3_mood()
