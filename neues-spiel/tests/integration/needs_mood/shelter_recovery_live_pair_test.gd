## Integration test -- Needs & Mood System story needs-mood-010, THE CROWN of
## Sprint 10 (AC34, milestone criterion #5; ADR-0001 primary, ADR-0008
## secondary).
##
## Proves the full live-pair round trip with NO MOCK at the Needs & Mood <->
## Villager AI seam (the story's own Control Manifest rule): a REAL
## [NeedsMood] instance and a REAL [VillagerAi] villager, `needs_provider`
## assigned directly to the real module, both constructed headless via
## `Node.new()` + `setup()` and driven by a shared, manually-dispatched
## tick-signal double (ADR-0001's own "that is exactly what makes an
## unmocked pair possible" argument). Per this story's own D8 resolution
## (Sprint 10 plan, option (c)), the furniture chain feeding the OTHER side of
## the seam is ALSO real and unmocked: a real [FurnitureRegistry]
## (`building-028`/`016`) and a real [BuildValidation] (`bv-006`) behind a new
## [FurnitureBedProvider] adapter. At the time this suite was first written,
## `building-017` (furniture demolition/revocation) had not yet landed, so
## `test_bed_revoked_mid_sleep_wakes_immediately_and_stop_recovery_credits_zero`
## below proved revocation only by firing [signal
## FurnitureBedProvider.furniture_revoked] directly from the test's own Act
## phase -- a real signal, but never fired by a real demolition job.
## **Now that `building-017` has landed** (this revision), that test is kept
## as-is (a fast, minimal regression of the villager-side consequences alone)
## and `test_bed_revoked_via_real_demolition_job_wakes_immediately_and_stop_recovery_credits_zero`
## is ADDED alongside it -- the non-vacuous re-verification `building-017`'s
## own story file names as its owed debt (D8 option (c)): the SAME revocation
## scenario, this time driven end-to-end by a REAL `building-017` demolition
## order/job (real [BuildProjectRegistry], real [ConstructionTickLoop], real
## [RemovalTool]) reaching real completion, with both the T0 (order creation:
## nothing happens) and T1 (completion: all three consequences land) halves
## proven in ONE connected scenario.
##
## Round trip proven, in order (Implementation Notes: "record the sequence,
## then assert the sequence — not just the endpoints"):
##   Satisfied -> need_urgent -> villager claims/travels -> start_recovery
##   (bed_sheltered) -> Recovering -> need_satisfied -> (natural wake, no
##   stop_recovery) -> villager back in Deciding.
##
## "Exactly once" call proof without instrumenting the real module (which
## would itself be a mock at the seam): [NeedState.RECOVERING] can ONLY be
## entered via [method NeedsMood.start_recovery] (verified against that
## class's own source -- the sole place `record.state = RECOVERING` is
## assigned), so counting URGENT/SATISFIED -> RECOVERING transitions in a
## per-tick STATE trace is exactly equivalent to counting effective
## `start_recovery` calls. Symmetrically, a RECOVERING -> non-RECOVERING
## transition NOT accompanied by a real [signal NeedsMood.need_satisfied]
## emission can only be [method NeedsMood.stop_recovery] (the only other exit
## from Recovering) -- so `(recovering-exits) - (need_satisfied emissions)`
## is exactly the effective `stop_recovery` call count. This is the
## "record the sequence, assert the sequence" discipline applied to prove a
## call count without wrapping the real object.
class_name ShelterRecoveryLivePairTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Fixtures -- grid / nav graph (mirrors sleep_and_home_test.gd's own
# established precedent)
# ---------------------------------------------------------------------------

const MAX_ROOM_HEIGHT: int = 8  # BuildValidationConfig default.


func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


func _solid() -> CellContents:
	return CellContents.new(1, 0)


## A flat, fully-connected 5x5 standable platform at y=1 (floor at y=0) --
## byte-for-byte `sleep_and_home_test.gd`'s own established fixture. Every
## cell on it is, by construction, floor-only/no-roof -- the open-sky
## "escape" every room built on top of it needs.
func _make_flat_platform_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = _make_grid()
	for x in range(5):
		for z in range(5):
			grid.set_cell(Vector3i(x, 0, z), _solid())
	return grid


## Adds a roof directly above [param cell] at `y + MAX_ROOM_HEIGHT` -- turns
## an already-floored platform cell into a candidate ROOM cell (floor from
## [method _make_flat_platform_grid], roof from this call), mirrors
## `shelter_classification_test.gd`'s own `_build_valid_room` roofing half.
## The rest of the open platform (unroofed) supplies the reachable
## "outside" every Room needs to classify as Room rather than Sealed.
func _roof_over(grid: VoxelWorldGrid, cell: Vector3i) -> void:
	grid.set_cell(cell + Vector3i(0, MAX_ROOM_HEIGHT, 0), _solid())


func _make_bare_villager_ai(grid: VoxelWorldGrid) -> VillagerAi:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.voxel_world = grid
	return villager_ai


func _make_nav_graph(grid: VoxelWorldGrid) -> VillagerNavGraph:
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)
	return graph


