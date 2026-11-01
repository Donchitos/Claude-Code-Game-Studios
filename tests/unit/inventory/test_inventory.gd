extends SceneTree
## Unit tests for InventoryModel: stack limits, slot transfer, categories and capacity rejection.

const InventoryModelScript = preload("res://src/inventory/inventory_model.gd")
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
	var inv: RefCounted = InventoryModelScript.new(4) # 4 slots capacity

	# 1. Load 5 item categories
	var medkit: Resource = load("res://assets/data/items/medkit.tres")
	var grenade: Resource = load("res://assets/data/items/grenade.tres")
	var battery: Resource = load("res://assets/data/items/shield_battery.tres")
	var module: Resource = load("res://assets/data/items/recoil_dampener.tres")
	var cube: Resource = load("res://assets/data/items/glitch_cube.tres")

	_check(medkit != null and medkit.category == ItemDataScript.Category.CONSUMPTION, "Category 0: Consumption loaded")
	_check(grenade != null and grenade.category == ItemDataScript.Category.ATTACK, "Category 1: Attack loaded")
	_check(battery != null and battery.category == ItemDataScript.Category.UTILITY, "Category 2: Utility loaded")
	_check(module != null and module.category == ItemDataScript.Category.MODULE, "Category 3: Module loaded")
	_check(cube != null and cube.category == ItemDataScript.Category.STRANGE, "Category 4: Strange loaded")

	# 2. Add and Stack items
	var add1: bool = inv.add_item(medkit, 2)
	_check(add1 and inv.slots[0].count == 2, "Added 2 medkits into slot 0")

	# Stacking into same slot
	var add2: bool = inv.add_item(medkit, 1) # max_stack is 3
	_check(add2 and inv.slots[0].count == 3, "Stacked 3rd medkit into slot 0 (at max stack)")

	# Overflow to next slot
	var add3: bool = inv.add_item(medkit, 1)
	_check(add3 and inv.slots[1].item.id == "medkit" and inv.slots[1].count == 1, "Overflow medkit placed in slot 1")

	# Fill remaining slots
	inv.add_item(grenade, 2) # slot 2
	inv.add_item(battery, 1) # slot 3 (bag is now full: 4/4 slots occupied)

	# 3. Capacity rejection: Bag full rejects new item without corruption
	var add_full: bool = inv.add_item(cube, 1)
	_check(not add_full, "Adding new item type to full bag is safely rejected")
	_check(inv.slots.size() == 4, "Slot count stays exactly at capacity")

	# 4. Slot transfer and swapping
	var swapped: bool = inv.transfer(2, 3) # Swap grenade and battery
	_check(swapped and inv.slots[2].item.id == "shield_battery" and inv.slots[3].item.id == "grenade", "Transferred / swapped slots without item duplication")

	# 5. Slot selection and item consumption
	inv.select_slot(0) # slot 0 has 3 medkits
	_check(inv.get_selected_item().id == "medkit", "Selected slot 0 contains medkit")
	_check(inv.get_selected_count() == 3, "Selected slot 0 count is 3")

	var consumed_observed := [false, 0.0]
	inv.item_consumed.connect(func(item, val):
		consumed_observed[0] = (item.id == "medkit")
		consumed_observed[1] = val
	)
	var used: bool = inv.use_selected_item()
	_check(used and consumed_observed[0] and consumed_observed[1] == 40.0, "Used selected medkit emits consumed with 40.0 effect")
	_check(inv.get_selected_count() == 2, "Consuming reduces item count to 2")

	# 6. Removing items
	inv.remove_item(0, 2)
	_check(inv.slots[0].item == null and inv.slots[0].count == 0, "Removing all items clears slot to null")

	print("Inventory tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
