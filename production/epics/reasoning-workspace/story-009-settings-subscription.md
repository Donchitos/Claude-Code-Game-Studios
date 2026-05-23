# Story 009: Settings subscription cascade — UIService auto-subscribe

> **Epic**: Reasoning Workspace
> **Status**: Ready
> **Layer**: Feature (Gameplay)
> **Type**: Integration
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/reasoning-workspace.md` (§6.4 #4 Settings dependency, §10.7 partial reduced_motion / text_scale, §10.8 partial focus_indicator_thickness)
**Requirement**: TR-WORKSPACE-LAYOUT-001 + (cross-cover TR-settings-006/007/008 from ADR-0009)

**ADR Governing Implementation**: ADR-0010 KrCustomControl auto-subscribe via UIService (text_scale + reduced_motion + focus_indicator_thickness signals) + ADR-0010 amend-1 (corrected AccessKit + announce_text) + ADR-0009 (SettingsService FIFTH autoload + 5-step cascade + setting_changed typed signal)
**ADR Decision Summary**: KrCustomControl base class `_ready()` auto-subscribes to SettingsService 3 signals (display.reduced_motion / display.text_scale / accessibility.focus_indicator_thickness_px) via UIService. text_scale → Theme.set_font_size cascade (VR-UI1 PASS — auto NOTIFICATION_THEME_CHANGED propagation). reduced_motion → UIService.tween_property gateway returns null. focus_indicator_thickness → dual focus ring outer dashed width 1-4px.

**Engine**: Godot 4.6 | **Risk**: LOW (post-VR-UI1 PASS)
**Engine Notes**: `Theme.set_font_size()` auto-cascade confirmed VR-UI1 PASS (3/3 dependent Labels receive NOTIFICATION_THEME_CHANGED). `UIService.tween_property` gateway returns null when reduced_motion → caller sets property immediately.

**Control Manifest Rules**: see `docs/architecture/control-manifest.md` v2026-05-18 — Feature Layer Required/Forbidden/Guardrails apply to this story

---

## Acceptance Criteria

Scope: §10.7 partial + §10.8 partial settings subscription.

- [ ] AC-40 — `display.reduced_motion = true` → all UIService.tween_property() calls within Workspace return null + caller sets property immediately (no animation). Verify: MemoPanel fade (story 005), Camera2D auto-center (story 006), drag preview animations (story 011) all bypass tween
- [ ] AC-41b — `display.text_scale` change → Theme runtime reload cascades to all KrCustomControl in Workspace scene (HypothesisNode label, MemoEdit, ReadOnlyIndicator) via NOTIFICATION_THEME_CHANGED (VR-UI1 PASS — automatic)
- [ ] AC-47 — `accessibility.focus_indicator_thickness_px` (1-4) controls dual focus ring outer dashed thickness on HypothesisNode + KrButton + KrDialog
- [ ] AC-48 — Settings change while Workspace in any state (INACTIVE/ACTIVE/FROZEN/READ_ONLY) applies immediately — no waiting for Workspace-specific signal
- [ ] AC-48b — KrCustomControl auto-subscribe happens in `_ready()` — verify by inspecting subscriber count on SettingsService after Workspace scene load
- [ ] AC-48c — `input.mouse_drag_threshold_px` change updates story 004 drag threshold; `input.gamepad_stick_deadzone` change updates story 006 deadzone — both via SettingsService.get() consumption at call-site (no caching per ADR-0009 forbidden_pattern `settings_local_cache`)

---

## Implementation Notes

Per ADR-0010 §Decision + amend-1 §G1/G2 + ADR-0009 §3.1:

```gdscript
# KrControlHelper.setup() — called from each Kr* class _ready()
static func setup(control: Control) -> void:
    if Engine.has_singleton("SettingsService"):
        SettingsService.setting_changed.connect(_on_setting_changed.bind(control))
    control._apply_access_kit_role()   # subclass override
    # ... other Kr setup

