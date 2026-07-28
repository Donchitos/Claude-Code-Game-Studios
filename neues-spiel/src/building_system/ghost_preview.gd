## Building System's ghost preview renderer (Story building-023, ADR-0014
## primary -- pooled `MeshInstance3D` nodes + `material_override` tint, never
## per-instance custom-data plumbing; ADR-0010 secondary -- the preview
## updates on the raw-input path, responsive even while paused).
##
## Owns TWO distinct, but related, rendering responsibilities the story's
## Acceptance Criteria both require:
##
## 1. **The LIVE pending-candidate preview** (AC1/AC50, [TR-building-system-003]/
##    [TR-building-system-026]/[TR-building-system-035]/[TR-building-system-039]/
##    [TR-building-system-093]) -- what the CURRENT pick/drag would commit if
##    released right now. Visible only while [ToolStateMachine] reports
##    [method ToolStateMachine.is_ghost_visible] (ToolArmed/Dragging), hidden
##    at Idle/Suspended. Tinted State Blue when the candidate would be a
##    valid commit, State Orange when it would not -- the colorblind-safe
##    axis TR-093 requires (never red-green; [TR-building-system-093]).
##    Above [member GhostPreviewConfig.preview_degradation_threshold] cells,
##    degrades from one pooled ghost per cell to a single wireframe bounding-
##    box outline spanning the candidate set (AC50) -- the eventual commit
##    stays cell-exact regardless (this class renders, [CommitPipeline] still
##    owns the actual write).
## 2. **The PERSISTENT blueprint-cell ghost set** ([TR-building-system-069]) --
##    every [BlueprintCell] [CommitPipeline] currently tracks (Planned or
##    UnderConstruction; a cell that has left both states -- Built, or a
##    future Canceled -- is pruned from this set, its real geometry now
##    rendered by [VoxelWorldMesher] instead) renders CONTINUOUSLY,
##    independent of the current tool/pick state (Core Rule 11: "planned
##    cells rendered as ghosts, owned by this system" is an unconditional
##    fact of a cell's existence, not gated by whether a tool happens to be
##    armed right now). Planned and UnderConstruction read distinctly via two
##    alpha tiers ([member GhostPreviewConfig.draft_ghost_alpha]/
##    [member GhostPreviewConfig.queued_ghost_alpha]) -- this story renders
##    the distinct VISUAL STATE only; Story building-029's tick-driven
##    progress FRACTION is explicitly out of scope here (this story's own Out
##    of Scope section) and no dependency on [ConstructionTickLoop] exists in
##    this class at all -- [BlueprintCell.state] alone (a plain field
##    [ConstructionTickLoop] mutates in place on the SAME shared
##    [RefCounted] reference this class already holds from [signal
##    CommitPipeline.blueprint_cells_created]) is sufficient to tell the two
##    tiers apart, exactly as the story's own Dependencies section lists only
##    Stories 019/020/022 -- never 029.
##
## **Deferred art-bible upgrade, explicitly flagged**: `design/art/
## art-bible.md` SS7.1 (2026-07-23, user-confirmed) commits the LONG-TERM
## direction as material-tinted ghosts ("a translucent tint of the ACTUAL
## material being placed... Invalid placement... switches to State Orange").
## This class implements the STATE-BLUE-valid / State-Orange-invalid axis
## instead for the LIVE preview, matching [TR-building-system-093]'s
## registered text verbatim AND this story's own embedded Control Manifest
## excerpt ("valid (blue) / orange (invalid) state axis") AND
## [PlacementPick]'s own pre-existing doc comment, which already names
## "Story 023" as owning exactly "the valid/invalid blue-orange ghost axis"
## (`placement_pick.gd`, `_ensure_highlight_mesh` doc comment) -- i.e. the
## ALREADY-LANDED codebase was written expecting this exact axis. Rendering
## a true material tint would require resolving [member
## CommitPipeline.get_selected_item]'s opaque id through Resource & Item
## Database to an actual renderable color/texture -- no such color-resolution
## utility exists anywhere in this codebase yet (even [VoxelWorldMesher]'s
## own terrain coloring is still an explicitly-labeled `DEBUG_BLOCK_COLORS`
## placeholder pending a future atlas story). Implementing blue/orange now
## and flagging the art-bible upgrade as a follow-on story (extend this
## class's tint resolution once RID color/texture resolution exists, without
## restructuring the pooling/degradation mechanism below) is the documented
## deviation this class's doc comment records, per this project's "flag
## deviations explicitly, don't silently pick" collaboration principle.
##
## **Persistent-ghost tint is intentionally NOT the blue/orange axis either**
## -- a persisted Planned/UnderConstruction cell was already accepted by
## [CommitPipeline]'s validity gate (Story building-022) at commit time, so
## there is no "invalid" concept left to signal for it; this class renders it
## in a neutral, colorblind-neutral white tint (mirrors [PlacementPick]'s own
## established cursor-highlight precedent exactly -- "a translucent,
## unshaded, colorblind-neutral tint (white)... an overlay, not the blue-
## orange axis") at the two GDD-named alpha tiers instead.
##
## **Live preview re-rasterization is event-driven, not per-frame polled**
## (Control Manifest cross-cutting constraint: "event-driven, not polled").
## [PlacementPick] already re-derives its own pick every frame while
## ToolArmed/Dragging and fires [signal PlacementPick.pick_changed] ONLY when
## the resolved hit/cell/normal actually differs from the previous frame
## (that class's own "never a redundant re-fire" precedent) -- reacting to
## THAT signal (plus [signal ToolStateMachine.ghost_visibility_changed] for
## show/hide and [signal ToolStateMachine.tool_armed] for a same-state
## tool-switch, AC2) already satisfies "the preview re-rasterizes every frame
## the cursor moves" ([TR-building-system-003]): a cursor move that does not
## change the resolved cell has nothing new to rasterize in the first place.
## This class's own [method _process] callback exists ONLY for the SEPARATE
## persistent-ghost tier's per-tick material/prune refresh (see point 2
## above) -- there is no per-cell state-CHANGE signal anywhere in this
## codebase (`claim_job` mutates [member BlueprintCell.state] directly, with
## no dedicated signal), so reading the live field once per frame is the
## correct, and only, way to keep that tier current (mirrors the Art Bible
## SS7.4 "render the raw value every frame, no easing" progress-bar
## convention, applied here to a world-space ghost instead of a HUD bar).
## [method _process] is enabled ONLY while at least one blueprint ghost is
## tracked (mirrors [PlacementPick]'s own "hover picking... runs per-frame
## only while a tool is armed" guardrail precedent, applied to this class's
## own idle-disable case).
##
## Injected-tier module (ADR-0001): [member tool_state_machine]/[member
## placement_pick]/[member commit_pipeline]/[member config] are wired via a
## scene file's Inspector in production (once a future scene-assembly story
## attaches this node -- mirroring [WallTool]/[FloorTool]/[RoofTool]/
## [BlockTool]'s own established "not yet wired into `Valley.tscn`,
## attached by a future scene-assembly story" precedent exactly; none of
## those four tools are hosted by `Valley` yet either), or assigned directly
## in a headless test; all wiring/validation lives in [method setup], never
## `_ready()`.
##
## Mirrors [PlacementPick]'s own established convention: `extends Node`
## (never `Node3D`), with every pooled [MeshInstance3D] child's `.position`
## set (LOCAL, never `.global_position`) -- this class's own root contributes
## no transform of its own, so local position IS the effective world
## position, exactly as [method PlacementPick._update_highlight]'s own doc
## comment already establishes for this codebase.
class_name GhostPreview
extends Node

