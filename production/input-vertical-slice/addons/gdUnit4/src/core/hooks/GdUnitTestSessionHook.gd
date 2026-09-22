## @since GdUnit4 5.1.0
##
## Base class for creating custom test session hooks in GdUnit4.[br]
## [br]
## [i]Test session hooks allow users to extend the GdUnit4 test framework by providing
## custom functionality that runs at specific points during the test execution lifecycle.
## This base class defines the interface that all test session hooks must implement.[/i]
## [br]
## [br]
## [b][u]Usage[/u][/b][br]
## 1. Create a new class that extends GdUnitTestSessionHook[br]
## 2. Override the required methods (startup, shutdown)[br]
## 3. Register your hook with the test engine (using the GdUnit4 settings dialog)[br]
## [br]
## [b][u]Example[/u][/b]
## [codeblock]
## class_name MyCustomTestHook
## extends GdUnitTestSessionHook
##
## func _init():
##     super("MyHook", "This is a description")
##
## func startup(session: GdUnitTestSession) -> GdUnitResult:
##     session.send_message("Custom hook initialized")
##     # Initialize resources, setup test environment, etc.
##     return GdUnitResult.success()
##
## func shutdown(session: GdUnitTestSession) -> GdUnitResult:
##     session.send_message("Custom hook cleanup completed")
##     # Cleanup resources, generate reports, etc.
##     return GdUnitResult.success()
## [/codeblock]
##
## [b][u]Hook Lifecycle[/u][/b][br]
## 1. [i][b]Registration[/b][/i]: Hooks are registered with the test engine via settings dialog[br]
## 2. [i][b]Priority Sorting[/b][/i]: Hooks are sorted by priority[br]
## 3. [i][b]Startup[/b][/i]: startup() is called before test execution begins, if it returns an error is shown in the console[br]
## 4. [i][b]Test Execution[/b][/i]: Tests run normally (only if all hooks started successfully)[br]
## 5. [i][b]Shutdown[/b][/i]: shutdown() is called after all tests complete, regardless of startup success[br]
## [br]
## [b][u]Priority System[/u][/b][br]
## The priority system allows controlling the execution order of multiple hooks.[br]
## - The order can be changed in the GdUnit4 settings dialog.[br]
## - The priority of system hooks cannot be changed and they cannot be deleted.[br]
## [br]
## [b][u]Session Access[/u][/b][br]
##
## Both [i]startup()[/i] and [i]shutdown()[/i] methods receive a [GdUnitTestSession] parameter that provides:[br]
## - Access to test cases being executed[br]
## - Event emission capabilities for test progress tracking[br]
## - Message sending functionality for logging and communication[br]
class_name GdUnitTestSessionHook
extends RefCounted


## The display name of this hook.
var name: String:
	get:
		return name


## A detailed description of what this hook does.
var description: String:
	get:
		return description


## Initializes a new test session hook.
##
## [param _name] The display name for this hook
## [param _description] A detailed description of the hook's functionality
func _init(_name: String, _description: String) -> void:
	self.name = _name
	self.description = _description


## Called when the test session starts up, before any tests are executed.[br]
## [br]
## [color=yellow][i]This method should be overridden to implement custom initialization logic[/i][/color][br]
## [br]
## such as:[br]
## - Setting up test databases or external services[br]
## - Initializing mock objects or test fixtures[br]
## - Configuring logging or reporting systems[br]
## - Preparing the test environment[br]
## - Subscribing to test events via the session[br]
## [br]
## [param session] The test session instance providing access to test data and communication[br]
## [b]return:[/b] [code]GdUnitResult.success()[/code] if initialization succeeds, or [code]GdUnitResult.error("error")[/code] with
##         an error message if initialization fails.
func startup(_session: GdUnitTestSession) -> GdUnitResult:
	return GdUnitResult.error("%s:startup is not implemented" % get_script().resource_path)


## Called when the test session shuts down, after all tests have completed.[br]
## [br]
## [color=yellow][i]This method should be overridden to implement custom cleanup logic[/i][/color][br]
## [br]
## such as:[br]
## - Cleaning up test databases or external services[br]
## - Generating test reports or artifacts[br]
## - Releasing resources allocated during startup[br]
## - Performing final validation or assertions[br]
## - Processing collected test events and data[br]
## [br]
## [param session] The test session instance providing access to test results and communication[br]
## [b]return:[/b] [code]GdUnitResult.success()[/code] if cleanup succeeds, or [code]GdUnitResult.error("error")[/code] with
##         an error message if cleanup fails. Cleanup errors are typically logged
##         but don't prevent the test engine from shutting down.
func shutdown(_session: GdUnitTestSession) -> GdUnitResult:
	return GdUnitResult.error("%s:shutdown is not implemented" % get_script().resource_path)
