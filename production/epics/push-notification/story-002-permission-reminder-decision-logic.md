# Story 002: Notification Permission Request + iOS Reminder Decision Logic

> **Epic**: Push Notification
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/push-notification.md`
**Requirement**: `TR-pushnotif-003`, `TR-pushnotif-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Push Notification Delivery Architecture, Decision §3 (iOS one-shot permission + Settings deep-link)

**Engine**: Flutter 3.44.4 / `firebase_messaging ^16.4.3` (actual resolved version, confirmed via `pubspec.lock` — ADR-0010 assumed `^15.x`, a version drift to note, though `requestPermission()`/`getNotificationSettings()`/`AuthorizationStatus` are all confirmed present and unchanged in `16.4.3`) | **Risk**: MEDIUM — the DECISION logic this story implements (given a status, which action to take) is LOW risk, pure and deterministic; the ADR's own MEDIUM rating is about the real iOS dialog/APNs behavior this story does NOT exercise (no widget test, no real permission dialog — see Out of Scope).

**Already Established (do not re-derive)**:
- Auth & Account Story 008 (Complete) explicitly flagged this exact gap in its own Out of Scope section: "Initial FCM token registration/permission request flow... likely belongs to Push Notification epic #9's onboarding story" — this story closes that flagged gap.
- No epic yet owns the actual UI screens that will CALL this logic (Onboarding Flow #24 for the initial ask, Parent Dashboard UI #21 for the reminder) — this story writes the pure, reusable decision function those future epics will consume, matching this codebase's established pattern of writing a pure contract function ahead of its UI consumer (e.g. `rewardFor()` before any UI read it, `knownCategoryIds` before `CustomTaskRepository` existed).
- `firebaseMessagingProvider` already exists (`src/lib/core/firebase_providers.dart:19`) — `Provider<FirebaseMessaging>((ref) => FirebaseMessaging.instance)`. Use it, do not construct a second provider or call `FirebaseMessaging.instance` directly from new code.

**Control Manifest Rules (this layer)**:
- Required: "Client requests permission ONCE at onboarding via `FirebaseMessaging.instance.requestPermission()`" — source: ADR-0010
- Required: "iOS reminder MUST deep-link to Settings (`UIApplication.openSettingsURLString`), NOT re-call `requestPermission()`" — source: ADR-0010
- Required: "MUST read `getNotificationSettings().authorizationStatus` before branching reminder logic" — source: ADR-0010
- Required: "Android may re-prompt normally" — source: ADR-0010
- Required: "iOS permission/deep-link flow MUST be validated on real TestFlight hardware before considered done" — source: ADR-0010 (epic-level gate, not satisfiable by this story — see Out of Scope)

---

## Acceptance Criteria

*From `design/gdd/push-notification.md` AC-8 and ADR-0010 Decision §3:*

- [x] A pure function (e.g. `resolveReminderAction({ platform, authorizationStatus })`) returns one of exactly 3 actions: `requestPermission` (safe to call `requestPermission()` again — Android, any status; or iOS, `notDetermined` only), `openSettings` (iOS + already `denied` — must NOT re-call `requestPermission()`), or `none` (already `authorized`/`provisional` — no reminder needed at all). ⚠️ **Corrected 2026-07-16**: the GDD/ADR describe a 5th `ephemeral` status; the actually-resolved `firebase_messaging_platform_interface` 4.9.2 has no such value (`AuthorizationStatus` is `authorized`/`denied`/`notDetermined`/`provisional` only) — `ephemeral` would be a compile error. Implement against the real 4-value enum.
- [x] On iOS specifically: `denied` status ALWAYS resolves to `openSettings`, never `requestPermission` — this is the core AC-8 guarantee (a re-call would silently no-op with no dialog, per ADR-0010's own explicit warning).
- [x] On Android: `denied` resolves to `requestPermission` (Android permits re-prompting, unlike iOS).
- [x] **Clarified 2026-07-16 (found in code review, qa-tester)**: `resolveReminderAction` takes `authorizationStatus` as an injected parameter rather than calling `getNotificationSettings()` itself — this is a deliberate design choice (same rationale as the `isIOS` injection below: it's what makes the branching logic testable via 8 plain unit tests with no Firebase fake needed at all). The "read via `getNotificationSettings()`, never branch on a stale/cached value" requirement is therefore a CALLER-side contract, not something this story's code enforces directly — whichever future screen calls `resolveReminderAction` (Onboarding #24 / Parent Dashboard #21) is responsible for calling `getNotificationSettings()` immediately before branching, not caching a status value across time. This story's own scope ends at providing the correctly-branching pure function for that caller to use.
- [x] A separate thin wrapper function for the one-shot onboarding call (e.g. `requestNotificationPermissionOnce()`) that calls `FirebaseMessaging.instance.requestPermission()` exactly once — exists as a testable unit even though no UI screen calls it yet (Onboarding Flow #24 has no epic).
- [x] Platform detection uses Flutter's standard `Platform.isIOS`/`defaultTargetPlatform`-equivalent (injectable/overridable for testing — do not hardcode a real `dart:io Platform` check that can't be faked in a unit test).

---

## Implementation Notes

*From ADR-0010 Decision §3 and Key Interfaces:*

```dart
enum ReminderAction { requestPermission, openSettings, none }

ReminderAction resolveReminderAction({
  required bool isIOS,
  required AuthorizationStatus authorizationStatus,
}) {
  // authorized/provisional -> none (real 4-value enum, no ephemeral — see AC note)
  // iOS + denied -> openSettings (NEVER requestPermission — silent no-op risk)
  // iOS + notDetermined -> requestPermission (one-shot hasn't fired yet)
  // Android + denied/notDetermined -> requestPermission (Android permits re-prompting)
}
```
- Keep `isIOS`/platform as an explicit injected `bool` parameter (not read internally from `dart:io Platform.isIOS` inside the pure function) — this is what makes the function testable for BOTH platforms from a single test file without platform-specific test runners, matching this project's established preference for injectable dependencies over static platform checks in testable logic.
- The actual "open Settings" platform call (`UIApplication.openSettingsURLString` equivalent) requires a Flutter package this project does not yet have installed (`url_launcher` with the `app-settings:` scheme, or the dedicated `app_settings` package — neither is in `pubspec.yaml` currently). This story does NOT add that dependency or make the platform call — it returns the `ReminderAction.openSettings` decision only. The actual settings-opening call is deferred to whichever future epic builds the reminder UI (Parent Dashboard #21), which will need to add the platform-call dependency at that point. Do not add an unused dependency speculatively.
- `requestNotificationPermissionOnce()` should take the `FirebaseMessaging` instance via Riverpod (`ref.watch(firebaseMessagingProvider)`), not a raw constructor param, matching this project's established DI convention for provider-backed dependencies (as opposed to `CustomTaskRepository`'s constructor-injection shape, which is for non-provider dependencies like `FirebaseFirestore`).
- `AuthorizationStatus` is the real `firebase_messaging_platform_interface` enum — confirmed present in the actually-resolved `firebase_messaging ^16.4.3` / `firebase_messaging_platform_interface 4.9.2`: `authorized`, `denied`, `notDetermined`, `provisional` (4 values, NOT 5 — `ephemeral` does not exist in this version, see the AC note above). Use it directly, do not invent a project-specific enum for this (only `ReminderAction` above is project-specific).

---

## Out of Scope

- The actual `requestPermission()` iOS system dialog behavior, APNs registration, and the real Settings-app-opening platform call — none of these can be exercised by a Flutter unit test; this story tests the DECISION function only.
- Adding a `url_launcher`/`app_settings` dependency to actually open Settings — deferred to whichever epic builds the reminder UI.
- The actual onboarding screen that calls `requestNotificationPermissionOnce()` — Onboarding Flow (#24), no epic yet.
- The actual Parent Dashboard reminder banner/button that calls `resolveReminderAction()` — Parent Dashboard UI (#21), no epic yet.
- **The epic-level TestFlight hardware validation gate (ADR-0010 §3)** — this story's unit tests validate the branching LOGIC only; they do not and cannot satisfy the epic's own BLOCKING DoD item requiring real-device validation of the actual iOS permission/APNs/Settings-deep-link flow. This remains open at the epic level after this story closes.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. Derived from ADR-0010 Decision §3 and this story's own Acceptance Criteria:*

```
Test: iOS + denied resolves to openSettings, never requestPermission (the core AC-8 guarantee)
  Given: isIOS=true, authorizationStatus=denied
  When: resolveReminderAction is called
  Then: returns ReminderAction.openSettings

Test: iOS + notDetermined resolves to requestPermission (one-shot hasn't fired yet)
  Given: isIOS=true, authorizationStatus=notDetermined
  When: resolveReminderAction is called
  Then: returns ReminderAction.requestPermission

Test: iOS + authorized/provisional resolve to none (real 4-value enum, no ephemeral)
  Given: isIOS=true, authorizationStatus in {authorized, provisional}
  When: resolveReminderAction is called for each
  Then: returns ReminderAction.none for both — no reminder needed

Test: Android + denied resolves to requestPermission (Android permits re-prompting)
  Given: isIOS=false, authorizationStatus=denied
  When: resolveReminderAction is called
  Then: returns ReminderAction.requestPermission

Test: Android + notDetermined resolves to requestPermission
  Given: isIOS=false, authorizationStatus=notDetermined
  When: resolveReminderAction is called
  Then: returns ReminderAction.requestPermission

Test: Android + authorized/provisional resolve to none
  Given: isIOS=false, authorizationStatus in {authorized, provisional}
  When: resolveReminderAction is called for each
  Then: returns ReminderAction.none for both

Test: requestNotificationPermissionOnce calls FirebaseMessaging.requestPermission exactly once
  Given: a fake/mocked FirebaseMessaging instance via provider override
  When: requestNotificationPermissionOnce() is invoked
  Then: the fake's requestPermission() is called exactly once
```

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/push_notification/permission_coordinator_test.dart` — must exist and pass

**Status**: [x] Created — `tests/unit/push_notification/permission_coordinator_test.dart`, 9/9 passing.

---

## Dependencies

- Depends on: None (pure Dart logic; `firebaseMessagingProvider` already exists from a prior epic's setup, not a story-level dependency).
- Unlocks: Onboarding Flow (#24, no epic yet) — the one-shot permission call. Parent Dashboard UI (#21, no epic yet) — the reminder banner's branching logic.

---

## Completion Notes

**Closed**: 2026-07-16

Implemented `resolveReminderAction()` (pure function), `ReminderAction` enum, and `NotificationPermissionActions`/`notificationPermissionActionsProvider` in `src/lib/providers/notification_providers.dart`, following the `ParentOverrideActions`/`auth_providers.dart` action-class convention.

**Real version drift found and corrected before implementation**: both the GDD and ADR-0010 describe a 5th `AuthorizationStatus.ephemeral` value. Verified against the actually-resolved `firebase_messaging ^16.4.3` / `firebase_messaging_platform_interface 4.9.2`: the real enum has only 4 values (`authorized`/`denied`/`notDetermined`/`provisional`) — `ephemeral` is a compile error (`undefined_enum_constant`) in this version. Corrected in the code, this story file, ADR-0010, and the GDD, each with a dated note — independently re-verified by flame-specialist directly against the installed package source, not just trusted.

**Code review**: flame-specialist (APPROVED WITH SUGGESTIONS) + qa-tester (GAPS) run in parallel. Findings actioned:
1. **Real bug (flame-specialist)**: a stale doc comment on `ReminderAction.none` still listed `ephemeral` as a live status, contradicting the corrected switch statement 12 lines below. Fixed.
2. **Real spec gap (qa-tester)**: AC bullet 4 described the function calling `getNotificationSettings()` internally, but `resolveReminderAction` deliberately takes `authorizationStatus` as an injected parameter (the same rationale as the `isIOS` injection — it's what makes 8 clean unit tests possible with no Firebase fake needed for the branching logic itself). Clarified the AC as a caller-side contract (whichever future screen calls this function is responsible for reading `getNotificationSettings()` immediately before branching), not something this story's code enforces.
3. **Diagnostic-completeness suggestion (qa-tester)**: two of the six `resolveReminderAction` tests collapsed 2 combinations each into a `for` loop — not a masking risk (still fails on any regression), but under-reports which combination broke on a single run. Split into 4 individual tests, matching the precision of the other 4 tests, for full 8-combination parity.

Both reviewers independently confirmed the core AC-8 guarantee (iOS + `denied` → `openSettings`, never `requestPermission`) holds structurally (traced every code path, not just trusted the tests), the `isIOS`/`authorizationStatus` injection pattern is correct DI (not overengineering), and the `NotificationSettings`/`AppleNotificationSetting` fake in the test file is correctly typed against the real 12-parameter constructor.

**Test evidence**: `tests/unit/push_notification/permission_coordinator_test.dart` — 9/9 passing (8 `resolveReminderAction` combinations + 1 `requestPermissionOnce` DI test). Full analyzer clean (baseline 11 pre-accepted `prefer_initializing_formals` lints unchanged). Full project suite: 256/256 passing.
