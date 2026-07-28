## Static walkability-predicate library (Story villager-ai-026, behavior-
## preserving extraction; ADR-0007 Decision §1 "Villager AI owns the
## walkability predicates as shared pure functions"; TD ruling BV-4 in
## `production/architecture-decisions-m02-preflight-2026-07-26.md`).
##
## [method is_standable], [method is_step_legal], [method body_column] and
## [method is_cell_in_body_column] were instance methods on [VillagerAi] (a
## `Node` carrying `villager_id`, `config`, `voxel_world`, scheduler, nav
## graph, telemetry), but their bodies read only a [VoxelWorldGrid] reference
## plus the two constants below -- no per-villager state whatsoever. Every
## [VillagerAi] instance therefore returns identical answers for identical
## inputs, so "which villager does a consumer inject?" never had a meaningful
## answer. Injecting a [VillagerAi] would encode a lie about the dependency,
## would break once `villager-ai-021` makes the roster plural, and would bake
## a freed-reference hazard into any consumer that outlives a despawned
## villager (Build Validation chief among them, per BV-4).
##
## This class is the fix: a `RefCounted`, **static-functions-only** twin,
## never instantiated anywhere in `src/` (Control Manifest Feature Layer
## Guardrail -- grep-verifiable via `VillagerWalkabilityRules.new(`).
## [VillagerAi] keeps `is_standable`/`is_step_legal`/`body_column`/
## `is_cell_in_body_column` as one-line delegations with unchanged
## signatures, so every existing call site -- including
## [VillagerNavGraph]'s `predicate_source` reads and
## [constant VillagerAi.VILLAGER_CLEARANCE]/[constant VillagerAi.MAX_STEP_HEIGHT] --
## compiles and behaves unchanged. A consumer with no villager reference to
## hold (Build Validation) calls this class directly and statically:
## `VillagerWalkabilityRules.is_standable(voxel_world, cell)` -- it already
## injects `voxel_world`, gains no new dependency, and cannot be null-ref'd
## by a despawned villager.
##
## Mechanical move only (this story introduces no behavior change): the only
## textual edit versus the pre-move bodies is the explicit `voxel_world`
## first parameter substituting for the implicit member read, and
## re-pointing the `_is_solid`/`_is_passable` calls at their static twins
## below. Cross-module static utility calls are already sanctioned and in
## use in this codebase ([VillagerAi] itself calls
## [method VoxelWorldGrid.cell_to_world] statically;
## [method VoxelWorldGrid._pure_terrain_height] is the same precedent).
##
## Explicitly out of scope (BV-4 §6, post-M02 tech debt): the `*_after_write`
## override-aware twins (`_is_standable_after_write`, `_is_step_legal_after_write`,
## `_is_solid_after_write`, `_is_passable_after_write`) stay on [VillagerAi]
## unchanged -- they are the one sanctioned duplication of this control flow
## today; an overlay-predicate parameter unifying them with this class is a
## later story. **Story `building-034` threads the scaffold source through
## both shapes (see below); it does NOT unify them (TD ruling D1, explicit).**
##
## **Scaffolding amendment (ADR-0007 §1a/§1b/§2a, story `building-034`,
## 2026-07-27).** [method is_standable]/[method is_step_legal] gain ONE
## explicit, DEFAULTED `scaffold_source` parameter -- a second occupancy
## source alongside [param voxel_world] (D1: scaffolding is NOT voxel data,
## mirrors the BV-1 furniture ruling). A caller that passes nothing (Build
## Validation, everywhere in `src/build_validation/`) observes EXACTLY
## pre-amendment behaviour -- structurally, not by discipline. `scaffold_source`
## is duck-typed against ONE method, an O(1) keyed read:
## `func has_scaffold(cell: Vector3i) -> bool` -- [ScaffoldRegistry] is the
## concrete implementation; no structural search (support/cantilever/
## connectivity) may ever run inside these predicates (ADR-0007 §1a binding
## performance clause) -- those are erection-time planning rules only.
class_name VillagerWalkabilityRules
extends RefCounted


