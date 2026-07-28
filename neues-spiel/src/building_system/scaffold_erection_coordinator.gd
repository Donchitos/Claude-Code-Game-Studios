## Scaffold erection coordinator (story `building-034`, TD ruling D5 point 3:
## "The Building System subscribes to the existing `job_reported_unreachable`
## signal and owns the erection response. **The AI detects; the Building
## System builds.**").
##
## Injected-tier collaborator (ADR-0001 shared-object style, mirrors
## [ConstructionJobQueue]'s own "population-wide shared object, code-assigned"
## precedent) -- constructed once, subscribes to [signal
## ConstructionJobQueue.job_reported_unreachable] in its own `_init`, exactly
## like [VillagerOnSiteGate]/[VillagerSealPreventionGate]'s established
## "wires itself into its own predicate/signal seam from `_init`" shape.
##
## **Bound the response** (D5, required): a cell can be unreachable for
## reasons scaffolding cannot fix (walled off, no support within the
## cantilever limit). [ScaffoldErectionPlanner.plan_for_target] returning
## [method ScaffoldPlan.has_plan] `false` is a genuine no-op here -- the cell
## stays flagged unreachable (the report itself already set that), and this
## class never retries the SAME cell again ([member _served_cells] is a
## permanent per-cell latch, not a cooldown) -- never erects a structure that
## does not make the target reachable, never loops.
##
## **Story villager-ai-025 ("A builder always has a way down") adds a SECOND
## trigger** -- see [method _on_tick]/[method _check_villager_descent]. The
## job-cell trigger above answers "can a QUEUED CELL be reached"; this one
## answers "can a VILLAGER get back DOWN": ADR-0009's two discrete climb
## mutations ([method VillagerAi.climb_onto_self_sealed_cell]/[method
## VillagerAi._relocate_if_marooned]) are how a builder gets UP its own work
## and, when possible, back down to other reachable work -- but neither
## guarantees a route to GROUND once nothing reachable is left up there
## (measured against the real hosted `payoff_loop_demo`: a builder stranded
## on a wall crown or a finished roof, WANDERING/SLEEPING, work left
## permanently pending below it). Rather than adding a THIRD discrete
## teleport (which would make the TD's own "these two retire once their
## counters read zero" criterion unreachable forever), this reuses the SAME
## scaffolding mechanism the job-cell trigger already uses: plan and erect a
## descent scaffold from where the villager stands, subject to the SAME
## "bound the response" / "persistence before erecting" discipline as the
## job-cell trigger (see [constant DESCENT_TICKS_BEFORE_ERECTING]).
class_name ScaffoldErectionCoordinator
extends RefCounted

var voxel_world: VoxelWorldGrid
var scaffold_registry: Object
var build_project_registry: BuildProjectRegistry
var construction_job_queue: ConstructionJobQueue
var furniture_registry: Object
var config: ScaffoldConfig

## Story villager-ai-025 ("A builder always has a way down") -- the SAME
## shared [VillagerNavGraph] every hosted villager already paths through.
## Cross-wired by [Valley] AFTER this coordinator's own construction (the
## graph does not exist yet at that point -- [method
## Valley._wire_build_project_lifecycle] runs strictly BEFORE [method
## Valley._wire_villager_population], see that class's own `_ready()` call
## order) rather than constructor-injected. `null` until then, and
## permanently `null` for any caller that never wires it -- ADR-0007 §1b's
## own "a caller supplying nothing sees EXACTLY pre-amendment behaviour"
## precedent, mirrored here: see [method _on_tick]'s own early-out. Every
## pre-existing test fixture that constructs this class directly (never
## setting this field) is therefore completely unaffected -- job-cell
## erection only, exactly as before this story.
var nav_graph: VillagerNavGraph = null

## Every blueprint cell this coordinator has already produced a plan attempt
## for (successful or not) -- latched permanently so a repeated
## `job_reported_unreachable` for the SAME cell (the retry cadence already
## re-fires it periodically) never re-plans or double-erects.
var _served_cells: Dictionary[Vector3i, bool] = {}

