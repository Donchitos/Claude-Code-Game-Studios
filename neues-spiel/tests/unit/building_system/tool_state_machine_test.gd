## Unit test — Building System Story building-019 (Tool state machine:
## Idle/ToolArmed/Dragging/Suspended). ADR-0010 primary (Suspended wiring
## shape, drag-ownership guidance); building-system.md Core Rule 1 /
## States-and-Transitions table secondary.
##
## Proves the story's four ACs directly against [ToolStateMachine]'s public
## transition methods -- mirroring this project's established
## direct-method-call test convention (camera_input's
## active_suspended_state_test.gd calls [method CameraInput._unhandled_input]/
## [method GameWorld.begin_transition] directly rather than simulating full
## engine input dispatch). [ToolStateMachine] deliberately exposes no raw
## [InputEvent] handling of its own (see that class's doc comment) -- every
## test here calls its public methods, or drives Suspended via [GameWorld]'s
## existing [signal GameWorld.transition_begun]/
## [signal GameWorld.transition_ended] contract surface, exactly like
## camera_input's own story cam-007 suite. Signal-capture assertions use the
## established `Array[...]` + `.append()` idiom throughout (never a scalar
## incremented inside a lambda -- GDScript captures scalars by value, not by
## reference; see transition_contract_surface_test.gd's documented pitfall).
##
## 1. AC2 [TR-building-system-042]: arming Tool B while Tool A is armed
##    deactivates A and arms B -- exactly one tool is ever active.
## 2. AC3 [TR-building-system-042]: cancel (right-click/Esc) from ToolArmed
##    returns to Idle with the ghost hidden.
## 3. AC37 [TR-building-system-067]: Suspended entered mid-drag aborts the
##    drag with no commit and no partial blueprint.
## 4. AC44 [TR-building-system-067]: a different tool selected mid-drag
##    aborts the drag with no commit.
class_name ToolStateMachineTest
extends GdUnitTestSuite


func _new_machine() -> ToolStateMachine:
	return auto_free(ToolStateMachine.new())


## Returns a [ToolStateMachine] wired to a bare [GameWorld] (mirrors
## camera_input's `active_suspended_state_test.gd`
## `_new_wired_camera()` helper exactly) -- no scene tree, no boot gate
## involved: [method GameWorld.begin_transition]/[method GameWorld.end_transition]
## touch neither [enum GameWorld.BootState] nor `resource_item_database`.
func _new_wired_machine() -> ToolStateMachine:
	var world: GameWorld = auto_free(GameWorld.new())
	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())
	machine.game_world = world
	machine.setup()
	return machine


# ---------------------------------------------------------------------------
# AC2 -- exactly one tool active at a time [TR-building-system-042]
# ---------------------------------------------------------------------------

func test_arming_a_tool_from_idle_enters_tool_armed() -> void:
	# Arrange
	var machine: ToolStateMachine = _new_machine()

	# Act
	machine.arm_tool(&"wall")

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.TOOL_ARMED)
	assert_str(String(machine.get_armed_tool())).is_equal("wall")


func test_arming_tool_b_while_tool_a_armed_deactivates_a_and_arms_b() -> void:
	# Arrange
	var machine: ToolStateMachine = _new_machine()
	machine.arm_tool(&"wall")

	# Act
	machine.arm_tool(&"floor")

	# Assert -- never two active tools; the single armed-tool field is the
	# structural guarantee this holds by construction.
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.TOOL_ARMED)
	assert_str(String(machine.get_armed_tool())).is_equal("floor")


func test_arming_tool_b_over_tool_a_fires_tool_armed_signal_with_b() -> void:
	# Arrange
	var machine: ToolStateMachine = _new_machine()
	var received: Array[StringName] = []
	machine.tool_armed.connect(func(tool_id: StringName) -> void: received.append(tool_id))
	machine.arm_tool(&"wall")
	received.clear()

	# Act
	machine.arm_tool(&"floor")

	# Assert
	assert_array(received).is_equal([&"floor"])


# ---------------------------------------------------------------------------
# AC3 -- cancel returns to Idle, ghost hidden [TR-building-system-042]
# ---------------------------------------------------------------------------

func test_cancel_from_tool_armed_returns_to_idle_with_no_tool_armed() -> void:
	# Arrange
	var machine: ToolStateMachine = _new_machine()
	machine.arm_tool(&"wall")

	# Act
	machine.cancel()

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.IDLE)
	assert_str(String(machine.get_armed_tool())).is_equal("")


func test_cancel_from_tool_armed_hides_the_ghost() -> void:
	# Arrange
	var machine: ToolStateMachine = _new_machine()
	machine.arm_tool(&"wall")
	assert_bool(machine.is_ghost_visible()).is_true()
	var received: Array[bool] = []
	machine.ghost_visibility_changed.connect(func(is_visible: bool) -> void: received.append(is_visible))

	# Act
	machine.cancel()

	# Assert
	assert_bool(machine.is_ghost_visible()).is_false()
	assert_int(received.size()).is_equal(1)
	assert_bool(received[0]).is_false()


