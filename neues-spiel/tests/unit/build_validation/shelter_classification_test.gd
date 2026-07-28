## Unit test — Build Validation & Navigability story build-validation-006
## (shelter classification & `shelter_status_changed`; ADR-0007 primary, ADR-
## 0001 secondary; TD rulings BV-1/BV-2 --
## `production/architecture-decisions-m02-preflight-2026-07-26.md`).
##
## Proves:
## 1. AC12/AC14: a bed inside a valid room classifies sheltered; a bed in a
##    sealed region classifies unsheltered.
## 2. AC13: opening a roof hole above a sheltered bed's cell flips it to
##    unsheltered on re-analysis, with exactly one emission.
## 3. AC15: a bed exactly under the roof edge is sheltered; one cell further
##    out is not — purely a function of the cell's own candidate status.
## 4. AC16: two listeners connected to `shelter_status_changed` both observe
##    exactly one emission for one transition (emission count, not consumer
##    count).
## 5. No-transition silence: a re-analysis that changes nothing shelter-
##    relevant emits nothing.
## 6. BV-1: a `null` furniture_registry yields zero items, zero emissions, no
##    error; enumeration happens ONLY through the injected, duck-typed
##    provider (developed and exercised entirely against a mock — no
##    `building-028` code exists anywhere in this test or the production
##    module).
## 7. Rule 11 / AC31 shape: the load pass silently seeds shelter status (no
##    emission), but a subsequent live transition after load still emits.
## 8. BV-2 second trigger: the registry's own `furniture_changed` signal
##    re-classifies without any voxel write.
## 9. Multi-cell footprint: sheltered iff EVERY occupied cell is Room.
## 10. Need-functional config resolution (BV-1 §6): the config's own
##     data-driven list, resolved through `ResourceItemDatabase.get_by_id`,
##     never a hardcoded `&"bed"` comparison in the predicate logic.
## 11. Grep guard: furniture occupancy is never read from `CellContents`
##     anywhere in the shelter-classification code.
class_name BuildValidationShelterClassificationTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

const MAX_ROOM_HEIGHT: int = 8  # BuildValidationConfig default.
const MIN_ROOM_CELLS: int = 2   # BuildValidationConfig default.


## Minimal duck-typed furniture-registry stub (BV-1 §5 shape): exposes
## `get_placed_furniture() -> Array[Dictionary]` and the `furniture_changed`
## signal (BV-2's second trigger) this test drives directly — no
## `building-028` code exists anywhere; this stub is test-local only.
class _StubFurnitureRegistry:
	signal furniture_changed

	var _records: Dictionary[String, Dictionary] = {}

	func get_placed_furniture() -> Array[Dictionary]:
		var out: Array[Dictionary] = []
		for item_id: String in _records:
			out.append(_records[item_id])
		return out

	func place(item_id: String, definition_id: StringName, cells: Array[Vector3i]) -> void:
		_records[item_id] = {"item_id": item_id, "definition_id": definition_id, "cells": cells}
		furniture_changed.emit()

	func remove(item_id: String) -> void:
		_records.erase(item_id)
		furniture_changed.emit()


func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


func _make_bv(grid: VoxelWorldGrid, registry: Object = null) -> BuildValidation:
	var bv: BuildValidation = auto_free(BuildValidation.new())
	bv.config = BuildValidationConfig.new()
	bv.voxel_world = grid
	bv.furniture_registry = registry
	bv.setup()
	return bv


func _solid_contents() -> CellContents:
	return CellContents.new(1, 0)


