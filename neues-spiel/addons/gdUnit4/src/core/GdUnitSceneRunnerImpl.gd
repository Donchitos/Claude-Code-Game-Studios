# This class provides a runner for scense to simulate interactions like keyboard or mouse
class_name GdUnitSceneRunnerImpl
extends GdUnitSceneRunner


var GdUnitFuncAssertImpl: GDScript = ResourceLoader.load("res://addons/gdUnit4/src/asserts/GdUnitFuncAssertImpl.gd", "GDScript", ResourceLoader.CACHE_MODE_REUSE)


# mapping of mouse buttons and his masks
const MAP_MOUSE_BUTTON_MASKS := {
	MOUSE_BUTTON_LEFT : MOUSE_BUTTON_MASK_LEFT,
	MOUSE_BUTTON_RIGHT : MOUSE_BUTTON_MASK_RIGHT,
	MOUSE_BUTTON_MIDDLE : MOUSE_BUTTON_MASK_MIDDLE,
	# https://github.com/godotengine/godot/issues/73632
	MOUSE_BUTTON_WHEEL_UP : 1 << (MOUSE_BUTTON_WHEEL_UP - 1),
	MOUSE_BUTTON_WHEEL_DOWN : 1 << (MOUSE_BUTTON_WHEEL_DOWN - 1),
	MOUSE_BUTTON_XBUTTON1 : MOUSE_BUTTON_MASK_MB_XBUTTON1,
	MOUSE_BUTTON_XBUTTON2 : MOUSE_BUTTON_MASK_MB_XBUTTON2,
}

var _is_disposed := false
var _current_scene: Node = null
var _awaiter: GdUnitAwaiter = GdUnitAwaiter.new()
var _verbose: bool
var _simulate_start_time: LocalTime
var _last_input_event: InputEvent = null
var _mouse_button_on_press := []
var _key_on_press := []
var _action_on_press := []
var _curent_mouse_position: Vector2
# holds the touch position for each touch index
# { index: int = position: Vector2}
var _current_touch_position: Dictionary = {}
# holds the curretn touch drag position
var _current_touch_drag_position: Vector2 = Vector2.ZERO

# time factor settings
var _time_factor := 1.0
var _saved_iterations_per_second: float
var _scene_auto_free := false


func _init(p_scene: Variant, p_verbose: bool, p_hide_push_errors := false) -> void:
	_verbose = p_verbose
	_saved_iterations_per_second = Engine.get_physics_ticks_per_second()
	@warning_ignore("return_value_discarded")
	set_time_factor(1)
	# handle scene loading by resource path
	if typeof(p_scene) == TYPE_STRING:
		@warning_ignore("unsafe_cast")
		if !ResourceLoader.exists(p_scene as String):
			if not p_hide_push_errors:
				push_error("GdUnitSceneRunner: Can't load scene by given resource path: '%s'. The resource does not exists." % p_scene)
			return
		if !str(p_scene).ends_with(".tscn") and !str(p_scene).ends_with(".scn") and !str(p_scene).begins_with("uid://"):
			if not p_hide_push_errors:
				push_error("GdUnitSceneRunner: The given resource: '%s'. is not a scene." % p_scene)
			return
		@warning_ignore("unsafe_cast")
		_current_scene = (load(p_scene as String) as PackedScene).instantiate()
		_scene_auto_free = true
	else:
		# verify we have a node instance
		if not p_scene is Node:
			if not p_hide_push_errors:
				push_error("GdUnitSceneRunner: The given instance '%s' is not a Node." % p_scene)
			return
		_current_scene = p_scene
	if _current_scene == null:
		if not p_hide_push_errors:
			push_error("GdUnitSceneRunner: Scene must be not null!")
		return

	_scene_tree().root.add_child(_current_scene)
	Engine.set_meta("GdUnitSceneRunner", self)
	# do finally reset all open input events when the scene is removed
	@warning_ignore("return_value_discarded")
	_scene_tree().root.child_exiting_tree.connect(func f(child: Node) -> void:
		if child == _current_scene:
			_reset_input_to_default()
	)
	_simulate_start_time = LocalTime.now()
	# we need to set inital a valid window otherwise the warp_mouse() is not handled
	move_window_to_foreground()

	# set inital mouse pos to 0,0
	var max_iteration_to_wait := 0
	while get_global_mouse_position() != Vector2.ZERO and max_iteration_to_wait < 100:
		Input.warp_mouse(Vector2.ZERO)
		max_iteration_to_wait += 1


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(self):
		# reset time factor to normal
		__deactivate_time_factor()
		if is_instance_valid(_current_scene):
			move_window_to_background()
			_scene_tree().root.remove_child(_current_scene)
			# do only free scenes instanciated by this runner
			if _scene_auto_free:
				_current_scene.free()
		_is_disposed = true
		_current_scene = null
		Engine.remove_meta("GdUnitSceneRunner")


