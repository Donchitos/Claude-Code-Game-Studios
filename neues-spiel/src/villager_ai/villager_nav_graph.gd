## AStar3D-backed shared travel-pathfinding graph (Story villager-ai-007,
## ADR-0007 Decision Section 2: "Villager AI's own travel pathfinding uses
## `AStar3D`... built once at boot... queried via `get_id_path()`/
## `get_point_path()`").
##
## **Architecture note** -- ONE instance for the whole villager population,
## never one per villager. ADR-0007's Performance Implications section is
## explicit: "Memory: One AStar3D instance holding the settlement-core
## region's standable cells" -- a per-[VillagerAi]-instance graph would
## duplicate tens of thousands of points across a population of up to 30
## villagers, for zero benefit (every villager's graph would be byte-for-byte
## identical). This is the SAME "separate shared collaborator, factored out
## of any single [VillagerAi] instance" resolution
## [VillagerDecidingScheduler] already applied to ADR-0008's per-tick budget
## for exactly this class of reason -- see that class's own doc comment for
## the full rationale this one mirrors. Deliberately a plain [RefCounted]
## (no Inspector authoring need, no scene-tree presence needed), constructed
## once by whichever code assembles the villager population (a headless
## test, or a future boot/world-generation story) and shared read-only by
## every consumer thereafter -- wiring it into [VillagerAi]'s own Traveling
## state is story villager-ai-009's scope, out of this story entirely.
##
## **Predicates, not a second copy of walkability** (ADR-0007 Decision
## Section 1 / Control Manifest Feature Layer: "EVERY consumer... calls
## these same two functions -- single source of truth"): [method build]
## takes a `predicate_source` parameter (a [VillagerAi] reference in
## practice, since that is the sole implementer of [method
## VillagerAi.is_standable]/[method VillagerAi.is_step_legal] this codebase
## has) and calls ONLY those two functions to decide which cells become
## points and which pairs become connections -- this class never re-derives
## an equivalent standability/step-legality rule of its own, and never reads
## [VoxelWorldGrid] cell contents directly (the one exception is [method
## VoxelWorldGrid.cell_to_world], the single source of truth for cell<->world
## conversion, reused here rather than a second, locally-duplicated formula).
##
## Story villager-ai-008 (this revision) implements ADR-0007 Decision Section
## 2's "incrementally patched -- not rebuilt -- whenever a Voxel World write
## changes standability or step-legality" ([TR-villager-ai-behavior-036]):
## [method subscribe_to_voxel_world] connects this graph to a
## [VoxelWorldGrid]'s [signal VoxelWorldGrid.cell_changed]/
## [signal VoxelWorldGrid.cells_changed_batch] with Godot's DEFAULT
## (synchronous, NEVER `CONNECT_DEFERRED`) connection flags -- the race this
## story's QA plan names explicitly depends on the patch landing in the SAME
## call stack as the write (ADR-0009's already-established synchronous-
## signal race closure). [method patch_cell]/[method patch_cells] recompute
## standability/step-legality (via [param predicate_source]'s [method
## VillagerAi.is_standable]/[method VillagerAi.is_step_legal], never a
## re-derived copy) for ONLY the changed cell(s) plus a bounded clearance/
## step neighborhood -- add/remove points and connections there, never
## `_astar.clear()`, never re-running [method build]. A dig/demolition write
## (solid -> air) patches through the IDENTICAL code path as a build write
## (air -> solid): neither [method patch_cell] nor [method
## _on_voxel_world_cell_changed] inspects `before`/`after` at all, only
## re-queries CURRENT state, which already reflects the write by the time the
## signal fires ([method VoxelWorldGrid.set_cell] applies the write BEFORE
## emitting). Idempotent ID reuse (this story's AC: "re-adding a
## previously-removed cell reuses the same ID") falls out of [method
## cell_to_astar_id]'s existing pure-function determinism with no extra code
## -- there is no counter to drift in the first place.
class_name VillagerNavGraph
extends RefCounted

