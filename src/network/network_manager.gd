class_name NetworkManager
extends Node
## Central networking coordinator for Sector 9 using Godot 4.7 high-level multiplayer (ENet).
## Manages server creation, room codes, client joins, roster sync, and 2-player hybrid roles.

signal player_joined(peer_id: int, player_info: Dictionary)
signal player_left(peer_id: int)
signal roster_updated()
signal connection_succeeded()
signal connection_failed(reason: String)
signal game_started()

const DEFAULT_PORT: int = 9999
const MAX_PLAYERS: int = 4

var players: Dictionary = {} # { peer_id: { "name": String, "role": String, "ready": bool, "is_host": bool } }
var current_room_code: String = ""
var is_host: bool = false
var peer: ENetMultiplayerPeer


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


## Host a new lobby with a generated or custom 4-digit room code.
func host_game(port: int = DEFAULT_PORT, custom_code: String = "") -> String:
	disconnect_game()
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_PLAYERS)
	if error != OK:
		connection_failed.emit(tr("Sunucu oluşturulamadı: %d") % error)
		return ""

	multiplayer.multiplayer_peer = peer
	is_host = true

	if custom_code.is_empty():
		current_room_code = generate_room_code()
	else:
		current_room_code = custom_code

	var local_id: int = multiplayer.get_unique_id()
	players[local_id] = {
		"name": "Operatör 1 (Host)",
		"role": "breaker",
		"ready": true,
		"is_host": true
	}
	roster_updated.emit()
	return current_room_code


## Join an existing lobby at the specified IP address or localhost.
func join_game(address: String = "127.0.0.1", port: int = DEFAULT_PORT, _code: String = "") -> bool:
	disconnect_game()
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		connection_failed.emit(tr("Bağlantı kurulamadı: %d") % error)
		return false

	multiplayer.multiplayer_peer = peer
	is_host = false
	return true


func disconnect_game() -> void:
	if peer != null:
		peer.close()
		peer = null
	multiplayer.multiplayer_peer = null
	players.clear()
	current_room_code = ""
	is_host = false
	roster_updated.emit()


## Generate 4-digit room code (e.g. "S9-4821").
static func generate_room_code() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return "S9-%04d" % rng.randi_range(1000, 9999)


## Set player role selection and sync across network.
func set_player_role(peer_id: int, role_id: String) -> void:
	if not players.has(peer_id):
		return
	players[peer_id]["role"] = role_id
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		sync_roster.rpc(players)
	elif multiplayer.has_multiplayer_peer():
		request_role_change.rpc_id(1, role_id)
	roster_updated.emit()


## Toggle ready state for a player.
func set_player_ready(peer_id: int, is_ready: bool) -> void:
	if not players.has(peer_id):
		return
	players[peer_id]["ready"] = is_ready
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		sync_roster.rpc(players)
	elif multiplayer.has_multiplayer_peer():
		request_ready_toggle.rpc_id(1, is_ready)
	roster_updated.emit()


## Check if all connected players are ready to start.
func are_all_players_ready() -> bool:
	if players.is_empty():
		return false
	for p in players.values():
		if not p.get("ready", false):
			return false
	return true


## Check if 2-player hybrid roles should be enabled.
func is_hybrid_mode_active() -> bool:
	return players.size() == 2


## Host starts the game for all connected peers.
func start_mission() -> bool:
	if not is_host or not are_all_players_ready():
		return false
	start_game_rpc.rpc()
	return true


# -----------------------------------------------------------------------------
# RPC Sync Methods
# -----------------------------------------------------------------------------

@rpc("authority", "call_local", "reliable")
func sync_roster(synced_players: Dictionary) -> void:
	players = synced_players.duplicate(true)
	roster_updated.emit()


@rpc("any_peer", "call_local", "reliable")
func request_role_change(role_id: String) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()
	if players.has(sender_id):
		players[sender_id]["role"] = role_id
		sync_roster.rpc(players)


@rpc("any_peer", "call_local", "reliable")
func request_ready_toggle(is_ready: bool) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()
	if players.has(sender_id):
		players[sender_id]["ready"] = is_ready
		sync_roster.rpc(players)


@rpc("authority", "call_local", "reliable")
func start_game_rpc() -> void:
	game_started.emit()


# -----------------------------------------------------------------------------
# Network Callbacks
# -----------------------------------------------------------------------------

func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		var player_count: int = players.size() + 1
		players[id] = {
			"name": "Operatör %d" % player_count,
			"role": "scout",
			"ready": false,
			"is_host": false
		}
		sync_roster.rpc(players)
		player_joined.emit(id, players[id])


func _on_peer_disconnected(id: int) -> void:
	if players.has(id):
		players.erase(id)
		if multiplayer.is_server():
			sync_roster.rpc(players)
		player_left.emit(id)


func _on_connected_to_server() -> void:
	connection_succeeded.emit()


func _on_connection_failed() -> void:
	connection_failed.emit(tr("Sunucuya bağlanılamadı."))


func _on_server_disconnected() -> void:
	disconnect_game()
