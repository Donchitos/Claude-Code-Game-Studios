@tool
extends Node

signal request_completed(response: HttpResponse)

class HttpResponse:
	var _http_status: int
	var _body: PackedByteArray


	func _init(http_status: int, body: PackedByteArray) -> void:
		_http_status = http_status
		_body = body


	func status() -> int:
		return _http_status


	func response() -> Variant:
		if _http_status != 200:
			return _body.get_string_from_utf8()

		var test_json_conv := JSON.new()
		@warning_ignore("return_value_discarded")
		var error := test_json_conv.parse(_body.get_string_from_utf8())
		if error != OK:
			return "HttpResponse: %s Error: %s" % [error_string(error), _body.get_string_from_utf8()]
		return test_json_conv.get_data()

	func get_body() -> PackedByteArray:
		return _body


var _http_request := HTTPRequest.new()


func _ready() -> void:
	add_child(_http_request)
	@warning_ignore("return_value_discarded")
	_http_request.request_completed.connect(_on_request_completed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_http_request):
			_http_request.queue_free()


#func list_tags() -> void:
#	_http_request.connect("request_completed",Callable(self,"_response_request_tags"))
#	var error = _http_request.request("https://api.github.com/repos/MikeSchulze/gdUnit4/tags")
#	if error != OK:
#		push_error("An error occurred in the HTTP request.")


func request_latest_version() -> HttpResponse:
	var error := _http_request.request("https://api.github.com/repos/MikeSchulze/gdUnit4/tags")
	if error != OK:
		var message := "Request latest version failed, %s" % error_string(error)
		return HttpResponse.new(error, message.to_utf8_buffer())
	return await self.request_completed


func request_releases() -> HttpResponse:
	var error := _http_request.request("https://api.github.com/repos/MikeSchulze/gdUnit4/releases")
	if error != OK:
		var message := "request_releases failed: %d" % error
		return HttpResponse.new(error, message.to_utf8_buffer())
	return await self.request_completed


func request_image(url: String) -> HttpResponse:
	var error := _http_request.request(url)
	if error != OK:
		var message := "request_image failed: %d" % error
		return HttpResponse.new(error, message.to_utf8_buffer())
	return await self.request_completed


func request_zip_package(url: String, file: String) -> HttpResponse:
	_http_request.set_download_file(file)
	var error := _http_request.request(url)
	if error != OK:
		var message := "request_zip_package failed: %d" % error
		return HttpResponse.new(error, message.to_utf8_buffer())
	return await self.request_completed


func extract_latest_version(response: HttpResponse) -> GdUnit4Version:
	var body: Array = response.response()
	return GdUnit4Version.parse(str(body[0]["name"]))


func _on_request_completed(_result: int, response_http_status: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_request.set_download_file("")
	request_completed.emit(HttpResponse.new(response_http_status, body))
