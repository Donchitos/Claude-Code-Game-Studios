## Integration test — Time & Tick System Story tick-006 (Cross-system
## integration guarantees; ADR-0001 primary, ADR-0002 secondary).
##
## Proves the three integration-tier acceptance criteria this story owns
## (GDD AC6/AC7/AC8):
##
## 1. [member Engine.time_scale] remains at its default (1.0) regardless of
##    this system's pause/warp state (AC-1, GDD AC6, TR-time-tick-system-025)
##    — plus a grep-verifiable regression guard that neither
##    [member Engine.time_scale] nor [member SceneTree.paused] appears as CODE
##    (not doc-comment prose) anywhere in this system's own source directory,
##    per the story's Test Evidence.
## 2. When a scene transition begins, `game_delta` continues to be computed
##    normally — never suspended by [GameWorld]'s Transitioning state (AC-2,
##    GDD AC7, TR-time-tick-system-027).
## 3. Across a full transition (begin -> complete, both outcomes), this
##    system's `time_warp`/`paused`/accumulator state is untouched, AND no API
##    of this system is invoked by transition events at all (AC-3, GDD AC8,
##    TR-time-tick-system-030). The "no API invoked" half is proven
##    STRUCTURALLY, not just behaviourally: `game_world.gd` (and the rest of
##    `scene_world_management`'s own source) never references the
##    `TimeTickSystem` symbol at all — mirroring
##    [WorldRootValleyAttachTest]'s `_read_all_gd_source` + banned-substring
##    technique (that file greps for banned scene-transition APIs the same
##    way this one greps for a banned CROSS-SYSTEM CALL SITE) — so there is
##    no call path that could touch this system's state, not merely one that
##    happens not to fire in today's synthetic driver. The retired
##    time-warp-reset function's continued absence from this system's own
##    public method surface is checked directly as a companion guard.
##
## [GameWorld]'s `begin_transition()`/`end_transition()` (Scene/World
## Management Story 003, ADR-0013) is the synthetic MVP transition driver
## this story's Implementation Notes call for — no real dungeon transition
## exists yet (VS-tier). `TimeTickSystem`'s own script deliberately carries
## no `class_name` (would hide the "TimeTickSystem" Autoload singleton, a
## Godot 4.7 parse error — see that script's own doc comment), so isolated
## instances are constructed via a preloaded [GDScript] and duck-typed at
## each access site, mirroring every prior time_tick_system test in this
## directory (`tick_accumulator_test.gd`, `autoload_config_boot_test.gd`).
## Every instance here is a freshly-constructed, never-autoloaded double —
## the real registered `TimeTickSystem` Autoload singleton is never touched,
## so this suite cannot leak state into any other suite in the same run.
class_name TransitionPersistenceTest
extends GdUnitTestSuite

const TimeTickSystemScript: GDScript = preload("res://src/time_tick_system/time_tick_system.gd")

## Floating-point tolerance shared by the approx assertions below (matching
## the sibling suites' convention).
const TOLERANCE: float = 0.000001


## Returns a fresh, never-autoloaded TimeTickSystem-script instance, wired
## with a GDD-default [TimeTickConfig] and already through `setup()` —
## isolated from the registered Autoload and the scene tree entirely. See the
## class doc comment for why this duck-typed construction is necessary.
## Untyped return.
func _new_system() -> Object:
	var system: Object = TimeTickSystemScript.new()
	@warning_ignore("unsafe_property_access")
	system.config = TimeTickConfig.new()
	@warning_ignore("unsafe_method_access")
	system.setup()
	return system


## Returns a [GameWorld] already booted to [constant GameWorld.BootState.ACTIVE]
## via an immediately-ready [MockResourceItemDatabase] double — the same
## boot-gate pattern every `scene_world_management` transition-surface test in
## this codebase already uses. `valley_scene` is deliberately left null (the
## existing "no Valley wired" precedent, `WorldRootValleyAttachTest`
## /`TransitionContractSurfaceTest`) — this story's transition-signal contract
## surface does not require a real Valley, and this suite is not verifying
## scene-world-management's own topology.
func _new_booted_world() -> GameWorld:
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	return world


# ---------------------------------------------------------------------------
# AC-1 — Engine.time_scale stays at its default 1.0 regardless of pause/warp
# (GDD AC6, TR-time-tick-system-025)
# ---------------------------------------------------------------------------