## Bit width per axis field of the deterministic point-id packing (ADR-0007
## Key Interfaces: `x&0x1FFFFF | y<<21 | z<<42`) -- 21 bits comfortably covers
## both the current (2048) and 16k production world extents (2^21 ~= 2.09M),
## with room to spare on every axis.
const AXIS_BITS: int = 21

## Bitmask for one 21-bit axis field (`(1 << 21) - 1`).
const AXIS_MASK: int = 0x1FFFFF

## The 4 horizontal (dx, dz) neighbor offsets that, taken together with their
## negations, cover exactly the 8 horizontal neighbors of a cell (GDD Rule 9:
## orthogonal + flanked-diagonal steps) -- deliberately only HALF of the 8
## directions. [method build]'s connection pass visits every standable cell
## as a "from" cell exactly once, so processing only this canonical half here
## (rather than all 8) means each UNORDERED neighbor pair is evaluated
## exactly once, never twice -- [method build]'s own doc comment explains why
## that matters (Villager AI's [method VillagerAi.is_step_legal] is not
## guaranteed symmetric for a diagonal step with a height difference, so
## "evaluate each ordered direction independently, exactly once each" is the
## correct, non-redundant connection strategy, not an accidental
## simplification).
const HORIZONTAL_HALF_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
]

## The 3 vertical offsets a legal step may span (GDD Rule 9:
## `|height difference| <= 1`) -- checked against every horizontal neighbor
## column, since a standable cell's neighbor column may hold a standable cell
## at a different Y (a step up or down, e.g. a staircase).
const VERTICAL_STEP_OFFSETS: Array[int] = [-1, 0, 1]

## Story `building-034` (ADR-0007 §2a clause 1) -- the ONLY same-column
## (`dx = 0, dz = 0`) candidate offsets this graph ever offers, and the only
## place `(0, +-1, 0)` appears anywhere in this class's candidate generation.
## Reused verbatim by [method VillagerAi.would_trap_builder]'s own escape-
## route search (§1b) -- never a second, independently-declared same-column
## offset pair. Legality is still gated entirely by [method
## VillagerWalkabilityRules.is_step_legal]'s own explicit same-column refusal
## (§2a clause 2) -- offering the candidate here does not itself admit it.
const VERTICAL_SAME_COLUMN_OFFSETS: Array[int] = [-1, 1]

## The underlying AStar3D graph. Never exposed directly to a consumer --
## every read goes through [method find_path]/[method has_point] so this
## class stays the sole owner of the id-packing scheme.
var _astar: AStar3D = AStar3D.new()

## True once [method build] has completed at least once (observability for
## tests/callers -- e.g. asserting a query against an unbuilt graph behaves
## sanely rather than silently returning garbage).
var _is_built: bool = false


## Deterministic `Vector3i -> int64` point-id packing (ADR-0007 Key
## Interfaces, this story's AC: "the same cell always yields the same ID; no
## counter state"). Pure and stateless -- collision-free for every
## non-negative cell coordinate this project's fixed-origin world (Core Rule
## 1: no negative cell coordinates) can ever produce, up to [constant
## AXIS_MASK] (~2.09M) per axis, far beyond both the current (2048) and 16k
## production world extents. Deliberately NEVER an incrementing counter
## (ADR-0007 Risk: counter-based ids drift/collide under `remove_point()`
## churn -- story villager-ai-008's incremental-patch scope; this scheme has
## no counter state to drift in the first place).
static func cell_to_astar_id(cell: Vector3i) -> int:
	return (
		(cell.x & AXIS_MASK)
		| ((cell.y & AXIS_MASK) << AXIS_BITS)
		| ((cell.z & AXIS_MASK) << (AXIS_BITS * 2))
	)


## Inverse of [method cell_to_astar_id] -- round-trips a point id produced by
## that function back to its originating cell. Never itself required by
## AStar3D (whose own [method AStar3D.get_point_path] already returns world
## positions directly) -- exists purely as a convenience for [method
## find_path]'s `get_id_path()` variant and for tests asserting the packing
## scheme's own round-trip/no-collision guarantee.
static func astar_id_to_cell(id: int) -> Vector3i:
	return Vector3i(
		id & AXIS_MASK,
		(id >> AXIS_BITS) & AXIS_MASK,
		(id >> (AXIS_BITS * 2)) & AXIS_MASK,
	)


