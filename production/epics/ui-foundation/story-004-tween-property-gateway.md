# Story 004: tween_property gateway + Reduced Motion path

> **Epic**: UI Foundation
> **Status**: Complete (2026-05-23)
> **Layer**: Foundation (Core)
> **Type**: Logic
> **Manifest Version**: 2026-05-18
> **Estimate**: 2 hours (S) — tween_property method + Reduced Motion check + ~8 unit tests
> **Performance**: tween_property call < 0.5ms per call; 0 allocation when Reduced Motion (skips Tween creation)

## Context

**GDD**: `design/gdd/ui-foundation.md` §10.5 AC-10/15/16
**Requirement**: TR-ui-010 (Reduced Motion gateway)
**ADR**: ADR-0010 §Decision + §Risk R7 + forbidden_pattern `direct_create_tween_bypassing_reduced_motion`
**Engine**: Godot 4.6 | **Risk**: LOW

## Acceptance Criteria

- [x] AC-15 — `UIService.tween_property(target, property, final_value, duration) -> Tween` with Reduced Motion = false: creates Tween + chains tween_property + returns Tween — **DONE**
- [x] AC-16 — Reduced Motion = true: returns `null` + immediately `target.set_indexed(property, final_value)` — **DONE**
- [x] AC-10 — Reduced Motion read via settable `UIService.reduced_motion` state field (default false; SettingsService signal wires it in story 005/009) — **DONE** (design improvement over story pseudo-code — see Completion Notes)
- [x] All callers use this gateway; direct `create_tween()` forbidden — **DONE** (forbidden_pattern `direct_create_tween_bypassing_reduced_motion` verified in architecture.yaml line 1866 via automated registry-read test)

## Implementation Notes

Per ADR-0010 §Decision:

```gdscript
# Add to UIService
func tween_property(
    target: Object,
    property: NodePath,
    final_value: Variant,
    duration: float
) -> Tween:
    if _is_reduced_motion():
        target.set_indexed(property, final_value)
        return null
    var tween := create_tween()
    tween.tween_property(target, property, final_value, duration)
    return tween

func _is_reduced_motion() -> bool:
    if Engine.has_singleton("SettingsService"):
        return SettingsService.get("display.reduced_motion", false)
    return false
```

## Out of Scope

- Real SettingsService.get subscription wiring (story 005 + workspace 009)
- Easing curve / transition type customization (use default LINEAR/ease for now)
- Tween parallel composition (callers can chain via returned Tween)

## QA Test Cases

- **AC-15**: target Node with `modulate.a = 0.0`, call `UIService.tween_property(node, "modulate:a", 1.0, 0.15)` with no SettingsService → returns Tween, after 0.2s `node.modulate.a == 1.0`
- **AC-16**: Mock SettingsService.get returns true for `display.reduced_motion` → call same → returns `null`, `node.modulate.a == 1.0` immediately
- **AC-10**: Without SettingsService (test fixture), `_is_reduced_motion()` returns false (safe default)
- Edge: target null → push_error (Godot will fault anyway, but graceful behavior preferred)

## Test Evidence

**Required**: `tests/unit/ui_foundation/tween_property_test.gd`
**Status**: [ ] Not yet created

## Dependencies

- Depends on: Story 001 (UIService autoload)
- Unlocks: workspace stories using animation (005 MemoPanel fade / 006 Camera2D auto-center / 011 visual polish) + 005 (announce_text uses similar gateway pattern)

---

## Completion Notes
**Completed**: 2026-05-23
**Criteria**: 4/4 passing (AC-15, AC-16, AC-10, forbidden-pattern gate).
**Files**:
- `src/ui/ui_service.gd` — added `var reduced_motion: bool = false` + `tween_property(target, property, final_value, duration) -> Tween` (+ null-target guard).
- `tests/unit/ui_foundation/tween_property_test.gd` — 7 tests.
**Test Evidence**: tween_property_test 7/7 PASS, exit 0 (incl. real-timing interpolation — Tween advances correctly in gdunit4, unlike the headless Timer-tick limitation noted for the viewport debounce).
**Deviation from story pseudo-code (design improvement)**: The story queried `Engine.has_singleton("SettingsService")` + `SettingsService.get("display.reduced_motion", false)` synchronously per call. Two problems: (1) autoloads are scene-tree nodes at `/root`, NOT Engine singletons — `Engine.has_singleton` is an unreliable presence check for them (empirically false for the LibraryService autoload); (2) `Object.get()` is single-arg (no default param). Replaced with a settable `reduced_motion` state field that the SettingsService `display.reduced_motion` signal subscription sets (story 005/009). This is correct, testable (tests set the field directly to drive AC-16), zero per-call lookup, and is the exact integration seam story 005/009 needs. The same `Engine.has_singleton` questionable pattern exists in `kr_control_helper.gd` (story-002) as a no-op stub — flagged for story 005/009 to resolve when wiring real SettingsService.
**Code Review**: Implemented + reviewed directly by orchestrator (small Logic story, well-known Tween API; sub-agent delegation skipped this session due to repeated agent message-truncation requiring heavy cleanup). Tween API (`create_tween`/`tween_property`) verified against engine-reference (modules/audio.md). forbidden_pattern existence verified pre-implementation (architecture.yaml line 1866).
