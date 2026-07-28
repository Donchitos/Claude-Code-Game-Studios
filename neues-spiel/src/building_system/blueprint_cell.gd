## Building System's blueprint (Draft) cell value object (Story
## building-021, GDD Core Rule 11 [TR-building-system-052]: "A valid commit
## does NOT write blocks into the grid. It creates blueprint cells: planned
## cells rendered as ghosts, owned by this system, invisible to Voxel World's
## data layer.")
##
## `RefCounted`, not `Resource` -- owned entirely by [CommitPipeline] (and,
## once it lands, the persistent project entity ADR-0016/Story
## building-002 defines) -- never authored/serialized/shared directly;
## mirrors [CellContents]/[RaycastHitResult]'s shared "fresh lightweight
## value object" precedent, though unlike those transient per-call objects
## this one is RETAINED for as long as the cell remains part of a project
## (RefCounted supports that fine -- it is not a garbage-collected type,
## just automatically freed once nothing references it anymore).
##
## [enum MicroState] names the FULL "Blueprint cell lifecycle" table
## (`design/gdd/building-system.md`, States and Transitions) up front so a
## later story never needs to introduce a second/renamed enum for the same
## per-cell state axis -- naming matches the GDD's own "micro-state"
## terminology (Core Rule 16: "the removal tool's behavior branches on the
## target cell's own micro-state"). [CommitPipeline] (this story) only ever
## constructs a cell in [constant MicroState.PLANNED]; the other three
## values exist here as the documented target shape for future stories to
## drive transitions into -- Story building-004 (release/job eligibility),
## building-029/030 (construction), and building-009/015/032 (demolition/
## cancel/undo). No transition method is implemented by this story.
##
## Story building-029 (this revision) adds [member category]/[member
## contents] -- GDD Formula F3's `cell_build_ticks = base_build_ticks
## [category]` needs to know WHICH tuning knob a cell uses
## ([TR-building-system-079]), and completing a cell needs to know WHAT to
## write into [VoxelWorldGrid] ([TR-building-system-057]). Both default to a
## PLACEHOLDER (`Category.BLOCK` / a generic solid [CellContents]) -- Story
## 022's real material-selection wiring (Core Rule 9) is the future caller
## that will pass a real resolved value into [method _init] instead of
## relying on this default, mirroring [CommitPipeline]'s own established
## placeholder-pending-a-later-story precedent (`_default_cell_set`'s doc
## comment).
##
## Story building-030 (this revision) adds [member is_unreachable] -- GDD
## Edge Case 5 / [TR-building-system-087]'s "the ghost switches to a pulsing
## orange tint" visual state. Deliberately a plain rendering-annotation flag,
## NOT a fifth [enum MicroState] value: an unreachable cell is still fully
## [constant MicroState.PLANNED] (still job-eligible, still enumerable by
## [method BuildProject.get_building_eligible_cells], never auto-canceled,
## per AC35) -- only its GHOST TINT changes. [ConstructionJobQueue] is the
## sole owner of this field's writes ([method ConstructionJobQueue.
## report_unreachable] sets it, a successful [method ConstructionJobQueue.
## claim_job] clears it) -- no ghost-rendering consumer exists yet in this
## codebase to read it, mirroring [member category]/[member contents]' own
## "field lands now, the real consumer wires in a later story" precedent.
##
## Story building-005 (this revision) adds [member claimed_by_villager_id] --
## GDD Rule 12/14f, ADR-0016 Decision Sec.4, [TR-building-system-109], AC58:
## "`claim_job` records the claiming villager against the cell." A plain
## per-cell attribution fact, display/save state only -- [method
## BuildProject.on_job_claimed] is the sole writer, and no code anywhere
## reads it to gate scheduling/claiming/lifecycle transitions (Control
## Manifest Forbidden rule; this is never a fifth [enum MicroState] value,
## mirroring [member is_unreachable]'s own "rendering/bookkeeping annotation,
## not a state" precedent).
class_name BlueprintCell
extends RefCounted

## The GDD's "Blueprint cell lifecycle" table states, verbatim: Planned (UX
## term "Draft" while its project/change-order batch is unreleased -- same
## system state, Slice revision 2026-07-23 doc note) / UnderConstruction /
## Built / Canceled.
enum MicroState {
	PLANNED,
	UNDER_CONSTRUCTION,
	BUILT,
	CANCELED,
}

## GDD Formula F3's `category` axis (`base_build_ticks[block]` = 4,
## `[furniture]` = 8, [TR-building-system-079]) -- Story building-029
## addition (see class doc comment). Determines which tuning knob
## [method ConstructionTickLoop.required_ticks_for] reads for this cell.
## Story `building-034` addition (ADR-0007/TD ruling D1/D3): `SCAFFOLD` is a
## THIRD category, mirroring `FURNITURE`'s own routing shape -- a completing
## `SCAFFOLD` job routes to [ScaffoldRegistry] INSTEAD OF [VoxelWorldGrid]
## (D1: scaffolding is not voxel data), exactly as `FURNITURE` routes to
## [FurnitureRegistry] (BV-1).
enum Category {
	BLOCK,
	FURNITURE,
	SCAFFOLD,
}

## The cell address this blueprint cell occupies.
var cell: Vector3i

