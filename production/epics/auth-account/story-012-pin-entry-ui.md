# Story 012: PIN Entry Screen UI

> **Epic**: Auth & Account
> **Status**: Complete
> **Layer**: Foundation
> **Type**: UI
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Unblocked

**UX spec complete**: `design/ux/pin-entry-screen.md` (2026-07-16), governed by pattern P10 (`design/ux/interaction-patterns.md`). Full layout, component inventory, states (including the offline-first-sync edge case from Story 004's AC4), interaction map, transitions, accessibility, and 6 acceptance criteria specified. Not yet run through `/ux-review` — implement against the spec as written.

## Context

**GDD**: `design/gdd/auth-account.md`
**Requirement**: covers the UI portion of the PIN-entry Acceptance Criteria
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Auth & PIN Security Architecture (backend contract only)

**Control Manifest Rules (this layer)**: none UI-specific yet — will come from the UX spec; underlying PIN verification already governed by Story 004's manifest rules (including the "never log raw PIN" rule, which this screen's text input must respect directly).

---

## Acceptance Criteria

*From `design/ux/pin-entry-screen.md`'s Acceptance Criteria section (supersedes the GDD-only draft list):*

- [x] Bé tap vào profile và nhập đúng PIN 4 số → app navigate đến Pet Room screen với `activeChildProvider` = đúng `childId`.
- [x] Bé nhập sai PIN 3 lần liên tiếp → PIN input bị disabled 60 giây, countdown hiển thị, không thể thử lại sớm hơn.
- [x] Nhập sai PIN lần 1-2 → dot display reset về rỗng để gõ lại ngay, không bị khóa.
- [x] Hồ sơ chưa từng sync credentials (offline-first-sync edge case) → hiển thị thông báo "cần kết nối mạng", không hiển thị như sai PIN.
- [x] Mỗi phím numpad đạt tối thiểu 48×48dp tap target.
- [x] Sau khi lockout hết hạn (60s), numpad tự động active lại mà không cần bé tap gì thêm.
- [x] PIN input field is configured to prevent Crashlytics/Sentry auto-capture of entered digits — satisfied by construction (no `TextField`/`EditableText` exists anywhere on this screen; digits are collected via numpad button taps into a local buffer, so there is no text-input surface for a crash reporter's default breadcrumb capture to hook into — no crash-reporting SDK is integrated in this project yet, so there's nothing to configure beyond that). Verified by direct code read (not just doc-comment claim) in code review, and now backed by a regression assertion (`find.byType(TextField)`/`EditableText`, `findsNothing`).

---

## Implementation Notes

*From `design/ux/pin-entry-screen.md`, governed by pattern P10:*