## State Blue (`design/art/art-bible.md` SS4.1) -- the live preview's VALID
## tint.
const STATE_BLUE: Color = Color("4A90C4")

## State Orange (`design/art/art-bible.md` SS4.1) -- the live preview's
## INVALID tint, and every "needs attention" world-space signal per that
## section.
const STATE_ORANGE: Color = Color("E1752E")

## Fixed, non-configurable live-preview overlay alpha -- mirrors
## [PlacementPick]'s own hardcoded `0.35` cursor-highlight alpha precedent
## (`_ensure_highlight_mesh`): a presentation-only overlay with no GDD-named
## tuning knob of its own (see class doc comment for why this is distinct
## from [member GhostPreviewConfig.draft_ghost_alpha]/[member
## GhostPreviewConfig.queued_ghost_alpha], which govern the PERSISTED-ghost
## tiers instead).
const LIVE_PREVIEW_ALPHA: float = 0.5

## Injected-tier dependency (ADR-0001) -- the four-state tool machine (Story
## building-019) this class reads [method ToolStateMachine.is_ghost_visible]/
## [method ToolStateMachine.get_state] from, and whose [signal
## ToolStateMachine.ghost_visibility_changed]/[signal ToolStateMachine.tool_armed]
## drive the live preview's show/hide/recompute.
@export var tool_state_machine: ToolStateMachine

