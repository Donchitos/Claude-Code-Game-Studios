## Unit test — Build Validation & Navigability story build-validation-007
## (`room_recognized` continuity & celebration pacing; ADR-0007 primary,
## ADR-0002 secondary (`room_cue_cooldown_ticks`); CD Ruling 2 --
## `production/creative-decisions-m02-preflight-2026-07-26.md` condition 3).
##
## Proves:
## 1. Signal payload shape: region cells, `celebrate: bool`, `pass_group_id`
##    (StringName) -- fires on a non-Room -> Room transition.
## 2. AC21: exactly one fire on becoming a room; zero on a re-analysis that
##    keeps it valid; zero on a merge of two already-valid rooms; zero on a
##    split of an existing valid room.
## 3. Accepted MVP consequence (Rule 11): a previously-Sealed pocket merging
##    into an existing valid room emits zero `room_recognized`, while the
##    pocket's own furniture's `shelter_status_changed` still fires
##    correctly.
## 4. AC32: two rooms recognized in different passes inside the cooldown --
##    first `celebrate = true`, second `celebrate = false`.
## 5. AC32b: two rooms recognized in the SAME pass -- both `celebrate = true`
##    with an identical `pass_group_id`, exactly two emissions (no third
##    grouping signal); a third room recognized in a LATER pass inside the
##    window then emits `celebrate = false`.
## 6. Cooldown boundary: a recognition exactly `room_cue_cooldown_ticks`
##    after the previous FIRED celebration celebrates; one tick earlier does
##    not; a quiet (non-celebrating) recognition in between never re-arms the
##    window. `room_cue_cooldown_ticks = 0` means every group celebrates.
## 7. Edge case: a room that goes Room -> Sealed -> Room fires again on the
##    second transition (no interior cell was in a valid room in the
##    immediately-previous snapshot).
## 8. Edge case: a pass recognizing zero rooms emits nothing.
## 9. The load pass never emits `room_recognized` (Rule 11/AC31) and never
##    arms the cooldown (CD Ruling 2 condition 3) -- the first LIVE
##    recognition afterward still celebrates.
class_name BuildValidationRoomRecognizedPacingTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

const MAX_ROOM_HEIGHT: int = 8  # BuildValidationConfig default.
const MIN_ROOM_CELLS: int = 2   # BuildValidationConfig default.
const DEFAULT_COOLDOWN_TICKS: int = 20  # BuildValidationConfig default.


func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


## [param mock_tick] is optional (mirrors [member BuildValidation.
## time_tick_system]'s own nil-safe shape) -- tests that never care about
## pacing may omit it, leaving [member BuildValidation._tick_count] frozen
## at `0` for the whole test.
func _make_bv(grid: VoxelWorldGrid, mock_tick: MockTimeTickSystem = null) -> BuildValidation:
	var bv: BuildValidation = auto_free(BuildValidation.new())
	bv.config = BuildValidationConfig.new()
	bv.voxel_world = grid
	if mock_tick != null:
		bv.time_tick_system = mock_tick
	bv.setup()
	return bv


func _solid_contents() -> CellContents:
	return CellContents.new(1, 0)


func _empty_contents() -> CellContents:
	return CellContents.new(0, 0)


## Adds the floor+roof pair that makes [param cell] a candidate interior cell
## in isolation (per-column, no wall coverage needed) to [param changes] --
## mirrors `analysis_pass_lifecycle_test.gd`'s established helper.
func _add_interior_cell(changes: Dictionary[Vector3i, CellContents], cell: Vector3i) -> void:
	changes[cell + Vector3i(0, -1, 0)] = _solid_contents()
	changes[cell + Vector3i(0, MAX_ROOM_HEIGHT, 0)] = _solid_contents()


## Adds the floor-only write that makes [param cell] a standable, genuinely
## open-sky escape cell (no roof anywhere above it) to [param changes].
func _add_open_sky_cell(changes: Dictionary[Vector3i, CellContents], cell: Vector3i) -> void:
	changes[cell + Vector3i(0, -1, 0)] = _solid_contents()


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


