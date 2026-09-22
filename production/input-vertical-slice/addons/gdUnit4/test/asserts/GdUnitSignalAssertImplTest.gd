@warning_ignore_start("redundant_await")
# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name GdUnitSignalAssertImplTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/asserts/GdUnitSignalAssertImpl.gd'
const GdUnitTools = preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")


class TestEmitter extends Node:
	signal test_signal_counted(value: int)
	signal test_signal(value: int)
	signal test_signal_without_value()
	signal test_signal_a(value: String)
	signal test_signal_arry_value(values: Array)
	@warning_ignore("unused_signal")
	signal test_signal_unused()

	var _trigger_count :int
	var _count := 0

	func _init(trigger_count := 10) -> void:
		_trigger_count = trigger_count

	func _process(_delta :float) -> void:
		if _count >= _trigger_count:
			test_signal_counted.emit(_count)

		if _count == 20:
			test_signal.emit(10)
			test_signal.emit(20)
			test_signal_a.emit("foo")
			test_signal_without_value.emit()
			test_signal_arry_value.emit(1, 2, 3)
		_count += 1

	func reset_trigger(trigger_count := 10) -> void:
		_trigger_count = trigger_count
		_count = 0


var signal_emitter: TestEmitter


func before_test() -> void:
	signal_emitter = auto_free(TestEmitter.new())
	add_child(signal_emitter)


func test_invalid_arg() -> void:
	(
		await assert_failure_await(func() -> void: await assert_signal(null).wait_until(50).is_emitted("test_signal_counted"))
	).has_message("Can't wait for signal checked a NULL object.")
	(
		await assert_failure_await(func() -> void: await assert_signal(null).wait_until(50).is_not_emitted("test_signal_counted"))
	).has_message("Can't wait for signal checked a NULL object.")


func test_unknown_signal() -> void:
	(
		await assert_failure_await(func() -> void: await assert_signal(signal_emitter).wait_until(50).is_emitted("unknown"))
	).has_message("Can't wait for non-existion signal 'unknown' checked object 'Node'.")


func test_signal_is_emitted_by_signal_name() -> void:
	await assert_signal(signal_emitter).is_emitted("test_signal_without_value")
	await assert_signal(signal_emitter).is_emitted("test_signal_counted", 20)


func test_signal_is_emitted_by_signal_type() -> void:
	await assert_signal(signal_emitter).is_emitted(signal_emitter.test_signal_without_value)
	await assert_signal(signal_emitter).is_emitted(signal_emitter.test_signal_counted, 20)


func test_signal_is_emitted_by_invalid_type() -> void:
	(
		await assert_failure_await(func() -> void: await assert_signal(signal_emitter).is_emitted(10))
	).has_message("Invalid signal_name: expected String or Signal, but is 'int'")


func test_signal_is_emitted_without_args() -> void:
	# wait until signal 'test_signal_counted' without args
	await assert_signal(signal_emitter).is_emitted("test_signal_without_value")
	# wait until signal 'test_signal_unused' where is never emitted
	(
		await assert_failure_await(func() -> void: await assert_signal(signal_emitter).wait_until(500).is_emitted("test_signal_unused"))
	).has_message("Expecting emit signal: 'test_signal_unused()' but timed out after 500ms")


func test_signal_is_emitted_with_array_args() -> void:
	# wait until signal 'test_signal_counted' is emitted with value 20
	await assert_signal(signal_emitter).is_emitted("test_signal_counted", [20])

	(
		await assert_failure_await(func() -> void: await assert_signal(signal_emitter).wait_until(50).is_emitted("test_signal_counted", [500]))
	).has_message("Expecting emit signal: 'test_signal_counted([500])' but timed out after 50ms")


func test_signal_is_emitted_with_variadic_args() -> void:
	await assert_signal(signal_emitter).is_emitted("test_signal_counted", 20)

	(
		await assert_failure_await(func() -> void: await assert_signal(signal_emitter).wait_until(50).is_emitted("test_signal_counted", 500))
	).has_message("Expecting emit signal: 'test_signal_counted([500])' but timed out after 50ms")


func test_signal_is_emitted_with_any_args() -> void:
	await assert_signal(signal_emitter).is_emitted("test_signal_counted", any())