## Injected-tier dependency (ADR-0001) -- the current pick (Story
## building-020) this class reads [method PlacementPick.get_current_pick]/
## [method PlacementPick.get_attach_cell]/[method PlacementPick.get_press_cell]
## from, and whose [signal PlacementPick.pick_changed] drives the live
## preview's re-rasterization.
@export var placement_pick: PlacementPick

## Injected-tier dependency (ADR-0001) -- the validity gate (Story
## building-022) this class calls [method CommitPipeline.preview_cell_set]/
## [method CommitPipeline.clamp_to_bounds]/[method CommitPipeline.first_rejection_reason]
## on (this story's own additions, side-effect-free w.r.t. that class), and
## whose [signal CommitPipeline.blueprint_cells_created] seeds the persistent
## ghost pool.
@export var commit_pipeline: CommitPipeline

## Tuning config dependency (ADR-0002). Wired via a scene file's Inspector in
## production, or assigned directly in a headless test. Never read inside
## `_ready()` -- see [method setup].
@export var config: GhostPreviewConfig

## True once [method setup] has completed at least once.
var _is_set_up: bool = false

## Shared box mesh every pooled ghost (live AND persistent) uses -- one
## flush, cell-sized box (never inflated; the inflated-overlay-box language
## is the REPLACE/DIG marker's own, a different story's concern per
## `design/art/art-bible.md` SS7.1). Built once in [method setup].
var _ghost_box_mesh: BoxMesh = null

## Shared valid-tint material for the live preview (State Blue @ [constant
## LIVE_PREVIEW_ALPHA]). Built once in [method setup].
var _valid_material: StandardMaterial3D = null

## Shared invalid-tint material for the live preview (State Orange @
## [constant LIVE_PREVIEW_ALPHA]). Built once in [method setup].
var _invalid_material: StandardMaterial3D = null

## Shared Planned-tier material for persistent blueprint ghosts (neutral
## white @ [member GhostPreviewConfig.draft_ghost_alpha]). Built once in
## [method setup].
var _planned_material: StandardMaterial3D = null

## Shared UnderConstruction-tier material for persistent blueprint ghosts
## (neutral white @ [member GhostPreviewConfig.queued_ghost_alpha]). Built
## once in [method setup].
var _under_construction_material: StandardMaterial3D = null

## Pooled per-cell live-preview ghost instances -- grow-only, reused across
## frames (index `i` un-hidden/repositioned while needed, hidden -- never
## freed -- once the current candidate set shrinks). Bounded above by
## [member GhostPreviewConfig.preview_degradation_threshold] in practice
## (above it, [method _show_outline] takes over and no new pool entries are
## ever requested).
var _live_ghost_pool: Array[MeshInstance3D] = []

## The single reusable wireframe bounding-box outline (AC50 degraded mode) --
## a unit-cube line mesh, repositioned/rescaled per frame via `.position`/
## `.scale` rather than rebuilt. Created once in [method setup].
var _outline_mesh: MeshInstance3D = null

## The post-bounds-clamp candidate cell set the live preview is CURRENTLY
## showing -- empty means hidden. Read-only observability (see [method
## get_live_preview_cells]).
var _last_live_cells: Array[Vector3i] = []

## Whether [member _last_live_cells] would currently commit validly (State
## Blue) or not (State Orange) -- meaningless while [member _last_live_cells]
## is empty.
var _last_live_valid: bool = false

## Whether the live preview is CURRENTLY in degraded outline mode (AC50) --
## meaningless while [member _last_live_cells] is empty.
var _last_live_degraded: bool = false

