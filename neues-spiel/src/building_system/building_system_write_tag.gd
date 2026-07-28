## Building System's self-write reentrancy tag (Story building-033,
## TR-building-system-024, ADR-0016 primary; ADR-0009's "Godot signals fire
## synchronously" fact is load-bearing here).
##
## A tiny, depth-counted marker shared between whichever Building System
## collaborator ISSUES a Voxel World write on this system's own behalf
## (today: [ConstructionTickLoop]'s batched job-completion write; a future
## demolition-completion write is expected to reuse the SAME instance rather
## than invent a second tag) and [UndoRedoStack]'s own undo-invalidation
## listener, which consults [method is_active] the instant its
## `cell_changed`/`cells_changed_batch` handler fires. Godot's default
## synchronous signal delivery means that handler runs INSIDE the writer's
## own call stack, so the depth counter is guaranteed still elevated when the
## listener checks it (TR-building-system-024: "Godot signals fire
## synchronously, so unwinding a command would otherwise re-enter the
## listener mid-unwind"). A depth COUNTER (not a plain bool) tolerates
## nested/reentrant self-writes without one prematurely clearing on top of
## another (defensive; no landed caller nests today).
##
## Deliberately a plain, unshared-by-default [RefCounted] -- NOT an Autoload
## (ADR-0001: "use sparingly, only for truly global systems"; this is a
## two-collaborator wiring seam, not a global system) -- whichever code
## assembles the Building System's tier constructs ONE instance and assigns
## the SAME reference to both the writer's own tag field (e.g. [member
## ConstructionTickLoop.write_tag]) and [member UndoRedoStack.write_tag]; a
## test wires it identically (see `voxel_write_seam_test.gd`). A collaborator
## that never receives a shared instance default-constructs its own private
## one (in its own `setup()`), so every existing pre-story caller/test that
## never wires this at all behaves exactly as before -- self-tagging a write
## no one is listening for is a complete no-op.
class_name BuildingSystemWriteTag
extends RefCounted

## Reentrancy depth -- see class doc comment. `0` means no self-originated
## write is currently in progress.
var _depth: int = 0


## Marks the start of a self-originated Voxel World write. Call [method end]
## exactly once for every [method begin] call, ideally bracketing the write
## itself directly (never leave one open past its own call).
func begin() -> void:
	_depth += 1


## Marks the end of a self-originated Voxel World write -- see [method
## begin]. Floors at `0` defensively (an unmatched [method end] call never
## goes negative).
func end() -> void:
	_depth = maxi(_depth - 1, 0)


## Whether a self-originated write is CURRENTLY in progress (i.e. at least
## one [method begin] call has not yet been matched by [method end]) --
## checked synchronously by a write-signal listener while still inside the
## writer's own call stack.
func is_active() -> bool:
	return _depth > 0
