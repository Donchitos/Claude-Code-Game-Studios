# Story 006: Persistent Chrome — Mood/Energy Status Row & Level Progress Bar

> **Epic**: Pet Room Screen UI
> **Status**: Complete with Notes
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: 3-4h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-25

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

- [x] **AC-CR7**: GIVEN `petMoodProvider` returns one of the 5 mood tiers and `petEnergyProvider` returns a value in `[10,100]`, WHEN `/child/pet-room` renders, THEN the mood icon and energy bar display the correct values, positioned directly under the Child app bar, not encroaching on Main Navigation Shell (#17)'s app bar territory. — Implemented, verified by `tests/integration/pet-room-screen-ui/persistent_chrome_test.dart`.
- [ ] **AC-CR8-1**: GIVEN `levelProgressProvider` returns any % in `[0,100)` and level `<5`, THEN the progress bar displays the correct %. — **BLOCKED**: `levelProgressProvider` does not exist anywhere in this codebase (Pet Leveling & Evolution #16 has a GDD but no epic yet, confirmed via project-wide grep). Explicit user decision (via `AskUserQuestion`) to implement only AC-CR7 in this story and leave this criterion unimplemented rather than invent a placeholder provider. Unblocks when `/create-epics pet-leveling-evolution` runs and that epic supplies a real `levelProgressProvider`.
- [ ] **AC-CR8-2**: GIVEN level `= 5` (MAX, per Pet Leveling #16 Edge Case 4), THEN the text "MAX" is displayed — not a bar shown full-then-looping. — **BLOCKED**: same reason as AC-CR8-1 (`petLevelProvider` does not exist yet).

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

**Status**: [x] Created — `tests/integration/pet-room-screen-ui/persistent_chrome_test.dart`, 16 tests, all passing (`cd src && flutter test ../tests/integration/pet-room-screen-ui/persistent_chrome_test.dart`). Covers AC-CR7 only — AC-CR8-1/AC-CR8-2 have no evidence since they are unimplemented (Blocked, see Acceptance Criteria above).

---

## Dependencies

- Depends on: Story 003 (Flame Canvas Composition — needs the `'chrome'` overlay key to exist)
- Unlocks: None

---

## Implementation Record

**Files created**:
- `src/lib/ui/pet_room_status_row.dart` — `PetRoomStatusRow` (mood icon + energy bar pill), split into `_MoodIcon`/`_EnergyBar` `ConsumerWidget`s each scoped to exactly the provider it reads (control manifest's rebuild-scoping rule). Public `energyFillFraction(double)` implements the `(energy-10)/90` mapping from this story's own QA Test Cases, clamped defensively.
- `tests/integration/pet-room-screen-ui/persistent_chrome_test.dart` — 16 tests: 5 pure-logic (`energyFillFraction` boundary/clamp coverage) + 11 widget-pumped (one per mood tier, distinct-icon proof, 3 energy boundary values, lower-clamp defense, app-bar-position non-overlap).

**Files modified**:
- `src/lib/ui/pet_room_screen.dart` — `'chrome'` overlay now builds `PetRoomStatusRow` instead of the prior placeholder; the dead `_ChromePlaceholder` class removed.
- `tests/integration/pet-room-screen-ui/composition_and_modal_exclusivity_test.dart`, `tests/integration/pet-room-screen-ui/modal_defer_triggered_visuals_test.dart` — both files' `_pumpPetRoomScreen` helper wrapped in a `ProviderScope` overriding `firebaseAuthProvider` with `MockFirebaseAuth()`. Required because chrome's new Riverpod reads throw "No ProviderScope found" otherwise — that `StateError`, not a real layout bug, was the actual cause of a `RenderFlex overflow "by 199244 pixels"` first seen wiring this story in. `firebaseFirestoreProvider` does not also need overriding: traced that `activeChildProvider` stays null with no signed-in user, so the Firestore-touching branch of `_activeChildEnergyDocProvider` is provably unreachable in these tests.
- `src/lib/providers/time_decay_providers.dart` — `_activeChildEnergyDocProvider` (a `StreamProvider`) now passes `retry: (retryCount, error) => null` to disable Riverpod's default automatic retry-with-backoff on a stream error. See Deviations below for why this was necessary.

**Deviation (cross-epic regression found via full-suite verification, fixed before close)**: this story made `energyProvider` a real, always-mounted production consumer for the first time (via chrome). Running the full suite (not just this story's own new test file) surfaced a genuine regression in an unrelated Time & Decay #2 test, `chip_cluster_test.dart`'s `test_AC7_xuBalanceProviderError_displaysDashXu_noCrash`: confirmed via `git stash`/`git stash pop` that it passed on the pre-Story-006 baseline and failed with this story's changes present. Root cause: that test's `docRef.seedError(...)` call shares the same fake Firestore document path both `xuBalanceProvider` and (now) `energyProvider`'s `_activeChildEnergyDocProvider` read from; Riverpod's default retry-with-backoff scheduled a real `Timer` that outlived the test's widget-tree disposal (`flutter_test`'s "Timer is still pending" teardown assertion). Fixed with the `retry: null` override above, verified against the installed riverpod 3.3.2 source (`element.dart`'s `triggerRetry`: returning `null` from `retry` skips `Timer` construction entirely).

qa-tester's code review of this fix flagged that it had no dedicated regression test in its own file (`tests/integration/time_decay/energy_provider_test.dart`), only incidental protection via `chip_cluster_test.dart`'s unrelated coupling. Added `test_energyProvider_preservesLastKnownValueOnFirestoreStreamError` and `test_energyProvider_defaultsToZero_whenStreamErrorsBeforeAnyValueEverArrives` there. Writing the first version surfaced a second, more interesting finding: it initially asserted `energyProvider` drops to `0.0` on any stream error, matching an incorrect claim in `time_decay_providers.dart`'s own doc comment at the time — verified against riverpod 3.3.2 source (`AsyncError.copyWithPrevious`) that a stream error occurring *after* a value was already received preserves that value, so `energyProvider` actually (and correctly) keeps showing the last known energy rather than flashing to empty. Both the test and the doc comment were corrected to describe the real, and more resilient, behavior.

**Code review**: flame-widget-specialist — 2 Required Changes, both actioned: (1) `_EnergyBar`'s doc comment incorrectly claimed `FractionallySizedBox` couldn't work here for a layout-constraint reason that doesn't hold (the outer track `Container`'s explicit `width`/`height` do impose a tight constraint) — corrected to state the real, weaker reason (direct pixel-width assertability in tests); (2) this story file's acceptance criteria / test evidence checkboxes, actioned in this update. qa-tester — flagged the missing dedicated regression test for the `retry: null` fix (actioned above, with a bonus real-behavior correction) and 2 non-blocking suggestions not actioned: a rebuild-scoping test proving `_MoodIcon` doesn't rebuild when only energy changes, and a second-viewport position test.

**Test results**: Full suite 599/599 passing (1 pre-existing unrelated skip). `flutter analyze`: 0 issues in any file this story touched (13 pre-existing unrelated `info`-level issues elsewhere, unchanged from baseline).

**No git commit made yet** — pending explicit user go-ahead per this project's established pattern.
