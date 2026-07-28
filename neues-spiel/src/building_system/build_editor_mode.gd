## Building System's outer Build/Editor Mode gate (Story building-001,
## ADR-0010 primary -- Build-Mode-gated click routing + Esc chain guidance;
## ADR-0016 secondary -- the persistent Build Project entity the tools this
## gate arms eventually feed, not touched here).
##
## Wraps the already-landed [ToolStateMachine] (Story building-019 -- its own
## doc comment explicitly defers "the outer Build Mode On/Off gate and the
## Esc chain's final link" to this story) with exactly the two-state gate the
## GDD's "Build Mode state machine" table specifies: `Off` (boot default) /
## `On` [TR-building-system-102] [TR-building-system-103]
## [TR-building-system-104] [TR-building-system-105]. This class never
## re-implements [ToolStateMachine]'s own four states -- it only decides
## whether that machine is reachable at all.
##
## **Rule 8a/8d -- Off is fully inert** [TR-building-system-102]
## [TR-building-system-105]: none of the six tools can be armed and no ghost
## preview exists while Off; world clicks are NOT consumed by this system at
## all -- they belong to villager/project selection per Camera & Input's
## ADR-0010 arbitration (Story 008's own separate concern, the sole
## exception being a project-cell click, also Story 008). This holds
## structurally rather than via a second gate here: [ToolStateMachine] can
## only ever reach [constant ToolStateMachine.State.TOOL_ARMED]/
## [constant ToolStateMachine.State.DRAGGING] through THIS class's
## [method arm_tool] (which always enters On FIRST, see below) -- provided
## every future caller arms tools exclusively through this class rather than
## [member tool_state_machine] directly (a documented contract, not a
## compiler-enforced one; [ToolStateMachine] itself is Story 019's own
## already-landed public class and stays unmodified per this story's Out of
## Scope). Under that contract, Off structurally implies
## [constant ToolStateMachine.State.IDLE], and [PlacementPick] (Story 020)
## already gates its own `_unhandled_input` press handling AND its per-frame
## hover-pick/ghost-highlight on exactly that state -- so "no tool, ghost, or
## commit is reachable" while Off holds transitively, with zero gating logic
## duplicated in this class or in a raw `_unhandled_input` override here.
##
## **Rule 8b -- entry/exit** [TR-building-system-103]: entered via
## [method enter_build_mode] (the explicit UI toggle -- Building UI's own
## widget, this story's Out of Scope) OR via [method arm_tool] (arming any
## tool auto-enters On first, one player action, AC52). Exited ONLY via
## [method exit_build_mode] (explicit toggle off) or [method handle_escape]'s
## final chain link (Rule 8c) -- never as a side effect of a single tool
## deactivation: [ToolStateMachine.cancel]'s existing Dragging/ToolArmed ->
## Idle collapse never, by itself, touches [member _mode] -- only a FURTHER
## [method handle_escape] call while already at
## [constant ToolStateMachine.State.IDLE] does.
##
## **Rule 8c -- layered Esc chain** [TR-building-system-104] (AC53): Build
## Mode is always the LAST link. A single [method handle_escape] call
## resolves AT MOST one step, never two in the same press:
## - Off -> no-op (nothing to close).
## - On, with [member tool_state_machine] NOT at
##   [constant ToolStateMachine.State.IDLE] (ToolArmed or Dragging) ->
##   delegates to the existing, UNCHANGED [method ToolStateMachine.cancel]
##   only -- Build Mode remains On. (Dragging and ToolArmed both resolve
##   through this SAME existing call, exactly like the GDD's own "(existing
##   Tool state machine)" / "(existing Rule, unchanged)" parentheticals
##   describe -- this story does not add a second Dragging-only step.)
## - On, with [member tool_state_machine] AT
##   [constant ToolStateMachine.State.IDLE] (no tool armed) -> a FURTHER Esc
##   exits Build Mode itself via [method exit_build_mode] (Rule 8d), handing
##   world clicks back to selection.
##
## Building UI's own story-002 four-step chain (HUD focus, tool, Selection,
## WorldNav) layers additional steps ON TOP of what this class owns -- this
## class only owns the two steps Building System itself is responsible for
## (the tool/drag layer, already-existing; the Build Mode layer, new here).
##
## **Ownership**: this story's own header text is explicit -- "Building UI
## exposes the interaction mode; Building System owns the mode state."
## [member _mode] is the single source of truth; Building UI (Story
## building-ui-002) mirrors it via [method get_mode]/[method is_on], exactly
## like it already mirrors [ToolStateMachine]'s armed-tool state via
## [signal ToolStateMachine.tool_armed]/[signal ToolStateMachine.state_changed]
## rather than latching a local copy of its own.
class_name BuildEditorMode
extends Node

## The outer Build Mode gate (GDD "Build Mode state machine" table, Rule
## 8a-8d). Exactly these two and no others -- the four-state
## [ToolStateMachine] underneath is a separate, already-landed machine this
## class wraps, never re-implements.
enum Mode {
	OFF,
	ON,
}