## Builds the graph once from Voxel World's CURRENT terrain (this story's AC:
## "built once at boot... one point per standable cell (via `is_standable`),
## connections for every legal-step pair (via `is_step_legal`)"), bounded to
## an `region_size` x `region_size` horizontal window centered on
## [param region_center] (ADR-0007's bounded settlement-core region,
## [member VillagerAIConfig.nav_region_size] -- "never the full world") and
## the full configured vertical extent ([param voxel_world]'s own [member
## VoxelWorldConfig.min_y]/[member VoxelWorldConfig.max_y] -- the ADR's
## "200x200" figure is explicitly horizontal-only, matching
## [member VoxelWorldConfig.settlement_radius_chunks]'s own horizontal-only
## precedent). A region edge that extends past the world's own configured
## bounds simply contributes no points there -- [method
## VillagerAi.is_standable] already reads back `false` for any cell [method
## VoxelWorldGrid.get_cell] reports out of bounds, so no special-case
## clamping is needed here for that edge case.
##
## Idempotent/re-buildable: clears any previous graph state first, so calling
## this again fully rebuilds from scratch rather than accumulating stale
## points/connections -- incremental patching in response to a single Voxel
## World write (never a full rebuild per edit) is story villager-ai-008's
## explicit scope, not this one.
##
## Two passes, in order (a connection can only be added between cells that
## already exist as points): (1) walk every cell in the bounded region,
## adding a point for each one [param predicate_source] reports standable
## via [method VillagerAi.is_standable]; (2) for every standable cell added in
## pass 1, walk its [constant HORIZONTAL_HALF_OFFSETS] x
## [constant VERTICAL_STEP_OFFSETS] neighbor candidates and connect any that
## are ALSO points (added in pass 1) and pass [method VillagerAi.is_step_legal]
## -- see that check's own per-direction handling below for why it is
## evaluated independently in each direction rather than assumed symmetric.
func build(
	voxel_world: VoxelWorldGrid,
	predicate_source: VillagerAi,
	region_center: Vector3i,
	region_size: int,
) -> void:
	assert(voxel_world != null, "VillagerNavGraph.build requires voxel_world")
	assert(predicate_source != null, "VillagerNavGraph.build requires predicate_source")
	assert(voxel_world.config != null, "VillagerNavGraph.build requires voxel_world.config wired")
	_astar.clear()
	_is_built = false

	var half: int = region_size / 2
	var min_x: int = region_center.x - half
	var max_x: int = min_x + region_size - 1
	var min_z: int = region_center.z - half
	var max_z: int = min_z + region_size - 1
	var min_y: int = voxel_world.config.min_y
	var max_y: int = voxel_world.config.max_y

	var standable_cells: Array[Vector3i] = []
	for x in range(min_x, max_x + 1):
		for z in range(min_z, max_z + 1):
			for y in range(min_y, max_y + 1):
				var cell := Vector3i(x, y, z)
				if predicate_source.is_standable(cell):
					var id: int = VillagerNavGraph.cell_to_astar_id(cell)
					_astar.add_point(id, VoxelWorldGrid.cell_to_world(cell))
					standable_cells.append(cell)

	for from_cell: Vector3i in standable_cells:
		var from_id: int = VillagerNavGraph.cell_to_astar_id(from_cell)
		for offset: Vector2i in HORIZONTAL_HALF_OFFSETS:
			for dy: int in VERTICAL_STEP_OFFSETS:
				var to_cell := Vector3i(from_cell.x + offset.x, from_cell.y + dy, from_cell.z + offset.y)
				var to_id: int = VillagerNavGraph.cell_to_astar_id(to_cell)
				if not _astar.has_point(to_id):
					continue
				_connect_if_legal(predicate_source, from_cell, from_id, to_cell, to_id)
		# Story `building-034` (ADR-0007 §2a clause 1) -- the same-column
		# vertical edge class. Only `(0, +1, 0)` here, mirroring
		# [constant HORIZONTAL_HALF_OFFSETS]'s own "visit each unordered pair
		# exactly once from a full, fresh scan" discipline: every standable
		# cell is visited as `from_cell` exactly once, so offering only the
		# upward direction here still reaches every same-column pair (the
		# downward direction is the SAME pair, visited from its own upper
		# cell's own turn through this same loop).
		var above_cell := from_cell + Vector3i(0, 1, 0)
		var above_id: int = VillagerNavGraph.cell_to_astar_id(above_cell)
		if _astar.has_point(above_id):
			_connect_if_legal(predicate_source, from_cell, from_id, above_cell, above_id)

	_is_built = true


