## Integration test — Scene/World Management Story scene-006 (Villager need
## seeding in the boot sequence; ADR-0005 primary, ADR-0001/0002 secondary).
##
## Closes `needs-mood-006`'s own "uncalled in `src/`" gap: [method
## NeedsMood.initialize_villager] is fully implemented and unit-tested but,
## before this story, called from nowhere in `src/` — every production
## villager existed with zero need records, so [NeedsMood]'s F1 decay pass
## (which only iterates `_need_records`) never advanced them, and the
## Needs & Mood → Villager AI payoff loop `needs-mood-010` proved end-to-end
## against a hand-seeded fixture could never actually start in the shipped
## game. This file is a NEW file (Test Evidence's own named alternative to
## extending `world_genesis_boot_test.gd`) — that file already bundles one
## expensive real 2000x2000 production boot into a single test to avoid
## re-paying its cost; this story's seven ACs are an independent cluster
## large enough to make that file unwieldy, so they get their own file
## instead, exactly as the story's own Test Evidence section anticipates.
##
## Proves:
## - **AC-SEED-BEFORE-ACTIVE** + **AC-PROBE-IS-NON-VACUOUS**: a REAL,
##   production-shaped `GameWorld`/`Valley.tscn` boot (never a mocked
##   `NeedsMood`) reaches [constant GameWorld.BootState.ACTIVE] with every
##   villager [method Valley.get_villagers] reports already seeded — proven
##   NON-VACUOUSLY via the **time probe** (AC-PROBE-IS-NON-VACUOUS option
##   (a)): the obvious `get_need_value(...) == 100.0` assertion PASSES on an
##   unseeded build (NeedsMood's own documented "unknown id answers as if
##   fine" default), so this test instead drives one real tick through the
##   ACTUAL global `TimeTickSystem` Autoload singleton (never a mock — the
##   same direct-global-access pattern `orbit_rotation_test.gd` already
##   establishes) and asserts every villager's `sleep` value has strictly
##   decayed below 100.0 — impossible for a villager with no tracked record,
##   since [NeedsMood]'s F1 decay pass only iterates `_need_records`. A RID
##   `Failed` boot never attaches a Valley at all (existing ADR-0005 halt
##   semantics, reused verbatim from `world_genesis_boot_test.gd`'s own
##   precedent) — seeding structurally cannot have run.
## - **AC-SEED-NOT-FROM-READY**: grep guard — `initialize_villager(` appears
##   nowhere inside `valley.gd`'s `_wire_villager_population()`/`_ready()`/
##   `_process()` function bodies.
## - **AC-SEED-AFTER-SETUP**: [method Valley.seed_default_villager_needs] and
##   [method Valley.spawn_starting_roster]'s own seeding both assert [method
##   NeedsMood.is_set_up] first — proven by ordering (calling either against
##   a freshly-instantiated, not-yet-`setup()`-ed [NeedsMood] raises exactly
##   that assertion), never by reading the source.
## - **AC-SEED-EVERY-ROSTER-MEMBER**: a lightweight, directly-instantiated
##   `Valley.tscn` (bypassing the expensive 2000x2000 production config —
##   config is swapped on the freshly-instantiated-but-not-yet-`_ready()`
##   node, exactly as `starting_roster_test.gd`'s own established
##   `_boot_valley()`-adjacent precedent already reads `@onready`-populated
##   children directly via [method Node.get_node] before the node ever
##   enters the tree) with `starting_villager_count = 3` seeds ALL 3
##   villagers (Story villager-ai-022: the default now counts toward that
##   config and is placed by the same call, so 3 total, 2 newly-constructed)
##   exactly once; a world with too few standable cells degrades
##   deterministically, seeding only the villagers actually placed.
## - **AC-SEED-IS-IDEMPOTENT-AT-BOOT**: a villager whose `sleep` has already
##   decayed below 100 keeps that exact value across a second
##   [method Valley.spawn_starting_roster] call (that method's own
##   already-tested "no growth bookkeeping" shape: it seeds only the NEW
##   villagers it creates, never re-touching an existing one).
## - **AC-NO-BOOT-EVENTS**: zero [signal NeedsMood.need_urgent]/[signal
##   NeedsMood.need_satisfied]/[signal NeedsMood.mood_band_changed]
##   emissions across a full seeding pass plus one subsequent real tick.
class_name VillagerNeedSeedingBootTest
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")
const ValleyScene: PackedScene = preload("res://src/scene_world_management/Valley.tscn")


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

