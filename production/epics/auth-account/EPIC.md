# Epic: Auth & Account

> **Layer**: Foundation
> **GDD**: design/gdd/auth-account.md
> **Architecture Module**: Auth & Account (#1)
> **Status**: Complete (2026-07-16) — all 13 stories closed
> **Stories**: 13 stories (12 created 2026-07-15, Story 013 added 2026-07-16) — see table below

## Overview

This epic implements the project's sole identity and access-control layer: a parent
authenticates via Firebase Auth (email/password), and each child gets a PIN-gated
profile that is a Firestore document, not its own Firebase Auth identity (COPPA
constraint — see ADR-0002 Non-Goals). The PIN is a client-side PBKDF2-HMAC-SHA256
comparison; it is a UI/psychological access boundary, not a Firestore-enforced one.
This module owns and exposes `sessionStateProvider`, the single derived source of
truth every other screen/system routes against — no other module may re-derive
session state. It also owns PIN lockout state, PIN reset, parent override
(reauthenticate without disposing the child session), and the account-deletion
Cloud Function path (GDPR erasure).

**Exit-criteria note (from `/gate-check` 2026-07-13 Pre-Production→Production)**:
before implementing, verify the production `riverpod` package version against
ADR-0002's `.valueOrNull` guidance — the vertical slice found `riverpod` 3.x removed
`.valueOrNull` in favor of a safe `.value`. Confirm which applies for the pinned
production version before writing `sessionStateProvider`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-------------------|-------------|
| ADR-0002: Auth & PIN Security Architecture | Parent-only Firebase Auth; PBKDF2-HMAC-SHA256 (100k iter, per-child salt) client-side PIN verify off-isolate; `sessionStateProvider` derived, not settable; PIN is UI-only, never a Firestore access boundary; lockout via `flutter_secure_storage`; GDPR erasure Cloud Function | LOW (firebase_auth ^5.x is Platform-level, not a Flutter/Flame engine risk) |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-auth-account-001 | Max 4 child profiles per family; PIN is a parent-controlled child-access boundary | ADR-0002 ✅ |
| TR-auth-account-002 | Parent-only Firebase Auth identity; child is a Firestore document, not a Firebase Auth user | ADR-0002 ✅ |
| TR-auth-account-003 | PIN hashed with PBKDF2-HMAC-SHA256, 100k iterations, 16-byte per-child salt; never bare SHA-256 | ADR-0002 ✅ |
| TR-auth-account-004 | PIN fail-lockout (3 attempts → 60s) stored in `flutter_secure_storage`, survives force-close | ADR-0002 ✅ |
| TR-auth-account-005 | `sessionStateProvider` is a derived 4-state enum and the sole routing source of truth | ADR-0002 ✅ |
| TR-auth-account-006 | Parent override reauthenticates via `reauthenticateWithCredential` without disposing the child session | ADR-0002 ✅ |
| TR-auth-account-007 | Cloud Function `onChildProfileDelete` performs recursive Admin-SDK delete | ADR-0002 ✅ |
| TR-auth-account-008 | FCM `onTokenRefresh` writes to `families/{parentId}.fcmToken` | ADR-0002 ✅ |
| TR-auth-account-009 | `resetChildPin()` generates a fresh salt/hash, resets `failCount`, does not kick the active session | ADR-0002 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/auth-account.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`
- The `riverpod`-version exit-criteria note above has been resolved (confirmed `.value` vs `.valueOrNull` against the actually-pinned production package version)

**DoD note (2026-07-16)**: the 3 UI stories (010/011/012) substituted automated widget tests (`tests/integration/auth_account/{login,child_profile_selection,pin_entry}_screen_test.dart`) for the `production/qa/evidence/` sign-off docs listed above — no evidence docs were created. This is a deliberate, consistent choice across all 3 UI stories (documented in each story's Completion Notes), not an oversight, but it means the DoD's literal "evidence docs with sign-off" bullet is satisfied by an equivalent rather than the letter of the requirement.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Parent Login & Family Bootstrap | Integration | **Complete** | ADR-0002 |
| 002 | Riverpod Session Provider Contract (sessionStateProvider) | Logic | **Complete** | ADR-0002 |
| 003 | go_router Session-Based Redirect | Integration | **Complete** | ADR-0002 |
| 004 | Child PIN Verification (crypto + lockout) | Logic | **Complete** | ADR-0002 |
| 005 | Child Profile Data Access (Firestore reads) | Integration | **Complete** | ADR-0002 |
| 006 | Parent Override (Reauthentication) | Integration | **Complete** | ADR-0002 |
| 007 | PIN Reset (resetChildPin) | Logic | **Complete** | ADR-0002 |
| 008 | FCM Token Refresh Listener | Integration | **Complete** | ADR-0002 |
| 009 | Child Profile Deletion (Cloud Function cascade) | Integration | **Complete** | ADR-0002 |
| 010 | Login Screen UI | UI | **Complete** | ADR-0002 |
| 011 | Child Profile Selection Screen UI | UI | **Complete** | ADR-0002 |
| 012 | PIN Entry Screen UI | UI | **Complete** | ADR-0002 |
| 013 | Parent Account Registration (Sign Up) | Integration | **Complete** | ADR-0002 |

**Recommended build order**: 001 → 002 → 005 → 004 → 003/006 (parallel) → 007 → 008/009 (parallel). Stories 010–012 unblock once `/ux-design` runs for Login / Child Profile Selection / PIN Entry.

## Next Step

**All 12 stories are Complete — this epic is feature-complete.** Remaining before this epic can be considered fully done per its Definition of Done:
- The `riverpod`-version exit-criteria note (line 22-26 above) — confirmed resolved during Story 002/003 (`.value`, not `.valueOrNull`, per `docs/architecture/control-manifest.md`'s dated correction notes) — no further action needed.
- No Logic/Integration story test evidence gaps outstanding.
- See the DoD note above regarding the 3 UI stories' evidence-doc substitution.

Recommended next actions: run `/story-readiness sprint` or `/architecture-review` to confirm the epic's stories are consistently reflected in the TR registry, then move to the next epic (e.g. Pet Room / Time & Decay, per the module list in `docs/architecture/architecture.md`).