## Connects [param from_id]<->[param to_id] according to [method
## VillagerAi.is_step_legal]'s result in EACH direction, evaluated
## INDEPENDENTLY -- deliberately not assumed symmetric. [method
## VillagerAi.is_step_legal]'s diagonal flanking check reads both flanker
## cells at `from_cell.y` (that predicate's own, already-shipped
## implementation, story villager-ai-002, out of this story's scope to
## alter) -- so for a diagonal step spanning a height difference, legality
## can genuinely differ between the A->B and B->A directions (a corner
## blocked from one cell's own floor height need not be blocked from the
## other's). A single `AStar3D.connect_points(a, b, true)` bidirectional call
## would silently assume symmetry and could admit an illegal reverse step, or
## reject a legal forward one -- verified against the live engine (Godot
## 4.7-stable) that calling `connect_points(a, b, false)` then, separately,
## `connect_points(b, a, false)` correctly yields a fully bidirectional
## connection when both directions are legal, and a one-way connection when
## only one is -- so exactly one `connect_points` call is made per direction
## that is actually legal, never a blind bidirectional call.
func _connect_if_legal(
	predicate_source: VillagerAi, from_cell: Vector3i, from_id: int, to_cell: Vector3i, to_id: int
) -> void:
	var forward_legal: bool = predicate_source.is_step_legal(from_cell, to_cell)
	var backward_legal: bool = predicate_source.is_step_legal(to_cell, from_cell)
	if forward_legal and backward_legal:
		_astar.connect_points(from_id, to_id, true)
	elif forward_legal:
		_astar.connect_points(from_id, to_id, false)
	elif backward_legal:
		_astar.connect_points(to_id, from_id, false)


## Whether [method build] has completed at least once.
func is_built() -> bool:
	return _is_built


## Whether [param cell] is a point in this graph (i.e. was standable at the
## most recent [method build] call) -- observability for tests and future
## consumers (story villager-ai-008's incremental patching will need this to
## decide add-vs-remove).
func has_point(cell: Vector3i) -> bool:
	return _astar.has_point(VillagerNavGraph.cell_to_astar_id(cell))


## Direct edge existence -- exposed for tests (and any future consumer
## needing "can this exact step be taken right now" without running a full
## shortest-path search) via `AStar3D`'s own `are_points_connected()`.
## [param bidirectional] defaults to `true` (matching [method
## AStar3D.are_points_connected]'s own default) -- pass `false` to ask about
## ONLY the [param from_cell] -> [param to_cell] direction specifically,
## relevant for the asymmetric-legality case [method _connect_if_legal]'s own
## doc comment describes (verified against the live engine: with a one-way
## connection A->B only, `are_points_connected(A, B, false)` is `true` while
## `are_points_connected(B, A, false)` is `false`). Returns `false`
## immediately if either cell is not currently a point in the graph.
func has_direct_connection(from_cell: Vector3i, to_cell: Vector3i, bidirectional: bool = true) -> bool:
	var from_id: int = VillagerNavGraph.cell_to_astar_id(from_cell)
	var to_id: int = VillagerNavGraph.cell_to_astar_id(to_cell)
	if not _astar.has_point(from_id) or not _astar.has_point(to_id):
		return false
	return _astar.are_points_connected(from_id, to_id, bidirectional)


