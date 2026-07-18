// Run with:
//   cd src && flutter test ../tests/unit/task_library/custom_task_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/custom_task_repository.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/core/models/custom_task_template.dart';

class _RecordedWrite {
  _RecordedWrite(this.path, this.data);
  final String path;
  final Map<String, dynamic> data;
}

class _FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  _FakeCollectionReference(this.path, this._writes);
  final String path;
  final List<_RecordedWrite> _writes;

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
    Map<String, dynamic> data,
  ) async {
    _writes.add(_RecordedWrite(path, data));
    return _FakeDocumentReference();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  final writes = <_RecordedWrite>[];

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _FakeCollectionReference(path, writes);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const parentId = 'parent-1';
  const childId = 'child-1';

  test(
      'test_createCustomTaskTemplate_writes_exactly_the_4_template_fields_no_reward_fields',
      () async {
    final firestore = _FakeFirestore();
    final repo = CustomTaskRepository(firestore: firestore);

    await repo.createCustomTaskTemplate(
      parentId: parentId,
      childId: childId,
      title: 'Đọc sách',
      categoryId: 'study',
    );

    expect(firestore.writes, hasLength(1));
    final write = firestore.writes.single;
    expect(write.path, FirestorePaths.customTasks(parentId));
    expect(write.data.keys.toSet(),
        {'title', 'categoryId', 'targetChildId', 'createdAt'});
    expect(write.data['title'], 'Đọc sách');
    expect(write.data['categoryId'], 'study');
    expect(write.data['targetChildId'], childId);
    expect(write.data.containsKey('xuReward'), isFalse);
    expect(write.data.containsKey('energyReward'), isFalse);
    expect(write.data.containsKey('status'), isFalse);
  });

  test('test_createCustomTaskTemplate_uses_FieldValue_serverTimestamp_for_createdAt',
      () async {
    final firestore = _FakeFirestore();
    final repo = CustomTaskRepository(firestore: firestore);

    await repo.createCustomTaskTemplate(
      parentId: parentId,
      childId: childId,
      title: 'Đọc sách',
      categoryId: 'study',
    );

    final createdAt = firestore.writes.single.data['createdAt'];
    expect(createdAt, isA<FieldValue>());
    expect(createdAt, FieldValue.serverTimestamp());
    expect(createdAt, isNot(FieldValue.delete()));
  });

  test('test_createCustomTaskTemplate_rejects_an_empty_title_before_writing',
      () async {
    final firestore = _FakeFirestore();
    final repo = CustomTaskRepository(firestore: firestore);

    await expectLater(
      () => repo.createCustomTaskTemplate(
        parentId: parentId,
        childId: childId,
        title: '',
        categoryId: 'study',
      ),
      throwsArgumentError,
    );
    expect(firestore.writes, isEmpty);
  });

  test(
      'test_createCustomTaskTemplate_rejects_a_whitespace_only_title_before_writing',
      () async {
    final firestore = _FakeFirestore();
    final repo = CustomTaskRepository(firestore: firestore);

    await expectLater(
      () => repo.createCustomTaskTemplate(
        parentId: parentId,
        childId: childId,
        title: '   ',
        categoryId: 'study',
      ),
      throwsArgumentError,
    );
    expect(firestore.writes, isEmpty);
  });

  test('test_createCustomTaskTemplate_trims_a_padded_title_before_writing',
      () async {
    final firestore = _FakeFirestore();
    final repo = CustomTaskRepository(firestore: firestore);

    await repo.createCustomTaskTemplate(
      parentId: parentId,
      childId: childId,
      title: '  Đọc sách  ',
      categoryId: 'study',
    );

    expect(firestore.writes.single.data['title'], 'Đọc sách');
  });

  test(
      'test_createCustomTaskTemplate_rejects_an_unknown_categoryId_before_writing',
      () async {
    final firestore = _FakeFirestore();
    final repo = CustomTaskRepository(firestore: firestore);

    await expectLater(
      () => repo.createCustomTaskTemplate(
        parentId: parentId,
        childId: childId,
        title: 'Đọc sách',
        categoryId: 'not_a_real_category',
      ),
      throwsArgumentError,
    );
    expect(firestore.writes, isEmpty);
  });

  test(
      'test_CustomTaskTemplate_toFirestoreMap_has_exactly_the_4_fields_and_defaults_createdAt',
      () {
    const template = CustomTaskTemplate(
      title: 'Đọc sách',
      categoryId: 'study',
      targetChildId: childId,
    );

    final map = template.toFirestoreMap();

    expect(map.keys.toSet(), {'title', 'categoryId', 'targetChildId', 'createdAt'});
    expect(map['title'], 'Đọc sách');
    expect(map['categoryId'], 'study');
    expect(map['targetChildId'], childId);
    expect(map['createdAt'], FieldValue.serverTimestamp());
  });
}