## How many SEPARATE unreachable reports a cell must accumulate before it earns
## scaffolding. Not a tuning nicety — without it this coordinator erects a
## scaffold for essentially every wall cell in a room.
##
## Measured, not assumed: instrumenting a real hosted build of a 30-cell room
## produced 20+ reports with `planned=true` for every single one, including
## cells that were perfectly reachable moments later. A pre-claim probe reports
## a cell as unreachable whenever it happens to be unreachable AT THAT INSTANT
## — which, with one villager walking around a site, is most cells most of the
## time. Erecting on the first report therefore floods the queue with scaffold
## jobs, and since a villager may hold only ONE claim, the real wall cells
## starve: villager-ai-024's regression test fell 30/30 -> 27/30.
##
## Requiring persistence restores the design rule the user actually stated —
## scaffolding is built only when it is NEEDED. A cell that is momentarily
## out of reach recovers on its own; a cell that is structurally out of reach
## keeps reporting.
const REPORTS_BEFORE_ERECTING: int = 3

## Per-cell count of distinct unreachable reports seen so far. Cleared when the
## cell is finally served, so a later structural change starts the count fresh.
var _report_counts: Dictionary[Vector3i, int] = {}

## Story villager-ai-025 -- duck-typed roster accessor (`get_villagers() ->
## Array[VillagerAi]`, `get_settlement_ground_cell() -> Vector3i`,
## `has_settlement_ground_cell() -> bool`), mirrors [member
## ScaffoldDismantleCoordinator._roster_provider]'s own established shape
## exactly (in production, the SAME `Valley._ValleyRosterProvider` instance
## is handed to both). `null` is tolerated -- see [method _init].
var _roster_provider: Object = null

## Story villager-ai-025's own per-villager persistence gate, mirroring
## [constant REPORTS_BEFORE_ERECTING]'s established "a single observation is
## 'not right now', never 'needs scaffolding'" discipline -- counted in
## consecutive per-tick OBSERVATIONS of "still marooned" rather than
## separate `job_reported_unreachable` signal reports, since this trigger has
## no signal of its own; [method _on_tick] firing IS the observation. A
## villager that regains a path on its own before reaching this threshold
## (the common case -- mid-Deciding-re-entry reads "marooned" for a tick or
## two as a matter of course) never erects anything; without this gate the
## SAME flood [constant REPORTS_BEFORE_ERECTING] already prevents on the
## job-cell side (measured: 20+ reports, every one planning successfully,
## starving the real wall cells 30/30 -> 27/30) would recur here on every
## real-boot run.
const DESCENT_TICKS_BEFORE_ERECTING: int = 3

## Per-villager-id count of consecutive ticks [method _on_tick] has observed
## that villager marooned (see [method _check_villager_descent]). Erased the
## instant a tick observes the villager NOT marooned (state changed,
## descended, or a path opened up some other way) -- never a monotonic
## counter, mirrors [member _report_counts]'s own reset-on-recovery shape.
var _villager_marooned_ticks: Dictionary[int, int] = {}

## Every villager-standing cell this coordinator has already produced a
## SUCCESSFUL descent-scaffold plan for -- latched permanently, mirrors
## [member _served_cells]'s identical "never retries the SAME cell again"
## discipline. Kept as a SEPARATE dictionary from [member _served_cells] even
## though both hold [Vector3i] keys: the two address spaces are conceptually
## different (a queued blueprint cell vs. a villager's own transient standing
## position) and collapsing them would let an address served for one reason
## silently suppress the other.
var _served_descent_cells: Dictionary[Vector3i, bool] = {}