## One pooled ghost entry per PERSISTED blueprint cell -- see class doc
## comment point 2. Declared above every method that uses it, mirroring
## [ConstructionTickLoop]'s own `_ActiveJob` nested-class-above-usage
## precedent.
class _BlueprintGhostEntry:
	## The tracked [BlueprintCell] itself -- a SHARED [RefCounted] reference,
	## never a copy, so this class's own per-frame [member state] read always
	## observes [ConstructionTickLoop]'s in-place mutations (class doc
	## comment).
	var blueprint_cell: BlueprintCell

	## This entry's own pooled [MeshInstance3D] -- one per tracked cell,
	## created once and reused for that cell's entire tracked lifetime.
	var mesh_instance: MeshInstance3D

	func _init(p_blueprint_cell: BlueprintCell, p_mesh_instance: MeshInstance3D) -> void:
		blueprint_cell = p_blueprint_cell
		mesh_instance = p_mesh_instance

## See [_BlueprintGhostEntry] doc comment -- keyed by cell address, mirroring
## [ConstructionTickLoop]'s own `_active_jobs` per-cell keying shape.
var _blueprint_ghost_pool: Dictionary[Vector3i, _BlueprintGhostEntry] = {}


## Explicitly callable wiring/validation entry point (ADR-0001). Asserts
## every dependency was wired, applies ADR-0002's clamp+warn (+BLOCKING)
## policy to [member config], builds every shared mesh/material resource
## once, connects to every signal this class reacts to (idempotent via
## [method Signal.is_connected], mirroring this codebase's established
## precedent), and reflects [member tool_state_machine]'s CURRENT visibility
## immediately (so a `setup()` call while a tool happens to already be armed
## does not leave the live preview hidden until the next visibility change --
## mirrors [PlacementPick.setup]'s identical "initialize to current state"
## precedent).
func setup() -> void:
	assert(tool_state_machine != null, "GhostPreview.tool_state_machine not wired")
	assert(placement_pick != null, "GhostPreview.placement_pick not wired")
	assert(commit_pipeline != null, "GhostPreview.commit_pipeline not wired")
	assert(config != null, "GhostPreview.config not wired")
	for issue: String in config.validate():
		push_warning(issue)
	_ensure_shared_resources()
	if not tool_state_machine.ghost_visibility_changed.is_connected(_on_ghost_visibility_changed):
		tool_state_machine.ghost_visibility_changed.connect(_on_ghost_visibility_changed)
	if not tool_state_machine.tool_armed.is_connected(_on_tool_armed):
		tool_state_machine.tool_armed.connect(_on_tool_armed)
	if not placement_pick.pick_changed.is_connected(_on_pick_changed):
		placement_pick.pick_changed.connect(_on_pick_changed)
	if not commit_pipeline.blueprint_cells_created.is_connected(_on_blueprint_cells_created):
		commit_pipeline.blueprint_cells_created.connect(_on_blueprint_cells_created)
	set_process(not _blueprint_ghost_pool.is_empty())
	_is_set_up = true
	_on_ghost_visibility_changed(tool_state_machine.is_ghost_visible())


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


# ---------------------------------------------------------------------------
# Live preview -- read-only observability (test/tool introspection)
# ---------------------------------------------------------------------------

## Whether the live preview is CURRENTLY showing anything (a non-empty,
## post-bounds-clamp candidate set).
func is_live_preview_visible() -> bool:
	return not _last_live_cells.is_empty()


## The live preview's CURRENT post-bounds-clamp candidate cell set --
## meaningless while [method is_live_preview_visible] is false.
func get_live_preview_cells() -> Array[Vector3i]:
	return _last_live_cells


## Whether the live preview's CURRENT candidate set would commit validly
## (State Blue) or not (State Orange, [TR-building-system-093]) --
## meaningless while [method is_live_preview_visible] is false.
func is_live_preview_valid() -> bool:
	return _last_live_valid


## Whether the live preview is CURRENTLY in degraded outline mode (AC50) --
## meaningless while [method is_live_preview_visible] is false.
func is_live_preview_degraded() -> bool:
	return _last_live_degraded


