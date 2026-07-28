class_name GdUnitTcpNode
extends Node


func rpc_send(stream: StreamPeerTCP, data: RPC) -> void:
	var package_buffer := StreamPeerBuffer.new()
	var buffer := data.serialize().to_utf16_buffer()
	package_buffer.put_u32(0xDEADBEEF)
	package_buffer.put_u32(buffer.size())
	var status_code := package_buffer.put_data(buffer)
	if status_code != OK:
		push_error("'rpc_send:' Can't put_data(), error: %s" % error_string(status_code))
		return
	stream.put_data(package_buffer.data_array)


func receive_packages(stream: StreamPeerTCP, rpc_cb: Callable = noop) -> Array[RPC]:
	var received_packages: Array[RPC] = []
	var package_buffer := StreamPeerBuffer.new()
	if stream.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return received_packages

	while stream.get_status() == StreamPeerTCP.STATUS_CONNECTED and stream.get_available_bytes() > 0:
		var buffer := stream.get_data(8)
		var status_code: int = buffer[0]
		if status_code != OK:
			push_error("'receive_packages:' Can't get_data(%d) for available_bytes, error: %s"
				% [stream.get_available_bytes(), error_string(status_code)])
			return received_packages

		var data_package: PackedByteArray
		package_buffer.data_array = buffer[1]
		package_buffer.seek(0)

		if package_buffer.get_u32() == 0xDEADBEEF:
			var size := package_buffer.get_u32()
			if stream.get_status() != StreamPeerTCP.STATUS_CONNECTED:
				return received_packages
			if stream.get_available_bytes() < size:
				prints("size check:",
					package_buffer.get_size(), ":",
					package_buffer.get_position(),
					"to read:",
					size,
					"available size:",
					stream.get_available_bytes())
				push_error("'receive_packages:' Can't receive data get_data(%d) for package, error: %s" % [size, error_string(status_code)])
				return received_packages

			buffer = stream.get_data(size)
			package_buffer.data_array = buffer[1]

			var rpc_data := package_buffer.get_data(size)
			status_code = rpc_data[0]
			if status_code != OK:
				push_error("'receive_packages:' Can't get_data(%d) for package, error: %s" % [size, error_string(status_code)])
				continue
			data_package = rpc_data[1]
		else:
			data_package = buffer[1]

		var json := data_package.get_string_from_utf16()
		if json.is_empty():
			push_warning("json is empty, can't process data")
			continue
		var data := RPC.deserialize(json)
		received_packages.append(data)
		rpc_cb.call(data)
	return received_packages


static func noop(_rpc_data: RPC) -> void:
	pass
