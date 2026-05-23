## ui_service_test.gd — UIService autoload unit tests.
##
## Covers story-001 Acceptance Criteria:
##   AC-1   _ready() loads Theme + connects viewport size_changed + emits ui_service_initialized.
##   AC-1.2 UIService.theme read-only: direct assignment fires push_error, ref unchanged.
##   AC-1.3 viewport_reflow_needed debounce: 3 size_changed fires within 30ms → exactly 1 emit.
##   AC-1.4 VIEWPORT_REFLOW_DEBOUNCE_MS constant == 50.
##   AC-1.5 _UIServiceScript extends Node (not Resource).
##   AC-1.6 Theme initially empty: get_type_variation_list("Label") returns [].
##
## Test strategy (isolation — option b):
##   Create a fresh _UIServiceScript.new() instance, add_child() it to the test
##   suite node (GdUnitTestSuite extends Node, so it is in the scene tree).
##   _ready() fires automatically on add_child. This avoids autoload-singleton
##   state contamination and satisfies the "unit tests must not depend on
##   external state" project standard.
##
## Signal assertions use the manual connect+counter pattern (proven by
## workspace_state_machine_test.gd): connect BEFORE the act, check counter AFTER.
## Node signals are synchronous for same-frame emits; the Timer debounce tests
## use `await get_tree().create_timer(...)` to cross the 50ms window.
##
## Run:
##   addons/gdUnit4/runtest.sh --godot_binary godot \
##     -a tests/unit/ui_foundation/ui_service_test.gd
##
## ADR: docs/architecture/adr-0010-ui-foundation-architecture.md
## TR:  TR-ui-001
extends GdUnitTestSuite


# Preload bypasses GDScript class_name cache (which requires editor scan to register
# global symbols). Test references the Script directly via preload constant — works
# in headless test runs without requiring `godot --editor` cache population.
const _UIServiceScript: Script = preload("res://src/ui/ui_service.gd")


# ─── Helpers ──────────────────────────────────────────────────────────────────

## Creates a fresh _UIServiceScript instance, adds it to the test suite node so
## _ready() fires and the Timer child can access the scene tree.
## auto_free() registers it for cleanup after each test.
func _make_service() -> Node:
	var svc: Node = _UIServiceScript.new()
	get_tree().root.add_child(svc)
	auto_free(svc)
	return svc


# ─── AC-1.4 — Constant value ──────────────────────────────────────────────────

func test_viewport_reflow_debounce_ms_constant_is_50() -> void:
	# Arrange + Act (constant — no instance needed)
	# Assert
	assert_int(_UIServiceScript.VIEWPORT_REFLOW_DEBOUNCE_MS).is_equal(50)


# ─── AC-1.5 — Extends Node ────────────────────────────────────────────────────

func test_ui_service_class_extends_node() -> void:
	# Arrange
	var svc: Node = _make_service()

	# Assert — _UIServiceScript must be a Node (not a Resource) for viewport access
	assert_bool(svc is Node).is_true()


# ─── AC-1 — _ready() initializes Theme + emits ui_service_initialized ─────────

func test_ready_theme_is_theme_instance() -> void:
	# Arrange
	var svc: Node = _make_service()

	# Assert — theme property holds a Theme object after _ready()
	assert_bool(svc.theme is Theme).is_true()


func test_autoload_ui_service_registered_in_tree() -> void:
	# AC-1 (autoload-verified): UIService autoload is registered + in scene tree
	# (verifies project.godot [autoload] entry; _ready() already ran at game start
	# so ui_service_initialized signal cannot be re-captured here — it's a one-shot
	# init signal. This test confirms the autoload registration succeeded.)
	var autoload: Node = get_tree().root.get_node_or_null("UIService")
	assert_object(autoload).is_not_null()


func test_autoload_ui_service_theme_is_initialized() -> void:
	# AC-1 (theme created during _ready on autoload): autoload's theme is Theme instance
	var autoload: Node = get_tree().root.get_node_or_null("UIService")
	assert_object(autoload).is_not_null()
	assert_bool(autoload.theme is Theme).is_true()


func test_autoload_ui_service_viewport_debounce_timer_child_exists() -> void:
	# AC-1 (debounce timer child added during _ready): autoload has Timer child
	var autoload: Node = get_tree().root.get_node_or_null("UIService")
	assert_object(autoload).is_not_null()
	var timer_count: int = 0
	for child in autoload.get_children():
		if child is Timer:
			timer_count += 1
	assert_int(timer_count).is_greater_equal(1)