func test_cancel_from_idle_is_a_noop() -> void:
	# Arrange -- Story 001's further "Esc exits Build Mode itself" link is a
	# separate, out-of-scope concern layered above this no-op.
	var machine: ToolStateMachine = _new_machine()
	var state_changes: Array[int] = []
	machine.state_changed.connect(
		func(_old_state: ToolStateMachine.State, new_state: ToolStateMachine.State) -> void:
			state_changes.append(new_state)
	)

	# Act
	machine.cancel()

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.IDLE)
	assert_array(state_changes).is_empty()


# ---------------------------------------------------------------------------
# AC37 -- Suspended entered mid-drag aborts, no commit, no partial blueprint
# [TR-building-system-067]
# ---------------------------------------------------------------------------

func test_suspended_entered_mid_drag_aborts_the_drag_exactly_once() -> void:
	# Arrange
	var machine: ToolStateMachine = _new_machine()
	machine.arm_tool(&"wall")
	machine.start_drag()
	var aborted_calls: Array[int] = []
	machine.drag_aborted.connect(func() -> void: aborted_calls.append(1))

	# Act
	machine.enter_suspended()

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.SUSPENDED)
	assert_int(aborted_calls.size()).is_equal(1)


func test_suspended_entered_mid_drag_leaves_no_tool_armed_and_hides_ghost() -> void:
	# Arrange -- "no partial blueprint": this class holds no draft/pending
	# geometry of its own, so the strongest structural proof available here
	# is that nothing is left armed/pending that could later resolve into a
	# write.
	var machine: ToolStateMachine = _new_machine()
	machine.arm_tool(&"wall")
	machine.start_drag()

	# Act
	machine.enter_suspended()

	# Assert
	assert_str(String(machine.get_armed_tool())).is_equal("")
	assert_bool(machine.is_ghost_visible()).is_false()


func test_suspended_entered_from_tool_armed_without_a_drag_does_not_abort() -> void:
	# Arrange -- Suspended can be entered with a tool merely armed, not
	# dragging; drag_aborted must fire only when a drag was actually
	# in progress.
	var machine: ToolStateMachine = _new_machine()
	machine.arm_tool(&"wall")
	var aborted_calls: Array[int] = []
	machine.drag_aborted.connect(func() -> void: aborted_calls.append(1))

	# Act
	machine.enter_suspended()

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.SUSPENDED)
	assert_int(aborted_calls.size()).is_equal(0)


func test_resume_after_suspended_mid_drag_returns_to_idle_not_stuck_dragging() -> void:
	# Arrange -- QA note: "an aborted drag leaves the tool SM in a clean
	# armed/idle state, not stuck in Dragging."
	var machine: ToolStateMachine = _new_machine()
	machine.arm_tool(&"wall")
	machine.start_drag()
	machine.enter_suspended()

	# Act
	machine.exit_suspended()

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.IDLE)
	assert_str(String(machine.get_armed_tool())).is_equal("")


func test_suspended_wired_via_game_world_transition_begun() -> void:
	# Arrange -- mirrors camera_input's own story cam-007 wiring: this class
	# connects itself to game_world's signals inside its own setup().
	var machine: ToolStateMachine = _new_wired_machine()
	machine.arm_tool(&"wall")
	machine.start_drag()

	# Act
	machine.game_world.begin_transition()

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.SUSPENDED)


func test_suspended_wired_via_game_world_transition_ended_returns_to_idle_on_abort() -> void:
	# Arrange -- mirrors camera_input's "abort must never strand a consumer
	# in Suspended" precedent: both success and abort resolve identically.
	var machine: ToolStateMachine = _new_wired_machine()
	machine.arm_tool(&"wall")
	machine.game_world.begin_transition()

	# Act
	machine.game_world.end_transition(false)

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.IDLE)


func test_suspended_wired_via_game_world_transition_ended_returns_to_idle_on_success() -> void:
	# Arrange
	var machine: ToolStateMachine = _new_wired_machine()
	machine.arm_tool(&"wall")
	machine.game_world.begin_transition()

	# Act
	machine.game_world.end_transition(true)

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.IDLE)


func test_setup_called_twice_with_game_world_wired_does_not_double_connect() -> void:
	# Arrange -- [method ToolStateMachine._connect_transition_signals]'s
	# is_connected() guard must make a repeated setup() call idempotent.
	var world: GameWorld = auto_free(GameWorld.new())
	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())
	machine.game_world = world
	machine.setup()
	machine.setup()

	# Act
	world.begin_transition()

	# Assert -- reaching this line without a duplicate-connection error
	# proves idempotence; the state change itself still happened exactly
	# once (a double connection would still leave the enum at SUSPENDED, so
	# this alone would not catch a double-fire -- the real proof is that no
	# "already connected" engine error occurs during setup()).
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.SUSPENDED)