## Records every `room_recognized` emission as a plain [Dictionary] (region
## cells / celebrate / pass_group_id) into [param captured] -- an [Array] is
## a reference type, so appending inside the lambda is visible to the
## caller without the scalar-capture-by-value pitfall a bare `int`/`bool`
## local would hit.
func _record_room_recognized(bv: BuildValidation, captured: Array) -> void:
	bv.room_recognized.connect(
		func(region_cells: Array[Vector3i], celebrate: bool, pass_group_id: StringName) -> void:
			captured.append({
				"cells": region_cells, "celebrate": celebrate, "group_id": pass_group_id
			})
	)


# ---------------------------------------------------------------------------
# Signal payload shape
# ---------------------------------------------------------------------------

func test_signal_payload_shape_on_new_room_recognition() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)
	var captured: Array = []
	_record_room_recognized(bv, captured)

	var changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes, Vector3i(0, 1, 0))
	_add_interior_cell(changes, Vector3i(1, 1, 0))
	_add_open_sky_cell(changes, Vector3i(2, 1, 0))
	grid.bulk_write(changes)

	assert_int(captured.size()).is_equal(1)
	var emission: Dictionary = captured[0]
	var region_cells: Array = emission["cells"]
	assert_int(region_cells.size()).is_equal(2)
	assert_bool(region_cells.has(Vector3i(0, 1, 0))).is_true()
	assert_bool(region_cells.has(Vector3i(1, 1, 0))).is_true()
	assert_bool(emission["celebrate"]).is_true()  # first-ever recognition, never suppressed.
	assert_bool(String(emission["group_id"]) != "").is_true()


# ---------------------------------------------------------------------------
# AC21 — exactly one fire; no re-fire on re-analysis, merge, or split
# ---------------------------------------------------------------------------

func test_ac21_new_room_fires_exactly_once() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)
	var captured: Array = []
	_record_room_recognized(bv, captured)

	var changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes, Vector3i(10, 1, 0))
	_add_interior_cell(changes, Vector3i(11, 1, 0))
	_add_open_sky_cell(changes, Vector3i(12, 1, 0))
	grid.bulk_write(changes)

	assert_int(captured.size()).is_equal(1)


func test_ac21_re_analysis_keeping_room_valid_does_not_refire() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)
	var interior_cell := Vector3i(20, 1, 0)
	var companion_cell := Vector3i(21, 1, 0)
	var escape_cell := Vector3i(22, 1, 0)
	var changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes, interior_cell)
	_add_interior_cell(changes, companion_cell)
	_add_open_sky_cell(changes, escape_cell)
	grid.bulk_write(changes)
	assert_int(bv.get_region_status(interior_cell)).is_equal(BuildValidationReachability.Verdict.ROOM)

	var captured: Array = []
	_record_room_recognized(bv, captured)

	# Act — re-touch the SAME floor cell with the SAME solid contents. This
	# still records a CellChangeRecord (VoxelWorldGrid.bulk_write does not
	# value-compare), re-triggering a pass over the identical, still-valid
	# region.
	grid.bulk_write({interior_cell + Vector3i(0, -1, 0): _solid_contents()})

	assert_int(bv.get_analysis_pass_count()).is_equal(2)
	assert_int(bv.get_region_status(interior_cell)).is_equal(BuildValidationReachability.Verdict.ROOM)
	assert_int(captured.size()).is_equal(0)


func test_ac21_merge_of_two_valid_rooms_does_not_refire() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)

	# Room A: x=30,31 interior, escape x=29.
	var changes_a: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_a, Vector3i(30, 1, 0))
	_add_interior_cell(changes_a, Vector3i(31, 1, 0))
	_add_open_sky_cell(changes_a, Vector3i(29, 1, 0))
	grid.bulk_write(changes_a)

	# Room B: x=33,34 interior, escape x=35. x=32 stays unbuilt (non-candidate),
	# keeping A and B as two DISTINCT regions for now.
	var changes_b: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_b, Vector3i(33, 1, 0))
	_add_interior_cell(changes_b, Vector3i(34, 1, 0))
	_add_open_sky_cell(changes_b, Vector3i(35, 1, 0))
	grid.bulk_write(changes_b)

	assert_int(bv.get_region_status(Vector3i(30, 1, 0))).is_equal(BuildValidationReachability.Verdict.ROOM)
	assert_int(bv.get_region_status(Vector3i(33, 1, 0))).is_equal(BuildValidationReachability.Verdict.ROOM)

	var captured: Array = []
	_record_room_recognized(bv, captured)

	# Act — bridge the gap: x=32 becomes a candidate interior cell, merging
	# A and B into ONE 4-cell region (still a valid Room via either escape).
	var bridge_changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(bridge_changes, Vector3i(32, 1, 0))
	grid.bulk_write(bridge_changes)

	assert_int(bv.get_region_status(Vector3i(30, 1, 0))).is_equal(BuildValidationReachability.Verdict.ROOM)
	assert_int(bv.get_region_status(Vector3i(33, 1, 0))).is_equal(BuildValidationReachability.Verdict.ROOM)
	assert_int(captured.size()).is_equal(0)  # neither original room re-fires.


