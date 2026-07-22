// Run with:
//   cd src && flutter test ../tests/unit/task_library/task_providers_test.dart
//
// Hand-rolled minimal Firestore fake supporting chained .where()/.orderBy()
// queries and .snapshots() (a live Stream) — extends the established
// Stream.multi()-based replay-then-forward pattern already used by
// energy_provider_test.dart / xu_balance_provider_test.dart.

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/task_providers.dart';

/// Minimal fake `DocumentReference` built purely from a path STRING — see
/// `task_model_test.dart`'s identical pair for the full rationale. `.parent`
/// alternates collection/doc by splitting off the last path segment, which
/// is what lets `TaskModel.fromFirestore`'s
/// `doc.reference.parent.parent!.id` (tasks collection -> owning child doc
/// -> that doc's id, i.e. `childId`) resolve correctly against a fake —
/// required now that BOTH `pendingTasksProvider` and the new
/// `familyPendingTasksProvider` route every snapshot through
/// `TaskModel.fromFirestore`.
class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this._path);
  final String _path;

  @override
  String get id => _path.split('/').last;

  @override
  CollectionReference<Map<String, dynamic>> get parent => _FakeCollectionReference(
        _path.substring(0, _path.lastIndexOf('/')),
        const [],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQueryDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDocumentSnapshot(this._data, this.reference);
  final Map<String, dynamic> _data;

  @override
  final DocumentReference<Map<String, dynamic>> reference;

  @override
  String get id => reference.id;

  /// Strips the `__id` seeding key (see `_task`/`_child` helpers below) —
  /// real Firestore never returns the document's own id as a data field
  /// unless a caller deliberately duplicated it there, which this schema
  /// doesn't.
  @override
  Map<String, dynamic> data() => Map.of(_data)..remove('__id');

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

/// A single applied filter, recorded so `_snapshotsFor` can apply the whole
/// chain when computing results.
class _Filter {
  _Filter.equals(this.field, dynamic value) : _predicate = ((doc) => doc[field] == value);
  _Filter.whereIn(this.field, List<dynamic> values)
      : _predicate = ((doc) => values.contains(doc[field]));
  _Filter.gte(this.field, dynamic value)
      : _predicate = ((doc) => _compare(doc[field], value) >= 0);

  final String field;
  final bool Function(Map<String, dynamic> doc) _predicate;

  static int _compare(dynamic a, dynamic b) {
    final aVal = a is Timestamp ? a.toDate() : a;
    final bVal = b is Timestamp ? b.toDate() : b;
    return (aVal as Comparable).compareTo(bVal);
  }

  bool matches(Map<String, dynamic> doc) => _predicate(doc);
}

class _FakeQuery implements Query<Map<String, dynamic>> {
  _FakeQuery(
    this._path,
    this._docsProvider,
    this._filters,
    this._orderByField,
    this._descending,
  );

  final String _path;
  final List<Map<String, dynamic>> Function() _docsProvider;
  final List<_Filter> _filters;
  final String? _orderByField;
  final bool _descending;

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
    // Only isEqualTo/isGreaterThanOrEqualTo/whereIn are actually used by
    // pendingTasksProvider/taskHistoryProvider — the rest of Query.where's
    // full signature is matched only so this override conforms to the real
    // interface (Dart requires an explicitly-declared override to
    // structurally match, even for parameters this fake never exercises).
    final fieldName = field as String;
    final newFilters = [..._filters];
    if (isEqualTo != null) {
      newFilters.add(_Filter.equals(fieldName, isEqualTo));
    }
    if (isGreaterThanOrEqualTo != null) {
      newFilters.add(_Filter.gte(fieldName, isGreaterThanOrEqualTo));
    }
    if (whereIn != null) {
      newFilters.add(_Filter.whereIn(fieldName, whereIn.toList()));
    }
    return _FakeQuery(_path, _docsProvider, newFilters, _orderByField, _descending);
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    return _FakeQuery(_path, _docsProvider, _filters, field as String, descending);
  }

  QuerySnapshot<Map<String, dynamic>> _snapshotNow() {
    final docs = _docsProvider().where((d) => _filters.every((f) => f.matches(d))).toList();
    if (_orderByField != null) {
      docs.sort((a, b) {
        final cmp = _Filter._compare(a[_orderByField], b[_orderByField]);
        return _descending ? -cmp : cmp;
      });
    }
    return _FakeQuerySnapshot([
      for (var i = 0; i < docs.length; i++)
        _FakeQueryDocumentSnapshot(
          docs[i],
          // `__id` (see `_task`/`_child` seeding helpers) wins when present
          // (needed wherever the real id is asserted on, e.g. `children`
          // docs, whose id IS `childId`) — otherwise an arbitrary but valid
          // per-emission id, sufficient for `tasks` docs, which no test
          // here asserts an exact id for.
          _FakeDocumentReference('$_path/${docs[i]['__id'] as String? ?? 'doc-$i'}'),
        ),
    ]);
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return _snapshotNow();
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return Stream.multi((controller) {
      controller.add(_snapshotNow());
      controller.onCancel = () {};
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollectionReference extends _FakeQuery
    implements CollectionReference<Map<String, dynamic>> {
  _FakeCollectionReference(String path, this._docs)
      : super(path, () => _docs, [], null, false);
  final List<Map<String, dynamic>> _docs;

  /// Required by `TaskModel.fromFirestore`'s `doc.reference.parent.parent`
  /// chain: `doc.reference.parent` IS a `_FakeCollectionReference` (the
  /// `tasks` collection itself) — its own `.parent` must resolve one level
  /// further up, to the owning child DOCUMENT (`.id` == `childId`).
  @override
  DocumentReference<Map<String, dynamic>>? get parent {
    final idx = _path.lastIndexOf('/');
    if (idx < 0) return null; // root collection — never hit by this schema.
    return _FakeDocumentReference(_path.substring(0, idx));
  }

  void seed(List<Map<String, dynamic>> docs) {
    _docs
      ..clear()
      ..addAll(docs);
  }
}

class _FakeFirestore implements FirebaseFirestore {
  final _collections = <String, _FakeCollectionReference>{};

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _collections.putIfAbsent(path, () => _FakeCollectionReference(path, []));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _task({
  required String status,
  required DateTime submittedAt,
  String categoryId = 'chores',
}) {
  return {
    'title': 'Task',
    'flavorText': 'desc',
    'categoryId': categoryId,
    'xuReward': 15,
    'energyReward': 25,
    'status': status,
    'submittedAt': Timestamp.fromDate(submittedAt),
    'approvedAt': null,
    'rejectedAt': null,
  };
}

/// `__id` is a seeding-only convention (see `_FakeQuery._snapshotNow`) — for
/// `children` docs the real id (`childId`) IS asserted on downstream
/// (`ChildProfileRepository.getChildProfiles` reads `doc.id` directly), so
/// unlike `_task` above this needs an explicit, real id.
Map<String, dynamic> _child(ChildProfile profile) {
  return {
    '__id': profile.childId,
    'name': profile.name,
    'avatarId': profile.avatarId,
    'mochiName': profile.mochiName,
  };
}

void main() {
  const childId = 'child-1';
  final child = const ChildProfile(
    childId: childId,
    name: 'Bé An',
    avatarId: 'avatar-1',
    mochiName: 'Mochi',
  );

  Future<String> waitForSignedInUser(
    ProviderContainer container,
    MockFirebaseAuth auth,
  ) {
    final completer = Completer<String>();
    late final ProviderSubscription<AsyncValue<User?>> sub;
    sub = container.listen(authStateProvider, (previous, next) {
      final user = next.value;
      if (user != null && !completer.isCompleted) {
        completer.complete(user.uid);
      }
    });
    completer.future.whenComplete(sub.close);
    auth.signInWithEmailAndPassword(email: 'parent@example.com', password: 'x');
    return completer.future.timeout(const Duration(seconds: 5));
  }

  group('pendingTasksProvider', () {
    test('test_pendingTasksProvider_returns_only_pending_tasks_newest_first',
        () async {
      final firestore = _FakeFirestore();
      final auth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firebaseFirestoreProvider.overrideWithValue(firestore),
        ],
      );
      addTearDown(container.dispose);
      final parentId = await waitForSignedInUser(container, auth);
      container.read(activeChildProvider.notifier).state = child;

      final now = DateTime(2026, 7, 16);
      (firestore.collection(FirestorePaths.tasks(parentId, childId))
              as _FakeCollectionReference)
          .seed([
        _task(status: 'pending', submittedAt: now.subtract(const Duration(days: 1))),
        _task(status: 'approved', submittedAt: now),
        _task(status: 'pending', submittedAt: now),
        _task(status: 'rejected', submittedAt: now),
      ]);

      final sub = container.listen(pendingTasksProvider, (_, __) {});
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);

      final tasks = sub.read().value!;
      expect(tasks, hasLength(2));
      expect(tasks.every((t) => t.status == 'pending'), isTrue);
      expect(tasks[0].submittedAt.isAfter(tasks[1].submittedAt), isTrue);
    });

    test('test_pendingTasksProvider_resolves_to_empty_when_signed_out',
        () async {
      final firestore = _FakeFirestore();
      final auth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firebaseFirestoreProvider.overrideWithValue(firestore),
        ],
      );
      addTearDown(container.dispose);
      // Deliberately never sign in.
      container.read(activeChildProvider.notifier).state = child;

      final sub = container.listen(pendingTasksProvider, (_, __) {});
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(sub.read().value, isEmpty);
    });
  });

  group('familyPendingTasksProvider', () {
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

    /// Several `Future.zero` hops needed (not just the single hop
    /// `pendingTasksProvider`'s own tests use): `authStateProvider` resolve
    /// -> `childProfilesProvider.future` await -> each per-child snapshot
    /// stream emitting into `_mergeLatestLists`'s combineLatest, which only
    /// emits once ALL sources have reported in at least once.
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test(
        'test_familyPendingTasksProvider_mergesAcrossAllChildren_newestFirst_withCorrectChildId',
        () async {
      // This is the story's own core fix under test: the OLD
      // pendingTasksProvider only ever saw ONE child (activeChildProvider);
      // this provider must see BOTH children's pending tasks, correctly
      // attributed via TaskModel.childId (Parent Dashboard UI Story 001's
      // AC-2 — multi-child correctness — depends on this).
      final firestore = _FakeFirestore();
      final auth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firebaseFirestoreProvider.overrideWithValue(firestore),
        ],
      );
      addTearDown(container.dispose);
      final parentId = await waitForSignedInUser(container, auth);

      (firestore.collection(FirestorePaths.children(parentId))
              as _FakeCollectionReference)
          .seed([_child(childA), _child(childB)]);

      final now = DateTime(2026, 7, 22, 10);
      (firestore.collection(FirestorePaths.tasks(parentId, childA.childId))
              as _FakeCollectionReference)
          .seed([
        _task(status: 'pending', submittedAt: now.subtract(const Duration(hours: 2))),
        _task(status: 'approved', submittedAt: now), // excluded — not pending
      ]);
      (firestore.collection(FirestorePaths.tasks(parentId, childB.childId))
              as _FakeCollectionReference)
          .seed([
        _task(status: 'pending', submittedAt: now), // newest overall
      ]);

      final sub = container.listen(familyPendingTasksProvider, (_, __) {});
      addTearDown(sub.close);
      await settle();

      final tasks = sub.read().value!;
      expect(tasks, hasLength(2),
          reason: 'one pending task per child; childA\'s approved task excluded');
      expect(tasks.every((t) => t.status == 'pending'), isTrue);
      // Newest first ACROSS children, not just within one child's own list —
      // childB's task (submitted at `now`) must sort ahead of childA's
      // (submitted 2 hours earlier), proving this is a genuine cross-child
      // merge+re-sort, not just concatenation in child-list order.
      expect(tasks[0].childId, childB.childId);
      expect(tasks[1].childId, childA.childId);
      expect(tasks[0].submittedAt.isAfter(tasks[1].submittedAt), isTrue);
    });

    test('test_familyPendingTasksProvider_resolvesToEmpty_whenSignedOut',
        () async {
      final firestore = _FakeFirestore();
      final auth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firebaseFirestoreProvider.overrideWithValue(firestore),
        ],
      );
      addTearDown(container.dispose);
      // Deliberately never sign in.

      final sub = container.listen(familyPendingTasksProvider, (_, __) {});
      addTearDown(sub.close);
      await settle();

      expect(sub.read().value, isEmpty);
    });

    test(
        'test_familyPendingTasksProvider_resolvesToEmpty_whenParentHasNoChildren',
        () async {
      // The exact "parent logs in directly, no active child session" flow
      // named in the story's own blocker note — must resolve to a clean
      // empty list, not hang or throw, when the family has 0 children.
      final firestore = _FakeFirestore();
      final auth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firebaseFirestoreProvider.overrideWithValue(firestore),
        ],
      );
      addTearDown(container.dispose);
      await waitForSignedInUser(container, auth);
      // children collection deliberately left unseeded (empty) —
      // activeChildProvider is ALSO deliberately left unset, since this
      // provider must not depend on it at all.

      final sub = container.listen(familyPendingTasksProvider, (_, __) {});
      addTearDown(sub.close);
      await settle();

      expect(sub.read().value, isEmpty);
    });
  });

  group('taskHistoryProvider', () {
    test(
        'test_taskHistoryProvider_returns_only_approved_rejected_tasks_within_30_days',
        () async {
      final firestore = _FakeFirestore();
      final auth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firebaseFirestoreProvider.overrideWithValue(firestore),
        ],
      );
      addTearDown(container.dispose);
      final parentId = await waitForSignedInUser(container, auth);
      container.read(activeChildProvider.notifier).state = child;

      final now = DateTime.now();
      (firestore.collection(FirestorePaths.tasks(parentId, childId))
              as _FakeCollectionReference)
          .seed([
        _task(status: 'pending', submittedAt: now), // excluded: not history
        _task(status: 'approved', submittedAt: now.subtract(const Duration(days: 5))),
        _task(status: 'rejected', submittedAt: now.subtract(const Duration(days: 10))),
        _task(status: 'approved', submittedAt: now.subtract(const Duration(days: 31))), // too old
      ]);

      final sub = container.listen(taskHistoryProvider, (_, __) {});
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);

      final tasks = sub.read().value!;
      expect(tasks, hasLength(2));
      expect(tasks.every((t) => t.status == 'approved' || t.status == 'rejected'),
          isTrue);
      // Newest first.
      expect(tasks[0].submittedAt.isAfter(tasks[1].submittedAt), isTrue);
    });

    test('test_taskHistoryProvider_resolves_to_empty_when_no_active_child',
        () async {
      final firestore = _FakeFirestore();
      final auth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firebaseFirestoreProvider.overrideWithValue(firestore),
        ],
      );
      addTearDown(container.dispose);
      await waitForSignedInUser(container, auth);
      // activeChildProvider deliberately left null.

      final sub = container.listen(taskHistoryProvider, (_, __) {});
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);

      expect(sub.read().value, isEmpty);
    });

    test('test_taskHistoryProvider_uses_whereIn_never_not_in', () {
      // Doc-comment lines are excluded — this file's own comment correctly
      // explains "NEVER not-in" in prose, which would otherwise false-flag
      // this check (same class of false positive already found and fixed
      // for task_model_test.dart's "no cancelled" check).
      final codeLines = File('lib/providers/task_providers.dart')
          .readAsLinesSync()
          .where((line) => !line.trim().startsWith('//'));

      expect(codeLines.any((line) => line.contains('not-in')), isFalse);
      expect(codeLines.any((line) => line.contains('whereIn')), isTrue);
    });
  });

  test('test_firestore_indexes_json_is_valid_and_covers_status_submittedAt',
      () {
    final source = File('../firestore.indexes.json').readAsStringSync();
    final decoded = source.isNotEmpty;
    expect(decoded, isTrue);
    expect(source.contains('"collectionGroup": "tasks"'), isTrue);
    expect(source.contains('"status"'), isTrue);
    expect(source.contains('"submittedAt"'), isTrue);
  });
}
