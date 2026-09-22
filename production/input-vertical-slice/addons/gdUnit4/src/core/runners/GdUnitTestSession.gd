##
## @since GdUnit4 5.1.0
##
## Represents a test execution session in GdUnit4.[br]
## [br]
## [i]A test session encapsulates a complete test execution cycle, managing the collection
## of test cases to be executed and providing communication channels for test events
## and messages. This class serves as the central coordination point for test execution
## and allows hooks and other components to interact with the running test session.[/i][br]
## [br]
## [b][u]Key Features[/u][/b][br]
## - [i][b]Test Case Management[/b][/i]: Maintains a collection of test cases to be executed[br]
## - [i][b]Event Broadcasting[/b][/i]: Forwards GdUnit events to session-specific listeners[br]
## - [i][b]Message Communication[/b][/i]: Provides a channel for sending messages during test execution[br]
## - [i][b]Hook Integration[/b][/i]: Passed to test session hooks for startup and shutdown operations[br]
## [br]
## [b][u]Usage in Test Hooks[/u][/b]
## [codeblock]
## func startup(session: GdUnitTestSession) -> GdUnitResult:
##     # Access test cases
##     print("Running %d test cases" % session.test_cases.size())
##
##     # Send status messages
##     session.send_message("Custom hook initialized")
##
##     # Listen for test events
##     session.test_event.connect(_on_test_event)
##
##     return GdUnitResult.success()
##
## func _on_test_event(event: GdUnitEvent) -> void:
##     print("Test event received: %s" % event.type)
## [/codeblock]
## [br]
## [b][u]Event Flow[/u][/b][br]
## 1. Session is created with a collection of test cases[br]
## 2. Session connects to the global GdUnit event system[br]
## 3. During test execution, events are automatically forwarded to session listeners[br]
## 4. Hooks and other components can subscribe to session events[br]
## 5. Messages can be sent through the session for logging and communication[br]
class_name GdUnitTestSession
extends RefCounted


## Emitted when a test execution event occurs.[br]
## [br]
## [i]This signal forwards events from the global GdUnit event system to session-specific
## listeners. It allows hooks and other session components to react to test events
## without directly connecting to the global event system.[/i][br]
## [br]
## [u]Common event types include:[/u][br]
## - Test suite start/end events[br]
## - Test case start/end events[br]
## - Test assertion events[br]
## - Test failure/error events[br]
##
## [param event] The test event containing details about test execution, timing, and results
@warning_ignore("unused_signal")
signal test_event(event: GdUnitEvent)


## [b][color=red]@readonly: Should not be modified directly during test execution![/color][/b][br]
## Collection of test cases to be executed in this session.[br]
## [br]
## This array contains all the test cases that will be run during the session.
## Test hooks can access this collection to:
## - Get the total number of tests to be executed
## - Access individual test case metadata
## - Perform setup/teardown based on test case requirements
## - Generate reports or statistics about the test suite
##
## The collection is typically populated before session startup and remains
## constant during test execution.
var _test_cases : Array[GdUnitTestCase] = []


## [b][color=red]@readonly: The report path should not be modified after session creation![/color][/b][br]
## The file system path where test reports for this session will be generated.[br]
## [br]
## [i]This property provides centralized access to the report output location,
## allowing test hooks, reporters, and other components to reference the same
## report path without coupling to specific reporter implementations.[/i][br]
## [br]
## [b][u]Common use cases include:[/u][/b][br]
## - Test hooks generating additional report files in the same directory[br]
## - Custom reporters creating supplementary output files[br]
## - Post-processing scripts that need to locate generated reports[br]
## - Cleanup operations that need to manage report artifacts[br]
## [br]
## [b][u]Example Usage:[/u][/b]
## [codeblock]
## # In a test hook
## func startup(session: GdUnitTestSession) -> GdUnitResult:
##     var report_dir = session.report_path.get_base_dir()
##     var custom_report = report_dir.path_join("custom_metrics.json")
##     # Generate additional reports in the same location
##     return GdUnitResult.success()
##
## func shutdown(session: GdUnitTestSession) -> GdUnitResult:
##     session.send_message("Reports available at: " + session.report_path)
##     return GdUnitResult.success()
## [/codeblock]
## [br]
## The path is set during session initialization and remains constant throughout
## the test execution lifecycle.
var report_path: String:
	get:
		return report_path


## Initializes the test session and sets up event forwarding.[br]
## [br]
## [i]This constructor automatically connects to the global GdUnit event system
## and forwards all events to the session's test_event signal. This allows
## session-specific components to listen for test events without managing
## global signal connections.[/i]
func _init(test_cases: Array[GdUnitTestCase], session_report_path: String) -> void:
	# We build a copy to prevent a user is modifing the tests
	_test_cases = test_cases.duplicate(true)
	report_path = session_report_path
	GdUnitSignals.instance().gdunit_event.connect(func(event: GdUnitEvent) -> void:
		test_event.emit(event)
	)


## Finds a test case by its unique identifier.[br]
## [br]
## [i]Searches through all test cases to find a test with the matching GUID.[/i][br]
## [br]
## [param id] The GUID of the test to find[br]
## Returns the matching test case or null if not found.
func find_test_by_id(id: GdUnitGUID) -> GdUnitTestCase:
	for test in _test_cases:
		if test.guid.equals(id):
			return test

	return null


## Sends a message through the GdUnit messaging system.[br]
## [br]
## [i]This method provides a convenient way for test hooks and other session
## components to send messages that will be handled by the GdUnit framework.[/i]
## [br][br]
## [b][u]Messages are typically used for:[/u][/b][br]
## - Status updates during test execution[br]
## - Progress reporting from test hooks[br]
## - Debug information and logging[br]
## - User notifications and alerts[br]
## [br]
## The message will be processed by the global GdUnit message system and
## may be displayed in the test runner UI, logged to files, or handled
## by other registered message handlers.
## [br]
## [b][u]Example Usage:[/u][/b]
## [codeblock]
## # In a test hook
## func startup(session: GdUnitTestSession) -> GdUnitResult:
##     session.send_message("Database connection established")
##     return GdUnitResult.success()
##
## func shutdown(session: GdUnitTestSession) -> GdUnitResult:
##     session.send_message("Generated test report: report.html")
##     return GdUnitResult.success()
## ```
## [/codeblock]
## [param message] The message text to send through the GdUnit messaging system
func send_message(message: String) -> void:
	GdUnitSignals.instance().gdunit_message.emit(message)
