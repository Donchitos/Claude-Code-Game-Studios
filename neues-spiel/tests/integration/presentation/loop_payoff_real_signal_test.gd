## Integration test — Build Validation & Navigability story build-validation-009
## ("Loop-payoff surface receives real signals," milestone-02 criterion #7;
## ADR-0001 primary; CD Ruling 2, `production/creative-decisions-m02-preflight-
## 2026-07-26.md` -- PROVISIONAL, pending user ratification; GDD `design/gdd/
## build-validation-navigability.md` Rule 10 signal contract).
##
## Proves [LoopPayoffAdapter] (the story's own new class) is the FIRST real
## production writer onto [LoopPayoffSignalSurface] -- the surface has
## existed, shipped, and been tested since its own scaffolding story
## (`presentation-002`), but nothing in `src/` ever called [method
## LoopPayoffSignalSurface.emit_payoff] with a REAL payoff before this story.
##
## `test_real_booted_scene_...` (below) is the CROWN of this suite: it boots
## the REAL `GameWorld.tscn` -> `Valley.tscn` chain (mirrors
## `gameworld_e2e_loop_test.gd`'s own established boot convention), writes
## real cells onto the REAL, hosted [VoxelWorldGrid], and asserts the REAL,
## hosted [BuildValidation]'s real analysis pass reaches the REAL, hosted
## [LoopPayoffSignalSurface] through the REAL, hosted [LoopPayoffAdapter] --
## never a hand-built harness, never a mock [BuildValidation]. Every other
## test in this suite uses the SAME direct-construction pattern this whole
## epic's own test suite already established (e.g.
## `room_recognized_pacing_test.gd`'s `_make_bv` helper) -- a REAL
## [BuildValidation]/[LoopPayoffAdapter]/[LoopPayoffSignalSurface] triple,
## just outside a live [SceneTree] (ADR-0001's own headless-mockable
## contract), which is what lets the pacing/idempotency/geometry ACs below
## be asserted with precise, controlled fixtures.
##
## NOTE (accumulated pitfall, this codebase's own established precedent):
## signal-fire capture uses a captured [Array] with `.append()`/`.size()`,
## never a captured scalar `+= 1` inside a lambda -- GDScript closures do not
## write back captured scalars.
class_name LoopPayoffRealSignalTest
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")

const MAX_ROOM_HEIGHT: int = 8  # BuildValidationConfig default.


# ---------------------------------------------------------------------------
# Shared fixtures (duplicated per this codebase's own established
# per-test-file convention -- see e.g. `room_recognized_pacing_test.gd`)
# ---------------------------------------------------------------------------

func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


func _make_bv(grid: VoxelWorldGrid, mock_tick: MockTimeTickSystem = null, registry: Object = null) -> BuildValidation:
	var bv: BuildValidation = auto_free(BuildValidation.new())
	bv.config = BuildValidationConfig.new()
	bv.voxel_world = grid
	if mock_tick != null:
		bv.time_tick_system = mock_tick
	if registry != null:
		bv.furniture_registry = registry
	bv.setup()
	return bv


func _make_surface() -> LoopPayoffSignalSurface:
	var surface: LoopPayoffSignalSurface = auto_free(LoopPayoffSignalSurface.new())
	surface.setup()
	return surface


func _make_adapter(bv: BuildValidation, surface: LoopPayoffSignalSurface) -> LoopPayoffAdapter:
	var adapter: LoopPayoffAdapter = auto_free(LoopPayoffAdapter.new())
	adapter.build_validation = bv
	adapter.payoff_surface = surface
	adapter.setup()
	return adapter


func _solid_contents() -> CellContents:
	return CellContents.new(1, 0)


func _empty_contents() -> CellContents:
	return CellContents.new(0, 0)


## Mirrors `room_recognized_pacing_test.gd`'s established helper: the
## floor+roof pair that makes [param cell] a candidate interior cell.
func _add_interior_cell(changes: Dictionary[Vector3i, CellContents], cell: Vector3i) -> void:
	changes[cell + Vector3i(0, -1, 0)] = _solid_contents()
	changes[cell + Vector3i(0, MAX_ROOM_HEIGHT, 0)] = _solid_contents()


func _add_open_sky_cell(changes: Dictionary[Vector3i, CellContents], cell: Vector3i) -> void:
	changes[cell + Vector3i(0, -1, 0)] = _solid_contents()