func test_signal_is_emitted_use_argument_matcher() -> void:
	# wait until signal 'test_signal_counted' is emitted by using any_int() matcher for signal arguments
	await assert_signal(signal_emitter).is_emitted("test_signal_counted", [any_int()])

	# should also work with any() matcher
	signal_emitter.reset_trigger()
	await assert_signal(signal_emitter).is_emitted("test_signal_counted", [any()])

	# should fail because the matcher uses the wrong type
	signal_emitter.reset_trigger()
	(
		await assert_failure_await( func() -> void: await assert_signal(signal_emitter).wait_until(50).is_emitted("test_signal_counted", [any_string()]))
	).has_message("Expecting emit signal: 'test_signal_counted([any_string()])' but timed out after 50ms")


func test_signal_is_not_emitted_by_signal_name() -> void:
	await assert_signal(signal_emitter).wait_until(50).is_not_emitted("test_signal_counted")
	await assert_signal(signal_emitter).wait_until(30).is_not_emitted("test_signal_counted", 50)


func test_signal_is_not_emitted_by_signal_type() -> void:
	await assert_signal(signal_emitter).wait_until(50).is_not_emitted(signal_emitter.test_signal_counted)
	await assert_signal(signal_emitter).wait_until(30).is_not_emitted(signal_emitter.test_signal_counted, 50)


func test_signal_is_not_emitted() -> void:
	# wait to verify signal 'test_signal_counted()' is not emitted until the first 50 ms
	await assert_signal(signal_emitter).wait_until(50).is_not_emitted("test_signal_counted")
	# wait to verify signal 'test_signal_counted(50)' is not emitted until the NEXT 30 ms
	await assert_signal(signal_emitter).wait_until(30).is_not_emitted("test_signal_counted", [50])

	# until the next 500 ms the signal is emitted and ends in a failure
	(
		await assert_failure_await(func() -> void: await assert_signal(signal_emitter).wait_until(1000).is_not_emitted("test_signal_counted", [50]))
	).starts_with_message("Expecting do not emit signal: 'test_signal_counted([50])' but is emitted after")


func test_signal_is_not_emitted_use_varargs() -> void:
	# wait to verify signal 'test_signal_counted()' is not emitted until the first 50 ms
	await assert_signal(signal_emitter).wait_until(50).is_not_emitted("test_signal_counted")
	# wait to verify signal 'test_signal_counted(50)' is not emitted until the NEXT 30 ms
	await assert_signal(signal_emitter).wait_until(30).is_not_emitted("test_signal_counted", 50)

	# until the next 500 ms the signal is emitted and ends in a failure
	(
		await assert_failure_await(func() -> void: await assert_signal(signal_emitter).wait_until(1000).is_not_emitted("test_signal_counted", 50))
	).starts_with_message("Expecting do not emit signal: 'test_signal_counted([50])' but is emitted after")


func test_signal_is_not_emitted_use_argument_matcher() -> void:
	# wait until signal 'test_signal_counted' is NOT emitted by using any_int() matcher for signal arguments
	await assert_signal(signal_emitter).wait_until(10).is_not_emitted("test_signal_counted", [any()])
	await assert_signal(signal_emitter).wait_until(10).is_not_emitted("test_signal_counted", [any_int()])

	# until the next 500ms the signal is emitted and ends in a failure
	(
		await assert_failure_await(func() -> void: await assert_signal(signal_emitter).wait_until(1000).is_not_emitted("test_signal_counted", [any()]))
	).starts_with_message("Expecting do not emit signal: 'test_signal_counted([any()])' but is emitted after")


func test_signal_is_not_emitted_use_variadic_argument_matcher() -> void:
	# wait until signal 'test_signal_counted' is NOT emitted by using any_int() matcher for signal arguments
	await assert_signal(signal_emitter).wait_until(10).is_not_emitted("test_signal_counted", any())
	await assert_signal(signal_emitter).wait_until(10).is_not_emitted("test_signal_counted", any_int())

	# until the next 500ms the signal is emitted and ends in a failure
	(
		await assert_failure_await(func() -> void: await assert_signal(signal_emitter).wait_until(1000).is_not_emitted("test_signal_counted", any()))
	).starts_with_message("Expecting do not emit signal: 'test_signal_counted([any()])' but is emitted after")


func test_signal_is_not_emitted_use_argument_matcher_GD_878() -> void:
	await assert_signal(signal_emitter).wait_until(500).is_emitted("test_signal_a", ["foo"])
	# verify the signal is not emitted again
	await assert_signal(signal_emitter).wait_until(10).is_not_emitted("test_signal_a", ["foo"])

	# restart trigger counter
	signal_emitter.reset_trigger()
	await assert_signal(signal_emitter).wait_until(500).is_emitted("test_signal_a", [any()])
	# verify the signal is not emitted again
	await assert_signal(signal_emitter).wait_until(1).is_not_emitted("test_signal_a", [any()])


