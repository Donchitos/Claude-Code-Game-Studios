# GdUnit4 test runner — invoked by CI and /smoke-check
# Usage: godot --headless --script tests/gdunit4_runner.gd
extends SceneTree

func _init() -> void:
	var runner := load("res://addons/gdunit4/GdUnitRunner.gd")
	if runner == null:
		push_error("GdUnit4 not found. Install via AssetLib or addons/.")
		quit(1)
		return
	var instance = runner.new()
	instance.run_tests()
	quit(0)