func _init(
	p_voxel_world: VoxelWorldGrid,
	p_scaffold_registry: Object,
	p_build_project_registry: BuildProjectRegistry,
	p_construction_job_queue: ConstructionJobQueue,
	p_furniture_registry: Object,
	p_config: ScaffoldConfig,
	p_roster_provider: Object = null,
) -> void:
	assert(p_voxel_world != null, "ScaffoldErectionCoordinator requires voxel_world")
	assert(p_build_project_registry != null, "ScaffoldErectionCoordinator requires build_project_registry")
	assert(p_construction_job_queue != null, "ScaffoldErectionCoordinator requires construction_job_queue")
	assert(p_config != null, "ScaffoldErectionCoordinator requires config")
	voxel_world = p_voxel_world
	scaffold_registry = p_scaffold_registry
	build_project_registry = p_build_project_registry
	construction_job_queue = p_construction_job_queue
	furniture_registry = p_furniture_registry
	config = p_config
	construction_job_queue.job_reported_unreachable.connect(_on_job_reported_unreachable)
	_roster_provider = p_roster_provider


## Story villager-ai-025 -- the villager-descent trigger's own clock
## subscription, deliberately NOT done at `_init` time (unlike [member
## _roster_provider], which is safe to take as a constructor arg). Found
## while wiring this in: [Valley._wire_build_project_lifecycle] -- called
## from [method Node._ready], which runs BEFORE [GameWorld]'s own
## `_setup_injected_tier()` boot sweep ever calls [method
## ConstructionTickLoop.setup] -- reads [member ConstructionTickLoop.time_tick_system]
## while it is STILL `null` (that field is resolved lazily, INSIDE `setup()`
## itself). A constructor-time subscription against that still-null value
## would silently never connect -- confirmed directly against a real boot:
## [member ScaffoldDismantleCoordinator]'s OWN identical `_init`-time
## subscription pattern has the SAME defect today (pre-existing, out of this
## story's own scope to fix -- flagged here, not silently patched elsewhere).
## Called from [method Valley.connect_scaffold_erection_descent_trigger],
## itself reached only from [method GameWorld._run_world_genesis] --
## strictly AFTER `_setup_injected_tier()` has already run, the SAME timing
## guarantee [method Valley.build_villager_nav_graph]'s own call site
## already relies on. Duck-typed against `signal tick`, `null`-tolerant (a
## caller that never wires a clock here sees NO villager-descent behaviour
## at all -- ADR-0007 §1b parity, same as every other optional collaborator
## on this class). "Connect at most once" guard mirrors
## [ScaffoldDismantleCoordinator]'s own defensive shape (re-entrant-safe
## against a test or a future re-genesis call).
func connect_tick(time_tick_system: Object) -> void:
	if time_tick_system == null:
		return
	@warning_ignore("unsafe_property_access")
	if not time_tick_system.tick.is_connected(_on_tick):
		@warning_ignore("unsafe_property_access")
		time_tick_system.tick.connect(_on_tick)


## [signal ConstructionJobQueue.job_reported_unreachable] handler (AC1: "the
## system detects an unreachable target cell and erects scaffolding exactly
## there... automatic, on demand"). Only ever responds for a cell belonging
## to a `BUILD`-kind project (never `DIG`/`SCAFFOLD` -- Out of Scope: "Build
## projects only").
func _on_job_reported_unreachable(cell: Vector3i) -> void:
	if _served_cells.has(cell):
		return
	var owning_id: int = build_project_registry.project_at_cell(cell)
	if owning_id == -1:
		return
	var owning_project: BuildProject = build_project_registry.get_project(owning_id)
	if owning_project == null or owning_project.kind != BuildProject.Kind.BUILD:
		return
	# PERSISTENCE GATE — see REPORTS_BEFORE_ERECTING. A single report means
	# "not right now", not "never without help".
	var seen: int = _report_counts.get(cell, 0) + 1
	_report_counts[cell] = seen
	if seen < REPORTS_BEFORE_ERECTING:
		return

	var plan: ScaffoldPlan = ScaffoldErectionPlanner.plan_for_target(
		voxel_world, scaffold_registry, build_project_registry, furniture_registry,
		cell, config.scaffold_max_cantilever_cells
	)
	if not plan.has_plan():
		# Deliberately NOT latched. `_served_cells` used to be written before
		# this check, so a cell whose plan failed ONCE was suppressed forever —
		# even after the world changed and a plan became possible. A failed plan
		# is a "not yet", never a "never": the report seam re-fires on its own
		# throttle, and the next attempt sees a different world.
		return
	_served_cells[cell] = true
	_report_counts.erase(cell)
	_erect(plan, owning_id)