func test_setup_without_game_world_wired_does_not_raise_and_stays_idle() -> void:
	# Arrange -- mirrors GameWorld.valley_scene / CameraInput.game_world's own
	# "deliberately optional" precedent: pre-existing callers that never wire
	# game_world must continue to construct/setup unaffected.
	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())

	# Act
	machine.setup()

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.IDLE)
	assert_bool(machine.is_set_up()).is_true()


# ---------------------------------------------------------------------------
# AC44 -- another tool selected mid-drag aborts, no commit
# [TR-building-system-067]
# ---------------------------------------------------------------------------

func test_selecting_another_tool_mid_drag_aborts_the_drag_exactly_once() -> void:
	# Arrange
	var machine: ToolStateMachine = _new_machine()
	machine.arm_tool(&"wall")
	machine.start_drag()
	var aborted_calls: Array[int] = []
	machine.drag_aborted.connect(func() -> void: aborted_calls.append(1))

	# Act
	machine.arm_tool(&"floor")

	# Assert
	assert_int(aborted_calls.size()).is_equal(1)


func test_selecting_another_tool_mid_drag_arms_the_new_tool_not_stuck_dragging() -> void:
	# Arrange -- QA note: "not stuck in Dragging."
	var machine: ToolStateMachine = _new_machine()
	machine.arm_tool(&"wall")
	machine.start_drag()

	# Act
	machine.arm_tool(&"floor")

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.TOOL_ARMED)
	assert_str(String(machine.get_armed_tool())).is_equal("floor")


func test_selecting_the_same_tool_mid_drag_still_aborts() -> void:
	# Arrange -- Core Rule 1 draws no distinction between "another" and "the
	# same" tool identity; re-arming while Dragging is still "activating a
	# tool," which unconditionally aborts.
	var machine: ToolStateMachine = _new_machine()
	machine.arm_tool(&"wall")
	machine.start_drag()
	var aborted_calls: Array[int] = []
	machine.drag_aborted.connect(func() -> void: aborted_calls.append(1))

	# Act
	machine.arm_tool(&"wall")

	# Assert
	assert_int(aborted_calls.size()).is_equal(1)
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.TOOL_ARMED)


func test_arm_tool_while_suspended_is_a_noop() -> void:
	# Arrange -- all interaction halted during Suspended.
	var machine: ToolStateMachine = _new_machine()
	machine.enter_suspended()

	# Act
	machine.arm_tool(&"wall")

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.SUSPENDED)
	assert_str(String(machine.get_armed_tool())).is_equal("")


# ---------------------------------------------------------------------------
# Drag lifecycle -- start/complete guards (supporting coverage; not a
# dedicated AC, but load-bearing for AC37/AC44's "was actually dragging"
# preconditions).
# ---------------------------------------------------------------------------

func test_start_drag_from_tool_armed_enters_dragging() -> void:
	# Arrange
	var machine: ToolStateMachine = _new_machine()
	machine.arm_tool(&"wall")

	# Act
	machine.start_drag()

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.DRAGGING)


func test_start_drag_from_idle_is_a_noop() -> void:
	# Arrange
	var machine: ToolStateMachine = _new_machine()

	# Act
	machine.start_drag()

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.IDLE)


func test_complete_drag_returns_to_tool_armed_with_the_same_tool_still_armed() -> void:
	# Arrange -- GDD Core Rule 2's repeatable pick -> preview -> commit
	# pipeline: the tool stays armed for the next placement.
	var machine: ToolStateMachine = _new_machine()
	machine.arm_tool(&"wall")
	machine.start_drag()

	# Act
	machine.complete_drag()

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.TOOL_ARMED)
	assert_str(String(machine.get_armed_tool())).is_equal("wall")


func test_complete_drag_from_tool_armed_is_a_noop() -> void:
	# Arrange
	var machine: ToolStateMachine = _new_machine()
	machine.arm_tool(&"wall")

	# Act
	machine.complete_drag()

	# Assert
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.TOOL_ARMED)


func test_ghost_visible_while_tool_armed_and_while_dragging() -> void:
	# Arrange
	var machine: ToolStateMachine = _new_machine()

	# Act + Assert
	machine.arm_tool(&"wall")
	assert_bool(machine.is_ghost_visible()).is_true()
	machine.start_drag()
	assert_bool(machine.is_ghost_visible()).is_true()


func test_ghost_hidden_in_idle_and_suspended() -> void:
	# Arrange
	var machine: ToolStateMachine = _new_machine()

	# Act + Assert
	assert_bool(machine.is_ghost_visible()).is_false()
	machine.enter_suspended()
	assert_bool(machine.is_ghost_visible()).is_false()
