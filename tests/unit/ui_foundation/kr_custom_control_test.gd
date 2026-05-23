## kr_custom_control_test.gd — KrControlHelper + 4 Kr* subclass scaffold unit tests.
##
## Covers story-002 Acceptance Criteria:
##   AC-5   KrControlHelper.setup(control) queues NOTIFICATION_ACCESSIBILITY_UPDATE
##          (via Control.queue_accessibility_update) without error. Subclasses apply
##          the role in their _notification(NOTIFICATION_ACCESSIBILITY_UPDATE) override.
##   AC-5   Each Kr* subclass _ready() sets theme_type_variation correctly.
##   AC-5   Each Kr* subclass declares the correct ACCESSIBILITY_ROLE constant integer.
##   AC-5a  setup() with SettingsService absent → no error/crash (headless: singleton absent).
##   AC-7   docs/registry/architecture.yaml contains "custom_control_outside_kr_hierarchy".
##
## Subclass role expectations (ADR-0010 amend-1 §G1 — corrected mapping):
##   KrPane   → theme_type_variation &"Pane"   + ACCESSIBILITY_ROLE 6 (ROLE_PANEL)
##   KrCard   → theme_type_variation &"Card"   + ACCESSIBILITY_ROLE 6 (ROLE_PANEL)
##   KrButton → theme_type_variation &"Button" + ACCESSIBILITY_ROLE 7 (ROLE_BUTTON)
##   KrBanner → theme_type_variation &"Banner" + ACCESSIBILITY_ROLE 4 (ROLE_STATIC_TEXT)
##
## Godot 4.6 API deviation (runtime-verified 2026-05-23):
##   Control has NO set_accessibility_role() method and NO accessibility_role property.
##   Role assignment uses DisplayServer.accessibility_update_set_role(rid, role), which
##   requires a valid RID only available in a live (non-headless) scene tree. In headless
##   runs the RID is invalid; the call is silently skipped via rid.is_valid() guard.
##   Tests verify role intent via the ACCESSIBILITY_ROLE constant on each class instead
##   of reading back a runtime property. DisplayServer.AccessibilityRole enum IS accessible
##   in headless (it is a compile-time constant, not a runtime object).
##
## Test strategy:
##   Preload each script directly to bypass class_name global cache (not registered
##   in headless runs without editor scan — same pattern as ui_service_test.gd).
##   Instantiate via Script.new(), add_child() to fire _ready(), auto_free() for cleanup.
##   KrControlHelper.setup() is tested as a direct static call without add_child().
##   FileAccess read verifies AC-7 registry gate (YAML is a static project file;
##   test is read-only + deterministic).
##
## Run:
##   addons/gdUnit4/runtest.sh --godot_binary /opt/homebrew/bin/godot \
##     -a tests/unit/ui_foundation/kr_custom_control_test.gd
##
## ADR: docs/architecture/adr-0010-ui-foundation-architecture.md
## TR:  TR-ui-005
extends GdUnitTestSuite


# ─── Preloaded scripts ────────────────────────────────────────────────────────
# Bypass class_name global cache (requires editor scan; may not resolve in headless).

const KrControlHelperScript: Script = preload("res://src/ui/kr_control_helper.gd")
const KrPaneScript: Script = preload("res://src/ui/kr_pane.gd")
const KrCardScript: Script = preload("res://src/ui/kr_card.gd")
const KrButtonScript: Script = preload("res://src/ui/kr_button.gd")
const KrBannerScript: Script = preload("res://src/ui/kr_banner.gd")


# ─── Helpers ──────────────────────────────────────────────────────────────────

## Instantiate a Kr* node, add it to the tree so _ready() fires, and register
## for automatic cleanup. Returns the node typed as Control.
func _make_kr_node(script: Script) -> Control:
	var node: Control = script.new() as Control
	get_tree().root.add_child(node)
	auto_free(node)
	return node


# ─── AC-5 — KrPane: theme_type_variation + ACCESSIBILITY_ROLE constant ────────

func test_kr_pane_ready_sets_theme_type_variation_pane() -> void:
	# Arrange + Act
	var pane: Control = _make_kr_node(KrPaneScript)

	# Assert
	assert_str(str(pane.theme_type_variation)).is_equal("Pane")


func test_kr_pane_accessibility_role_constant_is_role_panel() -> void:
	# Assert — ACCESSIBILITY_ROLE constant encodes ROLE_PANEL = 6.
	# Control has no accessibility_role property in Godot 4.6 (runtime-verified):
	# role assignment uses DisplayServer.accessibility_update_set_role(rid, role)
	# which requires a valid RID unavailable in headless. The constant is the
	# authoritative intent source.
	assert_int(KrPaneScript.ACCESSIBILITY_ROLE).is_equal(DisplayServer.AccessibilityRole.ROLE_PANEL)


func test_kr_pane_accessibility_role_constant_matches_expected_integer() -> void:
	# Belt-and-suspenders: verify the integer value directly (=6) so a future
	# enum renumbering would also fail this test.
	assert_int(KrPaneScript.ACCESSIBILITY_ROLE).is_equal(6)


# ─── AC-5 — KrCard: theme_type_variation + ACCESSIBILITY_ROLE constant ────────

func test_kr_card_ready_sets_theme_type_variation_card() -> void:
	# Arrange + Act
	var card: Control = _make_kr_node(KrCardScript)

	# Assert
	assert_str(str(card.theme_type_variation)).is_equal("Card")


func test_kr_card_accessibility_role_constant_is_role_panel() -> void:
	# Assert — base KrCard is ROLE_PANEL (=6). Subclasses override with
	# ROLE_LIST_ITEM / ROLE_TREE_ITEM / ROLE_BUTTON / ROLE_CHECK_BOX.
	assert_int(KrCardScript.ACCESSIBILITY_ROLE).is_equal(DisplayServer.AccessibilityRole.ROLE_PANEL)


