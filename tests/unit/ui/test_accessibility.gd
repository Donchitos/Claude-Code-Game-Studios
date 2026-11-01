extends SceneTree
## Unit tests for AccessibilitySettings: reticle scaling, hold/toggle, and reduced motion.

const AccessibilityScript = preload("res://src/ui/accessibility_settings.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred(&"_run_tests")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)


func _run_tests() -> void:
	var settings = AccessibilityScript.new()

	# 1. Defaults
	_check(settings.cursor_scale == 1.0, "Starts at 1.0x cursor scale")
	_check(not settings.reduced_effects, "Starts with full effects by default")
	_check(settings.screen_shake_multiplier == 1.0, "Screen shake starts at 100%")

	# 2. Reduced effects toggle (F6 keybind target)
	var toggled_seen := [false]
	settings.reduced_effects_toggled.connect(func(r): toggled_seen[0] = r)

	var is_red: bool = settings.toggle_reduced_effects()
	_check(is_red and toggled_seen[0], "Toggling reduced effects enables reduced flag")
	_check(settings.screen_shake_multiplier == 0.2, "Reduced motion scales down camera shake to 20%")

	settings.toggle_reduced_effects() # Turn back off
	_check(not settings.reduced_effects and settings.screen_shake_multiplier == 1.0, "Toggling off restores full motion")

	# 3. Cursor scale adjustment
	settings.set_cursor_scale(1.75)
	_check(settings.cursor_scale == 1.75, "Cursor scale sets to 1.75x")
	settings.set_cursor_scale(10.0) # Clamping test
	_check(settings.cursor_scale == 2.5, "Cursor scale clamps to 2.5x maximum safeguard")

	# 4. Hold vs Toggle setting
	settings.set_hold_toggle(true)
	_check(settings.hold_toggle_enabled, "Hold-to-toggle option activates")

	# 5. Reset
	settings.reset_defaults()
	_check(settings.cursor_scale == 1.0 and not settings.reduced_effects, "Reset restores accessibility defaults")

	print("Accessibility tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
