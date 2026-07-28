import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/firebase_providers.dart';

/// The action a caller (Onboarding Flow #24 for the initial ask, Parent
/// Dashboard #21 for the reminder) should take given the current
/// [AuthorizationStatus], per ADR-0010 Decision §3 (Push Notification
/// Story 002). This project owns the CONTRACT here even though neither
/// consuming screen has an epic yet — same pattern as `rewardFor()`
/// (`src/lib/core/reward_table.dart`) existing before any UI read it.
enum ReminderAction {
  /// Safe to call `requestPermission()` again — Android at any
  /// not-yet-authorized status (Android permits re-prompting), or iOS
  /// specifically when the one-shot dialog has never fired
  /// (`notDetermined`).
  requestPermission,

  /// iOS + `denied` — the one-shot dialog already fired and resolved
  /// negatively. Calling `requestPermission()` again would silently no-op
  /// with no dialog shown (ADR-0010 Decision §3's explicit warning) — the
  /// only correct action left is deep-linking to Settings.
  openSettings,

  /// Already `authorized`/`provisional` — no reminder needed.
  none,
}

/// Decides what a permission-reminder UI should do, given the current
/// authorization status and platform — the pure branching logic behind
/// ADR-0010 Decision §3's iOS one-shot-permission rule (TR-pushnotif-003).
///
/// [isIOS] is an explicit injected parameter rather than read internally
/// from `dart:io Platform.isIOS`, so this function is testable for BOTH
/// platforms from a single test file without a platform-specific runner.
///
/// ⚠️ **Corrected 2026-07-16**: both the GDD and ADR-0010 describe a 5th
/// `AuthorizationStatus.ephemeral` value ("a promptless quiet-notification
/// tier"). The actually-resolved `firebase_messaging_platform_interface`
/// 4.9.2 (pulled in by `firebase_messaging ^16.4.3`) defines only 4 values —
/// `authorized`, `denied`, `notDetermined`, `provisional` — `ephemeral`
/// does not exist in this version and referencing it is a compile error
/// (`undefined_enum_constant`). This `switch` exhaustively covers the real
/// 4-value enum; the GDD/ADR's `ephemeral` mention should be treated as
/// stale until independently re-verified against whatever version
/// production ultimately pins (same "snapshot, re-verify before relying
/// on" caveat as this project's other post-cutoff API corrections).
ReminderAction resolveReminderAction({
  required bool isIOS,
  required AuthorizationStatus authorizationStatus,
}) {
  switch (authorizationStatus) {
    case AuthorizationStatus.authorized:
    case AuthorizationStatus.provisional:
      return ReminderAction.none;
    case AuthorizationStatus.denied:
      return isIOS ? ReminderAction.openSettings : ReminderAction.requestPermission;
    case AuthorizationStatus.notDetermined:
      return ReminderAction.requestPermission;
  }
}

/// Notification-permission actions (Push Notification Story 002). Exposed
/// as a bound object rather than a bare top-level function — same
/// `Ref`/`WidgetRef` unification rationale as [ParentOverrideActions] in
/// `auth_providers.dart`.
class NotificationPermissionActions {
  NotificationPermissionActions(this._ref);

  final Ref _ref;

  /// The one-shot onboarding permission request (ADR-0010 Decision §3) —
  /// calls `requestPermission()` exactly once. No UI screen calls this yet
  /// (Onboarding Flow #24 has no epic); exists as a testable unit ahead of
  /// its consumer, per this story's own scope.
  Future<NotificationSettings> requestPermissionOnce() {
    return _ref.read(firebaseMessagingProvider).requestPermission();
  }
}

final notificationPermissionActionsProvider =
    Provider<NotificationPermissionActions>((ref) {
  return NotificationPermissionActions(ref);
});
