extends SceneTree
## Unit test for ContextualCursor HUD component: modes, colors, accessibility symbols and tags.

const CursorScript = preload("res://src/ui/contextual_cursor.gd")

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
	var cursor: Control = CursorScript.new()
	root.add_child(cursor)
	await process_frame

	# 1. Default mode
	_check(cursor.current_mode == CursorScript.Mode.DEFAULT, "Cursor starts in DEFAULT mode")
	_check(cursor._reticle.text == "+", "Default reticle is plus '+'")
	_check(cursor._symbol.text.is_empty(), "Default mode has no extra symbol")

	# 2. Enemy mode
	cursor.set_cursor_state(CursorScript.Mode.ENEMY, "PursuerA", 8.5)
	_check(cursor.current_mode == CursorScript.Mode.ENEMY, "Mode transitions to ENEMY")
	_check(cursor._reticle.text == "⌖", "Enemy reticle is target crosshair '⌖'")
	_check(cursor._symbol.text == "HEDEF", "Enemy mode displays HEDEF accessibility badge")
	_check(cursor._tag.text.contains("8.5m"), "Enemy tag exposes distance readout")
	_check(cursor._reticle.get_theme_color(&"font_color") == CursorScript.COLOR_ENEMY, "Enemy reticle has crimson red tint")

	# 3. Interact mode
	cursor.set_cursor_state(CursorScript.Mode.INTERACT, "Kapıyı Aç", 1.8)
	_check(cursor._reticle.text == "◎", "Interact reticle is focus ring '◎'")
	_check(cursor._symbol.text == "[E]", "Interact mode displays [E] key badge")
	_check(cursor._tag.text.contains("Kapıyı Aç"), "Interact tag displays action reason")
	_check(cursor._reticle.get_theme_color(&"font_color") == CursorScript.COLOR_INTERACT, "Interact reticle has gold/amber tint")

	# 4. Out of range mode
	cursor.set_cursor_state(CursorScript.Mode.OUT_OF_RANGE, "", 28.0)
	_check(cursor._reticle.text == "∅", "Out of range reticle is slashed zero '∅'")
	_check(cursor._symbol.text == "UZAK", "Out of range displays UZAK badge")
	_check(cursor._reticle.get_theme_color(&"font_color") == CursorScript.COLOR_OUT_OF_RANGE, "Out of range reticle has muted tint")

	# 5. Blocked / Cover mode
	cursor.set_cursor_state(CursorScript.Mode.BLOCKED, "Siper Arkası", 6.0)
	_check(cursor._reticle.text == "✕", "Blocked reticle is cross '✕'")
	_check(cursor._symbol.text == "ENGEL", "Blocked mode displays ENGEL badge")
	_check(cursor._reticle.get_theme_color(&"font_color") == CursorScript.COLOR_BLOCKED, "Blocked reticle has amber warning tint")

	# 6. Friendly mode
	cursor.set_cursor_state(CursorScript.Mode.FRIENDLY, "FriendlyTarget", 4.0)
	_check(cursor._reticle.text == "◇", "Friendly reticle is diamond '◇'")
	_check(cursor._symbol.text == "DOST", "Friendly mode displays DOST badge")
	_check(cursor._reticle.get_theme_color(&"font_color") == CursorScript.COLOR_FRIENDLY, "Friendly reticle has cyan/teal tint")

	# 7. Pulse animation on mode change
	cursor.set_cursor_state(CursorScript.Mode.DEFAULT, "")
	_check(cursor._pulse > 0.0, "Mode switch triggers scale pulse")
	cursor._process(0.2)
	_check(cursor._pulse <= 0.0, "Pulse decays back to neutral scale")

	cursor.queue_free()
	await process_frame

	print("ContextualCursor tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
