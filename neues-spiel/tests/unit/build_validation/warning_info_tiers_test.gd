## Unit test — Build Validation & Navigability story build-validation-008
## (Warning/Info tiers, exclusivity, and load-pass emissions; ADR-0007
## primary, ADR-0011 as the downstream UI contract).
##
## **KNOWN GAP, CLOSED by rid-009** (mirrors bv-006's own
## `test_is_need_functional_unknown_id_returns_false_without_error` --
## flipped the same sprint): `res://data/items/bed.tres` now ships as real
## MVP content (Sprint 11), so `ResourceItemDatabase.get_by_id(&"bed")`
## resolves the real, authored entry and
## [method BuildValidationConfig.is_need_functional] is `true` for `&"bed"`
## against the REAL Autoload-tier `ResourceItemDatabase` singleton (ADR-0001)
## -- never a test-local mock. The two dedicated tests that PINNED today's
## honest zero-emission behavior as a documented, named limitation
## (`test_documented_limitation_bed_in_sealed_region_emits_zero_warning_
## pending_rid_content`, `test_documented_limitation_bed_unsheltered_open_
## emits_zero_info_pending_rid_content`) are renamed and rewritten below into
## genuine two-branch tests, each in ONE connected scenario: the real,
## now-authored `&"bed"` id drives an actual `sealed_space_warning`/
## `unsheltered_furniture_info` EMISSION through the full pipeline (the
## flipped TRUE branch), while a decorative (non-functional) item in the
## SAME scenario still contributes zero (the retained FALSE branch -- not
## lost, proven side-by-side rather than in isolation). See this story's
## flip-evidence doc (`production/qa/evidence/rid-009-bed-functional-flip-
## evidence.md`) for the exact quoted pre/post assertions and suite counts.
## Consequently this suite proves the Warning/Info tier contract on TWO
## levels:
## 1. **[BuildValidationTierClassifier], directly** -- its own
##    `is_need_functional` parameter is a plain caller-supplied `bool`, so
##    every AC's actual DECISION LOGIC (AC3/17/18/22/28/35's mechanics, tier
##    exclusivity, the crawlspace no-region case, level-triggered
##    re-evaluation, a live tier swap) is fully provable, deterministic, and
##    independent of RID content.
## 2. **[BuildValidation]'s own signal-emission plumbing** -- the
##    zero-furniture case (AC34), the decorative-item case (AC35), the
##    four-signal contract, the load pass's silence over
##    `room_recognized`/`shelter_status_changed`, the private grouping helper
##    in isolation, AND (as of rid-009) a real end-to-end `sealed_space_
##    warning`/`unsheltered_furniture_info` emission for the real, authored
##    `&"bed"` id -- all tested directly against the real module, the real
##    Autoload RID, and the real shipped `res://data/items/` content. Plus a
##    source-level structural proof that the two signals' `emit()` call
##    sites are never gated by `silent` the way `shelter_status_changed`'s
##    own is (AC31's "these two DO fire on the load pass" half).
class_name BuildValidationWarningInfoTiersTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

const MAX_ROOM_HEIGHT: int = 8  # BuildValidationConfig default.
const MIN_ROOM_CELLS: int = 2   # BuildValidationConfig default.


## Minimal duck-typed furniture-registry stub (BV-1 §5 shape), mirrors
## `shelter_classification_test.gd`'s established `_StubFurnitureRegistry`.
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


func _empty_contents() -> CellContents:
	return CellContents.new(0, 0)


## Builds a valid ROOM: [param interior_cell] plus a companion interior cell,
## next to a permanent open-sky escape cell -- mirrors
## `shelter_classification_test.gd`'s established `_build_valid_room` helper.
func _build_valid_room(grid: VoxelWorldGrid, interior_cell: Vector3i, escape_cell: Vector3i) -> void:
	var companion_cell: Vector3i = interior_cell + Vector3i(0, 0, 1)
	var changes: Dictionary[Vector3i, CellContents] = {}
	for cell: Vector3i in [interior_cell, companion_cell]:
		changes[cell + Vector3i(0, -1, 0)] = _solid_contents()
		changes[cell + Vector3i(0, MAX_ROOM_HEIGHT, 0)] = _solid_contents()
	changes[escape_cell + Vector3i(0, -1, 0)] = _solid_contents()
	grid.bulk_write(changes)


