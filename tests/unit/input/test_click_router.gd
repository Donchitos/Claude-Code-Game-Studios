extends SceneTree
## Unit test for ClickRouter: click prioritization, hold/release lifecycle, pause and focus gating.

const RouterScript = preload("res://src/input/click_router.gd")

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
	var router = RouterScript.new()
	var test_pos := Vector2(400, 300)

	# 1. Standard left click firing
	var fire_observed := [false, false] # [fired, is_hold]
	router.fire_requested.connect(func(pos: Vector2, hold: bool):
		fire_observed[0] = true
		fire_observed[1] = hold
	)

	var accepted: bool = router.handle_mouse_button(MOUSE_BUTTON_LEFT, true, test_pos)
	_check(accepted and fire_observed[0] and not fire_observed[1], "Left click down emits fire_requested (semi-auto tap)")

	# Release
	fire_observed[0] = false
	router.handle_mouse_button(MOUSE_BUTTON_LEFT, false, test_pos)
	_check(not fire_observed[0], "Left click release does not fire")

	# 2. Priority routing: Clicking on nearby station triggers interaction, NOT weapon fire
	var mock_station := Node3D.new()
	# Add mock activate method via script or dummy
	var station_script := GDScript.new()
	station_script.source_code = "extends Node3D\nfunc activate() -> void: pass"
	station_script.reload()
	mock_station.set_script(station_script)
	root.add_child(mock_station)

	var interact_observed := [false]
	router.interaction_triggered.connect(func(s: Node3D): interact_observed[0] = (s == mock_station))

	fire_observed[0] = false
	var interact_accepted: bool = router.handle_mouse_button(MOUSE_BUTTON_LEFT, true, test_pos, mock_station)
	_check(interact_accepted and interact_observed[0], "Clicking on station triggers interaction")
	_check(not fire_observed[0], "Interaction click suppresses weapon firing")
	router.handle_mouse_button(MOUSE_BUTTON_LEFT, false, test_pos)

	# 3. Automatic fire hold
	router.is_automatic_weapon = true
	router.handle_mouse_button(MOUSE_BUTTON_LEFT, true, test_pos)
	fire_observed[0] = false
	# Advance below threshold
	router.advance(0.1, test_pos)
	_check(not fire_observed[0], "Below hold threshold does not auto-fire")
	# Advance past threshold
	router.advance(0.25, test_pos)
	_check(fire_observed[0] and fire_observed[1], "Holding automatic weapon emits fire_requested with is_hold=true")
	router.handle_mouse_button(MOUSE_BUTTON_LEFT, false, test_pos)

	# 4. Right click alt action
	var alt_observed := [false]
	router.alt_action_requested.connect(func(pos: Vector2): alt_observed[0] = true)
	var right_accepted: bool = router.handle_mouse_button(MOUSE_BUTTON_RIGHT, true, test_pos)
	_check(right_accepted and alt_observed[0], "Right click down emits alt_action_requested")

	# 5. Focus loss and pause gating
	router.has_focus = false
	var no_focus_accepted: bool = router.handle_mouse_button(MOUSE_BUTTON_LEFT, true, test_pos)
	_check(not no_focus_accepted, "Click is rejected when window lacks focus")

	router.has_focus = true
	router.is_paused = true
	var paused_accepted: bool = router.handle_mouse_button(MOUSE_BUTTON_LEFT, true, test_pos)
	_check(not paused_accepted, "Click is rejected when game is paused")

	router.is_paused = false
	router.can_fire = false
	var cant_fire_accepted: bool = router.handle_mouse_button(MOUSE_BUTTON_LEFT, true, test_pos)
	_check(not cant_fire_accepted, "Click is rejected when can_fire is false")

	mock_station.queue_free()
	await process_frame

	print("ClickRouter tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
