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

## Loads level data into the simulation state.
func load_level(level: Dictionary) -> void:
	waiting_slots.clear()
	pending_units.clear()
	max_waiting_slots = int(level.get("waiting_slots", 0))
	front_rows_visible = int(level.get("front_rows_visible", 0))
	columns = level.get("columns", [])
	if typeof(columns) != TYPE_ARRAY:
		columns = []

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

func _make_queue_key(column_id: String, index: int) -> String:
	return "%s:%d" % [column_id, index]
