## Resource & Item Database Autoload (ADR-0001 Autoload tier; ADR-0005 boot
## gate; ADR-0006 two-type split consumer).
##
## Loads every [ItemDefinitionResource] `.tres` file under [member data_dir]
## exactly once at boot, following the GDD's `Unloaded -> Validating ->
## Ready | Failed` lifecycle (design/gdd/resource-item-database.md States
## and Transitions table). [signal validation_complete] fires exactly once,
## when [method setup] resolves -- the boot-gate hook [GameWorld] (ADR-0005)
## already check-then-connects against via [method is_ready] first, this
## signal as a fallback.
##
## Story rid-004 scope note: this story extends the rid-002 placeholder
## pipeline with the PER-ENTRY schema-check pass (design/gdd/resource-item-
## database.md States and Transitions, Validating row; TR-resource-item-
## database-005/024/028/040/041/043/049/050/051): id snake_case format,
## duplicate ids across files, unknown category/material_family, required-
## field presence, category<->material_family pairing, tier >= 0, and
## max_stack_size >= 1 where stackable. Every check appends a STRUCTURED
## record (see [method _make_issue]) to the result -- entry id, source
## file, violated check, offending field -- never a log string, and the
## pipeline never short-circuits on the first failure (every entry is
## checked). `visual_asset` resolution is Story 006's scope (see that
## story's own scope note below); the `missing_item` fallback is Story 007's;
## `footprint` category-pairing/presence validation is Story 008's -- none of
## those checks are implemented here.
##
## Story rid-005 scope note: this story adds the CROSS-CATALOG invariants on
## top of rid-004's per-entry pass (GDD Core Rules 5/6, Edge Case 6,
## TR-resource-item-database-030/031/035/042/006/007): reserved-id
## (`missing_item`) and reserved-category (`missing`) rejection folded into
## [method _validate_single_entry]'s existing id/category checks; a
## retired-ids ledger ([RetiredIdsLedgerResource], [member ledger_path] --
## defaults to zero retired ids when no ledger file is authored yet, mirror-
## ing [member data_dir]'s own missing-directory tolerance) checked per-
## entry via [method _validate_single_entry]; tier-0 `building_material`
## family coverage (GDD Core Rule 6) as a new cross-entry check (see
## [method _check_tier0_family_coverage], run alongside [method
## _check_duplicate_ids] from [method _validate_entries]) naming every
## uncovered family; and [method get_validation_result] exposing the most
## recent structured result as PERSISTENT state -- not just [method setup]'s
## return value or [signal validation_complete]'s one-shot payload -- so the
## Failed state's result stays inspectable for the rest of the session (GDD
## AC26). The aggregate ">=3 different violation classes" proof (GDD AC7)
## needed no new production code: rid-004's pipeline already accumulates
## every issue without short-circuiting; Story 005 only raises the
## regression proof from rid-004's own 2-class fixture to 3.
##
## Story rid-006 scope note: this story adds `visual_asset` resolution
## validation (GDD AC22, TR-resource-item-database-023; ADR-0006 Decision §3
## and Risk 2 mitigation) via [method _validate_single_entry]'s new [constant
## CHECK_VISUAL_ASSET_UNRESOLVED] check -- a loaded entry whose typed
## `visual_asset` [Mesh] field is null halts boot naming the entry. This is
## deliberately distinct from [constant CHECK_RESOURCE_LOAD_FAILED] (the
## entry's backing `.tres` failing to load entirely, e.g. a missing/broken
## `[ext_resource]`) -- ADR-0006 Risk 2 calls out that these are two different
## failure shapes and the resource-load check must run FIRST. No runtime
## `if`/`else` ordering was needed to enforce that here: [method
## _load_entries] already excludes any entry that failed to load from the
## `entries` list passed into [method _validate_entries] / [method
## _validate_single_entry], so a broken-load entry structurally can never
## reach the `visual_asset` check and be mislabeled -- the two diagnostics
## are mutually exclusive by construction, not by a first-failure guard.
## `visual_asset` is never treated as a path string or filesystem-existence-
## checked -- it is a typed [Mesh] reference (Story 001/ADR-0006); a null
## field is the only unresolved state this check observes.
##
## Story rid-008 scope note: this story adds the category<->footprint
## pairing/presence validation the rid-004 note above deferred (GDD Core
## Rule 10, Edge Cases 10/11, TR-resource-item-database-052/053/054): a
## `furniture_fixture` entry must carry a `footprint` with both dimensions
## >= 1 (see [method _validate_single_entry]'s new block, [constant
## CHECK_INVALID_FOOTPRINT] -- one structured issue PER offending dimension
## so an entry invalid on both names both, never just the first); every
## other category must carry the schema's own implicit `Vector2i(1, 1)`
## value and never an authored footprint ([constant
## CHECK_CATEGORY_FOOTPRINT_PAIRING]). Engine fact (same shape as the
## `tier` coercion note below): a `furniture_fixture` entry that OMITS
## `footprint` entirely (GDD sub-case 31a) is structurally indistinguishable
## from one that explicitly authors the schema-default `(1, 1)` value --
## [ItemDefinitionResource]'s `@export var footprint: Vector2i = Vector2i(1,
## 1)` (Story 001) means an absent property in the `.tres` deserializes to
## that SAME default, which already satisfies "both dims >= 1"; the two
## cases are also behaviorally identical (both describe a one-cell
## footprint), so both correctly succeed. Only the reachable sub-case (an
## explicitly-authored non-positive dimension, 31b) has an observable
## runtime code path -- see `footprint_validation_test.gd`'s regression
## test for the proof, mirroring this class's own tier non-integer note.
##
## Story rid-007 scope note: this story adds the built-in `missing_item`
## fallback resolution (GDD Edge Case 1, TR-resource-item-database-038) via
## the new [method resolve_or_missing] entry point -- distinct from [method
## get_by_id] (Story 003), whose `null`-on-unknown-id contract is unchanged;
## callers that must resolve to something renderable (e.g. world loading
## reconstructing a stored cell/save id) use [method resolve_or_missing]
## instead. The fallback [ItemDefinitionResource] ([method
## _build_missing_item_resource]) is built once per instance, entirely in
## code -- never authored as a `.tres` (Story 005 already rejects that id/
## category) and never inserted into [member _definitions], which is
## exactly what keeps it excluded from every listing query (GDD AC27,
## TR-resource-item-database-033) BY CONSTRUCTION rather than by a dedicated
## exclusion check -- the listing methods below iterate [member
## _definitions] only, and this resource never lives there. Each distinct
## missing id is logged exactly once per [method resolve_or_missing]
## instance (tracked via [member _logged_missing_ids]), which already
## matches "once per load event" (GDD Edge Case 1) since an instance's
## lifetime IS one load event under the existing load-once guard ([method
## setup] rejects a second call on the same instance); cross-load-instance
## dedup (a NEW instance per save-file load, GDD AC9b) is explicitly
## deferred to the Save/Load & World Persistence GDD, per this story's Out
## of Scope.
##
## Engine note (verified via a headless load probe against this exact
## script during rid-004 implementation): [member ItemDefinitionResource.tier]
## is a statically `int`-typed [code]@export[/code] field, so Godot's
## resource deserializer silently truncates any authored non-integer value
## (e.g. `tier = 1.5`) to an `int` (`1`) BEFORE this pipeline ever inspects
## it -- there is no runtime code path by which a non-integer value can
## reach [method _validate_single_entry]. The GDD's "non-integer tier"
## boot-halt sub-case (AC23) is therefore structurally satisfied by the
## schema's type declaration itself, not by a runtime check; only the
## negative-tier sub-case is independently validated below (see
## `validation_schema_checks_test.gd` for the regression test proving the
## coercion, cited as a Deviation in this story's implementation report).
##
## The lookup entry point [method get_by_id] carries Story 002's minimal
## non-Ready guard contract (TR-resource-item-database-034 -- outside Ready,
## always an explicit error, never data, never a partial read) using the
## exact `get_by_id(id) -> ItemDefinition` signature ADR-0006's Key
## Interfaces section specifies. Story 003 completes the read-only lookup
## surface on this same guard: [method get_by_id] now logs an unknown id
## once before returning `null` (GDD Edge Case 2 / AC8), and four listing
## queries -- [method list_ids_by_category], [method
## list_ids_by_material_family], [method list_ids_by_tier], [method
## list_all_ids] -- are added, each returning an empty typed list (never an
## error) both outside Ready and for a zero-match query (GDD Edge Case 8 /
## AC12; GDD Core Rule 8 -- no write API is exposed anywhere on this
## surface). The `missing_item` fallback resolution and its exclusion from
## these listings remain Story 007's job, layered on this same surface
## without changing any signature here.
##
## Deliberately carries NO `class_name` -- Godot 4.7 hard-errors "Class
## 'ResourceItemDatabase' hides an autoload singleton" if a script both
## declares that `class_name` AND is registered as the Autoload singleton of
## the same name (the exact `TimeTickSystem` precedent -- see that script's
## own doc comment). Callers use the registered singleton name directly
## (`ResourceItemDatabase.is_ready()`), never `@export`-injected (ADR-0001
## forbids `@export`ing an Autoload into any module).
extends Node

