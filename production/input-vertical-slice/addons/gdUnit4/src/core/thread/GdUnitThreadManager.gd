## A manager to run new thread and crate a ThreadContext shared over the actual test run
class_name GdUnitThreadManager
extends Object

## { <thread_id> = <GdUnitThreadContext> }
var _thread_context_by_id: Dictionary[int, GdUnitThreadContext] = {}
## holds the current thread id
var _current_thread_id :int = -1

func _init() -> void:
	# add initail the main thread
	_current_thread_id = OS.get_thread_caller_id()
	_thread_context_by_id[OS.get_main_thread_id()] = GdUnitThreadContext.new()


static func instance() -> GdUnitThreadManager:
	return GdUnitSingleton.instance("GdUnitThreadManager", func() -> GdUnitThreadManager: return GdUnitThreadManager.new())


## Runs a new thread by given name and Callable.[br]
## A new GdUnitThreadContext is created, which is used for the actual test execution.[br]
## We need this custom implementation while this bug is not solved
## Godot issue https://github.com/godotengine/godot/issues/79637
static func run(name :String, cb :Callable) -> Variant:
	return await instance()._run(name, cb)


static func interrupt() -> void:
	for thread_context: GdUnitThreadContext in instance()._thread_context_by_id.values():
		thread_context.terminate()


## Returns the current valid thread context
static func get_current_context() -> GdUnitThreadContext:
	return instance()._get_current_context()


func _run(name :String, cb :Callable) -> Variant:
	# we do this hack because of `OS.get_thread_caller_id()` not returns the current id
	# when await process_frame is called inside the fread
	var save_current_thread_id := _current_thread_id
	var thread := Thread.new()
	thread.set_meta("name", name)
	@warning_ignore("return_value_discarded")
	thread.start(cb)
	_current_thread_id = thread.get_id() as int
	_register_thread(thread, _current_thread_id)
	var result :Variant = await thread.wait_to_finish()
	_unregister_thread(_current_thread_id)
	# restore original thread id
	_current_thread_id = save_current_thread_id
	return result


func _register_thread(thread :Thread, thread_id :int) -> void:
	var context := GdUnitThreadContext.new(thread)
	_thread_context_by_id[thread_id] = context


func _unregister_thread(thread_id :int) -> void:
	var context: GdUnitThreadContext = _thread_context_by_id.get(thread_id)
	if context:
		@warning_ignore("return_value_discarded")
		_thread_context_by_id.erase(thread_id)
		context.dispose()


func _get_current_context() -> GdUnitThreadContext:
	return _thread_context_by_id.get(_current_thread_id)
