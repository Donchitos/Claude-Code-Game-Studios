## Building System's persistent Build Project entity (Story building-002,
## ADR-0016 primary -- "A persistent, Building-System-owned build-project
## entity with an explicit lifecycle state machine ... exactly as
## slice-validated and specified in building-system.md TR-102..126."
## [TR-building-system-106] [TR-building-system-108] [TR-building-system-111]).
##
## `RefCounted`, not `Resource` or `Node` -- owned by a future registry
## (Story building-003's grouping/merge + cell->project reverse index) that
## creates instances and drops its own reference once a project [method
## is_empty] (see that method's doc comment for what "the project entity is
## deleted" (Rule 14i, AC61) means in a plain-`RefCounted` world); mirrors
## [BlueprintCell]'s own "retained for as long as it remains part of a
## project" precedent -- this class is exactly that project.
##
## Story building-002 establishes ONLY `id`/`kind`/`state`/`cells` and the
## state rollup (this story's own Implementation Notes, verbatim: "this
## story establishes id/state/cells and the rollup; `restore_value`/
## `worker_ids`/orders are extended by later stories"). Explicitly NOT this
## story's scope (see the story file's own Out of Scope section):
## - Story building-003: 26-neighborhood grouping/merge and the cell->project
##   reverse index that assigns newly-committed cells to a project. This
##   class exposes [method add_cell] as the seam that story calls into; it
##   performs no adjacency/merge logic of its own and does not enforce "a
##   cell belongs to exactly one project" beyond not double-tracking a cell
##   inside ITSELF -- that whole-world invariant is the future reverse
##   index's job.
## - Story building-004: the release ("Bau starten") transition itself
##   (validation, per-batch semantics, the player-facing action). This class
##   models [enum ProjectState.BUILDING] as a state value and [method
##   recompute_state] never demotes it back toward DRAFT, but nothing here
##   flips a project INTO BUILDING -- a future story sets [member state]
##   directly once released, exactly as [ConstructionTickLoop] already
##   mutates [member BlueprintCell.state] directly (that class's own
##   established precedent for "a plain public var another module writes").
## - Story building-006: pause/resume claim-revocation. [enum
##   ProjectState.PAUSED] exists as a state value; [method recompute_state]
##   never moves a project out of PAUSED on its own (Rule 14g: pausing/
##   resuming never happens as a side effect of a cell-state change) -- only
##   a future pause()/resume() action (not implemented here) transitions it.
## - `restore_value` (Rule 14l floor-excavation) and pending change-order
##   batches (Rule 14h) -- future additions to this same class per the ADR's
##   own data shape (`{ id, kind, state, cells, restore_value, worker_ids,
##   pending orders }`); this story carries neither. `worker_ids` itself
##   (attribution, Rule 12/ADR-0016 Decision Sec.4) IS this class's own
##   Story building-005 addition (see [method on_job_claimed] and the
##   [member worker_ids] doc comment below) -- landed after this story
##   (building-002), documented here only to keep this historical note
##   accurate about what building-002 itself did NOT yet carry.
##
## **The rollup** (TR-108, this story's core contract): [member state] is
## DERIVED from [member cells]' own [enum BlueprintCell.MicroState] values,
## never an independently-set flag for the DONE transition specifically --
## [method recompute_state] is the SOLE place that logic lives, called by
## every cell-membership mutator this class owns ([method add_cell]/[method
## cancel_cell]/[method demolish_cell]) and callable directly by any FUTURE
## caller that mutates a tracked [BlueprintCell]'s state through a different
## path (e.g. a later story wiring [ConstructionTickLoop]'s own completion
## write back into project rollup -- that class currently has no project
## concept at all, by its own documented design, so nothing calls this yet
## in production).
##
## **Why DRAFT/BUILDING/PAUSED are NOT purely cell-state-derived**: the GDD's
## own "Blueprint cell lifecycle" table states that "Queued" (released,
## job-eligible, not yet claimed) and "Draft" (not yet released) are "the
## UX term only" for the exact SAME [enum BlueprintCell.MicroState.PLANNED]
## per-cell value -- only the OWNING PROJECT's own release/pause state tells
## them apart (building-system.md States and Transitions section, Slice
## revision 2026-07-23 doc note). A cell reaching
## [enum BlueprintCell.MicroState.BUILT] is therefore the ONLY per-cell fact
## [method recompute_state] can safely read to drive an automatic
## transition -- which is exactly DONE (TR-111/AC60) and, symmetrically, a
## DONE project regaining a not-yet-built cell (a future change order,
## TR-112) falling back to BUILDING (already-released by construction, per
## Rule 14h: change orders only ever attach to an ALREADY released/done
## project).
class_name BuildProject
extends RefCounted

