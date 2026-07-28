## Building System's undo/redo stack core (Story building-032, ADR-0016
## primary -- "Plan-only undo/redo: the undo stack governs the plan ONLY --
## draft cells and queued orders ... redo re-creates only still-valid
## cells, dropping invalidated ones with feedback." ADR-0012 secondary --
## the undo stack is excluded from serialization, TR-building-system-033).
##
## Models each player command (Core Rule 17: "one wall drag = one command =
## one undo step") as one plain [Array][Vector3i] entry on a bounded LIFO
## undo stack, with a matching LIFO redo stack. This story owns ONLY the
## stack mechanics named by its own Acceptance Criteria:
## - AC30/Edge Case 9: bounded depth (`undo_stack_depth`, default 50) --
##   beyond capacity the oldest command is discarded silently.
## - AC31/Edge Case 9: any new command commit clears the redo branch.
## - AC28/Edge Case 8: redo re-validates every cell of the command
##   independently via [member recreate_cell_callable]; cells that fail are
##   dropped with feedback ([signal redo_cells_dropped]); a redo where ZERO
##   cells survive is a no-op with feedback ([signal redo_no_op]) -- nothing
##   is pushed back onto the undo stack for a fully-dropped redo.
## - AC32/AC32b/Core Rule 17: the stack clears ONLY on [signal
##   GameWorld.transition_ended] with `success == true` (transition-COMPLETE)
##   -- an aborted/failed transition ([param success] `== false`) leaves
##   every command untouched, and [signal GameWorld.transition_begun] is
##   NEVER connected at all, so a begin-signal side effect on the stack is
##   structurally impossible, not merely avoided by a runtime check.
##
## **What this story deliberately does NOT own** (see the story's own Out of
## Scope section):
## - WHICH cells make up a command, and how a cell is actually canceled
##   (undo) or actually re-validated-and-recreated as a fresh blueprint
##   (redo) against [CommitPipeline]/[BuildProject]. That real behavior is
##   this class's own [member cancel_cell_callable]/[member
##   recreate_cell_callable] seam -- `Callable(cell: Vector3i) -> bool`,
##   called once per cell -- mirroring [CommitPipeline]'s own established
##   "future story wires a real Callable into this seam" pattern exactly
##   ([method CommitPipeline.set_cell_set_resolver]/[method
##   CommitPipeline.set_furniture_support_predicate]). Story 011 (the
##   plan-only invariant -- undo never reaches a Built cell) is this seam's
##   real future caller for [member cancel_cell_callable]: it supplies a
##   callable that skips (returns `false`, does nothing) any cell whose
##   [member BlueprintCell.state] is already [constant
##   BlueprintCell.MicroState.BUILT]. Story building-033 (this revision)
##   lands the self-write-exemption / undo-invalidation listener directly on
##   this class -- see the new paragraph below for its shape; Story 011
##   remains the sole future caller of [member cancel_cell_callable] itself.
##   Until it lands, a caller (a headless test, or a future
##   population-assembly story) wires its own callable directly -- exactly
##   how [CommitPipeline]'s own seams are exercised in isolation today.
## - Plan-only enforcement itself. This file's own code contains ZERO
##   references to any committed-block/Voxel-World write API (no
##   [VoxelWorldGrid] call, no [ConstructionTickLoop] call, no `set_cell(`/
##   `bulk_write(`/`clear_cell(` of any kind) -- every cell-level effect
##   this class ever produces flows exclusively through the two injected
##   `Callable`s above (this story's own "plan-only invariant hook,"
##   verified by this story's own grep-guard test). Story 011 constrains
##   WHAT those callables do; this class only guarantees WHERE they are
##   called from, and that nowhere else in this class reaches further.
##
## Story building-033 (this revision, [TR-building-system-071]/
## [TR-building-system-024]) adds the undo-invalidation listener named above
## as a "future caller": this class now optionally subscribes to a write
## source's `cell_changed`/`cells_changed_batch` signals ([member
## voxel_world_write_source] -- deliberately duck-typed, see that member's
## own doc comment for why this file's plan-only-invariant grep-guard forces
## that shape) and tracks which cells a NON-self-originated write touched
## ([member _invalidated_cells]). [method undo] consults that set to skip
## [member cancel_cell_callable] for a cell some other system already
## changed (AC33) -- without ever calling into a write API itself, so this
## file's own "zero references to any committed-block/Voxel-World write API"
## invariant (see the "Plan-only enforcement" bullet above, and the
## grep-guard test that proves it) is completely undisturbed. [member
## write_tag] ([BuildingSystemWriteTag], shared with whichever collaborator
## issues this system's own writes -- today, [ConstructionTickLoop]'s batched
## completion write) is this listener's self-write exemption (AC46): Godot's
## synchronous signal delivery means a shared tag reads `is_active() ==
## true` for the FULL duration of the writer's own call, so this listener
## never invalidates an entry over its own system's writes.
##
## `Node`, not `RefCounted` -- mirrors [ToolStateMachine]'s exact injected-
## tier shape (an OPTIONAL [member game_world] dependency this class itself
## connects to inside [method setup], never asserted non-null, exactly
## [ToolStateMachine]'s own `_connect_transition_signals` guard shape): the
## transition-COMPLETE-only clear rule (AC32/AC32b) needs a live signal
## connection to [signal GameWorld.transition_ended], the same seam
## [ToolStateMachine] already established for its own Suspended entry/exit
## wiring -- this class reuses that exact pattern rather than inventing a
## second one.
class_name UndoRedoStack
extends Node