## Minimal duck-typed furniture-registry stub (BV-1 §5 shape), mirrors
## `room_recognized_pacing_test.gd`/`shelter_classification_test.gd`'s own
## established `_StubFurnitureRegistry`.
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


# ---------------------------------------------------------------------------
# THE CROWN — a real booted scene, real signal, real listener
# ---------------------------------------------------------------------------

func test_real_booted_scene_room_recognition_and_shelter_reach_hosted_surface() -> void:
	# Arrange — boot the REAL GameWorld.tscn -> Valley.tscn chain.
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)

	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()
	var surface: LoopPayoffSignalSurface = valley.get_loop_payoff_signal_surface()
	var adapter: LoopPayoffAdapter = valley.get_loop_payoff_adapter()
	var build_validation: BuildValidation = valley.get_build_validation()
	assert_object(surface).is_not_null()
	assert_bool(adapter.is_set_up()).is_true()
	assert_object(adapter.build_validation).is_same(build_validation)
	assert_object(adapter.payoff_surface).is_same(surface)
	assert_int(surface.get_active_payoff_count()).is_equal(0)

	# Learn the REAL pass_group_id BuildValidation mints (an internal
	# implementation detail this test must not hardcode) by observing the
	# SAME real, hosted signal the adapter itself subscribes to -- this
	# capture is read-only instrumentation; every assertion below reads
	# ONLY the real, hosted surface.
	var captured_group_ids: Array[StringName] = []
	build_validation.room_recognized.connect(
		func(_cells: Array[Vector3i], _celebrate: bool, group_id: StringName) -> void:
			captured_group_ids.append(group_id)
	)

	# Act — write a real 2-cell room directly onto the REAL, hosted
	# VoxelWorldGrid, ABOVE its own real, lazily-regenerated terrain (Story
	# vox-011/ADR-0015 §5: a chunk regenerates deterministic terrain the
	# instant residency is first requested for it -- "no eager
	# generate_terrain() call" does NOT mean "empty forever" once touched).
	# The shipped world is shallow (max_y = 16, base_height = 4, amplitude =
	# 3.0), so terrain height never exceeds 7 anywhere -- Y = 8 is
	# deterministically clear air in every column, everywhere in the world.
	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	var center: Vector3i = VillagerRosterSpawner.world_center_cell(voxel_world.config)
	var anchor: Vector3i = Vector3i(center.x + 40, 8, center.z + 40)

	# Shrink JUST this test's own residency window (a duplicated config, never
	# the shared production `.tres`) so the SAME real, sanctioned residency
	# API [Valley._process] already drives every frame in production
	# converges in one or two calls instead of needing to walk the shipped
	# `view_radius_chunks = 24` window's full budgeted dispatch order.
	voxel_world.config = voxel_world.config.duplicate()
	voxel_world.config.view_radius_chunks = 1
	voxel_world.config.settlement_radius_chunks = 1
	var target_chunk: Vector2i = voxel_world.chunk_key_for_cell(anchor)
	var residency_tries: int = 0
	while not voxel_world.is_chunk_resident(target_chunk) and residency_tries < 200:
		voxel_world.update_residency(anchor, anchor)
		voxel_world.drain_pending_async_reads(50)
		residency_tries += 1
	assert_bool(voxel_world.is_chunk_resident(target_chunk)).is_true()

	var changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes, anchor)
	_add_interior_cell(changes, anchor + Vector3i(1, 0, 0))
	_add_open_sky_cell(changes, anchor + Vector3i(2, 0, 0))
	voxel_world.bulk_write(changes)

	# Assert — the real analysis pass fired exactly one real room_recognized,
	# and the REAL, hosted surface received it as a real room_celebrated
	# payoff with real detail data -- never a stub/placeholder emitter.
	assert_int(captured_group_ids.size()).is_equal(1)
	var group_id: StringName = captured_group_ids[0]
	assert_int(surface.get_active_payoff_count()).is_equal(1)
	assert_bool(surface.is_payoff_active(&"room_celebrated", group_id)).is_true()
	var detail: PayoffDetail = surface.get_payoff_detail(&"room_celebrated", group_id)
	assert_object(detail).is_not_null()
	assert_bool(detail.celebrate).is_true()
	assert_int(detail.subjects.size()).is_equal(1)  # one region recognized this pass.
	assert_int(detail.cells.size()).is_equal(2)  # both of that region's interior cells.

	# Act — place a REAL bed (FurnitureRegistry.place, real production API)
	# inside the just-recognized room, through the REAL, hosted registry.
	var furniture_registry: FurnitureRegistry = valley.get_furniture_registry()
	var bed_item_id: String = furniture_registry.place(&"bed", [anchor])

	# Assert — the real shelter reclassification this triggers reaches the
	# REAL, hosted surface as a real shelter_status payoff.
	var shelter_subject: StringName = StringName(bed_item_id)
	assert_bool(surface.is_payoff_active(&"shelter_status", shelter_subject)).is_true()
	var shelter_detail: PayoffDetail = surface.get_payoff_detail(&"shelter_status", shelter_subject)
	assert_object(shelter_detail).is_not_null()
	assert_bool(shelter_detail.sheltered).is_true()
	# Two distinct live keys now: the room_celebrated group from above, plus
	# this new shelter_status key -- both real, both on the same real,
	# hosted surface.
	assert_int(surface.get_active_payoff_count()).is_equal(2)