## `design/gdd/building-system.md` "Build Project lifecycle" table, Slice
## revision 2026-07-23 [TR-building-system-108] -- named identically to
## ADR-0016's own Key Interfaces `enum ProjectState` so no later story ever
## needs a second/renamed enum for this axis (mirrors [BlueprintCell]'s own
## "name the full lifecycle up front" precedent).
enum ProjectState {
	DRAFT,
	BUILDING,
	PAUSED,
	DONE,
}

## GDD Rule 14m: a project's cell set is grouped/merged only within cells of
## the SAME kind (Story building-003's own future scope) -- `build`-kind
## cells terminate at Built, `dig`-kind cells terminate at a Removed
## per-cell state Rule 14m describes but [enum BlueprintCell.MicroState]
## does not yet model (a future dig-order story's addition). This story
## carries the field only; no kind-based merge/rollup behavior is
## implemented here yet.
## Story `building-034` addition (TD ruling D3): `SCAFFOLD` is a THIRD `Kind`
## -- a scaffold structure is its OWN project, never a member of the project
## it serves (D3's circularity finding: `recompute_state()` reaches `DONE`
## iff every tracked cell is `BUILT`, and `DONE` is the dismantle trigger --
## a scaffold cell counted among the owner's OWN cells would make the
## dismantle trigger a state the scaffolding itself prevents). [member
## BuildProjectRegistry.assign_cells] already gates grouping on
## `existing_project.kind == kind` -- a `SCAFFOLD` project can therefore
## NEVER merge into the structure it serves, for free.
enum Kind {
	BUILD,
	DIG,
	SCAFFOLD,
}

## Caller-supplied identity (Story building-003's future reverse index owns
## id assignment/uniqueness; this class does not generate or validate one).
var id: int

## See [enum Kind]. Defaults to `BUILD` -- every MVP tool (Wall/Floor/Roof/
## Block/Furniture) produces `build`-kind projects; only Rule 14m's future
## dig-order tool produces `DIG`.
var kind: Kind

## Rollup state -- see class doc comment for exactly which transitions
## [method recompute_state] drives automatically versus which a future
## story sets directly (mirrors [member BlueprintCell.state]'s own "plain
## public var, mutated directly by whichever module owns that transition"
## precedent). Starts DRAFT: "First commit whose cells don't 26-adjoin any
## existing project" (GDD Build Project lifecycle table) -- exactly this
## class's own construction moment.
var state: ProjectState = ProjectState.DRAFT

## Every [BlueprintCell] currently belonging to this project, keyed by its
## [Vector3i] address -- mirrors [CommitPipeline]'s own `_blueprint_cells`
## keying precedent exactly. `Dictionary` preserves insertion order in
## Godot 4, which [method get_building_eligible_cells] relies on to satisfy
## Core Rule 12's "queue... ordered by commit time" for free ([method
## add_cell] is called in commit order by its future caller) -- no separate
## ordering/timestamp field needed.
var cells: Dictionary[Vector3i, BlueprintCell] = {}

## Rolled-up worker attribution (Story building-005, ADR-0016 Decision
## Sec.4, GDD Rule 12/14f, [TR-building-system-109], AC58) -- de-duplicated
## aggregate of every villager id [method on_job_claimed] has ever recorded
## against one of this project's cells, in first-claim order. Read/display +
## save-state only (`design/ux/projects-panel.md` Data Requirements:
## "`worker_ids`... Read... Names resolved via Villager AI lookup") -- NEVER
## a control channel: no method on this class or [ConstructionJobQueue]
## branches scheduling, claiming, or lifecycle transitions on this array's
## contents (Control Manifest Forbidden rule; this story's own QA Test Cases,
## "Attribution is not a control channel").
var worker_ids: Array[int] = []

