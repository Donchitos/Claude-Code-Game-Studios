## Scaffold presentation tier (story `building-034`, TD ruling D2 --
## "Building System owns a pooled presentation tier. Visual identity LEFT TO
## THE USER."). Mirrors [GhostPreview]'s own `_blueprint_ghost_pool` shape
## exactly: `Dictionary[Vector3i, MeshInstance3D]`, pooled (created/hidden
## rather than freed), driven by [signal ScaffoldRegistry.scaffold_changed]
## with a full RE-ENUMERATION every time -- never a signal-payload read.
##
## **Material tier is distinct from a ghost** (D2, binding): scaffolding is
## built, REAL geometry, not a preview -- it must never reuse the
## translucent ghost tint, or the player would read it as "planned" and
## expect it to become a wall. The material this class ships is a
## deliberately plain, OPAQUE placeholder -- visible and legible, but
## explicitly marked provisional below. **"Renders as nothing" is forbidden
## and is not among the options** -- this class guarantees a scaffold cell
## is never invisible.
##
## **LEFT TO THE USER**: silhouette, material, colour, whether it reads as
## timber poles, planks, or a lashed frame. This class constrains only WHERE
## the pixels come from (a pooled per-cell mesh tier), never WHAT they look
## like -- swap [member provisional_material] for the real art direction the
## moment it exists, with zero structural change to this class.
##
## Named escape hatch (D2, not built now): if concurrent scaffold cell count
## ever exceeds 256, switch to a single `MultiMesh` instance -- at the
## cantilever-bounded sizes this story can produce, pooled instances stay far
## inside the 2000-draw-call budget.
class_name ScaffoldPresentation
extends Node3D

## Scaffold occupancy dependency (duck-typed `Object`, mirrors [member
## VillagerAi.scaffold_registry]'s own typing) -- the SAME [ScaffoldRegistry]
## instance [ConstructionTickLoop.scaffold_registry] routes completions
## through. Wired code-side (ADR-0001 injected-tier); [method setup]
## subscribes to its [signal ScaffoldRegistry.scaffold_changed].
var scaffold_registry: Object = null

## Cell size, matching [constant VoxelWorldConfig.CELL_SIZE] -- duplicated
## here only as a `BoxMesh` dimension default; callers may override via
## [member provisional_material]'s own box size at construction if the real
## cell size ever differs (kept simple deliberately -- this is a PLACEHOLDER
## tier, TD ruling D2).
const CELL_SIZE: float = 1.0

## PROVISIONAL placeholder material (D2: "LEFT TO THE USER... my ruling
## constrains only where the pixels come from, not what they look like").
## Opaque (never the ghost's translucent preview tint, D2 Forbids), a plain
## flat colour chosen only to read as clearly artificial/temporary --
## replace the moment real art direction exists.
var provisional_material: StandardMaterial3D = null

## Pooled per-cell mesh instances, keyed by cell -- created once per cell,
## hidden (never freed) when a cell stops being scaffold, shown again if the
## SAME cell becomes scaffold again later. Mirrors [GhostPreview]'s own
## `_blueprint_ghost_pool` shape and reuse discipline exactly.
var _pool: Dictionary[Vector3i, MeshInstance3D] = {}

var _is_set_up: bool = false


## Explicitly callable wiring/validation entry point (ADR-0001). Subscribes
## to [member scaffold_registry]'s change signal (idempotent-guarded, mirrors
## [CommitPipeline]'s own `is_connected` guard precedent) and performs one
## initial full sync, so a presentation wired onto an ALREADY-populated
## registry (e.g. after a save/load) starts correctly rendered rather than
## waiting for the next change.
func setup() -> void:
	if scaffold_registry != null:
		@warning_ignore("unsafe_property_access")
		if not scaffold_registry.scaffold_changed.is_connected(_on_scaffold_changed):
			@warning_ignore("unsafe_property_access")
			scaffold_registry.scaffold_changed.connect(_on_scaffold_changed)
	if provisional_material == null:
		provisional_material = _make_provisional_material()
	_resync_all()
	_is_set_up = true


func is_set_up() -> bool:
	return _is_set_up


## [signal ScaffoldRegistry.scaffold_changed] handler -- re-enumerates
## CURRENT membership rather than trusting [param _cell] as authoritative
## snapshot data (D2/ADR-0007 §2b's own "consumers re-enumerate, never read
## the payload" discipline).
func _on_scaffold_changed(_cell: Vector3i) -> void:
	_resync_all()


## Full reconciliation pass: every currently-scaffold cell gets a visible
## pooled instance (created if new, shown if previously hidden); every
## pooled instance whose cell is NO LONGER scaffold is hidden (never freed --
## pooling discipline).
func _resync_all() -> void:
	if scaffold_registry == null:
		return
	@warning_ignore("unsafe_method_access")
	var current_cells: Array[Vector3i] = scaffold_registry.get_cells()
	var current_set: Dictionary[Vector3i, bool] = {}
	for cell: Vector3i in current_cells:
		current_set[cell] = true
		var instance: MeshInstance3D = _pool.get(cell)
		if instance == null:
			instance = _create_pooled_instance(cell)
			_pool[cell] = instance
		instance.visible = true
	for cell: Vector3i in _pool:
		if not current_set.has(cell):
			_pool[cell].visible = false


func _create_pooled_instance(cell: Vector3i) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(CELL_SIZE, CELL_SIZE, CELL_SIZE)
	instance.mesh = box
	instance.material_override = provisional_material
	instance.position = VoxelWorldGrid.cell_to_world(cell)
	add_child(instance)
	return instance


func _make_provisional_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.85, 0.55, 0.15, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	return material


## Read-only observability for tests -- the number of currently-VISIBLE
## pooled instances (i.e. currently-scaffold cells this tier is presenting).
func get_visible_count() -> int:
	var count: int = 0
	for cell: Vector3i in _pool:
		if _pool[cell].visible:
			count += 1
	return count