## Vertical clearance a standable cell requires: the cell itself plus the
## two cells directly above it must all be empty (GDD Rule 8/8a,
## [TR-villager-ai-behavior-009]/[TR-villager-ai-behavior-098]'s body-column
## definition -- the 2-cell body plus one buffer cell of headroom). A
## registered design constant (`design/registry/entities.yaml`'s
## `villager_clearance` = 3), not a tunable knob -- same locked-constant
## rationale as [VoxelWorldGrid.CHUNK_SIZE]; deliberately absent from
## [VillagerAIConfig] (ADR-0007: "no duplicated constants, anywhere").
## Declared HERE and nowhere else (BV-4 §2) -- [constant VillagerAi.VILLAGER_CLEARANCE]
## is a re-export alias of this value, not a second declaration.
const VILLAGER_CLEARANCE: int = 3

## Maximum legal height difference between two adjacent standable cells
## (GDD Rule 9, [TR-villager-ai-behavior-010]). A registered design constant
## (`design/registry/entities.yaml`'s `max_step_height` = 1), not a tunable
## knob -- same locked-constant rationale as [constant VILLAGER_CLEARANCE].
## Declared HERE and nowhere else (BV-4 §2) -- [constant VillagerAi.MAX_STEP_HEIGHT]
## is a re-export alias of this value, not a second declaration.
const MAX_STEP_HEIGHT: int = 1


## Standability predicate (ADR-0007 Decision §1, GDD Rule 8/[TR-villager-ai-
## behavior-009]): [param cell] is standable iff the cell directly below it
## is solid (occupied -- terrain or a Built block) AND [param cell] itself
## plus the [constant VILLAGER_CLEARANCE] - 1 cells directly above it are all
## empty (GDD Rule 8a's body-column: the 2-cell body plus one buffer cell of
## headroom).
##
## An unbuilt Planned blueprint cell is never written to [param voxel_world]
## (Control Manifest Core Layer: "Built cells mutate ONLY via worker-executed
## jobs") -- it reads back empty via [method VoxelWorldGrid.get_cell], so it
## is non-solid/passable here BY CONSTRUCTION, matching Building System Core
## Rule 14b / GDD AC17 with no special-case branch needed.
##
## Pure query: reads only [param voxel_world]'s cell data (and, since the
## scaffolding amendment, [param scaffold_source]'s O(1) membership), never
## mutates anything, caches nothing of its own (Control Manifest Feature
## Layer Guardrail: "predicates are pure queries... no mutation, no caching
## state of their own"). A cell outside the configured world bounds reads
## back `null` from [method VoxelWorldGrid.get_cell] and is treated as
## blocking by both helpers below -- the world simply does not extend there,
## so it can neither support a foot (never solid-below) nor offer clearance
## (never passable).
##
## **§1a (ADR-0007, story `building-034`): a scaffold cell is standable
## WITHOUT a solid cell beneath it -- scaffolding supports itself.** The
## solid-below requirement becomes `(solid below) OR (this cell is a
## scaffold cell)`; the clearance-column check is completely unchanged (a
## scaffold cell is always passable in the raw grid -- D9 forbids it ever
## occupying an address that reads solid). [param scaffold_source] defaults
## to `null`, which is structurally identical to "never scaffold" -- the
## exact pre-amendment behaviour.
static func is_standable(
	voxel_world: VoxelWorldGrid, cell: Vector3i, scaffold_source: Object = null
) -> bool:
	assert(voxel_world != null, "VillagerWalkabilityRules.is_standable requires voxel_world")
	var solid_below: bool = _is_solid(voxel_world, cell + Vector3i(0, -1, 0))
	if not solid_below and not _has_scaffold(scaffold_source, cell):
		return false
	for offset in range(VILLAGER_CLEARANCE):
		if not _is_passable(voxel_world, cell + Vector3i(0, offset, 0)):
			return false
	return true


