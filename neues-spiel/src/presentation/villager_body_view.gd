## Per-villager placeholder 3D body (Presentation Experience story
## presentation-003, VB-1 §§1-6 -- the substrate three other epics are
## blocked on: `villager-info-ui-002`/`005`/`006` and `building-ui-016`'s
## "characters" clause). One instance per villager, created and freed by
## [VillagerBodyPresenter].
##
## PURE MIRROR (ADR-0009, one writer/N readers/zero copies): this class
## stores NO position of its own and performs NO interpolation of its own --
## [method _process] assigns [member Node3D.global_position] from
## [member ai_source]'s own already-interpolated visual position directly,
## every frame, pull-only, EXACTLY (never approximately -- grep-verifiable:
## this file contains no interpolation call of its own). The interpolation
## itself stays exactly where ADR-0009 put it (`VillagerAi._process`) --
## this class only ever re-reads the result.
##
## [member ai_source] is a duck-typed, nil-safe [Object] (this codebase's
## established DI precedent: `needs_provider`/`job_queue`/`population`) --
## exactly four members are read: `get_visual_position() -> Vector3`,
## `get_current_cell() -> Vector3i`, `get_state() -> int`, and
## `get_last_micro_behavior() -> Variant` (Presentation Experience story
## presentation-001 Sub-B's idle-behaviour hook, [method _apply_idle_pose] --
## the state read was this class's own previously-RESERVED seam; it is now
## acted on, exactly as reserved).
##
## Idle-behaviour presentation (VB-1's sibling story, presentation-001 Sub-B,
## Art Bible §5.6 / GDD Rule 7c): while [member ai_source] reports
## `State.WANDERING` (the STATIONARY half of Story villager-ai-019's F3/Rule
## 7c pick -- `WALK`/`BED_DRIFT` are `State.TRAVELING` instead, see that
## story's own doc comments) AND the most recent
## [enum VillagerWanderSelector.MicroBehavior] draw is `SIT` or `PAUSE_LOOK`,
## [method _apply_idle_pose] applies a fixed, static local-space offset to
## the placeholder figure's own child meshes -- never a Tween, never a
## per-frame accumulator, never a wall-clock read. This is presentation OF
## existing state only: both reads are pure observability seams already
## landed on [VillagerAi] (Story villager-ai-019), nothing here writes back
## into it, and the poses never touch this view's own
## `position`/`global_position` -- the pure-mirror invariant above stays
## exactly as story presentation-003 established it.
##
## A `null` [member ai_source] is inert -- [method _process]
## and [method set_slice_level] both no-op rather than crash.
##
## Geometry (VB-1 §3): a placeholder 2-cell-tall figure (Art Bible §5.2) --
## a box body + box head at roughly the 45:55 split, one flat
## [StandardMaterial3D] per villager (so the accent-hue channel has
## somewhere to live later). Placeholder ONLY -- art-bible-faithful geometry
## (limb blocks, profession trim, the accent palette) is explicitly Out of
## Scope for this story.
##
## Hit proxy (VB-1 §4, ADR-0004): a child [VillagerHitProxy] moves with this
## view for free -- a click lands where the player SEES the villager, not
## where its discrete `current_cell` is mid-transit.
##
## Slice View (VB-1 §5): [method set_slice_level] applies
## `visible = ai.get_current_cell().y <= level` -- the DISCRETE cell, never
## the interpolated position, so a villager never flickers mid-transit at
## the cutoff boundary. TRAP 1 (control manifest): hiding ALSO zeroes the
## hit proxy's `collision_layer` -- Godot does NOT disable an [Area3D]'s
## collision just because an ancestor's `visible` went false. TRAP 2: this
## class never reads, writes, or emits anything Selection-related --
## slicing away a selected villager must leave Selection untouched
## (`building-ui-016` AC65's precondition).
##
## `IconAnchor` (a named child [Node3D] at the top of the figure) is the
## anchor `villager-info-ui-005`'s billboard manager parents to / reads a
## world position from -- a surface only, no billboard logic lives here.
##
## [method set_highlight] is a stable seam `villager-info-ui-006` +
## `godot-shader-specialist` bind their actual outline treatment to later --
## this story owes a surface, not a finished treatment (a state getter is
## enough).
class_name VillagerBodyView
extends Node3D

## Which villager this view mirrors. Matches its [VillagerHitProxy] child's
## own `villager_id`.
var villager_id: int = 0

## Duck-typed, nil-safe AI source (class doc comment). Assigned by
## [VillagerBodyPresenter] at creation time; a headless test may assign a
## small mock object directly, exactly like every other landed DI seam in
## this codebase.
var ai_source: Object = null

## Hover/selection highlight seam (VB-1 §6) -- treatment deliberately Out of
## Scope; only the state itself is tracked here.
enum HighlightMode {
	NONE,
	HOVER,
	SELECTED,
}

