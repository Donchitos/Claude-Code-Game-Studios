## Build Validation & Navigability module scaffold (Story build-validation-001,
## ADR-0001 injected-tier DI + ADR-0002 config; ADR-0007 walkability-
## consumption contract). This story's scope is EXACTLY the config resource +
## DI scaffold + the AC27 blocking lockstep invariant -- no candidate-cell
## predicate, no region formation, no reachability trace (those are stories
## 002-005).
##
## Per TD ruling BV-4 (`production/architecture-decisions-m02-preflight-
## 2026-07-26.md`), this module injects NO walkability provider of any kind --
## it calls [VillagerWalkabilityRules]'s static functions directly,
## `VillagerWalkabilityRules.is_standable(voxel_world, cell)`, using the SAME
## [member voxel_world] reference this module already injects for its own
## region analysis (stories 002+). This module therefore holds no reference
## to [VillagerAi] or any other gameplay entity, and cannot be null-ref'd by a
## despawned villager (BV-4 rationale). There is deliberately no `@export`
## of any `VillagerAi`-typed field anywhere in this module.
##
## [member voxel_world] plays BOTH roles this story's AC names separately
## ("Voxel World ref, structural-change signal source"): it is both the data
## source this module's (future) analysis reads AND the emitter of
## [signal VoxelWorldGrid.cells_changed_batch], the single structural trigger
## a later story (005, per TD ruling BV-2) subscribes to -- ONE injected
## dependency, two documented roles, not two separate `@export` fields.
## [method setup]'s single assertion on [member voxel_world] therefore covers
## both named dependencies.
##
## Per BV-1 §5, [member furniture_registry] is a duck-typed, nil-safe `Object`
## dependency (the landed precedent: `VillagerAi.needs_provider`/`job_queue`)
## -- a `null` value is a valid, correct state ("no furniture exists," true
## until `building-028` lands) and is therefore NEVER asserted by
## [method setup].
##
## Story build-validation-005 (this revision) adds the analysis PASS
## LIFECYCLE: [method setup] subscribes to [signal
## VoxelWorldGrid.cells_changed_batch] -- and to NOTHING else structural. Per
## TD ruling BV-2 (`production/architecture-decisions-m02-preflight-2026-07-
## 26.md`), this module deliberately does NOT subscribe to [signal
## ConstructionTickLoop.construction_completed]: that signal fires
## unconditionally after [method VoxelWorldGrid.bulk_write], but [method
## VoxelWorldGrid._apply_write] (ADR-0015 "load-before-write") QUEUES a write
## whose chunk is not resident and returns `null` -- the write lands later,
## from [method VoxelWorldGrid._apply_pending_writes], which emits [signal
## VoxelWorldGrid.cells_changed_batch] itself the instant it actually applies
## the deferred write. A pass triggered by `construction_completed` could
## therefore read stale (not-yet-landed) data; [signal
## VoxelWorldGrid.cells_changed_batch] cannot, by construction, since it only
## ever fires when a record actually changed. There is no `ConstructionTickLoop`
## reference anywhere in this file, and none is ever added.
##
## Each pass ([method _run_analysis_pass]) seeds the affected region(s) from
## the batch's own changed cells ([method
## BuildValidationRegionFormation.form_affected_regions], story 003), verdicts
## each ([method BuildValidationReachability.classify_region], story 004), and
## incrementally patches [member _region_snapshot] -- the transient,
## never-serialized analysis memory Rule 11 names (edge-detection memory for a
## LATER story's transition signals, never a compute cache; a full rebuild
## happens ONLY in [method run_load_pass]). Emission of this GDD's own
## player-facing signal contract (`room_recognized`/`shelter_status_changed`/
## `sealed_space_warning`/`unsheltered_furniture_info`) is explicitly deferred
## to stories 006/007/008 (Out of Scope) -- this story builds the snapshot
## those stories diff against and emits nothing of its own.
##
## Story build-validation-006 (this revision) lands [signal
## shelter_status_changed] -- the payoff-chain unblocker Needs & Mood's sleep
## recovery ladder consumes. Shelter classification is a LIVE lookup
## ([BuildValidationShelterClassifier], never a read of [member
## _region_snapshot] -- see that class's doc comment for why), re-run from
## THREE call sites: the end of every batched structural pass ([method
## _run_analysis_pass] -- Edge Case 7's roof-hole re-classification), the
## furniture registry's own placed/removed signal ([method
## _on_furniture_changed], BV-2's second trigger), and [method run_load_pass]
## (silently -- Rule 11/AC31). [member _shelter_snapshot] is patched and
## edge-detected by [method _patch_shelter_flag] so the signal fires exactly
## once per transition. Per BV-1 §5, [member furniture_registry] stays
## duck-typed and nil-safe -- a `null` provider yields zero items, zero
## emissions, no error; every dynamic call/connection onto it is guarded with
## [method Object.has_method]/[method Object.has_signal].
##
## Story build-validation-007 (this revision) lands [signal room_recognized]
## -- Rule 11's continuity + celebration-pacing contract
## ([TR-build-validation-navigability-040]/[-049]/[-050]). Continuity
## ([method _patch_region_snapshot_and_is_newly_recognized]): a region newly
## classified ROOM this pass fires ONLY if NONE of its cells were already
## ROOM in [member _region_snapshot] immediately before this pass's own patch
## -- one predicate that covers AC21's re-fire/merge/split cases without
## three branches (see that method's own doc comment). Pacing ([method
## _emit_room_recognized_group]): every region newly recognized in the SAME
## pass shares one minted `pass_group_id` and one `celebrate` verdict (Rule
## 11's same-pass grouping, AC32b) -- `celebrate` compares [member
## _tick_count] against [member _last_celebrated_tick] + `config.
## room_cue_cooldown_ticks`, and [member _last_celebrated_tick] is advanced
## ONLY when a group actually celebrates (`celebrate == true`) -- a quiet
## emission, a transient seal/unseal churn (never even reaching this method,
## since it only runs for NEWLY-ROOM regions), or the load pass (which never
## calls this method at all) can never arm the cooldown (CD Ruling 2
## condition 3, `production/creative-decisions-m02-preflight-2026-07-26.md`).
## [member time_tick_system] mirrors [member furniture_registry]'s own BV-1
## nil-safe precedent rather than [NeedsMood]/[VillagerAi]'s asserted-required
## shape: Rule 11's pacing is the ONLY consumer of ticks anywhere in this
## module, and every pre-existing build-validation test file's `setup()` call
## site (stories 001-006) has zero tick dependency -- an asserted requirement
## here would force editing five unrelated, already-green test files for a
## dependency their own scope never needed. A `null`/unresolvable Autoload
## leaves [member _tick_count] frozen at `0` forever -- deterministic, never
## a crash -- and Rule 11's pacing degrades to comparing a frozen clock
## (harmless: no pre-existing test exercises [signal room_recognized] at
## all, so none can observe the difference).
##
## Story build-validation-008 (this revision) lands the remaining half of
## the signal contract: [signal sealed_space_warning] and [signal
## unsheltered_furniture_info]. Unlike [signal shelter_status_changed]/[signal
## room_recognized], these two are deliberately LEVEL-TRIGGERED, not
## edge-detected -- there is no snapshot for either of them anywhere in this
## module (Rule 10: "deliberately NO cleared signal... their clearing
## mechanism IS the cessation of re-emission plus the queryable current
## state"). Both are recomputed from scratch on EVERY call to [method
## _reclassify_all_furniture] -- the batched structural pass end ([method
## _run_analysis_pass]), the furniture registry's own placed/removed trigger
## ([method _on_furniture_changed]), AND [method run_load_pass] (AC31 -- these
## two fire even though that same pass silences [signal shelter_status_changed]/
## [signal room_recognized], per Rule 11's "persisting causes re-warned"
## clause). The per-item tier decision itself ([BuildValidationTierClassifier])
## reuses the [param sheltered] boolean [method _reclassify_all_furniture]
## already computed for [signal shelter_status_changed]'s own logic -- never a
## second, independently-derived sheltered/unsheltered verdict. Per-item
## `WARNING`-tier results are grouped into ONE [signal sealed_space_warning]
## emission per DISTINCT sealed region ([method _add_to_sealed_group] -- two
## items whose own sealed regions share even one cell are, by region-formation's
## connectivity guarantee, the exact same region), matching the signal's own
## documented `(region cells, affected item ids, why-string)` payload shape;
## `INFO`-tier results emit immediately, per item (no grouping -- that signal's
## payload is `(item id, why-string)` only). Never a hardcoded `&"bed"`
## comparison anywhere in this module (grep-guarded by story 006's own test) --
## see [BuildValidationTierClassifier]'s own class doc comment for why reusing
## [method BuildValidationConfig.is_need_functional] for BOTH tiers is
## sufficient in MVP.
class_name BuildValidation
extends Node