static func _on_setting_changed(key: String, _old: Variant, new: Variant, control: Control) -> void:
    match key:
        "display.reduced_motion":
            # No per-control action; UIService.tween_property gateway handles centrally
            pass
        "display.text_scale":
            # No per-control action; Theme.set_font_size cascade handled by UIService.theme mutation
            pass
        "accessibility.focus_indicator_thickness_px":
            control.queue_redraw()   # repaint focus ring with new thickness

# Workspace per-call consumption pattern (no local cache — ADR-0009 forbidden_pattern)
# story 004 drag threshold check:
var threshold: int = SettingsService.get("input.mouse_drag_threshold_px", 8)
if motion.length() < threshold: return
```

- `settings_local_cache` forbidden_pattern: do NOT do `var _cached_threshold = SettingsService.get(...)` in member vars; always call `SettingsService.get(key)` at use-site OR subscribe to `setting_changed` signal
- VR-UI1 PASS confirms Theme.set_font_size cascade is automatic — no manual `theme.emit_changed()` (per registry forbidden_pattern from ADR-0004 amend-1)
- AC-47 dual focus ring: outer dashed component width comes from `accessibility.focus_indicator_thickness_px` — per ADR-0010 §Dual Focus Ring Composite (inner=2px solid fixed, outer=1-4px dashed user-configurable)
- ADR-0010 R8 (dashed border non-trivial) — implementation deferred to story 011 visual polish; this story wires the setting subscription only

---

## Out of Scope

- Story 005: MemoPanel fade implementation (this story verifies the reduced_motion gateway works for MemoPanel's tween calls)
- Story 006: Camera2D auto-center implementation (this story verifies the gateway behavior)
- Story 011: Dual focus ring visual implementation (this story wires `focus_indicator_thickness_px` consumption; story 011 implements the actual outer dashed render via ADR-0010 R8 decision)
- ADR-0009 SettingsService implementation itself (Settings & Accessibility epic — out of this epic's scope)
- AccessKit role assignment (story 010)

---

## QA Test Cases

- **AC-40 Integration**: Set `display.reduced_motion = true`; trigger MemoPanel fade (story 005) → no opacity tween created, set immediate; trigger Camera2D auto-center (story 006) → camera.position = target immediately
- **AC-41b Integration**: Change `display.text_scale = 1.5`; verify HypothesisNode label font size visually +50% (or check Theme.set_font_size called once on UIService.theme then NOTIFICATION_THEME_CHANGED received by Workspace Controls)
- **AC-47 Manual**: Change `accessibility.focus_indicator_thickness_px` 1→4; focus a HypothesisNode → outer dashed ring visibly thickens
- **AC-48 Logic**: Workspace state INACTIVE; change `display.reduced_motion` → setting_changed signal received + UIService.tween_property reflects new value on next call
- **AC-48b Logic**: Load Workspace scene with 3 HypothesisNodes + MemoPanel + ReadOnlyIndicator (5 KrCustomControl); verify SettingsService.setting_changed has ≥5 connections
- **AC-48c Logic**: Set `input.mouse_drag_threshold_px = 16`; story 004 drag attempt at 12px motion → no drag; at 18px → drag starts (verify on next call, not stale cache)

Edge cases: SettingsService not yet ready when KrControl spawns (race per ADR-0010 R5 — `call_deferred` for UIService self-init; scene Controls always after autoload `_ready()` complete per Godot order); settings_changed signal during state transition.

---

## Test Evidence

**Story Type**: Integration
**Required**:
- `tests/integration/workspace/settings_subscription_test.gd` — AC-40, AC-48, AC-48b, AC-48c (gdunit4)
- `production/qa/evidence/workspace-settings-cascade-evidence.md` — AC-41b text_scale visual + AC-47 focus thickness manual

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (WorkspaceData), Story 003 (HypothesisNode KrCard), Story 005 (MemoPanel), Story 006 (Camera2D), ADR-0009 SettingsService implementation (Settings & Accessibility epic)
- Unlocks: Story 011 (focus ring visual uses thickness from this story's subscription)