func _solid() -> CellContents:
	return CellContents.new(1, 0)


## Fills a flat, fully-standable plane around [param center] -- byte-for-byte
## `starting_roster_test.gd`'s own established `_fill_flat_plane` fixture.
func _fill_flat_plane(voxel_world: VoxelWorldGrid, center: Vector3i, half_extent: int) -> void:
	for dx in range(-half_extent, half_extent + 1):
		for dz in range(-half_extent, half_extent + 1):
			voxel_world.set_cell(Vector3i(center.x + dx, center.y - 1, center.z + dz), _solid())


## Boots a REAL `GameWorld` behind the ADR-0005 gate, attaching the REAL
## production `Valley.tscn` (2000x2000 config, the shipped `.tres` roster
## config) -- the only shape that can prove AC-SEED-BEFORE-ACTIVE's own
## claim ("reached via GameWorld's boot orchestration", not merely "Valley's
## methods work in isolation"). Mirrors `world_genesis_boot_test.gd`'s own
## `test_real_boot_genesis_produces_a_populated_active_world` fixture.
func _boot_real_game_world() -> GameWorld:
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	return world


## Instantiates the REAL `Valley.tscn` directly (never through `GameWorld`),
## with a small, test-shaped [VoxelWorldConfig] and a caller-supplied
## [VillagerAIConfig] swapped in BEFORE the node ever enters the tree --
## `@onready` children (this class's own `$VoxelWorldGrid` etc.) do not
## resolve until `_ready()` fires, but the child NODES already physically
## exist immediately after [method PackedScene.instantiate] (the whole
## subtree is built synchronously), so [method Node.get_node] reaches them
## early and the swap lands before `_ready()`'s own `_wire_hosted_modules`/
## `_wire_villager_population` pass ever runs. Deliberately does NOT boot
## through `GameWorld` -- this harness exists precisely so
## AC-SEED-EVERY-ROSTER-MEMBER/AC-SEED-IS-IDEMPOTENT-AT-BOOT/
## AC-NO-BOOT-EVENTS can control `starting_villager_count` and avoid paying
## the production config's real 2000x2000 boot cost, mirroring this
## project's own established "swap config directly on an already-
## instantiated Resource-typed field" precedent (`starting_roster_test.gd`'s
## own `valley.villager_ai_config = VillagerAIConfig.new()` post-boot
## override, generalized to pre-`_ready()` here since we also need to swap
## the grid's config, which IS read inside `_wire_villager_population`'s own
## downstream callers).
##
## Immediately runs [method _setup_all_modules_except_needs_mood] once added
## to the tree -- this bare harness never goes through
## [method GameWorld._setup_injected_tier], so without this every hosted
## Building System module's own `_process` (`PlacementPick.update_pick` in
## particular) trips its own "called before setup()" assertion the instant a
## frame processes; calling every OTHER hosted module's `setup()` here
## mirrors production's own DI-sweep order for everything this story does
## NOT govern, leaving [NeedsMood]'s own `setup()` timing fully in each
## test's own hands (the one thing this story's ACs actually care about).
func _instantiate_bare_valley(villager_config: VillagerAIConfig) -> Valley:
	var valley: Valley = ValleyScene.instantiate()
	var voxel_world: VoxelWorldGrid = valley.get_node(^"VoxelWorldGrid") as VoxelWorldGrid
	var world_config := VoxelWorldConfig.new()
	world_config.world_width_cells = 64
	world_config.world_depth_cells = 64
	voxel_world.config = world_config
	valley.villager_ai_config = villager_config
	add_child(valley)
	auto_free(valley)
	_setup_all_modules_except_needs_mood(valley)
	return valley