## Fires on every successful [method undo] (AC held-key-repeat edge case:
## each call is exactly one step) -- carries the UNDONE command's original
## cell list, in commit order, exactly as [method record_command] received
## it. This is the requested cancellation set, not a report of which cells
## [member cancel_cell_callable] actually canceled (that per-cell outcome is
## the callable's own concern, e.g. Story 011's future Built-cell skip).
signal command_undone(cells: Array[Vector3i])

## Fires on every [method redo] call that produces at least one surviving
## cell -- carries the SURVIVING cell subset only (never the original,
## possibly-larger command), exactly as re-created and pushed back onto the
## undo stack as a fresh command.
signal command_redone(cells: Array[Vector3i])

## Fires whenever a [method redo] call drops at least one cell because
## [member recreate_cell_callable] reported it no longer valid (Edge Case 8,
## AC28's "standard invalid-feedback") -- carries only the DROPPED subset.
## Fires alongside [signal command_redone] when some cells survive, and
## alongside [signal redo_no_op] when none do.
signal redo_cells_dropped(cells: Array[Vector3i])

## Fires whenever a [method redo] call ends with ZERO surviving cells (Edge
## Case 8: "a redo where zero cells survive is a no-op with feedback") --
## nothing is pushed back onto the undo stack for this attempt; the popped
## redo entry is fully consumed and discarded.
signal redo_no_op()

## Tuning config dependency (ADR-0002, `undo_stack_depth`,
## [TR-building-system-089]). Wired via a scene file's Inspector in
## production, or assigned directly in a headless test. Never read inside
## `_ready()` -- see [method setup].
@export var config: UndoRedoStackConfig

## Optional injected-tier dependency (ADR-0001), mirroring
## [ToolStateMachine]'s own [member ToolStateMachine.game_world] shape
## exactly: wired via a scene file's Inspector in production once a future
## scene-assembly story attaches this node to `GameWorld.tscn`, or assigned
## directly in a headless test. Deliberately nullable -- a null value MUST
## remain a no-op, exactly as no scene-assembly story has wired a live
## [ToolStateMachine] node yet either.
@export var game_world: GameWorld = null

## Optional injected-tier dependency (ADR-0001), Story building-033
## ([TR-building-system-071]/[TR-building-system-024]) -- the write-signal
## source this system's own undo-invalidation listener subscribes to.
## Deliberately duck-typed against `Object` rather than a typed reference to
## the write-owning class -- this file's own plan-only-invariant grep-guard
## (`undo_redo_stack_core_test.gd`'s
## `test_undo_redo_module_never_references_a_built_cell_write_api`) bans
## referencing that class BY NAME anywhere in this file's CODE (never its
## doc comments) -- this module only ever LISTENS to two of its signals
## (`signal cell_changed(cell: Vector3i, before: CellContents, after:
## CellContents)` / `signal cells_changed_batch(changes:
## Array[CellChangeRecord])`); it never calls into its write API (see class
## doc comment's "Plan-only enforcement" bullet, unaffected by this story).
## Mirrors [ConstructionTickLoop]'s own `time_tick_system: Object`
## duck-typed precedent exactly. Plain `var`, never `@export` -- `Object` is
## not an exportable Inspector type either; code-assigned in production
## (once a future scene-assembly story wires it) or a headless test. A null
## value (the default) is a complete no-op -- every pre-033 caller/test that
## never wires this behaves exactly as before this story.
var voxel_world_write_source: Object = null

