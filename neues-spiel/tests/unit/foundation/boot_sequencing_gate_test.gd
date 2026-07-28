## Unit test — Foundation Spine Story 002 (ADR-0005 BootState machine + RID
## Ready/Failed gate).
##
## Proves GameWorld's boot gate settles correctly against a mock RID-shaped
## double ([MockResourceItemDatabase]) for all three ADR-0005 branches:
## Ready-via-synchronous-check, Ready-via-signal, and Failed (terminal halt,
## no setup() ever called) — the QA plan's AC-1 through AC-4, tested with
## zero scene tree beyond GameWorld itself and zero Autoload registration.
class_name BootSequencingGateTest
extends GdUnitTestSuite


## Test-local order-tracking injected-tier module (not a production class):
## records its label into a shared call_log on setup(), letting tests
## assert GameWorld invokes setup() in [member GameWorld.injected_tier_modules]
## array order, exactly once per module.
class OrderTrackingModule:
	extends Node

	var _label: String
	var _call_log: Array[String]

	func _init(label: String, call_log: Array[String]) -> void:
		_label = label
		_call_log = call_log

	func setup() -> void:
		_call_log.append(_label)


func test_boot_gate_database_ready_synchronously_activates_and_calls_setup() -> void:
	# Arrange
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	var module: ReferenceInjectedModule = auto_free(ReferenceInjectedModule.new())
	module.dependency_one = auto_free(Node.new())
	module.dependency_two = auto_free(Node.new())
	world.add_child(module)
	world.injected_tier_modules = [module]

	# Act — entering the live tree fires GameWorld._ready(); the mock
	# already reports is_ready() == true, so the synchronous
	# check-then-connect branch settles immediately, same frame.
	add_child(world)

	# Assert
	assert_bool(module.is_set_up()).is_true()
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)


func test_boot_gate_two_modules_ready_synchronously_each_setup_called_once_in_order() -> void:
	# Arrange
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	var call_log: Array[String] = []
	var module_a: OrderTrackingModule = auto_free(OrderTrackingModule.new("a", call_log))
	var module_b: OrderTrackingModule = auto_free(OrderTrackingModule.new("b", call_log))
	world.add_child(module_a)
	world.add_child(module_b)
	world.injected_tier_modules = [module_a, module_b]

	# Act
	add_child(world)

	# Assert — each called exactly once, in injected_tier_modules array
	# order (not scene-tree child order, which callers do not control here).
	assert_array(call_log).is_equal(["a", "b"])


func test_boot_gate_database_ready_via_signal_activates_and_calls_setup() -> void:
	# Arrange — the mock is NOT ready at GameWorld._ready() time, so the
	# check-then-connect fallback branch connects to validation_complete.
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	world.resource_item_database = database
	var module: ReferenceInjectedModule = auto_free(ReferenceInjectedModule.new())
	module.dependency_one = auto_free(Node.new())
	module.dependency_two = auto_free(Node.new())
	world.add_child(module)
	world.injected_tier_modules = [module]

	# Act — enter the tree; the gate stays WAITING_FOR_DATABASE until the
	# signal fires (no polling — see also the grep-verified single choke
	# point check in the story report).
	add_child(world)
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.WAITING_FOR_DATABASE)
	assert_bool(module.is_set_up()).is_false()

	database.settle(true, [])

	# Assert
	assert_bool(module.is_set_up()).is_true()
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)


func test_boot_gate_ready_signal_second_emission_does_not_rerun_setup() -> void:
	# Arrange — CONNECT_ONE_SHOT must make a second validation_complete
	# emission a no-op.
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	world.resource_item_database = database
	var call_log: Array[String] = []
	var module: OrderTrackingModule = auto_free(OrderTrackingModule.new("only", call_log))
	world.add_child(module)
	world.injected_tier_modules = [module]
	add_child(world)

	# Act
	database.settle(true, [])
	database.settle(true, [])

	# Assert
	assert_array(call_log).is_equal(["only"])


func test_boot_gate_database_failed_via_signal_halts_and_never_calls_setup() -> void:
	# Arrange — Failed is always observed via the signal-connect branch
	# (never via a synchronous is_ready()==true meaning Failed — the
	# story's QA plan specifies this exact shape). boot_halted is asserted
	# via a direct listener rather than GdUnitSignalAssert.is_emitted():
	# that helper's variadic-args unwrapping collides with a signal whose
	# sole parameter is itself an Array (see boot_halted's declaration).
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	world.resource_item_database = database
	var module: ReferenceInjectedModule = auto_free(ReferenceInjectedModule.new())
	module.dependency_one = auto_free(Node.new())
	module.dependency_two = auto_free(Node.new())
	world.add_child(module)
	world.injected_tier_modules = [module]
	# A plain Array (not a bool) is used as the capture target: GDScript
	# lambda captures of a reassigned local scalar (e.g. `halt_fired = true`)
	# do not write back to the outer scope, but mutating (append) a
	# captured Array's contents does, since the capture holds the same
	# underlying Array reference either way.
	var received_calls: Array = []
	world.boot_halted.connect(func(issues: Array) -> void:
		received_calls.append(issues))
	add_child(world)

	# Act
	database.settle(false, ["missing item definition"])

	# Assert
	assert_bool(module.is_set_up()).is_false()
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.HALTED)
	assert_int(received_calls.size()).is_equal(1)
	assert_array(received_calls[0]).is_equal(["missing item definition"])


func test_boot_gate_database_failed_with_multiple_modules_none_are_ever_set_up() -> void:
	# Arrange — the unified gate withholds ALL injected-tier setup() calls,
	# not just some, on Failed (ADR-0005 Decision §1, unified gate).
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	world.resource_item_database = database
	var module_a: ReferenceInjectedModule = auto_free(ReferenceInjectedModule.new())
	module_a.dependency_one = auto_free(Node.new())
	module_a.dependency_two = auto_free(Node.new())
	var module_b: ReferenceInjectedModule = auto_free(ReferenceInjectedModule.new())
	module_b.dependency_one = auto_free(Node.new())
	module_b.dependency_two = auto_free(Node.new())
	world.add_child(module_a)
	world.add_child(module_b)
	world.injected_tier_modules = [module_a, module_b]
	add_child(world)

	# Act
	database.settle(false, [])

	# Assert
	assert_bool(module_a.is_set_up()).is_false()
	assert_bool(module_b.is_set_up()).is_false()
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.HALTED)
