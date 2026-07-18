# Epic: Push Notification System

> **Layer**: Core
> **GDD**: design/gdd/push-notification.md
> **Architecture Module**: Push Notification (#9)
> **Status**: Stories Complete — Blocked on TestFlight hardware validation (ADR-0010 §3, BLOCKING DoD item)
> **Stories**: 2/2 stories complete (2026-07-16) — see table below

## Overview

This epic implements server-side push delivery: a 2nd-gen `onDocumentCreated`
Cloud Function fires when a child submits a task, sending an FCM payload
(fixed `notification`/`data`/priority contract) to the parent's registered
device with a deep-link URI (`petquest://parent/tasks/pending`). iOS requests
permission once at onboarding; a later reminder deep-links to Settings rather
than re-prompting (`requestPermission()` cannot be called twice on iOS).
MVP ships with FCM's `retry` flag disabled — 2nd-gen retry is time-window-bounded,
not attempt-count-bounded, so leaving it on risks many duplicate pushes from a
single systematic handler failure. No dedup/idempotency infrastructure exists;
duplicate notifications are an accepted MVP tradeoff (notifications aren't
data-mutating, and approve is already idempotent per the Data Persistence epic).

**Note**: this epic's real device/permission-flow behavior was explicitly cut
from the vertical slice's scope (Cloud Functions/FCM setup was judged
disproportionate infrastructure cost for what it would validate in a slice) —
this epic carries the full, un-slice-tested implementation risk for the iOS
permission path specifically. Per ADR-0010, **the iOS permission/deep-link flow
must be validated on real TestFlight hardware before this epic is considered
done** — simulator FCM delivery is not reliable enough to trust.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-------------------|-------------|
| ADR-0010: Push Notification Delivery Architecture | 2nd-gen `onDocumentCreated` Cloud Function; fixed FCM payload contract; iOS one-shot permission + Settings-deep-link reminder; retry disabled for MVP (time-window-bounded, not attempt-bounded); fire-and-forget, no dedup | MEDIUM — iOS one-shot permission behavior and physical-device FCM delivery were never exercised by the vertical slice (that scope cut was deliberate); this is the epic's real, still-open risk |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-pushnotif-001 | Create-only Firestore trigger (2nd-gen `onDocumentCreated`) | ADR-0010 ✅ |
| TR-pushnotif-002 | FCM payload includes notification, data, and platform-priority fields | ADR-0010 ✅ |
| TR-pushnotif-003 | iOS one-shot permission request; reminder deep-links to Settings rather than re-prompting | ADR-0010 ✅ |
| TR-pushnotif-004 | No dedup/idempotency infrastructure; accepted duplicate-notification tradeoff for MVP | ADR-0010 ✅ |
| TR-pushnotif-005 | Deep-link URI contract `petquest://parent/tasks/pending` | ADR-0010 ✅ |
| TR-pushnotif-006 | Delivery latency target <10s typical / <60s hard threshold; fire-and-forget, no attempt-count retry | ADR-0010 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/push-notification.md` are verified
- All Logic and Integration stories have passing test files in `tests/` (Cloud Function trigger logic is Logic-tier and unit-testable with the Firebase emulator; actual FCM delivery is Integration/manual)
- **The iOS permission/deep-link flow has been validated on real TestFlight hardware** — this is a BLOCKING acceptance criterion per ADR-0010, not advisory, since this behavior was never exercised by the vertical slice
- `retry` is confirmed disabled in the deployed Cloud Function config for MVP

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | onTaskSubmitted Cloud Function | Integration | Complete | ADR-0010 |
| 002 | Notification Permission Request + iOS Reminder Decision Logic | Logic | Complete | ADR-0010 |

**Scope note**: AC-5 (foreground handoff) has no dedicated story — it's satisfied automatically by `firebase_messaging`'s own `onMessage` stream once Story 001's payload contract is correct; the actual in-app banner render is Parent Dashboard UI (#21)'s job, no epic yet.

**Dependency note**: `families/{parentId}.fcmToken` write/refresh is already Complete (Auth & Account Story 008). Neither story here depends on the other — both can build in either order.

## Epic Status Notes

**As of 2026-07-16**: Both stories implemented, tested (69 combined test assertions across `functions/test/index.test.ts` and `tests/unit/push_notification/permission_coordinator_test.dart` — 60 + 9), and code-reviewed (flame-specialist + qa-tester on each, all findings actioned). `retry` confirmed disabled in the Cloud Function trigger config (Story 001, `__endpoint`-verified).

**This epic is deliberately NOT marked Complete.** Per this epic's own Definition of Done and ADR-0010 §3, real iOS TestFlight hardware validation of the permission-request + APNs-delivery + Settings-deep-link flow is a BLOCKING acceptance criterion, not advisory — simulator behavior is explicitly not trusted for this (per `game-concept.md`'s own named Technical Risk). No such hardware is available in this environment. Everything unit-testable without it has been implemented and tested; the epic remains open until that manual validation happens on a real device.

**Real version drift found and corrected during implementation**: both the GDD and ADR-0010 described a 5th `AuthorizationStatus.ephemeral` value that does not exist in the actually-resolved `firebase_messaging_platform_interface` 4.9.2 (only 4 real values). Corrected in the GDD, ADR-0010, both story files, and the implementation — independently re-verified by two separate reviewer agents directly against the installed package source.

**Next step once hardware is available**: build and deploy to a real iOS device via TestFlight, exercise the onboarding permission request, deny it, trigger the reminder flow, confirm it opens Settings (not a re-prompt), grant permission from Settings, and confirm a real task submission produces a delivered push within the 60s contract. Then flip this epic's status to Complete.