## D3 (RULED: Option (a)) -- a scaffold structure is its OWN `SCAFFOLD`-kind
## project, linked to its owner via [member BuildProject.owner_project_id],
## never a member of the project it serves. Registered into BOTH
## [member build_project_registry] (the reverse cell index) and [member
## construction_job_queue] (so its cells become real, worker-executed jobs,
## AC2), then released immediately -- a scaffold project needs no player
## "Bau starten" step; it is system-generated and job-eligible the instant it
## exists (AC1: "the player only draws the room").
func _erect(plan: ScaffoldPlan, owner_project_id: int) -> void:
	var scaffold_project := BuildProject.new(
		build_project_registry.allocate_project_id(), BuildProject.Kind.SCAFFOLD, owner_project_id
	)
	for scaffold_cell: Vector3i in plan.cells:
		var blueprint_cell := BlueprintCell.new(
			scaffold_cell, BlueprintCell.MicroState.PLANNED, BlueprintCell.Category.SCAFFOLD
		)
		scaffold_project.add_cell(blueprint_cell)
	build_project_registry.register_project(scaffold_project)
	construction_job_queue.add_project(scaffold_project)
	scaffold_project.release()


# =============================================================================
# Story villager-ai-025 -- the villager-descent trigger
# =============================================================================

## [signal TimeTickSystem.tick] handler. A no-op with [member _roster_provider]
## or [member nav_graph] unwired (ADR-0007 §1b parity: a caller supplying
## neither sees EXACTLY this class's pre-story behaviour -- job-cell erection
## only; every pre-existing test fixture that constructs this class directly
## is unaffected).
func _on_tick() -> void:
	if _roster_provider == null or nav_graph == null:
		return
	@warning_ignore("unsafe_method_access")
	var villagers: Array = _roster_provider.get_villagers()
	for villager: VillagerAi in villagers:
		_check_villager_descent(villager)


