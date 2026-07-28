# Test Evidence: Story 005 — Child Back-Button Exit Dialog & Root-Navigator Push Contract

> **Story**: `production/epics/main-navigation-shell/story-005-child-exit-dialog-root-navigator-push.md`
> **Story Type**: UI
> **Date**: 2026-07-21
> **Tester**: *(not yet performed — no live device available in this environment)*
> **Build / Commit**: *(fill in at time of manual verification)*

---

## What Was Tested

This document records what SHOULD be manually verified on a real device/emulator
for AC-1 (the kid-styled "Thoát PetQuest?" exit-confirm dialog on Child Shell
tab-root back-press) and AC-2 (the dialog must NOT appear on the
`/child/tasks/new` sub-screen — that back-press is handled by Story 002's own
`NewTaskScreen` `PopScope` instead). No live Android/iOS device or emulator was
available in this development environment, so the boxes below are unchecked —
this doc records the walkthrough steps to run, not a completed sign-off.

Automated coverage for the same behavior (plus AC-3, the root-navigator push
contract) already exists and passes:
`tests/integration/main-navigation-shell/root_navigator_push_test.dart` — see
that file for the equivalent assertions exercised via simulated back-press
(`tester.binding.handlePopRoute()`) rather than a physical device. This manual
walkthrough is a complementary check for real-device nuances the automated
suite cannot cover (actual Android back gesture / predictive back, actual
button tap-target feel, actual dialog animation timing on real hardware) —
per ADR-0014's own flagged risk: "Android predictive back gesture ... has
known platform-specific nuances not fully verifiable from source alone."

**Acceptance criteria covered**: AC-1 (GDD AC-10), AC-2 (dialog only on tab
roots, not sub-screens), the Parent-Shell-no-dialog criterion.

---

## Acceptance Criteria Results

| # | Criterion (from story) | Result | Notes |
|---|----------------------|--------|-------|
| AC-1 | GIVEN bé back-press trên Child tab root screen (Pet Room/Tasks/Shop), THEN dialog "Thoát PetQuest?" hiện — [Ở lại] dismiss dialog (stay in app), [Thoát] exit app. | NOT YET VERIFIED (manual) | Automated equivalent passes: `test_AC10_backPressOnEveryChildTabRoot_petRoomTasksShop_allShowExitDialog`, `test_AC10_oLaiButton_dismissesDialog_staysInApp_systemNavigatorPopNeverCalled`, `test_AC10_thoatButton_callsSystemNavigatorPop_exactlyOnce` |
| AC-2 | GIVEN bé ở `/child/tasks/new` (sub-screen), WHEN back-press, THEN dialog KHÔNG hiện — navigates to `/child/tasks` instead. | NOT YET VERIFIED (manual) | Automated equivalent passes: `test_AC2_backPressOnNewTaskScreen_doesNotShowExitDialog_returnsToChildTasksInstead` |
| Parent tab root, NOT in override — no dialog | Parent Shell must never show the kid-styled Child Shell dialog. | NOT YET VERIFIED (manual) | Automated equivalent passes: `test_parentShell_backPress_neverShowsChildExitDialog_overrideExitHandlesItInstead` |

---

## Screenshots / Video

None captured — no live device available in this environment. To be added
when this walkthrough is actually performed.

| # | Filename | What It Shows | Acceptance Criterion |
|---|----------|--------------|----------------------|
| *(pending)* | | | |

---

## Manual Walkthrough Steps (to run when a device is available)

1. **AC-1 — Pet Room tab root**
   - Launch the app, sign in, select a child profile — land on `/child/pet-room`.
   - Press the Android hardware/gesture back button (or, on iOS, verify no
     equivalent system back gesture exists here — this AC is primarily
     Android-relevant; confirm iOS has no unintended back affordance on this
     screen).
   - Verify: "Thoát PetQuest?" dialog appears, kid-styled (rounded corners,
     Art Bible palette, **no red/alarming color anywhere** — confirm visually
     against a real device's color rendering, not just the design spec).
   - Tap **[Ở lại]** — verify the dialog dismisses and the app stays on
     `/child/pet-room`, fully interactive.
   - Repeat back-press, this time tap **[Thoát]** — verify the app actually
     exits (backgrounds/closes) — this is the one behavior automated tests
     cannot directly observe (they mock `SystemNavigator.pop()`'s platform
     channel call rather than letting a real app instance exit).

2. **AC-1 — Tasks and Shop tab roots**
   - From Pet Room, tap the "Nhiệm vụ" tab, then repeat the back-press +
     dialog + [Ở lại] check.
   - Tap the "Shop" tab, repeat the same check.
   - Confirm the dialog behaves identically on all 3 tab roots — no
     branch-specific inconsistency.

3. **AC-2 — Sub-screen collision check**
   - From the Tasks tab, navigate into "New Task" (`/child/tasks/new`).
   - Press back.
   - Verify: the exit-confirm dialog does **NOT** appear — instead, the app
     navigates directly back to `/child/tasks` (Story 002's own behavior,
     unmodified by this story).
   - Confirm no visible flicker/flash of the exit dialog mid-transition (a
     real-device timing artifact automated tests, which control frame pumps
     explicitly, would not catch).

4. **Parent Shell — no dialog leak check**
   - Long-press the Profile chip trigger to enter Parent Override, confirm
     with the parent password, land on `/parent/dashboard`.
   - Press back.
   - Verify: the kid-styled "Thoát PetQuest?" dialog never appears here —
     the app should instead return directly to `/child/pet-room` (Story 004's
     override-exit behavior).

5. **Accessibility spot-check**
   - Verify both dialog buttons meet the 48×48dp minimum tap target on the
     actual device screen density being tested.
   - Verify text scaling (increase system font size) does not clip or
     overlap the dialog's title/body/buttons.

---

## Test Conditions

- **Game state at start**: fresh sign-in, one child profile selected, no
  pending tasks required.
- **Platform / hardware**: *(fill in when performed — at minimum one Android
  device/emulator with predictive back enabled, per ADR-0014's flagged risk,
  and one iOS device/simulator)*
- **Framerate during test**: *(fill in when performed)*
- **Any special setup required**: none beyond a signed-in parent + selected
  child.

---

## Observations

*(fill in when performed)*

---

## Sign-Off

All roles must sign off before the story can be marked COMPLETE via
`/story-done`. UI stories require the UX lead or designer sign-off.

**Solo developers**: all sign-offs may be by the same person in each role.

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Developer (implemented) | | | [ ] Approved |
| Designer / Art Lead / UX Lead | | | [ ] Approved |
| QA Lead | | | [ ] Approved |

**Any sign-off can be marked "Deferred — [reason]"** if the person is
unavailable. Deferred sign-offs must be resolved before the story advances
past the sprint review.

---

*Template: `.claude/docs/templates/test-evidence.md`*
*Automated coverage (already passing): `tests/integration/main-navigation-shell/root_navigator_push_test.dart`*
*Location: `production/qa/evidence/child-exit-dialog-evidence.md`*