func _scene_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func await_input_processed() -> void:
	if scene() != null and scene().process_mode != Node.PROCESS_MODE_DISABLED:
		Input.flush_buffered_events()
	await (Engine.get_main_loop() as SceneTree).process_frame
	await (Engine.get_main_loop() as SceneTree).physics_frame


@warning_ignore("return_value_discarded")
func simulate_action_pressed(action: String, event_index := -1) -> GdUnitSceneRunner:
	simulate_action_press(action, event_index)
	simulate_action_release(action, event_index)
	return self


func simulate_action_press(action: String, event_index := -1) -> GdUnitSceneRunner:
	__print_current_focus()
	var event := InputEventAction.new()
	event.pressed = true
	event.action = action
	event.event_index = event_index
	_action_on_press.append(action)
	return _handle_input_event(event)


func simulate_action_release(action: String, event_index := -1) -> GdUnitSceneRunner:
	__print_current_focus()
	var event := InputEventAction.new()
	event.pressed = false
	event.action = action
	event.event_index = event_index
	_action_on_press.erase(action)
	return _handle_input_event(event)


@warning_ignore("return_value_discarded")
func simulate_key_pressed(key_code: int, shift_pressed := false, ctrl_pressed := false) -> GdUnitSceneRunner:
	_push_warning_deprecated_arguments(shift_pressed, ctrl_pressed)
	simulate_key_press(key_code, shift_pressed, ctrl_pressed)
	await _scene_tree().process_frame
	simulate_key_release(key_code, shift_pressed, ctrl_pressed)
	return self


func simulate_key_press(key_code: int, shift_pressed := false, ctrl_pressed := false) -> GdUnitSceneRunner:
	_push_warning_deprecated_arguments(shift_pressed, ctrl_pressed)
	__print_current_focus()
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = key_code as Key
	event.physical_keycode = key_code as Key
	event.unicode = key_code
	event.set_alt_pressed(key_code == KEY_ALT)
	event.set_shift_pressed(shift_pressed)
	event.set_ctrl_pressed(ctrl_pressed)
	event.get_modifiers_mask()
	_apply_input_modifiers(event)
	_key_on_press.append(key_code)
	return _handle_input_event(event)


func simulate_key_release(key_code: int, shift_pressed := false, ctrl_pressed := false) -> GdUnitSceneRunner:
	_push_warning_deprecated_arguments(shift_pressed, ctrl_pressed)
	__print_current_focus()
	var event := InputEventKey.new()
	event.pressed = false
	event.keycode = key_code as Key
	event.physical_keycode = key_code as Key
	event.unicode = key_code
	event.set_alt_pressed(key_code == KEY_ALT)
	event.set_shift_pressed(shift_pressed)
	event.set_ctrl_pressed(ctrl_pressed)
	_apply_input_modifiers(event)
	_key_on_press.erase(key_code)
	return _handle_input_event(event)


func set_mouse_position(pos: Vector2) -> GdUnitSceneRunner:
	var event := InputEventMouseMotion.new()
	event.position = pos
	event.global_position = get_global_mouse_position()
	_apply_input_modifiers(event)
	return _handle_input_event(event)


func get_mouse_position() -> Vector2:
	if _last_input_event is InputEventMouse:
		return (_last_input_event as InputEventMouse).position
	var current_scene := scene()
	if current_scene != null:
		return current_scene.get_viewport().get_mouse_position()
	return Vector2.ZERO


func get_global_mouse_position() -> Vector2:
	return (Engine.get_main_loop() as SceneTree).root.get_mouse_position()


