## Unit test — Building System Story building-001 (Build/Editor Mode gate:
## Off/On, wrapping the already-landed [ToolStateMachine]). ADR-0010 primary
## (Build-Mode-gated click routing/Esc chain guidance); building-system.md
## Rule 8a-8d secondary.
##
## Proves the story's four ACs directly against [BuildEditorMode]'s public
## transition methods -- mirroring this project's established
## direct-method-call test convention (tool_state_machine_test.gd calls
## [ToolStateMachine]'s public methods directly rather than simulating full
## engine input dispatch; [BuildEditorMode] itself deliberately owns no raw
## [InputEvent] handling of its own, exactly like the class it wraps). Signal-
## capture assertions use the established `Array[...]` + `.append()` idiom
## throughout (never a scalar incremented inside a lambda -- GDScript
## captures scalars by value, not by reference).
##
## 1. AC52 [TR-building-system-102] [TR-building-system-103]: arming a tool
##    from Off auto-enters Build Mode and arms the tool in one call; arming a
##    second tool while already On does not re-toggle the mode.
## 2. AC53 [TR-building-system-104]: the layered Esc chain -- Dragging/
##    ToolArmed -> Idle (mode stays On), Idle -> Off; a single call never
##    crosses two links.
## 3. AC54 [TR-building-system-105]: while Off, [ToolStateMachine] stays Idle
##    (structurally, no tool/ghost/commit reachable) -- [PlacementPick]'s own
##    established suite (dda_placement_pick_test.gd
##    `test_idle_state_always_resolves_to_a_miss_regardless_of_the_ray`,
##    Story 020) already proves Idle never resolves a pick or handles input;
##    this story's own contract is that [method BuildEditorMode.arm_tool] is
##    the ONLY path that can move [ToolStateMachine] out of Idle, and it
##    always enters On first -- so Off implies Idle transitively, with no
##    second gate duplicated here.
## 4. Default post-boot state is Off; state after the Esc chain's final link
##    is Off.
class_name BuildEditorModeTest
extends GdUnitTestSuite


func _new_gate() -> BuildEditorMode:
	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())
	var gate: BuildEditorMode = auto_free(BuildEditorMode.new())
	gate.tool_state_machine = machine
	gate.setup()
	return gate


# ---------------------------------------------------------------------------
# Boot default + is_set_up (supporting coverage for the "Off is the default
# state after boot" requirement, TR-building-system-105)
# ---------------------------------------------------------------------------

func test_default_mode_after_construction_is_off() -> void:
	# Arrange + Act
	var gate: BuildEditorMode = _new_gate()

	# Assert
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.OFF)
	assert_bool(gate.is_on()).is_false()
	assert_bool(gate.is_set_up()).is_true()


# ---------------------------------------------------------------------------
# AC52 -- auto-enter Build Mode on tool arm [TR-building-system-102]
# [TR-building-system-103]
# ---------------------------------------------------------------------------

func test_arming_a_tool_from_off_enters_build_mode_and_arms_the_tool_in_one_call() -> void:
	# Arrange
	var gate: BuildEditorMode = _new_gate()

	# Act
	gate.arm_tool(&"wall")

	# Assert -- one call, no intermediate (On, no tool) state observable from
	# outside since both writes happen synchronously before returning.
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.ON)
	assert_int(gate.tool_state_machine.get_state()).is_equal(ToolStateMachine.State.TOOL_ARMED)
	assert_str(String(gate.tool_state_machine.get_armed_tool())).is_equal("wall")


func test_arming_a_tool_from_off_fires_mode_changed_exactly_once() -> void:
	# Arrange
	var gate: BuildEditorMode = _new_gate()
	var received: Array[Array] = []
	gate.mode_changed.connect(
		func(old_mode: BuildEditorMode.Mode, new_mode: BuildEditorMode.Mode) -> void:
			received.append([old_mode, new_mode])
	)

	# Act
	gate.arm_tool(&"wall")

	# Assert
	assert_int(received.size()).is_equal(1)
	assert_int(received[0][0]).is_equal(BuildEditorMode.Mode.OFF)
	assert_int(received[0][1]).is_equal(BuildEditorMode.Mode.ON)


