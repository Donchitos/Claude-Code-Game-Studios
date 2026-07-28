## Integration test — Scene/World Management Story 002 (ADR-0005 host
## relationship, AC17a/AC17b: boot-gate integration).
##
## Proves the scene-topology REACTION to the Foundation Spine's boot gate
## that [GameWorld] itself now implements: the Valley attach ([Valley]
## instance, story 001) fires ONLY on the gate's success path -- after the
## Resource & Item Database dependency reaches Ready, and strictly BEFORE the
## injected-tier `setup()` sweep, so Building System / Villager AI stand-ins
## observe the Valley already attached (AC17a, both the synchronous and the
## deferred-signal Ready path) -- and on a `Failed` outcome the Valley is
## NEVER attached (AC17b, no empty-palette Valley), no injected-tier
## `setup()` is ever called, and the terminal HALT is state-machine
## non-progression, never `SceneTree.paused`.
##
## The bare gate mechanism (BootState transitions, check-then-connect,
## CONNECT_ONE_SHOT, the unified "no module skipped" guarantee) is already
## proven in [BootSequencingGateTest] against a mock RID double with no
## Valley involved at all; this suite exists specifically for the
## Valley-attach × gate INTERACTION story 002 adds, using generic
## injected-tier stand-ins (this codebase has no landed Building System /
## Villager AI code yet) exactly as the existing spine suites already do.
class_name BootGateIntegrationTest
extends GdUnitTestSuite

const ValleyScene: PackedScene = preload("res://src/scene_world_management/Valley.tscn")


## Test-local injected-tier module (not a production class): stands in for
## "Building System" / "Villager AI" (AC17a's named consumers) generically,
## exactly as [ReferenceInjectedModule]/[CountingModule]/[OrderTrackingModule]
## already do in the sibling spine suites. Records, at the moment its OWN
## [method setup] runs, whether the World Root's Valley already existed --
## the direct observable proof that the attach happens strictly before the
## injected-tier sweep, not merely an inference from reading the source.
class ValleyPresenceRecordingModule:
	extends Node

	var _world: GameWorld
	var setup_call_count: int = 0
	var valley_was_present_at_setup: bool = false

	func _init(world: GameWorld) -> void:
		_world = world

	func setup() -> void:
		setup_call_count += 1
		valley_was_present_at_setup = _world.get_valley() != null


# ---------------------------------------------------------------------------
# AC17a — Ready → Valley attaches, THEN injected-tier setup() sweeps
# ---------------------------------------------------------------------------

func test_ready_synchronously_attaches_valley_before_injected_tier_setup() -> void:
	# Arrange
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	world.valley_scene = ValleyScene
	var module: ValleyPresenceRecordingModule = auto_free(ValleyPresenceRecordingModule.new(world))
	world.add_child(module)
	world.injected_tier_modules = [module]

	# Act — entering the live tree fires GameWorld._ready(); the mock already
	# reports is_ready() == true, so the gate settles synchronously, same frame.
	add_child(world)

	# Assert
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	assert_object(world.get_valley()).is_not_null()
	assert_int(module.setup_call_count).is_equal(1)
	assert_bool(module.valley_was_present_at_setup).is_true()


func test_ready_via_signal_attaches_valley_before_injected_tier_setup() -> void:
	# Arrange — edge case (QA plan): Ready observed via the deferred
	# validation_complete signal must produce the SAME attach-before-setup
	# ordering as the synchronous branch above.
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	world.resource_item_database = database
	world.valley_scene = ValleyScene
	var module: ValleyPresenceRecordingModule = auto_free(ValleyPresenceRecordingModule.new(world))
	world.add_child(module)
	world.injected_tier_modules = [module]

	# Act — enter the tree; the gate stays WAITING_FOR_DATABASE (Valley not
	# yet attached, setup() not yet called — the "not before" half of AC17a)
	# until the signal fires.
	add_child(world)
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.WAITING_FOR_DATABASE)
	assert_object(world.get_valley()).is_null()
	assert_int(module.setup_call_count).is_equal(0)

	database.settle(true, [])

	# Assert
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	assert_object(world.get_valley()).is_not_null()
	assert_int(module.setup_call_count).is_equal(1)
	assert_bool(module.valley_was_present_at_setup).is_true()


# ---------------------------------------------------------------------------
# AC17b — Failed → HALT, Valley never attached, no setup() ever called
# ---------------------------------------------------------------------------

func test_failed_halts_and_valley_is_never_attached() -> void:
	# Arrange
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	world.resource_item_database = database
	world.valley_scene = ValleyScene
	var module: ValleyPresenceRecordingModule = auto_free(ValleyPresenceRecordingModule.new(world))
	world.add_child(module)
	world.injected_tier_modules = [module]
	add_child(world)

	# Act
	database.settle(false, ["boot gate integration test — forced Failed"])

	# Assert — AC17b: HALTED, no empty-palette Valley, no setup() call.
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.HALTED)
	assert_object(world.get_valley()).is_null()
	assert_int(module.setup_call_count).is_equal(0)


func test_failed_with_multiple_modules_none_are_ever_set_up_and_valley_absent() -> void:
	# Arrange — edge case (QA plan AC17b): "assert Building/Villager AI
	# setup() was never called," scoped to this story's Valley-attach
	# interaction (the generic "none of N modules ever run" proof already
	# exists in boot_sequencing_gate_test.gd for the bare gate).
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	world.resource_item_database = database
	world.valley_scene = ValleyScene
	var module_a: ValleyPresenceRecordingModule = auto_free(ValleyPresenceRecordingModule.new(world))
	var module_b: ValleyPresenceRecordingModule = auto_free(ValleyPresenceRecordingModule.new(world))
	world.add_child(module_a)
	world.add_child(module_b)
	world.injected_tier_modules = [module_a, module_b]
	add_child(world)

	# Act
	database.settle(false, [])

	# Assert
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.HALTED)
	assert_object(world.get_valley()).is_null()
	assert_int(module_a.setup_call_count).is_equal(0)
	assert_int(module_b.setup_call_count).is_equal(0)


func test_failed_does_not_use_scene_tree_paused() -> void:
	# Arrange — edge case (QA plan AC17b): the HALT is state-machine
	# non-progression, never SceneTree.paused (forbidden project-wide,
	# technical-preferences.md; GDD Engine Notes). If the halt path ever
	# regressed to setting it, get_tree().paused would flip true here.
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	world.resource_item_database = database
	world.valley_scene = ValleyScene
	add_child(world)

	# Act
	database.settle(false, ["forced Failed"])

	# Assert
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.HALTED)
	assert_bool(get_tree().paused).is_false()
