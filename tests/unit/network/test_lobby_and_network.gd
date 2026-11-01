extends SceneTree
## Unit tests for NetworkManager & MainMenu lobby: room codes, roster sync, 2-player hybrid roles, and UI transitions.

const NetworkScript = preload("res://src/network/network_manager.gd")
const MenuScript = preload("res://src/ui/main_menu.gd")

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
	# 1. Room code generation
	var code: String = NetworkScript.generate_room_code()
	_check(code.begins_with("S9-") and code.length() == 7, "Room code generates format S9-XXXX")

	# 2. NetworkManager Host setup
	var net = NetworkScript.new()
	root.add_child(net)
	await process_frame

	var room_code: String = net.host_game(10055, "S9-7777")
	_check(room_code == "S9-7777", "Host lobby sets requested room code")
	_check(net.is_host, "Hosting sets is_host flag")
	_check(net.players.size() == 1, "Roster contains 1 player initially (the Host)")

	var host_id: int = net.multiplayer.get_unique_id()
	_check(net.players[host_id]["is_host"], "Host player marked is_host")
	_check(net.players[host_id]["role"] == "breaker", "Default host role is breaker")

	# 3. Role changing and ready toggling
	net.set_player_role(host_id, "scout")
	_check(net.players[host_id]["role"] == "scout", "Role changes to scout")

	_check(net.are_all_players_ready(), "Single host player starts ready")
	net.set_player_ready(host_id, false)
	_check(not net.are_all_players_ready(), "Toggling ready to false makes are_all_players_ready false")
	net.set_player_ready(host_id, true)

	# 4. 2-player Hybrid Mode check
	_check(not net.is_hybrid_mode_active(), "1 player is not hybrid mode")
	net.players[2] = {"name": "Operatör 2", "role": "lock", "ready": true, "is_host": false}
	_check(net.is_hybrid_mode_active(), "Exactly 2 players activates 2-player hybrid mode")

	# 3 players restores standard roles
	net.players[3] = {"name": "Operatör 3", "role": "carrier", "ready": true, "is_host": false}
	_check(not net.is_hybrid_mode_active(), "3 players returns to standard individual roles")

	# 5. Disconnect cleanup
	net.disconnect_game()
	_check(net.players.is_empty(), "Disconnect clears players roster")
	_check(net.current_room_code.is_empty() and not net.is_host, "Disconnect resets host and code")

	# 6. MainMenu UI Screen Transitions
	var menu = MenuScript.new()
	root.add_child(menu)
	await process_frame

	_check(menu._screen_landing.visible, "Menu starts on Landing screen")
	_check(not menu._screen_lobby.visible, "Lobby screen initially hidden")

	menu._show_screen(menu._screen_join)
	_check(menu._screen_join.visible and not menu._screen_landing.visible, "Transitions to Join screen")

	menu._show_screen(menu._screen_settings)
	_check(menu._screen_settings.visible and not menu._screen_join.visible, "Transitions to Settings screen")

	menu._show_screen(menu._screen_landing)
	_check(menu._screen_landing.visible, "Returns to Landing screen")

	menu.queue_free()
	net.queue_free()
	await process_frame

	print("Lobby & Network tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
