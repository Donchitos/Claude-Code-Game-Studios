// Run with:
//   cd src && flutter test ../tests/integration/parent-dashboard-ui/parent_shell_banner_test.dart
//
// Story: parent-dashboard-ui/story-004-fcm-banner-state-machine — Test
// Evidence section, QA Test Case 6 ("tap vs. dismiss share identical state
// transitions... the integration test should confirm the widget layer
// respects this split"). ADR-0015's own Validation Criteria also calls for
// "ParentShellScaffold's ScaffoldMessenger genuinely shows/hides/updates a
// MaterialBanner" as an Integration-tier check, separate from
// `fcm_banner_state_machine_test.dart`'s pure-reducer BLOCKING coverage.
//
// Added during this story's own code review — both flame-specialist and
// qa-tester independently flagged that no widget/integration test anywhere
// exercised the actual `MaterialBanner` render path, `_handleBannerTap`'s
// navigate-only-if-not-already-there branch, or `_handleBannerDismiss`'s
// never-navigate behavior. This file closes that gap. It is deliberately
// separate from `parent_shell_test.dart` (which keeps
// `authorizationStatus: authorized` specifically so the Story 004 banner
// NEVER renders during its own tests — see that file's own header comment)
// to avoid any risk of this file's message injection bleeding into that
// file's unrelated assertions.
//
// Message injection: `FirebaseMessaging.onMessage` is a plain static
// broadcast `StreamController` (`FirebaseMessagingPlatform.onMessage`,
// verified against the installed `firebase_messaging_platform_interface
// 4.9.2` source during code review — not app-scoped, no `Firebase
// .initializeApp()` needed to add to it). Each test's own
// `ParentShellScaffold.dispose()` cancels its subscription before the next
// test's widget tree mounts, so `.add()` calls here don't leak into a later
// test's listener.
//
// Children list is deliberately seeded EMPTY: `familyPendingTasksProvider`
// short-circuits to `[]` without any per-child Firestore query when
// `childProfilesProvider` resolves to an empty list (see
// `task_providers.dart`), so the only Firestore surface this file's fake
// needs to support is `children` collection `.get()` — no `tasks`
// subcollection query/snapshot machinery required. This means every
// message's `bannerDisplayText` resolves via the documented fallback path
// ("Có nhiệm vụ mới cần duyệt") rather than the child-name/task-title
// lookup — that lookup path is a separate, lower-stakes concern (ADR-0015's
// own Risks section: "a low-stakes display-text race, not a
// correctness-critical path") intentionally left for a future addition
// rather than expanding this file's fake Firestore further.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/router_provider.dart';