## Builds a SEALED region: two connected interior cells, floor+roof, with no
## escape anywhere -- mirrors `shelter_classification_test.gd`'s established
## `_build_sealed_region` helper.
func _build_sealed_region(grid: VoxelWorldGrid, cell_a: Vector3i, cell_b: Vector3i) -> void:
	var changes: Dictionary[Vector3i, CellContents] = {}
	for cell: Vector3i in [cell_a, cell_b]:
		changes[cell + Vector3i(0, -1, 0)] = _solid_contents()
		changes[cell + Vector3i(0, MAX_ROOM_HEIGHT, 0)] = _solid_contents()
	grid.bulk_write(changes)


## Records every `sealed_space_warning` emission as a plain [Dictionary] into
## [param captured] -- an [Array] is a reference type, so appending inside the
## lambda is visible to the caller (avoids the scalar-capture-by-value pitfall
## a bare `int`/`bool` local would hit).
func _record_sealed_space_warning(bv: BuildValidation, captured: Array) -> void:
	bv.sealed_space_warning.connect(
		func(region_cells: Array[Vector3i], affected_item_ids: Array[String], why_string: String) -> void:
			captured.append({
				"cells": region_cells, "item_ids": affected_item_ids, "why": why_string
			})
	)


func _record_unsheltered_furniture_info(bv: BuildValidation, captured: Array) -> void:
	bv.unsheltered_furniture_info.connect(
		func(item_id: String, why_string: String) -> void:
			captured.append({"item_id": item_id, "why": why_string})
	)


# ---------------------------------------------------------------------------
# BuildValidationTierClassifier — direct unit tests (no RID dependency: this
# class's own `is_need_functional` parameter is a plain caller-supplied bool)
# ---------------------------------------------------------------------------