## Shortest-path query (ADR-0007 Decision Section 2: "queried via
## `get_id_path()`/`get_point_path()`"). Returns the path as an ordered
## `Array[Vector3i]` of cells INCLUDING both endpoints, via `AStar3D`'s own
## `get_id_path()` unpacked back through [method astar_id_to_cell] -- never a
## second, hand-rolled path-search algorithm. Returns an empty array if
## either endpoint is not currently a point in the graph, or if no path
## connects them (this story's edge case: "unreachable target returns an
## empty path"). A [param from_cell] equal to [param to_cell] (both the same
## point) returns a single-element array containing just that one cell --
## [method path_length_cells] of a single-element path is `0.0`, F1's "target
## is the current/adjacent cell... immediate arrival" (verified against the
## live engine: `AStar3D.get_id_path(id, id)` returns `[id]`, not an empty
## array).
func find_path(from_cell: Vector3i, to_cell: Vector3i) -> Array[Vector3i]:
	var from_id: int = VillagerNavGraph.cell_to_astar_id(from_cell)
	var to_id: int = VillagerNavGraph.cell_to_astar_id(to_cell)
	if not _astar.has_point(from_id) or not _astar.has_point(to_id):
		return []
	var ids: PackedInt64Array = _astar.get_id_path(from_id, to_id)
	var path: Array[Vector3i] = []
	for id: int in ids:
		path.append(VillagerNavGraph.astar_id_to_cell(id))
	return path


## GDD F1's path-length classification summed over every consecutive step of
## [param path] -- orthogonal = `1.0`, diagonal = `1.4`, via [method
## VillagerAi.classify_step_length_cells] (the SAME static classifier
## [VillagerAi]'s own Traveling-step math uses, reused here rather than
## re-derived -- Control Manifest Feature Layer: "never duplicate... rules or
## constants" applies equally to this F1 formula, not only to walkability).
## A `path` of fewer than 2 cells (empty -- unreachable, per [method
## find_path] -- or a single cell -- already-arrived) returns `0.0`,
## matching this story's AC: "a target on the current/adjacent cell yields
## length 0."
static func path_length_cells(path: Array[Vector3i]) -> float:
	if path.size() < 2:
		return 0.0
	var total: float = 0.0
	for i in range(path.size() - 1):
		total += VillagerAi.classify_step_length_cells(path[i], path[i + 1])
	return total


## GDD F1: `travel_time_game_seconds = path_length_cells / move_speed`. A
## [param length_cells] of `0.0` (or less, defensively) short-circuits to
## `0.0` immediately -- this story's AC: "`path_length_cells = 0` (target is
## current/adjacent cell) yields immediate arrival" -- regardless of
## [param move_speed]'s value, never a division at all in that case.
static func travel_time_game_seconds(length_cells: float, move_speed: float) -> float:
	if length_cells <= 0.0:
		return 0.0
	return length_cells / move_speed


# =============================================================================
# Story villager-ai-008 -- incremental patching on Voxel World writes
# =============================================================================

## The changed cell's own horizontal column plus its 8 Chebyshev-adjacent
## horizontal neighbor columns (this story's "clearance/step neighborhood" --
## ADR-0007 Key Interfaces `_on_voxel_world_cell_changed`'s own wording).
## Point-membership (standability) can only change within the changed cell's
## OWN column (`Vector2i(0,0)`) -- [method VillagerAi.is_standable] never
## reads another column's contents. The other 8 columns are included here
## because [method VillagerAi.is_step_legal]'s diagonal-flank check reads
## [method VillagerAi.is_standable] on cells at a DIFFERENT (x, z) than
## either endpoint of the step it is evaluating -- a write at the changed
## cell can therefore flip the legality of a diagonal step between two OTHER
## neighboring columns where the changed cell is the flanker (provably true
## for any flanker offset [method VillagerAi.is_step_legal] can construct,
## since a flanker is always exactly one step away, horizontally, from one of
## the two cells whose step it gates). [method patch_cells] re-derives
## connections for every point in this 9-column band against its own full
## 8-direction neighbor set, so a step between two OTHER cells that both
## happen to lie just outside this band, but adjacent to a band member, is
## still correctly re-evaluated from that member's own side.
const PATCH_NEIGHBORHOOD_HORIZONTAL_OFFSETS: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

