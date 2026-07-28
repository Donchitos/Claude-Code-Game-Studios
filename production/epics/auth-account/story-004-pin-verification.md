# Story 004: Child PIN Verification (crypto + lockout)

> **Epic**: Auth & Account
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 4h
> **Manifest Version**: 2026-07-15
> **Last Updated**: 2026-07-15

## Context

**GDD**: `design/gdd/auth-account.md`
**Requirement**: `TR-auth-account-003`, `TR-auth-account-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Auth & PIN Security Architecture
**ADR Decision Summary**: PIN verification is client-side: read the child's `pinHash`/`pinSalt`, compute `PBKDF2-HMAC-SHA256(rawPin, salt, iterations=100000, keyLength=32)` off the main isolate via `pointycastle`, compare. The iteration count provides negligible brute-force resistance for a 4-digit PIN — the real defense is the 3-fail/60s lockout in `flutter_secure_storage`, which is a UI-layer control, not cryptographic.

**Engine**: Flutter 3.44.4 / `pointycastle ^3.9.0`, `flutter_secure_storage` | **Risk**: MEDIUM
**Engine Notes**: PBKDF2 MUST run via `Isolate.run`/`compute` — running it on the main isolate will jank low-end Android (ADR-0002 Risk: "PBKDF2 on the UI isolate would jank low-end Android"). `flutter_secure_storage` reset-on-uninstall behavior differs by platform (iOS Keychain typically survives reinstall, Android does not) — verify both during QA, this is a platform difference, not a bug.

**Control Manifest Rules (this layer)**:
- Required: PIN verification is client-side: compute `PBKDF2-HMAC-SHA256(rawPin, salt, iterations=100000, keyLength=32)` via `pointycastle`, compare to stored hash
- Required: PBKDF2 computation MUST run off the main isolate (`Isolate.run`/`compute`)
- Required: Per-child 16-byte random salt required (never bare SHA-256)
- Required: Lockout state (`failCount` 0–3, `lockUntil` Unix ms) lives in `flutter_secure_storage` under `pin_fail_{childId}`/`pin_lock_{childId}` (stored as strings)
- Required: 3 consecutive PIN failures → 60s lock
- Required: Never log raw PIN/pinHash/pinSalt; mask PIN text-field input from Crashlytics/Sentry breadcrumbs
- Forbidden: Never verify PIN server-side via Cloud Function
- Forbidden: Never treat the PIN as a Firestore-enforced access-control boundary — it is UI-only
- Forbidden: Do not over-correct into Argon2 or longer PINs

---

## Acceptance Criteria

*From GDD `design/gdd/auth-account.md`, scoped to this story:*

- [x] GIVEN bé tap vào profile và nhập đúng PIN 4 số, WHEN xác nhận PIN, THEN `verifyChildPin` returns `true` and `activeChildProvider` is set to the correct `childId`'s `ChildProfile`.
- [x] GIVEN bé nhập sai PIN 3 lần liên tiếp, WHEN lần thứ 3 fail, THEN PIN input is gated for 60 seconds (`lockUntil` set), and a 4th attempt before that window elapses is rejected without even computing PBKDF2 again.
- [x] Correct PIN entry resets `failCount` to 0.
- [x] Edge case (ADR-0002 Risk): a brand-new child profile's first PIN entry on a device that has never synced online finds no cached credential document — this must fail with a clear "needs to go online first" state, not a crash or a silent false-negative treated as "wrong PIN."

---

## Implementation Notes

*Derived from ADR-0002 Decision §2–4 and Key Interfaces:*

```dart
Future<bool> verifyChildPin({required String childId, required String rawPin});
```

- Read `children/{childId}/private/credentials` (the sub-document — see Story 005, which owns this specific read) to get `pinHash`/`pinSalt`. Do not read this from the `children/{childId}` document itself — that's the profile-list document and must never carry credentials (ADR-0002 §7, defense-in-depth).
- Before computing PBKDF2, check `flutter_secure_storage` for an active `lockUntil` on this `childId`. If locked, short-circuit and return `false` immediately — do not spend the PBKDF2 CPU cost on a request you're going to reject anyway.
- Compute PBKDF2 via `Isolate.run(() => ...)` — never on the calling isolate.
- On match: reset `failCount` to 0 in secure storage, set `activeChildProvider` to the matched `ChildProfile`, return `true`.
- On mismatch: increment `failCount`; if it reaches 3, write `lockUntil = now + 60s`; return `false`.
- `failCount`/`lockUntil` are stored as strings (`toString()`/`int.parse()` at the boundary) per the ADR — `flutter_secure_storage` only stores strings natively.
- Do not log `rawPin`, `pinHash`, or `pinSalt` anywhere, including in exception messages or crash-reporting breadcrumbs. If a PIN text field auto-captures into Crashlytics/Sentry, explicitly mask it.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: the actual Firestore read of the credentials sub-document (this story calls it, doesn't own it)
- Story 007: `resetChildPin` (shares the PBKDF2/salt-generation helper with this story — extract it to a shared function both stories call, do not duplicate the hashing logic)
- Story 012: the PIN Entry Screen UI and the visible lockout countdown (blocked pending `/ux-design`)

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. ADR-0002's Validation Criteria specifies the required coverage:*

> "Unit test: `verifyChildPin` accepts the correct PIN and rejects wrong ones; `failCount` increments and 3-fail lockout engages for 60s; correct PIN resets `failCount`."
> "Security check: confirm PBKDF2 runs off-isolate (no jank); confirm no PIN/hash/salt in logs or crash breadcrumbs."

Also test explicitly: a locked-out `childId` rejects a 4th attempt without recomputing PBKDF2 (assert the hash function is not invoked while locked — this is a real cost/correctness requirement, not just a UX nicety).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/auth_account/pin_verification_test.dart` — must exist and pass