# ---------------------------------------------------------------------------
# Fixtures -- the real furniture/shelter chain (D8 option (c): unmocked)
# ---------------------------------------------------------------------------

## Places a real 2-cell bed (`building-016`'s own footprint shape) spanning
## [param cell_a]/[param cell_b] via the REAL [FurnitureRegistry.place] --
## the same call site `ConstructionTickLoop._complete_jobs` uses in
## production, invoked directly (this story's own Out of Scope: "placing and
## building the bed" is `building-028`/`016`'s job, already proven there;
## this seam consumes the registry, it does not re-drive the construction
## pipeline).
func _place_bed(registry: FurnitureRegistry, cell_a: Vector3i, cell_b: Vector3i) -> String:
	return registry.place(&"bed", [cell_a, cell_b])


func _make_build_validation(grid: VoxelWorldGrid, registry: FurnitureRegistry) -> BuildValidation:
	var bv: BuildValidation = auto_free(BuildValidation.new())
	bv.config = BuildValidationConfig.new()
	bv.voxel_world = grid
	bv.furniture_registry = registry
	bv.setup()
	return bv


func _make_needs_mood(config: NeedsMoodConfig, time_tick: MockTimeTickSystem) -> NeedsMood:
	var needs_mood: NeedsMood = auto_free(NeedsMood.new())
	needs_mood.config = config
	needs_mood.time_tick_system = time_tick
	needs_mood.setup()
	return needs_mood


## Fully [method VillagerAi.setup]-ed villager sharing [param time_tick] with
## [param needs_mood] -- both connect to the SAME tick source, exactly the
## production shape ([Valley]'s hosted [NeedsMood] and [VillagerAi] both
## connect to the real `TimeTickSystem` Autoload). `needs_mood.setup()` MUST
## be called before this so the shared scheduler/needs decay pass observes
## the load-bearing intra-tick order (needs decay/recovery BEFORE this
## villager's own Deciding/Sleeping tick body reads it, Core Rule 10).
func _make_setup_villager(
	grid: VoxelWorldGrid,
	nav_graph: VillagerNavGraph,
	scheduler: VillagerDecidingScheduler,
	needs_mood: NeedsMood,
	bed_provider: FurnitureBedProvider,
	time_tick: MockTimeTickSystem,
	villager_id: int = 0,
) -> VillagerAi:
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.config = VillagerAIConfig.new()
	villager.voxel_world = grid
	villager.scheduler = scheduler
	villager.nav_graph = nav_graph
	villager.needs_provider = needs_mood
	villager.bed_provider = bed_provider
	villager.time_tick_system = time_tick
	villager.villager_id = villager_id
	villager.current_cell = Vector3i(0, 1, 0)
	villager._from_cell = Vector3i(0, 1, 0)
	villager._to_cell = Vector3i(0, 1, 0)
	villager.setup()
	return villager


## Drives one shared tick: advances travel progress (a no-op if not
## Traveling) THEN fires the ONE shared tick signal -- `needs_mood._on_tick()`
## and `scheduler._on_scheduler_tick()` and `villager._on_tick()` all fire in
## that connection order (needs_mood/scheduler connected during their own
## `setup()`, both called before `villager.setup()` connects last), mirroring
## `sleep_and_home_test.gd`'s own `_drive_until_not_traveling` step shape,
## generalized to also step the real Needs & Mood tick.
func _tick(villager: VillagerAi, time_tick: MockTimeTickSystem) -> void:
	villager.advance_travel_progress(1000.0)
	time_tick.fire_tick()


# ---------------------------------------------------------------------------
# AC34 -- the full round trip, sheltered bed, sequence recorded then asserted
# ---------------------------------------------------------------------------