- Layout: header (avatar+name+back) → dot display → numpad (3×4 grid). Full component inventory + ASCII wireframe in the spec.
- No explicit "confirm" button — PIN auto-verifies the instant the 4th digit is entered (spec's Interaction Map).
- Wire to Story 004's `PinVerificationActions.verifyChildPin({childId, rawPin})` — handle its 3 outcomes: `true` (correct), `false` (wrong, increments failCount internally), and thrown `PinCredentialsUnavailable` (render the offline-sync message, NOT a wrong-PIN state — spec's States & Variants, this is literally Story 004's AC4).
- Also handle thrown `VerifiedChildProfileMissing` (Story 004 code-review addition) — a data-integrity edge case; render a generic error rather than crashing.
- Lockout countdown display: read `PinVerificationRepository`'s lockout state (via secure storage) or derive from the repeated `false` results — confirm exact wiring mechanism during implementation since the repository doesn't currently expose a countdown-ready stream (may need a small addition; flag if so rather than guessing).
- Wrong-PIN feedback: dot-display shake animation (~300ms, small amplitude) then reset — no error text per P10. Reduced-motion: flash instead of shake.
- Mask this screen's digit input from Crashlytics/Sentry breadcrumbs — verify with whatever crash-reporting SDK is integrated (not yet confirmed elsewhere in this codebase; flag if none exists yet).
- No navigate() call needed on success — Story 003's route guard reacts to `activeChildProvider` being set (`sessionStateProvider` → `childSelected`) automatically.

---

## Out of Scope

- Story 004: PIN verification logic and lockout state itself (this story only displays it)
- Story 003: the post-success navigation mechanism

---

## QA Test Cases

*UI story — manual verification against the UX spec's States & Variants:*

```
Manual check: Correct PIN
  Setup: child profile with a known PIN, PIN Entry Screen open for that child
  Verify: enter the correct 4-digit PIN
  Pass condition: navigates to Pet Room with the correct child active

Manual check: Lockout after 3 wrong attempts
  Setup: PIN Entry Screen open
  Verify: enter wrong PIN 3 times
  Pass condition: numpad disables, 60s countdown visibly displays and counts down; a 4th attempt before it reaches 0 is rejected without recomputing

Manual check: Offline-first-sync edge case
  Setup: a child profile whose credentials sub-document has never synced to this device (simulate per Story 004's test setup)
  Verify: attempt PIN entry
  Pass condition: shows the "cần kết nối mạng" message, NOT a wrong-PIN shake/state
```

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/pin-entry-ui-evidence.md` — ADVISORY gate level

**Status**: Substituted with an automated widget test (established project pattern since Story 010): `tests/integration/auth_account/pin_entry_screen_test.dart` (11 tests) + 4 new unit tests in `tests/unit/auth_account/pin_verification_test.dart` (`PinVerificationRepository.getLockUntil` group) covering the new lockout-countdown accessor this story required.

---

## Dependencies

- Depends on: Story 004 (Complete), Story 003 (Complete), `design/ux/pin-entry-screen.md` (Complete)
- Unlocks: None

---

## Completion Notes

**Completed**: 2026-07-16

**Files changed**:
- `src/lib/ui/pin_entry_screen.dart` — new widget: header (back + best-effort name confirmation), `_DotDisplay` (shake via `AnimationController`, reduced-motion flash fallback, mint fill on success), 3×4 `_Numpad`/`_NumpadKey` (`Material`+`InkWell`, 48×48dp minimum, P1-equivalent single-flight guard via `_verifying`), `_LockoutCountdown`, `_OfflineSyncMessage`, `_DataErrorMessage`.
- `src/lib/core/pin_verification_repository.dart` — new `getLockUntil(childId)`: read-only lockout-expiry accessor (Story 004's repository had no countdown-ready seam; the story flagged this as an expected gap, not a guess — added here, not in the UI layer).
- `src/lib/providers/auth_providers.dart` — new `PinVerificationActions.getLockUntil(childId)` exposing the above.
- `src/lib/providers/router_provider.dart` — wired the real `PinEntryScreen` in place of the placeholder.
- `tests/unit/auth_account/pin_verification_test.dart` — 4 new tests for `getLockUntil` (never-locked, mid-lockout expiry value, post-expiry null, read-only/no-mutation).
- `tests/integration/auth_account/pin_entry_screen_test.dart` — new, 11 tests.

**Criteria**: 7/7 passing, all covered by automated tests.

**Deviations**: None from scope. The UX spec's "Events Fired" table (`pinVerified`, `pinVerificationFailed`, etc.) is not implemented — consistent with Stories 010/011, neither of which fires analytics events either; flagged in code review as a likely intentional cross-cutting gap pending an analytics event bus, not a regression specific to this story.

**Real finding (test-infrastructure, not production)**: `hashPin()` runs off-isolate via `Isolate.run` (ADR-0002 §2). A `tester.tap()` on the 4th PIN digit triggers that isolate call as an unawaited fire-and-forget `Future` from `InkWell.onTap`, and neither a bare `pumpAndSettle()` nor wrapping only the taps in `tester.runAsync` reliably waits for the cross-isolate round-trip — confirmed empirically via a throwaway debug test (the widget test hung indefinitely, then a follow-up attempt with a fixed real-time sleep "fixed" the hang but left `activeChildProvider`/lockout assertions observing stale state, later confirmed by an `UnmountedRefException` firing after test teardown once the isolate response finally arrived). A raw top-level `await hashPin(...)` in test seeding code has the same issue and needs `tester.runAsync` too. **Fix**: added a test-only `pin_verifying_marker` key that `PinEntryScreen` renders only while its internal `_verifying` flag is true, and the test's `enterPin()`/`waitForVerifyToSettle()` helpers poll for that key's disappearance (bounded by a generous 10s timeout) instead of guessing with a fixed sleep — this was itself a code-review finding (qa-tester flagged the original fixed-1s-delay as a real CI-flakiness risk) that got fixed, not just documented.

**Also found (test-infrastructure)**: `childProfilesProvider` (a cached, non-autoDispose `FutureProvider`) does its one-shot Firestore fetch as soon as `authStateProvider` resolves, which in these tests happens before the test seeds profile data. Fixed by having the test's `seedProfile()` helper call `container.invalidate(childProfilesProvider)` after seeding. qa-tester independently reviewed this fix and confirmed it's test-setup-only (in production, profile data is already loaded before the user ever reaches this screen, since it backs the selection grid the user just tapped from) — not a masked production bug.

**Code Review**: Complete — `flame-widget-specialist` (state-machine fidelity to the UX spec's 8 States & Variants, animation/timer disposal safety, security, Riverpod correctness, accessibility) + `qa-tester` (test coverage) run in parallel. flame-widget-specialist: **zero required changes** — clean pass, all 8 states correctly implemented, no disposal/leak risks, no `TextField` anywhere (AC7 verified by direct code read), correct `.value` (not `.valueOrNull`) usage. qa-tester: 7 advisory findings, all addressed — added an AC7 regression assertion, a test proving a tap during the "Verifying" state is ignored (single-flight guard), a reduced-motion (flash-not-shake) test, and replaced the flaky fixed-delay test wait with the `pin_verifying_marker`-polling fix described above. Two findings were evaluated and left as-is with reasoning recorded: no automated "never log raw PIN" backstop (code-inspection-only, consistent with how this rule is enforced elsewhere in the codebase) and untested countdown-tick intermediate values (low value — the 60s-initial and post-expiry boundaries are the meaningful assertions).

**Test Evidence**: `tests/integration/auth_account/pin_entry_screen_test.dart` (11/11 passing) + `tests/unit/auth_account/pin_verification_test.dart` (26/26 passing, including 4 new `getLockUntil` tests). Full suite: 114/114 passing (+1 pre-existing skip). `flutter analyze`: clean (10 pre-accepted cosmetic lints, unchanged pattern).

**This closes Story 012 — the last of the 3 UI stories (010/011/012) and the last Ready story in the Auth & Account epic. All 12 stories are now Complete; the epic is feature-complete.**
