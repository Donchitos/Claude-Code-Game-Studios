## Integration test — Villager AI story villager-ai-018 (Sleep & home, bed
## claim -- "the move-in moment"; ADR-0008 primary, ADR-0012 secondary).
##
## Proves, against [VillagerAi._tick_deciding]/[VillagerAi._commit_to_sleep]/
## [VillagerAi._attempt_claim_and_travel_to_bed]/[VillagerAi._abandon_travel]/
## [VillagerAi._complete_travel_arrival]/[VillagerAi._tick_sleeping]/
## [VillagerAi._on_furniture_revoked], using real [VoxelWorldGrid]/
## [VillagerNavGraph]/[VillagerBedSelector] and mocked, duck-typed
## [NeedsMood]-shaped/furniture-registry-shaped providers (this story's own
## Engine Notes: "Needs & Mood values are mocked at the need-is-urgent/wake
## boundary"; the bed/furniture source is consumed exclusively through a
## nil-safe duck-typed seam, `building-028`/`016` land the real registry
## concurrently in a different lane):
##
## 1. **AC22**: first urgent sleep + an unowned reachable bed -> the villager
##    claims that bed PERMANENTLY (the move-in moment) and travels to it,
##    arriving Sleeping and reporting `bed_sheltered`/`bed_unsheltered`
##    correctly.
## 2. **AC23/AC44**: an owned reachable bed is ALWAYS preferred, even over a
##    strictly closer unowned free bed -- the unowned candidate is never even
##    attempted.
## 3. **AC24**: no reachable bed -> ground sleep at the current cell,
##    reporting `ground_no_bed_owned` (owns no bed) or
##    `ground_bed_unreachable` (owns one it cannot reach).
## 4. **AC25**: the need restored above the wake threshold (mocked) -> wakes
##    and re-enters Deciding.
## 5. **AC26**: a bed removed while the villager sleeps in it -> wakes
##    immediately, ownership dissolves, `stop_recovery` is called crediting
##    zero recovery for the removal tick.
## 6. **AC27**: an owned-but-UNOCCUPIED bed removed -> ownership dissolves
##    SILENTLY -- no wake reaction, no `stop_recovery` call.
##
## NOTE (accumulated pitfall): private `_`-prefixed fields
## (`_has_owned_bed`/`_owned_bed_cell`/`_pursued_activity`/`_state`) are
## poked directly in several tests below -- an established convention in
## this codebase's own test suite (see `traveling_repath_test.gd`'s own
## direct `_from_cell`/`_to_cell` pokes, `unstuck_watchdog_test.gd`'s own
## `_pursued_activity`/`_state` pokes).
class_name SleepAndHomeTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test doubles
# ---------------------------------------------------------------------------

## One recorded [method VillagerAi._start_sleep_recovery] call.
class RecoveryStartCall:
	var villager_id: int
	var need: StringName
	var source_enum: int

	func _init(p_villager_id: int, p_need: StringName, p_source_enum: int) -> void:
		villager_id = p_villager_id
		need = p_need
		source_enum = p_source_enum


## One recorded [method VillagerAi._stop_sleep_recovery] call.
class RecoveryStopCall:
	var villager_id: int
	var need: StringName
	var reason: StringName

	func _init(p_villager_id: int, p_need: StringName, p_reason: StringName) -> void:
		villager_id = p_villager_id
		need = p_need
		reason = p_reason


## A [NeedsMood]-shaped test double (mocked boundary -- this story's own
## Engine Notes). `urgent`/`recovering` are independently test-controlled
## flags (mirroring the real module's own SATISFIED/URGENT/RECOVERING
## three-state split, TR-needs-mood-system-032/048) -- `has_urgent_need`
## answers `urgent` only (never `true` while merely `recovering`, exactly
## the real module's own behavior this story's `_tick_deciding` fix depends
## on), and `get_need_state` answers `RECOVERING` iff `recovering`, else
## `SATISFIED`.
class MockNeedsProvider:
	var urgent: bool = false
	var recovering: bool = false
	var start_recovery_calls: Array[RecoveryStartCall] = []
	var stop_recovery_calls: Array[RecoveryStopCall] = []

	func has_urgent_need(_villager_id: int) -> bool:
		return urgent

	func start_recovery(villager_id: int, need: StringName, source_enum: NeedsMood.RecoverySource) -> void:
		start_recovery_calls.append(RecoveryStartCall.new(villager_id, need, source_enum))

	func stop_recovery(villager_id: int, need: StringName, reason: StringName) -> void:
		stop_recovery_calls.append(RecoveryStopCall.new(villager_id, need, reason))

	func get_need_state(_villager_id: int, _need: StringName) -> NeedsMood.NeedState:
		return NeedsMood.NeedState.RECOVERING if recovering else NeedsMood.NeedState.SATISFIED


