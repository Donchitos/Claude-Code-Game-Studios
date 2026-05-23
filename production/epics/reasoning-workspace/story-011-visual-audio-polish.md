# Story 011: Visual + audio polish

> **Epic**: Reasoning Workspace
> **Status**: Ready
> **Layer**: Feature (Gameplay)
> **Type**: Visual/Feel
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/reasoning-workspace.md` (§8.1 Visual Requirements — 7 sub, §8.2 Audio Requirements — 6 sub including 21-event catalog, §10.7 UI Visual / Interaction visual portion)
**Requirement**: TR-WORKSPACE-LAYOUT-001 (visual portion)

**ADR Governing Implementation**: ADR-0004 + amend-1 (17 Theme type variations) + ADR-0008 §1 (DeskPane visual hierarchy) + ADR-0010 (KrCustomControl dual focus ring composite per §Decision Risk R8 — inner solid + outer dashed)
**ADR Decision Summary**: Workspace visual polish applies Theme type variations (HypothesisNode / MemoLabel / CommentLabel / CourtHeadline / CaptionLabel / Banner family) + dual focus ring composite (inner=2px solid 잉크블랙 fixed, outer=`accessibility.focus_indicator_thickness_px` 1-4px dashed per ADR-0010 R8). Audio plays 21 events from audio-director catalog via AudioService (`weight-stamp` for evidence attach, `paper-blocked` for invalid drop, etc.).

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: StyleBoxFlat has no native dashed border (per ADR-0010 R8) — implementer chooses among 3 options: (1) two overlap StyleBox at different draw layers, (2) Control `_draw()` override + custom draw_rect dashed line routine, (3) shader. Decision made at story implementation time + recorded in epic notes for future stories.

**Control Manifest Rules**: see `docs/architecture/control-manifest.md` v2026-05-18 — Feature Layer Required/Forbidden/Guardrails apply to this story

---

## Acceptance Criteria

Scope: §10.7 visual portion + §8.1/§8.2 spec compliance.

- [ ] AC-37 — HypothesisNode bottom evidence rule visualization: 6 discrete steps (cap=5 → ρ ∈ {0.0, 0.2, 0.4, 0.6, 0.8, 1.0}); 200×48 hero shape with inner padding rule: ρ=1.0 → 184px rule length, ρ=0.0 → 0px (or 36.8/110.4/184px ±2px per cycle 4 padding correction)
- [ ] AC-38b — KrCard hover state: subtle 잉크블랙 glow (StyleBoxFlat per Theme variation) + 50ms ease-in
- [ ] AC-38c — KrCard focus ring composite: inner 2px solid 잉크블랙 (fixed) + outer dashed `accessibility.focus_indicator_thickness_px` (1-4px, consumed from story 009 settings subscription) via chosen ADR-0010 R8 path
- [ ] AC-39b — ReadOnlyIndicator banner pulse: 0.5s opacity oscillation (50% ↔ 100%) on first entry; Reduced Motion → no pulse
- [ ] AC-40c — Drag preview opacity: 70% transparent KrCard ghost following cursor (per ADR-0008 §2 drag preview pattern)
- [ ] AC-39c — MemoPanel fade transition curve: ease-in-out 0.15s (visual polish on top of story 005 duration)
- [ ] AC-37b — All 21 audio events from §8.2 audio-director catalog wired: weight-stamp / paper-blocked / paper-rustle / ink-pen-mark / book-close / etc. (verify each event triggers from correct game action)

---

## Implementation Notes

Per ADR-0004 amend-1 + ADR-0008 §1 + ADR-0010 R8:

```gdscript
# HypothesisNode evidence rule (AC-37) — Control _draw override
func _draw() -> void:
    # Bottom evidence rule — left edge inset 8px (per cycle 4 padding correction)
    var rule_density: float = float(data.evidence.size()) / float(EVIDENCE_CAP)
    var rule_length := rule_density * 184.0   # 200px node width - 16px padding (8 left + 8 right)
    var rule_y := size.y - 4.0
    draw_line(Vector2(8, rule_y), Vector2(8 + rule_length, rule_y), Color(0.06, 0.06, 0.06), 2.0)

