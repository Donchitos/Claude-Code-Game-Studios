@tool
class_name GdUnitTcpClient
extends GdUnitTcpNode

signal connection_succeeded(message: String)
signal connection_failed(message: String)


var _client_name: String
var _debug := false
var _host: String
var _port: int
var _client_id: int
var _connected: bool
var _stream: StreamPeerTCP


func _init(client_name := "GdUnit4 TCP Client", debug := false) -> void:
	_client_name = client_name
	_debug = debug


func _ready() -> void:
	_connected = false
	_stream = StreamPeerTCP.new()
	#_stream.set_big_endian(true)


func stop() -> void:
	console("Disconnecting from server")
	if _stream != null:
		rpc_send(_stream, RPCClientDisconnect.new().with_id(_client_id))
	if _stream != null:
		_stream.disconnect_from_host()
	_connected = false


func start(host: String, port: int) -> GdUnitResult:
	_host = host
	_port = port
	if _connected:
		return GdUnitResult.warn("Client already connected ... %s:%d" % [_host, _port])

	# Connect client to server
	if _stream.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		var err := _stream.connect_to_host(host, port)
		#prints("connect_to_host", host, port, err)
		if err != OK:
			return GdUnitResult.error("GdUnit4: Can't establish client, error code: %s" % err)
	return GdUnitResult.success("GdUnit4: Client connected checked port %d" % port)


func _process(_delta: float) -> void:
	match _stream.get_status():
		StreamPeerTCP.STATUS_NONE:
			return

		StreamPeerTCP.STATUS_CONNECTING:
			set_process(false)
			# wait until client is connected to server
			for retry in 10:
				@warning_ignore("return_value_discarded")
				_stream.poll()
				console("Waiting to connect ..")
				if _stream.get_status() == StreamPeerTCP.STATUS_CONNECTING:
					await get_tree().create_timer(0.500).timeout
				if _stream.get_status() == StreamPeerTCP.STATUS_CONNECTED:
					set_process(true)
					return
			set_process(true)
			_stream.disconnect_from_host()
			console("Connection failed")
			connection_failed.emit("Connect to TCP Server %s:%d faild!" % [_host, _port])

		StreamPeerTCP.STATUS_CONNECTED:
			if not _connected:
				var rpc_data :RPC = null
				set_process(false)
				while rpc_data == null:
					await get_tree().create_timer(0.500).timeout
					rpc_data = rpc_receive()
				set_process(true)
				_client_id = (rpc_data as RPCClientConnect).client_id()
				console("Connected to Server: %d" % _client_id)
				connection_succeeded.emit("Connect to TCP Server %s:%d success." % [_host, _port])
				_connected = true
			process_rpc()

		StreamPeerTCP.STATUS_ERROR:
			console("Connection failed")
			_stream.disconnect_from_host()
			connection_failed.emit("Connect to TCP Server %s:%d faild!" % [_host, _port])
			return


func is_client_connected() -> bool:
	return _connected


func process_rpc() -> void:
	if _stream.get_available_bytes() > 0:
		var rpc_data := rpc_receive()
		if rpc_data is RPCClientDisconnect:
			console("RPCClientDisconnect")
			GdUnitSignals.instance().gdunit_test_session_terminate.emit.call_deferred()


func send(data: RPC) -> void:
	rpc_send(_stream, data)


func rpc_receive() -> RPC:
	return receive_packages(_stream).front()


func console(value: Variant) -> void:
	if _debug:
		print(_client_name, ":	", value)


func _on_connection_failed(message: String) -> void:
	console("Connection faild by: " + message)


func _on_connection_succeeded(message: String) -> void:
	console("Connected: " + message)