func simulate_mouse_move(position: Vector2) -> GdUnitSceneRunner:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.relative = position - get_mouse_position()
	event.global_position = get_global_mouse_position()
	_apply_input_mouse_mask(event)
	_apply_input_modifiers(event)
	return _handle_input_event(event)


@warning_ignore("return_value_discarded")
func simulate_mouse_move_relative(relative: Vector2, time: float = 1.0, trans_type: Tween.TransitionType = Tween.TRANS_LINEAR) -> GdUnitSceneRunner:
	var tween := _scene_tree().create_tween()
	_curent_mouse_position = get_mouse_position()
	var final_position := _curent_mouse_position + relative
	tween.tween_property(self, "_curent_mouse_position", final_position, time).set_trans(trans_type)
	tween.play()

	while not get_mouse_position().is_equal_approx(final_position):
		simulate_mouse_move(_curent_mouse_position)
		await _scene_tree().process_frame
	return self


@warning_ignore("return_value_discarded")
func simulate_mouse_move_absolute(position: Vector2, time: float = 1.0, trans_type: Tween.TransitionType = Tween.TRANS_LINEAR) -> GdUnitSceneRunner:
	var tween := _scene_tree().create_tween()
	_curent_mouse_position = get_mouse_position()
	tween.tween_property(self, "_curent_mouse_position", position, time).set_trans(trans_type)
	tween.play()

	while not get_mouse_position().is_equal_approx(position):
		simulate_mouse_move(_curent_mouse_position)
		await _scene_tree().process_frame
	return self


@warning_ignore("return_value_discarded")
func simulate_mouse_button_pressed(button_index: MouseButton, double_click := false) -> GdUnitSceneRunner:
	simulate_mouse_button_press(button_index, double_click)
	simulate_mouse_button_release(button_index)
	return self


func simulate_mouse_button_press(button_index: MouseButton, double_click := false) -> GdUnitSceneRunner:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = true
	event.double_click = double_click
	_apply_input_mouse_position(event)
	_apply_input_mouse_mask(event)
	_apply_input_modifiers(event)
	_mouse_button_on_press.append(button_index)
	return _handle_input_event(event)


func simulate_mouse_button_release(button_index: MouseButton) -> GdUnitSceneRunner:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = false
	_apply_input_mouse_position(event)
	_apply_input_mouse_mask(event)
	_apply_input_modifiers(event)
	_mouse_button_on_press.erase(button_index)
	return _handle_input_event(event)


@warning_ignore("return_value_discarded")
func simulate_screen_touch_pressed(index: int, position: Vector2, double_tap := false) -> GdUnitSceneRunner:
	simulate_screen_touch_press(index, position, double_tap)
	simulate_screen_touch_release(index)
	return self


@warning_ignore("return_value_discarded")
func simulate_screen_touch_press(index: int, position: Vector2, double_tap := false) -> GdUnitSceneRunner:
	if is_emulate_mouse_from_touch():
		# we need to simulate in addition to the touch the mouse events
		set_mouse_position(position)
		simulate_mouse_button_press(MOUSE_BUTTON_LEFT)
	# push touch press event at position
	var event := InputEventScreenTouch.new()
	event.window_id = scene().get_window().get_window_id()
	event.index = index
	event.position = position
	event.double_tap = double_tap
	event.pressed = true
	_current_scene.get_viewport().push_input(event)
	# save current drag position by index
	_current_touch_position[index] = position
	return self


@warning_ignore("return_value_discarded")
func simulate_screen_touch_release(index: int, double_tap := false) -> GdUnitSceneRunner:
	if is_emulate_mouse_from_touch():
		# we need to simulate in addition to the touch the mouse events
		simulate_mouse_button_release(MOUSE_BUTTON_LEFT)
	# push touch release event at position
	var event := InputEventScreenTouch.new()
	event.window_id = scene().get_window().get_window_id()
	event.index = index
	event.position = get_screen_touch_drag_position(index)
	event.pressed = false
	event.double_tap = (_last_input_event as InputEventScreenTouch).double_tap if _last_input_event is InputEventScreenTouch else double_tap
	_current_scene.get_viewport().push_input(event)
	return self