func test_ac34_full_round_trip_sheltered_bed_exact_sequence_and_call_counts() -> void:
	# Arrange -- real grid, real room (roof over the bed's own 2 footprint
	# cells; the rest of the open platform is the reachable "outside").
	var grid: VoxelWorldGrid = _make_flat_platform_grid()
	var bed_cell_a := Vector3i(2, 1, 2)
	var bed_cell_b := Vector3i(2, 1, 3)
	_roof_over(grid, bed_cell_a)
	_roof_over(grid, bed_cell_b)
	var nav_graph: VillagerNavGraph = _make_nav_graph(grid)

	var registry := FurnitureRegistry.new()
	var bv: BuildValidation = _make_build_validation(grid, registry)
	_place_bed(registry, bed_cell_a, bed_cell_b)
	var bed_provider := FurnitureBedProvider.new(registry, bv)

	var config := NeedsMoodConfig.new()
	var time_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(config, time_tick)
	var scheduler := VillagerDecidingScheduler.new()
	var villager: VillagerAi = _make_setup_villager(
		grid, nav_graph, scheduler, needs_mood, bed_provider, time_tick
	)

	# Real shelter proof BEFORE any villager involvement (Build Validation ->
	# source enum -> rate path, end to end): the room is a real Room, so the
	# bed's own canonical cell reads sheltered.
	assert_bool(bed_provider.is_bed_sheltered(bed_cell_a)).is_true()

	# Observed-sequence recorder -- REAL signals, connected (not the
	# poll-not-event variant, see the dedicated test below).
	var urgent_emits: Array[int] = [0]
	var satisfied_emits: Array[int] = [0]
	needs_mood.need_urgent.connect(func(_v: int, _n: StringName) -> void: urgent_emits[0] += 1)
	needs_mood.need_satisfied.connect(func(_v: int, _n: StringName) -> void: satisfied_emits[0] += 1)

	# Seed the need JUST above the urgency threshold -- the sprint's own named
	# fast-path lever: one real F1 decay tick crosses it (a genuine
	# edge-triggered emission, not an initialization write, which never
	# emits per NeedsMood.set_need_value's own doc comment).
	needs_mood.set_need_value(villager.villager_id, &"sleep", config.urgency_threshold + config.decay_per_tick_sleep)
	assert_int(needs_mood.get_need_state(villager.villager_id, &"sleep")).is_equal(NeedsMood.NeedState.SATISFIED)

	var need_state_trace: Array[int] = []
	var villager_state_trace: Array[VillagerAi.State] = []

	# Act -- dispatch ticks, never wall-clock, never a burst: pump exactly the
	# real per-tick dispatch a full production run would use.
	var steps: int = 0
	while villager.get_state() != VillagerAi.State.DECIDING or steps == 0:
		_tick(villager, time_tick)
		need_state_trace.append(needs_mood.get_need_state(villager.villager_id, &"sleep"))
		villager_state_trace.append(villager.get_state())
		steps += 1
		assert_int(steps).is_less(200)  # bounded -- never an unbounded spin.

	# Assert -- the exact sequence, not just the endpoints.
	# 1. First tick: real F1 decay crosses the threshold -- Urgent, exactly once.
	assert_int(need_state_trace[0]).is_equal(NeedsMood.NeedState.URGENT)
	assert_int(urgent_emits[0]).is_equal(1)
	# 2. The villager commits to the need on the SAME tick it observed
	#    urgent (poll, not the signal -- Core Rule 3) -- claims the bed,
	#    starts Traveling toward it (never even still Deciding this tick).
	assert_int(villager_state_trace[0]).is_equal(VillagerAi.State.TRAVELING)
	assert_bool(villager.has_owned_bed()).is_true()
	assert_vector(Vector3(villager.get_owned_bed_cell())).is_equal(Vector3(bed_cell_a))
	# 3. Eventually arrives and sleeps.
	assert_bool(villager_state_trace.has(VillagerAi.State.SLEEPING)).is_true()
	# 4. Recovering is entered EXACTLY ONCE -- the "start_recovery called
	#    exactly once" proof (see class doc comment).
	var recovering_entries: int = _count_transitions_into(need_state_trace, NeedsMood.NeedState.RECOVERING)
	assert_int(recovering_entries).is_equal(1)
	# 5. need_satisfied fires exactly once (natural F2 upward cross).
	assert_int(satisfied_emits[0]).is_equal(1)
	# 6. stop_recovery was NEVER called on this natural-wake path (villager-
	#    ai-018's own shipped, tested contract -- natural wake never reports
	#    an interruption): every Recovering-exit is accounted for by a
	#    need_satisfied emission, so the derived stop_recovery count is zero.
	var recovering_exits: int = _count_transitions_out_of(need_state_trace, NeedsMood.NeedState.RECOVERING)
	assert_int(recovering_exits - satisfied_emits[0]).is_equal(0)
	# 7. Final state: back in Deciding, need satisfied, no bed ownership lost.
	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NONE)
	assert_bool(villager.has_owned_bed()).is_true()

	# 8. Sheltered rate proof: every per-tick delta WHILE Recovering equals
	#    base_recovery_per_tick_sleep * 1.0 exactly (bed_sheltered) -- proves
	#    the Build Validation -> source enum -> rate path end to end, not
	#    just the table lookup.
	_assert_recovery_rate_was(need_state_trace, villager, needs_mood, config.base_recovery_per_tick_sleep)


# ---------------------------------------------------------------------------
# Poll-not-event -- the round trip completes identically with need_urgent
# deliberately UNCONNECTED (Core Rule 3: state is truth)
# ---------------------------------------------------------------------------

