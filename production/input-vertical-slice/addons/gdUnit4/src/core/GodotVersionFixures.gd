## This service class contains helpers to wrap Godot functions and handle them carefully depending on the current Godot version
class_name GodotVersionFixures
extends RefCounted


# handle global_position fixed by https://github.com/godotengine/godot/pull/88473
static func set_event_global_position(event: InputEventMouseMotion, global_position: Vector2) -> void:
	if Engine.get_version_info().hex >= 0x40202 or Engine.get_version_info().hex == 0x40104:
		event.global_position = event.position
	else:
		event.global_position = global_position