## Story villager-ai-025's own erection trigger -- see class doc comment.
## Mirrors [method _on_job_reported_unreachable]'s exact shape (persistence
## gate, then [method ScaffoldErectionPlanner.plan_for_target], then latch
## ONLY on success), applied to a VILLAGER'S OWN standing cell instead of a
## queued job cell.
##
## **Reuses [method ScaffoldErectionPlanner.plan_for_target] directly,
## unmodified** rather than adding a sibling "straight-down column" planner:
## passing the villager's OWN [method VillagerAi.get_current_cell] as that
## method's `target_cell` produces exactly the wanted shape -- a scaffold
## column anchored in an ADJACENT, currently-empty (x, z) footprint (D9
## already forbids the villager's own occupied address from ever being
## selected as that staging cell, so there is no risk of "planning a
## scaffold where the villager already stands"), landing a staging cell at
## `|dy| <= 1` of the villager's own height so the very next step is a
## single legal side-step onto it, then straight down. A genuinely
## straight-down column AT the villager's own (x, z) would not even be
## buildable in the measured stall geometries (a wall crown / a roof top):
## that column IS the villager's own finished structure, solid rock
## underfoot all the way down -- there is no empty address left to erect
## scaffolding INTO there, and none is needed (the structure itself is
## already the support). The problem this story fixes is never "no support
## column exists," it is "no LEGAL STEP exists off of the one the villager
## is standing on" -- precisely what an adjacent staging cell supplies.
##
## The erected scaffold's `owner_project_id` is resolved from the cell
## DIRECTLY BELOW the villager -- the structure it is stranded on top of, if
## any (`-1`, "no owner", when the villager stands above bare terrain rather
## than a tracked project, e.g. natural elevation -- not a measured scenario
## this story covers, and not itself wrong, only never auto-dismantled).
## This is deliberate, not incidental: it means [ScaffoldDismantleCoordinator]
## needs ZERO changes to correctly tear this descent scaffold down again once
## nobody needs it -- [method
## ScaffoldDismantleCoordinator._someone_is_still_up_there] (SC-INV-2) already
## refuses to dismantle while ANY villager still occupies the structure's own
## footprint or anything above it, which is exactly this villager, right now.
func _check_villager_descent(villager: VillagerAi) -> void:
	var state: VillagerAi.State = villager.get_state()
	if state != VillagerAi.State.WANDERING and state != VillagerAi.State.SLEEPING:
		# Not settled into "nothing left to do" yet (still Deciding/Traveling/
		# Working) -- never treated as marooned mid-transition, mirrors
		# [method VillagerAi._relocate_if_marooned]'s own "only once genuinely
		# topped out" discipline for the SAME reason.
		_villager_marooned_ticks.erase(villager.get_villager_id())
		return
	if _roster_provider == null:
		return
	@warning_ignore("unsafe_method_access")
	if not bool(_roster_provider.has_settlement_ground_cell()):
		return
	@warning_ignore("unsafe_method_access")
	var ground_cell: Vector3i = _roster_provider.get_settlement_ground_cell()
	var current_cell: Vector3i = villager.get_current_cell()
	# "Stands above ground" (this story's own framing) -- never plans
	# scaffolding for a villager at or below the settlement's own ground
	# reference height. Load-bearing for AC4: a villager walled in AT ground
	# level (villager-ai-016/019's own protected Edge Case 2 scenario --
	# GDD Rule 15: "a walled-in Idle/Wandering villager stays put, never
	# rescued") would already fail [method
	# ScaffoldErectionPlanner.plan_for_target] on its own merits (every
	# immediate neighbor reads SOLID, so no valid staging address exists) --
	# gating on height too means this coordinator never even ATTEMPTS a plan
	# for that scenario, defense in depth rather than relying solely on the
	# planner's own no-op to stay silent.
	if current_cell.y <= ground_cell.y:
		_villager_marooned_ticks.erase(villager.get_villager_id())
		return
	if not nav_graph.find_path(current_cell, ground_cell).is_empty():
		_villager_marooned_ticks.erase(villager.get_villager_id())
		return
	# PERSISTENCE GATE — see DESCENT_TICKS_BEFORE_ERECTING. One observation
	# means "not right now", not "needs scaffolding" -- the exact discipline
	# that keeps this coordinator's job-cell trigger from flooding the queue,
	# applied here to the SAME class of transient false positive (a villager
	# mid-Deciding-re-entry, or one about to be moved by [method
	# VillagerAi._relocate_if_marooned] on its own, reads "marooned" for a
	# tick or two as a matter of course).
	var seen: int = _villager_marooned_ticks.get(villager.get_villager_id(), 0) + 1
	_villager_marooned_ticks[villager.get_villager_id()] = seen
	if seen < DESCENT_TICKS_BEFORE_ERECTING:
		return
	if _served_descent_cells.has(current_cell):
		# Already attempted (and, since this dictionary only ever latches on
		# SUCCESS, already SUCCEEDED) for this exact standing cell -- never
		# double-erects while the villager waits for the scaffold below it to
		# actually finish building and become usable.
		return
	var plan: ScaffoldPlan = ScaffoldErectionPlanner.plan_for_target(
		voxel_world, scaffold_registry, build_project_registry, furniture_registry,
		current_cell, config.scaffold_max_cantilever_cells
	)
	if not plan.has_plan():
		# Deliberately NOT latched -- see [method _on_job_reported_unreachable]'s
		# own identical comment. A failed plan is a "not yet", never a "never":
		# the persistence gate above will fire again on the very next tick this
		# villager is still observed marooned, and the next attempt sees
		# whatever the world looks like by then.
		return
	_served_descent_cells[current_cell] = true
	_villager_marooned_ticks.erase(villager.get_villager_id())
	var owner_project_id: int = build_project_registry.project_at_cell(current_cell + Vector3i(0, -1, 0))
	_erect(plan, owner_project_id)