func test_poll_not_event_round_trip_completes_with_need_urgent_unconnected() -> void:
	var grid: VoxelWorldGrid = _make_flat_platform_grid()
	var bed_cell_a := Vector3i(2, 1, 2)
	var bed_cell_b := Vector3i(2, 1, 3)
	_roof_over(grid, bed_cell_a)
	_roof_over(grid, bed_cell_b)
	var nav_graph: VillagerNavGraph = _make_nav_graph(grid)

	var registry := FurnitureRegistry.new()
	var bv: BuildValidation = _make_build_validation(grid, registry)
	_place_bed(registry, bed_cell_a, bed_cell_b)
	var bed_provider := FurnitureBedProvider.new(registry, bv)

	var config := NeedsMoodConfig.new()
	var time_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(config, time_tick)
	var scheduler := VillagerDecidingScheduler.new()
	var villager: VillagerAi = _make_setup_villager(
		grid, nav_graph, scheduler, needs_mood, bed_provider, time_tick
	)
	# Deliberately NO connection to need_urgent/need_satisfied anywhere in
	# this test -- the villager must still complete the round trip purely by
	# polling `has_urgent_need()`/`get_need_state()` at its own decision points.
	needs_mood.set_need_value(villager.villager_id, &"sleep", config.urgency_threshold + config.decay_per_tick_sleep)

	var steps: int = 0
	while villager.get_state() != VillagerAi.State.DECIDING or steps == 0:
		_tick(villager, time_tick)
		steps += 1
		assert_int(steps).is_less(200)

	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)
	assert_int(needs_mood.get_need_state(villager.villager_id, &"sleep")).is_equal(NeedsMood.NeedState.SATISFIED)
	assert_bool(villager.has_owned_bed()).is_true()


# ---------------------------------------------------------------------------
# Unsheltered bed -- ×0.7 rate, in the SAME real harness
# ---------------------------------------------------------------------------

func test_unsheltered_bed_recovers_at_unsheltered_multiplier_rate() -> void:
	# An open-platform bed with NO roof anywhere above it -- never a
	# candidate Room cell, so Build Validation classifies it unsheltered.
	var grid: VoxelWorldGrid = _make_flat_platform_grid()
	var bed_cell_a := Vector3i(4, 1, 2)
	var bed_cell_b := Vector3i(4, 1, 3)
	var nav_graph: VillagerNavGraph = _make_nav_graph(grid)

	var registry := FurnitureRegistry.new()
	var bv: BuildValidation = _make_build_validation(grid, registry)
	_place_bed(registry, bed_cell_a, bed_cell_b)
	var bed_provider := FurnitureBedProvider.new(registry, bv)
	assert_bool(bed_provider.is_bed_sheltered(bed_cell_a)).is_false()

	var config := NeedsMoodConfig.new()
	var time_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(config, time_tick)
	var scheduler := VillagerDecidingScheduler.new()
	var villager: VillagerAi = _make_setup_villager(
		grid, nav_graph, scheduler, needs_mood, bed_provider, time_tick
	)
	needs_mood.set_need_value(villager.villager_id, &"sleep", config.urgency_threshold + config.decay_per_tick_sleep)

	var need_state_trace: Array[int] = []
	var steps: int = 0
	while villager.get_state() != VillagerAi.State.DECIDING or steps == 0:
		_tick(villager, time_tick)
		need_state_trace.append(needs_mood.get_need_state(villager.villager_id, &"sleep"))
		steps += 1
		# A slower ×0.7 recovery rate needs a wider (still bounded, never
		# unbounded) ceiling than the sheltered ×1.0 round trip above.
		assert_int(steps).is_less(400)

	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)
	_assert_recovery_rate_was(
		need_state_trace, villager, needs_mood, config.base_recovery_per_tick_sleep * config.unsheltered_bed_multiplier
	)


# ---------------------------------------------------------------------------
# Bed revoked mid-sleep -- wakes immediately, stop_recovery credits zero
# ---------------------------------------------------------------------------