## Fires whenever [enum Mode] actually changes value -- never a redundant
## re-fire for a same-value call (e.g. [method enter_build_mode] while
## already On, or arming a second tool while already On, AC52's edge case),
## mirroring [signal ToolStateMachine.state_changed]'s own "only on actual
## change" contract exactly.
signal mode_changed(old_mode: Mode, new_mode: Mode)

## Injected-tier dependency (ADR-0001) -- the four-state tool machine (Story
## building-019) this class wraps and drives via
## [method ToolStateMachine.arm_tool]/[method ToolStateMachine.cancel]. Never
## re-implemented here; wired via a scene file's Inspector in production
## (once a future scene-assembly story attaches this node) or assigned
## directly in a headless test.
@export var tool_state_machine: ToolStateMachine

## Current gate value. Read-only from outside this class -- see
## [method get_mode].
var _mode: Mode = Mode.OFF

## True once [method setup] has completed at least once.
var _is_set_up: bool = false


## Explicitly callable wiring/validation entry point (ADR-0001). Asserts
## [member tool_state_machine] was wired -- a MANDATORY dependency (unlike
## [ToolStateMachine]'s own optional `game_world`): this class has nothing
## meaningful to gate without a tool machine to wrap.
func setup() -> void:
	assert(tool_state_machine != null, "BuildEditorMode.tool_state_machine not wired")
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Returns the current gate value ([constant Mode.OFF] is the boot default
## and the Esc chain's final-link target, Rule 8d [TR-building-system-105]).
func get_mode() -> Mode:
	return _mode


## Convenience predicate -- `true` iff [method get_mode] == [constant Mode.ON].
func is_on() -> bool:
	return _mode == Mode.ON


## Explicit UI toggle ON (Rule 8b) -- Building UI's own widget calls this
## (the widget itself is this story's Out of Scope). A no-op (no
## [signal mode_changed] re-fire) if already On.
func enter_build_mode() -> void:
	_set_mode(Mode.ON)


## Explicit UI toggle OFF (Rule 8b), or the Esc chain's final link (Rule 8c)
## via [method handle_escape]. Forces [member tool_state_machine] back to
## [constant ToolStateMachine.State.IDLE] FIRST via
## [method ToolStateMachine.cancel] -- a no-op there if it is already Idle or
## Suspended -- so a tool/drag can never survive Build Mode closing (AC54:
## "no tool, ghost, or commit is reachable" while Off). A no-op if already
## Off.
func exit_build_mode() -> void:
	if _mode == Mode.OFF:
		return
	tool_state_machine.cancel()
	_set_mode(Mode.OFF)


## Arms [param tool_id] -- auto-entering Build Mode FIRST if currently Off, in
## the same call (Rule 8b, AC52: "one player action"), then unconditionally
## delegating to [method ToolStateMachine.arm_tool]. Arming a second tool
## while already On does not re-toggle the mode (AC52's edge case) --
## [method _set_mode]'s own "only on actual change" guard makes this hold
## without a separate branch here.
func arm_tool(tool_id: StringName) -> void:
	enter_build_mode()
	tool_state_machine.arm_tool(tool_id)


## The layered Esc chain's entry point (Rule 8c, AC53) -- resolves AT MOST
## ONE step per call:
## - Off -> no-op (nothing to close; AC53's "Esc while already Off" edge
##   case).
## - On, with [member tool_state_machine] NOT at
##   [constant ToolStateMachine.State.IDLE] (ToolArmed or Dragging) ->
##   delegates to the existing [method ToolStateMachine.cancel] only; Build
##   Mode remains On. Returns immediately afterward -- never falls through to
##   also check Idle in the same call.
## - On, with [member tool_state_machine] AT
##   [constant ToolStateMachine.State.IDLE] (no tool armed) -> a FURTHER Esc
##   exits Build Mode itself via [method exit_build_mode] (which itself calls
##   [method ToolStateMachine.cancel] again -- a no-op from Idle, see that
##   method's own doc comment).
## A single call never resolves two chain links: the tool/drag branch and the
## Build Mode branch below are mutually exclusive, never both taken in one
## call (see class doc comment).
func handle_escape() -> void:
	if _mode == Mode.OFF:
		return
	if tool_state_machine.get_state() != ToolStateMachine.State.IDLE:
		tool_state_machine.cancel()
		return
	exit_build_mode()


## Single mode-write choke point: updates [member _mode] and fires
## [signal mode_changed] only when the value actually changes -- never a
## redundant re-fire, mirroring
## [method ToolStateMachine._set_state]'s identical "only on actual change"
## precedent.
func _set_mode(new_mode: Mode) -> void:
	var old_mode: Mode = _mode
	_mode = new_mode
	if old_mode != new_mode:
		mode_changed.emit(old_mode, new_mode)