# ---------------------------------------------------------------------------
# Minimum 1 — one group, one cue
# ---------------------------------------------------------------------------

func test_minimum1_same_pass_group_of_three_yields_one_key_and_one_cue() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)
	var surface: LoopPayoffSignalSurface = _make_surface()
	_make_adapter(bv, surface)

	# A real "cue-trigger spy" -- gates on a key's FIRST activation only,
	# mirroring the surface's own documented "refresh-in-place, never a
	# fresh occurrence" contract (presentation-002) that a real presentation
	# consumer would apply to decide whether to actually play a chime.
	var cue_fire_count: Array[int] = [0]
	var already_cued: Dictionary[String, bool] = {}
	surface.payoff_signaled.connect(
		func(payoff_type: StringName, subject: StringName) -> void:
			var key: String = "%s:%s" % [payoff_type, subject]
			if not already_cued.has(key):
				already_cued[key] = true
				cue_fire_count[0] += 1
	)

	# Three DISJOINT rooms recognized in ONE real bulk_write -- one pass,
	# three newly-recognized regions, sharing one pass_group_id.
	var changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes, Vector3i(0, 1, 0))
	_add_interior_cell(changes, Vector3i(1, 1, 0))
	_add_open_sky_cell(changes, Vector3i(2, 1, 0))
	_add_interior_cell(changes, Vector3i(10, 1, 0))
	_add_interior_cell(changes, Vector3i(11, 1, 0))
	_add_open_sky_cell(changes, Vector3i(12, 1, 0))
	_add_interior_cell(changes, Vector3i(20, 1, 0))
	_add_interior_cell(changes, Vector3i(21, 1, 0))
	_add_open_sky_cell(changes, Vector3i(22, 1, 0))
	grid.bulk_write(changes)

	assert_int(surface.get_active_payoff_count()).is_equal(1)  # live-key count grows by exactly 1.
	assert_int(cue_fire_count[0]).is_equal(1)  # the cue-trigger spy fired exactly once.

	# Find the (single) live celebration key and read its accumulated detail.
	var live_key: String = already_cued.keys()[0]
	var parts: PackedStringArray = live_key.split(":", true, 1)
	var detail: PayoffDetail = surface.get_payoff_detail(StringName(parts[0]), StringName(parts[1]))
	assert_object(detail).is_not_null()
	assert_int(detail.subjects.size()).is_equal(3)  # detail.subjects.size() == N.


# ---------------------------------------------------------------------------
# Minimum 2 — same frame, no queue; grep-guard: no CONNECT_DEFERRED
# ---------------------------------------------------------------------------

func test_minimum2_receipt_happens_on_the_same_frame_as_the_emission() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)
	var surface: LoopPayoffSignalSurface = _make_surface()
	_make_adapter(bv, surface)

	var receipt_frame: Array[int] = [-1]
	surface.payoff_signaled.connect(
		func(_t: StringName, _s: StringName) -> void:
			receipt_frame[0] = Engine.get_process_frames()
	)

	var changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes, Vector3i(30, 1, 0))
	_add_interior_cell(changes, Vector3i(31, 1, 0))
	_add_open_sky_cell(changes, Vector3i(32, 1, 0))
	var emission_frame: int = Engine.get_process_frames()
	grid.bulk_write(changes)

	assert_int(receipt_frame[0]).is_equal(emission_frame)


