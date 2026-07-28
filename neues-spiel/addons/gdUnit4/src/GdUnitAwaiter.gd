class_name GdUnitAwaiter
extends RefCounted


# Waits for a specified signal in an interval of 50ms sent from the <source>, and terminates with an error after the specified timeout has elapsed.
# source: the object from which the signal is emitted
# signal_name: signal name
# args: the expected signal arguments as an array
# timeout: the timeout in ms, default is set to 2000ms
func await_signal_on(source :Object, signal_name :String, args :Array = [], timeout_millis :int = 2000) -> Variant:
	# fail fast if the given source instance invalid
	var assert_that := GdUnitAssertImpl.new(signal_name)
	var line_number := GdUnitAssertions.get_line_number()
	if not is_instance_valid(source):
		@warning_ignore("return_value_discarded")
		assert_that.report_error(GdAssertMessages.error_await_signal_on_invalid_instance(source, signal_name, args), line_number)
		return await (Engine.get_main_loop() as SceneTree).process_frame
	# fail fast if the given source instance invalid
	if not is_instance_valid(source):
		@warning_ignore("return_value_discarded")
		assert_that.report_error(GdAssertMessages.error_await_signal_on_invalid_instance(source, signal_name, args), line_number)
		return await await_idle_frame()
	var awaiter := GdUnitSignalAwaiter.new(timeout_millis)
	var value :Variant = await awaiter.on_signal(source, signal_name, args)
	if awaiter.is_interrupted():
		var failure := "await_signal_on(%s, %s) timed out after %sms" % [signal_name, args, timeout_millis]
		@warning_ignore("return_value_discarded")
		assert_that.report_error(failure, line_number)
	return value


# Waits for a specified signal sent from the <source> between idle frames and aborts with an error after the specified timeout has elapsed
# source: the object from which the signal is emitted
# signal_name: signal name
# args: the expected signal arguments as an array
# timeout: the timeout in ms, default is set to 2000ms
func await_signal_idle_frames(source :Object, signal_name :String, args :Array = [], timeout_millis :int = 2000) -> Variant:
	var line_number := GdUnitAssertions.get_line_number()
	# fail fast if the given source instance invalid
	if not is_instance_valid(source):
		@warning_ignore("return_value_discarded")
		GdUnitAssertImpl.new(signal_name)\
			.report_error(GdAssertMessages.error_await_signal_on_invalid_instance(source, signal_name, args), line_number)
		return await await_idle_frame()
	var awaiter := GdUnitSignalAwaiter.new(timeout_millis, true)
	var value :Variant = await awaiter.on_signal(source, signal_name, args)
	if awaiter.is_interrupted():
		var failure := "await_signal_idle_frames(%s, %s) timed out after %sms" % [signal_name, args, timeout_millis]
		@warning_ignore("return_value_discarded")
		GdUnitAssertImpl.new(signal_name).report_error(failure, line_number)
	return value


# Waits for for a given amount of milliseconds
# example:
#    # waits for 100ms
#    await GdUnitAwaiter.await_millis(myNode, 100).completed
# use this waiter and not `await get_tree().create_timer().timeout to prevent errors when a test case is timed out
func await_millis(milliSec :int) -> void:
	var timer :Timer = Timer.new()
	timer.set_name("gdunit_await_millis_timer_%d" % timer.get_instance_id())
	(Engine.get_main_loop() as SceneTree).root.add_child(timer)
	timer.add_to_group("GdUnitTimers")
	timer.set_one_shot(true)
	timer.start(milliSec / 1000.0)
	await timer.timeout
	timer.queue_free()


# Waits until the next idle frame
func await_idle_frame() -> void:
	await (Engine.get_main_loop() as SceneTree).process_frame
