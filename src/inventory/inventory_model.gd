class_name InventoryModel
extends RefCounted
## Slot-based deterministic inventory model with quick-slot selection and stack management.

const ItemDataScript = preload("res://src/inventory/item_data.gd")

signal inventory_changed()
signal slot_selected(slot_index: int)
signal item_consumed(item: Resource, effect_value: float)

var slot_count: int = 6
var slots: Array[Dictionary] = [] # [{ "item": ItemData, "count": int }]
var selected_slot: int = 0


func _init(capacity: int = 6) -> void:
	slot_count = capacity
	clear_inventory()


func clear_inventory() -> void:
	slots.clear()
	for i in range(slot_count):
		slots.append({"item": null, "count": 0})
	selected_slot = 0
	inventory_changed.emit()


## Add item to inventory; stacks where possible, then fills first empty slot.
## Returns true if all items were added, false if bag is full / partially rejected.
func add_item(item: Resource, count: int = 1) -> bool:
	if item == null or count <= 0:
		return false

	var remaining := count

	# Pass 1: Try stacking into existing slots of same item
	for i in range(slot_count):
		var slot: Dictionary = slots[i]
		if slot.item != null and slot.item.id == item.id:
			var space: int = slot.item.max_stack - slot.count
			if space > 0:
				var to_add := mini(space, remaining)
				slot.count += to_add
				remaining -= to_add
				if remaining <= 0:
					inventory_changed.emit()
					return true

	# Pass 2: Place in first empty slot
	for i in range(slot_count):
		var slot: Dictionary = slots[i]
		if slot.item == null:
			var to_add := mini(item.max_stack, remaining)
			slot.item = item
			slot.count = to_add
			remaining -= to_add
			if remaining <= 0:
				inventory_changed.emit()
				return true

	inventory_changed.emit()
	return remaining == 0


## Remove count items from a specific slot.
func remove_item(slot_index: int, count: int = 1) -> bool:
	if slot_index < 0 or slot_index >= slot_count:
		return false
	var slot: Dictionary = slots[slot_index]
	if slot.item == null or slot.count < count or count <= 0:
		return false

	slot.count -= count
	if slot.count <= 0:
		slot.item = null
		slot.count = 0
	inventory_changed.emit()
	return true


## Transfer items between two slots without duplication.
func transfer(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= slot_count or to_index < 0 or to_index >= slot_count:
		return false
	if from_index == to_index:
		return false

	var source: Dictionary = slots[from_index]
	var dest: Dictionary = slots[to_index]

	if source.item == null:
		return false

	# Same item: stack
	if dest.item != null and dest.item.id == source.item.id:
		var space: int = dest.item.max_stack - dest.count
		var to_move := mini(space, source.count)
		dest.count += to_move
		source.count -= to_move
		if source.count <= 0:
			source.item = null
			source.count = 0
		inventory_changed.emit()
		return true

	# Empty or swap
	var temp_item: Resource = dest.item
	var temp_count: int = dest.count
	dest.item = source.item
	dest.count = source.count
	source.item = temp_item
	source.count = temp_count

	inventory_changed.emit()
	return true


func select_slot(index: int) -> void:
	if index >= 0 and index < slot_count:
		selected_slot = index
		slot_selected.emit(selected_slot)


func get_selected_item() -> Resource:
	if selected_slot >= 0 and selected_slot < slot_count:
		return slots[selected_slot].item
	return null


func get_selected_count() -> int:
	if selected_slot >= 0 and selected_slot < slot_count:
		return slots[selected_slot].count
	return 0


## Consume one active item from selected slot.
func use_selected_item() -> bool:
	var item: Resource = get_selected_item()
	if item == null:
		return false

	item_consumed.emit(item, item.effect_value)
	remove_item(selected_slot, 1)
	return true