## A furniture-registry-shaped test double (mocked boundary -- Building
## System's `building-028`/`016` land the real registry CONCURRENTLY in a
## different lane; this story consumes it exclusively through this seam,
## never waiting on or editing those files). `unowned_cells` is the
## candidate pool; `sheltered_cells` names which of them Build Validation
## would classify as sheltered (GDD Core Rule 4's `bed_sheltered`/
## `bed_unsheltered` split). Atomicity mirrors [ConstructionJobQueue.claim_job]
## exactly (Story villager-ai-011's own shared PATTERN, AC43): first caller
## for a given cell wins, everyone else loses.
class MockBedProvider:
	signal furniture_revoked(villager_id: int, furniture_cell: Vector3i)

	var unowned_cells: Array[Vector3i] = []
	var sheltered_cells: Array[Vector3i] = []
	var claim_bed_call_count: int = 0
	var _claimed_by: Dictionary[Vector3i, int] = {}

	func get_unowned_bed_cells() -> Array[Vector3i]:
		var result: Array[Vector3i] = []
		for cell: Vector3i in unowned_cells:
			if not _claimed_by.has(cell):
				result.append(cell)
		return result

	func claim_bed(cell: Vector3i, villager_id: int) -> bool:
		claim_bed_call_count += 1
		if _claimed_by.has(cell):
			return false
		_claimed_by[cell] = villager_id
		return true

	func is_bed_sheltered(cell: Vector3i) -> bool:
		return sheltered_cells.has(cell)

	## Test-side trigger for the furniture-revocation event (GDD Edge Case
	## 5/6) -- mirrors the real Building System's own targeted, per-owner
	## broadcast (`docs/architecture/architecture.md`'s signal table).
	func revoke(villager_id: int, cell: Vector3i) -> void:
		furniture_revoked.emit(villager_id, cell)


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


func _solid() -> CellContents:
	return CellContents.new(1, 0)


## A flat, fully-connected 5x5 standable platform (mirrors
## `job_claim_attribution_test.gd`/`traveling_repath_test.gd`'s own
## established fixture).
func _make_flat_platform_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = _make_grid()
	for x in range(5):
		for z in range(5):
			grid.set_cell(Vector3i(x, 0, z), _solid())
	return grid


## Two isolated 1-cell standable columns with nothing standable between them
## -- `find_path` returns empty by construction (mirrors
## `traveling_repath_test.gd`'s own `_make_disconnected_islands_grid`).
func _make_disconnected_islands_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(0, 0, 0), _solid())
	grid.set_cell(Vector3i(4, 0, 4), _solid())
	return grid


func _make_bare_villager_ai(grid: VoxelWorldGrid) -> VillagerAi:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.voxel_world = grid
	return villager_ai


func _place_villager(villager: VillagerAi, cell: Vector3i) -> void:
	villager.current_cell = cell
	villager._from_cell = cell
	villager._to_cell = cell


## A villager wired for direct `_tick_deciding()` exercise (config/
## voxel_world/scheduler/nav_graph), deliberately WITHOUT calling [method
## VillagerAi.setup] -- these tests drive the Deciding pass directly, no
## live signal wiring needed (mirrors `job_claim_attribution_test.gd`'s own
## `_make_deciding_villager`).
func _make_deciding_villager(grid: VoxelWorldGrid, nav_graph: VillagerNavGraph, villager_id: int = 0) -> VillagerAi:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.config = VillagerAIConfig.new()
	villager_ai.voxel_world = grid
	villager_ai.scheduler = VillagerDecidingScheduler.new()
	villager_ai.nav_graph = nav_graph
	villager_ai.villager_id = villager_id
	return villager_ai


## A fully [method VillagerAi.setup]-ed villager -- needed only by the
## furniture-revocation tests (AC26/AC27), since that signal connection
## happens inside [method VillagerAi.setup].
func _make_setup_villager(
	grid: VoxelWorldGrid, nav_graph: VillagerNavGraph, needs: MockNeedsProvider, beds: MockBedProvider
) -> VillagerAi:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.config = VillagerAIConfig.new()
	villager_ai.voxel_world = grid
	villager_ai.scheduler = VillagerDecidingScheduler.new()
	villager_ai.nav_graph = nav_graph
	villager_ai.needs_provider = needs
	villager_ai.bed_provider = beds
	villager_ai.time_tick_system = auto_free(MockTimeTickSystem.new())
	villager_ai.setup()
	return villager_ai


