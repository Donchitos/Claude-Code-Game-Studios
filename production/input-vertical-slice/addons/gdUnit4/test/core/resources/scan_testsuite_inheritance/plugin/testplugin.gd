@tool
extends EditorPlugin

var plugin: EditorInspectorPlugin


func _enter_tree() -> void:
	plugin = preload("res://addons/gdUnit4/test/core/resources/scan_testsuite_inheritance/plugin/inspector_plugin.gd").new()
	add_inspector_plugin(plugin)
	pass


func _exit_tree() -> void:
	pass
