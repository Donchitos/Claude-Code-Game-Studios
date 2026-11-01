extends SceneTree
## External Windows keyboard rehearsal. This driver never injects Godot actions/events.
## The launcher must focus this window, hold D briefly, then press Space.

var _lab: Node3D
var _elapsed := 0.0
var _start := Vector3.ZERO
var _distance := 0.0
var _height := 0.0
var _seen_keys: Dictionary = {}
var _finished := false


func _initialize() -> void:
	call_deferred(&"_start_lab")


func _start_lab() -> void:
	_lab = load("res://src/lab/mechanics_lab.tscn").instantiate()
	root.add_child(_lab)
	_start = _lab._player.position
	root.window_input.connect(_observe_key)
	root.grab_focus()
	print("WINDOWS KEYBOARD READY")


func _observe_key(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_seen_keys[event.physical_keycode] = event.device


func _process(delta: float) -> bool:
	if not is_instance_valid(_lab) or _finished:
		return false
	_elapsed += delta
	_distance = maxf(_distance, _lab._player.position.x - _start.x)
	_height = maxf(_height, _lab._player.position.y - _start.y)
	if _elapsed >= 12.0:
		_finished = true
		var moved: bool = _distance > 0.5
		var jumped: bool = _height > 0.3
		print("WINDOWS KEYBOARD: devices=%s distance=%.3f jump_height=%.3f" % [
			_seen_keys, _distance, _height])
		print("WINDOWS KEYBOARD: movement=%s Space_jump=%s" % [moved, jumped])
		quit(0 if moved and jumped else 1)
	return false