# Dual focus ring composite (AC-38c) — choose ADR-0010 R8 option 2 (_draw override)
func _draw() -> void:
    # ... bottom rule first
    if has_focus():
        var inner_thickness := 2.0
        var outer_thickness: float = float(SettingsService.get("accessibility.focus_indicator_thickness_px", 1))
        # Inner solid
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.06, 0.06), false, inner_thickness)
        # Outer dashed
        _draw_dashed_rect(Rect2(-2, -2, size.x + 4, size.y + 4), Color(0.06, 0.06, 0.06), outer_thickness, 4.0, 4.0)

func _draw_dashed_rect(rect: Rect2, color: Color, thickness: float, dash_len: float, gap_len: float) -> void:
    # Custom draw_rect dashed routine — iterates edges drawing line segments
    pass  # full implementation at impl time

# Drag preview (AC-40c)
func _get_drag_data(_pos: Vector2) -> Variant:
    var preview := duplicate()
    preview.modulate.a = 0.7
    set_drag_preview(preview)
    # ... rest

# Audio (AC-37b) — wire 21 events per §8.2 catalog
# AudioService.play("weight-stamp") on evidence attach (story 004)
# AudioService.play("paper-blocked") on cap rejection (story 003 + story 008 READ_ONLY)
# AudioService.play("ink-pen-mark") on memo char input (story 005)
# ... full 21-event map
```

- Theme type variation registration in `&"HypothesisNode"` per ADR-0004 amend-1 — actual StyleBox values come from art-director spec
- ADR-0010 R8 — implementation decision: pick option 2 (`_draw()` override) for HypothesisNode; KrButton + KrDialog can reuse via base KrControl helper
- Audio events — list of 21 events in GDD §8.2 → AudioService.play(event_name) calls scattered across stories 003/004/005/007/008/011
- Reduced Motion (story 009) — pulse animations (AC-39b) gate via UIService.tween_property null-return

---

## Out of Scope

- Story 005: MemoPanel layout + transition duration (this story polishes the curve, not the duration)
- Story 003: HypothesisNode invariant enforcement (this story polishes appearance, not behavior)
- Story 009: Settings subscription wiring (this story consumes `accessibility.focus_indicator_thickness_px` via call-site)
- Story 010: AccessKit role assignment (this story is purely visual + audio)
- Art-director asset spec generation (separate `asset-spec` workflow — story 011 consumes specs, doesn't generate them)
- audio-director sound asset authoring (separate workflow — story 011 wires events, doesn't author SFX)

---

## QA Test Cases

- **AC-37 Manual**: Build HypothesisNode with 0/1/2/3/4/5 evidence → verify bottom rule length matches discrete step pixel value (±2px)
- **AC-38b Manual**: Hover over KrCard → glow visible within ~50ms; mouse out → glow fades
- **AC-38c Manual**: Tab to focus HypothesisNode → inner 2px ring + outer dashed visible; change `focus_indicator_thickness_px` 1→4 → outer dashed width updates immediately on next focus
- **AC-39b Manual**: Trigger READ_ONLY transition → ReadOnlyIndicator pulses 0.5s opacity oscillation; toggle reduced_motion ON → no pulse on next trigger
- **AC-40c Manual**: Drag LibraryCard → preview ghost at 70% opacity follows cursor
- **AC-39c Manual**: MemoPanel A↔B transition → opacity curve is ease-in-out (not linear)
- **AC-37b Manual**: Trigger each of 21 audio events from gameplay actions; verify each plays correct SFX from §8.2 catalog

---

## Test Evidence

**Story Type**: Visual/Feel
**Required**: `production/qa/evidence/workspace-visual-audio-polish-evidence.md` — manual walkthrough with screenshots / video clips for each AC + art-director + audio-director + ux-designer sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (HypothesisNode), Story 005 (MemoPanel), Story 006 (Camera2D), Story 008 (ReadOnlyIndicator), Story 009 (Settings subscription), Story 010 (AccessKit roles — focus ring assumes correct ROLE_TREE_ITEM etc.)
- Unlocks: Story 012 (performance gate — visual polish should not regress 60fps target)
