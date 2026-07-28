// Run with:
//   cd src && flutter test ../tests/integration/parent-dashboard-ui/pending_list_approve_reject_test.dart
//
// Story: parent-dashboard-ui/story-001-pending-list-approve-reject — Test
// Evidence section. Covers all 7 QA Test Cases from the story file (AC-1
// through AC-7), plus supplementary coverage for other Acceptance Criteria
// bullets this story's own file lists (offline pre-check wiring, "Chọn bé"
// wiring + absorption sanity, P1 single-flight regression, FAB absorption).
//
// Two different fake-repository strategies, deliberately, matching each
// group's actual concern:
//   - AC-1/AC-2/AC-7 (rendering/list/error) and AC-6 (tab switch) exercise
//     the REAL `ParentApprovalRepository` against a hand-rolled fake
//     Firestore supporting `.collection().where().orderBy().snapshots()`
//     (for `familyPendingTasksProvider`) AND `.doc()`/`runTransaction()`
//     (for the repository itself) — this is genuine wiring-level coverage.
//   - AC-3/AC-4/AC-5 (event emission) override `parentApprovalRepositoryProvider`
//     with a small controllable stub instead. `ParentApprovalRepository`'s
//     OWN idempotency/level-up/chest logic is already exhaustively covered
//     by `tests/integration/parent_approval/approve_task_test.dart` (12+
//     cases) — re-deriving that here (e.g. simulating a real two-device race
//     through this widget) would duplicate that coverage, not add to it.
//     This story's own responsibility is narrower and different: "given a
//     result from the repository, does the WIDGET emit the right
//     `GameEvent`s?" — a stub is the correct, focused boundary for that,
//     same reasoning `create_custom_task_test.dart`'s header comment already
//     applies to `CustomTaskRepository`.
//
// AC-2 (multi-child correctness) is this story's own unblock fix's reason
// for existing (`familyPendingTasksProvider` replacing the single-child-
// scoped `pendingTasksProvider`) — its test below seeds TWO real children,
// each with their own pending task, via the same hand-rolled fake Firestore
// used everywhere else in this file. Not a single-child stand-in.
//
// Pump strategy: NEVER `pumpAndSettle()` in this file — same convention as
// `create_custom_task_test.dart`/`family_tab_reset_pin_test.dart` in this
// epic (a bounded `pumpSteps` helper is used everywhere instead), since a
// `StreamProvider` that hasn't (yet) received its first snapshot, or a
// dialog/route transition mid-flight, can leave scheduled frames pending
// indefinitely.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` (riverpod 3.x) lives in `misc.dart`, not the main barrel export
// — see this file's `_pumpApp`/similar helper using `List<Override>`.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/core/game_event_bus.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/core/parent_approval_repository.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/parent_approval_providers.dart';
import 'package:pet_quest/providers/router_provider.dart';
import 'package:pet_quest/ui/create_custom_task_sheet.dart';
import 'package:pet_quest/ui/parent_dashboard_family_tab.dart';
import 'package:pet_quest/ui/parent_dashboard_tasks_tab.dart';
import 'package:pet_quest/ui/select_child_action.dart';

// ---------------------------------------------------------------------------
// Hand-rolled fake Firestore — supports the 3 call shapes this story's
// providers/repository need: `.collection(path).get()` (childProfilesProvider),
// `.collection(path).where(...).orderBy(...).snapshots()`
// (familyPendingTasksProvider, per child), and `.doc(path)` +
// `runTransaction()` (ParentApprovalRepository). All 3 share ONE generic
// path-keyed store so a transaction's write is immediately visible to the
// live query streams — required for AC-6 and AC-7's error-recovery test to
// be genuine, not just structurally present.
// ---------------------------------------------------------------------------

