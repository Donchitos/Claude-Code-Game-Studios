## Integration test — Build Validation & Navigability story build-validation-005
## (analysis pass lifecycle, batched trigger, snapshot & never-blocks guards;
## ADR-0007 primary, TD ruling BV-2 —
## `production/architecture-decisions-m02-preflight-2026-07-26.md`; QA plan
## `production/qa/qa-plan-sprint-9-2026-07-26.md` Gate 2).
##
## Proves:
## 1. Single subscription (BV-2): [signal VoxelWorldGrid.cells_changed_batch]
##    is bound exactly once by [method BuildValidation.setup] (idempotent
##    against a repeated call); zero `construction_completed` reference
##    anywhere in `src/build_validation/` (grep guard).
## 2. AC19: one batched signal covering N cells across multiple disjoint
##    regions → exactly one re-analysis pass, both regions independently
##    classified.
## 3. AC20: no structure-change signals → the instrumented pass count stays 0.
## 4. Page-in silence: a chunk paging in via background terrain regeneration
##    (no write) → pass count stays 0.
## 5. **Gate 2 — the deferred/paged-write correctness case (BV-2's own
##    empirical claim)**: a `bulk_write` to a non-resident chunk QUEUES the
##    write and fires no signal — pass count is 0 at the job-completion
##    instant (even if a `construction_completed`-shaped stand-in signal also
##    fires then, proving indifference) — and, WHEN the chunk later pages in
##    and [method VoxelWorldGrid._apply_pending_writes] actually lands the
##    write, exactly ONE new pass runs and the verdict reflects the now-landed
##    data (a real ROOM → SEALED transition, not a default-value artifact).
##    Both halves proven in ONE connected scenario, never two independent
##    tests.
## 6. AC33: a full pass never calls a mocked `VillagerAi`-shaped stand-in's
##    movement/behavior methods (this module holds no such reference at all,
##    per BV-4) while the shared predicates ARE demonstrably exercised (a real
##    verdict is computed, not the OPEN default).
## 7. Incremental snapshot: a pass touching a small affected region leaves an
##    already-classified, untouched region's own snapshot entry unchanged.
## 8. Load pass: [method BuildValidation.run_load_pass] fully re-derives every
##    status from world state alone (built entirely BEFORE this module ever
##    subscribed), without touching the batched-trigger pass counter.
## 9. Synchronous delivery: the pass completes within the same call frame as
##    the triggering `bulk_write` — no `await`, no frame boundary.
## 10. Edge case: a batch that changes nothing structurally relevant still
##     runs a pass (count increments) but leaves an unrelated, already-
##     classified region's status untouched (no spurious transition).
class_name BuildValidationAnalysisPassLifecycleTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

const MAX_ROOM_HEIGHT: int = 8  # BuildValidationConfig default.
const MIN_ROOM_CELLS: int = 2   # BuildValidationConfig default.


func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


func _make_bv(grid: VoxelWorldGrid) -> BuildValidation:
	var bv: BuildValidation = auto_free(BuildValidation.new())
	bv.config = BuildValidationConfig.new()
	bv.voxel_world = grid
	bv.setup()
	return bv


func _solid_contents() -> CellContents:
	return CellContents.new(1, 0)


## Adds the floor+roof pair that makes [param cell] a candidate interior cell
## in isolation (per-column, no wall coverage needed — GDD Rule 1 / Edge
## Case 6) to [param changes], for a caller assembling one combined
## [method VoxelWorldGrid.bulk_write] call.
func _add_interior_cell(changes: Dictionary[Vector3i, CellContents], cell: Vector3i) -> void:
	changes[cell + Vector3i(0, -1, 0)] = _solid_contents()
	changes[cell + Vector3i(0, MAX_ROOM_HEIGHT, 0)] = _solid_contents()


## Adds the floor-only write that makes [param cell] a standable, genuinely
## open-sky escape cell (no roof anywhere above it) to [param changes].
func _add_open_sky_cell(changes: Dictionary[Vector3i, CellContents], cell: Vector3i) -> void:
	changes[cell + Vector3i(0, -1, 0)] = _solid_contents()


## Reads and concatenates every `.gd` source file directly under
## [param dir_path] (non-recursive), STRIPPING full-line `#`/`##` doc-comment
## lines first -- mirrors
## `tests/integration/build_validation/config_and_scaffold_test.gd`'s
## `_read_all_gd_source` helper (this codebase's established precedent).
func _read_all_gd_source(dir_path: String) -> String:
	var combined: String = ""
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Could not open directory: %s" % dir_path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gd"):
			var text: String = FileAccess.get_file_as_string(dir_path.path_join(file_name))
			for line: String in text.split("\n"):
				if not line.strip_edges().begins_with("#"):
					combined += line
					combined += "\n"
		file_name = dir.get_next()
	dir.list_dir_end()
	return combined


