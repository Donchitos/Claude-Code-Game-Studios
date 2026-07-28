## Building System's project registry (Story building-003, ADR-0016 Decision
## Sec.2/Sec.6, GDD Rule 14c, F6, [TR-building-system-107]) -- owns every
## [BuildProject] the game currently tracks, resolves 26-neighborhood
## grouping/merge for newly-committed cells via a union-find pass over the
## WHOLE batch (Control Manifest requirement: deterministic, never
## iteration-order dependent), and maintains the cell -> project reverse
## index ([method project_at_cell]) that ADR-0010 Sec.4 Selection routing
## (and a future world-click resolution) calls into.
##
## `RefCounted`, not `Resource`/`Node` -- a plain, code-assigned shared
## collaborator, mirroring [ConstructionJobQueue]'s own "population-wide
## shared object, no Inspector-editable representation" precedent: this
## registry aggregates across EVERY project in the game, exactly as that
## class aggregates jobs across every project.
##
## Owns exactly what this story's Implementation Notes and Acceptance
## Criteria name -- the union-find grouping/merge pass (AC55/AC56, Rule 14c,
## F6) and the reverse index (this story's own "reverse index maps every
## project cell back to its owning project in O(1)" AC) -- and nothing
## else. Explicitly NOT this story's scope (see the story file's own Out of
## Scope section):
## - Story building-007: change orders (attaching to an already-released/
##   DONE project instead of merging into a Draft project) -- [method
##   assign_cells] merges into any same-kind touched project regardless of
##   its [enum BuildProject.ProjectState]; distinguishing "attach as change
##   order" from "merge as Draft" is that future story's own refinement.
## - Story building-008: the world-click -> [method project_at_cell]
##   selection routing -- this story builds the index; 008 consumes it.
## - Story building-013: the dig-kind partition rule (Rule 14m) that forbids
##   build<->dig merges -- this registry's `kind` filter already
##   structurally prevents a cross-kind merge (every touched-project lookup
##   below is gated on `existing_project.kind == kind`), but the
##   dig-producing tool itself, and Rule 14m's own dedicated edge-case
##   coverage, are that story's job.
## - Story building-018: Rule 14d's full batch-merge guarantee (a single
##   tool commit whose internally-generated sub-shapes are not all mutually
##   26-adjacent still becomes ONE project, [TR-building-system-126]/AC77)
##   -- [method assign_cells] groups purely by F6 adjacency; forcing an
##   entire commit into one project regardless of internal adjacency is a
##   separate, not-yet-tooled guarantee (no multi-shape tool exists in this
##   codebase yet, mirrors [CommitPipeline]'s own "no such tool exists yet"
##   precedent) -- AC77 is not among this story's own Acceptance Criteria.
## - Reverse-index removal on cancel/demolish -- [method
##   BuildProject.cancel_cell]/[method BuildProject.demolish_cell] already
##   exist and correctly free a project's OWN membership, but no production
##   wiring yet calls back into this registry to erase the corresponding
##   [member _cell_index] entry (no scene assembly/registry wiring exists
##   yet in this codebase, mirrors [ConstructionJobQueue.add_project]'s own
##   "a future caller registers" precedent). A future story wires this once
##   cancel/demolish flows reach a registry-aware caller.
##
## ADR-0016 Key Interfaces name [method release_project]/[method
## on_job_claimed] at this REGISTRY level -- Stories building-004/005
## implemented only the per-instance [method BuildProject.release]/[method
## BuildProject.on_job_claimed] seams and explicitly documented (their own
## doc comments) that "this story's registry wraps them." This class is
## that registry; [method release_project]/[method on_job_claimed] below
## are exactly that thin id-lookup wrapper -- no new lifecycle/attribution
## logic of their own.
class_name BuildProjectRegistry
extends RefCounted

## Every [BuildProject] this registry owns, keyed by its own [member
## BuildProject.id] -- the sole source of truth for id -> project lookup
## ([method get_project]/[method release_project]/[method on_job_claimed]).
var _projects: Dictionary[int, BuildProject] = {}

