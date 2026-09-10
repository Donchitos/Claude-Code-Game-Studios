class_name GdUnitSignals
extends RefCounted
## Singleton class that handles GdUnit's signal communication.[br]
## [br]
## This class manages all signals used to communicate test events, discovery, and status changes.[br]
## It uses a singleton pattern stored in Engine metadata to ensure a single instance.[br]
## [br]
## Signals are grouped by purpose:[br]
## - Client connection handling[br]
## - Test execution events[br]
## - Test discovery events[br]
## - Settings and status updates[br]
## [br]
## Example usage:[br]
## [codeblock]
## # Connect to test discovery
## GdUnitSignals.instance().gdunit_test_discovered.connect(self._on_test_discovered)
##
## # Emit test event
## GdUnitSignals.instance().gdunit_event.emit(test_event)
## [/codeblock]


## Emitted when a client connects to the GdUnit server.[br]
## [param client_id] The ID of the connected client.
@warning_ignore("unused_signal")
signal gdunit_client_connected(client_id: int)


## Emitted when a client disconnects from the GdUnit server.[br]
## [param client_id] The ID of the disconnected client.
@warning_ignore("unused_signal")
signal gdunit_client_disconnected(client_id: int)


## Emitted when a the user stops (terminates) the current test session
@warning_ignore("unused_signal")
signal gdunit_test_session_terminate()


## Emitted when a test execution event occurs.[br]
## [param event] The test event containing details about test execution.
@warning_ignore("unused_signal")
signal gdunit_event(event: GdUnitEvent)


## Emitted for test debug events during execution.[br]
## [param event] The debug event containing test execution details.
@warning_ignore("unused_signal")
signal gdunit_event_debug(event: GdUnitEvent)


## Emitted to broadcast a general message.[br]
## [param message] The message to broadcast.
@warning_ignore("unused_signal")
signal gdunit_message(message: String)


## Emitted to update test failure status.[br]
## [param is_failed] Whether the test has failed.
@warning_ignore("unused_signal")
signal gdunit_set_test_failed(is_failed: bool)


## Emitted when a GdUnit setting changes.[br]
## [param property] The property that was changed.
@warning_ignore("unused_signal")
signal gdunit_settings_changed(property: GdUnitProperty)

## Called when a new test case is discovered during the discovery process.
## Custom implementations should connect to this signal and store the discovered test case as needed.[br]
## [param test_case] The discovered test case instance to be processed.
@warning_ignore("unused_signal")
signal gdunit_test_discover_added(test_case: GdUnitTestCase)


## Emitted when a test case is deleted.[br]
## [param test_case] The test case that was deleted.
@warning_ignore("unused_signal")
signal gdunit_test_discover_deleted(test_case: GdUnitTestCase)


## Emitted when a test case is modified.[br]
## [param test_case] The test case that was modified.
@warning_ignore("unused_signal")
signal gdunit_test_discover_modified(test_case: GdUnitTestCase)


const META_KEY := "GdUnitSignals"


## Returns the singleton instance of GdUnitSignals.[br]
## Creates a new instance if none exists.[br]
## [br]
## Returns: The GdUnitSignals singleton instance.
static func instance() -> GdUnitSignals:
	if Engine.has_meta(META_KEY):
		return Engine.get_meta(META_KEY)
	var instance_ := GdUnitSignals.new()
	Engine.set_meta(META_KEY, instance_)
	return instance_


## Cleans up the singleton instance and disconnects all signals.[br]
## [br]
## Should be called when GdUnit is shutting down or needs to reset.[br]
## Ensures proper cleanup of signal connections and resources.
static func dispose() -> void:
	var signals := instance()
	# cleanup connected signals
	for signal_ in signals.get_signal_list():
		@warning_ignore("unsafe_cast")
		for connection in signals.get_signal_connection_list(signal_["name"] as StringName):
			var _signal: Signal = connection["signal"]
			var _callable: Callable = connection["callable"]
			_signal.disconnect(_callable)
	signals = null
	Engine.remove_meta(META_KEY)
