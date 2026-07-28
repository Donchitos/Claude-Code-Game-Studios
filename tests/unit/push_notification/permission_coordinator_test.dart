// Run with:
//   cd src && flutter test ../tests/unit/push_notification/permission_coordinator_test.dart
//
// resolveReminderAction is tested directly (pure function, no fakes
// needed). requestPermissionOnce() uses the same hand-rolled
// `_FakeFirebaseMessaging implements FirebaseMessaging` pattern as
// tests/integration/auth_account/fcm_token_refresh_test.dart — that file's
// header comment explains why (firebase_messaging has no mocks package
// equivalent to firebase_auth_mocks).

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/providers/notification_providers.dart';

const _fakeSettings = NotificationSettings(
  alert: AppleNotificationSetting.enabled,
  announcement: AppleNotificationSetting.disabled,
  authorizationStatus: AuthorizationStatus.authorized,
  badge: AppleNotificationSetting.enabled,
  carPlay: AppleNotificationSetting.disabled,
  lockScreen: AppleNotificationSetting.enabled,
  notificationCenter: AppleNotificationSetting.enabled,
  showPreviews: AppleShowPreviewSetting.always,
  timeSensitive: AppleNotificationSetting.disabled,
  criticalAlert: AppleNotificationSetting.disabled,
  sound: AppleNotificationSetting.enabled,
  providesAppNotificationSettings: AppleNotificationSetting.disabled,
);

class _FakeFirebaseMessaging implements FirebaseMessaging {
  int requestPermissionCallCount = 0;

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    requestPermissionCallCount++;
    return _fakeSettings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('resolveReminderAction (pure logic, AC-8)', () {
    test(
        'test_resolveReminderAction_iOS_denied_resolves_to_openSettings_never_requestPermission',
        () {
      final action = resolveReminderAction(
        isIOS: true,
        authorizationStatus: AuthorizationStatus.denied,
      );

      expect(action, ReminderAction.openSettings);
    });

    test(
        'test_resolveReminderAction_iOS_notDetermined_resolves_to_requestPermission',
        () {
      final action = resolveReminderAction(
        isIOS: true,
        authorizationStatus: AuthorizationStatus.notDetermined,
      );

      expect(action, ReminderAction.requestPermission);
    });

    test('test_resolveReminderAction_iOS_authorized_resolves_to_none', () {
      final action = resolveReminderAction(
        isIOS: true,
        authorizationStatus: AuthorizationStatus.authorized,
      );

      expect(action, ReminderAction.none);
    });

    test('test_resolveReminderAction_iOS_provisional_resolves_to_none', () {
      final action = resolveReminderAction(
        isIOS: true,
        authorizationStatus: AuthorizationStatus.provisional,
      );

      expect(action, ReminderAction.none);
    });

    test(
        'test_resolveReminderAction_android_denied_resolves_to_requestPermission_reprompt_allowed',
        () {
      final action = resolveReminderAction(
        isIOS: false,
        authorizationStatus: AuthorizationStatus.denied,
      );

      expect(action, ReminderAction.requestPermission);
    });

    test(
        'test_resolveReminderAction_android_notDetermined_resolves_to_requestPermission',
        () {
      final action = resolveReminderAction(
        isIOS: false,
        authorizationStatus: AuthorizationStatus.notDetermined,
      );

      expect(action, ReminderAction.requestPermission);
    });

    test('test_resolveReminderAction_android_authorized_resolves_to_none', () {
      final action = resolveReminderAction(
        isIOS: false,
        authorizationStatus: AuthorizationStatus.authorized,
      );

      expect(action, ReminderAction.none);
    });

    test('test_resolveReminderAction_android_provisional_resolves_to_none', () {
      final action = resolveReminderAction(
        isIOS: false,
        authorizationStatus: AuthorizationStatus.provisional,
      );

      expect(action, ReminderAction.none);
    });
  });

  group('NotificationPermissionActions.requestPermissionOnce', () {
    test(
        'test_requestPermissionOnce_calls_FirebaseMessaging_requestPermission_exactly_once',
        () async {
      final messaging = _FakeFirebaseMessaging();
      final container = ProviderContainer(
        overrides: [firebaseMessagingProvider.overrideWithValue(messaging)],
      );
      addTearDown(container.dispose);

      await container.read(notificationPermissionActionsProvider).requestPermissionOnce();

      expect(messaging.requestPermissionCallCount, 1);
    });
  });
}
