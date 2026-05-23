# Story 010: AccessKit roles per amend-4 §F1 corrected mapping + live-region announce cascade

> **Epic**: Reasoning Workspace
> **Status**: Ready
> **Layer**: Feature (Gameplay)
> **Type**: Logic + UI (Logic primary — role assignment is structural)
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/reasoning-workspace.md` (§9.5 Feedback Patterns, §9.6 Accessibility Requirements, §10.8 Accessibility)
**Requirement**: TR-WORKSPACE-LAYOUT-001 + (cross-cover TR-settings-014 screen_reader_detected, TR-settings-024 SettingsScreen role mapping)

**ADR Governing Implementation**: ADR-0008 amend-4 §F1 (AccessibilityRole 7 enum corrected mapping — retroactive supersede of hallucinated names) + ADR-0010 amend-1 §G1 (KrCustomControl 21 클래스 corrected mapping) + amend-1 §G3 (UIService.announce_text live-region API — VR-UI6 PASS path: DisplayServer.accessibility_update_set_live + AccessibilityLiveMode)
**ADR Decision Summary**: Workspace Controls use corrected AccessKit role enum (verified runtime via VR-UI6 dump 46-entry AccessibilityRole). Hallucinated names (ROLE_REGION/HEADING/GROUP/RADIO_GROUP/COMBO_BOX/STATUS/ALERT) replaced per amend-4 §F1. Live-region absence in role enum mitigated via UIService.announce_text(source, message, priority) → DisplayServer.accessibility_update_set_live(rid, mode) wrapper.

**Engine**: Godot 4.6 | **Risk**: LOW (post-sprint VR-UI2 + VR-UI6 PASS runtime confirmed)
**Engine Notes**: 46 AccessibilityRole values runtime-dumped (VR-UI6 prototype). `DisplayServer.accessibility_update_set_live(id, live)` + `AccessibilityLiveMode {LIVE_OFF=0, LIVE_POLITE=1, LIVE_ASSERTIVE=2}` confirmed. KrCustomControl `_apply_access_kit_role()` override hook (per ADR-0010 §Decision).

**Control Manifest Rules**: see `docs/architecture/control-manifest.md` v2026-05-18 — Feature Layer Required/Forbidden/Guardrails apply to this story

---

## Acceptance Criteria

Scope: §10.8 Accessibility (AC-45 ~ AC-48 partial) — 4 AC focused on role + announcement.

- [ ] AC-44a — Workspace root Controls have corrected AccessKit roles applied:
  - DeskPane root → `ROLE_PANEL` (=6)
  - DeskCanvas → `ROLE_TREE` (=27)
  - HypothesisNode → `ROLE_TREE_ITEM` (=28)
  - MemoPanel → `ROLE_PANEL` (=6)
  - SubmitButton → `ROLE_BUTTON` (=7)
  - ReadOnlyIndicator → `ROLE_STATIC_TEXT` (=4) + live-region announce
  - Confirmation dialog (story 007) → `ROLE_DIALOG` (=44)
  - HypothesisNode label edit → `ROLE_TEXT_FIELD` (=18)
  - HypothesisNode memo edit → `ROLE_MULTILINE_TEXT_FIELD` (=19)
- [ ] AC-44b — `accessibility_name` populated for each Control (HypothesisNode name = label + evidence count, MemoPanel name = "메모 패널", etc.)
- [ ] AC-44c — ReadOnlyIndicator (KrBanner) announces "평가 완료 — 읽기 전용" with priority POLITE via `UIService.announce_text(self, text, AnnouncePriority.POLITE)` on `_ready()` (per amend-1 §G3)
- [ ] AC-44d — Crash recovery CriticalBanner uses priority ASSERTIVE (per amend-1 §G3 + ADR-0009 §G3 cascade)
- [ ] AC-45 — keyboard-only full workflow completion (sub-step KB workflow per §10.8 AC-45) — focus visible throughout, status bar guidance, role announcements correct
- [ ] AC-48d — Forbidden_pattern check: no Workspace code references hallucinated enum names (`ROLE_REGION`, `ROLE_GROUP`, `ROLE_HEADING`, `ROLE_STATUS`, `ROLE_ALERT`, `ROLE_RADIO_GROUP`, `ROLE_COMBO_BOX`) — gdunit4 meta-test grep

---

## Implementation Notes

Per ADR-0008 amend-4 §F1 + ADR-0010 amend-1 §G1/G3:

```gdscript
# DeskPane root
func _apply_access_kit_role() -> void:
    accessibility_role = AccessibilityRole.ROLE_PANEL   # =6 (was ROLE_REGION — hallucinated)
    accessibility_name = "추론 작업대"

