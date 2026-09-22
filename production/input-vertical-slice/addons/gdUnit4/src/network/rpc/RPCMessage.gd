class_name RPCMessage
extends RPC

var _message: String


static func of(msg :String) -> RPCMessage:
	var rpc := RPCMessage.new()
	rpc._message = msg
	return rpc


func message() -> String:
	return _message


func _to_string() -> String:
	return "RPCMessage: " + _message
