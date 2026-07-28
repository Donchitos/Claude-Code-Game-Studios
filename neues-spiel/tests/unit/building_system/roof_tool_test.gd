## Unit test — Building System Story building-026 (Roof tool: GDD Formula F5
## Flat cell-set resolver + registration into CommitPipeline's per-tool seam,
## plus the formation-picker seam). ADR-0016 primary (blueprint cells grouped
## into a project, not a grid write).
##
## **Sprint 8 scope: Flat formation MVP only** (Gable/Hip/Shed are VS-tier,
## deferred per the sprint plan; AC15b is PROVISIONAL and intentionally not
## exercised here).
##
## Proves:
## 1. AC15 [TR-building-system-082]: a roof drag of 3 cells in x and 4 in z
##    (Flat formation) yields exactly 20 blueprint cells, one plane above the
##    footprint's picked surface.
## 2. Edge case: a 1x1 footprint (zero-length drag) yields exactly 1 cell.
## 3. The locked-plane Y-anchor discipline: every returned cell uses
##    press_cell's OWN Y plus one, never release_cell's -- mirrors
##    [FloorTool.floor_cell_set]'s identical precedent, offset up one plane.
## 4. One-cell-thick on the plane above the footprint -- never stacked.
## 5. Reversed drag direction (release below/behind press in x/z) yields the
##    identical cell set -- the rectangle is direction-agnostic.
## 6. [method RoofTool.resolve_cell_set] ignores its own `is_drag` parameter
##    for the Flat formation -- click and drag paths agree, mirroring
##    [WallTool]/[FloorTool]'s AC6b/precedent.
## 7. The formation-picker seam: [member RoofTool.Formation] defaults to
##    FLAT; [method RoofTool.set_formation]/[method RoofTool.get_formation]
##    round-trip for every formation value, including the VS-tier ones --
##    proving the SEAM exists without any of the three deferred formations
##    having built geometry (grep-guard below).
## 8. One-action fill, wired live into [CommitPipeline]: a single
##    [method CommitPipeline.commit] call creates every cell at once.
## 9. Grep-guards (QA plan Sprint 8, Call-out 3): `roof_tool.gd` never
##    constructs a [BlueprintCell] directly and never calls a
##    [VoxelWorldGrid] write API.
## 10. Scope guard (story's own Implementation Notes: "Do NOT build those
##     three algorithms in M01"): `roof_tool.gd` carries no Gable/Hip/Shed
##     geometry function of its own -- only the Flat formula and the
##     assert-guarded stub dispatch exist.
class_name RoofToolTest
extends GdUnitTestSuite