## Fires when one furniture item's sheltered flag TRANSITIONS (Rule 5/10,
## [TR-build-validation-navigability-036]) -- exactly once per transition,
## for ALL furniture types. Needs & Mood and the UI subscribe to this SAME
## emission (AC16: emission COUNT of 1, not consumer count). Silent on the
## load pass (Rule 11/AC31) -- see [method run_load_pass].
signal shelter_status_changed(item_id: String, sheltered: bool)

## Fires when a candidate region transitions non-Room -> Room this pass, per
## Rule 11's continuity rule ([TR-build-validation-navigability-040]/[-049]):
## [param region_cells] the region's own interior cells AS OF THIS PASS
## (never re-queried afterward); [param celebrate] Rule 11's same-pass-group
## pacing verdict -- every region newly recognized in ONE pass shares the
## SAME `celebrate` value; [param pass_group_id] minted once per pass, ONLY
## when at least one region was newly recognized (a pass recognizing zero
## rooms mints nothing and emits nothing at all -- see [method
## _emit_room_recognized_group]). Silent on [method run_load_pass] (Rule
## 11/AC31 -- that method never calls the emitting path) and on a
## furniture-only reclassification ([method _on_furniture_changed] never
## forms or classifies a region).
signal room_recognized(region_cells: Array[Vector3i], celebrate: bool, pass_group_id: StringName)