## Calls `setup()` on every hosted module [method Valley.get_injected_tier_modules]
## reports EXCEPT [NeedsMood] -- see [method _instantiate_bare_valley]'s own
## doc comment for why. [NeedsMood]'s `setup()` timing is each test's own to
## control (that is exactly what AC-SEED-AFTER-SETUP is about).
func _setup_all_modules_except_needs_mood(valley: Valley) -> void:
	var needs_mood: NeedsMood = valley.get_needs_mood()
	for module: Node in valley.get_injected_tier_modules():
		if module == needs_mood:
			continue
		if module.has_method(&"setup"):
			module.setup()


# ---------------------------------------------------------------------------
# AC-SEED-BEFORE-ACTIVE / AC-PROBE-IS-NON-VACUOUS
# ---------------------------------------------------------------------------

func test_ac_seed_before_active_real_boot_every_villager_decays_below_100_after_one_real_tick() -> void:
	# Arrange + Act -- the real production boot, through the real gate.
	var world: GameWorld = _boot_real_game_world()
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()
	var needs_mood: NeedsMood = valley.get_needs_mood()
	var villagers: Array[VillagerAi] = valley.get_villagers()
	assert_int(villagers.size()).is_greater(0)

	# The vacuous check (would ALSO pass on an unseeded build -- kept here as
	# a documented contrast, never as this test's own proof): every fresh
	# villager reads exactly 100.0 at t=0, seeded or not.
	for villager: VillagerAi in villagers:
		assert_float(needs_mood.get_need_value(villager.villager_id, &"sleep")).is_equal(100.0)

	# Act -- the NON-VACUOUS probe (AC-PROBE-IS-NON-VACUOUS option (a)): one
	# real tick through the ACTUAL global TimeTickSystem Autoload singleton
	# (never a mock -- the same direct-global-access pattern
	# `orbit_rotation_test.gd` already establishes for this exact Autoload).
	TimeTickSystem.tick.emit()

	# Assert -- a villager with NO tracked record never enters F1 decay's
	# iteration and would stay at the default 100.0 forever; a seeded one
	# has strictly decayed. This is the assertion that CANNOT pass on an
	# unseeded build (see this story's negative-control demonstration,
	# recorded in the commit body).
	for villager: VillagerAi in villagers:
		assert_float(needs_mood.get_need_value(villager.villager_id, &"sleep")).is_less(100.0)


func test_ac_seed_before_active_failed_rid_never_attaches_valley_so_seeding_cannot_have_run() -> void:
	# Arrange -- mirrors world_genesis_boot_test.gd's own established Failed
	# fixture: _attach_valley() (and therefore any seeding call, which all
	# require a live Valley) is never reached.
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	world.resource_item_database = database
	add_child(world)

	# Act
	database.settle(false, ["villager need seeding boot test — forced Failed"])

	# Assert
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.HALTED)
	assert_object(world.get_valley()).is_null()


# ---------------------------------------------------------------------------
# AC-SEED-NOT-FROM-READY — grep guard
# ---------------------------------------------------------------------------

func test_ac_seed_not_from_ready_zero_initialize_villager_calls_in_ready_or_wire_or_process() -> void:
	var text: String = FileAccess.get_file_as_string("res://src/scene_world_management/valley.gd")
	var cleaned_lines: Array[String] = []
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			cleaned_lines.append(line)
	var cleaned: String = "\n".join(cleaned_lines)

	var offenders: Array[String] = []
	for func_name: String in ["_ready", "_wire_villager_population", "_process"]:
		var body: String = _extract_named_function_body(cleaned, func_name)
		if body.contains("initialize_villager("):
			offenders.append(func_name)
	assert_array(offenders).is_empty()


