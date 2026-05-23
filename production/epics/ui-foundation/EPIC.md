# Epic: UI Foundation

> **Layer**: Foundation (Core — depends only on Settings/Library autoload signals)
> **GDD**: `design/gdd/ui-foundation.md`
> **Architecture Module**: `UIService` autoload SECOND + `KrCustomControl` tree (21 classes per ADR-0010 §Architecture Diagram) + Theme + 17 type variations (ADR-0004 amend-1) + Kr3PaneLayout primitive + KrFreezeOverlay + Reduced Motion gateway + dual focus ring composite + `announce_text` live-region API
> **Status**: Ready
> **Stories**: 5 stories created 2026-05-18 — minimum-viable scope to unblock #6 Reasoning Workspace UI stories (003b/005/006/009/010/011) + #7 Brief Editor. Full 21-class KrCustomControl tree + R8 dual focus ring polish + AC-18 viewport too-small dialog deferred to follow-up cycle.
> **Created**: 2026-05-18

## Overview

UI Foundation provides the cross-system UI infrastructure that all gameplay systems (#5/#6/#7/#9/#10) depend on: a Theme registry with type variations for consistent visual identity, a `KrCustomControl` base hierarchy that auto-wires Settings subscription + AccessKit roles + Reduced Motion gating, and `UIService` autoload SECOND providing animation gateway + live-region announcement + Theme runtime reload cascade.

This epic implements the **minimum-viable scope** for unblocking Reasoning Workspace UI stories. Specifically: UIService autoload + Theme runtime reload + KrCustomControl base + 6 essential type variations (Pane / HypothesisNode / MemoLabel / MemoEdit / Banner / Button) + tween_property gateway + announce_text live-region API. **Deferred to follow-up cycle**: full 21-class KrCustomControl tree, R8 dual focus ring composite rendering (3 options to evaluate), Kr3PaneLayout primitive completeness (3-pane width clamp at 1280-1365 dynamic), AC-18 viewport-too-small warning dialog.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0010: UI Foundation Architecture | UIService SECOND autoload + KrCustomControl base + Theme runtime reload (VR-UI1 PASS — auto NOTIFICATION_THEME_CHANGED cascade) + Reduced Motion gateway + dual focus ring composite | LOW (VR sprint closure) |
| ADR-0010 amend-1: KrCustomControl Role Corrections + Live-Region | 7 enum corrected mapping (KrPane → ROLE_PANEL etc.) + UIService.announce_text(source, message, priority) via DisplayServer.accessibility_update_set_live + AccessibilityLiveMode {LIVE_OFF=0, LIVE_POLITE=1, LIVE_ASSERTIVE=2} (VR-UI6 PASS) | LOW |
| ADR-0004: Korean Text Rendering MSDF Font | 3-font family lock (본명조 court_title + Pretendard body_sans + IBM Plex Mono code_mono) | LOW |
| ADR-0004 amend-1: Component Type Variations Expansion | 17 Theme type variations (Pane/Header/Card/HypothesisNode/MemoLabel/CommentLabel/CourtHeadline/CaptionLabel/Banner family 등) + text_scale runtime reload single-emit cascade | LOW |
| ADR-0009: Settings Storage Format | SettingsService FIFTH autoload + reduced_motion + text_scale + focus_indicator_thickness signals (UIService subscribes) | LOW |
| ADR-0008 amend-4: Verification Sprint FAIL Closure | AccessibilityRole corrected enum mapping (ROLE_REGION→ROLE_PANEL, etc. — runtime VR-UI6 verified 46-entry enum) | LOW |

## GDD Requirements (TR-ui-*)

22 TR-ui IDs in tr-registry covering Theme registration, KrCustomControl tree, Kr3PaneLayout, tween_property gateway, announce_text API, AccessKit role assignment, viewport reflow, Reduced Motion handling. All addressed by ADR-0010 + amend-1 (already covered in TR registry).

Story-level decomposition focuses on minimum-viable path; remaining TR-ui (full 21-class hierarchy, R8 dashed border) deferred to follow-up stories within this epic.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [UIService autoload + Theme load + viewport_resized signal](story-001-ui-service-autoload.md) | Logic | Complete | ADR-0010 §Decision |
| 002 | [KrCustomControl base + KrControlHelper](story-002-kr-custom-control-base.md) | Logic | Complete | ADR-0010 §Decision Note (composition + helper pattern) |
| 003 | [6 essential Theme type variations + base styles](story-003-theme-type-variations.md) | Config/Data + UI | Ready | ADR-0004 + amend-1 |
| 004 | [tween_property gateway + Reduced Motion path](story-004-tween-property-gateway.md) | Logic | Complete | ADR-0010 §Decision + §Risk R7 |
| 005 | [announce_text live-region API + AccessKit role helper](story-005-announce-text-api.md) | Logic + Integration | Ready | ADR-0010 amend-1 §G3 + amend-4 §F1 corrected enum |

## Deferred (follow-up cycle — UI Foundation v2)

- Full 21-class KrCustomControl tree (currently only base + workspace-relevant subclasses)
- R8 dual focus ring composite rendering (3 implementation options to evaluate: overlap StyleBox / `_draw()` custom dashed / shader)
- Kr3PaneLayout full primitive (currently subset for workspace 3-pane usage)
- KrFreezeOverlay full implementation (workspace inline usage acceptable)
- AC-18 viewport-too-small warning dialog (low-priority — game requires 1366 floor)
- 11 remaining Theme type variations beyond the 6 essential (Header/Card/LibraryCard/EnvelopeCard/GroundsCard/Dialog/Slider/Banner subvariants/etc.)
- AccessKit live-region API runtime test on multiple screen readers (VoiceOver/NVDA/Orca — VR-UI6 PASS is API existence only)

## Definition of Done (minimum-viable)

- All 5 stories implemented + reviewed + closed via `/story-done`
- 6 essential type variations registered + applied to test scenes
- UIService autoload registered in `project.godot [autoload]` SECOND position
- Workspace story-003b (KrCard scene wrapping) becomes implementable (KrCard base + theme_type_variation + tween_property + announce_text available)
- Logic stories: passing test files in `tests/unit/ui_foundation/`
- Integration stories (003 cascade + 005 live-region): integration tests in `tests/integration/ui_foundation/` OR manual evidence in `production/qa/evidence/`

## Next Step

Run `/story-readiness ui-foundation/story-001-ui-service-autoload.md` then `/dev-story` per story. Stories ordered for dependency safety: 001 → 002 → 003 (Config/Data, can parallel 002) → 004 → 005.