## Fires every qualifying analysis pass (Rule 8/Rule 10, [TR-build-validation-
## navigability-033]/[-041]/[-046]) while a Sealed candidate region contains at
## least one need-functional furniture item ([method
## BuildValidationConfig.is_need_functional]): [param region_cells] that
## region's own interior cells AS OF THIS PASS; [param affected_item_ids]
## every need-functional item id inside it this pass (Rule 8 exclusivity,
## [TR-build-validation-navigability-035] -- a decorative item in the SAME
## region never contributes, AC35); [param why_string] this module's own
## authored explanation (the UI presents it verbatim, never re-authors it).
## LEVEL-TRIGGERED (AC22): re-emitted from scratch every call to [method
## _reclassify_all_furniture], including [method run_load_pass] (AC31) --
## there is deliberately no snapshot/memory backing this signal at all, and
## deliberately no "cleared" counterpart (Rule 10).
signal sealed_space_warning(
	region_cells: Array[Vector3i], affected_item_ids: Array[String], why_string: String
)

## Fires every qualifying analysis pass (Rule 8/Rule 10, [TR-build-validation-
## navigability-034]/[-041]/[-046]) while a need-functional furniture item
## ([method BuildValidationConfig.is_need_functional] -- MVP: exactly the bed,
## see [BuildValidationTierClassifier]'s own doc comment) sits unsheltered
## AND not inside a Sealed region (i.e. genuinely in the open): [param
## item_id] the item; [param why_string] this module's own authored
## explanation. Mutually exclusive with [signal sealed_space_warning] per
## item -- Warning supersedes Info ([TR-build-validation-navigability-035]).
## LEVEL-TRIGGERED, same re-emission contract as [signal sealed_space_warning]
## (including firing on [method run_load_pass], AC31) -- no snapshot, no
## "cleared" counterpart.
signal unsheltered_furniture_info(item_id: String, why_string: String)

## Tuning config (ADR-0002). Wired via a scene file's Inspector in
## production, or assigned directly in a headless test. Asserted wired by
## [method setup] -- never read inside `_ready()`.
@export var config: BuildValidationConfig

## Voxel World reference (ADR-0001). Serves BOTH roles this story's AC names
## separately -- see class doc comment. Asserted wired by [method setup].
@export var voxel_world: VoxelWorldGrid

## Furniture-registry provider (BV-1 §5) -- duck-typed, nil-safe, deliberately
## NOT `@export`ed as a typed dependency (no `FurnitureRegistry` class exists
## yet; `building-028` is a future story) and deliberately NOT asserted by
## [method setup] -- `null` means "no furniture exists," a correct default,
## exactly true until `building-028` lands.
##
## Story build-validation-006's shape for this provider (guarded with [method
## Object.has_method]/[method Object.has_signal] at every call/connect site,
## never assumed): `func get_placed_furniture() -> Array[Dictionary]`,
## returning one record per placed item shaped `{"item_id": String,
## "definition_id": StringName, "cells": Array[Vector3i]}` (BV-1 -- item id,
## occupied cells from `ItemDefinition.get_footprint()`, definition id); and
## an optional `signal furniture_changed` (BV-2's second trigger) this module
## reacts to by RE-ENUMERATING via `get_placed_furniture()` -- it never reads
## a payload from that signal, matching [method _on_cells_changed_batch]'s own
## "re-query, don't inspect the payload" discipline.
var furniture_registry: Object = null

## Time & Tick System dependency (ADR-0001) -- OPTIONAL and duck-typed,
## mirroring [member furniture_registry]'s own BV-1 nil-safe shape rather
## than [NeedsMood]/[VillagerAi]/[ConstructionTickLoop]'s asserted-required
## one. Rule 11's celebration pacing (story build-validation-007) is the
## SOLE consumer of ticks anywhere in this module -- see class doc comment
## for why this is deliberately NOT a hard assert. Duck-typed against the
## one member [method setup] needs: `signal tick()`. Production resolves the
## real Autoload lazily in [method setup]; a headless test assigns a mock
## double (e.g. `MockTimeTickSystem`) directly beforehand.
var time_tick_system: Object = null

## This module's own relative tick counter (Rule 11 pacing), incremented by
## [method _on_tick] -- independent of [TimeTickSystem]'s own global tick
## count (mirrors [VillagerAi._tick_count]'s established precedent: this
## class only ever observes the global count indirectly, via the `tick`
## signal itself). Stays `0` forever if [member time_tick_system] never
## resolves (see that member's own doc comment) -- never an error.
var _tick_count: int = 0

## The value of [member _tick_count] at which the most recent celebration
## GROUP actually fired a cue (`celebrate == true`), or `-1` if no group has
## ever done so (the "never armed" sentinel -- the first-ever recognition
## this module observes therefore always celebrates, CD Ruling 2 condition
## 3). Advanced ONLY by [method _emit_room_recognized_group] when its own
## group celebrates -- a quiet emission (`celebrate == false`) never touches
## this value, so the cooldown window is always measured from the last
## celebration that actually fired a cue, never from a quiet one.
var _last_celebrated_tick: int = -1

## Monotonic counter minting a fresh [param pass_group_id] per pass that
## recognizes at least one newly-valid room ([method
## _emit_room_recognized_group]) -- never incremented for a pass that
## recognizes zero rooms (no `pass_group_id` is minted at all in that case).
var _next_pass_group_ordinal: int = 0