func test_engine_time_scale_stays_default_across_pause_and_warp_changes() -> void:
	# Arrange — the project-wide baseline this story regression-guards.
	assert_float(Engine.time_scale).is_equal_approx(1.0, TOLERANCE)
	var system: Object = auto_free(_new_system())

	# Act — the QA plan's edge case: warp 3x AND paused simultaneously, driven
	# across several physics frames, is the combination most likely to tempt
	# an implementation into reaching for the engine-global instead of this
	# system's own multiplier.
	@warning_ignore("unsafe_method_access")
	system.set_warp(3)
	@warning_ignore("unsafe_method_access")
	system.pause()
	for i: int in range(5):
		@warning_ignore("unsafe_method_access")
		system._physics_process(1.0 / 60.0)
	@warning_ignore("unsafe_method_access")
	system.resume()
	for i: int in range(5):
		@warning_ignore("unsafe_method_access")
		system._physics_process(1.0 / 60.0)

	# Assert — untouched throughout; this system maintains its own multiplier
	# instead (GDD Core Rule 4).
	assert_float(Engine.time_scale).is_equal_approx(1.0, TOLERANCE)


func test_engine_time_scale_and_scene_tree_paused_absent_as_code_from_this_systems_source() -> void:
	# Arrange — grep-verifiable regression guard (story Test Evidence): scan
	# every `.gd` file directly under this system's own source directory,
	# stripping full-line `#`/`##` doc-comment lines first (this system's own
	# doc comments legitimately NAME the banned APIs to document that they are
	# forbidden — see `time_tick_system.gd`'s own class doc comment — a naive
	# raw-text scan would flag that compliance documentation as a violation).
	var source: String = _read_all_gd_source("res://src/time_tick_system")

	# Assert — zero CODE usage of either banned API.
	assert_bool(source.contains("Engine.time_scale")).is_false()
	assert_bool(source.contains("SceneTree.paused")).is_false()


# ---------------------------------------------------------------------------
# AC-2 — game_delta keeps computing normally through a transition, never
# suspended (GDD AC7, TR-time-tick-system-027)
# ---------------------------------------------------------------------------

func test_game_delta_keeps_computing_before_during_and_after_a_transition() -> void:
	# Arrange — an unpaused, warp=1 system (so every frame's game_delta is
	# simply the clamped raw_delta — easy to assert exactly) and a booted
	# GameWorld to drive the transition signal contract surface.
	var system: Object = auto_free(_new_system())
	var world: GameWorld = _new_booted_world()
	const RAW_DELTA: float = 0.05

	# Act / Assert — BEFORE any transition: normal computation.
	@warning_ignore("unsafe_method_access")
	system._physics_process(RAW_DELTA)
	@warning_ignore("unsafe_method_access")
	assert_float(system.get_game_delta()).is_equal_approx(RAW_DELTA, TOLERANCE)

	# Act / Assert — DURING a transition (Transitioning state): this is the
	# exact window GDD AC7 requires stays unaffected.
	world.begin_transition()
	assert_int(world.get_transition_state()).is_equal(GameWorld.TransitionState.Transitioning)
	for i: int in range(3):
		@warning_ignore("unsafe_method_access")
		system._physics_process(RAW_DELTA)
		@warning_ignore("unsafe_method_access")
		assert_float(system.get_game_delta()).is_equal_approx(RAW_DELTA, TOLERANCE)

	# Act / Assert — AFTER the transition completes: still unaffected by
	# having just been through Transitioning.
	world.end_transition(true)
	assert_int(world.get_transition_state()).is_equal(GameWorld.TransitionState.Active)
	@warning_ignore("unsafe_method_access")
	system._physics_process(RAW_DELTA)
	@warning_ignore("unsafe_method_access")
	assert_float(system.get_game_delta()).is_equal_approx(RAW_DELTA, TOLERANCE)


# ---------------------------------------------------------------------------
# AC-3 — time_warp/paused/accumulator untouched across a full transition, and
# no API of this system is invoked by transition events (GDD AC8,
# TR-time-tick-system-030)
# ---------------------------------------------------------------------------