## Story building-033 addition ([TR-building-system-024]) -- the shared
## self-write exemption tag. A caller wanting this listener to correctly
## IGNORE a same-system write (e.g. [ConstructionTickLoop]'s own batched
## completion write) MUST assign the IDENTICAL instance to both this field
## and the writer's own matching field (see [BuildingSystemWriteTag]'s own
## class doc comment) -- an isolated test of this class alone that never
## shares its instance anywhere sees every observed write as external,
## which is the correct behavior for that narrower scope. Default-
## constructed in [method setup] if left unwired, mirroring [member config]'s
## own default-construct precedent. Plain `var`, never `@export` --
## `RefCounted` is not an exportable Inspector type.
var write_tag: BuildingSystemWriteTag = null

## Per-cell undo hook (see class doc comment) -- `Callable(cell: Vector3i)
## -> bool`. Default `Callable()` (invalid) is a permissive no-op: [method
## undo] simply skips calling it, mirroring [CommitPipeline]'s own
## `_all_cells_supported`/[member CommitPipeline._furniture_support_predicate]
## "no predicate wired => no restriction" default. Set via [method
## set_cancel_cell_callable].
var cancel_cell_callable: Callable = Callable()

## Per-cell redo re-validation hook (see class doc comment) --
## `Callable(cell: Vector3i) -> bool`, `true` meaning "still valid, recreate
## it," `false` meaning "no longer valid, drop it" (Edge Case 8, AC28).
## Default `Callable()` (invalid) treats every cell as surviving -- there is
## no validity information available at all without a wired callable,
## mirroring the same permissive-default precedent as [member
## cancel_cell_callable]. Set via [method set_recreate_cell_callable].
var recreate_cell_callable: Callable = Callable()

## The undo stack -- each entry is one command's [Array][Vector3i] cell
## list, oldest first ([Array.pop_front] discards the oldest on overflow,
## AC30). The most recent command is [Array.pop_back].
var _undo_stack: Array = []

## The redo stack -- each entry is one command's [Array][Vector3i] cell
## list, most-recently-undone last ([Array.pop_back] is the next [method
## redo] target). Cleared in full by [method record_command] (AC31) and by
## [method clear] (AC32/AC32b) -- never mutated by [method undo] beyond
## appending the command it just popped from [member _undo_stack].
var _redo_stack: Array = []

## True once [method setup] has completed at least once.
var _is_set_up: bool = false

## Cells this listener has observed change via a write [member write_tag]
## did NOT report as self-originated, since this instance was created (Story
## building-033, [TR-building-system-071]) -- [method undo] consults this to
## skip [member cancel_cell_callable] for a cell some other system already
## touched (AC33: "the stale entry is skipped without error or
## double-removal"), rather than attempting to cancel/restore a cell whose
## real Voxel World contents no longer match what this command originally
## produced. Never cleared once set -- an externally-touched cell stays
## "stale" for every future [method undo] call that might reference it, not
## only the first.
var _invalidated_cells: Dictionary[Vector3i, bool] = {}


