extends SceneTree
## Exercise interaction admission, hold cancellation, toggle and completion idempotence.
var checks := 0
var failures := 0
func _initialize() -> void:
	call_deferred(&"run_tests")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func run_tests() -> void:
	check(ResourceLoader.exists("res://src/interaction/interaction_controller.gd"), "Interaction controller exists")
	if ResourceLoader.exists("res://src/interaction/interaction_controller.gd"):
		var controller = load("res://src/interaction/interaction_controller.gd").new()
		var target = load("res://src/interaction/lab_interactable.gd").new()
		target.hold_duration = 1.0
		root.add_child(target)
		root.add_child(controller)
		controller.set_candidate(target, Vector3.ZERO, true)
		controller.step(true, true, 0.4)
		check(not target.completed and controller.progress > 0.0, "Hold starts but does not complete early")
		controller.step(false, false, 0.1)
		check(controller.progress == 0.0 and not target.completed, "Release cancels hold")
		controller.step(true, true, 1.0)
		check(target.completed, "Full hold completes")
		check(not target.activate(), "Repeated completion cannot duplicate effects")
		target.reset_target()
		controller.set_candidate(target, Vector3(20, 0, 0), true)
		controller.step(true, true, 2.0)
		check(not target.completed and controller.reason != "", "Out of range has reason and cannot complete")
		controller.set_candidate(target, Vector3.ZERO, false)
		controller.step(true, true, 2.0)
		check(not target.completed, "Occlusion blocks interaction")
		controller.toggle_mode = true
		controller.set_candidate(target, Vector3.ZERO, true)
		controller.step(true, false, 0.5)
		controller.step(false, false, 0.5)
		check(target.completed, "Toggle mode completes without held input")
		target.reset_target()
		controller.step(true, false, 0.4)
		controller.set_candidate(null, Vector3.ZERO, false)
		check(controller.progress == 0.0, "Target loss cancels progress")
		controller.set_candidate(target, Vector3.ZERO, true)
		controller.step(true, false, 0.4)
		controller.cancel()
		check(controller.progress == 0.0, "Explicit pause/focus cancel clears hold")
		target.hold_duration = 0.0
		controller.step(true, true, 0.01)
		check(target.completed, "Short press activates immediate target")
		target.queue_free()
		controller.queue_free()
		await process_frame
	print("Interaction tests: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