**Status**: [x] Created and passing (18 tests, all passing)

---

## Dependencies

- Depends on: Story 002 (needs `activeChildProvider` declared), Story 005 (needs the credentials sub-document read)
- Unlocks: Story 007 (shares crypto helper), Story 012 (blocked UI, needs this logic underneath)

---

## Completion Notes
**Completed**: 2026-07-15
**Criteria**: 4/4 passing
**Deviations**:
- ADVISORY: `pinHash`/`pinSalt` storage encoding (base64) is not ADR-mandated — a genuine implementation choice, extracted into shared `lib/core/pin_crypto.dart` helpers (`hashPin`, `generatePinSalt`, `encodePinSalt`, `decodePinSalt`) so Story 007 (PIN Reset) reuses the exact same functions rather than diverging, per this story's own Out of Scope instruction.
- ADVISORY: `_clearLockout` deletes the `pin_fail_{childId}` key rather than writing the literal string `"0"` as ADR-0002's prose says — behaviorally identical (missing key reads as 0), but Story 007 should copy the code, not the ADR wording, if it needs the same reset behavior.
**Test Evidence**: Logic — `tests/unit/auth_account/pin_verification_test.dart` (18 tests, all passing; full suite 65/65)
**Code Review**: Complete — `/code-review` run this session. Both flame-specialist and qa-tester independently found the same real gap: a successfully-verified PIN with no matching `childProfilesProvider` entry silently returned `true` without setting `activeChildProvider` — fixed by throwing a new `VerifiedChildProfileMissing` exception instead. qa-tester additionally found: (a) the "PBKDF2 not invoked while locked" test only proved this indirectly — added an injectable `hashPinFn` seam + a direct call-count spy test; (b) a real race condition where concurrent `verify()` calls for the same child could lose a `failCount` increment (double-tap from a young child is a realistic trigger) — fixed with a per-childId future-chaining serialization gate + a concurrent-calls regression test; (c) no test at the exact `now == lockUntil` boundary — added. flame-specialist independently re-verified the `pointycastle ^4.0.0` PBKDF2 API against the actual installed package source (the story's primary flagged risk, since the ADR assumed `^3.9.0`) and found no drift. Verdict: APPROVED (post-fix).
