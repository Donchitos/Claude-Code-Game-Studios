# Story 002: KrCustomControl base + KrControlHelper

> **Epic**: UI Foundation
> **Status**: Complete (2026-05-23)
> **Layer**: Foundation (Core)
> **Type**: Logic
> **Manifest Version**: 2026-05-18
> **Estimate**: 3 hours (M) — KrControlHelper static helper + 4 minimal Kr* subclasses (KrPane / KrCard / KrButton / KrBanner) + base lifecycle test
> **Performance**: No expected impact — _ready() one-time setup + signal connect; no per-frame cost

## Context

**GDD**: `design/gdd/ui-foundation.md` §3.1 Core Rules (KrCustomControl tree) + §10.2 AC-5/AC-7
**Requirement**: TR-ui-005 (KrCustomControl base composition pattern)
**ADR**: ADR-0010 §Decision Note (composition + static helper pattern — godot-specialist 2026-05-17 redefine to bypass GDScript multiple-inheritance)
**Engine**: Godot 4.6 | **Risk**: LOW

**Control Manifest Rules**: see `docs/architecture/control-manifest.md` v2026-05-18 — Foundation Layer

## Acceptance Criteria

- [x] AC-5 — KrCustomControl subclass `_ready()` calls `KrControlHelper.setup(self)` which (a) guards SettingsService 3-signal subscription (stub — skips if singleton absent), (b) calls `Control.queue_accessibility_update()`; subclass applies role in `_notification(NOTIFICATION_ACCESSIBILITY_UPDATE)` → `_apply_access_kit_role()` — **DONE** (see API deviation in Completion Notes)
- [x] AC-7 — `custom_control_outside_kr_hierarchy` forbidden_pattern registered in architecture.yaml — **DONE** (automated registry-read test, confirmed line 1851)
- [x] KrPane (Container) + KrCard (PanelContainer) + KrButton (Button) + KrBanner (PanelContainer) — 4 subclass scaffolds with `_apply_access_kit_role()` override + `theme_type_variation` + `ACCESSIBILITY_ROLE` constant — **DONE**
- [x] `KrControlHelper.setup(control)` static method tested independently — **DONE**
- [x] AC-7 verification — automated `architecture.yaml` registry-read assertion — **DONE**

## Implementation Notes

Per ADR-0010 §Decision Note (composition + static helper pattern):

```gdscript
# src/ui/kr_control_helper.gd
class_name KrControlHelper

static func setup(control: Control) -> void:
    if Engine.has_singleton("SettingsService"):
        # SettingsService 3 signals — auto subscribe (stub for story 002; real subscriber wiring in workspace 009)
        pass
    if control.has_method("_apply_access_kit_role"):
        control._apply_access_kit_role()

# src/ui/kr_pane.gd
class_name KrPane extends Container

func _ready() -> void:
    theme_type_variation = &"Pane"
    KrControlHelper.setup(self)

func _apply_access_kit_role() -> void:
    accessibility_role = AccessibilityRole.ROLE_PANEL  # =6 per amend-4 §F1
```

Similarly for KrCard (ROLE_PANEL), KrButton (ROLE_BUTTON=7), KrBanner (ROLE_STATIC_TEXT=4).

**SettingsService subscription**: stub for story-002 (real wiring is story 005 + workspace 009). Just check `Engine.has_singleton("SettingsService")` and skip if absent (test fixtures don't load full autoload chain).

## Out of Scope

- Full 17 Kr* subclasses (only 4 essentials for now: Pane / Card / Button / Banner)
- Theme type variations content (story 003)
- announce_text API (story 005)
- Dual focus ring composite (R8 — deferred to follow-up)

## QA Test Cases

- **AC-5**: Instantiate KrPane in scene, assert `theme_type_variation == &"Pane"` + `accessibility_role == ROLE_PANEL` after _ready()
- **AC-5-no-singleton**: KrControlHelper.setup with SettingsService absent → no error
- **AC-7-registry**: grep architecture.yaml for `custom_control_outside_kr_hierarchy` → found (already registered per control-manifest)
- Per-subclass tests: KrCard / KrButton / KrBanner each instantiate + correct role
- KrControlHelper static method directly callable

## Test Evidence

**Required**: `tests/unit/ui_foundation/kr_custom_control_test.gd`
**Status**: [ ] Not yet created

## Dependencies

- Depends on: Story 001 (UIService autoload — KrControlHelper may reference UIService.theme in future stories)
- Unlocks: Story 003 (Theme variations use these Kr* classes) + workspace 003b (KrCard scene wrapping uses KrCard base)

---

## Completion Notes
**Completed**: 2026-05-23
**Criteria**: 5/5 passing.
**Files created**:
- `src/ui/kr_control_helper.gd` — `class_name KrControlHelper extends RefCounted`, static `setup(control)` (SettingsService guard + `queue_accessibility_update()`)
- `src/ui/kr_pane.gd` (Container, ROLE_PANEL=6), `src/ui/kr_card.gd` (PanelContainer, ROLE_PANEL=6), `src/ui/kr_button.gd` (Button, ROLE_BUTTON=7), `src/ui/kr_banner.gd` (PanelContainer, ROLE_STATIC_TEXT=4) — each: `_ready()` (theme_type_variation + setup) + `_notification(NOTIFICATION_ACCESSIBILITY_UPDATE)` + `_apply_access_kit_role()` + `ACCESSIBILITY_ROLE` const
- `tests/unit/ui_foundation/kr_custom_control_test.gd` (17 tests)
**Test Evidence**: ui_foundation suite 29/29 PASS, exit 0 (independently re-run).
**⚠️ ENGINE API DEVIATION (important)**: The story pseudo-code used `accessibility_role = AccessibilityRole.ROLE_PANEL` (property assignment). Runtime investigation found **Godot 4.6 Control has no `accessibility_role` property and no `set_accessibility_role()` method** — despite `docs/engine-reference/godot/modules/ui.md` line 94 claiming "set via `Control.set_accessibility_role()`". The working API is `DisplayServer.accessibility_update_set_role(rid, role)` where `rid = get_accessibility_element()`, called **inside `NOTIFICATION_ACCESSIBILITY_UPDATE` (=3000)** — calling it elsewhere errors. Hence the `_ready()→queue_accessibility_update()` + `_notification()→_apply_access_kit_role()` pattern. The intended role int is exposed as `ACCESSIBILITY_ROLE` const for headless testability (live RID unavailable headless). **ui.md line 94 discrepancy logged as TD-003 for source verification.**
**Implementation notes**:
- Composition + static-helper pattern (ADR-0010 §Decision Note) — Kr* classes extend native Control types directly, share behavior via KrControlHelper; NO common base class (GDScript has no multiple inheritance).
- SettingsService 3-signal subscription is a stub (guarded by `Engine.has_singleton`) — real wiring deferred to story 005 / workspace 009.
**Code Review**: Performed by orchestrator via direct full-file inspection (agent was interrupted mid-migration leaving `kr_banner.gd` on the old `_ready`-dispatch pattern without `_notification` — would have silently never applied its role at runtime; orchestrator fixed banner to the canonical `_notification` pattern + corrected stale/misleading test comments + a misleadingly-named test). No separate review agent spawned.
