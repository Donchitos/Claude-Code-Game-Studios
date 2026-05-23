# Story 003: 6 essential Theme type variations + base styles

> **Epic**: UI Foundation
> **Status**: Ready
> **Layer**: Foundation (Core)
> **Type**: Config/Data + UI
> **Manifest Version**: 2026-05-18
> **Estimate**: 2 hours (S-M) — register 6 type variations on UIService.theme + base StyleBox/font/color values per Art Bible + cascade test (text_scale changes propagate to KrCustomControl labels)
> **Performance**: text_scale cascade < 50ms per control-manifest guardrail (VR-UI1 PASS — automatic NOTIFICATION_THEME_CHANGED)

## Context

**GDD**: `design/gdd/ui-foundation.md` §3.1 + §10.3 AC-2/AC-8 (text_scale cascade)
**Requirement**: TR-ui-002 (Theme type variations) + TR-ui-007 (text_scale cascade)
**ADR**: ADR-0004 + amend-1 (17 type variations) — implementing 6 essential subset for workspace
**Engine**: Godot 4.6 | **Risk**: LOW (VR-UI1 PASS confirmed Theme cascade)

## Acceptance Criteria

- [ ] 6 type variations registered on UIService.theme (in UIService._ready() or dedicated method called from _ready()):
  - `&"Pane"` (Container — Pane bg color + padding)
  - `&"HypothesisNode"` (PanelContainer — KrCard variant — 200×48 hero shape)
  - `&"MemoLabel"` (Label — body_sans font + base font_size 14)
  - `&"MemoEdit"` (TextEdit — code_mono or body_sans font + 14)
  - `&"Banner"` (PanelContainer — 32px height + ink-black bg + white text)
  - `&"Button"` (Button — base button styling)
- [ ] AC-2 — `UIService.set_text_scale(scale: float)` method: calls `theme.set_font_size(...)` for each registered variation with `base_size × scale`. NOTIFICATION_THEME_CHANGED auto-cascades.
- [ ] AC-8 — text_scale cascade: KrCustomControl subclass instances (story 002 KrPane / KrButton / KrBanner + a test KrLabel) auto-reflow when text_scale changes (verify via NOTIFICATION_THEME_CHANGED handler firing)
- [ ] Base font_size constants (`PANE_FONT_SIZE = 14`, `HEADER_FONT_SIZE = 24`, etc.) defined in UIService for centralized tuning
- [ ] No inline `theme_override_*` properties (forbidden_pattern `inline_theme_override_without_type_variation`)

## Implementation Notes

Per ADR-0004 amend-1 + ADR-0010:

```gdscript
# Add to UIService
const BASE_FONT_SIZE_BODY := 14   # MemoLabel, MemoEdit, Button base
const BASE_FONT_SIZE_HEADER := 24  # CourtHeadline (future)
const HYPOTHESIS_NODE_SIZE := Vector2(200, 48)

func _register_type_variations() -> void:
    # Pane
    var pane_style := StyleBoxFlat.new()
    pane_style.bg_color = Color(0.96, 0.95, 0.92)  # 판결지 #F5F2EC
    pane_style.set_content_margin_all(16)
    _theme.set_stylebox(&"panel", &"Pane", pane_style)
    
    # HypothesisNode (KrCard variant)
    var hypothesis_style := pane_style.duplicate()
    hypothesis_style.set_content_margin_all(8)
    _theme.set_stylebox(&"panel", &"HypothesisNode", hypothesis_style)
    
    # MemoLabel / MemoEdit
    _theme.set_font_size(&"font_size", &"MemoLabel", BASE_FONT_SIZE_BODY)
    _theme.set_font_size(&"font_size", &"MemoEdit", BASE_FONT_SIZE_BODY)
    
    # Banner — ink-black bg
    var banner_style := StyleBoxFlat.new()
    banner_style.bg_color = Color(0.06, 0.06, 0.06)
    _theme.set_stylebox(&"panel", &"Banner", banner_style)
    
    # Button — base
    _theme.set_font_size(&"font_size", &"Button", BASE_FONT_SIZE_BODY)

func set_text_scale(scale: float) -> void:
    _theme.set_font_size(&"font_size", &"MemoLabel", int(BASE_FONT_SIZE_BODY * scale))
    _theme.set_font_size(&"font_size", &"MemoEdit", int(BASE_FONT_SIZE_BODY * scale))
    _theme.set_font_size(&"font_size", &"Button", int(BASE_FONT_SIZE_BODY * scale))
    # NOTIFICATION_THEME_CHANGED cascades automatically (VR-UI1 PASS)
```

Add `_register_type_variations()` call to UIService `_ready()` (after Timer setup).

Font resources: use Godot default for now (full court_title MSDF + Pretendard + IBM Plex Mono integration deferred to art-director asset pipeline). 6 essential variations work with system default fonts.

## Out of Scope

- Full 17 type variations (Header / Card / LibraryCard / EnvelopeCard / GroundsCard / Dialog / Slider / Banner subvariants) — follow-up
- MSDF font asset integration (`assets/fonts/court_title.tres` etc.) — art-director pipeline
- text_scale + Reduced Motion cross-cutting (story 004 owns Reduced Motion)
- Per-screen visual polish (workspace 011)

## QA Test Cases

- 6 type variations registered: `_theme.has_stylebox(&"panel", &"Pane")` true etc. for each
- AC-2: `UIService.set_text_scale(1.5)` → `theme.get_font_size(&"font_size", &"MemoLabel") == 21` (14 × 1.5)
- AC-8 cascade: KrPane instance + MemoLabel child; call `set_text_scale(1.5)`; assert MemoLabel `_notification(NOTIFICATION_THEME_CHANGED)` fires (use NotifyingLabel helper from VR-UI1 prototype pattern)
- No inline override: grep src/ui/ for `add_theme_*_override` calls → 0 hits (or only in test fixtures)

## Test Evidence

**Required**: `tests/unit/ui_foundation/theme_variations_test.gd` (Logic portion) + `production/qa/evidence/ui_theme_cascade-evidence.md` (UI portion — screenshot at text_scale 1.0 / 1.5 / 2.0)
**Status**: [ ] Not yet created

## Dependencies

- Depends on: Story 001 (UIService autoload + theme instance), Story 002 (KrPane / KrCard / KrButton / KrBanner subclasses for cascade test)
- Unlocks: workspace stories that use these 6 variations (003b HypothesisNode / 005 MemoPanel / 008 ReadOnlyIndicator / 011 visual polish)