## Builds a valid ROOM: [param interior_cell] plus a companion interior cell
## (both floor+roof, orthogonally adjacent -- satisfies `min_room_cells` = 2
## on their own), next to a permanent open-sky escape cell (floor only, no
## roof) one step from [param interior_cell] (mirrors
## `analysis_pass_lifecycle_test.gd`'s established `_add_interior_cell` x2 +
## `_add_open_sky_cell` pattern). The companion cell sits at [param
## interior_cell] `+ Vector3i(0, 0, 1)` -- chosen so it never collides with
## any [param escape_cell]/other-fixture coordinate this suite uses (always
## offset along x).
func _build_valid_room(grid: VoxelWorldGrid, interior_cell: Vector3i, escape_cell: Vector3i) -> void:
	var companion_cell: Vector3i = interior_cell + Vector3i(0, 0, 1)
	var changes: Dictionary[Vector3i, CellContents] = {}
	for cell: Vector3i in [interior_cell, companion_cell]:
		changes[cell + Vector3i(0, -1, 0)] = _solid_contents()
		changes[cell + Vector3i(0, MAX_ROOM_HEIGHT, 0)] = _solid_contents()
	changes[escape_cell + Vector3i(0, -1, 0)] = _solid_contents()
	grid.bulk_write(changes)


## Builds a SEALED region: two connected interior cells, floor+roof, with no
## escape anywhere (>= min_room_cells but no outside connection).
func _build_sealed_region(grid: VoxelWorldGrid, cell_a: Vector3i, cell_b: Vector3i) -> void:
	var changes: Dictionary[Vector3i, CellContents] = {}
	for cell: Vector3i in [cell_a, cell_b]:
		changes[cell + Vector3i(0, -1, 0)] = _solid_contents()
		changes[cell + Vector3i(0, MAX_ROOM_HEIGHT, 0)] = _solid_contents()
	grid.bulk_write(changes)


# ---------------------------------------------------------------------------
# AC12 / AC14 — bed in a valid room -> sheltered; bed in a sealed region ->
# unsheltered
# ---------------------------------------------------------------------------

func test_ac12_bed_inside_valid_room_is_sheltered() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()
	var interior_cell := Vector3i(0, 1, 0)
	var escape_cell := Vector3i(1, 1, 0)
	_build_valid_room(grid, interior_cell, escape_cell)

	var bv: BuildValidation = _make_bv(grid, registry)
	registry.place("bed_1", &"bed", [interior_cell])

	assert_bool(bv.get_shelter_status("bed_1")).is_true()


func test_ac14_bed_in_sealed_region_is_unsheltered() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()
	var cell_a := Vector3i(10, 1, 10)
	var cell_b := Vector3i(11, 1, 10)
	_build_sealed_region(grid, cell_a, cell_b)

	var bv: BuildValidation = _make_bv(grid, registry)
	registry.place("bed_2", &"bed", [cell_a])

	assert_bool(bv.get_shelter_status("bed_2")).is_false()


# ---------------------------------------------------------------------------
# AC13 — a roof hole opening above the bed's cell flips it to unsheltered,
# exactly one emission
# ---------------------------------------------------------------------------

func test_ac13_roof_hole_above_bed_flips_to_unsheltered_with_one_emission() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()
	var interior_cell := Vector3i(20, 1, 20)
	var escape_cell := Vector3i(21, 1, 20)
	_build_valid_room(grid, interior_cell, escape_cell)

	var bv: BuildValidation = _make_bv(grid, registry)
	registry.place("bed_3", &"bed", [interior_cell])
	assert_bool(bv.get_shelter_status("bed_3")).is_true()

	# GDScript lambda scalar-capture pitfall: a plain `int` local is captured
	# BY VALUE at lambda-creation time, so `emit_count += 1` inside the lambda
	# would mutate an invisible copy, never this outer variable. A one-element
	# `Array[int]` is captured BY REFERENCE (Arrays/Dictionaries/Objects are
	# reference types), so mutating its element is visible here.
	var emit_count: Array[int] = [0]
	bv.shelter_status_changed.connect(func(_id: String, _sheltered: bool) -> void: emit_count[0] += 1)

	# Act — punch a hole directly through the bed's own roof cell (nothing
	# else above it within max_room_height, so it goes fully open-sky).
	grid.bulk_write({interior_cell + Vector3i(0, MAX_ROOM_HEIGHT, 0): CellContents.new(0, 0)})

	assert_bool(bv.get_shelter_status("bed_3")).is_false()
	assert_int(emit_count[0]).is_equal(1)