func test_ac21_split_of_valid_room_does_not_refire() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)

	# A single 5-cell room, x=40..44, with its OWN escape at BOTH ends so
	# each half can independently remain a valid room after the split.
	var changes: Dictionary[Vector3i, CellContents] = {}
	for x: int in range(40, 45):
		_add_interior_cell(changes, Vector3i(x, 1, 0))
	_add_open_sky_cell(changes, Vector3i(39, 1, 0))
	_add_open_sky_cell(changes, Vector3i(45, 1, 0))
	grid.bulk_write(changes)
	assert_int(bv.get_region_status(Vector3i(40, 1, 0))).is_equal(BuildValidationReachability.Verdict.ROOM)

	var captured: Array = []
	_record_room_recognized(bv, captured)

	# Act — occupy the middle cell (x=42) ITSELF with solid content (not its
	# floor/roof, which sit outside the direct-neighbor seed pool a changed
	# cell's own neighborhood scopes -- mirrors
	# `analysis_pass_lifecycle_test.gd`'s Gate-2 precedent: toggling a cell's
	# OWN standability, not a column offset, is what correctly reseeds its
	# immediate neighbors). x=41/43 (each a direct 6-neighbor of x=42) are
	# reseeded directly, splitting the region into {40,41} and {43,44}, each
	# still a valid Room via its own escape.
	grid.bulk_write({Vector3i(42, 1, 0): _solid_contents()})

	assert_int(bv.get_region_status(Vector3i(40, 1, 0))).is_equal(BuildValidationReachability.Verdict.ROOM)
	assert_int(bv.get_region_status(Vector3i(41, 1, 0))).is_equal(BuildValidationReachability.Verdict.ROOM)
	assert_int(bv.get_region_status(Vector3i(43, 1, 0))).is_equal(BuildValidationReachability.Verdict.ROOM)
	assert_int(bv.get_region_status(Vector3i(44, 1, 0))).is_equal(BuildValidationReachability.Verdict.ROOM)
	assert_int(captured.size()).is_equal(0)  # neither child re-fires.


# ---------------------------------------------------------------------------
# Accepted MVP consequence — a Sealed pocket merging into an existing room
# ---------------------------------------------------------------------------

func test_sealed_pocket_merge_into_existing_room_emits_zero_but_shelter_still_fires() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()
	var bv: BuildValidation = auto_free(BuildValidation.new())
	bv.config = BuildValidationConfig.new()
	bv.voxel_world = grid
	bv.furniture_registry = registry
	bv.setup()

	# Room A: x=50,51 interior, escape x=49.
	var changes_a: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_a, Vector3i(50, 1, 0))
	_add_interior_cell(changes_a, Vector3i(51, 1, 0))
	_add_open_sky_cell(changes_a, Vector3i(49, 1, 0))
	grid.bulk_write(changes_a)
	assert_int(bv.get_region_status(Vector3i(50, 1, 0))).is_equal(BuildValidationReachability.Verdict.ROOM)

	# Sealed pocket: x=53,54 interior, NO escape of its own -- carries a bed.
	var changes_pocket: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_pocket, Vector3i(53, 1, 0))
	_add_interior_cell(changes_pocket, Vector3i(54, 1, 0))
	grid.bulk_write(changes_pocket)
	assert_int(bv.get_region_status(Vector3i(53, 1, 0))).is_equal(BuildValidationReachability.Verdict.SEALED)
	registry.place("bed_pocket", &"bed", [Vector3i(53, 1, 0)])
	assert_bool(bv.get_shelter_status("bed_pocket")).is_false()

	var captured: Array = []
	_record_room_recognized(bv, captured)
	var shelter_emit_count: Array[int] = [0]
	bv.shelter_status_changed.connect(
		func(_id: String, _sheltered: bool) -> void: shelter_emit_count[0] += 1
	)

	# Act — bridge x=52 (candidate), merging the sealed pocket into Room A.
	# The merged region reaches Room A's own escape, so it is a valid Room
	# overall -- but the region AS A WHOLE was not "new" (Room A's own cells
	# were already ROOM).
	var bridge_changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(bridge_changes, Vector3i(52, 1, 0))
	grid.bulk_write(bridge_changes)

	assert_int(bv.get_region_status(Vector3i(53, 1, 0))).is_equal(BuildValidationReachability.Verdict.ROOM)
	assert_int(captured.size()).is_equal(0)  # zero room_recognized -- Accepted MVP consequence.
	assert_bool(bv.get_shelter_status("bed_pocket")).is_true()  # the pocket's own bed IS now sheltered.
	assert_int(shelter_emit_count[0]).is_equal(1)  # its shelter_status_changed still fired correctly.


