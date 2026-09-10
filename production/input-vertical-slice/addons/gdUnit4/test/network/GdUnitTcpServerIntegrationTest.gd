# GdUnit generated TestSuite
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/network/GdUnitTcpServer.gd'

var tcp_server: GdUnitTcpServer
var tcp_client: GdUnitTcpClient
var server_port: int


## We start a custom test server for this suite
func before() -> void:
	tcp_server = GdUnitTcpServer.new("Test TCP Server")
	tcp_client = GdUnitTcpClient.new("Test TCP Client", true)
	add_child(tcp_server)
	add_child(tcp_client)

	var result := tcp_server.start(62222)
	if not result.is_success():
		return

	server_port = result.value()
	tcp_client.start("127.0.0.1", server_port)

	# wait until the client is connected
	for n in 200:
		await await_idle_frame()
		if tcp_client.is_client_connected():
			break


## Shutdown the test server
func after() -> void:
	tcp_client.stop()
	tcp_client.queue_free()
	await await_idle_frame()
	tcp_server.stop()
	tcp_server.queue_free()
	await await_idle_frame()


@warning_ignore_start("redundant_await")
func test_receive_single_message(_timeout := 1000) -> void:
	monitor_signals(tcp_server, false)

	# send a single test message
	tcp_client.send(RPCMessage.of("Test Message"))

	# expect the RPCMessage is received and emitted
	await assert_signal(tcp_server).is_emitted("rpc_data", RPCMessage.of("Test Message"))


func test_receive_multy_message(_timeout := 1000) -> void:
	monitor_signals(tcp_server, false)

	# send a two test message
	tcp_client.send(RPCMessage.of("Test Message A"))
	tcp_client.send(RPCMessage.of("Test Message B"))

	# expect the RPCMessage is received and emitted
	await assert_signal(tcp_server).is_emitted("rpc_data", RPCMessage.of("Test Message A"))
	await assert_signal(tcp_server).is_emitted("rpc_data", RPCMessage.of("Test Message B"))


## Reproduces GD-1288: a TCP message rarely arrives in one piece, it is split across several
## reads. `receive_packages()` does not reassemble those pieces, so a split message corrupts
## the whole stream: the parser loses track of where the next frame starts, and every message
## after the split fails to deserialize.
func test_receive_message_split_across_polls(_timeout := 1000) -> void:
	monitor_signals(tcp_server, false)

	# connect directly with a raw socket so the test controls exactly how many bytes are sent
	# on each write, instead of `GdUnitTcpClient` sending the whole message in one go
	var raw := StreamPeerTCP.new()
	assert_int(raw.connect_to_host("127.0.0.1", server_port)).is_equal(OK)
	for n in 200:
		@warning_ignore("return_value_discarded")
		raw.poll()
		if raw.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			break
		await await_idle_frame()

	var message := RPCMessage.of("A long Message used to simmulate splitted tcp stream")

	# build the real wire bytes `GdUnitTcpNode.rpc_send()` would produce, by encoding the same
	# packet through a `PacketPeerStream` into an in-memory buffer instead of a socket
	var encoded := StreamPeerBuffer.new()
	var encoder := PacketPeerStream.new()
	encoder.stream_peer = encoded
	var _put_error := encoder.put_packet(message.serialize().to_utf16_buffer())
	var frame := encoded.data_array

	# send those bytes 16 at a time, one idle frame apart, so the frame arrives split across
	# multiple socket reads instead of all at once
	var frame_size := frame.size()
	var frame_offset := 0
	while frame_size > 0:
		var _e := raw.put_data(frame.slice(frame_offset, frame_offset + mini(16, frame_size)))
		await await_idle_frame()
		frame_size -= 16
		frame_offset += 16

	# the message should still arrive correctly once fully sent - fails on master because the
	# split desynced the stream and the message never gets reassembled
	await assert_signal(tcp_server).is_emitted("rpc_data", message)
	raw.disconnect_from_host()

@warning_ignore_restore("redundant_await")
