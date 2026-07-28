## Per-placed-furniture-item world-space view (Presentation Experience story
## presentation-005, F7 -- "a built bed becomes visible"). One instance per
## [FurnitureRegistry] record, created and freed by [FurniturePresenter] --
## mirrors [VillagerBodyView]'s own landed per-entity presenter precedent
## (story presentation-003), the ONLY landed render-mechanism precedent this
## codebase has for a placed simulation entity's visual (Open Decision D11,
## sprint-12.md: MultiMesh vs per-item [MeshInstance3D] -- followed here
## without a new TD ruling, per the sprint's own "follow precedent, record
## the choice" resolution; see this story's own Context section).
##
## STATIC, not a mirror (unlike [VillagerBodyView]'s per-frame position
## read): a placed furniture item never moves once built. [method
## position_over_footprint] runs exactly once, at creation, from the
## record's own occupied cells. This class has no [method Node._process] at
## all.
##
## READ-ONLY BY CONSTRUCTION (BV-1, ADR-0016): this class holds no reference
## to [FurnitureRegistry] and calls no method on it whatsoever --
## [FurniturePresenter] resolves the item's [Mesh] and world position and
## hands them to [method set_visual]/[method position_over_footprint]. BV-1's
## prohibition on furniture reaching [VoxelWorldGrid] -- and, by the same
## logic, on presentation ever writing back into [FurnitureRegistry] -- holds
## by construction here: there is nothing on this class capable of writing
## anywhere.
##
## TRAP (control manifest / presentation-003 precedent, TRAP 2): this class
## never reads, writes, or emits anything Selection-related -- a furniture
## view is presentation only, exactly like [VillagerBodyView]'s own rule.
## Out of scope, deliberately: no hit/pick proxy, no [Area3D], no
## `collision_layer` -- nothing in this milestone's scope asks a player to
## click a placed bed yet (this story's own Out of Scope section).
class_name FurnitureView
extends Node3D

## The placed item's own identity (matches [FurnitureRegistry]'s own
## `item_id`/`definition_id` record shape) -- observability/test seam, never
## read by this class itself.
var item_id: String = ""
var definition_id: StringName = &""

## The occupied cells this view represents (footprint, e.g. 2 cells for a
## bed) -- set once by [method position_over_footprint], never mutated
## afterward.
var cells: Array[Vector3i] = []

var _mesh_instance: MeshInstance3D


## Builds the (initially meshless) child [MeshInstance3D] -- headless-safe,
## mirrors [VillagerBodyView]'s own "correct from construction" precedent.
func _init() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "Mesh"
	add_child(_mesh_instance)


## Assigns [param mesh] ([method ItemDefinition.get_visual_asset]'s typed
## [Mesh] -- ADR-0006, never a path string) and repositions the child
## [MeshInstance3D] so the mesh's own bottom face rests at this view's local
## origin (y = 0) and its footprint is horizontally centered on local x/z --
## computed from the mesh's REAL [method Mesh.get_aabb], never a hardcoded
## per-item constant, so any authored mesh (not only a centered [BoxMesh])
## rests correctly regardless of its own pivot. A `null` [param mesh] is
## inert (mirrors [VillagerBodyView]'s own "nil-safe, never crashes"
## precedent) -- [FurniturePresenter] never hands this a null mesh in
## practice ([ResourceItemDatabase]'s own `visual_asset != null` boot
## invariant guarantees every Ready-state definition carries one), but a
## headless unit test may exercise the inert path directly.
func set_visual(mesh: Mesh) -> void:
	_mesh_instance.mesh = mesh
	if mesh == null:
		return
	var local_aabb: AABB = mesh.get_aabb()
	var center: Vector3 = local_aabb.get_center()
	_mesh_instance.position = Vector3(-center.x, -local_aabb.position.y, -center.z)


## Sets this view's own [member Node3D.global_position] to the horizontal
## center and floor level of [param footprint_cells] -- the average of every
## occupied cell's [method VoxelWorldGrid.cell_to_world] center on x/z (so a
## multi-cell footprint, e.g. the bed's `Vector2i(1, 2)`, sits centered
## across every occupied cell, never offset toward one), and the LOWEST
## cell's own floor (cell center minus half a [constant
## VoxelWorldConfig.CELL_SIZE]) on y -- the same "bottom of the occupied
## cell" convention [method set_visual] aligns the mesh's own bottom
## against. Called exactly once, at creation ([FurniturePresenter]'s own
## class doc comment) -- a placed item is static, so there is no per-frame
## re-derivation. A `null`/empty [param footprint_cells] is inert (no-op,
## never a crash) -- [FurnitureRegistry.place] itself asserts a non-empty
## cells array, so this is a defensive guard for a direct/test call only.
func position_over_footprint(footprint_cells: Array[Vector3i]) -> void:
	cells = footprint_cells.duplicate()
	if footprint_cells.is_empty():
		return
	var sum_x: float = 0.0
	var sum_z: float = 0.0
	var min_floor_y: float = INF
	for cell: Vector3i in footprint_cells:
		var world_center: Vector3 = VoxelWorldGrid.cell_to_world(cell)
		sum_x += world_center.x
		sum_z += world_center.z
		var floor_y: float = world_center.y - 0.5 * VoxelWorldConfig.CELL_SIZE
		min_floor_y = minf(min_floor_y, floor_y)
	var count: float = float(footprint_cells.size())
	global_position = Vector3(sum_x / count, min_floor_y, sum_z / count)


## Returns the child [MeshInstance3D] -- test/observability seam.
func get_mesh_instance() -> MeshInstance3D:
	return _mesh_instance
