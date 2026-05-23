## tween_property_test.gd — UIService.tween_property animation gateway unit tests.
##
## Covers story-004 Acceptance Criteria:
##   AC-15  reduced_motion == false → creates a Tween, chains tween_property, returns the Tween.
##   AC-16  reduced_motion == true  → returns null + applies final value immediately (set_indexed).
##   AC-10  reduced_motion defaults to false (safe default; SettingsService not yet integrated).
##   Forbidden-pattern gate: direct_create_tween_bypassing_reduced_motion registered in
##          docs/registry/architecture.yaml (all animation must route through the gateway).
##
## Design note (deviation from story-004 pseudo-code): reduced motion is read from the
## settable UIService.reduced_motion state field (the SettingsService subscription seam,
## wired in story 005/009), NOT a per-call Engine.has_singleton lookup. Tests drive the
## reduced-motion path by setting that field directly. See ui_service.gd for rationale.
##
## Test strategy (isolation — fresh instance per test):
##   Create a fresh _UIServiceScript.new() (preloaded to bypass class_name cache, same as
##   ui_service_test.gd), add_child() so create_tween() has a tree, auto_free() for cleanup.
##   This avoids mutating the shared autoload's reduced_motion state across tests.
##
## Run:
##   addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot \
##     -a tests/unit/ui_foundation/tween_property_test.gd
##
## ADR: docs/architecture/adr-0010-ui-foundation-architecture.md (§Decision + §Risk R7)
## TR:  TR-ui-010
extends GdUnitTestSuite


const _UIServiceScript: Script = preload("res://src/ui/ui_service.gd")


# ─── Helpers ──────────────────────────────────────────────────────────────────

## Fresh UIService instance in the tree (so create_tween() works), auto-freed.
func _make_service() -> Node:
	var svc: Node = _UIServiceScript.new()
	get_tree().root.add_child(svc)
	auto_free(svc)
	return svc


## A bare Control with modulate.a pre-set to 0.0, added to the tree + auto-freed.
func _make_target() -> Control:
	var c: Control = Control.new()
	c.modulate.a = 0.0
	get_tree().root.add_child(c)
	auto_free(c)
	return c


# ─── AC-10 — reduced_motion default ───────────────────────────────────────────

func test_reduced_motion_defaults_to_false() -> void:
	# Arrange + Act
	var svc: Node = _make_service()

	# Assert — safe default: animations play until SettingsService wires the real value
	assert_bool(svc.reduced_motion).is_false()


# ─── AC-15 — reduced_motion false → real Tween ────────────────────────────────

func test_tween_property_returns_valid_tween_when_motion_enabled() -> void:
	# Arrange
	var svc: Node = _make_service()
	svc.reduced_motion = false
	var target: Control = _make_target()

	# Act
	var tween: Tween = svc.tween_property(target, "modulate:a", 1.0, 0.05)

	# Assert — a Tween instance is returned and is live (AC-15 contract: creates + returns Tween)
	assert_object(tween).is_not_null()
	assert_bool(tween is Tween).is_true()
	assert_bool(tween.is_valid()).is_true()


func test_tween_property_interpolates_target_to_final_value() -> void:
	# Arrange
	var svc: Node = _make_service()
	svc.reduced_motion = false
	var target: Control = _make_target()
	assert_float(target.modulate.a).is_equal_approx(0.0, 0.001)

	# Act — start a short tween, then let real time pass beyond its duration
	svc.tween_property(target, "modulate:a", 1.0, 0.05)
	await get_tree().create_timer(0.15).timeout

	# Assert — target reached the final value (best-effort real-timing; the
	# deterministic contract is covered by the returns_valid_tween test above)
	assert_float(target.modulate.a).is_equal_approx(1.0, 0.01)


# ─── AC-16 — reduced_motion true → null + immediate set ───────────────────────

func test_tween_property_returns_null_and_sets_value_immediately_when_reduced() -> void:
	# Arrange — reduced motion ON
	var svc: Node = _make_service()
	svc.reduced_motion = true
	var target: Control = _make_target()
	assert_float(target.modulate.a).is_equal_approx(0.0, 0.001)

	# Act
	var tween: Tween = svc.tween_property(target, "modulate:a", 1.0, 0.05)

	# Assert — no Tween created; final value applied immediately
	assert_object(tween).is_null()
	assert_float(target.modulate.a).is_equal_approx(1.0, 0.001)


func test_tween_property_reduced_motion_does_not_create_tween() -> void:
	# AC-16: confirm no Tween allocation path when reduced motion is on, by checking
	# the immediate value application happens within the same frame (no await needed).
	var svc: Node = _make_service()
	svc.reduced_motion = true
	var target: Control = _make_target()

	# Act
	var result: Variant = svc.tween_property(target, "modulate:a", 0.42, 1.0)

	# Assert — returned null and value is set this frame (no time passage)
	assert_object(result).is_null()
	assert_float(target.modulate.a).is_equal_approx(0.42, 0.001)


# ─── Null-target guard ────────────────────────────────────────────────────────

func test_tween_property_null_target_returns_null_without_crash() -> void:
	# Arrange
	var svc: Node = _make_service()

	# Act — null target must not crash (push_error fires internally; gdunit4 does
	# not auto-fail on push_error). Returns null.
	var result: Variant = svc.tween_property(null, "modulate:a", 1.0, 0.05)

	# Assert
	assert_object(result).is_null()


# ─── Forbidden-pattern registry gate ──────────────────────────────────────────

func test_architecture_yaml_contains_direct_create_tween_forbidden_pattern() -> void:
	# All UI animation must route through UIService.tween_property; the forbidden
	# pattern enforces this at PR review. Verify it is registered (automated gate).
	const REGISTRY_PATH: String = "res://docs/registry/architecture.yaml"
	var file: FileAccess = FileAccess.open(REGISTRY_PATH, FileAccess.READ)
	assert_object(file).is_not_null()

	var content: String = file.get_as_text()
	file.close()
	assert_bool(content.contains("direct_create_tween_bypassing_reduced_motion")).is_true()