## True once [method setup] has completed at least once.
var _is_set_up: bool = false

## The BLOCKING-tagged subset of the most recent `config.validate()` result,
## if any. Populated by [method setup]; read by [GameWorld]'s boot gate via
## [method get_boot_blocking_issues] (ADR-0002/0005).
var _boot_blocking_issues: Array[String] = []

## Region-classification snapshot (Rule 11, [TR-build-validation-navigability-
## 048]/[TR-build-validation-navigability-006]): `cell -> Verdict`, PATCHED
## incrementally by every batched-trigger pass ([method _run_analysis_pass])
## and FULLY rebuilt only by [method run_load_pass] -- transient
## edge-detection memory for a LATER story's transition signals, never a
## compute cache, and never serialized (ADR-0012, Rule 4/28 -- rebuilt from the
## world on every load, nothing persisted here).
var _region_snapshot: Dictionary[Vector3i, BuildValidationReachability.Verdict] = {}

## Per-item shelter-flag snapshot -- Rule 11's OTHER named map ("the snapshot
## is two maps"), keyed by placed-item id (`String`, matching [member
## furniture_registry]'s own record shape). Populated and patched by [method
## _reclassify_all_furniture]/[method _patch_shelter_flag] (story
## build-validation-006) -- edge-detection memory ONLY (Rule 11): a re-run
## that leaves a flag unchanged patches the entry but never re-emits [signal
## shelter_status_changed]. Stays empty whenever [member furniture_registry]
## is `null` (correct -- no furniture exists, BV-1).
var _shelter_snapshot: Dictionary[String, bool] = {}

## Instrumented analysis-pass count (AC19/AC20/BV-2's Gate 2 -- "assert
## analysis call-count"). Incremented exactly once per call to [method
## _run_analysis_pass], i.e. once per [signal
## VoxelWorldGrid.cells_changed_batch] emission this module receives --
## NEVER once per cell, per region, or per command within that batch (AC19).
## [method run_load_pass] does NOT touch this counter: the load pass is a
## distinct, explicitly-invoked full rebuild, never a batched-trigger pass
## (Rule 11 -- "no transition events... on load"; AC19/AC20 are both scoped to
## the batched-trigger path only).
var _analysis_pass_count: int = 0

## [signal sealed_space_warning]'s own authored why-string (Implementation
## Notes: "The why-strings originate here... the UI presents them; it does
## not author them") -- verbatim from the GDD's own example text.
const _SEALED_SPACE_WARNING_WHY: String = "the bed can't be reached — the room has no opening"

## [signal unsheltered_furniture_info]'s own authored why-string -- verbatim
## from the GDD's own example text.
const _UNSHELTERED_FURNITURE_INFO_WHY: String = "a roof would make this a proper home"


## Explicitly callable wiring/validation entry point (ADR-0001). Asserts
## [member config] and [member voxel_world] are wired, then applies
## ADR-0002's two-tier `validate()` policy exactly like
## [ReferenceConfigConsumer]: every non-BLOCKING issue is a clamp+warn
## (already applied by `validate()` itself) and is logged via `push_warning`;
## any BLOCKING issue (AC27's lockstep invariant) is recorded for
## [method get_boot_blocking_issues] instead of being treated as fatal here --
## the actual halt decision and terminal-path reuse live in [GameWorld]'s boot
## gate (ADR-0005), not in this module. Deliberately asserts NOTHING about a
## walkability provider (BV-4 -- there is none) or [member furniture_registry]
## (BV-1 §5 -- `null` is a valid state).
func setup() -> void:
	assert(config != null, "BuildValidation.config not wired")
	assert(voxel_world != null, "BuildValidation.voxel_world not wired")
	var issues: Array[String] = config.validate()
	_boot_blocking_issues = issues.filter(
		func(issue: String) -> bool: return issue.begins_with(ConfigResource.BLOCKING_PREFIX)
	)
	for issue: String in issues:
		if not issue.begins_with(ConfigResource.BLOCKING_PREFIX):
			push_warning(issue)
	# Story build-validation-005 / BV-2 -- the ONE structural subscription.
	# Idempotent against a repeated setup() call (never double-connects); no
	# `ConstructionTickLoop.construction_completed` subscription exists
	# anywhere in this module -- see class doc comment for the correctness
	# argument (deferred/paged writes can leave that signal naming cells whose
	# data has not landed yet).
	if not voxel_world.cells_changed_batch.is_connected(_on_cells_changed_batch):
		voxel_world.cells_changed_batch.connect(_on_cells_changed_batch)
	# Story build-validation-006 / BV-2's SECOND trigger -- the furniture
	# registry's own placed/removed signal. Fully duck-typed and nil-safe: a
	# `null` provider, or one that simply does not expose this signal, is a
	# valid, silent no-op (BV-1 §5 -- correct until `building-028` lands).
	if furniture_registry != null and furniture_registry.has_signal(&"furniture_changed"):
		if not furniture_registry.is_connected(&"furniture_changed", _on_furniture_changed):
			furniture_registry.connect(&"furniture_changed", _on_furniture_changed)
	# Story build-validation-007 -- Rule 11's OPTIONAL tick dependency (see
	# member doc comment for why this is nil-safe rather than asserted).
	# Production resolves the real Autoload lazily; a test that assigned a
	# mock keeps it. `is_inside_tree()` guards the lookup itself: per ADR-0001,
	# a headless test constructs this module via `Node.new()` and calls
	# `setup()` directly with ZERO scene tree -- calling `get_node_or_null` on
	# an orphan node prints a noisy (harmless, but avoidable) engine ERROR
	# ["Can't use get_node() with absolute paths from outside the active
	# scene tree"]. A null result after this (no scene tree yet, no
	# registered Autoload, no test-assigned mock) is a valid, silent state --
	# _tick_count simply never advances.
	if time_tick_system == null and is_inside_tree():
		time_tick_system = get_node_or_null(^"/root/TimeTickSystem")
	if time_tick_system != null and time_tick_system.has_signal(&"tick"):
		if not time_tick_system.is_connected(&"tick", _on_tick):
			time_tick_system.connect(&"tick", _on_tick)
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Returns the BLOCKING-tagged issues (if any) found in the most recent
## `config.validate()` call. [GameWorld]'s boot gate duck-types this method
## on every injected-tier module after calling `setup()` (ADR-0002 Decision,
## ADR-0005 reuse) -- a non-empty result triggers the same terminal boot-halt
## path used for RID's Failed outcome, no new severity model, no new halt
## mechanism.
func get_boot_blocking_issues() -> Array[String]:
	return _boot_blocking_issues


