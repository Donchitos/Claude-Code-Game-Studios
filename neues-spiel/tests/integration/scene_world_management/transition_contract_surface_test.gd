## Integration test -- Scene/World Management Story 003 (ADR-0001 contract
## surface + ADR-0013 Key Interfaces; GDD Core Rule 7 three-outcome contract
## collapsed to two signals).
##
## Proves the transition-signal CONTRACT SURFACE [GameWorld] exposes at MVP:
## [signal GameWorld.transition_begun] / [signal GameWorld.transition_ended]
## / [method GameWorld.get_transition_state] exist with the right shape
## (public-surface AC); [method GameWorld.get_transition_state] resolves
## [constant GameWorld.TransitionState.Booting] before the boot gate
## completes and [constant GameWorld.TransitionState.Active] after, per
## story 002's already-landed boot-gate integration; a synthetic
## begin->end cycle driven via [method GameWorld.begin_transition] / [method
## GameWorld.end_transition] fires EXACTLY ONE [signal
## GameWorld.transition_ended] per begin, for both outcomes, and a second
## resolve attempt on the same begin does not fire a second signal
## (one-begin -> exactly-one-end invariant); and a stand-in listener
## (standing in for Camera & Input's Suspended contract) observes
## Suspended-entry on begin and Suspended-exit on end for EITHER outcome,
## wired via signal connection ONLY -- no direct method call from
## [GameWorld] into the listener.
##
## No real dungeon transition exists at MVP (VS-tier, ADR-0013) -- every
## begin/end cycle below is the synthetic contract-surface driver this story
## builds, exactly as the story's Implementation Notes describe.
##
## The banned scene-transition APIs
## (change_scene_to_file/change_scene_to_packed/reload_current_scene/a direct
## current_scene assignment) are already grep-verified absent from this
## system's entire source directory -- including this story's new code -- by
## [WorldRootValleyAttachTest]'s
## [code]test_banned_scene_transition_apis_absent_from_system_source[/code]
## (story 001); not duplicated here (QA plan sprint-3 smoke item 6 reuses
## that existing directory-wide grep rather than re-implementing it).
class_name TransitionContractSurfaceTest
extends GdUnitTestSuite


## Test-local stand-in for Camera & Input's Suspended contract (QA Test Case:
## "a listener bound to transition_begun/transition_ended, standing in for
## Camera & Input"). Reacts ONLY via signal connection -- [GameWorld] never
## calls this class directly, which is what proves
## [TR-scene-world-management-049]'s "signals only, no direct-call coupling"
## claim structurally rather than by inference.
class SuspendedStandInListener:
	extends RefCounted

	var suspended: bool = false
	var enter_count: int = 0
	var exit_count: int = 0
	var last_exit_success: bool = false

	func _on_transition_begun() -> void:
		suspended = true
		enter_count += 1

	func _on_transition_ended(success: bool) -> void:
		suspended = false
		exit_count += 1
		last_exit_success = success


# ---------------------------------------------------------------------------
# Public surface exists (AC1) + Booting -> Active boot observability (AC3)
# ---------------------------------------------------------------------------

func test_public_surface_members_exist_with_expected_shape() -> void:
	# Arrange
	var world: GameWorld = auto_free(GameWorld.new())

	# Assert -- signals present with the documented argument shape.
	assert_bool(world.has_signal(&"transition_begun")).is_true()
	assert_bool(world.has_signal(&"transition_ended")).is_true()
	assert_bool(world.has_method(&"get_transition_state")).is_true()

	var ended_signal: Dictionary = {}
	for sig: Dictionary in world.get_signal_list():
		if sig["name"] == "transition_ended":
			ended_signal = sig
			break
	assert_bool(ended_signal.is_empty()).is_false()
	var ended_args: Array = ended_signal["args"]
	assert_int(ended_args.size()).is_equal(1)
	assert_str(ended_args[0]["name"]).is_equal("success")

	var begun_signal: Dictionary = {}
	for sig: Dictionary in world.get_signal_list():
		if sig["name"] == "transition_begun":
			begun_signal = sig
			break
	assert_bool(begun_signal.is_empty()).is_false()
	assert_int((begun_signal["args"] as Array).size()).is_equal(0)


func test_transition_state_is_booting_before_gate_completes_and_active_after() -> void:
	# Arrange -- reuses the story 002 boot-gate integration pattern: signal
	# path (not the immediately-ready synchronous path) so the pre-boot
	# Booting observation is real, not skipped.
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	world.resource_item_database = database

	# Act / Assert -- pre-boot: Booting.
	add_child(world)
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.WAITING_FOR_DATABASE)
	assert_int(world.get_transition_state()).is_equal(GameWorld.TransitionState.Booting)

	# Act -- gate settles Ready.
	database.settle(true, [])

	# Assert -- post-boot: Active.
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	assert_int(world.get_transition_state()).is_equal(GameWorld.TransitionState.Active)


# ---------------------------------------------------------------------------
# One-begin -> exactly-one-end invariant
# ---------------------------------------------------------------------------

func test_begin_transition_emits_transition_begun_and_reports_transitioning() -> void:
	# Arrange
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	# NOTE: scalar closure-capture pitfall -- GDScript lambdas capture a
	# scalar local by VALUE, so `begun_count += 1` inside the lambda would
	# never write back to this outer `int`. An Array is captured by
	# reference, so `.append()` inside the lambda IS observable here.
	var begun_calls: Array[int] = []
	world.transition_begun.connect(func() -> void: begun_calls.append(1))

	# Act
	world.begin_transition()

	# Assert
	assert_int(begun_calls.size()).is_equal(1)
	assert_int(world.get_transition_state()).is_equal(GameWorld.TransitionState.Transitioning)


func test_end_transition_success_true_emits_transition_ended_exactly_once_with_true() -> void:
	# Arrange
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	var ended_calls: Array[bool] = []
	world.transition_ended.connect(func(success: bool) -> void: ended_calls.append(success))
	world.begin_transition()

	# Act
	world.end_transition(true)

	# Assert
	assert_int(ended_calls.size()).is_equal(1)
	assert_bool(ended_calls[0]).is_true()
	assert_int(world.get_transition_state()).is_equal(GameWorld.TransitionState.Active)


func test_end_transition_success_false_emits_transition_ended_exactly_once_with_false() -> void:
	# Arrange -- the abort outcome (GDD transition-abort, TR-scene-world-management-045).
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	var ended_calls: Array[bool] = []
	world.transition_ended.connect(func(success: bool) -> void: ended_calls.append(success))
	world.begin_transition()

	# Act
	world.end_transition(false)

	# Assert
	assert_int(ended_calls.size()).is_equal(1)
	assert_bool(ended_calls[0]).is_false()
	assert_int(world.get_transition_state()).is_equal(GameWorld.TransitionState.Active)


func test_second_end_transition_call_on_same_begin_does_not_fire_second_signal() -> void:
	# Arrange -- edge case (QA plan + AC): "a second resolve attempt on the
	# same begin does not fire a second transition_ended."
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	var ended_calls: Array[bool] = []
	world.transition_ended.connect(func(success: bool) -> void: ended_calls.append(success))
	world.begin_transition()
	world.end_transition(true)

	# Act -- a second resolve attempt on the SAME begin.
	world.end_transition(false)

	# Assert -- still exactly one call, still the FIRST resolution's value.
	assert_int(ended_calls.size()).is_equal(1)
	assert_bool(ended_calls[0]).is_true()


func test_end_transition_called_with_no_begin_in_progress_is_a_no_op() -> void:
	# Arrange -- edge case: end_transition() called with nothing in progress
	# (e.g. before any begin_transition() ever ran) must not fire either.
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	# NOTE: Array-not-scalar closure capture -- see the sibling test above.
	var ended_calls: Array[int] = []
	world.transition_ended.connect(func(_success: bool) -> void: ended_calls.append(1))

	# Act
	world.end_transition(true)

	# Assert
	assert_int(ended_calls.size()).is_equal(0)


func test_begin_transition_while_one_already_in_progress_asserts() -> void:
	# Arrange -- structural enforcement: the debounce policy (VS+) is out of
	# scope, but a second begin without an intervening end is still a
	# caller-contract violation this story asserts against rather than
	# silently corrupting the one-begin -> exactly-one-end invariant.
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	world.begin_transition()

	# Act / Assert
	await assert_error(func() -> void: world.begin_transition()).is_runtime_error(
		"Assertion failed: GameWorld.begin_transition() called while a transition is already in progress"
		+ " -- the double-trigger debounce is VS-tier scope, not built yet (story 003)"
	)


# ---------------------------------------------------------------------------
# Camera-Suspended bindable via signals only (AC + edge case: abort unwinds too)
# ---------------------------------------------------------------------------

func test_suspended_stand_in_enters_on_begin_and_exits_on_success_end() -> void:
	# Arrange
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	var listener: SuspendedStandInListener = SuspendedStandInListener.new()
	world.transition_begun.connect(listener._on_transition_begun)
	world.transition_ended.connect(listener._on_transition_ended)

	# Act -- begin.
	world.begin_transition()
	assert_bool(listener.suspended).is_true()
	assert_int(listener.enter_count).is_equal(1)

	# Act -- end (success).
	world.end_transition(true)

	# Assert -- Suspended-exit fired via the signal, not a direct call.
	assert_bool(listener.suspended).is_false()
	assert_int(listener.exit_count).is_equal(1)
	assert_bool(listener.last_exit_success).is_true()


func test_suspended_stand_in_exits_on_abort_end_never_stranding_the_consumer() -> void:
	# Arrange -- edge case (story AC + QA plan): "end with success=false still
	# fires the exit binding (abort must never strand a consumer in Suspended)."
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	var listener: SuspendedStandInListener = SuspendedStandInListener.new()
	world.transition_begun.connect(listener._on_transition_begun)
	world.transition_ended.connect(listener._on_transition_ended)
	world.begin_transition()

	# Act -- end (abort, success=false).
	world.end_transition(false)

	# Assert -- still unwinds Suspended even though the outcome is failure.
	assert_bool(listener.suspended).is_false()
	assert_int(listener.exit_count).is_equal(1)
	assert_bool(listener.last_exit_success).is_false()