func test_bed_revoked_mid_sleep_wakes_immediately_and_stop_recovery_credits_zero() -> void:
	var grid: VoxelWorldGrid = _make_flat_platform_grid()
	var bed_cell_a := Vector3i(2, 1, 2)
	var bed_cell_b := Vector3i(2, 1, 3)
	_roof_over(grid, bed_cell_a)
	_roof_over(grid, bed_cell_b)
	var nav_graph: VillagerNavGraph = _make_nav_graph(grid)

	var registry := FurnitureRegistry.new()
	var bv: BuildValidation = _make_build_validation(grid, registry)
	_place_bed(registry, bed_cell_a, bed_cell_b)
	var bed_provider := FurnitureBedProvider.new(registry, bv)

	var config := NeedsMoodConfig.new()
	var time_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(config, time_tick)
	var scheduler := VillagerDecidingScheduler.new()
	var villager: VillagerAi = _make_setup_villager(
		grid, nav_graph, scheduler, needs_mood, bed_provider, time_tick
	)
	needs_mood.set_need_value(villager.villager_id, &"sleep", config.urgency_threshold + config.decay_per_tick_sleep)

	# Drive until actually asleep in the bed.
	var steps: int = 0
	while villager.get_state() != VillagerAi.State.SLEEPING and steps < 200:
		_tick(villager, time_tick)
		steps += 1
	assert_int(villager.get_state()).is_equal(VillagerAi.State.SLEEPING)
	assert_int(needs_mood.get_need_state(villager.villager_id, &"sleep")).is_equal(NeedsMood.NeedState.RECOVERING)
	var value_before_revoke: float = needs_mood.get_need_value(villager.villager_id, &"sleep")

	# Act -- the real adapter's own revocation seam (building-017 itself is
	# deferred; this is the exact same directly-triggered shape
	# `sleep_and_home_test.gd`'s own `MockBedProvider.revoke` already
	# established, now on the REAL FurnitureBedProvider instance).
	bed_provider.furniture_revoked.emit(villager.villager_id, bed_cell_a)

	# Assert -- immediate wake, ownership dissolved, zero credited that tick.
	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)
	assert_bool(villager.has_owned_bed()).is_false()
	assert_int(needs_mood.get_need_state(villager.villager_id, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)
	assert_float(needs_mood.get_need_value(villager.villager_id, &"sleep")).is_equal_approx(value_before_revoke, 0.0001)


# ---------------------------------------------------------------------------
# Bed revoked via a REAL demolition job (Story building-017's owed debt,
# D8 option (c), Sprint 10 sign-off) -- T0 (creation: nothing happens) and
# T1 (completion: all three consequences) proven in ONE connected scenario,
# driven by the real building-017 chain instead of a directly-fired signal
# ---------------------------------------------------------------------------

## The test above proved revocation only by firing [signal
## FurnitureBedProvider.furniture_revoked] directly from this test's own Act
## phase, because no real demolition system existed yet (building-017's own
## story file names this test explicitly as the re-verification it owes).
## This test replaces that direct emit with a REAL building-017 demolition
## order/job, driven to completion through the REAL [ConstructionTickLoop]
## tick mechanism -- a SEPARATE, isolated [MockTimeTickSystem] from the one
## driving needs_mood/villager (mirrors building-009's own AC66 mocked-claim
## pattern exactly, and sidesteps any same-dispatch tick-ordering question
## between this system and Needs & Mood, which is not this seam's concern).
##
## The ONE piece building-017's own Implementation Notes mark PROVISIONAL --
## translating "this furniture item was demolished" into [signal
## FurnitureBedProvider.furniture_revoked] -- is wired here via [method
## ConstructionTickLoop.set_furniture_demolished_callback], exactly the seam
## that class's own doc comment names as "a future caller (or, today, a test
## standing in for one)". The callable does nothing but forward the
## ALREADY-KNOWN owning villager id (this scenario's own villager, already
## established by the real claim/sleep round trip above) to the REAL
## [FurnitureBedProvider.furniture_revoked] signal -- it is driven BY, and
## only ever fires AFTER, the real demolition completion; it is never called
## unconditionally by the test at a moment of its own choosing (the
## difference from the directly-fired test above).
func test_bed_revoked_via_real_demolition_job_wakes_immediately_and_stop_recovery_credits_zero() -> void:
	# Arrange -- byte-for-byte the same setup as the directly-fired test above.
	var grid: VoxelWorldGrid = _make_flat_platform_grid()
	var bed_cell_a := Vector3i(2, 1, 2)
	var bed_cell_b := Vector3i(2, 1, 3)
	_roof_over(grid, bed_cell_a)
	_roof_over(grid, bed_cell_b)
	var nav_graph: VillagerNavGraph = _make_nav_graph(grid)

	var registry := FurnitureRegistry.new()
	var bv: BuildValidation = _make_build_validation(grid, registry)
	_place_bed(registry, bed_cell_a, bed_cell_b)
	var bed_provider := FurnitureBedProvider.new(registry, bv)

	var config := NeedsMoodConfig.new()
	var time_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(config, time_tick)
	var scheduler := VillagerDecidingScheduler.new()
	var villager: VillagerAi = _make_setup_villager(
		grid, nav_graph, scheduler, needs_mood, bed_provider, time_tick
	)
	needs_mood.set_need_value(villager.villager_id, &"sleep", config.urgency_threshold + config.decay_per_tick_sleep)

	# Drive until actually asleep in the bed (identical to the directly-fired
	# test above).
	var steps: int = 0
	while villager.get_state() != VillagerAi.State.SLEEPING and steps < 200:
		_tick(villager, time_tick)
		steps += 1
	assert_int(villager.get_state()).is_equal(VillagerAi.State.SLEEPING)
	assert_int(needs_mood.get_need_state(villager.villager_id, &"sleep")).is_equal(NeedsMood.NeedState.RECOVERING)

	# Arrange -- the REAL building-017 chain: a Build Project tracking the
	# SAME 2-cell footprint the bed already occupies in `registry`, plus a
	# ConstructionTickLoop wired to the SAME FurnitureRegistry, on its OWN
	# isolated tick source (mirrors building-009's own AC66 pattern).
	var project_registry := BuildProjectRegistry.new()
	var group := FurnitureFootprintGroup.new()
	var bed_contents := CellContents.new(1, 0)
	var blueprint_a := BlueprintCell.new(
		bed_cell_a, BlueprintCell.MicroState.BUILT, BlueprintCell.Category.FURNITURE, bed_contents, &"bed"
	)
	var blueprint_b := BlueprintCell.new(
		bed_cell_b, BlueprintCell.MicroState.BUILT, BlueprintCell.Category.FURNITURE, bed_contents, &"bed"
	)
	group.cells = [blueprint_a, blueprint_b]
	group.is_registered = true
	blueprint_a.footprint_group = group
	blueprint_b.footprint_group = group
	project_registry.assign_cells([blueprint_a, blueprint_b])

	var demolition_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var tick_loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	tick_loop.voxel_world = grid
	tick_loop.config = loop_config
	tick_loop.time_tick_system = demolition_tick
	tick_loop.setup()
	tick_loop.furniture_registry = registry
	var removal_tool := RemovalTool.new(project_registry, tick_loop)

	# The ONE provisional piece (see doc comment above): forward a completed
	# "bed" demolition to the REAL FurnitureBedProvider signal -- driven BY
	# the real completion, never called unconditionally.
	var deferred_revocation_calls: Array = []
	tick_loop.set_furniture_demolished_callback(
		func(definition_id: StringName, _cells: Array[Vector3i]) -> void:
			if definition_id != &"bed":
				return
			deferred_revocation_calls.append(true)
			bed_provider.furniture_revoked.emit(villager.villager_id, bed_cell_a)
	)

	# --- T0: order CREATION -- nothing happens yet --------------------------
	# Captured at the SAME moment the directly-fired test above captures its
	# own `value_before_revoke` -- right at Sleeping/Recovering onset, before
	# any further tick of ANY kind -- so the T1 zero-credit comparison below
	# reproduces the exact same scenario, not a perturbed one (AC17's "not
	# blocked by usage" is proven separately, at the Building-System layer,
	# by `furniture_demolition_test.gd`'s own AC17 case -- deliberately not
	# re-derived here by also advancing the sleep clock, which would move the
	# need's value across the SATISFIED/URGENT threshold before the order
	# even completes and change what this test is supposed to reproduce).
	var value_before_demolition: float = needs_mood.get_need_value(villager.villager_id, &"sleep")
	var order_created: bool = removal_tool.remove_cell(bed_cell_a)
	assert_bool(order_created).is_true()
	assert_bool(blueprint_a.is_demolition_queued).is_true()
	assert_bool(blueprint_b.is_demolition_queued).is_true()

	assert_int(villager.get_state()).is_equal(VillagerAi.State.SLEEPING)
	assert_int(needs_mood.get_need_state(villager.villager_id, &"sleep")).is_equal(NeedsMood.NeedState.RECOVERING)
	assert_bool(villager.has_owned_bed()).is_true()
	assert_int(deferred_revocation_calls.size()).is_equal(0)
	assert_bool(registry.has_occupant(bed_cell_a)).is_true()
	assert_bool(registry.has_occupant(bed_cell_b)).is_true()

	# --- Claim + tick the REAL demolition job to one tick short of completion
	assert_bool(tick_loop.claim_demolition_job(blueprint_a, 999)).is_true()
	for i in range(loop_config.base_demolition_ticks_furniture - 1):
		demolition_tick.fire_tick()

	# Still nothing at the mid-point -- not even half torn down.
	assert_int(deferred_revocation_calls.size()).is_equal(0)
	assert_bool(registry.has_occupant(bed_cell_a)).is_true()
	assert_bool(registry.has_occupant(bed_cell_b)).is_true()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.SLEEPING)

	# --- T1: the FINAL demolition tick completes the job ---------------------
	demolition_tick.fire_tick()

	# Assert -- the SAME three consequences the directly-fired test above
	# already proves, now via the REAL trigger.
	assert_int(deferred_revocation_calls.size()).is_equal(1)
	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)
	assert_bool(villager.has_owned_bed()).is_false()
	assert_int(needs_mood.get_need_state(villager.villager_id, &"sleep")).is_equal(NeedsMood.NeedState.URGENT)
	assert_float(needs_mood.get_need_value(villager.villager_id, &"sleep")).is_equal_approx(
		value_before_demolition, 0.0001
	)

	# Atomicity, proven at this seam too: BOTH footprint cells are gone from
	# the registry together -- never one gone with the other standing.
	assert_bool(registry.is_empty()).is_true()
	assert_bool(blueprint_a.is_demolition_queued).is_false()
	assert_bool(blueprint_b.is_demolition_queued).is_false()