## Instrumented pass-count accessor (AC19/AC20, BV-2's Gate 2 -- "assert
## analysis call-count"). Test-observable instrumentation; [method
## get_region_status] is the GDD-facing queryable-state surface Rule 10 itself
## names.
func get_analysis_pass_count() -> int:
	return _analysis_pass_count


## Queryable region status (Rule 10: "all current statuses are additionally
## queryable at any time"). Returns [constant
## BuildValidationReachability.Verdict.OPEN] for a cell this module has never
## classified as part of any region -- the same default an ordinary
## un-analyzed cell would carry (States table: Open is the "no status" state),
## never a sentinel/error value.
func get_region_status(cell: Vector3i) -> BuildValidationReachability.Verdict:
	return _region_snapshot.get(cell, BuildValidationReachability.Verdict.OPEN)


## Queryable per-item shelter status (Rule 10, story build-validation-006).
## Returns `false` for an item id this module has never classified -- the
## same "no status = the ordinary default" convention [method
## get_region_status] already establishes, never a sentinel/error value.
func get_shelter_status(item_id: String) -> bool:
	return _shelter_snapshot.get(item_id, false)


## The one full-world pass (Rule 11, Edge Case 11, AC31): rebuilds [member
## _region_snapshot] and [member _shelter_snapshot] from scratch -- the ONLY
## place either snapshot is fully rebuilt rather than incrementally patched
## (Rule 11: "a full snapshot rebuild happens ONLY on the load pass"). Fires no
## transition events (this module emits none of its own at all yet -- see
## [method _run_analysis_pass]'s doc comment; stories 006-008 own the actual
## silence-on-load contract for their signals). Does NOT increment [member
## _analysis_pass_count] -- see that member's own doc comment.
##
## Seeds from every occupied cell's directly-above neighbor ([method
## VoxelWorldGrid.iterate_occupied], [TR-voxel-world-021]) rather than scanning
## every empty cell in the world bounds: a candidate interior cell always has
## SOME solid cell directly beneath it ([method
## VillagerWalkabilityRules.is_standable]'s own floor requirement), so this
## seed set is provably complete without an O(world-volume) empty-cell scan --
## only O(occupied-cell-count). Reuses [method
## BuildValidationRegionFormation.form_region] plus the same already-covered
## dedup [method _run_analysis_pass] uses, just seeded from the whole world's
## occupied cells instead of one pass's changed cells.
func run_load_pass() -> void:
	_region_snapshot.clear()
	_shelter_snapshot.clear()
	var already_covered: Dictionary[Vector3i, bool] = {}
	for record: CellOccupantRecord in voxel_world.iterate_occupied():
		var seed: Vector3i = record.cell + Vector3i(0, 1, 0)
		if already_covered.has(seed):
			continue
		var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
			voxel_world, seed, config.max_room_height
		)
		if region.size() == 0:
			continue
		var verdict: BuildValidationReachability.Verdict = BuildValidationReachability.classify_region(
			voxel_world, region, config.min_room_cells, config.max_room_height
		)
		for cell: Vector3i in region.cell_list():
			already_covered[cell] = true
			_region_snapshot[cell] = verdict
	# Story build-validation-006, Rule 11 silent seeding (AC31): the load
	# pass classifies every enumerated furniture item but fires NO
	# `shelter_status_changed` transitions -- statuses become queryable only.
	_reclassify_all_furniture(true)


## [signal VoxelWorldGrid.cells_changed_batch] handler -- THE single
## structural trigger this module ever subscribes to (TD ruling BV-2). Extracts
## every changed cell from [param changes] (the record's own [member
## CellChangeRecord.cell], never its before/after contents -- this module
## re-reads CURRENT grid state itself via the shared predicates, the same
## "re-query, don't inspect the payload" discipline [VillagerNavGraph]'s own
## batch handler already established) and runs exactly ONE [method
## _run_analysis_pass] per emission -- never per cell (AC19).
func _on_cells_changed_batch(changes: Array[CellChangeRecord]) -> void:
	var changed_cells: Array[Vector3i] = []
	for record: CellChangeRecord in changes:
		changed_cells.append(record.cell)
	_run_analysis_pass(changed_cells)