func simulate_screen_touch_drag_relative(index: int, relative: Vector2, time: float = 1.0, trans_type: Tween.TransitionType = Tween.TRANS_LINEAR) -> GdUnitSceneRunner:
	var current_position: Vector2 = _current_touch_position[index]
	return await _do_touch_drag_at(index, current_position + relative, time, trans_type)


func simulate_screen_touch_drag_absolute(index: int, position: Vector2, time: float = 1.0, trans_type: Tween.TransitionType = Tween.TRANS_LINEAR) -> GdUnitSceneRunner:
	return await _do_touch_drag_at(index, position, time, trans_type)


@warning_ignore("return_value_discarded")
func simulate_screen_touch_drag_drop(index: int, position: Vector2, drop_position: Vector2, time: float = 1.0, trans_type: Tween.TransitionType = Tween.TRANS_LINEAR) -> GdUnitSceneRunner:
	simulate_screen_touch_press(index, position)
	return await _do_touch_drag_at(index, drop_position, time, trans_type)


@warning_ignore("return_value_discarded")
func simulate_screen_touch_drag(index: int, position: Vector2) -> GdUnitSceneRunner:
	if is_emulate_mouse_from_touch():
		simulate_mouse_move(position)
	var event := InputEventScreenDrag.new()
	event.window_id = scene().get_window().get_window_id()
	event.index = index
	event.position = position
	event.relative = _get_screen_touch_drag_position_or_default(index, position) - position
	event.velocity = event.relative / _scene_tree().root.get_process_delta_time()
	event.pressure = 1.0
	_current_touch_position[index] = position
	_current_scene.get_viewport().push_input(event)
	return self


func get_screen_touch_drag_position(index: int) -> Vector2:
	if _current_touch_position.has(index):
		return _current_touch_position[index]
	push_error("No touch drag position for index '%d' is set!" % index)
	return Vector2.ZERO


func is_emulate_mouse_from_touch() -> bool:
	return ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", true)


func _get_screen_touch_drag_position_or_default(index: int, default_position: Vector2) -> Vector2:
	if _current_touch_position.has(index):
		return _current_touch_position[index]
	return default_position


@warning_ignore("return_value_discarded")
func _do_touch_drag_at(index: int, drag_position: Vector2, time: float, trans_type: Tween.TransitionType) -> GdUnitSceneRunner:
	# start draging
	var event := InputEventScreenDrag.new()
	event.window_id = scene().get_window().get_window_id()
	event.index = index
	event.position = get_screen_touch_drag_position(index)
	event.pressure = 1.0
	_current_touch_drag_position = event.position

	var tween := _scene_tree().create_tween()
	tween.tween_property(self, "_current_touch_drag_position", drag_position, time).set_trans(trans_type)
	tween.play()

	while not _current_touch_drag_position.is_equal_approx(drag_position):
		if is_emulate_mouse_from_touch():
			# we need to simulate in addition to the drag the mouse move events
			simulate_mouse_move(event.position)
		# send touche drag event to new position
		event.relative = _current_touch_drag_position - event.position
		event.velocity = event.relative / _scene_tree().root.get_process_delta_time()
		event.position = _current_touch_drag_position
		_current_scene.get_viewport().push_input(event)
		await _scene_tree().process_frame

	# finaly drop it
	if is_emulate_mouse_from_touch():
		simulate_mouse_move(drag_position)
		simulate_mouse_button_release(MOUSE_BUTTON_LEFT)
	var touch_drop_event := InputEventScreenTouch.new()
	touch_drop_event.window_id = event.window_id
	touch_drop_event.index = event.index
	touch_drop_event.position = drag_position
	touch_drop_event.pressed = false
	_current_scene.get_viewport().push_input(touch_drop_event)
	await _scene_tree().process_frame
	return self


func set_time_factor(time_factor: float = 1.0) -> GdUnitSceneRunner:
	_time_factor = min(9.0, time_factor)
	__activate_time_factor()
	__print("set time factor: %f" % _time_factor)
	__print("set physics physics_ticks_per_second: %d" % (_saved_iterations_per_second*_time_factor))
	return self


func simulate_frames(frames: int, delta_milli: int = -1) -> GdUnitSceneRunner:
	var time_shift_frames :int = max(1, frames / _time_factor)
	for frame in time_shift_frames:
		if delta_milli == -1:
			await _scene_tree().process_frame
		else:
			await _scene_tree().create_timer(delta_milli * 0.001).timeout
	return self


