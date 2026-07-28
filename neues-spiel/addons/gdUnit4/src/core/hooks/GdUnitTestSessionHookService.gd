class_name GdUnitTestSessionHookService
extends Object


var enigne_hooks: Array[GdUnitTestSessionHook] = []:
	get:
		return enigne_hooks
	set(value):
		enigne_hooks.append(value)


var _save_settings: bool = false


static func instance() -> GdUnitTestSessionHookService:
	return GdUnitSingleton.instance("GdUnitTestSessionHookService", func()->GdUnitTestSessionHookService:
		GdUnitSignals.instance().gdunit_message.emit("Installing GdUnit4 session system hooks.")
		var service := GdUnitTestSessionHookService.new()
		# Register default system hooks here
		service._save_settings = false
		service.register(GdUnitHtmlReporterTestSessionHook.new())
		service.register(GdUnitXMLReporterTestSessionHook.new())
		service.load_hook_settings()
		service._save_settings = true
		return service
	)


static func contains_hook(current: GdUnitTestSessionHook, other: GdUnitTestSessionHook) -> bool:
	return current.get_script().resource_path == other.get_script().resource_path


func find_custom(hook: GdUnitTestSessionHook) -> int:
	for index in enigne_hooks.size():
		if contains_hook.call(enigne_hooks[index], hook):
			return index
	return -1


func load_hook(hook_resourc_path: String) -> GdUnitResult:
	if !FileAccess.file_exists(hook_resourc_path):
		return GdUnitResult.error("The hook '%s' not exists." % hook_resourc_path)
	var script: GDScript = load(hook_resourc_path)
	if script.get_base_script() != GdUnitTestSessionHook:
		return GdUnitResult.error("The hook '%s' must inhertit from 'GdUnitTestSessionHook'." % hook_resourc_path)

	return GdUnitResult.success(script.new())


func enable_hook(hook: GdUnitTestSessionHook, enabled: bool) -> void:
	_enable_hook(hook, enabled)
	GdUnitSignals.instance().gdunit_message.emit("Session hook '{name}' {enabled}.".format({
		"name": hook.name,
		"enabled": "enabled" if enabled else "disabled"})
	)
	save_hock_setttings()


func register(hook: GdUnitTestSessionHook, enabled: bool = true) -> GdUnitResult:
	if find_custom(hook) != -1:
		return GdUnitResult.error("A hook instance of '%s' is already registered." % hook.get_script().resource_path)

	_enable_hook(hook, enabled)
	enigne_hooks.append(hook)
	save_hock_setttings()
	GdUnitSignals.instance().gdunit_message.emit("Session hook '%s' installed." % hook.name)

	return GdUnitResult.success()


func unregister(hook: GdUnitTestSessionHook) -> GdUnitResult:
	var hook_index := find_custom(hook)
	if hook_index == -1:
		return GdUnitResult.error("The hook instance of '%s' is NOT registered." % hook.get_script().resource_path)

	enigne_hooks.remove_at(hook_index)
	save_hock_setttings()
	return GdUnitResult.success()


func move_before(hook: GdUnitTestSessionHook, before: GdUnitTestSessionHook) -> void:
	var before_index := find_custom(before)
	var hook_index := find_custom(hook)

	# Verify the hook to move is behind the hook to be moved
	if before_index >= hook_index:
		return

	enigne_hooks.remove_at(hook_index)
	enigne_hooks.insert(before_index, hook)
	save_hock_setttings()


func move_after(hook: GdUnitTestSessionHook, after: GdUnitTestSessionHook) -> void:
	var after_index := find_custom(after)
	var hook_index := find_custom(hook)

	# Verify the hook to move is before the hook to be moved
	if after_index <= hook_index:
		return

	enigne_hooks.remove_at(hook_index)
	enigne_hooks.insert(after_index, hook)
	save_hock_setttings()


func execute_startup(session: GdUnitTestSession) -> GdUnitResult:
	return await execute("startup", session)


func execute_shutdown(session: GdUnitTestSession) -> GdUnitResult:
	return await execute("shutdown", session, true)


func execute(hook_func: String, session: GdUnitTestSession, reverse := false) -> GdUnitResult:
	var failed_hook_calls: Array[GdUnitResult] = []

	for hook_index in enigne_hooks.size():
		var index := enigne_hooks.size()-hook_index-1 if reverse else hook_index
		var hook: = enigne_hooks[index]
		if not is_enabled(hook):
			continue
		if OS.is_stdout_verbose():
			GdUnitSignals.instance().gdunit_message.emit("Session hook '%s' > %s()" % [hook.name, hook_func])
		var result: GdUnitResult = await hook.call(hook_func, session)
		if result == null:
			failed_hook_calls.push_back(GdUnitResult.error("Result is null! Check '%s'" % hook.get_script().resource_path))
		elif result.is_error():
			failed_hook_calls.push_back(result)

	if failed_hook_calls.is_empty():
		return GdUnitResult.success()

	var errors := failed_hook_calls.map(func(result: GdUnitResult) -> String:
		return "Hook call '%s' failed with error: '%s'" % [hook_func, result.error_message()]
	)
	return GdUnitResult.error( "\n".join(errors))


func save_hock_setttings() -> void:
	if not _save_settings:
		return

	var hooks_to_save: Dictionary[String, bool] = {}
	for hook in enigne_hooks:
		var enabled: bool = hook.get_meta("enabled")
		hooks_to_save[hook.get_script().resource_path] = enabled

	GdUnitSettings.set_session_hooks(hooks_to_save)


func load_hook_settings() -> void:
	var hooks_resource_paths := GdUnitSettings.get_session_hooks()
	if hooks_resource_paths.is_empty():
		return

	for hock_path: String in hooks_resource_paths.keys():
		var enabled := hooks_resource_paths[hock_path]

		# Do not reinstall already installed hooks
		var existing_hooks := enigne_hooks.filter(func(element: GdUnitTestSessionHook) -> bool:
			return element.get_script().resource_path == hock_path
		)
		var existing_hook: GdUnitTestSessionHook = null if existing_hooks.is_empty() else existing_hooks.front()
		# Applay enabled settings
		if existing_hook != null:
			_enable_hook(existing_hook, enabled)
			continue

		# Load additional hooks
		var result := load_hook(hock_path)
		if result.is_error():
			push_error(result.error_message())
			continue

		GdUnitSignals.instance().gdunit_message.emit("Installing GdUnit4 session hooks.")
		var hook: GdUnitTestSessionHook = result.value()

		result = register(hook, enabled)
		if result.is_error():
			push_error(result.error_message())
			continue


static func is_enabled(hook: GdUnitTestSessionHook) -> bool:
	if hook.has_meta("enabled"):
		return hook.get_meta("enabled")
	return true


func _enable_hook(hook: GdUnitTestSessionHook, enabled: bool) -> void:
	hook.set_meta("enabled", enabled)