func test_arming_a_second_tool_while_already_on_does_not_retoggle_the_mode() -> void:
	# Arrange
	var gate: BuildEditorMode = _new_gate()
	gate.arm_tool(&"wall")
	var received: Array[Array] = []
	gate.mode_changed.connect(
		func(old_mode: BuildEditorMode.Mode, new_mode: BuildEditorMode.Mode) -> void:
			received.append([old_mode, new_mode])
	)

	# Act
	gate.arm_tool(&"floor")

	# Assert -- mode was already On; no redundant re-fire.
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.ON)
	assert_array(received).is_empty()
	assert_str(String(gate.tool_state_machine.get_armed_tool())).is_equal("floor")


func test_arming_while_already_on_leaves_the_tool_armed_same_as_arming_from_off() -> void:
	# Arrange -- "arming from Off vs from On both leave the tool armed."
	var gate: BuildEditorMode = _new_gate()
	gate.enter_build_mode()

	# Act
	gate.arm_tool(&"wall")

	# Assert
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.ON)
	assert_int(gate.tool_state_machine.get_state()).is_equal(ToolStateMachine.State.TOOL_ARMED)


# ---------------------------------------------------------------------------
# AC53 -- layered Esc chain [TR-building-system-104]
# ---------------------------------------------------------------------------

func test_escape_from_dragging_aborts_the_drag_and_build_mode_stays_on() -> void:
	# Arrange -- On + Dragging.
	var gate: BuildEditorMode = _new_gate()
	gate.arm_tool(&"wall")
	gate.tool_state_machine.start_drag()
	assert_int(gate.tool_state_machine.get_state()).is_equal(ToolStateMachine.State.DRAGGING)

	# Act
	gate.handle_escape()

	# Assert -- drag aborted (existing Tool state machine behavior, unchanged
	# by this story); Build Mode remains On -- a single press never also
	# closes Build Mode.
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.ON)
	assert_int(gate.tool_state_machine.get_state()).is_equal(ToolStateMachine.State.IDLE)


func test_escape_from_tool_armed_returns_to_idle_and_build_mode_stays_on() -> void:
	# Arrange -- On + ToolArmed (no drag).
	var gate: BuildEditorMode = _new_gate()
	gate.arm_tool(&"wall")

	# Act
	gate.handle_escape()

	# Assert
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.ON)
	assert_int(gate.tool_state_machine.get_state()).is_equal(ToolStateMachine.State.IDLE)
	assert_str(String(gate.tool_state_machine.get_armed_tool())).is_equal("")


func test_escape_from_idle_no_tool_exits_build_mode_to_off() -> void:
	# Arrange -- On + Idle, no tool armed (a further Esc, chain's last link).
	var gate: BuildEditorMode = _new_gate()
	gate.enter_build_mode()
	assert_int(gate.tool_state_machine.get_state()).is_equal(ToolStateMachine.State.IDLE)

	# Act
	gate.handle_escape()

	# Assert
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.OFF)


func test_a_single_escape_never_crosses_two_links_dragging_to_off_takes_two_presses() -> void:
	# Arrange -- On + Dragging; proves the full chain requires exactly two
	# presses to reach Off, never one.
	var gate: BuildEditorMode = _new_gate()
	gate.arm_tool(&"wall")
	gate.tool_state_machine.start_drag()

	# Act -- first press: only the tool/drag layer resolves.
	gate.handle_escape()

	# Assert -- still On after press 1.
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.ON)
	assert_int(gate.tool_state_machine.get_state()).is_equal(ToolStateMachine.State.IDLE)

	# Act -- second press: now Idle, so this one closes Build Mode.
	gate.handle_escape()

	# Assert
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.OFF)


func test_escape_while_already_off_is_a_noop() -> void:
	# Arrange
	var gate: BuildEditorMode = _new_gate()
	var received: Array[Array] = []
	gate.mode_changed.connect(
		func(old_mode: BuildEditorMode.Mode, new_mode: BuildEditorMode.Mode) -> void:
			received.append([old_mode, new_mode])
	)

	# Act
	gate.handle_escape()

	# Assert
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.OFF)
	assert_array(received).is_empty()


