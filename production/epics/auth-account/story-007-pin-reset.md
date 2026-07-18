# Story 007: PIN Reset (resetChildPin)

> **Epic**: Auth & Account
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-07-15
> **Last Updated**: 2026-07-15

## Context

**GDD**: `design/gdd/auth-account.md`
**Requirement**: `TR-auth-account-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Auth & PIN Security Architecture
**ADR Decision Summary**: `resetChildPin` generates a fresh 16-byte salt (never reuses the old one), re-hashes with the same PBKDF2 parameters, overwrites `pinHash`/`pinSalt`, resets `failCount` to 0, and does not kick the active session — the new PIN only takes effect on the next PIN entry.

**Engine**: Flutter 3.44.4 / `pointycastle ^3.9.0` | **Risk**: LOW
**Engine Notes**: Same crypto primitives as Story 004 — this story should reuse that story's salt-generation and PBKDF2-hashing helper rather than reimplementing it, to guarantee both code paths stay parameter-identical (same iteration count, same key length).

**Control Manifest Rules (this layer)**:
- Required: `resetChildPin()` generates a fresh salt, re-hashes, resets `failCount` to 0, never kicks the active session
- Required: Per-child 16-byte random salt required (never bare SHA-256)
- Required: Never log raw PIN/pinHash/pinSalt

---

## Acceptance Criteria

*From GDD `design/gdd/auth-account.md`, scoped to this story:*

- [x] GIVEN bố mẹ gọi `resetChildPin(childId, newPin)` với `newPin` hợp lệ (4 số), WHEN function hoàn tất, THEN `pinHash` and `pinSalt` are overwritten with a fresh salt (different from the old one), `failCount` is reset to 0, and the old PIN no longer verifies on the next login attempt.
- [x] GIVEN bé đang có active session khi bố mẹ reset PIN của bé đó, WHEN reset hoàn tất, THEN the child's current session is NOT kicked — the new PIN only applies at the next PIN-entry (new login or after app force-close/restart).
- [x] `newPin` is validated as exactly 4 digits client-side before any hashing occurs — reject invalid input before touching Firestore.

---

## Implementation Notes

*Derived from GDD Core Rule 6 and ADR-0002 Key Interfaces:*

```dart
Future<void> resetChildPin({required String childId, required String newPin});
```

1. Validate `newPin` is exactly 4 numeric characters — client-side, before any crypto or network call.
2. Generate a fresh 16-byte random salt via the same `SecureRandom` mechanism as Story 004/GDD Formulas — **never reuse the old salt**.
3. Hash `newPin` with PBKDF2 using the fresh salt and the same iteration count (100,000) as PIN verification — reuse Story 004's hashing helper, do not reimplement.
4. Overwrite `children/{childId}.pinHash` and `children/{childId}.pinSalt` (per GDD Core Rule 1's schema — this story writes to the credential sub-document at `children/{childId}/private/credentials`, matching Story 005's read path, not the top-level profile document).
5. Reset `failCount` to 0 in `flutter_secure_storage` (handles the case where the child was mid-lockout before the reset).
6. Do NOT touch `activeChildProvider` or any session state — this function has zero effect on a currently-active child session by design.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: the PBKDF2 hashing helper this story calls (extract and share, don't duplicate)
- The UI for entering a new PIN in the reset dialog — GDD Core Rule 6 explicitly states this UI is owned by Parent Dashboard UI (epic #21, not this epic); this story implements only the `resetChildPin` function itself

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. No pre-existing qa-plan spec for this story:*

- **AC**: reset overwrites with a fresh, different salt
  - Given: a child with existing `pinHash`/`pinSalt`
  - When: `resetChildPin` is called with a valid new PIN
  - Then: the stored salt after reset differs from the salt before reset, and the old PIN fails `verifyChildPin` afterward
- **AC**: reset does not kick active session
  - Given: `activeChildProvider` holds this `childId` as the active child
  - When: `resetChildPin` completes
  - Then: `activeChildProvider` is unchanged
- **AC**: invalid `newPin` rejected before hashing
  - Given: `newPin = "12a4"` or `newPin = "123"` (wrong length/non-numeric)
  - When: `resetChildPin` is called
  - Then: it throws/returns an error before any Firestore write or PBKDF2 computation occurs

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/auth_account/pin_reset_test.dart` — must exist and pass

**Status**: [x] Created and passing (8 tests, all passing)

---

## Dependencies

- Depends on: Story 004 (shares the PBKDF2/salt helper), Story 005 (writes to the same credential sub-document path Story 005 reads)
- Unlocks: None further within this epic

---

## Completion Notes
**Completed**: 2026-07-15
**Criteria**: 3/3 passing
**Deviations**:
- ADVISORY: `resetChildPin` (a new distinct `PinResetActions` class, matching the ADR's separate `verifyChildPin`/`resetChildPin` interface functions) throws a plain `StateError` for "no parent signed in" rather than a domain exception — accepted per code review as the correct core-Dart type for an invalid-call-state precondition violation (this path is only reachable while parent-authed; hitting it indicates a caller bug, not a recoverable user-facing case).
- ADVISORY: concurrent `resetChildPin` calls for the same child are NOT serialized (unlike Story 004's `PinVerificationRepository`, which needed a per-childId gate to fix a real lost-increment race) — documented as a deliberate last-write-wins design in the repository's doc comment: each reset writes one complete, internally-consistent `{pinHash, pinSalt}` pair, so the race class Story 004 had (corrupting a counter) doesn't apply here.
**Test Evidence**: Logic — `tests/unit/auth_account/pin_reset_test.dart` (8 tests, all passing; full suite 73/73)
**Code Review**: Complete — `/code-review` run this session. flame-specialist: CLEAN (confirmed genuine reuse of Story 004's `pin_crypto.dart` helpers, correct validation-before-Firestore ordering, correct session-state isolation). qa-tester: GAPS — found 2 real coverage gaps (no explicit assertion of "create new credentials doc" correctness for a childId with no prior doc; no concurrency test or documented rationale for the absence of Story 004's serialization pattern) — both closed with new regression tests + a doc-comment explaining the last-write-wins design decision. Verdict: APPROVED (post-fix).
