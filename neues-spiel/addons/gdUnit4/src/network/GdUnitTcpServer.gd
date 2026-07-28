@tool
class_name GdUnitTcpServer
extends Node

signal client_connected(client_id: int)
signal client_disconnected(client_id: int)
@warning_ignore("unused_signal")
signal rpc_data(rpc_data: RPC)

var _server: TCPServer
var _server_name: String

class TcpConnection extends GdUnitTcpNode:
	var _id: int
	var _stream: StreamPeerTCP


	func _init(tcp_server: TCPServer) -> void:
		_stream = tcp_server.take_connection()
		#_stream.set_big_endian(true)
		_id = _stream.get_instance_id()
		rpc_send(_stream, RPCClientConnect.new().with_id(_id))


	func _ready() -> void:
		server().client_connected.emit(_id)


	func close() -> void:
		if _stream != null and _stream.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			_stream.disconnect_from_host()
			queue_free()


	func id() -> int:
		return _id


	func server() -> GdUnitTcpServer:
		return get_parent()


	func _process(_delta: float) -> void:
		if _stream == null or _stream.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			return
		receive_packages(_stream, func(rpc_data: RPC) -> void:
			server().rpc_data.emit(rpc_data)
			# is client disconnecting we close the server after a timeout of 1 second
			if rpc_data is RPCClientDisconnect:
				close()
		)


	func disconnect_from_server() -> void:
		if _stream == null or _stream.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			return
		rpc_send(_stream, RPCClientDisconnect.new().with_id(_id))


	func console(_value: Variant) -> void:
		#print_debug("TCP Server:		", value)
		pass


func _init(server_name := "GdUnit4 TCP Server") -> void:
	_server_name = server_name
	GdUnitSignals.instance().gdunit_test_session_terminate.connect(func() -> void:
		for connection in get_children():
			if connection is TcpConnection:
				(connection as TcpConnection).disconnect_from_server()
	)


func _ready() -> void:
	_server = TCPServer.new()
	client_connected.connect(_on_client_connected)
	client_disconnected.connect(_on_client_disconnected)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		stop()


func start(server_port := GdUnitServerConstants.GD_TEST_SERVER_PORT) -> GdUnitResult:
	var err := OK
	for retry in GdUnitServerConstants.DEFAULT_SERVER_START_RETRY_TIMES:
		err = _server.listen(server_port, "127.0.0.1")
		if err != OK:
			prints("GdUnit4: Can't establish server checked port: %d, Error: %s" % [server_port, error_string(err)])
			server_port += 1
			prints("GdUnit4: Retry (%d) ..." % retry)
		else:
			break
	if err != OK:
		if err == ERR_ALREADY_IN_USE:
			return GdUnitResult.error("GdUnit4: Can't establish server, the server is already in use. Error: %s, " % error_string(err))
		return GdUnitResult.error("GdUnit4: Can't establish server. Error: %s." % error_string(err))
	console("Successfully started checked port: %d" % server_port)
	return GdUnitResult.success(server_port)


func stop() -> void:
	if _server:
		_server.stop()
	for connection in get_children():
		if connection is TcpConnection:
			@warning_ignore("unsafe_method_access")
			connection.close()
			remove_child(connection)
	_server = null


func disconnect_client(client_id: int) -> void:
	client_disconnected.emit(client_id)


func _process(_delta: float) -> void:
	if _server != null and not _server.is_listening():
		return
	# check if connection is ready to be used
	if _server != null and _server.is_connection_available():
		add_child(TcpConnection.new(_server))


func _on_client_connected(client_id: int) -> void:
	console("Client connected %d" % client_id)


func _on_client_disconnected(client_id: int) -> void:
	for connection in get_children():
		@warning_ignore("unsafe_method_access")
		if connection is TcpConnection and connection.id() == client_id:
			@warning_ignore("unsafe_method_access")
			connection.close()
			remove_child(connection)


func console(value: Variant) -> void:
	print(_server_name, ":	", value)