func test_classifier_sheltered_item_is_none_regardless_of_need_functional() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var interior_cell := Vector3i(0, 1, 0)
	var escape_cell := Vector3i(1, 1, 0)
	_build_valid_room(grid, interior_cell, escape_cell)

	var result: BuildValidationTierClassifier.ItemTierResult = BuildValidationTierClassifier.classify_item_tier(
		grid, [interior_cell], true, true, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	assert_int(result.tier).is_equal(BuildValidationTierClassifier.Tier.NONE)
	assert_bool(result.sealed_region == null).is_true()


## AC3 / AC17 (sealed half) — a need-functional item in a Sealed region is
## WARNING, carrying that region.
func test_classifier_sealed_and_need_functional_is_warning_with_region() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var cell_a := Vector3i(10, 1, 10)
	var cell_b := Vector3i(11, 1, 10)
	_build_sealed_region(grid, cell_a, cell_b)

	var result: BuildValidationTierClassifier.ItemTierResult = BuildValidationTierClassifier.classify_item_tier(
		grid, [cell_a], false, true, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	assert_int(result.tier).is_equal(BuildValidationTierClassifier.Tier.WARNING)
	assert_bool(result.sealed_region != null).is_true()
	assert_bool(result.sealed_region.contains(cell_a)).is_true()
	assert_bool(result.sealed_region.contains(cell_b)).is_true()


## AC35's mechanical proof — sealed but NOT need-functional (decorative) is
## NONE, never Warning.
func test_classifier_sealed_but_not_need_functional_is_none() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var cell_a := Vector3i(20, 1, 20)
	var cell_b := Vector3i(21, 1, 20)
	_build_sealed_region(grid, cell_a, cell_b)

	var result: BuildValidationTierClassifier.ItemTierResult = BuildValidationTierClassifier.classify_item_tier(
		grid, [cell_a], false, false, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	assert_int(result.tier).is_equal(BuildValidationTierClassifier.Tier.NONE)
	assert_bool(result.sealed_region == null).is_true()


## AC17 (open half) — a need-functional item unsheltered in the open (no
## Sealed cell anywhere) is INFO.
func test_classifier_open_and_need_functional_is_info() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var open_cell := Vector3i(30, 1, 30)
	grid.bulk_write({open_cell + Vector3i(0, -1, 0): _solid_contents()})

	var result: BuildValidationTierClassifier.ItemTierResult = BuildValidationTierClassifier.classify_item_tier(
		grid, [open_cell], false, true, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	assert_int(result.tier).is_equal(BuildValidationTierClassifier.Tier.INFO)
	assert_bool(result.sealed_region == null).is_true()


func test_classifier_open_and_not_need_functional_is_none() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var open_cell := Vector3i(31, 1, 31)
	grid.bulk_write({open_cell + Vector3i(0, -1, 0): _solid_contents()})

	var result: BuildValidationTierClassifier.ItemTierResult = BuildValidationTierClassifier.classify_item_tier(
		grid, [open_cell], false, false, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	assert_int(result.tier).is_equal(BuildValidationTierClassifier.Tier.NONE)


## AC28 — a crawlspace (roof exactly 2 above the floor, Edge Case 13) forms
## NO candidate region at all; a need-functional item inside is INFO, never
## Warning (there is no Sealed region to find).
func test_classifier_crawlspace_no_region_is_info_not_warning() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var cell := Vector3i(40, 1, 40)
	# Floor (y=0) + a roof exactly 2 cells above the floor (y=2) -- inside the
	# 3-cell clearance zone (cell, cell+1, cell+2 = y=1,2,3 must all be
	# empty), so this fails standability's own clearance check before the
	# roof scan ever runs.
	grid.bulk_write({
		cell + Vector3i(0, -1, 0): _solid_contents(),
		cell + Vector3i(0, 1, 0): _solid_contents(),
	})

	var result: BuildValidationTierClassifier.ItemTierResult = BuildValidationTierClassifier.classify_item_tier(
		grid, [cell], false, true, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	assert_int(result.tier).is_equal(BuildValidationTierClassifier.Tier.INFO)
	assert_bool(result.sealed_region == null).is_true()


func test_classifier_empty_cells_is_none() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var result: BuildValidationTierClassifier.ItemTierResult = BuildValidationTierClassifier.classify_item_tier(
		grid, [] as Array[Vector3i], false, true, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)
	assert_int(result.tier).is_equal(BuildValidationTierClassifier.Tier.NONE)


## Multi-cell aggregation (documented judgment call, no AC pins this exactly):
## a footprint straddling one Sealed cell and one open (no-region) cell
## resolves WARNING -- any Sealed cell dominates, regardless of array order.
func test_classifier_multi_cell_any_sealed_cell_dominates_open() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var open_cell := Vector3i(50, 1, 50)
	grid.bulk_write({open_cell + Vector3i(0, -1, 0): _solid_contents()})
	var sealed_a := Vector3i(52, 1, 50)
	var sealed_b := Vector3i(53, 1, 50)
	_build_sealed_region(grid, sealed_a, sealed_b)

	# open_cell listed FIRST -- proves the loop does not stop at the first
	# non-Sealed cell.
	var result: BuildValidationTierClassifier.ItemTierResult = BuildValidationTierClassifier.classify_item_tier(
		grid, [open_cell, sealed_a], false, true, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	assert_int(result.tier).is_equal(BuildValidationTierClassifier.Tier.WARNING)


## AC22's logic-level proof — repeated calls with unchanged (Sealed) input
## return WARNING every time: the classifier is stateless and level-
## triggered, never edge-detected or cached.
func test_classifier_repeated_calls_same_sealed_input_reemit_warning_every_time() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var cell_a := Vector3i(60, 1, 60)
	var cell_b := Vector3i(61, 1, 60)
	_build_sealed_region(grid, cell_a, cell_b)

	for i: int in range(3):
		var result: BuildValidationTierClassifier.ItemTierResult = BuildValidationTierClassifier.classify_item_tier(
			grid, [cell_a], false, true, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
		)
		assert_int(result.tier).is_equal(BuildValidationTierClassifier.Tier.WARNING)


## Tier swap, logic-level proof — the SAME cell classifies WARNING while
## Sealed, then INFO once the seal opens (a fresh, live query each time, never
## a stale cached verdict); no third "cleared" state exists at all.
func test_classifier_tier_swap_sealed_then_open_flips_warning_to_info() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var cell_a := Vector3i(70, 1, 70)
	var cell_b := Vector3i(71, 1, 70)
	_build_sealed_region(grid, cell_a, cell_b)

	var sealed_result: BuildValidationTierClassifier.ItemTierResult = BuildValidationTierClassifier.classify_item_tier(
		grid, [cell_a], false, true, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)
	assert_int(sealed_result.tier).is_equal(BuildValidationTierClassifier.Tier.WARNING)

	# Act — remove cell_b's own roof (never touching cell_a's own body), so
	# cell_b drops out of candidate-interior status entirely and cell_a's
	# region shrinks to itself alone (< min_room_cells) -> OPEN, not a new
	# SEALED verdict.
	grid.bulk_write({cell_b + Vector3i(0, MAX_ROOM_HEIGHT, 0): _empty_contents()})

	var open_result: BuildValidationTierClassifier.ItemTierResult = BuildValidationTierClassifier.classify_item_tier(
		grid, [cell_a], false, true, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)
	assert_int(open_result.tier).is_equal(BuildValidationTierClassifier.Tier.INFO)


# ---------------------------------------------------------------------------
# Grouping — BuildValidation._add_to_sealed_group, called directly (private
# by convention only; GDScript enforces no access control). No RID
# dependency: this helper only groups already-formed regions + item ids.
# ---------------------------------------------------------------------------

func test_grouping_two_items_same_region_combine_into_one_group() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)
	var cell_a := Vector3i(80, 1, 80)
	var cell_b := Vector3i(81, 1, 80)
	_build_sealed_region(grid, cell_a, cell_b)

	var region_from_a: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, cell_a, MAX_ROOM_HEIGHT
	)
	var region_from_b: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, cell_b, MAX_ROOM_HEIGHT
	)

	var cell_index: Dictionary[Vector3i, int] = {}
	var groups: Array[Dictionary] = []
	bv._add_to_sealed_group(cell_index, groups, region_from_a, "bed_a")
	bv._add_to_sealed_group(cell_index, groups, region_from_b, "bed_b")

	assert_int(groups.size()).is_equal(1)
	var item_ids: Array = groups[0]["item_ids"]
	assert_int(item_ids.size()).is_equal(2)
	assert_bool(item_ids.has("bed_a")).is_true()
	assert_bool(item_ids.has("bed_b")).is_true()


func test_grouping_two_items_distinct_regions_stay_separate() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)
	var region_1_a := Vector3i(90, 1, 90)
	var region_1_b := Vector3i(91, 1, 90)
	var region_2_a := Vector3i(100, 1, 100)
	var region_2_b := Vector3i(101, 1, 100)
	_build_sealed_region(grid, region_1_a, region_1_b)
	_build_sealed_region(grid, region_2_a, region_2_b)

	var region_1: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, region_1_a, MAX_ROOM_HEIGHT
	)
	var region_2: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, region_2_a, MAX_ROOM_HEIGHT
	)

	var cell_index: Dictionary[Vector3i, int] = {}
	var groups: Array[Dictionary] = []
	bv._add_to_sealed_group(cell_index, groups, region_1, "bed_r1")
	bv._add_to_sealed_group(cell_index, groups, region_2, "bed_r2")

	assert_int(groups.size()).is_equal(2)
	var all_item_ids: Array = []
	for group: Dictionary in groups:
		all_item_ids.append_array(group["item_ids"])
	assert_bool(all_item_ids.has("bed_r1")).is_true()
	assert_bool(all_item_ids.has("bed_r2")).is_true()


# ---------------------------------------------------------------------------
# BuildValidation integration — provable today without resolvable RID content
# ---------------------------------------------------------------------------

## AC34 — a sealed region with NO furniture at all raises zero Warning.
func test_ac34_sealed_region_no_furniture_zero_warning() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()
	var cell_a := Vector3i(110, 1, 110)
	var cell_b := Vector3i(111, 1, 110)

	var bv: BuildValidation = _make_bv(grid, registry)
	var warnings: Array = []
	_record_sealed_space_warning(bv, warnings)

	_build_sealed_region(grid, cell_a, cell_b)

	assert_int(bv.get_region_status(cell_a)).is_equal(BuildValidationReachability.Verdict.SEALED)
	assert_int(warnings.size()).is_equal(0)


## AC35 [PROVISIONAL] — a decorative item in a sealed space: shelter still
## fires (Rule 10, ALL furniture types), Warning and Info stay 0.
func test_ac35_decorative_item_in_sealed_space_zero_warning_zero_info() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()
	var cell_a := Vector3i(120, 1, 120)
	var cell_b := Vector3i(121, 1, 120)
	_build_sealed_region(grid, cell_a, cell_b)

	var bv: BuildValidation = _make_bv(grid, registry)
	assert_bool(bv.config.is_need_functional(&"decorative_rug")).is_false()

	var warnings: Array = []
	var infos: Array = []
	var shelter_changes: Array[int] = [0]
	_record_sealed_space_warning(bv, warnings)
	_record_unsheltered_furniture_info(bv, infos)
	bv.shelter_status_changed.connect(func(_id: String, _sheltered: bool) -> void: shelter_changes[0] += 1)

	registry.place("rug_1", &"decorative_rug", [cell_a])

	assert_int(shelter_changes[0]).is_equal(1)
	assert_bool(bv.get_shelter_status("rug_1")).is_false()
	assert_int(warnings.size()).is_equal(0)
	assert_int(infos.size()).is_equal(0)


## Signal-contract guard — this module's own script-declared signal set is
## exactly the four contracted names, no others.
func test_signal_contract_exactly_four_signals() -> void:
	var bv: BuildValidation = auto_free(BuildValidation.new())
	bv.config = BuildValidationConfig.new()
	bv.voxel_world = _make_grid()
	bv.setup()

	var script: Script = bv.get_script()
	var names: Array[String] = []
	for sig: Dictionary in script.get_script_signal_list():
		names.append(String(sig["name"]))

	assert_int(names.size()).is_equal(4)
	assert_bool(names.has("shelter_status_changed")).is_true()
	assert_bool(names.has("room_recognized")).is_true()
	assert_bool(names.has("sealed_space_warning")).is_true()
	assert_bool(names.has("unsheltered_furniture_info")).is_true()


## The load pass never fires `room_recognized`/`shelter_status_changed`
## (AC31's first half -- unaffected by the RID gap, since it concerns
## silence, not a real emission).
func test_run_load_pass_silences_room_recognized_and_shelter_status_changed() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()

	var room_cell := Vector3i(130, 1, 130)
	var room_escape := Vector3i(131, 1, 130)
	_build_valid_room(grid, room_cell, room_escape)

	var sealed_a := Vector3i(140, 1, 140)
	var sealed_b := Vector3i(141, 1, 140)
	_build_sealed_region(grid, sealed_a, sealed_b)
	registry._records["bed_load"] = {
		"item_id": "bed_load", "definition_id": &"bed", "cells": [sealed_a] as Array[Vector3i]
	}

	var bv: BuildValidation = auto_free(BuildValidation.new())
	bv.config = BuildValidationConfig.new()
	bv.voxel_world = grid
	bv.furniture_registry = registry
	bv.setup()  # subscribes only from now on -- no pass has run yet.

	var room_recognized_count: Array[int] = [0]
	var shelter_changed_count: Array[int] = [0]
	bv.room_recognized.connect(
		func(_cells: Array[Vector3i], _celebrate: bool, _group_id: StringName) -> void:
			room_recognized_count[0] += 1
	)
	bv.shelter_status_changed.connect(
		func(_id: String, _sheltered: bool) -> void: shelter_changed_count[0] += 1
	)

	bv.run_load_pass()

	assert_int(room_recognized_count[0]).is_equal(0)
	assert_int(shelter_changed_count[0]).is_equal(0)
	assert_int(bv.get_region_status(room_cell)).is_equal(BuildValidationReachability.Verdict.ROOM)
	assert_bool(bv.get_shelter_status("bed_load")).is_false()


## AC31's second half, structural proof — neither `sealed_space_warning.emit`
## nor `unsheltered_furniture_info.emit` inside `_reclassify_all_furniture`
## sits behind a `silent`-gated branch the way `shelter_status_changed`'s own
## emission does (`_patch_shelter_flag`'s `if silent or not is_transition:
## return`) -- proving these two ARE reachable on the load pass (`silent =
## true`) by construction, even though an actual end-to-end emission for a
## real bed is blocked by the documented RID gap (see the two tests below).
func test_reclassify_all_furniture_warning_info_emits_are_not_silent_gated() -> void:
	var source: String = FileAccess.get_file_as_string(
		"res://src/build_validation/build_validation.gd"
	)
	var start: int = source.find("func _reclassify_all_furniture(silent: bool) -> void:")
	assert_bool(start != -1).is_true()
	var next_func: int = source.find("\nfunc ", start + 1)
	assert_bool(next_func != -1).is_true()
	var body: String = source.substr(start, next_func - start)

	assert_bool(body.contains("sealed_space_warning.emit")).is_true()
	assert_bool(body.contains("unsheltered_furniture_info.emit")).is_true()
	assert_bool(body.contains("if silent")).is_false()
	assert_bool(body.contains("if not silent")).is_false()


# ---------------------------------------------------------------------------
# FLIPPED by rid-009 — real end-to-end emissions for the real, authored
# "bed" id, each proven alongside the retained false/zero branch in ONE
# connected scenario (renamed from the pre-rid-009
# `test_documented_limitation_..._pending_rid_content` pins; see class doc
# comment + `production/qa/evidence/rid-009-bed-functional-flip-evidence.md`
# for the exact quoted pre/post assertions).
# ---------------------------------------------------------------------------

## Sealed-region half (AC3/AC17's Warning tier). Renamed from
## `test_documented_limitation_bed_in_sealed_region_emits_zero_warning_
## pending_rid_content` -- pre-rid-009 this function asserted
## `bv.config.is_need_functional(&"bed") == false` and `warnings.size() == 0`
## (the KNOWN GAP). Now: a real, authored `bed` in a Sealed region emits a
## real `sealed_space_warning` (the flipped TRUE branch) while a decorative
## item in the SAME sealed region still contributes zero (the retained
## FALSE/zero branch, proven side-by-side rather than in isolation).
func test_bed_in_sealed_region_emits_sealed_space_warning_rid_content_flipped() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()
	var cell_a := Vector3i(200, 1, 200)
	var cell_b := Vector3i(201, 1, 200)
	_build_sealed_region(grid, cell_a, cell_b)

	var bv: BuildValidation = _make_bv(grid, registry)
	assert_bool(bv.config.is_need_functional(&"bed")).is_true()  # the flip itself.
	assert_bool(bv.config.is_need_functional(&"decorative_rug")).is_false()  # retained false branch.

	var warnings: Array = []
	_record_sealed_space_warning(bv, warnings)
	registry.place("rug_1", &"decorative_rug", [cell_b])  # sealed but NOT need-functional -- joins no group.
	registry.place("bed_1", &"bed", [cell_a])  # sealed AND need-functional -- joins the warning group.

	assert_bool(bv.get_shelter_status("bed_1")).is_false()  # correctly unsheltered.
	assert_int(warnings.size()).is_equal(1)  # FLIPPED -- was 0 pre-rid-009.
	var warning: Dictionary = warnings[0]
	assert_bool((warning["item_ids"] as Array).has("bed_1")).is_true()
	assert_bool((warning["item_ids"] as Array).has("rug_1")).is_false()  # false branch held.


## Open/unsheltered half (AC17's Info tier). Renamed from
## `test_documented_limitation_bed_unsheltered_open_emits_zero_info_
## pending_rid_content` -- pre-rid-009 this function asserted
## `infos.size() == 0` (the KNOWN GAP; `is_need_functional` was not even
## asserted here since it was proven redundantly by the sealed-region test).
## Now: a real, authored `bed` unsheltered in the open emits a real
## `unsheltered_furniture_info` (the flipped TRUE branch) while a decorative
## item in the SAME open scenario still contributes zero (the retained
## FALSE/zero branch).
func test_bed_unsheltered_open_emits_unsheltered_furniture_info_rid_content_flipped() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()
	var open_cell := Vector3i(210, 1, 210)
	var decorative_cell := Vector3i(211, 1, 210)
	grid.bulk_write({
		open_cell + Vector3i(0, -1, 0): _solid_contents(),
		decorative_cell + Vector3i(0, -1, 0): _solid_contents(),
	})

	var bv: BuildValidation = _make_bv(grid, registry)
	assert_bool(bv.config.is_need_functional(&"bed")).is_true()  # the flip itself.
	assert_bool(bv.config.is_need_functional(&"decorative_rug")).is_false()  # retained false branch.

	var infos: Array = []
	_record_unsheltered_furniture_info(bv, infos)
	registry.place("rug_2", &"decorative_rug", [decorative_cell])  # open but NOT need-functional -- no Info.
	registry.place("bed_2", &"bed", [open_cell])  # open AND need-functional -- Info fires.

	assert_bool(bv.get_shelter_status("bed_2")).is_false()
	assert_int(infos.size()).is_equal(1)  # FLIPPED -- was 0 pre-rid-009.
	assert_str(String(infos[0]["item_id"])).is_equal("bed_2")  # false branch (rug_2) never appears.