## All 8 horizontal neighbor directions (unlike [constant
## HORIZONTAL_HALF_OFFSETS], which deliberately covers only half of them --
## an optimization valid ONLY for [method build]'s "visit every unordered
## pair exactly once from a full, fresh scan" shape). A patch pass revisits
## already-existing points from a small subset of cells, so it must consider
## BOTH directions from each one explicitly -- there is no complementary pass
## from "the other half" the way [method build]'s two-pass structure
## guarantees.
const HORIZONTAL_FULL_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
]


## Subscribes this graph to [param voxel_world]'s write signals so it patches
## itself incrementally on every future write (this story's AC1/AC2;
## ADR-0007 Decision Section 2). Connects with Godot's DEFAULT (synchronous,
## NEVER `CONNECT_DEFERRED`) flags -- see this class's own doc comment for
## why that is load-bearing, not incidental. Call exactly once per (graph,
## voxel_world) pair -- this codebase's single-shared-graph architecture
## (see this class's own doc comment, story villager-ai-007) means there is
## exactly ONE [VillagerNavGraph] instance for the whole population, so this
## is a one-time wiring call (a future boot/world-generation story's
## responsibility, or a test's, per this story's own integration test).
func subscribe_to_voxel_world(voxel_world: VoxelWorldGrid, predicate_source: VillagerAi) -> void:
	voxel_world.cell_changed.connect(_on_voxel_world_cell_changed.bind(predicate_source))
	voxel_world.cells_changed_batch.connect(_on_voxel_world_cells_changed_batch.bind(predicate_source))


## Story `building-034` (ADR-0007 §2b) -- subscribes this graph to [param
## scaffold_source]'s OWN change signal, since a scaffold erection/removal is
## NOT a [VoxelWorldGrid] write and [signal VoxelWorldGrid.cell_changed] will
## never fire for it. Connects with Godot's default (synchronous, never
## `CONNECT_DEFERRED`) flags -- the same race-closure discipline [method
## subscribe_to_voxel_world] already relies on. [param scaffold_source] is
## duck-typed (`Object`, mirrors [member VillagerAi.scaffold_registry]'s own
## typing) against exactly one signal: `signal scaffold_changed(cell:
## Vector3i)`. Routes into the EXISTING, bounded [method patch_cell] path --
## never `_astar.clear()`, never a rebuild.
func subscribe_to_scaffold_registry(scaffold_source: Object, predicate_source: VillagerAi) -> void:
	@warning_ignore("unsafe_property_access")
	scaffold_source.scaffold_changed.connect(_on_scaffold_changed.bind(predicate_source))


## [signal ScaffoldRegistry.scaffold_changed] handler -- delegates to [method
## patch_cell] exactly like [method _on_voxel_world_cell_changed]. Consumers
## re-query CURRENT state via [param predicate_source]; the changed cell
## itself is only ever used as the bounded patch's own center, never trusted
## as a snapshot of broader state (see [ScaffoldRegistry.scaffold_changed]'s
## own doc comment).
func _on_scaffold_changed(cell: Vector3i, predicate_source: VillagerAi) -> void:
	patch_cell(predicate_source, cell)


## [signal VoxelWorldGrid.cell_changed] handler ([param predicate_source] is
## the bound extra argument appended after the signal's own three, [method
## Signal.bind] semantics). Delegates to [method patch_cell] -- never
## inspects [param _before]/[param _after] itself (this story's AC2: a dig/
## demolition write patches IDENTICALLY to a build write; both are simply "a
## cell changed," and re-querying CURRENT state via [param predicate_source]
## is sufficient since [method VoxelWorldGrid.set_cell] already applied the
## write before emitting this signal).
func _on_voxel_world_cell_changed(
	cell: Vector3i, _before: CellContents, _after: CellContents, predicate_source: VillagerAi
) -> void:
	patch_cell(predicate_source, cell)