# ---------------------------------------------------------------------------
# AC15 — bed exactly under the roof edge vs. one cell outside it
# ---------------------------------------------------------------------------

func test_ac15_bed_under_roof_edge_sheltered_one_cell_outside_not() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()

	# A 2-wide roofed room: cells (30,1,30) and (31,1,30) are the interior +
	# escape half; (32,1,30) sits one cell beyond the roof's edge (floor only,
	# no roof at all -- open sky, never a candidate cell).
	var under_edge := Vector3i(30, 1, 30)
	var escape_cell := Vector3i(31, 1, 30)
	var outside_edge := Vector3i(32, 1, 30)
	_build_valid_room(grid, under_edge, escape_cell)
	grid.bulk_write({outside_edge + Vector3i(0, -1, 0): _solid_contents()})

	var bv: BuildValidation = _make_bv(grid, registry)
	registry.place("bed_under_edge", &"bed", [under_edge])
	registry.place("bed_outside_edge", &"bed", [outside_edge])

	assert_bool(bv.get_shelter_status("bed_under_edge")).is_true()
	assert_bool(bv.get_shelter_status("bed_outside_edge")).is_false()


# ---------------------------------------------------------------------------
# AC16 — exactly one emission per transition; two listeners both see it
# ---------------------------------------------------------------------------

func test_ac16_two_listeners_both_observe_exactly_one_emission_per_transition() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()
	var cell_a := Vector3i(40, 1, 40)
	var cell_b := Vector3i(41, 1, 40)
	_build_sealed_region(grid, cell_a, cell_b)

	var bv: BuildValidation = _make_bv(grid, registry)

	# See test_ac13's own comment: one-element Array[int] boxes, never a bare
	# `int` local, to survive the GDScript lambda scalar-capture-by-value trap.
	var listener_a_count: Array[int] = [0]
	var listener_b_count: Array[int] = [0]
	bv.shelter_status_changed.connect(func(_id: String, _sheltered: bool) -> void: listener_a_count[0] += 1)
	bv.shelter_status_changed.connect(func(_id: String, _sheltered: bool) -> void: listener_b_count[0] += 1)

	# Act — placing the bed in the sealed region is its first classification,
	# a real transition (unclassified -> unsheltered).
	registry.place("bed_4", &"bed", [cell_a])

	assert_int(listener_a_count[0]).is_equal(1)
	assert_int(listener_b_count[0]).is_equal(1)


# ---------------------------------------------------------------------------
# No-transition silence — a re-analysis leaving every flag unchanged emits
# nothing
# ---------------------------------------------------------------------------

func test_no_transition_re_analysis_emits_nothing() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()
	var interior_cell := Vector3i(50, 1, 50)
	var escape_cell := Vector3i(51, 1, 50)
	_build_valid_room(grid, interior_cell, escape_cell)

	var bv: BuildValidation = _make_bv(grid, registry)
	registry.place("bed_5", &"bed", [interior_cell])
	assert_bool(bv.get_shelter_status("bed_5")).is_true()

	var emit_count: Array[int] = [0]
	bv.shelter_status_changed.connect(func(_id: String, _sheltered: bool) -> void: emit_count[0] += 1)

	# Act — a structurally irrelevant write far away triggers a real pass
	# (form_affected_regions still resolves zero regions for it), which still
	# re-classifies all furniture -- but bed_5's flag is unchanged.
	grid.bulk_write({Vector3i(90, 0, 90): _solid_contents()})

	assert_bool(bv.get_shelter_status("bed_5")).is_true()
	assert_int(emit_count[0]).is_equal(0)