## One analysis pass (Rule 7/11, AC19): seeds the affected region(s) from
## [param changed_cells] ([method
## BuildValidationRegionFormation.form_affected_regions] -- story 003's own
## scoping, never re-derived here), classifies each ([method
## BuildValidationReachability.classify_region] -- story 004), and patches
## [member _region_snapshot] for every cell of every returned region -- an
## INCREMENTAL patch (Rule 11): only the entries the affected region(s)
## actually touch are written; every other snapshot entry persists unchanged.
## Increments [member _analysis_pass_count] exactly once per call, regardless
## of how many regions [param changed_cells] resolves into (Edge Case 10: a
## batch spanning two disjoint regions is still ONE pass, two regions
## evaluated) -- the counter tracks PASSES, not regions or cells.
##
## Emission of this GDD's own signal contract's remaining REGION-facing
## signals (`sealed_space_warning`/`unsheltered_furniture_info`) is
## explicitly OUT OF SCOPE here (Out of Scope: "Story 008") -- this method
## builds the region snapshot that story diffs against; it emits none of its
## own. Story build-validation-006 DOES additionally re-classify every
## enumerated furniture item at the end of this same pass ([method
## _reclassify_all_furniture]) and may emit [signal shelter_status_changed]
## -- Edge Case 7's roof-hole re-classification is exactly this: a
## structural change reaches furniture ONLY through this pass, never a
## separate counter or a separate signal subscription. Story
## build-validation-007 (this revision) additionally detects and emits
## [signal room_recognized] via [method
## _patch_region_snapshot_and_is_newly_recognized] (per-region continuity)
## and [method _emit_room_recognized_group] (same-pass grouping + pacing) --
## see [signal room_recognized]'s own doc comment for the full contract.
##
## Never calls any Building System or Villager AI API beyond the shared,
## static [VillagerWalkabilityRules] predicates (Rule 9's second half, AC33):
## [method BuildValidationRegionFormation.form_affected_regions] and [method
## BuildValidationReachability.classify_region] are this method's only
## structural calls, and neither holds nor accepts a villager/gameplay-entity
## reference.
func _run_analysis_pass(changed_cells: Array[Vector3i]) -> void:
	_analysis_pass_count += 1
	var regions: Array[BuildValidationRegion] = BuildValidationRegionFormation.form_affected_regions(
		voxel_world, changed_cells, config.max_room_height
	)
	var newly_recognized_regions: Array[BuildValidationRegion] = []
	for region: BuildValidationRegion in regions:
		var verdict: BuildValidationReachability.Verdict = BuildValidationReachability.classify_region(
			voxel_world, region, config.min_room_cells, config.max_room_height
		)
		if _patch_region_snapshot_and_is_newly_recognized(region, verdict):
			newly_recognized_regions.append(region)
	_emit_room_recognized_group(newly_recognized_regions)
	_reclassify_all_furniture(false)


## [signal TimeTickSystem.tick] handler (story build-validation-007, Rule 11
## pacing) -- the sole place [member _tick_count] ever advances, independent
## of [TimeTickSystem]'s own global tick count (mirrors
## [VillagerAi._tick_count]'s established "observed only indirectly, via the
## signal" precedent). Never connected at all if [member time_tick_system]
## stays `null` (see that member's own doc comment) -- this handler is then
## simply never called, and [member _tick_count] stays frozen at `0`.
func _on_tick() -> void:
	_tick_count += 1


## Patches [member _region_snapshot] for every cell of [param region] to
## [param verdict] and returns whether [param region] is NEWLY RECOGNIZED
## this pass (Rule 11 continuity, [TR-build-validation-navigability-049]):
## [param verdict] is [constant BuildValidationReachability.Verdict.ROOM] AND
## NONE of [param region]'s cells held [constant
## BuildValidationReachability.Verdict.ROOM] in [member _region_snapshot]
## immediately BEFORE this call's own patch (i.e. as of the pass immediately
## prior). One predicate covers AC21's three cases without three branches:
## - **Re-analysis keeping an existing room valid**: every cell of [param
##   region] already held ROOM before this call -- the "any cell already
##   ROOM" check trips, so this returns `false`.
## - **A merge of two already-valid rooms**: the merged region carries at
##   least one cell from EITHER contributing room, each already ROOM before
##   this call -- returns `false` for the merged region (neither original
##   room re-fires).
## - **A split of an existing valid room**: each child region still carries
##   a subset of the parent's own already-ROOM cells -- returns `false` for
##   both children.
## - **A previously-Sealed pocket merging into an existing valid room**
##   (Accepted MVP consequence, GDD Rule 11) also correctly returns `false`:
##   the pre-existing room's own cells were already ROOM, even though the
##   pocket's own cells were not -- the region AS A WHOLE was not "new."
## - **Room -> Sealed -> Room** (QA Test Cases edge case) correctly returns
##   `true` on the SECOND transition: the Sealed pass already patched every
##   cell to SEALED, so no cell holds ROOM immediately before the reopening
##   pass's own patch.
## A cell absent from [member _region_snapshot] entirely (never before
## classified as part of any region) defaults to [constant
## BuildValidationReachability.Verdict.OPEN] via [method Dictionary.get] --
## the same "no status = the ordinary default" convention [method
## get_region_status] already establishes.
func _patch_region_snapshot_and_is_newly_recognized(
	region: BuildValidationRegion, verdict: BuildValidationReachability.Verdict
) -> bool:
	var cells: Array[Vector3i] = region.cell_list()
	var any_cell_was_room: bool = false
	for cell: Vector3i in cells:
		var previous: BuildValidationReachability.Verdict = _region_snapshot.get(
			cell, BuildValidationReachability.Verdict.OPEN
		)
		if previous == BuildValidationReachability.Verdict.ROOM:
			any_cell_was_room = true
	for cell: Vector3i in cells:
		_region_snapshot[cell] = verdict
	return verdict == BuildValidationReachability.Verdict.ROOM and not any_cell_was_room


