class_name ExampleTestSessionHookB
extends GdUnitTestSessionHook

signal start_up(name: String)
signal shut_down(name: String)

var _state: PackedStringArray = []


func _init() -> void:
	super("hook_b", "An example hook for testing purpose.")


func startup(_session: GdUnitTestSession) -> GdUnitResult:
	start_up.emit(name)
	_state.push_back("startup")
	return GdUnitResult.success()


func shutdown(_session: GdUnitTestSession) -> GdUnitResult:
	shut_down.emit(name)
	_state.push_back("shutdown")
	return GdUnitResult.success()