func test_override_failure_message() -> void:
	assert_object(assert_signal(signal_emitter).override_failure_message("error")).is_instanceof(GdUnitSignalAssert)
	(
		await assert_failure_await(func() -> void: await assert_signal(signal_emitter) \
		.override_failure_message("Custom failure message")\
		.wait_until(100)\
		.is_emitted("test_signal_unused"))
	).has_message("Custom failure message")


@warning_ignore("unsafe_method_access")
func test_append_failure_message() -> void:
	assert_object(assert_signal(signal_emitter).append_failure_message("error")).is_instanceof(GdUnitSignalAssert)
	(
		await assert_failure_await(func() -> void: await assert_signal(signal_emitter) \
		.append_failure_message("custom failure data")\
		.wait_until(100)\
		.is_emitted("test_signal_unused"))
	).has_message("""
		Expecting emit signal: 'test_signal_unused()' but timed out after 100ms
		Additional info:
		 custom failure data""".dedent().trim_prefix("\n"))


func test_node_changed_emitting_signals() -> void:
	var node :Node2D = auto_free(Node2D.new())
	add_child(node)

	await assert_signal(node).wait_until(200).is_emitted("draw")

	node.visible = false;
	await assert_signal(node).wait_until(200).is_emitted("visibility_changed")

	# expecting to fail, we not changed the visibility
	#node.visible = true;
	(
		await assert_failure_await(func() -> void: await assert_signal(node).wait_until(200).is_emitted("visibility_changed"))
	).has_message("Expecting emit signal: 'visibility_changed()' but timed out after 200ms")

	node.show()
	await assert_signal(node).wait_until(200).is_emitted("draw")


func test_is_signal_exists() -> void:
	var node: Node2D = auto_free(Node2D.new())

	assert_signal(node).is_signal_exists("visibility_changed")\
		.is_signal_exists("draw")\
		.is_signal_exists("visibility_changed")\
		.is_signal_exists("tree_entered")\
		.is_signal_exists(node.tree_exiting)\
		.is_signal_exists(node.tree_exited)

	(
		await assert_failure_await(func() -> void: assert_signal(node).is_signal_exists("not_existing_signal"))
	).has_message("The signal 'not_existing_signal' not exists checked object 'Node2D'.")


class MyEmitter extends Node:

	signal my_signal_a
	signal my_signal_b(value :String)


	func do_emit_a() -> void:
		my_signal_a.emit()


	func do_emit_b() -> void:
		my_signal_b.emit("foo")


@warning_ignore("unsafe_method_access")
func test_monitor_signals() -> void:
	# start to watch on the emitter to collect all emitted signals
	var emitter_a: MyEmitter = monitor_signals(MyEmitter.new())
	var emitter_b: MyEmitter = monitor_signals(MyEmitter.new())

	# verify the signals are not emitted initial
	await assert_signal(emitter_a).wait_until(50).is_not_emitted('my_signal_a')
	await assert_signal(emitter_a).wait_until(50).is_not_emitted('my_signal_b')
	await assert_signal(emitter_b).wait_until(50).is_not_emitted('my_signal_a')
	await assert_signal(emitter_b).wait_until(50).is_not_emitted('my_signal_b')

	# emit signal `my_signal_a` on emitter_a
	emitter_a.do_emit_a()
	await assert_signal(emitter_a).is_emitted('my_signal_a')

	# emit signal `my_signal_b` on emitter_a
	emitter_a.do_emit_b()
	await assert_signal(emitter_a).is_emitted('my_signal_b', ["foo"])
	# verify emitter_b still has nothing emitted
	await assert_signal(emitter_b).wait_until(50).is_not_emitted('my_signal_a')
	await assert_signal(emitter_b).wait_until(50).is_not_emitted('my_signal_b')

	# now verify emitter b
	emitter_b.do_emit_a()
	await assert_signal(emitter_b).wait_until(50).is_emitted('my_signal_a')


class ExampleResource extends Resource:
	@export var title := "Title":
		set(new_value):
			title = new_value
			changed.emit()


	func change_title(p_title: String) -> void:
		title = p_title


func test_monitor_signals_on_resource_set() -> void:
	var sut := ExampleResource.new()
	var emitter := monitor_signals(sut)

	sut.change_title("Some title")

	# title change should emit "changed" signal
	await assert_signal(emitter).is_emitted("changed")
	assert_str(sut.title).is_equal("Some title")