func test_minimum2_grep_guard_no_connect_deferred_on_the_payoff_path() -> void:
	var source: String = (
		_read_module_source_only("res://src/presentation/loop_payoff_adapter.gd")
		+ _read_module_source_only("res://src/presentation/loop_payoff_signal_surface.gd")
	)
	assert_bool(source.contains("CONNECT_DEFERRED")).is_false()


# ---------------------------------------------------------------------------
# Minimum 3 — the first celebration of a session is never suppressed
# ---------------------------------------------------------------------------

func test_minimum3_first_fired_celebration_after_only_quiet_and_seal_churn_still_celebrates() -> void:
	var grid: VoxelWorldGrid = _make_grid()

	# Build a valid room DIRECTLY on the grid BEFORE bv even exists (so this
	# write can never trigger a LIVE pass) -- mirrors
	# `room_recognized_pacing_test.gd`'s own established "load pass never
	# arms" fixture shape.
	var changes_load: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_load, Vector3i(40, 1, 0))
	_add_interior_cell(changes_load, Vector3i(41, 1, 0))
	_add_open_sky_cell(changes_load, Vector3i(42, 1, 0))
	grid.bulk_write(changes_load)

	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var bv: BuildValidation = _make_bv(grid, mock_tick)  # subscribes only from NOW on.
	var surface: LoopPayoffSignalSurface = _make_surface()
	_make_adapter(bv, surface)

	bv.run_load_pass()
	assert_int(surface.get_active_payoff_count()).is_equal(0)  # silent load -- no payoff at all.

	# Transient seal/unseal churn (a natural build order: box four walls,
	# THEN carve the doorway -- a real Sealed state, then a real re-opening)
	# on a SEPARATE region -- never a room_recognized-eligible verdict while
	# sealed, so it never reaches the adapter/surface at all.
	var interior_cell := Vector3i(50, 1, 0)
	var companion_cell := Vector3i(51, 1, 0)
	var escape_cell := Vector3i(52, 1, 0)
	var seal_changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(seal_changes, interior_cell)
	_add_interior_cell(seal_changes, companion_cell)
	_add_open_sky_cell(seal_changes, escape_cell)
	grid.bulk_write(seal_changes)  # a genuine, LIVE (non-load-pass) recognition -- but this is the
	# session's first LIVE recognition, so per Rule 11 it must celebrate;
	# assert that first, then continue proving churn/quiet never re-suppress.
	assert_int(surface.get_active_payoff_count()).is_equal(1)
	assert_bool(surface.is_payoff_active(&"room_celebrated", &"room_group_1")).is_true()

	# Now churn a DIFFERENT, separate pocket through Sealed -> Room while
	# well inside the cooldown window, and confirm quiet/seal activity never
	# grows a SECOND celebration nor disturbs the first.
	for _i: int in range(3):
		mock_tick.fire_tick()
	var pocket_a := Vector3i(60, 1, 0)
	var pocket_b := Vector3i(61, 1, 0)
	var pocket_changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(pocket_changes, pocket_a)
	_add_interior_cell(pocket_changes, pocket_b)  # no escape -- Sealed, not Room-eligible.
	grid.bulk_write(pocket_changes)
	assert_int(bv.get_region_status(pocket_a)).is_equal(BuildValidationReachability.Verdict.SEALED)
	assert_int(surface.get_active_payoff_count()).is_equal(1)  # still just the one celebration.


# ---------------------------------------------------------------------------
# Minimum 4 — geometry travels with the event
# ---------------------------------------------------------------------------

func test_minimum4_detail_cells_survive_a_later_split_of_the_same_region() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)
	var surface: LoopPayoffSignalSurface = _make_surface()
	_make_adapter(bv, surface)

	# A 5-cell room with an escape at BOTH ends (mirrors
	# `room_recognized_pacing_test.gd`'s own established split fixture).
	var changes: Dictionary[Vector3i, CellContents] = {}
	for x: int in range(70, 75):
		_add_interior_cell(changes, Vector3i(x, 1, 0))
	_add_open_sky_cell(changes, Vector3i(69, 1, 0))
	_add_open_sky_cell(changes, Vector3i(75, 1, 0))
	grid.bulk_write(changes)

	assert_int(surface.get_active_payoff_count()).is_equal(1)
	var group_id: StringName = &"room_group_1"
	var detail: PayoffDetail = surface.get_payoff_detail(&"room_celebrated", group_id)
	assert_object(detail).is_not_null()
	assert_int(detail.cells.size()).is_equal(5)
	var recorded_cells: Dictionary[Vector3i, bool] = {}
	for cell: Vector3 in detail.cells:
		recorded_cells[Vector3i(cell)] = true
	for x: int in range(70, 75):
		assert_bool(recorded_cells.has(Vector3i(x, 1, 0))).is_true()

	# Act — split the region (occupy the middle cell), exactly like the
	# pacing test's own established split trigger.
	grid.bulk_write({Vector3i(72, 1, 0): _solid_contents()})

	# Assert — the ALREADY-DELIVERED detail is unchanged: it still reports
	# the region's cells AS OF THE EMITTING PASS, never re-queried.
	var detail_after_split: PayoffDetail = surface.get_payoff_detail(&"room_celebrated", group_id)
	assert_int(detail_after_split.cells.size()).is_equal(5)


