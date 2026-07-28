## Starting-roster placement + assembly (Story villager-ai-021, GDD Rule 14b /
## [TR-villager-ai-behavior-065]: "at world generation this system places
## `starting_villager_count` villagers (config: MVP = 1, Vertical Slice = 5)
## at valid standable cells near the world center"). This GDD Rule owns the
## STARTING population only -- growth beyond it (arrivals, recruitment) is
## Township Progression's (Alpha), out of this class's scope entirely.
##
## Two static, stateless entry points -- mirrors [VillagerRescueTargetSearch]/
## [VillagerWalkabilityRules]'s own established "pure algorithm library, no
## instance, no cached state" precedent (see either class's own doc comment
## for the full architectural rationale this one repeats): never instantiated
## anywhere (a `RefCounted` used purely as a static-functions namespace).
##
## [method select_starting_cells] is the PLACEMENT half -- Logic-testable in
## complete isolation, no [Node]/scene-tree involvement whatsoever: a
## deterministic expanding-ring Chebyshev BFS out from `center_cell`, reusing
## [method VillagerWalkabilityRules.is_standable] (never a re-derived copy of
## the rule, ADR-0007: "every consumer calls these same... functions") and the
## SAME lexicographic `(y, x, z)` tie-break
## [method VillagerJobSelector.lexicographic_cell_less_than] already
## establishes for F2/F5 -- collects up to `count` DISTINCT standable cells,
## nearest-ring first. Unlike [VillagerRescueTargetSearch]'s own ring walk,
## ring 0 (`center_cell` itself) IS eligible here -- there is no "rescuing a
## villager to itself" hazard for a fresh spawn, so the search may legally
## return the exact center cell. A world with fewer than `count` standable
## cells within [constant MAX_SEARCH_RADIUS] returns however many it found --
## never crashes, never blocks boot (this story's own QA-named edge case:
## "no standable cell near center within a fallback search (deterministic
## placement)").
##
## Story villager-ai-022 (this revision, "the stray villager at the world
## corner") adds [method place_villager_at_cell] -- the single-cell placement
## half [method assemble_roster] already performed inline for each freshly
## CONSTRUCTED roster member, now factored out so [Valley.spawn_starting_roster]
## can place the ALREADY-CONSTRUCTED, scene-hosted default villager (villager_id
## 0) through this exact same call rather than a second, hand-rolled field
## assignment (that story's own AC2: "one placement rule, not two"). Legal to
## call on a villager that has not yet had its first tick dispatched -- exactly
## [method assemble_roster]'s own pre-`setup()` construction-time use of it --
## which is why this is initial placement, not a violation of the Control
## Manifest's "`current_cell` changes at EXACTLY two sanctioned points" runtime
## rule (ADR-0009): that rule governs an ALREADY-SIMULATING villager's position
## changes (tick-boundary travel arrival / unstuck-watchdog rescue), not a
## not-yet-ticked villager's very first placement.
##
## [method assemble_roster] is the ASSEMBLY half: constructs one new
## [VillagerAi] per cell [param cells] supplies, DI-wires it (`config`/
## `voxel_world`/`scheduler`/`nav_graph`/`unstuck_telemetry`, `villager_id`
## starting at [param first_villager_id] and incrementing in array order --
## the GDD Edge Case 3/F2 stable-processing-order convention -- and places it
## via [method place_villager_at_cell], so it begins stationary at its
## assigned cell, never mid-transit). Deliberately NEVER calls
## `setup()` itself (ADR-0005: the sole call site for the boot gate's
## INITIAL injected-tier sweep is [method GameWorld._setup_injected_tier] --
## a villager assembled by this method is instantiated by whichever code
## actually triggers world generation, a distinct, later, on-demand entry
## point; that caller decides when to call `setup()`, mirroring the exact
## "construction/DI-wiring is not lifecycle" split
## [VillagerOnSiteGate.register_villager]/
## [VillagerSealPreventionGate]'s own registration methods already
## establish). Never adds any node to a scene tree either -- the caller
## (e.g. a future [Valley.spawn_starting_roster] world-generation call site)
## decides tree placement, exactly like every other hosted-module DI seam in
## this codebase.
class_name VillagerRosterSpawner
extends RefCounted

## Initial ring-search bound, in cells -- an `[assumption]`: GDD Rule 14b
## names no explicit search-radius knob, only the villager COUNT is a Tuning
## Knob. This search runs once, at world-generation time, for at most 8
## villagers ([constant VillagerAIConfig.STARTING_VILLAGER_COUNT_MAX]),
## never per-tick/per-frame.
const INITIAL_SEARCH_RADIUS: int = 4

## Hard expansion ceiling, in cells -- doubles from [constant
## INITIAL_SEARCH_RADIUS] exactly like [VillagerRescueTargetSearch]'s own F5
## doubling scheme (`min(radius * 2, MAX_SEARCH_RADIUS)`). Measured, not
## merely assumed cheap: a fully-exhausted search (the world has zero
## standable cells anywhere nearby -- e.g. a fresh [VoxelWorldGrid] before
## any terrain has paged in, ADR-0015, chunks regenerate ASYNCHRONOUSLY off
## the main thread, never synchronously at boot) against the FIRST value
## tried here (64) measured ~9.5s per call in this suite -- far outside a
## boot-time-safe budget. 16 keeps the same doubling shape
## (4 -> 8 -> 16, three steps) at a cost of tens of milliseconds worst-case,
## while still covering a 33x33x33 volume around the center -- generous for
## placing up to 8 villagers "near" it.
const MAX_SEARCH_RADIUS: int = 16