## Placeholder figure proportions (Art Bible §5.2: "~45:55" head:body split
## of a 2-cell-tall figure). Body first (feet at local y = 0), head stacked
## directly above it -- combined span is exactly 2.0 world units (2 cells,
## [constant VoxelWorldConfig.CELL_SIZE] == 1.0), asserted by [method
## get_figure_aabb], never eyeballed.
const BODY_HEIGHT: float = 1.1
const HEAD_HEIGHT: float = 0.9
const FIGURE_WIDTH: float = 0.6
const HEAD_WIDTH: float = 0.7

## Small vertical clearance above the figure's own top for `IconAnchor`
## (VB-1 §6: "local y ≈ 2.0 plus a small clearance").
const ICON_ANCHOR_CLEARANCE: float = 0.2

## Idle-behaviour pose constants (presentation-001 Sub-B, class doc comment).
## Fixed static offsets -- never animated/tweened -- applied by [method
## _apply_idle_pose] only while [enum VillagerWanderSelector.MicroBehavior]
## is `PAUSE_LOOK`/`SIT` AND [member ai_source] reports `State.WANDERING`.
## `PAUSE_LOOK_HEAD_TILT` tilts the head back/up (a cheap "stretch and
## glance" read); `SIT_VERTICAL_DROP` lowers the whole figure's body+head
## (a cheap "sitting" read) -- both a single flat number, no animation
## curve, matching this epic's own "Cheap" cost-class discipline (§6.5/§8.9).
const PAUSE_LOOK_HEAD_TILT: float = -0.35
const SIT_VERTICAL_DROP: float = 0.4

var _highlight_mode: HighlightMode = HighlightMode.NONE

## The last slice level [method set_slice_level] applied. A large sentinel
## default keeps a freshly-constructed view fully visible until the first
## real push -- no separate "never sliced yet" flag is needed.
var _slice_level: int = 1 << 30

var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _hit_proxy: VillagerHitProxy
var _icon_anchor: Node3D


## Builds the placeholder figure's child nodes -- headless-safe (constructs
## real [MeshInstance3D]/[VillagerHitProxy]/[Node3D] children with zero
## rendering/tree dependency), mirrors every other landed module's
## "correct from construction" precedent ([VillagerHitProxy]'s own
## [method VillagerHitProxy._init]).
func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	_body_mesh = MeshInstance3D.new()
	_body_mesh.name = "BodyMesh"
	var body_box := BoxMesh.new()
	body_box.size = Vector3(FIGURE_WIDTH, BODY_HEIGHT, FIGURE_WIDTH)
	_body_mesh.mesh = body_box
	_body_mesh.position = Vector3(0.0, BODY_HEIGHT * 0.5, 0.0)
	_body_mesh.material_override = StandardMaterial3D.new()
	add_child(_body_mesh)

	_head_mesh = MeshInstance3D.new()
	_head_mesh.name = "HeadMesh"
	var head_box := BoxMesh.new()
	head_box.size = Vector3(HEAD_WIDTH, HEAD_HEIGHT, HEAD_WIDTH)
	_head_mesh.mesh = head_box
	_head_mesh.position = Vector3(0.0, BODY_HEIGHT + HEAD_HEIGHT * 0.5, 0.0)
	_head_mesh.material_override = StandardMaterial3D.new()
	add_child(_head_mesh)

	_hit_proxy = VillagerHitProxy.new()
	_hit_proxy.name = "VillagerHitProxy"
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = FIGURE_WIDTH * 0.6
	capsule.height = BODY_HEIGHT + HEAD_HEIGHT
	shape.shape = capsule
	shape.position = Vector3(0.0, (BODY_HEIGHT + HEAD_HEIGHT) * 0.5, 0.0)
	_hit_proxy.add_child(shape)
	add_child(_hit_proxy)

	_icon_anchor = Node3D.new()
	_icon_anchor.name = "IconAnchor"
	_icon_anchor.position = Vector3(0.0, BODY_HEIGHT + HEAD_HEIGHT + ICON_ANCHOR_CLEARANCE, 0.0)
	add_child(_icon_anchor)


func _ready() -> void:
	_hit_proxy.villager_id = villager_id


## Pull-only mirror (class doc comment) -- reads [member ai_source]'s own
## already-computed visual position and assigns it directly. Never touches
## [member Node3D.position]/[member Node3D.transform] any other way, never
## stores a copy, never blends toward it over time.
func _process(_delta: float) -> void:
	if ai_source == null:
		return
	global_position = ai_source.get_visual_position()
	_apply_idle_pose()


