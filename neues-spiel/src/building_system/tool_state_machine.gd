## Building System's tool state machine skeleton (Story building-019, ADR-0010
## primary -- drag-ownership/input-arbitration guidance this story's Control
## Manifest rules cite; ADR-0016 secondary -- the persistent Build Project
## entity this SM's future Dragging/commit boundary will feed, not built
## here).
##
## Owns exactly the four-state machine the GDD's "Tool state machine" table
## specifies -- Idle / ToolArmed / Dragging / Suspended
## [TR-building-system-042] [TR-building-system-067] -- and nothing else. Per
## this story's explicit Out of Scope: the outer Build Mode On/Off gate and
## the Esc chain's final link (Story 001), ghost preview RENDERING (Story
## 023 -- this class only signals show/hide via
## [signal ghost_visibility_changed]), per-tool drag/commit geometry (Stories
## 024-028), and placement picking / the actual drag-threshold pixel
## calculation (GDD Formula F4, Story 020) are all NOT implemented here.
## Callers (those later stories) drive this machine exclusively through its
## public transition methods below -- this class deliberately never reads a
## raw [InputEvent] or the [Input] singleton itself, sidestepping this
## project's established "headless Input polling is unreliable" pitfall by
## construction rather than by a workaround; Story 020's placement pick owns
## the actual `_unhandled_input()`/`_input()` listening (ADR-0010's
## drag-ownership switch) and calls into [method start_drag]/
## [method complete_drag] once it has resolved a real pick.
##
## Core Rule 1 [TR-building-system-042]: exactly one tool is ever active;
## activating a tool deactivates the previous one; cancel (right-click/Esc)
## returns to no-tool (Idle). GDD States-and-Transitions table
## [TR-building-system-067]: entering Suspended or switching tools mid-drag
## aborts the drag WITHOUT commit -- no partial blueprint is ever created by
## an aborted drag. This class has no concept of "commit" at all yet
## (Stories 020/021 own the write-path) -- "no commit" holds here
## structurally, by the simple fact that aborting a drag never calls
## anything resembling a write.
##
## Suspended (ADR-0010 Decision "Enters Suspended with it"; GDD Interactions
## with Other Systems: "tool state machine suspends via Camera & Input's
## Suspended state") mirrors [CameraInput]'s own established story cam-007
## wiring shape exactly: an OPTIONAL injected-tier [member game_world]
## dependency (ADR-0001), connected to [signal GameWorld.transition_begun]/
## [signal GameWorld.transition_ended] inside this class's own [method setup]
## -- [GameWorld] never calls into any consumer directly, by construction
## (that class's own doc comment). Resuming (Suspended -> exit) always
## resolves to [constant State.IDLE] with no tool armed, never silently
## re-arming whatever was active before suspension -- a deliberate,
## documented interpretation where the GDD does not fully specify a resume
## target (this SM's OWN internal safe default, not a claim about Story
## 001's separate Build Mode on/off persistence, which is out of scope here).
##
## Ghost visibility ([signal ghost_visibility_changed]) is a pure derived
## flag -- visible in ToolArmed/Dragging, hidden in Idle/Suspended -- so
## Story 023's ghost renderer has a single boolean contract to react to
## rather than re-deriving "should the ghost show" from raw state itself.
class_name ToolStateMachine
extends Node

## The four-state tool machine (GDD "Tool state machine" table,
## [TR-building-system-042] [TR-building-system-067]). Exactly these four and
## no others.
enum State {
	IDLE,
	TOOL_ARMED,
	DRAGGING,
	SUSPENDED,
}

## Story scene-007 addition (Open Decision 2, producer recommendation (a)):
## the armed-tool id vocabulary [member _armed_tool_id] already stores as an
## opaque [StringName] -- named here, ONCE, so scene-007's armed-tool ->
## resolver router (and any future Building UI caller) shares one canonical
## spelling instead of re-inventing bare literals per call site. Before this
## story these ids existed ONLY as bare string literals inside test files
## (`gameworld_e2e_loop_test.gd`, `block_tool_test.gd`,
## `build_editor_mode_test.gd`, `commit_pipeline_test.gd`) -- this is their
## first production-code owner. This class owns [member _armed_tool_id]'s
## vocabulary already, which is why the ids live here rather than on
## [BuildEditorMode] (Option (b), not chosen) or as bare literals in
## `valley.gd` (Option (c), not chosen).
const TOOL_ID_WALL: StringName = &"wall"
const TOOL_ID_FLOOR: StringName = &"floor"
const TOOL_ID_ROOF: StringName = &"roof"
const TOOL_ID_BLOCK: StringName = &"block"
const TOOL_ID_FURNITURE: StringName = &"furniture"