## The cell -> owning-project-id reverse index (this story's core
## contract) -- kept consistent through every [method assign_cells] call,
## including merges (an absorbed project's cells are re-keyed to the
## surviving id, never left pointing at a dropped id).
var _cell_index: Dictionary[Vector3i, int] = {}

## Monotonically-increasing id source for freshly-created projects -- lower
## ids are always earlier-created by construction, which is exactly what
## Rule 14c's "the lowest-numbered (earliest-created) project id survives"
## requires with zero extra bookkeeping.
var _next_id: int = 1


## Registers an already-constructed [BuildProject] directly (test/future-
## caller seam, mirrors [ConstructionJobQueue.add_project]'s own "a caller
## that already holds an instance registers it" precedent) -- indexes every
## one of [param project]'s current cells into [member _cell_index] and
## advances [member _next_id] past [param project]'s own id so a
## subsequently-created project never collides with a manually-registered
## one. Intended for tests exercising the same-kind filter (see class doc
## comment) and a future `deserialize()` reconstruction path; production's
## real entry point is [method assign_cells].
func register_project(project: BuildProject) -> void:
	_projects[project.id] = project
	for cell: Vector3i in project.cells:
		_cell_index[cell] = project.id
	if project.id >= _next_id:
		_next_id = project.id + 1


## Story `building-034` addition (TD ruling D3) -- a fresh, never-before-used
## project id, for a caller ([ScaffoldErectionCoordinator]) that constructs
## its OWN [BuildProject] externally (a `SCAFFOLD`-kind project is never
## produced by [method assign_cells], since scaffolding is never grouped/
## merged with player-drawn cells) and must still draw from the SAME id
## space every other project uses, never a second counter.
func allocate_project_id() -> int:
	var id: int = _next_id
	_next_id += 1
	return id


## The core grouping/merge entry point (AC55/AC56, Rule 14c, F6,
## [TR-building-system-107]) -- [signal CommitPipeline.blueprint_cells_created]'s
## real future consumer (that class's own doc comment names this exact
## seam; no production wiring exists yet, mirrors every other
## not-yet-assembled seam in this codebase).
##
## Resolves membership via a SINGLE union-find pass over the combined
## domain of [param cells]' own batch indices AND every existing same-
## [param kind] project touched by any of their 26 neighbors (Control
## Manifest requirement -- never iteration-order dependent, and correct
## even when two different, mutually-non-adjacent parts of the batch both
## happen to touch the same existing project through different faces of
## it): every pair of [param cells] that is mutually 26-adjacent (F6) ends
## up in the same component; every component that touches one or more
## existing projects merges into the lowest-numbered (earliest-created)
## touched project id, absorbing every other touched project's cells and
## worker-attribution records (Rule 14c/Edge Case 13); a component that
## touches no existing project becomes a fresh project instead.
## [member _cell_index] is kept consistent for every cell this call
## touches, including re-keying absorbed cells to the surviving id.
##
## Returns every distinct [BuildProject] this call created or merged into
## -- ordinarily one project for a normal contiguous commit, but more than
## one when [param cells] contains multiple mutually-non-adjacent groups
## that also touch no shared project (see class doc comment: forcing an
## entire commit into exactly one project regardless of internal adjacency
## is Rule 14d/Story building-018's own future guarantee, not this
## method's job). Returns an empty array for an empty [param cells] input
## (no-op).
func assign_cells(
	cells: Array[BlueprintCell], kind: BuildProject.Kind = BuildProject.Kind.BUILD
) -> Array[BuildProject]:
	if cells.is_empty():
		return []

	var cell_to_index: Dictionary[Vector3i, int] = {}
	for i: int in cells.size():
		cell_to_index[cells[i].cell] = i

	# Union-find over a combined key space: batch indices 0..N-1 (new
	# cells) plus a disjoint negative-encoded key per touched existing
	# project id (see [method _encode_existing_id]) -- both domains share
	# one `parent` map so a single pass resolves every transitive merge,
	# regardless of which order cells/neighbors are visited in.
	var parent: Dictionary[int, int] = {}
	for i: int in cells.size():
		parent[i] = i

	for i: int in cells.size():
		for neighbor: Vector3i in _neighbor_cells(cells[i].cell):
			if cell_to_index.has(neighbor):
				_union(parent, i, cell_to_index[neighbor])
			elif _cell_index.has(neighbor):
				var existing_id: int = _cell_index[neighbor]
				var existing_project: BuildProject = _projects[existing_id]
				if existing_project.kind == kind:
					var encoded: int = _encode_existing_id(existing_id)
					if not parent.has(encoded):
						parent[encoded] = encoded
					_union(parent, i, encoded)

	# Group every key in `parent` (new-cell indices AND touched existing
	# ids) by its final root -- one group per resulting/merged project.
	var group_cells: Dictionary[int, Array] = {}
	var group_existing_ids: Dictionary[int, Array] = {}
	for key: int in parent.keys():
		var root: int = _find(parent, key)
		if key >= 0:
			if not group_cells.has(root):
				group_cells[root] = []
			group_cells[root].append(key)
		else:
			if not group_existing_ids.has(root):
				group_existing_ids[root] = []
			group_existing_ids[root].append(_decode_existing_id(key))

	var results: Array[BuildProject] = []
	for root: int in group_cells:
		var member_indices: Array = group_cells[root]
		var existing_ids: Array = group_existing_ids.get(root, [])

		var survivor: BuildProject
		if existing_ids.is_empty():
			survivor = BuildProject.new(_next_id, kind)
			_next_id += 1
			_projects[survivor.id] = survivor
		else:
			existing_ids.sort()
			var survivor_id: int = existing_ids[0]
			survivor = _projects[survivor_id]
			for other_id: int in existing_ids:
				if other_id == survivor_id:
					continue
				_absorb(survivor, _projects[other_id])
				_projects.erase(other_id)

		for index: int in member_indices:
			var blueprint_cell: BlueprintCell = cells[index]
			survivor.add_cell(blueprint_cell)
			_cell_index[blueprint_cell.cell] = survivor.id

		results.append(survivor)

	return results