## Extracts the text body of the top-level function named [param func_name]
## in [param source] (comment lines already stripped by the caller), from
## its own `func` line up to (not including) the next line whose stripped
## text begins with `func ` at the SAME OR SHALLOWER indentation -- mirrors
## `world_genesis_boot_test.gd`'s own `_extract_process_function_bodies`
## helper, generalized to an arbitrary function name rather than only
## `_process`/`_physics_process`.
func _extract_named_function_body(source: String, func_name: String) -> String:
	var lines: PackedStringArray = source.split("\n")
	var i: int = 0
	while i < lines.size():
		var line: String = lines[i]
		var stripped: String = line.strip_edges()
		if stripped.begins_with("func %s(" % func_name):
			var indent: int = line.length() - line.strip_edges(true, false).length()
			var body: String = line + "\n"
			var j: int = i + 1
			while j < lines.size():
				var next_line: String = lines[j]
				var next_stripped: String = next_line.strip_edges()
				if next_stripped.begins_with("func "):
					var next_indent: int = next_line.length() - next_line.strip_edges(true, false).length()
					if next_indent <= indent:
						break
				body += next_line + "\n"
				j += 1
			return body
		i += 1
	return ""


# ---------------------------------------------------------------------------
# AC-SEED-AFTER-SETUP — asserted by ordering, not by reading the code
# ---------------------------------------------------------------------------

func test_ac_seed_after_setup_default_villager_seeding_before_needs_mood_setup_raises() -> void:
	# Arrange -- a bare Valley whose hosted NeedsMood has NOT had setup()
	# called on it yet (freshly _ready()-wired, nothing more).
	var valley: Valley = _instantiate_bare_valley(VillagerAIConfig.new())
	assert_bool(valley.get_needs_mood().is_set_up()).is_false()

	# Act + Assert -- calling the seeding entry point before setup() raises
	# the exact assert this story's implementation adds for this reason.
	await assert_error(func() -> void: valley.seed_default_villager_needs()).is_runtime_error(
		"Assertion failed: Valley.seed_default_villager_needs called before NeedsMood.setup()"
		+ " has completed"
	)


func test_ac_seed_after_setup_default_villager_seeding_after_needs_mood_setup_succeeds() -> void:
	# Arrange
	var valley: Valley = _instantiate_bare_valley(VillagerAIConfig.new())
	valley.get_needs_mood().setup()

	# Act + Assert -- no error; the villager is tracked (non-vacuous via the
	# same real-tick probe as AC-SEED-BEFORE-ACTIVE).
	valley.seed_default_villager_needs()
	TimeTickSystem.tick.emit()
	assert_float(
		valley.get_needs_mood().get_need_value(valley.get_villager_ai().villager_id, &"sleep")
	).is_less(100.0)


func test_ac_seed_after_setup_roster_seeding_before_needs_mood_setup_raises() -> void:
	# Arrange -- a bare Valley with standable terrain but NeedsMood never
	# set up.
	var villager_config := VillagerAIConfig.new()
	villager_config.starting_villager_count = 1
	var valley: Valley = _instantiate_bare_valley(villager_config)
	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	var center: Vector3i = VillagerRosterSpawner.world_center_cell(voxel_world.config)
	_fill_flat_plane(voxel_world, center, 10)
	assert_bool(valley.get_needs_mood().is_set_up()).is_false()

	# Act + Assert
	await assert_error(func() -> void: valley.spawn_starting_roster()).is_runtime_error(
		"Assertion failed: Valley.spawn_starting_roster seeding a villager before"
		+ " NeedsMood.setup() has completed"
	)


# ---------------------------------------------------------------------------
# AC-SEED-EVERY-ROSTER-MEMBER
# ---------------------------------------------------------------------------