## Story `building-034` addition (TD ruling D3) -- the id of the `BUILD`-kind
## project this scaffold structure serves, or `-1` (the same sentinel
## convention [method BuildProjectRegistry.project_at_cell] already uses) for
## every non-`SCAFFOLD` project. A scaffold project's dismantle is triggered
## by its owner reaching `DONE` or being canceled (AC3/D4) -- this link field
## is what a dismantle coordinator resolves "which scaffold structure serves
## THIS project" through, never a name/position heuristic.
var owner_project_id: int = -1


func _init(p_id: int, p_kind: Kind = Kind.BUILD, p_owner_project_id: int = -1) -> void:
	id = p_id
	kind = p_kind
	owner_project_id = p_owner_project_id


## Adds [param blueprint_cell] to this project's cell set and recomputes the
## rollup (see class doc comment -- Story building-003's future reverse
## index is this method's real caller; it alone is responsible for the
## whole-world "a cell belongs to exactly one project" invariant, since a
## single project has no way to see other projects' cell sets). Overwrites
## any earlier entry at the same address, mirroring [CommitPipeline]'s own
## "last value for a duplicate key wins" precedent.
func add_cell(blueprint_cell: BlueprintCell) -> void:
	cells[blueprint_cell.cell] = blueprint_cell
	recompute_state()


## Whether [param cell] currently belongs to this project.
func has_cell(cell: Vector3i) -> bool:
	return cells.has(cell)


## Every [BlueprintCell] currently belonging to this project.
func get_cells() -> Array[BlueprintCell]:
	var result: Array[BlueprintCell] = []
	for cell: Vector3i in cells:
		result.append(cells[cell])
	return result


## Cancels [param cell] (GDD Rule 16: "Draft -> instant cancel... Queued/
## UnderConstruction... -> instant cancel" -- claim revocation itself is a
## future story's cross-module concern, not this entity's bookkeeping) --
## valid only while the cell's own micro-state is still
## [constant BlueprintCell.MicroState.PLANNED] or
## [constant BlueprintCell.MicroState.UNDER_CONSTRUCTION]; a
## [constant BlueprintCell.MicroState.BUILT] cell can NEVER be canceled this
## way (Rule 16/17: "Canceled... Never reachable from Built" -- a Built cell
## can only leave via [method demolish_cell]). On success, marks the cell
## [constant BlueprintCell.MicroState.CANCELED], removes it from [member
## cells] (a canceled cell's address "frees up," per [CommitPipeline]'s own
## documented combined-view rule), recomputes the rollup, and returns
## `true`. Returns `false` (no-op, nothing mutated) if [param cell] is not
## tracked by this project or is already Built.
func cancel_cell(cell: Vector3i) -> bool:
	var blueprint_cell: BlueprintCell = cells.get(cell)
	if blueprint_cell == null:
		return false
	if blueprint_cell.state == BlueprintCell.MicroState.BUILT:
		return false
	blueprint_cell.state = BlueprintCell.MicroState.CANCELED
	cells.erase(cell)
	recompute_state()
	return true


## Removes [param cell] from this project on demolition completion (GDD Rule
## 14j: "Once a cell's demolition completes... the cell is gone" -- the
## actual worker-executed demolition JOB mechanics are a future story's
## scope entirely; this method is the project-membership bookkeeping half
## only, symmetric to [method cancel_cell]). Valid only while the cell's own
## micro-state is [constant BlueprintCell.MicroState.BUILT] -- a
## not-yet-Built cell is canceled ([method cancel_cell]), never demolished.
## Returns `false` (no-op) if [param cell] is not tracked by this project or
## is not yet Built.
func demolish_cell(cell: Vector3i) -> bool:
	var blueprint_cell: BlueprintCell = cells.get(cell)
	if blueprint_cell == null:
		return false
	if blueprint_cell.state != BlueprintCell.MicroState.BUILT:
		return false
	cells.erase(cell)
	recompute_state()
	return true