const ROOF_TOOL_SOURCE_PATH: String = "res://src/building_system/roof_tool.gd"


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Reads a single `.gd` source file, stripping full-line `#`/`##` doc-comment
## lines first -- mirrors this codebase's established
## `_read_gd_source_without_comments` precedent (`wall_tool_test.gd`,
## `floor_tool_test.gd`) so a file's own doc comments (which legitimately NAME
## the banned APIs/formations to document their absence) are never mistaken
## for a violation.
func _read_gd_source_without_comments(file_path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(file_path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined


# ---------------------------------------------------------------------------
# F5 Flat -- pure static formula [TR-building-system-082]
# ---------------------------------------------------------------------------

func test_flat_roof_cell_set_3_in_x_and_4_in_z_yields_20_cells_one_plane_up() -> void:
	# AC15 / GDD's own F2-mirrored worked example: "dragging 3 cells in x and
	# 4 in z -> 4 x 5 = 20 blueprint cells", one plane above the picked
	# surface (press_cell.y = 4 -> roof plane y = 5).
	var cells: Array[Vector3i] = RoofTool.flat_roof_cell_set(Vector3i(0, 4, 0), Vector3i(3, 4, 4))

	assert_int(cells.size()).is_equal(20)
	for x: int in range(4):
		for z: int in range(5):
			assert_bool(cells.has(Vector3i(x, 5, z))).is_true()


func test_flat_roof_cell_set_1x1_footprint_yields_single_cell() -> void:
	# This story's own documented edge case: "a 1x1 footprint yields 1 cell."
	var cells: Array[Vector3i] = RoofTool.flat_roof_cell_set(Vector3i(5, 2, 5), Vector3i(5, 2, 5))

	assert_array(cells).is_equal([Vector3i(5, 3, 5)])


func test_flat_roof_cell_set_locked_to_press_cell_y_plus_one_never_release_cell_y() -> void:
	# The rectangle's Y is always anchored to press_cell's OWN Y (4) plus one
	# plane (5), never release_cell's (9) -- Core Rule 3's single-locked-plane
	# guarantee, mirroring FloorTool.floor_cell_set's identical precedent
	# offset up one plane.
	var cells: Array[Vector3i] = RoofTool.flat_roof_cell_set(Vector3i(0, 4, 0), Vector3i(2, 9, 2))

	assert_int(cells.size()).is_equal(9)
	for cell: Vector3i in cells:
		assert_int(cell.y).is_equal(5)


func test_flat_roof_cell_set_one_cell_thick_never_stacked() -> void:
	var cells: Array[Vector3i] = RoofTool.flat_roof_cell_set(Vector3i(0, 5, 0), Vector3i(2, 5, 1))

	assert_int(cells.size()).is_equal(6)
	var distinct_y: Array[int] = []
	for cell: Vector3i in cells:
		if not distinct_y.has(cell.y):
			distinct_y.append(cell.y)
	assert_array(distinct_y).is_equal([6])


func test_flat_roof_cell_set_reversed_drag_direction_yields_the_same_rectangle() -> void:
	# The rectangle is built from min/max, not press-as-origin -- a drag
	# ending up-and-left of its start yields the identical cell set as the
	# AC15 example dragged the other way.
	var cells: Array[Vector3i] = RoofTool.flat_roof_cell_set(Vector3i(3, 4, 4), Vector3i(0, 4, 0))

	assert_int(cells.size()).is_equal(20)
	for x: int in range(4):
		for z: int in range(5):
			assert_bool(cells.has(Vector3i(x, 5, z))).is_true()


# ---------------------------------------------------------------------------
# resolve_cell_set -- ignores is_drag entirely, Flat formation
# ---------------------------------------------------------------------------

func test_resolve_cell_set_ignores_is_drag_flag_click_and_drag_agree() -> void:
	# A genuine click (is_drag=false) and a real drag (is_drag=true) supply
	# the SAME press/release pair -- the formula must resolve identically
	# either way, with no separate click-path branch inside this class
	# (mirrors WallTool/FloorTool's identical AC6b precedent).
	var tool: RoofTool = auto_free(RoofTool.new())

	var click_path: Array[Vector3i] = tool.resolve_cell_set(false, Vector3i(0, 4, 0), Vector3i(2, 4, 3))
	var drag_path: Array[Vector3i] = tool.resolve_cell_set(true, Vector3i(0, 4, 0), Vector3i(2, 4, 3))

	assert_array(click_path).is_equal(drag_path)
	assert_int(click_path.size()).is_equal(12)


func test_resolve_cell_set_defaults_to_flat_formation() -> void:
	# Core Rule 6 / this story: "a formation is chosen before the drag" --
	# the tool must have a safe default (FLAT, the only MVP-complete
	# formation) rather than requiring a mandatory setup step.
	var tool: RoofTool = auto_free(RoofTool.new())

	assert_int(tool.get_formation()).is_equal(RoofTool.Formation.FLAT)
	var cells: Array[Vector3i] = tool.resolve_cell_set(true, Vector3i(0, 4, 0), Vector3i(3, 4, 4))
	assert_int(cells.size()).is_equal(20)


# ---------------------------------------------------------------------------
# Formation-picker seam (story's own Implementation Notes)
# ---------------------------------------------------------------------------

func test_set_formation_and_get_formation_round_trip_for_every_formation() -> void:
	# Proves the seam is a real, settable enum for all four MVP formations
	# (Core Rule 6) -- including the three VS-tier ones, which carry no built
	# geometry (see the grep-guard test below) but must still be selectable
	# as a formation VALUE so a future Building UI picker widget has
	# something to set.
	var tool: RoofTool = auto_free(RoofTool.new())

	for formation: RoofTool.Formation in [
		RoofTool.Formation.FLAT, RoofTool.Formation.GABLE, RoofTool.Formation.HIP, RoofTool.Formation.SHED
	]:
		tool.set_formation(formation)
		assert_int(tool.get_formation()).is_equal(formation)


# ---------------------------------------------------------------------------
# One-action fill, wired live into CommitPipeline's seam
# ---------------------------------------------------------------------------

func test_wired_into_commit_pipeline_creates_all_cells_in_one_commit_call() -> void:
	# Proves the "one commit, one undo step" invariant structurally,
	# mirroring wall_tool_test.gd/floor_tool_test.gd's own precedent: a
	# single CommitPipeline.commit() call (Story building-021/022's own
	# established entry point) creates every one of the roof's cells at
	# once, never a partial or per-row sequence.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	grid.set_cell(Vector3i(5, 3, 5), CellContents.new(1, 0))

	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())
	machine.arm_tool(&"roof")

	var pick: PlacementPick = auto_free(PlacementPick.new())
	pick.camera_input = auto_free(CameraInput.new())
	pick.voxel_world = grid
	pick.tool_state_machine = machine
	pick.config = PlacementPickConfig.new()
	pick.setup()
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))

	var pipeline: CommitPipeline = auto_free(CommitPipeline.new())
	pipeline.placement_pick = pick
	pipeline.voxel_world = grid
	pipeline.config = CommitPipelineConfig.new()
	pipeline.setup()
	pipeline.set_selected_item(&"placeholder_material")

	var roof_tool: RoofTool = auto_free(RoofTool.new())
	pipeline.set_cell_set_resolver(roof_tool.resolve_cell_set)

	var received: Array = []
	pipeline.blueprint_cells_created.connect(func(cells: Array[BlueprintCell]) -> void: received.append(cells))

	# Act -- a single drag-release trigger at the GDD's own F5-Flat example
	# (F2-mirrored): 3 cells in x, 4 in z, picked at y=3 (block top) -> roof
	# plane y=4.
	pipeline._on_build_committed(true, Vector3i(0, 3, 0), Vector3i(3, 3, 4))

	# Assert -- exactly one signal emission (one commit, one undo step) with
	# all 20 cells present (AC15), never a partial or per-row sequence.
	assert_int(received.size()).is_equal(1)
	var cells: Array = received[0]
	assert_int(cells.size()).is_equal(20)
	for cell: BlueprintCell in cells:
		assert_int(cell.cell.y).is_equal(4)
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(20)


