@tool
extends Node

var _client_id: int

@onready var _server: GdUnitTcpServer = $TcpServer


@warning_ignore("return_value_discarded")
func _ready() -> void:
	var result := _server.start()
	if result.is_error():
		push_error(result.error_message())
		return
	var server_port :int = result.value()
	Engine.set_meta("gdunit_server_port", server_port)
	_server.client_connected.connect(_on_client_connected)
	_server.client_disconnected.connect(_on_client_disconnected)
	_server.rpc_data.connect(_receive_rpc_data)


func _on_client_connected(client_id: int) -> void:
	_client_id = client_id
	GdUnitSignals.instance().gdunit_client_connected.emit(client_id)


func _on_client_disconnected(client_id: int) -> void:
	GdUnitSignals.instance().gdunit_client_disconnected.emit(client_id)


func _receive_rpc_data(p_rpc: RPC) -> void:
	if p_rpc is RPCMessage:
		var rpc_message: RPCMessage = p_rpc
		GdUnitSignals.instance().gdunit_message.emit(rpc_message.message())
		return
	if p_rpc is RPCGdUnitEvent:
		var rpc_event: RPCGdUnitEvent = p_rpc
		var event := rpc_event.event()
		GdUnitSignals.instance().gdunit_event.emit(event)
		if event.type() == GdUnitEvent.SESSION_CLOSE and _server != null:
			_server.disconnect_client(_client_id)