## Boot-sequencing lifecycle (GDD States and Transitions table). Progresses
## UNLOADED -> VALIDATING -> READY | FAILED exactly once per session; a
## second [method setup] call after leaving UNLOADED is rejected (see that
## method) rather than re-entering VALIDATING.
enum BootState { UNLOADED, VALIDATING, READY, FAILED }

## Emitted exactly once, when [method setup] resolves to Ready or Failed.
## Payload shape: `{"success": bool, "issues": Array}` -- a plain
## [Dictionary] rather than a typed `ValidationResult` (that class does not
## exist yet; Story 005 introduces the full aggregate/terminal-halt
## contract on top of this story's structured per-entry records). Each
## element of `issues` is itself a structured [Dictionary] -- see
## [method _make_issue] -- never a log string.
signal validation_complete(result: Dictionary)

## Default directory scanned for `.tres` [ItemDefinitionResource] entries
## (ADR-0002 authoring idiom, ADR-0006 storage location).
const DEFAULT_DATA_DIR: String = "res://data/items/"

## Default path to the [RetiredIdsLedgerResource] `.tres` file (Story
## rid-005, TR-resource-item-database-042). Deliberately OUTSIDE [constant
## DEFAULT_DATA_DIR] -- [member data_dir] scanning treats every `.tres`
## under it as an authored [ItemDefinitionResource], so a ledger file living
## alongside entries would itself be reported as [constant
## CHECK_RESOURCE_LOAD_FAILED]. A missing file at this path is NOT a boot
## failure -- see [method _load_retired_ids_ledger].
const DEFAULT_LEDGER_PATH: String = "res://data/items_retired_ids_ledger.tres"