func simulate_until_signal(signal_name: String, ...args: Array) -> GdUnitSceneRunner:
	await _awaiter.await_signal_idle_frames(scene(), signal_name, args, 10000)
	return self


func simulate_until_object_signal(source: Object, signal_name: String, ...args: Array) -> GdUnitSceneRunner:
	await _awaiter.await_signal_idle_frames(source, signal_name, args, 10000)
	return self


func await_func(func_name: String, ...args: Array) -> GdUnitFuncAssert:
	return GdUnitFuncAssertImpl.new(scene(), func_name, args)


func await_func_on(instance: Object, func_name: String, ...args: Array) -> GdUnitFuncAssert:
	return GdUnitFuncAssertImpl.new(instance, func_name, args)


func await_signal(signal_name: String, args := [], timeout := 2000 ) -> void:
	await _awaiter.await_signal_on(scene(), signal_name, args, timeout)


func await_signal_on(source: Object, signal_name: String, args := [], timeout := 2000 ) -> void:
	await _awaiter.await_signal_on(source, signal_name, args, timeout)


func move_window_to_foreground() -> GdUnitSceneRunner:
	if not Engine.is_embedded_in_editor():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_move_to_foreground()
	return self


func move_window_to_background() -> GdUnitSceneRunner:
	if not Engine.is_embedded_in_editor():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	return self


func _property_exists(name: String) -> bool:
	return scene().get_property_list().any(func(properties :Dictionary) -> bool: return properties["name"] == name)


func get_property(name: String) -> Variant:
	if not _property_exists(name):
		return "The property '%s' not exist checked loaded scene." % name
	return scene().get(name)


func set_property(name: String, value: Variant) -> bool:
	if not _property_exists(name):
		push_error("The property named '%s' cannot be set, it does not exist!" % name)
		return false;
	scene().set(name, value)
	return true


func invoke(name: String, ...args: Array) -> Variant:
	if scene().has_method(name):
		return await scene().callv(name, args)
	return "The method '%s' not exist checked loaded scene." % name


func find_child(name: String, recursive: bool = true, owned: bool = false) -> Node:
	return scene().find_child(name, recursive, owned)


func _scene_name() -> String:
	if scene() == null:
		return "unknown"
	var scene_script :GDScript = scene().get_script()
	var scene_name :String = scene().get_name()
	if not scene_script:
		return scene_name
	if not scene_name.begins_with("@"):
		return scene_name
	return scene_script.resource_name.get_basename()


func __activate_time_factor() -> void:
	Engine.set_time_scale(_time_factor)
	Engine.set_physics_ticks_per_second((_saved_iterations_per_second * _time_factor) as int)


func __deactivate_time_factor() -> void:
	Engine.set_time_scale(1)
	Engine.set_physics_ticks_per_second(_saved_iterations_per_second as int)


# copy over current active modifiers
func _apply_input_modifiers(event: InputEvent) -> void:
	if _last_input_event is InputEventWithModifiers and event is InputEventWithModifiers:
		var last_input_event := _last_input_event as InputEventWithModifiers
		var _event := event as InputEventWithModifiers
		_event.meta_pressed = _event.meta_pressed or last_input_event.meta_pressed
		_event.alt_pressed = _event.alt_pressed or last_input_event.alt_pressed
		_event.shift_pressed = _event.shift_pressed or last_input_event.shift_pressed
		_event.ctrl_pressed = _event.ctrl_pressed or last_input_event.ctrl_pressed
		# this line results into reset the control_pressed state!!!
		#event.command_or_control_autoremap = event.command_or_control_autoremap or _last_input_event.command_or_control_autoremap
	if _last_input_event is InputEventKey and event is InputEventWithModifiers:
		var last_input_event := _last_input_event as InputEventKey
		var _event := event as InputEventWithModifiers
		_event.shift_pressed = _event.shift_pressed or last_input_event.keycode == KEY_SHIFT
		_event.alt_pressed = _event.alt_pressed or last_input_event.keycode == KEY_ALT
		_event.ctrl_pressed = _event.ctrl_pressed or last_input_event.keycode == KEY_CTRL
		_event.meta_pressed = _event.meta_pressed or  last_input_event.keycode == KEY_META