func test_transition_begin_and_success_complete_leaves_state_fully_unchanged() -> void:
	# Arrange — GDD AC8's literal setup: time_warp=3, paused=true, plus a
	# nonzero banked accumulator (X), all established BEFORE any transition.
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_method_access")
	system._physics_process(0.05)
	@warning_ignore("unsafe_method_access")
	system._physics_process(0.05)
	@warning_ignore("unsafe_method_access")
	var accumulator_before: float = system.get_tick_accumulator()
	assert_float(accumulator_before).is_equal_approx(0.1, TOLERANCE)
	@warning_ignore("unsafe_method_access")
	system.pause()
	@warning_ignore("unsafe_method_access")
	system.set_warp(3)
	@warning_ignore("unsafe_property_access")
	var paused_before: bool = system.paused
	@warning_ignore("unsafe_property_access")
	var warp_before: int = system.time_warp
	assert_bool(paused_before).is_true()
	assert_int(warp_before).is_equal(3)

	var world: GameWorld = _new_booted_world()

	# Act — a full transition cycle: begin -> complete (success).
	world.begin_transition()
	world.end_transition(true)

	# Assert — every field this AC names is byte-for-byte unchanged.
	@warning_ignore("unsafe_property_access")
	assert_bool(system.paused).is_equal(paused_before)
	@warning_ignore("unsafe_property_access")
	assert_int(system.time_warp).is_equal(warp_before)
	@warning_ignore("unsafe_method_access")
	assert_float(system.get_tick_accumulator()).is_equal_approx(accumulator_before, TOLERANCE)


func test_transition_begin_and_abort_complete_also_leaves_state_fully_unchanged() -> void:
	# Arrange — same as above, but the transition resolves as an ABORT
	# (success=false). GDD AC8 does not carve out an exception for the abort
	# outcome — persistence must hold for either resolution.
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_method_access")
	system._physics_process(0.05)
	@warning_ignore("unsafe_method_access")
	var accumulator_before: float = system.get_tick_accumulator()
	@warning_ignore("unsafe_method_access")
	system.pause()
	@warning_ignore("unsafe_method_access")
	system.set_warp(2)
	@warning_ignore("unsafe_property_access")
	var paused_before: bool = system.paused
	@warning_ignore("unsafe_property_access")
	var warp_before: int = system.time_warp

	var world: GameWorld = _new_booted_world()

	# Act
	world.begin_transition()
	world.end_transition(false)

	# Assert
	@warning_ignore("unsafe_property_access")
	assert_bool(system.paused).is_equal(paused_before)
	@warning_ignore("unsafe_property_access")
	assert_int(system.time_warp).is_equal(warp_before)
	@warning_ignore("unsafe_method_access")
	assert_float(system.get_tick_accumulator()).is_equal_approx(accumulator_before, TOLERANCE)


func test_scene_world_management_source_never_references_time_tick_system() -> void:
	# Arrange — structural proof that no system calls into Time & Tick on
	# transition events (TR-time-tick-system-030): the retired
	# time-warp-reset call site is not merely unused today, it CANNOT exist,
	# because scene_world_management's own source never names the
	# `TimeTickSystem` Autoload symbol at all. Same technique as
	# `WorldRootValleyAttachTest`'s banned-scene-API grep, aimed at a
	# cross-system call site instead of an engine API.
	var source: String = _read_all_gd_source("res://src/scene_world_management")

	# Assert
	assert_bool(source.contains("TimeTickSystem")).is_false()


func test_time_tick_system_exposes_no_transition_reset_entry_point() -> void:
	# Arrange — GDD Interactions with Other Systems / this story's
	# Implementation Notes: "the former time-warp-reset call ... was
	# REMOVED ... retired from the contract." Confirmed directly against the
	# live method surface rather than only by absence of a caller, so a
	# reintroduced reset method would fail this test even before anything
	# called it.
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_method_access")
	var methods: Array = system.get_method_list()

	# Act / Assert — no method name anywhere on this instance references
	# "transition" (case-insensitive) -- this system exposes no transition
	# API surface at all (this story's Control Manifest Rules).
	for method: Dictionary in methods:
		var method_name: String = String(method["name"])
		assert_bool(method_name.to_lower().contains("transition")).is_false()


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Reads and concatenates every `.gd` source file directly under
## [param dir_path] (non-recursive -- both directories this suite scans are
## flat), STRIPPING full-line `#`/`##` doc-comment lines first. Mirrors
## `WorldRootValleyAttachTest._read_all_gd_source` exactly (duplicated here
## rather than shared, since GdUnit4 suites in this codebase do not share
## helper code across files).
func _read_all_gd_source(dir_path: String) -> String:
	var combined: String = ""
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Could not open directory: %s" % dir_path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gd"):
			var text: String = FileAccess.get_file_as_string(dir_path.path_join(file_name))
			for line: String in text.split("\n"):
				if not line.strip_edges().begins_with("#"):
					combined += line
					combined += "\n"
		file_name = dir.get_next()
	dir.list_dir_end()
	return combined