## Fixed, five-entry authorable category set (GDD Core Rule 5) checked by
## [method _validate_single_entry]'s unknown-category check. The reserved,
## non-authorable sixth category (`missing`) is deliberately EXCLUDED here --
## it is rejected earlier via the dedicated [constant CHECK_RESERVED_CATEGORY]
## check (Story 005, TR-resource-item-database-030), which the `elif` chain
## in [method _validate_single_entry] short-circuits before this whitelist is
## ever consulted for that value.
const _KNOWN_CATEGORIES: Array[StringName] = [
	&"building_material", &"furniture_fixture", &"raw_resource", &"consumable", &"equipment"
]

## Fixed material-family set (Visual Direction Note) plus `none` for
## non-material items (GDD Core Rule 4), checked by [method
## _validate_single_entry]'s unknown-material_family check.
const _KNOWN_MATERIAL_FAMILIES: Array[StringName] = [&"wood", &"stone", &"thatch", &"none"]

## Material families that must each have >= 1 tier-0 `building_material`
## entry (GDD Core Rule 6 / Tuning Knobs "Tier-0 set composition", checked by
## [method _check_tier0_family_coverage]). Deliberately a standalone list
## rather than `_KNOWN_MATERIAL_FAMILIES` minus `none` -- the two lists
## answer different questions (valid enum values vs. tier-0-bootstrap-
## required families) and keeping them separately-authored means an enum
## addition never silently changes the coverage requirement.
const _TIER0_COVERAGE_FAMILIES: Array[StringName] = [&"wood", &"stone", &"thatch"]

## Reserved built-in fallback id (Story 007, GDD Edge Case 1 / TR-038) --
## never authorable (Story 005's [constant CHECK_RESERVED_ID] rejects any
## entry using it); the sole id [method resolve_or_missing] resolves any
## unknown id to.
const MISSING_ITEM_ID: StringName = &"missing_item"

## Reserved, non-authorable sixth category (GDD Core Rule 5) -- the built-in
## `missing_item` fallback's own category. Deliberately excluded from
## [constant _KNOWN_CATEGORIES] below; an authored entry using it is
## rejected earlier via [constant CHECK_RESERVED_CATEGORY] (Story 005),
## which the `elif` chain in [method _validate_single_entry] short-circuits
## before that whitelist is ever consulted for this value.
const MISSING_ITEM_CATEGORY: StringName = &"missing"

## Violated-check identifiers -- the `"check"` value of a structured issue
## record (see [method _make_issue]). Exposed as constants (mirroring
## [enum BootState]'s exposure pattern) so tests reference the exact
## identifier rather than a duplicated string literal.
const CHECK_RESOURCE_LOAD_FAILED: StringName = &"resource_load_failed"
const CHECK_MISSING_REQUIRED_FIELD: StringName = &"missing_required_field"
const CHECK_INVALID_ID_FORMAT: StringName = &"invalid_id_format"
const CHECK_DUPLICATE_ID: StringName = &"duplicate_id"
const CHECK_UNKNOWN_CATEGORY: StringName = &"unknown_category"
const CHECK_UNKNOWN_MATERIAL_FAMILY: StringName = &"unknown_material_family"
const CHECK_CATEGORY_FAMILY_PAIRING: StringName = &"category_family_pairing"
const CHECK_INVALID_TIER: StringName = &"invalid_tier"
const CHECK_INVALID_MAX_STACK_SIZE: StringName = &"invalid_max_stack_size"
const CHECK_RESERVED_ID: StringName = &"reserved_id"
const CHECK_RESERVED_CATEGORY: StringName = &"reserved_category"
const CHECK_RETIRED_ID_CONFLICT: StringName = &"retired_id_conflict"
const CHECK_TIER0_COVERAGE_GAP: StringName = &"tier0_coverage_gap"
const CHECK_INVALID_FOOTPRINT: StringName = &"invalid_footprint"
const CHECK_CATEGORY_FOOTPRINT_PAIRING: StringName = &"category_footprint_pairing"
const CHECK_VISUAL_ASSET_UNRESOLVED: StringName = &"visual_asset_unresolved"

## Directory this instance scans at [method setup]. Production leaves this
## at [constant DEFAULT_DATA_DIR]; a headless test assigns a fixture
## directory before calling [method setup] directly (Test Evidence:
## `Node.new()`, inject a mock data path, call `setup()` directly -- zero
## scene tree, zero Autoload registration).
var data_dir: String = DEFAULT_DATA_DIR

## Path to the [RetiredIdsLedgerResource] `.tres` file this instance checks
## new entries against at [method setup] (Story rid-005). Production leaves
## this at [constant DEFAULT_LEDGER_PATH]; a headless test assigns a fixture
## ledger path before calling [method setup] directly, exactly like [member
## data_dir].
var ledger_path: String = DEFAULT_LEDGER_PATH

## Current lifecycle state. Read-only from outside this class -- see
## [method get_state] / [method is_ready].
var _state: BootState = BootState.UNLOADED

## Loaded definitions, keyed by [member ItemDefinitionResource.id]. Only
## ever populated on a successful [method setup] resolution; stays empty in
## every other state.
var _definitions: Dictionary[StringName, ItemDefinitionResource] = {}