## Step-legality predicate (ADR-0007 Decision §1, GDD Rule 9/[TR-villager-ai-
## behavior-010]): a step from [param from_cell] to [param to_cell] is legal
## iff the vertical height difference is at most [constant MAX_STEP_HEIGHT],
## AND -- only when the step is diagonal (both the X and Z coordinates
## differ; a purely orthogonal step never runs this second check at all) --
## both flanking orthogonal cells (the cell at `(to_cell.x, from_cell.y,
## from_cell.z)` and the cell at `(from_cell.x, from_cell.y, to_cell.z)`) are
## themselves standable ([method is_standable]) -- no corner-cutting through
## walls.
##
## Assumes [param from_cell] and [param to_cell] are themselves standable --
## the caller (the AStar3D graph builder, story 007) only ever connects
## standable-cell pairs via this predicate, so re-verifying that here would
## duplicate [method is_standable]'s own job. Pure query, no mutation, no
## cached state (same guardrail as [method is_standable]).
##
## **§2a clause 2 (ADR-0007, story `building-034`, LOAD-BEARING): a
## same-column step (`dx = 0 and dz = 0`) is legal ONLY if BOTH endpoints are
## scaffold cells.** Before this amendment, a same-column pair could never
## reach this predicate at all -- two stacked cells could never both be
## standable (no scaffold-supports-itself clause existed). §1a removes
## exactly that structural prevention, so without this explicit gate,
## `|dy| <= MAX_STEP_HEIGHT` alone would silently accept a same-column step
## between an ordinary standable cell and a scaffold cell directly above/
## below it -- general climbing, never intended. This gate is checked FIRST,
## before the diagonal flank check (which never runs for a same-column pair
## anyway, since `dx == 0 and dz == 0`).
static func is_step_legal(
	voxel_world: VoxelWorldGrid, from_cell: Vector3i, to_cell: Vector3i, scaffold_source: Object = null
) -> bool:
	if absi(to_cell.y - from_cell.y) > MAX_STEP_HEIGHT:
		return false
	var dx: int = to_cell.x - from_cell.x
	var dz: int = to_cell.z - from_cell.z
	if dx == 0 and dz == 0:
		var from_is_scaffold: bool = _has_scaffold(scaffold_source, from_cell)
		var to_is_scaffold: bool = _has_scaffold(scaffold_source, to_cell)
		if from_is_scaffold and to_is_scaffold:
			return true  # §2a: the one new edge class.
		if from_is_scaffold or to_is_scaffold:
			return false  # Never climb between ordinary ground and scaffolding.
		# NEITHER endpoint is scaffold: fall through to the pre-amendment rules
		# and return exactly what this predicate returned before story 034.
		#
		# This clause is load-bearing and was MISSING in the first cut, which
		# turned the whole suite red. The amendment's binding promise is that a
		# caller passing no scaffold_source observes EXACTLY pre-amendment
		# behaviour. Refusing every same-column step broke that promise: the
		# predicate used to fall through to the |dy| <= MAX_STEP_HEIGHT check
		# and return true here, and villager-ai-024's wall fix depends on it —
		# its regression test dropped straight back to 27/30.
		#
		# The TD's rationale for the blanket refusal was that two stacked
		# ordinary cells can never both be standable, so the case never
		# arises. That is true of callers which check standability first, and
		# NOT true of every caller. Structural safety still holds without the
		# blanket refusal: §1a relaxes solid-below only FOR scaffold cells, so
		# two ordinary stacked cells still cannot both stand, and the
		# one-endpoint-scaffold case above is what actually closes general
		# climbing.
	if dx != 0 and dz != 0:
		var flanker_a := Vector3i(to_cell.x, from_cell.y, from_cell.z)
		var flanker_b := Vector3i(from_cell.x, from_cell.y, to_cell.z)
		if (
			not is_standable(voxel_world, flanker_a, scaffold_source)
			or not is_standable(voxel_world, flanker_b, scaffold_source)
		):
			return false
	return true