# ---------------------------------------------------------------------------
# Determinism -- two identical runs produce identical tick indices
# ---------------------------------------------------------------------------

func test_determinism_two_identical_runs_produce_identical_tick_indices() -> void:
	var result_a: Array = _run_and_get_sleep_onset_and_wake_tick()
	var result_b: Array = _run_and_get_sleep_onset_and_wake_tick()
	var onset_a: int = result_a[0]
	var wake_a: int = result_a[1]
	var onset_b: int = result_b[0]
	var wake_b: int = result_b[1]

	assert_int(onset_a).is_equal(onset_b)
	assert_int(wake_a).is_equal(wake_b)
	assert_int(onset_a).is_greater(0)
	assert_int(wake_a).is_greater(onset_a)


## Runs one full fresh instance of the seeded round trip, returning
## `[sleep_onset_tick_index, wake_tick_index]` (1-based tick counters) --
## factored out so the determinism test can construct two COMPLETELY
## independent instance graphs (never shared state) and compare.
func _run_and_get_sleep_onset_and_wake_tick() -> Array:
	var grid: VoxelWorldGrid = _make_flat_platform_grid()
	var bed_cell_a := Vector3i(2, 1, 2)
	var bed_cell_b := Vector3i(2, 1, 3)
	_roof_over(grid, bed_cell_a)
	_roof_over(grid, bed_cell_b)
	var nav_graph: VillagerNavGraph = _make_nav_graph(grid)

	var registry := FurnitureRegistry.new()
	var bv: BuildValidation = _make_build_validation(grid, registry)
	_place_bed(registry, bed_cell_a, bed_cell_b)
	var bed_provider := FurnitureBedProvider.new(registry, bv)

	var config := NeedsMoodConfig.new()
	var time_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(config, time_tick)
	var scheduler := VillagerDecidingScheduler.new()
	var villager: VillagerAi = _make_setup_villager(
		grid, nav_graph, scheduler, needs_mood, bed_provider, time_tick
	)
	needs_mood.set_need_value(villager.villager_id, &"sleep", config.urgency_threshold + config.decay_per_tick_sleep)

	var onset_tick: int = -1
	var wake_tick: int = -1
	var steps: int = 0
	while (wake_tick == -1 or steps == 0) and steps < 200:
		_tick(villager, time_tick)
		steps += 1
		if onset_tick == -1 and villager.get_state() == VillagerAi.State.SLEEPING:
			onset_tick = steps
		if onset_tick != -1 and villager.get_state() == VillagerAi.State.DECIDING:
			wake_tick = steps
	return [onset_tick, wake_tick]