# copy over current active mouse mask and combine with curren mask
func _apply_input_mouse_mask(event: InputEvent) -> void:
	# first apply last mask
	if _last_input_event is InputEventMouse and event is InputEventMouse:
		(event as InputEventMouse).button_mask |= (_last_input_event as InputEventMouse).button_mask
	if event is InputEventMouseButton:
		var _event := event as InputEventMouseButton
		var button_mask :int = MAP_MOUSE_BUTTON_MASKS.get(_event.get_button_index(), 0)
		if _event.is_pressed():
			_event.button_mask |= button_mask
		else:
			_event.button_mask ^= button_mask


# copy over last mouse position if need
func _apply_input_mouse_position(event: InputEvent) -> void:
	if _last_input_event is InputEventMouse and event is InputEventMouseButton:
		(event as InputEventMouseButton).position = (_last_input_event as InputEventMouse).position


## handle input action via Input modifieres
func _handle_actions(event: InputEventAction) -> bool:
	if not InputMap.event_is_action(event, event.action, true):
		return false
	__print("	process action %s (%s) <- %s" % [scene(), _scene_name(), event.as_text()])
	if event.is_pressed():
		Input.action_press(event.action, event.get_strength())
	else:
		Input.action_release(event.action)
	return true


# for handling read https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html?highlight=inputevent#how-does-it-work
@warning_ignore("return_value_discarded")
func _handle_input_event(event: InputEvent) -> GdUnitSceneRunner:
	if event is InputEventMouse:
		Input.warp_mouse((event as InputEventMouse).position as Vector2)
	Input.parse_input_event(event)

	if event is InputEventAction:
		_handle_actions(event as InputEventAction)

	var current_scene := scene()
	if is_instance_valid(current_scene):
		# do not flush events if node processing disabled otherwise we run into errors at tree removed
		if _current_scene.process_mode != Node.PROCESS_MODE_DISABLED:
			Input.flush_buffered_events()
		__print("	process event %s (%s) <- %s" % [current_scene, _scene_name(), event.as_text()])
		if(current_scene.has_method("_gui_input")):
			(current_scene as Control)._gui_input(event)
		if(current_scene.has_method("_unhandled_input")):
			current_scene._unhandled_input(event)
		current_scene.get_viewport().set_input_as_handled()

	# save last input event needs to be merged with next InputEventMouseButton
	_last_input_event = event
	return self


@warning_ignore("return_value_discarded")
func _reset_input_to_default() -> void:
	# reset all mouse button to inital state if need
	for m_button :int in _mouse_button_on_press.duplicate():
		if Input.is_mouse_button_pressed(m_button):
			simulate_mouse_button_release(m_button)
	_mouse_button_on_press.clear()

	for key_scancode :int in _key_on_press.duplicate():
		if Input.is_key_pressed(key_scancode):
			simulate_key_release(key_scancode)
	_key_on_press.clear()

	for action :String in _action_on_press.duplicate():
		if Input.is_action_pressed(action):
			simulate_action_release(action)
	_action_on_press.clear()

	if is_instance_valid(_current_scene) and _current_scene.process_mode != Node.PROCESS_MODE_DISABLED:
		Input.flush_buffered_events()
	_last_input_event = null


func __print(message: String) -> void:
	if _verbose:
		prints(message)


func __print_current_focus() -> void:
	if not _verbose:
		return
	var focused_node := scene().get_viewport().gui_get_focus_owner()
	if focused_node:
		prints("	focus checked %s" % focused_node)
	else:
		prints("	no focus set")


func scene() -> Node:
	if is_instance_valid(_current_scene):
		return _current_scene
	if not _is_disposed:
		push_error("The current scene instance is not valid anymore! check your test is valid. e.g. check for missing awaits.")
	return null


func _push_warning_deprecated_arguments(shift_pressed: bool, ctrl_pressed: bool) -> void:
	if shift_pressed:
		push_warning("Deprecated! Don't use 'shift_pressed' it will be removed in v7.0, checkout the documentaion how to use key combinations.")
	if ctrl_pressed:
		push_warning("Deprecated! Don't use 'ctrl_pressed' it will be removed in v7.0, checkout the documentaion how to use key combinations.")