class _FakeUser implements User {
  _FakeUser(this.uid);
  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocumentSnapshot(this._data);
  final Map<String, dynamic>? _data;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => _data != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this.collectionPath, this.id, this._firestore);

  final String collectionPath;
  @override
  final String id;
  final _FakeFirestore _firestore;

  @override
  String get path => '$collectionPath/$id';

  @override
  CollectionReference<Map<String, dynamic>> get parent =>
      _FakeCollectionReference(collectionPath, _firestore);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return _FakeDocumentSnapshot(_firestore.store[collectionPath]?[id]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQueryDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDocumentSnapshot(this._ref, this._data);
  final _FakeDocumentReference _ref;
  final Map<String, dynamic> _data;

  @override
  String get id => _ref.id;

  @override
  Map<String, dynamic> data() => _data;

  @override
  DocumentReference<Map<String, dynamic>> get reference => _ref;

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

/// `.where()`/`.orderBy()`/`.snapshots()` — the exact chain
/// `familyPendingTasksProvider` calls per child
/// (`.collection(...).where('status', isEqualTo: 'pending').orderBy('submittedAt',
/// descending: true).snapshots()`). Re-computes its filtered/sorted result
/// live from [_FakeFirestore]'s shared store every time that collection path
/// changes (add/update via `runTransaction` or direct seeding) — this is
/// what makes AC-6/AC-7 genuine: a transaction's committed write is
/// immediately reflected in the next emission, same as real Firestore.
class _FakeQuery implements Query<Map<String, dynamic>> {
  _FakeQuery(
    this.path,
    this._firestore, {
    this.whereField,
    this.whereEquals,
    this.orderByField,
    this.descending = false,
  });

  final String path;
  final _FakeFirestore _firestore;
  final String? whereField;
  final Object? whereEquals;
  final String? orderByField;
  final bool descending;

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return _FakeQuery(
      path,
      _firestore,
      whereField: field as String,
      whereEquals: isEqualTo,
      orderByField: orderByField,
      descending: descending,
    );
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    return _FakeQuery(
      path,
      _firestore,
      whereField: whereField,
      whereEquals: whereEquals,
      orderByField: field as String,
      descending: descending,
    );
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return _firestore.watchCollection(path).map(_buildSnapshot);
  }

  QuerySnapshot<Map<String, dynamic>> _buildSnapshot(
    Map<String, Map<String, dynamic>> docs,
  ) {
    var entries = docs.entries.toList();
    if (whereField != null) {
      entries = entries.where((e) => e.value[whereField] == whereEquals).toList();
    }
    if (orderByField != null) {
      entries.sort((a, b) {
        final av = a.value[orderByField] as Timestamp;
        final bv = b.value[orderByField] as Timestamp;
        return descending ? bv.compareTo(av) : av.compareTo(bv);
      });
    }
    return _FakeQuerySnapshot([
      for (final e in entries)
        _FakeQueryDocumentSnapshot(_FakeDocumentReference(path, e.key, _firestore), e.value),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  _FakeCollectionReference(this.path, this._firestore);
  final String path;
  final _FakeFirestore _firestore;

  @override
  DocumentReference<Map<String, dynamic>>? get parent {
    final segments = path.split('/');
    if (segments.length < 2) return null;
    final parentDocId = segments[segments.length - 2];
    final parentCollectionPath = segments.sublist(0, segments.length - 2).join('/');
    return _FakeDocumentReference(parentCollectionPath, parentDocId, _firestore);
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    if (path == FirestorePaths.children(_firestore.failChildrenReadForParentId ?? '') &&
        _firestore.failChildrenReadForParentId != null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'simulated-failure',
        message: 'Simulated children read failure for test',
      );
    }
    final docs = _firestore.store[path] ?? const <String, Map<String, dynamic>>{};
    return _FakeQuerySnapshot([
      for (final entry in docs.entries)
        _FakeQueryDocumentSnapshot(_FakeDocumentReference(path, entry.key, _firestore), entry.value),
    ]);
  }

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return _FakeQuery(path, _firestore, whereField: field as String, whereEquals: isEqualTo);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordedWrite {
  _RecordedWrite(this.collectionPath, this.docId, this.data);
  final String collectionPath;
  final String docId;
  final Map<String, dynamic> data;
}

class _FakeTransaction implements Transaction {
  _FakeTransaction(this._firestore);
  final _FakeFirestore _firestore;
  final pendingUpdates = <_RecordedWrite>[];

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async {
    final ref = documentReference as _FakeDocumentReference;
    final data = _firestore.store[ref.collectionPath]?[ref.id];
    return _FakeDocumentSnapshot(data) as DocumentSnapshot<T>;
  }

  @override
  Transaction update(
    DocumentReference documentReference,
    Map<Object, Object?> data,
  ) {
    final ref = documentReference as _FakeDocumentReference;
    pendingUpdates.add(_RecordedWrite(ref.collectionPath, ref.id, Map<String, dynamic>.from(data)));
    return this;
  }

  @override
  Transaction delete(DocumentReference documentReference) =>
      throw UnimplementedError('not used by ParentApprovalRepository');

  @override
  Transaction set<T>(DocumentReference<T> documentReference, T data, [SetOptions? options]) =>
      throw UnimplementedError('not used by ParentApprovalRepository');
}

class _FakeFirestore implements FirebaseFirestore {
  /// collectionPath -> (docId -> data).
  final store = <String, Map<String, Map<String, dynamic>>>{};
  final _changeControllers = <String, StreamController<void>>{};

  /// Set to a parentId to simulate the CHILDREN collection read itself
  /// failing (AC-7 / QA AC-7) — distinct from the tasks-query error case
  /// below.
  String? failChildrenReadForParentId;

  /// If non-null, `runTransaction()` awaits this before running the handler
  /// — lets a test hold a transaction genuinely "in flight" across a tab
  /// switch (AC-6 / QA AC-6).
  Completer<void>? transactionGate;

  void seedChildren(String parentId, List<ChildProfile> children) {
    final docs = store.putIfAbsent(FirestorePaths.children(parentId), () => {});
    for (final child in children) {
      docs[child.childId] = {
        'name': child.name,
        'avatarId': child.avatarId,
        'mochiName': child.mochiName,
      };
    }
  }

  void seedTask(
    String parentId,
    String childId,
    String taskId,
    Map<String, dynamic> data,
  ) {
    final path = FirestorePaths.tasks(parentId, childId);
    final docs = store.putIfAbsent(path, () => {});
    docs[taskId] = data;
    _notify(path);
  }

  void _notify(String path) => _changeControllers[path]?.add(null);

  Stream<Map<String, Map<String, dynamic>>> watchCollection(String path) {
    return Stream.multi((controller) {
      controller.add(Map.of(store[path] ?? const {}));
      final ctrl = _changeControllers.putIfAbsent(path, () => StreamController<void>.broadcast());
      final sub = ctrl.stream.listen((_) => controller.add(Map.of(store[path] ?? const {})));
      controller.onCancel = sub.cancel;
    });
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _FakeCollectionReference(path, this);

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) {
    final segments = path.split('/');
    final id = segments.last;
    final collectionPath = segments.sublist(0, segments.length - 1).join('/');
    return _FakeDocumentReference(collectionPath, id, this);
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    if (transactionGate != null) {
      await transactionGate!.future;
    }
    final txn = _FakeTransaction(this);
    final result = await transactionHandler(txn);
    for (final w in txn.pendingUpdates) {
      final bucket = store.putIfAbsent(w.collectionPath, () => {});
      bucket[w.docId] = {...?bucket[w.docId], ...w.data};
      _notify(w.collectionPath);
    }
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Offline pre-check fake (`connectivity_plus` 7.3.0's verified shape — see
/// `parent_approval_providers.dart`'s own doc comment): `implements
/// Connectivity` via Dart's implicit interfaces, same pattern this
/// codebase's other fakes already use for concrete classes with a private
/// constructor.
class _FakeOfflineConnectivity implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      [ConnectivityResult.none];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Default connectivity fake for every test that doesn't specifically test
/// the offline path — resolves synchronously to "online", same as
/// `_FakeOfflineConnectivity` resolves synchronously to "offline". Without
/// EITHER override, `connectivityProvider`'s real `Connectivity()` singleton
/// hits `connectivity_plus`'s actual platform channel, which has no
/// registered handler in this widget-test environment: unlike a plain
/// `Future` rejection, a MethodChannel call crosses into REAL async
/// machinery outside Flutter's fake test clock, so `pumpSteps`' bounded
/// `tester.pump()` loop (fake-clock-only, deliberately never
/// `tester.runAsync`/`pumpAndSettle` per this file's header comment) can
/// never observe it resolving — `_isOfflineBestEffort`'s `await` inside
/// `_approveTask`/`_rejectTask` would stay pending for the entire test,
/// silently preventing every downstream call (approve/reject never reached,
/// zero events, zero stub calls) with no thrown exception to explain why.
/// Found while diagnosing every AC-3/AC-4/AC-5/AC-6/P1 test failing
/// identically at "0 calls made" despite a correctly-wired stub override.
class _FakeOnlineConnectivity implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      [ConnectivityResult.wifi];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Parent Dashboard UI Story 004 (ADR-0015) addition — `ParentShellScaffold
/// .initState()` now reads `firebaseMessagingProvider.getNotificationSettings()`
/// once. The default `firebaseMessagingProvider` resolves `FirebaseMessaging
/// .instance`, which requires a live Firebase app and throws `[core/no-app]`
/// in this widget-test environment (no `Firebase.initializeApp()` here) —
/// this fake avoids that for AC-6's real-router test (the only test in this
/// file that constructs a real `ParentShellScaffold`). `authorized` keeps
/// `bannerStateProvider.displayKind` at `none` so no incidental banner shows
/// up during a test that isn't exercising Story 004's own banner logic.
const _fakeNotificationSettings = NotificationSettings(
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
  @override
  Future<NotificationSettings> getNotificationSettings() async => _fakeNotificationSettings;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Controllable stub for the event-emission test groups (AC-3/AC-4/AC-5) —
/// see file header comment for why a stub, not the real repository, is the
/// correct boundary for those tests.
class _StubParentApprovalRepository implements ParentApprovalRepository {
  ApproveResult? nextApproveResult;
  Object? approveThrows;
  Object? rejectThrows;
  int approveCallCount = 0;
  int rejectCallCount = 0;

  /// When set, `approveTask`/`rejectTask` both suspend here before
  /// resolving — lets a test hold a call genuinely "in flight" long enough
  /// for a second tap to land while the first is still pending. Without
  /// this, `tester.tap()`'s own internal `await` fully drains this stub's
  /// (otherwise instantly-resolving) async chain before the test can issue
  /// a second tap at all — there would be no real race left to observe
  /// (found diagnosing this story's own P1 regression tests, which need
  /// one). Shared between both methods since a single card is only ever
  /// mid-approve OR mid-reject at once, never both.
  Completer<void>? gate;

  @override
  Future<ApproveResult?> approveTask({
    required String parentId,
    required String childId,
    required String taskId,
  }) async {
    approveCallCount++;
    if (gate != null) await gate!.future;
    if (approveThrows != null) throw approveThrows!;
    return nextApproveResult;
  }

  @override
  Future<void> rejectTask({
    required String parentId,
    required String childId,
    required String taskId,
  }) async {
    rejectCallCount++;
    if (gate != null) await gate!.future;
    if (rejectThrows != null) throw rejectThrows!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const parentId = 'parent-1';
  const childA = ChildProfile(
    childId: 'child-1',
    name: 'Bé An',
    avatarId: 'avatar-1',
    mochiName: 'Mochi An',
  );
  const childB = ChildProfile(
    childId: 'child-2',
    name: 'Bé Bình',
    avatarId: 'avatar-2',
    mochiName: 'Mochi Bình',
  );

  Map<String, dynamic> pendingTaskDoc({
    required String title,
    required String categoryId,
    required DateTime submittedAt,
  }) {
    return {
      'title': title,
      'flavorText': 'flavor',
      'categoryId': categoryId,
      'xuReward': 10,
      'energyReward': 5,
      'status': 'pending',
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }

  /// Fixed-frame-count pump, never `pumpAndSettle()` — see header comment.
  Future<void> pumpSteps(
    WidgetTester tester, [
    int steps = 20,
    Duration step = const Duration(milliseconds: 16),
  ]) async {
    for (var i = 0; i < steps; i++) {
      await tester.pump(step);
    }
  }

  setUp(() {
    GameEventBus().resetForTesting();
  });

  /// Pumps `ParentDashboardTasksTab` standalone (no real GoRouter) — used by
  /// every group that never taps "Chọn bé" (which needs a real Router
  /// ancestor only at tap time).
  /// [offline] picks which connectivity fake backs [connectivityProvider] —
  /// defaults to online (see [_FakeOnlineConnectivity]'s doc comment for why
  /// this is REQUIRED, not just a convenience default: the real
  /// `Connectivity()` singleton's platform channel never resolves under this
  /// file's fake-clock-only `pumpSteps`). The one test that genuinely
  /// exercises the offline pre-check passes `offline: true` instead of
  /// hand-adding its own `connectivityProvider` override to [extraOverrides]
  /// (which would risk a duplicate-override conflict with this default).
  Future<void> pumpTasksTab(
    WidgetTester tester, {
    required _FakeFirestore firestore,
    String uid = parentId,
    bool offline = false,
    List<Override> extraOverrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseFirestoreProvider.overrideWithValue(firestore),
          authStateProvider.overrideWith((ref) => Stream.value(_FakeUser(uid))),
          connectivityProvider.overrideWithValue(
            offline ? _FakeOfflineConnectivity() : _FakeOnlineConnectivity(),
          ),
          ...extraOverrides,
        ],
        child: const MaterialApp(home: ParentDashboardTasksTab()),
      ),
    );
    await pumpSteps(tester);
  }

  // ---------------------------------------------------------------------
  // AC-1 (Pending list rendering): N=1, N=15, N=0 (empty state).
  // ---------------------------------------------------------------------
  group('AC-1 — Pending list rendering', () {
    testWidgets('test_AC1_oneChild_onePendingTask_rendersExactlyOneCardWithAllFields',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      firestore.seedTask(
        parentId,
        childA.childId,
        'task-1',
        pendingTaskDoc(
          title: 'Dọn phòng',
          categoryId: 'chores',
          submittedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      await pumpTasksTab(tester, firestore: firestore);

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Bé An'), findsOneWidget);
      expect(find.text('Việc nhà'), findsOneWidget);
      expect(find.text('Dọn phòng'), findsOneWidget);
      expect(find.textContaining('phút trước'), findsOneWidget);
      expect(find.byKey(const Key('approveButton_task-1')), findsOneWidget);
      expect(find.byKey(const Key('rejectButton_task-1')), findsOneWidget);
    });

    testWidgets('test_AC1_fifteenPendingTasks_rendersExactlyFifteenCards_noPaginationNoCap',
        (tester) async {
      // A ListView only builds visible (+cacheExtent) children — the default
      // test viewport (~800x600) fits far fewer than 15 cards, so without
      // resizing, `find.byType(Card)` would only see whatever's currently
      // on/near-screen, not the full uncapped list this AC is actually
      // testing for. Tall enough that all 15 cards render without scrolling.
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1.0;

      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      for (var i = 0; i < 15; i++) {
        firestore.seedTask(
          parentId,
          childA.childId,
          'task-$i',
          pendingTaskDoc(
            title: 'Task $i',
            categoryId: 'study',
            submittedAt: DateTime.now().subtract(Duration(minutes: i)),
          ),
        );
      }
      await pumpTasksTab(tester, firestore: firestore);

      expect(find.byType(Card), findsNWidgets(15));
    });

    testWidgets('test_AC1_zeroPendingTasks_showsEmptyState_fabStillTappable',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      await pumpTasksTab(tester, firestore: firestore);

      expect(find.text('Chưa có nhiệm vụ nào chờ duyệt'), findsOneWidget);
      expect(find.byType(Card), findsNothing);

      final fab = tester.widget<FloatingActionButton>(
        find.byKey(const Key('createCustomTaskFab')),
      );
      expect(fab.onPressed, isNotNull);
    });
  });

  // ---------------------------------------------------------------------
  // AC-2 (Multi-child correctness) — THE core regression this story's own
  // unblock fix (familyPendingTasksProvider) exists to prevent. Genuine
  // 2-child fake Firestore, not a single-child stand-in.
  // ---------------------------------------------------------------------
  group('AC-2 — Multi-child correctness', () {
    testWidgets(
        'test_AC2_twoChildrenEachWithPendingTask_eachCardShowsItsOwnChildsAvatarAndName_noCrossContamination',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA, childB]);
      firestore.seedTask(
        parentId,
        childA.childId,
        'task-a',
        pendingTaskDoc(title: 'Bài của An', categoryId: 'study', submittedAt: DateTime.now()),
      );
      firestore.seedTask(
        parentId,
        childB.childId,
        'task-b',
        pendingTaskDoc(title: 'Bài của Bình', categoryId: 'sport', submittedAt: DateTime.now()),
      );
      await pumpTasksTab(tester, firestore: firestore);

      expect(find.byType(Card), findsNWidgets(2));

      // Card for task-a must show childA's name, NOT childB's.
      final cardA = find.byKey(const Key('pendingTaskCard_task-a'));
      expect(
        find.descendant(of: cardA, matching: find.text(childA.name)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: cardA, matching: find.text(childB.name)),
        findsNothing,
      );

      // Card for task-b must show childB's name, NOT childA's.
      final cardB = find.byKey(const Key('pendingTaskCard_task-b'));
      expect(
        find.descendant(of: cardB, matching: find.text(childB.name)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: cardB, matching: find.text(childA.name)),
        findsNothing,
      );
    });
  });

  // ---------------------------------------------------------------------
  // AC-3 (Event emission — normal approve) + idempotent-null edge case.
  // AC-4 (Event emission — level-up).
  // AC-5 (Reject — no emission).
  // Stub repository — see file header comment.
  // ---------------------------------------------------------------------
  group('AC-3/AC-4/AC-5 — Event emission', () {
    Future<_StubParentApprovalRepository> pumpWithOneTask(
      WidgetTester tester, {
      required _StubParentApprovalRepository stub,
    }) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      firestore.seedTask(
        parentId,
        childA.childId,
        'task-1',
        pendingTaskDoc(title: 'Dọn phòng', categoryId: 'chores', submittedAt: DateTime.now()),
      );
      await pumpTasksTab(
        tester,
        firestore: firestore,
        extraOverrides: [parentApprovalRepositoryProvider.overrideWithValue(stub)],
      );
      return stub;
    }

    testWidgets(
        'test_AC3_approveResolvesNonNull_notLeveledUp_emitsExactly1TaskApproved_0PetLeveledUp',
        (tester) async {
      final events = <GameEvent>[];
      final sub = GameEventBus().stream.listen(events.add);
      addTearDown(sub.cancel);

      final stub = _StubParentApprovalRepository()
        ..nextApproveResult = const ApproveResult(leveledUp: false);
      await pumpWithOneTask(tester, stub: stub);

      await tester.tap(find.byKey(const Key('approveButton_task-1')));
      await pumpSteps(tester);

      expect(stub.approveCallCount, 1);
      final taskApprovedEvents =
          events.where((e) => e.type == GameEventType.taskApproved).toList();
      final levelUpEvents =
          events.where((e) => e.type == GameEventType.petLeveledUp).toList();
      expect(taskApprovedEvents, hasLength(1));
      expect(levelUpEvents, isEmpty);
    });

    testWidgets(
        'test_AC3_edgeCase_approveResolvesNull_idempotentNoOp_emitsZeroEventsOfAnyKind',
        (tester) async {
      final events = <GameEvent>[];
      final sub = GameEventBus().stream.listen(events.add);
      addTearDown(sub.cancel);

      final stub = _StubParentApprovalRepository()..nextApproveResult = null;
      await pumpWithOneTask(tester, stub: stub);

      await tester.tap(find.byKey(const Key('approveButton_task-1')));
      await pumpSteps(tester);

      expect(stub.approveCallCount, 1);
      expect(events, isEmpty, reason: 'null result (idempotent no-op) must emit nothing');
    });

    testWidgets(
        'test_AC4_approveResolvesLeveledUp_emits1TaskApproved_then1PetLeveledUp_inThatOrder',
        (tester) async {
      final events = <GameEvent>[];
      final sub = GameEventBus().stream.listen(events.add);
      addTearDown(sub.cancel);

      final stub = _StubParentApprovalRepository()
        ..nextApproveResult = const ApproveResult(leveledUp: true, newPetLevel: 3);
      await pumpWithOneTask(tester, stub: stub);

      await tester.tap(find.byKey(const Key('approveButton_task-1')));
      await pumpSteps(tester);

      expect(events, hasLength(2));
      expect(events[0].type, GameEventType.taskApproved);
      expect(events[1].type, GameEventType.petLeveledUp);
      expect(events[1].data, 3);
    });

    testWidgets('test_AC5_reject_completes_emitsZeroGameEventsOfAnyKind', (tester) async {
      final events = <GameEvent>[];
      final sub = GameEventBus().stream.listen(events.add);
      addTearDown(sub.cancel);

      final stub = _StubParentApprovalRepository();
      await pumpWithOneTask(tester, stub: stub);

      await tester.tap(find.byKey(const Key('rejectButton_task-1')));
      await pumpSteps(tester);

      expect(stub.rejectCallCount, 1);
      expect(events, isEmpty);
    });

    testWidgets(
        'test_offlinePreCheck_blocksBeforeCallingApproveTask_showsUnifiedError_noEventsEmitted',
        (tester) async {
      // AC "Offline pre-check wiring" — story's own AC list, verified here
      // as this story's supplementary evidence.
      final events = <GameEvent>[];
      final sub = GameEventBus().stream.listen(events.add);
      addTearDown(sub.cancel);

      final stub = _StubParentApprovalRepository()
        ..nextApproveResult = const ApproveResult(leveledUp: false);
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      firestore.seedTask(
        parentId,
        childA.childId,
        'task-1',
        pendingTaskDoc(title: 'Dọn phòng', categoryId: 'chores', submittedAt: DateTime.now()),
      );
      await pumpTasksTab(
        tester,
        firestore: firestore,
        offline: true,
        extraOverrides: [
          parentApprovalRepositoryProvider.overrideWithValue(stub),
        ],
      );

      await tester.tap(find.byKey(const Key('approveButton_task-1')));
      await pumpSteps(tester);

      expect(stub.approveCallCount, 0,
          reason: 'the offline pre-check must block BEFORE calling approveTask()');
      expect(events, isEmpty);
      expect(find.text('Không thực hiện được — thử lại'), findsOneWidget);
      // Button re-enabled after the (pre-check) failure — P1's "re-enable on
      // completion OR failure".
      final approveButton = tester.widget<FilledButton>(
        // `approveButton_task-1`'s Key is directly on the `FilledButton`
        // itself (see `parent_dashboard_tasks_tab.dart`'s `FilledButton.icon`
        // key wiring) — NOT on some ancestor wrapper, so a `find.descendant`
        // search (which excludes the widget matched by `of:` itself) would
        // always find zero results. Fixed from an incorrect `find.descendant`
        // assumption found while independently verifying this story.
        find.byKey(const Key('approveButton_task-1')),
      );
      expect(approveButton.onPressed, isNotNull);
    });
  });

  // ---------------------------------------------------------------------
  // AC-6 (Tab switch during in-flight transaction) — real ParentShellScaffold
  // (both tabs), real ParentApprovalRepository, a gated fake transaction so
  // the transaction is genuinely still running while the tab switch happens.
  // ---------------------------------------------------------------------
  group('AC-6 — Tab switch during in-flight transaction', () {
    testWidgets(
        'test_AC6_approveInFlight_switchToGiaDinhAndBack_transactionCompletes_listReflectsResult_noCancellation',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      firestore.seedTask(
        parentId,
        childA.childId,
        'task-1',
        pendingTaskDoc(title: 'Dọn phòng', categoryId: 'chores', submittedAt: DateTime.now()),
      );
      firestore.transactionGate = Completer<void>();

      final events = <GameEvent>[];
      final sub = GameEventBus().stream.listen(events.add);
      addTearDown(sub.cancel);

      final container = ProviderContainer(
        overrides: [
          firebaseFirestoreProvider.overrideWithValue(firestore),
          authStateProvider.overrideWith((ref) => Stream.value(_FakeUser(parentId))),
          // Without this, `_isOfflineBestEffort`'s real `Connectivity()`
          // check hangs on a platform channel with no test handler — the
          // approve handler would never even reach `runTransaction`/the
          // gate below, so `transactionGate!.complete()` at the end of this
          // test would have no observable effect at all (found while
          // independently verifying this story — see `_FakeOnlineConnectivity`'s
          // doc comment for the full mechanism).
          connectivityProvider.overrideWithValue(_FakeOnlineConnectivity()),
          firebaseMessagingProvider.overrideWithValue(_FakeFirebaseMessaging()),
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

      // Tap Approve — transaction starts but is held by the gate.
      await tester.tap(find.byKey(const Key('approveButton_task-1')));
      await pumpSteps(tester, 3);

      // Still in flight — button disabled.
      var approveButton = tester.widget<FilledButton>(
        // `approveButton_task-1`'s Key is directly on the `FilledButton`
        // itself (see `parent_dashboard_tasks_tab.dart`'s `FilledButton.icon`
        // key wiring) — NOT on some ancestor wrapper, so a `find.descendant`
        // search (which excludes the widget matched by `of:` itself) would
        // always find zero results. Fixed from an incorrect `find.descendant`
        // assumption found while independently verifying this story.
        find.byKey(const Key('approveButton_task-1')),
      );
      expect(approveButton.onPressed, isNull, reason: 'in flight — disabled');

      // Switch to Gia đình (first-ever visit — unambiguous, that tab's own
      // app bar title doesn't exist in the tree yet).
      await tester.tap(find.text('Gia đình'));
      await pumpSteps(tester, 3);
      expect(find.byType(ParentDashboardFamilyTab), findsOneWidget);

      // Switch back — scoped to the NavigationBar since the Dashboard tab's
      // own app bar title also reads "Nhiệm vụ" (same string as the
      // NavigationBar destination label).
      await tester.tap(
        find.descendant(of: find.byType(NavigationBar), matching: find.text('Nhiệm vụ')),
      );
      await pumpSteps(tester, 3);

      // Still in flight after the round-trip — not cancelled, not resolved
      // early.
      expect(stubEventsEmptyOrEquivalent(events), isTrue);
      approveButton = tester.widget<FilledButton>(
        // `approveButton_task-1`'s Key is directly on the `FilledButton`
        // itself (see `parent_dashboard_tasks_tab.dart`'s `FilledButton.icon`
        // key wiring) — NOT on some ancestor wrapper, so a `find.descendant`
        // search (which excludes the widget matched by `of:` itself) would
        // always find zero results. Fixed from an incorrect `find.descendant`
        // assumption found while independently verifying this story.
        find.byKey(const Key('approveButton_task-1')),
      );
      expect(approveButton.onPressed, isNull,
          reason: 'transaction must still be in flight — tab switch must not '
              'have cancelled or force-resolved it');

      // Release the gate — the transaction commits for real now.
      firestore.transactionGate!.complete();
      await pumpSteps(tester, 5);

      // The task is no longer pending (status == 'approved') — it must have
      // disappeared from the list, proving the result was reflected, not
      // lost or cancelled by the earlier tab switch.
      expect(find.byKey(const Key('pendingTaskCard_task-1')), findsNothing);
      expect(events.where((e) => e.type == GameEventType.taskApproved), hasLength(1),
          reason: 'exactly 1 taskApproved — no duplicate credit from the '
              'tab-switch round-trip');
    });
  });

  // ---------------------------------------------------------------------
  // AC-7 (List load error).
  // ---------------------------------------------------------------------
  group('AC-7 — List load error', () {
    testWidgets('test_AC7_childrenReadThrows_showsInlineErrorAndRetry_noCrash',
        (tester) async {
      final firestore = _FakeFirestore()..failChildrenReadForParentId = parentId;
      await pumpTasksTab(tester, firestore: firestore);

      expect(find.text('Không tải được danh sách — thử lại'), findsOneWidget);
      expect(find.byKey(const Key('pendingListRetryButton')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('test_AC7_retryButton_afterUnderlyingFixIsResolved_recoversToRealList',
        (tester) async {
      final firestore = _FakeFirestore()..failChildrenReadForParentId = parentId;
      await pumpTasksTab(tester, firestore: firestore);
      expect(find.text('Không tải được danh sách — thử lại'), findsOneWidget);

      // "Fix" the underlying condition, then retry.
      firestore.failChildrenReadForParentId = null;
      firestore.seedChildren(parentId, [childA]);
      firestore.seedTask(
        parentId,
        childA.childId,
        'task-1',
        pendingTaskDoc(title: 'Dọn phòng', categoryId: 'chores', submittedAt: DateTime.now()),
      );

      await tester.tap(find.byKey(const Key('pendingListRetryButton')));
      await pumpSteps(tester);

      expect(find.text('Không tải được danh sách — thử lại'), findsNothing);
      expect(find.byType(Card), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // "Chọn bé" wiring (this tab) + absorption sanity (shared with
  // ParentDashboardFamilyTab — Story 003's provisional local copy).
  // ---------------------------------------------------------------------
  group('"Chọn bé" — wiring and absorption', () {
    testWidgets('test_selectChildAction_visibleOnTasksTab_tapNavigatesToSelectChildRoute',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      final router = GoRouter(
        initialLocation: AppRoutes.parentDashboard,
        routes: [
          GoRoute(
            path: AppRoutes.parentDashboard,
            builder: (_, _) => const ParentDashboardTasksTab(),
          ),
          GoRoute(
            path: AppRoutes.selectChild,
            builder: (_, _) => const Scaffold(body: Text('Select Child Screen')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseFirestoreProvider.overrideWithValue(firestore),
            authStateProvider.overrideWith((ref) => Stream.value(_FakeUser(parentId))),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await pumpSteps(tester);

      expect(find.byType(SelectChildAction), findsOneWidget);
      await tester.tap(find.byKey(SelectChildAction.actionKey));
      await pumpSteps(tester);

      expect(find.text('Select Child Screen'), findsOneWidget);
    });

    testWidgets(
        'test_absorption_taskTabAndFamilyTab_shareTheSameSelectChildActionWidget_notTwoLookAlikes',
        (tester) async {
      // Proves genuine sharing, not two independent implementations that
      // happen to look similar — same shape as chip_cluster_test.dart's own
      // "ParentOverrideTrigger absorption sanity" group.
      expect(ParentDashboardFamilyTab.selectChildActionKey, SelectChildAction.actionKey);

      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseFirestoreProvider.overrideWithValue(firestore),
            authStateProvider.overrideWith((ref) => Stream.value(_FakeUser(parentId))),
          ],
          child: const MaterialApp(home: ParentDashboardTasksTab()),
        ),
      );
      await pumpSteps(tester);
      expect(find.byType(SelectChildAction), findsOneWidget,
          reason: 'Tab Nhiệm vụ must render the SHARED widget');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseFirestoreProvider.overrideWithValue(firestore),
            authStateProvider.overrideWith((ref) => Stream.value(_FakeUser(parentId))),
          ],
          child: const MaterialApp(home: ParentDashboardFamilyTab()),
        ),
      );
      await pumpSteps(tester);
      expect(find.byType(SelectChildAction), findsOneWidget,
          reason: 'Tab Gia đình must ALSO render the SAME shared widget type, '
              'not a second look-alike implementation');
    });
  });

  // ---------------------------------------------------------------------
  // P1 single-flight guard regression (rapid double-tap Approve).
  // ---------------------------------------------------------------------
  group('P1 — single-flight guard regression', () {
    testWidgets('test_rapidDoubleTapApprove_callsApproveTaskExactlyOnce',
        (tester) async {
      // A gate is REQUIRED here, not optional: with an instantly-resolving
      // stub, `tester.tap()`'s own internal `await` fully drains the first
      // tap's entire async chain (guard -> repo call -> clear status)
      // before the test can even issue a second `tester.tap()` — there
      // would be no genuine overlap left to race. Holding the first call at
      // the gate keeps it truly in-flight while the second tap lands.
      final stub = _StubParentApprovalRepository()
        ..nextApproveResult = const ApproveResult(leveledUp: false)
        ..gate = Completer<void>();
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      firestore.seedTask(
        parentId,
        childA.childId,
        'task-1',
        pendingTaskDoc(title: 'Dọn phòng', categoryId: 'chores', submittedAt: DateTime.now()),
      );
      await pumpTasksTab(
        tester,
        firestore: firestore,
        extraOverrides: [parentApprovalRepositoryProvider.overrideWithValue(stub)],
      );

      // Tap 1 starts, increments approveCallCount, then suspends on the
      // gate — genuinely in flight.
      await tester.tap(find.byKey(const Key('approveButton_task-1')));
      // Tap 2 lands while tap 1 is still gated — the button's `onPressed`
      // hasn't been rebuilt to null yet (no pump since tap 1), so this
      // exercises the SAME re-tap-before-rebuild path the other P1 tests in
      // this epic prove; the guard inside `_approveTask` itself (checked
      // synchronously, not just the button's disabled visual state) is what
      // must stop this from reaching the repository a second time.
      await tester.tap(find.byKey(const Key('approveButton_task-1')), warnIfMissed: false);
      await pumpSteps(tester, 3);

      // Still gated — prove call count is 1 WHILE genuinely in flight, not
      // just after everything settles (which wouldn't distinguish "blocked"
      // from "both calls happened to interleave harmlessly").
      expect(stub.approveCallCount, 1,
          reason: 'second tap must be blocked before reaching the repository, '
              'while the first call is still gated open');

      stub.gate!.complete();
      await pumpSteps(tester);

      expect(stub.approveCallCount, 1);
    });

    testWidgets('test_rapidDoubleTapReject_callsRejectTaskExactlyOnce',
        (tester) async {
      // Symmetric coverage for the Reject path's identical guard
      // (`_rejectTask`'s own `if (... inFlight ?? false) return;`) — added
      // in code review alongside the Approve test above, since the two
      // handlers' guards are byte-identical but were previously only
      // regression-tested on one side.
      final stub = _StubParentApprovalRepository()..gate = Completer<void>();
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      firestore.seedTask(
        parentId,
        childA.childId,
        'task-1',
        pendingTaskDoc(title: 'Dọn phòng', categoryId: 'chores', submittedAt: DateTime.now()),
      );
      await pumpTasksTab(
        tester,
        firestore: firestore,
        extraOverrides: [parentApprovalRepositoryProvider.overrideWithValue(stub)],
      );

      await tester.tap(find.byKey(const Key('rejectButton_task-1')));
      await tester.tap(find.byKey(const Key('rejectButton_task-1')), warnIfMissed: false);
      await pumpSteps(tester, 3);

      expect(stub.rejectCallCount, 1,
          reason: 'second tap must be blocked before reaching the repository, '
              'while the first call is still gated open');

      stub.gate!.complete();
      await pumpSteps(tester);

      expect(stub.rejectCallCount, 1);
    });
  });

  // ---------------------------------------------------------------------
  // FAB absorption sanity — the exact same key/behavior Story 002's
  // provisional FAB used, now folded into the real tab layout.
  // ---------------------------------------------------------------------
  group('FAB absorption', () {
    testWidgets('test_createCustomTaskFab_sameKeyAsStory002_stillOpensCreateSheet',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [childA]);
      await pumpTasksTab(tester, firestore: firestore);

      await tester.tap(find.byKey(const Key('createCustomTaskFab')));
      await pumpSteps(tester);

      expect(find.byType(CreateCustomTaskSheet), findsOneWidget);
    });
  });
}

/// Small helper to keep the AC-6 test's "nothing resolved yet" assertion
/// readable — returns true if no `taskApproved`/`petLeveledUp` has landed
/// yet.
bool stubEventsEmptyOrEquivalent(List<GameEvent> events) {
  return events
      .where((e) =>
          e.type == GameEventType.taskApproved || e.type == GameEventType.petLeveledUp)
      .isEmpty;
}
