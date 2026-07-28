# Story 001: Parent Login & Family Bootstrap

> **Epic**: Auth & Account
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-07-15
> **Last Updated**: 2026-07-15

## Context

**GDD**: `design/gdd/auth-account.md`
**Requirement**: `TR-auth-account-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Auth & PIN Security Architecture
**ADR Decision Summary**: Parent authenticates via Firebase Auth `signInWithEmailAndPassword`; a child is NOT a Firebase Auth principal (COPPA). `FirebaseAuthException` is caught generically — `firebase_auth ^5.x` was believed to consolidate `wrong-password`/`user-not-found` into `invalid-credential` server-side (see Engine Notes correction below), so do not resurrect per-code branching without first re-checking that claim.

**Engine**: Flutter 3.44.4 / `firebase_auth` (actual resolved: `^6.5.6`) | **Risk**: LOW-MEDIUM
**Engine Notes**: ⚠️ **Corrected 2026-07-15**: ADR-0002 assumed `firebase_auth ^5.x`; scaffolding `src/pubspec.yaml` via live `flutter pub add` resolved `^6.5.6` instead — a major version ahead. The `invalid-credential` consolidated error code was documented as v5.x behavior; **this has not been independently re-verified against `^6.5.6`**. Before implementing the generic-error-catch AC, check the actual `FirebaseAuthException.code` values `^6.5.6` produces for wrong-password vs. unknown-email — do not assume the consolidation still holds just because this note says it used to.

**Control Manifest Rules (this layer)**:
- Required: Parent authenticates via Firebase Auth `signInWithEmailAndPassword`; a child is NOT a Firebase Auth principal — a Firestore doc `families/{parentId}/children/{childId}` with an auto-generated doc ID
- Required: Catch `FirebaseAuthException` generically — do not branch per error code (was believed `firebase_auth ^5.x` consolidates `wrong-password`/`user-not-found` into `invalid-credential`; actual version is `^6.5.6` — re-verify per Engine Notes above)
- Forbidden: Never give each child their own Firebase Auth identity (anonymous/custom-token) — violates COPPA
- Forbidden: Do not resurrect per-error-code branching (`wrong-password`/`user-not-found`) unless `^6.5.6` verification (above) shows the consolidation no longer applies

---

## Acceptance Criteria

*From GDD `design/gdd/auth-account.md`, scoped to this story:*

- [x] GIVEN bố mẹ nhập email + password hợp lệ, WHEN tap "Đăng nhập", THEN `authStateProvider` emits a non-null `User` and `parentProfileProvider` resolves `families/{parentId}` within a state transition fast enough to support a <3s screen navigation (actual navigation is Story 010's concern — this story delivers the state, not the transition itself).
- [x] GIVEN bố mẹ nhập sai password, WHEN tap "Đăng nhập", THEN the sign-in call surfaces a single generic error state (mapped from `FirebaseAuthException` code `invalid-credential`) — never a message that reveals whether the email exists.
- [x] GIVEN bố mẹ tạo account lần đầu và `families/{parentId}` chưa tồn tại, WHEN login thành công, THEN the bootstrap logic detects the missing document and exposes a "needs first-time setup" state — no crash, no unhandled exception.

---

## Implementation Notes

*Derived from ADR-0002 Decision §1, §6:*

- Use `FirebaseAuth.instance.signInWithEmailAndPassword(email: ..., password: ...)`. This is the ONLY sign-in call in this story — do not use `createUserWithEmailAndPassword` here (that's a separate signup flow, not in this epic's GDD scope as written).
- `authStateProvider = StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges())` — this is the canonical provider every downstream story reads; declare it once, here, in `lib/providers/auth_providers.dart` per the GDD's "all downstream systems import from `lib/providers/auth_providers.dart`" contract.
- `parentProfileProvider = FutureProvider<ParentProfile?>(...)` reads `families/{parentId}` once auth resolves. Return `null` (not throw) when the document doesn't exist — that `null` is the first-time-setup signal this story's third AC requires.
- Catch `FirebaseAuthException` at the call site and map ALL codes to one generic error surface. Do not write a `switch` on `.code` — v5.x already did the consolidation server-side.
- `childId` is never a Firebase Auth UID anywhere in this story or any story in this epic — only `parentId` (the Firebase Auth UID) is Auth-native.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: `sessionStateProvider` derivation (this story only produces the raw `authStateProvider`/`parentProfileProvider` inputs it consumes)
- Story 004: PIN verification / `activeChildProvider`
- Story 010: actual Login Screen UI and the real <3s navigation (blocked pending `/ux-design`)

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped; test specs not pre-generated. Use ADR-0002's own Validation Criteria as the baseline before writing tests, then run `/qa-plan` for full coverage if needed:*

- ADR-0002 Validation Criteria: "Unit test: `verifyChildPin` accepts the correct PIN..." (not this story — see Story 004)
- For this story specifically, verify: (1) successful sign-in resolves `authStateProvider` to non-null `User`, (2) wrong-password sign-in surfaces exactly one generic error type, (3) `parentProfileProvider` returns `null` (not an exception) when `families/{parentId}` is absent.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/auth_account/parent_login_test.dart` — must exist and pass

**Status**: [x] Created — 4/4 tests passing (3 AC + 1 regression)

---

## Dependencies

- Depends on: None (Foundation, first story in epic)
- Unlocks: Story 002 (needs `authStateProvider`), Story 005 (needs `parentId` scope), Story 006, Story 008

---

## Completion Notes

**Completed**: 2026-07-15
**Criteria**: 3/3 passing
**Deviations**: None (GDD/ADR/manifest current, no forbidden patterns, no scope creep). One documented minor deviation: `authStateProvider` uses `ref.watch(firebaseAuthProvider)` DI seam instead of ADR-0002's literal inline `FirebaseAuth.instance` snippet — same contract, justified by coding-standards.md's DI-over-singletons rule, approved during code review.
**Test Evidence**: Integration: `tests/integration/auth_account/parent_login_test.dart` — 4/4 passing
**Code Review**: Complete — `/code-review` verdict APPROVED WITH SUGGESTIONS (flame-specialist + qa-tester, parallel). 1 Required Change (strengthen AC2 test to assert message content, not just exception type) fixed before closing. 3 Suggestions logged as follow-up, not blocking: (1) add try/catch around `getParentProfile`'s Firestore read, (2) soften hard `as String` casts in `parent_profile.dart` to nullable + explicit handling, (3) confirm which story/flow actually creates `families/{parentId}` on first-time setup — no method in this story's scope does it, likely belongs to the (currently blocked) Login Screen UI story or a dedicated onboarding flow not yet tracked.
**Real defects found and fixed during implementation** (verified firsthand, not assumed): `fake_cloud_firestore ^4.1.1` incompatible with `cloud_firestore ^6.7.1` (replaced with a hand-rolled test fake); a test race condition subscribing to a stream after triggering its event; `AsyncValue.future` resolving to a stale first value instead of waiting for a later update; confirmed `riverpod` 3.3.2's `.valueOrNull` removal firsthand (matches ADR-0002's correction note); confirmed `firebase_auth ^6.5.6`'s `invalid-credential` consolidation still holds (resolves ADR-0002's previously-open verification item).