## Releases this project ("Bau starten", GDD Rule 14f, Story building-004,
## [TR-building-system-109]/AC57) -- ADR-0016's Key Interfaces name this
## action `release_project(project_id: int) -> void` at the future
## REGISTRY level (Story building-003's cell->project reverse-index
## registry, not yet landed); this method is the per-instance seam that
## registry will call into once it exists (`self` is already the resolved
## project -- no id lookup needed here), mirroring [method add_cell]/
## [method cancel_cell]/[method demolish_cell]'s own established "plain
## instance method, a future caller resolves/supplies the project" pattern.
##
## Transitions every currently-tracked cell into job-eligible BUILDING work
## by flipping [member state] from DRAFT to BUILDING. [method
## get_building_eligible_cells] already gates its ENTIRE return on
## `state == BUILDING` (Story building-002) -- so this one state flip alone
## satisfies AC57's "every one of its cells becomes job-eligible... and
## none of them were claimable before that action": pre-release, [method
## get_building_eligible_cells] returns empty for a DRAFT project
## structurally; post-release, every still-PLANNED cell is included,
## ordered by commit time ([TR-building-system-106]).
##
## Valid ONLY while [member state] is DRAFT and [member cells] is non-empty
## -- returns `false` (no-op, nothing mutated) otherwise: an
## already-BUILDING/PAUSED/DONE project is left untouched (resuming a
## PAUSED project back to BUILDING is Story building-006's own action,
## never this one; re-releasing an already-BUILDING project is meaningless),
## and releasing a project with no cells at all is a no-op too (QA Edge
## Case: "releasing an empty project is a no-op, no error, no phantom
## jobs") -- there is nothing to make job-eligible.
func release() -> bool:
	if state != ProjectState.DRAFT:
		return false
	if cells.is_empty():
		return false
	state = ProjectState.BUILDING
	return true


## Records worker attribution for a successful job claim (Story
## building-005, ADR-0016 Decision Sec.4, GDD Rule 12/14f,
## [TR-building-system-109], AC58) -- the ADR's own Key Interfaces name this
## `on_job_claimed(project_id: int, villager_id: int) -> void` at the future
## REGISTRY level (Story building-003, not yet landed); this method is the
## per-instance seam that registry will call into once it exists (`self` is
## already the resolved project -- no id lookup needed here), mirroring
## [method release]'s own established "registry-level signature loses its
## id param at the per-instance level" precedent.
##
## Records [param villager_id] against [param cell]'s own [member
## BlueprintCell.claimed_by_villager_id] (AC58: "the villager's id is
## recorded on that cell") and, if not already present, appends it to
## [member worker_ids] (de-duplicated aggregate) -- the same villager
## claiming a second cell of this project later is a no-op against [member
## worker_ids] (still appears exactly once) even though the second cell's own
## [member BlueprintCell.claimed_by_villager_id] is written independently.
##
## The claim mechanic (path -> arrive -> claim) is Villager AI's; this
## method's real caller is [method ConstructionJobQueue.claim_job] -- the
## SAME Building-System code that already performs the claim itself --
## attribution is recorded as that claim's own side effect, never a separate
## control decision: this method never reads or writes [member
## BlueprintCell.state] and never rejects/blocks anything. A `false` return
## means only "this project does not currently track [param cell]," never
## "the claim was refused."
##
## Returns `false` (no-op against both [member cells] and [member
## worker_ids]) if [param cell] is not currently tracked by this project --
## defensive only; [method ConstructionJobQueue.claim_job] never calls this
## for a cell it has not already resolved to this exact project.
func on_job_claimed(cell: Vector3i, villager_id: int) -> bool:
	var blueprint_cell: BlueprintCell = cells.get(cell)
	if blueprint_cell == null:
		return false
	blueprint_cell.claimed_by_villager_id = villager_id
	if not worker_ids.has(villager_id):
		worker_ids.append(villager_id)
	return true