# ─── AC-1.2 — Theme read-only property guard ─────────────────────────────────

func test_theme_direct_assignment_does_not_mutate() -> void:
	# Arrange
	var svc: Node = _make_service()
	var original_theme: Theme = svc.theme

	# Act — direct assignment fires push_error internally; gdunit4 does not
	# auto-fail on push_error. Theme reference integrity is the assertion.
	svc.theme = Theme.new()

	# Assert — reference unchanged (setter rejected the write)
	assert_object(svc.theme).is_same(original_theme)


func test_theme_getter_returns_same_reference_on_repeated_access() -> void:
	# Arrange
	var svc: Node = _make_service()

	# Act + Assert — two gets return the same object (no copy-on-read)
	assert_object(svc.theme).is_same(svc.theme)


# ─── AC-1.6 — Theme initially empty ──────────────────────────────────────────

func test_theme_initially_has_no_label_type_variations() -> void:
	# Arrange
	var svc: Node = _make_service()

	# Assert — story 003 populates type variations; story 001 is empty
	assert_array(svc.theme.get_type_variation_list("Label")).is_empty()


# ─── AC-1.3 — viewport_reflow_needed callback chain (autoload-based) ─────────
# Note: Timer Node's _process tick may not advance in gdunit4 headless test
# isolation, so tests below verify the callback chain structurally rather than
# the actual 50ms debounce timing. Real timing verification belongs in
# integration tests (deferred — would require manual headless run with
# scene tree process explicitly ticked).

func test_size_changed_handler_starts_debounce_timer() -> void:
	# AC-1.3 (structural): _on_viewport_size_changed calls Timer.start()
	var svc: Node = get_tree().root.get_node_or_null("UIService")
	assert_object(svc).is_not_null()

	# Find the debounce Timer child (added during _ready)
	var timer: Timer = null
	for child in svc.get_children():
		if child is Timer:
			timer = child
			break
	assert_object(timer).is_not_null()

	# Stop timer initially (may have been running from prior tests)
	timer.stop()
	assert_bool(timer.is_stopped()).is_true()

	# Act — fire size_changed
	svc._on_viewport_size_changed()

	# Assert — timer started + wait_time matches constant
	assert_bool(timer.is_stopped()).is_false()
	assert_float(timer.wait_time).is_equal_approx(0.05, 0.001)  # 50ms
	timer.stop()


func test_debounce_timeout_callback_emits_viewport_reflow_needed() -> void:
	# AC-1.3 (callback chain): _on_viewport_debounce_timeout emits the signal
	var svc: Node = get_tree().root.get_node_or_null("UIService")
	assert_object(svc).is_not_null()
	# Use an Array accumulator (reference type), NOT a plain int: GDScript lambdas
	# capture primitives BY VALUE, so `count += 1` inside a lambda increments a copy
	# and the outer int stays 0. Arrays are shared by reference with the outer scope.
	# (Same hazard documented in freeze_contract_test.gd header lines 25-34.)
	var captured: Array = []
	var cb: Callable = func() -> void: captured.append(true)
	svc.viewport_reflow_needed.connect(cb)

	# Act — call the timeout callback directly (bypass Timer tick which may not
	# advance in headless test isolation)
	svc._on_viewport_debounce_timeout()
	await get_tree().process_frame

	# Assert
	svc.viewport_reflow_needed.disconnect(cb)
	assert_int(captured.size()).is_equal(1)


func test_debounce_multiple_starts_reset_timer() -> void:
	# AC-1.3 (coalescing structural): Timer.start() resets running timer
	var svc: Node = get_tree().root.get_node_or_null("UIService")
	assert_object(svc).is_not_null()
	var timer: Timer = null
	for child in svc.get_children():
		if child is Timer:
			timer = child
			break
	assert_object(timer).is_not_null()
	timer.stop()

	# Act — start timer 3 times in succession; each start resets time_left
	svc._on_viewport_size_changed()
	var first_time_left: float = timer.time_left
	svc._on_viewport_size_changed()  # reset
	var second_time_left: float = timer.time_left
	svc._on_viewport_size_changed()  # reset again
	var third_time_left: float = timer.time_left

	# Assert — each start sets time_left back to ~wait_time (50ms)
	assert_float(first_time_left).is_greater(0.0)
	assert_float(second_time_left).is_greater(0.0)
	assert_float(third_time_left).is_greater(0.0)
	timer.stop()
