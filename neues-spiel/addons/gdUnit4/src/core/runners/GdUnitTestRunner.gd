@tool
extends "res://addons/gdUnit4/src/core/runners/GdUnitTestSessionRunner.gd"
## Runner implementation used by the editor UI.[br]
## [br]
## This runner connects to a GdUnit server via TCP to report test results.[br]
## Test results are reported in real-time and displayed in the editor UI.[br]
## [br]
## The runner uses an RPC message protocol to communicate status and events:[br]
## - Messages to report progress[br]
## - Events to report test results[br]

## The TCP client used to connect to the GdUnit server
@onready var _client: GdUnitTcpClient = $GdUnitTcpClient
@onready var _version_label: Control = %Version


func _init() -> void:
	super()
	# We set the default max report history to 1
	max_report_history = 1


func _ready() -> void:
	super()
	GdUnit4Version.init_version_label(_version_label)

	var config_result := _runner_config.load_config()
	if config_result.is_error():
		push_error(config_result.error_message())
		_state = EXIT
		return
	@warning_ignore("return_value_discarded")
	_client.connection_failed.connect(_on_connection_failed)
	GdUnitSignals.instance().gdunit_message.connect(_on_send_message)
	_executor.fail_fast(_runner_config.is_fail_fast())
	var result := _client.start("127.0.0.1", _runner_config.server_port())
	if result.is_error():
		push_error(result.error_message())
		return


## Cleanup and quit the runner.[br]
## [br]
## [param code] The exit code to return.
func quit(code: int) -> void:
	if code != RETURN_SUCCESS:
		_state = EXIT
	await GdUnitMemoryObserver.gc_on_guarded_instances()
	await super.quit(code)


## Called when the TCP connection to the GdUnit server fails.[br]
## Stops the test execution.[br]
## [br]
## [param message] The error message describing the failure.
func _on_connection_failed(message: String) -> void:
	prints("_on_connection_failed", message)
	_state = STOP


## Initializes the test runner.[br]
## Waits for TCP client connection and then scans for test suites.[br]
## Reports the number of found test suites via TCP message.
func init_runner() -> void:
	# wait until client is connected to the GdUnitServer
	if _client.is_client_connected():
		await gdUnitInit()
		_state = RUN


## Initializes the GdUnit framework.[br]
## Sends initial message about number of test suites.
func gdUnitInit() -> void:
	#enable_manuall_polling()
	_test_cases = _runner_config.test_cases()
	await get_tree().process_frame


## Sends a message via TCP to the GdUnit server.[br]
## [br]
## [param message] The message to send.
func _on_send_message(message: String) -> void:
	_client.send(RPCMessage.of(message))


## Handles GdUnit events by sending them via TCP to the server.[br]
## [br]
## [param event] The event to send.
func _on_gdunit_event(event: GdUnitEvent) -> void:
	_client.send(RPCGdUnitEvent.of(event))