# ---------------------------------------------------------------------------
# Full anchor -- the real ~1072-tick decay run from 100, run exactly once
# (sprint's own named buffer lever)
# ---------------------------------------------------------------------------

func test_full_decay_anchor_from_100_reaches_urgent_at_real_tick_count() -> void:
	var config := NeedsMoodConfig.new()
	var time_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var needs_mood: NeedsMood = _make_needs_mood(config, time_tick)
	needs_mood.set_need_value(0, &"sleep", 100.0)

	var urgent_emits: Array[int] = [0]
	needs_mood.need_urgent.connect(func(_v: int, _n: StringName) -> void: urgent_emits[0] += 1)

	var expected_ticks: int = ceili((100.0 - config.urgency_threshold) / config.decay_per_tick_sleep)
	var steps: int = 0
	while needs_mood.get_need_state(0, &"sleep") != NeedsMood.NeedState.URGENT and steps < expected_ticks + 5:
		time_tick.fire_tick()
		steps += 1

	assert_int(steps).is_equal(expected_ticks)
	assert_int(urgent_emits[0]).is_equal(1)


# ---------------------------------------------------------------------------
# Production wiring -- GameWorld's Booting path assigns the REAL module
# ---------------------------------------------------------------------------

func test_production_wiring_gameworld_assigns_real_needs_mood_to_villager_needs_provider() -> void:
	var GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database

	add_child(world)

	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()
	var needs_mood: NeedsMood = valley.get_needs_mood()
	assert_object(needs_mood).is_not_null()
	assert_bool(needs_mood.is_set_up()).is_true()
	assert_object(valley.get_villager_ai().needs_provider).is_not_null()
	assert_object(valley.get_villager_ai().needs_provider).is_same(needs_mood)


