# Story 008: FCM Token Refresh Listener

> **Epic**: Auth & Account
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1.5h
> **Manifest Version**: 2026-07-15
> **Last Updated**: 2026-07-15

## Context

**GDD**: `design/gdd/auth-account.md`
**Requirement**: `TR-auth-account-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Auth & PIN Security Architecture (jointly owned with the Push Notification ADR — see Related Decisions)
**ADR Decision Summary**: `FirebaseMessaging.instance.onTokenRefresh` stream must update `families/{parentId}.fcmToken` in Firestore automatically — this keeps push notification delivery working after events like app reinstall, which rotates the token.

**Engine**: Flutter 3.44.4 / `firebase_messaging` (actual resolved: `^16.4.3`) | **Risk**: LOW
**Engine Notes**: This story implements only the write-on-refresh listener owned by Auth & Account. Push Notification (epic #9) owns everything else about how `fcmToken` is consumed for sending — do not expand scope into that epic's territory. ⚠️ **Corrected 2026-07-15**: ADR-0002 assumed `firebase_messaging ^15.x`; actual resolved version is `^16.4.3`. The `onTokenRefresh` stream API itself is stable across this range and not expected to be affected, but this hasn't been independently re-verified against `^16.4.3` specifically.

**Control Manifest Rules (this layer)**:
- No Auth-specific manifest bullet exists for FCM beyond the GDD's own requirement — this story is governed directly by TR-auth-account-008 and the interaction table in `auth-account.md` ("Push Notification | → downstream | `fcmToken` of parent | stored in `families/{parentId}`").

---

## Acceptance Criteria

*From GDD `design/gdd/auth-account.md`, scoped to this story:*

- [x] GIVEN `fcmToken` thay đổi sau khi app reinstall, WHEN bố mẹ login, THEN `families/{parentId}.fcmToken` is updated automatically in Firestore — no manual action required from the parent.

---

## Implementation Notes

*Derived from GDD Core Rule / Edge Cases ("Nếu `fcmToken` của bố mẹ thay đổi (app reinstall)"):*

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  // write newToken to families/{parentId}.fcmToken
});
```

- This listener should be established once the parent is authenticated (depends on `authStateProvider` resolving a non-null `parentId`) — it has nothing to do before that point, since there's no `families/{parentId}` document to write to yet.
- Write with `set(..., SetOptions(merge: true))` or `update()` on the single `fcmToken` field — do not overwrite the rest of the `families/{parentId}` document.
- This is a fire-and-forget listener for the app's lifetime once established; no explicit cleanup/dispose logic is called out by the GDD beyond normal provider lifecycle.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Anything about consuming `fcmToken` to actually send push notifications — that's Push Notification epic #9, not this story
- Initial FCM token registration/permission request flow (not explicitly covered by this epic's GDD acceptance criteria — if that's needed, it likely belongs to Push Notification epic #9's onboarding story; flag as a cross-epic gap if no such story exists there)

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. No pre-existing qa-plan spec for this story:*

- **AC**: token refresh writes to Firestore
  - Given: an authenticated parent with an existing `families/{parentId}` document
  - When: `onTokenRefresh` emits a new token value
  - Then: `families/{parentId}.fcmToken` reflects the new value, and no other field on that document is modified

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/auth_account/fcm_token_refresh_test.dart` — must exist and pass

**Status**: [x] Created and passing (7 tests, all passing)

---

## Dependencies

- Depends on: Story 001 (needs an authenticated `parentId` to write to)
- Unlocks: None within this epic (consumed by Push Notification epic #9, out of scope here)

---

## Completion Notes
**Completed**: 2026-07-15
**Criteria**: 1/1 passing
**Deviations**:
- ADVISORY: this story shipped with only 1 formal Acceptance Criterion — below the story-readiness checklist's minimum of 3 for Integration-type stories. Not corrected retroactively (story was already implemented under lean review mode), but flagged here for the producer: test coverage exceeds the single AC (7 tests covering sign-out/sign-in restart, write-failure handling, merge semantics), so implementation risk is mitigated even though the story document itself is under the formal minimum.
**Test Evidence**: Integration — `tests/integration/auth_account/fcm_token_refresh_test.dart` (7 tests, all passing; full suite 47/47)
**Code Review**: Complete — `/code-review` run this session. qa-tester verdict GAPS → closed: fixed a real unhandled-Future-rejection bug (Firestore write failures on token refresh were silently unhandled — now caught and logged, non-fatal) and added a sign-out→sign-in listener-restart regression test. The flame-specialist review agent stalled mid-analysis on a second pass and did not produce a complete final report; repo state was verified clean via `git status`/`git diff` (no unintended file changes from the agent) before proceeding. Verdict: APPROVED based on qa-tester's full review, the flame-specialist's partial-but-relevant findings (dispose-before-rebuild ordering verified safe against riverpod source), and this session's own manual verification.
**Known accepted limitation (not fixed, documented per qa-tester)**: rapid/overlapping `onTokenRefresh` emissions have no write-ordering guarantee — each emission fires an independent unawaited Firestore write with no sequencing. Low-probability in practice (token refreshes are infrequent) and no ADR/GDD requirement currently governs it; flagged as a gap for the producer rather than fixed here, consistent with this story's narrow Out of Scope boundary.
