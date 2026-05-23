## KrCard — base card primitive for content display (LibraryCard, HypothesisNode, etc.).
##
## Extends [PanelContainer] directly (not a common KrCustomControl base — see ADR-0010
## §Decision Note on composition + static-helper pattern). Shared behavior is
## provided via [KrControlHelper.setup].
##
## [b]Theme type variation[/b]: [code]&"Card"[/code] — PanelContainer + 12px padding
## + 판결지 background + 1.5px outline 미드그레이 (story 003 populates the actual
## Theme variation).
##
## [b]AccessKit role[/b]: [code]DisplayServer.AccessibilityRole.ROLE_PANEL[/code] (=6).
## Subclasses (LibraryCard, HypothesisNode, EnvelopeCard, GroundsCard) override
## [method _apply_access_kit_role] with their specific roles (see ADR-0010 §Architecture
## Diagram + amend-1 §G1 for the full corrected mapping).
##
## [b]Role API note (Godot 4.6 — runtime-verified)[/b]: Role assignment uses
## [code]DisplayServer.accessibility_update_set_role[/code] inside
## [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code]. See [constant ACCESSIBILITY_ROLE].
##
## Note: story 007/008 reference a KrCard subclass (HypothesisNode). This file
## contains the minimal base per ADR-0010 §Decision Note.
##
## ADR: docs/architecture/adr-0010-ui-foundation-architecture.md
## TR:  TR-ui-005
class_name KrCard extends PanelContainer

## Preloaded to avoid class_name global cache dependency in headless runs.
const _KrControlHelper: Script = preload("res://src/ui/kr_control_helper.gd")


# ─── Constants ────────────────────────────────────────────────────────────────

## Intended AccessKit role integer for this class.
##
## [code]DisplayServer.AccessibilityRole.ROLE_PANEL[/code] = 6.
## Subclasses override [method _apply_access_kit_role] and should define their own
## [constant ACCESSIBILITY_ROLE] (LibraryCard=30, HypothesisNode=28, EnvelopeCard=7,
## GroundsCard=9 — ADR-0010 amend-1 §G1).
const ACCESSIBILITY_ROLE: int = 6  # DisplayServer.AccessibilityRole.ROLE_PANEL


# ─── Built-in virtual methods ─────────────────────────────────────────────────

## Applies the [code]&"Card"[/code] theme type variation and calls
## [method KrControlHelper.setup], which queues [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code].
func _ready() -> void:
	theme_type_variation = &"Card"
	_KrControlHelper.setup(self)


## Handles [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code] by calling
## [method _apply_access_kit_role] at the correct engine notification cycle.
func _notification(what: int) -> void:
	if what == NOTIFICATION_ACCESSIBILITY_UPDATE:
		_apply_access_kit_role()


# ─── Public methods ────────────────────────────────────────────────────────────

## Assigns the AccessKit role [code]ROLE_PANEL[/code] (=6) via
## [code]DisplayServer.accessibility_update_set_role[/code].
##
## Called from [method _notification] when [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code]
## fires. Override in subclasses (LibraryCard → ROLE_LIST_ITEM, HypothesisNode →
## ROLE_TREE_ITEM, EnvelopeCard → ROLE_BUTTON, GroundsCard → ROLE_CHECK_BOX).
func _apply_access_kit_role() -> void:
	var rid: RID = get_accessibility_element()
	if rid.is_valid():
		DisplayServer.accessibility_update_set_role(rid, DisplayServer.AccessibilityRole.ROLE_PANEL)