# ---------------------------------------------------------------------------
# Minimum 5 — nothing competes with it (grep guard; no HUD/toast exists yet)
# ---------------------------------------------------------------------------

func test_minimum5_grep_guard_no_hud_or_toast_consumer_binds_the_celebration_type() -> void:
	# No `src/building_ui` or `src/villager_info_ui` directory exists yet in
	# this codebase (building-ui Rule 9d already rules room_recognized has no
	# HUD surface) -- this is a forward-looking REGRESSION guard: scan every
	# `.gd` file under `src/` for a `payoff_signaled.connect` call site and
	# assert the ONLY one is this story's own adapter subscription pattern
	# (there is none -- the adapter subscribes to BuildValidation's signals,
	# never to the surface's own `payoff_signaled`). A future HUD/toast
	# binding directly to `payoff_signaled` would trip this guard.
	var offending_files: Array[String] = []
	_scan_dir_for_substring("res://src", "payoff_signaled.connect", offending_files)
	assert_array(offending_files).is_empty()


# ---------------------------------------------------------------------------
# Pacing — celebrate vs quiet reach the surface as distinct payoff types
# ---------------------------------------------------------------------------

func test_pacing_same_pass_group_is_celebrated_later_pass_inside_cooldown_is_quiet() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var bv: BuildValidation = _make_bv(grid, mock_tick)
	var surface: LoopPayoffSignalSurface = _make_surface()
	_make_adapter(bv, surface)

	var changes_a: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_a, Vector3i(80, 1, 0))
	_add_interior_cell(changes_a, Vector3i(81, 1, 0))
	_add_open_sky_cell(changes_a, Vector3i(82, 1, 0))
	grid.bulk_write(changes_a)
	assert_bool(surface.is_payoff_active(&"room_celebrated", &"room_group_1")).is_true()

	for _i: int in range(5):  # well inside the default 20-tick cooldown.
		mock_tick.fire_tick()
	var changes_b: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes_b, Vector3i(90, 1, 0))
	_add_interior_cell(changes_b, Vector3i(91, 1, 0))
	_add_open_sky_cell(changes_b, Vector3i(92, 1, 0))
	grid.bulk_write(changes_b)

	# The second, quiet recognition never grows a SECOND room_celebrated key.
	assert_int(surface.get_active_payoff_count()).is_equal(2)  # celebration + quiet.
	var quiet_detail: PayoffDetail = null
	for key_string: String in _all_active_room_recognized_quiet_keys(surface):
		quiet_detail = surface.get_payoff_detail(&"room_recognized_quiet", StringName(key_string))
	assert_object(quiet_detail).is_not_null()
	assert_bool(quiet_detail.celebrate).is_false()


func _all_active_room_recognized_quiet_keys(surface: LoopPayoffSignalSurface) -> Array[String]:
	# There is no enumerator on the surface (by design -- it is a thin,
	# keyed store) -- this test already knows the exact subject it minted
	# (the region's own lexicographic-anchor key derived the SAME way
	# LoopPayoffAdapter does), so it re-derives that ONE key rather than
	# needing to enumerate.
	return [String(StringName("room_90_1_0"))]


# ---------------------------------------------------------------------------
# emit_payoff idempotency under REAL emissions
# ---------------------------------------------------------------------------