func test_ac_seed_every_roster_member_config_driven_count_all_four_hold_records() -> void:
	# Arrange -- a lightweight Valley, starting_villager_count = 3.
	#
	# Story villager-ai-022 (AC4): villager 0 now COUNTS toward this config --
	# this is the FIRST-ever spawn_starting_roster() call on this bare Valley
	# (never boot-genesis-driven), so it consumes cells[0] to place villager 0
	# itself and constructs 2 NEW roster members from the remaining cells
	# (3 total villagers, not "3 new + 1 pre-existing = 4").
	var villager_config := VillagerAIConfig.new()
	villager_config.starting_villager_count = 3
	var valley: Valley = _instantiate_bare_valley(villager_config)
	valley.get_needs_mood().setup()
	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	var center: Vector3i = VillagerRosterSpawner.world_center_cell(voxel_world.config)
	_fill_flat_plane(voxel_world, center, 10)

	# Act -- the production order: default villager first, then the roster.
	valley.seed_default_villager_needs()
	var spawned: Array[VillagerAi] = valley.spawn_starting_roster()

	# Assert -- 2 new roster members (villager 0 absorbed the 3rd slot), 3
	# villagers total.
	assert_int(spawned.size()).is_equal(2)
	var all_villagers: Array[VillagerAi] = valley.get_villagers()
	assert_int(all_villagers.size()).is_equal(3)

	# Non-vacuous: one real tick, every one of the 3 has strictly decayed.
	TimeTickSystem.tick.emit()
	var needs_mood: NeedsMood = valley.get_needs_mood()
	for villager: VillagerAi in all_villagers:
		assert_float(needs_mood.get_need_value(villager.villager_id, &"sleep")).is_less(100.0)


func test_ac_seed_every_roster_member_partial_placement_seeds_only_those_placed() -> void:
	# Arrange -- QA plan edge case: too few standable cells for the
	# requested count; only TWO standable cells exist anywhere near center,
	# five are requested. Mirrors `starting_roster_test.gd`'s own
	# established degrade-deterministically fixture.
	#
	# Story villager-ai-022 (AC4): the first of the two found cells is
	# consumed by villager 0's own first-ever placement; only ONE remains for
	# a newly-constructed roster member.
	var villager_config := VillagerAIConfig.new()
	villager_config.starting_villager_count = 5
	var valley: Valley = _instantiate_bare_valley(villager_config)
	valley.get_needs_mood().setup()
	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	var center: Vector3i = VillagerRosterSpawner.world_center_cell(voxel_world.config)
	voxel_world.set_cell(center + Vector3i(0, -1, 0), _solid())
	voxel_world.set_cell(center + Vector3i(1, -1, 0), _solid())

	# Act
	valley.seed_default_villager_needs()
	var spawned: Array[VillagerAi] = valley.spawn_starting_roster()

	# Assert -- never a crash; fewer placed, exactly those seeded.
	assert_int(spawned.size()).is_equal(1)
	TimeTickSystem.tick.emit()
	var needs_mood: NeedsMood = valley.get_needs_mood()
	for villager: VillagerAi in valley.get_villagers():
		assert_float(needs_mood.get_need_value(villager.villager_id, &"sleep")).is_less(100.0)


# ---------------------------------------------------------------------------
# AC-SEED-IS-IDEMPOTENT-AT-BOOT
# ---------------------------------------------------------------------------