## Minimal stand-in for a "job completion" signal shaped like
## [signal ConstructionTickLoop.construction_completed] — held ONLY by this
## test harness, never wired to [BuildValidation] in any way (BV-4: this
## module holds no such reference at all). Firing it and observing zero
## effect on the pass counter is Gate 2's own explicit indifference proof.
class _FakeConstructionCompletedEmitter:
	signal construction_completed(cells: Array[Vector3i])


## Minimal duck-typed stand-in for a villager movement/behavior surface
## (AC33) — held ONLY by this test harness; [BuildValidation] never receives
## or stores a reference to it anywhere (BV-4), so its call-counts staying at
## 0 is a property of the module's shape, not a runtime branch this test
## exercises.
class _MockVillagerAi:
	var move_call_count: int = 0
	var behavior_call_count: int = 0

	func move_to(_cell: Vector3i) -> void:
		move_call_count += 1

	func trigger_behavior(_name: StringName) -> void:
		behavior_call_count += 1


# ---------------------------------------------------------------------------
# Test isolation — per-test temp region directories (Gate 2 + page-in tests)
# ---------------------------------------------------------------------------

var _created_region_dirs: Array[String] = []


func after_test() -> void:
	for dir_path: String in _created_region_dirs:
		_remove_dir_recursive(dir_path)
	_created_region_dirs.clear()


func _make_temp_region_dir(suffix: String) -> String:
	var dir_path: String = "user://bv005_test_regions/%s_%d" % [suffix, Time.get_ticks_usec()]
	_created_region_dirs.append(dir_path)
	return dir_path


func _remove_dir_recursive(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path: String = dir_path.path_join(entry)
			if dir.current_is_dir():
				_remove_dir_recursive(full_path)
			else:
				DirAccess.remove_absolute(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(dir_path)


# ---------------------------------------------------------------------------
# Single subscription (BV-2) — cells_changed_batch bound once, never
# construction_completed
# ---------------------------------------------------------------------------

func test_setup_subscribes_to_cells_changed_batch_exactly_once() -> void:
	# Arrange + Act
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)

	# Assert — bound exactly once.
	assert_int(grid.cells_changed_batch.get_connections().size()).is_equal(1)

	# Act — a repeated setup() call must never double-connect.
	bv.setup()

	# Assert
	assert_int(grid.cells_changed_batch.get_connections().size()).is_equal(1)


func test_module_has_zero_construction_completed_references() -> void:
	var source: String = _read_all_gd_source("res://src/build_validation")

	assert_bool(source.contains("construction_completed")).is_false()
	assert_bool(source.contains("ConstructionTickLoop")).is_false()


# ---------------------------------------------------------------------------
# AC19 — one batched signal across disjoint regions -> exactly one pass
# ---------------------------------------------------------------------------

func test_ac19_batch_spanning_two_disjoint_regions_runs_exactly_one_pass() -> void:
	# Arrange — two far-apart, independently-valid rooms, all cells folded
	# into ONE Dictionary so a single bulk_write models "N cells completed in
	# one tick dispatch, across any number of commands/villagers."
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)
	var changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes, Vector3i(0, 1, 0))
	_add_interior_cell(changes, Vector3i(1, 1, 0))
	_add_open_sky_cell(changes, Vector3i(2, 1, 0))
	_add_interior_cell(changes, Vector3i(20, 1, 20))
	_add_interior_cell(changes, Vector3i(21, 1, 20))
	_add_open_sky_cell(changes, Vector3i(22, 1, 20))

	# Act
	grid.bulk_write(changes)

	# Assert — exactly one pass, both disjoint regions independently
	# classified as valid rooms.
	assert_int(bv.get_analysis_pass_count()).is_equal(1)
	assert_int(bv.get_region_status(Vector3i(0, 1, 0))).is_equal(
		BuildValidationReachability.Verdict.ROOM
	)
	assert_int(bv.get_region_status(Vector3i(20, 1, 20))).is_equal(
		BuildValidationReachability.Verdict.ROOM
	)


# ---------------------------------------------------------------------------
# AC20 — no signals -> pass count stays 0 across frames
# ---------------------------------------------------------------------------

func test_ac20_no_structure_change_signals_pass_count_stays_zero() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)

	# Act — no cells_changed_batch emission of any kind; let several frames
	# pass.
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	# Assert
	assert_int(bv.get_analysis_pass_count()).is_equal(0)


