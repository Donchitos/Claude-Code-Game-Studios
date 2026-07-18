// Run with:
//   cd src && flutter test ../tests/integration/auth_account/child_profile_selection_screen_test.dart
//
// UI story (Test Evidence gate: ADVISORY per coding-standards.md) — automated
// widget test in lieu of the manual-walkthrough evidence doc, matching this
// project's established pattern (see login_screen_test.dart).
//
// Uses the same hand-rolled minimal Firestore fake pattern as
// child_profile_data_test.dart (fake_cloud_firestore is incompatible with
// cloud_firestore ^6.7.1 — see parent_login_test.dart's header comment).
// Navigation is tested against a real minimal GoRouter (not a plain
// MaterialApp/Navigator) since ChildProfileSelectionScreen uses go_router's
// `context.push()`.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/router_provider.dart';
import 'package:pet_quest/ui/child_profile_selection_screen.dart';

class _FakeQueryDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDocumentSnapshot(this._id, this._data);
  final String _id;
  final Map<String, dynamic> _data;

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _FakeQuerySnapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A collection whose `.get()` never resolves until the test completes it —
/// lets a test observe the Loading state deterministically.
class _ControllableCollectionReference
    implements CollectionReference<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> seeded = {};
  Completer<QuerySnapshot<Map<String, dynamic>>>? _pendingCompleter;
  bool shouldThrow = false;
  int getCallCount = 0;

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    getCallCount++;
    if (shouldThrow) throw Exception('simulated Firestore failure');
    if (_pendingCompleter != null) return _pendingCompleter!.future;
    return _snapshot();
  }

  _FakeQuerySnapshot _snapshot() => _FakeQuerySnapshot(
        seeded.entries
            .map((e) => _FakeQueryDocumentSnapshot(e.key, e.value))
            .toList(),
      );

  /// Makes the next `.get()` call hang until [resolvePending] is called.
  void holdPending() => _pendingCompleter = Completer<QuerySnapshot<Map<String, dynamic>>>();

  void resolvePending() {
    _pendingCompleter?.complete(_snapshot());
    _pendingCompleter = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  final collectionRef = _ControllableCollectionReference();

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => collectionRef;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const parentId = 'parent-1';

  void seedProfiles(_FakeFirestore firestore, int count) {
    for (var i = 1; i <= count; i++) {
      firestore.collectionRef.seeded['child-$i'] = {
        'name': 'Bé $i',
        'avatarId': 'avatar-$i',
        'mochiName': 'Mochi $i',
      };
    }
  }

  /// Pumps a minimal real GoRouter with two routes so context.push() (used
  /// by the screen's profile-card tap) actually navigates — not just a bare
  /// MaterialApp/Navigator.
  Future<GoRouter> pumpWithRealRouter(
    WidgetTester tester,
    FirebaseFirestore firestore, {
    required String parentUid,
  }) async {
    final router = GoRouter(
      initialLocation: '/select-child',
      routes: [
        GoRoute(
          path: '/select-child',
          builder: (context, state) => const ChildProfileSelectionScreen(),
        ),
        GoRoute(
          path: AppRoutes.pinEntry,
          builder: (context, state) => Scaffold(
            body: Text('PIN Entry: ${state.uri.queryParameters['childId']}'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseFirestoreProvider.overrideWithValue(firestore),
          authStateProvider.overrideWith((ref) => Stream.value(_FakeUser(parentUid))),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    return router;
  }

  testWidgets('test_ChildProfileSelectionScreen_renders_a_card_per_profile',
      (tester) async {
    final firestore = _FakeFirestore();
    seedProfiles(firestore, 3);
    await pumpWithRealRouter(tester, firestore, parentUid: parentId);
    await tester.pumpAndSettle();

    expect(find.text('Bé 1'), findsOneWidget);
    expect(find.text('Bé 2'), findsOneWidget);
    expect(find.text('Bé 3'), findsOneWidget);
    expect(find.text('Thêm bé'), findsOneWidget); // 3/4, slot free
  });

  testWidgets(
      'test_ChildProfileSelectionScreen_tap_navigates_to_pin_entry_with_correct_childId',
      (tester) async {
    final firestore = _FakeFirestore();
    seedProfiles(firestore, 2);
    await pumpWithRealRouter(tester, firestore, parentUid: parentId);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bé 1'));
    await tester.pumpAndSettle();

    expect(find.text('PIN Entry: child-1'), findsOneWidget);
  });

  testWidgets('test_ChildProfileSelectionScreen_shows_empty_state_for_0_profiles',
      (tester) async {
    final firestore = _FakeFirestore();
    await pumpWithRealRouter(tester, firestore, parentUid: parentId);
    await tester.pumpAndSettle();

    expect(find.text('Chưa có hồ sơ nào — hãy thêm bé đầu tiên!'), findsOneWidget);
    expect(find.text('Thêm bé'), findsOneWidget);
  });

  testWidgets(
      'test_ChildProfileSelectionScreen_hides_add_child_when_full',
      (tester) async {
    final firestore = _FakeFirestore();
    seedProfiles(firestore, 4);
    await pumpWithRealRouter(tester, firestore, parentUid: parentId);
    await tester.pumpAndSettle();

    expect(find.text('Bé 1'), findsOneWidget);
    expect(find.text('Bé 4'), findsOneWidget);
    expect(find.text('Thêm bé'), findsNothing);
  });

  testWidgets(
      'test_ChildProfileSelectionScreen_shows_loading_then_data',
      (tester) async {
    final firestore = _FakeFirestore();
    seedProfiles(firestore, 1);
    firestore.collectionRef.holdPending();

    await pumpWithRealRouter(tester, firestore, parentUid: parentId);
    await tester.pump(); // one frame — still loading
    expect(find.text('Bé 1'), findsNothing);

    firestore.collectionRef.resolvePending();
    await tester.pumpAndSettle();
    expect(find.text('Bé 1'), findsOneWidget);
  });

  testWidgets(
      'test_ChildProfileSelectionScreen_tap_navigates_to_pin_entry_for_second_profile_not_just_first',
      (tester) async {
    // Regression guard (code review 2026-07-16): a bug that hardcoded the
    // first profile's childId regardless of which card was tapped would
    // still pass a test that only ever taps "Bé 1".
    final firestore = _FakeFirestore();
    seedProfiles(firestore, 2);
    await pumpWithRealRouter(tester, firestore, parentUid: parentId);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bé 2'));
    await tester.pumpAndSettle();

    expect(find.text('PIN Entry: child-2'), findsOneWidget);
  });

  testWidgets(
      'test_ChildProfileSelectionScreen_double_tap_only_navigates_once',
      (tester) async {
    // P1 single-flight guard, added in code review 2026-07-16 — a fast
    // double-tap must not push the PIN entry route twice.
    final firestore = _FakeFirestore();
    seedProfiles(firestore, 1);
    await pumpWithRealRouter(tester, firestore, parentUid: parentId);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bé 1'));
    await tester.tap(find.text('Bé 1'));
    await tester.pumpAndSettle();

    // If the route were pushed twice, both page instances would still be
    // present in the widget tree (only the top one is visible on screen).
    expect(find.text('PIN Entry: child-1'), findsOneWidget);
  });

  testWidgets(
      'test_ChildProfileSelectionScreen_error_state_shows_retry_and_refetches',
      (tester) async {
    // Regression guard (code review 2026-07-16 — see control-manifest.md's
    // 2026-07-16 note): childProfilesProvider must disable riverpod
    // 3.3.2's default silent retry, otherwise this error never surfaces as
    // AsyncError within a normal pumpAndSettle — the screen stays on the
    // loading skeleton instead of showing the manual "Thử lại" button.
    final firestore = _FakeFirestore();
    firestore.collectionRef.shouldThrow = true;
    await pumpWithRealRouter(tester, firestore, parentUid: parentId);
    await tester.pumpAndSettle();

    expect(find.text('Không tải được danh sách hồ sơ'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    final callsBeforeRetry = firestore.collectionRef.getCallCount;

    firestore.collectionRef.shouldThrow = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(firestore.collectionRef.getCallCount, greaterThan(callsBeforeRetry));
    expect(find.text('Không tải được danh sách hồ sơ'), findsNothing);
  });

  testWidgets(
      'test_ChildProfileSelectionScreen_profile_card_meets_minimum_tap_target',
      (tester) async {
    final firestore = _FakeFirestore();
    seedProfiles(firestore, 1);
    await pumpWithRealRouter(tester, firestore, parentUid: parentId);
    await tester.pumpAndSettle();

    final cardSize = tester.getSize(find.byType(InkWell).first);
    expect(cardSize.width, greaterThanOrEqualTo(48));
    expect(cardSize.height, greaterThanOrEqualTo(48));
  });

  testWidgets(
      'test_ChildProfileSelectionScreen_long_name_does_not_overflow_or_throw',
      (tester) async {
    final firestore = _FakeFirestore();
    firestore.collectionRef.seeded['child-1'] = {
      'name': 'Một cái tên rất là dài để kiểm tra tràn chữ trên thẻ hồ sơ',
      'avatarId': 'avatar-1',
      'mochiName': 'Mochi 1',
    };
    await pumpWithRealRouter(tester, firestore, parentUid: parentId);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'test_ChildProfileSelectionScreen_malformed_profile_doc_is_skipped_others_still_render',
      (tester) async {
    final firestore = _FakeFirestore();
    seedProfiles(firestore, 2);
    // Missing 'name' — ChildProfileRepository.getChildProfiles skips this
    // doc rather than crashing the whole list (Story 005 behavior).
    firestore.collectionRef.seeded['child-bad'] = {
      'avatarId': 'avatar-x',
      'mochiName': 'Mochi X',
    };
    await pumpWithRealRouter(tester, firestore, parentUid: parentId);
    await tester.pumpAndSettle();

    expect(find.text('Bé 1'), findsOneWidget);
    expect(find.text('Bé 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeUser implements User {
  _FakeUser(this.uid);
  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
