## KrButton — styled button primitive for primary and dialog actions.
##
## Extends [Button] directly (not a common KrCustomControl base — see ADR-0010
## §Decision Note on composition + static-helper pattern). Shared behavior is
## provided via [KrControlHelper.setup].
##
## [b]Theme type variation[/b]: [code]&"Button"[/code] — 잉크블랙 fill + 흰 텍스트
## Pretendard Medium + 8px padding (story 003 populates the actual Theme variation).
## Variants (SubmitButton, DialogButton) are additional type variations assigned
## by subclasses or callers; this class provides the default [code]&"Button"[/code] tag.
##
## [b]AccessKit role[/b]: [code]DisplayServer.AccessibilityRole.ROLE_BUTTON[/code] (=7).
## [Button] already carries native button semantics in Godot, but explicit role
## assignment ensures AccessKit screen readers receive the correct announcement even
## when theme type variation is changed.
##
## [b]Role API note (Godot 4.6 — runtime-verified)[/b]: Role assignment uses
## [code]DisplayServer.accessibility_update_set_role[/code] inside
## [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code]. See [constant ACCESSIBILITY_ROLE].
##
## ADR: docs/architecture/adr-0010-ui-foundation-architecture.md
## TR:  TR-ui-005
class_name KrButton extends Button

## Preloaded to avoid class_name global cache dependency in headless runs.
const _KrControlHelper: Script = preload("res://src/ui/kr_control_helper.gd")


# ─── Constants ────────────────────────────────────────────────────────────────

## Intended AccessKit role integer for this class.
##
## [code]DisplayServer.AccessibilityRole.ROLE_BUTTON[/code] = 7.
## Exposed as a constant so unit tests can verify the intended role without
## requiring a live display.
const ACCESSIBILITY_ROLE: int = 7  # DisplayServer.AccessibilityRole.ROLE_BUTTON


# ─── Built-in virtual methods ─────────────────────────────────────────────────

## Applies the [code]&"Button"[/code] theme type variation and calls
## [method KrControlHelper.setup], which queues [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code].
func _ready() -> void:
	theme_type_variation = &"Button"
	_KrControlHelper.setup(self)


## Handles [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code] by calling
## [method _apply_access_kit_role] at the correct engine notification cycle.
func _notification(what: int) -> void:
	if what == NOTIFICATION_ACCESSIBILITY_UPDATE:
		_apply_access_kit_role()


# ─── Public methods ────────────────────────────────────────────────────────────

## Assigns the AccessKit role [code]ROLE_BUTTON[/code] (=7) via
## [code]DisplayServer.accessibility_update_set_role[/code].
##
## Called from [method _notification] when [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code]
## fires. Override in subclasses if a more specific button-family role is required
## (e.g. [code]ROLE_CHECK_BUTTON[/code] =11 for toggle behavior).
func _apply_access_kit_role() -> void:
	var rid: RID = get_accessibility_element()
	if rid.is_valid():
		DisplayServer.accessibility_update_set_role(rid, DisplayServer.AccessibilityRole.ROLE_BUTTON)