## Same-pass grouping + celebration pacing (Rule 11, AC32/AC32b, [TR-build-
## validation-navigability-050]): a no-op if [param newly_recognized_regions]
## is empty (a pass recognizing zero rooms mints no `pass_group_id` and emits
## nothing at all). Otherwise mints ONE fresh `pass_group_id` and resolves
## ONE `celebrate` verdict for the WHOLE group -- every region in [param
## newly_recognized_regions] emits [signal room_recognized] with the SAME
## `celebrate`/`pass_group_id` pair (AC32b's "one combined celebration
## event," never an arbitrary per-region winner).
##
## `celebrate` is `true` iff no group has ever celebrated yet ([member
## _last_celebrated_tick] still `-1`, the "never armed" sentinel -- the
## first-ever recognition always celebrates, CD Ruling 2 condition 3) OR
## [member _tick_count] minus [member _last_celebrated_tick] is at least
## `config.room_cue_cooldown_ticks` (the boundary is inclusive: exactly
## `room_cue_cooldown_ticks` ticks later celebrates; one tick earlier does
## not; `0` therefore means every group celebrates). [member
## _last_celebrated_tick] advances to [member _tick_count] ONLY when this
## group celebrates -- a quiet group (`celebrate == false`) never rewrites
## it, so the cooldown window is always measured from the last celebration
## that actually fired a cue, never from a quiet one, a load pass (which
## never calls this method), or a transient seal/unseal churn (which never
## reaches this method at all, since only NEWLY-ROOM regions are ever passed
## in).
func _emit_room_recognized_group(newly_recognized_regions: Array[BuildValidationRegion]) -> void:
	if newly_recognized_regions.is_empty():
		return
	var celebrate: bool = (
		_last_celebrated_tick < 0
		or (_tick_count - _last_celebrated_tick) >= config.room_cue_cooldown_ticks
	)
	_next_pass_group_ordinal += 1
	var pass_group_id: StringName = StringName("room_group_%d" % _next_pass_group_ordinal)
	for region: BuildValidationRegion in newly_recognized_regions:
		room_recognized.emit(region.cell_list(), celebrate, pass_group_id)
	if celebrate:
		_last_celebrated_tick = _tick_count


## [member furniture_registry]'s own placed/removed signal handler (BV-2's
## SECOND trigger, story build-validation-006). Re-enumerates via [method
## _reclassify_all_furniture] -- never reads a payload from the triggering
## signal (this module's established "re-query, don't inspect the payload"
## discipline, [method _on_cells_changed_batch]). Never silent -- a
## placement/removal is not the load pass, so ordinary edge-detected
## emissions apply.
func _on_furniture_changed() -> void:
	_reclassify_all_furniture(false)