# DeskCanvas (SubViewportContainer + SubViewport host)
func _apply_access_kit_role() -> void:
    accessibility_role = AccessibilityRole.ROLE_TREE   # =27
    accessibility_name = "사고 트리"

# HypothesisNode
func _apply_access_kit_role() -> void:
    accessibility_role = AccessibilityRole.ROLE_TREE_ITEM   # =28
    accessibility_name = "%s (증거 %d개)" % [data.label, data.evidence.size()]

# ReadOnlyIndicator (KrBanner subclass per ADR-0010 amend-1 §G3)
func _ready() -> void:
    super._ready()
    accessibility_role = AccessibilityRole.ROLE_STATIC_TEXT   # =4 (was ROLE_STATUS — hallucinated)
    UIService.announce_text(self, "평가 완료 — 읽기 전용", UIService.AnnouncePriority.POLITE)

# Crash recovery banner (CriticalBanner — used by story 008)
func _on_schema_version_mismatch() -> void:
    var banner := CriticalBanner.new()
    banner.text = "스냅샷 손상 — 케이스 재시작 권장"
    add_child(banner)
    UIService.announce_text(banner, banner.text, UIService.AnnouncePriority.ASSERTIVE)
```

- Per amend-4 §F4 registry `accessibility_role_pre_verification_implementation` forbidden_pattern — gdunit4 meta-test cross-references corrected mapping table; this story passes that gate by using only corrected names
- VR-UI6 PASS confirms `DisplayServer.accessibility_update_set_live` + `LIVE_POLITE/LIVE_ASSERTIVE` enum — UIService.announce_text body fully implementable
- `kr_banner_dynamic_show_without_announce` forbidden_pattern (amend-1 §G5) — ReadOnlyIndicator + CriticalBanner explicitly satisfy via super()._ready() pattern
- `accessibility_name` separate from role — gives unique identity per element (mitigates Risk R3 about ROLE_STATIC_TEXT cap across KrHeader + KrBanner family)

---

## Out of Scope

- Story 003: HypothesisNode role assignment (this story does cross-cutting audit + announcement layer; per-story role assignment was in stories 001-008)
- Story 011: Focus ring visual + dual focus implementation (this story enforces role; story 011 paints focus ring per `accessibility.focus_indicator_thickness_px`)
- VR-D7 (Korean IME) interactive prototype — non-blocking; affects KrTextEdit memo input but no role assignment
- AccessKit screen reader manual verification (story 011 visual + audio polish)
- ADR-0010 amend-1 §G5 forbidden_pattern enforcement (gdunit4 meta-test — out-of-epic CI scope; story 010 only ensures Workspace code complies)

---

## QA Test Cases

- **AC-44a Logic**: For each Workspace Control, assert `accessibility_role == EXPECTED_ROLE` matching the table; values come from `AccessibilityRole.ROLE_*` enum (verified non-hallucinated)
- **AC-44b Logic**: For each Workspace Control, assert `accessibility_name != ""` and meets the per-control naming convention
- **AC-44c Manual**: Trigger READ_ONLY transition; verify screen reader (VoiceOver / NVDA / Orca) announces "평가 완료 — 읽기 전용" at POLITE priority
- **AC-44d Manual**: Trigger schema_version_mismatch crash recovery; verify screen reader announces critical banner at ASSERTIVE priority (interrupts current speech)
- **AC-45 Manual**: Execute keyboard-only full workflow (per §10.8 AC-45 — 8 steps) → all controls announce correctly + focus visible throughout
- **AC-48d Logic**: gdunit4 meta-test — grep `src/scenes/workspace/` for `ROLE_REGION|ROLE_GROUP|ROLE_HEADING|ROLE_STATUS|ROLE_ALERT|ROLE_RADIO_GROUP|ROLE_COMBO_BOX` → 0 hits

Edge cases: HypothesisNode with no evidence (accessibility_name = "label (증거 0개)" — verify no null), MemoPanel `_apply_access_kit_role` before scene tree ready (defensive null check).

---

## Test Evidence

**Story Type**: Logic + UI
**Required**:
- `tests/unit/workspace/accesskit_roles_test.gd` — AC-44a, AC-44b, AC-48d (gdunit4)
- `production/qa/evidence/workspace-screen-reader-walkthrough.md` — AC-44c, AC-44d, AC-45 manual (accessibility-specialist sign-off)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (DeskPane root), Story 003 (HypothesisNode + label edit), Story 005 (MemoPanel + MemoEdit), Story 007 (Confirmation dialog), Story 008 (ReadOnlyIndicator + CriticalBanner), Story 009 (Settings subscription for screen_reader_detected)
- Unlocks: Story 011 (focus visual polish), Story 012 (Pillar compliance + edge cases)