# ---------------------------------------------------------------------------
# AC54 -- no world-click consumption while Off [TR-building-system-105]
# ---------------------------------------------------------------------------

func test_build_mode_off_leaves_tool_state_machine_idle_with_no_tool_armed_and_no_ghost() -> void:
	# Arrange + Act
	var gate: BuildEditorMode = _new_gate()

	# Assert -- structural proof: [ToolStateMachine] can only leave Idle via
	# this class's own [method arm_tool], which always enters On first (see
	# class doc comment) -- so Off implies Idle, no tool armed, no ghost.
	# [PlacementPick]'s own established suite (Story 020) already proves Idle
	# never resolves a pick or marks a world press handled; this class adds
	# no second gate duplicating that proof.
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.OFF)
	assert_int(gate.tool_state_machine.get_state()).is_equal(ToolStateMachine.State.IDLE)
	assert_str(String(gate.tool_state_machine.get_armed_tool())).is_equal("")
	assert_bool(gate.tool_state_machine.is_ghost_visible()).is_false()


func test_exit_build_mode_forces_an_armed_tool_back_to_idle_no_tool_survives_off() -> void:
	# Arrange -- On + ToolArmed; the explicit UI toggle turns Build Mode off
	# directly (not via the Esc chain).
	var gate: BuildEditorMode = _new_gate()
	gate.arm_tool(&"wall")

	# Act
	gate.exit_build_mode()

	# Assert -- AC54: no tool survives Build Mode closing.
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.OFF)
	assert_int(gate.tool_state_machine.get_state()).is_equal(ToolStateMachine.State.IDLE)
	assert_str(String(gate.tool_state_machine.get_armed_tool())).is_equal("")


func test_exit_build_mode_forces_a_drag_in_progress_back_to_idle_no_commit_survives_off() -> void:
	# Arrange -- On + Dragging.
	var gate: BuildEditorMode = _new_gate()
	gate.arm_tool(&"wall")
	gate.tool_state_machine.start_drag()
	var aborted_calls: Array[int] = []
	gate.tool_state_machine.drag_aborted.connect(func() -> void: aborted_calls.append(1))

	# Act
	gate.exit_build_mode()

	# Assert -- the drag is aborted, never committed, before Off takes effect.
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.OFF)
	assert_int(gate.tool_state_machine.get_state()).is_equal(ToolStateMachine.State.IDLE)
	assert_int(aborted_calls.size()).is_equal(1)


func test_state_after_the_escape_chains_final_link_is_off() -> void:
	# Arrange -- boot default is already Off (see the dedicated boot-default
	# test); this proves the OTHER stated path to Off -- reaching it via the
	# chain rather than never having left it.
	var gate: BuildEditorMode = _new_gate()
	gate.enter_build_mode()

	# Act
	gate.handle_escape()

	# Assert
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.OFF)


# ---------------------------------------------------------------------------
# Supporting coverage -- enter/exit_build_mode idempotence (load-bearing for
# AC52/53's "only on actual change" guarantees above)
# ---------------------------------------------------------------------------

func test_enter_build_mode_while_already_on_does_not_refire_mode_changed() -> void:
	# Arrange
	var gate: BuildEditorMode = _new_gate()
	gate.enter_build_mode()
	var received: Array[Array] = []
	gate.mode_changed.connect(
		func(old_mode: BuildEditorMode.Mode, new_mode: BuildEditorMode.Mode) -> void:
			received.append([old_mode, new_mode])
	)

	# Act
	gate.enter_build_mode()

	# Assert
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.ON)
	assert_array(received).is_empty()


func test_exit_build_mode_while_already_off_does_not_refire_mode_changed() -> void:
	# Arrange
	var gate: BuildEditorMode = _new_gate()
	var received: Array[Array] = []
	gate.mode_changed.connect(
		func(old_mode: BuildEditorMode.Mode, new_mode: BuildEditorMode.Mode) -> void:
			received.append([old_mode, new_mode])
	)

	# Act
	gate.exit_build_mode()

	# Assert
	assert_int(gate.get_mode()).is_equal(BuildEditorMode.Mode.OFF)
	assert_array(received).is_empty()
