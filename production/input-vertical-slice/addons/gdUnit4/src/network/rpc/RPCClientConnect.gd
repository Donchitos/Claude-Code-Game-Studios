class_name RPCClientConnect
extends RPC

var _client_id: int


func with_id(id: int) -> RPCClientConnect:
	_client_id = id
	return self


func client_id() -> int:
	return _client_id