## The shared material CURRENTLY applied to the live preview (per-cell ghosts
## or the outline, whichever is active) -- [constant STATE_BLUE]/[constant
## STATE_ORANGE] tinted, per [method is_live_preview_valid]. Returns `null`
## while [method is_live_preview_visible] is false.
func get_live_preview_material() -> StandardMaterial3D:
	if _last_live_cells.is_empty():
		return null
	return _valid_material if _last_live_valid else _invalid_material


## Every pooled live-ghost [MeshInstance3D] CURRENTLY visible -- test/tool
## introspection convenience (never used by this class's own rendering
## logic, which indexes [member _live_ghost_pool] directly).
func get_visible_live_ghost_count() -> int:
	var count: int = 0
	for instance: MeshInstance3D in _live_ghost_pool:
		if instance.visible:
			count += 1
	return count


## Whether the degraded outline mesh is CURRENTLY visible.
func is_outline_visible() -> bool:
	return _outline_mesh != null and _outline_mesh.visible


# ---------------------------------------------------------------------------
# Persistent blueprint ghosts -- read-only observability
# ---------------------------------------------------------------------------

## Every cell address CURRENTLY holding a tracked persistent blueprint ghost.
func get_blueprint_ghost_cells() -> Array[Vector3i]:
	var keys: Array[Vector3i] = []
	for cell: Vector3i in _blueprint_ghost_pool:
		keys.append(cell)
	return keys


## Whether [param cell] currently holds a VISIBLE persistent blueprint ghost.
func is_blueprint_ghost_visible(cell: Vector3i) -> bool:
	return _blueprint_ghost_pool.has(cell) and _blueprint_ghost_pool[cell].mesh_instance.visible


## The shared material CURRENTLY applied to [param cell]'s persistent
## blueprint ghost -- `null` if [param cell] holds no tracked ghost.
func get_blueprint_ghost_material(cell: Vector3i) -> StandardMaterial3D:
	if not _blueprint_ghost_pool.has(cell):
		return null
	var override: Material = _blueprint_ghost_pool[cell].mesh_instance.material_override
	return override as StandardMaterial3D


# ---------------------------------------------------------------------------
# Live preview -- signal handlers + recompute
# ---------------------------------------------------------------------------

## [signal ToolStateMachine.ghost_visibility_changed] handler -- the
## authoritative show/hide gate (AC1/AC3): recomputes immediately when
## becoming visible (so arming a tool shows the preview THIS frame, not
## waiting for the next [signal PlacementPick.pick_changed]), hides
## immediately otherwise.
func _on_ghost_visibility_changed(is_visible: bool) -> void:
	if is_visible:
		_recompute_live_preview()
	else:
		_hide_live_preview()


## [signal PlacementPick.pick_changed] handler -- the main per-cursor-move
## re-rasterization path (TR-003). A no-op while the ghost is not currently
## supposed to be visible (defensive; [PlacementPick] only fires this while
## ToolArmed/Dragging per its own guardrail, which already coincides with
## ghost visibility).
func _on_pick_changed(_result: RaycastHitResult) -> void:
	if tool_state_machine.is_ghost_visible():
		_recompute_live_preview()


## [signal ToolStateMachine.tool_armed] handler -- AC2's "Tool A deactivates,
## B arms" case: a re-arm to a DIFFERENT tool while ALREADY ToolArmed does
## NOT fire [signal ToolStateMachine.ghost_visibility_changed] (the boolean
## does not change), so this class would otherwise keep showing the
## PREVIOUS tool's stale-shaped preview until the next incidental pick
## change. Forces a recompute so the newly-armed tool's own registered
## resolver ([method CommitPipeline.preview_cell_set]) takes over
## immediately.
func _on_tool_armed(_tool_id: StringName) -> void:
	if tool_state_machine.is_ghost_visible():
		_recompute_live_preview()


