# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name GdUnitAwaiterTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/GdUnitAwaiter.gd'

signal test_signal_a()
signal test_signal_b()
signal test_signal_c(value :String)


func after_test() -> void:
	for node in (Engine.get_main_loop() as SceneTree).root.get_children():
		if node is Timer and node.is_in_group("test_signal_emitter"):
			@warning_ignore("unsafe_method_access")
			node.stop()
			node.queue_free()


func install_signal_emitter(signal_name: Signal, signal_args: Array = [], time_ms := 20) -> void:
	var timer := Timer.new()
	timer.add_to_group("test_signal_emitter")
	(Engine.get_main_loop() as SceneTree).root.add_child(timer)
	timer.timeout.connect(emit_test_signal.bind(signal_name.get_name(), signal_args))
	timer.one_shot = true
	timer.start(time_ms * 0.001 * Engine.get_time_scale())


func emit_test_signal(signal_name: String, signal_args: Array) -> void:
	match signal_args.size():
		0: emit_signal(signal_name)
		1: emit_signal(signal_name, signal_args[0])
		2: emit_signal(signal_name, signal_args[0], signal_args[1])
		3: emit_signal(signal_name, signal_args[0], signal_args[1], signal_args[2])


func test_await_signal_on() -> void:
	install_signal_emitter(test_signal_a)
	await await_signal_on(self, "test_signal_a", [], 100)

	install_signal_emitter(test_signal_b)
	await await_signal_on(self, "test_signal_b", [], 100)

	install_signal_emitter(test_signal_c)
	await await_signal_on(self, "test_signal_c", [], 100)

	install_signal_emitter(test_signal_c, ["abc"])
	await await_signal_on(self, "test_signal_c", ["abc"], 100)

	install_signal_emitter(test_signal_c, ["abc", "eee"])
	await await_signal_on(self, "test_signal_c", ["abc", "eee"], 100)


func test_await_signal_on_manysignals_emitted() -> void:
	# emits many different signals
	install_signal_emitter(test_signal_a)
	install_signal_emitter(test_signal_a)
	install_signal_emitter(test_signal_a)
	install_signal_emitter(test_signal_c, ["xxx"])
	# the signal we want to wait for
	install_signal_emitter(test_signal_c, ["abc"], 200)
	install_signal_emitter(test_signal_c, ["yyy"], 100)
	# we only wait for 'test_signal_c("abc")' is emitted
	await await_signal_on(self, test_signal_c.get_name(), ["abc"], 300)


func test_await_signal_on_never_emitted_timedout() -> void:
	(
		# we  wait for 'test_signal_c("yyy")' which  is never emitted
		await assert_failure_await(func x() -> void: await await_signal_on(self, "test_signal_c", ["yyy"], 200))
	).has_line(73)\
		.has_message("await_signal_on(test_signal_c, [\"yyy\"]) timed out after 200ms")


func test_await_signal_on_invalid_source_timedout() -> void:
	(
		# we  wait for a signal on a already freed instance
		await assert_failure_await(func x() -> void: await await_signal_on(invalid_node(), "tree_entered", [], 300))
	).has_line(81)\
		.has_message(GdAssertMessages.error_await_signal_on_invalid_instance(null, "tree_entered", []))


func invalid_node() -> Node:
	return null
