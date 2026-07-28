## Building System's furniture registry (Story building-028, ADR-0016 BV-1
## ruling primary -- `production/architecture-decisions-m02-preflight-
## 2026-07-26.md`: "Furniture is not voxel data. It never enters
## VoxelWorldGrid... Furniture occupancy lives in a Building-System-owned
## furniture registry, keyed by placed-item identity, holding at minimum:
## item id, occupied cells, and the definition id.").
##
## `RefCounted`, not `Resource`/`Node` -- a plain, code-assigned shared
## collaborator, mirroring [ConstructionJobQueue]/[BuildProjectRegistry]'s own
## established "population-wide shared object, no Inspector-editable
## representation" precedent: this registry aggregates every placed
## furniture item across the whole game, exactly as those classes aggregate
## jobs/projects. [ConstructionTickLoop] holds this as a plain, non-`@export`ed
## `var` (RefCounted is not an exportable Inspector type, Godot 4.7 -- see
## `production/architecture-decisions-m02-preflight-2026-07-26.md` PD-1's
## same finding), mirroring [member ConstructionTickLoop.write_tag]'s own
## identical wiring shape exactly.
##
## **This is the sole destination a completing [constant
## BlueprintCell.Category.FURNITURE] job is routed to, INSTEAD OF
## [VoxelWorldGrid].** [method ConstructionTickLoop._complete_jobs] calls
## [method place] once per completing furniture cell; this class performs no
## job/tick/construction bookkeeping of its own -- it is a pure identity +
## occupancy store, written to only by that one call site.
##
## **Consumer contract** (BV-1 §5, landed and already consumed by
## `build-validation-006`'s [member BuildValidation.furniture_registry] --
## see that class's own doc comment for the EXACT shape it duck-types
## against): [method get_placed_furniture] returns one [Dictionary] per
## placed item, shaped `{"item_id": String, "definition_id": StringName,
## "cells": Array[Vector3i]}`; [signal furniture_changed] fires on every
## placement (and, once Story building-017 lands, removal) -- BV-2's second
## structural trigger, alongside [signal VoxelWorldGrid.cells_changed_batch].
## A consumer never reads a payload from that signal; it re-enumerates via
## [method get_placed_furniture] instead (the SAME "re-query, don't inspect
## the payload" discipline [BuildValidation]'s own batch handler already
## establishes for the voxel-world trigger).
##
## **Single-cell only, this story** -- every [param cells] passed to [method
## place] is a one-element array (this story's own scope: "single-cell
## furniture support/placement base"). Story building-016's multi-cell
## footprint extends [method place]'s CALLERS to pass a real multi-cell list;
## this class's own storage shape (`cells: Array[Vector3i]` per record) is
## already footprint-sized, so no shape change is needed when that story
## lands -- only [ConstructionTickLoop]'s own single-cell call site needs to
## grow into a whole-footprint completion (that story's job, not this one's).
##
## **Removal (Story building-017, this revision)** -- [method remove] is the
## atomic counterpart to [method place]: erases a whole item's record AND
## every one of its occupied cells from [member _cell_index] in ONE call,
## never a per-cell partial removal (mirrors [method place]'s own "every
## footprint cell together" discipline in reverse). [method
## ConstructionTickLoop._complete_jobs] is the sole call site -- a completed
## FURNITURE demolition job, resolved via [method get_occupant_at] against
## whichever cell the job happened to be claimed under (every footprint cell
## shares the SAME occupant id, so any one of them resolves the whole
## entity). Emits [signal furniture_changed] exactly once on success -- this
## class's own doc comment already named this as the expected shape ("Story
## building-017... is expected to emit this SAME signal on a successful
## removal, not a second one").
##
## A re-`place()` at an already-occupied cell (still never exercised by any
## real caller -- [CommitPipeline]'s own combined-view validity gate already
## prevents a normal double-commit at the same address before construction
## ever reaches this class) still overwrites [member _cell_index]'s
## reverse-index entry for that address without erasing the PRIOR record's
## own stale `cells` list -- a known, narrow, pre-existing limitation, but
## strictly orthogonal to [method remove]'s own correctness: a genuine
## remove-then-place at the same address works correctly, since [method
## remove] fully erases the prior record (both its [member
## _FurnitureRecord.cells] entries in [member _cell_index] AND the record
## itself) before any later [method place] call could ever run.
class_name FurnitureRegistry
extends RefCounted

## Fires whenever [method place] registers a newly-completed furniture item
## (BV-2's second structural trigger) -- zero-argument, matching [member
## BuildValidation.furniture_registry]'s own documented "optional signal
## furniture_changed... never reads a payload from that signal" contract
## exactly. Story building-017 (furniture removal, out of this story's
## scope) is expected to emit this SAME signal on a successful removal, not
## a second one.
signal furniture_changed