## The live preview's core recompute (AC1/AC50/TR-093): resolves the
## CURRENT candidate cell set (Dragging: the frozen press cell + the
## continuously-updated current attach cell, `is_drag=true`; ToolArmed hover:
## the current attach cell as both press and release, `is_drag=false` -- "if
## a click landed right now"), clamps to world bounds, and either hides
## (no valid pick, or the clamp emptied the set -- Edge Case 1/4's own
## established "absence of a ghost IS the feedback" contract, unchanged),
## renders per-cell ghosts, or degrades to the outline (AC50) once the
## in-bounds count exceeds [member GhostPreviewConfig.preview_degradation_threshold].
##
## **Dragging release cell reads [method PlacementPick.get_current_pick]'s
## cell DIRECTLY, never [method PlacementPick.get_attach_cell]** -- mirrors
## the bug fix this story's own testing surfaced in [method
## PlacementPick._input] (see that method's doc comment): while Dragging,
## the current pick's `cell` (from [method PlacementPick.derive_drag_plane_hit])
## is ALREADY the attach-equivalent working-surface cell; [method
## PlacementPick.get_attach_cell]'s `+normal` offset would double-count it,
## shifting the live preview one cell too high the instant the cursor
## actually moves mid-drag (this exact discrepancy is what this story's
## `test_dragging_uses_frozen_press_cell_and_live_release_cell` caught).
func _recompute_live_preview() -> void:
	if not tool_state_machine.is_ghost_visible() or not placement_pick.get_current_pick().hit:
		_hide_live_preview()
		return

	var press_cell: Vector3i
	var release_cell: Vector3i
	var is_drag: bool
	if tool_state_machine.get_state() == ToolStateMachine.State.DRAGGING:
		press_cell = placement_pick.get_press_cell()
		release_cell = placement_pick.get_current_pick().cell
		is_drag = true
	else:
		var attach_cell: Vector3i = placement_pick.get_attach_cell()
		press_cell = attach_cell
		release_cell = attach_cell
		is_drag = false

	var candidate: Array[Vector3i] = commit_pipeline.preview_cell_set(is_drag, press_cell, release_cell)
	var in_bounds: Array[Vector3i] = commit_pipeline.clamp_to_bounds(candidate)
	if in_bounds.is_empty():
		_hide_live_preview()
		return

	var is_valid: bool = commit_pipeline.first_rejection_reason(in_bounds) == -1
	_last_live_cells = in_bounds
	_last_live_valid = is_valid
	if in_bounds.size() > config.preview_degradation_threshold:
		_show_outline(in_bounds, is_valid)
	else:
		_show_per_cell_ghosts(in_bounds, is_valid)


## Hides every live-preview visual (per-cell pool + outline) and clears the
## observability state -- AC1/AC3's "hidden at Idle" / "cancel hides the
## ghost" contract.
func _hide_live_preview() -> void:
	_hide_per_cell_ghosts()
	_hide_outline()
	_last_live_cells = []
	_last_live_valid = false
	_last_live_degraded = false


## Renders one pooled ghost per entry of [param cells], tinted per [param
## is_valid] -- growing [member _live_ghost_pool] on demand, reusing/hiding
## the rest (never freeing a pooled instance, ADR-0014's pooling contract).
func _show_per_cell_ghosts(cells: Array[Vector3i], is_valid: bool) -> void:
	_hide_outline()
	var material: StandardMaterial3D = _valid_material if is_valid else _invalid_material
	for i: int in cells.size():
		var instance: MeshInstance3D = _get_or_create_live_ghost(i)
		instance.position = VoxelWorldGrid.cell_to_world(cells[i])
		instance.material_override = material
		instance.visible = true
	for i: int in range(cells.size(), _live_ghost_pool.size()):
		_live_ghost_pool[i].visible = false
	_last_live_degraded = false


## Degrades to a single wireframe bounding-box outline spanning [param cells]
## (AC50) -- protects the frame budget on a large drag: cost is O(1) per
## frame regardless of how many cells [param cells] holds, unlike [method
## _show_per_cell_ghosts]'s O(n).
func _show_outline(cells: Array[Vector3i], is_valid: bool) -> void:
	_hide_per_cell_ghosts()
	var bounds: Dictionary = GhostPreview.compute_bounds(cells)
	var min_cell: Vector3i = bounds["min"]
	var max_cell: Vector3i = bounds["max"]
	_outline_mesh.position = Vector3(min_cell) * VoxelWorldConfig.CELL_SIZE
	_outline_mesh.scale = Vector3(max_cell - min_cell + Vector3i.ONE) * VoxelWorldConfig.CELL_SIZE
	_outline_mesh.material_override = _valid_material if is_valid else _invalid_material
	_outline_mesh.visible = true
	_last_live_degraded = true