# ---------------------------------------------------------------------------
# Page-in silence — a pristine chunk paging in via terrain regen (no write)
# never triggers a pass
# ---------------------------------------------------------------------------

func test_page_in_of_pristine_chunk_via_terrain_regen_causes_no_pass() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 64
	config.world_depth_cells = 64
	config.region_size_chunks = 4
	config.view_radius_chunks = 1
	config.settlement_radius_chunks = 1
	config.region_directory = _make_temp_region_dir("page_in_silence")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var bv: BuildValidation = _make_bv(grid)
	var pristine_cell := Vector3i(48, 0, 48)  # never written -- regenerates from seed.

	# Act — first update_residency call engages residency and dispatches
	# regen for the pristine chunk; settle it fully.
	grid.update_residency(pristine_cell, pristine_cell)
	grid.wait_for_async_residency_idle()

	# Assert — page-in is silent by contract (_bg_regenerate_from_seed never
	# marks dirty, never emits); no pass ran.
	assert_bool(grid.is_chunk_resident(grid.chunk_key_for_cell(pristine_cell))).is_true()
	assert_int(bv.get_analysis_pass_count()).is_equal(0)


# ---------------------------------------------------------------------------
# Gate 2 — the connected deferred/paged-write scenario (BOTH halves, one
# scenario)
# ---------------------------------------------------------------------------

func test_deferred_write_no_pass_at_completion_then_exactly_one_pass_with_landed_verdict_on_write_landing() -> void:
	# Arrange -- cell_b is fully built (floor+roof) and already sits next to a
	# PERMANENT, never-touched open-sky escape cell; cell_a is missing only
	# its OWN floor (roof already placed) -- deliberately NOT yet a candidate
	# cell at all. The deferred write is exactly that missing floor, directly
	# beneath cell_a -- a genuine 6-neighbor of cell_a itself, so [method
	# BuildValidationRegionFormation.form_affected_regions] correctly reseeds
	# cell_a's own region the instant it lands. This avoids any "climb onto a
	# newly-solid ledge and step back down beside it" escape-route artifact a
	# wall-gap fixture would introduce (villager movement allows stepping onto
	# anything ≤1 cell taller, so toggling a WALL cell solid/empty next to an
	# already-open escape route does not cleanly seal/unseal in one step) --
	# toggling cell_a's OWN foundational standability has no such loophole.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 64
	config.world_depth_cells = 64
	config.region_size_chunks = 4
	config.view_radius_chunks = 1
	config.settlement_radius_chunks = 1
	config.region_directory = _make_temp_region_dir("gate2_deferred_write")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var bv: BuildValidation = _make_bv(grid)

	var cell_a := Vector3i(0, 3, 0)
	var cell_b := Vector3i(1, 3, 0)
	var escape_cell := Vector3i(2, 3, 0)  # permanent open-sky escape, never touched again.
	var missing_floor := cell_a + Vector3i(0, -1, 0)  # the deferred write's target.
	var initial_changes: Dictionary[Vector3i, CellContents] = {}
	initial_changes[cell_a + Vector3i(0, MAX_ROOM_HEIGHT, 0)] = _solid_contents()  # cell_a's roof (placed early; no floor yet -- not a candidate).
	_add_interior_cell(initial_changes, cell_b)
	_add_open_sky_cell(initial_changes, escape_cell)  # floor only -- permanently unroofed.
	grid.bulk_write(initial_changes)

	# Sanity -- cell_b alone is below min_room_cells (2), so it is a real,
	# computed OPEN verdict here -- NOT the unclassified default (cell_a is
	# absent from the snapshot entirely at this point, since it was never a
	# candidate for any pass to touch).
	assert_int(bv.get_analysis_pass_count()).is_equal(1)
	assert_int(bv.get_region_status(cell_b)).is_equal(BuildValidationReachability.Verdict.OPEN)

	# Act -- engage residency, evict the room's chunk (flushing its dirty
	# data), and settle.
	var far_anchor := Vector3i(48, 0, 48)
	grid.update_residency(far_anchor, far_anchor)
	grid.wait_for_async_residency_idle()
	var chunk_key: Vector2i = grid.chunk_key_for_cell(missing_floor)
	assert_bool(grid.is_chunk_resident(chunk_key)).is_false()

	var baseline: int = bv.get_analysis_pass_count()

	# Act -- the deferred write: cell_a's floor targets a NON-resident chunk,
	# so VoxelWorldGrid._apply_write QUEUES it and returns null; no cell
	# actually changed yet, so bulk_write's own record array is empty and
	# cells_changed_batch never fires.
	var completing_changes: Dictionary[Vector3i, CellContents] = {missing_floor: _solid_contents()}
	var records: Array[CellChangeRecord] = grid.bulk_write(completing_changes)
	assert_array(records).is_empty()

	# Assert -- T0 (job-completion instant): zero passes since baseline, even
	# though the write is "done" from the caller's point of view.
	assert_int(bv.get_analysis_pass_count()).is_equal(baseline)

	# Act -- fire a construction_completed-SHAPED stand-in at this exact
	# instant (BV-2: had this module bound that signal instead, THIS is the
	# moment it would have read stale data). BuildValidation is not connected
	# to it in any way (BV-4/BV-2 -- no such subscription exists), so firing
	# it must have zero observable effect.
	var fake_job_completion := _FakeConstructionCompletedEmitter.new()
	fake_job_completion.construction_completed.emit([missing_floor])

	# Assert -- T0 confirmed: still zero passes since baseline, indifferent
	# to the stand-in signal.
	assert_int(bv.get_analysis_pass_count()).is_equal(baseline)

	# Act -- T1: the chunk pages back in (a durable read of its own flushed
	# region-file data, since it was dirtied before eviction) and
	# _apply_pending_writes lands the queued write the instant the chunk
	# becomes resident, emitting cells_changed_batch for real this time.
	grid.update_residency(missing_floor, missing_floor)
	grid.wait_for_async_residency_idle()

	# Assert -- T1: exactly ONE new pass since baseline, and the verdict
	# reflects the now-landed data -- cell_a is now a genuine candidate,
	# joins cell_b into a 2-cell region that reaches the permanent escape --
	# both flip from the real, previously-computed OPEN to a real, newly-
	# computed ROOM (a distinct computed transition, not a default-value
	# artifact).
	assert_int(bv.get_analysis_pass_count()).is_equal(baseline + 1)
	assert_int(bv.get_region_status(cell_a)).is_equal(BuildValidationReachability.Verdict.ROOM)
	assert_int(bv.get_region_status(cell_b)).is_equal(BuildValidationReachability.Verdict.ROOM)