## One placed-furniture record's shape -- see class doc comment. Plain inner
## value holder (mirrors [BlueprintCell]'s own "value object retained for as
## long as it remains tracked" precedent), never exposed directly outside
## this class -- [method get_placed_furniture] always re-serializes into the
## BV-1-documented plain [Dictionary] shape instead.
class _FurnitureRecord:
	var item_id: String
	var definition_id: StringName
	var cells: Array[Vector3i]

	func _init(p_item_id: String, p_definition_id: StringName, p_cells: Array[Vector3i]) -> void:
		item_id = p_item_id
		definition_id = p_definition_id
		cells = p_cells

## Every placed furniture item, keyed by its own auto-generated [member
## _FurnitureRecord.item_id] -- the sole source of truth [method
## get_placed_furniture] reads from.
var _records: Dictionary[String, _FurnitureRecord] = {}

## cell -> owning item id reverse index ("furniture occupies its cells
## one-occupant-per-cell," Control Manifest requirement) -- read-only
## observability today ([method get_occupant_at]/[method has_occupant]);
## Story building-017's future removal caller is this index's real future
## consumer, mirroring [BuildProjectRegistry._cell_index]'s own established
## shape.
var _cell_index: Dictionary[Vector3i, String] = {}

## Monotonically-increasing id source for freshly-placed items -- a plain
## counter turned into a stable [String] (mirrors [BuildProjectRegistry]'s
## own `_next_id` precedent); never reused, never reset.
var _next_id: int = 1


## Registers a newly-completed furniture item occupying [param cells] (this
## story: always a one-element array) with RID identity [param
## definition_id] (e.g. `&"bed"`, opaque -- this class never resolves it
## beyond storing it, mirrors [CommitPipeline]'s own "opaque ids only" RID
## discipline). Assigns and returns a fresh item id, indexes every occupied
## cell, and emits [signal furniture_changed] exactly once. [param cells]
## must be non-empty (asserted) -- [ConstructionTickLoop]'s own call site
## never calls this for a job with no completed cell.
func place(definition_id: StringName, cells: Array[Vector3i]) -> String:
	assert(not cells.is_empty(), "FurnitureRegistry.place requires at least one cell")
	var item_id: String = str(_next_id)
	_next_id += 1
	var record := _FurnitureRecord.new(item_id, definition_id, cells.duplicate())
	_records[item_id] = record
	for cell: Vector3i in cells:
		_cell_index[cell] = item_id
	furniture_changed.emit()
	return item_id


## The BV-1-documented enumeration [BuildValidation.furniture_registry]
## duck-types against: one [Dictionary] per placed item, shaped
## `{"item_id": String, "definition_id": StringName, "cells":
## Array[Vector3i]}` (see class doc comment). No defined order beyond
## [Dictionary]'s own insertion-order guarantee. An empty registry (nothing
## placed yet) returns an empty array -- a valid result, never an error.
func get_placed_furniture() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id: String in _records:
		var record: _FurnitureRecord = _records[item_id]
		result.append({
			"item_id": record.item_id,
			"definition_id": record.definition_id,
			"cells": record.cells.duplicate(),
		})
	return result


## Whether [param cell] currently belongs to a placed furniture item
## ("one-occupant-per-cell").
func has_occupant(cell: Vector3i) -> bool:
	return _cell_index.has(cell)


## The item id occupying [param cell], or `""` if none -- the same
## empty-string "no status" sentinel convention this codebase already
## established elsewhere (mirrors [method BuildValidation.get_shelter_status]'s
## own "no status = the ordinary default" precedent), never a crash.
func get_occupant_at(cell: Vector3i) -> String:
	return _cell_index.get(cell, "")


## The full record tracked for [param item_id] (same shape as [method
## get_placed_furniture]'s per-item entry), or an empty [Dictionary] if
## [param item_id] is unknown -- read-only observability/test seam.
func get_record(item_id: String) -> Dictionary:
	if not _records.has(item_id):
		return {}
	var record: _FurnitureRecord = _records[item_id]
	return {
		"item_id": record.item_id,
		"definition_id": record.definition_id,
		"cells": record.cells.duplicate(),
	}


## Whether this registry currently tracks zero placed items.
func is_empty() -> bool:
	return _records.is_empty()


## Removes a previously-placed furniture item (Story building-017,
## [TR-building-system-127]; see class doc comment's "Removal" section) --
## the atomic counterpart to [method place]. Erases [param item_id]'s own
## record and every one of its occupied cells from [member _cell_index] in
## one call, so a multi-cell footprint's occupancy clears for EVERY cell
## together, never one cell freed while another still reads occupied. Emits
## [signal furniture_changed] exactly once on success. Returns `false`
## (no-op, nothing mutated, no signal) if [param item_id] is not currently
## tracked -- a defensive, never-crashing "already gone" case, never a
## crash.
func remove(item_id: String) -> bool:
	if not _records.has(item_id):
		return false
	var record: _FurnitureRecord = _records[item_id]
	for cell: Vector3i in record.cells:
		_cell_index.erase(cell)
	_records.erase(item_id)
	furniture_changed.emit()
	return true
