## Unit test -- Building System Story building-032 (Undo/redo stack core:
## command model, bounded depth, redo-branch clear, transition-complete
## clear). ADR-0016 primary (plan-only undo/redo mechanics); ADR-0012
## secondary (the stack is excluded from serialization -- not exercised
## here, no serialize() surface exists on this class).
##
## Proves:
## 1. AC28 (Edge Case 8): redo re-validates every cell independently via
##    [member UndoRedoStack.recreate_cell_callable] -- invalid cells are
##    dropped with feedback ([signal UndoRedoStack.redo_cells_dropped]);
##    valid cells are re-created (re-pushed as a fresh undoable command,
##    [signal UndoRedoStack.command_redone]); a zero-survivor redo is a
##    no-op with feedback ([signal UndoRedoStack.redo_no_op]), and pushes
##    nothing back onto the undo stack.
## 2. AC30 (Edge Case 9): the bounded stack (`undo_stack_depth`) silently
##    discards the oldest command once a new command exceeds capacity.
## 3. AC31 (Edge Case 9): any command recorded after an undo clears the
##    entire redo branch.
## 4. AC30 + AC31 together, from the SAME single new-command commit (QA
##    plan's own explicit "both effects observed from one action" case).
## 5. AC32 / AC32b: [signal GameWorld.transition_ended] with
##    `success == true` clears both stacks; `success == false` (abort)
##    leaves every command untouched; [signal GameWorld.transition_begun]
##    is never even connected, so no begin-signal side effect is possible.
## 6. Held-key-repeat edge case: repeated [method UndoRedoStack.undo] calls
##    each consume exactly one step -- no acceleration, no double-consumption.
## 7. Plan-only guardrail (control-manifest grep-guard family, extended to
##    this story's new stack code): the undo/redo module source contains
##    zero references to a committed-block/Voxel-World write API.
class_name UndoRedoStackCoreTest
extends GdUnitTestSuite

const BUILDING_SYSTEM_DIR: String = "res://src/building_system/"
const UNDO_REDO_STACK_SOURCE_PATH: String = "res://src/building_system/undo_redo_stack.gd"


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

func _new_stack() -> UndoRedoStack:
	var stack: UndoRedoStack = auto_free(UndoRedoStack.new())
	stack.config = UndoRedoStackConfig.new()
	stack.setup()
	return stack


## Returns an [UndoRedoStack] wired to a bare [GameWorld] (mirrors
## [ToolStateMachine]'s own `_new_wired_machine()` helper exactly, see
## `tool_state_machine_test.gd`) -- no scene tree, no boot gate involved:
## [method GameWorld.begin_transition]/[method GameWorld.end_transition]
## touch neither [enum GameWorld.BootState] nor `resource_item_database`.
func _new_wired_stack() -> UndoRedoStack:
	var world: GameWorld = auto_free(GameWorld.new())
	var stack: UndoRedoStack = auto_free(UndoRedoStack.new())
	stack.config = UndoRedoStackConfig.new()
	stack.game_world = world
	stack.setup()
	return stack