## Drives Traveling to completion (or any other terminal transition) via
## repeated tick-boundary crossings, mirroring
## `traveling_repath_test.gd`'s own `_drive_one_step` -- a deliberately huge
## `game_delta` forces each step's progress to `1.0` regardless of length.
func _drive_until_not_traveling(villager: VillagerAi, max_steps: int = 20) -> void:
	var steps: int = 0
	while villager.get_state() == VillagerAi.State.TRAVELING and steps < max_steps:
		villager.advance_travel_progress(1000.0)
		villager._on_tick()
		steps += 1


# ---------------------------------------------------------------------------
# AC22 -- first urgent sleep + unowned reachable bed: claims permanently
# ---------------------------------------------------------------------------

func test_first_urgent_sleep_claims_unowned_reachable_bed_and_arrives_sleeping_sheltered() -> void:
	var grid: VoxelWorldGrid = _make_flat_platform_grid()
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)
	var villager: VillagerAi = _make_deciding_villager(grid, graph)
	_place_villager(villager, Vector3i(0, 1, 0))
	var needs := MockNeedsProvider.new()
	needs.urgent = true
	var beds := MockBedProvider.new()
	var bed_cell := Vector3i(4, 1, 0)
	beds.unowned_cells = [bed_cell]
	beds.sheltered_cells = [bed_cell]
	villager.needs_provider = needs
	villager.bed_provider = beds

	villager._tick_deciding()

	# The move-in moment: claimed permanently, traveling toward it.
	assert_int(beds.claim_bed_call_count).is_equal(1)
	assert_bool(villager.has_owned_bed()).is_true()
	assert_vector(Vector3(villager.get_owned_bed_cell())).is_equal(Vector3(bed_cell))
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NEED)
	assert_int(villager.get_state()).is_equal(VillagerAi.State.TRAVELING)

	_drive_until_not_traveling(villager)

	assert_int(villager.get_state()).is_equal(VillagerAi.State.SLEEPING)
	assert_int(needs.start_recovery_calls.size()).is_equal(1)
	var recorded: RecoveryStartCall = needs.start_recovery_calls[0]
	assert_int(recorded.villager_id).is_equal(villager.villager_id)
	assert_str(recorded.need).is_equal(VillagerAi.SLEEP_NEED_NAME)
	assert_int(recorded.source_enum).is_equal(NeedsMood.RecoverySource.BED_SHELTERED)
	# Ownership persists -- claiming a bed IS the move-in moment (Rule 11).
	assert_bool(villager.has_owned_bed()).is_true()


func test_claimed_bed_reports_unsheltered_when_build_validation_says_so() -> void:
	var grid: VoxelWorldGrid = _make_flat_platform_grid()
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)
	var villager: VillagerAi = _make_deciding_villager(grid, graph)
	_place_villager(villager, Vector3i(0, 1, 0))
	var needs := MockNeedsProvider.new()
	needs.urgent = true
	var beds := MockBedProvider.new()
	var bed_cell := Vector3i(4, 1, 0)
	beds.unowned_cells = [bed_cell]
	# sheltered_cells deliberately left empty -- unsheltered.
	villager.needs_provider = needs
	villager.bed_provider = beds

	villager._tick_deciding()
	_drive_until_not_traveling(villager)

	assert_int(villager.get_state()).is_equal(VillagerAi.State.SLEEPING)
	var recorded: RecoveryStartCall = needs.start_recovery_calls[0]
	assert_int(recorded.source_enum).is_equal(NeedsMood.RecoverySource.BED_UNSHELTERED)


# ---------------------------------------------------------------------------
# AC23/AC44 -- owned reachable bed is ALWAYS preferred over a closer unowned
# ---------------------------------------------------------------------------