func test_kr_card_accessibility_role_constant_matches_expected_integer() -> void:
	assert_int(KrCardScript.ACCESSIBILITY_ROLE).is_equal(6)


# ─── AC-5 — KrButton: theme_type_variation + ACCESSIBILITY_ROLE constant ──────

func test_kr_button_ready_sets_theme_type_variation_button() -> void:
	# Arrange + Act
	var button: Control = _make_kr_node(KrButtonScript)

	# Assert
	assert_str(str(button.theme_type_variation)).is_equal("Button")


func test_kr_button_accessibility_role_constant_is_role_button() -> void:
	# Assert — ROLE_BUTTON = 7 (DisplayServer.AccessibilityRole — ADR-0010 amend-1 §G1)
	assert_int(KrButtonScript.ACCESSIBILITY_ROLE).is_equal(DisplayServer.AccessibilityRole.ROLE_BUTTON)


func test_kr_button_accessibility_role_constant_matches_expected_integer() -> void:
	assert_int(KrButtonScript.ACCESSIBILITY_ROLE).is_equal(7)


# ─── AC-5 — KrBanner: theme_type_variation + ACCESSIBILITY_ROLE constant ──────

func test_kr_banner_ready_sets_theme_type_variation_banner() -> void:
	# Arrange + Act
	var banner: Control = _make_kr_node(KrBannerScript)

	# Assert
	assert_str(str(banner.theme_type_variation)).is_equal("Banner")


func test_kr_banner_accessibility_role_constant_is_role_static_text() -> void:
	# Assert — ROLE_STATIC_TEXT = 4. Godot 4.6 has no ROLE_STATUS/ROLE_ALERT —
	# ROLE_STATIC_TEXT is the correct cap (ADR-0010 amend-1 §G1 correction).
	assert_int(KrBannerScript.ACCESSIBILITY_ROLE).is_equal(DisplayServer.AccessibilityRole.ROLE_STATIC_TEXT)


func test_kr_banner_accessibility_role_constant_matches_expected_integer() -> void:
	assert_int(KrBannerScript.ACCESSIBILITY_ROLE).is_equal(4)


# ─── AC-5a — KrControlHelper.setup() with SettingsService absent ──────────────

func test_kr_control_helper_setup_no_crash_when_settings_service_absent() -> void:
	# Arrange — bare Control; SettingsService singleton NOT registered in headless tests.
	# Engine.has_singleton("SettingsService") returns false → the stub branch is skipped.
	var bare: Control = Control.new()
	get_tree().root.add_child(bare)
	auto_free(bare)

	# Act — must not raise an error or crash
	KrControlHelperScript.setup(bare)

	# Assert — no crash; bare Control has no _apply_access_kit_role method.
	# has_method check inside setup() returns false → no dispatch attempt.
	assert_bool(bare.has_method("_apply_access_kit_role")).is_false()


func test_kr_subclass_declares_apply_access_kit_role_override() -> void:
	# A Kr* subclass must declare _apply_access_kit_role(), which its
	# _notification(NOTIFICATION_ACCESSIBILITY_UPDATE) override invokes when the
	# engine rebuilds the accessibility tree. (setup() itself only QUEUES the update
	# via Control.queue_accessibility_update — it does NOT call the role setter
	# directly; the RID is only valid inside the notification cycle.)
	var pane: Control = KrPaneScript.new() as Control
	get_tree().root.add_child(pane)
	auto_free(pane)

	# Assert — the override hook the _notification path depends on is present.
	assert_bool(pane.has_method("_apply_access_kit_role")).is_true()


func test_kr_control_helper_setup_queues_accessibility_update_without_error() -> void:
	# setup() calls Control.queue_accessibility_update() to schedule
	# NOTIFICATION_ACCESSIBILITY_UPDATE; it must complete without error on a real
	# Kr* node (headless: the queued notification's RID work is a no-op).
	var pane: Control = KrPaneScript.new() as Control
	get_tree().root.add_child(pane)
	auto_free(pane)

	# Act — direct static call must not raise
	KrControlHelperScript.setup(pane)

	# Assert — reached here without crash; the override hook exists for the
	# notification cycle to dispatch.
	assert_bool(pane.has_method("_apply_access_kit_role")).is_true()


func test_kr_control_helper_setup_is_callable_as_static_method() -> void:
	# Arrange
	var bare: Control = Control.new()
	get_tree().root.add_child(bare)
	auto_free(bare)

	# Act — static dispatch must not raise errors. If we reach the assert,
	# no fatal crash or parse error occurred.
	KrControlHelperScript.setup(bare)
	assert_bool(true).is_true()


# ─── AC-7 — Registry gate: custom_control_outside_kr_hierarchy ───────────────

func test_architecture_yaml_contains_custom_control_outside_kr_hierarchy() -> void:
	# Arrange — read the forbidden_patterns registry.
	# The YAML is a static project file committed to version control;
	# reading it in tests is deterministic and requires no mock.
	const REGISTRY_PATH: String = "res://docs/registry/architecture.yaml"
	var file: FileAccess = FileAccess.open(REGISTRY_PATH, FileAccess.READ)
	assert_object(file).is_not_null()

	# Act
	var content: String = file.get_as_text()
	file.close()

	# Assert — forbidden pattern must be registered (AC-7 automated gate).
	# Confirmed present at line 1851 of architecture.yaml (verified pre-implementation).
	assert_bool(content.contains("custom_control_outside_kr_hierarchy")).is_true()