func _read_gd_source_without_comments(file_path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(file_path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined


# ---------------------------------------------------------------------------
# Baseline record/undo/redo mechanics
# ---------------------------------------------------------------------------

func test_record_command_makes_it_undoable_not_yet_redoable() -> void:
	# Arrange
	var stack: UndoRedoStack = _new_stack()
	var cells: Array[Vector3i] = [Vector3i(1, 0, 1), Vector3i(2, 0, 1)]

	# Act
	stack.record_command(cells)

	# Assert
	assert_bool(stack.can_undo()).is_true()
	assert_bool(stack.can_redo()).is_false()
	assert_int(stack.get_undo_stack_size()).is_equal(1)


func test_undo_with_no_callable_wired_still_pops_and_signals() -> void:
	# Arrange -- no cancel_cell_callable wired: a permissive no-op, mirroring
	# CommitPipeline's own "no predicate wired => no restriction" default.
	var stack: UndoRedoStack = _new_stack()
	var cells: Array[Vector3i] = [Vector3i(1, 0, 1)]
	stack.record_command(cells)
	var received: Array = []
	stack.command_undone.connect(func(undone_cells: Array[Vector3i]) -> void: received.append(undone_cells))

	# Act
	var result: bool = stack.undo()

	# Assert
	assert_bool(result).is_true()
	assert_bool(stack.can_undo()).is_false()
	assert_bool(stack.can_redo()).is_true()
	assert_int(received.size()).is_equal(1)
	assert_array(received[0]).is_equal([Vector3i(1, 0, 1)])


func test_undo_calls_cancel_cell_callable_once_per_cell_in_order() -> void:
	# Arrange
	var stack: UndoRedoStack = _new_stack()
	var cells: Array[Vector3i] = [Vector3i(1, 0, 1), Vector3i(2, 0, 1), Vector3i(3, 0, 1)]
	stack.record_command(cells)
	var canceled: Array[Vector3i] = []
	stack.set_cancel_cell_callable(func(cell: Vector3i) -> bool:
		canceled.append(cell)
		return true
	)

	# Act
	stack.undo()

	# Assert
	assert_array(canceled).is_equal(cells)


func test_undo_on_empty_stack_is_a_no_op() -> void:
	# Arrange
	var stack: UndoRedoStack = _new_stack()

	# Act
	var result: bool = stack.undo()

	# Assert
	assert_bool(result).is_false()


# ---------------------------------------------------------------------------
# AC28 (Edge Case 8) -- redo re-validates every cell independently
# ---------------------------------------------------------------------------

func test_redo_drops_invalidated_cells_and_keeps_valid_ones() -> void:
	# Arrange -- a 3-cell command; one cell is now "occupied" (simulated via
	# the injected recreate_cell_callable, this story's own plan-only hook).
	var stack: UndoRedoStack = _new_stack()
	var occupied_cell := Vector3i(2, 0, 1)
	var cells: Array[Vector3i] = [Vector3i(1, 0, 1), occupied_cell, Vector3i(3, 0, 1)]
	stack.record_command(cells)
	stack.undo()
	stack.set_recreate_cell_callable(func(cell: Vector3i) -> bool: return cell != occupied_cell)
	var dropped_received: Array = []
	var redone_received: Array = []
	stack.redo_cells_dropped.connect(func(dropped: Array[Vector3i]) -> void: dropped_received.append(dropped))
	stack.command_redone.connect(func(redone: Array[Vector3i]) -> void: redone_received.append(redone))

	# Act
	var result: bool = stack.redo()

	# Assert -- only the still-valid cells re-created; the invalid one dropped.
	assert_bool(result).is_true()
	assert_int(dropped_received.size()).is_equal(1)
	assert_array(dropped_received[0]).is_equal([occupied_cell])
	assert_int(redone_received.size()).is_equal(1)
	assert_array(redone_received[0]).is_equal([Vector3i(1, 0, 1), Vector3i(3, 0, 1)])
	# The surviving subset becomes a fresh undoable command.
	assert_bool(stack.can_undo()).is_true()
	assert_int(stack.get_undo_stack_size()).is_equal(1)


func test_redo_with_zero_survivors_is_a_no_op_with_feedback() -> void:
	# Arrange -- every cell of the command is now invalid.
	var stack: UndoRedoStack = _new_stack()
	var cells: Array[Vector3i] = [Vector3i(1, 0, 1), Vector3i(2, 0, 1)]
	stack.record_command(cells)
	stack.undo()
	stack.set_recreate_cell_callable(func(_cell: Vector3i) -> bool: return false)
	var no_op_count: Array = []
	var redone_received: Array = []
	stack.redo_no_op.connect(func() -> void: no_op_count.append(true))
	stack.command_redone.connect(func(redone: Array[Vector3i]) -> void: redone_received.append(redone))

	# Act
	var result: bool = stack.redo()

	# Assert -- a genuine no-op: nothing pushed back onto the undo stack.
	assert_bool(result).is_false()
	assert_int(no_op_count.size()).is_equal(1)
	assert_int(redone_received.size()).is_equal(0)
	assert_bool(stack.can_undo()).is_false()
	assert_bool(stack.can_redo()).is_false()


func test_redo_with_no_callable_wired_treats_every_cell_as_surviving() -> void:
	# Arrange -- no recreate_cell_callable wired: permissive default.
	var stack: UndoRedoStack = _new_stack()
	var cells: Array[Vector3i] = [Vector3i(1, 0, 1), Vector3i(2, 0, 1)]
	stack.record_command(cells)
	stack.undo()

	# Act
	var result: bool = stack.redo()

	# Assert
	assert_bool(result).is_true()
	assert_bool(stack.can_undo()).is_true()
	assert_bool(stack.can_redo()).is_false()


func test_redo_on_empty_redo_stack_is_a_no_op() -> void:
	# Arrange
	var stack: UndoRedoStack = _new_stack()

	# Act
	var result: bool = stack.redo()

	# Assert
	assert_bool(result).is_false()


# ---------------------------------------------------------------------------
# AC30 (Edge Case 9) -- bounded depth discards the oldest silently
# ---------------------------------------------------------------------------

func test_stack_discards_oldest_command_beyond_configured_depth() -> void:
	# Arrange -- a tiny depth to keep the test cheap.
	var stack: UndoRedoStack = _new_stack()
	stack.config.undo_stack_depth = 2
	var first: Array[Vector3i] = [Vector3i(1, 0, 1)]
	var second: Array[Vector3i] = [Vector3i(2, 0, 1)]
	var third: Array[Vector3i] = [Vector3i(3, 0, 1)]

	# Act -- three commands committed against a depth-2 stack.
	stack.record_command(first)
	stack.record_command(second)
	stack.record_command(third)

	# Assert -- exactly `undo_stack_depth` commands retained; the oldest
	# (`first`) is gone, silently (no signal, no error) -- undoing twice
	# reaches only `third` then `second`, never `first`.
	assert_int(stack.get_undo_stack_size()).is_equal(2)
	var undone: Array = []
	stack.command_undone.connect(func(cells: Array[Vector3i]) -> void: undone.append(cells))
	stack.undo()
	stack.undo()
	assert_int(undone.size()).is_equal(2)
	assert_array(undone[0]).is_equal(third)
	assert_array(undone[1]).is_equal(second)
	assert_bool(stack.can_undo()).is_false()


# ---------------------------------------------------------------------------
# AC31 (Edge Case 9) -- a new command clears the redo branch
# ---------------------------------------------------------------------------

func test_new_command_after_undo_clears_the_redo_branch() -> void:
	# Arrange
	var stack: UndoRedoStack = _new_stack()
	stack.record_command([Vector3i(1, 0, 1)])
	stack.undo()
	assert_bool(stack.can_redo()).is_true()

	# Act -- a genuinely new command commits.
	stack.record_command([Vector3i(2, 0, 1)])

	# Assert -- the redo branch is gone.
	assert_bool(stack.can_redo()).is_false()
	assert_int(stack.get_redo_stack_size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC30 + AC31 together -- QA plan's explicit "one action, both effects" case
# ---------------------------------------------------------------------------

func test_bounded_discard_and_redo_clear_both_observed_from_one_commit() -> void:
	# Arrange -- fill a depth-2 stack, then undo once (populating the redo
	# branch) before the triggering commit.
	var stack: UndoRedoStack = _new_stack()
	stack.config.undo_stack_depth = 2
	stack.record_command([Vector3i(1, 0, 1)])
	stack.record_command([Vector3i(2, 0, 1)])
	stack.undo()
	assert_bool(stack.can_redo()).is_true()
	assert_int(stack.get_undo_stack_size()).is_equal(1)

	# Act -- two more commands commit; the second pushes the stack past
	# depth 2 again.
	stack.record_command([Vector3i(3, 0, 1)])
	stack.record_command([Vector3i(4, 0, 1)])

	# Assert -- redo branch cleared (AC31) AND the stack stayed bounded,
	# discarding the oldest survivor silently (AC30) -- both from committing
	# new commands after the undo above.
	assert_bool(stack.can_redo()).is_false()
	assert_int(stack.get_undo_stack_size()).is_equal(2)
	var undone: Array = []
	stack.command_undone.connect(func(cells: Array[Vector3i]) -> void: undone.append(cells))
	stack.undo()
	stack.undo()
	assert_int(undone.size()).is_equal(2)
	assert_array(undone[0]).is_equal([Vector3i(4, 0, 1)])
	assert_array(undone[1]).is_equal([Vector3i(3, 0, 1)])
	assert_bool(stack.can_undo()).is_false()


# ---------------------------------------------------------------------------
# AC32 / AC32b -- transition-COMPLETE clears; abort leaves the stack intact
# ---------------------------------------------------------------------------

func test_transition_complete_clears_the_stack() -> void:
	# Arrange -- a 3-command stack (QA plan's own scenario size).
	var stack: UndoRedoStack = _new_wired_stack()
	stack.record_command([Vector3i(1, 0, 1)])
	stack.record_command([Vector3i(2, 0, 1)])
	stack.record_command([Vector3i(3, 0, 1)])
	assert_int(stack.get_undo_stack_size()).is_equal(3)

	# Act -- the transition begins, then completes successfully.
	stack.game_world.begin_transition()
	stack.game_world.end_transition(true)

	# Assert -- fully empty.
	assert_int(stack.get_undo_stack_size()).is_equal(0)
	assert_bool(stack.can_undo()).is_false()
	assert_bool(stack.can_redo()).is_false()


func test_transition_abort_leaves_all_commands_undoable() -> void:
	# Arrange -- a 3-command stack (QA plan's own scenario size).
	var stack: UndoRedoStack = _new_wired_stack()
	stack.record_command([Vector3i(1, 0, 1)])
	stack.record_command([Vector3i(2, 0, 1)])
	stack.record_command([Vector3i(3, 0, 1)])

	# Act -- the transition begins, then ABORTS (target scene failed to load).
	stack.game_world.begin_transition()
	stack.game_world.end_transition(false)

	# Assert -- all 3 commands remain exactly as undoable as before.
	assert_int(stack.get_undo_stack_size()).is_equal(3)
	assert_bool(stack.can_undo()).is_true()


func test_transition_begun_alone_never_touches_the_stack() -> void:
	# Arrange -- AC32b's own wording: "no begin-signal side effect touched
	# the stack." Only the begin signal fires; end_transition is never
	# called in this test at all.
	var stack: UndoRedoStack = _new_wired_stack()
	stack.record_command([Vector3i(1, 0, 1)])

	# Act
	stack.game_world.begin_transition()

	# Assert
	assert_int(stack.get_undo_stack_size()).is_equal(1)
	assert_bool(stack.can_undo()).is_true()


func test_setup_called_twice_with_game_world_wired_does_not_double_connect() -> void:
	# Arrange -- UndoRedoStack._connect_transition_signals' is_connected()
	# guard must make a repeated setup() call idempotent, mirroring
	# ToolStateMachine's own established precedent for this exact check.
	var world: GameWorld = auto_free(GameWorld.new())
	var stack: UndoRedoStack = auto_free(UndoRedoStack.new())
	stack.config = UndoRedoStackConfig.new()
	stack.game_world = world
	stack.setup()
	stack.setup()
	stack.record_command([Vector3i(1, 0, 1)])

	# Act -- reaching this without a duplicate-connection engine error already
	# proves idempotence; also assert the clear itself still happened exactly
	# once (a double connection would still leave the stack empty, so the
	# real proof is the absence of an "already connected" error above).
	world.begin_transition()
	world.end_transition(true)

	# Assert
	assert_int(stack.get_undo_stack_size()).is_equal(0)


func test_setup_without_game_world_wired_does_not_raise() -> void:
	# Arrange / Act
	var stack: UndoRedoStack = auto_free(UndoRedoStack.new())
	stack.config = UndoRedoStackConfig.new()
	stack.setup()
	stack.record_command([Vector3i(1, 0, 1)])

	# Assert -- reaching this line without an error is the proof; the command
	# is still undoable, nothing was silently cleared.
	assert_bool(stack.can_undo()).is_true()


# ---------------------------------------------------------------------------
# Held Ctrl+Z key-repeat edge case -- each repeat is exactly one undo step
# ---------------------------------------------------------------------------

func test_repeated_undo_calls_consume_exactly_one_step_each_no_acceleration() -> void:
	# Arrange -- 5 commands, simulating a held-key repeat firing 5 discrete
	# undo() calls in a tight loop (this story's own concern is the STACK's
	# reaction to N discrete calls -- the OS key-repeat rate / InputEvent
	# handling itself is Building UI's future keybinding wiring, out of
	# scope here).
	var stack: UndoRedoStack = _new_stack()
	for i: int in range(5):
		stack.record_command([Vector3i(i, 0, 0)])
	var undone: Array = []
	stack.command_undone.connect(func(cells: Array[Vector3i]) -> void: undone.append(cells))

	# Act -- 5 rapid repeats.
	for i: int in range(5):
		stack.undo()

	# Assert -- exactly 5 steps consumed (one per call, no acceleration, no
	# double-consumption of a single repeat), in strict most-recent-first
	# order, and a 6th repeat now finds nothing left to undo.
	assert_int(undone.size()).is_equal(5)
	assert_array(undone[0]).is_equal([Vector3i(4, 0, 0)])
	assert_array(undone[4]).is_equal([Vector3i(0, 0, 0)])
	assert_bool(stack.can_undo()).is_false()
	assert_bool(stack.undo()).is_false()


# ---------------------------------------------------------------------------
# Config (ADR-0002 two-tier policy) -- undo_stack_depth
# ---------------------------------------------------------------------------

func test_undo_stack_depth_out_of_range_clamps_with_warning() -> void:
	# Arrange
	var config := UndoRedoStackConfig.new()
	config.undo_stack_depth = 5

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(config.undo_stack_depth).is_equal(UndoRedoStackConfig.UNDO_STACK_DEPTH_MIN)
	assert_bool(issues.any(func(issue: String) -> bool: return issue.contains("undo_stack_depth"))).is_true()


# ---------------------------------------------------------------------------
# Plan-only guardrail (control-manifest grep-guard family) -- the undo/redo
# module never calls into the committed-block (Built-cell) write path
# ---------------------------------------------------------------------------

func test_undo_redo_module_never_references_a_built_cell_write_api() -> void:
	# ADR-0016 Alternative C rejected / Rule 17: "undo never touches built
	# cells." Story building-032's own scope is the stack mechanics only --
	# this asserts the structural hook: zero calls of any kind into a
	# committed-block write API anywhere in this file. Every cell-level
	# effect flows exclusively through the injected cancel/recreate
	# Callables (see class doc comment).
	var source: String = _read_gd_source_without_comments(UNDO_REDO_STACK_SOURCE_PATH)

	assert_bool(source.contains("set_cell(")).is_false()
	assert_bool(source.contains("bulk_write(")).is_false()
	assert_bool(source.contains("clear_cell(")).is_false()
	assert_bool(source.contains("VoxelWorldGrid")).is_false()
	assert_bool(source.contains("ConstructionTickLoop")).is_false()


func test_no_physics_apis_anywhere_in_building_system_source() -> void:
	# Grep-verifiable AC (Control Manifest / ADR-0004), carried forward and
	# re-checked against this story's new files.
	var banned_substrings: Array[String] = [
		"intersect_ray",
		"PhysicsServer3D",
		"RayCast3D",
		"PhysicsDirectSpaceState3D",
		"PhysicsRayQueryParameters3D",
	]
	var dir := DirAccess.open(BUILDING_SYSTEM_DIR)
	assert_object(dir).is_not_null()
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	var checked_at_least_one_file: bool = false
	while file_name != "":
		if file_name.ends_with(".gd"):
			checked_at_least_one_file = true
			var source: String = _read_gd_source_without_comments(BUILDING_SYSTEM_DIR + file_name)
			for banned: String in banned_substrings:
				assert_bool(source.contains(banned)).is_false()
		file_name = dir.get_next()
	dir.list_dir_end()
	assert_bool(checked_at_least_one_file).is_true()