func test_owned_reachable_bed_preferred_over_closer_unowned_bed() -> void:
	var grid: VoxelWorldGrid = _make_flat_platform_grid()
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)
	var villager: VillagerAi = _make_deciding_villager(grid, graph)
	_place_villager(villager, Vector3i(0, 1, 0))
	var owned_bed_cell := Vector3i(4, 1, 4)  # farther
	var closer_unowned_cell := Vector3i(1, 1, 0)  # strictly closer
	villager._has_owned_bed = true
	villager._owned_bed_cell = owned_bed_cell
	var needs := MockNeedsProvider.new()
	needs.urgent = true
	var beds := MockBedProvider.new()
	beds.unowned_cells = [closer_unowned_cell]
	villager.needs_provider = needs
	villager.bed_provider = beds

	villager._tick_deciding()

	# Never even attempted the closer, unowned bed.
	assert_int(beds.claim_bed_call_count).is_equal(0)
	assert_int(villager.get_state()).is_equal(VillagerAi.State.TRAVELING)
	assert_vector(Vector3(villager._travel_target_cell)).is_equal(Vector3(owned_bed_cell))
	assert_vector(Vector3(villager.get_owned_bed_cell())).is_equal(Vector3(owned_bed_cell))


# ---------------------------------------------------------------------------
# AC24 -- no reachable bed: ground sleep, correct widened source enum
# ---------------------------------------------------------------------------

func test_no_bed_owned_and_none_claimable_sleeps_on_ground_reporting_no_bed_owned() -> void:
	var grid: VoxelWorldGrid = _make_flat_platform_grid()
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)
	var villager: VillagerAi = _make_deciding_villager(grid, graph)
	_place_villager(villager, Vector3i(0, 1, 0))
	var needs := MockNeedsProvider.new()
	needs.urgent = true
	villager.needs_provider = needs
	# bed_provider deliberately left unwired -- nil-safe: no candidates at all.

	villager._tick_deciding()

	assert_int(villager.get_state()).is_equal(VillagerAi.State.SLEEPING)
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NEED)
	assert_bool(villager.has_owned_bed()).is_false()
	assert_int(needs.start_recovery_calls.size()).is_equal(1)
	assert_int(needs.start_recovery_calls[0].source_enum).is_equal(NeedsMood.RecoverySource.GROUND_NO_BED_OWNED)


func test_owned_but_unreachable_bed_sleeps_on_ground_reporting_bed_unreachable() -> void:
	var grid: VoxelWorldGrid = _make_disconnected_islands_grid()
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)
	var villager: VillagerAi = _make_deciding_villager(grid, graph)
	_place_villager(villager, Vector3i(0, 1, 0))
	villager._has_owned_bed = true
	villager._owned_bed_cell = Vector3i(4, 1, 4)  # the OTHER island -- unreachable
	var needs := MockNeedsProvider.new()
	needs.urgent = true
	villager.needs_provider = needs

	villager._tick_deciding()

	assert_int(villager.get_state()).is_equal(VillagerAi.State.SLEEPING)
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NEED)
	# Ownership is UNAFFECTED by unreachability -- only removal dissolves it.
	assert_bool(villager.has_owned_bed()).is_true()
	assert_int(needs.start_recovery_calls.size()).is_equal(1)
	assert_int(needs.start_recovery_calls[0].source_enum).is_equal(NeedsMood.RecoverySource.GROUND_BED_UNREACHABLE)


# ---------------------------------------------------------------------------
# AC25 -- wake threshold reached (mocked): wakes, re-enters Deciding
# ---------------------------------------------------------------------------