## The reverse index (this story's core contract) -- the owning project id
## for [param cell], or `-1` if untracked. O(1): a single [Dictionary]
## lookup, never a scan (ADR-0016 Decision Sec.6/Performance Guardrail).
func project_at_cell(cell: Vector3i) -> int:
	return _cell_index.get(cell, -1)


## The [BuildProject] currently registered under [param project_id], or
## `null` if none exists.
func get_project(project_id: int) -> BuildProject:
	return _projects.get(project_id)


## Whether a project with [param project_id] is currently registered.
func has_project(project_id: int) -> bool:
	return _projects.has(project_id)


## Every [BuildProject] this registry currently owns (no defined order
## beyond [Dictionary]'s own insertion-order guarantee).
func get_projects() -> Array[BuildProject]:
	var result: Array[BuildProject] = []
	for id: int in _projects:
		result.append(_projects[id])
	return result


## Registry-level wrapper (see class doc comment) -- ADR-0016 Key
## Interfaces' `release_project(project_id: int) -> void`, realized here as
## an id lookup + delegate to [method BuildProject.release]. Returns
## `false` (no-op) if [param project_id] is not currently registered.
func release_project(project_id: int) -> bool:
	var project: BuildProject = _projects.get(project_id)
	if project == null:
		return false
	return project.release()


## Registry-level wrapper (see class doc comment) -- ADR-0016 Key
## Interfaces' `on_job_claimed(project_id: int, villager_id: int) -> void`,
## realized here as an id lookup + delegate to [method
## BuildProject.on_job_claimed] (which additionally needs [param cell] to
## know WHICH tracked cell to attribute -- the ADR's own pseudocode omits
## it; this is the same [param cell] a real caller already resolved via
## [method project_at_cell] to find [param project_id] in the first
## place). Returns `false` (no-op) if [param project_id] is not currently
## registered.
func on_job_claimed(project_id: int, cell: Vector3i, villager_id: int) -> bool:
	var project: BuildProject = _projects.get(project_id)
	if project == null:
		return false
	return project.on_job_claimed(cell, villager_id)