## The most recent structured `{"success": bool, "issues": Array}` result --
## see [method get_validation_result]. Neutral (`success = false`, empty
## `issues`) until the first [method setup] call resolves; a rejected
## repeat [method setup] call (already left [constant BootState.UNLOADED])
## never overwrites this -- it keeps reflecting the session's one real
## resolution, matching the load-once guarantee.
var _last_validation_result: Dictionary = {"success": false, "issues": []}

## Built-in, code-defined fallback definition returned by [method
## resolve_or_missing] for any id not present in [member _definitions] (GDD
## Edge Case 1, TR-resource-item-database-038). Built once per instance via
## [method _build_missing_item_resource] -- see this class's Story rid-007
## scope note for why it is never inserted into [member _definitions] itself.
var _missing_item_resource: ItemDefinitionResource = _build_missing_item_resource()

## Tracks which distinct missing/unknown ids [method resolve_or_missing] has
## already logged THIS instance's lifetime -- see this class's Story rid-007
## scope note for why an instance's lifetime already matches GDD Edge Case
## 1's "once per load event."
var _logged_missing_ids: Dictionary[StringName, bool] = {}


func _ready() -> void:
	setup()


## Explicitly callable wiring/validation entry point (ADR-0001/ADR-0005
## Autoload-tier convention, mirroring `TimeTickSystem.setup()`). Runs the
## GDD's Unloaded->Validating->Ready|Failed pipeline against
## [member data_dir] and emits [signal validation_complete] exactly once.
##
## Load-once guard (GDD Core Rule 2 / TR-resource-item-database-025, story
## QA plan AC-2): once this instance has left [constant BootState.UNLOADED]
## (Ready OR Failed -- both terminal for the session), a further call is
## rejected outright -- no re-scan, no second [signal validation_complete]
## emission, [member _definitions] left completely untouched -- and returns
## an explicit error result describing the rejection.
##
## Returns the same `{"success": bool, "issues": Array}` result
## [signal validation_complete] carries, so a direct caller (production
## `_ready()`, or a test) can inspect the outcome inline without a signal
## listener.
func setup() -> Dictionary:
	if _state != BootState.UNLOADED:
		var template: String = (
			"ResourceItemDatabase.setup() called again after the database "
			+ "already resolved to %s -- rejected; a database loads exactly "
			+ "once per session and Ready contents are never re-scanned"
		)
		return {"success": false, "issues": [template % BootState.keys()[_state]]}
	_state = BootState.VALIDATING
	var load_result: Dictionary = _load_definitions()
	var result: Dictionary = {
		"success": load_result["success"],
		"issues": load_result["issues"],
	}
	if load_result["success"]:
		_definitions = load_result["definitions"]
		_state = BootState.READY
	else:
		_state = BootState.FAILED
	_last_validation_result = result
	validation_complete.emit(result)
	return result


## Returns whether the database has resolved to Ready (ADR-0005's
## check-then-connect synchronous first check). `false` in every other
## state, including Failed.
func is_ready() -> bool:
	return _state == BootState.READY


## Returns the current lifecycle state -- the test/observability seam for
## the pipeline's progress (mirrors `GameWorld.get_boot_state()`).
func get_state() -> BootState:
	return _state


## Returns the most recent structured validation result -- GDD AC26 /
## TR-resource-item-database-006/007: "the database exposes the structured
## validation result" persists for the rest of the session, not only via
## [signal validation_complete]'s one-shot payload or [method setup]'s own
## return value, so a caller (an error screen, a test) can inspect it after
## the fact. Before the first [method setup] call resolves, returns a
## neutral `{"success": false, "issues": []}` -- nothing has been validated
## yet.
func get_validation_result() -> Dictionary:
	return _last_validation_result


## Full lookup implementation (Story 003, ADR-0006 Decision + GDD Core
## Rule 8): outside Ready, always returns `null` -- an explicit "no data"
## result, never a partial read, never a stale/previous value
## (TR-resource-item-database-034). Inside Ready, wraps the stored
## [ItemDefinitionResource] in a fresh [ItemDefinition] per call (ADR-0006 --
## wraps, never copies), or logs the unknown id once and returns `null` if
## [param id] is not present (GDD Edge Case 2 / AC8 -- an explicit not-found
## result, never a crash; the `missing_item` fallback resolution is Story
## 007's job, layered on this same guard without changing this signature).
func get_by_id(id: StringName) -> ItemDefinition:
	if _state != BootState.READY:
		return null
	var source: ItemDefinitionResource = _definitions.get(id)
	if source == null:
		push_warning(
			(
				"ResourceItemDatabase.get_by_id(): unknown id '%s' queried -- "
				+ "returning null (GDD Edge Case 2; missing_item fallback is "
				+ "Story 007's scope)"
			) % String(id)
		)
		return null
	return ItemDefinition.new(source)


## Resolves [param id] to its stored definition, or the built-in, fully
## inert [constant MISSING_ITEM_ID] fallback if [param id] is unknown (GDD
## Edge Case 1 / AC9a, TR-resource-item-database-038). Distinct from
## [method get_by_id] (Story 003), whose `null`-on-unknown-id contract is
## unchanged -- callers that MUST resolve to something renderable (e.g.
## world loading reconstructing a stored cell/save id) use this method
## instead, since a `null` result is never safe to render.
##
## Same non-Ready guard as [method get_by_id]: outside Ready [member
## _definitions] is empty (class invariant, see that member's doc comment),
## so every id resolves to the fallback there too -- an explicit, inert
## result, never a partial read (TR-resource-item-database-034).
##
## Each distinct missing id is logged exactly once per load event -- see
## [member _logged_missing_ids] and this class's Story rid-007 scope note.
func resolve_or_missing(id: StringName) -> ItemDefinition:
	var source: ItemDefinitionResource = null
	if _state == BootState.READY:
		source = _definitions.get(id)
	if source != null:
		return ItemDefinition.new(source)

	if not _logged_missing_ids.has(id):
		_logged_missing_ids[id] = true
		push_warning(
			(
				"ResourceItemDatabase.resolve_or_missing(): unknown/retired id "
				+ "'%s' resolved to the built-in missing_item fallback (GDD "
				+ "Edge Case 1) -- logged once per load event"
			) % String(id)
		)
	return ItemDefinition.new(_missing_item_resource)


