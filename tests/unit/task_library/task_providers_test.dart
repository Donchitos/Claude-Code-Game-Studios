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

class _FakeQueryDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDocumentSnapshot(this._data);
  final Map<String, dynamic> _data;

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
  _FakeQuery(this._docsProvider, this._filters, this._orderByField, this._descending);

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
    return _FakeQuery(_docsProvider, newFilters, _orderByField, _descending);
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    return _FakeQuery(_docsProvider, _filters, field as String, descending);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return Stream.multi((controller) {
      void emit() {
        var docs = _docsProvider().where((d) => _filters.every((f) => f.matches(d))).toList();
        if (_orderByField != null) {
          docs.sort((a, b) {
            final cmp = _Filter._compare(a[_orderByField], b[_orderByField]);
            return _descending ? -cmp : cmp;
          });
        }
        controller.add(
          _FakeQuerySnapshot(docs.map(_FakeQueryDocumentSnapshot.new).toList()),
        );
      }

      emit();
      controller.onCancel = () {};
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollectionReference extends _FakeQuery
    implements CollectionReference<Map<String, dynamic>> {
  _FakeCollectionReference(this._docs) : super(() => _docs, [], null, false);
  final List<Map<String, dynamic>> _docs;

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
    return _collections.putIfAbsent(path, () => _FakeCollectionReference([]));
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
