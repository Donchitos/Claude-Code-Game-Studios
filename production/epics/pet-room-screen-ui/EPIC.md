# Epic: Pet Room Screen UI

> **Layer**: Presentation
> **GDD**: design/gdd/pet-room-screen-ui.md
> **Architecture Module**: Pet Room Screen UI (#18)
> **Status**: Ready
> **Stories**: 7 stories (Stories 001, 003, 004 implemented — see Stories table)

## Overview

Pet Room Screen UI is the convergence point where six other systems render as
one screen — the default `/child/pet-room` route (Main Navigation Shell #17,
Tab 1) that bé sees every time the app opens. A `GameWidget` hosts exactly one
`FlameGame` instance (`MochiComponent` + a fixed room-background
`SpriteComponent`), with Flutter overlay chrome (mood/energy status row, level
progress bar) and modal layers (tap-on-Mochi context menu, Wardrobe bottom
sheet) stacked above it via `GameWidget.overlayBuilderMap`. The system owns no
game-logic state of its own — it reads `petMoodProvider`/`petEnergyProvider`
(#6), `petLevelProvider`/`levelProgressProvider` (#16), and `itemCatalogProvider`
(#3) — and contributes exactly two owned computations: **Formula 1** (a Flame
canvas draw-call budget contract, fixed at 5 calls / 2.5% of the project's
≤200 budget, ratified by ADR-0001) and **Formula 2** (a tap hit-area padding
formula that Pet Interaction #14 explicitly delegated to this GDD — it
guarantees `hitBoxSize ≥ 80dp` on `MochiComponent`'s `TapCallbacks` region
regardless of the Mochi sprite's actual rendered size at any evolution stage).
`StatefulShellRoute` keeps the Flame game loop mounted and running across tab
switches (never disposed), so triggered-state animations can complete
off-screen — this screen must never call an init/reset method on the already-
running `FlameGame` or the singleton `GameEventBus` when the tab regains focus.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-------------------|-------------|
| ADR-0001: Draw-Call Budget Scope | Scopes the ≤200 draw-call budget to the Flame canvas only (SpriteComponent-level, post-SpriteBatch); Flutter overlay compositing is governed separately by frame build/raster time, not folded into the same count. Ratifies #18's Formula 1 (`drawCalls_sceneFlame = 5`) as-is. | MEDIUM-HIGH |
| ADR-0017: Pet Room Screen Rendering & Interaction Contract | Covers the remaining 4 requirements: (TR-petroom-001) concrete widget/component tree, z-order via `priority`, and `overlayBuilderMap` key contract (`chrome`/`context_menu`/`wardrobe`) with `showModal`/`dismissModal` as the sole modal-mutation path; (TR-petroom-003, Formula 2) the `computeHitArea()` pure function plus a `MochiComponent.render()` override that pads `size` for the hit test while keeping the pinned sprite art unscaled — built directly on ADR-0016's already-Accepted hit-area contract and `MochiComponent` base class/mixins (no `TapCallbacks`, per ADR-0016); (TR-petroom-004) a new `GameEventType.modalVisibilityChanged` bridge event gating Flame-side triggered-state visual playback while a modal is open; (TR-petroom-005) ratifies the existing `PetRoomScreen` singleton-`FlameGame`-per-`State` pattern (from ADR-0014 Story 002) as permanent, with two explicit forbidden patterns for future stories. | MEDIUM-HIGH |

**Epic Engine Risk: MEDIUM-HIGH** — this is the first (and so far only) GDD hosting an actual `FlameGame` canvas, per `docs/architecture/architecture.md`'s Module Ownership table ("Flame Canvas rendering — ⚠️ MEDIUM-HIGH: Impeller default backend, governed by ADR-0001's draw-call budget but pipeline behavior needs device testing"). Impeller is the default renderer on iOS (all devices) and selectively on Android (Vulkan-capable, API 29+) per `docs/engine-reference/flutter-flame/VERSION.md` — no physical-device profiling has occurred yet for this screen (ADR-0001's Validation Criteria requires 3 device passes: Android Impeller/Vulkan, Android OpenGLES fallback, iOS Impeller/Metal). `MochiComponent` uses `DragCallbacks` only (per ADR-0016 — **not** `TapCallbacks`, ruled out for a gesture-arena conflict with `DragCallbacks`), consistent with `deprecated-apis.md`'s ban on the deprecated `TapDetector`/`DragDetector` mixins.

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-petroom-001 | Screen composition z-order; `GameWidget` hosts exactly one `FlameGame` | ADR-0017 ✅ |
| TR-petroom-002 | Flame draw-call budget contract of 5 draw calls, 2.5% of the project-wide 200 budget (Formula 1) | ADR-0001 ✅ |
| TR-petroom-003 | Tap hit-area padding formula guarantees `hitBoxSize ≥ 80dp` regardless of visual sprite size (**Formula 2** — the requirement Pet Interaction #14's Story 005 is blocked on) | ADR-0017 ✅ |
| TR-petroom-004 | Modal defer when Wardrobe is open or a competing `GameEvent` arrives | ADR-0017 ✅ |
| TR-petroom-005 | Never call `FlameGame` init/reset on tab return, since `StatefulShellRoute` keeps tabs mounted | ADR-0017 ✅ |

**Coverage: 5 / 5 by ADR** (ADR-0001 covers TR-petroom-002; ADR-0017, Accepted 2026-07-23, covers TR-petroom-001/003/004/005 — matches `docs/architecture/architecture.md`'s Traceability Coverage Check, now updated to "Pet Room UI (#18) | 5 | 5/5 | ✅ FULL").

## Untraced Requirements

None remaining. The **"Pet Room Screen Rendering & Interaction Contract"** ADR
(ADR-0017, `docs/architecture/adr-0017-pet-room-screen-rendering-interaction-contract.md`)
was written and Accepted 2026-07-23, closing the gap this section previously
tracked. `/create-stories pet-room-screen-ui` can now be run without any
TR-ID producing a Blocked story for ADR-coverage reasons.

**Downstream note**: TR-petroom-003 (Formula 2) was the specific requirement
that Pet Interaction's `production/epics/pet-interaction/story-005-hit-area-minimum-enforcement.md`
was blocked on — that story verifies Pet Interaction's own ≥80×80dp contract
(ADR-0016) against this epic's Formula 2 *output*. ADR-0017 now supplies that
concrete output (`computeHitArea()`, `src/lib/gameplay/hit_area_formula.dart`,
producing `hitBoxSize` 80/112/152dp for Baby/Young/Grown Mochi). A future story
under this epic covering TR-petroom-003 still needs to be implemented (this
epic has not implemented any stories yet — only the ADR exists) before Story
005 has real code to verify against, but the architecture-level blocker is
resolved.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/pet-room-screen-ui.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
  (Formula 1 → `tests/unit/pet-room-screen-ui/`, Formula 2 → `tests/unit/pet-room-screen-ui/`,
  Edge Case 4 → `tests/integration/pet-room-screen-ui/`, per the GDD's own Acceptance
  Criteria test-tier annotations)
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`
- [x] **ADR-Accepted**: The "Pet Room Screen Rendering & Interaction Contract" ADR
  (ADR-0017) is Accepted — condition met 2026-07-23. (ADR-0001 covers TR-petroom-002.)
- The GDD's `/ux-design` flag (composition wireframe, context-menu anchor
  positioning across screen sizes, Wardrobe height cap on small screens) is
  resolved before or alongside implementation — see GDD's UI Requirements section

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Tap Hit-Area Padding (Formula 2) | Logic | Complete | ADR-0017 |
| 002 | Flame Canvas Draw-Call Budget Contract (Formula 1) | Logic | Complete | ADR-0001 |
| 003 | Flame Canvas Composition, Z-Order & Modal Mutual Exclusivity | Integration | Complete | ADR-0017 |
| 004 | Modal Defer for Wardrobe / Competing GameEvent | Integration | Complete | ADR-0017 |
| 005 | FlameGame Lifecycle — Never Init/Reset on Tab Return | Integration | Ready | ADR-0017 |
| 006 | Persistent Chrome — Status Row & Level Progress Bar | UI | Complete with Notes | ADR-0017 |
| 007 | Tap-on-Mochi Context Menu & Wardrobe Bottom Sheet | UI | Complete with Notes | ADR-0017 |

Story 001 (TR-petroom-003 / Formula 2) was prioritized and implemented first —
per this epic's own prior guidance below — since it was the specific,
already-flagged blocker for Pet Interaction epic's Story 005 (Hit-Area
Minimum Enforcement). Story 003 (Composition, Z-Order & Modal Mutual
Exclusivity) is now also Complete — it fixes the live-app black-screen bug
(neither `RoomBackgroundComponent` nor `MochiComponent` were ever mounted
prior to this story) and unblocks Stories 004, 006, 007, which needed its
`showModal`/`dismissModal`/overlay-key contract. Story 004 (Modal Defer) is
now also Complete — code review (flame-specialist + qa-tester, both
independently) found and this story fixed a real bug in `_onTriggerComplete`
that bypassed the new modal-defer gate for a dequeued ADR-0007 `_queued`
trigger; see story-004's own Implementation Record for the full repro and
fix. Story 006 (Persistent Chrome) is now Complete with Notes — AC-CR7
(mood/energy status row) is implemented and verified; AC-CR8-1/AC-CR8-2
(level progress bar) are explicitly Blocked pending the Pet Leveling &
Evolution #16 epic (no `petLevelProvider`/`levelProgressProvider` exists
yet), an explicit user decision rather than an oversight — see story-006's
own Acceptance Criteria and Implementation Record. Its code review also
surfaced and fixed a cross-epic regression in Time & Decay #2's
`_activeChildEnergyDocProvider` (Riverpod retry-`Timer` leak). Story 007
(Context Menu & Wardrobe) is now also Complete with Notes — all 7 ACs
implemented and verified. **Important gap this story surfaced, flagged by
both flame-widget-specialist and qa-tester, not just noted in a code
comment**: `game.showModal('context_menu')` has no production caller
anywhere in `src/lib/` — the context menu it built is fully implemented
and tested but currently unreachable by any real player action, since Pet
Interaction epic's own already-ratified GDD/ADR-0016 binds a tap on
Mochi's sprite directly to the PLEASED animation, conflicting with this
GDD's own "tap-on-Mochi mở context menu" prose. Needs a follow-up
ADR/story to reconcile before the feature is actually playable — see
story-007's own Acceptance Criteria and Implementation Record. Story 002
(Formula 1) is now also Complete — flame-specialist code review: Approve,
no Required Changes. Story 005 (Lifecycle) remains Ready and
unimplemented.

## Next Step

Implement Story 005 (FlameGame Lifecycle), the epic's last unstarted
story. Separately, resolve the tap-on-Mochi gesture conflict Story 007
surfaced — a new ADR or follow-up story reconciling ADR-0016's ratified
tap=PLEASED semantics against this GDD's "tap-on-Mochi opens context
menu" prose. Without it, Story 007's context menu stays unreachable in
the live app despite being Complete. Story 006's AC-CR8 remainder is
Blocked, not droppable — pick it up once
`/create-epics pet-leveling-evolution` exists.