## Unregisters [param cell] from the reverse index only (Story building-011,
## ADR-0016 primary, plan-only undo's own registry-aware caller --
## [PlanOnlyUndoGate] -- see this class's own doc comment's "Reverse-index
## removal on cancel/demolish" future-story note above, which named exactly
## this gap). Does not touch any [BuildProject]'s own membership -- [method
## BuildProject.cancel_cell]/[method BuildProject.demolish_cell] already
## erase a cancelled/demolished cell from the project's OWN [member
## BuildProject.cells] dictionary; this call keeps THIS registry's separate
## reverse index consistent with that removal, so a later commit at the same
## address is never blocked by a stale entry. A no-op if [param cell] is not
## currently indexed.
func unregister_cell(cell: Vector3i) -> void:
	_cell_index.erase(cell)


## Drops [param project] from this registry entirely (Story building-011) --
## the caller-driven realization of AC61/Rule 14i's "the project entity
## itself is deleted": a registry-aware caller (today, [PlanOnlyUndoGate])
## checks [method BuildProject.is_empty] after a cancel/demolish that empties
## it and calls this to drop the registry's own last reference. Mirrors
## [method ConstructionJobQueue.remove_project]'s identically-named
## counterpart -- a caller that also registered [param project] with that
## queue is expected to call both, keeping every aggregator in sync. A no-op
## if [param project]'s id is not currently registered.
func remove_project(project: BuildProject) -> void:
	_projects.erase(project.id)


## Merges [param absorbed]'s cells and worker-attribution history into
## [param survivor] (Rule 14c: "absorbs the others' cells and worker-
## attribution records") -- called only from within [method assign_cells]'s
## own merge branch, never directly.
func _absorb(survivor: BuildProject, absorbed: BuildProject) -> void:
	for blueprint_cell: BlueprintCell in absorbed.get_cells():
		survivor.add_cell(blueprint_cell)
		_cell_index[blueprint_cell.cell] = survivor.id
	for villager_id: int in absorbed.worker_ids:
		if not survivor.worker_ids.has(villager_id):
			survivor.worker_ids.append(villager_id)


## Every cell 26-adjacent to [param cell] (F6, full 3D Moore neighborhood)
## -- all 26 combinations of a {-1, 0, 1} offset per axis, excluding the
## origin offset itself. Recomputed fresh per call (cheap: exactly 26
## [Vector3i] additions) rather than a stored constant, sidestepping
## GDScript's compile-time-only `const` restriction for a derived-per-cell
## array.
static func _neighbor_cells(cell: Vector3i) -> Array[Vector3i]:
	var neighbors: Array[Vector3i] = []
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			for dz: int in range(-1, 2):
				if dx == 0 and dy == 0 and dz == 0:
					continue
				neighbors.append(cell + Vector3i(dx, dy, dz))
	return neighbors


## Encodes an existing project id into the union-find's negative key
## sub-space (see [method assign_cells]'s own doc comment) -- disjoint from
## every non-negative batch index by construction (`-id - 1 <= -2` for any
## `id >= 1`, since project ids start at 1).
static func _encode_existing_id(project_id: int) -> int:
	return -project_id - 1


## Inverse of [method _encode_existing_id].
static func _decode_existing_id(encoded_key: int) -> int:
	return -encoded_key - 1


## Union-find `find` with path compression -- see [method assign_cells].
static func _find(parent: Dictionary, key: int) -> int:
	var root: int = key
	while parent[root] != root:
		root = parent[root]
	while parent[key] != root:
		var next_key: int = parent[key]
		parent[key] = root
		key = next_key
	return root


## Union-find `union` -- see [method assign_cells]. Which root survives
## the union is arbitrary and NEVER affects which PROJECT id survives --
## that decision is [method assign_cells]'s own `existing_ids.sort()` step,
## entirely independent of union-find root bookkeeping.
static func _union(parent: Dictionary, a: int, b: int) -> void:
	var root_a: int = _find(parent, a)
	var root_b: int = _find(parent, b)
	if root_a != root_b:
		parent[root_b] = root_a