## Explicitly callable wiring entry point (ADR-0001). Applies ADR-0002's
## clamp+warn `validate()` policy to [member config] (constructing a
## default instance if none was wired, mirroring [ConstructionTickLoop]'s
## own "config is optional at this story's isolated-test scope" tolerance),
## default-constructs [member write_tag] if left unwired (Story
## building-033), and connects to [member game_world]'s transition-COMPLETE
## signal plus [member voxel_world_write_source]'s write signals (idempotent
## via [method Signal.is_connected], mirroring
## [ToolStateMachine._connect_transition_signals]'s exact guard shape).
func setup() -> void:
	if config == null:
		config = UndoRedoStackConfig.new()
	for issue: String in config.validate():
		push_warning(issue)
	if write_tag == null:
		write_tag = BuildingSystemWriteTag.new()
	_connect_transition_signals()
	_connect_voxel_world_write_source_signals()
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Wires [member cancel_cell_callable] (see that member's doc comment) --
## Story 011's real future caller.
func set_cancel_cell_callable(callable: Callable) -> void:
	cancel_cell_callable = callable


## Wires [member recreate_cell_callable] (see that member's doc comment).
func set_recreate_cell_callable(callable: Callable) -> void:
	recreate_cell_callable = callable


## Records a freshly-committed command (Core Rule 17: "one wall drag = one
## command = one undo step") -- [param cells] is the full cell list a single
## commit produced, in commit order. Clears the ENTIRE redo branch first
## (AC31: "any new command commit clears the redo branch"), then pushes the
## command onto the undo stack, discarding the oldest entry if the bounded
## depth ([member UndoRedoStackConfig.undo_stack_depth]) is now exceeded
## (AC30) -- both effects are observed from this ONE call, exactly as the
## story's own Edge Case demands. A future [CommitPipeline]-listening caller
## (not wired by this story) is the intended real caller; directly callable
## by tests in the meantime.
func record_command(cells: Array[Vector3i]) -> void:
	_redo_stack.clear()
	_push_undo(cells)


## Whether at least one command is currently undoable.
func can_undo() -> bool:
	return not _undo_stack.is_empty()


## Whether at least one command is currently redoable.
func can_redo() -> bool:
	return not _redo_stack.is_empty()


## Number of commands currently on the undo stack -- observability/test seam.
func get_undo_stack_size() -> int:
	return _undo_stack.size()


## Number of commands currently on the redo stack -- observability/test seam.
func get_redo_stack_size() -> int:
	return _redo_stack.size()


## Undoes the most recently recorded (or redone) command -- one call is
## exactly one undo step (a held Ctrl+Z key-repeat at OS rate therefore
## consumes exactly one step per repeat event, with neither acceleration nor
## double-consumption of a single repeat, since each repeat is its own
## discrete call into this method). Calls [member cancel_cell_callable] once
## per cell in the popped command, in order, when a callable is wired (a
## no-op skip otherwise) -- see class doc comment for why this is the
## story's own "plan-only invariant hook," not full plan-only enforcement.
## Story building-033 (AC33): a cell already recorded in [member
## _invalidated_cells] (touched by a non-self-originated write since this
## instance was created) is skipped entirely -- [member cancel_cell_callable]
## is never called for it, so a cell some other system already changed is
## never double-processed or erroneously canceled; every OTHER cell of the
## SAME command still cancels normally. Pushes the popped command onto the
## redo stack and fires [signal command_undone] (still carrying the FULL
## original cell list, including any skipped ones -- unchanged from this
## story). Returns `false` (no-op) if the undo stack is empty.
func undo() -> bool:
	if _undo_stack.is_empty():
		return false
	var cells: Array[Vector3i] = _undo_stack.pop_back()
	if cancel_cell_callable.is_valid():
		for cell: Vector3i in cells:
			if _invalidated_cells.has(cell):
				continue
			cancel_cell_callable.call(cell)
	_redo_stack.append(cells)
	command_undone.emit(cells)
	return true


## Redoes the most recently undone command (Edge Case 8, AC28) --
## re-validates EVERY cell of the popped command independently via [member
## recreate_cell_callable] (a cell survives when the callable returns `true`
## or when no callable is wired at all -- see that member's doc comment).
## Cells that fail are dropped: [signal redo_cells_dropped] fires with
## exactly the dropped subset whenever at least one cell was dropped.
## If at least one cell survives, the SURVIVING subset is pushed onto the
## undo stack as a fresh command (subject to the same bounded-depth discard
## as [method record_command]'s own push -- see [method _push_undo]) and
## [signal command_redone] fires with that subset; this does NOT touch the
## redo branch otherwise (only a NEW command via [method record_command]
## clears it, per AC31). If ZERO cells survive, [signal redo_no_op] fires
## instead and nothing is pushed back onto the undo stack -- the popped
## entry is fully consumed and discarded, a genuine no-op (Edge Case 8: "a
## redo where zero cells survive is a no-op with feedback"). Returns `false`
## if the redo stack was empty, or if the redo was a zero-survivor no-op;
## returns `true` only when at least one cell was actually redone.
func redo() -> bool:
	if _redo_stack.is_empty():
		return false
	var cells: Array[Vector3i] = _redo_stack.pop_back()
	var survivors: Array[Vector3i] = []
	var dropped: Array[Vector3i] = []
	for cell: Vector3i in cells:
		var still_valid: bool = true
		if recreate_cell_callable.is_valid():
			still_valid = bool(recreate_cell_callable.call(cell))
		if still_valid:
			survivors.append(cell)
		else:
			dropped.append(cell)
	if not dropped.is_empty():
		redo_cells_dropped.emit(dropped)
	if survivors.is_empty():
		redo_no_op.emit()
		return false
	_push_undo(survivors)
	command_redone.emit(survivors)
	return true


## Clears both stacks in full (Core Rule 17, AC32) -- the ONLY sanctioned
## caller-visible way either stack is emptied outside normal undo/redo
## traffic. Called by [method _on_transition_ended] on transition-COMPLETE
## ([param success] `== true`) ONLY; directly callable by a future
## save/load-adjacent caller if one is ever needed, mirroring this
## codebase's "public method, real caller may not exist yet" precedent.
func clear() -> void:
	_undo_stack.clear()
	_redo_stack.clear()


## Connects this instance to [member game_world]'s transition-COMPLETE
## signal ONLY -- mirrors [ToolStateMachine._connect_transition_signals]'s
## exact idempotent-guard shape, but deliberately connects [signal
## GameWorld.transition_ended] alone. [signal GameWorld.transition_begun] is
## NEVER connected anywhere in this class (AC32b: "no begin-signal side
## effect touched the stack" holds structurally -- there is no handler for
## it to call). A no-op when [member game_world] is null.
func _connect_transition_signals() -> void:
	if game_world == null:
		return
	if not game_world.transition_ended.is_connected(_on_transition_ended):
		game_world.transition_ended.connect(_on_transition_ended)


## Handles [signal GameWorld.transition_ended]. Clears both stacks only when
## [param success] is `true` (transition-COMPLETE, AC32) -- an aborted/
## failed transition ([param success] `== false`, AC32b) is a deliberate
## no-op: every previously recorded command remains exactly as undoable as
## before the transition was even attempted.
func _on_transition_ended(success: bool) -> void:
	if not success:
		return
	clear()


## Connects to [member voxel_world_write_source]'s two write signals (Story
## building-033) -- idempotent via [method Signal.is_connected], mirroring
## [method _connect_transition_signals]'s own exact guard shape. A no-op
## when [member voxel_world_write_source] is null.
func _connect_voxel_world_write_source_signals() -> void:
	if voxel_world_write_source == null:
		return
	@warning_ignore("unsafe_property_access")
	var cell_changed_connected: bool = voxel_world_write_source.cell_changed.is_connected(_on_write_source_cell_changed)
	if not cell_changed_connected:
		@warning_ignore("unsafe_property_access")
		voxel_world_write_source.cell_changed.connect(_on_write_source_cell_changed)
	@warning_ignore("unsafe_property_access")
	var batch_connected: bool = (
		voxel_world_write_source.cells_changed_batch.is_connected(_on_write_source_cells_changed_batch)
	)
	if not batch_connected:
		@warning_ignore("unsafe_property_access")
		voxel_world_write_source.cells_changed_batch.connect(_on_write_source_cells_changed_batch)


## Single-cell write-signal handler (Story building-033,
## [TR-building-system-071]/[TR-building-system-024]) -- self-write exemption
## FIRST (AC46): a write [member write_tag] reports as currently active
## (self-originated) is completely ignored, never invalidating anything.
## Otherwise [param cell] is recorded as invalidated -- see [member
## _invalidated_cells].
func _on_write_source_cell_changed(cell: Vector3i, _before: CellContents, _after: CellContents) -> void:
	if write_tag != null and write_tag.is_active():
		return
	_invalidated_cells[cell] = true


## Batched write-signal handler -- the exact same self-write exemption +
## invalidation as [method _on_write_source_cell_changed], applied to every
## record in [param changes] in one pass (never one handler dispatch per
## cell).
func _on_write_source_cells_changed_batch(changes: Array[CellChangeRecord]) -> void:
	if write_tag != null and write_tag.is_active():
		return
	for record: CellChangeRecord in changes:
		_invalidated_cells[record.cell] = true


## Whether [param cell] has been recorded as invalidated by a non-self write
## since this instance was created (Story building-033) -- observability for
## tests/callers.
func is_cell_invalidated(cell: Vector3i) -> bool:
	return _invalidated_cells.has(cell)


## Shared push helper for [method record_command] and [method redo]'s own
## surviving-cell re-push -- appends [param cells] as a new top-of-stack
## command, then discards the oldest entry if [member
## UndoRedoStackConfig.undo_stack_depth] is now exceeded (AC30, Edge Case
## 9). [method redo] deliberately calls this directly rather than through
## [method record_command], so a successful redo never ALSO clears the
## remaining redo branch (AC31 only fires for a genuinely new command).
func _push_undo(cells: Array[Vector3i]) -> void:
	_undo_stack.append(cells)
	if _undo_stack.size() > config.undo_stack_depth:
		_undo_stack.pop_front()