class _FakeUser implements User {
  _FakeUser(this.uid);
  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async =>
      _EmptyQuerySnapshot();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Only `.collection(path).get()` is exercised — see file header comment for
/// why an empty `children` list means no `tasks` subcollection support is
/// needed at all.
class _FakeFirestore implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _FakeCollectionReference();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _fakeAuthorizedSettings = NotificationSettings(
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

const _fakeDeclinedSettings = NotificationSettings(
  alert: AppleNotificationSetting.disabled,
  announcement: AppleNotificationSetting.disabled,
  authorizationStatus: AuthorizationStatus.denied,
  badge: AppleNotificationSetting.disabled,
  carPlay: AppleNotificationSetting.disabled,
  lockScreen: AppleNotificationSetting.disabled,
  notificationCenter: AppleNotificationSetting.disabled,
  showPreviews: AppleShowPreviewSetting.always,
  timeSensitive: AppleNotificationSetting.disabled,
  criticalAlert: AppleNotificationSetting.disabled,
  sound: AppleNotificationSetting.disabled,
  providesAppNotificationSettings: AppleNotificationSetting.disabled,
);

class _FakeFirebaseMessaging implements FirebaseMessaging {
  _FakeFirebaseMessaging(this._settings);
  final NotificationSettings _settings;

  @override
  Future<NotificationSettings> getNotificationSettings() async => _settings;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const parentId = 'parent-1';

  /// Fixed-frame-count pump, never `pumpAndSettle()` — same convention as
  /// every other real-router test in this epic (an indeterminate
  /// `CircularProgressIndicator()` while `childProfilesProvider`/
  /// `familyPendingTasksProvider` resolve would hang `pumpAndSettle()`).
  Future<void> pumpSteps(WidgetTester tester,
      [int steps = 10, Duration step = const Duration(milliseconds: 16)]) async {
    for (var i = 0; i < steps; i++) {
      await tester.pump(step);
    }
  }

  /// Reaches `/parent/dashboard` via the REAL `parentShellRoute` (both
  /// tabs), with [authorized] controlling whether the permission-reminder
  /// banner is eligible.
  Future<ProviderContainer> pumpParentShell(
    WidgetTester tester, {
    bool authorized = true,
  }) async {
    final container = ProviderContainer(
      overrides: [
        firebaseFirestoreProvider.overrideWithValue(_FakeFirestore()),
        authStateProvider.overrideWith((ref) => Stream.value(_FakeUser(parentId))),
        firebaseMessagingProvider.overrideWithValue(
          _FakeFirebaseMessaging(authorized ? _fakeAuthorizedSettings : _fakeDeclinedSettings),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.parentDashboard,
      routes: [parentShellRoute],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpSteps(tester);
    return container;
  }

  group('MaterialBanner rendering (ADR-0015 Decision §1/§4)', () {
    testWidgets('test_messageArrives_rendersMaterialBanner_withFallbackText',
        (tester) async {
      await pumpParentShell(tester);
      expect(find.byType(MaterialBanner), findsNothing);

      FirebaseMessagingPlatform.onMessage.add(
        const RemoteMessage(data: {'taskId': 'task-1', 'childId': 'child-1'}),
      );
      await pumpSteps(tester);

      expect(find.byType(MaterialBanner), findsOneWidget);
      // No matching task/child seeded (file header comment) — the
      // documented fallback text, not a crash or blank banner.
      expect(find.text('Có nhiệm vụ mới cần duyệt'), findsOneWidget);
    });

    testWidgets('test_secondMessage_liveUpdatesSameBanner_toCoalescedText',
        (tester) async {
      await pumpParentShell(tester);

      FirebaseMessagingPlatform.onMessage.add(
        const RemoteMessage(data: {'taskId': 'task-1', 'childId': 'child-1'}),
      );
      await pumpSteps(tester);
      expect(find.byType(MaterialBanner), findsOneWidget);

      FirebaseMessagingPlatform.onMessage.add(
        const RemoteMessage(data: {'taskId': 'task-2', 'childId': 'child-1'}),
      );
      await pumpSteps(tester);

      // Still exactly ONE MaterialBanner (live-updated in place, per GDD
      // Core Rule 6 — never a second banner stacked underneath).
      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.text('2 nhiệm vụ mới đang chờ'), findsOneWidget);
    });
  });

  group('Tap navigates only if not already on Tab Nhiệm vụ (GDD Core Rule 6)', () {
    testWidgets(
        'test_tapFromGiaDinhTab_navigatesToNhiemVu_andDismissesBanner',
        (tester) async {
      final container = await pumpParentShell(tester);

      // Switch to Gia đình (index 1) BEFORE the message arrives, so the
      // banner is genuinely tapped from the non-default tab.
      container.read(activeChildBranchIndexProvider.notifier).state = 1;
      await tester.tap(find.text('Gia đình'));
      await pumpSteps(tester);
      expect(find.text('Gia đình'), findsWidgets); // sanity: tab switched

      FirebaseMessagingPlatform.onMessage.add(
        const RemoteMessage(data: {'taskId': 'task-1', 'childId': 'child-1'}),
      );
      await pumpSteps(tester);
      expect(find.byType(MaterialBanner), findsOneWidget);

      await tester.tap(find.byKey(const Key('parentShellBannerTapTarget')));
      // MaterialBanner's own exit animation is 250ms — pumpSteps' default
      // 10x16ms=160ms isn't enough to let it fully leave the tree.
      await pumpSteps(tester, 25);

      // Navigated to Tab Nhiệm vụ — its own AppBar title is now present.
      expect(find.text('Nhiệm vụ'), findsWidgets);
      // Banner dismissed as part of the same tap (bannerDismissedOrTapped()
      // resets unseenCount to 0 -> displayKind back to none).
      expect(find.byType(MaterialBanner), findsNothing);
    });

    testWidgets(
        'test_tapWhileAlreadyOnNhiemVuTab_doesNotNavigate_stillDismissesBanner',
        (tester) async {
      await pumpParentShell(tester); // default route IS Tab Nhiệm vụ

      FirebaseMessagingPlatform.onMessage.add(
        const RemoteMessage(data: {'taskId': 'task-1', 'childId': 'child-1'}),
      );
      await pumpSteps(tester);
      expect(find.byType(MaterialBanner), findsOneWidget);

      await tester.tap(find.byKey(const Key('parentShellBannerTapTarget')));
      await pumpSteps(tester, 25);

      // Still on Tab Nhiệm vụ (no-op navigation — GDD's own explicit AC),
      // but the banner is gone.
      expect(find.text('Nhiệm vụ'), findsWidgets);
      expect(find.byType(MaterialBanner), findsNothing);
    });
  });

  group('Dismiss never navigates (GDD Core Rule 6 / Edge Case 5)', () {
    testWidgets('test_dismissButton_closesBanner_neverNavigates_fromGiaDinhTab',
        (tester) async {
      final container = await pumpParentShell(tester);

      container.read(activeChildBranchIndexProvider.notifier).state = 1;
      await tester.tap(find.text('Gia đình'));
      await pumpSteps(tester);

      FirebaseMessagingPlatform.onMessage.add(
        const RemoteMessage(data: {'taskId': 'task-1', 'childId': 'child-1'}),
      );
      await pumpSteps(tester);
      expect(find.byType(MaterialBanner), findsOneWidget);

      await tester.tap(find.byKey(const Key('parentShellBannerDismissButton')));
      await pumpSteps(tester, 25);

      expect(find.byType(MaterialBanner), findsNothing);
      // Dismiss must NOT have navigated — still on Gia đình, Nhiệm vụ's own
      // AppBar title is absent (only the NavigationBar destination label,
      // which reads the same string, would remain — so assert the ABSENCE
      // of the family tab's own content instead, an unambiguous signal).
      expect(find.text('Chưa có hồ sơ con nào'), findsOneWidget);
    });
  });

  group('Permission-declined reminder banner (GDD Core Rule 7)', () {
    testWidgets(
        'test_permissionDeclined_showsReminderOnColdStart_dismissClearsIt_neverNavigates',
        (tester) async {
      await pumpParentShell(tester, authorized: false);

      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(
        find.text('Bật thông báo để biết ngay khi con submit task →'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('parentShellBannerDismissButton')));
      await pumpSteps(tester, 25);

      expect(find.byType(MaterialBanner), findsNothing);
      // Still on Tab Nhiệm vụ — reminder dismiss never navigates (identical
      // no-navigate rule as the FCM banner's own dismiss).
      expect(find.text('Nhiệm vụ'), findsWidgets);
    });

    testWidgets(
        'test_permissionDeclined_thenFcmArrives_replacesReminderImmediately_noQueueing',
        (tester) async {
      await pumpParentShell(tester, authorized: false);
      expect(
        find.text('Bật thông báo để biết ngay khi con submit task →'),
        findsOneWidget,
      );

      FirebaseMessagingPlatform.onMessage.add(
        const RemoteMessage(data: {'taskId': 'task-1', 'childId': 'child-1'}),
      );
      await pumpSteps(tester);

      // Exactly one MaterialBanner — the reminder was replaced immediately
      // (removeCurrentMaterialBanner + showMaterialBanner), not queued
      // behind an exit animation (ADR-0015 Decision §1 / this story's own
      // banner-slot conflict resolution).
      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.text('Có nhiệm vụ mới cần duyệt'), findsOneWidget);
      expect(
        find.text('Bật thông báo để biết ngay khi con submit task →'),
        findsNothing,
      );
    });
  });
}