## Fires whenever [enum State] actually changes value (never a redundant
## re-fire for a same-enum-value call, e.g. re-arming a different tool while
## already [constant State.TOOL_ARMED] -- see [signal tool_armed] for that
## case instead).
signal state_changed(old_state: State, new_state: State)

## Fires whenever the ARMED TOOL identity is (re-)set via [method arm_tool]
## (AC2's "Tool A deactivates, B arms" case) -- distinct from
## [signal state_changed], which does not fire when the enum value itself is
## unchanged (ToolArmed -> ToolArmed).
signal tool_armed(tool_id: StringName)

## Fires exactly once whenever an in-progress drag is aborted without commit
## [TR-building-system-067] -- Suspended entry mid-drag (AC37), another tool
## selected mid-drag (AC44), or cancel mid-drag. Downstream stories
## (020/024-028) that track pending pick/preview state observe this to
## discard it; this class holds no such state itself to discard.
signal drag_aborted()

## Fires whenever the derived ghost-visibility flag changes (see class doc
## comment) -- Story 023's sole render-facing contract from this class.
signal ghost_visibility_changed(is_visible: bool)

## Optional injected-tier dependency (ADR-0001), mirroring [CameraInput]'s
## own story cam-007 [member CameraInput.game_world] shape exactly: wired via
## a scene file's Inspector in production once Story 001 assembles Building
## System into `GameWorld.tscn`, or assigned directly in a headless test.
## Deliberately nullable -- no scene-assembly story has wired a live
## [ToolStateMachine] node yet, so a null value MUST remain a no-op.
@export var game_world: GameWorld = null

## Current state. Read-only from outside this class -- see [method get_state].
var _state: State = State.IDLE

## Opaque armed-tool identifier (ADR-0006's opaque-id convention) -- empty
## (`&""`) whenever no tool is armed ([constant State.IDLE] or
## [constant State.SUSPENDED]). Read-only from outside this class -- see
## [method get_armed_tool].
var _armed_tool_id: StringName = &""

## Derived ghost-visibility flag -- true in ToolArmed/Dragging, false in
## Idle/Suspended. Mirrored 1:1 by [signal ghost_visibility_changed]; never
## diverges from [method _ghost_should_be_visible]'s derivation for the
## current [member _state].
var _ghost_visible: bool = false

## True once [method setup] has completed at least once.
var _is_set_up: bool = false


## Explicitly callable wiring entry point (ADR-0001). Connects this instance
## to [member game_world]'s transition signals when wired (idempotent via
## [method Signal.is_connected], mirroring
## [method CameraInput._connect_transition_signals]'s exact guard shape) --
## a no-op otherwise. No config Resource to validate at this story's scope --
## no tuning knob is introduced by the state machine itself (the first one,
## `drag_threshold_px`, arrives with Story 020's placement pick).
func setup() -> void:
	_connect_transition_signals()
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Connects this instance to [member game_world]'s transition-signal contract
## surface, mirroring [CameraInput]'s established story cam-007 wiring. A
## no-op when [member game_world] is null. Guards each connection with
## [method Signal.is_connected] so a repeated [method setup] call never
## double-connects.
func _connect_transition_signals() -> void:
	if game_world == null:
		return
	if not game_world.transition_begun.is_connected(_on_transition_begun):
		game_world.transition_begun.connect(_on_transition_begun)
	if not game_world.transition_ended.is_connected(_on_transition_ended):
		game_world.transition_ended.connect(_on_transition_ended)


## Handles [signal GameWorld.transition_begun]: enters Suspended
## (ADR-0010, "tool state machine suspends via Camera & Input's Suspended
## state").
func _on_transition_begun() -> void:
	enter_suspended()


## Handles [signal GameWorld.transition_ended]: exits Suspended regardless of
## [param success] -- transition-complete and transition-abort release
## Suspended identically, mirroring [CameraInput]'s "never complete alone"
## precedent (an aborted transition must never strand this system in
## Suspended).
func _on_transition_ended(_success: bool) -> void:
	exit_suspended()


## Returns the current state.
func get_state() -> State:
	return _state


## Returns the currently armed tool id, or `&""` if none is armed
## ([constant State.IDLE] or [constant State.SUSPENDED]).
func get_armed_tool() -> StringName:
	return _armed_tool_id


## Returns the derived ghost-visibility flag (see class doc comment).
func is_ghost_visible() -> bool:
	return _ghost_visible