## Contract-shape-only serialization seam (Story building-005's own AC2:
## "`worker_ids` is... included in `serialize()` (contract shape only --
## full save flow is VS-tier)"; ADR-0016 Decision Sec.7, ADR-0012 per-system
## contract). Returns a plain [Dictionary] (ADR-0012's own
## `FileAccess.store_var()/get_var()` shape, never a custom [Resource])
## carrying this class's own fields as they exist TODAY -- [member id]/
## [member kind]/[member state]/[member worker_ids]. [member restore_value]
## (Rule 14l, floor-excavation), a full [member cells] round-trip, and
## pending change/demolition orders (Rule 14h) are explicitly future
## stories' additions to this same Dictionary shape (this class's own doc
## comment precedent for "field/section lands now, a later story extends
## it") -- no `deserialize()` counterpart exists yet either, matching this
## story's own Out of Scope: "Full save/load round-trip -- VS-tier."
func serialize() -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"state": state,
		"worker_ids": worker_ids.duplicate(),
		"owner_project_id": owner_project_id,
	}


## `true` once [member cells] has become empty -- per Rule 14i/AC61, "A
## project disappears only when it becomes empty." This class does not
## delete/free ITSELF (a `RefCounted` has no such operation) -- "the project
## entity itself is deleted" is realized by a future OWNING registry (Story
## building-003) checking this method after every [method cancel_cell]/
## [method demolish_cell] call and dropping its own last reference, which
## frees this `RefCounted` normally. This story's own tests therefore treat
## `is_empty() == true` as the observable proof of AC61's "deleted."
func is_empty() -> bool:
	return cells.is_empty()


## The BUILDING-eligible job queue (Core Rule 12/Rule 14e,
## [TR-building-system-106]): every currently-[constant
## BlueprintCell.MicroState.PLANNED] cell, in commit (insertion) order --
## see [member cells]' own doc comment for why insertion order alone
## satisfies "ordered by commit time" -- but ONLY while [member state] is
## [constant ProjectState.BUILDING]. Returns an empty array for every other
## state, structurally: a DRAFT project's Planned cells are invisible here
## regardless of how many exist ("a Draft cell generates no job and is
## invisible to `claim_job`... villagers ignore it entirely"), and a PAUSED
## project offers none either ("pausing... stops offering new jobs," Rule
## 14g) even though its still-queued cells remain tracked and Planned.
## Already-[constant BlueprintCell.MicroState.UNDER_CONSTRUCTION] or
## [constant BlueprintCell.MicroState.BUILT] cells are never re-offered
## (they are not [constant BlueprintCell.MicroState.PLANNED]).
func get_building_eligible_cells() -> Array[BlueprintCell]:
	var eligible: Array[BlueprintCell] = []
	if state != ProjectState.BUILDING:
		return eligible
	for cell: Vector3i in cells:
		var blueprint_cell: BlueprintCell = cells[cell]
		if blueprint_cell.state == BlueprintCell.MicroState.PLANNED:
			eligible.append(blueprint_cell)
	return eligible


## The state rollup (TR-108/AC60/AC61) -- see class doc comment for the full
## rationale. Called by every cell-membership mutator this class owns, and
## directly callable by any future caller after mutating a tracked
## [BlueprintCell]'s own [member BlueprintCell.state] through a different
## path (e.g. a later story's construction-completion wiring). No-op while
## [member cells] is empty -- an empty project has no rollup left to
## compute; a future registry checks [method is_empty] separately to decide
## whether the entity itself should be dropped (see that method's doc
## comment).
##
## Rule: if every tracked cell is [constant BlueprintCell.MicroState.BUILT],
## the project is DONE (AC60), REGARDLESS of its prior state -- this is the
## one rollup transition this story fully owns end-to-end. Otherwise, a
## project previously DONE that has regained a not-yet-Built cell (a future
## change order, TR-112 -- always attaches to an ALREADY released/done
## project per Rule 14h) falls back to BUILDING, the correct "least-finished"
## reflection for a project that is by construction already past DRAFT.
## Every other case (DRAFT, BUILDING, PAUSED, none yet all-Built) is left
## exactly as [member state] already reads -- release()/pause()/resume()
## are explicitly future stories' own actions (see class doc comment), never
## derived from a cell-state change here.
func recompute_state() -> void:
	if cells.is_empty():
		return
	var all_built: bool = true
	for cell: Vector3i in cells:
		if cells[cell].state != BlueprintCell.MicroState.BUILT:
			all_built = false
			break
	if all_built:
		state = ProjectState.DONE
	elif state == ProjectState.DONE:
		state = ProjectState.BUILDING
