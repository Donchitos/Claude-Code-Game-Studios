# Story 005: announce_text live-region API + AccessKit role helper

> **Epic**: UI Foundation
> **Status**: Ready
> **Layer**: Foundation (Core)
> **Type**: Logic + Integration
> **Manifest Version**: 2026-05-18
> **Estimate**: 3 hours (M) — announce_text API + AnnouncePriority enum + AccessKit role static helper + ~10 unit tests
> **Performance**: < 0.5ms per announce_text call (single DisplayServer API call); negligible

## Context

**GDD**: `design/gdd/ui-foundation.md` §10.4 AC-11/12/13/14 (AccessKit + Focus)
**Requirement**: TR-ui-014 (announce_text) + TR-ui-013 (AccessKit role assignment)
**ADR**: ADR-0010 amend-1 §G3 (UIService.announce_text via DisplayServer.accessibility_update_set_live, VR-UI6 PASS path) + amend-4 §F1 (46-entry AccessibilityRole corrected mapping)
**Engine**: Godot 4.6 | **Risk**: LOW (VR-UI6 PASS — DisplayServer.accessibility_update_set_live + AccessibilityLiveMode runtime confirmed)

## Acceptance Criteria

- [ ] AC-11 — `UIService.announce_text(source: Control, message: String, priority: AnnouncePriority)` calls `DisplayServer.accessibility_update_set_live(rid, mode)` + `accessibility_update_set_name(rid, message)`
- [ ] AC-11.2 — AnnouncePriority enum: `POLITE = 0, ASSERTIVE = 1` mapping to `DisplayServer.LIVE_POLITE = 1, LIVE_ASSERTIVE = 2`
- [ ] AC-11.3 — source Control with no accessibility element → push_warning + no-op (graceful)
- [ ] AC-11.4 — `_map_priority(AnnouncePriority) -> int` returns correct DisplayServer enum (POLITE→1, ASSERTIVE→2, default→LIVE_OFF=0)
- [ ] AC-14 — `KrAccessKitHelper.apply_role(control: Control, role: int)` static helper sets `control.accessibility_role = role` + asserts role is in valid range (0..45 per VR-UI6 enum dump)
- [ ] AC-14.2 — `KrAccessKitHelper.is_valid_role(role: int)` returns true for role in 0..45, false otherwise

## Implementation Notes

Per ADR-0010 amend-1 §G3 (VR-UI6 PASS path — focus-shift fallback UNUSED):

```gdscript
# Add to UIService
enum AnnouncePriority { POLITE, ASSERTIVE }

func announce_text(source: Control, message: String, priority: AnnouncePriority = AnnouncePriority.POLITE) -> void:
    if source == null:
        push_warning("UIService.announce_text: source Control is null — skipped")
        return
    var rid: RID = source.get_accessibility_element()
    if not rid.is_valid():
        push_warning("UIService.announce_text: source has no AccessKit element — skipped")
        return
    DisplayServer.accessibility_update_set_live(rid, _map_priority(priority))
    DisplayServer.accessibility_update_set_name(rid, message)

func _map_priority(p: AnnouncePriority) -> int:
    match p:
        AnnouncePriority.POLITE:    return DisplayServer.LIVE_POLITE     # = 1
        AnnouncePriority.ASSERTIVE: return DisplayServer.LIVE_ASSERTIVE  # = 2
        _:                          return DisplayServer.LIVE_OFF        # = 0
```

```gdscript
# src/ui/kr_access_kit_helper.gd
class_name KrAccessKitHelper

const MIN_ROLE := 0   # ROLE_UNKNOWN
const MAX_ROLE := 45  # ROLE_TOOLTIP (per VR-UI6 46-entry enum dump)

static func apply_role(control: Control, role: int) -> void:
    if not is_valid_role(role):
        push_error("KrAccessKitHelper.apply_role: invalid role %d (must be 0..%d)" % [role, MAX_ROLE])
        return
    control.accessibility_role = role

static func is_valid_role(role: int) -> bool:
    return role >= MIN_ROLE and role <= MAX_ROLE
```

## Out of Scope

- AC-12 (AccessKit verification gate fail mode) — defer, requires Godot project-level AccessKit init check (lower-priority MVP)
- AC-13 KrButton focus visual ring (R8 dual focus composite — deferred follow-up)
- Real screen reader integration tests (VoiceOver / NVDA / Orca — manual evidence portion deferred)

## QA Test Cases

- **AC-11**: Mock Control with valid accessibility_element RID → call announce_text → assert DisplayServer.accessibility_update_set_live + set_name called via test instrumentation (or verify RID state)
- **AC-11.3**: null source → push_warning + no API call
- **AC-11.4**: `_map_priority(POLITE) == DisplayServer.LIVE_POLITE` (1) + `_map_priority(ASSERTIVE) == DisplayServer.LIVE_ASSERTIVE` (2)
- **AC-14**: `KrAccessKitHelper.apply_role(control, 28)` (ROLE_TREE_ITEM) → `control.accessibility_role == 28`
- **AC-14.2**: `is_valid_role(-1)` false, `is_valid_role(46)` false, `is_valid_role(0)` true, `is_valid_role(45)` true

## Test Evidence

**Required**: `tests/unit/ui_foundation/announce_text_test.gd` + `tests/unit/ui_foundation/access_kit_helper_test.gd`
**Status**: [ ] Not yet created

## Dependencies

- Depends on: Story 001 (UIService autoload), Story 002 (KrCustomControl subclasses can use KrAccessKitHelper.apply_role)
- Unlocks: workspace 008 (ReadOnlyIndicator + CriticalBanner announce) + 010 (AccessKit role audit) + workspace 003b (KrCard scene wrapping uses KrAccessKitHelper)
