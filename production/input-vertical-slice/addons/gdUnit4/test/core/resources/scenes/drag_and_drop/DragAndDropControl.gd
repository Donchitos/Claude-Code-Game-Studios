extends PanelContainer


# Godot calls this method to get data that can be dragged and dropped onto controls that expect drop data.
# Returns null if there is no data to drag.
# Controls that want to receive drop data should implement can_drop_data() and drop_data().
# position is local to this control. Drag may be forced with force_drag().
func _get_drag_data(_position: Vector2) -> Variant:
	var x :TextureRect = $TextureRect
	var data: = {texture = x.texture}
	var drag_texture :TextureRect = x.duplicate()
	drag_texture.size = x.size
	drag_texture.position = x.global_position * -0.2

	# set drag preview
	var control := Panel.new()
	control.add_child(drag_texture)
	# center texture relative to mouse pos
	set_drag_preview(control)
	return data


# Godot calls this method to test if data from a control's get_drag_data() can be dropped at position. position is local to this control.
func _can_drop_data(_position: Vector2, data :Variant) -> bool:
	@warning_ignore("unsafe_method_access")
	return typeof(data) == TYPE_DICTIONARY and data.has("texture")


# Godot calls this method to pass you the data from a control's get_drag_data() result.
# Godot first calls can_drop_data() to test if data is allowed to drop at position where position is local to this control.
func _drop_data(_position: Vector2, data :Variant) -> void:
	var drag_texture :Texture = data["texture"]
	if drag_texture != null:
		($TextureRect as TextureRect).texture = drag_texture


# Virtual method to be implemented by the user. Use this method to process and accept inputs on UI elements. See accept_event().
func _gui_input(_event :InputEvent) -> void:
	#if _event is InputEventScreenDrag:
	#	prints(" InputEventScreenDrag", _event.as_text())
	#if _event is InputEventScreenTouch:
	#	prints(" InputEventScreenTouch", _event.as_text())
	#if _event is InputEventMouseButton:
	#	prints("Panel _gui_input", _event.as_text())
	pass
