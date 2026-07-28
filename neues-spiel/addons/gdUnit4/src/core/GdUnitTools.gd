extends RefCounted


static var _richtext_normalize: RegEx


static func normalize_text(text :String) -> String:
	return text.replace("\r", "");


static func richtext_normalize(input :String) -> String:
	if _richtext_normalize == null:
		_richtext_normalize = to_regex("\\[/?(b|color|bgcolor|right|table|cell).*?\\]")
	return _richtext_normalize.sub(input, "", true).replace("\r", "")


static func to_regex(pattern :String) -> RegEx:
	var regex := RegEx.new()
	var err := regex.compile(pattern)
	if err != OK:
		push_error("Can't compiling regx '%s'.\n ERROR: %s" % [pattern, error_string(err)])
	return regex


static func prints_verbose(message :String) -> void:
	if OS.is_stdout_verbose():
		prints(message)


static func free_instance(instance :Variant, use_call_deferred :bool = false, is_stdout_verbose := false) -> bool:
	if instance is Array:
		var as_array: Array = instance
		for element: Variant in as_array:
			@warning_ignore("return_value_discarded")
			free_instance(element)
		as_array.clear()
		return true
	# do not free an already freed instance
	if not is_instance_valid(instance):
		return false
	# do not free a class refernece
	@warning_ignore("unsafe_cast")
	if typeof(instance) == TYPE_OBJECT and (instance as Object).is_class("GDScriptNativeClass"):
		return false
	if is_stdout_verbose:
		print_verbose("GdUnit4:gc():free instance ", instance)
	@warning_ignore("unsafe_cast")
	release_double(instance as Object)
	if instance is RefCounted:
		@warning_ignore("unsafe_cast")
		(instance as RefCounted).notification(Object.NOTIFICATION_PREDELETE)
		# If scene runner freed we explicit await all inputs are processed
		if instance is GdUnitSceneRunnerImpl:
			@warning_ignore("unsafe_cast")
			await (instance as GdUnitSceneRunnerImpl).await_input_processed()
		return true
	else:
		if instance is Timer:
			var timer: Timer = instance
			timer.stop()
			if use_call_deferred:
				timer.call_deferred("free")
			else:
				timer.free()
				await (Engine.get_main_loop() as SceneTree).process_frame
			return true

		@warning_ignore("unsafe_cast")
		if instance is Node and (instance as Node).get_parent() != null:
			var node: Node = instance
			if is_stdout_verbose:
				print_verbose("GdUnit4:gc():remove node from parent ", node.get_parent(), node)
			if use_call_deferred:
				node.get_parent().remove_child.call_deferred(node)
				#instance.call_deferred("set_owner", null)
			else:
				node.get_parent().remove_child(node)
		if is_stdout_verbose:
			print_verbose("GdUnit4:gc():freeing `free()` the instance ", instance)
		if use_call_deferred:
			@warning_ignore("unsafe_cast")
			(instance as Object).call_deferred("free")
		else:
			@warning_ignore("unsafe_cast")
			(instance as Object).free()
		return !is_instance_valid(instance)


static func _release_connections(instance :Object) -> void:
	if is_instance_valid(instance):
		# disconnect from all connected signals to force freeing, otherwise it ends up in orphans
		for connection in instance.get_incoming_connections():
			var signal_ :Signal = connection["signal"]
			var callable_ :Callable = connection["callable"]
			#prints(instance, connection)
			#prints("signal", signal_.get_name(), signal_.get_object())
			#prints("callable", callable_.get_object())
			if instance.has_signal(signal_.get_name()) and instance.is_connected(signal_.get_name(), callable_):
				#prints("disconnect signal", signal_.get_name(), callable_)
				instance.disconnect(signal_.get_name(), callable_)
	release_timers()


static func release_timers() -> void:
	# we go the new way to hold all gdunit timers in group 'GdUnitTimers'
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree.root == null:
		return
	for node :Node in scene_tree.root.get_children():
		if is_instance_valid(node) and node.is_in_group("GdUnitTimers"):
			if is_instance_valid(node):
				scene_tree.root.remove_child.call_deferred(node)
				(node as Timer).stop()
				node.queue_free()


# the finally cleaup unfreed resources and singletons
static func dispose_all(use_call_deferred :bool = false) -> void:
	release_timers()
	GdUnitSingleton.dispose(use_call_deferred)
	GdUnitSignals.dispose()


# if instance an mock or spy we need manually freeing the self reference
static func release_double(instance :Object) -> void:
	if instance.has_method("__release_double"):
		instance.call("__release_double")



static func find_test_case(test_suite: Node, test_case_name: String, index := -1) -> _TestCase:
	for test_case: _TestCase in test_suite.get_children():
		if test_case.test_name() == test_case_name:
			if index != -1:
				if test_case._test_case.attribute_index != index:
					continue
			return test_case
	return null


static func register_expect_interupted_by_timeout(test_suite: Node, test_case_name: String) -> void:
	var test_case := find_test_case(test_suite, test_case_name)
	if test_case:
		test_case.expect_to_interupt()