## Current micro-state -- always [constant MicroState.PLANNED] for a cell
## [CommitPipeline] itself creates (this story never drives a transition).
var state: MicroState

## See [enum Category] -- Story building-029 addition. Defaults to
## [constant Category.BLOCK]; [CommitPipeline] does not yet set this
## explicitly (Story 028's furniture placement is the future real caller).
var category: Category

## The [CellContents] [ConstructionTickLoop] writes into [VoxelWorldGrid]
## once this cell completes construction ([TR-building-system-057]) --
## Story building-029 addition, PLACEHOLDER pending Story 022's real
## material selection (see class doc comment).
var contents: CellContents

## The RID `furniture_fixture` item id this cell represents (e.g. `&"bed"`)
## -- Story building-028 addition, GDD Rule 8 / [TR-building-system-048].
## Empty (`&""`) for every [constant Category.BLOCK] cell; only ever
## non-empty when [member category] is [constant Category.FURNITURE].
## [CommitPipeline.commit] is the sole writer (resolved from whichever item
## was selected via [method CommitPipeline.set_selected_item] at commit
## time). [ConstructionTickLoop]'s completion write reads this to route a
## completing furniture cell to the Building System's own furniture
## registry INSTEAD OF [VoxelWorldGrid] (ADR-0016 BV-1 ruling,
## `production/architecture-decisions-m02-preflight-2026-07-26.md`:
## "furniture is not voxel data -- it never enters VoxelWorldGrid").
var furniture_definition_id: StringName = &""

## See class doc comment (Story building-030 addition, GDD Edge Case 5,
## [TR-building-system-087]). Defaults `false` -- a freshly-created cell is
## never unreachable until [method ConstructionJobQueue.report_unreachable]
## says otherwise.
var is_unreachable: bool = false

## See class doc comment (Story building-005 addition, AC58). `-1` means "no
## villager has ever claimed this cell" (same sentinel convention ADR-0016's
## own Key Interfaces use for `project_at_cell(cell) -> int`, "-1 = none") --
## a freshly-created cell always starts unclaimed. [method
## BuildProject.on_job_claimed] is the sole writer; a later claim on the SAME
## cell (e.g. after a release + re-claim by a different villager) simply
## overwrites the previous id, mirroring [member is_unreachable]'s own
## "latest write wins, no history kept" precedent.
var claimed_by_villager_id: int = -1

## Story building-016 addition (GDD Core Rule 8/F5, [TR-building-system-124]/
## [TR-building-system-127]) -- the shared [FurnitureFootprintGroup] this
## cell belongs to, or `null`. `null` for every [constant Category.BLOCK]
## cell and for a single-cell (1x1) furniture item -- only a multi-cell
## furniture commit (footprint size > 1) ever populates this ([method
## CommitPipeline.commit] is the sole writer, after constructing every
## sibling [BlueprintCell] of the same commit). See
## [FurnitureFootprintGroup]'s own doc comment for why [ConstructionTickLoop]
## needs this reference to route a multi-cell footprint's completion as
## exactly ONE furniture entity.
var footprint_group: FurnitureFootprintGroup = null

## Story building-009 addition (GDD Rule 14l, [TR-building-system-120]) --
## the captured terrain [CellContents] for a floor-excavation blueprint entry
## (Story 012's future capturing half, at floor-tool commit time on a
## terrain-top-surface start cell). `null` for every ordinary cell (the
## overwhelming majority). When non-null, [ConstructionTickLoop]'s demolition
## completion writes THIS value back to [VoxelWorldGrid] instead of an empty
## [CellContents] (Rule 14j/14l: "the original terrain's restore_value is
## written back instead of leaving an empty cell") -- this story (009) is the
## CONSUMING half of the contract; Story 012 is the future capturing half.
## A snapshot, never re-derived -- whichever future caller sets this must set
## it once, at capture time, and never recompute it later (Edge 18).
var restore_value: CellContents = null

## Story building-009 addition (GDD Rule 14j, [TR-building-system-114],
## Edge 17) -- `true` once a demolition order exists for this (necessarily
## [constant MicroState.BUILT]) cell. Deliberately a plain rendering/
## bookkeeping-style flag, NOT a fifth [enum MicroState] value -- mirrors
## [member is_unreachable]'s own "annotation, not a state" precedent exactly:
## the cell stays fully [constant MicroState.BUILT] (still the per-cell
## terminal state per the GDD's own "Built (terminal for the cell; not for
## the project)" table row) for as long as its demolition job is queued or
## in progress; only [ConstructionTickLoop] mutates this field ([method
## ConstructionTickLoop.create_demolition_order] sets it, that same class's
## demolition-completion path clears it). A freshly-created cell always
## starts `false`.
var is_demolition_queued: bool = false


func _init(
	p_cell: Vector3i,
	p_state: MicroState = MicroState.PLANNED,
	p_category: Category = Category.BLOCK,
	p_contents: CellContents = null,
	p_furniture_definition_id: StringName = &"",
	p_restore_value: CellContents = null
) -> void:
	cell = p_cell
	state = p_state
	category = p_category
	contents = p_contents if p_contents != null else CellContents.new(1, 0)
	furniture_definition_id = p_furniture_definition_id
	restore_value = p_restore_value