# ---------------------------------------------------------------------------
# BV-1 — null provider: zero items, zero emissions, no error
# ---------------------------------------------------------------------------

func test_null_furniture_registry_yields_zero_items_zero_emissions_no_error() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid, null)

	var emit_count: Array[int] = [0]
	bv.shelter_status_changed.connect(func(_id: String, _sheltered: bool) -> void: emit_count[0] += 1)

	# Act — a real structural pass runs, with no furniture_registry wired.
	_build_valid_room(grid, Vector3i(60, 1, 60), Vector3i(61, 1, 60))

	assert_int(emit_count[0]).is_equal(0)
	assert_bool(bv.get_shelter_status("anything")).is_false()


# ---------------------------------------------------------------------------
# Rule 11 / AC31 — the load pass silently seeds shelter status; a subsequent
# live transition still emits
# ---------------------------------------------------------------------------

func test_load_pass_seeds_shelter_status_silently_then_a_later_transition_emits() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()
	var cell_a := Vector3i(70, 1, 70)
	var cell_b := Vector3i(71, 1, 70)
	_build_sealed_region(grid, cell_a, cell_b)  # written directly -- bv does not exist yet.
	registry._records["bed_6"] = {"item_id": "bed_6", "definition_id": &"bed", "cells": [cell_a] as Array[Vector3i]}

	var bv: BuildValidation = auto_free(BuildValidation.new())
	bv.config = BuildValidationConfig.new()
	bv.voxel_world = grid
	bv.furniture_registry = registry
	bv.setup()  # subscribes only from now on -- no pass has run yet.

	var emit_count: Array[int] = [0]
	bv.shelter_status_changed.connect(func(_id: String, _sheltered: bool) -> void: emit_count[0] += 1)

	# Act — the load pass: first-ever classification of bed_6, silently.
	bv.run_load_pass()

	assert_bool(bv.get_shelter_status("bed_6")).is_false()
	assert_int(emit_count[0]).is_equal(0)

	# Act — now open the sealed region to the outside (a REAL, live
	# transition after load) by adding a NEW, permanently-unroofed escape cell
	# adjacent to cell_b -- cell_a/cell_b's own floor+roof are never touched,
	# so their candidate/region-membership status is unaffected; only the
	# reachability trace gains a new open-sky neighbor to walk into.
	var escape_cell: Vector3i = cell_b + Vector3i(1, 0, 0)
	grid.bulk_write({escape_cell + Vector3i(0, -1, 0): _solid_contents()})

	assert_bool(bv.get_shelter_status("bed_6")).is_true()
	assert_int(emit_count[0]).is_equal(1)


# ---------------------------------------------------------------------------
# BV-2 second trigger — furniture_changed re-classifies with no voxel write
# ---------------------------------------------------------------------------

func test_furniture_changed_signal_reclassifies_with_no_voxel_write() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()
	var interior_cell := Vector3i(80, 1, 80)
	var escape_cell := Vector3i(81, 1, 80)
	_build_valid_room(grid, interior_cell, escape_cell)  # room exists BEFORE bv is made.

	var bv: BuildValidation = _make_bv(grid, registry)
	assert_int(bv.get_analysis_pass_count()).is_equal(0)  # no structural pass has run under bv.

	# Act — placing furniture fires furniture_changed only; no bulk_write.
	registry.place("bed_7", &"bed", [interior_cell])

	assert_bool(bv.get_shelter_status("bed_7")).is_true()
	assert_int(bv.get_analysis_pass_count()).is_equal(0)  # AC19/20's counter is structural-only.


