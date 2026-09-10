class_name GdUnitContextMenuItem


var command_id: String:
	set(value):
		command_id = value
	get:
		return command_id

var name: StringName:
	set(value):
		name = value
	get:
		return name

var visible: Callable:
	set(value):
		visible = value
	get:
		return visible

var icon: Texture2D:
	get:
		return GdUnitCommandHandler.instance().command_icon(command_id)


func _init(p_command_id: String, p_name: StringName, p_is_visible: Callable) -> void:
	assert(p_command_id != null and not p_command_id.is_empty(), "(%s) missing command id " % p_command_id)
	assert(p_is_visible != null, "(%s) missing parameter 'GdUnitCommand'" % p_name)

	self.command_id = p_command_id
	self.name = p_name
	self.visible = p_is_visible


func shortcut() -> Shortcut:
	return GdUnitCommandHandler.instance().command_shortcut(command_id)


func is_visible(...args: Array) -> bool:
	return visible.callv(args)


func execute(...args: Array) -> void:
	GdUnitCommandHandler.instance().command_execute(command_id, args)