## Arms [param tool_id], deactivating whatever was previously armed -- Core
## Rule 1's "exactly one tool active at a time" [TR-building-system-042]. A
## no-op while [constant State.SUSPENDED] (all interaction halted). Called
## while already [constant State.TOOL_ARMED] switches the armed tool directly
## (AC2); called while [constant State.DRAGGING] aborts the in-progress drag
## first, without commit, THEN arms the new tool (AC44,
## [TR-building-system-067]) -- both are the same "activating a tool
## deactivates the previous one" rule, applied uniformly regardless of
## whether the previous tool was merely armed or mid-drag.
func arm_tool(tool_id: StringName) -> void:
	if _state == State.SUSPENDED:
		return
	if _state == State.DRAGGING:
		drag_aborted.emit()
	_armed_tool_id = tool_id
	tool_armed.emit(tool_id)
	_set_state(State.TOOL_ARMED)


## Cancels the current tool interaction (right-click/Esc), returning to
## [constant State.IDLE] with no tool armed and the ghost hidden (AC3,
## [TR-building-system-042]). Aborts an in-progress drag first, without
## commit, if called while [constant State.DRAGGING]
## [TR-building-system-067]. A no-op from [constant State.IDLE] (nothing to
## cancel -- Story 001's further "Esc exits Build Mode itself" link is a
## separate, out-of-scope concern layered above this no-op) or
## [constant State.SUSPENDED] (all interaction halted).
func cancel() -> void:
	if _state == State.IDLE or _state == State.SUSPENDED:
		return
	if _state == State.DRAGGING:
		drag_aborted.emit()
	_armed_tool_id = &""
	_set_state(State.IDLE)


## Transitions [constant State.TOOL_ARMED] -> [constant State.DRAGGING] (drag
## threshold reached, GDD Formula F4 -- computed by Story 020, not here). A
## no-op from any other state (only a validly armed tool can start a drag).
func start_drag() -> void:
	if _state != State.TOOL_ARMED:
		return
	_set_state(State.DRAGGING)


## Transitions [constant State.DRAGGING] -> [constant State.TOOL_ARMED] on a
## successful release/commit (Story 021's write-path is a separate concern;
## this class only owns the STATE transition, not the write). The same tool
## remains armed afterward, ready for the next pick/drag (GDD Core Rule 2's
## repeatable pick -> preview -> commit pipeline). A no-op from any other
## state.
func complete_drag() -> void:
	if _state != State.DRAGGING:
		return
	_set_state(State.TOOL_ARMED)


## Enters [constant State.SUSPENDED] (Camera & Input's Suspended state,
## scene transition -- ADR-0010, "tool state machine suspends via Camera &
## Input's Suspended state"). Aborts an in-progress drag first, without
## commit, if called while [constant State.DRAGGING] (AC37,
## [TR-building-system-067]). Idempotent -- a no-op if already Suspended.
## Clears the armed tool immediately -- all interaction halted; nothing is
## armed while Suspended, matching the ghost-hidden derivation.
func enter_suspended() -> void:
	if _state == State.SUSPENDED:
		return
	if _state == State.DRAGGING:
		drag_aborted.emit()
	_armed_tool_id = &""
	_set_state(State.SUSPENDED)


## Exits [constant State.SUSPENDED] back to [constant State.IDLE] (Camera &
## Input reactivates). Always resolves to Idle with no tool armed -- a
## deliberate, documented default (see class doc comment) since the GDD does
## not specify re-arming whatever was active before suspension. A no-op if
## not currently Suspended.
func exit_suspended() -> void:
	if _state != State.SUSPENDED:
		return
	_set_state(State.IDLE)


## Single state-write choke point: updates [member _state], fires
## [signal state_changed] only when the value actually changes, and
## re-derives/fires [signal ghost_visibility_changed] only when THAT flag
## actually changes -- never a redundant re-fire of either signal.
func _set_state(new_state: State) -> void:
	var old_state: State = _state
	_state = new_state
	if old_state != new_state:
		state_changed.emit(old_state, new_state)
	var should_be_visible: bool = ToolStateMachine._ghost_should_be_visible(new_state)
	if should_be_visible != _ghost_visible:
		_ghost_visible = should_be_visible
		ghost_visibility_changed.emit(_ghost_visible)


## Pure derivation: the ghost previews only while a tool is armed or a drag
## is in progress (Story 023's contract point -- see class doc comment).
## Stateless -- exercisable directly with an arbitrary [enum State] value.
static func _ghost_should_be_visible(state: State) -> bool:
	return state == State.TOOL_ARMED or state == State.DRAGGING