# ---------------------------------------------------------------------------
# AC32 — sequential recognitions in different passes inside the cooldown
# ---------------------------------------------------------------------------

func test_ac32_sequential_recognitions_within_cooldown_second_is_quiet() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var bv: BuildValidation = _make_bv(grid, mock_tick)
	var captured: Array = []
	_record_room_recognized(bv, captured)

	# First room, at tick 0.
	var changes_a: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_a, Vector3i(60, 1, 0))
	_add_interior_cell(changes_a, Vector3i(61, 1, 0))
	_add_open_sky_cell(changes_a, Vector3i(62, 1, 0))
	grid.bulk_write(changes_a)

	# Advance fewer ticks than the cooldown (default 20), then recognize a
	# SEPARATE second room.
	for _i: int in range(5):
		mock_tick.fire_tick()
	var changes_b: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_b, Vector3i(70, 1, 0))
	_add_interior_cell(changes_b, Vector3i(71, 1, 0))
	_add_open_sky_cell(changes_b, Vector3i(72, 1, 0))
	grid.bulk_write(changes_b)

	assert_int(captured.size()).is_equal(2)
	assert_bool(captured[0]["celebrate"]).is_true()
	assert_bool(captured[1]["celebrate"]).is_false()


# ---------------------------------------------------------------------------
# AC32b — same-pass group shares celebrate + pass_group_id; a later quiet room
# ---------------------------------------------------------------------------

func test_ac32b_same_pass_group_shares_celebrate_and_group_id_then_later_quiet_room() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var bv: BuildValidation = _make_bv(grid, mock_tick)
	var captured: Array = []
	_record_room_recognized(bv, captured)

	# Two DISJOINT rooms recognized in ONE combined bulk_write -- ONE pass,
	# two newly-recognized regions.
	var changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes, Vector3i(80, 1, 0))
	_add_interior_cell(changes, Vector3i(81, 1, 0))
	_add_open_sky_cell(changes, Vector3i(82, 1, 0))
	_add_interior_cell(changes, Vector3i(90, 1, 0))
	_add_interior_cell(changes, Vector3i(91, 1, 0))
	_add_open_sky_cell(changes, Vector3i(92, 1, 0))
	grid.bulk_write(changes)

	assert_int(captured.size()).is_equal(2)  # exactly two emissions, no third grouping signal.
	assert_bool(captured[0]["celebrate"]).is_true()
	assert_bool(captured[1]["celebrate"]).is_true()
	assert_bool(captured[0]["group_id"] == captured[1]["group_id"]).is_true()

	# Act — a THIRD, separate room recognized in a LATER pass, still inside
	# the cooldown window (armed at tick 0 by the group above).
	for _i: int in range(3):
		mock_tick.fire_tick()
	var changes_c: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_c, Vector3i(100, 1, 0))
	_add_interior_cell(changes_c, Vector3i(101, 1, 0))
	_add_open_sky_cell(changes_c, Vector3i(102, 1, 0))
	grid.bulk_write(changes_c)

	assert_int(captured.size()).is_equal(3)
	assert_bool(captured[2]["celebrate"]).is_false()
	assert_bool(captured[2]["group_id"] != captured[0]["group_id"]).is_true()  # its own, unshared group id.


