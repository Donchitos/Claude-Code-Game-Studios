extends SceneTree
## Unit tests for LootCrate: access adapters, single-reward guarantee, and trap triggers.

const LootCrateScript = preload("res://src/loot/loot_crate.gd")
const ItemDataScript = preload("res://src/inventory/item_data.gd")

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
	var crate: StaticBody3D = LootCrateScript.new()
	var medkit: Resource = load("res://assets/data/items/medkit.tres")
	crate.stored_item = medkit
	crate.stored_count = 2
	crate.crate_type = LootCrateScript.CrateType.SMALL
	root.add_child(crate)
	await process_frame

	# 1. Starts closed
	_check(not crate.is_opened, "Crate starts closed")

	# 2. Small crate direct open
	var reward_observed := [null, 0]
	crate.opened.connect(func(item, count):
		reward_observed[0] = item
		reward_observed[1] = count
	)
	var opened: bool = crate.try_open()
	_check(opened and crate.is_opened, "Small crate opens successfully")
	_check(reward_observed[0] == medkit and reward_observed[1] == 2, "Payout delivers stored item and count")

	# 3. Single-reward guarantee: second attempt is rejected
	reward_observed = [null, 0]
	var second_open: bool = crate.try_open()
	_check(not second_open, "Second open attempt on already opened crate is rejected")
	_check(reward_observed[0] == null, "No duplicate reward emitted")

	# 4. Locked crate requires key
	crate.reset_crate()
	crate.crate_type = LootCrateScript.CrateType.LOCKED
	var locked_no_key: bool = crate.try_open(false)
	_check(not locked_no_key and not crate.is_opened, "Locked crate without key is rejected")
	var locked_with_key: bool = crate.try_open(true)
	_check(locked_with_key and crate.is_opened, "Locked crate opens with key")

	# 5. Heavy crate requires bash
	crate.reset_crate()
	crate.crate_type = LootCrateScript.CrateType.HEAVY
	var heavy_no_bash: bool = crate.try_open(false, false)
	_check(not heavy_no_bash and not crate.is_opened, "Heavy crate without bash is rejected")
	var heavy_with_bash: bool = crate.try_open(false, true)
	_check(heavy_with_bash and crate.is_opened, "Heavy crate opens with Breaker bash")

	# 6. Trapped crate triggers damage
	crate.reset_crate()
	crate.crate_type = LootCrateScript.CrateType.TRAPPED
	var trap_dmg := [0.0]
	crate.trap_triggered.connect(func(dmg): trap_dmg[0] = dmg)
	crate.try_open()
	_check(trap_dmg[0] > 0.0, "Opening trapped crate emits trap_triggered signal")

	# 7. Reset
	crate.reset_crate()
	_check(not crate.is_opened, "Reset restores crate to closed state")

	crate.queue_free()
	await process_frame

	print("LootCrate tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
