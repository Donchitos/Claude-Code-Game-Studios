## Interior warm-detail clutter (Presentation Experience story
## presentation-001 Sub-scope A; art-bible SS6.5: "static props" implying
## recent use -- "cheapest possible win," explicitly "no motion cost").
## Instantiates one static [MeshInstance3D] per scene-authored transform in
## [member clutter_transforms] -- a lived-in room's mugs/tools/laundry, per
## the AC's "warm static clutter reads as recently used."
##
## Deliberately NEVER animated (art-bible SS6.5 Notes column: "static
## props"): every spawned [MeshInstance3D] has [method
## Node.set_process]/[method Node.set_physics_process] explicitly forced
## `false` and no [Tween] is ever attached -- this is the class's own
## structural guarantee that "no motion cost" holds, not merely a documented
## intention (see [method get_prop_count]'s doc comment for the test-facing
## surface this backs).
##
## Data-driven placement, not a tuning-config knob (see
## [AmbientLifeConfig]'s doc comment for why): [member clutter_transforms]
## is scene-authored composition data -- a per-room layout, analogous to how
## `Valley.tscn` wires scene-specific structural children directly. There is
## no shared numeric budget here for a [ConfigResource] to own.
##
## [member prop_mesh] defaults to a small placeholder [BoxMesh] (art-bible
## SS6 Texturing note: prop art is deferred; mirrors
## [VoxelWorldMesher.DEBUG_BLOCK_COLORS]'s "flat placeholder, never a
## missing/blocking asset" precedent) when left unassigned -- a later prop-
## authoring story swaps in real mug/tool/laundry meshes without needing any
## change to this class's placement logic.
class_name InteriorClutterPlacer
extends Node3D

## One entry per clutter prop to place, in this node's local space --
## scene-authored (class doc comment). Spawning is fully deterministic:
## the SAME array always produces the SAME spawned transforms, in the SAME
## order, with zero randomness anywhere in [method setup] (coding-standards
## determinism rule, applied here even though this is presentation code, so
## the "determinism of spawn patterns" evidence this story's task calls for
## holds as a provable property, not an eyeballed one).
@export var clutter_transforms: Array[Transform3D] = []

## The prop mesh instantiated at every [member clutter_transforms] entry --
## see class doc comment for the placeholder-default behavior when left
## unassigned.
@export var prop_mesh: Mesh

## True once [method setup] has completed.
var _is_set_up: bool = false

## Every spawned prop [MeshInstance3D], in [member clutter_transforms] order
## -- exposed via [method get_prop_count]/[method get_prop_transform] for
## tests, never mutated after [method setup].
var _prop_nodes: Array[MeshInstance3D] = []


## Explicitly-callable wiring entry point (ADR-0001-style, though this class
## has no cross-module dependency to assert -- it exists purely so the
## established "nothing happens before an explicit setup() call" discipline
## applies uniformly here too). Falls back to a placeholder [BoxMesh] if
## [member prop_mesh] was left unassigned, then spawns one static
## [MeshInstance3D] per [member clutter_transforms] entry.
func setup() -> void:
	var mesh_to_use: Mesh = prop_mesh if prop_mesh != null else _build_placeholder_mesh()
	for prop_transform: Transform3D in clutter_transforms:
		var instance := MeshInstance3D.new()
		instance.mesh = mesh_to_use
		instance.transform = prop_transform
		# "No motion cost" (class doc comment) -- explicit, not merely the
		# default absence of a _process override, so a grep/review check
		# finds the guarantee stated in code, not just implied by omission.
		instance.set_process(false)
		instance.set_physics_process(false)
		add_child(instance)
		_prop_nodes.append(instance)
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Returns the number of spawned clutter props -- always equal to [member
## clutter_transforms].size() after [method setup] (one prop per authored
## transform, never more or fewer).
func get_prop_count() -> int:
	return _prop_nodes.size()


## Returns the WORLD-space transform of the [param index]-th spawned prop --
## test-facing, proves deterministic placement (same input transform in,
## same prop transform out).
func get_prop_transform(index: int) -> Transform3D:
	return _prop_nodes[index].transform


## Returns whether the [param index]-th spawned prop is static (both process
## callbacks disabled) -- the "no motion cost" structural guarantee,
## test-facing.
func is_prop_static(index: int) -> bool:
	var instance: MeshInstance3D = _prop_nodes[index]
	return not instance.is_processing() and not instance.is_physics_processing()


## Builds the placeholder prop mesh used when [member prop_mesh] is left
## unassigned (class doc comment).
func _build_placeholder_mesh() -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.2, 0.2, 0.2)
	return mesh