# ---------------------------------------------------------------------------
# Cooldown boundary — exact tick celebrates; one tick earlier does not; a
# quiet recognition never re-arms the window
# ---------------------------------------------------------------------------

func test_cooldown_boundary_exact_tick_celebrates_one_tick_early_does_not() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var bv: BuildValidation = _make_bv(grid, mock_tick)
	assert_int(bv.config.room_cue_cooldown_ticks).is_equal(DEFAULT_COOLDOWN_TICKS)
	var captured: Array = []
	_record_room_recognized(bv, captured)

	# Room A, tick 0 -- first-ever recognition, always celebrates; ARMS the
	# cooldown at tick 0.
	var changes_a: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_a, Vector3i(110, 1, 0))
	_add_interior_cell(changes_a, Vector3i(111, 1, 0))
	_add_open_sky_cell(changes_a, Vector3i(112, 1, 0))
	grid.bulk_write(changes_a)

	# Room B, tick 19 -- one tick EARLIER than the cooldown boundary -> quiet.
	# Because this is a QUIET emission, it must NOT re-arm the cooldown.
	for _i: int in range(19):
		mock_tick.fire_tick()
	var changes_b: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_b, Vector3i(120, 1, 0))
	_add_interior_cell(changes_b, Vector3i(121, 1, 0))
	_add_open_sky_cell(changes_b, Vector3i(122, 1, 0))
	grid.bulk_write(changes_b)

	# Room C, tick 20 -- EXACTLY the cooldown boundary measured from Room A's
	# own fired celebration (tick 0), not from Room B's quiet one -> celebrates.
	mock_tick.fire_tick()
	var changes_c: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_c, Vector3i(130, 1, 0))
	_add_interior_cell(changes_c, Vector3i(131, 1, 0))
	_add_open_sky_cell(changes_c, Vector3i(132, 1, 0))
	grid.bulk_write(changes_c)

	assert_int(captured.size()).is_equal(3)
	assert_bool(captured[0]["celebrate"]).is_true()
	assert_bool(captured[1]["celebrate"]).is_false()
	assert_bool(captured[2]["celebrate"]).is_true()


func test_cooldown_zero_always_celebrates() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var bv: BuildValidation = auto_free(BuildValidation.new())
	bv.config = BuildValidationConfig.new()
	bv.config.room_cue_cooldown_ticks = 0
	bv.voxel_world = grid
	bv.time_tick_system = mock_tick
	bv.setup()
	var captured: Array = []
	_record_room_recognized(bv, captured)

	var changes_a: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_a, Vector3i(140, 1, 0))
	_add_interior_cell(changes_a, Vector3i(141, 1, 0))
	_add_open_sky_cell(changes_a, Vector3i(142, 1, 0))
	grid.bulk_write(changes_a)

	# A second, separate room, SAME tick (no tick advance at all).
	var changes_b: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_b, Vector3i(150, 1, 0))
	_add_interior_cell(changes_b, Vector3i(151, 1, 0))
	_add_open_sky_cell(changes_b, Vector3i(152, 1, 0))
	grid.bulk_write(changes_b)

	assert_int(captured.size()).is_equal(2)
	assert_bool(captured[0]["celebrate"]).is_true()
	assert_bool(captured[1]["celebrate"]).is_true()


# ---------------------------------------------------------------------------
# Edge case — Room -> Sealed -> Room refires on the second transition
# ---------------------------------------------------------------------------