## [signal VoxelWorldGrid.cells_changed_batch] handler -- same delegation as
## [method _on_voxel_world_cell_changed], batched: every changed cell across
## an entire bulk write (e.g. terrain generation, a large demolition order)
## is folded into ONE [method patch_cells] call, never one [method
## patch_cell] call per record.
func _on_voxel_world_cells_changed_batch(
	changes: Array[CellChangeRecord], predicate_source: VillagerAi
) -> void:
	var cells: Array[Vector3i] = []
	for record: CellChangeRecord in changes:
		cells.append(record.cell)
	patch_cells(predicate_source, cells)


## Incremental single-cell patch (this story's AC1: "patch only the affected
## cell + its clearance/step neighborhood -- never a full rebuild"; ADR-0007
## Key Interfaces `_on_voxel_world_cell_changed`). Convenience wrapper around
## [method patch_cells] for exactly one changed cell -- also this story's own
## directly-testable entry point (no signal wiring required to exercise it).
func patch_cell(predicate_source: VillagerAi, changed_cell: Vector3i) -> void:
	patch_cells(predicate_source, [changed_cell])


## Incremental multi-cell patch -- the same operation as [method patch_cell],
## batched over every cell in [param changed_cells] (this story's own
## `cells_changed_batch` consumer; also directly testable for a
## multi-cell-write scenario without needing a live signal). A no-op before
## [method build] has ever run (`_is_built` false) -- nothing to keep
## consistent yet; the eventual [method build] call starts from Voxel
## World's then-current state regardless of any writes that happened before
## it.
##
## For every cell in [param changed_cells], expands to its [constant
## PATCH_NEIGHBORHOOD_HORIZONTAL_OFFSETS] x a `[-VILLAGER_CLEARANCE,
## +VILLAGER_CLEARANCE]` vertical band (a generous, provably-sufficient
## superset of the tighter exact bound [method VillagerAi.is_standable]'s own
## solid-below/clearance-column reads imply -- cheap at this graph's
## per-write scale, matching the ADR's own measured patch-cost guardrail).
## Deduplicates the resulting cell set (a plain `Dictionary`-as-set) before
## re-syncing points then connections -- never a full `_astar.clear()`/
## [method build] re-run (this story's AC1).
func patch_cells(predicate_source: VillagerAi, changed_cells: Array[Vector3i]) -> void:
	if not _is_built:
		return
	var affected: Dictionary[Vector3i, bool] = {}
	var clearance: int = VillagerAi.VILLAGER_CLEARANCE
	for changed_cell: Vector3i in changed_cells:
		for offset: Vector2i in PATCH_NEIGHBORHOOD_HORIZONTAL_OFFSETS:
			for dy in range(-clearance, clearance + 1):
				affected[changed_cell + Vector3i(offset.x, dy, offset.y)] = true
	var affected_cells: Array[Vector3i] = affected.keys()
	_resync_points(predicate_source, affected_cells)
	_resync_connections(predicate_source, affected_cells)


## Point-membership half of a patch pass: for every cell in [param cells],
## add a point if [param predicate_source] now reports it standable and it
## wasn't already a point, or remove its point if it no longer is (`AStar3D`'s
## own `remove_point()` clears every connection that point held -- no
## separate disconnect pass needed for a removal). Never touches a cell
## whose standability did not change (an unaffected `add_point`/`remove_point`
## call is simply never made -- not a no-op call, an OMITTED one), which is
## what keeps a patch bounded to the affected neighborhood rather than a
## full rebuild.
func _resync_points(predicate_source: VillagerAi, cells: Array[Vector3i]) -> void:
	for cell: Vector3i in cells:
		var id: int = VillagerNavGraph.cell_to_astar_id(cell)
		var should_be_point: bool = predicate_source.is_standable(cell)
		var is_point: bool = _astar.has_point(id)
		if should_be_point and not is_point:
			_astar.add_point(id, VoxelWorldGrid.cell_to_world(cell))
		elif not should_be_point and is_point:
			_astar.remove_point(id)