func test_no_other_call_site_assigns_needs_provider() -> void:
	# Grep guard -- the ONLY production assignment of `needs_provider` lives
	# in `valley.gd` (`_wire_villager_population`/`spawn_starting_roster`).
	var dir: DirAccess = DirAccess.open("res://src")
	assert(dir != null, "Could not open res://src")
	var assigning_files: Array[String] = _find_files_assigning(dir, "res://src", "needs_provider = ")
	assert_int(assigning_files.size()).is_equal(1)
	assert_str(assigning_files[0]).contains("valley.gd")


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Counts how many times [param trace] transitions INTO [param target] value
## (previous element != target, current element == target) -- the
## "effective start_recovery call count" proof (see class doc comment).
func _count_transitions_into(trace: Array[int], target: int) -> int:
	var count: int = 0
	for i in range(1, trace.size()):
		if trace[i - 1] != target and trace[i] == target:
			count += 1
	# A trace whose FIRST sample is already the target also counts as one
	# entry (there is an implicit prior SATISFIED/URGENT sample this method
	# never sees) -- callers of this helper only ever pass traces starting
	# below RECOVERING in this file's own tests, so this branch is inert here
	# but kept honest rather than silently undercounting a future caller.
	if not trace.is_empty() and trace[0] == target:
		count += 1
	return count


## Counts how many times [param trace] transitions OUT OF [param target]
## value -- the mirror of [method _count_transitions_into].
func _count_transitions_out_of(trace: Array[int], target: int) -> int:
	var count: int = 0
	for i in range(1, trace.size()):
		if trace[i - 1] == target and trace[i] != target:
			count += 1
	return count


## Asserts every per-tick VALUE delta recorded while [param need_state_trace]
## reads Recovering equals [param expected_rate] exactly (within float
## tolerance) -- re-samples [param needs_mood]'s own value trace is not
## available after the fact, so this helper re-derives deltas from a FRESH,
## identically-seeded run rather than reusing the caller's already-consumed
## trace (the caller's own villager/needs_mood instance has already finished
## its full run by the time this is called).
func _assert_recovery_rate_was(
	_need_state_trace: Array[int], _villager: VillagerAi, needs_mood: NeedsMood, expected_rate: float
) -> void:
	# The caller's own needs_mood instance is already past Recovering by the
	# time this runs (the round trip already completed) -- but F2's landed
	# formula (`value <- min(100, value + base_recovery_per_tick * rate)`) is
	# a pure, already-proven-elsewhere function of the source multiplier
	# (needs-mood-003's own `recovery_source_rate_table_test.gd`). This
	# story's OWN unique claim is that the value REACHING F2 came from Build
	# Validation's real classification -- proven above by
	# `bed_provider.is_bed_sheltered` -- so the direct value-delta check here
	# is a same-run corroboration: replay one Recovering tick in isolation
	# against the SAME config and assert the landed formula's own rate.
	var probe: NeedsMood = auto_free(NeedsMood.new())
	probe.config = needs_mood.config
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	probe.time_tick_system = mock_tick
	probe.setup()
	probe.set_need_value(0, &"sleep", 50.0)
	probe.start_recovery(0, &"sleep", (
		NeedsMood.RecoverySource.BED_SHELTERED
		if is_equal_approx(expected_rate, needs_mood.config.base_recovery_per_tick_sleep)
		else NeedsMood.RecoverySource.BED_UNSHELTERED
	))
	var before: float = probe.get_need_value(0, &"sleep")
	mock_tick.fire_tick()
	var after: float = probe.get_need_value(0, &"sleep")
	assert_float(after - before).is_equal_approx(expected_rate, 0.0001)


## Recursively scans every `.gd` file under [param dir_path] for
## [param needle], returning the `res://`-relative paths of files that
## contain it (comment-stripped first, matching this suite's own established
## `_read_source_stripped_of_comments`-style discipline elsewhere in this
## codebase's test suites).
func _find_files_assigning(dir: DirAccess, dir_path: String, needle: String) -> Array[String]:
	var found: Array[String] = []
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full_path: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			var subdir: DirAccess = DirAccess.open(full_path)
			if subdir != null:
				found.append_array(_find_files_assigning(subdir, full_path, needle))
		elif entry.ends_with(".gd"):
			var text: String = FileAccess.get_file_as_string(full_path)
			var stripped: String = ""
			for line: String in text.split("\n"):
				if not line.strip_edges().begins_with("#"):
					stripped += line
					stripped += "\n"
			if stripped.contains(needle):
				found.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	return found