## Deterministic world-center cell derivation (GDD Rule 14b: "near the world
## center") -- `(world_width_cells / 2, (min_y + max_y) / 2,
## world_depth_cells / 2)`, reusing [param config]'s own already-validated
## Voxel World Tuning Knobs (never a second, locally-duplicated world-size
## guess). The Y guess is a midpoint, not a real surface height -- [method
## select_starting_cells]'s own 3D ring search is what actually finds a
## standable Y near it; this is only the search's STARTING point.
static func world_center_cell(config: VoxelWorldConfig) -> Vector3i:
	assert(config != null, "VillagerRosterSpawner.world_center_cell requires a VoxelWorldConfig")
	return Vector3i(
		config.world_width_cells / 2,
		(config.min_y + config.max_y) / 2,
		config.world_depth_cells / 2,
	)


## The placement half -- see class doc comment for the full algorithm and
## its ring-0-eligible departure from [VillagerRescueTargetSearch]'s own
## walk. Returns up to [param count] distinct standable cells, nearest
## [param center_cell] first (deterministic given the same
## [param voxel_world] contents, [param center_cell], and [param count] --
## this story's own "same world seed/config" requirement).
static func select_starting_cells(
	voxel_world: VoxelWorldGrid, center_cell: Vector3i, count: int
) -> Array[Vector3i]:
	assert(voxel_world != null, "VillagerRosterSpawner.select_starting_cells requires voxel_world")
	var found: Array[Vector3i] = []
	if count <= 0:
		return found

	var radius: int = INITIAL_SEARCH_RADIUS
	# -1 (not 0) so the FIRST scanned range is 0..radius inclusive -- ring 0
	# (the center cell itself) is eligible here, unlike
	# VillagerRescueTargetSearch's own walk (see class doc comment).
	var checked_up_to_distance: int = -1
	while true:
		for distance in range(checked_up_to_distance + 1, radius + 1):
			var ring: Array[Vector3i] = _ring_cells(center_cell, distance)
			ring.sort_custom(VillagerJobSelector.lexicographic_cell_less_than)
			for candidate: Vector3i in ring:
				if VillagerWalkabilityRules.is_standable(voxel_world, candidate):
					found.append(candidate)
					if found.size() >= count:
						return found
		checked_up_to_distance = radius
		if radius >= MAX_SEARCH_RADIUS:
			break
		radius = mini(radius * 2, MAX_SEARCH_RADIUS)
	return found


## The assembly half -- see class doc comment. [param cells] is normally
## [method select_starting_cells]'s own return value; one [VillagerAi] is
## constructed per entry, in array order.
static func assemble_roster(
	voxel_world: VoxelWorldGrid,
	config: VillagerAIConfig,
	scheduler: VillagerDecidingScheduler,
	nav_graph: VillagerNavGraph,
	unstuck_telemetry: VillagerUnstuckTelemetry,
	cells: Array[Vector3i],
	first_villager_id: int,
) -> Array[VillagerAi]:
	var roster: Array[VillagerAi] = []
	for i in range(cells.size()):
		var villager := VillagerAi.new()
		villager.config = config
		villager.voxel_world = voxel_world
		villager.scheduler = scheduler
		villager.nav_graph = nav_graph
		villager.unstuck_telemetry = unstuck_telemetry
		villager.villager_id = first_villager_id + i
		place_villager_at_cell(villager, cells[i])
		roster.append(villager)
	return roster


## Sets [param villager]'s discrete `current_cell`/`_from_cell`/`_to_cell` to
## [param cell], leaving it stationary there (never mid-transit) -- see class
## doc comment's own Story villager-ai-022 paragraph for why this is legal
## initial placement, not a runtime `current_cell` mutation. Factored out of
## [method assemble_roster]'s own former inline three-field assignment so
## [Valley.spawn_starting_roster] can place villager_id 0 -- an
## ALREADY-CONSTRUCTED, scene-hosted [VillagerAi], never one this class
## constructs -- through the identical call.
static func place_villager_at_cell(villager: VillagerAi, cell: Vector3i) -> void:
	villager.current_cell = cell
	villager._from_cell = cell
	villager._to_cell = cell


## Every cell at EXACTLY Chebyshev distance [param distance] from
## [param center] in 3D (the surface of a `(2*distance+1)`-side cube, never
## its interior) -- mirrors [VillagerRescueTargetSearch]'s own private
## `_ring_cells` generator byte-for-byte (a small, self-contained geometry
## helper, not a walkability rule -- ADR-0007's "never duplicate walkability
## rules or constants" guardrail does not extend to this generic ring-surface
## enumeration, which carries no game-rule content of its own).
## `distance == 0` returns just `[center]`, reachable here (unlike that
## class's own walk, which never starts at distance 0 -- see class doc
## comment).
static func _ring_cells(center: Vector3i, distance: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	if distance == 0:
		cells.append(center)
		return cells

	for x_sign in [-1, 1]:
		var x: int = center.x + x_sign * distance
		for dy in range(-distance, distance + 1):
			for dz in range(-distance, distance + 1):
				cells.append(Vector3i(x, center.y + dy, center.z + dz))

	for y_sign in [-1, 1]:
		var y: int = center.y + y_sign * distance
		for dx in range(-distance + 1, distance):
			for dz in range(-distance, distance + 1):
				cells.append(Vector3i(center.x + dx, y, center.z + dz))

	for z_sign in [-1, 1]:
		var z: int = center.z + z_sign * distance
		for dx in range(-distance + 1, distance):
			for dy in range(-distance + 1, distance):
				cells.append(Vector3i(center.x + dx, center.y + dy, z))

	return cells
