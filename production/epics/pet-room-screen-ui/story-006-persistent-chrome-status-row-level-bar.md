# Story 006: Persistent Chrome — Mood/Energy Status Row & Level Progress Bar

> **Epic**: Pet Room Screen UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: 3-4h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-23

## Context

**GDD**: `design/gdd/pet-room-screen-ui.md`
**Requirement**: `TR-petroom-001` (chrome-content half — the `'chrome'` overlay key contract itself is Story 003's scope; this story fills it with real content)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: Pet Room Screen Rendering & Interaction Contract (Decision → TR-petroom-001, `'chrome'` overlay).
**ADR Decision Summary**: `'chrome'` is added to `game.overlays` exactly once, immediately after `PetRoomGame`'s first `onLoad()` resolves, and never removed for the screen's lifetime (it renders behind/under any open modal per Story 003's z-order, since chrome does not need to stay visible while a modal is open — only Mochi does, per the GDD's Visual/Audio Requirements).

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: LOW-MEDIUM
**Engine Notes**: Pure Flutter widget work (Riverpod `Consumer`/`select` scoping) layered above the Flame canvas via `overlayBuilderMap` — no new Flame component, no draw-call budget impact (Story 002's Formula 1 does not count Flutter overlay widgets). Must read `petMoodProvider`/`petEnergyProvider` (Pet State Machine #6) and `petLevelProvider`/`levelProgressProvider` (Pet Leveling #16) — read-only, this screen does not own or mutate any of that state.

**Control Manifest Rules (this layer)**:
- Required: Overlay widgets use targeted `Consumer`/`Selector` (Riverpod `select`) rebuild scoping, not whole-subtree rebuilds on every tick (source: ADR-0001, Presentation Layer Rules) — status row + level bar should each scope their rebuild to only the provider fields they read.
- Forbidden: mutating `petMoodProvider`/`petEnergyProvider`/`petLevelProvider`/`levelProgressProvider` from this screen — read-only consumption (source: GDD Interactions table; this screen "owns no game-logic state of its own").

---

## Acceptance Criteria

*From GDD `design/gdd/pet-room-screen-ui.md`, scoped to this story:*

- [ ] **AC-CR7**: GIVEN `petMoodProvider` returns one of the 5 mood tiers and `petEnergyProvider` returns a value in `[10,100]`, WHEN `/child/pet-room` renders, THEN the mood icon and energy bar display the correct values, positioned directly under the Child app bar, not encroaching on Main Navigation Shell (#17)'s app bar territory.
- [ ] **AC-CR8-1**: GIVEN `levelProgressProvider` returns any % in `[0,100)` and level `<5`, THEN the progress bar displays the correct %.
- [ ] **AC-CR8-2**: GIVEN level `= 5` (MAX, per Pet Leveling #16 Edge Case 4), THEN the text "MAX" is displayed — not a bar shown full-then-looping.

---

## Implementation Notes

*Derived from GDD Core Rules 7-8 and Visual/Audio Requirements:*

- Style contract (Visual/Audio Requirements — advisory for this UI-type story, not blocking, but should be followed at implementation time): both status row and level bar render as rounded pill/card widgets, Cream Ivory ~85% opacity, soft shadow, floating above the background (not full-width-docked). Status row: mood icon ~32dp (backup cue, not primary — Pillar 2's real test is Mochi's own body language) + energy bar track ~10dp, Mint Breeze → Peach Glow gradient fill, no raw numeric display. Level bar: separate pill, ~6dp thick, Honey Gold `#FFD060` fill, directly under the status row pill.
- Combined chrome budget: status row + level bar together should occupy roughly 12-15% of screen height, sat just below the Child app bar.
- Mounted via the `'chrome'` overlay key Story 003 establishes — added once after `onLoad()` resolves, never removed.
- Consume `petMoodProvider`/`petEnergyProvider`/`petLevelProvider`/`levelProgressProvider` via `Consumer`/`ref.watch(...select(...))` — do not `ref.watch` the whole provider object if only a sub-field is needed, to avoid rebuilding on unrelated field changes (ADR-0001 Presentation Layer Rules).
- MAX state (AC-CR8-2): swap the bar fill for a static "MAX" badge/text — must not render a full bar that then "loops" or resets, which reads as broken/stuck UI per the GDD's explicit note.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: the `'chrome'` overlay key's existence/mount-once contract — this story only fills its content.
- Pet State Machine #6 / Pet Leveling #16's own provider implementations — this story only consumes them.
- Any interaction (tap-to-open-menu) — that lives on `MochiComponent`/context menu (Story 007), not on chrome.

---

## QA Test Cases

*Concrete test cases (lean review mode — written directly into the story, no qa-lead gate spawned per `production/review-mode.txt`).*

- **AC-CR7**: Given `petMoodProvider` overridden to each of the 5 mood tiers in turn, and `petEnergyProvider` overridden to boundary values `10`, `55`, `100` — When: `/child/pet-room` is pumped — Then: assert the mood icon widget corresponding to that tier is found (`find.byKey`/`find.byIcon`), the energy bar's fill fraction matches `(energy-10)/90` (or the GDD's defined mapping), and the status row's top edge is positioned below the app bar's bottom edge (no overlap, via `tester.getTopLeft`/`getBottomLeft` comparison).
- **AC-CR8-1**: Given `levelProgressProvider` overridden to `0`, `1`, `50`, `99.9` and level `<5` — When: pumped — Then: assert the progress bar's fill fraction matches the provider value, no "MAX" text shown.
- **AC-CR8-2**: Given level `= 5` — When: pumped — Then: assert text "MAX" is found and no progress-bar fill widget (or a bar frozen at 100% is explicitly disallowed per the GDD) is rendered in its place.

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/pet-room-persistent-chrome-evidence.md` (manual walkthrough) OR `tests/integration/pet-room-screen-ui/persistent_chrome_test.dart` (interaction test) — advisory gate per `coding-standards.md`'s Testing Standards table (UI stories are ADVISORY, not BLOCKING), but an automated widget test is preferred here since the assertions are mechanically checkable.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (Flame Canvas Composition — needs the `'chrome'` overlay key to exist)
- Unlocks: None