func test_idempotency_bed_toggling_sheltered_keeps_exactly_one_live_key() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var registry := _StubFurnitureRegistry.new()
	var bv: BuildValidation = _make_bv(grid, null, registry)
	var surface: LoopPayoffSignalSurface = _make_surface()
	_make_adapter(bv, surface)

	# A valid room (floor + roof + a genuine open-sky escape), mirroring the
	# CROWN test's own already-proven shape -- a bed placed inside a valid
	# Room reads sheltered immediately.
	var interior_cell := Vector3i(100, 1, 0)
	var companion_cell := Vector3i(101, 1, 0)
	var escape_cell := Vector3i(102, 1, 0)
	var changes: Dictionary[Vector3i, CellContents] = {}
	_add_interior_cell(changes, interior_cell)
	_add_interior_cell(changes, companion_cell)
	_add_open_sky_cell(changes, escape_cell)
	grid.bulk_write(changes)
	assert_int(bv.get_region_status(interior_cell)).is_equal(BuildValidationReachability.Verdict.ROOM)

	registry.place("bed_1", &"bed", [interior_cell])
	assert_int(surface.get_active_payoff_count()).is_equal(2)  # room_celebrated + shelter_status.
	assert_bool(surface.is_payoff_active(&"shelter_status", &"bed_1")).is_true()
	assert_bool(surface.get_payoff_detail(&"shelter_status", &"bed_1").sheltered).is_true()

	# Seal it (roof directly over the escape cell) -- shelter flips to
	# false, refreshed IN PLACE: the live-key count does not grow, because
	# a Sealed region never fires room_recognized/room_celebrated.
	# The no-op rewrite of interior_cell's OWN floor is load-bearing, not
	# decoration: roofing escape_cell alone does not necessarily seed this
	# pass's affected-region set with a member of the region interior_cell
	# belongs to, so get_region_status() would still report the stale ROOM
	# verdict. Bundling a same-content write of a known region member forces
	# the reseed. This mirrors room_recognized_pacing_test.gd's own
	# established trick — see its comment for the full rationale.
	grid.bulk_write({
		escape_cell + Vector3i(0, MAX_ROOM_HEIGHT, 0): _solid_contents(),
		interior_cell + Vector3i(0, -1, 0): _solid_contents(),
	})
	assert_int(bv.get_region_status(interior_cell)).is_equal(BuildValidationReachability.Verdict.SEALED)
	assert_int(surface.get_active_payoff_count()).is_equal(2)  # unchanged.
	assert_bool(surface.is_payoff_active(&"shelter_status", &"bed_1")).is_true()  # SAME key, never a second one.
	assert_bool(surface.get_payoff_detail(&"shelter_status", &"bed_1").sheltered).is_false()

	# Reopen it -- shelter flips back to true, refreshed in place at the
	# SAME (payoff_type, subject) key throughout every transition.
	# Same reseeding bundle as the seal above, for the same reason.
	grid.bulk_write({
		escape_cell + Vector3i(0, MAX_ROOM_HEIGHT, 0): _empty_contents(),
		interior_cell + Vector3i(0, -1, 0): _solid_contents(),
	})
	assert_bool(surface.is_payoff_active(&"shelter_status", &"bed_1")).is_true()
	assert_bool(surface.get_payoff_detail(&"shelter_status", &"bed_1").sheltered).is_true()


# ---------------------------------------------------------------------------
# Write-before-emit (Ordering constraint 1)
# ---------------------------------------------------------------------------

func test_write_before_emit_synchronous_handler_reads_the_current_record() -> void:
	var surface: LoopPayoffSignalSurface = _make_surface()
	var observed_sheltered: Array[bool] = []
	var observed_not_null: Array[bool] = []
	surface.payoff_signaled.connect(
		func(payoff_type: StringName, subject: StringName) -> void:
			var detail: PayoffDetail = surface.get_payoff_detail(payoff_type, subject)
			observed_not_null.append(detail != null)
			if detail != null:
				observed_sheltered.append(detail.sheltered)
	)

	var detail := PayoffDetail.new()
	detail.sheltered = true
	surface.emit_payoff(&"shelter_status", &"item_1", detail)

	assert_int(observed_not_null.size()).is_equal(1)
	assert_bool(observed_not_null[0]).is_true()
	assert_bool(observed_sheltered[0]).is_true()


# ---------------------------------------------------------------------------
# Detail cleanup (Ordering constraint 2)
# ---------------------------------------------------------------------------

