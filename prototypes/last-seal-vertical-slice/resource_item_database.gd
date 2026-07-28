# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: full build->furnish->live loop, unguided <=5 min, cozy at scale
# Date: 2026-07-12
# Resource & Item Database per design/gdd/resource-item-database.md, slice-reduced:
# inline authored tier-0 set, getter-only defs, boot validation, id-only references.
extends Node

class ItemDef:
	var _id: String
	var _display_name: String
	var _category: String
	var _cell_value: int
	var _color: Color
	var _build_ticks: int

	func _init(id: String, display_name: String, category: String, cell_value: int, color: Color, build_ticks: int) -> void:
		_id = id
		_display_name = display_name
		_category = category
		_cell_value = cell_value
		_color = color
		_build_ticks = build_ticks

	var id: String:
		get: return _id
	var display_name: String:
		get: return _display_name
	var category: String:
		get: return _category
	var cell_value: int:
		get: return _cell_value
	var color: Color:
		get: return _color
	var build_ticks: int:
		get: return _build_ticks


var _defs: Dictionary = {}          # id -> ItemDef
var _by_cell_value: Dictionary = {} # int -> ItemDef
var _ready_state := false


func _ready() -> void:
	# Authored tier-0 set (warm palette per design/art/art-bible.md §4.1).
	var authored := [
		["wood_block", "Wood", "building_material", 10, Color(0.55, 0.38, 0.22), 6],
		["stone_block", "Stone", "building_material", 11, Color(0.52, 0.50, 0.47), 8],
		["thatch_block", "Thatch", "building_material", 12, Color(0.76, 0.62, 0.30), 4],
		["bed", "Bed", "furniture_fixture", 20, Color(0.72, 0.28, 0.24), 8],
	]
	for row in authored:
		var def := ItemDef.new(row[0], row[1], row[2], row[3], row[4], row[5])
		# Boot validation (terminal in production; slice: assert)
		assert(not _defs.has(def.id), "duplicate item id: %s" % def.id)
		assert(def.cell_value > 0, "invalid cell value for %s" % def.id)
		_defs[def.id] = def
		_by_cell_value[def.cell_value] = def
	_ready_state = true


func is_ready() -> bool:
	return _ready_state


func get_by_id(id: String) -> ItemDef:
	if not _defs.has(id):
		push_warning("unknown item id: %s" % id)
		return null
	return _defs[id]


func get_by_cell_value(v: int) -> ItemDef:
	return _by_cell_value.get(v)


func list_by_category(category: String) -> Array:
	var out: Array = []
	for def: ItemDef in _defs.values():
		if def.category == category:
			out.append(def)
	return out