# ---------------------------------------------------------------------------
# Grep-guards (QA plan Sprint 8, Call-out 3 + this story's own scope guard)
# ---------------------------------------------------------------------------

func test_roof_tool_never_constructs_a_blueprint_cell_directly() -> void:
	var source: String = _read_gd_source_without_comments(ROOF_TOOL_SOURCE_PATH)

	assert_bool(source.contains("BlueprintCell.new(")).is_false()


func test_roof_tool_never_calls_a_voxel_world_write_api() -> void:
	var source: String = _read_gd_source_without_comments(ROOF_TOOL_SOURCE_PATH)

	assert_bool(source.contains("set_cell(")).is_false()
	assert_bool(source.contains("bulk_write(")).is_false()
	assert_bool(source.contains("clear_cell(")).is_false()


func test_roof_tool_carries_no_gable_hip_shed_geometry_functions_yet() -> void:
	# This story's own Implementation Notes: "Do NOT build those three
	# algorithms in M01." A stray partial implementation would itself be a
	# scope violation this test exists to catch -- only the Flat formula
	# (flat_roof_cell_set) may exist; no per-formation geometry function for
	# the three deferred formations may exist under any name.
	var source: String = _read_gd_source_without_comments(ROOF_TOOL_SOURCE_PATH)

	assert_bool(source.contains("gable_roof_cell_set")).is_false()
	assert_bool(source.contains("hip_roof_cell_set")).is_false()
	assert_bool(source.contains("shed_roof_cell_set")).is_false()
	assert_bool(source.contains("flat_roof_cell_set")).is_true()