## Connection half of a patch pass: for every cell in [param cells] that IS
## (still, or newly) a point, re-evaluates its connection to each of its 8
## horizontal x [constant VERTICAL_STEP_OFFSETS] neighbor candidates that is
## ALSO currently a point, via [method _resync_pair]. Unlike [method build]'s
## two-pass "visit each unordered pair exactly once" optimization (safe only
## for a full, fresh scan), a patch must use [constant HORIZONTAL_FULL_OFFSETS]
## (all 8 directions) since it revisits a small, pre-existing subset of
## points from only one side at a time -- there is no guaranteed
## complementary pass from "the other half."
func _resync_connections(predicate_source: VillagerAi, cells: Array[Vector3i]) -> void:
	for cell: Vector3i in cells:
		var id: int = VillagerNavGraph.cell_to_astar_id(cell)
		if not _astar.has_point(id):
			continue
		for offset: Vector2i in HORIZONTAL_FULL_OFFSETS:
			for dy: int in VERTICAL_STEP_OFFSETS:
				var neighbor: Vector3i = cell + Vector3i(offset.x, dy, offset.y)
				var neighbor_id: int = VillagerNavGraph.cell_to_astar_id(neighbor)
				if not _astar.has_point(neighbor_id):
					continue
				_resync_pair(predicate_source, cell, id, neighbor, neighbor_id)
		# Story `building-034` (ADR-0007 §2a clause 1) -- a patch revisits a
		# small, pre-existing subset of points, never a complementary full
		# scan, so BOTH same-column directions must be considered explicitly
		# here (matching [constant HORIZONTAL_FULL_OFFSETS]'s own "all 8, not
		# half" patch-pass discipline). This is also the ONLY path a scaffold
		# write's own patch ([method patch_cell] via [signal
		# ScaffoldRegistry.scaffold_changed]) ever reaches this edge class
		# through -- a scaffold write is never part of [method build]'s
		# initial full scan.
		for dy: int in VERTICAL_SAME_COLUMN_OFFSETS:
			var neighbor: Vector3i = cell + Vector3i(0, dy, 0)
			var neighbor_id: int = VillagerNavGraph.cell_to_astar_id(neighbor)
			if not _astar.has_point(neighbor_id):
				continue
			_resync_pair(predicate_source, cell, id, neighbor, neighbor_id)


## Re-evaluates ONE ordered pair's connection in BOTH directions
## independently (mirroring [method _connect_if_legal]'s own non-symmetric
## reasoning -- see that method's doc comment), but as an explicit
## add-or-remove reconciliation against the connection's CURRENT state
## (unlike [method _connect_if_legal], which only ever runs once against a
## brand-new pair with no prior connection to remove): if a direction is now
## legal and isn't yet connected, connect it; if a direction is no longer
## legal and IS connected, disconnect it. A direction that is already in the
## correct state is left untouched -- no redundant `connect_points`/
## `disconnect_points` call.
func _resync_pair(
	predicate_source: VillagerAi, from_cell: Vector3i, from_id: int, to_cell: Vector3i, to_id: int
) -> void:
	var forward_legal: bool = predicate_source.is_step_legal(from_cell, to_cell)
	var backward_legal: bool = predicate_source.is_step_legal(to_cell, from_cell)
	var forward_connected: bool = _astar.are_points_connected(from_id, to_id, false)
	var backward_connected: bool = _astar.are_points_connected(to_id, from_id, false)
	if forward_legal and not forward_connected:
		_astar.connect_points(from_id, to_id, false)
	elif not forward_legal and forward_connected:
		_astar.disconnect_points(from_id, to_id, false)
	if backward_legal and not backward_connected:
		_astar.connect_points(to_id, from_id, false)
	elif not backward_legal and backward_connected:
		_astar.disconnect_points(to_id, from_id, false)