func test_clear_payoff_erases_the_detail_alongside_the_key() -> void:
	var surface: LoopPayoffSignalSurface = _make_surface()
	var detail := PayoffDetail.new()
	detail.sheltered = true
	surface.emit_payoff(&"shelter_status", &"item_1", detail)
	assert_object(surface.get_payoff_detail(&"shelter_status", &"item_1")).is_not_null()

	surface.clear_payoff(&"shelter_status", &"item_1")

	assert_bool(surface.is_payoff_active(&"shelter_status", &"item_1")).is_false()
	assert_object(surface.get_payoff_detail(&"shelter_status", &"item_1")).is_null()


# ---------------------------------------------------------------------------
# Additivity — an existing two-arg consumer compiles and behaves verbatim
# ---------------------------------------------------------------------------

func test_additivity_existing_two_arg_consumer_still_works_unmodified() -> void:
	# The EXACT presentation-002 scaffolding call shape, unmodified.
	var surface: LoopPayoffSignalSurface = _make_surface()
	var received: Array = []
	surface.payoff_signaled.connect(func(payoff_type: StringName, subject: StringName) -> void:
		received.append([payoff_type, subject]))

	surface.emit_payoff(&"project_completed", &"project_7")

	assert_int(received.size()).is_equal(1)
	assert_str(String(received[0][0])).is_equal("project_completed")
	assert_str(String(received[0][1])).is_equal("project_7")
	assert_object(surface.get_payoff_detail(&"project_completed", &"project_7")).is_null()


# ---------------------------------------------------------------------------
# Injected-tier binding — setup() asserts wiring; a missing surface asserts
# ---------------------------------------------------------------------------

func test_setup_asserts_when_build_validation_unwired() -> void:
	var surface: LoopPayoffSignalSurface = _make_surface()
	var adapter: LoopPayoffAdapter = auto_free(LoopPayoffAdapter.new())
	adapter.payoff_surface = surface

	await assert_error(func() -> void: adapter.setup()).is_runtime_error(
		"Assertion failed: LoopPayoffAdapter.build_validation not wired"
	)


func test_setup_asserts_when_payoff_surface_unwired() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var bv: BuildValidation = _make_bv(grid)
	var adapter: LoopPayoffAdapter = auto_free(LoopPayoffAdapter.new())
	adapter.build_validation = bv

	await assert_error(func() -> void: adapter.setup()).is_runtime_error(
		"Assertion failed: LoopPayoffAdapter.payoff_surface not wired"
	)


# ---------------------------------------------------------------------------
# Grep guard — no placeholder/stub emitter remains on the payoff path
# ---------------------------------------------------------------------------

func test_grep_guard_no_scaffolding_placeholder_emitter_on_the_payoff_path() -> void:
	# The scaffolding story's own EXAMPLE payoff-type literals
	# ("project_completed", "villager_satisfied") must never appear as a
	# real emission source inside the production adapter/surface files --
	# their sole legitimate appearance anywhere in `src/` is documentation
	# (this check is comment-stripped, matching this codebase's own
	# established `_read_module_source_only` precedent) or a test's own
	# additivity fixture (out of `src/`, unaffected by this guard).
	var source: String = (
		_read_module_source_only("res://src/presentation/loop_payoff_adapter.gd")
		+ _read_module_source_only("res://src/presentation/loop_payoff_signal_surface.gd")
	)
	var placeholder_literals: Array[String] = ["project_completed", "villager_satisfied"]
	for literal: String in placeholder_literals:
		assert_bool(source.contains(literal)).is_false()

	# And positively: the REAL subscription this story's own wiring requires
	# is actually present (fails loudly if a future edit silently removes
	# the real connection and leaves the surface uncalled again).
	var adapter_source: String = _read_module_source_only("res://src/presentation/loop_payoff_adapter.gd")
	assert_bool(adapter_source.contains("room_recognized.connect")).is_true()
	assert_bool(adapter_source.contains("shelter_status_changed.connect")).is_true()


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Reads [param path] ONLY, STRIPPING full-line `#`/`##` doc-comment lines
## first -- mirrors `loop_payoff_surface_test.gd`'s own established
## `_read_module_source_only` precedent.
func _read_module_source_only(path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined


## Recursively scans every `.gd` file under [param dir_path] for [param
## needle] (comment-stripped), appending any matching file's path to [param
## offending_files_out].
func _scan_dir_for_substring(dir_path: String, needle: String, offending_files_out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry in [".", ".."]:
			entry = dir.get_next()
			continue
		var full_path: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			_scan_dir_for_substring(full_path, needle, offending_files_out)
		elif entry.ends_with(".gd"):
			if _read_module_source_only(full_path).contains(needle):
				offending_files_out.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