func test_room_sealed_then_reopened_refires() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)

	var interior_cell := Vector3i(160, 1, 0)
	var companion_cell := Vector3i(161, 1, 0)
	var escape_cell := Vector3i(162, 1, 0)
	var changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes, interior_cell)
	_add_interior_cell(changes, companion_cell)
	_add_open_sky_cell(changes, escape_cell)
	grid.bulk_write(changes)
	assert_int(bv.get_region_status(interior_cell)).is_equal(BuildValidationReachability.Verdict.ROOM)

	var captured: Array = []
	_record_room_recognized(bv, captured)

	# Act — seal the room by roofing OVER the escape cell (never solidifying
	# the escape cell's own body -- the RECURRING FIXTURE TRAP: a solid block
	# there creates a legal step-up standing surface ON TOP of it, one cell
	# higher and un-roofed, which is itself open sky and silently reopens the
	# very escape being sealed). Roofing escape_cell instead makes it a
	# genuine THIRD interior cell (still standable, now roofed, cell body
	# still empty) -- the whole thing becomes one Sealed 3-cell region, no
	# artificial escape. Bundled with a harmless same-content re-write of
	# interior_cell's own floor so this pass's affected-region seeding
	# directly includes a region member regardless of escape_cell's own
	# candidacy change (mirrors the re-analysis test's own established
	# no-op-rewrite trick) -- this is what actually reseeds {160,161}, not
	# reliance on escape_cell's neighbor-of-neighbor placement.
	grid.bulk_write({
		escape_cell + Vector3i(0, MAX_ROOM_HEIGHT, 0): _solid_contents(),
		interior_cell + Vector3i(0, -1, 0): _solid_contents(),
	})
	assert_int(bv.get_region_status(interior_cell)).is_equal(BuildValidationReachability.Verdict.SEALED)
	assert_int(captured.size()).is_equal(0)  # sealing is never a room_recognized-eligible verdict.

	# Act — reopen it (remove escape_cell's roof; same reseeding bundle).
	grid.bulk_write({
		escape_cell + Vector3i(0, MAX_ROOM_HEIGHT, 0): _empty_contents(),
		interior_cell + Vector3i(0, -1, 0): _solid_contents(),
	})

	assert_int(bv.get_region_status(interior_cell)).is_equal(BuildValidationReachability.Verdict.ROOM)
	assert_int(captured.size()).is_equal(1)  # no interior cell was ROOM in the immediately-previous (SEALED) snapshot.


# ---------------------------------------------------------------------------
# Edge case — a pass recognizing zero rooms emits nothing
# ---------------------------------------------------------------------------

func test_pass_recognizing_zero_rooms_emits_nothing() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)
	var captured: Array = []
	_record_room_recognized(bv, captured)

	# A lone decorative block, isolated -- its own neighbourhood contains no
	# candidate cell at all (form_affected_regions resolves to zero regions).
	grid.bulk_write({Vector3i(200, 0, 200): _solid_contents()})

	assert_int(bv.get_analysis_pass_count()).is_equal(1)  # a pass DID run...
	assert_int(captured.size()).is_equal(0)  # ...but recognized zero rooms.


# ---------------------------------------------------------------------------
# The load pass never emits room_recognized and never arms the cooldown
# ---------------------------------------------------------------------------

func test_load_pass_never_emits_room_recognized_and_never_arms_cooldown() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	# Build a valid room DIRECTLY on the grid before bv even exists.
	var changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes, Vector3i(210, 1, 0))
	_add_interior_cell(changes, Vector3i(211, 1, 0))
	_add_open_sky_cell(changes, Vector3i(212, 1, 0))
	grid.bulk_write(changes)

	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var bv: BuildValidation = _make_bv(grid, mock_tick)  # subscribes only from now on.
	var captured: Array = []
	_record_room_recognized(bv, captured)

	# Act — the load pass.
	bv.run_load_pass()

	assert_int(bv.get_region_status(Vector3i(210, 1, 0))).is_equal(BuildValidationReachability.Verdict.ROOM)
	assert_int(captured.size()).is_equal(0)  # silent seeding -- Rule 11/AC31.

	# Act — advance well past the default cooldown, then recognize a genuinely
	# NEW, separate region live. If the load pass had (incorrectly) armed the
	# cooldown, this would still celebrate regardless (elapsed > cooldown) --
	# so instead prove the STRONGER claim: it celebrates even with ZERO ticks
	# advanced, which only holds if the load pass left the "never armed"
	# sentinel (-1) untouched.
	var changes_live: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_live, Vector3i(220, 1, 0))
	_add_interior_cell(changes_live, Vector3i(221, 1, 0))
	_add_open_sky_cell(changes_live, Vector3i(222, 1, 0))
	grid.bulk_write(changes_live)

	assert_int(captured.size()).is_equal(1)
	assert_bool(captured[0]["celebrate"]).is_true()