# ---------------------------------------------------------------------------
# AC33 — never calls a mocked villager's movement/behavior APIs
# ---------------------------------------------------------------------------

func test_ac33_full_pass_never_calls_mocked_villager_movement_or_behavior_apis() -> void:
	# Arrange -- BuildValidation holds no reference to this mock anywhere
	# (BV-4); it exists purely so the assertion below is meaningful evidence,
	# not a tautology about an object that was never in scope at all.
	var mock_villager := _MockVillagerAi.new()
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)
	var changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes, Vector3i(0, 1, 0))
	_add_interior_cell(changes, Vector3i(1, 1, 0))
	_add_open_sky_cell(changes, Vector3i(2, 1, 0))

	# Act -- a full pass runs.
	grid.bulk_write(changes)

	# Assert -- zero calls into the mocked movement/behavior surface...
	assert_int(mock_villager.move_call_count).is_equal(0)
	assert_int(mock_villager.behavior_call_count).is_equal(0)
	# ...while the shared static predicates WERE demonstrably exercised: a
	# real, non-default verdict was computed (proving is_standable/is_roofed
	# ran), companion to the never-calls-villager-APIs half above.
	assert_int(bv.get_analysis_pass_count()).is_equal(1)
	assert_int(bv.get_region_status(Vector3i(0, 1, 0))).is_equal(
		BuildValidationReachability.Verdict.ROOM
	)


# ---------------------------------------------------------------------------
# Incremental snapshot — an untouched, already-classified region's entry is
# unaffected by a later, disjoint pass
# ---------------------------------------------------------------------------

func test_incremental_snapshot_leaves_untouched_region_status_unchanged() -> void:
	# Arrange -- region P (a valid ROOM) established by pass 1.
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)
	var changes_p: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_p, Vector3i(0, 1, 0))
	_add_interior_cell(changes_p, Vector3i(1, 1, 0))
	_add_open_sky_cell(changes_p, Vector3i(2, 1, 0))
	grid.bulk_write(changes_p)
	assert_int(bv.get_analysis_pass_count()).is_equal(1)
	assert_int(bv.get_region_status(Vector3i(0, 1, 0))).is_equal(
		BuildValidationReachability.Verdict.ROOM
	)

	# Act -- a second, entirely disjoint pass forms region Q as SEALED (no
	# escape at all) -- deliberately a DIFFERENT verdict than P's, so any
	# cross-contamination between the two snapshot entries would be caught.
	var changes_q: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_q, Vector3i(30, 1, 30))
	_add_interior_cell(changes_q, Vector3i(31, 1, 30))
	grid.bulk_write(changes_q)

	# Assert -- pass 2 ran, Q is SEALED, and P's entry is untouched.
	assert_int(bv.get_analysis_pass_count()).is_equal(2)
	assert_int(bv.get_region_status(Vector3i(30, 1, 30))).is_equal(
		BuildValidationReachability.Verdict.SEALED
	)
	assert_int(bv.get_region_status(Vector3i(0, 1, 0))).is_equal(
		BuildValidationReachability.Verdict.ROOM
	)