## Hides every pooled live-preview ghost instance (never frees one -- pooled
## for reuse).
func _hide_per_cell_ghosts() -> void:
	for instance: MeshInstance3D in _live_ghost_pool:
		instance.visible = false


## Hides the outline mesh, if it exists yet.
func _hide_outline() -> void:
	if _outline_mesh != null:
		_outline_mesh.visible = false


## Returns [member _live_ghost_pool]'s entry at [param index], creating (and
## adding as a child) a fresh one on first use -- the ADR-0014 pooling
## pattern, mirroring [VoxelWorldMesher._get_or_create_chunk_node]'s
## identical grow-on-demand shape.
func _get_or_create_live_ghost(index: int) -> MeshInstance3D:
	if index < _live_ghost_pool.size():
		return _live_ghost_pool[index]
	var instance := MeshInstance3D.new()
	instance.mesh = _ghost_box_mesh
	instance.visible = false
	add_child(instance)
	_live_ghost_pool.append(instance)
	return instance


## Pure axis-aligned bounding-box derivation over [param cells] (AC50) --
## stateless, exercisable directly with arbitrary values, mirroring this
## codebase's established testable-pure-function shape ([method
## PlacementPick.derive_attach_cell], [method WallTool.rasterize_run]).
## Returns a two-key [Dictionary] (`"min"`/`"max"`, both [Vector3i]) rather
## than a dedicated value type -- this story introduces no new class for a
## single internal pure-geometry helper. [param cells] must be non-empty
## (callers only ever reach this after an emptiness check, mirroring [method
## CommitPipeline.commit]'s own "clamps to empty commits nothing" guard
## upstream of this method).
static func compute_bounds(cells: Array[Vector3i]) -> Dictionary:
	var min_cell: Vector3i = cells[0]
	var max_cell: Vector3i = cells[0]
	for cell: Vector3i in cells:
		min_cell = Vector3i(mini(min_cell.x, cell.x), mini(min_cell.y, cell.y), mini(min_cell.z, cell.z))
		max_cell = Vector3i(maxi(max_cell.x, cell.x), maxi(max_cell.y, cell.y), maxi(max_cell.z, cell.z))
	return {"min": min_cell, "max": max_cell}


# ---------------------------------------------------------------------------
# Persistent blueprint ghosts -- signal handler + per-frame refresh
# ---------------------------------------------------------------------------

## [signal CommitPipeline.blueprint_cells_created] handler -- seeds one
## pooled ghost per newly-created [BlueprintCell] (always Planned at
## creation, [CommitPipeline]'s own established contract), then enables
## [method _process] if this is the first tracked cell (guardrail, class doc
## comment).
func _on_blueprint_cells_created(cells: Array[BlueprintCell]) -> void:
	for cell: BlueprintCell in cells:
		if _blueprint_ghost_pool.has(cell.cell):
			continue
		var instance := MeshInstance3D.new()
		instance.mesh = _ghost_box_mesh
		instance.position = VoxelWorldGrid.cell_to_world(cell.cell)
		add_child(instance)
		_blueprint_ghost_pool[cell.cell] = _BlueprintGhostEntry.new(cell, instance)
	_refresh_blueprint_ghosts()


## Godot's per-frame engine callback -- the persistent-ghost tier's ONLY
## driver (see class doc comment for why this tier, unlike the live preview,
## needs a per-frame poll). Enabled/disabled by [method
## _refresh_blueprint_ghosts] itself, matching [PlacementPick]'s own
## "toggled by the guardrail, not merely no-op'd" precedent.
func _process(_delta: float) -> void:
	_refresh_blueprint_ghosts()


