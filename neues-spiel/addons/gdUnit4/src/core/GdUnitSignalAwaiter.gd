class_name GdUnitSignalAwaiter
extends RefCounted

signal signal_emitted(action :Variant)

const NO_ARG :Variant = GdUnitConstants.NO_ARG

var _wait_on_idle_frame := false
var _interrupted := false
var _time_left :float = 0
var _timeout_millis :int


func _init(timeout_millis :int, wait_on_idle_frame := false) -> void:
	_timeout_millis = timeout_millis
	_wait_on_idle_frame = wait_on_idle_frame


func _on_signal_emmited(
	arg0 :Variant = NO_ARG,
	arg1 :Variant = NO_ARG,
	arg2 :Variant = NO_ARG,
	arg3 :Variant = NO_ARG,
	arg4 :Variant = NO_ARG,
	arg5 :Variant = NO_ARG,
	arg6 :Variant = NO_ARG,
	arg7 :Variant = NO_ARG,
	arg8 :Variant = NO_ARG,
	arg9 :Variant = NO_ARG) -> void:
	var signal_args :Variant = GdArrayTools.filter_value([arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9], NO_ARG)
	signal_emitted.emit(signal_args)


func is_interrupted() -> bool:
	return _interrupted


func elapsed_time() -> float:
	return _time_left


func on_signal(source :Object, signal_name :String, expected_signal_args :Array) -> Variant:
	# register checked signal to wait for
	@warning_ignore("return_value_discarded")
	source.connect(signal_name, _on_signal_emmited)
	# install timeout timer
	var scene_tree := Engine.get_main_loop() as SceneTree
	var timer := Timer.new()
	scene_tree.root.add_child(timer)
	timer.add_to_group("GdUnitTimers")
	timer.set_one_shot(true)
	@warning_ignore("return_value_discarded")
	timer.timeout.connect(_do_interrupt, CONNECT_DEFERRED)
	timer.start(_timeout_millis * 0.001 * Engine.get_time_scale())

	# holds the emited value
	var value :Variant
	# wait for signal is emitted or a timeout is happen
	while true:
		value = await signal_emitted
		if _interrupted:
			break
		if not (value is Array):
			value = [value]
		if expected_signal_args.size() == 0 or GdObjects.equals(value, expected_signal_args):
			break
		await scene_tree.process_frame

	source.disconnect(signal_name, _on_signal_emmited)
	_time_left = timer.time_left
	timer.queue_free()
	await scene_tree.process_frame
	@warning_ignore("unsafe_cast")
	if value is Array and (value as Array).size() == 1:
		return value[0]
	return value


func _do_interrupt() -> void:
	_interrupted = true
	signal_emitted.emit(null)
