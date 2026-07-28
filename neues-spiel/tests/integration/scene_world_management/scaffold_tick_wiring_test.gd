## Both scaffold coordinators are actually TICKING in the shipped game.
##
## This exists because a constructor-time clock connection silently did
## nothing. Valley builds both coordinators during
## `_wire_build_project_lifecycle`, and at that moment `ConstructionTickLoop`
## has not run its own `setup()` yet — so its `time_tick_system` is still null,
## the `is_connected`/`connect` pair was skipped, and neither coordinator ever
## received a tick in production.
##
## Nothing caught it. `scaffold_dismantle_live_test.gd` asserts the DEFERRAL
## DECISION and the two construction/cancel signals; the tick that RETRIES a
## deferred owner was never covered. The consequence was precise and invisible:
## a dismantle deferred because a builder was still standing on the structure
## (SC-INV-2) would never have been retried at all — the structure would simply
## stand there forever.
##
## It surfaced only from a diagnostic print on a real boot reading
## `dismantle_connected=false`. This test is that print, made permanent.
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")


func _boot_valley() -> Valley:
	var world: Node = auto_free(GameWorldScene.instantiate())
	add_child(world)
	return world.get_valley() as Valley


func test_both_scaffold_coordinators_receive_the_real_tick() -> void:
	var valley: Valley = _boot_valley()
	var clock: Object = valley.get_construction_tick_loop().time_tick_system
	assert_object(clock).override_failure_message(
		"the hosted ConstructionTickLoop must have resolved a real clock by the time boot completes"
	).is_not_null()

	# Identity of the connection, not mere existence of the object — hosted
	# versus actually wired is this project's most repeated defect.
	@warning_ignore("unsafe_property_access")
	assert_bool(
		clock.tick.is_connected(valley.get_scaffold_dismantle_coordinator()._on_tick)
	).override_failure_message(
		"ScaffoldDismantleCoordinator is not receiving ticks — SC-INV-2's deferred retry can never fire"
	).is_true()
	@warning_ignore("unsafe_property_access")
	assert_bool(
		clock.tick.is_connected(valley.get_scaffold_erection_coordinator()._on_tick)
	).override_failure_message(
		"ScaffoldErectionCoordinator is not receiving ticks — the villager-descent trigger can never fire"
	).is_true()