## Re-classifies every currently-enumerated placed-furniture item (story
## build-validation-006) via a LIVE lookup ([BuildValidationShelterClassifier]
## -- never a read of [member _region_snapshot], see that class's own doc
## comment for why) and patches [member _shelter_snapshot] through [method
## _patch_shelter_flag], emitting [signal shelter_status_changed] per
## transition UNLESS [param silent] is `true` (the load pass, Rule 11/AC31).
## A `null` [member furniture_registry], or one that does not (yet) expose
## `get_placed_furniture`, is a silent, correct no-op -- zero items, zero
## emissions, no error (BV-1 §5). An item id no longer present in the current
## enumeration is untracked from [member _shelter_snapshot] WITHOUT emitting
## -- Rule 10 fires on a flag TRANSITION for an existing item, never on an
## item's own removal.
##
## Story build-validation-008 (this revision) ADDITIONALLY resolves each
## item's Warning/Info tier ([BuildValidationTierClassifier], reusing the
## SAME [param sheltered] this call just computed -- never a second,
## independently-derived verdict) and emits [signal sealed_space_warning]/
## [signal unsheltered_furniture_info] -- UNCONDITIONALLY, regardless of
## [param silent] (AC31: these two fire even on the load pass; only [signal
## shelter_status_changed] is ever silenced by that parameter). `WARNING`-tier
## items are grouped by their own sealed region ([method _add_to_sealed_group])
## so two need-functional items sharing one sealed space emit ONE combined
## `sealed_space_warning` naming both, never one per item; `INFO`-tier items
## emit immediately, per item. Both signals are recomputed from scratch every
## call -- no snapshot of any kind backs either of them (Rule 10's "no cleared
## signal" model).
func _reclassify_all_furniture(silent: bool) -> void:
	if furniture_registry == null:
		return
	if not furniture_registry.has_method(&"get_placed_furniture"):
		return
	@warning_ignore("unsafe_method_access")
	var records: Array = furniture_registry.get_placed_furniture()

	var current_ids: Dictionary[String, bool] = {}
	var sealed_group_cell_index: Dictionary[Vector3i, int] = {}
	var sealed_groups: Array[Dictionary] = []
	for entry: Variant in records:
		var record: Dictionary = entry as Dictionary
		var item_id: String = String(record.get("item_id", ""))
		if item_id == "":
			continue
		current_ids[item_id] = true
		var cells: Array[Vector3i] = _cells_from_record(record)
		var sheltered: bool = BuildValidationShelterClassifier.is_sheltered(
			voxel_world, cells, config.min_room_cells, config.max_room_height
		)
		_patch_shelter_flag(item_id, sheltered, silent)

		var definition_id: StringName = StringName(record.get("definition_id", &""))
		var tier_result: BuildValidationTierClassifier.ItemTierResult = (
			BuildValidationTierClassifier.classify_item_tier(
				voxel_world,
				cells,
				sheltered,
				config.is_need_functional(definition_id),
				config.min_room_cells,
				config.max_room_height,
			)
		)
		match tier_result.tier:
			BuildValidationTierClassifier.Tier.WARNING:
				_add_to_sealed_group(
					sealed_group_cell_index, sealed_groups, tier_result.sealed_region, item_id
				)
			BuildValidationTierClassifier.Tier.INFO:
				unsheltered_furniture_info.emit(item_id, _UNSHELTERED_FURNITURE_INFO_WHY)
			BuildValidationTierClassifier.Tier.NONE:
				pass

	for group: Dictionary in sealed_groups:
		var region: BuildValidationRegion = group["region"]
		var item_ids: Array[String] = group["item_ids"]
		sealed_space_warning.emit(region.cell_list(), item_ids, _SEALED_SPACE_WARNING_WHY)

	for tracked_id: String in _shelter_snapshot.keys():
		if not current_ids.has(tracked_id):
			_shelter_snapshot.erase(tracked_id)


## Groups one `WARNING`-tier item into [param groups] by its own [param
## region] (Rule 8/Rule 10's `(region cells, affected item ids, why-string)`
## payload -- one emission per DISTINCT sealed region, never one per item).
## [param cell_index] maps every cell already claimed by an existing group to
## that group's index in [param groups]; two items whose own sealed regions
## share even one cell are, by [BuildValidationRegionFormation]'s own
## connectivity guarantee, the EXACT same region, so checking any one shared
## cell is sufficient to merge them -- no canonical-cell/sort step needed.
## Both [param cell_index] and [param groups] are mutated in place (Dictionary/
## Array are reference types in GDScript) -- this method returns nothing, and
## none of [BuildValidation]'s own callers need it to.
func _add_to_sealed_group(
	cell_index: Dictionary[Vector3i, int],
	groups: Array[Dictionary],
	region: BuildValidationRegion,
	item_id: String,
) -> void:
	var cells: Array[Vector3i] = region.cell_list()
	var matched_index: int = -1
	for cell: Vector3i in cells:
		if cell_index.has(cell):
			matched_index = cell_index[cell]
			break
	if matched_index == -1:
		matched_index = groups.size()
		groups.append({"region": region, "item_ids": [] as Array[String]})
		for cell: Vector3i in cells:
			cell_index[cell] = matched_index
	var item_ids: Array[String] = groups[matched_index]["item_ids"]
	item_ids.append(item_id)


## Patches [member _shelter_snapshot][[param item_id]] to [param sheltered]
## and emits [signal shelter_status_changed] iff this is a TRANSITION (the
## item was never classified before, or its flag flipped) AND [param silent]
## is `false` (Rule 11: "a re-analysis that leaves a flag unchanged emits
## nothing"; the load pass silences even a first-time classification, AC31).
func _patch_shelter_flag(item_id: String, sheltered: bool, silent: bool) -> void:
	var is_transition: bool = (
		not _shelter_snapshot.has(item_id) or _shelter_snapshot[item_id] != sheltered
	)
	_shelter_snapshot[item_id] = sheltered
	if silent or not is_transition:
		return
	shelter_status_changed.emit(item_id, sheltered)


## Extracts [param record]'s `"cells"` entry as a typed [code]Array[Vector3i][/code]
## (BV-1's record shape -- see [member furniture_registry]'s own doc comment).
## An explicit element-by-element cast rather than relying on an implicit
## typed-array conversion from a Dictionary's `Variant` value, so a malformed
## or missing entry fails predictably (an empty result, never a crash) rather
## than depending on GDScript's own untyped-to-typed array coercion rules.
func _cells_from_record(record: Dictionary) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var raw: Array = record.get("cells", [])
	for value: Variant in raw:
		cells.append(value as Vector3i)
	return cells