## Re-derives every tracked persistent ghost's material from its live
## [member BlueprintCell.state] (Planned/UnderConstruction -- TR-069), and
## prunes any entry whose cell has left both states (Built via
## [ConstructionTickLoop], or a future Canceled) -- its real geometry now
## exists via [VoxelWorldMesher] instead, so continuing to render a ghost
## over it would be stale/duplicate. Re-checks and re-applies [method
## Node.set_process]'s own enabled state at the end (empties itself out once
## nothing remains tracked).
func _refresh_blueprint_ghosts() -> void:
	var to_remove: Array[Vector3i] = []
	for cell: Vector3i in _blueprint_ghost_pool:
		var entry: _BlueprintGhostEntry = _blueprint_ghost_pool[cell]
		match entry.blueprint_cell.state:
			BlueprintCell.MicroState.PLANNED:
				entry.mesh_instance.material_override = _planned_material
				entry.mesh_instance.visible = true
			BlueprintCell.MicroState.UNDER_CONSTRUCTION:
				entry.mesh_instance.material_override = _under_construction_material
				entry.mesh_instance.visible = true
			_:
				to_remove.append(cell)
	for cell: Vector3i in to_remove:
		_blueprint_ghost_pool[cell].mesh_instance.queue_free()
		_blueprint_ghost_pool.erase(cell)
	set_process(not _blueprint_ghost_pool.is_empty())


# ---------------------------------------------------------------------------
# Shared resource construction (setup-time only)
# ---------------------------------------------------------------------------

## Builds every shared mesh/material resource exactly once (idempotent --
## a no-op on a repeated [method setup] call), mirroring [PlacementPick
## ._ensure_highlight_mesh]'s identical "created once, never re-created"
## shape.
func _ensure_shared_resources() -> void:
	if _ghost_box_mesh == null:
		_ghost_box_mesh = BoxMesh.new()
		_ghost_box_mesh.size = Vector3.ONE * VoxelWorldConfig.CELL_SIZE
	if _valid_material == null:
		_valid_material = GhostPreview._build_unshaded_material(GhostPreview._with_alpha(STATE_BLUE, LIVE_PREVIEW_ALPHA))
	if _invalid_material == null:
		_invalid_material = GhostPreview._build_unshaded_material(GhostPreview._with_alpha(STATE_ORANGE, LIVE_PREVIEW_ALPHA))
	if _planned_material == null:
		_planned_material = GhostPreview._build_unshaded_material(GhostPreview._with_alpha(Color.WHITE, config.draft_ghost_alpha))
	if _under_construction_material == null:
		_under_construction_material = GhostPreview._build_unshaded_material(GhostPreview._with_alpha(Color.WHITE, config.queued_ghost_alpha))
	if _outline_mesh == null:
		_outline_mesh = MeshInstance3D.new()
		_outline_mesh.mesh = GhostPreview._build_wireframe_unit_cube_mesh()
		_outline_mesh.visible = false
		add_child(_outline_mesh)


## Pure helper: [param color] with its alpha channel replaced by [param
## alpha] -- stateless.
static func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


## Builds one translucent, unshaded material for [param color] -- mirrors
## [method PlacementPick._ensure_highlight_mesh]'s identical material recipe
## (unshaded, alpha transparency) exactly.
static func _build_unshaded_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	return material


## Builds a unit-cube (`[0,1]^3`) wireframe line mesh (AC50's outline mode) --
## 8 corners, 12 edges, `PRIMITIVE_LINES`. Rescaled/repositioned per frame
## via the owning [MeshInstance3D]'s `.position`/`.scale` rather than
## rebuilt -- this is the ONE construction site for this mesh (mirrors
## [VoxelWorldMesher]'s own "one mesher construction site" discipline,
## scaled to this class's own single outline shape). Pure -- exercisable
## directly without an instance or [method setup] (e.g. asserting the exact
## vertex count).
static func _build_wireframe_unit_cube_mesh() -> ArrayMesh:
	var corners: Array[Vector3] = [
		Vector3(0.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(1.0, 0.0, 1.0), Vector3(0.0, 0.0, 1.0),
		Vector3(0.0, 1.0, 0.0), Vector3(1.0, 1.0, 0.0), Vector3(1.0, 1.0, 1.0), Vector3(0.0, 1.0, 1.0),
	]
	var edges: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 0),
		Vector2i(4, 5), Vector2i(5, 6), Vector2i(6, 7), Vector2i(7, 4),
		Vector2i(0, 4), Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 7),
	]
	var verts := PackedVector3Array()
	for edge: Vector2i in edges:
		verts.append(corners[edge.x])
		verts.append(corners[edge.y])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh
