## Bridges Building System's real [FurnitureRegistry] + Build Validation's
## real shelter classification into [VillagerAi]'s duck-typed `bed_provider`
## seam (Story needs-mood-010 -- "the wire between them", GDD Rule 11/12/13,
## TR-needs-mood-system-036). This class holds ZERO furniture-placement or
## shelter-classification LOGIC of its own -- it only translates between two
## already-shipped, independently-owned surfaces:
## [method FurnitureRegistry.get_placed_furniture]'s per-item `{"item_id",
## "definition_id", "cells"}` records and [method
## BuildValidation.get_shelter_status]'s per-item shelter query, into the
## exact four-member shape [member VillagerAi.bed_provider] duck-types
## against -- matching `tests/integration/villager_ai/sleep_and_home_test.gd`'s
## own `MockBedProvider` contract verbatim: `get_unowned_bed_cells() ->
## Array[Vector3i]`, `claim_bed(cell, villager_id) -> bool`,
## `is_bed_sheltered(cell) -> bool`, and `signal furniture_revoked(villager_id,
## furniture_cell)`.
##
## Claim bookkeeping is owned HERE, never by [FurnitureRegistry] (a pure
## identity/occupancy store with no notion of villager ownership) -- the same
## division of responsibility `MockBedProvider` already established between
## "which cells exist" (the registry) and "who has claimed one" (the
## provider). Keyed by each bed's own CANONICAL cell -- the
## lexicographically-least cell of its footprint ([method
## VillagerJobSelector.lexicographic_cell_less_than], the same tie-break
## convention every other selection in this codebase reuses) -- so a 2-cell
## bed (Story building-016) is offered/claimed as exactly ONE candidate,
## never one candidate per footprint cell.
##
## [signal furniture_revoked] is declared (required -- [method
## VillagerAi.setup] unconditionally connects to it whenever `bed_provider`
## is non-null) but this class never emits it on its own: furniture REMOVAL
## is Story building-017, deferred to S11 (Sprint 10 plan, D8/F1) --
## [FurnitureRegistry] itself exposes no removal today. Nothing here needs to
## change for a future story to wire real emission; the seam already exists.
class_name FurnitureBedProvider
extends RefCounted

## Fires when a claimed/owned bed is revoked out from under [param
## villager_id] (GDD Edge Case 5/6). Never emitted by this class today (see
## class doc comment) -- reserved for Story building-017's future real
## emission, and directly test-triggerable in the meantime (mirrors
## `MockBedProvider.revoke`'s own precedent).
signal furniture_revoked(villager_id: int, furniture_cell: Vector3i)

## The RID definition id MVP's bed occupies (`building-028`'s own doc
## comment: "MVP: bed") -- the one furniture kind this provider treats as a
## sleepable bed; any other placed item is invisible to this seam.
const BED_DEFINITION_ID: StringName = &"bed"

## The real, already-populated Building System collaborator
## (`building-028` -> `016`) -- read-only from this class's own
## perspective; claims live in [member _claimed_by] instead (see class doc
## comment), never on the registry itself.
var furniture_registry: FurnitureRegistry = null

## The real Build Validation collaborator (`bv-006`) -- its [method
## BuildValidation.get_shelter_status] is this provider's SOLE source for
## [method is_bed_sheltered] (never a second, locally-derived
## classification).
var build_validation: BuildValidation = null

## cell -> claiming villager_id, keyed by each bed's own canonical cell (see
## class doc comment). Mirrors [method ConstructionJobQueue.claim_job]'s own
## "first caller wins" atomicity precedent (Story villager-ai-011).
var _claimed_by: Dictionary[Vector3i, int] = {}


func _init(p_furniture_registry: FurnitureRegistry, p_build_validation: BuildValidation) -> void:
	furniture_registry = p_furniture_registry
	build_validation = p_build_validation


## [member VillagerAi.bed_provider] candidate-list read: one canonical cell
## per currently-unclaimed bed item (see class doc comment's "one candidate
## per bed, never per footprint cell" rule). Nil-safe: an unwired registry
## answers "no candidates," never an error.
func get_unowned_bed_cells() -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	if furniture_registry == null:
		return result
	for record: Dictionary in furniture_registry.get_placed_furniture():
		if StringName(record.get("definition_id", &"")) != BED_DEFINITION_ID:
			continue
		var canonical: Vector3i = _canonical_cell(record)
		if not _claimed_by.has(canonical):
			result.append(canonical)
	return result


## [member VillagerAi.bed_provider] atomic-claim attempt: first caller for a
## given (canonical) cell wins -- mirrors [method
## ConstructionJobQueue.claim_job] exactly (AC43's shared pattern).
func claim_bed(cell: Vector3i, villager_id: int) -> bool:
	if _claimed_by.has(cell):
		return false
	_claimed_by[cell] = villager_id
	return true


## [member VillagerAi.bed_provider] shelter-classification read: resolves
## [param cell] back to its owning furniture item via [method
## FurnitureRegistry.get_occupant_at], then defers ENTIRELY to [method
## BuildValidation.get_shelter_status] -- never a second, locally-derived
## sheltered/unsheltered rule (TR-needs-mood-system-036: "supplied by Build
## Validation & Navigability").
func is_bed_sheltered(cell: Vector3i) -> bool:
	if furniture_registry == null or build_validation == null:
		return false
	var item_id: String = furniture_registry.get_occupant_at(cell)
	if item_id == "":
		return false
	return build_validation.get_shelter_status(item_id)


## The canonical cell representing a whole bed item for candidate/claim
## purposes -- the lexicographically-least cell of [param record]'s own
## `"cells"` entry (see class doc comment). A single-cell item's own only
## cell is trivially its own canonical cell.
func _canonical_cell(record: Dictionary) -> Vector3i:
	var raw: Array = record.get("cells", [])
	var canonical: Vector3i = raw[0] as Vector3i
	for i in range(1, raw.size()):
		var candidate: Vector3i = raw[i] as Vector3i
		if VillagerJobSelector.lexicographic_cell_less_than(candidate, canonical):
			canonical = candidate
	return canonical