func test_furniture_removed_untracks_without_emitting() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()
	var interior_cell := Vector3i(85, 1, 85)
	var escape_cell := Vector3i(86, 1, 85)
	_build_valid_room(grid, interior_cell, escape_cell)

	var bv: BuildValidation = _make_bv(grid, registry)
	registry.place("bed_8", &"bed", [interior_cell])
	assert_bool(bv.get_shelter_status("bed_8")).is_true()

	var emit_count: Array[int] = [0]
	bv.shelter_status_changed.connect(func(_id: String, _sheltered: bool) -> void: emit_count[0] += 1)

	# Act
	registry.remove("bed_8")

	assert_bool(bv.get_shelter_status("bed_8")).is_false()  # untracked -- the "never classified" default.
	assert_int(emit_count[0]).is_equal(0)


# ---------------------------------------------------------------------------
# Multi-cell footprint — sheltered iff EVERY occupied cell is Room
# ---------------------------------------------------------------------------

func test_multi_cell_footprint_sheltered_only_if_every_cell_is_room() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()
	var inside_cell := Vector3i(100, 1, 100)
	var escape_cell := Vector3i(101, 1, 100)
	_build_valid_room(grid, inside_cell, escape_cell)
	# A second footprint cell that is open sky (never a candidate at all).
	var outside_cell := Vector3i(102, 1, 100)
	grid.bulk_write({outside_cell + Vector3i(0, -1, 0): _solid_contents()})

	var bv: BuildValidation = _make_bv(grid, registry)
	registry.place("bed_multi", &"bed", [inside_cell, outside_cell])

	assert_bool(bv.get_shelter_status("bed_multi")).is_false()


# ---------------------------------------------------------------------------
# Need-functional config resolution (BV-1 §6)
# ---------------------------------------------------------------------------

func test_need_functional_item_ids_default_contains_bed() -> void:
	var config := BuildValidationConfig.new()
	assert_bool(config.need_functional_item_ids.has(&"bed")).is_true()


func test_is_need_functional_unknown_id_returns_false_without_error() -> void:
	# FLIPPED (rid-009): res://data/items/bed.tres now ships as real MVP
	# content, so ResourceItemDatabase's global Autoload resolves &"bed" via
	# the REAL production data set -- is_need_functional(&"bed") is TRUE
	# against real content, never a test-local mock (this is the exact
	# BLOCKING DoD line Sprint 10's sign-off named as unmet, §4.1/§4.4
	# condition #2 -- closed here). The false branch for a genuinely unknown
	# id is retained as its own real, useful assertion -- the fail-safe
	# default this method's own contract requires for an id nothing has ever
	# authored.
	var config := BuildValidationConfig.new()
	assert_bool(config.is_need_functional(&"totally_unknown_item")).is_false()
	assert_bool(config.is_need_functional(&"bed")).is_true()


func test_no_hardcoded_bed_literal_in_shelter_classification_predicate_logic() -> void:
	# The config's own DEFAULT VALUE is allowed to name &"bed" (that is the
	# data-driven default, not application logic) -- this guard scans only
	# the pure classifier + BuildValidation's own furniture-orchestration
	# code, neither of which may ever compare against &"bed" directly.
	for path: String in [
		"res://src/build_validation/build_validation_shelter_classifier.gd",
		"res://src/build_validation/build_validation.gd",
	]:
		var source: String = _read_source_stripped_of_comments(path)
		assert_bool(source.contains("\"bed\"")).is_false()
		assert_bool(source.contains("&\"bed\"")).is_false()


# ---------------------------------------------------------------------------
# Grep guard — furniture occupancy never read from CellContents
# ---------------------------------------------------------------------------

func test_shelter_classifier_never_reads_cell_contents() -> void:
	var source: String = _read_source_stripped_of_comments(
		"res://src/build_validation/build_validation_shelter_classifier.gd"
	)
	assert_bool(source.contains("CellContents")).is_false()


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Reads [param file_path], STRIPPING full-line `#`/`##` doc-comment lines
## first -- mirrors `tests/unit/build_validation/candidate_cell_test.gd`'s
## established precedent.
func _read_source_stripped_of_comments(file_path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(file_path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined
