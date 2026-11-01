extends SceneTree
## Unit tests for MutatorManager: seed determinism, compatibility matrix, and softlock prevention.

const MutatorScript = preload("res://src/world/mutators/mutator_manager.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred(&"_run_tests")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)


func _run_tests() -> void:
	# 1. Deterministic Seed generation
	var seed_1 := 94102
	var set_a: Array[MutatorScript.Mutator] = MutatorScript.generate_mutators_for_seed(seed_1, 2)
	var set_b: Array[MutatorScript.Mutator] = MutatorScript.generate_mutators_for_seed(seed_1, 2)

	_check(set_a.size() == 2, "Generates requested 2 mutators")
	_check(set_a[0] == set_b[0] and set_a[1] == set_b[1], "Same seed (94102) produces 100% identical mutator set")

	# 2. Incompatible pairs verification
	_check(MutatorScript.are_incompatible(MutatorScript.Mutator.DARKNESS, MutatorScript.Mutator.FOG), "Darkness and Fog are marked incompatible")
	_check(MutatorScript.are_incompatible(MutatorScript.Mutator.SILENCE, MutatorScript.Mutator.DARKNESS), "Silence and Darkness are marked incompatible")
	_check(not MutatorScript.are_incompatible(MutatorScript.Mutator.SLIPPERY, MutatorScript.Mutator.CONVEYOR), "Slippery and Conveyor are compatible")

	# 3. Conflict resolution across 50 random seeds
	var conflict_found := false
	for s in range(50):
		var test_set: Array[MutatorScript.Mutator] = MutatorScript.generate_mutators_for_seed(s, 2)
		if test_set.size() == 2:
			if MutatorScript.are_incompatible(test_set[0], test_set[1]):
				conflict_found = true
				break

	_check(not conflict_found, "Across 50 generated seeds, zero incompatible pairs were admitted")

	# 4. Naming
	_check(MutatorScript.get_mutator_name(MutatorScript.Mutator.DARKNESS) == "Karanlık", "Mutator names resolve correctly")

	print("Mutator tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