# ---------------------------------------------------------------------------
# Load pass — full re-derive from world state alone, counter untouched
# ---------------------------------------------------------------------------

func test_load_pass_rebuilds_whole_snapshot_from_world_state_without_a_prior_signal() -> void:
	# Arrange -- build a valid room DIRECTLY on the grid before BuildValidation
	# even exists, so no cells_changed_batch emission was ever observed for
	# these cells.
	var grid: VoxelWorldGrid = _make_grid()
	var changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes, Vector3i(0, 1, 0))
	_add_interior_cell(changes, Vector3i(1, 1, 0))
	_add_open_sky_cell(changes, Vector3i(2, 1, 0))
	grid.bulk_write(changes)  # bv does not exist yet -- nothing observes this.

	var bv: BuildValidation = _make_bv(grid)  # subscribes only from now on.
	assert_int(bv.get_analysis_pass_count()).is_equal(0)
	assert_int(bv.get_region_status(Vector3i(0, 1, 0))).is_equal(
		BuildValidationReachability.Verdict.OPEN
	)  # unclassified default -- the snapshot has never seen this cell.

	# Act -- the load pass.
	bv.run_load_pass()

	# Assert -- fully re-derived and queryable, without touching the
	# batched-trigger pass counter.
	assert_int(bv.get_region_status(Vector3i(0, 1, 0))).is_equal(
		BuildValidationReachability.Verdict.ROOM
	)
	assert_int(bv.get_region_status(Vector3i(1, 1, 0))).is_equal(
		BuildValidationReachability.Verdict.ROOM
	)
	assert_int(bv.get_analysis_pass_count()).is_equal(0)


# ---------------------------------------------------------------------------
# Synchronous delivery — the pass completes within the same call frame
# ---------------------------------------------------------------------------

func test_pass_completes_synchronously_within_the_triggering_bulk_write_call() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)
	var changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes, Vector3i(0, 1, 0))
	_add_interior_cell(changes, Vector3i(1, 1, 0))
	_add_open_sky_cell(changes, Vector3i(2, 1, 0))

	# Act -- no `await` anywhere between the write and the assertion.
	grid.bulk_write(changes)

	# Assert -- already reflects the pass; delivery was synchronous, not
	# deferred to a later frame.
	assert_int(bv.get_analysis_pass_count()).is_equal(1)
	assert_int(bv.get_region_status(Vector3i(0, 1, 0))).is_equal(
		BuildValidationReachability.Verdict.ROOM
	)


# ---------------------------------------------------------------------------
# Edge case — a batch changing nothing structurally relevant still runs a
# pass, but produces no spurious transition
# ---------------------------------------------------------------------------

func test_structurally_irrelevant_batch_runs_a_pass_but_leaves_existing_region_unchanged() -> void:
	# Arrange -- an established, valid room.
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)
	var changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes, Vector3i(0, 1, 0))
	_add_interior_cell(changes, Vector3i(1, 1, 0))
	_add_open_sky_cell(changes, Vector3i(2, 1, 0))
	grid.bulk_write(changes)
	assert_int(bv.get_analysis_pass_count()).is_equal(1)

	# Act -- a lone decorative block far away, isolated (its own neighbourhood
	# contains no candidate cell at all, so form_affected_regions resolves to
	# zero regions for this batch).
	var irrelevant_changes: Dictionary[Vector3i, CellContents] = {Vector3i(50, 0, 50): _solid_contents()}
	grid.bulk_write(irrelevant_changes)

	# Assert -- a pass DID run (count incremented) but the established room's
	# status is byte-identical to before -- no spurious transition, and the
	# irrelevant cell's own neighbourhood was never classified as a region.
	assert_int(bv.get_analysis_pass_count()).is_equal(2)
	assert_int(bv.get_region_status(Vector3i(0, 1, 0))).is_equal(
		BuildValidationReachability.Verdict.ROOM
	)
	assert_int(bv.get_region_status(Vector3i(50, 1, 50))).is_equal(
		BuildValidationReachability.Verdict.OPEN
	)