## Body-column derivation (Story villager-ai-003, ADR-0009 slice-propagation
## Decision §2/Key Interfaces, GDD Rule 8a/[TR-villager-ai-behavior-098],
## Control Manifest Core Layer: "Occupancy is a body-column, not a single
## cell"): the villager's own space is a 3-cell vertical span -- the 2-cell
## body (feet + head) plus one buffer headroom cell -- derived
## deterministically from a single discrete cell, exactly the same span
## [method is_standable] already checks for standability clearance
## ([constant VILLAGER_CLEARANCE] -- no second constant is introduced).
## Shared by the Unstuck Watchdog (stories 014/015) and seal-prevention/
## walled-in queries (story 016) so they use ONE source of truth instead of
## each re-deriving an equivalent span locally.
##
## Interpolation-free by construction: [param cell] is a plain `Vector3i` --
## there is no villager instance, `current_cell`, or `_visual_position`
## anywhere in this function's signature or body, so it cannot accidentally
## read interpolation state. Callers are responsible for always passing the
## authoritative discrete `current_cell` (ADR-0009 Decision §1), never a
## visual/interpolated position.
##
## Pure query: no mutation, no cached state, identical inputs always yield
## an identical result (the same purity guarantee as [method is_standable] /
## [method is_step_legal]).
static func body_column(cell: Vector3i) -> Array[Vector3i]:
	var column: Array[Vector3i] = []
	for offset in range(VILLAGER_CLEARANCE):
		column.append(cell + Vector3i(0, offset, 0))
	return column


## Occupancy predicate against a villager's body-column (ADR-0009
## slice-propagation Decision §2/§2b, Control Manifest Core Layer: "Seal
## prevention is a negative-write gate the Building System write path MUST
## accept" -- this is the shared predicate that gate, and the Watchdog's
## rescue/trigger checks, read). Returns whether [param query_cell] falls
## within the body-column occupying [param occupant_cell] -- i.e. whether a
## villager standing at [param occupant_cell] occupies [param query_cell].
##
## Deliberately NOT a feet-only comparison (`query_cell == occupant_cell`):
## the body cell directly above the feet, and the buffer headroom cell above
## that, are also occupied, and a write there must be caught by
## seal-prevention exactly as a write at the feet cell would be.
##
## Pure query: delegates entirely to [method body_column]; no mutation, no
## cached state.
static func is_cell_in_body_column(occupant_cell: Vector3i, query_cell: Vector3i) -> bool:
	return body_column(occupant_cell).has(query_cell)


## Solidity read for [method is_standable]'s "solid below" check -- an
## out-of-bounds cell ([method VoxelWorldGrid.get_cell] returns `null`) is
## never solid (there is nothing to stand ON there).
static func _is_solid(voxel_world: VoxelWorldGrid, cell: Vector3i) -> bool:
	var contents: CellContents = voxel_world.get_cell(cell)
	return contents != null and not contents.is_empty()


## Passability read for [method is_standable]'s clearance-column check -- an
## out-of-bounds cell is never passable (the world doesn't extend there, so
## clearance can't be confirmed).
static func _is_passable(voxel_world: VoxelWorldGrid, cell: Vector3i) -> bool:
	var contents: CellContents = voxel_world.get_cell(cell)
	return contents != null and contents.is_empty()


## The O(1) duck-typed scaffold-membership read every predicate above
## consults (ADR-0007 §1a/§1b, story `building-034`). A `null`
## [param scaffold_source] (the default, and Build Validation's own explicit
## choice everywhere) is structurally "never scaffold" -- never a crash, never
## a special-cased branch at any call site.
static func _has_scaffold(scaffold_source: Object, cell: Vector3i) -> bool:
	if scaffold_source == null:
		return false
	@warning_ignore("unsafe_method_access")
	return bool(scaffold_source.has_scaffold(cell))
