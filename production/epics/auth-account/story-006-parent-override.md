# Story 006: Parent Override (Reauthentication)

> **Epic**: Auth & Account
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 2h
> **Manifest Version**: 2026-07-15
> **Last Updated**: 2026-07-15

## Context

**GDD**: `design/gdd/auth-account.md`
**Requirement**: `TR-auth-account-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Auth & PIN Security Architecture
**ADR Decision Summary**: The parent override from a child session verifies the parent password via `user.reauthenticateWithCredential(EmailAuthProvider.credential(...))` — NOT a second `signInWithEmailAndPassword`, which is the wrong semantic and can churn `authStateChanges()`, flickering the session state.

**Engine**: Flutter 3.44.4 / `firebase_auth` (actual resolved: `^6.5.6`) | **Risk**: MEDIUM
**Engine Notes**: The risk here is specifically choosing the wrong Firebase Auth call — `signInWithEmailAndPassword` would technically also validate the password, but it re-triggers `authStateChanges()`, which downstream (Story 002's `sessionStateProvider`) could misinterpret as a fresh login rather than an override, causing a visible flicker or an incorrect state transition. Use `reauthenticateWithCredential` specifically. ⚠️ **Corrected 2026-07-15**: ADR-0002 assumed `firebase_auth ^5.x`; actual resolved version is `^6.5.6` (see Story 001's Engine Notes for the same finding) — `reauthenticateWithCredential`'s core semantics are stable across this range, but re-verify `FirebaseAuthException` codes for wrong-password specifically on `^6.5.6` before assuming the generic-catch behavior is unchanged.

**Control Manifest Rules (this layer)**:
- Required: Parent override MUST use `user.reauthenticateWithCredential(EmailAuthProvider.credential(...))`, NOT a second `signInWithEmailAndPassword`
- Required: Catch `FirebaseAuthException` generically — do not branch per error code (verify against actual `^6.5.6`, not the `^5.x` this rule was originally written against — see Engine Notes)

---

## Acceptance Criteria

*From GDD `design/gdd/auth-account.md`, scoped to this story:*

- [x] GIVEN bố mẹ tap nút override từ child session và nhập đúng password, WHEN xác nhận, THEN `parentOverrideProvider` becomes `true` and the child session (`activeChildProvider`) is NOT cleared/disposed.
- [x] WHEN bố mẹ tap "xong"/"quay lại" ở Parent Dashboard, THEN `parentOverrideProvider` becomes `false`, returning directly to `childSelected` — no PIN re-entry required (the session was never disposed, per GDD's explicit note in the Riverpod Provider Contract section).
- [x] Wrong parent password on the override attempt surfaces a generic error (same `FirebaseAuthException`-generic-catch rule as Story 001), and `parentOverrideProvider` stays `false`.

---

## Implementation Notes

*Derived from ADR-0002 Decision §6:*

```dart
await user.reauthenticateWithCredential(
  EmailAuthProvider.credential(email: parentEmail, password: enteredPassword),
);
```

- On success: `ref.read(parentOverrideProvider.notifier).state = true`. Do not touch `activeChildProvider` at all — that's the whole point of override vs. logout.
- On "done"/"back" in the Parent Dashboard: `ref.read(parentOverrideProvider.notifier).state = false`. Per the GDD, this returns to `childSelected` with the same active child, no PIN prompt.
- Catch `FirebaseAuthException` generically, same as Story 001 — do not add a second, differently-worded error-handling path for this call site.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: the `sessionStateProvider` derivation that consumes `parentOverrideProvider`'s value (this story only writes to it)
- Story 010–012: any UI for the override button or Parent Dashboard itself (not in this epic's UI scope as written in the GDD's UI Requirements section — that section lists only Login/Child Selection/PIN Entry, not Parent Dashboard, which belongs to a different epic: Parent Dashboard UI #21)

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. No pre-existing qa-plan spec for this story:*

- **AC**: override preserves child session
  - Given: `activeChildProvider` holds a valid child, `parentOverrideProvider` is `false`
  - When: `reauthenticateWithCredential` succeeds
  - Then: `parentOverrideProvider` is `true`, `activeChildProvider` is unchanged (same childId, not null)
- **AC**: closing override returns without PIN
  - Given: `parentOverrideProvider` is `true`
  - When: the "done" action sets it to `false`
  - Then: `sessionStateProvider` resolves to `childSelected` immediately, with no intermediate `unauthenticated`/`parentAuthed` state

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/auth_account/parent_override_test.dart` — must exist and pass

**Status**: [x] Created and passing (10 tests, all passing)

---

## Dependencies

- Depends on: Story 001 (needs the authenticated `User` to reauthenticate), Story 002 (needs `parentOverrideProvider` declared)
- Unlocks: None within this epic (Parent Dashboard UI is a separate epic, #21)

---

## Completion Notes
**Completed**: 2026-07-15
**Criteria**: 3/3 passing
**Deviations**:
- ADVISORY: `attemptParentOverride`/`endParentOverride` (as named in this story's Implementation Notes) implemented as a `ParentOverrideActions` class exposed via `parentOverrideActionsProvider`, not bare top-level functions — `Ref` (used inside providers) and `WidgetRef` (used in widgets) are non-unifying `sealed` types in riverpod 3.3.2, verified against installed package source, so a bare `Function(Ref ref, ...)` could not be called from both a widget and a `ProviderContainer` test. Same method names/semantics (`.attempt(password:)` ≈ `attemptParentOverride`, `.end()` ≈ `endParentOverride`), different calling convention.
**Test Evidence**: Integration — `tests/integration/auth_account/parent_override_test.dart` (10 tests, all passing; full suite 40/40)
**Code Review**: Complete — `/code-review` run this session, verdict APPROVED. qa-tester flagged 3 non-blocking test-coverage gaps (double-invocation idempotency of `.attempt()`/`.end()`; propagation of non-`FirebaseAuthException` errors) — all 3 closed with regression tests rather than left as tech debt.