func test_ac_seed_is_idempotent_at_boot_second_roster_call_never_resets_a_decayed_value() -> void:
	# Arrange -- a lightweight Valley, one roster member seeded and decayed
	# to a known value below 100 via several real ticks.
	#
	# Story villager-ai-022 (AC4): starting_villager_count = 2 -- the FIRST
	# call consumes cells[0] for villager 0's own one-time-only placement and
	# constructs exactly ONE new roster member from cells[1] (first_batch.size
	# == 1). Villager 0 is already placed by the SECOND call, so it spends
	# the full count (2) on two new members instead.
	var villager_config := VillagerAIConfig.new()
	villager_config.starting_villager_count = 2
	var valley: Valley = _instantiate_bare_valley(villager_config)
	valley.get_needs_mood().setup()
	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	var center: Vector3i = VillagerRosterSpawner.world_center_cell(voxel_world.config)
	_fill_flat_plane(voxel_world, center, 10)

	valley.seed_default_villager_needs()
	var first_batch: Array[VillagerAi] = valley.spawn_starting_roster()
	assert_int(first_batch.size()).is_equal(1)

	var needs_mood: NeedsMood = valley.get_needs_mood()
	for _i in range(5):
		TimeTickSystem.tick.emit()
	var default_before: float = needs_mood.get_need_value(valley.get_villager_ai().villager_id, &"sleep")
	var first_batch_before: float = needs_mood.get_need_value(first_batch[0].villager_id, &"sleep")
	assert_float(default_before).is_less(100.0)
	assert_float(first_batch_before).is_less(100.0)

	# Act -- a second spawn_starting_roster() call ("no growth bookkeeping"
	# own shape, `starting_roster_test.gd`'s own established behaviour):
	# this creates NEW villagers with NEW ids, never re-touching the ones
	# already spawned.
	var second_batch: Array[VillagerAi] = valley.spawn_starting_roster()
	assert_int(second_batch.size()).is_equal(2)
	assert_int(second_batch[0].villager_id).is_not_equal(first_batch[0].villager_id)
	assert_int(second_batch[1].villager_id).is_not_equal(first_batch[0].villager_id)

	# Assert -- neither the default villager nor the first batch's already-
	# decayed value was reset.
	assert_float(
		needs_mood.get_need_value(valley.get_villager_ai().villager_id, &"sleep")
	).is_equal(default_before)
	assert_float(needs_mood.get_need_value(first_batch[0].villager_id, &"sleep")).is_equal(first_batch_before)


# ---------------------------------------------------------------------------
# AC-NO-BOOT-EVENTS
# ---------------------------------------------------------------------------

func test_ac_no_boot_events_zero_need_and_mood_signals_across_a_full_seeding_pass() -> void:
	# Arrange -- a lightweight Valley; listeners connected as early as this
	# harness structurally allows (immediately once a live NeedsMood
	# reference exists, before ANY seeding call runs) -- the earliest point
	# achievable, since a real full-GameWorld boot runs Valley attachment,
	# setup(), and genesis all synchronously in one call with no exposed
	# seam to connect a listener mid-sequence (see class doc comment).
	var villager_config := VillagerAIConfig.new()
	villager_config.starting_villager_count = 2
	var valley: Valley = _instantiate_bare_valley(villager_config)
	var needs_mood: NeedsMood = valley.get_needs_mood()

	var urgent_emits: Array[int] = [0]
	var satisfied_emits: Array[int] = [0]
	var band_emits: Array[int] = [0]
	needs_mood.need_urgent.connect(func(_v: int, _n: StringName) -> void: urgent_emits[0] += 1)
	needs_mood.need_satisfied.connect(func(_v: int, _n: StringName) -> void: satisfied_emits[0] += 1)
	needs_mood.mood_band_changed.connect(func(_v: int, _b: NeedsMood.MoodBand) -> void: band_emits[0] += 1)

	needs_mood.setup()
	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	var center: Vector3i = VillagerRosterSpawner.world_center_cell(voxel_world.config)
	_fill_flat_plane(voxel_world, center, 10)

	# Act -- the full seeding pass (both call sites), then one real tick (a
	# fresh spawn at 100 crosses nothing on its very first tick).
	valley.seed_default_villager_needs()
	valley.spawn_starting_roster()
	assert_int(urgent_emits[0]).is_equal(0)
	assert_int(satisfied_emits[0]).is_equal(0)
	assert_int(band_emits[0]).is_equal(0)

	TimeTickSystem.tick.emit()
	assert_int(urgent_emits[0]).is_equal(0)
	assert_int(satisfied_emits[0]).is_equal(0)
	assert_int(band_emits[0]).is_equal(0)
