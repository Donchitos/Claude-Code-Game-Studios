class_name GdUnitOrphanNodeInfo
extends RefCounted

enum GdUnitOrphanType {
	member,
	variable,
	unknown
}


var _id: int
var _orphan_type: GdUnitOrphanType
var _type: String
var _name: String
var _script_ref: String
var _func_ref: String
var _next: GdUnitOrphanNodeInfo

const text_color := Color.ANTIQUE_WHITE
const function_color := Color.SKY_BLUE
const member_variable_color := Color.SALMON
const engine_type_color := Color.LIGHT_GREEN
const script_path_color := Color.CORNFLOWER_BLUE


func _init(orphan_type: GdUnitOrphanType, id: int, type: String, name: String, script_ref: String, func_ref: String = "") -> void:
	_orphan_type = orphan_type
	_id = id
	_type = type
	_name = name
	_script_ref = script_ref
	_func_ref = func_ref


func as_trace(info: GdUnitOrphanNodeInfo, show_orphan_id := true) -> String:
	var trace := ""
	if show_orphan_id:
		trace += "• <%s> Id:%s\n" % [
			_colored(info._type, engine_type_color),
			_colored(info._id, engine_type_color)]
	match info._orphan_type:
		GdUnitOrphanType.member:
			return trace + "	at  %s script: %s" % [
				_colored(info._name, member_variable_color),
				_colored(info._script_ref, script_path_color)
				] + sub_info(info._next)
		GdUnitOrphanType.variable:
			return trace + "	at %s script: %s.%s()" % [
				_colored(info._name, member_variable_color),
				_colored(info._script_ref, script_path_color),
				_colored(info._func_ref, function_color),
				]
		GdUnitOrphanType.unknown:
			return trace + "	%s" % [
				_colored(info._name, member_variable_color)
				]

		_:
			return trace + "	No details available"


func sub_info(next: GdUnitOrphanNodeInfo) -> String:
	if next == null:
		return ""

	return "\n" + as_trace(next, false)


static func _colored(value: Variant, color: Color) -> String:
	return "[color=%s]%s[/color]" % [color.to_html(), value]
