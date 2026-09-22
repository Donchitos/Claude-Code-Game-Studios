## A static utility class that acts as a central sink for test case discovery events in GdUnit4.
## Instead of implementing custom sink classes, test discovery consumers should connect to
## the GdUnitSignals.gdunit_test_discovered signal to receive test case discoveries.
## This design allows for a more flexible and decoupled test discovery system.
class_name GdUnitTestDiscoverSink
extends RefCounted


## Emits a discovered test case through the GdUnitSignals system.[br]
## Sends the test case to all listeners connected to the gdunit_test_discovered signal.[br]
## [member test_case] The discovered test case to be broadcast to all connected listeners.
static func discover(test_case: GdUnitTestCase) -> void:
	GdUnitSignals.instance().gdunit_test_discover_added.emit(test_case)
