class_name GdUnitTcpNode
extends Node

## Maximum size of a single RPC payload. Godot's default of 64 KiB is too small for larger test
## events (e.g. reports with long stack traces), so it is raised here. Kept modest because
## `PacketPeerStream` allocates its buffers eagerly at this size, per connection.
const MAX_PACKET_SIZE := 2 * 1024 * 1024

# `PacketPeerStream` reassembles length-prefixed packets from a raw `StreamPeerTCP` byte stream,
# buffering partial reads across calls instead of assuming a full message always arrives at once.
var _packets := _new_packet_peer()


static func _new_packet_peer() -> PacketPeerStream:
	var packet_peer := PacketPeerStream.new()
	packet_peer.input_buffer_max_size = MAX_PACKET_SIZE
	packet_peer.output_buffer_max_size = MAX_PACKET_SIZE
	return packet_peer


func rpc_send(stream: StreamPeerTCP, data: RPC) -> void:
	_packets.stream_peer = stream
	var payload := data.serialize().to_utf16_buffer()
	var status_code := _packets.put_packet(payload)
	if status_code != OK:
		push_error("'rpc_send:' Can't put_packet(), error: %s" % error_string(status_code))


func receive_packages(stream: StreamPeerTCP, rpc_cb: Callable = noop) -> Array[RPC]:
	var received_packages: Array[RPC] = []
	if stream.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return received_packages

	_packets.stream_peer = stream
	while _packets.get_available_packet_count() > 0:
		var payload := _packets.get_packet()
		var status_code := _packets.get_packet_error()
		if status_code != OK:
			push_error("'receive_packages:' Can't get_packet(), error: %s" % error_string(status_code))
			continue

		var json := payload.get_string_from_utf16()
		if json.is_empty():
			push_warning("json is empty, can't process data")
			continue
		var data := RPC.deserialize(json)
		if data == null:
			continue
		received_packages.append(data)
		rpc_cb.call(data)
	return received_packages


static func noop(_rpc_data: RPC) -> void:
	pass