func test_sleeping_villager_wakes_and_redecides_once_no_longer_recovering() -> void:
	var grid: VoxelWorldGrid = _make_flat_platform_grid()
	var villager: VillagerAi = _make_deciding_villager(grid, VillagerNavGraph.new())
	_place_villager(villager, Vector3i(0, 1, 0))
	var needs := MockNeedsProvider.new()
	needs.recovering = true
	villager.needs_provider = needs
	villager._pursued_activity = VillagerAi.PursuedActivity.NEED
	villager._state = VillagerAi.State.SLEEPING

	# Still recovering -- stays asleep.
	villager._tick_sleeping()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.SLEEPING)

	# Restored above the wake threshold (mocked) -- wakes.
	needs.recovering = false
	villager._tick_sleeping()

	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NONE)
	# Natural wake never reports an interruption (GDD Core Rule 10 reserves
	# `stop_recovery` for revocation/interruption, never natural completion --
	# NeedsMood's own F2 pass already transitioned Recovering -> Satisfied).
	assert_int(needs.stop_recovery_calls.size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC26 -- bed removed while sleeping in it: wakes immediately, dissolves
# ---------------------------------------------------------------------------

func test_bed_removed_while_sleeping_in_it_wakes_immediately_and_dissolves_ownership() -> void:
	var grid: VoxelWorldGrid = _make_flat_platform_grid()
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)
	var needs := MockNeedsProvider.new()
	needs.urgent = true
	var beds := MockBedProvider.new()
	var bed_cell := Vector3i(4, 1, 0)
	beds.unowned_cells = [bed_cell]
	beds.sheltered_cells = [bed_cell]
	var villager: VillagerAi = _make_setup_villager(grid, graph, needs, beds)
	_place_villager(villager, Vector3i(0, 1, 0))

	villager._tick_deciding()
	_drive_until_not_traveling(villager)
	assert_int(villager.get_state()).is_equal(VillagerAi.State.SLEEPING)
	assert_bool(villager.has_owned_bed()).is_true()

	# Act -- the Building System's furniture-revocation event, targeted at
	# this villager, for the bed it is currently sleeping in.
	beds.revoke(villager.villager_id, bed_cell)

	assert_bool(villager.has_owned_bed()).is_false()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NONE)
	assert_int(needs.stop_recovery_calls.size()).is_equal(1)
	var recorded: RecoveryStopCall = needs.stop_recovery_calls[0]
	assert_int(recorded.villager_id).is_equal(villager.villager_id)
	assert_str(recorded.need).is_equal(VillagerAi.SLEEP_NEED_NAME)


# ---------------------------------------------------------------------------
# AC27 -- owned but UNOCCUPIED bed removed: dissolves silently
# ---------------------------------------------------------------------------

func test_owned_unoccupied_bed_removed_dissolves_silently_no_wake_reaction() -> void:
	var grid: VoxelWorldGrid = _make_flat_platform_grid()
	var graph := VillagerNavGraph.new()
	var needs := MockNeedsProvider.new()
	var beds := MockBedProvider.new()
	var bed_cell := Vector3i(4, 1, 0)
	var villager: VillagerAi = _make_setup_villager(grid, graph, needs, beds)
	_place_villager(villager, Vector3i(0, 1, 0))
	# Owns the bed, but is NOT sleeping in it (e.g. off wandering) --
	# Edge Case 6's own scope.
	villager._has_owned_bed = true
	villager._owned_bed_cell = bed_cell
	villager._state = VillagerAi.State.WANDERING
	villager._pursued_activity = VillagerAi.PursuedActivity.NONE

	beds.revoke(villager.villager_id, bed_cell)

	assert_bool(villager.has_owned_bed()).is_false()
	# Silent dissolve -- no wake reaction, no state change, no report.
	assert_int(villager.get_state()).is_equal(VillagerAi.State.WANDERING)
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NONE)
	assert_int(needs.stop_recovery_calls.size()).is_equal(0)


func test_furniture_revoked_for_a_different_villager_id_is_a_noop() -> void:
	var grid: VoxelWorldGrid = _make_flat_platform_grid()
	var graph := VillagerNavGraph.new()
	var needs := MockNeedsProvider.new()
	var beds := MockBedProvider.new()
	var bed_cell := Vector3i(4, 1, 0)
	var villager: VillagerAi = _make_setup_villager(grid, graph, needs, beds)
	villager.villager_id = 0
	_place_villager(villager, Vector3i(0, 1, 0))
	villager._has_owned_bed = true
	villager._owned_bed_cell = bed_cell

	# Targeted at a DIFFERENT villager id -- this villager's own ownership
	# must be completely unaffected.
	beds.revoke(1, bed_cell)

	assert_bool(villager.has_owned_bed()).is_true()
	assert_int(needs.stop_recovery_calls.size()).is_equal(0)


func test_furniture_revoked_for_a_different_cell_is_a_noop() -> void:
	var grid: VoxelWorldGrid = _make_flat_platform_grid()
	var graph := VillagerNavGraph.new()
	var needs := MockNeedsProvider.new()
	var beds := MockBedProvider.new()
	var owned_cell := Vector3i(4, 1, 0)
	var other_cell := Vector3i(3, 1, 0)
	var villager: VillagerAi = _make_setup_villager(grid, graph, needs, beds)
	_place_villager(villager, Vector3i(0, 1, 0))
	villager._has_owned_bed = true
	villager._owned_bed_cell = owned_cell

	beds.revoke(villager.villager_id, other_cell)

	assert_bool(villager.has_owned_bed()).is_true()
	assert_int(needs.stop_recovery_calls.size()).is_equal(0)
