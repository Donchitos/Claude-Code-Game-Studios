## Holds deterministic simulation state for gameplay steps.
class_name SimulationState
extends RefCounted

## Units that have returned to waiting slots.
var waiting_slots: Array = []

## Units queued for the next simulation step.
var pending_units: Array = []

## Maximum waiting slots allowed for this level.
var max_waiting_slots: int = 0

## Number of front rows visible per column.
var front_rows_visible: int = 0

## Column definitions loaded from level data.
var columns: Array = []

## Building definitions loaded from level data.
var buildings: Array = []

## Loads level data into the simulation state.
func load_level(level: Dictionary) -> void:
	waiting_slots.clear()
	pending_units.clear()
	max_waiting_slots = int(level.get("waiting_slots", 0))
	front_rows_visible = int(level.get("front_rows_visible", 0))
	columns = level.get("columns", [])
	if typeof(columns) != TYPE_ARRAY:
		columns = []
	buildings = level.get("buildings", [])
	if typeof(buildings) != TYPE_ARRAY:
		buildings = []

## Enqueues a unit into the simulation state.
func enqueue_unit(column_id: String, index: int) -> void:
	pending_units.append({"column_id": column_id, "index": index})

## Returns units available within the front rows, respecting queue locks.
func get_available_units() -> Array:
	var available: Array = []
	if front_rows_visible <= 0:
		return available
	if columns.is_empty():
		return available
	var consumed: Dictionary = {}
	for entry in pending_units:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var key := _make_queue_key(str(entry.get("column_id", "")), int(entry.get("index", -1)))
		consumed[key] = true
	for entry in waiting_slots:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var key := _make_queue_key(str(entry.get("column_id", "")), int(entry.get("index", -1)))
		consumed[key] = true
	for column in columns:
		if typeof(column) != TYPE_DICTIONARY:
			continue
		var column_id := str(column.get("id", ""))
		var units := column.get("units", [])
		if typeof(units) != TYPE_ARRAY:
			continue
		var start_index := 0
		while start_index < units.size():
			var start_key := _make_queue_key(column_id, start_index)
			if not consumed.has(start_key):
				break
			start_index += 1
		if start_index < units.size():
			var key := _make_queue_key(column_id, start_index)
			if not consumed.has(key):
				available.append({"column_id": column_id, "index": start_index, "unit": units[start_index]})
	return available

## Returns attackable buildings for a given color, respecting layer blocking.
func get_attackable_buildings(color: String) -> Array:
	var candidates: Array = []
	var min_layer_depth: int = -1
	for entry in buildings:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if str(entry.get("color", "")) != color:
			continue
		var layer_depth := int(entry.get("layer_depth", 0))
		if layer_depth <= 0:
			continue
		if min_layer_depth == -1 or layer_depth < min_layer_depth:
			min_layer_depth = layer_depth
		candidates.append(entry)
	if min_layer_depth == -1:
		return []
	var attackable: Array = []
	for entry in candidates:
		if int(entry.get("layer_depth", 0)) == min_layer_depth:
			attackable.append(entry)
	return attackable

func _make_queue_key(column_id: String, index: int) -> String:
	return "%s:%d" % [column_id, index]