## Returns the id of every entry whose [member ItemDefinitionResource.category]
## equals [param category]. A category with zero authored entries (e.g.
## `raw_resource` in MVP) returns an empty list -- a valid result, never an
## error (GDD Edge Case 8 / AC12). Outside Ready, also returns an empty list
## -- the same non-Ready guard [method get_by_id] applies
## (TR-resource-item-database-034): a listing query never partially answers.
func list_ids_by_category(category: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	if _state != BootState.READY:
		return ids
	for id: StringName in _definitions:
		if _definitions[id].category == category:
			ids.append(id)
	return ids


## Returns the id of every entry whose [member
## ItemDefinitionResource.material_family] equals [param material_family] --
## all and only entries of that family (GDD AC15). Same empty-list-on-zero-
## matches and non-Ready guard as [method list_ids_by_category].
func list_ids_by_material_family(material_family: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	if _state != BootState.READY:
		return ids
	for id: StringName in _definitions:
		if _definitions[id].material_family == material_family:
			ids.append(id)
	return ids


## Returns the id of every entry whose [member ItemDefinitionResource.tier]
## equals [param tier] (GDD AC14 -- proves the query logic on a fixture; the
## tier-0 building-material CONTENT assertion against shipped MVP data is
## Story 009's scope). Same empty-list-on-zero-matches and non-Ready guard
## as [method list_ids_by_category].
func list_ids_by_tier(tier: int) -> Array[StringName]:
	var ids: Array[StringName] = []
	if _state != BootState.READY:
		return ids
	for id: StringName in _definitions:
		if _definitions[id].tier == tier:
			ids.append(id)
	return ids


## Returns every authored entry's id exactly once, in boot-load (sorted
## filename) order -- no unauthored id ever appears (GDD AC16). Same
## non-Ready guard as [method list_ids_by_category].
func list_all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	if _state != BootState.READY:
		return ids
	for id: StringName in _definitions:
		ids.append(id)
	return ids


## Scans [member data_dir] for `.tres` files, loads each as an
## [ItemDefinitionResource], and runs the full per-entry + cross-entry
## schema-check pipeline (Story 004) over every entry that loaded
## successfully. Returns
## `{"success": bool, "issues": Array[Dictionary], "definitions":
## Dictionary[StringName, ItemDefinitionResource]}` -- `definitions` is
## populated ONLY when `success` is true (GDD Failed-state philosophy: never
## launch with a partially valid database, TR-resource-item-database-006 --
## a load failure OR any schema-check violation fails the WHOLE batch, not
## just the offending entry).
##
## A missing or empty [member data_dir] is NOT a failure (no entries to
## validate) -- it resolves as zero entries, `success = true`.
func _load_definitions() -> Dictionary:
	var definitions: Dictionary[StringName, ItemDefinitionResource] = {}
	var directory: DirAccess = DirAccess.open(data_dir)
	if directory == null:
		return {"success": true, "issues": [] as Array[Dictionary], "definitions": definitions}

	var retired_ids: Array[StringName] = _load_retired_ids_ledger()
	var file_names: Array[String] = _scan_entry_file_names(directory)
	var load_result: Dictionary = _load_entries(file_names)
	var entries: Array[Dictionary] = load_result["entries"]

	var issues: Array[Dictionary] = []
	issues.append_array(load_result["issues"] as Array[Dictionary])
	issues.append_array(_validate_entries(entries, retired_ids))

	if issues.is_empty():
		for entry: Dictionary in entries:
			var resource: ItemDefinitionResource = entry["resource"]
			definitions[resource.id] = resource

	return {"success": issues.is_empty(), "issues": issues, "definitions": definitions}


## Loads [member ledger_path] as a [RetiredIdsLedgerResource] and returns its
## [member RetiredIdsLedgerResource.retired_ids] (Story rid-005,
## TR-resource-item-database-042). A missing/empty [member ledger_path], or
## a path that fails to load as a [RetiredIdsLedgerResource], degrades to
## ZERO retired ids -- not a boot failure -- mirroring [method
## _load_definitions]'s own missing-[member data_dir] tolerance: no ledger
## has been authored yet is a valid, harmless state, not an error (the
## shipped MVP ledger is empty per the GDD).
func _load_retired_ids_ledger() -> Array[StringName]:
	var retired_ids: Array[StringName] = []
	if ledger_path == "" or not ResourceLoader.exists(ledger_path):
		return retired_ids
	var loaded: Resource = load(ledger_path)
	if loaded is RetiredIdsLedgerResource:
		retired_ids = (loaded as RetiredIdsLedgerResource).retired_ids
	return retired_ids


## Returns every `.tres` file name directly under [param directory], sorted
## for deterministic boot-load order. Extracted from the original rid-002
## scan loop so the schema-check pipeline can run over the full entry list
## (not a by-id-deduped [Dictionary]) before deciding uniqueness.
func _scan_entry_file_names(directory: DirAccess) -> Array[String]:
	var file_names: Array[String] = []
	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.ends_with(".tres"):
			file_names.append(file_name)
		file_name = directory.get_next()
	directory.list_dir_end()
	file_names.sort()
	return file_names


## Loads each file in [param file_names] (relative to [member data_dir]) as
## an [ItemDefinitionResource]. Returns `{"issues": Array[Dictionary],
## "entries": Array[Dictionary]}` where each `entries` element is
## `{"source_file": String, "resource": ItemDefinitionResource}`. A file
## that fails to load entirely, or loads as something other than an
## [ItemDefinitionResource], produces one structured [constant
## CHECK_RESOURCE_LOAD_FAILED] issue (ADR-0006 Risk 2's "resource failed to
## load entirely" case) and is excluded from `entries` -- it cannot be
## schema-checked since its fields are unreadable.
func _load_entries(file_names: Array[String]) -> Dictionary:
	var issues: Array[Dictionary] = []
	var entries: Array[Dictionary] = []
	for name: String in file_names:
		var path: String = data_dir.path_join(name)
		var loaded: Resource = load(path)
		if loaded == null or not (loaded is ItemDefinitionResource):
			issues.append(_make_issue(&"", path, CHECK_RESOURCE_LOAD_FAILED))
			continue
		entries.append({"source_file": path, "resource": loaded as ItemDefinitionResource})
	return {"issues": issues, "entries": entries}


## Runs the full schema-check pipeline (Stories 004/005) over every entry in
## [param entries] -- per-entry checks first (now including [param
## retired_ids] conflicts, Story 005), then the cross-entry checks
## (duplicate-id, tier-0 family coverage) -- accumulating every violation
## without short-circuiting on the first (GDD "Failed... naming EVERY
## invalid entry", TR-resource-item-database-005/035).
func _validate_entries(entries: Array[Dictionary], retired_ids: Array[StringName]) -> Array[Dictionary]:
	var issues: Array[Dictionary] = []
	for entry: Dictionary in entries:
		issues.append_array(
			_validate_single_entry(entry["resource"], entry["source_file"], retired_ids)
		)
	issues.append_array(_check_duplicate_ids(entries))
	issues.append_array(_check_tier0_family_coverage(entries))
	return issues


## Per-entry schema checks (Story 004 Implementation Notes, extended by
## Stories 005/008/006): required-field presence, id snake_case format,
## RESERVED id (`missing_item`) rejection, retired-ids ledger conflict, known
## category/material_family, RESERVED category (`missing`) rejection,
## category<->material_family pairing, `tier >= 0`, `max_stack_size >= 1`
## where `stackable`, category<->footprint pairing/presence, and
## `visual_asset` resolution. Every violated check appends its own structured
## record -- an entry with multiple problems reports all of them, never just
## the first.
func _validate_single_entry(
	resource: ItemDefinitionResource, source_file: String, retired_ids: Array[StringName]
) -> Array[Dictionary]:
	var issues: Array[Dictionary] = []
	var id: StringName = resource.id

	# --- required-field presence (GDD AC5 / TR-028) -----------------------
	# `id` missing skips the reserved/format/ledger checks below (nothing
	# valid to check) rather than double-reporting the same root cause.
	var id_present: bool = String(id) != ""
	if not id_present:
		issues.append(_make_issue(id, source_file, CHECK_MISSING_REQUIRED_FIELD, &"id"))
	else:
		# --- reserved id (GDD AC10a / TR-030) -------------------------------
		# `missing_item` can never be authored -- it is reserved for the
		# built-in fallback (Story 007). Exclusive with the format check
		# below since `missing_item` is itself valid snake_case; reporting
		# both would double-report the same root cause.
		if id == MISSING_ITEM_ID:
			issues.append(_make_issue(id, source_file, CHECK_RESERVED_ID, &"id"))
		elif not _is_valid_snake_case(String(id)):
			issues.append(_make_issue(id, source_file, CHECK_INVALID_ID_FORMAT, &"id"))

		# --- retired-ids ledger conflict (GDD Edge Case 6 / TR-042) ---------
		# Independent of (can coexist with) the reserved/format checks above
		# -- a different root cause, so no elif chaining with them.
		if retired_ids.has(id):
			issues.append(_make_issue(id, source_file, CHECK_RETIRED_ID_CONFLICT, &"id"))

	if resource.display_name == "":
		issues.append(_make_issue(id, source_file, CHECK_MISSING_REQUIRED_FIELD, &"display_name"))

	if String(resource.category) == "":
		issues.append(_make_issue(id, source_file, CHECK_MISSING_REQUIRED_FIELD, &"category"))
	elif resource.category == MISSING_ITEM_CATEGORY:
		# --- reserved category (GDD AC10b / TR-030) -------------------------
		# `missing` is reserved for the built-in fallback (Story 007) --
		# exclusive with the unknown-category check below since `missing`
		# would also fail that check; reporting both would double-report
		# the same root cause.
		issues.append(_make_issue(id, source_file, CHECK_RESERVED_CATEGORY, &"category"))
	elif not _KNOWN_CATEGORIES.has(resource.category):
		issues.append(_make_issue(id, source_file, CHECK_UNKNOWN_CATEGORY, &"category"))

	if String(resource.storage_category) == "":
		issues.append(_make_issue(id, source_file, CHECK_MISSING_REQUIRED_FIELD, &"storage_category"))

	# --- known material_family enum (GDD AC4b / TR-041) ---------------------
	if not _KNOWN_MATERIAL_FAMILIES.has(resource.material_family):
		issues.append(_make_issue(id, source_file, CHECK_UNKNOWN_MATERIAL_FAMILY, &"material_family"))

	# --- category<->material_family pairing (GDD AC24 / TR-051) -------------
	# building_material requires a real family (not `none`, not empty);
	# every other category requires exactly `none`.
	if resource.category == &"building_material":
		if resource.material_family == &"none" or String(resource.material_family) == "":
			issues.append(_make_issue(id, source_file, CHECK_CATEGORY_FAMILY_PAIRING, &"material_family"))
	elif resource.material_family != &"none":
		issues.append(_make_issue(id, source_file, CHECK_CATEGORY_FAMILY_PAIRING, &"material_family"))

	# --- tier >= 0 (GDD AC23 / TR-050) --------------------------------------
	# See this script's class doc comment: a non-integer authored value is
	# structurally impossible to observe here -- Godot's resource loader
	# coerces it to `int` before this pipeline ever runs -- so only the
	# negative-value sub-case is a reachable runtime check.
	if resource.tier < 0:
		issues.append(_make_issue(id, source_file, CHECK_INVALID_TIER, &"tier"))

	# --- max_stack_size >= 1 where stackable (GDD AC20/AC21 / TR-049/043) --
	# A non-stackable entry with max_stack_size authored is intentionally
	# NOT checked at all here -- ignored silently, per Edge Case 7.
	if resource.stackable and resource.max_stack_size < 1:
		issues.append(_make_issue(id, source_file, CHECK_INVALID_MAX_STACK_SIZE, &"max_stack_size"))

	# --- category<->footprint pairing (GDD Core Rule 10 / AC30-32 / -------
	# TR-resource-item-database-052/053/054, Story rid-008): furniture_fixture
	# requires an explicit footprint with both dimensions >= 1 -- one issue
	# PER offending dimension, so an entry invalid on both (e.g. `(0, -1)`)
	# names both rather than only the first. Every other category must carry
	# the schema's own implicit `(1, 1)` value and never an authored
	# footprint (Edge Case 10 / AC32). See this script's class doc comment
	# (Story rid-008 scope note) for the engine fact making GDD sub-case 31a
	# ("missing footprint") structurally unreachable as a distinct check.
	if resource.category == &"furniture_fixture":
		if resource.footprint.x < 1:
			issues.append(
				_make_issue(
					id, source_file, CHECK_INVALID_FOOTPRINT, &"footprint",
					{"dimension": &"width_cells"}
				)
			)
		if resource.footprint.y < 1:
			issues.append(
				_make_issue(
					id, source_file, CHECK_INVALID_FOOTPRINT, &"footprint",
					{"dimension": &"depth_cells"}
				)
			)
	elif resource.footprint != Vector2i(1, 1):
		issues.append(_make_issue(id, source_file, CHECK_CATEGORY_FOOTPRINT_PAIRING, &"footprint"))

	# --- visual_asset resolution (GDD AC22 / TR-resource-item-database-023, --
	# Story rid-006): a loaded entry whose `visual_asset` field is null halts
	# boot naming the entry, distinct from [constant
	# CHECK_RESOURCE_LOAD_FAILED] (ADR-0006 Risk 2's "entry failed to load"
	# shape). Order is guaranteed by construction, not a runtime branch here --
	# [method _load_entries] already excludes any entry whose backing `.tres`
	# failed to load entirely from the `entries` list this method is called
	# over, so a broken-load entry can never reach this check and be
	# mislabeled as "visual_asset unresolved."
	if resource.visual_asset == null:
		issues.append(_make_issue(id, source_file, CHECK_VISUAL_ASSET_UNRESOLVED, &"visual_asset"))

	return issues


## Cross-entry check: two (or more) entries sharing the same [member
## ItemDefinitionResource.id] across different source files (GDD Edge
## Case 4 / AC3, TR-resource-item-database-040). Emits one structured
## record PER duplicated file -- every record shares the same `entry_id`
## but names a different `source_file`, so the aggregated result names
## both entries AND both source files without a combined-list field shape.
## Entries with a missing (empty) id are excluded -- already reported by
## [method _validate_single_entry]'s required-field check, and grouping
## them here would misreport unrelated missing-id entries as "duplicates"
## of each other.
func _check_duplicate_ids(entries: Array[Dictionary]) -> Array[Dictionary]:
	var files_by_id: Dictionary[StringName, Array] = {}
	for entry: Dictionary in entries:
		var resource: ItemDefinitionResource = entry["resource"]
		if String(resource.id) == "":
			continue
		if not files_by_id.has(resource.id):
			files_by_id[resource.id] = []
		(files_by_id[resource.id] as Array).append(entry["source_file"])

	var issues: Array[Dictionary] = []
	for id: StringName in files_by_id:
		var files: Array = files_by_id[id]
		if files.size() > 1:
			for source_file: String in files:
				issues.append(_make_issue(id, source_file, CHECK_DUPLICATE_ID, &"id"))
	return issues


## Cross-entry check: tier-0 `building_material` family coverage (GDD Core
## Rule 6 / Tuning Knobs "Tier-0 set composition", TR-resource-item-
## database-031, Story 005). Every family in [constant
## _TIER0_COVERAGE_FAMILIES] must have >= 1 entry that is BOTH category
## `building_material` AND `tier == 0` -- an entry that is invalid for some
## OTHER reason (e.g. a duplicate id, a missing display_name) still counts
## toward coverage, since its category/material_family/tier fields are
## independently readable regardless of its other violations. This check is
## data-set-wide, not tied to one entry or file, so the resulting record
## uses an empty `entry_id` and [member data_dir] itself as `source_file`;
## the specific uncovered family is carried in the `"missing_family"` extra
## key (see [method _make_issue]) rather than overloading `field`, which
## every other check uses to name a literal schema field.
func _check_tier0_family_coverage(entries: Array[Dictionary]) -> Array[Dictionary]:
	var covered_families: Dictionary[StringName, bool] = {}
	for entry: Dictionary in entries:
		var resource: ItemDefinitionResource = entry["resource"]
		if resource.category == &"building_material" and resource.tier == 0:
			covered_families[resource.material_family] = true

	var issues: Array[Dictionary] = []
	for family: StringName in _TIER0_COVERAGE_FAMILIES:
		if not covered_families.get(family, false):
			issues.append(
				_make_issue(
					&"", data_dir, CHECK_TIER0_COVERAGE_GAP, &"material_family",
					{"missing_family": family}
				)
			)
	return issues


## Builds one structured validation-result record (design/gdd/resource-
## item-database.md's Validation-result contract: "a list of records, each
## carrying at least the entry id, source file, violated check, and
## offending field where applicable" -- TR-resource-item-database-007).
## [param field] defaults to an empty [StringName] for checks with no single
## offending field. [param extra] (Story 005 addition) merges additional
## keys onto the record for checks that need to carry more context than the
## base four fields -- currently only [method _check_tier0_family_coverage]'s
## `"missing_family"` key -- without overloading `field`'s meaning (a
## literal schema field name) for every other check. Defaults to an empty
## [Dictionary] so every pre-Story-005 call site is unaffected.
static func _make_issue(
	entry_id: StringName,
	source_file: String,
	check: StringName,
	field: StringName = &"",
	extra: Dictionary = {}
) -> Dictionary:
	var issue: Dictionary = {
		"entry_id": entry_id,
		"source_file": source_file,
		"check": check,
		"field": field,
	}
	for key: Variant in extra:
		issue[key] = extra[key]
	return issue


## Returns whether [param value] is valid `snake_case`: non-empty, entirely
## lowercase, and containing neither spaces nor hyphens (GDD AC6 / TR-024,
## sub-cases 6a uppercase / 6b spaces / 6c hyphens).
static func _is_valid_snake_case(value: String) -> bool:
	if value.is_empty():
		return false
	if value != value.to_lower():
		return false
	if value.contains(" ") or value.contains("-"):
		return false
	return true


## Builds the fully inert, code-defined [constant MISSING_ITEM_ID] fallback
## definition (Story 007) -- every field matches GDD Edge Case 1 exactly:
## category [constant MISSING_ITEM_CATEGORY] (the reserved, non-authorable
## sixth category), `material_family: none`, `tier: 0`, non-stackable
## (`max_stack_size: 1`), non-haulable, `storage_category: none`, the
## schema's own implicit `(1, 1)` footprint ([constant MISSING_ITEM_CATEGORY]
## is not `furniture_fixture`, so Story 008's category<->footprint pairing
## rule requires exactly this value), a deliberately conspicuous magenta
## placeholder visual ([method _build_missing_item_visual]), display name
## "Missing Item". Never authored as a `.tres` (Story 005 rejects that) and
## never routed through [method _load_definitions] -- constructed directly
## in code, once per instance (see [member _missing_item_resource]).
static func _build_missing_item_resource() -> ItemDefinitionResource:
	var resource: ItemDefinitionResource = ItemDefinitionResource.new()
	resource.id = MISSING_ITEM_ID
	resource.display_name = "Missing Item"
	resource.category = MISSING_ITEM_CATEGORY
	resource.material_family = &"none"
	resource.tier = 0
	resource.visual_asset = _build_missing_item_visual()
	resource.stackable = false
	resource.max_stack_size = 1
	resource.haulable = false
	resource.storage_category = &"none"
	resource.footprint = Vector2i(1, 1)
	return resource


## Builds the deliberately conspicuous magenta placeholder [Mesh] for
## [method _build_missing_item_resource] (GDD Edge Case 1 -- "same approach
## as Minecraft's missing-texture handling") -- a code-defined, unshaded
## magenta [BoxMesh], not an authored asset. This fallback visual is
## independent of Story 009's content pipeline (which authors the real MVP
## meshes) and must never depend on it.
static func _build_missing_item_visual() -> Mesh:
	var mesh: BoxMesh = BoxMesh.new()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.0, 1.0)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	return mesh