## Idle-behaviour presentation (presentation-001 Sub-B, class doc comment).
## Reads two existing, pure observability seams -- [method
## VillagerAi.get_state]/[method VillagerAi.get_last_micro_behavior] -- and
## applies a fixed local-space pose offset to the placeholder figure's
## child meshes. `WALK`/`BED_DRIFT` (already `State.TRAVELING`, never
## `State.WANDERING`, per Story villager-ai-019) and any other state/`null`
## micro-behavior reset both meshes to their neutral, [method _init]-assigned
## pose -- a stale `SIT`/`PAUSE_LOOK` draw from a since-ended Wandering
## episode (Story villager-ai-019's [member VillagerAi._last_micro_behavior]
## is never cleared) must never leak a sitting/glancing pose onto a villager
## that is now Working or Traveling for a job.
func _apply_idle_pose() -> void:
	var state: int = ai_source.get_state()
	var micro_behavior: Variant = ai_source.get_last_micro_behavior()
	var is_stationary_wander: bool = state == VillagerAi.State.WANDERING
	var showing_pause_look: bool = (
		is_stationary_wander and micro_behavior == VillagerWanderSelector.MicroBehavior.PAUSE_LOOK
	)
	var showing_sit: bool = (
		is_stationary_wander and micro_behavior == VillagerWanderSelector.MicroBehavior.SIT
	)

	_head_mesh.rotation = Vector3(PAUSE_LOOK_HEAD_TILT if showing_pause_look else 0.0, 0.0, 0.0)

	var vertical_drop: float = SIT_VERTICAL_DROP if showing_sit else 0.0
	_body_mesh.position = Vector3(0.0, BODY_HEIGHT * 0.5 - vertical_drop, 0.0)
	_head_mesh.position = Vector3(0.0, BODY_HEIGHT + HEAD_HEIGHT * 0.5 - vertical_drop, 0.0)


## Applies the Slice View cutoff (VB-1 §5). Reads the DISCRETE
## `ai_source.get_current_cell()` -- never the interpolated position -- so a
## villager mid-transit across the cutoff switches cleanly, with no
## flicker. TRAP 1: also zeroes/restores the hit proxy's `collision_layer`
## in lockstep with `visible` (an ancestor's `visible` going false does NOT
## disable an [Area3D]'s own collision in Godot). A `null` [member
## ai_source] leaves every villager visible (nothing to slice against)
## rather than crashing.
func set_slice_level(level: int) -> void:
	_slice_level = level
	if ai_source == null:
		return
	var hidden_by_slice: bool = ai_source.get_current_cell().y > _slice_level
	visible = not hidden_by_slice
	_hit_proxy.collision_layer = 0 if hidden_by_slice else 1


## Read-only observability seam (VB-1 §6) -- the actual outline/tint
## treatment is `villager-info-ui-006` + `godot-shader-specialist`'s scope,
## deliberately not implemented here.
func set_highlight(mode: HighlightMode) -> void:
	_highlight_mode = mode


func get_highlight() -> HighlightMode:
	return _highlight_mode


## Returns the [VillagerHitProxy] child -- test / picker observability seam.
func get_hit_proxy() -> VillagerHitProxy:
	return _hit_proxy


## Returns the `IconAnchor` child -- test / `villager-info-ui-005`
## observability seam.
func get_icon_anchor() -> Node3D:
	return _icon_anchor


## Returns the body [MeshInstance3D] -- test / presentation-001 Sub-B idle-
## pose observability seam.
func get_body_mesh() -> MeshInstance3D:
	return _body_mesh


## Returns the head [MeshInstance3D] -- test / presentation-001 Sub-B idle-
## pose observability seam.
func get_head_mesh() -> MeshInstance3D:
	return _head_mesh


## Combined local-space [AABB] of the placeholder figure's two mesh parts
## (body + head) -- AC-HEIGHT's "asserted against the mesh AABB, not
## eyeballed" seam. Computed from the real node transforms/mesh data, never
## a hardcoded constant.
func get_figure_aabb() -> AABB:
	var combined: AABB = _local_mesh_aabb(_body_mesh)
	return combined.merge(_local_mesh_aabb(_head_mesh))


## Transforms [param mesh_instance]'s own local mesh-space [AABB] by its
## node transform into this view's local space. Computes all 8 corners
## manually and folds them into one bounding box via [method AABB.expand] --
## avoids depending on any [Transform3D]/[AABB] operator overload whose
## exact availability this post-cutoff engine version was not re-verified
## for.
func _local_mesh_aabb(mesh_instance: MeshInstance3D) -> AABB:
	var local_aabb: AABB = mesh_instance.mesh.get_aabb()
	var xform: Transform3D = mesh_instance.transform
	var result: AABB = AABB(xform * local_aabb.position, Vector3.ZERO)
	for corner_index in range(1, 8):
		var offset := Vector3(
			local_aabb.size.x if corner_index & 1 else 0.0,
			local_aabb.size.y if corner_index & 2 else 0.0,
			local_aabb.size.z if corner_index & 4 else 0.0,
		)
		result = result.expand(xform * (local_aabb.position + offset))
	return result
