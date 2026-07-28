## Camera hosting-layer mirror (Camera & Input epic, story cam-013 --
## "Camera hosting in the shipped scene"; ADR-0001 primary DI shape; ADR-0010
## referenced only to note this introduces NO new input handler anywhere --
## it reads no [InputEvent], listens on neither `_input()` nor
## `_unhandled_input()`, and owns no InputMap action).
##
## Drives a plain, passive [Camera3D] whose identity this class does not
## own -- [member camera] is wired via [Valley]'s own code-assigned
## cross-sibling DI ([method Valley._wire_hosted_modules]), mirroring
## [TorchFlicker]'s already-established "driver [Node] + passive driven
## node" shape exactly ([member camera]/[member camera_input] are both
## Node-typed cross-references, code-assigned, never an Inspector-authored
## `NodePath` literal -- see [Valley]'s own class doc comment for why a
## hand-authored `.tscn` `NodePath` value does not resolve).
##
## Every frame, and once immediately at [method setup] (so the very first
## rendered frame is already correctly framed, before this node's own first
## engine [method _process] callback ever lands), reads [method
## CameraInput.get_camera_position] / [method CameraInput.get_target] and
## writes them onto [member camera]'s [member Node3D.global_position] / via
## [method Node3D.look_at] -- the EXACT relationship
## `tools/camera_sandbox.gd`'s own class doc comment already specifies and
## its own `_process` already implements (a real driven [Camera3D] living in
## a SEPARATE node that mirrors [CameraInput]'s derived state onto its own
## transform every frame), reused here rather than reinvented, per this
## story's own instruction. [member Node3D.global_position] is used
## deliberately, not `position` -- unlike `camera_sandbox.gd`'s own flat
## root-level camera, [member camera] sits one level deeper (a [Valley]-
## hosted child, with [Valley] itself attached under [GameWorld]), so only
## the global-space property is unambiguously correct regardless of any
## parent transform in that chain.
##
## **ONE-WAY ONLY, by construction (AC2/AC3)**: this class only ever WRITES
## to [member camera] and only ever READS from [member camera_input] -- it
## never reads any property of [member camera] back, and [CameraInput]
## itself is never modified by this story: its own class doc comment's "why
## no live Camera3D" rationale (an external Camera3D reading back would be
## an ordering hazard) stays true, unchanged. This is exactly the split AC3
## requires: the mirroring lives in the HOSTING layer -- this class, a
## [Valley]-hosted sibling -- never inside [CameraInput] itself.
##
## **Frame-ordering hazard** (documented, not incidental -- the SAME hazard
## `camera_sandbox.gd`'s own class doc comment already names and fixes):
## [CameraInput]'s own [method Node._process] (WASD pan, story cam-005) must
## already have run THIS frame before this class reads its derived state, or
## a held pan key would visibly lag one frame behind. [constant
## MIRROR_PROCESS_PRIORITY] is applied to [member Node.process_priority] in
## [method setup] -- [CameraInput] is left at the engine default (0), a
## sibling under the SAME [Valley] parent -- so this class's own [method
## _process] is guaranteed to run strictly after [CameraInput]'s every
## frame, exactly mirroring `camera_sandbox.gd`'s own established fix (there
## applied to that tool's own root node; here scoped to ONLY this small
## driver node, leaving [method Valley._process] -- an unrelated, pre-
## existing per-frame concern, vox-018's residency/mesh-window drive --
## completely untouched by this story).
class_name CameraMirror
extends Node

## See class doc comment's own "Frame-ordering hazard" paragraph.
const MIRROR_PROCESS_PRIORITY: int = 1

## The passive, driven [Camera3D] -- code-assigned by [Valley] (Node-typed
## cross-reference, never an Inspector-authored `NodePath`). Owns no config
## and no script of its own; every property this class writes onto it is
## overwritten again the very next frame, so no other write path may safely
## assume a stable value survives between frames.
@export var camera: Camera3D = null

## The hosted [CameraInput] instance this class mirrors FROM, never writes
## to. Code-assigned by [Valley], mirroring [member camera]'s own DI shape.
@export var camera_input: CameraInput = null

## True once [method setup] has completed at least once.
var _is_set_up: bool = false


## Explicitly callable wiring/validation entry point (ADR-0001). Asserts both
## Node-typed dependencies were wired, applies [constant
## MIRROR_PROCESS_PRIORITY] (see class doc comment), and performs the
## initial mirror pass immediately -- so the first rendered frame is already
## correctly framed rather than showing [member camera]'s scene-authored
## default transform for one frame while waiting on the first engine
## [method _process] callback.
func setup() -> void:
	assert(camera != null, "CameraMirror.camera not wired")
	assert(camera_input != null, "CameraMirror.camera_input not wired")
	process_priority = MIRROR_PROCESS_PRIORITY
	_mirror()
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Godot's per-frame engine callback -- mirrors [member camera_input]'s
## derived state onto [member camera] every frame. See class doc comment for
## the full one-way/ordering rationale.
func _process(_delta: float) -> void:
	_mirror()


## The mirror step itself, factored out so [method setup] can also perform it
## once immediately (see that method's own doc comment) without waiting for
## the first engine [method _process] callback.
func _mirror() -> void:
	camera.global_position = camera_input.get_camera_position()
	camera.look_at(camera_input.get_target(), Vector3.UP)
